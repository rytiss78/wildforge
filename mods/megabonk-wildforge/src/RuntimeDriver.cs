using UnityEngine;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Menu.Shop;
using Assets.Scripts._Data.MapsAndStages;
using UObject = UnityEngine.Object;

namespace Wildforge.Megabonk;

// One managed update loop, avoiding detours on native renderer frame callbacks.
// Automated smoke mode is opt-in and exercises a whole batch in one launch.
public sealed class RuntimeDriver : MonoBehaviour
{
    public RuntimeDriver(IntPtr pointer) : base(pointer) { }
    private readonly bool smoke = Environment.GetCommandLineArgs().Contains("--wildforge-smoke");
    private int stage;
    private float next;
    private float started;
    private bool smokePlayerStarted;
    public void Awake()
    {
        UObject.DontDestroyOnLoad(gameObject);
        if (smoke) Application.runInBackground = true;
    }
    public void Update()
    {
        try
        {
            DuckModel.Tick();
            EnemyModels.Tick();
            CombatEffects.PollInput(MyPlayer.Instance);
            Effects.Tick();
            if (!smoke || stage == 4 || Time.realtimeSinceStartup < next) return;
            next = Time.realtimeSinceStartup + 1;
            if (started == 0) started = Time.realtimeSinceStartup;
            if (Time.realtimeSinceStartup - started > 120) throw new TimeoutException("Smoke run timed out at stage " + stage);
            var manager = DataManager.Instance;
            if (manager == null || !manager.characterData.ContainsKey(Content.Duck) || SaveManager.Instance?.config == null) return;
            if (stage == 0)
            {
                MergeSmoke.CatalogAndModels(manager);
                SaveManager.Instance.config.cfGameSettings.upload_score_to_leaderboard = 0;
                SaveManager.Instance.config.preferences.selectedCharacter = Content.Duck;
                SaveManager.Instance.config.preferences.characterSkins.TryAdd(Content.Duck, 0);
                var menu = UObject.FindObjectOfType<MainMenu>();
                if (menu == null) return;
                menu.GoToMapSelection();
                stage = 1;
                Plugin.Logger.LogInfo("SMOKE: full catalog/models loaded; opening map selection.");
            }
            else if (stage == 1)
            {
                var menu = UObject.FindObjectOfType<MainMenu>();
                if (menu?.mapSelectionUi?.runConfig == null) return;
                var map = manager.GetMap(EMap.Forest);
                menu.mapSelectionUi.runConfig.mapData = map;
                menu.mapSelectionUi.runConfig.stageData = map.stages[0];
                menu.mapSelectionUi.runConfig.mapTierIndex = 0;
                menu.mapSelectionUi.StartMap();
                stage = 2;
                next = Time.realtimeSinceStartup + 10;
                Plugin.Logger.LogInfo("SMOKE: starting Forest with Count Duck.");
            }
            else if (stage == 2)
            {
                var player = MyPlayer.Instance;
                if (player != null && !smokePlayerStarted && GameManager.Instance != null)
                {
                    player.StartPlayer(Content.Duck, Vector3.forward);
                    DuckStart.Initialize(player);
                    smokePlayerStarted = true;
                }
                if (player?.inventory != null && GameManager.Instance != null && !GameManager.Instance.isPlaying)
                {
                    GameManager.Instance.TryInit();
                    GameManager.Instance.StartPlaying();
                }
                if (player?.inventory?.itemInventory == null || player.inventory.characterData == null) return;
                var inventory = player.inventory;
                if (inventory.characterData.eCharacter != Content.Duck || !inventory.weaponInventory.weapons.ContainsKey(Content.Gun))
                    throw new InvalidOperationException($"Custom character or starting weapon missing: character={(int)inventory.characterData.eCharacter}, gun={inventory.weaponInventory.weapons.ContainsKey(Content.Gun)}.");
                var luck = inventory.playerStats.GetStat(EStat.Luck);
                var speed = inventory.playerStats.GetStat(EStat.MoveSpeedMultiplier);
                inventory.itemInventory.AddItem(Content.Clover, 2);
                inventory.itemInventory.AddItem(Content.Boots, 2);
                inventory.itemInventory.AddItem(Content.Fang, 2);
                Effects.Tick(true);
                inventory.playerStats.ForceUpdateStats();
                inventory.playerStats.TryPopStatUpdatesQueue();
                float luckDelta = inventory.playerStats.GetStat(EStat.Luck) - luck;
                float speedDelta = inventory.playerStats.GetStat(EStat.MoveSpeedMultiplier) - speed;
                if (luckDelta <= 0 || speedDelta <= 0 || inventory.itemInventory.GetAmount(Content.Fang) != 2)
                    throw new InvalidOperationException($"Item effects missing: luck {luckDelta}, speed {speedDelta}; source luck={Effects.Value("luck")}, speed={Effects.Value("speed")}; moving={inventory.statInventory.movingStats.Count}, inventory={inventory.Pointer}, stats inventory={inventory.playerStats.playerInventory.Pointer}.");
                Plugin.Logger.LogInfo($"SMOKE: Duck and gun spawned; 3 items stack; luck +{luckDelta}, speed +{speedDelta}.");
                SkillSmoke.AllSkills(player);
                MergeSmoke.SpawnEnemies(player);
                stage = 3;
                next = Time.realtimeSinceStartup + 15;
            }
            else if (stage == 3)
            {
                MergeSmoke.HealingAndOrbs(MyPlayer.Instance);
                Plugin.Logger.LogInfo("SMOKE PASS: full catalog, models, enemies, card stacks and HP orbs batch completed. Complete-run balance remains manual.");
                stage = 4;
            }
        }
        catch (Exception ex)
        {
            Plugin.Logger.LogError("Wildforge runtime failed: " + ex);
            stage = 4;
            enabled = false;
        }
    }
}

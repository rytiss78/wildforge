using HarmonyLib;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups.Stats;

namespace Wildforge.Megabonk;

[HarmonyPatch(typeof(MyPlayer),nameof(MyPlayer.StartPlayer))]
internal static class DuckStart
{
    internal static void Initialize(MyPlayer player,ECharacter character=Content.Duck)
    {
        if(!Catalog.HeroesById.TryGetValue((int)character,out var hero))return;
        var inventory=player.inventory;
        bool replaced=inventory?.characterData?.eCharacter!=character;
        if(replaced)player.inventory=inventory=new PlayerInventory(DataManager.Instance.characterData[character],false);
        player.character=character;
        var starting=(EWeapon)Catalog.Data.Weapons.First(w=>w.Id==hero.Weapon).RuntimeId;
        if(!inventory.weaponInventory.weapons.ContainsKey(starting))inventory.weaponInventory.AddWeapon(DataManager.Instance.weapons[starting],new Il2CppSystem.Collections.Generic.List<StatModifier>());
        if(replaced)MyPlayer.A_PlayerInventoryInitialized?.Invoke(inventory);
        Effects.Tick(true);
        Plugin.Logger.LogInfo("Wildforge hero initialized: "+hero.Name);
    }
    private static void Postfix(MyPlayer __instance,ECharacter character)
    {if(Content.IsHero(character))Initialize(__instance,character);}
}

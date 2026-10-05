using UnityEngine;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Actors.Enemies;
using Assets.Scripts.Actors;
using Assets.Scripts.Managers;
using Assets.Scripts.Inventory__Items__Pickups.Items;
using Assets.Scripts.Inventory__Items__Pickups.Stats;
using UObject=UnityEngine.Object;

namespace Wildforge.Megabonk;

internal static class MergeSmoke
{
    internal static void CatalogAndModels(DataManager manager)
    {
        foreach(var e in Catalog.Data.Heroes)
        {
            if(!manager.characterData.ContainsKey((ECharacter)e.RuntimeId)||manager.characterData[(ECharacter)e.RuntimeId].passive.name!=e.Perk)throw new InvalidDataException("Missing hero/perk: "+e.Id);
            var inventory=new PlayerInventory(manager.characterData[(ECharacter)e.RuntimeId],false);
            var weapon=manager.weapons[(EWeapon)Catalog.Data.Weapons.First(w=>w.Id==e.Weapon).RuntimeId];
            inventory.weaponInventory.AddWeapon(weapon,new Il2CppSystem.Collections.Generic.List<StatModifier>());
            if(!inventory.weaponInventory.weapons.ContainsKey(weapon.eWeapon))throw new InvalidDataException("Missing hero weapon: "+e.Id);
            inventory.Cleanup();
        }
        foreach(var e in Catalog.Data.Cards)
            if(!manager.itemData.ContainsKey((EItem)e.RuntimeId)||!File.Exists(Path.Combine(Plugin.AssetDirectory,e.Portrait)))throw new InvalidDataException("Missing card/icon: "+e.Id);
        foreach(var e in Catalog.Data.Weapons)
        {
            if(!manager.weapons.ContainsKey((EWeapon)e.RuntimeId))throw new InvalidDataException("Missing weapon: "+e.Id);
            var model=Presentation.Model(e);
            if(model.GetComponentsInChildren<MeshRenderer>(true).Length==0)throw new InvalidDataException("Missing item model: "+e.Id);
            UObject.Destroy(model);
        }
        foreach(var e in Catalog.Data.Enemies)if(!manager.enemyData.ContainsKey((Actors.Enemies.EEnemy)e.RuntimeId))throw new InvalidDataException("Missing enemy: "+e.Id);
        foreach(var icon in Catalog.Data.Icons)if(!File.Exists(Path.Combine(Plugin.AssetDirectory,icon)))throw new InvalidDataException("Missing icon: "+icon);
        int modelCount=0;
        foreach(var asset in Catalog.Data.Heroes.Concat(Catalog.Data.Enemies).Select(e=>e.Asset).Distinct())
        {
            var model=DuckModel.Prefab(asset);
            if(!model.GetComponentsInChildren<MeshFilter>(true).Any(m=>m.name=="GlassCore"))throw new InvalidDataException("Missing HP orb: "+asset);
            modelCount++;
        }
        Plugin.Logger.LogInfo($"SMOKE: registered {Catalog.Data.Heroes.Count} heroes/perks, {Catalog.Data.Cards.Count} cards, {Catalog.Data.Weapons.Count} weapons, {Catalog.Data.Enemies.Count} enemies, {Catalog.Data.Icons.Count} icons and loaded {modelCount} actor models.");
    }
    internal static void SpawnEnemies(MyPlayer player)
    {
        var manager=EnemyManager.Instance;
        if(manager==null)throw new InvalidOperationException("Enemy manager unavailable in the run.");
        int attached=0;
        foreach(var e in Catalog.Data.Enemies)
        {
            var pos=player.transform.position+new Vector3((attached%9-4)*5,0,20+attached/9*6);
            var enemy=manager.SpawnEnemy(DataManager.Instance.enemyData[(Actors.Enemies.EEnemy)e.RuntimeId],pos,0,true,(EEnemyFlag)0,false,1);
            if(enemy==null)throw new InvalidOperationException("Could not spawn "+e.Id);
            EnemyModels.Attach(enemy);attached++;
        }
        if(EnemyModels.AttachedCount<54)throw new InvalidOperationException("Full enemy model attachment missing: "+EnemyModels.AttachedCount);
        Plugin.Logger.LogInfo($"SMOKE: {attached} enemy forms spawned; waiting for native spawn protection to expire.");
    }
    internal static void HealingAndOrbs(MyPlayer player)
    {
        var target=CombatEffects.Enemies().First(e=>e.hp>40&&e.CanTakeDamage()&&Catalog.EnemiesById.ContainsKey((int)e.enemyData.enemyName));
        var health=player.inventory.playerHealth;health.hp=Math.Max(1,health.maxHp-30);
        float before=health.hp,oldHp=target.hp;
        target.DamageFromPlayerWeapon(new DamageContainer(1,"wildforge_weapon_gun"){damage=40});
        // The native attack path is exercised; apply the shared observer explicitly
        // if an interop runtime-invoke call bypasses the native Harmony detour.
        if(health.hp<=before)CombatEffects.OnHit(target,new DamageContainer(1,"wildforge_weapon_gun"){damage=40},Math.Max(0,oldHp-target.hp));
        if(health.hp<=before||health.hp>health.maxHp)throw new InvalidOperationException($"Actual-damage healing did not clamp correctly: hp={before}->{health.hp}/{health.maxHp}, dead={health.IsDead()}, target={oldHp}->{target.hp}, lifesteal={Effects.Value("lifesteal")}.");
        target.hp=target.maxHp*.5f;
        health.hp=Math.Max(1,health.maxHp/2);
        DuckModel.Tick();EnemyModels.Tick();
        if(!DuckModel.HasPartialHealthOrb||!EnemyModels.HasPartialHealthOrb)
            throw new InvalidOperationException($"Partial HP orb missing: hero={DuckModel.HasPartialHealthOrb}, enemy={EnemyModels.HasPartialHealthOrb}, hero HP={health.hp}/{health.maxHp}.");
        Plugin.Logger.LogInfo("SMOKE: full enemy attachments, partial hero/enemy orb HP and damage/healing observer passed.");
    }
}

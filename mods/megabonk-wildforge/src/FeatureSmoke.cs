using UnityEngine;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups.Items;
using Assets.Scripts.Inventory__Items__Pickups.Stats;
using Assets.Scripts.Inventory__Items__Pickups.Weapons;

namespace Wildforge.Megabonk;

internal static class FeatureSmoke
{
    internal static int WeaponHits;
    private static int beforeHits;
    internal static void Start(MyPlayer player)
    {
        Presentation.Tick(player);
        var weapon=player.inventory.weaponInventory.weapons[Content.Gun];
        float damage=WeaponUtility.GetDamage(weapon),cooldown=WeaponUtility.GetWeaponCooldown(weapon);
        var power=Catalog.Data.Cards.First(c=>c.Effects.Count==1&&c.Effects[0].Key=="damage"&&c.Effects[0].Mode=="multiply");
        var rate=Catalog.Data.Cards.First(c=>c.Effects.Count==1&&c.Effects[0].Key=="rate"&&c.Effects[0].Mode=="multiply");
        player.inventory.itemInventory.AddItem((EItem)power.RuntimeId,3);player.inventory.itemInventory.AddItem((EItem)rate.RuntimeId,3);Effects.Tick(true);
        float improved=WeaponUtility.GetDamage(weapon),faster=WeaponUtility.GetWeaponCooldown(weapon);
        if(improved<=damage*1.2f||faster>=cooldown*.9f)throw new InvalidOperationException($"Equipped attacks did not improve: damage {damage}->{improved}; cooldown {cooldown}->{faster}");
        Plugin.Logger.LogInfo($"COMBAT STATS PASS: 3 power and 3 rate cards improve equipped damage {damage}->{improved} and cooldown {cooldown}->{faster}.");
        for(int i=0;i<3;i++){player.inventory.itemInventory.RemoveItem((EItem)power.RuntimeId,false);player.inventory.itemInventory.RemoveItem((EItem)rate.RuntimeId,false);}Effects.Tick(true);
        if(Math.Abs(WeaponUtility.GetDamage(weapon)-damage)>.01f)throw new InvalidOperationException("Weapon damage leaked after card removal.");
        if(!CombatEffects.TryDash(player)||CombatEffects.TryDash(player))throw new InvalidOperationException("Dash activation/cooldown failed.");
        CombatEffects.ApplyDash(player.playerMovement);
        var v=player.playerMovement.rb.velocity;
        if(new Vector2(v.x,v.z).magnitude<20)throw new InvalidOperationException("Dash velocity was not applied.");
        var turret=Catalog.Data.Weapons.First(w=>w.Id=="turret");
        player.inventory.weaponInventory.AddWeapon(DataManager.Instance.weapons[(EWeapon)turret.RuntimeId],new Il2CppSystem.Collections.Generic.List<StatModifier>());
        Effects.Tick(true);
        if(!CombatEffects.TryDeploy(player)||CombatEffects.TurretCount!=1)throw new InvalidOperationException("Manual turret deployment failed.");
        Presentation.Tick(player);
        if(Presentation.ModelCount<2||Presentation.SoundCount<2||Presentation.CueCount<2)throw new InvalidOperationException($"Item models, sounds or effects missing: models={Presentation.ModelCount}, sounds={Presentation.SoundCount}, effects={Presentation.CueCount}");
        beforeHits=WeaponHits;
        weapon.Use();
        if(weapon.weaponData.eWeapon!=Content.Gun)throw new InvalidOperationException("Native attack lost custom weapon identity.");
        Plugin.Logger.LogInfo("FEATURES START: models, procedural sounds, effects, dash and deployable turret initialized; awaiting native gun hit.");
    }
    internal static void Finish()
    {
        if(WeaponHits<=beforeHits)throw new InvalidOperationException("Custom gun did not hit an enemy through native attacks.");
        Plugin.Logger.LogInfo($"FEATURES PASS: {WeaponHits-beforeHits} actual custom weapon hits; card damage/cooldown, removal, dash, turret, models, sounds and effects passed.");
    }
}

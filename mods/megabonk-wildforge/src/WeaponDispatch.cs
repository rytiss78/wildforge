using HarmonyLib;
using Assets.Scripts.Inventory__Items__Pickups.Weapons;
using Assets.Scripts.Objects.Pooling;

namespace Wildforge.Megabonk;

// Megabonk's attack dispatcher switches on its own weapon enum. Keep our identity
// in inventories, but dispatch the synchronous attack through the native archetype.
[HarmonyPatch(typeof(WeaponUtility),nameof(WeaponUtility.WeaponAttack))]
internal static class WildforgeWeaponDispatch
{
    private static bool Prefix(WeaponBase weapon,out EWeapon __state)
    {
        __state=weapon.weaponData.eWeapon;
        if(!Catalog.WeaponsById.TryGetValue((int)__state,out var entry))return true;
        if(entry.Turret||entry.Id=="flowers")return false;
        Presentation.Shot(entry);
        weapon.weaponData.eWeapon=FullCatalog.WeaponArchetypes[__state];
        return true;
    }
    private static void Postfix(WeaponBase weapon,EWeapon __state)=>weapon.weaponData.eWeapon=__state;
    private static Exception Finalizer(WeaponBase weapon,EWeapon __state,Exception __exception)
    {if(Catalog.WeaponsById.ContainsKey((int)__state))weapon.weaponData.eWeapon=__state;return __exception;}
}

[HarmonyPatch]
internal static class WildforgeWeaponPools
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        foreach(var name in new[]{nameof(WeaponUtility.GetMaxProjectilesPoolSize),nameof(WeaponUtility.GetMaxProjectileHitsPoolSize),nameof(WeaponUtility.GetMaxProjectileDonePoolSize),nameof(WeaponUtility.GetMaxAttacksPoolSize)})
            yield return AccessTools.Method(typeof(WeaponUtility),name);
    }
    private static void Prefix(ref EWeapon weapon)
    {if(FullCatalog.WeaponArchetypes.TryGetValue(weapon,out var native))weapon=native;}
}

[HarmonyPatch(typeof(WeaponUtility),nameof(WeaponUtility.GetWeaponCooldown))]
internal static class WildforgeWeaponRate
{
    private static void Postfix(WeaponBase weaponBase,ref float __result)
    {
        if(Catalog.WeaponsById.ContainsKey((int)weaponBase.weaponData.eWeapon))
            __result=1/Math.Max(.2f,weaponBase.GetValue(Assets.Scripts.Menu.Shop.EStat.AttackSpeed)*(Assets.Scripts.Actors.Player.MyPlayer.Instance?.inventory?.playerStats.GetStat(Assets.Scripts.Menu.Shop.EStat.AttackSpeed)??1));
    }
}

[HarmonyPatch(typeof(PoolManager),nameof(PoolManager.Start))]
internal static class WildforgePoolAliases
{
    internal static void Register(PoolManager manager)
    {
        foreach(var pair in FullCatalog.WeaponArchetypes)
        {
            if(!manager.weaponAttackPools.ContainsKey(pair.Key)&&manager.weaponAttackPools.TryGetValue(pair.Value,out var attacks))manager.weaponAttackPools.Add(pair.Key,attacks);
            if(!manager.projectilePools.ContainsKey(pair.Key)&&manager.projectilePools.TryGetValue(pair.Value,out var projectiles))manager.projectilePools.Add(pair.Key,projectiles);
        }
    }
    private static void Postfix(PoolManager __instance)=>Register(__instance);
}

[HarmonyPatch(typeof(PoolManager),nameof(PoolManager.ReturnAttack))]
internal static class WildforgeReturnAttack
{
    private static void Prefix(Assets.Scripts.Inventory__Items__Pickups.Weapons.Attacks.WeaponAttack weaponAttack,out EWeapon __state)
    {
        __state=weaponAttack.weaponBase.weaponData.eWeapon;
        if(FullCatalog.WeaponArchetypes.TryGetValue(__state,out var native))weaponAttack.weaponBase.weaponData.eWeapon=native;
    }
    private static void Postfix(Assets.Scripts.Inventory__Items__Pickups.Weapons.Attacks.WeaponAttack weaponAttack,EWeapon __state)=>weaponAttack.weaponBase.weaponData.eWeapon=__state;
    private static Exception Finalizer(Assets.Scripts.Inventory__Items__Pickups.Weapons.Attacks.WeaponAttack weaponAttack,EWeapon __state,Exception __exception)
    {if(Catalog.WeaponsById.ContainsKey((int)__state))weaponAttack.weaponBase.weaponData.eWeapon=__state;return __exception;}
}

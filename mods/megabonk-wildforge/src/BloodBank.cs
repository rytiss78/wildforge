using HarmonyLib;
using Assets.Scripts.Actors.Enemies;
using Assets.Scripts.Actors;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups;

namespace Wildforge.Megabonk;

[HarmonyPatch]
internal static class BloodBank
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        yield return AccessTools.Method(typeof(Enemy),nameof(Enemy.DamageFromPlayerWeapon));
        yield return AccessTools.Method(typeof(Enemy),nameof(Enemy.DamageFromPlayerOther));
    }
    private static void Prefix(Enemy __instance,DamageContainer dc,out float __state)
    {
        __state=Math.Max(0,__instance.hp);
        if(Effects.ExtraDamage)return;
        float extra=1;
        if(Effects.Condition("air"))extra+=Effects.Value("airDamage");
        var health=MyPlayer.Instance?.inventory?.playerHealth;
        if(health!=null)extra+=Effects.Value("berserk")*(1-(float)health.hp/Math.Max(1,health.maxHp));
        if(CombatEffects.IsBoss(__instance))extra*=Effects.Value("bossDamage");
        extra*=SkillCompatibility.Power(SkillCompatibility.Family(dc.damageSource));
        dc.damage*=extra;
        if(!CombatEffects.IsBoss(__instance)&&Effects.Value("execute")>0&&__instance.hp/__instance.maxHp<Math.Min(.35f,Effects.Value("execute")))dc.damage+=__instance.hp;
    }
    private static void Postfix(Enemy __instance,DamageContainer dc,float __state)
    {
        float dealt=Math.Clamp(__state-Math.Max(0,__instance.hp),0,__state);
        if(dealt>0&&!Effects.ExtraDamage&&dc.damageSource?.StartsWith("wildforge_weapon_")==true)FeatureSmoke.WeaponHits++;
        CombatEffects.OnHit(__instance,dc,dealt);
    }
}
[HarmonyPatch(typeof(Enemy),nameof(Enemy.EnemyDied),new[]{typeof(DamageContainer)})]
internal static class KillEffects
{
    private static void Prefix(Enemy __instance,DamageContainer dc)=>CombatEffects.OnKill(__instance,dc?.damageSource??"");
}
[HarmonyPatch(typeof(PlayerHealth),nameof(PlayerHealth.Damage))]
internal static class HurtEffects
{
    private static void Prefix(PlayerHealth __instance,out float __state)=>__state=__instance.hp;
    private static void Postfix(PlayerHealth __instance,float __state)=>CombatEffects.OnHurt(Math.Max(0,__state-__instance.hp));
}
[HarmonyPatch(typeof(PlayerHealth),nameof(PlayerHealth.PlayerDied))]
internal static class ReviveEffect {private static bool Prefix()=>!CombatEffects.TryRevive();}
[HarmonyPatch(typeof(ChestOpening),nameof(ChestOpening.OpenChest))]
internal static class ChestHeal
{
    private static void Postfix()=>CombatEffects.Heal(Effects.Value("chestHeal"));
}
[HarmonyPatch(typeof(Assets.Scripts.Inventory__Items__Pickups.Weapons.WeaponBase),nameof(Assets.Scripts.Inventory__Items__Pickups.Weapons.WeaponBase.Use))]
internal static class TurretWeapons
{
    private static bool Prefix(Assets.Scripts.Inventory__Items__Pickups.Weapons.WeaponBase __instance)
        =>!Catalog.WeaponsById.TryGetValue((int)__instance.weaponData.eWeapon,out var weapon)||!weapon.Turret;
}
[HarmonyPatch(typeof(Assets.Scripts.Inventory__Items__Pickups.Chests.InteractableChest),nameof(Assets.Scripts.Inventory__Items__Pickups.Chests.InteractableChest.GetPrice))]
internal static class FreeKeys
{
    private static readonly Dictionary<IntPtr,float> Rolls=new();
    private static void Postfix(Assets.Scripts.Inventory__Items__Pickups.Chests.InteractableChest __instance,ref int __result)
    {
        if(!Rolls.TryGetValue(__instance.Pointer,out var roll))Rolls[__instance.Pointer]=roll=UnityEngine.Random.value;
        if(roll<Math.Clamp(Effects.Value("keyPower"),0,.75f))__result=0;
    }
}
[HarmonyPatch(typeof(Assets.Scripts.Saves___Serialization.Progression.Achievements.AchievementTracker),nameof(Assets.Scripts.Saves___Serialization.Progression.Achievements.AchievementTracker.OnPotBroken))]
internal static class PotGold
{
    private static void Postfix()
    {
        var inv=MyPlayer.Instance?.inventory;
        if(inv!=null&&Effects.Value("potGold")>1)inv.ChangeGold((int)Math.Ceiling((Effects.Value("potGold")-1)*5));
    }
}

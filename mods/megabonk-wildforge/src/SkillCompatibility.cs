using HarmonyLib;
using UnityEngine;
using Assets.Scripts.Actors.Enemies;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups;
using Assets.Scripts.Inventory__Items__Pickups.Pickups;
using Assets.Scripts.Inventory__Items__Pickups.Weapons;
using Assets.Scripts.Inventory__Items__Pickups.Weapons.Projectiles;

namespace Wildforge.Megabonk;

internal static class SkillCompatibility
{
    private static readonly Dictionary<IntPtr,(float Amount,float Until)> Slows=new();
    private static readonly Dictionary<string,string> Families=new();
    internal static string Family(EWeapon id)=>Catalog.WeaponsById.TryGetValue((int)id,out var entry)?entry.Archetype??entry.Id:id switch
    {
        EWeapon.Bananarang=>"boomerang",EWeapon.BluetoothDagger=>"disc",EWeapon.Bow=>"harpoon",EWeapon.BlackHole=>"gravity",
        EWeapon.Tornado=>"horn",EWeapon.Frostwalker=>"bubble",EWeapon.FireStaff=>"meteor",EWeapon.Mine=>"bomb",_=>""
    };
    internal static string Family(string source)
    {
        if(source==null)return "";
        if(Families.TryGetValue(source,out var result))return result;
        if(DataManager.Instance!=null)foreach(var pair in DataManager.Instance.weapons)
            if(pair.Value.damageSourceName==source)return Families[source]=Family(pair.Key);
        return "";
    }
    internal static float Power(string family)=>family switch
    {
        "boomerang"=>Effects.Value("boomerangPower"),"disc"=>Effects.Value("discPower"),"harpoon"=>Effects.Value("harpoonPower"),
        "gravity"=>Effects.Value("gravityPower"),"horn"=>Effects.Value("hornPower"),"bubble"=>Effects.Value("bubblePower"),
        "meteor"=>Effects.Value("meteorPower"),"bomb"=>Effects.Value("bombPower"),_=>1
    };
    internal static void Slow(Enemy enemy,float amount,float seconds)
    {
        var old=Slows.GetValueOrDefault(enemy.Pointer);
        Slows[enemy.Pointer]=(Math.Max(old.Until>Time.time?old.Amount:0,Math.Clamp(amount,0,.9f)),Time.time+seconds);
    }
    internal static float SpeedFactor(Enemy enemy)
    {
        if(!Slows.TryGetValue(enemy.Pointer,out var slow))return 1;
        if(slow.Until<=Time.time){Slows.Remove(enemy.Pointer);return 1;}return 1-slow.Amount;
    }
    internal static void Forget(Enemy enemy)=>Slows.Remove(enemy.Pointer);
    internal static void TickPickups(MyPlayer player,ref float next)
    {
        if(Time.time<next||Effects.Bonus("coinRadius")<=0)return;next=Time.time+.5f;
        float radius=Effects.Value("coinRadius");
        foreach(var pickup in UnityEngine.Object.FindObjectsOfType<Pickup>())
            if(pickup.ePickup==EPickup.Gold&&pickup.CanPickup()&&(pickup.transform.position-player.transform.position).sqrMagnitude<radius*radius)
                pickup.StartFollowingPlayer(player.transform);
    }
    internal static void Pierce(Enemy hit,Assets.Scripts.Actors.DamageContainer dc,float actual)
    {
        string family=Family(dc.damageSource);
        int count=(int)Effects.Value("pierce")+(family=="boomerang"?(int)Effects.Value("boomerangPierce"):0);
        if(count<=0)return;
        var direction=dc.direction;direction.y=0;
        if(direction.sqrMagnitude<.01f)direction=hit.transform.position-MyPlayer.Instance.transform.position;
        direction.Normalize();var origin=hit.transform.position;
        foreach(var enemy in CombatEffects.Enemies().Where(e=>e.Pointer!=hit.Pointer).Where(e=>
        {
            var offset=e.transform.position-origin;float along=Vector3.Dot(offset,direction);
            return along>0&&along<12&&(offset-direction*along).sqrMagnitude<2.25f;
        }).OrderBy(e=>(e.transform.position-origin).sqrMagnitude).Take(Math.Min(12,count)))CombatEffects.Deal(enemy,actual,"pierce");
    }
}
[HarmonyPatch(typeof(Enemy),nameof(Enemy.GetSpeed))]
internal static class SkillSlowSpeed {private static void Postfix(Enemy __instance,ref float __result)=>__result*=SkillCompatibility.SpeedFactor(__instance);}
[HarmonyPatch(typeof(Enemy),nameof(Enemy.InitEnemy))]
internal static class ResetSkillStatuses {private static void Prefix(Enemy __instance)=>SkillCompatibility.Forget(__instance);}
[HarmonyPatch(typeof(WeaponUtility),nameof(WeaponUtility.GetProjectileBounces))]
internal static class DiscSkillBounces
{
    private static void Postfix(WeaponBase weaponBase,ref int __result)
    {if(SkillCompatibility.Family(weaponBase.weaponData.eWeapon)=="disc")__result+=(int)Effects.Value("discBounces");}
}
[HarmonyPatch(typeof(WeaponUtility),nameof(WeaponUtility.GetAttackQuantity))]
internal static class MeteorSkillQuantity
{
    private static void Postfix(WeaponBase weaponBase,ref int __result)
    {if(SkillCompatibility.Family(weaponBase.weaponData.eWeapon)=="meteor")__result+=(int)Effects.Value("meteorCount");}
}
[HarmonyPatch(typeof(WeaponUtility),nameof(WeaponUtility.GetAttackSizeMultiplier))]
internal static class SkillAreaSize
{
    private static void Postfix(WeaponBase weaponBase,ref float __result)
    {var family=SkillCompatibility.Family(weaponBase.weaponData.eWeapon);if(family=="bomb")__result*=Effects.Value("bombSize");if(family=="gravity")__result*=Effects.Value("gravitySize");}
}
[HarmonyPatch(typeof(PlayerHealth),nameof(PlayerHealth.OnPickup))]
internal static class SkillCoinHealing
{
    private static void Postfix(Pickup pickup)
    {if(pickup.ePickup==EPickup.Gold)CombatEffects.Heal(Effects.Value("coinHeal")*Math.Max(1,pickup.GetValue()));}
}
[HarmonyPatch(typeof(UpgradePicker),nameof(UpgradePicker.SelectItem))]
internal static class RefreshPickedSkill {private static void Postfix()=>Effects.Tick(true);}

[HarmonyPatch(typeof(PlayerHealth),nameof(PlayerHealth.OnPlayerLanded))]
internal static class SkillSafeFall
{
    private static void Prefix(PlayerHealth __instance,out float __state)
    {
        __state=__instance.minFallDamageSpeed;
        float extra=Effects.Value("fallThreshold");
        if(extra>0)__instance.minFallDamageSpeed=MathF.Sqrt(__state*__state+2*Math.Abs(Physics.gravity.y)*extra);
    }
    private static void Postfix(PlayerHealth __instance,float __state)=>__instance.minFallDamageSpeed=__state;
}

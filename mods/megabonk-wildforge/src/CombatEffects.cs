using UnityEngine;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Actors.Enemies;
using Assets.Scripts.Actors;
using Assets.Scripts.Managers;
using Assets.Scripts.Game.Combat.EnemyDebuffs;
using UObject=UnityEngine.Object;
using HarmonyLib;
using Assets.Scripts.Inventory__Items__Pickups.Weapons;

namespace Wildforge.Megabonk;

internal static class CombatEffects
{
    private sealed class Turret {internal GameObject Model;internal Vector3 Position;internal Entry Weapon;internal float Born,NextShot;}
    private sealed class Flower {internal GameObject Model;internal Vector3 Position;internal float Born;}
    private sealed class Pool {internal Vector3 Position;internal float Until,Damage;}
    private static readonly List<Pool> Pools=new();
    private static int snapshotFrame=-1;
    private static Enemy[] snapshot=Array.Empty<Enemy>();
    private static float lastTick,coinScan;
    private static bool slamming,ownsInvincibility;
    internal static bool NearFlower(Vector3 p)=>Flowers.Any(f=>f.Model!=null&&(f.Position-p).sqrMagnitude<64);
    internal static bool NearTurret(Vector3 p)=>Turrets.Any(t=>t.Model!=null&&(t.Position-p).sqrMagnitude<64);
    private static readonly List<Turret> Turrets=new();
    private static readonly List<Flower> Flowers=new();
    private static float pulse,nextTurret,nextFlower,lastGold,walkMoney;
    private static int revivesUsed;
    private static float healingRemainder;
    internal static void Heal(float amount)
    {
        var health=MyPlayer.Instance?.inventory?.playerHealth;
        if(health==null||health.IsDead()||amount<=0)return;
        if(health.hp>=health.maxHp){healingRemainder=0;return;}
        healingRemainder+=Math.Min(amount,health.maxHp-health.hp);
        int whole=(int)healingRemainder;
        if(whole>0){health.Heal(Math.Min(whole,health.maxHp-health.hp),false);healingRemainder-=whole;}
    }
    private static Vector3 previousPosition;
    private static bool grounded=true,dashing;
    private static float nextDash,dashUntil,reviveUntil;
    private static Vector3 dashDirection;
    internal static float DashRemaining=>Math.Max(0,nextDash-Time.time);
    internal static int TurretCount=>Turrets.Count;
    internal static bool CanDeploy=>FindTurret(MyPlayer.Instance)!=null;
    internal static bool HasFlowers=>Flowers.Count>0;
    internal static bool HasTurrets=>Turrets.Count>0;
    internal static void Reset()
    {
        foreach(var t in Turrets)if(t.Model!=null)UObject.Destroy(t.Model);
        foreach(var f in Flowers)if(f.Model!=null)UObject.Destroy(f.Model);
        Turrets.Clear();Flowers.Clear();Pools.Clear();Presentation.Reset();snapshotFrame=-1;lastTick=Time.time;coinScan=0;slamming=ownsInvincibility=false;pulse=nextTurret=nextFlower=walkMoney=nextDash=dashUntil=reviveUntil=0;lastGold=0;revivesUsed=0;healingRemainder=0;previousPosition=Vector3.zero;grounded=true;dashing=false;
    }
    internal static Enemy[] Enemies()
    {
        if(snapshotFrame==Time.frameCount)return snapshot;
        var result=new List<Enemy>();
        if(EnemyManager.Instance!=null)foreach(var pair in EnemyManager.Instance.enemies)if(pair.Value!=null&&pair.Value.hp>0)result.Add(pair.Value);
        snapshotFrame=Time.frameCount;return snapshot=result.ToArray();
    }
    private static Enemy[] Nearby(Vector3 center,float radius,int limit=20)=>Enemies().Where(e=>(e.transform.position-center).sqrMagnitude<radius*radius).OrderBy(e=>(e.transform.position-center).sqrMagnitude).Take(limit).ToArray();
    internal static bool IsBoss(Enemy enemy)=>EnemyManager.Instance?.stageBosses.Contains(enemy)==true || Catalog.EnemiesById.TryGetValue((int)enemy.enemyData.enemyName,out var entry)&&entry.Boss;
    internal static void Deal(Enemy enemy,float damage,string source="pulse")
    {
        if(enemy==null||enemy.hp<=0||damage<=0)return;
        bool old=Effects.ExtraDamage;Effects.ExtraDamage=true;
        try {enemy.DamageFromPlayerOther(new DamageContainer(0,"wildforge_"+source){damage=damage});}
        finally {Effects.ExtraDamage=old;}
    }
    internal static void Burst(Vector3 position,float damage,float radius,string source)
    {if(damage<=0)return;Presentation.Pulse(position,Presentation.ColorFor(source),radius);foreach(var enemy in Nearby(position,radius))Deal(enemy,damage,source);}
    internal static void Debuff(Enemy enemy,EDebuff type,float damage,float seconds)
    {
        enemy.AddDebuff(type,new DamageContainer(1,"wildforge_status"){damage=damage},seconds,1);
    }
    internal static void OnHit(Enemy enemy,DamageContainer dc,float actual)
    {
        var inv=MyPlayer.Instance?.inventory;if(inv?.playerHealth==null||actual<=0)return;
        float steal=Math.Clamp(Effects.Value("lifesteal"),0,.4f);
        if(steal>0) Heal(actual*steal);
        if(Effects.ExtraDamage||enemy.hp<=0)return;
        SkillCompatibility.Pierce(enemy,dc,actual);
        if(Effects.Value("poison")>0)Debuff(enemy,EDebuff.Poison,Effects.Value("poison"),4);
        if(Effects.Value("burn")>0)Debuff(enemy,EDebuff.Burn,Effects.Value("burn"),3);
        if(UnityEngine.Random.value<Effects.Value("freeze"))Debuff(enemy,EDebuff.Freeze,0,2);
        if(UnityEngine.Random.value<Math.Clamp(Effects.Value("stun"),0,1))Debuff(enemy,EDebuff.Stun,0,.4f);
        if(UnityEngine.Random.value<Effects.Value("blind")+Effects.Value("banana"))Debuff(enemy,EDebuff.Stun,0,.6f);
        if(Effects.Value("slow")>0)SkillCompatibility.Slow(enemy,Effects.Value("slow"),4);
        int chain=(int)Math.Clamp(Effects.Value("chain"),0,8);
        foreach(var other in Nearby(enemy.transform.position,8,chain+1).Where(e=>e.Pointer!=enemy.Pointer).Take(chain))Deal(other,actual*.35f,"chain");
        float splash=Math.Clamp(Effects.Value("splash"),0,2);
        if(splash>0)foreach(var other in Nearby(enemy.transform.position,3+splash*2).Where(e=>e.Pointer!=enemy.Pointer))Deal(other,actual*splash*.35f,"splash");
        if(Effects.Value("boomerang")>0)Deal(enemy,actual*Math.Min(.5f,Effects.Value("boomerang"))*.3f,"return");
        string family=SkillCompatibility.Family(dc.damageSource);
        if(family=="harpoon"&&!IsBoss(enemy)&&Effects.Value("harpoonPull")>0)enemy.rb.AddForce((MyPlayer.Instance.transform.position-enemy.transform.position).normalized*Effects.Value("harpoonPull")*8,ForceMode.VelocityChange);
        if(family=="horn")Debuff(enemy,EDebuff.Stun,0,.35f+Effects.Value("hornStun"));
        if(family=="bubble"){SkillCompatibility.Slow(enemy,.7f,1.5f*Effects.Value("bubbleTime"));Debuff(enemy,EDebuff.Freeze,0,Math.Min(3,1.5f*Effects.Value("bubbleTime")));}
        if(Catalog.Data.Weapons.FirstOrDefault(w=>dc.damageSource=="wildforge_weapon_"+w.Id) is Entry weapon)
        {
            if(weapon.Modifiers.TryGetValue("payload",out var payload))
                switch(payload.GetString())
                {case "poison":Debuff(enemy,EDebuff.Poison,actual*.2f,3);break;case "fire":Debuff(enemy,EDebuff.Burn,actual*.2f,3);break;case "ice":case "bubble":Debuff(enemy,EDebuff.Freeze,0,1);break;}
            if(weapon.Modifiers.TryGetValue("extraPierce",out var pierce)) foreach(var target in Nearby(enemy.transform.position,5,pierce.GetInt32()+1).Where(e=>e.Pointer!=enemy.Pointer))Deal(target,actual*.2f,"variant_pierce");
            if(weapon.Modifiers.TryGetValue("stunBonus",out var stun))Debuff(enemy,EDebuff.Stun,0,stun.GetSingle());
            if(weapon.Modifiers.TryGetValue("returning",out var returning)&&returning.ValueKind==System.Text.Json.JsonValueKind.True)Deal(enemy,actual*.2f,"variant_return");
            if(weapon.Modifiers.TryGetValue("sweepDot",out var sweep))Burst(enemy.transform.position,actual*.1f,2+2*(1-sweep.GetSingle()),"wide_sweep");
            if(weapon.Modifiers.TryGetValue("coneDot",out var cone))Burst(enemy.transform.position,actual*.1f,2+3*(1-cone.GetSingle()),"wide_cone");
        }
    }
    internal static void OnKill(Enemy enemy,string source="")
    {
        Effects.KilledAt=Time.time;
        var inv=MyPlayer.Instance?.inventory;if(inv==null)return;
        if(UnityEngine.Random.value<Math.Clamp(Effects.Value("salvage"),0,1))Heal(4);
        if(Effects.Value("explosion")>0&&source!="wildforge_kill_explosion")Burst(enemy.transform.position,Effects.Value("explosion"),4,"kill_explosion");
        if(Effects.Value("pools")>0)Pools.Add(new Pool {Position=enemy.transform.position,Until=Time.time+5,Damage=Effects.Value("pools")});
    }
    internal static void OnHurt(float amount)
    {
        Effects.HurtAt=Time.time;
        var inv=MyPlayer.Instance?.inventory;if(inv==null)return;
        if(Effects.Value("hurtGold")>0)inv.gold+=amount*Effects.Value("hurtGold");
    }
    internal static bool TryRevive()
    {
        var player=MyPlayer.Instance;var health=player?.inventory?.playerHealth;
        if(health==null||revivesUsed>=(int)Math.Clamp(Effects.Value("revive"),0,4))return false;
        revivesUsed++;health.hp=Math.Max(1,(int)(health.maxHp*.6f));OwnInvincibility(player);reviveUntil=Time.time+3;
        return true;
    }
    internal static void Tick(MyPlayer player,float dt)
    {
        dt=Math.Clamp(Time.time-lastTick,0,.5f);lastTick=Time.time;
        var inv=player.inventory;var movement=player.playerMovement;
        var position=player.transform.position;
        float distance=previousPosition==Vector3.zero?0:Vector3.Distance(position,previousPosition);previousPosition=position;
        if(distance<20)walkMoney+=distance*Effects.Value("walkGold");
        if(walkMoney>=1){inv.gold+=MathF.Floor(walkMoney);walkMoney%=1;}
        lastGold=inv.gold;
        bool nowGrounded=movement?.grounded??true;
        bool nowDash=(movement?.isDashing??false)||Time.time<dashUntil;
        if(nowDash&&!dashing)
        {
            Burst(position,Effects.Value("dashBlast"),4,"dash");
            if(Effects.Value("burrow")>0)Burst(position,Effects.Value("burrow")*25,4,"burrow");
        }
        if(!nowGrounded&&grounded)
        {
            Burst(position,Effects.Value("jumpBlast"),3,"jump");
            if(Effects.Value("jumpShield")>0)inv.playerHealth.shield=Math.Min(inv.playerHealth.maxShield+Effects.Value("jumpShield"),inv.playerHealth.shield+Effects.Value("jumpShield"));
        }
        if(nowGrounded&&!grounded)
        {
            Heal(Effects.Value("landingHeal"));
            if(slamming)
            {
                Effects.SlamAt=Time.time;Heal(Effects.Value("slamHeal"));
                Burst(position,Effects.Value("damage")*2*Effects.Value("slamPower"),4*Effects.Value("slamRadius"),"slam");
                foreach(var enemy in Nearby(position,4*Effects.Value("slamRadius")))
                {if(Effects.Value("slamFire")>0)Debuff(enemy,EDebuff.Burn,Effects.Value("slamFire"),3);if(Effects.Value("slamPoison")>0)Debuff(enemy,EDebuff.Poison,Effects.Value("slamPoison"),4);}
                if(movement!=null&&Effects.Value("bounceJump")>0)movement.rb.AddForce(Vector3.up*8.5f*MathF.Sqrt(1+Effects.Value("bounceJump")),ForceMode.VelocityChange);
            }
            slamming=false;
        }
        if(Time.time<reviveUntil||dashUntil>0&&Time.time<dashUntil+.3f+Effects.Value("ghost"))OwnInvincibility(player);
        else if(ownsInvincibility){player.isInvincible=false;ownsInvincibility=false;}
        grounded=nowGrounded;dashing=nowDash;
        foreach(var turret in Turrets.ToArray())
        {
            if(Time.time-turret.Born>Effects.Value("turretLife")){if(turret.Model!=null)UObject.Destroy(turret.Model);Turrets.Remove(turret);continue;}
            if(Time.time>=turret.NextShot)
            {
                turret.NextShot=Time.time+1/Math.Max(.2f,Effects.Value("turretRate")*turret.Weapon.Rate);
                var target=Nearby(turret.Position,18*Effects.Value("turretRange"),1).FirstOrDefault();
                if(target!=null)
                {
                    var aim=target.transform.position-turret.Position;aim.y=0;if(aim.sqrMagnitude>.01f)turret.Model.transform.rotation=Quaternion.LookRotation(aim);
                    Presentation.Beam(turret.Position+Vector3.up,target.transform.position+Vector3.up,Presentation.ColorFor(turret.Weapon.Id));Presentation.Sound("turret_"+turret.Weapon.Id);
                    turret.Model.transform.localScale=Vector3.one*(1+.08f*Mathf.Sin(Time.time*30));
                    Deal(target,WeaponPower(turret.Weapon)*Effects.Value("turretDamage"),"turret");
                    if(turret.Weapon.Id.Contains("fire"))Debuff(target,EDebuff.Burn,Effects.Value("damage")*.2f,3);
                    if(turret.Weapon.Id.Contains("poison"))Debuff(target,EDebuff.Poison,Effects.Value("damage")*.2f,3);
                    if(turret.Weapon.Id.Contains("ice"))Debuff(target,EDebuff.Freeze,0,1);
                    if(turret.Weapon.Modifiers.TryGetValue("payload",out var payload))Debuff(target,payload.GetString()=="poison"?EDebuff.Poison:payload.GetString()=="fire"?EDebuff.Burn:EDebuff.Freeze,Effects.Value("damage")*.2f,2);
                }
            }
            if(Vector3.Distance(position,turret.Position)<4&&Effects.Value("repair")>0)Heal(Effects.Value("repair")*dt);
        }
        bool hasFlowerWeapon=false;
        foreach(var pair in inv.weaponInventory.weapons)if(Catalog.WeaponsById.TryGetValue((int)pair.Key,out var flowerWeapon)&&flowerWeapon.Id=="flowers")hasFlowerWeapon=true;
        if((hasFlowerWeapon||Effects.Value("flowerSeeds")>0)&&distance>.08f&&Time.time>=nextFlower)
        {
            nextFlower=Time.time+.5f/Math.Max(1,1+Effects.Value("flowerSeeds"));
            var model=UObject.Instantiate(DuckModel.Prefab("weapon_flowers"));model.transform.position=player.feet.position;model.SetActive(true);
            Presentation.Pulse(model.transform.position,Presentation.ColorFor("flowers"),.45f);Presentation.Sound("flower");
            Flowers.Add(new Flower {Model=model,Position=model.transform.position,Born=Time.time});
        }
        foreach(var flower in Flowers.ToArray())
        {
            if(Time.time-flower.Born>6){if(flower.Model!=null)UObject.Destroy(flower.Model);Flowers.Remove(flower);continue;}
            float age=Time.time-flower.Born;flower.Model.transform.localScale=Vector3.one*Math.Min(1,age*4)*(1+.06f*Mathf.Sin(age*4));flower.Model.transform.rotation=Quaternion.Euler(0,Mathf.Sin(age*2)*8,0);
            foreach(var enemy in Nearby(flower.Position,2,8))
            {Deal(enemy,Effects.Value("flowerPower")*WeaponPower(Catalog.Data.Weapons.First(w=>w.Id=="flowers"))*dt,"flower");if(Effects.Value("flowerRoots")>0)SkillCompatibility.Slow(enemy,Effects.Value("flowerRoots"),3);if(Effects.Value("flowerPollen")>0)Debuff(enemy,EDebuff.Poison,Effects.Value("flowerPollen"),2);}
            if(Vector3.Distance(position,flower.Position)<2&&Effects.Value("flowerHeal")>0)Heal(Effects.Value("flowerHeal")*dt);
        }
        foreach(var pool in Pools.ToArray())
        {if(Time.time>=pool.Until){Pools.Remove(pool);continue;}foreach(var enemy in Nearby(pool.Position,3))Deal(enemy,pool.Damage*dt,"pool");}
        SkillCompatibility.TickPickups(player,ref coinScan);
        if(Time.time<pulse)return;
        pulse=Time.time+1;
        Burst(position,Effects.Value("auraDamage"),4,"aura");
        Burst(position,Effects.Value("orbitDamage"),3,"orbit");
        if(Effects.Value("nova")>0)Burst(position,Effects.Value("nova"),6,"nova");
        if(Effects.Value("storm")>0)foreach(var target in Nearby(position,20,3))Deal(target,Effects.Value("storm"),"storm");
        if(Effects.Value("drones")>0)foreach(var target in Nearby(position,15,(int)Math.Clamp(Effects.Value("drones"),0,3)))Deal(target,Effects.Value("damage"),"drone");
        if(Effects.Value("interest")>0)inv.gold+=inv.gold*Math.Clamp(Effects.Value("interest"),0,.08f)/60;
        if(Effects.Value("magnetPulse")>0)inv.statInventory.ChangeMovingStat("wf:magnet",new Assets.Scripts.Inventory__Items__Pickups.Stats.StatModifier {stat=Assets.Scripts.Menu.Shop.EStat.PickupRange,modification=Effects.Value("magnetPulse"),modifyType=Assets.Scripts.Inventory__Items__Pickups.Stats.EStatModifyType.Flat});
    }
    private static void OwnInvincibility(MyPlayer player){if(!player.isInvincible){player.isInvincible=true;ownsInvincibility=true;}}
    internal static void PollInput(MyPlayer player)
    {
        if(player?.playerMovement?.rb==null||GameManager.Instance?.isPlaying!=true||Time.timeScale<=0||player.playerMovement.frozen||player.inventory.playerHealth.IsDead())return;
        var movement=player.playerMovement;
        if(Input.GetKeyDown(KeyCode.LeftShift)||Input.GetKeyDown(KeyCode.RightShift)||Input.GetMouseButtonDown(1))TryDash(player);
        if(Input.GetKeyDown(KeyCode.R))TryDeploy(player);
        if(!movement.grounded&&Input.GetKeyDown(KeyCode.LeftControl)){slamming=true;Presentation.Sound("slam");var v=movement.rb.velocity;v.y=-24;movement.rb.velocity=v;}
    }
    internal static bool TryDash(MyPlayer player)
    {
        if(Time.time<nextDash||player?.playerMovement?.rb==null)return false;
        nextDash=Time.time+Math.Max(.6f,Effects.Value("dashCooldown"));dashUntil=Time.time+.25f;Effects.DashedAt=Time.time;
        var direction=player.playerMovement.GetWishDir();if(direction.sqrMagnitude<.01f)direction=player.playerMovement.orientation.forward;direction.y=0;
        dashDirection=direction.normalized;ApplyDash(player.playerMovement);OwnInvincibility(player);
        Presentation.Sound("dash");Presentation.Pulse(player.feet.position,Color.cyan,1.2f);return true;
    }
    internal static void ApplyDash(PlayerMovement movement)
    {
        if(MyPlayer.Instance?.playerMovement?.Pointer!=movement.Pointer||Time.time>=dashUntil)return;
        var v=movement.rb.velocity;float speed=Math.Max(24,movement.currentMaxSpeed*2.5f);
        movement.rb.velocity=new Vector3(dashDirection.x*speed,v.y,dashDirection.z*speed);
    }
    private static Entry FindTurret(MyPlayer player)
    {
        if(player?.inventory?.weaponInventory==null)return null;
        foreach(var pair in player.inventory.weaponInventory.weapons)if(Catalog.WeaponsById.TryGetValue((int)pair.Key,out var entry)&&entry.Turret)return entry;
        if(Catalog.HeroesById.TryGetValue((int)player.inventory.characterData.eCharacter,out var hero)&&hero.TurretType!=null)return Catalog.Data.Weapons.First(w=>w.Id=="turret");
        return null;
    }
    internal static bool TryDeploy(MyPlayer player)
    {
        var weapon=FindTurret(player);
        if(weapon==null){Presentation.Notify("Equip a turret weapon, then press R to deploy");return false;}
        if(Time.time<nextTurret)return false;nextTurret=Time.time+1;
        int max=Math.Clamp((int)Effects.Value("turretCount"),1,4);
        while(Turrets.Count>=max){var old=Turrets[0];if(old.Model!=null)UObject.Destroy(old.Model);Turrets.RemoveAt(0);}
        var model=Presentation.Model(weapon);var forward=player.playerMovement.orientation.forward;forward.y=0;
        model.transform.position=player.feet.position+forward.normalized*2;
        Turrets.Add(new Turret {Model=model,Position=model.transform.position,Weapon=weapon,Born=Time.time});
        Presentation.Sound("deploy");Presentation.Pulse(model.transform.position,Color.yellow,1);Presentation.Notify("Turret deployed — lasts "+Effects.Value("turretLife").ToString("0")+"s");return true;
    }
    private static float WeaponPower(Entry entry)
    {var inv=MyPlayer.Instance?.inventory;if(inv?.weaponInventory!=null&&inv.weaponInventory.weapons.TryGetValue((EWeapon)entry.RuntimeId,out var weapon))return Math.Max(1,WeaponUtility.GetDamage(weapon));return Effects.Value("damage")*entry.Damage;}
}

[HarmonyPatch(typeof(PlayerMovement),nameof(PlayerMovement.MovementTick))]
internal static class WildforgeDashMovement {private static void Postfix(PlayerMovement __instance)=>CombatEffects.ApplyDash(__instance);}

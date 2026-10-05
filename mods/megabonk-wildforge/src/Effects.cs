using UnityEngine;
using HarmonyLib;
using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups.Stats;
using Assets.Scripts.Menu.Shop;
using Assets.Scripts.Managers;

namespace Wildforge.Megabonk;

// Catalog amounts remain source data. Native stats are supplied as reversible
// moving modifiers; special combat/movement/economy effects share this state.
internal static class Effects
{
    internal static readonly Dictionary<string,EStat> NativeStats=new()
    {
        ["damage"]=EStat.DamageMultiplier,["rate"]=EStat.AttackSpeed,["speed"]=EStat.MoveSpeedMultiplier,
        ["maxHp"]=EStat.MaxHealth,["armor"]=EStat.Armor,["regen"]=EStat.HealthRegen,["shield"]=EStat.Shield,
        ["thorns"]=EStat.Thorns,["dodge"]=EStat.Evasion,["crit"]=EStat.CritChance,["critPower"]=EStat.CritDamage,
        ["size"]=EStat.SizeMultiplier,["range"]=EStat.DurationMultiplier,["projectileSpeed"]=EStat.ProjectileSpeedMultiplier,
        ["knockback"]=EStat.KnockbackMultiplier,["multishot"]=EStat.Projectiles,["ricochet"]=EStat.ProjectileBounces,
        ["xpGain"]=EStat.XpIncreaseMultiplier,["goldGain"]=EStat.GoldIncreaseMultiplier,["chestBonus"]=EStat.ChestIncreaseMultiplier,
        ["pickup"]=EStat.PickupRange,["luck"]=EStat.Luck,["jumpHeight"]=EStat.JumpHeight,["airJumps"]=EStat.ExtraJumps,
        ["fallGuard"]=EStat.FallDamageReduction,["slamPower"]=EStat.Slam,["potionDuration"]=EStat.EffectDurationMultiplier,
        ["potionPower"]=EStat.PowerupBoostMultiplier,["potionChance"]=EStat.PowerupChance
    };
    private static readonly HashSet<string> Ratios=new(){"damage","rate","speed","maxHp","critPower","size","range","projectileSpeed","xpGain","goldGain","pickup","jumpHeight","slamPower","potionDuration","potionPower","coinRadius"};
    private static readonly Dictionary<string,float> Caps=new()
    {
        ["airJumps"]=8,["keyPower"]=.75f,["fallGuard"]=.95f,["jumpHeight"]=5,["slamRadius"]=4,["bounceJump"]=2,["flowerSeeds"]=2,["flowerRoots"]=.7f,
        ["rate"]=18,["speed"]=18,["maxHp"]=5000,["damage"]=3000,["dodge"]=.65f,["lifesteal"]=.4f,["crit"]=.85f,["freeze"]=.65f,["blind"]=.65f,
        ["discount"]=.6f,["multishot"]=7,["chain"]=8,["pierce"]=12,["turretCount"]=4,["drones"]=3,["interest"]=.08f,["ghost"]=2,["pickup"]=20,["coinRadius"]=22,
        ["regen"]=40,["revive"]=4,["discBounces"]=8,["boomerangPierce"]=12,["harpoonPull"]=3,["gravitySize"]=4,["hornStun"]=3,["bubbleTime"]=4,
        ["meteorCount"]=5,["bombSize"]=4,["airDamage"]=3,["landingHeal"]=50,["slamHeal"]=50,["airControl"]=.5f,["fallThreshold"]=20,["potionDuration"]=4,
        ["potionPower"]=3,["potionChance"]=.6f,["jumpShield"]=100,["jumpBlast"]=200,["slamFire"]=100,["slamPoison"]=100,["coinHeal"]=20,["chestHeal"]=200,
        ["size"]=2.5f,["knockback"]=3,["slow"]=.7f,["banana"]=.6f
    };
    internal static readonly Dictionary<string,float> Values=new();
    private static readonly Dictionary<string,float> Applied=new();
    private static readonly Dictionary<string,(float Amount,string Mode)> Conditional=new();
    internal static bool Active;
    internal static Func<string,bool> ConditionOverride;
    private static IntPtr inventoryPointer;
    private static float nextTick;
    internal static float KilledAt=-100,HurtAt=-100,SlamAt=-100,DashedAt=-100;
    internal static bool ExtraDamage;
    internal static float Value(string key)=>Values.GetValueOrDefault(key,Catalog.Data?.Stats.GetValueOrDefault(key,0)??0);
    internal static float Bonus(string key)=>Value(key)-(Catalog.Data?.Stats.GetValueOrDefault(key,0)??0);
    internal static bool IsRatio(string key)=>Ratios.Contains(key);
    internal static void Tick(bool force=false)
    {
        var player=MyPlayer.Instance;
        var inv=player?.inventory;
        if(Catalog.Data==null||inv?.statInventory==null) return;
        if(!force&&Time.time<nextTick) return;
        nextTick=Time.time+.15f;
        if(inventoryPointer!=inv.Pointer){inventoryPointer=inv.Pointer;Applied.Clear();CombatEffects.Reset();}
        Values.Clear();Conditional.Clear(); foreach(var pair in Catalog.Data.Stats) if(!pair.Key.StartsWith("augment-")) Values[pair.Key]=pair.Value;
        bool hasContent=false;
        if(Catalog.HeroesById.TryGetValue((int)inv.characterData.eCharacter,out var hero)) {Apply(hero.Effects,1);hasContent=true;}
        foreach(var pair in inv.itemInventory.items)
            if(Catalog.CardsById.TryGetValue((int)pair.Key,out var card)) {Apply(card.Effects,pair.Value.amount);hasContent=true;}
        foreach(var pair in Conditional)Values[pair.Key]=pair.Value.Mode=="multiply"?Values.GetValueOrDefault(pair.Key)* (1+pair.Value.Amount):Values.GetValueOrDefault(pair.Key)+pair.Value.Amount;
        Active=hasContent;
        foreach(var cap in Caps) if(Values.ContainsKey(cap.Key)) Values[cap.Key]=Math.Min(Values[cap.Key],cap.Value);
        bool dirty=false;
        foreach(var pair in NativeStats)
        {
            string key="wf:"+pair.Key;
            float baseline=Catalog.Data.Stats.GetValueOrDefault(pair.Key,0);
            float modifier=Ratios.Contains(pair.Key)&&baseline!=0?Value(pair.Key)/baseline-1:Value(pair.Key)-baseline;
            if(pair.Key=="regen")modifier*=60; // Megabonk expresses regeneration per minute.
            if(!hasContent) modifier=0;
            if(Applied.TryGetValue(key,out var previous)&&Math.Abs(previous-modifier)<.00001f) continue;
            if(Math.Abs(modifier)<.00001f) inv.statInventory.RemoveMovingStat(key);
            else inv.statInventory.ChangeMovingStat(key,new StatModifier {stat=pair.Value,modifyType=Ratios.Contains(pair.Key)?EStatModifyType.Multiplication:EStatModifyType.Flat,modification=Ratios.Contains(pair.Key)?1+modifier:modifier});
            Applied[key]=modifier;
            dirty=true;
        }
        dirty|=SetSpecial(inv,"discount",EStat.ChestPriceMultiplier,-Math.Clamp(Value("discount"),0,.6f),EStatModifyType.Multiplication);
        dirty|=SetSpecial(inv,"airControl",EStat.MoveSpeedMultiplier,player.playerMovement?.grounded==false?Bonus("airControl"):0,EStatModifyType.Multiplication);
        if(dirty)
        {
            inv.playerStats.ForceUpdateStats();inv.statInventory.Tick();inv.playerStats.TryPopStatUpdatesQueue();
            // Existing weapons cache their stats. A card must update attacks already equipped.
            foreach(var weapon in inv.weaponInventory.weapons)
                foreach(var stat in NativeStats.Values.Distinct())if(weapon.Value.weaponStats.ContainsKey(stat))weapon.Value.UpdateStat(stat);
        }
        if(GameManager.Instance?.isPlaying==true) CombatEffects.Tick(player,.15f);
    }
    private static bool SetSpecial(PlayerInventory inv,string name,EStat stat,float value,EStatModifyType mode)
    {
        string key="wf:"+name;
        if(Applied.TryGetValue(key,out var old)&&Math.Abs(old-value)<.00001f)return false;
        if(value==0)inv.statInventory.RemoveMovingStat(key);else inv.statInventory.ChangeMovingStat(key,new StatModifier {stat=stat,modification=mode==EStatModifyType.Multiplication?1+value:value,modifyType=mode});
        Applied[key]=value;
        return true;
    }
    private static void Apply(IEnumerable<EffectDef> effects,int count)
    {
        foreach(var effect in effects)
        {
            string key=effect.Key,mode=effect.Mode;
            if(Catalog.Data.Augments.TryGetValue(key,out var augment))
            {
                if(!Condition(augment.Condition))continue;
                var prior=Conditional.GetValueOrDefault(augment.Stat);
                Conditional[augment.Stat]=(prior.Amount+effect.Amount*count,augment.Mode);continue;
            }
            float old=Values.GetValueOrDefault(key,0);
            Values[key]=mode=="multiply"?old*MathF.Pow(1+effect.Amount,count):old+effect.Amount*count;
        }
    }
    internal static bool Condition(string name)
    {
        if(ConditionOverride!=null)return ConditionOverride(name);
        var player=MyPlayer.Instance; if(player?.inventory==null)return false;
        var movement=player.playerMovement; var health=player.inventory.playerHealth;
        var velocity=movement?.rb?.velocity??Vector3.zero;
        float horizontal=new Vector2(velocity.x,velocity.z).magnitude;
        float hp=(float)health.hp/Math.Max(1,health.maxHp);
        var enemies=CombatEffects.Enemies();var position=player.transform.position;
        return name switch
        {
            "air"=>movement?.grounded==false,"ground"=>movement?.grounded==true,"moving"=>horizontal>1,"still"=>horizontal<.5f,
            "low"=>hp<.4f,"healthy"=>hp>.8f,"shield"=>health.shield>0,"bare"=>health.shield<=0,
            "dash"=>Time.time-DashedAt<3||movement?.isDashing==true,"slam"=>Time.time-SlamAt<4,"kill"=>Time.time-KilledAt<3,"hurt"=>Time.time-HurtAt<4,
            "boss"=>enemies.Any(e=>CombatEffects.IsBoss(e)&&(e.transform.position-position).sqrMagnitude<625),
            "alone"=>!enemies.Any(e=>(e.transform.position-position).sqrMagnitude<64),"crowd"=>enemies.Count(e=>(e.transform.position-position).sqrMagnitude<144)>=4,
            "flower"=>CombatEffects.NearFlower(position),"turret"=>CombatEffects.NearTurret(position),"rich"=>player.inventory.gold>=50,_=>false
        };
    }
}

[HarmonyPatch(typeof(UpgradePicker),nameof(UpgradePicker.ShuffleUpgrades))]
internal static class WildforgeCardsInLevelups
{
    private static void Postfix(UpgradePicker __instance)
    {
        if(Catalog.Data==null||__instance.buttons==null)return;
        var chosen=new HashSet<int>();
        for(int slot=1;slot<__instance.buttons.Length;slot+=2)
        {
            float luck=MyPlayer.Instance?.inventory?.playerStats.GetStat(EStat.Luck)??0;
            float roll=UnityEngine.Random.value+Math.Min(luck,.75f)*.18f;
            int rarity=roll>.987f?3:roll>.91f?2:roll>.66f?1:0;
            var pool=Catalog.Data.Cards.Where(c=>c.Kind=="skill"&&c.Rarity==rarity).ToArray();
            if(pool.Length==0)pool=Catalog.Data.Cards.Where(c=>c.Kind=="skill").ToArray();
            var card=pool[UnityEngine.Random.Range(0,pool.Length)];
            if(!chosen.Add(card.RuntimeId))continue;
            __instance.buttons[slot].SetItem(DataManager.Instance.itemData[(Assets.Scripts.Inventory__Items__Pickups.Items.EItem)card.RuntimeId]);
        }
    }
}
[HarmonyPatch(typeof(UpgradeButton),nameof(UpgradeButton.SetItem))]
internal static class WildforgeCardPresentation
{
    private static void Postfix(UpgradeButton __instance,ItemData itemData)
    {
        if(!Catalog.CardsById.TryGetValue((int)itemData.eItem,out var card))return;
        __instance.t_name.text=card.Title??card.Name;
        __instance.t_description.text=Catalog.Describe(card);
        __instance.icon.texture=FullCatalog.Icon(card.Portrait);
    }
}

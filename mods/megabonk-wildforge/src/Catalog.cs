using System.Text.Json;

namespace Wildforge.Megabonk;

internal sealed class EffectDef
{
    public string Key { get; set; }
    public float Amount { get; set; }
    public string Mode { get; set; } = "add";
}
internal sealed class Entry
{
    public string Id { get; set; }
    public string Name { get; set; }
    public string Title { get; set; }
    public string Description { get; set; }
    public string Family { get; set; }
    public string Kind { get; set; }
    public int Rarity { get; set; }
    public string Asset { get; set; }
    public string Portrait { get; set; }
    public string Weapon { get; set; }
    public string Perk { get; set; }
    public int RuntimeId { get; set; }
    public List<EffectDef> Effects { get; set; } = new();
    public float Damage { get; set; } = 1;
    public float Rate { get; set; } = 1;
    public float Range { get; set; }
    public bool Turret { get; set; }
    public string TurretType { get; set; }
    public string Archetype { get; set; }
    public Dictionary<string,JsonElement> Modifiers { get; set; }=new();
    public int Biome { get; set; }
    public int Species { get; set; }
    public float Health { get; set; } = 1;
    public float Speed { get; set; } = 1;
    public float Height { get; set; }
    public float Radius { get; set; }
    public int Weight { get; set; }
    public string Behavior { get; set; }
    public bool Flying { get; set; }
    public bool Boss { get; set; }
    public int Realm { get; set; }
}
internal sealed class AugmentDef
{
    public string Condition { get; set; }
    public string Stat { get; set; }
    public string Mode { get; set; }
    public string When { get; set; }
    public string Label { get; set; }
}
internal sealed class Catalog
{
    public List<Entry> Heroes { get; set; }
    public List<Entry> Cards { get; set; }
    public List<Entry> Weapons { get; set; }
    public List<Entry> Enemies { get; set; }
    public Dictionary<string,AugmentDef> Augments { get; set; }
    public Dictionary<string,float> Stats { get; set; }
    public Dictionary<string,string> Labels { get; set; }
    public List<string> Icons { get; set; }
    internal static Catalog Data;
    internal static readonly Dictionary<int,Entry> HeroesById = new(), CardsById = new(), WeaponsById = new(), EnemiesById = new();
    internal static void Load()
    {
        if (Data != null) return;
        Data = JsonSerializer.Deserialize<Catalog>(File.ReadAllText(Path.Combine(Plugin.AssetDirectory,"wildforge-catalog.json")),new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
        foreach(var e in Data.Heroes) HeroesById.Add(e.RuntimeId,e);
        foreach(var e in Data.Cards) CardsById.Add(e.RuntimeId,e);
        foreach(var e in Data.Weapons) WeaponsById.Add(e.RuntimeId,e);
        foreach(var e in Data.Enemies) EnemiesById.Add(e.RuntimeId,e);
    }
    internal static string Describe(Entry entry)
    {
        if(entry.Effects.Count==0&&WeaponsById.ContainsKey(entry.RuntimeId)&&entry.Kind==null)
        {
            if(entry.Turret)return $"Press R to deploy this turret in front of you. It aims and fires automatically for {Data.Stats["turretLife"]:0}s. Turret cards improve damage, rate, range and capacity.";
            if(entry.Id=="flowers")return "Grow damaging flowers where you walk. Nearby enemies are slowed and poisoned. Bloom cards improve flower damage, healing and seed rate.";
            string native=FullCatalog.WeaponArchetypes.TryGetValue((EWeapon)entry.RuntimeId,out var id)?id.ToString():"weapon";
            return $"Uses {native} attacks. Damage x{entry.Damage:0.##}; attack rate x{entry.Rate:0.##}. Weapon and skill cards stack with Megabonk upgrades.";
        }
        if(entry.Effects.Count==0)return entry.Description??"Original Wildforge content.";
        return string.Join("\n",entry.Effects.Select(e =>
        {
            string key=e.Key;
            string when = "";
            string mode = e.Mode;
            if (Data.Augments.TryGetValue(key,out var augment)) { key=augment.Stat;when=" "+augment.When;mode=augment.Mode; }
            string label=key switch
            {
                "damage"=>"weapon damage","rate"=>"attack speed","speed"=>"movement speed","crit"=>"critical hit chance","critPower"=>"critical damage",
                "maxHp"=>"maximum health","regen"=>"health regenerated per second","range"=>"attack duration","projectileSpeed"=>"projectile speed",
                "lifesteal"=>"damage healed on hit","dodge"=>"evasion chance","multishot"=>"extra projectiles","ricochet" or "discBounces"=>"projectile bounces",
                "turretCount"=>"deployed turret capacity (maximum 4)","turretLife"=>"turret lifetime (seconds)","dashCooldown"=>"dash cooldown (seconds)",
                "flowerPower"=>"flower damage","flowerSeeds"=>"flower planting speed","flowerHeal"=>"healing per second near flowers",
                "slow" or "flowerRoots"=>"enemy movement slowed on hit","poison" or "flowerPollen"=>"poison damage","burn"=>"burn damage",
                "chain"=>"nearby targets hit by chain damage","pierce" or "boomerangPierce"=>"extra targets pierced","splash"=>"splash strength",
                "freeze"=>"freeze chance on hit","stun"=>"stun chance on hit","salvage"=>"chance to heal 4 HP on kill",
                "coinHeal"=>"health restored per gold picked up","chestHeal"=>"health restored on opening a chest","repair"=>"healing per second near a turret",
                "ghost"=>"extra dash protection (seconds)","execute"=>"low-health enemy execution threshold","airDamage"=>"damage while airborne",
                _=>Data.Labels.GetValueOrDefault(key,key)
            };
            bool percent=mode=="multiply"||key is "crit" or "dodge" or "freeze" or "lifesteal" or "luck" or "discount" or "keyPower" or "slow" or "flowerRoots" or "stun" or "salvage" or "execute" or "fallGuard" or "potionChance" or "airDamage" or "banana" or "blind" or "berserk";
            float amount=percent?e.Amount*100:e.Amount;
            if(mode!="multiply"&&Effects.IsRatio(key)&&Data.Stats.GetValueOrDefault(key)>0){percent=true;amount=e.Amount/Data.Stats[key]*100;}
            string sign=amount<0?"−":"+";
            return $"{sign}{Math.Abs(amount):0.##}{(percent?"%":"")} {label}{when} per stack";
        }));
    }
}

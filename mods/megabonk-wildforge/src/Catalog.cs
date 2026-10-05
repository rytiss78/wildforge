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
        if (!string.IsNullOrEmpty(entry.Description)) return entry.Description;
        if (entry.Effects.Count == 0) return entry.Family + " weapon from Wildforge.";
        return string.Join("\n",entry.Effects.Select(e =>
        {
            string label = Data.Labels.GetValueOrDefault(e.Key,e.Key);
            string when = "";
            string mode = e.Mode;
            if (Data.Augments.TryGetValue(e.Key,out var augment)) { label=augment.Label; when=" "+augment.When; mode=augment.Mode; }
            bool percent=mode=="multiply" || e.Key is "crit" or "dodge" or "freeze" or "lifesteal" or "luck" or "discount" or "keyPower";
            return $"+{(percent?e.Amount*100:e.Amount):0.##}{(percent?"%":"")} {label}{when} per stack";
        }));
    }
}

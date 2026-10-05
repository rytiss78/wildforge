using Assets.Scripts.Actors.Player;
using Assets.Scripts.Inventory__Items__Pickups.Items;
using Assets.Scripts.Menu.Shop;

namespace Wildforge.Megabonk;

internal static class SkillSmoke
{
    internal static void AllSkills(MyPlayer player)
    {
        int count=0;
        Effects.ConditionOverride=_=>true;
        try
        {
            foreach(var card in Catalog.Data.Cards.Where(c=>c.Kind=="skill"))
            {
                Effects.Tick(true);
                var before=new Dictionary<string,float>(Effects.Values);
                var id=(EItem)card.RuntimeId;
                int old=player.inventory.itemInventory.GetAmount(id);
                player.inventory.itemInventory.AddItem(id,2);Effects.Tick(true);
                if(player.inventory.itemInventory.GetAmount(id)!=old+2)throw new InvalidOperationException("Skill cannot stack: "+card.Id);
                foreach(var effect in card.Effects)
                {
                    string key=Catalog.Data.Augments.TryGetValue(effect.Key,out var augment)?augment.Stat:effect.Key;
                    if(effect.Amount>0&&Effects.Value(key)<=before.GetValueOrDefault(key))throw new InvalidOperationException("Skill effect does not resolve: "+card.Id+" / "+key);
                }
                for(int i=0;i<2&&player.inventory.itemInventory.GetAmount(id)>old;i++)player.inventory.itemInventory.RemoveItem(id,false);
                Effects.Tick(true);
                if(player.inventory.itemInventory.GetAmount(id)!=old)throw new InvalidOperationException("Skill cannot be removed: "+card.Id);
                foreach(var effect in card.Effects)
                {
                    string key=Catalog.Data.Augments.TryGetValue(effect.Key,out var augment)?augment.Stat:effect.Key;
                    if(Math.Abs(Effects.Value(key)-before.GetValueOrDefault(key))>.001f)throw new InvalidOperationException("Skill modifier leaked after removal: "+card.Id);
                }
                count++;
            }
            var conditional=Catalog.Data.Cards.First(c=>c.Effects.Any(e=>e.Key=="augment-ground-damage"));
            var item=(EItem)conditional.RuntimeId;
            Effects.ConditionOverride=_=>false;Effects.Tick(true);float inactive=Effects.Value("damage");
            player.inventory.itemInventory.AddItem(item,2);Effects.Tick(true);
            if(Math.Abs(Effects.Value("damage")-inactive)>.001f)throw new InvalidOperationException("Inactive conditional skill applied.");
            Effects.ConditionOverride=_=>true;Effects.Tick(true);
            float amount=conditional.Effects.First(e=>e.Key=="augment-ground-damage").Amount;
            if(Math.Abs(Effects.Value("damage")-inactive*(1+2*amount))>.001f)throw new InvalidOperationException("Conditional stacks differ from source sum.");
            player.inventory.itemInventory.RemoveItem(item,false);player.inventory.itemInventory.RemoveItem(item,false);
        }
        finally {Effects.ConditionOverride=null;Effects.Tick(true);}
        var original=player.inventory;
        var native=new PlayerInventory(DataManager.Instance.characterData[ECharacter.Bandit],false);
        try
        {
            player.inventory=native;Effects.Tick(true);
            var rateCard=Catalog.Data.Cards.First(c=>c.Kind=="skill"&&c.Effects.Any(e=>e.Key=="rate"));
            float before=native.playerStats.GetStat(EStat.AttackSpeed);
            native.itemInventory.AddItem((EItem)rateCard.RuntimeId,2);Effects.Tick(true);
            if(native.playerStats.GetStat(EStat.AttackSpeed)<=before)throw new InvalidOperationException("Wildforge skill does not apply to Megabonk hero.");
        }
        finally {player.inventory=original;native.Cleanup();Effects.Tick(true);}
        Plugin.Logger.LogInfo($"SKILLS PASS: all {count} skill cards acquired, stacked, resolved and removed; conditional activation and native hero compatibility passed.");
    }
}

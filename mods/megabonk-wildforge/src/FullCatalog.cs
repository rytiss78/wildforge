using UnityEngine;
using Assets.Scripts.Inventory__Items__Pickups.AbilitiesPassive;
using Assets.Scripts.Inventory__Items__Pickups.Items;
using Assets.Scripts.Inventory__Items__Pickups.Stats;
using Assets.Scripts.Menu.Shop;
using Assets.Scripts._Data.MapsAndStages;
using Actors.Enemies;
using UObject=UnityEngine.Object;

namespace Wildforge.Megabonk;

internal static class FullCatalog
{
    internal static readonly Dictionary<string,Texture2D> Icons = new();
    internal static readonly Dictionary<IntPtr,Entry> Passives = new();
    internal static readonly Dictionary<EWeapon,EWeapon> WeaponArchetypes = new();
    internal static Texture2D Icon(string path)
    {
        if(!Icons.TryGetValue(path,out var texture)) Icons[path]=texture=TextureLoader.Load(Path.Combine(Plugin.AssetDirectory,path.Replace('/',Path.DirectorySeparatorChar)));
        return texture;
    }
    internal static void Register(DataManager manager)
    {
        Catalog.Load();
        foreach(var entry in Catalog.Data.Weapons)
        {
            var id=(EWeapon)entry.RuntimeId;
            if(manager.weapons.ContainsKey(id)) continue;
            var archetype=WeaponArchetype(entry);
            if(!manager.weapons.ContainsKey(archetype)) archetype=EWeapon.Revolver;
            var source=manager.weapons[archetype];
            var weapon=UObject.Instantiate(source);
            Content.Setup(weapon,entry.Name);
            weapon.eWeapon=id; weapon.icon=Icon(entry.Portrait); weapon.AchievementRequirement=null;
            weapon.damageSourceName="wildforge_weapon_"+entry.Id;
            weapon.baseStats=new Il2CppSystem.Collections.Generic.Dictionary<EStat,float>();
            foreach(var pair in source.baseStats) weapon.baseStats.Add(pair.Key,pair.Value);
            // Source values are factors of Wildforge's base damage and shots/sec,
            // not factors of the level-one native template's much weaker defaults.
            weapon.baseStats[EStat.DamageMultiplier]=Catalog.Data.Stats["damage"]*entry.Damage;
            weapon.baseStats[EStat.AttackSpeed]=Catalog.Data.Stats["rate"]*entry.Rate;
            void Modify(string key,EStat stat,bool multiplier=false)
            {
                if(!entry.Modifiers.TryGetValue(key,out var value)||value.ValueKind!=System.Text.Json.JsonValueKind.Number)return;
                float amount=value.GetSingle();
                if(weapon.baseStats.ContainsKey(stat)) weapon.baseStats[stat]=multiplier?weapon.baseStats[stat]*amount:weapon.baseStats[stat]+amount;
                else weapon.baseStats[stat]=multiplier?amount:amount;
            }
            Modify("extraShots",EStat.Projectiles);Modify("extraBounce",EStat.ProjectileBounces);Modify("shotScale",EStat.SizeMultiplier,true);
            Modify("areaScale",EStat.SizeMultiplier,true);Modify("durationScale",EStat.DurationMultiplier,true);Modify("extraMeteors",EStat.Projectiles);
            manager.weapons.Add(id,weapon); manager.unsortedWeapons.Add(weapon); manager.unsortedUnlockables.Add(weapon);
            EffectManager.weaponNamesCache[id]=weapon.damageSourceName;
            WeaponArchetypes[id]=archetype;
        }
        foreach(var entry in Catalog.Data.Heroes)
        {
            var id=(ECharacter)entry.RuntimeId;
            if(manager.characterData.ContainsKey(id)) continue;
            var hero=UObject.Instantiate(manager.characterData[ECharacter.Bandit]);
            Content.Setup(hero,entry.Name);
            hero.eCharacter=id; hero.icon=Icon(entry.Portrait);
            hero.weapon=manager.weapons[(EWeapon)Catalog.Data.Weapons.First(w=>w.Id==entry.Weapon).RuntimeId];
            hero.achievementRequirement=null; hero.numQuestsRequiredForVisibilityInCharacterSelection=0;
            hero.statModifiers=new Il2CppSystem.Collections.Generic.List<StatModifier>();
            hero.passive=UObject.Instantiate(manager.characterData[ECharacter.Bandit].passive);
            hero.passive.name=entry.Perk; hero.passive.ePassive=EPassive.None; hero.passive.icon=hero.icon;
            UObject.DontDestroyOnLoad(hero.passive); Passives[hero.passive.Pointer]=entry;
            manager.characterData.Add(id,hero); manager.unsortedCharacterData.Add(hero); manager.unsortedUnlockables.Add(hero);
            var skin=UObject.Instantiate(manager.GetSkin(ECharacter.Bandit,0));
            Content.Setup(skin,entry.Name+" Default"); skin.character=id; skin.icon=hero.icon; skin.unlockRequirement=null;
            var skins=new Il2CppSystem.Collections.Generic.List<SkinData>(); skins.Add(skin); manager.skinData.Add(id,skins);
            manager.unsortedSkins.Add(skin);
        }
        foreach(var entry in Catalog.Data.Cards)
        {
            var id=(EItem)entry.RuntimeId;
            if(manager.itemData.ContainsKey(id)) continue;
            var item=UObject.Instantiate(manager.itemData[EItem.Clover]);
            Content.Setup(item,entry.Name); item.eItem=id; item.icon=Icon(entry.Portrait); item.inItemPool=true;
            item.rarity=(EItemRarity)entry.Rarity;
            item.unlockRequirement=null; item.maxAmount=int.MaxValue; item.maxAmountPerRun=int.MaxValue;
            item.dummyItem=Content.MakeItem(id,new ItemInventory());
            manager.itemData.Add(id,item); manager.unsortedItems.Add(item); manager.unsortedUnlockables.Add(item);
        }
        foreach(var entry in Catalog.Data.Enemies)
        {
            var id=(EEnemy)entry.RuntimeId;
            if(manager.enemyData.ContainsKey(id)) continue;
            var native=entry.Behavior switch { "boss"=>EEnemy.MinibossGolem,"armored"=>EEnemy.ArmoredSkeleton,"spit"=>EEnemy.CactusShooter,"skitter"=>EEnemy.Goblin,_=>entry.Flying?EEnemy.Ghost:EEnemy.Skeleton };
            if(!manager.enemyData.ContainsKey(native)) native=EEnemy.Skeleton;
            var source=manager.enemyData[native];
            var data=UObject.Instantiate(source); data.name=entry.Name; data.enemyName=id;
            data.hp=entry.Boss?(int)entry.Health:Math.Max(1,(int)(source.hp*entry.Health)); data.damage=Math.Max(1,(int)(source.damage*entry.Damage));
            data.speed=source.speed*entry.Speed; data.isFlying=entry.Flying;
            data.overrideHeight=entry.Height; data.colliderRadius=entry.Radius; data.colliderCenter=Vector3.up*(entry.Height*.5f);
            data.canBeElite=!entry.Boss; data.minStage=entry.Boss?1000:0; data.canSpawnAfterTime=entry.Boss?float.MaxValue:0;
            data.maps=EMap.Forest|EMap.Desert|EMap.Graveyard|EMap.Hell;
            data.creditCost=Math.Max(.1f,source.creditCost*entry.Health);
            UObject.DontDestroyOnLoad(data); manager.enemyData.Add(id,data); manager.unsortedEnemies.Add(data);
        }
        Content.Portrait=Icon(Catalog.HeroesById[(int)Content.Duck].Portrait);
        Plugin.Logger.LogInfo($"FULL MERGE registered: {Catalog.Data.Heroes.Count} heroes, {Passives.Count} perks, {Catalog.Data.Cards.Count} cards, {Catalog.Data.Weapons.Count} weapons, {Catalog.Data.Enemies.Count} enemies; {Catalog.Data.Icons.Count} icon files available.");
    }
    private static EWeapon WeaponArchetype(Entry e)
    {
        string archetype=e.Archetype??e.Id;
        var exact=archetype switch {"gun"=>EWeapon.Revolver,"shotgun"=>EWeapon.Shotgun,"rail"=>EWeapon.Sniper,"flame"=>EWeapon.DragonsBreath,"poison"=>EWeapon.PoisonFlask,"ice"=>EWeapon.Frostwalker,"lightning"=>EWeapon.LightningStaff,"saw"=>EWeapon.Scythe,"rocket"=>EWeapon.Rockets,"boomerang"=>EWeapon.Bananarang,"disc"=>EWeapon.BluetoothDagger,"harpoon"=>EWeapon.Bow,"gravity"=>EWeapon.BlackHole,"horn"=>EWeapon.Tornado,"bubble"=>EWeapon.Frostwalker,"meteor"=>EWeapon.FireStaff,"bomb"=>EWeapon.Mine,_=>EWeapon.None};
        if(exact!=EWeapon.None)return exact;
        if(e.Id.Contains("gravity")||e.Id.Contains("black-hole")||e.Id.Contains("singularity")) return EWeapon.BlackHole;
        if(e.Id.Contains("boomerang")||e.Id.Contains("twister")||e.Id.Contains("hook")) return EWeapon.Bananarang;
        if(e.Id.Contains("bomb")||e.Id.Contains("fuse")||e.Id.Contains("mine")) return EWeapon.Mine;
        if(e.Id.Contains("rail")||e.Id.Contains("needles")||e.Id.Contains("ruler")) return EWeapon.Sniper;
        if(e.Id.Contains("shotgun")||e.Id.Contains("blunderbuss")||e.Id.Contains("confetti")) return EWeapon.Shotgun;
        return e.Family switch {"Garden"=>EWeapon.Flamewalker,"Fire"=>EWeapon.FireStaff,"Poison" or "Toxic"=>EWeapon.PoisonFlask,"Ice" or "Frost"=>EWeapon.Frostwalker,"Lightning" or "Electric"=>EWeapon.LightningStaff,"Thorns"=>EWeapon.Scythe,"Boom" or "Explosives"=>EWeapon.Rockets,"Ghost"=>EWeapon.BloodMagic,"Magic"=>EWeapon.Tornado,"Engineering"=>EWeapon.Revolver,_=>EWeapon.Revolver};
    }
}

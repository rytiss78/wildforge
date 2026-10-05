using HarmonyLib;
using UnityEngine;
using Assets.Scripts.Inventory__Items__Pickups.AbilitiesPassive;
using Assets.Scripts.Inventory__Items__Pickups.Items;
using Assets.Scripts.Inventory__Items__Pickups.Items.ItemImplementations;
using Assets.Scripts.Inventory__Items__Pickups.Stats;
using Assets.Scripts.Saves___Serialization.Progression.Achievements;
using Assets.Scripts.Saves___Serialization.Progression.Unlocks;
using Assets.Scripts.Menu.Shop;
using UObject = UnityEngine.Object;

namespace Wildforge.Megabonk;

internal static class Content
{
    internal const string Author = "Wildforge";
    internal const ECharacter Duck = (ECharacter)87001;
    internal const EWeapon Gun = (EWeapon)87001;
    internal const EItem Fang = (EItem)87001, Clover = (EItem)87002, Boots = (EItem)87003;
    internal static readonly Dictionary<string, string> Descriptions = new()
    {
        ["Count Duck"] = "A very normal duck. Blood Bank heals for 8% of actual weapon damage dealt.",
        ["Breadcrumb Blaster"] = "Count Duck's gun. Fires a quick volley of extremely unfriendly breadcrumbs.",
        ["Questionable Fang"] = "Heal for 2.5% of actual weapon damage dealt per stack.",
        ["Clover Sandwich"] = "+14% luck per stack. Do not ask what is inside.",
        ["Emergency Boots"] = "+12% movement speed per stack. For urgent waddling.",
        ["Count Duck Default"] = "Count Duck's original Wildforge appearance.",
    };
    internal static bool IsOurs(UnlockableBase data) => data != null && data.author == Author;
    internal static bool IsItem(EItem item) => Catalog.CardsById.ContainsKey((int)item);
    internal static Texture2D Portrait;

    internal static void Register(DataManager manager) => FullCatalog.Register(manager);

    internal static void Setup(UnlockableBase data, string name)
    {
        data.name = name;
        data.author = Author;
        data.isEnabled = true;
        data.showInUnlocks = false;
        data.price = 0;
        data.sortingPriority = 1000;
        UObject.DontDestroyOnLoad(data);
    }

    internal static ItemBase MakeItem(EItem id, ItemInventory inventory)
    {
        var item = new ItemClover(inventory) { luckPerAmount = 0f };
        item.damageSource = "wildforge_item_" + (int)id;
        return item;
    }
    internal static bool IsHero(ECharacter id) => Catalog.HeroesById.ContainsKey((int)id);
    internal static string Description(UnlockableBase data)
    {
        var item=data.TryCast<ItemData>();var hero=data.TryCast<CharacterData>();var weapon=data.TryCast<WeaponData>();
        if(item!=null && Catalog.CardsById.TryGetValue((int)item.eItem,out var card)) return Catalog.Describe(card);
        if(hero!=null && Catalog.HeroesById.TryGetValue((int)hero.eCharacter,out var entry)) return Catalog.Describe(entry);
        if(weapon!=null && Catalog.WeaponsById.TryGetValue((int)weapon.eWeapon,out var gun)) return Catalog.Describe(gun);
        return data.name+" from Wildforge.";
    }
    internal static string InternalName(UnlockableBase data)
    {
        var item=data.TryCast<ItemData>();if(item!=null)return "wildforge_card_"+(int)item.eItem;
        var hero=data.TryCast<CharacterData>();if(hero!=null)return "wildforge_hero_"+(int)hero.eCharacter;
        var weapon=data.TryCast<WeaponData>();if(weapon!=null)return "wildforge_weapon_"+(int)weapon.eWeapon;
        var skin=data.TryCast<SkinData>();if(skin!=null)return "wildforge_skin_"+(int)skin.character;
        return "wildforge_"+data.name.ToLowerInvariant().Replace(' ','_');
    }

}

[HarmonyPatch(typeof(DataManager), nameof(DataManager.Load))]
internal static class RegisterContent
{
    private static void Postfix(DataManager __instance)
    {
        try { Content.Register(__instance); }
        catch (Exception ex) { Plugin.Logger.LogError($"Wildforge registration failed: {ex}"); }
    }
}

[HarmonyPatch(typeof(UnlockableBase), nameof(UnlockableBase.GetName))]
internal static class ContentName
{
    private static void Postfix(UnlockableBase __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = __instance.name; }
}

[HarmonyPatch(typeof(UnlockableBase), nameof(UnlockableBase.GetDescription))]
internal static class ContentDescription
{
    private static void Postfix(UnlockableBase __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = Content.Description(__instance); }
}

[HarmonyPatch(typeof(ItemData), nameof(ItemData.GetName))]
internal static class ItemName
{
    private static void Postfix(ItemData __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = __instance.name; }
}

[HarmonyPatch]
internal static class ItemDescription
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        yield return AccessTools.Method(typeof(ItemData), nameof(ItemData.GetDescription));
    }
    private static void Postfix(ItemData __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = Content.Description(__instance); }
}

[HarmonyPatch(typeof(PassiveData), nameof(PassiveData.GetName))]
internal static class PassiveName
{
    private static void Postfix(PassiveData __instance, ref string __result)
    { if (FullCatalog.Passives.TryGetValue(__instance.Pointer,out var hero)) __result = hero.Perk; }
}

[HarmonyPatch(typeof(PassiveData), nameof(PassiveData.GetDescription))]
internal static class PassiveDescription
{
    private static void Postfix(PassiveData __instance, ref string __result)
    { if (FullCatalog.Passives.TryGetValue(__instance.Pointer,out var hero)) __result = Catalog.Describe(hero); }
}

[HarmonyPatch]
internal static class AvailableContent
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        foreach (var name in new[] { nameof(MyAchievements.IsPurchased), nameof(MyAchievements.IsAvailable), nameof(MyAchievements.IsActivated) })
            yield return AccessTools.Method(typeof(MyAchievements), name);
    }
    private static bool Prefix(UnlockableBase unlockable, ref bool __result)
    { if (!Content.IsOurs(unlockable)) return true; __result = true; return false; }
}

[HarmonyPatch(typeof(CharacterData), nameof(CharacterData.IsBlackedOutInCharacterSelectionScreen))]
internal static class DuckVisible
{
    private static bool Prefix(CharacterData __instance, ref bool __result)
    { if (!Content.IsHero(__instance.eCharacter)) return true; __result = false; return false; }
}

[HarmonyPatch(typeof(CharacterData), nameof(CharacterData.GetDisplayRank))]
internal static class DuckRank
{
    private static bool Prefix(CharacterData __instance, ref int __result)
    { if (!Content.IsHero(__instance.eCharacter)) return true; __result = 0; return false; }
}

[HarmonyPatch(typeof(DataManager), nameof(DataManager.GetSkin))]
internal static class DuckSkin
{
    private static bool Prefix(DataManager __instance, ECharacter character, ref SkinData __result)
    { if (!Content.IsHero(character) || !__instance.skinData.ContainsKey(character)) return true; __result = __instance.skinData[character][0]; return false; }
}

[HarmonyPatch(typeof(ItemFactory), nameof(ItemFactory.CreateItem))]
internal static class CustomItemFactory
{
    private static bool Prefix(EItem eItem, ItemInventory inventory, ref ItemBase __result)
    { if (!Content.IsItem(eItem)) return true; __result = Content.MakeItem(eItem, inventory); return false; }
}

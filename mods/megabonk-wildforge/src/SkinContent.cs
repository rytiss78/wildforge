using HarmonyLib;

namespace Wildforge.Megabonk;

[HarmonyPatch(typeof(SkinData), nameof(SkinData.GetPrice))]
internal static class SkinPrice
{
    private static bool Prefix(SkinData __instance, ref int __result)
    { if (!Content.IsOurs(__instance)) return true; __result = 0; return false; }
}
[HarmonyPatch(typeof(SkinData), nameof(SkinData.GetName))]
internal static class SkinName
{
    private static void Postfix(SkinData __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = __instance.name; }
}
[HarmonyPatch(typeof(SkinData), nameof(SkinData.GetDescription))]
internal static class SkinDescription
{
    private static void Postfix(SkinData __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = Content.Description(__instance); }
}
[HarmonyPatch]
internal static class InternalContentName
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        foreach (var type in new[] { typeof(CharacterData), typeof(WeaponData), typeof(ItemData), typeof(SkinData) })
            yield return AccessTools.Method(type, "GetInternalName");
    }
    private static void Postfix(Assets.Scripts.Saves___Serialization.Progression.Achievements.UnlockableBase __instance, ref string __result)
    { if (Content.IsOurs(__instance)) __result = Content.InternalName(__instance); }
}

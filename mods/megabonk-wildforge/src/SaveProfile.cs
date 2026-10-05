using BepInEx;
using HarmonyLib;

namespace Wildforge.Megabonk;

// Custom enum IDs stay inside a separate save profile so disabling the plugin
// never asks unmodded Megabonk to resolve a Wildforge character or reward.
internal static class SaveProfile
{
    internal static readonly string Root = Path.Combine(Paths.ConfigPath, "WildforgeProfile", "Saves");
}
[HarmonyPatch]
internal static class ModSaveRoot
{
    private static IEnumerable<System.Reflection.MethodBase> TargetMethods()
    {
        yield return AccessTools.Method(typeof(SaveManager), nameof(SaveManager.GetDataPath));
        yield return AccessTools.Method(typeof(SaveManager), nameof(SaveManager.GetDataPathDefault));
    }
    private static void Postfix(ref string __result)
    { Directory.CreateDirectory(SaveProfile.Root); __result = SaveProfile.Root; }
}
[HarmonyPatch(typeof(SaveManager), nameof(SaveManager.GetCloudFolder))]
internal static class ModCloudSave
{
    private static void Postfix(ref string __result)
    { __result = Path.Combine(SaveProfile.Root, "CloudDir"); Directory.CreateDirectory(__result); }
}
[HarmonyPatch(typeof(SaveManager), nameof(SaveManager.GetLocalFolder))]
internal static class ModLocalSave
{
    private static void Postfix(ref string __result)
    { __result = Path.Combine(SaveProfile.Root, "LocalDir"); Directory.CreateDirectory(__result); }
}
[HarmonyPatch(typeof(SaveManager), nameof(SaveManager.SaveTemp))]
internal static class ModSaveDirectory
{
    private static void Prefix(string filePath)
    {
        if (Path.GetFullPath(filePath).StartsWith(Path.GetFullPath(SaveProfile.Root) + Path.DirectorySeparatorChar, StringComparison.OrdinalIgnoreCase))
            Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);
    }
}

using BepInEx;
using BepInEx.Unity.IL2CPP;
using HarmonyLib;
using BepInEx.Logging;

namespace Wildforge.Megabonk;

[BepInPlugin(Id, Name, Version)]
public sealed class Plugin : BasePlugin
{
    public const string Id = "wildforge.megabonk";
    public const string Name = "Megabonk Wildforge Mod";
    public const string Version = "0.3.0";
    internal static ManualLogSource Logger = null!;
    internal static string AssetDirectory = Path.Combine(Path.GetDirectoryName(typeof(Plugin).Assembly.Location)!, "assets");

    public override void Load()
    {
        Logger = Log;
        if (Environment.GetCommandLineArgs().Contains("--wildforge-smoke")) UnityEngine.Application.runInBackground = true;
        Log.LogInfo($"Wildforge bootstrap loaded: {Name} {Version}");
        var harmony=new Harmony(Id);
        try { harmony.PatchAll(typeof(Plugin).Assembly); }
        catch { harmony.UnpatchSelf(); throw; }
        AddComponent<RuntimeDriver>();
        Log.LogInfo("Full Wildforge catalog, mixed enemies, perks, cards and orb HP integration enabled.");
    }
}

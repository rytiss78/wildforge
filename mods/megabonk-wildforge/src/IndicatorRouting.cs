using HarmonyLib;
using Assets.Scripts.Actors.Player;

namespace Wildforge.Megabonk;

[HarmonyPatch(typeof(HealthUI),nameof(HealthUI.UpdateBars))]
internal static class IndicatorRouting
{
    private static readonly Dictionary<IntPtr,float> Hidden=new();
    private static void Postfix(HealthUI __instance)
    {
        if(__instance.canvasGroup==null)return;
        bool wildforge=MyPlayer.Instance?.inventory?.characterData!=null&&Content.IsHero(MyPlayer.Instance.inventory.characterData.eCharacter);
        if(wildforge)
        {
            if(!Hidden.ContainsKey(__instance.Pointer))Hidden[__instance.Pointer]=__instance.canvasGroup.alpha;
            __instance.canvasGroup.alpha=0;
        }
        else if(Hidden.Remove(__instance.Pointer,out var alpha))__instance.canvasGroup.alpha=alpha;
    }
}

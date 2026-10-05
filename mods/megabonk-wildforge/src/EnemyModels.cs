using HarmonyLib;
using UnityEngine;
using Assets.Scripts.Actors.Enemies;
using Assets.Scripts.Managers;
using UObject=UnityEngine.Object;

namespace Wildforge.Megabonk;

internal static class EnemyModels
{
    private sealed class View {internal Enemy Enemy; internal GameObject Model; internal OrbHealth Orbs; internal Entry Entry;}
    private static readonly Dictionary<IntPtr,View> Views=new();
    internal static int AttachedCount=>Views.Count;
    internal static bool HasPartialHealthOrb=>Views.Values.Any(v=>v.Orbs.Count>0&&v.Orbs.FillPercent>0&&v.Orbs.FillPercent<100);
    internal static void Attach(Enemy enemy)
    {
        if(Views.Remove(enemy.Pointer,out var old)) {old.Orbs.Dispose(); if(old.Model!=null) UObject.Destroy(old.Model);}
        if(!Catalog.EnemiesById.TryGetValue((int)enemy.enemyData.enemyName,out var entry))
        { if(enemy.renderer!=null) enemy.renderer.forceRenderingOff=false; return; }
        var model=UObject.Instantiate(DuckModel.Prefab(entry.Asset),enemy.transform);
        model.transform.localPosition=Vector3.zero; model.transform.localRotation=Quaternion.identity;
        if(entry.Boss) model.transform.localScale=Vector3.one*(entry.Height/4.1f);
        model.name="WildforgeEnemy_"+entry.Id; model.SetActive(true);
        enemy.renderer.forceRenderingOff=true;
        Views[enemy.Pointer]=new View {Enemy=enemy,Model=model,Entry=entry,Orbs=new OrbHealth(model)};
    }
    internal static void Tick()
    {
        foreach(var pair in Views.ToArray())
        {
            var v=pair.Value;
            if(v.Enemy==null||v.Model==null) {v.Orbs.Dispose(); Views.Remove(pair.Key);continue;}
            bool alive=v.Enemy.hp>0&&v.Enemy.gameObject.activeInHierarchy;
            if(v.Model.activeSelf!=alive) v.Model.SetActive(alive);
            if(!alive) continue;
            v.Enemy.renderer.forceRenderingOff=true; v.Orbs.Update(v.Enemy.hp/Math.Max(1,v.Enemy.maxHp));
            if(v.Entry.Behavior=="charge") v.Enemy.speedMultiplier=Time.time%5<1?2.2f:1;
            if(v.Entry.Behavior=="skitter") v.Model.transform.localRotation=Quaternion.Euler(0,Mathf.Sin(Time.time*9)*14,0);
        }
    }
}
[HarmonyPatch(typeof(Enemy),nameof(Enemy.InitEnemy))]
internal static class AttachEnemyModel
{
    private static void Postfix(Enemy __instance)
    {try {EnemyModels.Attach(__instance);} catch(Exception ex) {Plugin.Logger.LogError("Wildforge enemy model failed: "+ex);}}
}
[HarmonyPatch(typeof(EnemyManager),nameof(EnemyManager.SpawnEnemy),new[]{typeof(EnemyData),typeof(Vector3),typeof(int),typeof(bool),typeof(EEnemyFlag),typeof(bool),typeof(float)})]
internal static class MixedEnemyWaves
{
    private static readonly HashSet<int> Bosses=new(){7,15,25,27,34,35,36,43,50};
    private static void Prefix(ref EnemyData enemyData)
    {
        if(Catalog.Data==null || Catalog.EnemiesById.ContainsKey((int)enemyData.enemyName) || Bosses.Contains((int)enemyData.enemyName) || UnityEngine.Random.value>.4f) return;
        int biome=UnityEngine.Random.Range(0,6),roll=UnityEngine.Random.Range(0,100);
        foreach(var e in Catalog.Data.Enemies.Where(e=>e.Biome==biome&&!e.Boss))
        {roll-=e.Weight;if(roll<0){enemyData=DataManager.Instance.enemyData[(Actors.Enemies.EEnemy)e.RuntimeId];return;}}
    }
}
[HarmonyPatch(typeof(EnemyManager),nameof(EnemyManager.SpawnBoss))]
internal static class MixedBosses
{
    private static void Prefix(ref Actors.Enemies.EEnemy eEnemy)
    {
        if(Catalog.Data==null||Catalog.EnemiesById.ContainsKey((int)eEnemy)||UnityEngine.Random.value>.5f)return;
        var bosses=Catalog.Data.Enemies.Where(e=>e.Boss).ToArray();
        eEnemy=(Actors.Enemies.EEnemy)bosses[UnityEngine.Random.Range(0,bosses.Length)].RuntimeId;
    }
}
[HarmonyPatch(typeof(EnemyData),nameof(EnemyData.GetName))]
internal static class WildforgeEnemyName
{
    private static void Postfix(EnemyData __instance,ref string __result)
    {if(Catalog.EnemiesById.TryGetValue((int)__instance.enemyName,out var enemy)) __result=enemy.Name;}
}

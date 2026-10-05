using System.Text.Json;
using System.Runtime.InteropServices;
using HarmonyLib;
using UnityEngine;
using Il2CppInterop.Runtime.InteropTypes.Arrays;
using UObject = UnityEngine.Object;

namespace Wildforge.Megabonk;

// Loads the subset of glTF emitted by our own original Wildforge model exporter.
// Meshes/materials are cached; instances follow Megabonk's existing player rig.
internal static class DuckModel
{
    private static readonly Dictionary<string,GameObject> Prefabs = new();
    private sealed class HeroView
    {
        internal PlayerRenderer Renderer;
        internal PlayerInventory Inventory;
        internal GameObject Model;
        internal OrbHealth Orbs;
        internal Transform[] Limbs;
    }
    private static readonly Dictionary<IntPtr,HeroView> Heroes = new();
    internal static bool HasPartialHealthOrb=>Heroes.Values.Any(v=>v.Orbs.Count>0&&v.Orbs.FillPercent>0&&v.Orbs.FillPercent<100);
    internal static GameObject Prefab(string asset)
    {
        if (!Prefabs.TryGetValue(asset,out var prefab)) Prefabs[asset]=prefab=Load(asset);
        return prefab;
    }
    internal static void Prepare() => Prefab("count_duck");
    internal static void Tick()
    {
        foreach (var pair in Heroes.ToArray())
        {
            var view=pair.Value;
            if(view.Renderer==null || view.Model==null) { Heroes.Remove(pair.Key); continue; }
            view.Renderer.renderer.forceRenderingOff=true;
            float swing=Mathf.Sin(Time.time*(view.Renderer.moving?10:2))*(view.Renderer.moving?24:2);
            for(int i=0;i<view.Limbs.Length;i++) if(view.Limbs[i]!=null) view.Limbs[i].localRotation=Quaternion.Euler(swing*(i%2==0?1:-1),0,0);
            var current=Assets.Scripts.Actors.Player.MyPlayer.Instance?.inventory;
            var health=current?.characterData?.eCharacter==view.Renderer.characterData.eCharacter?current.playerHealth:view.Inventory?.playerHealth;
            view.Orbs.Update(health==null?1:(float)health.hp/Math.Max(1,health.maxHp));
        }
    }
    internal static void Attach(PlayerRenderer renderer,PlayerInventory inventory)
    {
        if(Heroes.Remove(renderer.Pointer,out var old)) { old.Orbs.Dispose(); if(old.Model!=null) UObject.Destroy(old.Model); }
        if(!Catalog.HeroesById.TryGetValue((int)renderer.characterData.eCharacter,out var entry))
        { if(renderer.renderer!=null) renderer.renderer.forceRenderingOff=false; return; }
        var instance=UObject.Instantiate(Prefab(entry.Asset),renderer.rendererObject.transform);
        instance.name="Wildforge_"+entry.Id;
        instance.transform.localPosition=Vector3.zero; instance.transform.localRotation=Quaternion.identity; instance.transform.localScale=Vector3.one;
        instance.SetActive(true); renderer.renderer.forceRenderingOff=true;
        var limbs=instance.GetComponentsInChildren<Transform>(true).Where(t=>t.name.StartsWith("Leg")||t.name.StartsWith("Arm")).ToArray();
        Heroes[renderer.Pointer]=new HeroView {Renderer=renderer,Inventory=inventory,Model=instance,Orbs=new OrbHealth(instance),Limbs=limbs};
        Plugin.Logger.LogInfo("Wildforge hero model attached: "+entry.Name);
    }

    private static GameObject Load(string asset)
    {
        var bytes = File.ReadAllBytes(Path.Combine(Plugin.AssetDirectory, asset+".glb"));
        if (BitConverter.ToUInt32(bytes, 0) != 0x46546C67 || BitConverter.ToUInt32(bytes, 4) != 2)
            throw new InvalidDataException("Invalid Wildforge GLB: "+asset);
        int jsonLength = BitConverter.ToInt32(bytes, 12);
        using var doc = JsonDocument.Parse(bytes.AsMemory(20, jsonLength));
        var gltf = doc.RootElement;
        int binaryOffset = 28 + jsonLength;
        var views = gltf.GetProperty("bufferViews");
        var accessors = gltf.GetProperty("accessors");
        float[] ReadFloat(int id, int width)
        {
            var a = accessors[id];
            if (a.GetProperty("componentType").GetInt32() != 5126) throw new InvalidDataException("Only float mesh attributes supported");
            var view = views[a.GetProperty("bufferView").GetInt32()];
            int offset = binaryOffset + GetInt(view, "byteOffset") + GetInt(a, "byteOffset");
            int count = a.GetProperty("count").GetInt32();
            int stride = view.TryGetProperty("byteStride", out var s) ? s.GetInt32() : width * 4;
            var values = new float[count * width];
            for (int i = 0; i < count; i++) for (int j = 0; j < width; j++) values[i * width + j] = BitConverter.ToSingle(bytes, offset + i * stride + j * 4);
            return values;
        }
        int[] ReadIndices(int id)
        {
            var a = accessors[id]; var view = views[a.GetProperty("bufferView").GetInt32()];
            int offset = binaryOffset + GetInt(view, "byteOffset") + GetInt(a, "byteOffset");
            int count = a.GetProperty("count").GetInt32(), type = a.GetProperty("componentType").GetInt32();
            int width = type switch { 5121 => 1, 5123 => 2, 5125 => 4, _ => throw new InvalidDataException("Invalid indices") };
            var result = new int[count];
            for (int i = 0; i < count; i++) result[i] = width switch { 1 => bytes[offset+i], 2 => BitConverter.ToUInt16(bytes, offset+i*2), _ => checked((int)BitConverter.ToUInt32(bytes,offset+i*4)) };
            // Reflect glTF's right-handed Z axis and reverse winding for Unity.
            for (int i = 0; i < count; i += 3) (result[i+1], result[i+2]) = (result[i+2], result[i+1]);
            return result;
        }
        var paper = TextureLoader.Load(Path.Combine(Plugin.AssetDirectory, "paper.png"));
        var shader = Shader.Find("Standard") ?? Shader.Find("Unlit/Texture");
        if (shader == null) throw new InvalidOperationException("No compatible model shader found");
        var materials = gltf.GetProperty("materials").EnumerateArray().Select(m =>
        {
            var pbr = m.GetProperty("pbrMetallicRoughness");
            var c = pbr.GetProperty("baseColorFactor");
            var material = new Material(shader) { color = new Color(c[0].GetSingle(),c[1].GetSingle(),c[2].GetSingle(),c[3].GetSingle()).gamma, mainTexture = paper };
            if (material.HasProperty("_Glossiness")) material.SetFloat("_Glossiness", 0);
            return material;
        }).ToArray();
        var meshes = gltf.GetProperty("meshes").EnumerateArray().Select(m =>
        {
            var primitive = m.GetProperty("primitives")[0];
            var attributes = primitive.GetProperty("attributes");
            var positions = ReadFloat(attributes.GetProperty("POSITION").GetInt32(), 3);
            var normals = ReadFloat(attributes.GetProperty("NORMAL").GetInt32(), 3);
            var uvs = ReadFloat(attributes.GetProperty("TEXCOORD_0").GetInt32(), 2);
            var vertices = new Vector3[positions.Length/3]; var ns = new Vector3[vertices.Length]; var uv = new Vector2[vertices.Length];
            for (int i=0;i<vertices.Length;i++)
            { vertices[i] = new Vector3(positions[i*3],positions[i*3+1],-positions[i*3+2]); ns[i] = new Vector3(normals[i*3],normals[i*3+1],-normals[i*3+2]); uv[i] = new Vector2(uvs[i*2], 1-uvs[i*2+1]); }
            var mesh = new Mesh { name = m.GetProperty("name").GetString() };
            SetChannel(mesh, UnityEngine.Rendering.VertexAttribute.Position, 3, vertices);
            SetChannel(mesh, UnityEngine.Rendering.VertexAttribute.Normal, 3, ns);
            SetChannel(mesh, UnityEngine.Rendering.VertexAttribute.TexCoord0, 2, uv);
            var indices = ReadIndices(primitive.GetProperty("indices").GetInt32());
            var pin = GCHandle.Alloc(indices, GCHandleType.Pinned);
            try { Mesh.SetIndicesNativeArrayImpl_Injected(mesh.m_CachedPtr, 0, MeshTopology.Triangles, UnityEngine.Rendering.IndexFormat.UInt32, pin.AddrOfPinnedObject(), 0, indices.Length, true, 0); }
            finally { pin.Free(); }
            mesh.RecalculateBounds();
            return (mesh, material: materials[primitive.GetProperty("material").GetInt32()]);
        }).ToArray();
        var root = new GameObject("WildforgePrefab_"+asset);
        var nodesJson = gltf.GetProperty("nodes");
        var nodes = nodesJson.EnumerateArray().Select(n => new GameObject(n.GetProperty("name").GetString())).ToArray();
        for (int i=0;i<nodes.Length;i++)
        {
            var node = nodesJson[i];
            nodes[i].transform.SetParent(root.transform, false);
            if (node.TryGetProperty("translation", out var t)) nodes[i].transform.localPosition = new Vector3(t[0].GetSingle(),t[1].GetSingle(),-t[2].GetSingle());
            if (node.TryGetProperty("rotation", out var q)) nodes[i].transform.localRotation = new Quaternion(-q[0].GetSingle(),-q[1].GetSingle(),q[2].GetSingle(),q[3].GetSingle());
            if (node.TryGetProperty("scale",out var scale)) nodes[i].transform.localScale = new Vector3(scale[0].GetSingle(),scale[1].GetSingle(),scale[2].GetSingle());
            if (node.TryGetProperty("mesh",out var meshIndex))
            { var meshAsset = meshes[meshIndex.GetInt32()]; nodes[i].AddComponent<MeshFilter>().sharedMesh = meshAsset.mesh; nodes[i].AddComponent<MeshRenderer>().sharedMaterial = meshAsset.material; }
        }
        for (int i=0;i<nodes.Length;i++) if (nodesJson[i].TryGetProperty("children",out var children)) foreach (var child in children.EnumerateArray()) nodes[child.GetInt32()].transform.SetParent(nodes[i].transform, false);
        root.SetActive(false);
        UObject.DontDestroyOnLoad(root);
        Plugin.Logger.LogInfo($"Loaded Wildforge model {asset}: {meshes.Length} mesh parts.");
        return root;
    }
    private static int GetInt(JsonElement element, string key) => element.TryGetProperty(key,out var value) ? value.GetInt32() : 0;
    internal static void SetChannel<T>(Mesh mesh, UnityEngine.Rendering.VertexAttribute channel, int width, T[] values) where T : struct
    {
        var pin = GCHandle.Alloc(values, GCHandleType.Pinned);
        try { Mesh.SetNativeArrayForChannelImpl_Injected(mesh.m_CachedPtr, channel, UnityEngine.Rendering.VertexAttributeFormat.Float32, width, pin.AddrOfPinnedObject(), values.Length, 0, values.Length, UnityEngine.Rendering.MeshUpdateFlags.Default); }
        finally { pin.Free(); }
    }
}

[HarmonyPatch(typeof(PlayerRenderer), nameof(PlayerRenderer.SetCharacter))]
internal static class DuckRenderer
{
    private static void Prefix(CharacterData characterData)
    {
        if (Content.IsHero(characterData.eCharacter))
            SaveManager.Instance.config.preferences.characterSkins.TryAdd(characterData.eCharacter, 0);
    }
    private static void Postfix(PlayerRenderer __instance, PlayerInventory inventory)
    { try { DuckModel.Attach(__instance, inventory); } catch (Exception ex) { Plugin.Logger.LogError($"Wildforge hero model failed: {ex}"); } }
}

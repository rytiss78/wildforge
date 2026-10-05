using UnityEngine;
using UnityEngine.Rendering;
using System.Runtime.InteropServices;
using UObject=UnityEngine.Object;

namespace Wildforge.Megabonk;

// A geometric liquid surface replaces the Godot-only orb shader. The fill is
// attached to the original GlassCore/RearGlass meshes, never a floating HP bar.
internal sealed class OrbHealth
{
    private sealed class Core
    {
        internal Mesh Mesh;
        internal MeshRenderer Liquid;
        internal float Radius;
        internal Vector3 Center;
    }
    private readonly List<Core> cores=new();
    private int fill=-1;
    private static Material glass,blood;
    internal int Count=>cores.Count;
    internal int FillPercent=>fill;
    internal OrbHealth(GameObject model)
    {
        if(glass==null)
        {
            var shader=Shader.Find("Standard")??Shader.Find("Unlit/Color");
            blood=new Material(shader) {color=new Color(.8f,.04f,.08f,1)};
            glass=new Material(shader) {color=new Color(.55f,.85f,.77f,.24f)};
            glass.SetFloat("_Mode",3); glass.SetInt("_SrcBlend",(int)BlendMode.SrcAlpha); glass.SetInt("_DstBlend",(int)BlendMode.OneMinusSrcAlpha); glass.SetInt("_ZWrite",0);
            glass.EnableKeyword("_ALPHABLEND_ON"); glass.renderQueue=3000;
            UObject.DontDestroyOnLoad(glass); UObject.DontDestroyOnLoad(blood);
        }
        foreach(var filter in model.GetComponentsInChildren<MeshFilter>(true))
        {
            if(filter.name!="GlassCore" && filter.name!="RearGlass") continue;
            var renderer=filter.GetComponent<MeshRenderer>(); renderer.sharedMaterial=glass;
            var bounds=filter.sharedMesh.bounds;
            var liquid=new GameObject("WildforgeBloodFill"); liquid.transform.SetParent(filter.transform,false);
            var mesh=new Mesh {name="WildforgeHPOrb"};
            liquid.AddComponent<MeshFilter>().sharedMesh=mesh;
            var lr=liquid.AddComponent<MeshRenderer>(); lr.sharedMaterial=blood;
            lr.shadowCastingMode=ShadowCastingMode.Off;
            cores.Add(new Core {Mesh=mesh,Liquid=lr,Radius=bounds.size.y*.5f*.97f,Center=bounds.center});
        }
        Update(1);
    }
    internal void Update(float ratio)
    {
        int next=(int)(Math.Clamp(ratio,0,1)*100);
        if(next==fill) return;
        fill=next;
        foreach(var core in cores)
        {
            core.Liquid.enabled=fill>0;
            if(fill==0) continue;
            const int rings=12,segments=24;
            float upper=Mathf.Acos(-1+2*fill/100f);
            var vertices=new List<Vector3>(); var normals=new List<Vector3>(); var indices=new List<int>();
            for(int ring=0;ring<=rings;ring++)
            {
                float theta=Mathf.Lerp(Mathf.PI,upper,ring/(float)rings);
                for(int side=0;side<=segments;side++)
                {
                    float phi=side*Mathf.PI*2/segments;
                    var normal=new Vector3(Mathf.Sin(theta)*Mathf.Cos(phi),Mathf.Cos(theta),Mathf.Sin(theta)*Mathf.Sin(phi));
                    vertices.Add(core.Center+normal*core.Radius); normals.Add(normal);
                    if(ring<rings&&side<segments) { int a=ring*(segments+1)+side,b=a+segments+1; indices.AddRange(new[]{a,b,a+1,a+1,b,b+1}); }
                }
            }
            int cap=vertices.Count; vertices.Add(core.Center+Vector3.up*(core.Radius*Mathf.Cos(upper))); normals.Add(Vector3.up);
            for(int side=0;side<segments;side++) indices.AddRange(new[]{cap,rings*(segments+1)+side,rings*(segments+1)+side+1});
            core.Mesh.Clear();
            DuckModel.SetChannel(core.Mesh,VertexAttribute.Position,3,vertices.ToArray());
            DuckModel.SetChannel(core.Mesh,VertexAttribute.Normal,3,normals.ToArray());
            var buffer=indices.ToArray(); var pin=GCHandle.Alloc(buffer,GCHandleType.Pinned);
            try { Mesh.SetIndicesNativeArrayImpl_Injected(core.Mesh.m_CachedPtr,0,MeshTopology.Triangles,IndexFormat.UInt32,pin.AddrOfPinnedObject(),0,buffer.Length,true,0); }
            finally {pin.Free();}
            core.Mesh.RecalculateBounds();
        }
    }
    internal void Dispose() {foreach(var core in cores) if(core.Mesh!=null) UObject.Destroy(core.Mesh);}
}

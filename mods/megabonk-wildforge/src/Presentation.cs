using UnityEngine;
using Assets.Scripts.Actors.Player;
using UObject=UnityEngine.Object;
using UnityEngine.Bindings;

namespace Wildforge.Megabonk;

// Small procedural cues reuse the original low-poly meshes and a shared material.
internal static class Presentation
{
    private sealed class View {internal GameObject Model;internal Entry Entry;internal float Fired;}
    private sealed class Cue {internal GameObject Model;internal float Born,Life;internal Vector3 Scale;}
    private static readonly Dictionary<int,View> Weapons=new();
    private static readonly List<Cue> Cues=new();
    private static readonly Dictionary<string,AudioClip> Clips=new();
    private static readonly Dictionary<string,float> LastSound=new();
    private static Material material;
    private static AudioSource audio;
    private static IntPtr inventory;
    private static int cards=-1;
    private static string toast="";
    private static float toastUntil;
    internal static int ModelCount=>Weapons.Count;
    internal static int SoundCount=>Clips.Count;
    internal static int CueCount=>Cues.Count;
    internal static Color ColorFor(string key)=>key.Contains("poison")?new Color(.4f,1,.25f):key.Contains("ice")||key.Contains("bubble")?Color.cyan:key.Contains("flower")?new Color(1,.4f,.8f):key.Contains("fire")||key.Contains("flame")?new Color(1,.35f,.1f):key.Contains("lightning")?Color.yellow:new Color(.75f,.55f,1);
    internal static GameObject Model(Entry entry)
    {
        string asset="weapon_"+entry.Id;
        if(!File.Exists(Path.Combine(Plugin.AssetDirectory,asset+".glb")))asset="weapon_"+(entry.Turret?"turret":entry.Archetype??"gun");
        GameObject model;
        if(File.Exists(Path.Combine(Plugin.AssetDirectory,asset+".glb")))model=UObject.Instantiate(DuckModel.Prefab(asset));
        else
        {
            model=new GameObject("WildforgeBasicGun");
            material??=new Material(Shader.Find("Unlit/Color")??Shader.Find("Standard"));
            void Part(string name,Vector3 position,Vector3 scale,Color color)
            {
                var part=GameObject.CreatePrimitive(PrimitiveType.Cube);part.name=name;UObject.Destroy(part.GetComponent<Collider>());
                part.transform.SetParent(model.transform,false);part.transform.localPosition=position;part.transform.localScale=scale;
                var renderer=part.GetComponent<Renderer>();renderer.sharedMaterial=material;var props=new MaterialPropertyBlock();props.SetColor("_Color",color);renderer.SetPropertyBlock(props);
            }
            Part("Body",Vector3.zero,new Vector3(.35f,.3f,.6f),ColorFor(entry.Id));
            Part("Barrel",new Vector3(0,0,.55f),new Vector3(.16f,.16f,.55f),new Color(.2f,.2f,.25f));
            Part("Grip",new Vector3(0,-.27f,-.1f),new Vector3(.18f,.4f,.2f),new Color(.65f,.4f,.2f));
            Part("Sight",new Vector3(0,.2f,.05f),new Vector3(.1f,.1f,.15f),Color.yellow);
        }
        model.name="WildforgeItem_"+entry.Id;model.SetActive(true);return model;
    }
    internal static void Reset()
    {
        foreach(var view in Weapons.Values)if(view.Model!=null)UObject.Destroy(view.Model);
        foreach(var cue in Cues)if(cue.Model!=null)UObject.Destroy(cue.Model);
        Weapons.Clear();Cues.Clear();cards=-1;toastUntil=0;
    }
    internal static void Tick(MyPlayer player)
    {
        if(player?.inventory?.weaponInventory==null||GameManager.Instance?.isPlaying!=true){if(Weapons.Count>0)Reset();return;}
        if(inventory!=player.inventory.Pointer){inventory=player.inventory.Pointer;Reset();}
        var held=new HashSet<int>();int slot=0;
        foreach(var pair in player.inventory.weaponInventory.weapons)
        {
            int id=(int)pair.Key;
            if(!Catalog.WeaponsById.TryGetValue(id,out var entry))continue;
            held.Add(id);
            if(!Weapons.TryGetValue(id,out var view))Weapons[id]=view=new View {Model=Model(entry),Entry=entry};
            float angle=slot++*1.7f;var origin=player.feet?.position??player.transform.position;
            view.Model.transform.position=origin+new Vector3(Mathf.Cos(angle)*1.3f,1.1f+Mathf.Sin(Time.time*2+angle)*.08f,Mathf.Sin(angle)*1.3f);
            var forward=player.playerMovement?.orientation?.forward??Vector3.forward;forward.y=0;
            if(forward.sqrMagnitude>.01f)view.Model.transform.rotation=Quaternion.LookRotation(forward)*Quaternion.Euler(-Math.Max(0,.15f-(Time.time-view.Fired))*100,entry.Id=="flowers"?Time.time*30:0,0);
            view.Model.transform.localScale=Vector3.one*(entry.Turret?.35f:.55f);
        }
        foreach(var id in Weapons.Keys.Where(id=>!held.Contains(id)).ToArray()){UObject.Destroy(Weapons[id].Model);Weapons.Remove(id);}
        int total=0;foreach(var pair in player.inventory.itemInventory.items)if(Catalog.CardsById.ContainsKey((int)pair.Key))total+=pair.Value.amount;
        if(cards>=0&&total>cards){Notify("Card applied — "+total+" Wildforge stacks");Sound("card");Pulse(player.transform.position,Color.yellow,.6f);}
        cards=total;
        foreach(var cue in Cues.ToArray())
        {
            float t=(Time.time-cue.Born)/cue.Life;
            if(t>=1||cue.Model==null){if(cue.Model!=null)UObject.Destroy(cue.Model);Cues.Remove(cue);continue;}
            cue.Model.transform.localScale=cue.Scale*(1+t*2);
            cue.Model.transform.Rotate(0,Time.deltaTime*90,0);
        }
    }
    internal static void Shot(Entry entry)
    {
        if(Weapons.TryGetValue(entry.RuntimeId,out var view))
        {view.Fired=Time.time;Pulse(view.Model.transform.position,ColorFor(entry.Id),.14f,.15f);}
        Sound("shot_"+entry.Id);
    }
    internal static void Notify(string text){toast=text;toastUntil=Time.unscaledTime+2.5f;}
    internal static void Pulse(Vector3 position,Color color,float radius,float life=.45f)
    {
        if(Cues.Count>=48)return;
        var obj=GameObject.CreatePrimitive(PrimitiveType.Sphere);obj.name="WildforgeEffect";
        UObject.Destroy(obj.GetComponent<Collider>());
        material??=new Material(Shader.Find("Unlit/Color")??Shader.Find("Standard"));
        var renderer=obj.GetComponent<Renderer>();renderer.sharedMaterial=material;
        var properties=new MaterialPropertyBlock();properties.SetColor("_Color",color);renderer.SetPropertyBlock(properties);
        obj.transform.position=position+Vector3.up*.1f;
        var scale=new Vector3(radius,.06f,radius);obj.transform.localScale=scale;
        Cues.Add(new Cue {Model=obj,Born=Time.time,Life=life,Scale=scale});
    }
    internal static void Beam(Vector3 from,Vector3 to,Color color)
    {
        if(Cues.Count>=48)return;
        var obj=GameObject.CreatePrimitive(PrimitiveType.Cube);obj.name="WildforgeTracer";UObject.Destroy(obj.GetComponent<Collider>());
        material??=new Material(Shader.Find("Unlit/Color")??Shader.Find("Standard"));var renderer=obj.GetComponent<Renderer>();renderer.sharedMaterial=material;
        var properties=new MaterialPropertyBlock();properties.SetColor("_Color",color);renderer.SetPropertyBlock(properties);
        obj.transform.position=(from+to)*.5f;obj.transform.rotation=Quaternion.LookRotation(to-from);
        var scale=new Vector3(.055f,.055f,Math.Max(.05f,Vector3.Distance(from,to)));obj.transform.localScale=scale;
        Cues.Add(new Cue {Model=obj,Born=Time.time,Life=.1f,Scale=scale});
    }
    internal static unsafe void Sound(string key)
    {
        if(Time.unscaledTime-LastSound.GetValueOrDefault(key,-100)<.12f)return;LastSound[key]=Time.unscaledTime;
        if(!Clips.TryGetValue(key,out var clip))
        {
            const int hz=22050;int n=(int)(hz*(key=="dash"?.22f:key=="deploy"?.28f:.13f));
            var samples=new float[n];int seed=17;foreach(char c in key)seed=unchecked(seed*31+c);
            float pitch=180+Math.Abs((long)seed)%600;var noise=new System.Random(seed);
            for(int i=0;i<n;i++){float t=(float)i/n;float wave=Mathf.Sin(2*Mathf.PI*(pitch*(1-t*.65f))*i/hz);samples[i]=(wave*.7f+(float)(noise.NextDouble()*2-1)*(key.StartsWith("shot")?.3f:.08f))*Mathf.Sin(Mathf.PI*t)*.3f;}
            // The reconstructed Span APIs in this Unity build cannot pin strings or
            // float arrays. Use the same direct native span bindings as our PNG loader.
            clip=AudioClip.Construct_Internal();string name="Wildforge_"+key;
            fixed(char* namePtr=name){var span=new ManagedSpanWrapper(namePtr,name.Length);AudioClip.CreateUserSound_Injected(clip.m_CachedPtr,ref span,n,1,hz,false);}
            fixed(float* dataPtr=samples){var span=new ManagedSpanWrapper(dataPtr,samples.Length);if(!AudioClip.SetData_Injected(clip.m_CachedPtr,ref span,0))throw new InvalidOperationException("Cannot initialize Wildforge sound "+key);}
            UObject.DontDestroyOnLoad(clip);Clips[key]=clip;
        }
        if(audio==null){var obj=new GameObject("WildforgeAudio");UObject.DontDestroyOnLoad(obj);audio=obj.AddComponent<AudioSource>();audio.spatialBlend=0;audio.volume=.3f;}
        audio.PlayOneShot(clip);
    }
    internal static void Hud()
    {
        if(MyPlayer.Instance?.inventory==null||GameManager.Instance?.isPlaying!=true)return;
        GUI.Box(new Rect(12,Screen.height-88,440,76),"Wildforge  •  Shift / Right click: dash  •  R: turret\nCtrl in air: slam  •  Dash: "+(CombatEffects.DashRemaining<=0?"ready":CombatEffects.DashRemaining.ToString("0.0")+"s")+"  •  Turret: "+(CombatEffects.CanDeploy?"equipped":"equip a turret")+"\nDamage bonus: "+(Effects.Bonus("damage")/15*100).ToString("0")+"%  •  Card stacks: "+Math.Max(0,cards));
        if(Time.unscaledTime<toastUntil)GUI.Box(new Rect(Screen.width*.5f-220,90,440,38),toast);
    }
}

shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 p;
void vertex(){ p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float edge=max(abs(p.x),abs(p.z));
 if(edge<375.0) discard;
 float wave=sin(p.x*.18+TIME*1.4)*sin(p.z*.13-TIME*.8);
 float foam=1.0-smoothstep(.2,1.2,abs(mod(edge-375.0+wave*.8-TIME*.7,7.0)-1.0));
 vec3 water=mix(vec3(.035,.20,.31),vec3(.06,.52,.59),.5+wave*.25);
 float shore=1.0-smoothstep(375.0,403.0,edge);
 ALBEDO=mix(water,vec3(.80,.96,.86),foam*(.15+shore*.65));
 ROUGHNESS=.6;
}

shader_type spatial;
render_mode unshaded,cull_disabled;
uniform bool red_moon=false;
uniform float phase=0.0;
// Per-island coastline terms (RealmWorld.GRADE): 4-lobe, 6-lobe, radius shift.
uniform vec3 shape=vec3(0.0);
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 float a=atan(p.z,p.x);
 float coast=344.0+24.0*sin(3.0*(a+phase))+14.0*sin(5.0*(a-phase))+8.0*cos(7.0*(a+phase*.5))+shape.x*sin(4.0*(a-phase*1.3))+shape.y*sin(6.0*(a+phase))+shape.z;
 if(red_moon) coast=72.0;
 float shore_distance=length(p.xz)-coast;
 if(shore_distance< -4.0) discard;
 float swell=sin(p.x*.065+p.z*.041+TIME*.65)+sin(p.z*.09-p.x*.023-TIME*.42)*.55;
 float ripple=sin(p.x*.39+sin(p.z*.21)+TIME)*sin(p.z*.31-TIME*.7);
 float shore=1.0-smoothstep(0.0,22.0,shore_distance);
 float foam=(1.0-smoothstep(.2,1.5,abs(shore_distance-2.0-swell*1.8)))*.8;
 float flecks=pow(max(0.0,ripple),12.0)*.10;
 vec3 water=mix(vec3(.025,.13,.21),vec3(.055,.34,.36),clamp(.45+swell*.15+shore*.25,0.,1.));
 if(red_moon) water=vec3(.008,.003,.019)+vec3(.11,.014,.025)*shore;
 ALBEDO=mix(water,vec3(.69,.85,.73),(foam+flecks)*(red_moon?.08:1.0));ROUGHNESS=.8;
}

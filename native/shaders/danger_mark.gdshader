shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_disabled;
// One warning language: the ink says who it threatens (danger red for every
// enemy attack, gold for the hero's own, pale blue for harmless hazards), the
// fill keeps the attack's identity, the sweep closes in, and the last quarter
// second flashes white: impact now.
uniform vec4 ink:source_color=vec4(1.0,.29,.18,1.0);
uniform vec4 fill:source_color=vec4(1.0,.29,.18,1.0);
uniform float progress=0.0;
uniform float flash_from=.8;
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);
 float edge=smoothstep(.88,.91,r)*(1.0-smoothstep(.98,1.0,r));
 float sweep=1.0-smoothstep(.012,.04,abs(r-(1.0-progress)*.84));
 float a=atan(p.y,p.x);float teeth=step(.78,cos(a*12.0))*smoothstep(.72,.77,r)*(1.0-smoothstep(.87,.9,r));
 float crosshair=(1.0-smoothstep(.008,.018,min(abs(p.x),abs(p.y))))*(1.0-smoothstep(.68,.72,r));
 float pattern=max(max(edge,teeth),max(sweep*.65,crosshair*.35));
 float inner=1.0-smoothstep(.0,.88,r);
 ALBEDO=mix(mix(ink.rgb,fill.rgb,inner*.6),vec3(1.0,.87,.61),pattern*.6);
 float flash=step(flash_from,progress)*(.55+.45*sin(TIME*42.0));
 ALBEDO=mix(ALBEDO,vec3(1.0),flash*.75);EMISSION=ALBEDO*(.4+flash*.8);
 ALPHA=(.10+inner*.08+pattern*.78+flash*.25)*(1.0-smoothstep(.99,1.0,r));
}

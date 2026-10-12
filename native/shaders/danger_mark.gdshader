shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_disabled;
uniform vec4 ink:source_color=vec4(1.0,.34,.2,1.0);
uniform float progress=0.0;
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);
 float edge=smoothstep(.88,.91,r)*(1.0-smoothstep(.98,1.0,r));
 float sweep=1.0-smoothstep(.012,.04,abs(r-(1.0-progress)*.84));
 float a=atan(p.y,p.x);float teeth=step(.78,cos(a*12.0))*smoothstep(.72,.77,r)*(1.0-smoothstep(.87,.9,r));
 float crosshair=(1.0-smoothstep(.008,.018,min(abs(p.x),abs(p.y))))*(1.0-smoothstep(.68,.72,r));
 float pattern=max(max(edge,teeth),max(sweep*.65,crosshair*.35));
 ALBEDO=mix(ink.rgb,vec3(1.0,.87,.61),pattern*.6);EMISSION=ALBEDO*.4;
 ALPHA=(.10+pattern*.78)*(1.0-smoothstep(.99,1.0,r));
}

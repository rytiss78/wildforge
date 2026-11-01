shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
// A burst on the ground (explosions, slams, heals, pulses) as a soft disc of
// colour that spreads and fades: no ring line (user request, November 1).
uniform float age=0.0;
uniform vec4 pigment:source_color=vec4(1.0,.2,.025,1.0);
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);
 float radius=.25+.75*(1.0-exp(-age*7.0));
 float disc=1.0-smoothstep(radius-.12,radius,r);
 float glow=mix(.55,1.0,smoothstep(0.0,radius,r));
 ALBEDO=pigment.rgb;EMISSION=pigment.rgb*.3;
 ALPHA=disc*glow*.32*(1.0-smoothstep(.15,.8,age));
}

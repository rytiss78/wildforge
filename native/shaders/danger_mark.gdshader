shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_disabled;
// One warning language, as a soft colour fill with no edge lines (user request,
// November 1): danger red for every enemy attack, gold for the hero's own, pale
// blue for harmless hazards. The fill deepens from the middle out as the warning
// runs, and the last quarter second flashes white: impact now.
uniform vec4 ink:source_color=vec4(1.0,.29,.18,1.0);
uniform vec4 fill:source_color=vec4(1.0,.29,.18,1.0);
uniform float progress=0.0;
uniform float flash_from=.8;
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);
 float inside=1.0-smoothstep(.9,1.0,r);
 float filled=1.0-smoothstep(progress*.96,progress*.96+.08,r);
 vec3 color=mix(ink.rgb,fill.rgb,.45);
 float flash=step(flash_from,progress)*(.55+.45*sin(TIME*42.0));
 ALBEDO=mix(color,vec3(1.0),flash*.6);EMISSION=ALBEDO*(.25+flash*.6);
 ALPHA=(.16+filled*.22+flash*.18)*inside;
}

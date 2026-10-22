shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
// Tornado funnel on an open cone: diagonal wind bands swirl upward with dark
// ink edges; the bottom frays into the ground and the top into the sky.
uniform vec4 pigment:source_color=vec4(.78,.93,.9,1.0);
uniform float fade=1.0;
void fragment(){
 float u=UV.x;float v=UV.y;
 float swirl=fract(u*3.0+v*2.2-TIME*2.6);
 float band=smoothstep(.0,.08,swirl)*(1.0-smoothstep(.42,.56,swirl));
 float ink=smoothstep(.56,.6,swirl)*(1.0-smoothstep(.6,.66,swirl));
 float streak=pow(abs(sin((u*5.0-v*1.4+TIME*1.7)*6.2832)),18.0);
 float ends=smoothstep(.0,.16,v)*(1.0-smoothstep(.82,1.0,v));
 vec3 color=mix(pigment.rgb*.82,vec3(1.0,.99,.94),streak*.7);
 color=mix(color,vec3(.06,.05,.08),ink);
 ALBEDO=color;EMISSION=color*.25;
 ALPHA=clamp(band*.45+ink*.75+streak*.45,0.0,1.0)*ends*fade;
}

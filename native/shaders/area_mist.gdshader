shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 mist_color : source_color = vec4(.32,.64,.13,1.);
uniform float phase=0.;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) { vec2 i=floor(p), f=fract(p); f=f*f*(3.-2.*f); return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y); }
void vertex() {
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0],INV_VIEW_MATRIX[1],INV_VIEW_MATRIX[2],MODEL_MATRIX[3]);
}
void fragment() {
 vec2 p=(UV-.5)*2.;
 float n=noise(UV*5.+vec2(TIME*.14+phase,-TIME*.24));
 n+=.45*noise(UV*11.+vec2(-TIME*.23,TIME*.13+phase));
 float outline=1.-smoothstep(.42,1.,length(p)+.12*sin(p.x*9.+TIME+phase));
 float density=smoothstep(.37,.53,n)*outline;
 float curl=smoothstep(.55,.59,n)*(1.0-smoothstep(.63,.67,n));
 ALBEDO=mix(mist_color.rgb*.22,mist_color.rgb*1.25,smoothstep(.47,.55,n));
 ALBEDO=mix(ALBEDO,vec3(.74,1.0,.28),curl*.55);
 EMISSION=mist_color.rgb*curl*.35;
 ALPHA=density*.48;
}

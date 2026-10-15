shader_type spatial;
render_mode diffuse_toon, cull_disabled;
uniform float wind_strength=1.0;
varying float height_blend;
void vertex(){
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 height_blend=clamp(UV.y,0.0,1.0);
 VERTEX.x+=sin(TIME*1.7+p.x*.7+p.z*.3)*height_blend*height_blend*.075*wind_strength;
 VERTEX.z+=cos(TIME*1.2+p.z*.4)*height_blend*height_blend*.04*wind_strength;
}
void fragment(){
 ALBEDO=COLOR.rgb*mix(.4,1.15,height_blend);
 EMISSION=COLOR.rgb*.06*height_blend;
 ROUGHNESS=1.0;SPECULAR=0.0;
}

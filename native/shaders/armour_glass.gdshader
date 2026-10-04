shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never;
uniform float armour : hint_range(0.0,1.0)=0.0;
uniform float shield_fill : hint_range(0.0,1.0)=0.0;
uniform float radius=.285;
varying vec3 world_position;
varying float centre_y;
varying float radius_y;
void vertex(){
 world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 centre_y=MODEL_MATRIX[3].y;
 radius_y=length(MODEL_MATRIX[1].xyz)*radius;
}
void fragment(){
 float height=(world_position.y-centre_y)/max(radius_y*2.0,.001)+.5;
 float shield=(1.0-smoothstep(shield_fill-.02,shield_fill+.02,height))*step(.002,shield_fill);
 float protection=clamp(armour+shield*.85,0.0,1.0);
 float rim=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),1.6);
 ALBEDO=vec3(.16,.57,.95);
 EMISSION=vec3(.08,.30,.65)*rim*protection*.35;
 ALPHA=(.10+rim*.65)*protection;
}

shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform vec4 pigment:source_color=vec4(1.0,.4,.025,1.0);
uniform float age=0.0;
void fragment(){
 float core=(1.0-smoothstep(.08,.35,abs(UV.x-.5)))*(1.0-smoothstep(.0,.7,age));
 ALBEDO=mix(pigment.rgb,vec3(1.0,.95,.78),core*.85);
 EMISSION=ALBEDO*.45*(1.0-age);
 ALPHA=1.0-smoothstep(.32,1.0,age);
}

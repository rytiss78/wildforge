shader_type spatial;
render_mode diffuse_toon,cull_disabled;
uniform vec4 tint:source_color=vec4(.9,.3,.5,1.0);
void vertex(){VERTEX.z+=sin(TIME*2.2+UV.y*7.0)*UV.y*.22;}
void fragment(){float hem=step(UV.x,.08)+step(.92,UV.x)+step(.93,UV.y);ALBEDO=mix(tint.rgb,vec3(.95,.79,.36),min(1.0,hem));ROUGHNESS=1.0;}

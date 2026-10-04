shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D paper : source_color, filter_linear_mipmap;
uniform float age=0.0;
void fragment() {
 float grain=texture(paper,UV*2.0).r;
 float scallop=sin(UV.x*94.0+sin(UV.y*23.0)*2.0)*.05;
 float flame=sin(UV.y*28.0- age*18.0+sin(UV.x*43.0)*2.0)*.5+.5;
 vec3 color=mix(vec3(.92,.25,.10),vec3(1.0,.78,.32),flame);
 color=mix(color,vec3(.31,.24,.32),smoothstep(.55,.94,age));
 ALBEDO=color*mix(.85,1.1,grain);
 EMISSION=color*(1.0-age)*.6;
 ALPHA=(1.0-smoothstep(.38,1.0,age))*(.64+scallop);
}

shader_type spatial;
render_mode unshaded,cull_disabled;
uniform sampler2D paper:source_color,filter_linear_mipmap;
void fragment(){
 vec2 p=UV-.5;
 float edge=1.0-smoothstep(.28,.5,length(p));
 float bubble=sin(p.x*79.0+sin(p.y*64.0+TIME*2.0))*sin(p.y*53.0-TIME*2.5);
 float ring=smoothstep(.5,.9,bubble);
 ALBEDO=mix(vec3(.61,.54,.39),vec3(.94,.86,.60),ring)*texture(paper,UV*2.0).rgb;
 EMISSION=vec3(.2,.11,.025)*ring;
 ALPHA=edge*.25;
}

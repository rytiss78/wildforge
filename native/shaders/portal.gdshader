shader_type spatial;
render_mode unshaded,cull_disabled,blend_add,depth_draw_never;
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);
 float spiral=pow(0.5+0.5*sin(a*5.0-r*21.0+TIME*2.5),3.0);
 ALBEDO=mix(vec3(0.15,0.8,0.83),vec3(1.0,0.72,0.25),spiral);
 ALPHA=smoothstep(1.0,0.82,r)*(0.3+spiral*0.6);}

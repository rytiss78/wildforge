shader_type spatial;
render_mode unshaded,blend_add,cull_disabled,depth_draw_never;
void fragment(){ALBEDO=vec3(1.0,0.72,0.28); ALPHA=(0.18+0.07*sin(TIME*1.5+UV.y*12.0))*(1.0-UV.y*0.65);}

shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
void fragment(){float r=length(UV-.5)*2.0;ALBEDO=vec3(.19,.18,.24);ALPHA=(1.0-smoothstep(.25,1.0,r))*.18*COLOR.a;}

shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float age=0.0;
uniform vec4 pigment:source_color=vec4(1.0,.2,.025,1.0);
void fragment(){
 vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);
 float radius=.18+.77*(1.0-exp(-age*7.0));
 float width=mix(.065,.012,age);
 float ring=1.0-smoothstep(width,width+.016,abs(r-radius));
 float breaks=smoothstep(-.72,-.48,sin(a*9.0+age*4.0));
 float rays=pow(max(0.0,cos(a*13.0)),22.0)*(1.0-smoothstep(.45,.95,r))*smoothstep(.10,.19,r);
 float flare=rays*(1.0-smoothstep(.06,.3,age));
 ALBEDO=mix(pigment.rgb,vec3(1.0,.91,.61),flare);
 EMISSION=ALBEDO*.35;
 ALPHA=max(ring*breaks,flare)*(1.0-smoothstep(.22,.78,age));
}

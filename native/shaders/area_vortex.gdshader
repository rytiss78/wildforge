shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
void fragment() {
 vec2 p=(UV-.5)*2.; float r=length(p); float a=atan(p.y,p.x);
 float arms=pow(.5+.5*sin(a*4.-r*15.+TIME*4.),3.);
 float band=exp(-pow((r-.48)*8.,2.));
 float halo=exp(-pow((r-.55)*3.6,2.))*.3;
 float filament=band*(.4+.6*arms);
 float core=1.-smoothstep(.23,.28,r);
 float edge=1.-smoothstep(.75,1.,r);
 vec3 hot=mix(vec3(.85,.18,.035),vec3(1.,.85,.43),filament);
 ALBEDO=mix(hot,vec3(.003,.006,.012),core);
 EMISSION=hot*filament*1.2*(1.-core);
 ALPHA=clamp(core+filament+halo,0.,1.)*edge;
}

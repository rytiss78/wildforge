shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,depth_test_disabled,shadows_disabled;
// Billboard particle for enemy statuses, drawn over the body it covers so it
// reads on every creature shape. COLOR comes from the particle colour
// ramp (alpha fades it out). shape: 0 flame tongue, 1 toxic bubble, 2 frost glint,
// 3 dark mote.
uniform float shape=0.0;
uniform float strength=1.0;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=(UV-.5)*2.0;p.y=-p.y;
 float edge;float hot=0.0;
 if(shape<.5){
  // Teardrop flame: round base, pointed tip, flickering side.
  float t=(p.y+.8)/1.75;
  p.x+=sin(p.y*5.0+TIME*14.0)*.07*t;
  float w=.62*pow(clamp(1.0-t,0.0,1.0),.85)*sqrt(clamp(t*3.0,0.0,1.0));
  edge=max(abs(p.x)-w,max(-t,t-1.0));
  hot=1.0-smoothstep(.0,.5,length(vec2(p.x*1.5,p.y+.35)));
 } else if(shape<1.5){
  float r=length(p);edge=r-.85;
  hot=smoothstep(.55,.72,r)*(1.0-smoothstep(.72,.8,r))*.4+(1.0-smoothstep(.0,.2,length(p-vec2(-.32,.32))));
 } else if(shape<2.5){
  float a=atan(p.y,p.x);float r=length(p);
  edge=r-(.2+.75*pow(abs(cos(a*2.0)),12.0));
  hot=1.0-smoothstep(.0,.35,r);
 } else {
  edge=length(p)-.75;
 }
 float coverage=1.0-smoothstep(-.06,.0,edge);
 float bubble=step(.5,shape)*step(shape,1.5);
 float body=1.0-smoothstep(mix(-.14,-.24,bubble),mix(-.07,-.16,bubble),edge);
 // Flames get a dark-red ink edge; the rest a near-black one.
 vec3 ink=shape<.5?vec3(.42,.05,.02):vec3(.05,.03,.04);
 vec3 color=mix(ink,COLOR.rgb,body);
 color=mix(color,vec3(1.0,.93,.62),hot*(shape<.5?.35:.85)*step(shape,2.5));
 // A bubble is a translucent film with a bright rim.
 float fill=mix(1.0,mix(.72,1.0,max(hot,1.0-body)),bubble);
 ALBEDO=color;EMISSION=color*(.45+hot)*strength;
 ALPHA=coverage*fill*COLOR.a*clamp(strength,0.0,1.0);
}

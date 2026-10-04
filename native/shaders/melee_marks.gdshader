shader_type spatial;
render_mode unshaded,cull_disabled;
uniform vec4 color:source_color=vec4(.72,.18,.15,1.0);
uniform float fade=1.0;
uniform bool splatter=false;
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float coverage=1.0;
 if(splatter){
  float angle=atan(p.y,p.x);float edge=.38+.13*sin(angle*7.0)+.08*cos(angle*11.0);
  coverage=1.0-smoothstep(edge-.025,edge,length(p));
  for(int i=0;i<6;i++){float a=float(i)*2.4;vec2 drop=vec2(cos(a),sin(a))*.68;coverage=max(coverage,1.0-smoothstep(.075,.11,length(p-drop)));}
 }
 ALBEDO=color.rgb;ALPHA=coverage*color.a*fade;
}

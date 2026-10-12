shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
uniform float age=0.0;
uniform vec4 pigment:source_color=vec4(1.0,.2,.025,1.0);
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float growth=.36+.60*(1.0-exp(-age*12.0));
 p/=growth;
 float cloud=10.0;
 float inner=10.0;
 for(int i=0;i<7;i++){
  float a=float(i)*2.39996;
  vec2 centre=vec2(cos(a),sin(a))*(.35+.09*sin(float(i)*3.1));
  float radius=.24+.07*cos(float(i)*2.6);
  float edge=length(p-centre)-radius;
  cloud=min(cloud,edge);
  inner=min(inner,length(p-centre*.72)-radius*.78);
 }
 float angle=atan(p.y,p.x);
 cloud+=sin(angle*17.0+length(p)*28.0)*.016;
 // A sharp asymmetric opening flash gives way to separate curling lobes.
 float spikes=pow(max(0.0,cos(angle*7.0+.35)),16.0)*.32;
 float flash_edge=length(p)-(.30+spikes);
 cloud=min(cloud,flash_edge+smoothstep(.04,.28,age)*.65);
 float coverage=1.0-smoothstep(-.009,.009,cloud);
 float ink=1.0-smoothstep(-.055,-.023,cloud);
 float hot=1.0-smoothstep(-.11,.035,inner+age*.19);
 vec3 color=mix(vec3(.055,.012,.04),pigment.rgb,ink);
 color=mix(color,vec3(1.0,.68,.025),hot);
 float core=(1.0-smoothstep(-.12,-.02,flash_edge))*(1.0-smoothstep(.06,.30,age));
 color=mix(color,vec3(1.0,.96,.65),core);
 float curl=(1.0-smoothstep(.012,.028,abs(inner+.06)))*smoothstep(.03,.14,age);
 color=mix(color,pigment.rgb*.48,curl*.72);
 float fade=1.0-smoothstep(.35,.86,age);
 ALBEDO=color;EMISSION=color*(.42+core*.8)*(1.0-age);
 ALPHA=coverage*fade;
}

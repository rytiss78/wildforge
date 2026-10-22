shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
// Camera-facing impact star: dark ink rim, pigment body, white-hot core.
// points = number of spikes; stretch > 1 squashes it into a slash.
uniform float age=0.0;
uniform vec4 pigment:source_color=vec4(1.0,.8,.3,1.0);
uniform float points=6.0;
uniform float stretch=1.0;
uniform float twist=0.0;
void vertex(){
 MODELVIEW_MATRIX=VIEW_MATRIX*mat4(INV_VIEW_MATRIX[0]*length(MODEL_MATRIX[0].xyz),INV_VIEW_MATRIX[1]*length(MODEL_MATRIX[1].xyz),INV_VIEW_MATRIX[2]*length(MODEL_MATRIX[2].xyz),MODEL_MATRIX[3]);
}
void fragment(){
 vec2 p=(UV-.5)*2.0;
 float c=cos(twist),s=sin(twist);p=mat2(vec2(c,s),vec2(-s,c))*p;p.y*=stretch;
 float grow=.45+.55*(1.0-exp(-age*16.0));
 p/=grow;
 float r=length(p);float a=atan(p.y,p.x);
 float spikes=pow(abs(cos(a*points*.5)),7.0);
 float star=r-(.22+.72*spikes)*(1.0-age*.55);
 float coverage=1.0-smoothstep(-.02,.02,star);
 float body=1.0-smoothstep(-.11,-.06,star);
 float core=(1.0-smoothstep(.0,.30,r))*(1.0-smoothstep(.0,.55,age));
 vec3 color=mix(vec3(.05,.02,.04),pigment.rgb,body);
 color=mix(color,vec3(1.0,.97,.86),core);
 ALBEDO=color;EMISSION=color*(.5+core)*(1.0-age);
 ALPHA=coverage*(1.0-smoothstep(.45,1.0,age));
}

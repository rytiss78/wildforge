shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never,shadows_disabled;
// Inferno nova. On the ground plane (wall=0) it draws a burning band at the
// unit radius with ink edges and a scorched trail inside; on the open cylinder
// wall (wall=1) it draws flame tongues rising from that band.
uniform vec4 pigment:source_color=vec4(1.0,.45,.1,1.0);
uniform float wall=0.0;
uniform float fade=1.0;
void fragment(){
 vec3 hot=vec3(1.0,.9,.45);vec3 ink=vec3(.18,.03,.02);
 if(wall<.5){
  vec2 p=UV*2.0-1.0;float r=length(p);float a=atan(p.y,p.x);
  float wobble=sin(a*23.0+TIME*9.0)*.012+sin(a*7.0-TIME*4.0)*.01;
  float band=1.0-smoothstep(.0,.05,abs(r-.94+wobble));
  float rim=1.0-smoothstep(.05,.075,abs(r-.94+wobble));
  float trail=smoothstep(.55,.92,r)*(1.0-smoothstep(.92,.95,r));
  vec3 color=mix(ink,pigment.rgb,rim);
  color=mix(color,hot,band*.75);
  ALBEDO=color;EMISSION=color*.5;
  ALPHA=max(rim,trail*.35)*fade;
 } else {
  float u=UV.x;float v=1.0-UV.y;
  float tongue=.55+.45*sin(u*6.2832*28.0+TIME*7.0)*sin(u*6.2832*9.0-TIME*3.0);
  float edge=v-tongue;
  float body=1.0-smoothstep(-.06,.0,edge);
  float outline=1.0-smoothstep(.0,.05,edge);
  vec3 color=mix(ink,mix(pigment.rgb,hot,1.0-smoothstep(.0,.6,v)),body);
  ALBEDO=color;EMISSION=color*.55;
  ALPHA=outline*fade;
 }
}

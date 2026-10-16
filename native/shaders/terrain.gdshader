shader_type spatial;
uniform bool red_moon=false;
render_mode diffuse_toon;
uniform sampler2D t0:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D t1:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D t2:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D t3:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D t4:source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D t5:source_color,filter_linear_mipmap,repeat_enable;
uniform float phase=0.0;
varying vec3 p;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
vec3 biome_paint(float b,vec2 uv) {
 vec3 paint;vec3 base;
 if(b>4.5){paint=texture(t5,uv).rgb;base=vec3(.13,.075,.22);}
 else if(b>3.5){paint=texture(t4,uv).rgb;base=vec3(.27,.105,.065);}
 else if(b>2.5){paint=texture(t3,uv).rgb;base=vec3(.28,.36,.40);}
 else if(b>1.5){paint=texture(t2,uv).rgb;base=vec3(.12,.19,.29);}
 else if(b>.5){paint=texture(t1,uv).rgb;base=vec3(.09,.17,.12);}
 else {
   vec3 stone=texture(t0,p.xz*.15).rgb;
   // Keep shadows legible while letting the painted stone and moss read at gameplay distance.
   float value=dot(stone,vec3(.2126,.7152,.0722));
   float facet=smoothstep(.012,.28,value);
   vec3 slate=mix(vec3(.035,.052,.065),vec3(.12,.16,.18),facet);
   float islands=sin(p.x*.14+sin(p.z*.09)*2.0)+cos(p.z*.18+p.x*.03);
   float moss=smoothstep(-.3,1.3,islands);
   float detail=texture(t1,p.xz*.38).g;
   vec3 green=mix(vec3(.045,.12,.075),vec3(.10,.25,.14),detail);
   return mix(slate,green,moss*.84);
 }
 float wash=sin(uv.x*.57+sin(uv.y*.8))*.025+cos(uv.y*.66)*.02;
 float grain=dot(paint,vec3(.299,.587,.114));
 float texture_value=mix(.72,1.14,clamp(grain,0.0,1.0));
 return base*texture_value+vec3(wash*.5);
}
void fragment(){
 vec2 uv=p.xz*.042;
 float angle=mod(atan(p.z,p.x)+phase+6.2831853,6.2831853)/1.04719755;
 float index=floor(angle);float fraction=fract(angle);
 float width=clamp(12.0/max(length(p.xz),1.0),.004,.20);
 vec3 paint=biome_paint(index,uv);
 if(fraction<width){paint=mix(biome_paint(mod(index+5.0,6.0),uv),paint,smoothstep(-width,width,fraction));}
 else if(fraction>1.0-width){paint=mix(paint,biome_paint(mod(index+1.0,6.0),uv),smoothstep(1.0-width,1.0+width,fraction));}
 if(length(p.xz)<69.0) paint=mix(biome_paint(0.0,uv),paint,smoothstep(61.0,69.0,length(p.xz)));
 float path=1.0-smoothstep(2.2,3.5,abs(p.x+sin(p.z*.035)*9.0));
 float a=atan(p.z,p.x);
 float coast=344.0+24.0*sin(3.0*(a+phase))+14.0*sin(5.0*(a-phase))+8.0*cos(7.0*(a+phase*.5));
 paint=mix(paint,vec3(.075,.061,.043),smoothstep(coast-22.0,coast-3.0,length(p.xz)));
 if(red_moon) paint=vec3(.16,.045,.027)*(0.7+texture(t2,uv).r*.5);
 ALBEDO=mix(paint,paint*1.06+vec3(.012,.008,.002),path*.4);ROUGHNESS=1.0;SPECULAR=0.0;
}

shader_type spatial;
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
 if(b>4.5){paint=texture(t5,uv).rgb;base=vec3(.065,.038,.11);}
 else if(b>3.5){paint=texture(t4,uv).rgb;base=vec3(.13,.053,.044);}
 else if(b>2.5){paint=texture(t3,uv).rgb;base=vec3(.18,.23,.25);}
 else if(b>1.5){paint=texture(t2,uv).rgb;base=vec3(.075,.10,.16);}
 else if(b>.5){paint=texture(t1,uv).rgb;base=vec3(.045,.08,.065);}
 else {
   vec3 stone=texture(t0,p.xz*.07).rgb;
   // Quiet slate values leave the bright range to actors, lights and combat.
   // Remap the painted facets; gold chips and moss must not glow across the floor.
   float value=dot(stone,vec3(.2126,.7152,.0722));
   float facet=smoothstep(.012,.28,value);
   return mix(vec3(.028,.038,.055),vec3(.105,.145,.155),facet);
 }
 float wash=sin(uv.x*.57+sin(uv.y*.8))*.025+cos(uv.y*.66)*.02;
 float grain=dot(paint,vec3(.299,.587,.114));
 return base*(.82+grain*.9)+vec3(wash*.55);
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
 paint=mix(paint,vec3(.19,.15,.09),smoothstep(coast-22.0,coast-3.0,length(p.xz)));
 ALBEDO=mix(paint,paint*1.06+vec3(.012,.008,.002),path*.4);ROUGHNESS=1.0;SPECULAR=0.0;
}

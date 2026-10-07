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
 if(b>4.5){paint=texture(t5,uv).rgb;base=vec3(.20,.15,.28);}
 else if(b>3.5){paint=texture(t4,uv).rgb;base=vec3(.39,.21,.16);}
 else if(b>2.5){paint=texture(t3,uv).rgb;base=vec3(.43,.55,.57);}
 else if(b>1.5){paint=texture(t2,uv).rgb;base=vec3(.24,.30,.38);}
 else if(b>.5){paint=texture(t1,uv).rgb;base=vec3(.16,.27,.23);}
 else {paint=texture(t0,uv).rgb;base=vec3(.16,.29,.12);}
 float wash=sin(uv.x*.57+sin(uv.y*.8))*.025+cos(uv.y*.66)*.02;
 return mix(base,paint,.19)+vec3(wash);
}
void fragment(){
 vec2 uv=p.xz*.085;
 float angle=mod(atan(p.z,p.x)+phase+6.2831853,6.2831853)/1.04719755;
 float index=floor(angle);float fraction=fract(angle);
 float width=clamp(12.0/max(length(p.xz),1.0),.004,.20);
 vec3 paint=biome_paint(index,uv);
 if(fraction<width){paint=mix(biome_paint(mod(index+5.0,6.0),uv),paint,smoothstep(-width,width,fraction));}
 else if(fraction>1.0-width){paint=mix(paint,biome_paint(mod(index+1.0,6.0),uv),smoothstep(1.0-width,1.0+width,fraction));}
 if(length(p.xz)<69.0) paint=mix(biome_paint(0.0,uv),paint,smoothstep(61.0,69.0,length(p.xz)));
 float path=1.0-smoothstep(2.2,3.5,abs(p.x+sin(p.z*.035)*9.0));
 paint=mix(paint,vec3(.79,.68,.43),smoothstep(349.0,369.0,max(abs(p.x),abs(p.z))));
 ALBEDO=mix(paint,paint*.8+vec3(.13,.10,.06),path*.65);EMISSION=paint*.035;ROUGHNESS=1.0;SPECULAR=0.0;
}

shader_type spatial;
render_mode diffuse_toon;
void vertex(){vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;VERTEX.x+=sin(TIME*2.0+p.x*.7)*VERTEX.y*.18;VERTEX.z+=cos(TIME*1.4+p.z*.4)*VERTEX.y*.1;}
void fragment(){ALBEDO=COLOR.rgb;ROUGHNESS=1.0;SPECULAR=0.0;}

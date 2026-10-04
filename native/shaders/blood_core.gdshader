shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform float fill : hint_range(0.0,1.0) = 1.0;
uniform float hit : hint_range(0.0,1.0) = 0.0;
uniform float radius = 0.5;
varying vec3 world_position;
varying float centre_y;
varying float radius_y;

void vertex() {
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	centre_y=MODEL_MATRIX[3].y;
	radius_y=length(MODEL_MATRIX[1].xyz)*radius;
}

void fragment() {
	float height=(world_position.y-centre_y)/max(radius_y*2.0,0.001)+0.5;
	float surface=fill+sin(TIME*3.0+world_position.x*8.0)*0.009*step(0.02,fill)*step(fill,0.98);
	float blood=(1.0-smoothstep(surface-0.008,surface+0.008,height))*step(0.002,fill);
	float rim=pow(1.0-clamp(dot(normalize(NORMAL),normalize(VIEW)),0.0,1.0),2.3);
	vec3 empty_glass=mix(vec3(0.66,0.83,0.76),vec3(0.22,0.48,0.47),rim*0.75);
	vec3 red=mix(vec3(0.36,0.012,0.027),vec3(0.65,0.047,0.049),height);
	vec3 liquid=red;
	vec3 color=mix(empty_glass,liquid,blood*(1.0-rim*0.3));
	float meniscus=(1.0-smoothstep(0.008,0.021,abs(height-surface)))*step(0.015,fill)*step(fill,0.985);
	color=mix(color,vec3(1.0,0.64,0.48),meniscus*0.7);
	// Broken ink lines reinforce current damage without replacing the level readout.
	vec2 p=UV;
	float crack_path=0.26+abs(p.y-0.48)*0.24+sin(p.y*49.0)*0.009;
	float crack=(1.0-smoothstep(0.002,0.006,abs(p.x-crack_path)))*step(0.2,p.y)*step(p.y,0.85)*step(fill,0.65);
	float crack2=(1.0-smoothstep(0.002,0.006,abs(p.x-(0.67+sin(p.y*27.0)*0.022))))*step(0.34,p.y)*step(p.y,0.67)*step(fill,0.25);
	color=mix(color,vec3(0.16,0.30,0.30),max(crack,crack2)*0.8);
	float reflection=(1.0-smoothstep(0.019,0.037,abs(UV.x-0.18)))*smoothstep(0.30,0.48,UV.y)*(1.0-smoothstep(0.69,0.77,UV.y));
	vec3 n=normalize(NORMAL);
	float glass_arc=(1.0-smoothstep(0.04,0.10,abs(n.x+0.47)))*smoothstep(0.05,0.25,n.y)*(1.0-smoothstep(0.55,0.80,n.y));
	reflection=max(reflection,glass_arc*0.85);
	color=mix(color,vec3(0.97,0.96,0.82),reflection*0.8);
	ALBEDO=mix(color,vec3(1.0,0.83,0.58),hit*0.35);
	ROUGHNESS=0.85;
	EMISSION=color*(0.025+fill*0.10)+vec3(0.96,0.77,0.5)*rim*0.06;
}

shader_type spatial;
// Glass health orb (October 31, user: "can HP orbs be transparent when empty, made
// of glass"). The liquid is near-solid; the empty part is clear glass with a bright
// fresnel rim, so the far inside wall (drawn too: cull_disabled) shows the liquid
// level as a real volume. clear_glass=false keeps the old opaque look for orbs set
// into a solid head (the final boss's eyes), where clear glass would show its hollow.
render_mode blend_mix, cull_disabled, depth_draw_never, diffuse_toon, specular_disabled;

uniform float fill : hint_range(0.0,1.0) = 1.0;
uniform float hit : hint_range(0.0,1.0) = 0.0;
uniform float radius = 0.5;
uniform bool clear_glass = true;
// The liquid's bright colour; the default is the enemies' blood red. The final
// boss changes it with each phase.
uniform vec3 liquid_color = vec3(0.98,0.025,0.08);
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
	float rim=pow(1.0-clamp(abs(dot(normalize(NORMAL),normalize(VIEW))),0.0,1.0),2.3);
	vec3 red=mix(liquid_color*vec3(0.204,0.24,0.325),liquid_color,floor(height*5.0)/4.0);
	if (!FRONT_FACING) {
		// The far inside wall: liquid seen through the glass, a little darker.
		if (!clear_glass) discard;
		ALBEDO=red*0.7;
		ALPHA=blood*0.9;
		EMISSION=red*0.08*blood;
		ROUGHNESS=0.6;
	} else {
		vec3 empty_glass=clear_glass ? mix(vec3(0.70,0.88,0.92),vec3(0.92,0.98,1.0),rim) : mix(vec3(0.18,0.32,0.29),vec3(0.035,0.09,0.09),rim*0.75);
		vec3 color=mix(empty_glass,red,blood*(1.0-rim*0.3));
		float meniscus=(1.0-smoothstep(0.008,0.021,abs(height-surface)))*step(0.015,fill)*step(fill,0.985);
		color=mix(color,vec3(1.0,0.64,0.48),meniscus*0.7);
		// Broken ink lines reinforce current damage without replacing the level readout.
		vec2 p=UV;
		float crack_path=0.26+abs(p.y-0.48)*0.24+sin(p.y*49.0)*0.009;
		float crack=(1.0-smoothstep(0.003,0.009,abs(p.x-crack_path)))*step(0.2,p.y)*step(p.y,0.85)*step(fill,0.65);
		float crack2=(1.0-smoothstep(0.002,0.006,abs(p.x-(0.67+sin(p.y*27.0)*0.022))))*step(0.34,p.y)*step(p.y,0.67)*step(fill,0.25);
		float cracks=max(crack,crack2);
		color=mix(color,vec3(0.86,0.97,1.0),cracks*0.85);
		float reflection=(1.0-smoothstep(0.019,0.037,abs(UV.x-0.18)))*smoothstep(0.30,0.48,UV.y)*(1.0-smoothstep(0.69,0.77,UV.y));
		vec3 n=normalize(NORMAL);
		float glass_arc=(1.0-smoothstep(0.04,0.10,abs(n.x+0.47)))*smoothstep(0.05,0.25,n.y)*(1.0-smoothstep(0.55,0.80,n.y));
		reflection=max(reflection,glass_arc*0.85);
		color=mix(color,vec3(0.97,0.96,0.82),reflection*0.8);
		// Broken bronze bezel and ink edge frame the liquid without covering its level.
		float bezel=smoothstep(.55,.73,rim)*(1.0-smoothstep(.9,.99,rim));
		float engraving=step(.38,fract(UV.x*12.0));
		color=mix(color,mix(vec3(.26,.16,.05),vec3(.80,.57,.20),engraving),bezel*.9);
		float edge=smoothstep(.94,1.0,rim);
		color=mix(color,vec3(.018,.025,.036),edge);
		ALBEDO=mix(color,vec3(1.0,0.83,0.58),hit*0.35);
		// Clear glass: the liquid is solid, the empty glass mostly see-through.
		float glass=clear_glass ? 0.14+rim*0.5 : 1.0;
		ALPHA=clamp(max(max(glass,blood*0.96),max(max(reflection*0.8,bezel*0.9),max(edge,max(meniscus*0.8,max(cracks*0.7,hit*0.5))))),0.0,1.0);
		ROUGHNESS=clear_glass ? 0.25 : 0.85;
		EMISSION=color*(0.025+fill*0.10)+vec3(0.96,0.77,0.5)*rim*0.16;
	}
}

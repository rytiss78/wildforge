shader_type spatial;
// Cartoon creatures: flat toon paint from vertex colour, a warm rim and a little
// self-light so they stand out from any ground, a white flash when hit, and the
// shared hooks the rest of the game drives on every enemy material (tint for
// statuses, corruption for the Eclipse, dissolve for death).
render_mode diffuse_toon, specular_disabled;
#include "res://shaders/cartoon_creature.gdshaderinc"

uniform vec3 tint = vec3(1.0);
uniform float corruption = 0.0;
uniform float dissolve = 0.0;
uniform vec3 rim_color = vec3(1.0, 0.85, 0.6);
uniform float rim_strength = 0.9;
uniform float self_light = 0.25;
varying vec3 local_position;

void vertex() {
	local_position = VERTEX;
	VERTEX = creature_deform(VERTEX, UV2, UV);
}

void fragment() {
	float melt = 0.0;
	if (dissolve > 0.0) {
		vec3 q = local_position * 4.0 / size;
		float n = 0.5 + 0.25 * sin(q.x * 1.7 + sin(q.y * 2.3)) + 0.25 * sin(q.z * 2.1 + q.y * 1.3 + sin(q.x * 1.1));
		float t = n * 0.65 + (1.0 - clamp(local_position.y / (2.4 * size), 0.0, 1.0)) * 0.35;
		if (t < dissolve) discard;
		melt = 1.0 - smoothstep(dissolve, dissolve + 0.12, t);
	}
	vec3 paint = pow(COLOR.rgb, vec3(2.2)) * tint;
	paint = mix(paint, paint * vec3(0.48, 0.38, 0.57), corruption);
	paint = mix(paint, vec3(1.0), clamp(hurt * 3.0, 0.0, 0.45));
	ALBEDO = mix(paint, vec3(0.03, 0.035, 0.05), max(melt, dissolve * 0.75));
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	EMISSION = (rim_color * rim * rim_strength + ALBEDO * self_light) * (1.0 - dissolve);
	// Alpha below 0.6 marks glowing parts: alien eyes, bulbs and spots.
	if (COLOR.a < 0.6) EMISSION += paint * 1.6;
	EMISSION += vec3(0.32, 0.14, 0.5) * melt * 0.7;
}

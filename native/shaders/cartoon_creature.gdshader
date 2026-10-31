shader_type spatial;
// Cartoon creatures: toon paint from vertex colour, a warm rim and a little
// self-light so they stand out from any ground, a white flash when hit, and the
// shared hooks the rest of the game drives on every enemy material (tint for
// statuses, corruption for the Eclipse, dissolve for death).
//
// October 31 (user: "monsters look too basic"): painterly detail on top of the
// flat primitives, all in the shader so every species gets it at no mesh cost:
//   - three-band cel light with a toon gloss spot and cool, purple-blue shadows
//   - countershading: lighter belly, darker back, darker feet
//   - a skin pattern per species (pattern 1 spots, 2 stripes, 3 scales, 4 freckles),
//     only on saturated body paint, never on eyes, teeth, pupils or glowing parts
render_mode cull_back;
#include "res://shaders/cartoon_creature.gdshaderinc"

uniform vec3 tint = vec3(1.0);
uniform float corruption = 0.0;
uniform float dissolve = 0.0;
uniform vec3 rim_color = vec3(1.0, 0.85, 0.6);
uniform float rim_strength = 0.9;
uniform float self_light = 0.25;
uniform int pattern = 0;
uniform float pattern_scale = 1.0;
uniform float gloss = 0.5;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
	VERTEX = creature_deform(VERTEX, UV2, UV);
}

vec3 hash3(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)), dot(p, vec3(269.5, 183.3, 246.1)), dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453);
}

float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash3(i).x, b = hash3(i + vec3(1, 0, 0)).x, c = hash3(i + vec3(0, 1, 0)).x, d = hash3(i + vec3(1, 1, 0)).x;
	float e = hash3(i + vec3(0, 0, 1)).x, g = hash3(i + vec3(1, 0, 1)).x, h = hash3(i + vec3(0, 1, 1)).x, k = hash3(i + vec3(1, 1, 1)).x;
	return mix(mix(mix(a, b, f.x), mix(c, d, f.x), f.y), mix(mix(e, g, f.x), mix(h, k, f.x), f.y), f.z);
}

// Distances to the nearest and second-nearest jittered cell point.
vec2 cells(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			for (int z = -1; z <= 1; z++) {
				vec3 o = vec3(float(x), float(y), float(z));
				vec3 r = o + hash3(i + o) * 0.8 + 0.1 - f;
				float d = dot(r, r);
				if (d < d1) { d2 = d1; d1 = d; } else if (d < d2) { d2 = d; }
			}
		}
	}
	return sqrt(vec2(d1, d2));
}

// 0..1: how strongly the pattern marks this point.
float skin_mark(vec3 q) {
	if (pattern == 1) {
		vec2 c = cells(q * 3.6);
		return 1.0 - smoothstep(0.36, 0.44, c.x);
	} else if (pattern == 2) {
		float wave = sin(q.y * 11.0 + value_noise(q * 2.0) * 4.0 + q.x * 1.6);
		return smoothstep(0.35, 0.55, wave);
	} else if (pattern == 3) {
		vec2 c = cells(q * 5.0);
		return 1.0 - smoothstep(0.06, 0.14, c.y - c.x);
	} else if (pattern == 4) {
		vec2 c = cells(q * 8.0);
		float freckle = 1.0 - smoothstep(0.22, 0.3, c.x);
		return max(freckle, smoothstep(0.62, 0.8, value_noise(q * 1.8)) * 0.6);
	}
	return 0.0;
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
	vec3 paint = pow(COLOR.rgb, vec3(2.2));
	bool glowing = COLOR.a < 0.6;
	float part = UV2.x;
	// Skin detail only on coloured body, legs and tails: not white eye balls, black
	// pupils and mouths, pale teeth, or glowing bits.
	float high = max(COLOR.r, max(COLOR.g, COLOR.b));
	float low = min(COLOR.r, min(COLOR.g, COLOR.b));
	float saturation = (high - low) / max(high, 0.001);
	float skin = smoothstep(0.16, 0.32, saturation) * smoothstep(0.12, 0.25, high) * float(!glowing) * float(part < 1.5 || (part > 4.5 && part < 5.5));
	if (skin > 0.0) {
		vec3 q = local_position / max(size, 0.01) * 3.0 * pattern_scale;
		float mark = skin_mark(q) * skin;
		float bright = dot(paint, vec3(0.299, 0.587, 0.114));
		// Dark marks on light skin, light marks on dark skin; hue-shifted toward violet.
		vec3 marked = bright > 0.08 ? paint * vec3(0.52, 0.46, 0.62) : paint * 2.2 + vec3(0.04, 0.03, 0.06);
		paint = mix(paint, marked, mark * 0.85);
		// Soft mottling everywhere on skin so no surface is perfectly flat.
		paint *= mix(1.0, 0.8 + 0.36 * value_noise(q * 3.5), skin);
		// Countershading: belly up to 22% lighter, back darker, feet in shade.
		vec3 n = normalize(local_normal);
		paint *= mix(1.0, 1.0 + 0.22 * clamp(-n.y, 0.0, 1.0) - 0.14 * clamp(n.y, 0.0, 1.0), skin);
		paint *= mix(1.0, 0.7 + 0.3 * smoothstep(0.0, 0.22, local_position.y / max(size, 0.01)), skin);
	}
	paint *= tint;
	paint = mix(paint, paint * vec3(0.48, 0.38, 0.57), corruption);
	paint = mix(paint, vec3(1.0), clamp(hurt * 3.0, 0.0, 0.45));
	ALBEDO = mix(paint, vec3(0.03, 0.035, 0.05), max(melt, dissolve * 0.75));
	ROUGHNESS = 1.0;
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2);
	// Self-light tinted cool, so the unlit side reads blue-violet, not grey.
	EMISSION = (rim_color * rim * rim_strength + ALBEDO * self_light * vec3(0.82, 0.86, 1.18)) * (1.0 - dissolve);
	// Alpha below 0.6 marks glowing parts: alien eyes, bulbs and spots.
	if (glowing) EMISSION += paint * 1.6;
	EMISSION += vec3(0.32, 0.14, 0.5) * melt * 0.7;
}

// Three-band cel light (shadow, mid, lit) and a hard toon gloss spot.
void light() {
	float ndl = dot(NORMAL, LIGHT);
	float band = smoothstep(-0.08, 0.02, ndl) * 0.62 + smoothstep(0.42, 0.5, ndl) * 0.38;
	vec3 colour = LIGHT_COLOR / PI;
	DIFFUSE_LIGHT += colour * band * ATTENUATION * 1.15;
	float h = dot(normalize(VIEW + LIGHT), NORMAL);
	SPECULAR_LIGHT += LIGHT_COLOR * smoothstep(0.955, 0.97, h) * ATTENUATION * gloss * 0.35;
}

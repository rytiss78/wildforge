shader_type spatial;
// The island's hanging rock belly (Underside, October 31): layered earth and stone
// strata, roots near the lip, and veins glowing in the biome's colour, faintly
// self-lit so it reads in the dark under the island. Faces point down.
render_mode diffuse_toon, specular_disabled;

uniform float phase = 0.0;
uniform vec3 glow0 : source_color = vec3(0.35, 0.93, 0.73);
uniform vec3 glow1 : source_color = vec3(0.72, 0.9, 0.42);
uniform vec3 glow2 : source_color = vec3(0.46, 0.79, 1.0);
uniform vec3 glow3 : source_color = vec3(0.56, 0.91, 0.93);
uniform vec3 glow4 : source_color = vec3(1.0, 0.52, 0.32);
uniform vec3 glow5 : source_color = vec3(0.81, 0.56, 1.0);
uniform vec3 glow6 : source_color = vec3(0.71, 1.0, 0.23);
varying vec3 p;

void vertex() {
	p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float hash(vec2 q) { return fract(sin(dot(q, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 q) {
	vec2 i = floor(q); vec2 f = fract(q); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}

vec3 glow_of(float index) {
	if (index < 0.5) return glow0;
	if (index < 1.5) return glow1;
	if (index < 2.5) return glow2;
	if (index < 3.5) return glow3;
	if (index < 4.5) return glow4;
	if (index < 5.5) return glow5;
	return glow6;
}

void fragment() {
	float angle = mod(atan(p.z, p.x) + phase + 6.2831853, 6.2831853) / 0.8975979;
	float biome = length(p.xz) < 65.0 ? 0.0 : min(floor(angle), 6.0);
	// Strata: bands by depth, wobbling around the island.
	float depth = -p.y;
	float wobble = noise(p.xz * 0.05) * 3.0 + sin(atan(p.z, p.x) * 9.0) * 0.6;
	float band = fract((depth + wobble) / 5.0);
	vec3 earth = vec3(0.24, 0.16, 0.11);
	vec3 stone = vec3(0.30, 0.29, 0.33);
	vec3 dark = vec3(0.13, 0.11, 0.13);
	vec3 rock = mix(earth, stone, smoothstep(0.3, 0.7, band));
	rock = mix(rock, dark, smoothstep(0.85, 0.95, band) * 0.8);
	rock *= 0.8 + 0.4 * noise(p.xz * 0.6 + vec2(depth));
	// Fine grit and dark cracks, so the rock up close is not a smooth smear.
	rock *= 0.85 + 0.3 * noise(p.xz * 3.1 + vec2(p.y * 2.0));
	float crack = 1.0 - smoothstep(0.01, 0.03, abs(noise(p.xz * 0.7 + vec2(p.y * 0.4)) - 0.5));
	rock = mix(rock, rock * 0.45, crack * 0.7);
	// Root tangles just under the lip.
	float roots = smoothstep(0.55, 0.9, noise(vec2(atan(p.z, p.x) * 40.0, depth * 0.6))) * (1.0 - smoothstep(14.0, 20.0, depth));
	rock = mix(rock, vec3(0.32, 0.22, 0.12), roots * 0.8);
	// Glowing veins in the biome's colour.
	// Thin veins, only in some patches, from noise over all three axes (no stripes on
	// the rim's wall).
	vec2 q = p.xz * 0.11 + vec2(p.y * 0.21, -p.y * 0.17);
	float vein = 1.0 - smoothstep(0.002, 0.006, abs(noise(q) - 0.5));
	vein *= smoothstep(0.68, 0.82, noise(p.xz * 0.025 + vec2(p.y * 0.05)));
	vec3 glow = glow_of(biome);
	ALBEDO = mix(rock, glow, vein * 0.5);
	ROUGHNESS = 1.0;
	EMISSION = rock * 0.22 + glow * vein * 0.7;
}

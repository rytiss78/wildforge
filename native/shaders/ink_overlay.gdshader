// Screen-space ink: one consistent outline over terrain, props, heroes and
// enemies, plus a soft vignette. Outputs only translucent ink, so transparent
// effects drawn earlier are never replaced by a stale screen copy.
shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, cull_disabled, fog_disabled, shadows_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D normal_tex : hint_normal_roughness_texture, filter_nearest;
uniform vec3 ink_color : source_color = vec3(0.035, 0.03, 0.045);
uniform float thickness = 1.25;
uniform float depth_threshold = 0.06;
uniform float normal_threshold = 0.55;
uniform float fade_start = 22.0;
uniform float fade_end = 70.0;
uniform float strength = 0.9;
uniform float vignette = 0.42;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float linear_depth(vec2 uv, mat4 inv_projection) {
	float raw = texture(depth_tex, uv).r;
	vec4 view = inv_projection * vec4(uv * 2.0 - 1.0, raw, 1.0);
	return -view.z / view.w;
}

vec3 view_normal(vec2 uv) {
	return texture(normal_tex, uv).xyz * 2.0 - 1.0;
}

void fragment() {
	vec2 px = thickness / VIEWPORT_SIZE;
	vec2 uv = SCREEN_UV;
	float center = linear_depth(uv, INV_PROJECTION_MATRIX);
	float edge = 0.0;
	// The sky sits at the far plane and gets no ink.
	if (center < 170.0) {
		vec3 n = view_normal(uv);
		float depth_edge = 0.0;
		float normal_edge = 0.0;
		vec2 offsets[4] = vec2[](vec2(px.x, 0.0), vec2(-px.x, 0.0), vec2(0.0, px.y), vec2(0.0, -px.y));
		int farther = 0;
		for (int i = 0; i < 4; i++) {
			// An edge must hold one and two pixels out; camera-fade dither alternates
			// pixel by pixel and would otherwise read as ink stipple.
			float d1 = linear_depth(uv + offsets[i], INV_PROJECTION_MATRIX);
			float d2 = linear_depth(uv + offsets[i] * 2.0, INV_PROJECTION_MATRIX);
			// Relative depth steps outline silhouettes against what is behind them.
			float step_size = (min(d1, d2) - center) / max(center, 0.5);
			depth_edge = max(depth_edge, step_size);
			if ((d1 - center) / max(center, 0.5) > depth_threshold) farther++;
			float bend1 = 1.0 - dot(n, view_normal(uv + offsets[i]));
			float bend2 = 1.0 - dot(n, view_normal(uv + offsets[i] * 2.0));
			normal_edge = max(normal_edge, min(bend1, bend2));
		}
		edge = max(smoothstep(depth_threshold, depth_threshold * 2.5, depth_edge), smoothstep(normal_threshold, normal_threshold + 0.3, normal_edge) * 0.75);
		// A pixel nearer than 3+ neighbours is camera-fade dither, not a silhouette.
		if (farther >= 3) edge = 0.0;
		edge *= 1.0 - smoothstep(fade_start, fade_end, center);
	}
	vec2 centered = uv - 0.5;
	float vig = smoothstep(0.35, 0.85, length(centered * vec2(1.0, 0.85))) * vignette;
	ALBEDO = ink_color;
	ALPHA = clamp(max(edge * strength, vig), 0.0, 1.0);
}

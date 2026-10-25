shader_type spatial;
// Inverted-hull cartoon outline: the back faces, pushed out along the normal and
// drawn flat ink-black, leave a bold line around every part (CartoonAlienRig).
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform float width = 0.028;
uniform vec4 ink : source_color = vec4(0.05, 0.035, 0.06, 1.0);

void vertex() {
	VERTEX += NORMAL * width;
}

void fragment() {
	ALBEDO = ink.rgb;
}

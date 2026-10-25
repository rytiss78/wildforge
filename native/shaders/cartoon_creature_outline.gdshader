shader_type spatial;
// The bold ink outline around a cartoon creature: back faces pushed out along the
// normal, after the same animation as the paint pass.
render_mode unshaded, cull_front, shadows_disabled;
#include "res://shaders/cartoon_creature.gdshaderinc"

uniform float width = 0.03;
uniform vec4 ink : source_color = vec4(0.05, 0.035, 0.06, 1.0);

void vertex() {
	VERTEX = creature_deform(VERTEX, UV2, UV) + NORMAL * width * size;
}

void fragment() {
	ALBEDO = ink.rgb;
}

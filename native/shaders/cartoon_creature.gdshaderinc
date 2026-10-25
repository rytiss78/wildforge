// Shared vertex animation for the cartoon creatures (CartoonCreatureRig). Every
// creature is one merged mesh: COLOR is its paint, UV2.x the part kind, UV2.y a
// per-part phase, UV.x the part's pivot (height, or side distance for wings) and
// UV.y its swing strength. Both the paint pass and the outline pass run this, so
// the ink line moves with the body.
//   0 body   jelly wobble, hop while walking, lean into an attack
//   1 leg    swings about its hip (UV.x = hip height)
//   2 stalk  eyes and antennae sway from their base (UV.x = base height)
//   3 jaw    drops open on an attack
//   4 wing   flaps; the tips move most (UV.x = root distance from the middle)
//   5 tail   tentacles and tails wave below/behind their root (UV.x = root height)
//   6 pupil  wobbles with the body and darts to a new spot now and then
uniform float clock = 0.0;
uniform float moving = 0.0;
uniform float attack = 0.0;
uniform float airborne = 0.0;
uniform float hurt = 0.0;
uniform float size = 1.0;

vec3 creature_deform(vec3 v, vec2 kind, vec2 pivot) {
	float part = kind.x;
	float phase = kind.y * 6.2831;
	float strength = pivot.y;
	float base_y = pivot.x;
	if (part < 0.5 || part > 5.5) {
		float w = sin(clock * 3.2) * 0.035 + abs(sin(clock * 9.0)) * 0.05 * moving;
		v.y *= 1.0 + w;
		v.xz *= 1.0 - w * 0.6;
	}
	if (part < 0.5) {
	} else if (part < 1.5) {
		v.z += sin(clock * 10.0 + phase) * (base_y - v.y) * 0.9 * moving * strength;
	} else if (part < 2.5) {
		float reach = max(0.0, v.y - base_y);
		v.x += sin(clock * 2.3 + phase) * reach * 0.22 * strength;
		v.z += sin(clock * 1.9 + phase * 1.7) * reach * 0.16 * strength;
	} else if (part < 3.5) {
		v.y -= attack * 0.16 * size * strength;
		v.z -= attack * 0.05 * size * strength;
	} else if (part < 4.5) {
		float tip = max(0.0, abs(v.x) - base_y);
		v.y += sin(clock * (11.0 + airborne * 5.0) + phase) * tip * 0.75 * strength;
	} else if (part < 5.5) {
		float hang = max(0.0, base_y - v.y) + max(0.0, v.z) * 0.6;
		v.x += sin(clock * 3.4 + v.y * 5.0 / size + phase) * hang * 0.16 * strength;
		v.z += cos(clock * 2.7 + v.y * 4.0 / size + phase) * hang * 0.1 * strength;
	} else {
		float step = floor(clock * 1.1 + kind.y * 7.0);
		v.x += (fract(sin(step * 12.9898 + phase) * 43758.5) - 0.5) * 0.05 * size * strength;
		v.y += (fract(sin(step * 78.233 + phase) * 24634.6) - 0.5) * 0.04 * size * strength;
	}
	// Everything but the legs hops while walking and leans into an attack.
	if (part > 0.5 && part < 1.5) return v;
	v.y += abs(sin(clock * 9.0)) * 0.06 * size * moving;
	v.z -= attack * 0.12 * max(0.0, v.y);
	v.x += sin(clock * 55.0) * 0.03 * size * hurt;
	return v;
}

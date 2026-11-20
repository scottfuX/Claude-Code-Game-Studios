// Devin: recessed snow contact. Compatibility/desktop, no textures, one SDF.
shader_type spatial;
render_mode cull_disabled;

const float SOLE_LENGTH = 0.4;
const float SOLE_EDGE = 0.95;
const vec3 CENTRE = vec3(0.34, 0.43, 0.53);
const vec3 SOLE_RIM = vec3(0.69, 0.77, 0.83);

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float edge = length(vec2(p.x, max(abs(p.y) - SOLE_LENGTH, 0.0)));
	if (edge > SOLE_EDGE) {
		discard;
	}
	ALBEDO = mix(CENTRE, SOLE_RIM, smoothstep(0.55, SOLE_EDGE, edge));
	ROUGHNESS = 1.0;
}

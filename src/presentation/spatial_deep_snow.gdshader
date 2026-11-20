// Persistent snow heightfield. Compatibility: five vertex reads, one fragment read.
shader_type spatial;

const float WORLD_SIZE = 64.0;
const float FRESH_HEIGHT = 0.28;
const float PACKED_HEIGHT = 0.025;
const float NORMAL_STEP = 0.125;

uniform sampler2D trail_map : filter_linear, repeat_disable;
varying vec2 snow_position;

float compact(vec2 p) {
	return texture(trail_map, p / WORLD_SIZE + vec2(0.5)).r;
}

float height_at(vec2 p) {
	float c = compact(p);
	float drift = sin(p.x * 0.63 + sin(p.y * 0.38)) * cos(p.y * 0.47) * 0.035;
	float berm = 0.065 * smoothstep(0.03, 0.25, c) * (1.0 - smoothstep(0.25, 0.65, c));
	return mix(FRESH_HEIGHT + drift, PACKED_HEIGHT, c) + berm;
}

void vertex() {
	vec2 p = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	snow_position = p;
	VERTEX.y = height_at(p);
	float e = NORMAL_STEP;
	NORMAL = normalize(vec3(height_at(p - vec2(e, 0)) - height_at(p + vec2(e, 0)), 2.0 * e, height_at(p - vec2(0, e)) - height_at(p + vec2(0, e))));
}

void fragment() {
	float c = compact(snow_position);
	ALBEDO = mix(vec3(0.823, 0.888, 0.965), vec3(0.56, 0.67, 0.79), c);
	ROUGHNESS = mix(1.0, 0.72, c);
	SPECULAR = 0.0;
}

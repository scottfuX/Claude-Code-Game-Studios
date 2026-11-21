// Lonefire shaded blue ice and feathered snow bank, desktop Compatibility/Forward+.
// One opaque pass, one filtered mask read; no shader variants.
shader_type spatial;
#include "res://src/presentation/lake_outline.gdshaderinc"

uniform vec2 lake_size;
uniform sampler2D thin_map : filter_linear, repeat_disable;
uniform vec4 ice_color : source_color = vec4(0.18, 0.42, 0.70, 1.0);
uniform vec4 thin_color : source_color = vec4(0.11, 0.34, 0.60, 1.0);
uniform vec4 snow_color : source_color = vec4(0.823, 0.888, 0.965, 1.0);
uniform float shore_blend_width : hint_range(0.1, 5.0) = 1.5;

void fragment() {
	float thin = smoothstep(0.1, 0.9, texture(thin_map, UV).r);
	float edge = lake_edge((UV - vec2(0.5)) * lake_size, lake_size * 0.5);
	float ice_weight = smoothstep(0.0, shore_blend_width, edge);
	ALBEDO = mix(snow_color.rgb, mix(ice_color.rgb, thin_color.rgb, thin), ice_weight);
	EMISSION = vec3(0.015, 0.055, 0.12) * ice_weight;
	ROUGHNESS = mix(0.95, 0.38, ice_weight);
	SPECULAR = mix(0.0, 0.65, ice_weight);
}

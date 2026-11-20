// Lonefire: shaded ice/snow shore for Compatibility and Forward+ on desktop.
// One transparent pass, no texture samples or shader variants.
shader_type spatial;

uniform vec2 lake_size;
uniform float shore_width : hint_range(0.1, 5.0) = 2.0;
uniform float edge_fade : hint_range(0.1, 2.0) = 0.7;
uniform vec4 ice_color : source_color = vec4(0.447, 0.663, 0.847, 1.0);
uniform vec4 snow_color : source_color = vec4(0.94, 0.95, 0.96, 1.0);

void fragment() {
	vec2 edge = (vec2(0.5) - abs(UV - vec2(0.5))) * (lake_size + vec2(shore_width * 2.0));
	float distance_from_edge = min(edge.x, edge.y);
	ALBEDO = mix(snow_color.rgb, ice_color.rgb, smoothstep(0.0, shore_width, distance_from_edge));
	ROUGHNESS = 0.65;
	SPECULAR = 0.4;
	ALPHA = smoothstep(0.0, edge_fade, distance_from_edge);
}

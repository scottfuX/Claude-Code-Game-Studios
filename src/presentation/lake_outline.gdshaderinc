// Lonefire lake presentation: inset rounded shore, desktop Compatibility/Forward+.
// Analytic distance only; gameplay retains the rectangular 0.5 m grid.
float lake_edge(vec2 p, vec2 half_size) {
	const float CORNER_RADIUS = 7.0;
	const float SHORE_INSET = 2.0;
	vec2 q = abs(p) - (half_size - vec2(CORNER_RADIUS));
	float inside = CORNER_RADIUS - length(max(q, vec2(0.0))) - min(max(q.x, q.y), 0.0);
	float ripple = sin(p.x * 0.31 + p.y * 0.13) * 0.65 + sin(p.y * 0.57 - p.x * 0.09) * 0.35;
	return inside - SHORE_INSET - ripple;
}

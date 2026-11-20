class_name HudCanvas extends Control

var view: Dictionary = {}
const INK := Color("e9e2cf")
const EDGE := Color(0.025, 0.05, 0.08, 0.8)

## Returns a centred sixteen-by-nine safe rectangle with a five-percent inset.
func safe_rect() -> Rect2:
	var width := minf(size.x, size.y * 16.0 / 9.0)
	var rect := Rect2(Vector2((size.x - width) * 0.5, 0), Vector2(width, size.y))
	return rect.grow_individual(-width * 0.05, -size.y * 0.05, -width * 0.05, -size.y * 0.05)

func _draw() -> void:
	if view.is_empty() or view.get(&"context", &"") == &"end":
		return
	var safe := safe_rect()
	var anchor := Vector2(safe.position.x + 26, safe.end.y - 30)
	var alpha: float = view.get(&"band_alpha", 1.0)
	_band(anchor, alpha)
	if view.get(&"context", &"") in [&"ritual", &"sleep"]:
		return
	var energy: int = view.get(&"energy_level", 0)
	var energy_anchor := anchor + Vector2(335, 0)
	draw_rect(Rect2(energy_anchor, Vector2(140, 15)), EDGE)
	var energy_color := Color("8ea89b") if energy == 0 else (Color("d2ae65") if energy == 1 else Color("d37d66"))
	draw_rect(Rect2(energy_anchor, Vector2(140 * float(view.get(&"energy_fill", 1.0)), 15)), energy_color)
	var label := tr(&"HUD_ENERGY_NORMAL" if energy == 0 else (&"HUD_ENERGY_TIRED" if energy == 1 else &"HUD_ENERGY_EXHAUSTED"))
	draw_string_outline(ThemeDB.fallback_font, energy_anchor + Vector2(0, -9), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, 4, EDGE)
	draw_string(ThemeDB.fallback_font, energy_anchor + Vector2(0, -9), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
	var trend: int = view.get(&"energy_trend", 0)
	if trend != 0:
		var p := energy_anchor + Vector2(155, 7)
		draw_line(p + Vector2(-6, trend * 5), p + Vector2(0, -trend * 5), INK, 2)
		draw_line(p + Vector2(0, -trend * 5), p + Vector2(6, trend * 5), INK, 2)
	_arc(Vector2(safe.end.x - 65, safe.position.y + 64), float(view.get(&"opacity", 1.0)))
	var progress: float = view.get(&"progress", -1.0)
	if progress >= 0:
		var centre := Vector2(safe.get_center().x, safe.end.y - 68)
		draw_arc(centre, 16, -PI / 2, TAU - PI / 2, 40, EDGE, 6, true)
		draw_arc(centre, 16, -PI / 2, -PI / 2 + TAU * maxf(0.001, progress), 40, INK, 3, true)

func _band(anchor: Vector2, alpha: float) -> void:
	var rect := Rect2(anchor, Vector2(220, 15))
	draw_rect(rect.grow(4), Color(0.025, 0.05, 0.08, 0.65 * alpha))
	var fill: float = view.get(&"fill", 1.0)
	for i in 44:
		var portion := clampf(fill * 44 - i, 0, 1)
		if portion <= 0:
			break
		var color := Color("648da9").lerp(Color("d98b49"), i / 43.0)
		color.a = alpha
		draw_rect(Rect2(anchor + Vector2(i * 5, 0), Vector2(5 * portion, 15)), color)
	var ink := Color(INK, alpha)
	_stroke(PackedVector2Array([anchor + Vector2(-2, -2), anchor + Vector2(70, -3), anchor + Vector2(155, -1), anchor + Vector2(222, -2)]), ink, 1.5)
	_stroke(PackedVector2Array([anchor + Vector2(-2, 17), anchor + Vector2(80, 18), anchor + Vector2(160, 16), anchor + Vector2(222, 17)]), ink, 1.5)
	for temperature: float in [32.0, 34.0, 35.5, 36.5]:
		var x := anchor.x + (temperature - 30.0) / 7.0 * 220
		draw_line(Vector2(x, anchor.y - 3), Vector2(x, anchor.y + 18), Color(INK, 0.3 * alpha), 1.0, true)
	_snowflake(anchor + Vector2(-18, 7), ink)
	var fire := anchor + Vector2(240, 7)
	var flame := PackedVector2Array([fire + Vector2(-7, 8), fire + Vector2(-8, 0), fire + Vector2(2, -12), fire + Vector2(1, -3), fire + Vector2(7, 1), fire + Vector2(6, 8), fire + Vector2(-7, 8)])
	draw_colored_polygon(flame, ink)
	draw_polyline(flame, Color(EDGE, alpha), 2, true)
	var arrow: int = view.get(&"arrow", 0)
	for i in absi(arrow):
		var p := anchor + Vector2(267 + i * 11, 7)
		var direction := 1.0 if arrow > 0 else -1.0
		var triangle := PackedVector2Array([p + Vector2(-4 * direction, -6), p + Vector2(4 * direction, 0), p + Vector2(-4 * direction, 6), p + Vector2(-4 * direction, -6)])
		draw_colored_polygon(triangle, ink)
		draw_polyline(triangle, Color(EDGE, alpha), 2, true)

func _snowflake(p: Vector2, color: Color) -> void:
	for i in 3:
		var v := Vector2.RIGHT.rotated(i * PI / 3) * 8
		draw_line(p - v, p + v, Color(EDGE, color.a), 4, true)
		draw_line(p - v, p + v, color, 2, true)

func _arc(p: Vector2, alpha: float) -> void:
	var ink := Color(INK, alpha)
	draw_arc(p, 48, PI, TAU, 48, Color(EDGE, EDGE.a * alpha), 5, true)
	draw_arc(p, 48, PI, TAU, 48, Color(Color("d3a676"), alpha) if view.get(&"twilight", false) else ink, 2, true)
	var angle := PI + PI * float(view.get(&"arc", 0.5))
	var dot := p + Vector2(cos(angle), sin(angle)) * 48
	draw_circle(dot, 7, ink)
	if view.get(&"moon", false):
		draw_circle(dot + Vector2(3, -3), 6, Color(Color("18283b"), alpha))
	else:
		for i in 8:
			var v := Vector2.RIGHT.rotated(i * TAU / 8)
			draw_line(dot + v * 10, dot + v * 13, ink, 1.5, true)

func _stroke(points: PackedVector2Array, color: Color, width: float) -> void:
	draw_polyline(points, Color(EDGE, EDGE.a * color.a), width + 2, true)
	draw_polyline(points, color, width, true)

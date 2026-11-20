class_name SnowDeformation extends RefCounted

var size: int
var extent: float
var image: Image
var texture: ImageTexture
var dirty: bool = false
var _upload_elapsed: float = 0.0

func _init(resolution: int = 512, world_size: float = 64.0) -> void:
	size = maxi(2, resolution)
	extent = maxf(1.0, world_size)
	image = Image.create(size, size, false, Image.FORMAT_RF)
	image.fill(Color(0, 0, 0, 1))
	texture = ImageTexture.create_from_image(image)

func compaction_at(world_pos: Vector3) -> float:
	if not _inside(world_pos):
		return 0.0
	var uv := (Vector2(world_pos.x, world_pos.z) / extent + Vector2.ONE * 0.5) * (size - 1)
	return image.get_pixel(roundi(uv.x), roundi(uv.y)).r

func speed_factor(world_pos: Vector3, fresh_factor: float) -> float:
	return lerpf(clampf(fresh_factor, 0.1, 1.0), 1.0, compaction_at(world_pos))

func press(world_pos: Vector3, radius: float, strength: float, aspect: float = 1.0, yaw: float = 0.0) -> void:
	if not _inside(world_pos) or not is_finite(radius) or radius <= 0 or not is_finite(strength) or strength <= 0 or not is_finite(aspect) or aspect <= 0 or not is_finite(yaw):
		return
	var reach := radius * maxf(1.0, aspect)
	var pixel_scale := (size - 1) / extent
	var centre := (Vector2(world_pos.x, world_pos.z) / extent + Vector2.ONE * 0.5) * (size - 1)
	var low := Vector2i(maxi(0, floori(centre.x - reach * pixel_scale)), maxi(0, floori(centre.y - reach * pixel_scale)))
	var high := Vector2i(mini(size - 1, ceili(centre.x + reach * pixel_scale)), mini(size - 1, ceili(centre.y + reach * pixel_scale)))
	for y in range(low.y, high.y + 1):
		for x in range(low.x, high.x + 1):
			var offset := ((Vector2(x, y) - centre) / pixel_scale).rotated(yaw)
			var distance := Vector2(offset.x, offset.y / aspect).length() / radius
			if distance >= 1.0:
				continue
			var old := image.get_pixel(x, y).r
			var value := maxf(old, clampf(strength, 0, 1) * (1.0 - smoothstep(0.55, 1.0, distance)))
			if value > old:
				image.set_pixel(x, y, Color(value, 0, 0, 1))
				dirty = true

func clear(world_pos: Vector3, radius: float) -> void:
	press(world_pos, radius, 1.0)

func upload(delta: float) -> void:
	_upload_elapsed += maxf(0.0, delta)
	if dirty and _upload_elapsed >= 0.1:
		texture.update(image)
		dirty = false
		_upload_elapsed = 0.0

func _inside(p: Vector3) -> bool:
	return p.is_finite() and absf(p.x) <= extent * 0.5 and absf(p.z) <= extent * 0.5

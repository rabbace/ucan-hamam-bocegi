class_name FogWall
extends Node2D

## Faz 11.6 (Belediye İlaçlıyor): ekranı boydan boya kaplayan yeşil sis sütunu, ortasında geçiş deliği.
## Çarpışma kutusu görselden biraz dar (yumuşak kenar adil kalsın). Diva kalkanı / Halay hayaleti / Yurt pasifi korur.

const PUFF_STEP: float = 46.0
const PUFF_HOLE_MARGIN: float = 50.0

var wall_index: int = 0
var world_distance: float = 0.0
var hole_y: float = 600.0
var hole_size: float = GameConfig.EVENT_FOG_HOLE
var passed: bool = false

var _top_area: Area2D = null
var _bottom_area: Area2D = null
var _puff_tex: GradientTexture2D = null
var _time: float = 0.0


func setup(data: Dictionary) -> void:
	wall_index = int(data["index"])
	world_distance = float(data["distance"])
	hole_y = float(data["hole_y"])
	hole_size = float(data["hole_size"])
	var hit_w: float = GameConfig.EVENT_FOG_WALL_W * 0.8
	var top_y0: float = GameConfig.CEILING_Y - GameConfig.SLIPPER_EXTEND_PX
	var top_y1: float = hole_y - hole_size * 0.5
	var bot_y0: float = hole_y + hole_size * 0.5
	var bot_y1: float = GameConfig.FLOOR_Y + GameConfig.FLOOR_DEATH_MARGIN
	_top_area = _make_area("FogTop", Rect2(-hit_w * 0.5, top_y0, hit_w, top_y1 - top_y0))
	_bottom_area = _make_area("FogBottom", Rect2(-hit_w * 0.5, bot_y0, hit_w, bot_y1 - bot_y0))

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([GameConfig.EVENT_FOG_COLOR, Color(GameConfig.EVENT_FOG_COLOR, 0.45), Color(GameConfig.EVENT_FOG_COLOR, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	_puff_tex = GradientTexture2D.new()
	_puff_tex.gradient = grad
	_puff_tex.width = 96
	_puff_tex.height = 96
	_puff_tex.fill = GradientTexture2D.FILL_RADIAL
	_puff_tex.fill_from = Vector2(0.5, 0.5)
	_puff_tex.fill_to = Vector2(0.5, 0.0)
	queue_redraw()


func _make_area(n: String, r: Rect2) -> Area2D:
	var a: Area2D = Area2D.new()
	a.name = n
	a.collision_layer = GameConfig.LAYER_SLIPPER
	a.collision_mask = 0
	a.monitoring = false
	a.monitorable = true
	a.set_meta("death_cause", "belediye")
	a.set_meta("is_fog_wall", true)
	var cs: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = r.size
	cs.shape = rect
	cs.position = r.get_center()
	a.add_child(cs)
	add_child(a)
	return a


func update_motion(delta: float) -> void:
	_time += delta
	queue_redraw()


## Kalkan çarpınca o parça dağılır (yalnızca bu cihazda; sis kimseyi itmez).
func shatter_part(hit_area: Area2D) -> void:
	if hit_area != _top_area and hit_area != _bottom_area:
		return
	hit_area.set_deferred("monitorable", false)
	var cs: CollisionShape2D = hit_area.get_child(0) as CollisionShape2D
	if cs != null:
		cs.set_deferred("disabled", true)
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 0.45, GameConfig.SHATTER_DURATION)


## Elektrik konturu ile aynı arayüz: görünen sis dikdörtgenleri.
func contour_rects() -> Array[Rect2]:
	var w: float = GameConfig.EVENT_FOG_WALL_W
	var gp: Vector2 = global_position
	var out: Array[Rect2] = []
	out.append(Rect2(Vector2(gp.x - w * 0.5, GameConfig.CEILING_Y - 40.0), Vector2(w, hole_y - hole_size * 0.5 + 40.0)))
	out.append(Rect2(Vector2(gp.x - w * 0.5, hole_y + hole_size * 0.5), Vector2(w, GameConfig.FLOOR_Y + GameConfig.PEDESTAL_DRAW_BELOW_FLOOR - hole_y - hole_size * 0.5)))
	return out


func _draw() -> void:
	if _puff_tex == null:
		return
	var w: float = GameConfig.EVENT_FOG_WALL_W
	var top_end: float = hole_y - hole_size * 0.5
	var bot_start: float = hole_y + hole_size * 0.5
	var bottom_end: float = GameConfig.FLOOR_Y + GameConfig.PEDESTAL_DRAW_BELOW_FLOOR
	# Gövde: yarı saydam yeşil sütun + kenar çizgisi
	var body: Color = Color(GameConfig.EVENT_FOG_COLOR, 0.55)
	draw_rect(Rect2(-w * 0.5, GameConfig.CEILING_Y - 60.0, w, top_end - GameConfig.CEILING_Y + 60.0), body, true)
	draw_rect(Rect2(-w * 0.5, bot_start, w, bottom_end - bot_start), body, true)
	# Kaynayan sis bulutları (deterministik dizilim, zamanla nefes alır)
	var y: float = GameConfig.CEILING_Y - 30.0
	var i: int = 0
	while y < bottom_end:
		# Bulutlar deliğe taşmasın: delik net okunmalı
		if y < top_end - PUFF_HOLE_MARGIN or y > bot_start + PUFF_HOLE_MARGIN:
			var ph: float = _time * 2.2 + float(i) * 0.9 + float(wall_index) * 1.7
			var sx: float = sin(ph) * 10.0
			var sc: float = 1.05 + sin(ph * 0.7) * 0.12
			draw_texture_rect(_puff_tex, Rect2(Vector2(sx - 48.0 * sc, y - 48.0 * sc), Vector2(96.0, 96.0) * sc), false)
		y += PUFF_STEP
		i += 1
	# Deliğin kenarları: koyu yeşil, dalgalı ağız
	for edge_y: float in [top_end, bot_start]:
		var pts: PackedVector2Array = PackedVector2Array()
		for k: int in range(9):
			var x: float = lerpf(-w * 0.5 - 6.0, w * 0.5 + 6.0, float(k) / 8.0)
			pts.append(Vector2(x, edge_y + sin(_time * 3.0 + float(k)) * 3.0))
		draw_polyline(pts, GameConfig.EVENT_FOG_EDGE_COLOR, 6.0, true)
	# "İLAÇ" damlaları deliğin hemen üstünde ve altında
	draw_circle(Vector2(0.0, top_end - 18.0), 6.0, GameConfig.EVENT_FOG_EDGE_COLOR)
	draw_circle(Vector2(0.0, bot_start + 18.0), 6.0, GameConfig.EVENT_FOG_EDGE_COLOR)

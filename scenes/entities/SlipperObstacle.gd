extends Node2D

## Üst "Anne Eli" (hafifçe sallanan) ve alt "Sandalyeye Çıkmış İnsan" engel çifti + opsiyonel böcek ilacı bulutu.

var obstacle_index: int = 0
var world_distance: float = 0.0
var gap_y: float = 640.0
var gap_size: float = 300.0
var bob_amp: float = 0.0
var is_frozen: bool = false
var passed: bool = false
var has_spray: bool = false
var surprise_type: String = ""

var _base_gap_size: float = 300.0
var _base_top_y: float = 0.0
var _base_bot_y: float = 0.0
var _scare_label: Label = null
var _spray_area: Area2D = null
var _spray_puffs: Array[Sprite2D] = []
var _sopa_area: Area2D = null
var _dolap_door: ColorRect = null
var _dolap_opened: bool = false
var _flying_slipper: Area2D = null
var _flying_launched: bool = false
## Alt engel görselinin üstündeki şeffaf boşluk (piksel; doku başına bir kez ölçülür).
## Kafa, aralığın alt kenarına hizalanır.
static var _blank_cache: Dictionary = {}
var _bottom_blank_top: float = 0.0
var _pedestal: Node2D = null
# Faz 11.5: insan tipleri (seed'den) ve Faz 11.6 misafir kılığı
var top_type: String = "anne"
var bottom_type: String = "amca"
var is_guest: bool = false
var _top_custom: bool = false
var _bottom_custom: bool = false
var _top_art: Node2D = null
var _bottom_art: Node2D = null
var _extra_gap_mult: float = 1.0
var _drum_active: bool = false

@onready var top_area: Area2D = $TopSlipper
@onready var top_sprite: Sprite2D = $TopSlipper/Sprite2D
@onready var top_shape: CollisionShape2D = $TopSlipper/CollisionShape2D
@onready var bottom_area: Area2D = $BottomSlipper
@onready var bottom_sprite: Sprite2D = $BottomSlipper/Sprite2D
@onready var bottom_shape: CollisionShape2D = $BottomSlipper/CollisionShape2D


func _ready() -> void:
	top_area.collision_layer = GameConfig.LAYER_SLIPPER
	top_area.collision_mask = 0
	top_area.monitoring = false
	top_area.monitorable = true
	top_area.set_meta("death_cause", "ust_engel")

	bottom_area.collision_layer = GameConfig.LAYER_SLIPPER
	bottom_area.collision_mask = 0
	bottom_area.monitoring = false
	bottom_area.monitorable = true
	bottom_area.set_meta("death_cause", "alt_engel")

	top_sprite.texture = AssetHelper.texture(
		GameConfig.SLIPPER_TOP_PATH,
		"terlik_ust",
		GameConfig.SLIPPER_SIZE
	)
	bottom_sprite.texture = AssetHelper.texture(
		GameConfig.SLIPPER_BOTTOM_PATH,
		"terlik_alt",
		GameConfig.SLIPPER_SIZE
	)

	var rect_size: Vector2 = Vector2(
		float(GameConfig.SLIPPER_SIZE.x) * GameConfig.SLIPPER_HITBOX_WIDTH_RATIO,
		float(GameConfig.SLIPPER_SIZE.y) * 0.96
	)
	var top_rect: RectangleShape2D = RectangleShape2D.new()
	top_rect.size = rect_size
	top_shape.shape = top_rect

	var bot_rect: RectangleShape2D = RectangleShape2D.new()
	bot_rect.size = rect_size
	bottom_shape.shape = bot_rect

	# Üst engel tavanın da üstüne kadar uzar (yukarıdan aşma yok).
	top_rect.size.y = rect_size.y + GameConfig.SLIPPER_EXTEND_PX
	top_shape.position.y = -GameConfig.SLIPPER_EXTEND_PX * 0.5

	# Alt engel: görseldeki boş üst kısmı at, kafayı aralığın alt kenarına hizala.
	_measure_bottom_blank()
	bottom_sprite.position.y = -_bottom_blank_top
	_pedestal = Node2D.new()
	_pedestal.name = "Pedestal"
	_pedestal.show_behind_parent = true
	_pedestal.draw.connect(_draw_pedestal)
	bottom_area.add_child(_pedestal)
	bottom_area.move_child(_pedestal, 0)

	# Tip aksesuarları görselin hemen üstünde çizilir (çarpışma kutusunu değiştirmez)
	_top_art = Node2D.new()
	_top_art.name = "TopArt"
	_top_art.draw.connect(_draw_top_art)
	top_area.add_child(_top_art)
	top_area.move_child(_top_art, top_sprite.get_index() + 1)
	_bottom_art = Node2D.new()
	_bottom_art.name = "BottomArt"
	_bottom_art.draw.connect(_draw_bottom_art)
	bottom_area.add_child(_bottom_art)
	bottom_area.move_child(_bottom_art, bottom_sprite.get_index() + 1)


## Terlik çiftini verilen aralık merkezine ve genişliğine göre konumlandırır.
func setup(
	idx: int,
	dist: float,
	p_gap_y: float,
	p_gap_size: float,
	p_has_spray: bool = false,
	p_surprise_type: String = "",
	p_bob_amp: float = GameConfig.ANNE_ELI_BOB_AMP
) -> void:
	obstacle_index = idx
	world_distance = dist
	gap_y = p_gap_y
	_base_gap_size = p_gap_size
	gap_size = p_gap_size
	bob_amp = p_bob_amp
	is_frozen = false
	has_spray = p_has_spray
	surprise_type = p_surprise_type
	passed = false
	_dolap_opened = false

	_apply_gap_positions()

	if has_spray:
		_create_spray_cloud()
	if surprise_type == "sopa":
		_create_sopa_bar()
	elif surprise_type == "dolap":
		_create_dolap_door()
	elif surprise_type == "firlayan_terlik":
		_create_flying_slipper()


func _apply_gap_positions() -> void:
	var half_gap: float = gap_size * 0.5
	var half_h: float = float(GameConfig.SLIPPER_SIZE.y) * 0.5
	_base_top_y = gap_y - half_gap - half_h
	_base_bot_y = gap_y + half_gap + half_h
	top_area.position.y = _base_top_y
	bottom_area.position.y = _base_bot_y
	_update_bottom_shape()


## Görseldeki şeffaf üst boşluğu ölçer (doku başına bir kez; tüm engeller paylaşır).
func _measure_bottom_blank() -> void:
	_bottom_blank_top = 0.0
	var tex: Texture2D = bottom_sprite.texture
	if tex == null:
		return
	var key: String = tex.resource_path if not tex.resource_path.is_empty() else str(tex.get_rid())
	if _blank_cache.has(key):
		_bottom_blank_top = float(_blank_cache[key])
		return
	_blank_cache[key] = 0.0
	var img: Image = tex.get_image()
	if img == null:
		return
	if img.is_compressed():
		img.decompress()
	var used: Rect2i = img.get_used_rect()
	var tex_h: float = float(tex.get_height())
	if used.size.y <= 0 or tex_h <= 0.0:
		return
	# Doku SLIPPER_SIZE'tan farklı boyuttaysa ölçeği dikkate al.
	var sc: float = float(GameConfig.SLIPPER_SIZE.y) / tex_h * bottom_sprite.scale.y
	_bottom_blank_top = float(used.position.y) * sc
	_blank_cache[key] = _bottom_blank_top


## Faz 11.5: üst ve alt insan tipini uygular. Gerçek görsel varsa onu, yoksa varsayılan görsel + yedek aksesuar.
## Alt görsel değişirse kafa yine aralığın alt kenarına hizalanır; çarpışma kutusu aynı kurala göre yeniden kurulur.
func set_people(p_top: String, p_bottom: String) -> void:
	top_type = p_top
	bottom_type = p_bottom
	var t_tex: Texture2D = PeopleArt.custom_texture(top_type, true)
	_top_custom = t_tex != null
	if _top_custom:
		top_sprite.texture = t_tex
		top_sprite.scale = Vector2.ONE * (float(GameConfig.SLIPPER_SIZE.y) / maxf(float(t_tex.get_height()), 1.0))
	var b_tex: Texture2D = PeopleArt.custom_texture(bottom_type, false)
	_bottom_custom = b_tex != null
	if _bottom_custom:
		bottom_sprite.texture = b_tex
		bottom_sprite.scale = Vector2.ONE * (float(GameConfig.SLIPPER_SIZE.y) / maxf(float(b_tex.get_height()), 1.0))
		_measure_bottom_blank()
		bottom_sprite.position.y = -_bottom_blank_top
		_apply_gap_positions()
	_redraw_art()


## Faz 11.6 (Misafir Var): şapka, fiyonk ve çay tepsisi.
func set_guest(active: bool) -> void:
	if is_guest == active:
		return
	is_guest = active
	_redraw_art()


func _redraw_art() -> void:
	if _top_art != null:
		_top_art.queue_redraw()
	if _bottom_art != null:
		_bottom_art.queue_redraw()


## Görsel pikselini yerel koordinata çeviren dönüşüm (görsel ortalanmış ve 120x600 kabul edilir).
func _art_transform(spr: Sprite2D) -> Transform2D:
	var sc: float = float(GameConfig.SLIPPER_SIZE.y) / PeopleArt.IMG_H
	var origin: Vector2 = spr.position - Vector2(PeopleArt.IMG_W, PeopleArt.IMG_H) * 0.5 * sc
	return Transform2D(0.0, Vector2(sc, sc), 0.0, origin)


func _draw_top_art() -> void:
	var xf: Transform2D = _art_transform(top_sprite)
	_top_art.draw_set_transform_matrix(xf)
	PeopleArt.draw_top(_top_art, top_type, is_guest, GameConfig.SLIPPER_EXTEND_PX + 40.0, _top_custom)
	_top_art.draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_bottom_art() -> void:
	var xf: Transform2D = _art_transform(bottom_sprite)
	_bottom_art.draw_set_transform_matrix(xf)
	PeopleArt.draw_bottom(_bottom_art, bottom_type, is_guest, _bottom_custom)
	_bottom_art.draw_set_transform_matrix(Transform2D.IDENTITY)


## Alt çarpışma kutusu: kafanın üstünden (görünen kenar) zemin ölüm çizgisinin altına kadar.
## Böylece görünmez duvar da, alttan geçme kanalı da olmaz.
func _update_bottom_shape() -> void:
	if bottom_shape == null or not (bottom_shape.shape is RectangleShape2D):
		return
	var half_h: float = float(GameConfig.SLIPPER_SIZE.y) * 0.5
	var local_top: float = -half_h + GameConfig.SLIPPER_HEAD_INSET_PX
	var floor_local: float = (GameConfig.FLOOR_Y + GameConfig.FLOOR_DEATH_MARGIN) - _base_bot_y
	var local_bottom: float = maxf(floor_local, local_top + 40.0)
	var rect: RectangleShape2D = bottom_shape.shape as RectangleShape2D
	rect.size.y = local_bottom - local_top
	bottom_shape.position.y = (local_top + local_bottom) * 0.5
	if _pedestal != null:
		_pedestal.queue_redraw()


## Sandalyenin altından zemine kadar uzanan ahşap kaide (görsel ile çarpışma kutusu aynı olsun).
func _draw_pedestal() -> void:
	var half_h: float = float(GameConfig.SLIPPER_SIZE.y) * 0.5
	var top_y: float = half_h - _bottom_blank_top - 6.0
	# Çizim uzun ekranlarda da ekranın altına kadar insin (çarpışma kutusu ayrı hesaplanır).
	var bottom_y: float = (GameConfig.FLOOR_Y + GameConfig.PEDESTAL_DRAW_BELOW_FLOOR) - _base_bot_y
	if bottom_y <= top_y + 4.0:
		return
	var w: float = float(GameConfig.SLIPPER_SIZE.x) * GameConfig.SLIPPER_HITBOX_WIDTH_RATIO * 0.86
	var r: Rect2 = Rect2(-w * 0.5, top_y, w, bottom_y - top_y)
	_pedestal.draw_rect(r, GameConfig.PEDESTAL_COLOR, true)
	# Tahta çizgileri
	var plank_y: float = top_y + 34.0
	while plank_y < bottom_y:
		_pedestal.draw_line(Vector2(r.position.x + 6.0, plank_y), Vector2(r.end.x - 6.0, plank_y), GameConfig.PEDESTAL_LINE_COLOR, 3.0)
		plank_y += 46.0
	_pedestal.draw_rect(r, GameConfig.COLOR_INK, false, 4.0)


## Dondurma güçlendirmesi için engelleri buz mavisine çevirip aralığı genişletir.
func set_frozen(frozen: bool) -> void:
	if is_frozen == frozen:
		return
	is_frozen = frozen
	_recalc_gap()
	var tint: Color = Color(0.68, 0.90, 1.0, 1.0) if frozen else Color.WHITE
	top_area.modulate = tint
	bottom_area.modulate = tint
	if _sopa_area != null:
		_sopa_area.modulate = tint


func _recalc_gap() -> void:
	var mult: float = maxf(GameConfig.POWERUP_FREEZE_GAP_MULT if is_frozen else 1.0, _extra_gap_mult)
	gap_size = _base_gap_size * mult
	_apply_gap_positions()


## Faz 10.2 (Yedek Anahtar): aralığı yerelde verilen oranla genişletir (1.0 = normal).
func set_gap_mult(mult: float) -> void:
	if is_equal_approx(_extra_gap_mult, mult):
		return
	_extra_gap_mult = mult
	_recalc_gap()


## Faz 10.2 (Davul): insanlar aynı ritimde, yavaş ve öngörülebilir sallanır.
func set_drum(active: bool) -> void:
	_drum_active = active


## Faz 10.2 (İngiliz Anahtarı): engelin tüm parçalarını söker.
func shatter_all() -> void:
	for a: Area2D in [top_area, bottom_area, _sopa_area, _flying_slipper]:
		if a != null and is_instance_valid(a) and a.visible:
			shatter_part(a)
	if _spray_area != null and is_instance_valid(_spray_area):
		_spray_area.set_deferred("monitorable", false)
		var tw: Tween = create_tween()
		tw.tween_property(_spray_area, "modulate:a", 0.0, GameConfig.SHATTER_DURATION)


## Oyuncunun hitbox kenarının üst veya alt engele 18 px'den (+ek) yakın olup olmadığını döner.
func is_close_scare(player_y: float, player_radius: float, extra_px: float = 0.0) -> bool:
	return close_scare_side(player_y, player_radius, extra_px) != 0


## Yakın kaçışta korkan taraf: 1 üst, 2 alt, 0 yakın değil (ikisi de yakınsa daha yakın olan).
func close_scare_side(player_y: float, player_radius: float, extra_px: float = 0.0) -> int:
	var half_h: float = float(GameConfig.SLIPPER_SIZE.y) * 0.5
	var top_edge: float = top_area.position.y + half_h
	var bot_edge: float = bottom_area.position.y - half_h
	var dist_top: float = absf((player_y - player_radius) - top_edge)
	var dist_bot: float = absf(bot_edge - (player_y + player_radius))
	var limit: float = GameConfig.CLOSE_SCARE_EDGE_PX + extra_px
	if dist_top >= limit and dist_bot >= limit:
		return 0
	return 1 if dist_top < dist_bot else 2


## Korkan kişinin tipi (taraf 1 üst, 2 alt).
func type_for_side(side: int) -> String:
	return top_type if side == 1 else bottom_type


## Elektrik Kesildi konturu için üst ve alt engelin dünya dikdörtgenleri (görünen kısım).
func contour_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var half_w: float = float(GameConfig.SLIPPER_SIZE.x) * GameConfig.SLIPPER_HITBOX_WIDTH_RATIO * 0.5
	var half_h: float = float(GameConfig.SLIPPER_SIZE.y) * 0.5
	if top_area.visible:
		var tp: Vector2 = top_area.global_position
		out.append(Rect2(Vector2(tp.x - half_w, tp.y - half_h - GameConfig.SLIPPER_EXTEND_PX), Vector2(half_w * 2.0, half_h * 2.0 + GameConfig.SLIPPER_EXTEND_PX)))
	if bottom_area.visible:
		var bp: Vector2 = bottom_area.global_position
		out.append(Rect2(Vector2(bp.x - half_w, bp.y - half_h), Vector2(half_w * 2.0, GameConfig.FLOOR_Y + GameConfig.PEDESTAL_DRAW_BELOW_FLOOR - (bp.y - half_h))))
	return out


## Anne Eli sallanmasını, alt kişi titremesini ve açılan dolap kapağını günceller.
func update_motion(match_time: float) -> void:
	if is_frozen:
		return
	if _drum_active:
		# Davul ritmi: tüm engeller aynı fazda, yavaş ve küçük genlikle sallanır
		var drum_bob: float = sin(match_time * GameConfig.SIG_DRUM_BOB_SPEED * TAU) * minf(bob_amp, 18.0)
		top_area.position.y = _base_top_y + drum_bob
		bottom_area.position.x = sin(match_time * GameConfig.SIG_DRUM_BOB_SPEED * TAU) * 6.0
	else:
		var bob: float = sin(match_time * GameConfig.ANNE_ELI_BOB_SPEED + float(obstacle_index) * 1.1) * bob_amp
		top_area.position.y = _base_top_y + bob
		bottom_area.position.x = sin(match_time * 32.0 + float(obstacle_index)) * 2.2
	if _dolap_door != null and not _dolap_opened and position.x <= GameConfig.PLAYER_X + 260.0:
		_dolap_opened = true
		var tw: Tween = create_tween().set_parallel(true)
		tw.tween_property(_dolap_door, "scale:y", 0.08, 0.25)
		tw.tween_property(_dolap_door, "modulate:a", 0.35, 0.25)
	if _flying_slipper != null:
		# Kare hızından bağımsız dönüş (60 fps'de eski 0.14/kare ile aynı).
		_flying_slipper.rotation = match_time * GameConfig.FLYING_SLIPPER_SPIN
		if not _flying_launched and position.x <= GameConfig.PLAYER_X + 340.0:
			_flying_launched = true
			var ftw: Tween = create_tween()
			ftw.tween_property(_flying_slipper, "position:y", gap_y - 68.0, 0.55).set_trans(Tween.TRANS_SINE)
	if not _spray_puffs.is_empty():
		for i: int in range(_spray_puffs.size()):
			var puff: Sprite2D = _spray_puffs[i]
			if is_instance_valid(puff):
				var phase: float = match_time * 2.4 + float(i) * 1.15
				var s: float = 0.92 + sin(phase) * 0.12
				puff.scale = Vector2(s, s)
				puff.position.y += sin(phase * 0.8) * 0.18


## Böcek yanından geçerken korkan kişinin yanında çığlık yazısı çıkarır (yakın kaçışta tipin kendi lafı).
func trigger_scare(is_close: bool, side: int = 2) -> void:
	if _scare_label != null:
		return
	var font: Font = AssetHelper.get_ui_font()
	_scare_label = Label.new()
	var txt: String = "AAAA!"
	if is_close:
		var lines: Array = GameConfig.get_person(type_for_side(side)).get("scream_lines", []) as Array
		txt = str(lines[obstacle_index % lines.size()]) if not lines.is_empty() else "AAAAAA!!!"
	_scare_label.text = txt
	var y0: float = gap_y + gap_size * 0.5 - 48.0
	if is_close and side == 1:
		y0 = gap_y - gap_size * 0.5 + 6.0
	_scare_label.position = Vector2(-65.0, y0)
	_scare_label.add_theme_font_override("font", font)
	_scare_label.add_theme_font_size_override("font_size", (34 if txt.length() <= 12 else 26) if is_close else 24)
	_scare_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED if is_close else Color.WHITE)
	_scare_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	_scare_label.add_theme_constant_override("outline_size", 6)
	add_child(_scare_label)

	var tw: Tween = create_tween()
	tw.tween_property(_scare_label, "position:y", _scare_label.position.y - 36.0, 0.55)
	tw.parallel().tween_property(_scare_label, "modulate:a", 0.0, 0.55)


func _create_spray_cloud() -> void:
	_spray_area = Area2D.new()
	_spray_area.name = "SprayCloud"
	_spray_area.collision_layer = GameConfig.LAYER_SLIPPER
	_spray_area.collision_mask = 0
	_spray_area.monitoring = false
	_spray_area.monitorable = true
	_spray_area.position = Vector2(0.0, gap_y)
	_spray_area.set_meta("is_spray_cloud", true)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(72.0, minf(gap_size * 0.45, 110.0))
	shape.shape = rect
	_spray_area.add_child(shape)

	var grad: Gradient = Gradient.new()
	grad.colors = PackedColorArray([
		Color(0.32, 0.90, 0.36, 0.58),
		Color(0.24, 0.78, 0.30, 0.30),
		Color(0.20, 0.65, 0.25, 0.0),
	])
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var puff_tex: GradientTexture2D = GradientTexture2D.new()
	puff_tex.gradient = grad
	puff_tex.width = 96
	puff_tex.height = 96
	puff_tex.fill = GradientTexture2D.FILL_RADIAL
	puff_tex.fill_from = Vector2(0.5, 0.5)
	puff_tex.fill_to = Vector2(0.5, 0.0)

	var puff_offsets: Array[Vector2] = [
		Vector2(0.0, 0.0),
		Vector2(-26.0, -18.0),
		Vector2(26.0, -14.0),
		Vector2(-24.0, 20.0),
		Vector2(24.0, 18.0),
		Vector2(0.0, -28.0),
		Vector2(0.0, 28.0),
	]
	_spray_puffs.clear()
	for offset: Vector2 in puff_offsets:
		var puff: Sprite2D = Sprite2D.new()
		puff.texture = puff_tex
		puff.position = offset
		_spray_area.add_child(puff)
		_spray_puffs.append(puff)

	var particles: CPUParticles2D = CPUParticles2D.new()
	particles.amount = 16
	particles.lifetime = 0.85
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 38.0
	particles.direction = Vector2(0.0, -1.0)
	particles.spread = 180.0
	particles.gravity = Vector2(0.0, -18.0)
	particles.initial_velocity_min = 8.0
	particles.initial_velocity_max = 22.0
	particles.scale_amount_min = 4.0
	particles.scale_amount_max = 10.0
	particles.color = Color(0.42, 0.95, 0.45, 0.55)
	_spray_area.add_child(particles)

	var lbl: Label = Label.new()
	lbl.text = "BÖCEK\nİLACI"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(-46.0, -28.0)
	lbl.custom_minimum_size = Vector2(92.0, 56.0)
	lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.96, 1.0, 0.90, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.22, 0.08, 1.0))
	lbl.add_theme_constant_override("outline_size", 5)
	_spray_area.add_child(lbl)

	add_child(_spray_area)


func _create_sopa_bar() -> void:
	_sopa_area = Area2D.new()
	_sopa_area.name = "SopaBar"
	_sopa_area.collision_layer = GameConfig.LAYER_SLIPPER
	_sopa_area.collision_mask = 0
	_sopa_area.monitoring = false
	_sopa_area.monitorable = true
	_sopa_area.position = Vector2(0.0, gap_y)
	_sopa_area.set_meta("death_cause", "surpriz")

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(132.0, 14.0)
	shape.shape = rect
	_sopa_area.add_child(shape)

	var main_col: Color = Color(0.55, 0.34, 0.16, 1.0)
	var accent_col: Color = Color(0.76, 0.54, 0.30, 1.0)
	match NetworkManager.selected_bg_id:
		"kahvehane":
			main_col = Color("#8C5A2B")
			accent_col = Color("#FFF3D1") # Okey ıstakası + taş şeridi
		"sanayi":
			main_col = Color("#7A8694")
			accent_col = Color("#D0D7DE") # İngiliz anahtarı çeliği
		"otobus":
			main_col = Color("#E8B923")
			accent_col = Color("#2A2624") # Sarı tutunma borusu
		"dugun":
			main_col = Color("#D94B43")
			accent_col = Color("#FFE169") # Takı / halay kurdelesi
		"pavyon":
			main_col = Color("#D645B8")
			accent_col = Color("#7CF5FF") # Neon disko çubuğu
		"banyo":
			main_col = Color("#5CA4C4")
			accent_col = Color("#E2F3FA") # Paspas sapı

	var wood: ColorRect = ColorRect.new()
	wood.color = main_col
	wood.size = Vector2(144.0, 18.0)
	wood.position = Vector2(-72.0, -9.0)
	_sopa_area.add_child(wood)

	var stripe: ColorRect = ColorRect.new()
	stripe.color = accent_col
	stripe.size = Vector2(144.0, 4.0)
	stripe.position = Vector2(-72.0, -5.0)
	_sopa_area.add_child(stripe)

	add_child(_sopa_area)


func _create_dolap_door() -> void:
	_dolap_door = ColorRect.new()
	_dolap_door.name = "DolapDoor"
	_dolap_door.color = Color(0.58, 0.39, 0.22, 0.94)
	var door_h: float = gap_size * 0.58
	_dolap_door.size = Vector2(30.0, door_h)
	_dolap_door.position = Vector2(-15.0, gap_y - gap_size * 0.5)

	var handle: ColorRect = ColorRect.new()
	handle.color = Color(0.92, 0.78, 0.32, 1.0)
	handle.size = Vector2(6.0, 22.0)
	handle.position = Vector2(4.0, door_h - 34.0)
	_dolap_door.add_child(handle)

	add_child(_dolap_door)


func _create_flying_slipper() -> void:
	_flying_slipper = Area2D.new()
	_flying_slipper.name = "FlyingSlipper"
	_flying_slipper.collision_layer = GameConfig.LAYER_SLIPPER
	_flying_slipper.collision_mask = 0
	_flying_slipper.monitoring = false
	_flying_slipper.monitorable = true
	_flying_slipper.position = Vector2(18.0, gap_y + 42.0)
	_flying_slipper.set_meta("death_cause", "terlik")

	var col: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(54.0, 32.0)
	col.shape = rect
	_flying_slipper.add_child(col)

	var spr: Sprite2D = Sprite2D.new()
	spr.texture = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(64, 40))
	spr.scale = Vector2(0.75, 0.75)
	_flying_slipper.add_child(spr)
	add_child(_flying_slipper)


## Diva kalkanı çarptığında ilgili terlik veya sopa parçasını 0.3 sn içinde parçalar.
func shatter_part(hit_area: Area2D) -> void:
	if hit_area != top_area and hit_area != bottom_area and hit_area != _sopa_area and hit_area != _flying_slipper:
		return
	var col_shape: CollisionShape2D = null
	if hit_area == top_area:
		col_shape = top_shape
	elif hit_area == bottom_area:
		col_shape = bottom_shape
	else:
		col_shape = hit_area.get_child(0) as CollisionShape2D
	if col_shape != null:
		col_shape.set_deferred("disabled", true)
	hit_area.set_deferred("monitorable", false)

	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(hit_area, "scale", Vector2(0.1, 0.1), GameConfig.SHATTER_DURATION)
	tw.tween_property(hit_area, "rotation", hit_area.rotation + PI * 1.5, GameConfig.SHATTER_DURATION)
	tw.tween_property(hit_area, "modulate:a", 0.0, GameConfig.SHATTER_DURATION)
	tw.chain().tween_callback(func() -> void:
		hit_area.visible = false
	)

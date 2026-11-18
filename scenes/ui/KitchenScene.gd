class_name KitchenScene
extends Control

## Faz 13B: canlı mutfak sahnesi (intro ve ana menü arka planı).
## Katmanlar: arka (mutfak görseli + perde, duvar saati, buzdolabı, çaydanlık buharı, duvardaki böcek),
## ışık (gece lambası, buzdolabı aralığı; toplamalı karışım), ön (kodla çizilen tezgâh, çay bardağı,
## terlik şakası), tezgâhtaki karakter, karanlık ve parlama örtüleri.
## Hafif paralaks: telefon eğimiyle değil, yavaş otomatik kayma ile (ön katman daha çok kayar).
## Gece 22:00–06:00 (cihaz saati) loş ve sıcak ışıklı gece modu.

const FORCE_AUTO: int = -1
const BG_PATH: String = "res://assets/sprites/bg_mutfak.png"

## Tezgâh üst kenarının ekran y'si (sahibi yerleşime göre verir)
var counter_y: float = 900.0
## -1 otomatik (saate göre), 0 gündüz, 1 gece
var force_night: int = FORCE_AUTO
## Intro: ek karanlık (0..1), buzdolabı aralığından sızan ışık (0..1), beyaz parlama (0..1)
var darkness: float = 0.0
var fridge_crack: float = 0.0
var flash: float = 0.0
var jokes_enabled: bool = true
var show_actor: bool = true
## Karakterin ev konumuna göre kayması (intro uçuşları) ve korku hali
var actor_offset: Vector2 = Vector2.ZERO
var actor_scared: bool = false
var actor: Sprite2D = null

var _tex: Texture2D = null
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _back: Control = null
var _glow: Control = null
var _front: Control = null
var _shade: Control = null
var _crack: Control = null
var _flash: Control = null
var _slipper_tex: Texture2D = null
var _actor_base_scale: Vector2 = Vector2.ONE
var _actor_react: float = 0.0

# Animasyon durumları
var _steam: Array[Vector3] = []        # x, y, yaş (görsel koordinatı)
var _steam_timer: float = 0.0
var _glass_steam: Array[Vector3] = []  # tezgâhtaki çay bardağı buharı (ekran koordinatı)
var _hum_left: float = 0.0
var _hum_timer: float = 12.0
var _joke_timer: float = 25.0
var _joke: String = ""
var _joke_t: float = 0.0
var _joke_len: float = 0.0
var _counter_jitter: PackedFloat32Array = PackedFloat32Array()
var _grain: Texture2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rng.randomize()
	_tex = AssetHelper.texture(BG_PATH, "bg_mutfak", GameConfig.BG_SIZE)
	_slipper_tex = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(140, 220))
	_hum_timer = _rng.randf_range(GameConfig.KITCHEN_FRIDGE_HUM_EVERY.x, GameConfig.KITCHEN_FRIDGE_HUM_EVERY.y)
	_joke_timer = _rng.randf_range(GameConfig.KITCHEN_JOKE_EVERY.x, GameConfig.KITCHEN_JOKE_EVERY.y)
	for i: int in range(24):
		_counter_jitter.append(_rng.randf_range(-2.5, 2.5))
	_grain = _make_grain()

	_back = _layer("Back", _draw_back)
	_glow = _layer("Glow", _draw_glow)
	var add_mat: CanvasItemMaterial = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add_mat
	_front = _layer("Front", _draw_front)
	_front.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	actor = Sprite2D.new()
	actor.name = "Actor"
	add_child(actor)
	_shade = _layer("Shade", _draw_shade)
	_crack = _layer("Crack", _draw_crack)
	_crack.material = add_mat
	_flash = _layer("Flash", _draw_flash)
	set_actor(NetworkManager.selected_char_id)


func _layer(n: String, fn: Callable) -> Control:
	var c: Control = Control.new()
	c.name = n
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.draw.connect(fn.bind(c))
	add_child(c)
	return c


## Saate göre gece mi? (22:00–06:00)
static func is_night_hour(hour: int) -> bool:
	return hour >= GameConfig.KITCHEN_NIGHT_START_H or hour < GameConfig.KITCHEN_NIGHT_END_H


func is_night() -> bool:
	if force_night != FORCE_AUTO:
		return force_night == 1
	return is_night_hour(int(Time.get_time_dict_from_system()["hour"]))


## Ana menü yerleşimi (intro ile menü aynı kareyi paylaşsın diye tek yerde):
## top_bar, pages, nav, logo, play (Rect2, ekran koordinatı) ve counter_y.
static func menu_layout(vis: Vector2, ins: Dictionary) -> Dictionary:
	var g: float = GameConfig.SCREEN_GUTTER
	var side_extra: float = maxf(0.0, (vis.x - GameConfig.MENU_CONTENT_MAX_W) * 0.5 - g)
	var left: float = float(ins.get("left", 0.0)) + g + side_extra
	var right: float = vis.x - float(ins.get("right", 0.0)) - g - side_extra
	var w: float = right - left
	var top: float = float(ins.get("top", 0.0)) + g * 0.75
	var top_bar: Rect2 = Rect2(left, top, w, GameConfig.MENU_TOP_BAR_H)
	var bottom: float = vis.y - float(ins.get("bottom", 0.0)) - g * 0.5
	var nav: Rect2 = Rect2(left, bottom - GameConfig.MENU_NAV_H, w, GameConfig.MENU_NAV_H)
	var pages_y: float = top_bar.end.y + GameConfig.SP_S
	var pages: Rect2 = Rect2(left, pages_y, w, nav.position.y - GameConfig.SP_S - pages_y)
	var logo_w: float = minf(GameConfig.MENU_LOGO_MAX_W, w - 2.0 * (GameConfig.MENU_GEAR_SIZE + GameConfig.SP_XS))
	var logo: Rect2 = Rect2(left + (w - logo_w) * 0.5, pages.position.y + GameConfig.SP_XS, logo_w, logo_w * GameConfig.MENU_LOGO_ASPECT)
	var play_w: float = minf(w, GameConfig.MENU_PLAY_MAX_W)
	var play: Rect2 = Rect2(left + (w - play_w) * 0.5, pages.end.y - GameConfig.MENU_PLAY_H - GameConfig.SP_XS, play_w, GameConfig.MENU_PLAY_H)
	return {
		"top_bar": top_bar, "nav": nav, "pages": pages, "logo": logo, "play": play,
		"counter_y": play.position.y - GameConfig.MENU_COUNTER_GAP,
	}


func set_actor(char_id: String) -> void:
	if actor == null:
		return
	var cdata: Dictionary = CharacterData.get_character(char_id)
	actor.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	var md: float = maxf(actor.texture.get_size().x, actor.texture.get_size().y)
	var sc: float = GameConfig.KITCHEN_ACTOR_PX / md if md > 0.0 else 1.0
	_actor_base_scale = Vector2(sc, sc)
	actor.scale = _actor_base_scale


## Karakterin tezgâhtaki yeri (ekran koordinatı, gövde merkezi).
func actor_home() -> Vector2:
	return Vector2(size.x * 0.5, counter_y - GameConfig.KITCHEN_ACTOR_PX * 0.36)


## Dokununca kısa zıplama tepkisi.
func poke_actor() -> void:
	_actor_react = 0.8


func _time() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


func _process(delta: float) -> void:
	var t: float = _time()
	_update_steam(delta)
	_update_timers(delta)
	if actor != null:
		actor.visible = show_actor
		var bob: float = sin(t * 2.4) * 4.0
		var breathe: float = sin(t * 2.4) * 0.025
		actor.position = actor_home() + actor_offset + Vector2(0.0, bob)
		if actor_scared:
			actor.scale = _actor_base_scale * Vector2(1.08, 1.08)
			actor.rotation = sin(t * 40.0) * deg_to_rad(3.0)
		elif _actor_react > 0.0:
			_actor_react = maxf(0.0, _actor_react - delta)
			actor.rotation = sin(t * 26.0) * deg_to_rad(14.0) * _actor_react
			actor.scale = _actor_base_scale * (1.0 + 0.18 * _actor_react)
		else:
			actor.rotation = sin(t * 1.3) * deg_to_rad(4.0)
			actor.scale = _actor_base_scale * Vector2(1.0 - breathe * 0.6, 1.0 + breathe)
	for c: Control in [_back, _glow, _front, _shade, _crack, _flash]:
		c.queue_redraw()


func _update_steam(delta: float) -> void:
	_steam_timer -= delta
	if _steam_timer <= 0.0:
		_steam_timer = GameConfig.KITCHEN_STEAM_EVERY
		var o: Vector2 = GameConfig.KITCHEN_KETTLE_STEAM
		_steam.append(Vector3(o.x + _rng.randf_range(-4.0, 4.0), o.y, 0.0))
		_glass_steam.append(Vector3(_rng.randf_range(-5.0, 5.0), 0.0, 0.0))
	for i: int in range(_steam.size() - 1, -1, -1):
		var p: Vector3 = _steam[i]
		p.z += delta
		p.y -= delta * 26.0
		p.x += sin(p.z * 2.2 + p.y * 0.05) * delta * 10.0
		_steam[i] = p
		if p.z > 3.2:
			_steam.remove_at(i)
	for i: int in range(_glass_steam.size() - 1, -1, -1):
		var g: Vector3 = _glass_steam[i]
		g.z += delta
		g.y -= delta * 18.0
		g.x += sin(g.z * 3.0) * delta * 6.0
		_glass_steam[i] = g
		if g.z > 2.2:
			_glass_steam.remove_at(i)


func _update_timers(delta: float) -> void:
	_hum_timer -= delta
	if _hum_timer <= 0.0:
		_hum_timer = _rng.randf_range(GameConfig.KITCHEN_FRIDGE_HUM_EVERY.x, GameConfig.KITCHEN_FRIDGE_HUM_EVERY.y)
		_hum_left = 0.7
	_hum_left = maxf(0.0, _hum_left - delta)
	if not _joke.is_empty():
		_joke_t += delta
		if _joke_t >= _joke_len:
			_joke = ""
	if not jokes_enabled:
		return
	_joke_timer -= delta
	if _joke_timer <= 0.0 and _joke.is_empty():
		_joke_timer = _rng.randf_range(GameConfig.KITCHEN_JOKE_EVERY.x, GameConfig.KITCHEN_JOKE_EVERY.y)
		var kinds: Array[String] = ["bug_wall", "slipper_peek", "fridge_open"]
		start_joke(kinds[_rng.randi_range(0, kinds.size() - 1)])


## Ortam şakası başlatır: "bug_wall" | "slipper_peek" | "fridge_open"
func start_joke(kind: String) -> void:
	_joke = kind
	_joke_t = 0.0
	match kind:
		"bug_wall":
			_joke_len = 7.0
		"slipper_peek":
			_joke_len = 1.6
		"fridge_open":
			_joke_len = 2.2
		_:
			_joke = ""


func current_joke() -> String:
	return _joke


# ---------------------------------------------------------------------------
# Dönüşüm: mutfak görseli (720x1280) -> ekran
# ---------------------------------------------------------------------------

func image_scale() -> float:
	var img: Vector2 = GameConfig.KITCHEN_IMG_SIZE
	var s: float = maxf(size.x / img.x, (counter_y + 60.0) / img.y)
	return s * GameConfig.KITCHEN_OVERSCAN


func _pan(mult: float) -> float:
	return sin(_time() * TAU / GameConfig.KITCHEN_PAN_PERIOD) * GameConfig.KITCHEN_PAN_PX * mult


func image_xform() -> Transform2D:
	var img: Vector2 = GameConfig.KITCHEN_IMG_SIZE
	var s: float = image_scale()
	var ox: float = (size.x - img.x * s) * 0.5 + _pan(1.0)
	var oy_min: float = counter_y + 60.0 - img.y * s
	var oy: float = clampf(counter_y - GameConfig.KITCHEN_IMG_COUNTER_Y * s, oy_min, 0.0)
	return Transform2D(0.0, Vector2(s, s), 0.0, Vector2(ox, oy))


func img_to_screen(p: Vector2) -> Vector2:
	return image_xform() * p


# ---------------------------------------------------------------------------
# Arka katman
# ---------------------------------------------------------------------------

func _draw_back(c: Control) -> void:
	var xf: Transform2D = image_xform()
	var t: float = _time()
	c.draw_set_transform_matrix(xf)
	if _tex != null:
		c.draw_texture_rect(_tex, Rect2(Vector2.ZERO, GameConfig.KITCHEN_IMG_SIZE), false)
	# Perde: üstten sabit, alt ucu rüzgârla sallanır (görselin kendi bölgesi eğilerek yeniden çizilir)
	var cr: Rect2 = GameConfig.KITCHEN_CURTAIN_RECT
	var sk: float = sin(t * 0.9) * GameConfig.KITCHEN_CURTAIN_SKEW + sin(t * 2.3) * GameConfig.KITCHEN_CURTAIN_SKEW * 0.3
	var pivot: Vector2 = cr.position
	var curtain_xf: Transform2D = xf * Transform2D(0.0, Vector2.ONE, 0.0, pivot) * Transform2D(0.0, Vector2.ONE, -sk, Vector2.ZERO) * Transform2D(0.0, Vector2.ONE, 0.0, -pivot)
	c.draw_set_transform_matrix(curtain_xf)
	if _tex != null:
		c.draw_texture_rect_region(_tex, cr, cr)
	c.draw_set_transform_matrix(xf)
	_draw_fridge(c, t)
	_draw_clock(c)
	_draw_steam(c)
	if _joke == "bug_wall":
		_draw_wall_bug(c)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if is_night():
		c.draw_rect(Rect2(Vector2.ZERO, c.size), GameConfig.KITCHEN_NIGHT_TINT)


func _draw_fridge(c: Control, t: float) -> void:
	if _tex == null:
		return
	var fr: Rect2 = GameConfig.KITCHEN_FRIDGE_RECT
	if _hum_left > 0.0:
		# Motor titremesi: bölge 1-2 piksel sağa sola sarsılır
		var dx: float = sin(t * 190.0) * 1.4
		c.draw_texture_rect_region(_tex, Rect2(fr.position + Vector2(dx, 0.0), fr.size), fr)
	if _joke == "fridge_open":
		var k: float = _ease_peak(_joke_t / _joke_len)
		var dr: Rect2 = GameConfig.KITCHEN_FRIDGE_DOOR_RECT
		var gap: float = dr.size.x * 0.22 * k
		# Kapı aralığı: içerisi karanlık + sıcak ışık, iki merak eden göz
		c.draw_rect(Rect2(dr.position, Vector2(gap + 6.0, dr.size.y)), Color("#2A1B14"))
		c.draw_rect(Rect2(dr.position + Vector2(4.0, 8.0), Vector2(maxf(gap - 4.0, 0.0), dr.size.y - 16.0)), Color(1.0, 0.86, 0.55, 0.55 * k))
		if k > 0.5:
			var eye_c: Vector2 = dr.position + Vector2(gap * 0.5 + 3.0, dr.size.y * 0.42)
			for sx: float in [-6.0, 6.0]:
				c.draw_circle(eye_c + Vector2(sx, 0.0), 4.5, Color("#FFF8EE"))
				c.draw_circle(eye_c + Vector2(sx + 1.2, 0.5), 2.2, GameConfig.COLOR_INK)
		# Kapının kendisi menteşeye (sağ kenar) doğru daralır
		var door_dst: Rect2 = Rect2(dr.position + Vector2(gap, 0.0), Vector2(dr.size.x - gap, dr.size.y))
		c.draw_texture_rect_region(_tex, door_dst, dr)
		c.draw_line(door_dst.position, door_dst.position + Vector2(0.0, dr.size.y), GameConfig.COLOR_INK, 2.0, true)


func _draw_clock(c: Control) -> void:
	var p: Vector2 = GameConfig.KITCHEN_CLOCK_POS
	var r: float = GameConfig.KITCHEN_CLOCK_R
	var ink: Color = GameConfig.COLOR_INK
	c.draw_circle(p + Vector2(2.0, 4.0), r + 3.0, Color(0.141, 0.086, 0.055, 0.18))
	c.draw_circle(p, r + 3.0, Color("#C0583F"))
	c.draw_circle(p, r - 2.0, Color("#FFF8EC"))
	c.draw_arc(p, r + 3.0, 0.0, TAU, 40, ink, 3.0, true)
	c.draw_arc(p, r - 2.0, 0.0, TAU, 40, ink, 1.5, true)
	for i: int in range(12):
		var a: float = TAU * float(i) / 12.0
		var d: Vector2 = Vector2(sin(a), -cos(a))
		var inner: float = r * (0.70 if i % 3 == 0 else 0.80)
		c.draw_line(p + d * inner, p + d * (r * 0.88), ink, 2.5 if i % 3 == 0 else 1.5, true)
	# Gerçek saat (cihaz saati)
	var td: Dictionary = Time.get_time_dict_from_system()
	var h: float = float(int(td["hour"]) % 12) + float(td["minute"]) / 60.0
	var m: float = float(td["minute"]) + float(td["second"]) / 60.0
	var sec: float = float(td["second"])
	var ha: float = TAU * h / 12.0
	var ma: float = TAU * m / 60.0
	var sa: float = TAU * sec / 60.0
	c.draw_line(p, p + Vector2(sin(ha), -cos(ha)) * r * 0.48, ink, 4.0, true)
	c.draw_line(p, p + Vector2(sin(ma), -cos(ma)) * r * 0.70, ink, 3.0, true)
	c.draw_line(p, p + Vector2(sin(sa), -cos(sa)) * r * 0.76, Color("#C0583F"), 1.5, true)
	c.draw_circle(p, 3.5, ink)


func _draw_steam(c: Control) -> void:
	for p: Vector3 in _steam:
		var life: float = p.z / 3.2
		var a: float = sin(life * PI) * 0.42
		var rad: float = 6.0 + life * 18.0
		c.draw_circle(Vector2(p.x, p.y), rad, Color(1.0, 1.0, 1.0, a))


## Duvar boyunca yürüyen başka bir böcek (raf altı çizgisi)
func _draw_wall_bug(c: Control) -> void:
	var k: float = _joke_t / _joke_len
	var x: float = lerpf(-40.0, GameConfig.KITCHEN_IMG_SIZE.x + 40.0, k)
	var y: float = 528.0 + sin(k * TAU * 3.0) * 6.0
	_draw_small_bug(c, Vector2(x, y), 15.0, _joke_t)


func _draw_small_bug(c: Control, at: Vector2, s: float, t: float) -> void:
	var ink: Color = GameConfig.COLOR_INK
	for i: int in range(3):
		var lx: float = at.x - s * 0.5 + float(i) * s * 0.5
		var step: float = sin(t * 18.0 + float(i) * 2.0) * s * 0.25
		c.draw_line(Vector2(lx, at.y), Vector2(lx + step, at.y - s * 0.75), ink, 1.6, true)
		c.draw_line(Vector2(lx, at.y), Vector2(lx - step, at.y + s * 0.75), ink, 1.6, true)
	c.draw_set_transform_matrix(image_xform() * Transform2D(0.0, Vector2(1.0, 0.6), 0.0, at))
	c.draw_circle(Vector2.ZERO, s, GameConfig.COLOR_BROWN.darkened(0.15))
	c.draw_arc(Vector2.ZERO, s, 0.0, TAU, 18, ink, 2.0, true)
	c.draw_set_transform_matrix(image_xform())
	var head: Vector2 = at + Vector2(s * 1.0, 0.0)
	c.draw_circle(head, s * 0.4, GameConfig.COLOR_BROWN.darkened(0.35))
	c.draw_line(head, head + Vector2(s * 0.9, -s * 0.7 + sin(t * 9.0) * 3.0), ink, 1.4, true)
	c.draw_line(head, head + Vector2(s * 1.0, -s * 0.2 + sin(t * 7.0) * 3.0), ink, 1.4, true)


# ---------------------------------------------------------------------------
# Işık katmanı (toplamalı)
# ---------------------------------------------------------------------------

func _draw_glow(c: Control) -> void:
	if not is_night():
		return
	var xf: Transform2D = image_xform()
	var sc: float = image_scale()
	# Pencereden ay ışığı
	var wr: Rect2 = GameConfig.KITCHEN_WINDOW_RECT
	var wc: Vector2 = xf * (wr.position + wr.size * 0.5)
	_soft_light(c, wc, wr.size.x * sc * 1.3, Color(0.42, 0.50, 0.75, 0.32))
	# Dolap altı lambası: rafların altında sıcak şerit
	for i: int in range(4):
		var p: Vector2 = xf * Vector2(390.0 + float(i) * 52.0, 520.0)
		_soft_light(c, p, 70.0 * sc, Color(GameConfig.KITCHEN_NIGHT_LAMP, 0.45))
	# Tezgâh lambası: karakterin üstünde sıcak ışık havuzu
	var lamp_c: Vector2 = Vector2(c.size.x * 0.5, counter_y - 70.0)
	_soft_light(c, lamp_c, c.size.x * 0.5, Color(GameConfig.KITCHEN_NIGHT_LAMP, 0.7))
	_soft_light(c, Vector2(c.size.x * 0.82, counter_y - 30.0), c.size.x * 0.16, Color(1.0, 0.62, 0.30, 0.4))


func _soft_light(c: Control, at: Vector2, radius: float, col: Color) -> void:
	var steps: int = 16
	for i: int in range(steps):
		var k: float = 1.0 - float(i) / float(steps)
		c.draw_circle(at, radius * k, Color(col.r, col.g, col.b, col.a / float(steps)))


# ---------------------------------------------------------------------------
# Ön katman: tezgâh
# ---------------------------------------------------------------------------

func _draw_front(c: Control) -> void:
	var w: float = c.size.x
	var top: float = counter_y - 14.0
	var slab_h: float = 42.0
	var ink: Color = GameConfig.COLOR_INK
	var pan: float = _pan(GameConfig.KITCHEN_PAN_FRONT_MULT)
	# Dolap gövdesi (ekranın altına kadar)
	c.draw_rect(Rect2(-4.0, top + slab_h, w + 8.0, c.size.y - top - slab_h + 4.0), GameConfig.KITCHEN_CABINET)
	var door_w: float = 220.0
	var x0: float = fposmod(pan, door_w) - door_w
	var door_i: int = 0
	while x0 < w + door_w:
		var dr: Rect2 = Rect2(x0 + 12.0, top + slab_h + 18.0, door_w - 24.0, c.size.y - top - slab_h)
		c.draw_rect(dr, GameConfig.KITCHEN_CABINET.lightened(0.06))
		c.draw_rect(dr, Color(ink, 0.55), false, 2.0)
		c.draw_rect(dr.grow(-14.0), Color(ink, 0.18), false, 2.0)
		var knob: Vector2 = Vector2(dr.position.x + (dr.size.x - 22.0 if door_i % 2 == 0 else 22.0), dr.position.y + 36.0)
		c.draw_circle(knob, 7.0, Color("#E8C27A"))
		c.draw_arc(knob, 7.0, 0.0, TAU, 14, ink, 2.0, true)
		x0 += door_w
		door_i += 1
	# Gölge şeridi (tezgâhın altı)
	c.draw_rect(Rect2(-4.0, top + slab_h, w + 8.0, 10.0), Color(0.141, 0.086, 0.055, 0.22))
	# Tezgâh plakası: üst kenar hafif düzensiz (el çizimi)
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = _counter_jitter.size()
	for i: int in range(n):
		var x: float = -8.0 + (w + 16.0) * float(i) / float(n - 1)
		pts.append(Vector2(x, top + _counter_jitter[i] * 0.6))
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(Vector2(w + 8.0, top + slab_h))
	outline.append(Vector2(-8.0, top + slab_h))
	c.draw_colored_polygon(outline, GameConfig.KITCHEN_COUNTER_WOOD)
	c.draw_rect(Rect2(-8.0, top + slab_h - 12.0, w + 16.0, 12.0), GameConfig.KITCHEN_COUNTER_EDGE)
	# Damarlar
	for gi: int in range(5):
		var gy: float = top + 8.0 + float(gi) * 5.5
		var gx: float = fposmod(pan * 1.0 + float(gi) * 137.0, w + 200.0) - 100.0
		c.draw_line(Vector2(gx, gy), Vector2(gx + 90.0 + float(gi) * 14.0, gy + 1.0), Color(GameConfig.KITCHEN_COUNTER_EDGE, 0.45), 2.0, true)
	c.draw_polyline(pts, ink, 3.0, true)
	c.draw_line(Vector2(-8.0, top + slab_h), Vector2(w + 8.0, top + slab_h), ink, 3.0, true)
	# Karakterin gölgesi
	if show_actor and actor != null:
		var sh_c: Vector2 = Vector2(actor_home().x + actor_offset.x, top + 6.0)
		var lift: float = clampf(-actor_offset.y / 300.0, 0.0, 1.0)
		c.draw_set_transform(sh_c, 0.0, Vector2(1.0, 0.22))
		c.draw_circle(Vector2.ZERO, 58.0 * (1.0 - lift * 0.6), Color(0.141, 0.086, 0.055, 0.22 * (1.0 - lift)))
		c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_tea_glass(c, Vector2(w * 0.82 + pan * 0.4, top + 4.0))
	if _joke == "slipper_peek":
		_draw_slipper_peek(c)
	if is_night():
		c.draw_rect(Rect2(Vector2(0.0, top - 20.0), Vector2(w, c.size.y - top + 20.0)), Color(GameConfig.KITCHEN_NIGHT_TINT, GameConfig.KITCHEN_NIGHT_TINT.a * 0.55))
	if _grain != null:
		c.draw_texture_rect(_grain, Rect2(Vector2.ZERO, c.size), true, Color(1.0, 1.0, 1.0, 0.035))


## İnce belli çay bardağı, tabağı ve buharı
func _draw_tea_glass(c: Control, base: Vector2) -> void:
	var ink: Color = GameConfig.COLOR_INK
	c.draw_set_transform(base, 0.0, Vector2(1.0, 0.28))
	c.draw_circle(Vector2.ZERO, 34.0, Color("#E9E2D6"))
	c.draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 24, ink, 2.5 / 0.28, true)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var glass: PackedVector2Array = PackedVector2Array([
		base + Vector2(-17.0, -62.0), base + Vector2(17.0, -62.0), base + Vector2(10.0, -38.0),
		base + Vector2(14.0, -8.0), base + Vector2(-14.0, -8.0), base + Vector2(-10.0, -38.0),
	])
	var tea: PackedVector2Array = PackedVector2Array([
		base + Vector2(-15.0, -54.0), base + Vector2(15.0, -54.0), base + Vector2(9.5, -38.0),
		base + Vector2(13.0, -10.0), base + Vector2(-13.0, -10.0), base + Vector2(-9.5, -38.0),
	])
	c.draw_colored_polygon(glass, Color(1.0, 0.98, 0.95, 0.55))
	c.draw_colored_polygon(tea, Color("#B5432A"))
	var closed: PackedVector2Array = glass.duplicate()
	closed.append(glass[0])
	c.draw_polyline(closed, ink, 2.5, true)
	c.draw_line(base + Vector2(-8.0, -50.0), base + Vector2(-6.0, -40.0), Color(1.0, 1.0, 1.0, 0.6), 2.0, true)
	for g: Vector3 in _glass_steam:
		var life: float = g.z / 2.2
		c.draw_circle(base + Vector2(g.x, -66.0 + g.y), 4.0 + life * 9.0, Color(1.0, 1.0, 1.0, sin(life * PI) * 0.35))


## Kenardan uzanıp kaybolan terlik ucu
func _draw_slipper_peek(c: Control) -> void:
	if _slipper_tex == null:
		return
	var k: float = _ease_peak(_joke_t / _joke_len)
	var tsz: Vector2 = _slipper_tex.get_size()
	var sc: float = 120.0 / maxf(tsz.y, 1.0)
	var x: float = c.size.x + 40.0 - 95.0 * k
	var at: Vector2 = Vector2(x, counter_y - 40.0)
	c.draw_set_transform(at, deg_to_rad(-70.0), Vector2(sc, sc))
	c.draw_texture(_slipper_tex, -tsz * 0.5)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _ease_peak(k: float) -> float:
	# 0 -> 1 (ilk %25) -> bekle -> 0 (son %25)
	if k < 0.25:
		return ease(k / 0.25, 0.4)
	if k > 0.75:
		return ease((1.0 - k) / 0.25, 0.4)
	return 1.0


# ---------------------------------------------------------------------------
# Intro örtüleri
# ---------------------------------------------------------------------------

func _draw_shade(c: Control) -> void:
	if darkness <= 0.001:
		return
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(GameConfig.INTRO_NIGHT_TINT, 0.94 * darkness))


func _draw_crack(c: Control) -> void:
	if fridge_crack <= 0.001:
		return
	var xf: Transform2D = image_xform()
	var dr: Rect2 = GameConfig.KITCHEN_FRIDGE_DOOR_RECT
	var top: Vector2 = xf * (dr.position + Vector2(2.0, 10.0))
	var bottom: Vector2 = xf * (dr.position + Vector2(2.0, dr.size.y + 330.0))
	var col: Color = Color(1.0, 0.85, 0.55, 1.0)
	# İnce parlak çizgi + yere düşen ışık üçgeni
	c.draw_line(top, bottom, Color(col, 0.9 * fridge_crack), 4.0, true)
	# Kapı aralığından sola açılan ışık üçgeni (her zaman geçerli üçgen)
	var wedge: PackedVector2Array = PackedVector2Array([top, bottom, Vector2(bottom.x - 260.0, bottom.y + 140.0)])
	c.draw_colored_polygon(wedge, Color(col, 0.16 * fridge_crack))
	_soft_light(c, (top + bottom) * 0.5, 160.0, Color(col, 0.35 * fridge_crack))


func _draw_flash(c: Control) -> void:
	if flash <= 0.001:
		return
	c.draw_rect(Rect2(Vector2.ZERO, c.size), Color(1.0, 0.99, 0.95, flash))


## Kâğıt dokusu için küçük gürültü dokusu (tekrarlanarak çizilir)
func _make_grain() -> Texture2D:
	var img: Image = Image.create_empty(96, 96, false, Image.FORMAT_RGBA8)
	var r: RandomNumberGenerator = RandomNumberGenerator.new()
	r.seed = 1307
	for y: int in range(96):
		for x: int in range(96):
			var v: float = r.randf()
			img.set_pixel(x, y, Color(v, v * 0.95, v * 0.88, 1.0))
	return ImageTexture.create_from_image(img)

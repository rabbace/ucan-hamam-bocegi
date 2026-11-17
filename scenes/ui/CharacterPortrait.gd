class_name CharacterPortrait
extends Control

## Faz 10.3: Oyuncuya dönük, büyük önden karakter yüzü.
## Üç çizim yolu vardır (ilk bulunan kullanılır):
##   1) Parçalı portre: res://assets/sprites/chars/<id>/portre/*.png (aynı tuvalde hizalı katmanlar)
##   2) Hazır görsel: CharacterData angry_path (sinirli) / front_path (diğer ifadeler)
##   3) Kodla çizilen pastel yedek yüz (kaşlar, gözler, ağız, antenler, yumruklar, aksesuar)
## İfadeler: sinirli, cok_sinirli, gururlu, kus, ciddi.

signal one_more_requested

const EXPR_ANGRY: String = "sinirli"
const EXPR_FURIOUS: String = "cok_sinirli"
const EXPR_PROUD: String = "gururlu"
const EXPR_SULK: String = "kus"
## Faz 11.2: rövanşa basınca "ciddi" (kararlı) yüz
const EXPR_SERIOUS: String = "ciddi"
const TAPS_FOR_ONE_MORE: int = 5
const STEAM_MAX: int = 12
const STEAM_HALF: int = 6

var char_id: String = "klasik"
var expression: String = EXPR_ANGRY
var interactive: bool = true
## true: replik balonu portrenin üst kenarının içinde durur (üstünde yer olmayan panellerde taşmasın).
var bubble_inside: bool = false

var _mode: String = "vector"
var _base_tex: Texture2D = null
var _parts: Dictionary = {}
var _tint: Color = Color("#8B5A3C")
var _t: float = 0.0
var _talk_t: float = 0.0
var _look: Vector2 = Vector2.ZERO
var _look_target: Vector2 = Vector2.ZERO
var _antenna_vel: Vector2 = Vector2.ZERO
var _antenna_off: Vector2 = Vector2.ZERO
var _taps: int = 0
var _tear_y: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

var _steam_l: CPUParticles2D = null
var _steam_r: CPUParticles2D = null
var _sparkles: CPUParticles2D = null
var _bubble: PanelContainer = null
var _bubble_lbl: Label = null
var _bubble_remaining: float = 0.0


func _ready() -> void:
	_rng.randomize()
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_build_fx()
	resized.connect(_layout_fx)
	_layout_fx()


## Karakteri ve ifadeyi ayarlar.
func setup(p_char_id: String, p_expression: String = EXPR_ANGRY) -> void:
	char_id = p_char_id
	_tint = CharacterData.get_portrait_tint(char_id)
	_taps = 0
	_load_parts()
	set_expression(p_expression)


func set_expression(p_expression: String) -> void:
	expression = p_expression
	_choose_base_texture()
	var angry: bool = expression == EXPR_ANGRY or expression == EXPR_FURIOUS
	if _steam_l != null:
		_steam_l.emitting = angry
		_steam_r.emitting = angry
		var amt: int = STEAM_MAX if expression == EXPR_FURIOUS else STEAM_HALF
		_steam_l.amount = amt
		_steam_r.amount = amt
		_sparkles.emitting = expression == EXPR_PROUD
	_tear_y = 0.0
	queue_redraw()


## Ekranın altından fırlayarak gelme animasyonu (0.6 → 1.08 → 1.0).
func pop_in() -> void:
	pivot_offset = size * 0.5
	scale = Vector2(0.6, 0.6)
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(self, "scale", Vector2(1.08, 1.08), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "scale", Vector2.ONE, 0.13)


## Portrenin üstünde konuşma balonu gösterir ve ağzı konuşturur.
func say(text: String, duration: float = 2.4) -> void:
	if _bubble == null:
		return
	_bubble_lbl.text = GameConfig.censor(text)
	_bubble.visible = true
	_bubble.modulate.a = 1.0
	_layout_fx()
	_bubble.scale = Vector2(0.4, 0.4)
	var tw: Tween = create_tween()
	tw.tween_property(_bubble, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_bubble_remaining = duration
	_talk_t = minf(duration, 1.8)
	_layout_fx()


func _process(delta: float) -> void:
	_t += delta
	if _talk_t > 0.0:
		_talk_t = maxf(_talk_t - delta, 0.0)
	if _bubble_remaining > 0.0:
		_bubble_remaining -= delta
		if _bubble_remaining <= 0.0 and _bubble != null:
			var tw: Tween = create_tween()
			tw.tween_property(_bubble, "modulate:a", 0.0, 0.25)
			tw.tween_callback(func() -> void: _bubble.visible = false)
	_look = _look.lerp(_look_target, clampf(delta * 8.0, 0.0, 1.0))
	if _look_target.length() > 0.01 and _rng.randf() < delta * 0.4:
		_look_target = Vector2.ZERO
	# Anten yayı: sinirde titrer
	var kick: float = 0.0
	if expression == EXPR_ANGRY:
		kick = 40.0
	elif expression == EXPR_FURIOUS:
		kick = 110.0
	var force: Vector2 = -_antenna_off * 60.0 - _antenna_vel * 7.0
	force += Vector2(_rng.randf_range(-kick, kick), _rng.randf_range(-kick, kick))
	_antenna_vel += force * delta
	_antenna_off += _antenna_vel * delta
	if expression == EXPR_SULK:
		_tear_y = fmod(_tear_y + delta * 0.25, 1.0)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	var pressed: bool = false
	var pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		pressed = mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
		pos = mb.position
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		pressed = st.pressed
		pos = st.position
	if not pressed:
		return
	accept_event()
	_taps += 1
	var c: Vector2 = size * 0.5
	_look_target = ((pos - c) / maxf(minf(size.x, size.y) * 0.5, 1.0)).limit_length(1.0)
	if _taps >= TAPS_FOR_ONE_MORE:
		_taps = 0
		set_expression(EXPR_FURIOUS)
		say("Tamam! Bi el daha!", 2.0)
		if AudioManager.is_vibration_enabled:
			Input.vibrate_handheld(30)
		one_more_requested.emit()
	else:
		if expression == EXPR_ANGRY or expression == EXPR_FURIOUS:
			say(CharacterData.get_random_lose_line(char_id), 2.0)
		elif expression == EXPR_PROUD:
			say(CharacterData.get_random_win_line(char_id), 2.0)
		else:
			say("Az kalmıştı…", 1.6)
		var snd: String = "res://assets/sounds/chars/%s/sinir.ogg" % char_id
		if ResourceLoader.exists(snd):
			AudioManager.play_sfx(snd)


# ---------------------------------------------------------------- kurulum

func _load_parts() -> void:
	_parts.clear()
	var dir: String = "res://assets/sprites/chars/%s/portre/" % char_id
	if not ResourceLoader.exists(dir + "kafa.png"):
		return
	for part: String in ["kafa", "kas", "goz", "goz_bebek", "agiz_bagir", "agiz_gul", "agiz_kapali", "aksesuar", "el_yumruk", "el_parmak"]:
		var p: String = dir + part + ".png"
		if ResourceLoader.exists(p):
			_parts[part] = load(p) as Texture2D


func _choose_base_texture() -> void:
	if not _parts.is_empty():
		_mode = "parts"
		return
	var cdata: Dictionary = CharacterData.get_character(char_id)
	var angry_path: String = str(cdata.get("angry_path", ""))
	var front_path: String = str(cdata.get("front_path", ""))
	_base_tex = null
	var angry: bool = expression == EXPR_ANGRY or expression == EXPR_FURIOUS
	if angry and not angry_path.is_empty() and ResourceLoader.exists(angry_path):
		_base_tex = load(angry_path) as Texture2D
	elif not angry and not front_path.is_empty() and ResourceLoader.exists(front_path):
		_base_tex = load(front_path) as Texture2D
	_mode = "texture" if _base_tex != null else "vector"


func _build_fx() -> void:
	_steam_l = _make_steam(Vector2(-1.0, -0.6))
	_steam_r = _make_steam(Vector2(1.0, -0.6))
	_sparkles = CPUParticles2D.new()
	_sparkles.amount = 10
	_sparkles.lifetime = 0.9
	_sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_sparkles.emission_sphere_radius = 120.0
	_sparkles.gravity = Vector2(0.0, -30.0)
	_sparkles.initial_velocity_min = 5.0
	_sparkles.initial_velocity_max = 20.0
	_sparkles.scale_amount_min = 4.0
	_sparkles.scale_amount_max = 8.0
	_sparkles.color = Color("#F5D76E")
	_sparkles.emitting = false
	add_child(_sparkles)

	_bubble = PanelContainer.new()
	_bubble.visible = false
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 0.98, 0.97)
	sb.border_color = GameConfig.COLOR_DARK_TEXT
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(10)
	sb.shadow_color = Color(0.24, 0.21, 0.19, 0.25)
	sb.shadow_size = 4
	_bubble.add_theme_stylebox_override("panel", sb)
	_bubble_lbl = Label.new()
	_bubble_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bubble_lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	_bubble_lbl.add_theme_font_size_override("font_size", 22)
	_bubble_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_bubble.add_child(_bubble_lbl)
	add_child(_bubble)


func _make_steam(side: Vector2) -> CPUParticles2D:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.amount = STEAM_HALF
	p.lifetime = 0.8
	p.direction = Vector2(side.x * 0.6, -1.0)
	p.spread = 18.0
	p.gravity = Vector2(0.0, -80.0)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 120.0
	p.scale_amount_min = 8.0
	p.scale_amount_max = 16.0
	var ramp: Gradient = Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 1.0, 0.75))
	ramp.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	p.color_ramp = ramp
	p.emitting = false
	p.set_meta("side", side)
	add_child(p)
	return p


func _layout_fx() -> void:
	var s: float = minf(size.x, size.y)
	var c: Vector2 = size * 0.5
	if _steam_l != null:
		_steam_l.position = c + Vector2(-0.34 * s, -0.22 * s)
		_steam_r.position = c + Vector2(0.34 * s, -0.22 * s)
		_sparkles.position = c
		_sparkles.emission_sphere_radius = 0.42 * s
	if _bubble != null:
		var bw: float = clampf(size.x * 0.9, 220.0, 520.0)
		# Kaydırmalı etiketin genişliği verilmezse yazı görünmez; kenar boşlukları (2x10) düşülür.
		_bubble_lbl.custom_minimum_size = Vector2(bw - 20.0, 0.0)
		_bubble.custom_minimum_size = Vector2(bw, 0.0)
		_bubble.size = Vector2(bw, 0.0)
		_bubble.reset_size()
		var bh: float = _bubble.get_combined_minimum_size().y
		var by: float = 0.0 if bubble_inside else -0.08 * s - bh
		_bubble.position = Vector2((size.x - bw) * 0.5, by)
		_bubble.pivot_offset = Vector2(bw, bh) * 0.5


# ---------------------------------------------------------------- çizim

func _shake() -> Vector2:
	if expression == EXPR_FURIOUS:
		return Vector2(_rng.randf_range(-6.0, 6.0), _rng.randf_range(-6.0, 6.0))
	if expression == EXPR_ANGRY:
		return Vector2(sin(_t * 38.0) * 2.5, cos(_t * 31.0) * 1.5)
	return Vector2.ZERO


func _anger_pulse() -> float:
	if expression == EXPR_ANGRY:
		return (sin(_t * 6.0) + 1.0) * 0.5 * 0.35
	if expression == EXPR_FURIOUS:
		return 0.35 + (sin(_t * 10.0) + 1.0) * 0.5 * 0.35
	return 0.0


func _draw() -> void:
	var s: float = minf(size.x, size.y)
	if s <= 4.0:
		return
	var c: Vector2 = size * 0.5 + _shake()
	match _mode:
		"parts":
			_draw_parts(c, s)
		"texture":
			_draw_texture_mode(c, s)
		_:
			_draw_vector_face(c, s)


func _draw_texture_mode(c: Vector2, s: float) -> void:
	var tex_sz: Vector2 = _base_tex.get_size()
	var k: float = s / maxf(tex_sz.x, tex_sz.y)
	var bounce: float = 1.0
	if _talk_t > 0.0:
		bounce = 1.0 + absf(sin(_t * 16.0)) * 0.05
	var draw_sz: Vector2 = tex_sz * k * Vector2(bounce, 2.0 - bounce)
	var tint: Color = Color.WHITE.lerp(Color(1.0, 0.55, 0.5), _anger_pulse())
	draw_texture_rect(_base_tex, Rect2(c - draw_sz * 0.5, draw_sz), false, tint)
	_draw_extras(c, s)


func _draw_parts(c: Vector2, s: float) -> void:
	var rect: Rect2 = Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s))
	var tint: Color = Color.WHITE.lerp(Color(1.0, 0.6, 0.55), _anger_pulse())
	if _parts.has("kafa"):
		draw_texture_rect(_parts["kafa"] as Texture2D, rect, false, tint)
	if _parts.has("goz"):
		draw_texture_rect(_parts["goz"] as Texture2D, rect, false)
	if _parts.has("goz_bebek"):
		draw_texture_rect(_parts["goz_bebek"] as Texture2D, Rect2(rect.position + _look * s * 0.03, rect.size), false)
	if _parts.has("kas"):
		var ang: float = 0.0
		if expression == EXPR_ANGRY:
			ang = 0.12
		elif expression == EXPR_FURIOUS:
			ang = 0.22
		elif expression == EXPR_PROUD:
			ang = -0.10
		elif expression == EXPR_SERIOUS:
			ang = 0.05
		draw_set_transform(c, ang, Vector2.ONE)
		draw_texture_rect(_parts["kas"] as Texture2D, Rect2(-Vector2(s, s) * 0.5, Vector2(s, s)), false)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var mouth_key: String = "agiz_kapali"
	if expression == EXPR_ANGRY or expression == EXPR_FURIOUS:
		mouth_key = "agiz_bagir" if (_talk_t <= 0.0 or sin(_t * 26.0) > -0.3) else "agiz_kapali"
	elif expression == EXPR_PROUD:
		mouth_key = "agiz_gul"
	if _parts.has(mouth_key):
		draw_texture_rect(_parts[mouth_key] as Texture2D, rect, false)
	if _parts.has("aksesuar"):
		draw_texture_rect(_parts["aksesuar"] as Texture2D, rect, false)
	var hand_key: String = "el_parmak" if expression == EXPR_PROUD else "el_yumruk"
	if _parts.has(hand_key) and expression != EXPR_SULK:
		var wob: Vector2 = Vector2(0.0, sin(_t * 14.0) * s * 0.02)
		draw_texture_rect(_parts[hand_key] as Texture2D, Rect2(rect.position + wob, rect.size), false)
	_draw_extras(c, s)


func _draw_extras(c: Vector2, s: float) -> void:
	if expression == EXPR_SULK:
		var tp: Vector2 = c + Vector2(-0.12 * s, 0.02 * s + _tear_y * 0.18 * s)
		var r: float = 0.025 * s
		draw_circle(tp, r, Color("#9AD0E6"))
		draw_colored_polygon(PackedVector2Array([tp + Vector2(-r, 0.0), tp + Vector2(r, 0.0), tp + Vector2(0.0, -r * 2.4)]), Color("#9AD0E6"))
	if expression == EXPR_ANGRY or expression == EXPR_FURIOUS:
		# Sinir işareti (çizgi roman damarı)
		var a: Vector2 = c + Vector2(0.30 * s, -0.30 * s)
		var rr: float = 0.035 * s
		var col: Color = GameConfig.COLOR_WARN_RED
		draw_arc(a + Vector2(-rr, -rr), rr, 0.0, PI * 0.5, 8, col, 4.0)
		draw_arc(a + Vector2(rr, -rr), rr, PI * 0.5, PI, 8, col, 4.0)
		draw_arc(a + Vector2(rr, rr), rr, PI, PI * 1.5, 8, col, 4.0)
		draw_arc(a + Vector2(-rr, rr), rr, PI * 1.5, TAU, 8, col, 4.0)


func _draw_vector_face(c: Vector2, s: float) -> void:
	var ink: Color = GameConfig.COLOR_DARK_TEXT
	var head_col: Color = _tint.lerp(Color(0.86, 0.32, 0.28), _anger_pulse())
	var head_r: Vector2 = Vector2(0.30 * s, 0.31 * s)
	var head_c: Vector2 = c + Vector2(0.0, -0.04 * s)

	# Göğüs (pronotum) ve gövde halkaları: yüz bir topa değil böceğe benzesin
	var thor_c: Vector2 = head_c + Vector2(0.0, head_r.y * 1.05)
	var thor_col: Color = _tint.darkened(0.22)
	_draw_ellipse(thor_c, Vector2(head_r.x * 1.25, head_r.y * 0.55), thor_col)
	_draw_ellipse_outline(thor_c, Vector2(head_r.x * 1.25, head_r.y * 0.55), ink, maxf(s * 0.01, 2.0))
	for k: int in range(2):
		var yk: float = thor_c.y + head_r.y * (0.12 + 0.18 * float(k))
		var wk: float = head_r.x * (1.05 - 0.18 * float(k))
		draw_arc(Vector2(thor_c.x, yk - head_r.y * 0.35), wk, PI * 0.2, PI * 0.8, 18, Color(ink, 0.55), maxf(s * 0.006, 1.5))
	draw_circle(thor_c + Vector2(-head_r.x * 0.5, -head_r.y * 0.12), head_r.x * 0.12, Color(1, 1, 1, 0.08))

	# Antenler (yay fiziği)
	for side: float in [-1.0, 1.0]:
		var base: Vector2 = head_c + Vector2(side * 0.10 * s, -head_r.y * 0.92)
		var tip: Vector2 = base + Vector2(side * 0.16 * s, -0.24 * s) + _antenna_off * Vector2(side, 1.0) * 0.6
		var mid: Vector2 = base.lerp(tip, 0.5) + Vector2(side * 0.05 * s, 0.02 * s)
		draw_polyline(PackedVector2Array([base, mid, tip]), ink, maxf(s * 0.014, 2.0), true)
		var tip_col: Color = ink
		if char_id == "siber":
			tip_col = Color("#D9605A") if side < 0.0 else Color("#7FB3D5")
		draw_circle(tip, s * 0.018, tip_col)

	# Kafa (hafif düzensiz kontur: el çizimi hissi)
	var pts: PackedVector2Array = PackedVector2Array()
	var n: int = 40
	for i: int in range(n):
		var a: float = TAU * float(i) / float(n)
		var wob: float = 1.0 + sin(a * 5.0 + 1.3) * 0.012
		pts.append(head_c + Vector2(cos(a) * head_r.x, sin(a) * head_r.y) * wob)
	draw_colored_polygon(pts, head_col)
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, ink, maxf(s * 0.012, 2.0), true)
	# Alın plakası ve ışık
	draw_arc(head_c + Vector2(0.0, -head_r.y * 0.15), head_r.x * 0.82, PI * 1.15, PI * 1.85, 20, Color(ink, 0.35), maxf(s * 0.008, 1.5))
	draw_circle(head_c + Vector2(-0.14 * s, -0.13 * s), 0.045 * s, Color(1, 1, 1, 0.12))
	# Çene uçları (mandibula)
	for side: float in [-1.0, 1.0]:
		var mb: Vector2 = head_c + Vector2(side * 0.10 * s, head_r.y * 0.78)
		draw_colored_polygon(PackedVector2Array([mb, mb + Vector2(side * 0.05 * s, 0.03 * s), mb + Vector2(side * 0.005 * s, 0.07 * s)]), _tint.darkened(0.35))

	_draw_accessory_back(head_c, head_r, s)

	# Gözler
	var eye_r: float = 0.085 * s
	var eye_y: float = head_c.y - 0.04 * s
	var eyes: Array[Vector2] = [Vector2(head_c.x - 0.12 * s, eye_y), Vector2(head_c.x + 0.12 * s, eye_y)]
	var squint: float = 1.0
	if expression == EXPR_ANGRY:
		squint = 0.72
	elif expression == EXPR_FURIOUS:
		squint = 0.55
	elif expression == EXPR_SULK:
		squint = 0.6
	elif expression == EXPR_SERIOUS:
		squint = 0.62
	for i: int in range(2):
		var e: Vector2 = eyes[i]
		var wink: bool = expression == EXPR_PROUD and i == 1 and fmod(_t, 2.4) < 0.9
		if wink:
			draw_arc(e + Vector2(0.0, eye_r * 0.2), eye_r * 0.8, PI * 1.1, PI * 1.9, 10, ink, maxf(s * 0.012, 2.0))
			continue
		_draw_ellipse(e, Vector2(eye_r, eye_r * squint), Color(1, 1, 1))
		_draw_ellipse_outline(e, Vector2(eye_r, eye_r * squint), ink, maxf(s * 0.008, 1.5))
		var pup: Vector2 = e + _look * eye_r * 0.45
		var pr: float = eye_r * (0.42 if char_id != "saftirik" else 0.55)
		draw_circle(pup, pr * minf(squint + 0.2, 1.0), ink)
		draw_circle(pup + Vector2(-pr * 0.3, -pr * 0.3), pr * 0.28, Color(1, 1, 1, 0.9))
		if expression == EXPR_FURIOUS:
			draw_line(e + Vector2(-eye_r * 0.8, 0.0), e + Vector2(-eye_r * 0.3, eye_r * 0.2), Color("#D9605A"), 2.0)
			draw_line(e + Vector2(eye_r * 0.8, -eye_r * 0.1), e + Vector2(eye_r * 0.35, eye_r * 0.15), Color("#D9605A"), 2.0)

	# Kaşlar
	var bw: float = maxf(s * 0.022, 3.0)
	if expression == EXPR_FURIOUS:
		bw *= 1.4
	for i: int in range(2):
		var side: float = -1.0 if i == 0 else 1.0
		var e: Vector2 = eyes[i]
		var outer: Vector2 = e + Vector2(side * eye_r * 1.1, -eye_r * 1.25)
		var inner: Vector2 = e + Vector2(-side * eye_r * 0.4, -eye_r * 1.25)
		match expression:
			EXPR_ANGRY:
				outer.y -= eye_r * 0.35
				inner.y += eye_r * 0.35
			EXPR_FURIOUS:
				outer.y -= eye_r * 0.6
				inner.y += eye_r * 0.55
			EXPR_PROUD:
				if i == 0:
					outer.y -= eye_r * 0.35
					inner.y -= eye_r * 0.35
			EXPR_SULK:
				outer.y += eye_r * 0.25
				inner.y -= eye_r * 0.15
			EXPR_SERIOUS:
				outer.y += eye_r * 0.05
				inner.y += eye_r * 0.2
		draw_line(outer, inner, ink, bw, true)

	# Ağız
	var m: Vector2 = head_c + Vector2(0.0, 0.14 * s)
	match expression:
		EXPR_ANGRY, EXPR_FURIOUS:
			var open_amt: float = 0.75
			if _talk_t > 0.0:
				open_amt = 0.45 + (sin(_t * 26.0) + 1.0) * 0.5 * 0.55
			var mw: float = 0.13 * s * (1.25 if expression == EXPR_FURIOUS else 1.0)
			var mh: float = 0.075 * s * open_amt
			_draw_ellipse(m, Vector2(mw, mh), Color(0.30, 0.06, 0.06))
			if mh > 0.02 * s:
				draw_rect(Rect2(m + Vector2(-mw * 0.6, -mh * 0.95), Vector2(mw * 1.2, mh * 0.35)), Color(1, 1, 0.96))
			_draw_ellipse_outline(m, Vector2(mw, mh), ink, maxf(s * 0.009, 2.0))
		EXPR_PROUD:
			draw_arc(m + Vector2(0.0, -0.05 * s), 0.11 * s, PI * 0.15, PI * 0.85, 16, ink, maxf(s * 0.014, 2.5))
		EXPR_SULK:
			var a1: Vector2 = m + Vector2(-0.07 * s, 0.01 * s)
			var a2: Vector2 = m + Vector2(-0.02 * s, -0.012 * s)
			var a3: Vector2 = m + Vector2(0.03 * s, 0.006 * s)
			var a4: Vector2 = m + Vector2(0.07 * s, -0.008 * s)
			draw_polyline(PackedVector2Array([a1, a2, a3, a4]), ink, maxf(s * 0.012, 2.0), true)
		EXPR_SERIOUS:
			# Düz, sıkılmış ağız: kararlılık
			draw_line(m + Vector2(-0.075 * s, 0.0), m + Vector2(0.075 * s, 0.0), ink, maxf(s * 0.016, 2.5), true)

	_draw_accessory_front(head_c, head_r, s)
	_draw_hands(head_c, head_r, s)
	_draw_extras(c, s)


func _draw_hands(head_c: Vector2, head_r: Vector2, s: float) -> void:
	if expression == EXPR_SULK:
		return
	var ink: Color = GameConfig.COLOR_DARK_TEXT
	var hand_col: Color = _tint.lightened(0.15)
	if expression == EXPR_PROUD:
		var hp: Vector2 = head_c + Vector2(head_r.x * 1.05, head_r.y * 0.55)
		draw_circle(hp, 0.06 * s, hand_col)
		draw_arc(hp, 0.06 * s, 0.0, TAU, 20, ink, 2.0)
		var ang: float = -PI * 0.5 + sin(_t * 9.0) * 0.4
		var tip: Vector2 = hp + Vector2(cos(ang), sin(ang)) * 0.11 * s
		draw_line(hp, tip, hand_col, 0.03 * s, true)
		draw_line(hp, tip, ink, 2.0, true)
		return
	for side: float in [-1.0, 1.0]:
		var speed: float = 16.0 if expression == EXPR_FURIOUS else 10.0
		var hp: Vector2 = head_c + Vector2(side * head_r.x * 1.08, head_r.y * 0.62 + sin(_t * speed + side) * 0.03 * s)
		draw_circle(hp, 0.065 * s, hand_col)
		draw_arc(hp, 0.065 * s, 0.0, TAU, 20, ink, 2.0)
		for k: int in range(3):
			var kx: float = hp.x - 0.03 * s + float(k) * 0.03 * s
			draw_line(Vector2(kx, hp.y - 0.04 * s), Vector2(kx, hp.y - 0.015 * s), ink, 1.5)


func _draw_accessory_back(head_c: Vector2, head_r: Vector2, s: float) -> void:
	match char_id:
		"yurt":
			draw_arc(head_c, head_r.x * 1.05, PI * 1.05, PI * 1.95, 24, Color("#5E6B73"), 0.035 * s)
			draw_circle(head_c + Vector2(-head_r.x * 1.02, 0.0), 0.06 * s, Color("#7F8C8D"))
			draw_circle(head_c + Vector2(head_r.x * 1.02, 0.0), 0.06 * s, Color("#7F8C8D"))


func _draw_accessory_front(head_c: Vector2, head_r: Vector2, s: float) -> void:
	var ink: Color = GameConfig.COLOR_DARK_TEXT
	match char_id:
		"plaza":
			var t0: Vector2 = head_c + Vector2(0.0, head_r.y * 0.98)
			draw_colored_polygon(PackedVector2Array([t0 + Vector2(-0.03 * s, 0.0), t0 + Vector2(0.03 * s, 0.0), t0 + Vector2(0.04 * s, 0.14 * s), t0 + Vector2(0.0, 0.18 * s), t0 + Vector2(-0.04 * s, 0.14 * s)]), Color("#A9BCD0"))
		"usta":
			var hat_c: Vector2 = head_c + Vector2(0.0, -head_r.y * 0.72)
			_draw_half_ellipse_top(hat_c, Vector2(head_r.x * 0.82, head_r.y * 0.38), Color("#F5D76E"))
			draw_rect(Rect2(hat_c + Vector2(-head_r.x * 0.95, -0.01 * s), Vector2(head_r.x * 1.9, 0.035 * s)), Color("#E6C24F"))
		"dayi":
			var cap_c: Vector2 = head_c + Vector2(0.0, -head_r.y * 0.78)
			_draw_half_ellipse_top(cap_c, Vector2(head_r.x * 0.86, head_r.y * 0.3), Color("#7A6A5A"))
			draw_rect(Rect2(cap_c + Vector2(-head_r.x * 0.2, -0.005 * s), Vector2(head_r.x * 1.1, 0.03 * s)), Color("#665747"))
		"taraftar":
			var y0: float = head_c.y + head_r.y * 0.86
			for k: int in range(6):
				var col: Color = Color("#D9605A") if k % 2 == 0 else Color("#F5D76E")
				draw_rect(Rect2(Vector2(head_c.x - head_r.x * 0.9 + float(k) * head_r.x * 0.3, y0), Vector2(head_r.x * 0.3, 0.06 * s)), col)
		"emlakci":
			var b0: Vector2 = head_c + Vector2(0.0, head_r.y * 1.02)
			draw_colored_polygon(PackedVector2Array([b0, b0 + Vector2(-0.06 * s, -0.035 * s), b0 + Vector2(-0.06 * s, 0.035 * s)]), Color("#C94C5A"))
			draw_colored_polygon(PackedVector2Array([b0, b0 + Vector2(0.06 * s, -0.035 * s), b0 + Vector2(0.06 * s, 0.035 * s)]), Color("#C94C5A"))
		"duktur":
			var mc: Vector2 = head_c + Vector2(0.0, -head_r.y * 0.62)
			draw_circle(mc, 0.05 * s, Color("#DDE8EE"))
			draw_arc(mc, 0.05 * s, 0.0, TAU, 18, ink, 2.0)
		"halaybasi":
			var hp: Vector2 = head_c + Vector2(head_r.x * 1.08, head_r.y * 0.4)
			draw_colored_polygon(PackedVector2Array([hp, hp + Vector2(0.09 * s, -0.12 * s + sin(_t * 8.0) * 0.02 * s), hp + Vector2(0.13 * s, -0.02 * s)]), Color("#D9605A"))
		"deli":
			for k: int in range(5):
				var hx: float = head_c.x - head_r.x * 0.5 + float(k) * head_r.x * 0.25
				var hy: float = head_c.y - head_r.y * 0.95
				draw_line(Vector2(hx, hy), Vector2(hx + sin(float(k) * 2.1) * 0.03 * s, hy - 0.06 * s), ink, 2.5, true)
		"diva":
			for e: float in [-1.0, 1.0]:
				var gc: Vector2 = head_c + Vector2(e * 0.12 * s, -0.04 * s)
				draw_arc(gc, 0.1 * s, 0.0, TAU, 20, Color("#C94C5A"), 0.018 * s)
			draw_line(head_c + Vector2(-0.02 * s, -0.04 * s), head_c + Vector2(0.02 * s, -0.04 * s), Color("#C94C5A"), 0.014 * s)
		"siber":
			draw_rect(Rect2(head_c + Vector2(-head_r.x * 0.9, -head_r.y * 0.52), Vector2(head_r.x * 1.8, 0.03 * s)), Color("#9AA4AA"))


func _draw_ellipse(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var a: float = TAU * float(i) / 28.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)


func _draw_ellipse_outline(center: Vector2, radii: Vector2, col: Color, width: float) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(29):
		var a: float = TAU * float(i) / 28.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_polyline(pts, col, width, true)


func _draw_half_ellipse_top(center: Vector2, radii: Vector2, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(17):
		var a: float = PI + PI * float(i) / 16.0
		pts.append(center + Vector2(cos(a) * radii.x, sin(a) * radii.y))
	draw_colored_polygon(pts, col)
	var ol: PackedVector2Array = pts.duplicate()
	ol.append(pts[0])
	draw_polyline(ol, GameConfig.COLOR_DARK_TEXT, 2.0, true)

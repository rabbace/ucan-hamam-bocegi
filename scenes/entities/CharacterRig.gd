class_name CharacterRig
extends Node2D

## 9.1: Parçalı (cutout) karakter iskeleti, ikincil yay/göz fiziği ve AnimationPlayer.

var char_id: String = "klasik"
var anim_player: AnimationPlayer = null

var _govde: Node2D = null
var _kafa: Node2D = null
var _anten_l: Node2D = null
var _anten_r: Node2D = null
var _kanat_arka_l: Node2D = null
var _kanat_arka_r: Node2D = null
var _kanat_on_l: Node2D = null
var _kanat_on_r: Node2D = null
var _kol_arka: Node2D = null
var _kol_on: Node2D = null
var _goz_l: Node2D = null
var _goz_r: Node2D = null
var _bebek_l: Node2D = null
var _bebek_r: Node2D = null
var _agiz: Node2D = null
var _wing_ghost_1: Node2D = null
var _wing_ghost_2: Node2D = null

var _anten_vel: float = 0.0
var _anten_ang: float = 0.0
var _blink_timer: float = 2.6
var _blink_close: float = 0.0
var _talk_until: float = 0.0
var _anim_t: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _current_anim: String = "hover"


func _ready() -> void:
	_rng.randomize()
	_build_rig()
	_build_animations()
	play_anim("hover")


func setup(p_char_id: String) -> void:
	char_id = p_char_id
	if _govde != null:
		_refresh_textures()


func play_anim(anim_name: String) -> void:
	_current_anim = anim_name
	if anim_player != null and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)


func trigger_flap() -> void:
	_anten_vel -= 14.0
	play_anim("flap")


func set_talking(duration: float) -> void:
	_talk_until = maxf(_talk_until, duration)


func update_secondary(delta: float, danger_dir: Vector2, is_falling_fast: bool, is_dead: bool) -> void:
	_anim_t += delta

	# Anten sönümlü yay fiziği
	var k_spring: float = 110.0
	var damping: float = 10.0
	var acc: float = -k_spring * _anten_ang - damping * _anten_vel
	_anten_vel += acc * delta
	_anten_ang = clampf(_anten_ang + _anten_vel * delta, -0.75, 0.75)
	var fall_tilt: float = -0.35 if is_falling_fast else 0.0
	if _anten_l != null:
		_anten_l.rotation = _anten_ang + fall_tilt + sin(_anim_t * 5.0) * 0.08
	if _anten_r != null:
		_anten_r.rotation = -_anten_ang + fall_tilt + cos(_anim_t * 5.2) * 0.08

	# Göz kırpma (2–5 sn rastgele)
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_timer = _rng.randf_range(2.0, 5.0)
		_blink_close = 0.12
	if _blink_close > 0.0:
		_blink_close = maxf(_blink_close - delta, 0.0)
	var eye_sy: float = 0.12 if _blink_close > 0.0 else (1.25 if is_falling_fast else 1.0)
	if _goz_l != null:
		_goz_l.scale.y = eye_sy
	if _goz_r != null:
		_goz_r.scale.y = eye_sy

	# Göz bebekleri en yakın tehlikeye kayar (max 4 px)
	var look_off: Vector2 = danger_dir.limit_length(1.0) * 4.0
	if _bebek_l != null:
		_bebek_l.position = look_off
	if _bebek_r != null:
		_bebek_r.position = look_off

	# Ağız aç/kapa (konuşurken 9 Hz, düşerken açık)
	if _talk_until > 0.0:
		_talk_until = maxf(_talk_until - delta, 0.0)
	if _agiz != null:
		var mouth_open: bool = is_falling_fast or (_talk_until > 0.0 and int(_anim_t * 18.0) % 2 == 0)
		_agiz.scale.y = 1.6 if mouth_open else 0.7

	# Arka kanat titreşimi + motion blur izleri
	var wing_spd: float = 42.0 if not is_dead else 8.0
	var w_ang: float = sin(_anim_t * wing_spd) * 0.55
	if _kanat_arka_l != null:
		_kanat_arka_l.rotation = -0.35 + w_ang
	if _kanat_arka_r != null:
		_kanat_arka_r.rotation = 0.35 - w_ang
	if _wing_ghost_1 != null:
		_wing_ghost_1.visible = not is_dead
		_wing_ghost_1.rotation = -0.35 + sin((_anim_t - 0.025) * wing_spd) * 0.55
	if _wing_ghost_2 != null:
		_wing_ghost_2.visible = not is_dead
		_wing_ghost_2.rotation = -0.35 + sin((_anim_t - 0.05) * wing_spd) * 0.55

	# Panik kolları
	if _kol_arka != null and _kol_on != null and not is_dead:
		if is_falling_fast:
			_kol_arka.rotation = lerpf(_kol_arka.rotation, -1.2, clampf(delta * 10.0, 0.0, 1.0))
			_kol_on.rotation = lerpf(_kol_on.rotation, -1.1, clampf(delta * 10.0, 0.0, 1.0))
		else:
			var row_ang: float = sin(_anim_t * 7.0) * 0.25
			_kol_arka.rotation = row_ang
			_kol_on.rotation = -row_ang


func _build_rig() -> void:
	_wing_ghost_1 = _make_part_node("WingGhost1", Vector2(-12.0, -10.0), Color(0.95, 0.92, 0.85, 0.22), Vector2(38.0, 14.0))
	_wing_ghost_2 = _make_part_node("WingGhost2", Vector2(-14.0, -12.0), Color(0.95, 0.92, 0.85, 0.14), Vector2(38.0, 14.0))
	add_child(_wing_ghost_1)
	add_child(_wing_ghost_2)

	_kanat_arka_l = _make_part_node("KanatArka_Sol", Vector2(-10.0, -8.0), Color(0.96, 0.92, 0.84, 0.55), Vector2(40.0, 15.0))
	_kanat_arka_r = _make_part_node("KanatArka_Sag", Vector2(-8.0, 4.0), Color(0.96, 0.92, 0.84, 0.55), Vector2(40.0, 15.0))
	add_child(_kanat_arka_l)
	add_child(_kanat_arka_r)

	_kanat_on_l = _make_part_node("KanatOn_Sol", Vector2(-8.0, -10.0), Color(0.42, 0.24, 0.14, 0.88), Vector2(36.0, 16.0))
	_kanat_on_r = _make_part_node("KanatOn_Sag", Vector2(-8.0, 6.0), Color(0.42, 0.24, 0.14, 0.88), Vector2(36.0, 16.0))
	add_child(_kanat_on_l)
	add_child(_kanat_on_r)

	_govde = Node2D.new()
	_govde.name = "Govde"
	add_child(_govde)

	_kol_arka = _make_part_node("KolArka", Vector2(8.0, -10.0), Color(0.32, 0.18, 0.10, 0.95), Vector2(20.0, 7.0))
	_govde.add_child(_kol_arka)

	_kafa = Node2D.new()
	_kafa.name = "Kafa"
	_kafa.position = Vector2(24.0, -6.0)
	_govde.add_child(_kafa)

	_anten_l = _make_part_node("Anten_Sol", Vector2(8.0, -10.0), Color(0.22, 0.12, 0.08, 0.95), Vector2(24.0, 3.0))
	_anten_r = _make_part_node("Anten_Sag", Vector2(10.0, -4.0), Color(0.22, 0.12, 0.08, 0.95), Vector2(24.0, 3.0))
	_kafa.add_child(_anten_l)
	_kafa.add_child(_anten_r)

	_goz_l = _make_part_node("Goz_Sol", Vector2(8.0, -5.0), Color.WHITE, Vector2(10.0, 10.0))
	_goz_r = _make_part_node("Goz_Sag", Vector2(14.0, 0.0), Color.WHITE, Vector2(10.0, 10.0))
	_kafa.add_child(_goz_l)
	_kafa.add_child(_goz_r)

	_bebek_l = _make_part_node("Bebek", Vector2.ZERO, Color("#24160E"), Vector2(5.0, 5.0))
	_bebek_r = _make_part_node("Bebek", Vector2.ZERO, Color("#24160E"), Vector2(5.0, 5.0))
	_goz_l.add_child(_bebek_l)
	_goz_r.add_child(_bebek_r)

	_agiz = _make_part_node("Agiz", Vector2(12.0, 7.0), Color("#3D1E18"), Vector2(8.0, 4.0))
	_kafa.add_child(_agiz)

	_kol_on = _make_part_node("KolOn", Vector2(12.0, 8.0), Color(0.32, 0.18, 0.10, 0.95), Vector2(20.0, 7.0))
	_govde.add_child(_kol_on)

	anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	add_child(anim_player)


func _make_part_node(p_name: String, pos: Vector2, col: Color, rect_size: Vector2) -> Node2D:
	var n: Node2D = Node2D.new()
	n.name = p_name
	n.position = pos
	var poly: Polygon2D = Polygon2D.new()
	var hw: float = rect_size.x * 0.5
	var hh: float = rect_size.y * 0.5
	poly.polygon = PackedVector2Array([Vector2(-hw, -hh), Vector2(hw, -hh), Vector2(hw, hh), Vector2(-hw, hh)])
	poly.color = col
	n.add_child(poly)
	return n


func _refresh_textures() -> void:
	var base_dir: String = "res://assets/sprites/chars/%s/" % char_id
	var govde_path: String = base_dir + "govde.png"
	if ResourceLoader.exists(govde_path):
		var spr: Sprite2D = Sprite2D.new()
		spr.texture = load(govde_path) as Texture2D
		_govde.add_child(spr)


func _build_animations() -> void:
	var lib: AnimationLibrary = AnimationLibrary.new()
	for a_name: String in ["hover", "flap", "fall", "near_miss", "talk", "ability_1", "ability_2", "taunt", "win", "death", "idle_menu"]:
		var anim: Animation = Animation.new()
		anim.length = 0.25 if a_name != "flap" else 0.14
		var track: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, "Govde:scale")
		if a_name == "flap":
			anim.track_insert_key(track, 0.0, Vector2(0.96, 1.04))
			anim.track_insert_key(track, 0.14, Vector2.ONE)
		elif a_name == "death":
			anim.track_insert_key(track, 0.0, Vector2.ONE)
			anim.track_insert_key(track, 0.25, Vector2(1.0, -1.0))
		else:
			anim.track_insert_key(track, 0.0, Vector2.ONE)
		lib.add_animation(a_name, anim)
	anim_player.add_animation_library("", lib)

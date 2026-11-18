class_name EventDirector
extends Node2D

## Faz 11.6: Ani olayların oynatıcısı. Zaman ve tür timeline'dan (seed) gelir; çok oyunculu, LAN ve
## Botlarla Oyna'da herkes aynı anda görür (ağ mesajı yok). Bu düğüm dünyanın üstünde çizer:
## Annem Geldi ışık şeridi/parlaması, Elektrik Kesildi karanlığı (gözler + engel konturu),
## belediye ilaçlama arabası ve sis duvarı ok uyarıları. Sis duvarları ObstacleLayer'a eklenir.

const ARROW_X_INSET: float = 56.0
const TRUCK_SIZE: Vector2 = Vector2(176.0, 72.0)

var world: GameWorld = null
var _next_event: int = 0
var _active: Dictionary = {}
var _annem_stage: int = 0
var _bot_hide: Dictionary = {} # bot pid -> küçüldü mü (görsel)
var _next_wall: int = 0
var _walls: Array[FogWall] = []
var _arrows: Array[float] = [] # delik merkezi y
var _elec_alpha: float = 0.0
var _elec_target: float = 0.0
var _flash_alpha: float = 0.0
var _strip_alpha: float = 0.0
var _strip_grow: float = 0.0
var _truck_t: float = -1.0
var _guest_on: bool = false
var _time: float = 0.0
var _drew_last: bool = false


## Yeni koşu başında tüm olay durumunu sıfırlar.
func reset() -> void:
	_next_event = 0
	_active = {}
	_annem_stage = 0
	_bot_hide.clear()
	_next_wall = 0
	for w: FogWall in _walls:
		if is_instance_valid(w):
			w.queue_free()
	_walls.clear()
	_arrows.clear()
	_elec_alpha = 0.0
	_elec_target = 0.0
	_flash_alpha = 0.0
	_strip_alpha = 0.0
	_strip_grow = 0.0
	_truck_t = -1.0
	_guest_on = false
	queue_redraw()


func is_guest_active() -> bool:
	return _guest_on


func is_blackout() -> bool:
	return _elec_alpha > 0.05


func active_event_id() -> String:
	return str(_active.get("id", ""))


## Her kare GameWorld'den çağrılır (maç sürerken).
func process_events(match_time: float, current_dist: float, delta: float) -> void:
	_time += delta
	_update_walls(match_time, current_dist, delta)
	var evs: Array[Dictionary] = world.timeline.events
	while _next_event < evs.size():
		var ev: Dictionary = evs[_next_event]
		if match_time < float(ev["start_time"]):
			break
		_next_event += 1
		if match_time >= float(ev["end_time"]):
			continue
		if not _active.is_empty():
			_end_active()
		_start_event(ev)
	if not _active.is_empty():
		_tick_active(match_time)
		if not _active.is_empty() and match_time >= float(_active["end_time"]):
			_end_active()

	_elec_alpha = move_toward(_elec_alpha, _elec_target, delta * GameConfig.EVENT_ELEC_DARK_ALPHA / GameConfig.EVENT_ELEC_FADE_SEC)
	_flash_alpha = maxf(_flash_alpha - delta * GameConfig.EVENT_ANNEM_FLASH_ALPHA / GameConfig.EVENT_ANNEM_LIGHT_SEC, 0.0)
	if _annem_stage == 0 and active_event_id() == "annem":
		_strip_grow = minf(_strip_grow + delta / GameConfig.EVENT_ANNEM_WARN_SEC, 1.0)
	elif _strip_alpha > 0.0:
		_strip_alpha = maxf(_strip_alpha - delta * 2.0, 0.0)
	if _truck_t >= 0.0:
		_truck_t += delta
		if _truck_t > GameConfig.EVENT_TRUCK_SEC:
			_truck_t = -1.0
	var visible_now: bool = _elec_alpha > 0.0 or _flash_alpha > 0.0 or _strip_alpha > 0.0 or _truck_t >= 0.0 or not _arrows.is_empty()
	if visible_now or _drew_last:
		queue_redraw()
	_drew_last = visible_now


# ---------------------------------------------------------------------------
# Olay başlangıcı / akışı / bitişi
# ---------------------------------------------------------------------------

func _start_event(ev: Dictionary) -> void:
	_active = ev
	var eid: String = str(ev["id"])
	var def: Dictionary = GameConfig.get_event_def(eid)
	# İlk görülüşte tanıtım şeridi (cihaz başına bir kez)
	var seen_key: String = "event_" + eid
	if not AudioManager.has_seen_tip(seen_key):
		AudioManager.mark_tip_seen(seen_key)
		world.hud.show_event_banner(str(def["name"]).to_upper(), str(def["intro"]), 3.2)
	else:
		world.hud.show_event_banner(str(def["name"]).to_upper(), "", 1.6)
	AudioManager.play_sfx(str(GameConfig.EVENT_SFX.get(eid, "")))
	var lp: Area2D = world.local_player
	match eid:
		"annem":
			_annem_stage = 0
			_strip_alpha = 1.0
			_strip_grow = 0.0
			world.hud.show_phase_banner("ANAHTAR SESİ! KÜÇÜL!")
			if lp != null and is_instance_valid(lp) and lp.state == lp.State.ACTIVE:
				lp.refresh_ability2_cooldown()
				world.hud.flash_ability2()
			_plan_bot_hiding(ev)
		"elektrik":
			_elec_target = GameConfig.EVENT_ELEC_DARK_ALPHA
		"misafir":
			_set_guest(true)
		"belediye":
			_truck_t = 0.0


func _tick_active(match_time: float) -> void:
	if active_event_id() != "annem":
		return
	var lt: float = match_time - float(_active["start_time"])
	if _annem_stage == 0 and lt >= GameConfig.EVENT_ANNEM_WARN_SEC:
		_annem_stage = 1
		_annem_light()
	elif _annem_stage == 1 and lt >= GameConfig.EVENT_ANNEM_WARN_SEC + GameConfig.EVENT_ANNEM_LIGHT_SEC:
		_annem_stage = 2
		world._tween_dark_modulate(Color.WHITE)


## Işık yandı: küçülmemiş (ve kalkan/hayalet fazında olmayan) böcek 1 sn donar; diğerleri sıvışır.
func _annem_light() -> void:
	_flash_alpha = GameConfig.EVENT_ANNEM_FLASH_ALPHA
	world._tween_dark_modulate(GameConfig.EVENT_ANNEM_WARM_TINT)
	var lp: Area2D = world.local_player
	if lp != null and is_instance_valid(lp) and lp.state == lp.State.ACTIVE:
		if lp.is_hidden_from_light():
			world.combo_count += 1
			lp.show_combo_title("Sıvıştın!")
			Monetization.quest_event("annem_escape")
		else:
			lp.apply_caught(GameConfig.EVENT_ANNEM_CAUGHT_SEC)
	# Botlar: yalnızca görsel (ölüm anı değişmez)
	for pid_v: Variant in _bot_hide.keys():
		var pid: int = int(pid_v)
		if not world.players_by_id.has(pid):
			continue
		var p: Area2D = world.players_by_id[pid] as Area2D
		if is_instance_valid(p) and p.state == p.State.ACTIVE:
			p.speech_bubble.show_text("Sıvıştın!" if bool(_bot_hide[pid]) else "Yakalandım!", 1.4)


## Botların küçülüp küçülmeyeceği seed'den (her cihazda aynı görünür).
func _plan_bot_hiding(ev: Dictionary) -> void:
	_bot_hide.clear()
	for pid_v: Variant in world._bot_plans.keys():
		var pid: int = int(pid_v)
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = world.timeline.seed_value ^ (absi(pid) * BotPlanner.SEED_MUL) ^ (int(ev["index"]) * 104729 + 17)
		var hide: bool = rng.randf() < GameConfig.EVENT_ANNEM_BOT_SHRINK_CHANCE
		_bot_hide[pid] = hide
		if hide and world.players_by_id.has(pid):
			var p: Area2D = world.players_by_id[pid] as Area2D
			if is_instance_valid(p):
				p.bot_visual_ability(2)


func _end_active() -> void:
	var eid: String = active_event_id()
	match eid:
		"annem":
			if _annem_stage < 2:
				world._tween_dark_modulate(Color.WHITE)
			_annem_stage = 2
		"elektrik":
			_elec_target = 0.0
			world.hud.show_phase_banner("Elektrik geldi!")
			AudioManager.play_sfx(str(GameConfig.EVENT_SFX["elektrik_end"]))
		"misafir":
			_set_guest(false)
		"belediye":
			_belediye_survivors()
	_active = {}


## Belediye bitti: hayatta kalanlara +40 Kırıntı (yerel) ve olay akışında satır.
func _belediye_survivors() -> void:
	var lp: Area2D = world.local_player
	if lp != null and is_instance_valid(lp) and lp.state == lp.State.ACTIVE:
		Monetization.add_kirinti(GameConfig.EVENT_FOG_REWARD)
		world.hud.show_event_banner("BELEDİYEYİ ATLATTIN!", "+%d Kırıntı" % GameConfig.EVENT_FOG_REWARD, 1.8, GameConfig.COLOR_SAGE)
	for pid_v: Variant in world.players_by_id.keys():
		var pid: int = int(pid_v)
		var p: Area2D = world.players_by_id[pid] as Area2D
		if not is_instance_valid(p) or p.state != p.State.ACTIVE:
			continue
		var pname: String = NetworkManager.local_player_name if not NetworkManager.is_multiplayer_match else str(NetworkManager.players.get(pid, {}).get("name", "Böcek"))
		world.hud.push_event_feed("%s belediyeyi atlattı!" % pname)


func _set_guest(on: bool) -> void:
	_guest_on = on
	for obs: Node2D in world.active_slippers:
		if is_instance_valid(obs):
			obs.set_guest(on)


# ---------------------------------------------------------------------------
# Sis duvarları (Belediye İlaçlıyor)
# ---------------------------------------------------------------------------

func _update_walls(match_time: float, current_dist: float, delta: float) -> void:
	var fw: Array[Dictionary] = world.timeline.fog_walls
	if fw.is_empty():
		return
	var vis_right: float = get_viewport().get_visible_rect().end.x
	while _next_wall < fw.size():
		var w: Dictionary = fw[_next_wall]
		var sx: float = GameConfig.PLAYER_X + (float(w["distance"]) - current_dist)
		if sx > vis_right + GameConfig.SPAWN_AHEAD_PX:
			break
		var node: FogWall = FogWall.new()
		node.name = "FogWall%d" % int(w["index"])
		world.obstacle_layer.add_child(node)
		node.setup(w)
		node.position.x = sx
		_walls.append(node)
		_next_wall += 1
	var kept: Array[FogWall] = []
	for node: FogWall in _walls:
		if not is_instance_valid(node):
			continue
		node.position.x = GameConfig.PLAYER_X + (node.world_distance - current_dist)
		node.update_motion(delta)
		if node.position.x < -GameConfig.DESPAWN_BEHIND_PX:
			node.queue_free()
		else:
			kept.append(node)
	_walls = kept
	# Ok uyarısı: duvar ekrana girmeden EVENT_FOG_WARN_SEC önce, delik hizasında yanıp söner
	_arrows.clear()
	var spd: float = maxf(world.timeline.speed_at(match_time), 1.0)
	for w: Dictionary in fw:
		var left_edge: float = GameConfig.PLAYER_X + (float(w["distance"]) - current_dist) - GameConfig.EVENT_FOG_WALL_W * 0.5
		if left_edge <= vis_right:
			continue
		var t_enter: float = (left_edge - vis_right) / spd
		if t_enter <= GameConfig.EVENT_FOG_WARN_SEC:
			_arrows.append(float(w["hole_y"]))


# ---------------------------------------------------------------------------
# Çizim
# ---------------------------------------------------------------------------

func _draw() -> void:
	var vr: Rect2 = get_viewport().get_visible_rect()
	var full: Rect2 = Rect2(vr.position - Vector2(60.0, 60.0), vr.size + Vector2(120.0, 120.0))
	if _elec_alpha > 0.0:
		_draw_blackout(full)
	if _strip_alpha > 0.0:
		var w: float = GameConfig.EVENT_ANNEM_STRIP_W * (0.25 + 0.75 * _strip_grow)
		var c0: Color = GameConfig.EVENT_ANNEM_STRIP_COLOR
		c0.a *= _strip_alpha
		var c1: Color = Color(c0, 0.0)
		var x0: float = vr.position.x
		draw_polygon(
			PackedVector2Array([Vector2(x0, full.position.y), Vector2(x0 + w, full.position.y), Vector2(x0 + w, full.end.y), Vector2(x0, full.end.y)]),
			PackedColorArray([c0, c1, c1, c0])
		)
	if _flash_alpha > 0.0:
		draw_rect(full, Color(1.0, 0.98, 0.92, _flash_alpha), true)
	if _truck_t >= 0.0:
		_draw_truck(vr)
	for hy: float in _arrows:
		_draw_arrow(Vector2(vr.end.x - ARROW_X_INSET, hy))


func _draw_blackout(full: Rect2) -> void:
	draw_rect(full, Color(0.01, 0.01, 0.03, _elec_alpha), true)
	var k: float = clampf(_elec_alpha / GameConfig.EVENT_ELEC_DARK_ALPHA, 0.0, 1.0)
	var cc: Color = GameConfig.EVENT_ELEC_CONTOUR_COLOR
	cc.a *= k
	for obs: Node2D in world.active_slippers:
		if is_instance_valid(obs):
			for r: Rect2 in obs.contour_rects():
				draw_rect(r, cc, false, 3.0)
	for node: FogWall in _walls:
		if is_instance_valid(node):
			for r: Rect2 in node.contour_rects():
				draw_rect(r, cc, false, 3.0)
	# Yalnızca böceklerin gözleri parlar
	var eye: Color = GameConfig.EVENT_ELEC_EYE_COLOR
	for p_v: Variant in world.players_by_id.values():
		var p: Area2D = p_v as Area2D
		if not is_instance_valid(p) or not p.visible or p.state == p.State.DEAD:
			continue
		var a: float = k * (1.0 if p.is_local_player else 0.75)
		for e: Vector2 in p.eye_positions():
			draw_circle(e, 13.0, Color(eye, 0.18 * a))
			draw_circle(e, 7.0, Color(eye, 0.45 * a))
			draw_circle(e, 3.5, Color(1.0, 1.0, 1.0, a))


## Pastel ilaçlama kamyoneti (tezgâh şeridi boyunca soldan sağa), üstünde dönen ışık, arkasında sis.
func _draw_truck(vr: Rect2) -> void:
	var r: float = _truck_t / GameConfig.EVENT_TRUCK_SEC
	var x: float = lerpf(vr.position.x - TRUCK_SIZE.x - 40.0, vr.end.x + 40.0, r)
	var base_y: float = GameConfig.FLOOR_Y + GameConfig.COUNTER_STRIP_HEIGHT * 0.5 + 6.0
	var body: Rect2 = Rect2(Vector2(x, base_y - TRUCK_SIZE.y), Vector2(TRUCK_SIZE.x * 0.72, TRUCK_SIZE.y))
	var cab: Rect2 = Rect2(Vector2(body.end.x - 4.0, base_y - TRUCK_SIZE.y * 0.78), Vector2(TRUCK_SIZE.x * 0.3, TRUCK_SIZE.y * 0.78))
	var ink: Color = GameConfig.COLOR_INK
	# Arkasında sis bulutları
	for i: int in range(4):
		var px: float = x - 18.0 - float(i) * 26.0
		var py: float = base_y - 30.0 - sin(_time * 4.0 + float(i)) * 6.0
		draw_circle(Vector2(px, py), 18.0 - float(i) * 2.5, Color(GameConfig.EVENT_FOG_COLOR, 0.55 - float(i) * 0.1))
	draw_rect(body, GameConfig.COLOR_SAGE, true)
	draw_rect(body, ink, false, 3.0)
	draw_rect(cab, GameConfig.COLOR_PEACH, true)
	draw_rect(cab, ink, false, 3.0)
	draw_rect(Rect2(cab.position + Vector2(10.0, 8.0), Vector2(cab.size.x - 20.0, 22.0)), GameConfig.COLOR_DUST_BLUE, true)
	draw_rect(Rect2(cab.position + Vector2(10.0, 8.0), Vector2(cab.size.x - 20.0, 22.0)), ink, false, 2.0)
	var font: Font = AssetHelper.get_title_font()
	draw_string(font, body.position + Vector2(10.0, body.size.y * 0.62), "İLAÇLAMA", HORIZONTAL_ALIGNMENT_LEFT, body.size.x - 16.0, GameConfig.FS_TINY, ink)
	for wx: float in [body.position.x + 26.0, cab.end.x - 22.0]:
		draw_circle(Vector2(wx, base_y + 2.0), 14.0, ink)
		draw_circle(Vector2(wx, base_y + 2.0), 6.0, GameConfig.COLOR_CREAM)
	# Dönen ışık
	var lamp: Vector2 = Vector2(body.position.x + body.size.x * 0.5, body.position.y - 8.0)
	var red_on: bool = fmod(_time * 6.0, 2.0) < 1.0
	var lamp_col: Color = GameConfig.COLOR_WARN_RED if red_on else GameConfig.COLOR_DUST_BLUE
	var ang: float = _time * 9.0
	for k: int in range(2):
		var dir: Vector2 = Vector2(cos(ang + PI * float(k)), sin(ang + PI * float(k)) * 0.35)
		draw_line(lamp, lamp + dir * 46.0, Color(lamp_col, 0.45), 10.0, true)
	draw_rect(Rect2(lamp - Vector2(10.0, 8.0), Vector2(20.0, 12.0)), lamp_col, true)
	draw_rect(Rect2(lamp - Vector2(10.0, 8.0), Vector2(20.0, 12.0)), ink, false, 2.0)


## Deliğin hizasında yanıp sönen sola dönük ok ve delik kenar işaretleri.
func _draw_arrow(c: Vector2) -> void:
	var on: bool = fmod(_time * 7.0, 2.0) < 1.25
	if not on:
		return
	var col: Color = GameConfig.COLOR_GOLD
	var ink: Color = GameConfig.COLOR_INK
	var pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(-34.0, 0.0), c + Vector2(4.0, -30.0), c + Vector2(4.0, -12.0),
		c + Vector2(34.0, -12.0), c + Vector2(34.0, 12.0), c + Vector2(4.0, 12.0), c + Vector2(4.0, 30.0),
	])
	draw_colored_polygon(pts, col)
	var loop: PackedVector2Array = pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, ink, 4.0, true)
	var half: float = GameConfig.EVENT_FOG_HOLE * 0.5
	for sy: float in [-half, half]:
		draw_line(c + Vector2(-20.0, sy), c + Vector2(34.0, sy), Color(col, 0.9), 6.0, true)

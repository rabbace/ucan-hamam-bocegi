class_name ObstacleTimeline
extends RefCounted

## Seed tabanlı deterministik engel, karanlık evre, füze, ani olay ve sis duvarı zaman çizelgesi üreticisi.

## Yalnızca hata ayıklama: bu olay EVENT_DEBUG_START_SEC'te zorla başlar (boşsa normal akış).
static var debug_force_event: String = ""

var seed_value: int = 1
var is_multiplayer: bool = false
## Zorluk kimliği (GameConfig.DIFFICULTIES); generate() öncesi atanır
var difficulty: String = GameConfig.DIFFICULTY_NORMAL
var slippers: Array[Dictionary] = []
var dark_phases: Array[Dictionary] = []
var missiles: Array[Dictionary] = []
var powerups: Array[Dictionary] = []
var surprise_intros: Array[Dictionary] = []
## Faz 11.6: ani olaylar {index, id, start_time, end_time, level, start_dist, end_dist}
var events: Array[Dictionary] = []
## Belediye sis duvarları {index, event_start, distance, hit_time, hole_y, hole_size, level}
var fog_walls: Array[Dictionary] = []

var _fog_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _boss_levels_done: Dictionary = {}

var _speed_profile: PackedFloat32Array = PackedFloat32Array()
var _distance_profile: PackedFloat32Array = PackedFloat32Array()


## Verilen seed ile 15 dakikalık hız profilini, terlik, karanlık evre, füze ve güçlendirme listesini üretir.
func generate(world_seed: int, p_is_multiplayer: bool = false) -> void:
	seed_value = world_seed
	is_multiplayer = p_is_multiplayer
	slippers.clear()
	dark_phases.clear()
	missiles.clear()
	powerups.clear()
	surprise_intros.clear()
	events.clear()
	fog_walls.clear()
	_boss_levels_done.clear()

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	# Olay ve insan tipi akışları ayrı rng kullanır (engel dizisini bozmasın)
	_fog_rng.seed = seed_value ^ GameConfig.EVENT_FOG_SEED_XOR

	_build_speed_profile()
	_generate_dark_phases_and_missiles(rng)
	if debug_force_event == "belediye":
		_schedule_boss(GameConfig.EVENT_DEBUG_START_SEC, 1, (GameConfig.GAP_MIN_Y + GameConfig.GAP_MAX_Y) * 0.5)
	_generate_slippers(rng)
	_generate_regular_events()
	_apply_event_effects_to_slippers()
	_assign_people()
	_generate_powerups(rng)


## 0.05 sn adımlarla 15 dakikalık deterministik hız ve mesafe profilini oluşturur.
func _build_speed_profile() -> void:
	var step: float = GameConfig.SPEED_PROFILE_STEP
	var total_steps: int = int(GameConfig.TIMELINE_DURATION_SEC / step) + 2
	_speed_profile.resize(total_steps)
	_distance_profile.resize(total_steps)

	var dist: float = 0.0
	var cur_level: int = 1
	var cur_speed: float = float(GameConfig.get_level_config_for(1, difficulty)["speed"])
	var ramp_from: float = cur_speed
	var ramp_to: float = cur_speed
	var ramp_elapsed: float = GameConfig.SPEED_TRANSITION_SEC

	for i: int in range(total_steps):
		var passed_pairs: int = 0
		if dist >= GameConfig.FIRST_OBSTACLE_DIST:
			passed_pairs = int((dist - GameConfig.FIRST_OBSTACLE_DIST) / GameConfig.OBSTACLE_SPACING) + 1
		var target_level: int = GameConfig.level_for_passed_pairs(passed_pairs)
		if target_level > cur_level:
			cur_level = target_level
			ramp_from = cur_speed
			ramp_to = float(GameConfig.get_level_config_for(cur_level, difficulty)["speed"])
			ramp_elapsed = 0.0

		if ramp_elapsed < GameConfig.SPEED_TRANSITION_SEC:
			ramp_elapsed = minf(ramp_elapsed + step, GameConfig.SPEED_TRANSITION_SEC)
			var ratio: float = ramp_elapsed / GameConfig.SPEED_TRANSITION_SEC
			cur_speed = lerpf(ramp_from, ramp_to, ratio)
		else:
			cur_speed = ramp_to

		_speed_profile[i] = cur_speed
		_distance_profile[i] = dist
		dist += cur_speed * step


## t anındaki toplam dünya mesafesini hız profilinden doğrusal enterpolasyonla döner.
func distance_at(t: float) -> float:
	if t <= 0.0 or _distance_profile.is_empty():
		return 0.0
	var f_idx: float = t / GameConfig.SPEED_PROFILE_STEP
	var idx: int = int(f_idx)
	if idx >= _distance_profile.size() - 1:
		var last_idx: int = _distance_profile.size() - 1
		var extra_t: float = t - float(last_idx) * GameConfig.SPEED_PROFILE_STEP
		return _distance_profile[last_idx] + _speed_profile[last_idx] * extra_t
	var frac: float = f_idx - float(idx)
	return lerpf(_distance_profile[idx], _distance_profile[idx + 1], frac)


## t anındaki kaydırma hızını (px/s) hız profilinden döner.
func speed_at(t: float) -> float:
	if t <= 0.0 or _speed_profile.is_empty():
		return float(GameConfig.get_level_config_for(1, difficulty)["speed"])
	var f_idx: float = t / GameConfig.SPEED_PROFILE_STEP
	var idx: int = int(f_idx)
	if idx >= _speed_profile.size() - 1:
		return _speed_profile[_speed_profile.size() - 1]
	var frac: float = f_idx - float(idx)
	return lerpf(_speed_profile[idx], _speed_profile[idx + 1], frac)


func _level_at_distance(dist: float) -> int:
	if dist < GameConfig.FIRST_OBSTACLE_DIST:
		return 1
	var passed_pairs: int = int((dist - GameConfig.FIRST_OBSTACLE_DIST) / GameConfig.OBSTACLE_SPACING) + 1
	return GameConfig.level_for_passed_pairs(passed_pairs)


func _generate_dark_phases_and_missiles(rng: RandomNumberGenerator) -> void:
	var phase_start: float = GameConfig.DARK_FIRST_TIME
	var phase_idx: int = 0
	var missile_idx: int = 0

	while phase_start < GameConfig.TIMELINE_DURATION_SEC:
		var lv: int = _level_at_distance(distance_at(phase_start))
		var lv_cfg: Dictionary = GameConfig.get_level_config_for(lv, difficulty)
		var target_count: int = int(lv_cfg["missiles"])

		var phase_end: float = phase_start + GameConfig.DARK_DURATION
		var pad_start: float = maxf(phase_start - GameConfig.DARK_SLIPPER_PAD_SEC, 0.0)
		var pad_end: float = phase_end + GameConfig.DARK_SLIPPER_PAD_SEC

		dark_phases.append({
			"index": phase_idx,
			"start_time": phase_start,
			"end_time": phase_end,
			"no_slipper_start_dist": distance_at(pad_start) if target_count > 0 else -1.0,
			"no_slipper_end_dist": distance_at(pad_end) if target_count > 0 else -1.0,
		})

		var launch_t: float = phase_start + 0.35
		for m: int in range(target_count):
			if launch_t > phase_end - 0.2:
				break
			var start_x: float = rng.randf_range(GameConfig.MISSILE_SPAWN_X_MIN, GameConfig.MISSILE_SPAWN_X_MAX)
			var angle_deg: float = rng.randf_range(GameConfig.MISSILE_ANGLE_MIN_DEG, GameConfig.MISSILE_ANGLE_MAX_DEG)
			var angle_rad: float = deg_to_rad(angle_deg)
			var dir: Vector2 = Vector2(-cos(angle_rad), sin(angle_rad)).normalized()

			missiles.append({
				"index": missile_idx,
				"warn_time": launch_t - GameConfig.MISSILE_WARN_LEAD_SEC,
				"launch_time": launch_t,
				"start_pos": Vector2(start_x, GameConfig.MISSILE_SPAWN_Y),
				"dir": dir,
			})
			missile_idx += 1
			launch_t += rng.randf_range(GameConfig.MISSILE_MIN_GAP_SEC, GameConfig.MISSILE_MAX_GAP_SEC)

		phase_start += GameConfig.DARK_INTERVAL
		phase_idx += 1


func _generate_slippers(rng: RandomNumberGenerator) -> void:
	var max_dist: float = distance_at(GameConfig.TIMELINE_DURATION_SEC)
	var dist: float = GameConfig.FIRST_OBSTACLE_DIST
	var prev_y: float = (GameConfig.GAP_MIN_Y + GameConfig.GAP_MAX_Y) * 0.5
	var idx: int = 0
	var normal_since_surprise: int = GameConfig.SURPRISE_MIN_NORMAL_BETWEEN
	var seen_surprises: Dictionary = {}
	var last_dist: float = 0.0

	while dist <= max_dist:
		# Faz 11.6: Seviye 5'e girerken (ve her 3 seviyede) Belediye İlaçlıyor
		var lv_here: int = GameConfig.level_for_passed_pairs(idx)
		if GameConfig.is_boss_level(lv_here) and not _boss_levels_done.has(lv_here):
			_boss_levels_done[lv_here] = true
			var t_lv: float = time_at_distance(last_dist) if idx > 0 else 0.0
			_schedule_boss(t_lv + GameConfig.EVENT_BOSS_DELAY_SEC, lv_here, prev_y)
		if _is_in_dark_gap(dist) or _is_in_fog_gap(dist):
			dist += GameConfig.OBSTACLE_SPACING
			normal_since_surprise = GameConfig.SURPRISE_MIN_NORMAL_BETWEEN
			continue

		var lv: int = GameConfig.level_for_passed_pairs(idx)
		var lv_cfg: Dictionary = GameConfig.get_level_config_for(lv, difficulty)
		var gap_size: float = float(lv_cfg["gap"])
		if idx < GameConfig.WARMUP_PAIR_COUNT:
			gap_size += GameConfig.WARMUP_GAP_BONUS
		if lv > 1 and (idx - int(lv_cfg["start_pairs"])) < GameConfig.LEVEL_BREATH_PAIRS:
			gap_size += GameConfig.LEVEL_BREATH_GAP_BONUS

		var min_y: float = GameConfig.GAP_MIN_Y
		var max_y: float = GameConfig.GAP_MAX_Y
		if idx > 0:
			min_y = maxf(GameConfig.GAP_MIN_Y, prev_y - GameConfig.GAP_MAX_DELTA_Y)
			max_y = minf(GameConfig.GAP_MAX_Y, prev_y + GameConfig.GAP_MAX_DELTA_Y)

		var gap_y: float = rng.randf_range(min_y, max_y)
		var has_spray: bool = false
		var surprise_type: String = ""
		var surprise_chance: float = float(lv_cfg["surprise_chance"])
		var near_missile: bool = _is_near_dark_gap(dist, 2.0 * GameConfig.OBSTACLE_SPACING)
		var pool: Array[String] = _surprise_pool_for_level(lv)

		if not pool.is_empty() and not near_missile and normal_since_surprise >= GameConfig.SURPRISE_MIN_NORMAL_BETWEEN and rng.randf() < surprise_chance:
			var picked: String = pool[rng.randi_range(0, pool.size() - 1)]
			if picked == "sprey":
				has_spray = true
			else:
				surprise_type = picked
				if picked == "sopa":
					gap_size = maxf(gap_size, GameConfig.SOPALI_GAP_MIN)
			normal_since_surprise = 0
			if not seen_surprises.has(picked):
				seen_surprises[picked] = true
				var lv_spd: float = float(lv_cfg["speed"])
				surprise_intros.append({
					"type": picked,
					"trigger_dist": maxf(dist - lv_spd * 1.5, 0.0),
					"text": str(GameConfig.SURPRISE_INTRO_TEXTS.get(picked, "")),
				})
		else:
			normal_since_surprise += 1

		slippers.append({
			"index": idx,
			"level": lv,
			"distance": dist,
			"gap_y": gap_y,
			"gap_size": gap_size,
			"bob_amp": float(lv_cfg["bob_amp"]),
			"has_spray": has_spray,
			"surprise_type": surprise_type,
		})
		prev_y = gap_y
		last_dist = dist
		dist += GameConfig.OBSTACLE_SPACING
		idx += 1


func _surprise_pool_for_level(lv: int) -> Array[String]:
	if lv <= 1:
		return []
	if lv == 2:
		return ["sprey"]
	if lv == 3:
		return ["sprey", "dolap"]
	if lv == 4:
		return ["sprey", "dolap", "firlayan_terlik"]
	return ["sprey", "dolap", "firlayan_terlik", "sopa"]


func _is_near_dark_gap(dist: float, margin: float) -> bool:
	for phase: Dictionary in dark_phases:
		var s: float = float(phase["no_slipper_start_dist"])
		var e: float = float(phase["no_slipper_end_dist"])
		if s >= 0.0 and dist >= s - margin and dist <= e + margin:
			return true
	return false


func _generate_powerups(rng: RandomNumberGenerator) -> void:
	if slippers.is_empty():
		return
	var next_idx: int = rng.randi_range(GameConfig.POWERUP_SPAWN_MIN_STEP, GameConfig.POWERUP_SPAWN_MAX_STEP)
	var box_idx: int = 0
	while next_idx < slippers.size():
		var s: Dictionary = slippers[next_idx]
		var lv: int = int(s["level"])
		var gap_y: float = float(s["gap_y"])
		var gap_size: float = float(s["gap_size"])
		var item_id: String = _pick_weighted_powerup(rng, lv)
		# Faz 10.2: kutuların bir kısmı gizemli (imza) kutusu; yeri ve türü herkeste aynı,
		# içeriği her oyuncunun kendi karakterine göre toplanınca açılır.
		if rng.randf() < GameConfig.SIGNATURE_DROP_RATE:
			item_id = GameConfig.MYSTERY_ITEM_ID
		var box_dist: float = float(s["distance"]) + rng.randf_range(0.0, 140.0)
		var box_y: float = clampf(
			gap_y + rng.randf_range(-gap_size * 0.25, gap_size * 0.25),
			240.0,
			GameConfig.FLOOR_Y - 120.0
		)
		powerups.append({
			"index": box_idx,
			"distance": box_dist,
			"y": box_y,
			"item_id": item_id,
		})
		box_idx += 1
		var step: int = rng.randi_range(GameConfig.POWERUP_SPAWN_MIN_STEP, GameConfig.POWERUP_SPAWN_MAX_STEP)
		# Misafir Var: kutu çıkma ihtimali x1.5 (adım kısalır)
		if bool(s.get("guest", false)):
			step = maxi(1, int(roundf(float(step) / GameConfig.EVENT_GUEST_BOX_MULT)))
		next_idx += step


func _pick_weighted_powerup(rng: RandomNumberGenerator, lv: int) -> String:
	var table: Array[Dictionary] = GameConfig.POWERUP_WEIGHTS_MID
	if is_multiplayer and rng.randf() < 0.42:
		table = GameConfig.TAUNT_WEIGHTS_MULTIPLAYER
	elif lv <= 2:
		table = GameConfig.POWERUP_WEIGHTS_EARLY
	elif lv >= 4:
		table = GameConfig.POWERUP_WEIGHTS_LATE
	var total: int = 0
	for entry: Dictionary in table:
		total += int(entry["weight"])
	var r: int = rng.randi_range(0, maxi(total - 1, 0))
	var acc: int = 0
	for entry: Dictionary in table:
		acc += int(entry["weight"])
		if r < acc:
			return str(entry["id"])
	return "dondurma"


func _is_in_dark_gap(dist: float) -> bool:
	for phase: Dictionary in dark_phases:
		if dist >= float(phase["no_slipper_start_dist"]) and dist <= float(phase["no_slipper_end_dist"]):
			return true
	return false


## Verilen dünya mesafesine ulaşılan maç zamanını (sn) ikili aramayla döner.
func time_at_distance(dist: float) -> float:
	if dist <= 0.0:
		return 0.0
	var lo: float = 0.0
	var hi: float = GameConfig.TIMELINE_DURATION_SEC
	while distance_at(hi) < dist and hi < GameConfig.TIMELINE_DURATION_SEC * 8.0:
		hi *= 2.0
	for _i: int in range(40):
		var mid: float = (lo + hi) * 0.5
		if distance_at(mid) < dist:
			lo = mid
		else:
			hi = mid
	return hi


# ---------------------------------------------------------------------------
# Faz 11.6: ani olaylar (seed'den; herkeste aynı)
# ---------------------------------------------------------------------------

## Belediye İlaçlıyor: sis duvarlarını kurar ve olay kaydını ekler.
func _schedule_boss(t_want: float, lv: int, prev_y: float) -> void:
	var dur: float = GameConfig.belediye_duration_bound()
	var t0: float = _find_free_start(t_want, dur)
	# İlk duvar, olay başladıktan EVENT_FOG_FIRST_SEC sonra sağ kenardan girer
	var travel: float = (GameConfig.VIEWPORT_WIDTH - GameConfig.PLAYER_X) / maxf(speed_at(t0), 1.0)
	if t0 + dur > GameConfig.TIMELINE_DURATION_SEC:
		return
	var hole_y: float = prev_y
	for i: int in range(GameConfig.EVENT_FOG_WALLS):
		var lo: float = maxf(GameConfig.GAP_MIN_Y, hole_y - GameConfig.EVENT_FOG_MAX_DELTA_Y)
		var hi: float = minf(GameConfig.GAP_MAX_Y, hole_y + GameConfig.EVENT_FOG_MAX_DELTA_Y)
		hole_y = _fog_rng.randf_range(lo, hi)
		var hit_t: float = t0 + GameConfig.EVENT_FOG_FIRST_SEC + travel + float(i) * GameConfig.EVENT_FOG_SPACING_SEC
		fog_walls.append({
			"index": fog_walls.size(),
			"event_start": t0,
			"distance": distance_at(hit_t),
			"hit_time": hit_t,
			"hole_y": hole_y,
			"hole_size": GameConfig.EVENT_FOG_HOLE,
			"level": lv,
		})
	_add_event("belediye", t0, dur, lv)


## Olay kaydını ekler (sıralama sonra yapılır).
func _add_event(event_id: String, t0: float, dur: float, lv: int) -> void:
	events.append({
		"index": -1,
		"id": event_id,
		"start_time": t0,
		"end_time": t0 + dur,
		"level": lv,
		"start_dist": distance_at(t0),
		"end_dist": distance_at(t0 + dur),
	})


## t'den itibaren karanlık evrelere ve diğer olaylara çakışmayan en erken başlangıç.
func _find_free_start(t: float, dur: float) -> float:
	var pad: float = GameConfig.EVENT_DARK_PAD_SEC
	var gap: float = GameConfig.EVENT_MIN_GAP_SEC
	var end_gap: float = GameConfig.EVENT_MIN_END_GAP_SEC
	var moved: bool = true
	var guard: int = 0
	while moved and guard < 400:
		guard += 1
		moved = false
		for ph: Dictionary in dark_phases:
			var s0: float = float(ph["start_time"]) - pad
			var e0: float = float(ph["end_time"]) + pad
			if t < e0 and t + dur > s0:
				t = e0
				moved = true
		for ev: Dictionary in events:
			var es: float = float(ev["start_time"])
			var ee: float = float(ev["end_time"])
			# Başlangıçlar arası en az gap; bitişten sonra en az end_gap; çakışma yok
			if absf(t - es) < gap or (t < ee + end_gap and t + dur + end_gap > es):
				t = maxf(es + gap, ee + end_gap)
				moved = true
	return t


## Belediye dışındaki olaylar: seviyeye göre havuzdan ağırlıklı seçilir.
func _generate_regular_events() -> void:
	var erng: RandomNumberGenerator = RandomNumberGenerator.new()
	erng.seed = seed_value ^ GameConfig.EVENT_SEED_XOR
	var forced: String = debug_force_event
	if not forced.is_empty() and forced != "belediye" and GameConfig.EVENTS.has(forced):
		_add_event(forced, GameConfig.EVENT_DEBUG_START_SEC, float(GameConfig.get_event_def(forced)["duration"]), 1)
	var t: float = GameConfig.EVENT_FIRST_MIN_SEC + erng.randf_range(0.0, GameConfig.EVENT_FIRST_JITTER_SEC)
	var guard: int = 0
	while t < GameConfig.TIMELINE_DURATION_SEC and guard < 1000:
		guard += 1
		var lv: int = _level_at_time(t)
		var picked: String = _pick_event(erng, lv)
		if picked.is_empty():
			t += GameConfig.EVENT_RETRY_STEP_SEC
			continue
		var dur: float = float(GameConfig.get_event_def(picked)["duration"])
		var t0: float = _find_free_start(t, dur)
		if t0 + dur > GameConfig.TIMELINE_DURATION_SEC:
			break
		_add_event(picked, t0, dur, _level_at_time(t0))
		t = t0 + GameConfig.EVENT_MIN_GAP_SEC + erng.randf_range(0.0, GameConfig.EVENT_EXTRA_GAP_SEC)
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["start_time"]) < float(b["start_time"]))
	for i: int in range(events.size()):
		events[i]["index"] = i


func _pick_event(erng: RandomNumberGenerator, lv: int) -> String:
	var total: int = 0
	for eid: String in GameConfig.EVENT_ORDER:
		var d: Dictionary = GameConfig.get_event_def(eid)
		if not bool(d.get("boss", false)) and int(d["min_level"]) <= lv:
			total += int(d["weight"])
	if total <= 0:
		return ""
	var r: int = erng.randi_range(0, total - 1)
	for eid: String in GameConfig.EVENT_ORDER:
		var d: Dictionary = GameConfig.get_event_def(eid)
		if bool(d.get("boss", false)) or int(d["min_level"]) > lv:
			continue
		r -= int(d["weight"])
		if r < 0:
			return eid
	return ""


## Oyuncunun t anında geçmiş olduğu engel sayısına göre seviye (oyundaki seviye çubuğuyla aynı).
func _level_at_time(t: float) -> int:
	var d: float = distance_at(t)
	var passed: int = 0
	for s: Dictionary in slippers:
		if float(s["distance"]) >= d:
			break
		passed += 1
	return GameConfig.level_for_passed_pairs(passed)


## Elektrik Kesildi: o sırada gelen engellerin aralığı +40; Misafir Var: engeller misafir kılığında.
func _apply_event_effects_to_slippers() -> void:
	for ev: Dictionary in events:
		var eid: String = str(ev["id"])
		if eid != "elektrik" and eid != "misafir":
			continue
		var d0: float = float(ev["start_dist"])
		var d1: float = float(ev["end_dist"])
		for s: Dictionary in slippers:
			var sd: float = float(s["distance"])
			if sd < d0 or sd > d1:
				continue
			if eid == "elektrik":
				s["gap_size"] = float(s["gap_size"]) + GameConfig.EVENT_ELEC_GAP_BONUS
				s["elec"] = true
			else:
				s["guest"] = true


## Faz 11.5: her engel çiftinin üst ve alt insan tipi (seviyeye göre havuzdan, seed'li).
func _assign_people() -> void:
	var prng: RandomNumberGenerator = RandomNumberGenerator.new()
	prng.seed = seed_value ^ GameConfig.PEOPLE_SEED_XOR
	for s: Dictionary in slippers:
		var pool: Array[String] = GameConfig.people_pool_for_level(int(s["level"]))
		var n: int = pool.size()
		var a: int = prng.randi_range(0, n - 1)
		var b: int = prng.randi_range(0, n - 1)
		if b == a and n > 1:
			b = (b + 1) % n
		s["top_type"] = pool[a]
		s["bottom_type"] = pool[b]


func _is_in_fog_gap(dist: float) -> bool:
	if fog_walls.is_empty():
		return false
	var by_event: Dictionary = {}
	for w: Dictionary in fog_walls:
		var key: float = float(w["event_start"])
		var cur: Vector2 = by_event.get(key, Vector2(INF, -INF)) as Vector2
		var wd: float = float(w["distance"])
		by_event[key] = Vector2(minf(cur.x, wd), maxf(cur.y, wd))
	for v: Variant in by_event.values():
		var r: Vector2 = v as Vector2
		if dist >= r.x - GameConfig.EVENT_FOG_CLEAR_BEFORE_PX and dist <= r.y + GameConfig.EVENT_FOG_CLEAR_AFTER_PX:
			return true
	return false


## t anında süren olay (yoksa boş sözlük).
func event_at_time(t: float) -> Dictionary:
	for ev: Dictionary in events:
		if t >= float(ev["start_time"]) and t < float(ev["end_time"]):
			return ev
		if float(ev["start_time"]) > t:
			break
	return {}


## Verilen dünya mesafesinde süren olay kimliği (mesafe aralığına göre; yoksa boş).
func event_id_at_distance(dist: float) -> String:
	for ev: Dictionary in events:
		if dist >= float(ev["start_dist"]) and dist <= float(ev["end_dist"]):
			return str(ev["id"])
	return ""

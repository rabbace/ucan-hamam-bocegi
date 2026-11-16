class_name ObstacleTimeline
extends RefCounted

## Seed tabanlı deterministik engel, karanlık evre ve füze zaman çizelgesi üreticisi.

var seed_value: int = 1
var is_multiplayer: bool = false
var slippers: Array[Dictionary] = []
var dark_phases: Array[Dictionary] = []
var missiles: Array[Dictionary] = []
var powerups: Array[Dictionary] = []
var surprise_intros: Array[Dictionary] = []

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

	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value

	_build_speed_profile()
	_generate_dark_phases_and_missiles(rng)
	_generate_slippers(rng)
	_generate_powerups(rng)


## 0.05 sn adımlarla 15 dakikalık deterministik hız ve mesafe profilini oluşturur.
func _build_speed_profile() -> void:
	var step: float = GameConfig.SPEED_PROFILE_STEP
	var total_steps: int = int(GameConfig.TIMELINE_DURATION_SEC / step) + 2
	_speed_profile.resize(total_steps)
	_distance_profile.resize(total_steps)

	var dist: float = 0.0
	var cur_level: int = 1
	var cur_speed: float = float(GameConfig.get_level_config(1)["speed"])
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
			ramp_to = float(GameConfig.get_level_config(cur_level)["speed"])
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
		return float(GameConfig.get_level_config(1)["speed"])
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
		var lv_cfg: Dictionary = GameConfig.get_level_config(lv)
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

	while dist <= max_dist:
		if _is_in_dark_gap(dist):
			dist += GameConfig.OBSTACLE_SPACING
			normal_since_surprise = GameConfig.SURPRISE_MIN_NORMAL_BETWEEN
			continue

		var lv: int = GameConfig.level_for_passed_pairs(idx)
		var lv_cfg: Dictionary = GameConfig.get_level_config(lv)
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
		next_idx += rng.randi_range(GameConfig.POWERUP_SPAWN_MIN_STEP, GameConfig.POWERUP_SPAWN_MAX_STEP)


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

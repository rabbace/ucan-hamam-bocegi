class_name BotPlanner
extends RefCounted

## Faz 11.1: Deterministik bot planı. Her cihaz aynı seed'den aynı sonucu hesaplar:
## ölüm engeli ve zamanı, görsel uçuş yolu, laf atma / görsel yetenek zamanları ve (sunucuda) sataşma zamanları.
## Botlar ağdan pozisyon göndermez; çarpışma yoktur, yol yalnızca görseldir.

const SEED_MUL: int = 7919
const STREAM_PATH: int = 101
const STREAM_EVENTS: int = 202
const STREAM_TAUNT: int = 303

var bot_index: int = 1
var skill: String = GameConfig.BOT_DEFAULT_SKILL
var death_pair: int = -1
var death_time: float = 0.0
var death_dist: float = 0.0
var death_cause: String = "ust_engel"
## Görsel olaylar: {time, kind ("chat"|"ability"|"sig"), value}
var events: Array[Dictionary] = []
## Yalnızca otorite kullanır: sataşma zamanları ve eşyaları
var taunt_times: PackedFloat32Array = PackedFloat32Array()
var taunt_items: PackedStringArray = PackedStringArray()

var _timeline: ObstacleTimeline = null
var _dists: PackedFloat32Array = PackedFloat32Array()
var _ys: PackedFloat32Array = PackedFloat32Array()
var _flap_phase: float = 0.0


## Planı üretir. max_death_level > 0 ise bot en geç o seviyenin sonunda ölür.
func setup(timeline: ObstacleTimeline, world_seed: int, p_bot_index: int, p_skill: String, max_death_level: int) -> void:
	_timeline = timeline
	bot_index = p_bot_index
	skill = p_skill if GameConfig.BOT_SKILLS.has(p_skill) else GameConfig.BOT_DEFAULT_SKILL
	var base_seed: int = world_seed ^ (bot_index * SEED_MUL)

	# 1) Ölüm engeli: her çiftte fail_chance olasılığıyla başarısız olur
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = base_seed
	var slips: Array[Dictionary] = timeline.slippers
	death_pair = -1
	for i: int in range(slips.size()):
		var lv: int = int(slips[i]["level"])
		if max_death_level > 0 and lv > max_death_level:
			death_pair = maxi(i - 1, 0)
			break
		if rng.randf() < GameConfig.bot_fail_chance(lv, skill):
			death_pair = i
			break
	if death_pair < 0:
		death_pair = maxi(slips.size() - 1, 0)
	var hits_top: bool = rng.randf() < 0.5
	death_cause = "ust_engel" if hits_top else "alt_engel"

	# 2) Görsel yol noktaları (her çiftte aralık içinde seed'li sapma)
	var prng: RandomNumberGenerator = RandomNumberGenerator.new()
	prng.seed = base_seed + STREAM_PATH
	_flap_phase = prng.randf()
	_dists.resize(0)
	_ys.resize(0)
	var last: int = mini(death_pair, slips.size() - 1)
	for i: int in range(last + 1):
		var s: Dictionary = slips[i]
		var gap_y: float = float(s["gap_y"])
		var gap: float = float(s["gap_size"])
		var bob: float = float(s.get("bob_amp", 0.0))
		var y: float
		if i == death_pair:
			y = gap_y - gap * 0.5 - 40.0 if hits_top else gap_y + gap * 0.5 + 40.0
		else:
			var half_span: float = maxf((gap - bob) * 0.5 - GameConfig.BOT_GAP_MARGIN_PX, 0.0)
			var off: float = prng.randf_range(-GameConfig.BOT_GAP_OFFSET_MAX, GameConfig.BOT_GAP_OFFSET_MAX)
			y = gap_y + bob * 0.5 + off * half_span
		_dists.append(float(s["distance"]))
		_ys.append(clampf(y, GameConfig.CEILING_Y + 20.0, GameConfig.FLOOR_Y - 20.0))

	if slips.is_empty():
		death_dist = GameConfig.FIRST_OBSTACLE_DIST
	else:
		death_dist = float(slips[death_pair]["distance"]) - GameConfig.BOT_HIT_LEAD_PX
	death_time = timeline.time_at_distance(death_dist)

	# 3) Laf atma, görsel yetenek ve imza balonları (ölüm anına kadar)
	var erng: RandomNumberGenerator = RandomNumberGenerator.new()
	erng.seed = base_seed + STREAM_EVENTS
	events.clear()
	var t_chat: float = erng.randf_range(GameConfig.BOT_CHAT_MIN_SEC * 0.5, GameConfig.BOT_CHAT_MAX_SEC)
	var t_abil: float = erng.randf_range(GameConfig.BOT_ABILITY_MIN_SEC * 0.5, GameConfig.BOT_ABILITY_MAX_SEC)
	while t_chat < death_time or t_abil < death_time:
		if t_chat <= t_abil:
			events.append({"time": t_chat, "kind": "chat", "value": erng.randi_range(0, GameConfig.QUICK_CHAT_LINES.size())})
			t_chat += erng.randf_range(GameConfig.BOT_CHAT_MIN_SEC, GameConfig.BOT_CHAT_MAX_SEC)
		else:
			var r: float = erng.randf()
			var kind: String = "sig" if r < 0.2 else "ability"
			events.append({"time": t_abil, "kind": kind, "value": 1 if r < 0.6 else 2})
			t_abil += erng.randf_range(GameConfig.BOT_ABILITY_MIN_SEC, GameConfig.BOT_ABILITY_MAX_SEC)
	var kept: Array[Dictionary] = []
	for e: Dictionary in events:
		if float(e["time"]) < death_time:
			kept.append(e)
	events = kept

	# 4) Sataşma zamanları (otorite kullanır; bot başına en fazla 20 sn'de bir)
	var trng: RandomNumberGenerator = RandomNumberGenerator.new()
	trng.seed = base_seed + STREAM_TAUNT
	taunt_times.resize(0)
	taunt_items.resize(0)
	var t_taunt: float = trng.randf_range(GameConfig.BOT_TAUNT_FIRST_MIN_SEC, GameConfig.BOT_TAUNT_FIRST_MAX_SEC)
	while t_taunt < death_time:
		taunt_times.append(t_taunt)
		taunt_items.append(GameConfig.BOT_TAUNT_ITEMS[trng.randi_range(0, GameConfig.BOT_TAUNT_ITEMS.size() - 1)])
		t_taunt += GameConfig.BOT_TAUNT_MIN_GAP_SEC + trng.randf_range(0.0, GameConfig.BOT_TAUNT_EXTRA_MAX_SEC)


## Ölüm engelinin seviyesi (test ve ayarlama için).
func death_level() -> int:
	if _timeline == null or _timeline.slippers.is_empty():
		return 1
	return int(_timeline.slippers[death_pair]["level"])


## Verilen maç zamanında botun görsel Y konumu.
func y_at(t: float) -> float:
	if _timeline == null:
		return GameConfig.PLAYER_START_Y
	var d: float = _timeline.distance_at(t)
	var base_y: float = _base_y_at_dist(d)
	# Kanat çırpma hissi: kısa parabolik sıçramalar
	var f: float = fposmod(t * GameConfig.BOT_FLAP_HZ + _flap_phase, 1.0)
	var hop: float = (4.0 * f * (1.0 - f) - 0.5) * GameConfig.BOT_FLAP_AMP_PX * 2.0
	if d >= death_dist - GameConfig.BOT_PATH_HOLD_PX:
		hop *= 0.3
	return base_y - hop


## Görsel eğim: yolun yerel türevinden (radyan).
func rotation_at(t: float) -> float:
	var dy: float = y_at(t + 0.05) - y_at(t)
	return clampf(dy * 0.02, -0.45, 0.6)


func _base_y_at_dist(d: float) -> float:
	var n: int = _dists.size()
	if n == 0:
		return GameConfig.PLAYER_START_Y
	var hold: float = GameConfig.BOT_PATH_HOLD_PX
	# İlk engelden önce: başlangıç yüksekliğinden ilk aralığa
	if death_pair > 0 and d <= _dists[0] - hold:
		var ratio0: float = clampf(d / maxf(_dists[0] - hold, 1.0), 0.0, 1.0)
		return lerpf(GameConfig.PLAYER_START_Y, _ys[0], _smooth(ratio0))
	for i: int in range(n):
		var is_death: bool = i == n - 1 and i == death_pair
		if is_death:
			# Ölüm engeline doğru sapar ve çarpma noktasında hedefe ulaşır
			var prev_y: float = _ys[i - 1] if i > 0 else GameConfig.PLAYER_START_Y
			var start_d: float = (_dists[i - 1] + hold) if i > 0 else 0.0
			var ratio_d: float = clampf((d - start_d) / maxf(death_dist - start_d, 1.0), 0.0, 1.0)
			return lerpf(prev_y, _ys[i], _smooth(ratio_d))
		if d <= _dists[i] + hold:
			return _ys[i]
		if i + 1 < n:
			var next_start: float = _dists[i + 1] - hold
			if i + 1 == death_pair:
				next_start = _dists[i] + hold
			if d < next_start:
				var ratio: float = clampf((d - (_dists[i] + hold)) / maxf(next_start - (_dists[i] + hold), 1.0), 0.0, 1.0)
				return lerpf(_ys[i], _ys[i + 1], _smooth(ratio))
	return _ys[n - 1]


func _smooth(x: float) -> float:
	return x * x * (3.0 - 2.0 * x)

extends Node2D

## Ana oyun dünyası: tek/çok oyunculu akış, deterministik engeller, karanlık evre ve halay zaferi.

const PLAYER_SCENE: PackedScene = preload("res://scenes/entities/Player.tscn")
const SLIPPER_SCENE: PackedScene = preload("res://scenes/entities/SlipperObstacle.tscn")
const MISSILE_SCENE: PackedScene = preload("res://scenes/entities/Missile.tscn")
const WARNING_SCENE: PackedScene = preload("res://scenes/entities/MissileWarning.tscn")

var timeline: ObstacleTimeline = ObstacleTimeline.new()
var match_active: bool = false
var match_ended: bool = false
var match_time: float = 0.0
var score: int = 0

var next_slipper_idx: int = 0
var next_powerup_idx: int = 0
var next_phase_idx: int = 0
var next_warn_idx: int = 0
var next_launch_idx: int = 0
var next_intro_idx: int = 0
var _victory_lap_remaining: float = -1.0
var _test_res_idx: int = 0
var _is_dark_phase: bool = false
var _dark_tween: Tween = null
var current_level: int = 1
var passed_pairs: int = 0
var combo_count: int = 0
var freeze_remaining: float = 0.0
# Faz 10.2: dünya etkili imza ödülleri
var sig_drum_remaining: float = 0.0
var sig_key_remaining: float = 0.0
var sig_tea_remaining: float = 0.0

var active_slippers: Array[Node2D] = []
var active_powerups: Array[Node2D] = []
var active_warnings: Array[Node2D] = []
var active_missiles: Array[Area2D] = []
var _pending_ghost_slippers: Array[Dictionary] = []
var _active_ghost_slippers: Array[Area2D] = []
var players_by_id: Dictionary = {} # peer_id -> Player
var local_player: Area2D = null
# Faz 11.1: bot planları (her cihaz seed'den aynı hesaplar)
var _bot_plans: Dictionary = {} # bot pid -> BotPlanner
var _bot_event_idx: Dictionary = {} # bot pid -> int
var _stats_recorded: bool = false
# Faz 11.2: taht (maç başındaki taç sahibi) ve tek oyunculu hayalet
var _crown_holder_id: int = 0
var _crown_streak: int = 0
var _muhtar_toppled_shown: bool = false
var _ghost_samples: PackedFloat32Array = PackedFloat32Array()
var _ghost_sample_timer: float = 0.0
var _prev_run_ys: PackedFloat32Array = PackedFloat32Array()
var _prev_run_node: Node2D = null
# Faz 11.3: Ölüm Karesi halka tamponu; 11.4: yerel ölüm anındaki süre (görev)
var _death_recorder: DeathFrameRecorder = null
var _local_survive_sec: float = -1.0

var _shake_remaining: float = 0.0
var _shake_rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var bg_a: Sprite2D = $BgLayer/BgA
@onready var bg_b: Sprite2D = $BgLayer/BgB
@onready var obstacle_layer: Node2D = $ObstacleLayer
@onready var missile_layer: Node2D = $MissileLayer
@onready var players_layer: Node2D = $PlayersLayer
@onready var dark_modulate: CanvasModulate = $DarkModulate
@onready var camera: Camera2D = $Camera2D
@onready var hud: CanvasLayer = $Hud


func _ready() -> void:
	DisplayServer.screen_set_keep_on(true)
	AudioManager.play_music("res://assets/sounds/muzik_oyun.ogg")
	_shake_rng.randomize()

	var bg_theme: Dictionary = GameConfig.get_bg_theme(NetworkManager.selected_bg_id)
	var bg_tex: Texture2D = AssetHelper.texture(
		str(bg_theme["path"]),
		str(bg_theme["kind"]),
		GameConfig.BG_SIZE
	)
	bg_a.texture = bg_tex
	bg_b.texture = bg_tex
	bg_a.position = Vector2.ZERO
	bg_b.position = Vector2(GameConfig.VIEWPORT_WIDTH, 0.0)

	# Arka plan kontrastını yumuşatıp karakter/engelleri öne çıkaran atmosferik perde
	var bg_layer: Node = $BgLayer
	if bg_layer.get_node_or_null("BgScrim") == null:
		var bg_scrim: ColorRect = ColorRect.new()
		bg_scrim.name = "BgScrim"
		bg_scrim.position = Vector2.ZERO
		bg_scrim.size = GameConfig.BG_SIZE
		bg_scrim.color = Color(0.06, 0.05, 0.06, 0.36)
		bg_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg_layer.add_child(bg_scrim)

	get_viewport().size_changed.connect(_relayout_for_viewport)
	_relayout_for_viewport()

	_death_recorder = DeathFrameRecorder.new()
	_death_recorder.name = "DeathFrameRecorder"
	_death_recorder.focus_source = _local_focus_ratio
	add_child(_death_recorder)

	hud.retry_requested.connect(_on_retry_requested)
	hud.menu_requested.connect(_on_menu_requested)
	hud.replay_match_requested.connect(_on_replay_match_requested)
	hud.return_lobby_requested.connect(_on_return_lobby_requested)
	hud.powerup_slot_pressed.connect(_on_powerup_slot_pressed)
	hud.quick_chat_sent.connect(func(text: String) -> void:
		# Sunucuya serbest metin değil, hazır satırın indeksi gider.
		NetworkManager.send_quick_chat_text(text)
		Monetization.quest_event("chat")
	)
	hud.ghost_slipper_requested.connect(func(y: float) -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.throw_ghost_slipper.rpc_id(1, y, match_time)
			Monetization.quest_event("ghost_slipper")
	)
	hud.taunt_target_chosen.connect(_on_taunt_target_chosen)
	hud.same_course_requested.connect(_on_same_course_requested)
	hud.rematch_requested.connect(func() -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.request_rematch_vote.rpc_id(1, true)
			Monetization.quest_event("rematch")
	)
	hud.rematch_force_requested.connect(func() -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.request_rematch_force.rpc_id(1)
	)
	hud.finish_victory_lap_requested.connect(func() -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.request_finish_victory_lap.rpc_id(1)
	)

	if NetworkManager.is_multiplayer_match:
		NetworkManager.match_countdown_started.connect(_run_countdown)
		NetworkManager.player_eliminated.connect(_on_network_player_eliminated)
		NetworkManager.player_left_match.connect(_on_network_player_left)
		NetworkManager.winner_announced.connect(_on_winner_announced)
		NetworkManager.victory_lap_started.connect(_on_victory_lap_started)
		NetworkManager.results_ready.connect(_on_results_ready)
		NetworkManager.taunt_applied.connect(_on_taunt_applied)
		NetworkManager.quick_chat_received.connect(_on_quick_chat_received)
		NetworkManager.ghost_slipper_spawned.connect(_on_ghost_slipper_spawned)
		NetworkManager.awards_ready.connect(hud.show_awards_summary)
		NetworkManager.item_fx_received.connect(_on_item_fx_received)
		NetworkManager.local_death_forced.connect(_on_local_death_forced)
		NetworkManager.rematch_updated.connect(_on_rematch_updated)

	_start_new_run()


func _start_new_run() -> void:
	var world_seed: int = NetworkManager.current_seed
	if world_seed == 0:
		world_seed = NetworkManager.prepare_single_player_seed()

	timeline.generate(world_seed, NetworkManager.is_multiplayer_match)
	match_active = false
	match_ended = false
	match_time = 0.0
	score = 0
	next_slipper_idx = 0
	next_powerup_idx = 0
	next_phase_idx = 0
	next_warn_idx = 0
	next_launch_idx = 0
	next_intro_idx = 0
	_victory_lap_remaining = -1.0
	current_level = 1
	passed_pairs = 0
	combo_count = 0
	freeze_remaining = 0.0
	sig_drum_remaining = 0.0
	sig_key_remaining = 0.0
	sig_tea_remaining = 0.0
	_is_dark_phase = false
	dark_modulate.color = Color.WHITE
	bg_a.modulate = GameConfig.LEVEL_BG_TINTS[0]
	bg_b.modulate = GameConfig.LEVEL_BG_TINTS[0]
	_shake_remaining = 0.0
	camera.offset = Vector2.ZERO

	_clear_node_array(active_slippers)
	_clear_node_array(active_powerups)
	_clear_node_array(active_warnings)
	_clear_node_array(active_missiles)
	_clear_node_array(_active_ghost_slippers)
	_pending_ghost_slippers.clear()
	_stats_recorded = false
	_muhtar_toppled_shown = false
	_ghost_samples = PackedFloat32Array()
	_ghost_sample_timer = 0.0
	_local_survive_sec = -1.0
	hud.set_death_card_data(null, "", "", 0, 0.0)
	Monetization.quest_match_begin()
	# Kilitli karakterle oynanamaz; deneme hakkı maç BAŞINDA tüketilir.
	var valid_char: String = Monetization.begin_match_character(NetworkManager.selected_char_id)
	if not NetworkManager.is_multiplayer_match and valid_char != NetworkManager.selected_char_id:
		NetworkManager.save_selected_char(valid_char)
	_spawn_players()
	_load_previous_run(world_seed)

	var cdata: Dictionary = CharacterData.get_character(NetworkManager.selected_char_id)
	hud.set_score(0)
	hud.set_level_progress(1, 0)
	hud.set_seed_text(world_seed)
	hud.set_character_badge(NetworkManager.local_player_name, str(cdata["display_name"]))
	hud.set_spectator_mode(false)
	var counts: Vector2i = NetworkManager.get_alive_counts()
	hud.set_alive_count(counts.x, counts.y)

	if NetworkManager.is_multiplayer_match:
		NetworkManager.client_loaded.rpc_id(1)
		# Geri sayım bildirimi bu sahne yüklenmeden geldiyse sinyal kaçmıştır.
		if NetworkManager.countdown_started:
			_run_countdown()
	else:
		_run_countdown()


func _spawn_players() -> void:
	for child: Node in players_layer.get_children():
		child.queue_free()
	players_by_id.clear()
	local_player = null
	_bot_plans.clear()
	_bot_event_idx.clear()
	_crown_holder_id = 0
	_crown_streak = 0

	if not NetworkManager.is_multiplayer_match:
		var p: Area2D = PLAYER_SCENE.instantiate() as Area2D
		p.name = "1"
		players_layer.add_child(p)
		p.load_character(NetworkManager.selected_char_id)
		p.reset_for_countdown()
		players_by_id[1] = p
		local_player = p
	else:
		var ids: Array = NetworkManager.players.keys()
		ids.sort()
		for pid_v: Variant in ids:
			var pid: int = int(pid_v)
			var pdata: Dictionary = NetworkManager.players[pid] as Dictionary
			var p: Area2D = PLAYER_SCENE.instantiate() as Area2D
			p.name = str(pid) if pid > 0 else "Bot%d" % absi(pid)
			players_layer.add_child(p)
			if NetworkManager.is_bot_id(pid):
				p.configure_bot(pid, str(pdata["name"]), str(pdata["char_id"]))
				_bot_plans[pid] = NetworkManager.build_bot_plan(timeline, timeline.seed_value, pid)
				_bot_event_idx[pid] = 0
			else:
				p.configure_network(pid, str(pdata["name"]), str(pdata["char_id"]))
			var crown: int = int(pdata.get("crown", 0))
			if crown > 0:
				p.set_crown(crown)
				_crown_holder_id = pid
				_crown_streak = crown
			players_by_id[pid] = p
			if pid == multiplayer.get_unique_id():
				local_player = p

	if local_player != null:
		local_player.died.connect(_on_local_player_died)
		local_player.ability_cooldown_changed.connect(hud.update_ability_cooldown)
		local_player.ability2_cooldown_changed.connect(hud.set_ability2_cooldown)
		local_player.spare_leg_triggered.connect(func() -> void:
			combo_count = 0
		)
		local_player.ability_active_changed.connect(hud.update_ability_active)
		local_player.ability2_active_changed.connect(hud.set_ability2_active)
		# Faz 11.4: görev olayları (botlar bu sinyalleri yaymaz; yalnızca yerel oyuncu)
		local_player.ability_active_changed.connect(func(active: bool) -> void:
			if active:
				Monetization.quest_event("ability")
		)
		local_player.ability2_active_changed.connect(func(active: bool) -> void:
			if active and local_player != null:
				Monetization.quest_event("ability")
				Monetization.quest_event("shrink", 1, local_player.char_id)
		)
		local_player.confetti_requested.connect(hud.spawn_edge_confetti)
		local_player.spray_hit.connect(hud.show_spray_warning)
		hud.ability_pressed.connect(local_player.activate_ability)
		hud.ability2_pressed.connect(func() -> void:
			local_player.activate_ability_slot(2)
		)
		local_player.powerup_quick_use_requested.connect(func() -> void:
			hud.trigger_leftmost_powerup()
		)
		local_player.swipe_visual_requested.connect(func(f: Vector2, t: Vector2) -> void:
			hud.show_swipe_arrow(f, t)
		)


func _clear_node_array(arr: Array) -> void:
	for item: Node in arr:
		if is_instance_valid(item):
			item.queue_free()
	arr.clear()


func _run_countdown() -> void:
	hud.show_match_skill_summary(NetworkManager.selected_char_id)
	var steps: Array[String] = ["3", "2", "1", "UÇ!"]
	for step_text: String in steps:
		hud.show_countdown(step_text)
		await get_tree().create_timer(GameConfig.COUNTDOWN_STEP_SEC).timeout
	if match_ended:
		return
	hud.hide_countdown()
	hud.hide_match_skill_summary()
	hud.set_ability_visible(true)
	match_active = true
	if _death_recorder != null and local_player != null:
		_death_recorder.start()
	_show_crown_banner()
	for p: Area2D in players_by_id.values():
		if is_instance_valid(p):
			p.start_flying()


func _process(delta: float) -> void:
	_update_screen_shake(delta)
	_declutter_name_labels(delta)
	if not match_active or match_ended:
		return

	# Arka plandan dönüşte gelen dev delta dünyayı oyuncunun "içinden" geçirmesin.
	delta = minf(delta, GameConfig.MAX_FRAME_DELTA)
	match_time += delta
	NetworkManager.current_match_time = match_time
	if _victory_lap_remaining > 0.0:
		_victory_lap_remaining -= delta
		if _victory_lap_remaining <= 0.0 and NetworkManager.is_multiplayer_match and multiplayer.is_server():
			NetworkManager.request_finish_victory_lap.rpc_id(1)
	if freeze_remaining > 0.0:
		freeze_remaining = maxf(freeze_remaining - delta, 0.0)
		if freeze_remaining <= 0.0:
			for obs: Node2D in active_slippers:
				if is_instance_valid(obs):
					obs.set_frozen(false)

	_update_world_signatures(delta)

	var current_dist: float = timeline.distance_at(match_time)
	var current_speed: float = timeline.speed_at(match_time)

	_scroll_background(current_speed * GameConfig.BG_PARALLAX_RATIO * delta)
	_check_surprise_intros(current_dist)
	_spawn_upcoming_slippers(current_dist)
	_update_active_slippers(current_dist)
	_spawn_upcoming_powerups(current_dist)
	_update_active_powerups(current_dist, delta)
	_update_dark_phase()
	_update_missiles_and_warnings()
	_update_ghost_slippers(delta)
	_update_bots()
	_update_previous_run(delta)


func _relayout_for_viewport() -> void:
	var vis_size: Vector2 = get_viewport().get_visible_rect().size
	var scale_cov: float = maxf(vis_size.x / float(GameConfig.BG_SIZE.x), vis_size.y / float(GameConfig.BG_SIZE.y))
	bg_a.scale = Vector2(scale_cov, scale_cov)
	bg_b.scale = Vector2(scale_cov, scale_cov)
	var bg_w: float = float(GameConfig.BG_SIZE.x) * scale_cov
	bg_b.position.x = bg_a.position.x + bg_w
	var scrim: ColorRect = $BgLayer.get_node_or_null("BgScrim") as ColorRect
	if scrim != null:
		scrim.size = vis_size


func _unhandled_input(event: InputEvent) -> void:
	if GameConfig.DEBUG and event is InputEventKey and event.pressed and not event.echo:
		var kev: InputEventKey = event as InputEventKey
		if kev.keycode == KEY_F9:
			_test_res_idx = (_test_res_idx + 1) % GameConfig.TEST_RESOLUTIONS.size()
			DisplayServer.window_set_size(GameConfig.TEST_RESOLUTIONS[_test_res_idx])


func _scroll_background(shift: float) -> void:
	var bg_w: float = float(GameConfig.BG_SIZE.x) * bg_a.scale.x
	bg_a.position.x -= shift
	bg_b.position.x -= shift
	if bg_a.position.x <= -bg_w:
		bg_a.position.x = bg_b.position.x + bg_w
	if bg_b.position.x <= -bg_w:
		bg_b.position.x = bg_a.position.x + bg_w


func _spawn_upcoming_slippers(current_dist: float) -> void:
	var total: int = timeline.slippers.size()
	while next_slipper_idx < total:
		var data: Dictionary = timeline.slippers[next_slipper_idx]
		var obs_dist: float = float(data["distance"])
		var spawn_ahead: float = get_viewport().get_visible_rect().end.x - GameConfig.PLAYER_X + GameConfig.SPAWN_AHEAD_PX
		var screen_x: float = GameConfig.PLAYER_X + (obs_dist - current_dist)
		if screen_x > GameConfig.PLAYER_X + spawn_ahead:
			break

		var obs: Node2D = SLIPPER_SCENE.instantiate() as Node2D
		obstacle_layer.add_child(obs)
		var surprise: String = String(data.get("surprise_type", ""))
		obs.setup(
			int(data["index"]),
			obs_dist,
			float(data["gap_y"]),
			float(data["gap_size"]),
			bool(data.get("has_spray", false)),
			surprise,
			float(data.get("bob_amp", GameConfig.ANNE_ELI_BOB_AMP))
		)
		obs.set_frozen(freeze_remaining > 0.0)
		obs.set_gap_mult(GameConfig.SIG_KEY_GAP_MULT if sig_key_remaining > 0.0 else 1.0)
		obs.set_drum(sig_drum_remaining > 0.0)
		obs.position.x = screen_x
		active_slippers.append(obs)
		if surprise == "sopa":
			AudioManager.play_sfx("res://assets/sounds/sopa.wav")
		next_slipper_idx += 1


func _update_active_slippers(current_dist: float) -> void:
	var kept: Array[Node2D] = []
	for obs: Node2D in active_slippers:
		if not is_instance_valid(obs):
			continue
		var obs_dist: float = float(obs.get("world_distance"))
		var screen_x: float = GameConfig.PLAYER_X + (obs_dist - current_dist)
		obs.position.x = screen_x
		obs.update_motion(match_time)

		if not bool(obs.get("passed")) and obs_dist < current_dist:
			obs.set("passed", true)
			passed_pairs += 1
			var new_lv: int = GameConfig.level_for_passed_pairs(passed_pairs)
			if new_lv > current_level:
				current_level = new_lv
				var lv_cfg: Dictionary = GameConfig.get_level_config(current_level)
				hud.show_level_up_banner(current_level, str(lv_cfg["name"]))
				if local_player != null and local_player.state == local_player.State.ACTIVE:
					Monetization.quest_event("level", current_level)
				var tint: Color = GameConfig.LEVEL_BG_TINTS[(current_level - 1) % GameConfig.LEVEL_BG_TINTS.size()]
				var bg_tw: Tween = create_tween().set_parallel(true)
				bg_tw.tween_property(bg_a, "modulate", tint, 0.8)
				bg_tw.tween_property(bg_b, "modulate", tint, 0.8)
			hud.set_level_progress(current_level, passed_pairs)

			if local_player != null and local_player.state == local_player.State.ACTIVE:
				var extra_px: float = GameConfig.SIG_TEA_SCARE_EXTRA_PX if sig_tea_remaining > 0.0 else 0.0
				var is_close: bool = obs.is_close_scare(local_player.position.y, GameConfig.PLAYER_HITBOX_RADIUS, extra_px)
				obs.trigger_scare(is_close)
				Monetization.quest_event("pass")
				if is_close:
					combo_count += 1
					Monetization.quest_event("close")
					Monetization.quest_event("combo", combo_count)
					if sig_tea_remaining > 0.0:
						Monetization.add_kirinti(1)
					if local_player.char_id == "halaybasi" and combo_count % 5 == 0:
						local_player.reduce_cooldowns(2.0)
					var close_sfx: String = "res://assets/sounds/lululu.wav" if (_shake_rng.randi() % 2 == 0) else "res://assets/sounds/agucuk.wav"
					AudioManager.play_sfx(close_sfx)
					var combo_title: String = GameConfig.get_combo_title(combo_count)
					if not combo_title.is_empty():
						local_player.show_combo_title("x%d %s" % [combo_count, combo_title])
				else:
					combo_count = 0
				var close_pts: int = 4 if local_player.sig_bread_remaining > 0.0 else 2
				score += (close_pts if is_close else 1)
				Monetization.quest_event("scare", close_pts if is_close else 1)
				hud.set_score(score)
				if NetworkManager.is_multiplayer_match:
					NetworkManager.report_score_update.rpc_id(1, score)

		if screen_x < -GameConfig.DESPAWN_BEHIND_PX:
			obs.queue_free()
		else:
			kept.append(obs)
	active_slippers = kept


func _update_dark_phase() -> void:
	if next_phase_idx >= timeline.dark_phases.size():
		return
	var phase: Dictionary = timeline.dark_phases[next_phase_idx]
	var start_t: float = float(phase["start_time"])
	var end_t: float = float(phase["end_time"])

	if not _is_dark_phase and match_time >= start_t:
		_is_dark_phase = true
		_tween_dark_modulate(GameConfig.DARK_MODULATE_COLOR)
		hud.show_phase_banner(GameConfig.DARK_BANNER_TEXT)
		AudioManager.play_sfx("res://assets/sounds/aydinlat.ogg")
		if local_player != null:
			local_player.set_dark_light(true)
	elif _is_dark_phase and match_time >= end_t:
		_is_dark_phase = false
		if local_player != null and local_player.state == local_player.State.ACTIVE:
			Monetization.quest_event("missile_survive")
		_tween_dark_modulate(Color.WHITE)
		if local_player != null:
			local_player.set_dark_light(false)
		next_phase_idx += 1


func _tween_dark_modulate(target_col: Color) -> void:
	if _dark_tween != null and _dark_tween.is_valid():
		_dark_tween.kill()
	_dark_tween = create_tween()
	_dark_tween.tween_property(dark_modulate, "color", target_col, GameConfig.DARK_TWEEN_SEC)


func _check_surprise_intros(current_dist: float) -> void:
	while next_intro_idx < timeline.surprise_intros.size():
		var intro: Dictionary = timeline.surprise_intros[next_intro_idx]
		if current_dist < float(intro["trigger_dist"]):
			break
		var txt: String = str(intro.get("text", ""))
		if not txt.is_empty():
			hud.show_phase_banner(txt)
		next_intro_idx += 1


func _update_missiles_and_warnings() -> void:
	var warn_lead: float = 0.2 if (local_player != null and local_player.char_id == "diva") else 0.0
	var total_m: int = timeline.missiles.size()
	while next_warn_idx < total_m:
		var m_data: Dictionary = timeline.missiles[next_warn_idx]
		if match_time < float(m_data["warn_time"]) - warn_lead:
			break
		if match_time < float(m_data["launch_time"]):
			var warn: Node2D = WARNING_SCENE.instantiate() as Node2D
			missile_layer.add_child(warn)
			warn.setup(m_data["start_pos"] as Vector2, m_data["dir"] as Vector2, float(m_data["launch_time"]))
			active_warnings.append(warn)
		next_warn_idx += 1

	var kept_warnings: Array[Node2D] = []
	for warn: Node2D in active_warnings:
		if not is_instance_valid(warn):
			continue
		if match_time >= float(warn.get("launch_time")):
			warn.queue_free()
		else:
			kept_warnings.append(warn)
	active_warnings = kept_warnings

	while next_launch_idx < total_m:
		var m_data: Dictionary = timeline.missiles[next_launch_idx]
		if match_time < float(m_data["launch_time"]):
			break
		if active_missiles.size() < GameConfig.MISSILE_MAX_ACTIVE:
			var missile: Area2D = MISSILE_SCENE.instantiate() as Area2D
			missile_layer.add_child(missile)
			missile.setup(m_data["start_pos"] as Vector2, m_data["dir"] as Vector2, float(m_data["launch_time"]))
			active_missiles.append(missile)
			AudioManager.play_sfx("res://assets/sounds/fuze.ogg", 0.95, 1.08)
		next_launch_idx += 1

	var kept_missiles: Array[Area2D] = []
	for missile: Area2D in active_missiles:
		if not is_instance_valid(missile):
			continue
		missile.update_at_time(match_time)
		if missile.position.x < -160.0 or missile.position.y > GameConfig.VIEWPORT_HEIGHT + 160.0:
			missile.queue_free()
		else:
			kept_missiles.append(missile)
	active_missiles = kept_missiles


func _update_screen_shake(delta: float) -> void:
	if _shake_remaining <= 0.0:
		camera.offset = Vector2.ZERO
		return
	_shake_remaining = maxf(_shake_remaining - delta, 0.0)
	var ratio: float = _shake_remaining / GameConfig.DEATH_SHAKE_DURATION
	var strength: float = GameConfig.DEATH_SHAKE_STRENGTH * ratio
	camera.offset = Vector2(
		_shake_rng.randf_range(-strength, strength),
		_shake_rng.randf_range(-strength, strength)
	)


func _on_local_player_died(cause: String) -> void:
	_record_stats_once()
	if not NetworkManager.is_multiplayer_match:
		_save_current_run()
	combo_count = 0
	_local_survive_sec = match_time
	# Faz 11.3: son kare siyah-beyaz efektten ÖNCE alınır
	if _death_recorder != null:
		_death_recorder.capture_death()
		hud.set_death_card_data(_death_recorder, cause, local_player.char_id if local_player != null else NetworkManager.selected_char_id, score, match_time)
	_shake_remaining = GameConfig.DEATH_SHAKE_DURATION
	AudioManager.play_death_music(true)
	hud.play_bw_death_effect()
	hud.show_first_time_tip("tip_death", "İlk kez elendin! İstersen tekrar dene ya da arkadaşlarını izle.")
	if NetworkManager.is_multiplayer_match:
		hud.set_spectator_mode(true)
		hud.show_mini_portrait(local_player.char_id if local_player != null else NetworkManager.selected_char_id)
		var counts: Vector2i = NetworkManager.get_alive_counts()
		hud.set_alive_count(counts.x, counts.y)
	else:
		match_active = false
		# Tasarım: engel başına 1, yakın kaçış başına +1 (skor zaten bunların toplamı).
		var earned: int = maxi(score, 1)
		if NetworkManager.selected_char_id == "emlakci":
			earned = int(ceilf(float(earned) * 1.2))
		Monetization.add_kirinti(earned)
		Monetization.quest_match_end({
			"char": NetworkManager.selected_char_id,
			"mp": false,
			"survive": int(match_time),
			"level": current_level,
		})
		Monetization.consume_trial()
		await get_tree().create_timer(GameConfig.DEATH_PANEL_DELAY).timeout
		hud.show_death_panel(score, NetworkManager.selected_char_id, cause, earned)


func _spawn_upcoming_powerups(current_dist: float) -> void:
	var total: int = timeline.powerups.size()
	while next_powerup_idx < total:
		var data: Dictionary = timeline.powerups[next_powerup_idx]
		var box_dist: float = float(data["distance"])
		var screen_x: float = GameConfig.PLAYER_X + (box_dist - current_dist)
		if screen_x > get_viewport().get_visible_rect().end.x + GameConfig.SPAWN_AHEAD_PX:
			break
		var box: Node2D = _create_powerup_box_node(data)
		box.position = Vector2(screen_x, float(data["y"]))
		obstacle_layer.add_child(box)
		active_powerups.append(box)
		next_powerup_idx += 1


func _create_powerup_box_node(data: Dictionary) -> Node2D:
	var item_id: String = str(data["item_id"])
	var box: Node2D = Node2D.new()
	box.set_meta("world_distance", float(data["distance"]))
	box.set_meta("item_id", item_id)
	box.set_meta("magnet_offset", Vector2.ZERO)

	# Faz 10.1: pastel kırıntı tabağı + gerçek ikon görseli (harf yok)
	var plate: Sprite2D = Sprite2D.new()
	plate.texture = IconFactory.plate_texture(64)
	box.add_child(plate)

	var icon: Sprite2D = Sprite2D.new()
	var icon_tex: Texture2D = IconFactory.item_icon(item_id)
	icon.texture = icon_tex
	var max_side: float = maxf(float(icon_tex.get_width()), float(icon_tex.get_height()))
	var target: float = 46.0
	icon.scale = Vector2.ONE * (target / maxf(max_side, 1.0))
	box.add_child(icon)
	return box


func _update_active_powerups(current_dist: float, delta: float) -> void:
	var kept: Array[Node2D] = []
	for box: Node2D in active_powerups:
		if not is_instance_valid(box):
			continue
		var box_dist: float = float(box.get_meta("world_distance"))
		var base_x: float = GameConfig.PLAYER_X + (box_dist - current_dist)
		var mag_off: Vector2 = box.get_meta("magnet_offset", Vector2.ZERO) as Vector2
		box.position.x = base_x + mag_off.x
		box.rotation = sin(match_time * 3.5) * 0.16

		if local_player != null and local_player.state == local_player.State.ACTIVE:
			if local_player.magnet_remaining > 0.0 and box.position.distance_to(local_player.position) <= GameConfig.POWERUP_MAGNET_RADIUS:
				var pull: Vector2 = (local_player.position - box.position).normalized() * 380.0 * delta
				mag_off += pull
				box.set_meta("magnet_offset", mag_off)
				box.position.y += pull.y
			if box.position.distance_to(local_player.position) <= 56.0:
				var item_id: String = str(box.get_meta("item_id"))
				Monetization.quest_event("box")
				if item_id == GameConfig.MYSTERY_ITEM_ID:
					Monetization.quest_event("mystery")
					# Faz 10.2: gizemli kutu, toplayanın karakterine göre imza ödülüne dönüşür
					item_id = GameConfig.get_signature_for(local_player.char_id)
					if item_id.is_empty():
						item_id = "dondurma"
					var sig_def: Dictionary = GameConfig.get_item_def(item_id)
					local_player.speech_bubble.show_text(str(sig_def.get("quote", "")), 1.6)
					hud.show_first_time_tip("tip_signature", "İmza ödülün çıktı! Her böceğin kendine özel bir ödülü var.")
				hud.add_powerup(item_id)
				hud.show_first_time_tip("tip_powerup", "Güçlendirme aldın! Alttaki yuvarlak tepsiden dokun.")
				AudioManager.play_sfx("res://assets/sounds/kutu_al.ogg")
				box.queue_free()
				continue

		if box.position.x < -GameConfig.DESPAWN_BEHIND_PX:
			box.queue_free()
		else:
			kept.append(box)
	active_powerups = kept


func _on_powerup_slot_pressed(slot_idx: int) -> void:
	if local_player == null or local_player.state != local_player.State.ACTIVE:
		return
	var item_id: String = hud.get_powerup_at(slot_idx)
	if item_id.is_empty():
		return
	if GameConfig.TAUNT_DEFS.has(item_id):
		if not NetworkManager.is_multiplayer_match:
			return
		var my_id: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
		if item_id == "ayna":
			NetworkManager.send_taunt_item.rpc_id(1, my_id, "ayna")
			hud.consume_powerup_at(slot_idx)
		else:
			hud.open_taunt_target_picker(slot_idx)
		return
	match item_id:
		"dondurma":
			freeze_remaining = GameConfig.POWERUP_FREEZE_DURATION
			for obs: Node2D in active_slippers:
				if is_instance_valid(obs):
					obs.set_frozen(true)
			local_player.speech_bubble.show_text("Beyin dondu ama değdi.", 1.5)
			AudioManager.play_sfx("res://assets/sounds/dondurma.ogg")
		"turbo":
			local_player.activate_turbo()
			if NetworkManager.is_multiplayer_match:
				NetworkManager.show_item_fx.rpc("turbo")
		"yedek_bacak":
			if not local_player.activate_spare_leg():
				return
		"miknatis":
			local_player.activate_magnet()
		"ozel_yetenek":
			local_player.refresh_ability_cooldown()
		"davul":
			sig_drum_remaining = GameConfig.SIG_DRUM_DURATION
			_apply_world_signatures_to_obstacles()
			local_player.speech_bubble.show_text(str(GameConfig.get_item_def("davul").get("quote", "")), 1.6)
			if NetworkManager.is_multiplayer_match:
				NetworkManager.show_item_fx.rpc("davul")
		"ingiliz_anahtari":
			if not _shatter_next_obstacle():
				return
			local_player.speech_bubble.show_text(str(GameConfig.get_item_def("ingiliz_anahtari").get("quote", "")), 1.6)
		"yedek_anahtar":
			sig_key_remaining = GameConfig.SIG_KEY_DURATION
			_apply_world_signatures_to_obstacles()
			local_player.speech_bubble.show_text(str(GameConfig.get_item_def("yedek_anahtar").get("quote", "")), 1.6)
		"demlik_cay":
			sig_tea_remaining = GameConfig.SIG_TEA_DURATION
			local_player.speech_bubble.show_text(str(GameConfig.get_item_def("demlik_cay").get("quote", "")), 1.6)
		_:
			if GameConfig.SIGNATURE_DEFS.has(item_id):
				if not local_player.activate_signature(item_id):
					return
			else:
				return
	hud.consume_powerup_at(slot_idx)
	Monetization.quest_event("powerup_use")
	if GameConfig.SIGNATURE_DEFS.has(item_id):
		Monetization.quest_event("signature")


func _update_world_signatures(delta: float) -> void:
	var changed: bool = false
	if sig_drum_remaining > 0.0:
		sig_drum_remaining = maxf(sig_drum_remaining - delta, 0.0)
		changed = changed or sig_drum_remaining <= 0.0
	if sig_key_remaining > 0.0:
		sig_key_remaining = maxf(sig_key_remaining - delta, 0.0)
		changed = changed or sig_key_remaining <= 0.0
	if sig_tea_remaining > 0.0:
		sig_tea_remaining = maxf(sig_tea_remaining - delta, 0.0)
	if changed:
		_apply_world_signatures_to_obstacles()


func _apply_world_signatures_to_obstacles() -> void:
	for obs: Node2D in active_slippers:
		if is_instance_valid(obs):
			obs.set_gap_mult(GameConfig.SIG_KEY_GAP_MULT if sig_key_remaining > 0.0 else 1.0)
			obs.set_drum(sig_drum_remaining > 0.0)


## İngiliz Anahtarı: oyuncunun önündeki ilk geçilmemiş engel çiftini söker.
func _shatter_next_obstacle() -> bool:
	var best: Node2D = null
	for obs: Node2D in active_slippers:
		if not is_instance_valid(obs) or bool(obs.get("passed")):
			continue
		if obs.position.x < local_player.position.x - 20.0:
			continue
		if best == null or obs.position.x < best.position.x:
			best = obs
	if best == null:
		return false
	best.shatter_all()
	AudioManager.play_sfx("res://assets/sounds/terlik_kirildi.ogg", 0.95, 1.08)
	return true


func _on_taunt_target_chosen(slot_idx: int, target_id: int) -> void:
	var item_id: String = hud.get_powerup_at(slot_idx)
	if item_id.is_empty():
		return
	NetworkManager.send_taunt_item.rpc_id(1, target_id, item_id)
	NetworkManager.show_item_fx.rpc("taunt")
	hud.consume_powerup_at(slot_idx)
	Monetization.quest_event("taunt")


func _on_item_fx_received(sender_id: int, item_id: String) -> void:
	if not players_by_id.has(sender_id):
		return
	var p: Area2D = players_by_id[sender_id] as Area2D
	if not is_instance_valid(p):
		return
	if item_id == "turbo":
		if not p.is_local_player:
			p.speech_bubble.show_text("Bas bas kökle amk kökleeee", 2.0)
			if ResourceLoader.exists("res://assets/sounds/turbo_kokle.ogg"):
				AudioManager.play_sfx("res://assets/sounds/turbo_kokle.ogg")
			else:
				AudioManager.play_sfx("res://assets/sounds/turbo.ogg")
	elif item_id == "davul":
		if not p.is_local_player:
			p.speech_bubble.show_text("Davulcu geldi, halay başlasın!", 1.6)
			hud.spawn_edge_confetti()
	elif item_id == "taunt":
		p.speech_bubble.show_text("Özür dilerim pıttığım", 1.8)
		if ResourceLoader.exists("res://assets/sounds/ozur_dilerim.ogg"):
			AudioManager.play_sfx("res://assets/sounds/ozur_dilerim.ogg")


func _on_taunt_applied(sender_id: int, target_id: int, item_id: String) -> void:
	var sender_name: String = str(NetworkManager.players.get(sender_id, {}).get("name", "Böcek"))
	var target_name: String = str(NetworkManager.players.get(target_id, {}).get("name", "Böcek"))
	# Bot sataşırken o da "Özür dilerim pıttığım" der
	if NetworkManager.is_bot_id(sender_id) and players_by_id.has(sender_id):
		var bp: Area2D = players_by_id[sender_id] as Area2D
		if is_instance_valid(bp) and item_id != "ayna":
			bp.speech_bubble.show_text("Özür dilerim pıttığım", 1.8)
	# Bota atılan sataşma yalnızca görsel etkidir (ölüm anını değiştirmez)
	if NetworkManager.is_bot_id(target_id) and players_by_id.has(target_id):
		var tp: Area2D = players_by_id[target_id] as Area2D
		if is_instance_valid(tp) and item_id != "ayna":
			tp.apply_taunt_effect(item_id, sender_name)
	var item_name: String = str(GameConfig.get_item_def(item_id).get("name", item_id))
	if item_id == "ayna":
		hud.push_event_feed("%s: Ayna kalkanı!" % sender_name)
	else:
		hud.push_event_feed("%s -> %s: %s" % [sender_name, target_name, item_name])

	var my_id: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	if target_id != my_id or local_player == null or local_player.state != local_player.State.ACTIVE:
		return
	if item_id == "ayna":
		local_player.apply_taunt_effect("ayna", sender_name)
		return
	hud.show_taunt_warning(sender_name, item_name)
	await get_tree().create_timer(GameConfig.TAUNT_WARN_DELAY).timeout
	if not is_instance_valid(local_player) or local_player.state != local_player.State.ACTIVE:
		return
	hud.activate_taunt_immunity()
	local_player.apply_taunt_effect(item_id, sender_name)
	if item_id == "kirli_corap":
		hud.show_dirty_sock_cloud(_shake_rng.randi() % 2 == 0)
	elif item_id == "komsu_teyze":
		hud.show_aunt_popup()


func _on_quick_chat_received(sender_id: int, text: String) -> void:
	if players_by_id.has(sender_id):
		var p: Area2D = players_by_id[sender_id] as Area2D
		if is_instance_valid(p):
			p.speech_bubble.show_text(text, 2.0)


func _on_ghost_slipper_spawned(thrower_id: int, y: float, launch_match_time: float) -> void:
	var warn: Node2D = WARNING_SCENE.instantiate() as Node2D
	missile_layer.add_child(warn)
	warn.position = Vector2(get_viewport().get_visible_rect().end.x - 48.0, y)
	_pending_ghost_slippers.append({
		"thrower_id": thrower_id,
		"y": y,
		"launch_time": launch_match_time,
		"warn": warn,
	})


func _update_ghost_slippers(delta: float) -> void:
	var kept_pending: Array[Dictionary] = []
	for entry: Dictionary in _pending_ghost_slippers:
		if match_time >= float(entry["launch_time"]):
			var w: Node2D = entry.get("warn") as Node2D
			if is_instance_valid(w):
				w.queue_free()
			_spawn_ghost_slipper_projectile(int(entry["thrower_id"]), float(entry["y"]))
		else:
			kept_pending.append(entry)
	_pending_ghost_slippers = kept_pending

	var kept_active: Array[Area2D] = []
	for gs: Area2D in _active_ghost_slippers:
		if not is_instance_valid(gs):
			continue
		gs.position.x -= GameConfig.GHOST_SLIPPER_SPEED * delta
		var sp: Node2D = gs.get_node_or_null("Visual") as Node2D
		if sp != null:
			sp.rotation -= 8.0 * delta
		if gs.position.x < -160.0:
			gs.queue_free()
		else:
			kept_active.append(gs)
	_active_ghost_slippers = kept_active


func _spawn_ghost_slipper_projectile(thrower_id: int, y: float) -> void:
	AudioManager.play_sfx("res://assets/sounds/terlik_at.ogg")
	var area: Area2D = Area2D.new()
	area.collision_layer = GameConfig.LAYER_SLIPPER
	area.collision_mask = 0
	area.monitoring = false
	area.monitorable = true
	area.position = Vector2(get_viewport().get_visible_rect().end.x + 60.0, y)
	area.set_meta("death_cause", "hayalet_terlik")
	area.set_meta("ghost_thrower_id", thrower_id)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(64.0, 44.0)
	shape.shape = rect
	area.add_child(shape)

	var vis: ColorRect = ColorRect.new()
	vis.name = "Visual"
	vis.color = GameConfig.COLOR_WARN_RED
	vis.size = Vector2(68.0, 34.0)
	vis.position = Vector2(-34.0, -17.0)
	vis.pivot_offset = Vector2(34.0, 17.0)
	area.add_child(vis)

	var lbl: Label = Label.new()
	var t_name: String = str(NetworkManager.players.get(thrower_id, {}).get("name", "Böcek"))
	lbl.text = "%s'ten sevgilerle" % t_name
	lbl.position = Vector2(-80.0, -44.0)
	lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	lbl.add_theme_constant_override("outline_size", 4)
	area.add_child(lbl)

	missile_layer.add_child(area)
	_active_ghost_slippers.append(area)


func _on_network_player_eliminated(pid: int, cause: String) -> void:
	var p_name: String = str(NetworkManager.players.get(pid, {}).get("name", "Böcek"))
	var line: String = GameConfig.get_random_death_cause_line(cause, p_name)
	if players_by_id.has(pid):
		var p: Area2D = players_by_id[pid] as Area2D
		if is_instance_valid(p):
			if not p.last_taunt_sender_name.is_empty():
				line += " (Teşekkürler %s!)" % p.last_taunt_sender_name
				if pid == _crown_holder_id and _crown_streak >= GameConfig.CROWN_MUHTAR_STREAK and not _muhtar_toppled_shown:
					_muhtar_toppled_shown = true
					hud.push_event_feed("%s muhtarı devirdi!" % p.last_taunt_sender_name)
			var early_bot: bool = false
			if _bot_plans.has(pid):
				# Duyuru az önce geldiyse bot planındaki çarpışma anında ölür (görsel engelle aynı kalsın)
				var wait_t: float = (_bot_plans[pid] as BotPlanner).death_time - match_time
				early_bot = wait_t > 0.0 and wait_t <= GameConfig.BOT_DEATH_SYNC_TOLERANCE_SEC
			if not p.is_local_player and not early_bot:
				p.play_remote_death()
				AudioManager.play_death_music(false)
	hud.push_event_feed(line)
	var counts: Vector2i = NetworkManager.get_alive_counts()
	hud.set_alive_count(counts.x, counts.y)


func _on_network_player_left(pid: int) -> void:
	if players_by_id.has(pid):
		var p: Area2D = players_by_id[pid] as Area2D
		if is_instance_valid(p):
			p.queue_free()
		players_by_id.erase(pid)
	var counts: Vector2i = NetworkManager.get_alive_counts()
	hud.set_alive_count(counts.x, counts.y)


func _on_victory_lap_started(winner_id: int) -> void:
	AudioManager.stop_death_music()
	_victory_lap_remaining = GameConfig.VICTORY_LAP_DURATION
	var w_name: String = str(NetworkManager.players.get(winner_id, {}).get("name", "Böcek"))
	var local_uid: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	hud.show_victory_lap_banner(winner_id == local_uid, w_name)
	_announce_muhtar_toppled(winner_id)


func _on_results_ready(results: Array) -> void:
	match_ended = true
	match_active = false
	_victory_lap_remaining = -1.0
	AudioManager.stop_death_music()
	_tween_dark_modulate(Color.WHITE)
	var local_uid: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	if _death_recorder != null:
		_death_recorder.stop()
	var my_rank: int = 0
	for r_v: Variant in results:
		var r: Dictionary = r_v as Dictionary
		if int(r.get("peer_id", 0)) == local_uid:
			my_rank = int(r.get("rank", 5))
			var rk: int = int(r.get("rank", 5))
			var rank_k: int = GameConfig.KIRINTI_RANK_BONUS[mini(rk - 1, GameConfig.KIRINTI_RANK_BONUS.size() - 1)]
			if NetworkManager.is_offline_bots:
				rank_k = 0
			var tot_k: int = rank_k + score
			if NetworkManager.selected_char_id == "emlakci":
				tot_k = int(ceilf(float(tot_k) * 1.2))
			Monetization.add_kirinti(tot_k)
			break
	Monetization.quest_match_end({
		"char": NetworkManager.selected_char_id,
		"mp": true,
		"won": my_rank == 1,
		"survive": int(_local_survive_sec if _local_survive_sec >= 0.0 else match_time),
		# Elendikten sonra dünya akmaya devam eder; seviye görevi canlıyken olaylarla ilerler
		"level": current_level if _local_survive_sec < 0.0 else 0,
	})
	Monetization.consume_trial()
	_record_stats_once()
	_announce_muhtar_toppled(_winner_from_results(results))
	hud.show_results_ranking(results, local_uid, NetworkManager.is_room_owner())


func _on_winner_announced(winner_id: int, is_draw: bool) -> void:
	match_ended = true
	match_active = false
	_tween_dark_modulate(Color.WHITE)

	var title_text: String = "BERABERE!"
	if not is_draw and NetworkManager.players.has(winner_id):
		var w_name: String = str(NetworkManager.players[winner_id].get("name", "Böcek"))
		title_text = "%s KAZANDI!" % w_name

	# Kazanan / hayatta kalan böcekler tüm ekranlarda aynı anda halay çeker
	var dancers: Array[Area2D] = []
	if not is_draw and players_by_id.has(winner_id):
		dancers.append(players_by_id[winner_id] as Area2D)
	else:
		for p: Area2D in players_by_id.values():
			if is_instance_valid(p):
				dancers.append(p)

	var win_char: String = NetworkManager.selected_char_id
	if not is_draw and NetworkManager.players.has(winner_id):
		win_char = str(NetworkManager.players[winner_id].get("char_id", "klasik"))
	var win_entry: Dictionary = CharacterData.get_random_win_entry(win_char)

	for i: int in range(dancers.size()):
		if is_instance_valid(dancers[i]):
			dancers[i].start_halay_dance(i, dancers.size(), str(win_entry["text"]))

	AudioManager.play_sfx(str(win_entry["sound"]), 0.98, 1.04)
	hud.show_winner_panel(title_text, score, NetworkManager.is_room_owner())


func _on_retry_requested() -> void:
	NetworkManager.prepare_single_player_seed()
	get_tree().reload_current_scene()


## Ağ yerel oyuncuyu ölü saydı (ör. uzun süre arka planda kaldı): yerelde de öldür.
func _on_local_death_forced(cause: String) -> void:
	if local_player != null and is_instance_valid(local_player) and local_player.state != local_player.State.DEAD:
		local_player.die(cause)


func _on_menu_requested() -> void:
	get_tree().paused = false
	Monetization.quest_match_abort()
	if NetworkManager.is_offline_bots:
		NetworkManager.leave_game()
	Monetization.end_match_character()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


## O8: Tek oyunculuda uygulama arka plana gidince / pencere odağı kaybolunca otomatik duraklat.
## Android Geri tuşu da duraklatır (oyundan yanlışlıkla çıkılmasın).
func _notification(what: int) -> void:
	var lost_focus: bool = what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT
	var back_pressed: bool = what == NOTIFICATION_WM_GO_BACK_REQUEST
	if not (lost_focus or back_pressed):
		return
	if NetworkManager.is_multiplayer_match or not match_active or match_ended:
		return
	if hud != null and hud.has_method("open_pause_menu"):
		hud.call("open_pause_menu")


func _on_replay_match_requested() -> void:
	if NetworkManager.is_dedicated_mode:
		NetworkManager.request_start_match.rpc_id(1)
	else:
		NetworkManager.host_start_match()


func _on_return_lobby_requested() -> void:
	# Rövanş açıkken lobiye dönmek "rövanşı reddet" demektir (oda lobiye döner)
	if NetworkManager.rematch_state != GameConfig.REMATCH_STATE_CLOSED:
		NetworkManager.request_rematch_vote.rpc_id(1, false)
	elif NetworkManager.is_dedicated_mode:
		NetworkManager.request_return_lobby.rpc_id(1)
	else:
		NetworkManager.host_return_to_lobby()


# ---------------------------------------------------------------------------
# Faz 11.1: Botlar (görsel yol, laf, yetenek; ölüm anı plandan)
# ---------------------------------------------------------------------------

func _update_bots() -> void:
	for pid_v: Variant in _bot_plans.keys():
		var pid: int = int(pid_v)
		if not players_by_id.has(pid):
			continue
		var p: Area2D = players_by_id[pid] as Area2D
		if not is_instance_valid(p) or p.state != p.State.ACTIVE:
			continue
		var plan: BotPlanner = _bot_plans[pid] as BotPlanner
		if match_time >= plan.death_time:
			# Planlanan engele çarptı: ölüm akışı (sunucu duyurusu sayaç ve sıralamayı günceller)
			p.play_remote_death()
			AudioManager.play_death_music(false)
			continue
		p.set_bot_pose(plan.y_at(match_time), plan.rotation_at(match_time))
		var idx: int = int(_bot_event_idx.get(pid, 0))
		while idx < plan.events.size() and float(plan.events[idx]["time"]) <= match_time:
			var ev: Dictionary = plan.events[idx]
			idx += 1
			match str(ev["kind"]):
				"chat":
					var li: int = int(ev["value"])
					var txt: String = GameConfig.QUICK_CHAT_LINES[li] if li < GameConfig.QUICK_CHAT_LINES.size() else str(CharacterData.get_character(p.char_id).get("taunt_line", ""))
					if not txt.is_empty():
						p.speech_bubble.show_text(txt, 2.0)
				"ability":
					p.bot_visual_ability(int(ev["value"]))
				"sig":
					p.bot_visual_signature()
		_bot_event_idx[pid] = idx


func _on_rematch_updated(accepted: Array, total: int, state: int, secs: float) -> void:
	var uid: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	hud.update_rematch(accepted, total, state, secs, uid, NetworkManager.is_room_owner())


func _record_stats_once() -> void:
	if _stats_recorded:
		return
	_stats_recorded = true
	NetworkManager.record_local_match(current_level)


# ---------------------------------------------------------------------------
# Faz 11.2: Taht ve Mahalle Muhtarı
# ---------------------------------------------------------------------------

func _show_crown_banner() -> void:
	if _crown_holder_id == 0 or not NetworkManager.is_multiplayer_match:
		return
	var local_uid: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	var c_name: String = str(NetworkManager.players.get(_crown_holder_id, {}).get("name", "Böcek"))
	if _crown_holder_id == local_uid:
		hud.show_phase_banner("Tahtını koru!" if _crown_streak < GameConfig.CROWN_MUHTAR_STREAK else "Muhtarlığını koru!")
	else:
		hud.show_phase_banner("%s'i tahtından indirin!" % c_name)


func _winner_from_results(results: Array) -> int:
	for r_v: Variant in results:
		var r: Dictionary = r_v as Dictionary
		if int(r.get("rank", 0)) == 1:
			return int(r.get("peer_id", 0))
	return 0


## Muhtar (3+ seri) kazanamadıysa kazananın adına özel satır.
func _announce_muhtar_toppled(winner_id: int) -> void:
	if _muhtar_toppled_shown or _crown_streak < GameConfig.CROWN_MUHTAR_STREAK:
		return
	if winner_id == 0 or winner_id == _crown_holder_id:
		return
	_muhtar_toppled_shown = true
	var w_name: String = str(NetworkManager.players.get(winner_id, {}).get("name", "Böcek"))
	hud.push_event_feed("%s muhtarı devirdi!" % w_name)


# ---------------------------------------------------------------------------
# Faz 11.2: Tek oyunculu "Aynı Parkur" ve önceki denemenin hayaleti
# ---------------------------------------------------------------------------

func _on_same_course_requested() -> void:
	Monetization.quest_event("same_course")
	NetworkManager.prepare_single_player_seed(timeline.seed_value)
	get_tree().reload_current_scene()


## Yerel oyuncunun Y konumunu 0.1 sn aralıkla kaydeder (yalnızca tek oyunculu).
func _sample_current_run(delta: float) -> void:
	if NetworkManager.is_multiplayer_match or local_player == null or local_player.state != local_player.State.ACTIVE:
		return
	_ghost_sample_timer += delta
	while _ghost_sample_timer >= GameConfig.GHOST_RUN_STEP_SEC and _ghost_samples.size() < GameConfig.GHOST_RUN_MAX_SAMPLES:
		_ghost_sample_timer -= GameConfig.GHOST_RUN_STEP_SEC
		_ghost_samples.append(local_player.position.y)


func _save_current_run() -> void:
	if _ghost_samples.size() < 2:
		return
	var f: FileAccess = FileAccess.open(GameConfig.GHOST_RUN_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({
		"seed": timeline.seed_value,
		"char_id": NetworkManager.selected_char_id,
		"step": GameConfig.GHOST_RUN_STEP_SEC,
		"ys": _ghost_samples,
	})
	f.close()


## Aynı seed'li önceki deneme varsa gri, yarı saydam "Önceki sen" hayaletini kurar.
func _load_previous_run(world_seed: int) -> void:
	if _prev_run_node != null and is_instance_valid(_prev_run_node):
		_prev_run_node.queue_free()
	_prev_run_node = null
	_prev_run_ys = PackedFloat32Array()
	if NetworkManager.is_multiplayer_match or not FileAccess.file_exists(GameConfig.GHOST_RUN_PATH):
		return
	var f: FileAccess = FileAccess.open(GameConfig.GHOST_RUN_PATH, FileAccess.READ)
	if f == null:
		return
	var data: Variant = f.get_var(false)
	f.close()
	if not (data is Dictionary):
		return
	var d: Dictionary = data as Dictionary
	if int(d.get("seed", 0)) != world_seed or not (d.get("ys") is PackedFloat32Array):
		return
	_prev_run_ys = d["ys"] as PackedFloat32Array
	if _prev_run_ys.size() > GameConfig.GHOST_RUN_MAX_SAMPLES:
		_prev_run_ys = _prev_run_ys.slice(0, GameConfig.GHOST_RUN_MAX_SAMPLES)
	var cid: String = str(d.get("char_id", "klasik"))
	var cdata: Dictionary = CharacterData.get_character(cid)
	var ghost: Node2D = Node2D.new()
	ghost.name = "PreviousRunGhost"
	ghost.z_index = 4
	ghost.position = Vector2(GameConfig.PLAYER_X, GameConfig.PLAYER_START_Y)
	var sp: Sprite2D = Sprite2D.new()
	sp.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	var tex_sz: Vector2 = sp.texture.get_size() if sp.texture != null else Vector2(128.0, 128.0)
	var norm: float = 128.0 / maxf(maxf(tex_sz.x, tex_sz.y), 1.0)
	sp.scale = Vector2.ONE * norm * GameConfig.PLAYER_VISUAL_SCALE
	sp.modulate = Color(0.78, 0.78, 0.78, GameConfig.GHOST_RUN_ALPHA)
	ghost.add_child(sp)
	var lbl: Label = Label.new()
	lbl.text = "Önceki sen"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(180.0, 28.0)
	lbl.position = Vector2(-90.0, -92.0)
	lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	lbl.add_theme_constant_override("outline_size", 5)
	ghost.add_child(lbl)
	players_layer.add_child(ghost)
	_prev_run_node = ghost


func _update_previous_run(delta: float) -> void:
	_sample_current_run(delta)
	if _prev_run_node == null or not is_instance_valid(_prev_run_node) or _prev_run_ys.is_empty():
		return
	var f_idx: float = match_time / GameConfig.GHOST_RUN_STEP_SEC
	var i: int = int(f_idx)
	if i >= _prev_run_ys.size() - 1:
		# Önceki deneme burada bitti: hayalet düşüp solar
		_prev_run_node.position.y += 420.0 * delta
		_prev_run_node.rotation += 6.0 * delta
		_prev_run_node.modulate.a = maxf(_prev_run_node.modulate.a - delta * 0.8, 0.0)
		if _prev_run_node.modulate.a <= 0.0:
			_prev_run_node.queue_free()
			_prev_run_node = null
		return
	var y0: float = _prev_run_ys[i]
	var y1: float = _prev_run_ys[i + 1]
	var new_y: float = lerpf(y0, y1, f_idx - float(i))
	_prev_run_node.rotation = clampf((new_y - _prev_run_node.position.y) * 0.02, -0.4, 0.5)
	_prev_run_node.position.y = new_y


# ---------------------------------------------------------------------------
# 3+ bot/oyuncu: isim etiketleri üst üste binmesin
# ---------------------------------------------------------------------------

## Görünen isim etiketlerini dikeyde sıralar; çakışanları yukarı doğru kaydırır.
func _declutter_name_labels(delta: float) -> void:
	if not NetworkManager.is_multiplayer_match:
		return
	var rows: Array[Array] = []
	for p_v: Variant in players_by_id.values():
		var p: Area2D = p_v as Area2D
		if not is_instance_valid(p) or not p.name_label.visible:
			continue
		# Etiketin ekrandaki doğal üst kenarı (gövde ölçeği hesaba katılır)
		rows.append([p.position.y + float(p.get("_name_base_y")) * p.scale.y, p])
	if rows.is_empty():
		return
	# Alttan yukarı: her etiket bir alttakinin en az GAP üstünde olsun
	rows.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) > float(b[0]))
	var prev_top: float = INF
	for row: Array in rows:
		var p: Area2D = row[1] as Area2D
		var natural: float = float(row[0])
		var placed: float = minf(natural, prev_top - GameConfig.NAME_LABEL_STACK_GAP)
		p.set_name_shift((placed - natural) / maxf(p.scale.y, 0.1), delta)
		prev_top = placed


## Ölüm Karesi: yerel böceğin görünür alandaki konumu (0..1).
func _local_focus_ratio() -> Vector2:
	if local_player == null or not is_instance_valid(local_player):
		return Vector2(0.5, 0.5)
	var vis: Vector2 = get_viewport().get_visible_rect().size
	var pos: Vector2 = local_player.get_global_transform_with_canvas().origin
	return Vector2(pos.x / maxf(vis.x, 1.0), pos.y / maxf(vis.y, 1.0))

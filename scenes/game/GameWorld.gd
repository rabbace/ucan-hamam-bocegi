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

var active_slippers: Array[Node2D] = []
var active_powerups: Array[Node2D] = []
var active_warnings: Array[Node2D] = []
var active_missiles: Array[Area2D] = []
var _pending_ghost_slippers: Array[Dictionary] = []
var _active_ghost_slippers: Array[Area2D] = []
var players_by_id: Dictionary = {} # peer_id -> Player
var local_player: Area2D = null

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

	hud.retry_requested.connect(_on_retry_requested)
	hud.menu_requested.connect(_on_menu_requested)
	hud.replay_match_requested.connect(_on_replay_match_requested)
	hud.return_lobby_requested.connect(_on_return_lobby_requested)
	hud.powerup_slot_pressed.connect(_on_powerup_slot_pressed)
	hud.quick_chat_sent.connect(func(text: String) -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.send_quick_chat.rpc_id(1, text)
	)
	hud.ghost_slipper_requested.connect(func(y: float) -> void:
		if NetworkManager.is_multiplayer_match:
			NetworkManager.throw_ghost_slipper.rpc_id(1, y, match_time)
	)
	hud.taunt_target_chosen.connect(_on_taunt_target_chosen)
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
	_spawn_players()

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
	else:
		_run_countdown()


func _spawn_players() -> void:
	for child: Node in players_layer.get_children():
		child.queue_free()
	players_by_id.clear()
	local_player = null

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
			p.name = str(pid)
			players_layer.add_child(p)
			p.configure_network(pid, str(pdata["name"]), str(pdata["char_id"]))
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
	for p: Area2D in players_by_id.values():
		if is_instance_valid(p):
			p.start_flying()


func _process(delta: float) -> void:
	_update_screen_shake(delta)
	if not match_active or match_ended:
		return

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
				var tint: Color = GameConfig.LEVEL_BG_TINTS[(current_level - 1) % GameConfig.LEVEL_BG_TINTS.size()]
				var bg_tw: Tween = create_tween().set_parallel(true)
				bg_tw.tween_property(bg_a, "modulate", tint, 0.8)
				bg_tw.tween_property(bg_b, "modulate", tint, 0.8)
			hud.set_level_progress(current_level, passed_pairs)

			if local_player != null and local_player.state == local_player.State.ACTIVE:
				var is_close: bool = obs.is_close_scare(local_player.position.y, GameConfig.PLAYER_HITBOX_RADIUS)
				obs.trigger_scare(is_close)
				if is_close:
					combo_count += 1
					if local_player.char_id == "halaybasi" and combo_count % 5 == 0:
						local_player.reduce_cooldowns(2.0)
					var close_sfx: String = "res://assets/sounds/lululu.wav" if (_shake_rng.randi() % 2 == 0) else "res://assets/sounds/agucuk.wav"
					AudioManager.play_sfx(close_sfx)
					var combo_title: String = GameConfig.get_combo_title(combo_count)
					if not combo_title.is_empty():
						local_player.show_combo_title("x%d %s" % [combo_count, combo_title])
				else:
					combo_count = 0
				score += (2 if is_close else 1)
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
	combo_count = 0
	_shake_remaining = GameConfig.DEATH_SHAKE_DURATION
	AudioManager.play_death_music(true)
	hud.play_bw_death_effect()
	hud.show_first_time_tip("tip_death", "İlk kez elendin! İstersen tekrar dene ya da arkadaşlarını izle.")
	if NetworkManager.is_multiplayer_match:
		hud.set_spectator_mode(true)
		var counts: Vector2i = NetworkManager.get_alive_counts()
		hud.set_alive_count(counts.x, counts.y)
	else:
		match_active = false
		var earned: int = maxi(passed_pairs + score, 1)
		if NetworkManager.selected_char_id == "emlakci":
			earned = int(ceilf(float(earned) * 1.2))
		Monetization.add_kirinti(earned)
		Monetization.record_quest_progress(passed_pairs, combo_count)
		Monetization.consume_trial()
		await get_tree().create_timer(GameConfig.DEATH_PANEL_DELAY).timeout
		hud.show_death_panel(score, NetworkManager.selected_char_id, cause)


func _spawn_upcoming_powerups(current_dist: float) -> void:
	var total: int = timeline.powerups.size()
	while next_powerup_idx < total:
		var data: Dictionary = timeline.powerups[next_powerup_idx]
		var box_dist: float = float(data["distance"])
		var screen_x: float = GameConfig.PLAYER_X + (box_dist - current_dist)
		if screen_x > GameConfig.VIEWPORT_WIDTH + GameConfig.SPAWN_AHEAD_PX:
			break
		var box: Node2D = _create_powerup_box_node(data)
		box.position = Vector2(screen_x, float(data["y"]))
		obstacle_layer.add_child(box)
		active_powerups.append(box)
		next_powerup_idx += 1


func _create_powerup_box_node(data: Dictionary) -> Node2D:
	var item_id: String = str(data["item_id"])
	var def: Dictionary = GameConfig.POWERUP_DEFS.get(item_id, {}) as Dictionary
	var box: Node2D = Node2D.new()
	box.set_meta("world_distance", float(data["distance"]))
	box.set_meta("item_id", item_id)
	box.set_meta("magnet_offset", Vector2.ZERO)

	var icon_path: String = str(def.get("icon_path", ""))
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		var sp: Sprite2D = Sprite2D.new()
		sp.texture = load(icon_path) as Texture2D
		box.add_child(sp)
	else:
		var col: Color = def.get("color", GameConfig.COLOR_PEACH) as Color
		var bg: ColorRect = ColorRect.new()
		bg.color = Color(0.95, 0.88, 0.76, 0.95)
		bg.size = Vector2(56.0, 56.0)
		bg.position = Vector2(-28.0, -28.0)
		box.add_child(bg)

		var badge: ColorRect = ColorRect.new()
		badge.color = col
		badge.size = Vector2(44.0, 44.0)
		badge.position = Vector2(-22.0, -22.0)
		box.add_child(badge)

		var lbl: Label = Label.new()
		lbl.text = str(def.get("letter", "?"))
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size = Vector2(44.0, 44.0)
		lbl.position = Vector2(-22.0, -22.0)
		lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
		lbl.add_theme_font_size_override("font_size", 24)
		lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
		box.add_child(lbl)
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
	hud.consume_powerup_at(slot_idx)


func _on_taunt_target_chosen(slot_idx: int, target_id: int) -> void:
	var item_id: String = hud.get_powerup_at(slot_idx)
	if item_id.is_empty():
		return
	NetworkManager.send_taunt_item.rpc_id(1, target_id, item_id)
	NetworkManager.show_item_fx.rpc("taunt")
	hud.consume_powerup_at(slot_idx)


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
	elif item_id == "taunt":
		p.speech_bubble.show_text("Özür dilerim pıttığım", 1.8)
		if ResourceLoader.exists("res://assets/sounds/ozur_dilerim.ogg"):
			AudioManager.play_sfx("res://assets/sounds/ozur_dilerim.ogg")


func _on_taunt_applied(sender_id: int, target_id: int, item_id: String) -> void:
	var sender_name: String = str(NetworkManager.players.get(sender_id, {}).get("name", "Böcek"))
	var target_name: String = str(NetworkManager.players.get(target_id, {}).get("name", "Böcek"))
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
	warn.position = Vector2(GameConfig.VIEWPORT_WIDTH - 48.0, y)
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
	area.position = Vector2(GameConfig.VIEWPORT_WIDTH + 60.0, y)
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
			if not p.is_local_player:
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


func _on_results_ready(results: Array) -> void:
	match_ended = true
	match_active = false
	_victory_lap_remaining = -1.0
	AudioManager.stop_death_music()
	_tween_dark_modulate(Color.WHITE)
	var local_uid: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	for r_v: Variant in results:
		var r: Dictionary = r_v as Dictionary
		if int(r.get("peer_id", 0)) == local_uid:
			var rk: int = int(r.get("rank", 5))
			var rank_k: int = GameConfig.KIRINTI_RANK_BONUS[mini(rk - 1, GameConfig.KIRINTI_RANK_BONUS.size() - 1)]
			var tot_k: int = rank_k + score
			if NetworkManager.selected_char_id == "emlakci":
				tot_k = int(ceilf(float(tot_k) * 1.2))
			Monetization.add_kirinti(tot_k)
			break
	Monetization.record_quest_progress(passed_pairs, combo_count)
	Monetization.consume_trial()
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
	hud.show_winner_panel(title_text, score, multiplayer.is_server())


func _on_retry_requested() -> void:
	NetworkManager.prepare_single_player_seed()
	get_tree().reload_current_scene()


func _on_menu_requested() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_replay_match_requested() -> void:
	if NetworkManager.is_dedicated_mode:
		NetworkManager.request_start_match.rpc_id(1)
	else:
		NetworkManager.host_start_match()


func _on_return_lobby_requested() -> void:
	if NetworkManager.is_dedicated_mode:
		NetworkManager.request_return_lobby.rpc_id(1)
	else:
		NetworkManager.host_return_to_lobby()

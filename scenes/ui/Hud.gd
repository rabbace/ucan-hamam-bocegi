extends CanvasLayer

## Oyun içi HUD, geri sayım ve elenme paneli.

signal retry_requested
signal menu_requested
signal ability_pressed
signal ability2_pressed
signal replay_match_requested
signal return_lobby_requested
signal finish_victory_lap_requested
signal powerup_slot_pressed(slot_idx: int)
signal quick_chat_sent(text: String)
signal ghost_slipper_requested(y: float)
signal taunt_target_chosen(slot_idx: int, target_id: int)

const ABILITY_BTN_SCENE: PackedScene = preload("res://scenes/ui/AbilityButton.tscn")

var _ability2_btn: Control = null
var _skill_summary_card: PanelContainer = null
var _victory_banner: PanelContainer = null
var _finish_lap_btn: Button = null
var _results_panel: PanelContainer = null
var _bw_rect: ColorRect = null
var _tip_banner: PanelContainer = null
var _pause_btn: Button = null
var _pause_overlay: Control = null

var _talk_remaining: float = 0.0
var _talk_elapsed: float = 0.0
var _using_angry_portrait: bool = false

var _tray_items: Array[String] = []
var _tray_cooldown: float = 0.0
var _counter_strip: Panel = null
var _powerup_tray: Panel = null
var _slot_buttons: Array[Button] = []
var _slot_cd_overlays: Array[Panel] = []

const SLOT_THEMES: Array[Dictionary] = [
	{
		"bg": Color("#F5C9A6"),
		"hover": Color("#FBE0C9"),
		"pressed": Color("#E4B087"),
		"border": Color("#B36B42"),
	},
	{
		"bg": Color("#B8D4B0"),
		"hover": Color("#D0E6CA"),
		"pressed": Color("#9CBF92"),
		"border": Color("#587D4F"),
	},
	{
		"bg": Color("#B2C9DF"),
		"hover": Color("#CCE0F2"),
		"pressed": Color("#94B1CC"),
		"border": Color("#4E6E8E"),
	},
]
var _equip_toast: Label = null
var _level_badge: Label = null
var _level_progress_fill: ColorRect = null
var _level_banner: PanelContainer = null
var _level_banner_title: Label = null
var _level_banner_sub: Label = null
var _edge_glow: ColorRect = null

var _chat_btn: Button = null
var _chat_popup: VBoxContainer = null
var _chat_cooldown: float = 0.0
var _event_feed_vbox: VBoxContainer = null
var _target_box: HBoxContainer = null
var _pending_taunt_slot: int = -1
var _pending_taunt_timer: float = 0.0
var _taunt_warn_label: Label = null
var _immune_badge: Label = null
var _immune_remaining: float = 0.0
var _stink_overlay: ColorRect = null
var _aunt_panel: PanelContainer = null
var _ghost_strip: Panel = null
var _ghost_cd_remaining: float = 0.0
var _ghost_label: Label = null
var _awards_label: Label = null

@onready var score_label: Label = $ScoreLabel
@onready var countdown_label: Label = $CountdownLabel
@onready var seed_label: Label = $SeedLabel
@onready var char_badge_label: Label = $CharBadgeLabel
@onready var alive_label: Label = $AliveLabel
@onready var spectator_label: Label = $SpectatorLabel
@onready var phase_label: Label = $PhaseLabel
@onready var death_panel: PanelContainer = $DeathPanel
@onready var angry_char_rect: TextureRect = $DeathPanel/VBox/AngryCharRect
@onready var face_overlay: Control = $DeathPanel/VBox/AngryCharRect/FaceOverlay
@onready var death_title: Label = $DeathPanel/VBox/DeathTitle
@onready var final_score_label: Label = $DeathPanel/VBox/FinalScoreLabel
@onready var retry_button: Button = $DeathPanel/VBox/RetryButton
@onready var menu_button: Button = $DeathPanel/VBox/MenuButton
@onready var ability_button: Control = $AbilityButton
@onready var winner_panel: PanelContainer = $WinnerPanel
@onready var winner_title: Label = $WinnerPanel/VBox/WinnerTitle
@onready var winner_summary: Label = $WinnerPanel/VBox/WinnerSummary
@onready var wait_label: Label = $WinnerPanel/VBox/WaitLabel
@onready var replay_button: Button = $WinnerPanel/VBox/ReplayButton
@onready var lobby_button: Button = $WinnerPanel/VBox/LobbyButton


func _ready() -> void:
	_apply_styles()
	death_panel.visible = false
	winner_panel.visible = false
	countdown_label.visible = false
	phase_label.visible = false
	spectator_label.visible = false
	alive_label.visible = false
	ability_button.visible = false
	seed_label.visible = GameConfig.DEBUG
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	replay_button.pressed.connect(func() -> void: replay_match_requested.emit())
	lobby_button.pressed.connect(func() -> void: return_lobby_requested.emit())
	ability_button.ability_pressed.connect(func() -> void: ability_pressed.emit())
	face_overlay.draw.connect(_on_face_overlay_draw)
	_connect_button_tween(retry_button)
	_connect_button_tween(menu_button)
	_connect_button_tween(replay_button)
	_connect_button_tween(lobby_button)
	_setup_faz6_ui()
	_setup_faz7_ui()


## Skoru günceller ve artışta kısa pop animasyonu uygular.
func set_score(value: int) -> void:
	score_label.text = str(value)
	if value > 0:
		score_label.pivot_offset = score_label.size * 0.5
		score_label.scale = Vector2(1.28, 1.28)
		var tw: Tween = create_tween()
		tw.tween_property(score_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Çok oyunculu modda hayatta kalan sayacını günceller.
func set_alive_count(alive: int, total: int) -> void:
	alive_label.visible = NetworkManager.is_multiplayer_match
	alive_label.text = "Hayatta Kalan: %d / %d" % [alive, total]


## Çok oyunculu modda izleyici bandını açar veya kapatır.
func set_spectator_mode(active: bool) -> void:
	spectator_label.visible = active
	if _ghost_strip != null:
		_ghost_strip.visible = active and NetworkManager.is_multiplayer_match
	if active:
		ability_button.visible = false
		_counter_strip.visible = false


## Çok oyunculu maç sonu kazanan ve halay özet ekranını gösterir.
func show_winner_panel(title_text: String, scared_count: int, is_host: bool) -> void:
	spectator_label.visible = false
	ability_button.visible = false
	winner_title.text = title_text
	winner_summary.text = "Bugün %d kişiyi sandalyeye çıkardın!" % scared_count
	wait_label.visible = not is_host
	replay_button.visible = false
	lobby_button.visible = false
	winner_panel.visible = true

	if is_host:
		await get_tree().create_timer(GameConfig.WINNER_WAIT_BTN_SEC).timeout
		if is_instance_valid(winner_panel) and winner_panel.visible:
			replay_button.visible = true
			lobby_button.visible = true


## Debug modunda mevcut seed bilgisini köşede gösterir.
func set_seed_text(seed_val: int) -> void:
	seed_label.visible = GameConfig.DEBUG
	seed_label.text = "Seed: %d" % seed_val


## Oynanan oyuncu ve karakter adını köşede gösterir.
func set_character_badge(player_name: String, char_name: String) -> void:
	char_badge_label.text = "%s (%s)" % [player_name, char_name]


## Füze evresi başlangıç yazısını pop animasyonuyla gösterir.
func show_phase_banner(text: String) -> void:
	phase_label.text = text
	phase_label.visible = true
	phase_label.modulate.a = 1.0
	phase_label.pivot_offset = phase_label.size * 0.5
	phase_label.scale = Vector2(0.5, 0.5)
	var tw: Tween = create_tween()
	tw.tween_property(phase_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(GameConfig.DARK_BANNER_DURATION)
	tw.tween_property(phase_label, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		phase_label.visible = false
	)


## Böcek ilacı uyarısını üstte sabit ve okunaklı biçimde kısa süre gösterir.
func show_spray_warning() -> void:
	phase_label.text = "ÖHÖ ÖHÖ! BÖCEK İLACI!"
	phase_label.visible = true
	phase_label.modulate.a = 1.0
	phase_label.pivot_offset = phase_label.size * 0.5
	phase_label.scale = Vector2(0.8, 0.8)
	var tw: Tween = create_tween()
	tw.tween_property(phase_label, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.75)
	tw.tween_property(phase_label, "modulate:a", 0.0, 0.25)
	tw.tween_callback(func() -> void:
		phase_label.visible = false
	)


## Geri sayım metnini pop animasyonuyla gösterir.
func show_countdown(text: String) -> void:
	countdown_label.text = text
	countdown_label.visible = true
	countdown_label.pivot_offset = countdown_label.size * 0.5
	countdown_label.scale = Vector2(0.6, 0.6)
	var tw: Tween = create_tween()
	tw.tween_property(countdown_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Geri sayımı gizler.
func hide_countdown() -> void:
	countdown_label.visible = false


## Elenme panelini sinirli karakter, rastgele argo replik ve konuşma animasyonuyla açar.
func show_death_panel(final_score: int, char_id: String = "klasik", death_cause: String = "") -> void:
	ability_button.visible = false
	_counter_strip.visible = false
	var cdata: Dictionary = CharacterData.get_character(char_id)
	var angry_path: String = str(cdata.get("angry_path", ""))
	var front_path: String = str(cdata.get("front_path", ""))
	_using_angry_portrait = false
	if not angry_path.is_empty() and ResourceLoader.exists(angry_path):
		angry_char_rect.texture = AssetHelper.texture(angry_path, str(cdata["fallback_kind"]), Vector2i(256, 256))
		_using_angry_portrait = true
	elif not front_path.is_empty() and ResourceLoader.exists(front_path):
		angry_char_rect.texture = AssetHelper.texture(front_path, str(cdata["fallback_kind"]), Vector2i(256, 256))
	else:
		angry_char_rect.texture = AssetHelper.texture(
			str(cdata["sprite_path"]),
			str(cdata["fallback_kind"]),
			GameConfig.PLAYER_SPRITE_SIZE
		)
	angry_char_rect.modulate = Color(1.0, 0.90, 0.90, 1.0)
	angry_char_rect.pivot_offset = Vector2(170.0, 170.0)
	angry_char_rect.rotation = 0.0
	angry_char_rect.scale = Vector2.ONE

	_talk_remaining = 1.8
	_talk_elapsed = 0.0
	face_overlay.queue_redraw()

	var best: int = _load_best_score()
	var is_new_record: bool = final_score > best
	if is_new_record:
		best = final_score
		_save_best_score(best)

	var death_entry: Dictionary = CharacterData.get_random_death_entry(char_id)
	death_title.text = str(death_entry["text"])
	var cause_line: String = ""
	if not death_cause.is_empty():
		cause_line = "\n" + GameConfig.get_random_death_cause_line(death_cause, NetworkManager.local_player_name)
	var rec_line: String = "\nRekor: %d" % best
	if is_new_record and final_score > 0:
		rec_line += " — YENİ REKOR! Mahalle seni konuşuyor!"
	final_score_label.text = ("Bugün %d kişiyi sandalyeye çıkardın!" % final_score) + rec_line + cause_line
	death_panel.visible = true
	death_panel.pivot_offset = death_panel.size * 0.5
	death_panel.scale = Vector2(0.85, 0.85)

	var tw: Tween = create_tween()
	tw.tween_property(death_panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	AudioManager.play_sfx(str(death_entry["sound"]), 0.96, 1.05)


func _process(delta: float) -> void:
	if _tray_cooldown > 0.0:
		_tray_cooldown = maxf(_tray_cooldown - delta, 0.0)
		_refresh_tray_cooldown_visuals()
	if _chat_cooldown > 0.0:
		_chat_cooldown = maxf(_chat_cooldown - delta, 0.0)
		if _chat_btn != null:
			_chat_btn.disabled = _chat_cooldown > 0.0
	if _immune_remaining > 0.0:
		_immune_remaining = maxf(_immune_remaining - delta, 0.0)
		if _immune_badge != null:
			_immune_badge.visible = _immune_remaining > 0.0
	if _ghost_cd_remaining > 0.0:
		_ghost_cd_remaining = maxf(_ghost_cd_remaining - delta, 0.0)
		if _ghost_label != null:
			_ghost_label.text = "Bekle\n%ds" % ceili(_ghost_cd_remaining) if _ghost_cd_remaining > 0.0 else "Terlik\nAt!"
	if _pending_taunt_slot >= 0:
		_pending_taunt_timer -= delta
		if _pending_taunt_timer <= 0.0:
			var slot: int = _pending_taunt_slot
			_close_target_picker()
			var auto_target: int = _pick_leader_opponent()
			if auto_target > 0:
				taunt_target_chosen.emit(slot, auto_target)
	if not death_panel.visible:
		return
	_talk_elapsed += delta
	if _talk_remaining > 0.0:
		_talk_remaining = maxf(_talk_remaining - delta, 0.0)
		angry_char_rect.rotation = sin(_talk_elapsed * 22.0) * deg_to_rad(5.5)
		var bounce: float = 1.0 + absf(sin(_talk_elapsed * 16.0)) * 0.06
		angry_char_rect.scale = Vector2(bounce, 2.0 - bounce)
	else:
		angry_char_rect.rotation = lerpf(angry_char_rect.rotation, 0.0, clampf(delta * 10.0, 0.0, 1.0))
		angry_char_rect.scale = angry_char_rect.scale.lerp(Vector2.ONE, clampf(delta * 10.0, 0.0, 1.0))
	face_overlay.queue_redraw()


func _on_face_overlay_draw() -> void:
	if _using_angry_portrait:
		return
	var w: float = face_overlay.size.x
	var h: float = face_overlay.size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Çatık sinirli kaşlar (V biçiminde)
	var brow_y: float = h * 0.34 + sin(_talk_elapsed * 14.0) * (2.5 if _talk_remaining > 0.0 else 0.0)
	var brow_col: Color = GameConfig.COLOR_DARK_TEXT
	face_overlay.draw_line(Vector2(w * 0.33, brow_y - 6.0), Vector2(w * 0.47, brow_y + 7.0), brow_col, 6.0, true)
	face_overlay.draw_line(Vector2(w * 0.67, brow_y - 6.0), Vector2(w * 0.53, brow_y + 7.0), brow_col, 6.0, true)

	# Sağ üstte sinir işareti (çarpı/kıvılcım)
	var anger_c: Vector2 = Vector2(w * 0.80, h * 0.20)
	var r_col: Color = GameConfig.COLOR_WARN_RED
	face_overlay.draw_arc(anger_c - Vector2(8.0, 8.0), 7.0, 0.0, PI * 0.5, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(8.0, -8.0), 7.0, PI * 0.5, PI, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(8.0, 8.0), 7.0, PI, PI * 1.5, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(-8.0, 8.0), 7.0, PI * 1.5, TAU, 8, r_col, 3.0)

	# Konuşma sırasında açılıp kapanan ağız animasyonu
	if _talk_remaining > 0.0:
		var open_amt: float = (sin(_talk_elapsed * 26.0) + 1.0) * 0.5
		var mouth_h: float = lerpf(3.0, 14.0, open_amt)
		var mouth_center: Vector2 = Vector2(w * 0.5, h * 0.49)
		var pts: PackedVector2Array = PackedVector2Array([
			mouth_center + Vector2(-14.0, 0.0),
			mouth_center + Vector2(0.0, -mouth_h),
			mouth_center + Vector2(14.0, 0.0),
			mouth_center + Vector2(0.0, mouth_h),
		])
		face_overlay.draw_colored_polygon(pts, Color(0.22, 0.05, 0.05, 0.92))
		face_overlay.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), GameConfig.COLOR_DARK_TEXT, 2.5)


## Yetenek butonunun görünürlüğünü ayarlar.
func set_ability_visible(vis: bool) -> void:
	ability_button.visible = vis


## Yetenek bekleme göstergesini günceller.
func update_ability_cooldown(remaining: float, total: float) -> void:
	ability_button.set_cooldown(remaining, total)


## Yetenek aktif durumunu günceller.
func update_ability_active(active: bool) -> void:
	ability_button.set_active(active)


## Halay Başı yeteneğinde yalnızca sol ve sağ kenar şeritlerinde konfeti yağdırır.
func spawn_edge_confetti() -> void:
	var half_w: float = GameConfig.HALAY_CONFETTI_STRIP_WIDTH * 0.5
	var x_positions: Array[float] = [half_w, GameConfig.VIEWPORT_WIDTH - half_w]
	for x_pos: float in x_positions:
		var p: CPUParticles2D = CPUParticles2D.new()
		p.position = Vector2(x_pos, -10.0)
		p.emitting = true
		p.one_shot = true
		p.lifetime = GameConfig.HALAY_CONFETTI_DURATION
		p.explosiveness = 0.25
		p.amount = 24
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(half_w - 8.0, 10.0)
		p.direction = Vector2(0.0, 1.0)
		p.spread = 22.0
		p.gravity = Vector2(0.0, 420.0)
		p.initial_velocity_min = 180.0
		p.initial_velocity_max = 360.0
		p.angular_velocity_min = -180.0
		p.angular_velocity_max = 180.0
		p.scale_amount_min = 10.0
		p.scale_amount_max = 18.0
		p.color = GameConfig.COLOR_WARN_RED
		add_child(p)
		get_tree().create_timer(GameConfig.HALAY_CONFETTI_DURATION + 1.2).timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.queue_free()
		)


func _on_retry_pressed() -> void:
	retry_requested.emit()


func _on_menu_pressed() -> void:
	menu_requested.emit()


func _apply_styles() -> void:
	var font: Font = AssetHelper.get_ui_font()

	score_label.add_theme_font_override("font", font)
	score_label.add_theme_font_size_override("font_size", 64)
	score_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	score_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	score_label.add_theme_constant_override("outline_size", 8)

	countdown_label.add_theme_font_override("font", font)
	countdown_label.add_theme_font_size_override("font_size", 72)
	countdown_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	countdown_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	countdown_label.add_theme_constant_override("outline_size", 10)

	seed_label.add_theme_font_override("font", font)
	seed_label.add_theme_font_size_override("font_size", 20)
	seed_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	char_badge_label.add_theme_font_override("font", font)
	char_badge_label.add_theme_font_size_override("font_size", 22)
	char_badge_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	char_badge_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	char_badge_label.add_theme_constant_override("outline_size", 5)

	phase_label.add_theme_font_override("font", font)
	phase_label.add_theme_font_size_override("font_size", 46)
	phase_label.add_theme_color_override("font_color", GameConfig.COLOR_PEACH)
	phase_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	phase_label.add_theme_constant_override("outline_size", 8)

	ComicUiHelper.style_bitten_panel(death_panel, GameConfig.COLOR_CREAM, 21, 28)

	death_title.add_theme_font_override("font", font)
	death_title.add_theme_font_size_override("font_size", 40)
	death_title.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)

	final_score_label.add_theme_font_override("font", font)
	final_score_label.add_theme_font_size_override("font_size", GameConfig.UI_FONT_BODY)
	final_score_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	ComicUiHelper.style_bitten_button(retry_button, GameConfig.COLOR_SAGE, font, GameConfig.UI_FONT_BODY, 31)
	ComicUiHelper.style_bitten_button(menu_button, GameConfig.COLOR_PEACH, font, GameConfig.UI_FONT_BODY, 32)
	ComicUiHelper.style_bitten_button(replay_button, GameConfig.COLOR_SAGE, font, GameConfig.UI_FONT_BODY, 33)
	ComicUiHelper.style_bitten_button(lobby_button, GameConfig.COLOR_PEACH, font, GameConfig.UI_FONT_BODY, 34)

	ComicUiHelper.style_bitten_panel(winner_panel, GameConfig.COLOR_CREAM, 22, 28)
	winner_title.add_theme_font_override("font", font)
	winner_title.add_theme_font_size_override("font_size", 44)
	winner_title.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	winner_summary.add_theme_font_override("font", font)
	winner_summary.add_theme_font_size_override("font_size", 26)
	winner_summary.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	wait_label.add_theme_font_override("font", font)
	wait_label.add_theme_font_size_override("font_size", 22)
	wait_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)

	alive_label.add_theme_font_override("font", font)
	alive_label.add_theme_font_size_override("font_size", 24)
	alive_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	alive_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	alive_label.add_theme_constant_override("outline_size", 5)

	spectator_label.add_theme_font_override("font", font)
	spectator_label.add_theme_font_size_override("font_size", 26)
	spectator_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	spectator_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	spectator_label.add_theme_constant_override("outline_size", 6)


func _style_button(btn: Button, bg: Color, font: Font) -> void:
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", GameConfig.UI_FONT_BODY)
	btn.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = GameConfig.COLOR_DARK_TEXT
	normal.set_border_width_all(GameConfig.UI_BORDER_WIDTH)
	normal.set_corner_radius_all(GameConfig.UI_CORNER_RADIUS)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.15)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0.0, 3.0)
	normal.set_content_margin_all(14)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.08)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)


func _connect_button_tween(btn: Button) -> void:
	btn.button_down.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
		var tw: Tween = create_tween()
		tw.tween_property(btn, "scale", Vector2(GameConfig.BUTTON_PRESS_SCALE, GameConfig.BUTTON_PRESS_SCALE), GameConfig.BUTTON_PRESS_DURATION)
	)
	btn.button_up.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
		var tw: Tween = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, GameConfig.BUTTON_PRESS_DURATION)
	)


func _setup_faz6_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()

	# Şeffaf alt kontrol şeridi (arka planı kapatmaz, boş yerlere dokununca zıplatır)
	_counter_strip = Panel.new()
	_counter_strip.name = "CounterStrip"
	_counter_strip.position = Vector2(0.0, GameConfig.FLOOR_Y)
	_counter_strip.size = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.COUNTER_STRIP_HEIGHT)
	_counter_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_strip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_counter_strip)
	move_child(_counter_strip, 0)

	# 3 yuvalı şeffaf/buzlu yuvarlak tepsi konteyneri (arka plan görünür)
	_powerup_tray = Panel.new()
	_powerup_tray.name = "PowerupTray"
	_powerup_tray.position = Vector2(16.0, 8.0)
	_powerup_tray.size = Vector2(268.0, 88.0)
	_powerup_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	var tray_style: StyleBoxFlat = StyleBoxFlat.new()
	tray_style.bg_color = Color(0.14, 0.10, 0.08, 0.36)
	tray_style.border_color = Color(1.0, 0.94, 0.84, 0.45)
	tray_style.set_border_width_all(2)
	tray_style.set_corner_radius_all(44)
	tray_style.shadow_color = Color(0.0, 0.0, 0.0, 0.18)
	tray_style.shadow_size = 4
	tray_style.shadow_offset = Vector2(0.0, 2.0)
	_powerup_tray.add_theme_stylebox_override("panel", tray_style)
	_counter_strip.add_child(_powerup_tray)

	# 3 yuvarlak güçlendirme butonu (her yuva 74x74, temaya uygun farklı renklerde)
	_slot_buttons.clear()
	_slot_cd_overlays.clear()
	var slot_radius: int = int(GameConfig.POWERUP_SLOT_SIZE * 0.5)
	for i: int in range(GameConfig.POWERUP_SLOTS):
		var theme_col: Dictionary = SLOT_THEMES[i % SLOT_THEMES.size()]
		var slot_btn: Button = Button.new()
		slot_btn.name = "PowerupSlot_%d" % i
		slot_btn.position = Vector2(11.0 + float(i) * 86.0, 7.0)
		slot_btn.size = Vector2(GameConfig.POWERUP_SLOT_SIZE, GameConfig.POWERUP_SLOT_SIZE)
		slot_btn.pivot_offset = slot_btn.size * 0.5
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS

		var sb_normal: StyleBoxFlat = _make_circle_style(
			theme_col["bg"] as Color,
			theme_col["border"] as Color,
			slot_radius,
			2
		)
		var sb_hover: StyleBoxFlat = _make_circle_style(
			theme_col["hover"] as Color,
			theme_col["border"] as Color,
			slot_radius,
			3
		)
		var sb_pressed: StyleBoxFlat = _make_circle_style(
			theme_col["pressed"] as Color,
			GameConfig.COLOR_DARK_TEXT,
			slot_radius,
			1
		)
		slot_btn.add_theme_stylebox_override("normal", sb_normal)
		slot_btn.add_theme_stylebox_override("hover", sb_hover)
		slot_btn.add_theme_stylebox_override("pressed", sb_pressed)
		slot_btn.add_theme_stylebox_override("hover_pressed", sb_pressed)
		slot_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		slot_btn.add_theme_font_override("font", font)
		slot_btn.add_theme_font_size_override("font_size", 20)
		var slot_txt_col: Color = Color(0.24, 0.21, 0.19, 0.65)
		slot_btn.add_theme_color_override("font_color", slot_txt_col)
		slot_btn.add_theme_color_override("font_hover_color", slot_txt_col)
		slot_btn.add_theme_color_override("font_pressed_color", slot_txt_col)
		slot_btn.add_theme_color_override("font_hover_pressed_color", slot_txt_col)
		slot_btn.add_theme_color_override("font_focus_color", slot_txt_col)
		var captured_i: int = i
		slot_btn.pressed.connect(func() -> void:
			_on_powerup_slot_clicked(captured_i)
		)
		_powerup_tray.add_child(slot_btn)
		_slot_buttons.append(slot_btn)

		var cd_panel: Panel = Panel.new()
		cd_panel.size = slot_btn.size
		cd_panel.visible = false
		cd_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cd_sb: StyleBoxFlat = StyleBoxFlat.new()
		cd_sb.bg_color = Color(0.18, 0.16, 0.14, 0.52)
		cd_sb.set_corner_radius_all(slot_radius)
		cd_panel.add_theme_stylebox_override("panel", cd_sb)
		slot_btn.add_child(cd_panel)
		_slot_cd_overlays.append(cd_panel)

	# YETENEK butonunu alt şeridin sağına yerleştir
	ability_button.reparent(_counter_strip)
	ability_button.position = Vector2(GameConfig.VIEWPORT_WIDTH - GameConfig.ABILITY_BTN_SIZE - 18.0, 5.0)

	# 8.3: İkinci aktif yetenek (Küçülme) butonu — Aktif 1'in solunda (78x78)
	_ability2_btn = ABILITY_BTN_SCENE.instantiate() as Control
	_ability2_btn.name = "Ability2Button"
	_ability2_btn.size = Vector2(78.0, 78.0)
	_ability2_btn.custom_minimum_size = Vector2(78.0, 78.0)
	_ability2_btn.position = Vector2(ability_button.position.x - 88.0, 13.0)
	_ability2_btn.ability_pressed.connect(func() -> void:
		ability2_pressed.emit()
	)
	_counter_strip.add_child(_ability2_btn)
	var a2_lbl: Label = _ability2_btn.get_node_or_null("Label") as Label
	if a2_lbl != null:
		a2_lbl.text = "KÜÇÜL"
		a2_lbl.add_theme_font_size_override("font_size", 14)

	_setup_faz8_ui(font)

	_equip_toast = Label.new()
	_equip_toast.text = "Kuşanıldı!"
	_equip_toast.position = Vector2(22.0, -34.0)
	_equip_toast.visible = false
	_equip_toast.add_theme_font_override("font", font)
	_equip_toast.add_theme_font_size_override("font_size", 22)
	_equip_toast.add_theme_color_override("font_color", Color("#FFF3B0"))
	_equip_toast.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	_equip_toast.add_theme_constant_override("outline_size", 5)
	_counter_strip.add_child(_equip_toast)

	# Sol üst seviye rozeti + ince ilerleme çubuğu
	_level_badge = Label.new()
	_level_badge.text = "Sv 1"
	_level_badge.position = Vector2(24.0, 62.0)
	_level_badge.add_theme_font_override("font", font)
	_level_badge.add_theme_font_size_override("font_size", 24)
	_level_badge.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_level_badge.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	_level_badge.add_theme_constant_override("outline_size", 4)
	add_child(_level_badge)

	var prog_bg: ColorRect = ColorRect.new()
	prog_bg.color = Color(0.24, 0.20, 0.18, 0.25)
	prog_bg.position = Vector2(24.0, 96.0)
	prog_bg.size = Vector2(120.0, 10.0)
	add_child(prog_bg)

	_level_progress_fill = ColorRect.new()
	_level_progress_fill.color = GameConfig.COLOR_SAGE
	_level_progress_fill.size = Vector2(0.0, 10.0)
	prog_bg.add_child(_level_progress_fill)

	# Seviye atlama şeridi (üstten kayar)
	_level_banner = PanelContainer.new()
	_level_banner.position = Vector2(60.0, -140.0)
	_level_banner.size = Vector2(600.0, 108.0)
	_level_banner.visible = false
	var lb_style: StyleBoxFlat = StyleBoxFlat.new()
	lb_style.bg_color = GameConfig.COLOR_PEACH
	lb_style.border_color = GameConfig.COLOR_DARK_TEXT
	lb_style.set_border_width_all(3)
	lb_style.set_corner_radius_all(18)
	_level_banner.add_theme_stylebox_override("panel", lb_style)
	var lb_vbox: VBoxContainer = VBoxContainer.new()
	lb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_level_banner.add_child(lb_vbox)

	_level_banner_title = Label.new()
	_level_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_banner_title.add_theme_font_override("font", font)
	_level_banner_title.add_theme_font_size_override("font_size", 28)
	_level_banner_title.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	lb_vbox.add_child(_level_banner_title)

	_level_banner_sub = Label.new()
	_level_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_banner_sub.add_theme_font_override("font", font)
	_level_banner_sub.add_theme_font_size_override("font_size", 20)
	_level_banner_sub.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	lb_vbox.add_child(_level_banner_sub)
	add_child(_level_banner)

	# Ekran kenarı parlama efekti (0.3 sn)
	_edge_glow = ColorRect.new()
	_edge_glow.color = Color(1.0, 0.94, 0.72, 0.0)
	_edge_glow.size = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.VIEWPORT_HEIGHT)
	_edge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge_glow)

	_refresh_tray_visuals()


func _unhandled_input(event: InputEvent) -> void:
	if death_panel.visible or winner_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_ev: InputEventKey = event as InputEventKey
		if key_ev.keycode == KEY_1:
			_on_powerup_slot_clicked(0)
		elif key_ev.keycode == KEY_2:
			_on_powerup_slot_clicked(1)
		elif key_ev.keycode == KEY_3:
			_on_powerup_slot_clicked(2)


func _make_circle_style(bg_col: Color, border_col: Color, radius: int, shadow_sz: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0.24, 0.21, 0.19, 0.22)
	sb.shadow_size = shadow_sz
	sb.shadow_offset = Vector2(0.0, 2.0)
	return sb


func _on_powerup_slot_clicked(slot_idx: int) -> void:
	if _tray_cooldown > 0.0 or slot_idx < 0 or slot_idx >= _tray_items.size():
		return
	var btn: Button = _slot_buttons[slot_idx]
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(0.88, 0.88)
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	powerup_slot_pressed.emit(slot_idx)


## Tepsiye yeni güçlendirme ekler (3 doluysa en soldakini kaydırarak atar).
func add_powerup(item_id: String) -> void:
	if _tray_items.size() >= GameConfig.POWERUP_SLOTS:
		_tray_items.remove_at(0)
	_tray_items.append(item_id)
	_refresh_tray_visuals()
	var target_idx: int = _tray_items.size() - 1
	var btn: Button = _slot_buttons[target_idx]
	btn.pivot_offset = btn.size * 0.5
	btn.scale = Vector2(1.22, 1.22)
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_equip_toast.visible = true
	_equip_toast.modulate.a = 1.0
	_equip_toast.position = Vector2(_powerup_tray.position.x + btn.position.x, -34.0)
	var t_tw: Tween = create_tween()
	t_tw.tween_property(_equip_toast, "position:y", -58.0, 0.65)
	t_tw.parallel().tween_property(_equip_toast, "modulate:a", 0.0, 0.65)


func get_powerup_at(slot_idx: int) -> String:
	if slot_idx < 0 or slot_idx >= _tray_items.size():
		return ""
	return _tray_items[slot_idx]


func consume_powerup_at(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= _tray_items.size():
		return
	_tray_items.remove_at(slot_idx)
	_tray_cooldown = GameConfig.POWERUP_GLOBAL_COOLDOWN
	_refresh_tray_visuals()
	_refresh_tray_cooldown_visuals()


func _refresh_tray_visuals() -> void:
	var font: Font = AssetHelper.get_ui_font()
	for i: int in range(_slot_buttons.size()):
		var btn: Button = _slot_buttons[i]
		for child: Node in btn.get_children():
			if child != _slot_cd_overlays[i]:
				child.queue_free()
		if i < _tray_items.size():
			var item_id: String = _tray_items[i]
			var def: Dictionary = GameConfig.get_item_def(item_id)
			btn.text = ""

			# Ortada küçük renkli yuvarlak ikon rozeti
			var icon_badge: Panel = Panel.new()
			icon_badge.size = Vector2(30.0, 30.0)
			icon_badge.position = Vector2((btn.size.x - 30.0) * 0.5, 10.0)
			icon_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var badge_sb: StyleBoxFlat = StyleBoxFlat.new()
			badge_sb.bg_color = def.get("color", GameConfig.COLOR_PEACH) as Color
			badge_sb.border_color = GameConfig.COLOR_DARK_TEXT
			badge_sb.set_border_width_all(2)
			badge_sb.set_corner_radius_all(15)
			icon_badge.add_theme_stylebox_override("panel", badge_sb)
			btn.add_child(icon_badge)

			var letter_lbl: Label = Label.new()
			letter_lbl.text = str(def.get("letter", "?"))
			letter_lbl.size = icon_badge.size
			letter_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			letter_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			letter_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			letter_lbl.add_theme_font_override("font", font)
			letter_lbl.add_theme_font_size_override("font_size", 15)
			letter_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
			icon_badge.add_child(letter_lbl)

			# Altta kısa isim
			var name_lbl: Label = Label.new()
			name_lbl.text = str(def.get("short_name", item_id))
			name_lbl.position = Vector2(2.0, 42.0)
			name_lbl.size = Vector2(btn.size.x - 4.0, 20.0)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_lbl.clip_text = true
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_lbl.add_theme_font_override("font", font)
			name_lbl.add_theme_font_size_override("font_size", 11)
			name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
			btn.add_child(name_lbl)

			# Sağ üstte küçük numara rozeti (1, 2, 3)
			var num_pill: Panel = Panel.new()
			num_pill.size = Vector2(18.0, 18.0)
			num_pill.position = Vector2(btn.size.x - 19.0, 1.0)
			num_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var num_sb: StyleBoxFlat = StyleBoxFlat.new()
			num_sb.bg_color = GameConfig.COLOR_DARK_TEXT
			num_sb.set_corner_radius_all(9)
			num_pill.add_theme_stylebox_override("panel", num_sb)
			btn.add_child(num_pill)

			var num_lbl: Label = Label.new()
			num_lbl.text = "%d" % (i + 1)
			num_lbl.size = num_pill.size
			num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			num_lbl.add_theme_font_override("font", font)
			num_lbl.add_theme_font_size_override("font_size", 10)
			num_lbl.add_theme_color_override("font_color", GameConfig.COLOR_CREAM)
			num_pill.add_child(num_lbl)
		else:
			btn.text = "%d" % (i + 1)


func _refresh_tray_cooldown_visuals() -> void:
	for i: int in range(_slot_cd_overlays.size()):
		var ov: Panel = _slot_cd_overlays[i]
		ov.visible = _tray_cooldown > 0.0 and i < _tray_items.size()


## Sol üst seviye rozetini ve ilerleme çubuğunu günceller.
func set_level_progress(level_num: int, passed_pairs: int) -> void:
	_level_badge.text = "Sv %d" % level_num
	var cur_cfg: Dictionary = GameConfig.get_level_config(level_num)
	var next_cfg: Dictionary = GameConfig.get_level_config(level_num + 1)
	var start_p: int = int(cur_cfg["start_pairs"])
	var end_p: int = int(next_cfg["start_pairs"])
	var span: int = maxi(end_p - start_p, 1)
	var ratio: float = clampf(float(passed_pairs - start_p) / float(span), 0.0, 1.0)
	_level_progress_fill.size.x = 120.0 * ratio


## Seviye atlama şeridini üstten kaydırır ve kenar parlaması oynatır.
func show_level_up_banner(level_num: int, level_name: String) -> void:
	_level_banner_title.text = "SEVİYE %d: %s!" % [level_num, level_name.to_upper()]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var sub_idx: int = rng.randi_range(0, GameConfig.LEVEL_SUBTITLES.size() - 1)
	_level_banner_sub.text = GameConfig.LEVEL_SUBTITLES[sub_idx]
	_level_banner.visible = true
	_level_banner.position.y = -130.0

	var tw: Tween = create_tween()
	tw.tween_property(_level_banner, "position:y", 118.0, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(2.0)
	tw.tween_property(_level_banner, "position:y", -140.0, 0.25)
	tw.tween_callback(func() -> void:
		_level_banner.visible = false
	)

	_edge_glow.color.a = 0.28
	var g_tw: Tween = create_tween()
	g_tw.tween_property(_edge_glow, "color:a", 0.0, 0.3)
	AudioManager.play_sfx("res://assets/sounds/seviye.ogg")


func _load_best_score() -> int:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(GameConfig.SETTINGS_PATH) != OK:
		return 0
	return int(cfg.get_value("records", "best_score", 0))


func _save_best_score(val: int) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("records", "best_score", val)
	cfg.save(GameConfig.SETTINGS_PATH)


func _setup_faz7_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()
	var is_mp: bool = NetworkManager.is_multiplayer_match

	# Laf atma butonu (sol üstte seviye rozetinin yanında)
	_chat_btn = Button.new()
	_chat_btn.text = "Laf"
	_chat_btn.position = Vector2(160.0, 62.0)
	_chat_btn.size = Vector2(72.0, 44.0)
	_chat_btn.visible = is_mp
	_chat_btn.focus_mode = Control.FOCUS_NONE
	_style_button(_chat_btn, GameConfig.COLOR_PEACH, font)
	_chat_btn.add_theme_font_size_override("font_size", 18)
	_chat_btn.pressed.connect(_toggle_chat_popup)
	add_child(_chat_btn)

	_chat_popup = VBoxContainer.new()
	_chat_popup.position = Vector2(24.0, 114.0)
	_chat_popup.visible = false
	_chat_popup.add_theme_constant_override("separation", 6)
	var lines: Array[String] = GameConfig.QUICK_CHAT_LINES.duplicate()
	var cdata: Dictionary = CharacterData.get_character(NetworkManager.selected_char_id)
	var c_line: String = str(cdata.get("taunt_line", ""))
	if not c_line.is_empty():
		lines.append(c_line)
	for line: String in lines:
		var b: Button = Button.new()
		b.text = line
		b.focus_mode = Control.FOCUS_NONE
		_style_button(b, GameConfig.COLOR_CREAM, font)
		b.add_theme_font_size_override("font_size", 18)
		var captured: String = line
		b.pressed.connect(func() -> void:
			_chat_popup.visible = false
			_chat_cooldown = GameConfig.QUICK_CHAT_COOLDOWN
			quick_chat_sent.emit(captured)
		)
		_chat_popup.add_child(b)
	add_child(_chat_popup)

	# Sol üst olay akışı (son 3 olay)
	_event_feed_vbox = VBoxContainer.new()
	_event_feed_vbox.position = Vector2(24.0, 118.0)
	_event_feed_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_feed_vbox.add_theme_constant_override("separation", 4)
	add_child(_event_feed_vbox)

	# Sataşma hedef seçici (tepsi üstünde)
	_target_box = HBoxContainer.new()
	_target_box.position = Vector2(24.0, GameConfig.FLOOR_Y - 76.0)
	_target_box.visible = false
	_target_box.add_theme_constant_override("separation", 10)
	add_child(_target_box)

	# Sataşma uyarı yazısı (0.6 sn)
	_taunt_warn_label = Label.new()
	_taunt_warn_label.position = Vector2(40.0, 260.0)
	_taunt_warn_label.size = Vector2(640.0, 64.0)
	_taunt_warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_taunt_warn_label.visible = false
	_taunt_warn_label.add_theme_font_override("font", font)
	_taunt_warn_label.add_theme_font_size_override("font_size", 28)
	_taunt_warn_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	_taunt_warn_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	_taunt_warn_label.add_theme_constant_override("outline_size", 6)
	add_child(_taunt_warn_label)

	# 4 sn bağışıklık rozeti
	_immune_badge = Label.new()
	_immune_badge.text = "Bağışık"
	_immune_badge.position = Vector2(24.0, GameConfig.FLOOR_Y - 40.0)
	_immune_badge.visible = false
	_immune_badge.add_theme_font_override("font", font)
	_immune_badge.add_theme_font_size_override("font_size", 20)
	_immune_badge.add_theme_color_override("font_color", GameConfig.COLOR_SAGE)
	_immune_badge.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	_immune_badge.add_theme_constant_override("outline_size", 4)
	add_child(_immune_badge)

	# Kirli çorap koku perdesi (en fazla %60 opak)
	_stink_overlay = ColorRect.new()
	_stink_overlay.color = Color(0.32, 0.56, 0.24, 0.58)
	_stink_overlay.size = Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.FLOOR_Y * 0.5)
	_stink_overlay.visible = false
	_stink_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stink_overlay)

	# Komşu teyze kenar paneli
	_aunt_panel = PanelContainer.new()
	_aunt_panel.position = Vector2(GameConfig.VIEWPORT_WIDTH, 340.0)
	_aunt_panel.size = Vector2(310.0, 120.0)
	_aunt_panel.visible = false
	_aunt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ap_sb: StyleBoxFlat = StyleBoxFlat.new()
	ap_sb.bg_color = GameConfig.COLOR_DUST_PINK
	ap_sb.border_color = GameConfig.COLOR_DARK_TEXT
	ap_sb.set_border_width_all(3)
	ap_sb.set_corner_radius_all(18)
	_aunt_panel.add_theme_stylebox_override("panel", ap_sb)
	var ap_lbl: Label = Label.new()
	ap_lbl.text = "Ayyy bu ne böcek!"
	ap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ap_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ap_lbl.add_theme_font_override("font", font)
	ap_lbl.add_theme_font_size_override("font_size", 24)
	ap_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_aunt_panel.add_child(ap_lbl)
	add_child(_aunt_panel)

	# Hayalet terlik sağ kenar şeridi (elenenler için)
	_ghost_strip = Panel.new()
	_ghost_strip.position = Vector2(GameConfig.VIEWPORT_WIDTH - 96.0, 160.0)
	_ghost_strip.size = Vector2(88.0, GameConfig.FLOOR_Y - 220.0)
	_ghost_strip.visible = false
	_ghost_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	var gs_sb: StyleBoxFlat = StyleBoxFlat.new()
	gs_sb.bg_color = Color(0.85, 0.38, 0.35, 0.55)
	gs_sb.border_color = GameConfig.COLOR_DARK_TEXT
	gs_sb.set_border_width_all(3)
	gs_sb.set_corner_radius_all(18)
	_ghost_strip.add_theme_stylebox_override("panel", gs_sb)
	_ghost_strip.gui_input.connect(_on_ghost_strip_input)
	_ghost_label = Label.new()
	_ghost_label.text = "Terlik\nAt!"
	_ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ghost_label.size = _ghost_strip.size
	_ghost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_label.add_theme_font_override("font", font)
	_ghost_label.add_theme_font_size_override("font_size", 20)
	_ghost_label.add_theme_color_override("font_color", Color.WHITE)
	_ghost_strip.add_child(_ghost_label)
	add_child(_ghost_strip)

	# Ödül kartları etiketi (WinnerPanel içinde)
	_awards_label = Label.new()
	_awards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_awards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_awards_label.visible = false
	_awards_label.add_theme_font_override("font", font)
	_awards_label.add_theme_font_size_override("font_size", 22)
	_awards_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	$WinnerPanel/VBox.add_child(_awards_label)
	$WinnerPanel/VBox.move_child(_awards_label, 2)


func _toggle_chat_popup() -> void:
	if _chat_cooldown > 0.0:
		return
	_chat_popup.visible = not _chat_popup.visible


## Sol üst olay akışına kısa süreli bir olay satırı ekler (en fazla 3 satır, 3 sn'de solar).
func push_event_feed(text: String) -> void:
	if _event_feed_vbox == null or text.is_empty():
		return
	while _event_feed_vbox.get_child_count() >= 3:
		var oldest: Node = _event_feed_vbox.get_child(0)
		oldest.queue_free()
	var lbl: Label = Label.new()
	lbl.text = GameConfig.censor(text)
	lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	lbl.add_theme_constant_override("outline_size", 4)
	_event_feed_vbox.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_interval(2.4)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.6)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


## Sataşma güçlendirmesi seçilince rakip hedef butonlarını açar (2 sn sonra lideri seçer).
func open_taunt_target_picker(slot_idx: int) -> void:
	if _target_box == null:
		return
	for ch: Node in _target_box.get_children():
		ch.queue_free()
	var my_id: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	var font: Font = AssetHelper.get_ui_font()
	var has_any: bool = false
	for pid_v: Variant in NetworkManager.players.keys():
		var pid: int = int(pid_v)
		if pid == my_id:
			continue
		var pdata: Dictionary = NetworkManager.players[pid] as Dictionary
		if not bool(pdata.get("is_alive", false)):
			continue
		has_any = true
		var immune: bool = NetworkManager.is_player_immune(pid)
		var btn: Button = Button.new()
		btn.text = str(pdata.get("name", "Böcek"))
		btn.disabled = immune
		btn.focus_mode = Control.FOCUS_NONE
		_style_button(btn, GameConfig.COLOR_DEAD_GRAY if immune else GameConfig.COLOR_PEACH, font)
		btn.add_theme_font_size_override("font_size", 18)
		var cap_pid: int = pid
		btn.pressed.connect(func() -> void:
			_close_target_picker()
			taunt_target_chosen.emit(slot_idx, cap_pid)
		)
		_target_box.add_child(btn)
	if not has_any:
		return
	_pending_taunt_slot = slot_idx
	_pending_taunt_timer = GameConfig.TAUNT_TARGET_TIMEOUT
	_target_box.visible = true


func _close_target_picker() -> void:
	_pending_taunt_slot = -1
	if _target_box != null:
		_target_box.visible = false


func _pick_leader_opponent() -> int:
	var my_id: int = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	var best_id: int = 0
	var best_score: int = -1
	for pid_v: Variant in NetworkManager.players.keys():
		var pid: int = int(pid_v)
		if pid == my_id:
			continue
		var pdata: Dictionary = NetworkManager.players[pid] as Dictionary
		if not bool(pdata.get("is_alive", false)):
			continue
		var sc: int = int(pdata.get("score", 0))
		if sc > best_score:
			best_score = sc
			best_id = pid
	return best_id


## Kurbanın ekranında sataşma uyarısı ve görsel etkileri gösterir.
func show_taunt_warning(sender_name: String, item_name: String) -> void:
	_taunt_warn_label.text = "%s SANA %s ATTI!" % [sender_name.to_upper(), item_name.to_upper()]
	_taunt_warn_label.visible = true
	_taunt_warn_label.modulate.a = 1.0
	AudioManager.play_sfx("res://assets/sounds/satasma_geldi.ogg")
	var tw: Tween = create_tween()
	tw.tween_interval(GameConfig.TAUNT_WARN_DELAY + 0.4)
	tw.tween_property(_taunt_warn_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		_taunt_warn_label.visible = false
	)


func activate_taunt_immunity() -> void:
	_immune_remaining = GameConfig.TAUNT_IMMUNITY_SEC


func show_dirty_sock_cloud(top_half: bool) -> void:
	_stink_overlay.position.y = 0.0 if top_half else GameConfig.FLOOR_Y * 0.5
	_stink_overlay.visible = true
	_stink_overlay.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_stink_overlay, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void:
		_stink_overlay.visible = false
	)


func show_aunt_popup() -> void:
	_aunt_panel.visible = true
	_aunt_panel.position.x = GameConfig.VIEWPORT_WIDTH
	AudioManager.play_sfx("res://assets/sounds/teyze_ayyy.ogg")
	var tw: Tween = create_tween()
	tw.tween_property(_aunt_panel, "position:x", GameConfig.VIEWPORT_WIDTH - 320.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(_aunt_panel, "position:x", GameConfig.VIEWPORT_WIDTH, 0.2)
	tw.tween_callback(func() -> void:
		_aunt_panel.visible = false
	)


func _on_ghost_strip_input(event: InputEvent) -> void:
	if _ghost_cd_remaining > 0.0:
		return
	var pressed_pos_y: float = -1.0
	if event is InputEventMouseButton and event.pressed:
		pressed_pos_y = _ghost_strip.position.y + (event as InputEventMouseButton).position.y
	elif event is InputEventScreenTouch and event.pressed:
		pressed_pos_y = _ghost_strip.position.y + (event as InputEventScreenTouch).position.y
	if pressed_pos_y > 0.0:
		_ghost_cd_remaining = GameConfig.GHOST_SLIPPER_COOLDOWN
		ghost_slipper_requested.emit(pressed_pos_y)


## Maç sonu ödül kartlarını WinnerPanel içinde gösterir.
func show_awards_summary(awards: Array) -> void:
	if _awards_label == null or awards.is_empty():
		return
	var lines: Array[String] = []
	for a: Variant in awards:
		var d: Dictionary = a as Dictionary
		lines.append("%s: %s" % [str(d.get("title", "")), str(d.get("name", ""))])
	_awards_label.text = "\n".join(lines)
	_awards_label.visible = true
	AudioManager.play_sfx("res://assets/sounds/odul.ogg")


func set_ability2_cooldown(remaining: float, total: float) -> void:
	if _ability2_btn != null:
		_ability2_btn.call("set_cooldown", remaining, total)


func set_ability2_active(active: bool) -> void:
	if _ability2_btn != null:
		_ability2_btn.call("set_active", active)


func _setup_faz8_ui(font: Font) -> void:
	if _ability2_btn != null:
		_ability2_btn.set("default_label_text", "KÜÇÜL")

	get_viewport().size_changed.connect(_relayout_hud)
	_relayout_hud()

	# 8.8: Siyah-beyaz ölüm efekti katmanı (CanvasLayer üzerinde)
	_bw_rect = ColorRect.new()
	_bw_rect.name = "BwDeathOverlay"
	_bw_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bw_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bw_rect.visible = false
	var sh: Shader = Shader.new()
	sh.code = "shader_type canvas_item;\nuniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;\nuniform float mix_amt : hint_range(0.0, 1.0) = 1.0;\nvoid fragment() {\n\tvec4 c = texture(screen_tex, SCREEN_UV);\n\tfloat g = dot(c.rgb, vec3(0.299, 0.587, 0.114));\n\tCOLOR = vec4(mix(c.rgb, vec3(g), mix_amt), c.a);\n}"
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = sh
	_bw_rect.material = mat
	add_child(_bw_rect)

	# 8.4: Tek oyunculuda duraklatma butonu ve menüsü
	if not NetworkManager.is_multiplayer_match:
		_pause_btn = Button.new()
		_pause_btn.name = "PauseButton"
		_pause_btn.text = "||"
		_pause_btn.position = Vector2(GameConfig.VIEWPORT_WIDTH - 76.0, 56.0)
		_pause_btn.size = Vector2(54.0, 54.0)
		ComicUiHelper.style_bitten_button(_pause_btn, GameConfig.COLOR_CREAM, font, 22, 601)
		_pause_btn.pressed.connect(_open_pause_menu)
		add_child(_pause_btn)

	# 8.5: İlk kez ipucu şeridi
	_tip_banner = PanelContainer.new()
	_tip_banner.position = Vector2(70.0, 118.0)
	_tip_banner.size = Vector2(580.0, 62.0)
	_tip_banner.visible = false
	_tip_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_tip_banner, Color("#FFF3B0"), 602, 10)
	var tip_lbl: Label = Label.new()
	tip_lbl.name = "TipLabel"
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.add_theme_font_override("font", font)
	tip_lbl.add_theme_font_size_override("font_size", 18)
	tip_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_tip_banner.add_child(tip_lbl)
	add_child(_tip_banner)


func _open_pause_menu() -> void:
	if death_panel.visible or _pause_overlay != null:
		return
	get_tree().paused = true
	var font: Font = AssetHelper.get_ui_font()
	_pause_overlay = Control.new()
	_pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_pause_overlay.z_index = 85

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	_pause_overlay.add_child(dim)

	var p: PanelContainer = PanelContainer.new()
	p.position = Vector2(110.0, 420.0)
	p.size = Vector2(500.0, 360.0)
	ComicUiHelper.style_bitten_panel(p, GameConfig.COLOR_CREAM, 610, 24)
	_pause_overlay.add_child(p)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	p.add_child(v)

	var ttl: Label = Label.new()
	ttl.text = "DURAKLATILDI"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", font)
	ttl.add_theme_font_size_override("font_size", 32)
	ttl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	v.add_child(ttl)

	var resume_btn: Button = Button.new()
	resume_btn.text = "Devam Et"
	resume_btn.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(resume_btn, Color("#8FD17C"), font, 24, 611)
	resume_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		if is_instance_valid(_pause_overlay):
			_pause_overlay.queue_free()
			_pause_overlay = null
	)
	v.add_child(resume_btn)

	var sk_btn: Button = Button.new()
	sk_btn.text = "Yetenekler"
	sk_btn.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(sk_btn, GameConfig.COLOR_DUST_PINK, font, 24, 612)
	sk_btn.pressed.connect(func() -> void:
		var sm: SkillsModal = SkillsModal.new()
		sm.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_overlay.add_child(sm)
		sm.open_for(NetworkManager.selected_char_id, false)
	)
	v.add_child(sk_btn)

	var m_btn: Button = Button.new()
	m_btn.text = "Ana Menü"
	m_btn.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(m_btn, GameConfig.COLOR_PEACH, font, 24, 613)
	m_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		menu_requested.emit()
	)
	v.add_child(m_btn)

	add_child(_pause_overlay)


## 8.4: Maç başı 3-2-1 geri sayımı sırasında 3 yetenek özet kartı gösterir.
func show_match_skill_summary(char_id: String) -> void:
	hide_match_skill_summary()
	var font: Font = AssetHelper.get_ui_font()
	var cdata: Dictionary = CharacterData.get_character(char_id)
	_skill_summary_card = PanelContainer.new()
	_skill_summary_card.position = Vector2(70.0, 740.0)
	_skill_summary_card.size = Vector2(580.0, 230.0)
	_skill_summary_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_skill_summary_card, GameConfig.COLOR_CREAM, 620, 16)
	add_child(_skill_summary_card)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	_skill_summary_card.add_child(v)

	var hdr: Label = Label.new()
	hdr.text = "%s — Yeteneklerin" % str(cdata["display_name"])
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_override("font", font)
	hdr.add_theme_font_size_override("font_size", 22)
	hdr.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	v.add_child(hdr)

	var skills: Array = cdata.get("skills", []) as Array
	for sk_v: Variant in skills:
		var sk: Dictionary = sk_v as Dictionary
		var sl: String = str(sk.get("slot", "pasif"))
		var key_hint: String = "Pasif" if sl == "pasif" else ("E / Sağ" if sl == "aktif1" else "Q / Küçül")
		var lbl: Label = Label.new()
		lbl.text = "[%s] %s: %s" % [key_hint, str(sk.get("name", "")), str(sk.get("desc", ""))]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.add_theme_font_override("font", font)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
		v.add_child(lbl)


func hide_match_skill_summary() -> void:
	if _skill_summary_card != null and is_instance_valid(_skill_summary_card):
		var card: PanelContainer = _skill_summary_card
		_skill_summary_card = null
		var tw: Tween = create_tween()
		tw.tween_property(card, "position:y", 1320.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if is_instance_valid(card):
				card.queue_free()
		)


## 8.5: Cihaz başına bir kez gösterilen 2 sn'lik ipucu.
func show_first_time_tip(tip_key: String, text: String) -> void:
	if _tip_banner == null or AudioManager.has_seen_tip(tip_key):
		return
	AudioManager.mark_tip_seen(tip_key)
	var lbl: Label = _tip_banner.get_node_or_null("TipLabel") as Label
	if lbl != null:
		lbl.text = GameConfig.censor(text)
	_tip_banner.visible = true
	_tip_banner.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_tip_banner, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_tip_banner):
			_tip_banner.visible = false
	)


## 8.8: Yerel ölümde 2.5 sn siyah-beyaz efekt (dünya akmaya devam eder).
func play_bw_death_effect() -> void:
	if _bw_rect == null:
		return
	_bw_rect.visible = true
	var mat: ShaderMaterial = _bw_rect.material as ShaderMaterial
	if mat != null:
		mat.set_shader_parameter("mix_amt", 1.0)
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	if mat != null:
		tw.tween_method(func(v: float) -> void:
			mat.set_shader_parameter("mix_amt", v)
		, 1.0, 0.0, 0.5)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_bw_rect):
			_bw_rect.visible = false
	)


## 8.1: Zafer turu üst bandı ve kazanan için "Bitir" butonu.
func show_victory_lap_banner(is_winner: bool, winner_name: String) -> void:
	var font: Font = AssetHelper.get_ui_font()
	if _victory_banner != null and is_instance_valid(_victory_banner):
		_victory_banner.queue_free()
	_victory_banner = PanelContainer.new()
	_victory_banner.position = Vector2(40.0, 128.0)
	_victory_banner.size = Vector2(640.0, 90.0)
	_victory_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_victory_banner, Color("#FFF3B0"), 630, 12)
	add_child(_victory_banner)

	var lbl: Label = Label.new()
	if is_winner:
		lbl.text = "KAZANDIN! Zafer turu — bakalım daha ne kadar gidebilirsin"
	else:
		lbl.text = "%s kazandı! Zafer turu izleniyor..." % winner_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_victory_banner.add_child(lbl)

	if is_winner:
		if _finish_lap_btn != null and is_instance_valid(_finish_lap_btn):
			_finish_lap_btn.queue_free()
		_finish_lap_btn = Button.new()
		_finish_lap_btn.text = "Bitir"
		_finish_lap_btn.position = Vector2(270.0, 228.0)
		_finish_lap_btn.size = Vector2(180.0, 56.0)
		ComicUiHelper.style_bitten_button(_finish_lap_btn, GameConfig.COLOR_PEACH, font, 22, 631)
		_finish_lap_btn.pressed.connect(func() -> void:
			finish_victory_lap_requested.emit()
		)
		add_child(_finish_lap_btn)


## 8.6: "MAHALLE SONUÇLARI" sıralama ekranını sondan başa animasyonla açar.
func show_results_ranking(results: Array, local_pid: int, is_host: bool) -> void:
	spectator_label.visible = false
	ability_button.visible = false
	if _ability2_btn != null:
		_ability2_btn.visible = false
	_counter_strip.visible = false
	if _ghost_strip != null:
		_ghost_strip.visible = false
	if _victory_banner != null and is_instance_valid(_victory_banner):
		_victory_banner.queue_free()
	if _finish_lap_btn != null and is_instance_valid(_finish_lap_btn):
		_finish_lap_btn.queue_free()

	if _results_panel != null and is_instance_valid(_results_panel):
		_results_panel.queue_free()

	var font: Font = AssetHelper.get_ui_font()
	_results_panel = PanelContainer.new()
	_results_panel.position = Vector2(40.0, 140.0)
	_results_panel.size = Vector2(640.0, 960.0)
	_results_panel.z_index = 80
	ComicUiHelper.style_bitten_panel(_results_panel, GameConfig.COLOR_CREAM, 640, 22)
	add_child(_results_panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 12)
	_results_panel.add_child(root_v)

	var title_lbl: Label = Label.new()
	title_lbl.text = "MAHALLE SONUÇLARI"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_override("font", font)
	title_lbl.add_theme_font_size_override("font_size", 34)
	title_lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	root_v.add_child(title_lbl)

	var rows_v: VBoxContainer = VBoxContainer.new()
	rows_v.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rows_v.add_theme_constant_override("separation", 10)
	root_v.add_child(rows_v)

	# Yer tutucu boş satırlar oluşturup sondan başa doğru doldur
	var row_slots: Array[Control] = []
	for _i: int in range(results.size()):
		var slot_box: Control = Control.new()
		slot_box.custom_minimum_size = Vector2(0.0, 108.0)
		rows_v.add_child(slot_box)
		row_slots.append(slot_box)

	var footer_h: HBoxContainer = HBoxContainer.new()
	footer_h.add_theme_constant_override("separation", 12)
	root_v.add_child(footer_h)

	var wait_lbl: Label = Label.new()
	wait_lbl.text = "Host'un kararı bekleniyor…"
	wait_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wait_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wait_lbl.visible = not is_host
	wait_lbl.add_theme_font_override("font", font)
	wait_lbl.add_theme_font_size_override("font_size", 22)
	wait_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	footer_h.add_child(wait_lbl)

	var share_btn: Button = Button.new()
	share_btn.text = "Paylaş"
	share_btn.custom_minimum_size = Vector2(120.0, 60.0)
	ComicUiHelper.style_bitten_button(share_btn, GameConfig.COLOR_DUST_BLUE, font, 22, 643)
	share_btn.pressed.connect(func() -> void:
		var top_scare: int = int((results[0] as Dictionary).get("score", 0)) if not results.is_empty() else 0
		var txt: String = GameConfig.SHARE_TEXT_KING.replace("{n}", str(top_scare)).replace("{link}", GameConfig.SHARE_SITE_URL)
		share_current_screen(txt, share_btn)
	)
	footer_h.add_child(share_btn)

	var rep_btn: Button = Button.new()
	rep_btn.text = "Tekrar Oyna"
	rep_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rep_btn.custom_minimum_size = Vector2(0.0, 60.0)
	rep_btn.visible = false
	ComicUiHelper.style_bitten_button(rep_btn, Color("#8FD17C"), font, 24, 641)
	rep_btn.pressed.connect(func() -> void:
		replay_match_requested.emit()
	)
	footer_h.add_child(rep_btn)

	var lob_btn: Button = Button.new()
	lob_btn.text = "Lobiye Dön"
	lob_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lob_btn.custom_minimum_size = Vector2(0.0, 60.0)
	lob_btn.visible = false
	ComicUiHelper.style_bitten_button(lob_btn, GameConfig.COLOR_PEACH, font, 24, 642)
	lob_btn.pressed.connect(func() -> void:
		return_lobby_requested.emit()
	)
	footer_h.add_child(lob_btn)

	# Sondan başa doğru 0.4 sn arayla kayarak gelsin
	for idx: int in range(results.size() - 1, -1, -1):
		var row_data: Dictionary = results[idx] as Dictionary
		var row_card: PanelContainer = _build_result_row(row_data, local_pid, font)
		row_card.position = Vector2(0.0, 60.0)
		row_card.modulate.a = 0.0
		row_slots[idx].add_child(row_card)
		var delay: float = float(results.size() - 1 - idx) * 0.4
		var rtw: Tween = create_tween()
		rtw.tween_interval(delay)
		rtw.tween_property(row_card, "position:y", 0.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		rtw.parallel().tween_property(row_card, "modulate:a", 1.0, 0.22)
		if idx == 0:
			rtw.tween_callback(func() -> void:
				var w_cid: String = str(row_data.get("char_id", "klasik"))
				AudioManager.play_win_sfx(w_cid)
			)

	if is_host:
		get_tree().create_timer(GameConfig.WINNER_WAIT_BTN_SEC).timeout.connect(func() -> void:
			if is_instance_valid(_results_panel) and _results_panel.visible:
				rep_btn.visible = true
				lob_btn.visible = true
		)


func _build_result_row(row: Dictionary, local_pid: int, font: Font) -> PanelContainer:
	var rank: int = int(row.get("rank", 1))
	var pid: int = int(row.get("peer_id", 0))
	var p_name: String = str(row.get("name", "Böcek"))
	if bool(row.get("left", false)):
		p_name += " (kaçtı)"
	var cid: String = str(row.get("char_id", "klasik"))
	var cdata: Dictionary = CharacterData.get_character(cid)
	var disp_t: float = float(row.get("display_time", 0.0))
	var mins: int = int(disp_t) / 60
	var secs: int = int(disp_t) % 60
	var scares: int = int(row.get("score", 0))
	var pts: int = int(row.get("points", 0))
	var badges: Array = row.get("badges", []) as Array

	var card: PanelContainer = PanelContainer.new()
	card.size = Vector2(580.0, 102.0)
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF8") if pid != local_pid else Color("#EAF5E4")
	sb.border_color = GameConfig.COLOR_WARN_RED if pid == local_pid else GameConfig.COLOR_DARK_TEXT
	sb.set_border_width_all(4 if pid == local_pid else 2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(10)
	card.add_theme_stylebox_override("panel", sb)

	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	card.add_child(h)

	var rank_col: Color = GameConfig.COLOR_DARK_TEXT
	if rank == 1:
		rank_col = Color("#D4A017")
	elif rank == 2:
		rank_col = Color("#8A959E")
	elif rank == 3:
		rank_col = Color("#B87333")

	var rank_lbl: Label = Label.new()
	rank_lbl.text = "%d." % rank
	rank_lbl.custom_minimum_size = Vector2(48.0, 0.0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.add_theme_font_override("font", font)
	rank_lbl.add_theme_font_size_override("font_size", 32)
	rank_lbl.add_theme_color_override("font_color", rank_col)
	h.add_child(rank_lbl)

	var icon_r: TextureRect = TextureRect.new()
	icon_r.custom_minimum_size = Vector2(60.0, 60.0)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_r.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	h.add_child(icon_r)

	var info_v: VBoxContainer = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.add_theme_constant_override("separation", 2)
	h.add_child(info_v)

	var name_lbl: Label = Label.new()
	name_lbl.text = "%s  (+%d Puan)" % [p_name, pts]
	name_lbl.add_theme_font_override("font", font)
	name_lbl.add_theme_font_size_override("font_size", 21)
	name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	info_v.add_child(name_lbl)

	var stats_lbl: Label = Label.new()
	stats_lbl.text = "Süre: %02d:%02d  ·  Ödü Kopan: %d" % [mins, secs, scares]
	stats_lbl.add_theme_font_override("font", font)
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	info_v.add_child(stats_lbl)

	if not badges.is_empty():
		var b_lbl: Label = Label.new()
		b_lbl.text = ", ".join(badges)
		b_lbl.add_theme_font_override("font", font)
		b_lbl.add_theme_font_size_override("font_size", 14)
		b_lbl.add_theme_color_override("font_color", Color("#9E4B3A"))
		info_v.add_child(b_lbl)

	return card


func _relayout_hud() -> void:
	if _counter_strip == null:
		return
	var vis_rect: Rect2 = get_viewport().get_visible_rect()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win_size: Vector2i = DisplayServer.window_get_size()
	var bottom_pad: float = 8.0
	if win_size.y > 0 and safe.size.y > 0:
		var raw_bot: float = float(win_size.y - (safe.position.y + safe.size.y))
		bottom_pad = maxf(8.0, raw_bot * (vis_rect.size.y / float(win_size.y)))

	_counter_strip.size.x = vis_rect.size.x
	_counter_strip.position = Vector2(0.0, vis_rect.size.y - GameConfig.COUNTER_STRIP_HEIGHT - bottom_pad)

	var sc: float = AudioManager.button_scale
	ability_button.scale = Vector2(sc, sc)
	if _ability2_btn != null:
		_ability2_btn.scale = Vector2(sc, sc)

	if AudioManager.left_handed:
		ability_button.position = Vector2(18.0, 5.0)
		if _ability2_btn != null:
			_ability2_btn.position = Vector2(18.0 + GameConfig.ABILITY_BTN_SIZE * sc + 10.0, 13.0)
		if _powerup_tray != null:
			_powerup_tray.position = Vector2(vis_rect.size.x - _powerup_tray.size.x - 16.0, 8.0)
	else:
		if _powerup_tray != null:
			_powerup_tray.position = Vector2(16.0, 8.0)
		ability_button.position = Vector2(vis_rect.size.x - GameConfig.ABILITY_BTN_SIZE * sc - 18.0, 5.0)
		if _ability2_btn != null:
			_ability2_btn.position = Vector2(ability_button.position.x - 88.0 * sc, 13.0)


func trigger_leftmost_powerup() -> void:
	_on_powerup_slot_clicked(0)


func show_swipe_arrow(from_pos: Vector2, to_pos: Vector2) -> void:
	var arrow: Line2D = Line2D.new()
	arrow.width = 7.0
	arrow.default_color = Color("#FFF3B0")
	arrow.add_point(from_pos)
	arrow.add_point(to_pos)
	add_child(arrow)
	var tw: Tween = create_tween()
	tw.tween_property(arrow, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func() -> void:
		if is_instance_valid(arrow):
			arrow.queue_free()
	)


func share_current_screen(share_text: String, btn: Button = null) -> void:
	var img: Image = get_viewport().get_texture().get_image()
	if img != null:
		img.save_png("user://paylas.png")
	if Engine.has_singleton("GodotShare"):
		var abs_path: String = ProjectSettings.globalize_path("user://paylas.png")
		Engine.get_singleton("GodotShare").call("sharePic", abs_path, "Skor Paylaş", "Uçan Hamam Böceği", share_text)
	else:
		DisplayServer.clipboard_set(share_text)
		if btn != null:
			btn.text = "Panoya kopyalandı"

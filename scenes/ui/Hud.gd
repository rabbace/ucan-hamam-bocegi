extends CanvasLayer

## Oyun içi HUD: üst çubuk, bildirim yığını, alt kontrol şeridi ve maç sonu panelleri.

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
## Faz 11.2: tek oyunculu "Aynı Parkur" ve çok oyunculu rövanş
signal same_course_requested
signal rematch_requested
signal rematch_force_requested

const ABILITY_BTN_SCENE: PackedScene = preload("res://scenes/ui/AbilityButton.tscn")
const PORTRAIT_SCENE: PackedScene = preload("res://scenes/ui/CharacterPortrait.tscn")

# Faz 10.3: sinirli büyük yüz
var _death_portrait: CharacterPortrait = null
var _death_share_btn: Button = null
var _death_char_id: String = "klasik"
var _death_line: String = ""
var _death_score: int = 0
var _pulse_tween: Tween = null
# Faz 11.2: rövanş arayüzü
var _same_course_btn: Button = null
var _rematch_btn: Button = null
var _rematch_label: Label = null
var _rematch_force_btn: Button = null
var _rematch_portrait: CharacterPortrait = null
var _rematch_pressed: bool = false
# Faz 11.3: Ölüm Karesi
var _death_card_data: Dictionary = {}
var _death_card_img: Image = null
var _death_card_btn: Button = null
var _death_card_busy: bool = false
# Faz 11.4: maç içi görev bildirimi
var _quest_notice: Label = null
var _quest_notice_tween: Tween = null
var _quest_notice_last_ms: int = -100000

# --- HUD yerleşim sabitleri (HUD'a özel; ileride GameConfig'e taşınabilir) ---
const TOP_BLOCK_MAX_W: float = 260.0      # sol üst blok (isim + seviye) en fazla genişlik
const LEVEL_BAR_W: float = 150.0          # seviye ilerleme çubuğu genişliği
const LEVEL_BAR_H: float = 16.0           # seviye ilerleme çubuğu yüksekliği
const SCORE_BOX_W: float = 200.0          # skor etiketi kutusu
const SCORE_BOX_H: float = 80.0
const SCORE_OUTLINE: int = 10
const PAUSE_BTN_SIZE: float = 64.0        # duraklat dokunma alanı
const PAUSE_BAR_W: float = 9.0            # duraklat ikonundaki çubuklar
const PAUSE_BAR_H: float = 26.0
const PAUSE_BAR_GAP: float = 8.0
const CHAT_BTN_SIZE: Vector2 = Vector2(104.0, 52.0)
const STACK_MAX_W: float = 640.0          # üst bildirim yığını en fazla genişlik
const STACK_GAP: int = 8
const EVENT_FEED_MAX: int = 3
const EVENT_FEED_LIFE: float = 2.4
const SLOT_SIZE: float = 88.0             # güçlendirme yuvası
const SLOT_GAP: float = 8.0
const SLOT_RADIUS: int = 24
const SLOT_ICON_SIZE: float = 44.0
## Sıralama ekranındaki yerel oyuncu portresinin boyu.
const RESULTS_PORTRAIT_SIZE: float = 200.0
const SLOT_NUM_SIZE: float = 26.0
const TRAY_PAD: float = 8.0
const TRAY_MIN_SCALE: float = 0.72        # dar ekranda tepsinin küçülebileceği alt sınır
const ABILITY_GAP: float = 12.0           # iki yetenek butonu arası
const STRIP_MID_GAP: float = 16.0         # tepsi ile yetenek butonları arası en az boşluk
const STRIP_BOTTOM_MIN: float = 8.0
const DEATH_PANEL_MAX_W: float = 600.0
const DEATH_PORTRAIT_MAX: float = 300.0
const DEATH_PORTRAIT_MIN: float = 140.0
const KIRINTI_COUNT_SEC: float = 0.8
const SKILL_CARD_MAX_W: float = 600.0
const WINNER_PANEL_MAX_W: float = 560.0
const TARGET_PANEL_MAX_W: float = 600.0
const RESULTS_ROW_H: float = 108.0
const AUNT_PANEL_SIZE: Vector2 = Vector2(310.0, 110.0)
const GHOST_STRIP_W: float = 88.0
const HUD_ANIM_SEC: float = 0.2
const HUD_PANEL_BG: Color = Color(0.965, 0.937, 0.894, 0.84)   # yarı saydam krem
const HUD_BAR_BG: Color = Color(0.141, 0.086, 0.055, 0.70)     # çubuk koyu zemini
const HUD_TIP_BG: Color = Color("#FBEFC4")
const ICON_LINE_W: float = 2.5

var _ability2_btn: Control = null
var _skill_summary_card: PanelContainer = null
var _victory_banner: PanelContainer = null
var _finish_lap_btn: Button = null
var _results_panel: Control = null
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

var _equip_toast: Label = null
var _left_block: PanelContainer = null
var _level_badge: Label = null
var _level_bar: Control = null
var _level_ratio: float = 0.0
var _alive_pill: PanelContainer = null
var _notice_stack: VBoxContainer = null
# Faz 11.5/11.6: olay tanıtım şeridi ve albüm bildirimi
var _event_banner: PanelContainer = null
var _event_banner_title: Label = null
var _event_banner_sub: Label = null
var _event_banner_tween: Tween = null
var _level_banner: PanelContainer = null
var _level_banner_title: Label = null
var _level_banner_sub: Label = null
var _edge_glow: ColorRect = null

var _chat_btn: Button = null
var _chat_popup: VBoxContainer = null
var _chat_cooldown: float = 0.0
var _event_feed_vbox: VBoxContainer = null
var _target_panel: PanelContainer = null
var _target_box: HFlowContainer = null
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

var _death_dim: ColorRect = null
var _death_host: MarginContainer = null
var _winner_host: MarginContainer = null
var _record_label: Label = null
var _kirinti_label: Label = null
var _quest_label: Label = null

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
	alive_label.visible = true
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
	_build_top_bar()
	_build_notice_stack()
	_build_bottom_strip()
	_build_overlays()
	_build_death_extras()
	_build_same_course_button()
	Monetization.quest_progressed.connect(_on_quest_progressed)
	get_viewport().size_changed.connect(_relayout_hud)
	_relayout_hud()
	_relayout_hud.call_deferred()


# ---------------------------------------------------------------------------
# Genel API
# ---------------------------------------------------------------------------

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
	_alive_pill.visible = NetworkManager.is_multiplayer_match
	alive_label.text = "Hayatta: %d / %d" % [alive, total]
	_alive_pill.offset_left = _alive_pill.offset_right - _alive_pill.get_combined_minimum_size().x


## Çok oyunculu modda izleyici bandını açar veya kapatır.
func set_spectator_mode(active: bool) -> void:
	spectator_label.visible = active
	if _ghost_strip != null:
		_ghost_strip.visible = active and NetworkManager.is_multiplayer_match
		_relayout_hud()
	if active:
		ability_button.visible = false
		_counter_strip.visible = false
		_close_target_picker()


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
	_layout_center_panel(_winner_host, winner_panel, WINNER_PANEL_MAX_W)

	if is_host:
		await get_tree().create_timer(GameConfig.WINNER_WAIT_BTN_SEC).timeout
		if is_instance_valid(winner_panel) and winner_panel.visible:
			replay_button.visible = true
			lobby_button.visible = true


## Debug modunda mevcut seed bilgisini gösterir.
func set_seed_text(seed_val: int) -> void:
	seed_label.visible = GameConfig.DEBUG
	seed_label.text = "Seed: %d" % seed_val


## Oynanan oyuncu ve karakter adını sol üst blokta gösterir.
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
	tw.tween_property(phase_label, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		phase_label.visible = false
	)


## Böcek ilacı uyarısını ortada kısa süre gösterir.
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


## Elenme panelini açar: sinirli portre, replik, rekor, kazanılan kırıntı ve günlük görev.
func show_death_panel(final_score: int, char_id: String = "klasik", death_cause: String = "", earned_kirinti: int = -1, cause_suffix: String = "") -> void:
	ability_button.visible = false
	_counter_strip.visible = false
	_close_target_picker()
	hide_match_skill_summary()
	# Faz 10.3: tek görselli yüz yerine önden, sinirli, etkileşimli portre (boyu _layout_death_panel verir)
	_using_angry_portrait = true
	angry_char_rect.texture = null
	angry_char_rect.modulate = Color.WHITE
	angry_char_rect.rotation = 0.0
	angry_char_rect.scale = Vector2.ONE
	face_overlay.visible = false
	_talk_remaining = 0.0
	_talk_elapsed = 0.0
	if _death_portrait == null or not is_instance_valid(_death_portrait):
		_death_portrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
		_death_portrait.bubble_inside = true
		angry_char_rect.add_child(_death_portrait)
		_death_portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_death_portrait.one_more_requested.connect(func() -> void:
			_pulse_button(retry_button)
		)
	_death_portrait.setup(char_id, CharacterPortrait.EXPR_ANGRY)
	_death_char_id = char_id
	_death_score = final_score

	var best: int = _load_best_score()
	var is_new_record: bool = final_score > best
	if is_new_record:
		best = final_score
		_save_best_score(best)

	var death_entry: Dictionary = CharacterData.get_random_death_entry(char_id)
	_death_line = str(death_entry["text"])
	death_title.text = "ELENDİN!"
	var cause_line: String = ""
	if not death_cause.is_empty():
		cause_line = "\n" + GameConfig.get_random_death_cause_line(death_cause, NetworkManager.local_player_name) + cause_suffix
	final_score_label.text = ("Bugün %d kişiyi sandalyeye çıkardın!" % final_score) + cause_line

	# Rekor satırı (yeni rekorda vurgulu altın şerit)
	if is_new_record and final_score > 0:
		_record_label.text = "YENİ REKOR: %d! Mahalle seni konuşuyor!" % best
		_record_label.add_theme_stylebox_override("normal", _pill_style(GameConfig.COLOR_GOLD, GameConfig.COLOR_INK))
		_record_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	else:
		_record_label.text = "Rekor: %d" % best
		_record_label.add_theme_stylebox_override("normal", _pill_style(Color(0.48, 0.36, 0.29, 0.12), Color(0.0, 0.0, 0.0, 0.0)))
		_record_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)

	# Kırıntı satırı (0 -> N sayarak)
	_kirinti_label.visible = earned_kirinti >= 0
	_kirinti_label.text = "+0 Kırıntı"

	# Günlük görev ilerlemesi
	var quest_text: String = _quest_progress_text()
	_quest_label.visible = not quest_text.is_empty()
	_quest_label.text = quest_text

	_death_dim.visible = true
	_death_dim.modulate.a = 0.0
	death_panel.visible = true
	_death_host.modulate.a = 0.0
	_layout_death_panel(DEATH_PORTRAIT_MAX)
	# Satır kaydırmalı yazılar ölçülsün diye iki kare bekle, sığmazsa portreyi küçült
	await get_tree().process_frame
	await get_tree().process_frame
	_fit_death_portrait()
	_death_host.modulate.a = 1.0
	_death_host.pivot_offset = _death_host.size * 0.5
	_death_host.scale = Vector2(0.85, 0.85)

	var tw: Tween = create_tween()
	tw.tween_property(_death_host, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_death_dim, "modulate:a", 1.0, 0.2)
	if earned_kirinti > 0:
		var target: float = float(earned_kirinti)
		tw.tween_method(func(v: float) -> void:
			_kirinti_label.text = "+%d Kırıntı" % int(roundf(v))
		, 0.0, target, KIRINTI_COUNT_SEC).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			_kirinti_label.pivot_offset = _kirinti_label.size * 0.5
			_kirinti_label.scale = Vector2(1.15, 1.15)
			var ptw: Tween = create_tween()
			ptw.tween_property(_kirinti_label, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		)

	_death_portrait.pop_in()
	_death_portrait.say(_death_line, 2.6)
	AudioManager.play_sfx(str(death_entry["sound"]), 0.96, 1.05)
	_ensure_death_share_button()


## Yetenek butonlarının görünürlüğünü ayarlar.
func set_ability_visible(vis: bool) -> void:
	ability_button.visible = vis
	if _ability2_btn != null:
		_ability2_btn.visible = vis


## Yetenek bekleme göstergesini günceller.
func update_ability_cooldown(remaining: float, total: float) -> void:
	ability_button.set_cooldown(remaining, total)


## Yetenek aktif durumunu günceller.
func update_ability_active(active: bool) -> void:
	ability_button.set_active(active)


func set_ability2_cooldown(remaining: float, total: float) -> void:
	if _ability2_btn != null:
		_ability2_btn.call("set_cooldown", remaining, total)


func set_ability2_active(active: bool) -> void:
	if _ability2_btn != null:
		_ability2_btn.call("set_active", active)


## Halay Başı yeteneğinde yalnızca sol ve sağ kenar şeritlerinde konfeti yağdırır.
func spawn_edge_confetti() -> void:
	var vis_w: float = ComicUiHelper.visible_size(score_label).x
	var half_w: float = GameConfig.HALAY_CONFETTI_STRIP_WIDTH * 0.5
	var x_positions: Array[float] = [half_w, vis_w - half_w]
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
		# Sahne değişirse zamanlayıcı serbest bırakılmış düğümü yakalamasın
		p.finished.connect(p.queue_free)


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
	var k: float = w / 340.0

	# Çatık sinirli kaşlar (V biçiminde)
	var brow_y: float = h * 0.34 + sin(_talk_elapsed * 14.0) * (2.5 if _talk_remaining > 0.0 else 0.0)
	var brow_col: Color = GameConfig.COLOR_DARK_TEXT
	face_overlay.draw_line(Vector2(w * 0.33, brow_y - 6.0 * k), Vector2(w * 0.47, brow_y + 7.0 * k), brow_col, 6.0 * k, true)
	face_overlay.draw_line(Vector2(w * 0.67, brow_y - 6.0 * k), Vector2(w * 0.53, brow_y + 7.0 * k), brow_col, 6.0 * k, true)

	# Sağ üstte sinir işareti
	var anger_c: Vector2 = Vector2(w * 0.80, h * 0.20)
	var r_col: Color = GameConfig.COLOR_WARN_RED
	var a: float = 8.0 * k
	face_overlay.draw_arc(anger_c - Vector2(a, a), 7.0 * k, 0.0, PI * 0.5, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(a, -a), 7.0 * k, PI * 0.5, PI, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(a, a), 7.0 * k, PI, PI * 1.5, 8, r_col, 3.0)
	face_overlay.draw_arc(anger_c + Vector2(-a, a), 7.0 * k, PI * 1.5, TAU, 8, r_col, 3.0)

	# Konuşma sırasında açılıp kapanan ağız
	if _talk_remaining > 0.0:
		var open_amt: float = (sin(_talk_elapsed * 26.0) + 1.0) * 0.5
		var mouth_h: float = lerpf(3.0, 14.0, open_amt) * k
		var mouth_center: Vector2 = Vector2(w * 0.5, h * 0.49)
		var pts: PackedVector2Array = PackedVector2Array([
			mouth_center + Vector2(-14.0 * k, 0.0),
			mouth_center + Vector2(0.0, -mouth_h),
			mouth_center + Vector2(14.0 * k, 0.0),
			mouth_center + Vector2(0.0, mouth_h),
		])
		face_overlay.draw_colored_polygon(pts, Color(0.22, 0.05, 0.05, 0.92))
		face_overlay.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), GameConfig.COLOR_DARK_TEXT, 2.5)


func _on_retry_pressed() -> void:
	retry_requested.emit()


func _on_menu_pressed() -> void:
	menu_requested.emit()


# ---------------------------------------------------------------------------
# Kurulum
# ---------------------------------------------------------------------------

func _apply_styles() -> void:
	var font: Font = AssetHelper.get_ui_font()
	var title_font: Font = AssetHelper.get_title_font()

	score_label.add_theme_font_override("font", title_font)
	score_label.add_theme_font_size_override("font_size", GameConfig.FS_HERO)
	score_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	score_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	score_label.add_theme_constant_override("outline_size", SCORE_OUTLINE)
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	countdown_label.add_theme_font_override("font", title_font)
	countdown_label.add_theme_font_size_override("font_size", GameConfig.FS_HERO)
	countdown_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	countdown_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	countdown_label.add_theme_constant_override("outline_size", 12)
	countdown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	seed_label.add_theme_font_override("font", font)
	seed_label.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
	seed_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	seed_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	seed_label.add_theme_constant_override("outline_size", 4)
	seed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	seed_label.modulate.a = 0.75
	seed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	char_badge_label.add_theme_font_override("font", font)
	char_badge_label.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	char_badge_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	char_badge_label.clip_text = true
	char_badge_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	char_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	phase_label.add_theme_font_override("font", title_font)
	phase_label.add_theme_font_size_override("font_size", GameConfig.FS_H1)
	phase_label.add_theme_color_override("font_color", GameConfig.COLOR_PEACH)
	phase_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_INK)
	phase_label.add_theme_constant_override("outline_size", 10)
	phase_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	ComicUiHelper.style_bitten_panel(death_panel, GameConfig.COLOR_CREAM, 21, GameConfig.SP_L)

	death_title.add_theme_font_override("font", title_font)
	death_title.add_theme_font_size_override("font_size", GameConfig.FS_H1)
	death_title.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)

	final_score_label.add_theme_font_override("font", font)
	final_score_label.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	final_score_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	final_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	retry_button.custom_minimum_size = Vector2(0.0, 72.0)
	menu_button.custom_minimum_size = Vector2(0.0, 60.0)
	menu_button.text = "Ana Menü"
	ComicUiHelper.style_bitten_button(retry_button, GameConfig.COLOR_GREEN_GO, title_font, GameConfig.FS_BUTTON + 2, 31)
	ComicUiHelper.style_bitten_button(menu_button, GameConfig.COLOR_CREAM.darkened(0.04), font, GameConfig.FS_BUTTON, 32)
	ComicUiHelper.style_bitten_button(replay_button, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON, 33)
	ComicUiHelper.style_bitten_button(lobby_button, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 34)

	ComicUiHelper.style_bitten_panel(winner_panel, GameConfig.COLOR_CREAM, 22, GameConfig.SP_L)
	winner_title.add_theme_font_override("font", title_font)
	winner_title.add_theme_font_size_override("font_size", GameConfig.FS_H1)
	winner_title.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	winner_summary.add_theme_font_override("font", font)
	winner_summary.add_theme_font_size_override("font_size", GameConfig.FS_BUTTON)
	winner_summary.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	wait_label.add_theme_font_override("font", font)
	wait_label.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	wait_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)

	alive_label.add_theme_font_override("font", font)
	alive_label.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	alive_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	alive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	alive_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	spectator_label.add_theme_font_override("font", title_font)
	spectator_label.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	spectator_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	spectator_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	spectator_label.add_theme_constant_override("outline_size", 6)
	spectator_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spectator_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Sahne düğümlerini elle yerleştirmek için sol üst çapaya al
	for c: Control in [score_label, seed_label]:
		c.set_anchors_preset(Control.PRESET_TOP_LEFT)


## Sol üst blok (isim + Sv + ilerleme), ortada skor, sağda duraklat / hayatta kalan.
func _build_top_bar() -> void:
	var font: Font = AssetHelper.get_ui_font()

	_left_block = PanelContainer.new()
	_left_block.name = "LeftBlock"
	_left_block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_block.add_theme_stylebox_override("panel", _hud_panel_style(14, 10, 6))
	add_child(_left_block)

	var lv: VBoxContainer = VBoxContainer.new()
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lv.add_theme_constant_override("separation", 2)
	_left_block.add_child(lv)

	char_badge_label.reparent(lv, false)
	char_badge_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	char_badge_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", GameConfig.SP_XS)
	lv.add_child(row)

	_level_badge = Label.new()
	_level_badge.text = "Sv 1"
	_level_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_badge.add_theme_font_override("font", AssetHelper.get_title_font())
	_level_badge.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	_level_badge.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	row.add_child(_level_badge)

	_level_bar = Control.new()
	_level_bar.name = "LevelBar"
	_level_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_bar.custom_minimum_size = Vector2(LEVEL_BAR_W, LEVEL_BAR_H)
	_level_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_level_bar.draw.connect(_draw_level_bar)
	row.add_child(_level_bar)

	# Sağ: çoklu oyuncuda hayatta kalan hapı
	_alive_pill = PanelContainer.new()
	_alive_pill.name = "AlivePill"
	_alive_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_alive_pill.add_theme_stylebox_override("panel", _hud_panel_style(14, 12, 8))
	_alive_pill.visible = NetworkManager.is_multiplayer_match
	add_child(_alive_pill)
	alive_label.reparent(_alive_pill, false)
	alive_label.set_anchors_preset(Control.PRESET_TOP_LEFT)

	# Sağ: tek oyunculuda duraklat butonu (çizilmiş iki çubuk)
	if not NetworkManager.is_multiplayer_match:
		_pause_btn = Button.new()
		_pause_btn.name = "PauseButton"
		_pause_btn.text = ""
		_pause_btn.custom_minimum_size = Vector2(PAUSE_BTN_SIZE, PAUSE_BTN_SIZE)
		_pause_btn.size = Vector2(PAUSE_BTN_SIZE, PAUSE_BTN_SIZE)
		ComicUiHelper.style_bitten_button(_pause_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_BODY, 601)
		_pause_btn.draw.connect(_draw_pause_icon)
		_pause_btn.pressed.connect(_open_pause_menu)
		add_child(_pause_btn)

	# Laf butonu: sol bloğun altında ayrı satır (yalnızca çoklu)
	_chat_btn = Button.new()
	_chat_btn.name = "ChatButton"
	_chat_btn.text = "Laf At"
	_chat_btn.custom_minimum_size = CHAT_BTN_SIZE
	_chat_btn.size = CHAT_BTN_SIZE
	_chat_btn.visible = NetworkManager.is_multiplayer_match
	ComicUiHelper.style_bitten_button(_chat_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_SMALL, 602)
	_chat_btn.pressed.connect(_toggle_chat_popup)
	add_child(_chat_btn)


func _draw_level_bar() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, _level_bar.size)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = HUD_BAR_BG
	bg.border_color = GameConfig.COLOR_INK
	bg.set_border_width_all(2)
	bg.set_corner_radius_all(int(r.size.y * 0.5))
	_level_bar.draw_style_box(bg, r)
	if _level_ratio > 0.0:
		var inner: Rect2 = r.grow(-3.0)
		inner.size.x = maxf(inner.size.y, inner.size.x * _level_ratio)
		var fill: StyleBoxFlat = StyleBoxFlat.new()
		fill.bg_color = GameConfig.COLOR_GREEN_GO
		fill.set_corner_radius_all(int(inner.size.y * 0.5))
		_level_bar.draw_style_box(fill, inner)
		_level_bar.draw_line(inner.position + Vector2(4.0, 2.0), Vector2(inner.end.x - 4.0, inner.position.y + 2.0), Color(1.0, 0.97, 0.88, 0.5), 2.0)


func _draw_pause_icon() -> void:
	var s: Vector2 = _pause_btn.size
	var cy: float = s.y * 0.5 - 2.0
	var bar: StyleBoxFlat = StyleBoxFlat.new()
	bar.bg_color = GameConfig.COLOR_INK
	bar.set_corner_radius_all(int(PAUSE_BAR_W * 0.5))
	var x0: float = s.x * 0.5 - PAUSE_BAR_GAP * 0.5 - PAUSE_BAR_W
	var x1: float = s.x * 0.5 + PAUSE_BAR_GAP * 0.5
	_pause_btn.draw_style_box(bar, Rect2(x0, cy - PAUSE_BAR_H * 0.5, PAUSE_BAR_W, PAUSE_BAR_H))
	_pause_btn.draw_style_box(bar, Rect2(x1, cy - PAUSE_BAR_H * 0.5, PAUSE_BAR_W, PAUSE_BAR_H))


## Üst çubuğun altında, sırayla dizilen bildirim yığını (birbirine binmez).
func _build_notice_stack() -> void:
	var font: Font = AssetHelper.get_ui_font()
	_notice_stack = VBoxContainer.new()
	_notice_stack.name = "NoticeStack"
	_notice_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notice_stack.add_theme_constant_override("separation", STACK_GAP)
	add_child(_notice_stack)

	# 1) Laf menüsü (Laf butonunun hemen altında açılır)
	_chat_popup = VBoxContainer.new()
	_chat_popup.name = "ChatPopup"
	_chat_popup.visible = false
	_chat_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chat_popup.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_chat_popup.add_theme_constant_override("separation", 6)
	var lines: Array[String] = GameConfig.QUICK_CHAT_LINES.duplicate()
	var cdata: Dictionary = CharacterData.get_character(NetworkManager.selected_char_id)
	var c_line: String = str(cdata.get("taunt_line", ""))
	if not c_line.is_empty():
		lines.append(c_line)
	for line: String in lines:
		var b: Button = Button.new()
		b.text = line
		b.custom_minimum_size = Vector2(0.0, 48.0)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		ComicUiHelper.style_bitten_button(b, GameConfig.COLOR_CREAM, font, GameConfig.FS_SMALL, 603)
		var captured: String = line
		b.pressed.connect(func() -> void:
			_chat_popup.visible = false
			_chat_cooldown = GameConfig.QUICK_CHAT_COOLDOWN
			quick_chat_sent.emit(captured)
		)
		_chat_popup.add_child(b)
	_notice_stack.add_child(_chat_popup)

	# 2) İzleyici bandı
	spectator_label.reparent(_notice_stack, false)
	spectator_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# 3) Zafer bandı + Bitir butonu yuvası (show_victory_lap_banner doldurur)

	# 4) Sataşma uyarısı
	_taunt_warn_label = Label.new()
	_taunt_warn_label.name = "TauntWarn"
	_taunt_warn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_taunt_warn_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_taunt_warn_label.visible = false
	_taunt_warn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_taunt_warn_label.add_theme_font_override("font", AssetHelper.get_title_font())
	_taunt_warn_label.add_theme_font_size_override("font_size", GameConfig.FS_H2)
	_taunt_warn_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	_taunt_warn_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	_taunt_warn_label.add_theme_constant_override("outline_size", 8)
	_notice_stack.add_child(_taunt_warn_label)

	# 5) Seviye atlama şeridi
	_level_banner = PanelContainer.new()
	_level_banner.name = "LevelBanner"
	_level_banner.visible = false
	_level_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_level_banner, GameConfig.COLOR_PEACH, 604, GameConfig.SP_M)
	var lb_vbox: VBoxContainer = VBoxContainer.new()
	lb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lb_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_banner.add_child(lb_vbox)
	_level_banner_title = Label.new()
	_level_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_level_banner_title, GameConfig.FS_H2, GameConfig.COLOR_INK, true)
	lb_vbox.add_child(_level_banner_title)
	_level_banner_sub = Label.new()
	_level_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_level_banner_sub, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	lb_vbox.add_child(_level_banner_sub)
	_notice_stack.add_child(_level_banner)

	# 5b) Faz 11.6: ani olay tanıtım şeridi / Faz 11.5: "Yeni komşu" bildirimi
	_event_banner = PanelContainer.new()
	_event_banner.name = "EventBanner"
	_event_banner.visible = false
	_event_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_event_banner, GameConfig.COLOR_GOLD, 606, GameConfig.SP_S)
	var eb_vbox: VBoxContainer = VBoxContainer.new()
	eb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	eb_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	eb_vbox.add_theme_constant_override("separation", 0)
	_event_banner.add_child(eb_vbox)
	_event_banner_title = Label.new()
	_event_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_banner_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_event_banner_title, GameConfig.FS_H2, GameConfig.COLOR_INK, true)
	eb_vbox.add_child(_event_banner_title)
	_event_banner_sub = Label.new()
	_event_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_event_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_event_banner_sub, GameConfig.FS_SMALL, GameConfig.COLOR_INK)
	eb_vbox.add_child(_event_banner_sub)
	_notice_stack.add_child(_event_banner)

	# 6) İlk kez ipucu şeridi
	_tip_banner = PanelContainer.new()
	_tip_banner.name = "TipBanner"
	_tip_banner.visible = false
	_tip_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_tip_banner, HUD_TIP_BG, 605, GameConfig.SP_S)
	var tip_lbl: Label = Label.new()
	tip_lbl.name = "TipLabel"
	tip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(tip_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_INK)
	_tip_banner.add_child(tip_lbl)
	_notice_stack.add_child(_tip_banner)

	# 7) Olay akışı (son 3 olay)
	_event_feed_vbox = VBoxContainer.new()
	_event_feed_vbox.name = "EventFeed"
	_event_feed_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_feed_vbox.add_theme_constant_override("separation", 4)
	_notice_stack.add_child(_event_feed_vbox)

	# 8) Faz 11.4: küçük görev ilerleme bildirimi
	_quest_notice = Label.new()
	_quest_notice.name = "QuestNotice"
	_quest_notice.visible = false
	_quest_notice.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quest_notice.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_quest_notice.add_theme_font_override("font", AssetHelper.get_ui_font())
	_quest_notice.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
	_quest_notice.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	_quest_notice.add_theme_stylebox_override("normal", _pill_style(Color(GameConfig.COLOR_GOLD, 0.92), GameConfig.COLOR_INK))
	_notice_stack.add_child(_quest_notice)


## Alt kontrol şeridi: güçlendirme tepsisi + iki yetenek butonu.
func _build_bottom_strip() -> void:
	var font: Font = AssetHelper.get_ui_font()

	_counter_strip = Panel.new()
	_counter_strip.name = "CounterStrip"
	_counter_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_counter_strip.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	add_child(_counter_strip)
	move_child(_counter_strip, 0)

	_powerup_tray = Panel.new()
	_powerup_tray.name = "PowerupTray"
	_powerup_tray.size = _tray_natural_size()
	_powerup_tray.mouse_filter = Control.MOUSE_FILTER_STOP
	var tray_style: StyleBoxFlat = StyleBoxFlat.new()
	tray_style.bg_color = Color(0.14, 0.10, 0.08, 0.38)
	tray_style.border_color = Color(0.965, 0.937, 0.894, 0.5)
	tray_style.set_border_width_all(2)
	tray_style.set_corner_radius_all(SLOT_RADIUS + int(TRAY_PAD))
	_powerup_tray.add_theme_stylebox_override("panel", tray_style)
	_counter_strip.add_child(_powerup_tray)

	_slot_buttons.clear()
	_slot_cd_overlays.clear()
	for i: int in range(GameConfig.POWERUP_SLOTS):
		var slot_btn: Button = Button.new()
		slot_btn.name = "PowerupSlot_%d" % i
		slot_btn.position = Vector2(TRAY_PAD + float(i) * (SLOT_SIZE + SLOT_GAP), TRAY_PAD)
		slot_btn.size = Vector2(SLOT_SIZE, SLOT_SIZE)
		slot_btn.pivot_offset = slot_btn.size * 0.5
		slot_btn.focus_mode = Control.FOCUS_NONE
		slot_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		slot_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var captured_i: int = i
		slot_btn.pressed.connect(func() -> void:
			_on_powerup_slot_clicked(captured_i)
		)
		_powerup_tray.add_child(slot_btn)
		_slot_buttons.append(slot_btn)

		var cd_panel: Panel = Panel.new()
		cd_panel.name = "Cooldown"
		cd_panel.size = slot_btn.size
		cd_panel.visible = false
		cd_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd_panel.z_index = 2
		var cd_sb: StyleBoxFlat = StyleBoxFlat.new()
		cd_sb.bg_color = Color(0.18, 0.16, 0.14, 0.55)
		cd_sb.set_corner_radius_all(SLOT_RADIUS)
		cd_panel.add_theme_stylebox_override("panel", cd_sb)
		slot_btn.add_child(cd_panel)
		_slot_cd_overlays.append(cd_panel)

	# Aktif 1 (YETENEK)
	ability_button.reparent(_counter_strip, false)
	ability_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
	ability_button.set("base_color", GameConfig.COLOR_SAGE)
	ability_button.set("icon_kind", "star")

	# Aktif 2 (KÜÇÜL) — aynı boy, farklı renk ve ikon
	_ability2_btn = ABILITY_BTN_SCENE.instantiate() as Control
	_ability2_btn.name = "Ability2Button"
	_ability2_btn.visible = false
	_ability2_btn.ability_pressed.connect(func() -> void:
		ability2_pressed.emit()
	)
	_counter_strip.add_child(_ability2_btn)
	_ability2_btn.set("default_label_text", "KÜÇÜL")
	_ability2_btn.set("base_color", GameConfig.COLOR_DUST_BLUE)
	_ability2_btn.set("icon_kind", "shrink")

	_equip_toast = Label.new()
	_equip_toast.text = "Kuşanıldı!"
	_equip_toast.visible = false
	_equip_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_equip_toast.add_theme_font_override("font", AssetHelper.get_title_font())
	_equip_toast.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	_equip_toast.add_theme_color_override("font_color", HUD_TIP_BG)
	_equip_toast.add_theme_color_override("font_outline_color", GameConfig.COLOR_INK)
	_equip_toast.add_theme_constant_override("outline_size", 6)
	_counter_strip.add_child(_equip_toast)

	_immune_badge = Label.new()
	_immune_badge.text = "Bağışık"
	_immune_badge.visible = false
	_immune_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_immune_badge.add_theme_font_override("font", font)
	_immune_badge.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	_immune_badge.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	_immune_badge.add_theme_stylebox_override("normal", _pill_style(GameConfig.COLOR_SAGE, GameConfig.COLOR_INK))
	add_child(_immune_badge)

	# Sataşma hedef seçici (tepsi üstünde, ortalı)
	_target_panel = PanelContainer.new()
	_target_panel.name = "TargetPicker"
	_target_panel.visible = false
	_target_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_panel.add_theme_stylebox_override("panel", _hud_panel_style(18, 12, 10))
	add_child(_target_panel)
	var tv: VBoxContainer = VBoxContainer.new()
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.add_theme_constant_override("separation", GameConfig.SP_XS)
	_target_panel.add_child(tv)
	var t_title: Label = Label.new()
	t_title.text = "Kime atalım?"
	t_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(t_title, GameConfig.FS_SMALL, GameConfig.COLOR_INK, true)
	tv.add_child(t_title)
	_target_box = HFlowContainer.new()
	_target_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_target_box.alignment = FlowContainer.ALIGNMENT_CENTER
	_target_box.add_theme_constant_override("h_separation", GameConfig.SP_XS)
	_target_box.add_theme_constant_override("v_separation", GameConfig.SP_XS)
	tv.add_child(_target_box)

	_refresh_tray_visuals()


## Efekt katmanları, teyze paneli, hayalet terlik şeridi, ödül etiketi.
func _build_overlays() -> void:
	var font: Font = AssetHelper.get_ui_font()

	_stink_overlay = ColorRect.new()
	_stink_overlay.color = Color(0.32, 0.56, 0.24, 0.58)
	_stink_overlay.visible = false
	_stink_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stink_overlay)

	_aunt_panel = PanelContainer.new()
	_aunt_panel.size = AUNT_PANEL_SIZE
	_aunt_panel.visible = false
	_aunt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_aunt_panel, GameConfig.COLOR_DUST_PINK, 606, GameConfig.SP_M)
	var ap_lbl: Label = Label.new()
	ap_lbl.text = "Ayyy bu ne böcek!"
	ap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ap_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(ap_lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	_aunt_panel.add_child(ap_lbl)
	add_child(_aunt_panel)

	_ghost_strip = Panel.new()
	_ghost_strip.visible = false
	_ghost_strip.mouse_filter = Control.MOUSE_FILTER_STOP
	var gs_sb: StyleBoxFlat = StyleBoxFlat.new()
	gs_sb.bg_color = Color(0.85, 0.38, 0.35, 0.55)
	gs_sb.border_color = GameConfig.COLOR_INK
	gs_sb.set_border_width_all(3)
	gs_sb.set_corner_radius_all(18)
	_ghost_strip.add_theme_stylebox_override("panel", gs_sb)
	_ghost_strip.gui_input.connect(_on_ghost_strip_input)
	_ghost_label = Label.new()
	_ghost_label.text = "Terlik\nAt!"
	_ghost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ghost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ghost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ghost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_label.add_theme_font_override("font", AssetHelper.get_title_font())
	_ghost_label.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	_ghost_label.add_theme_color_override("font_color", GameConfig.COLOR_CREAM)
	_ghost_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_INK)
	_ghost_label.add_theme_constant_override("outline_size", 5)
	_ghost_strip.add_child(_ghost_label)
	add_child(_ghost_strip)

	_awards_label = Label.new()
	_awards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_awards_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_awards_label.visible = false
	_awards_label.add_theme_font_override("font", font)
	_awards_label.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	_awards_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	$WinnerPanel/VBox.add_child(_awards_label)
	$WinnerPanel/VBox.move_child(_awards_label, 2)

	_edge_glow = ColorRect.new()
	_edge_glow.color = Color(1.0, 0.94, 0.72, 0.0)
	_edge_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge_glow)

	# Siyah-beyaz ölüm efekti katmanı
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


## Faz 11.2: "Tekrar Dene" (yeni parkur) ile yan yana "Aynı Parkur" (aynı seed + önceki denemenin hayaleti).
func _build_same_course_button() -> void:
	var vbox: VBoxContainer = retry_button.get_parent() as VBoxContainer
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "RetryRow"
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	vbox.add_child(row)
	vbox.move_child(row, retry_button.get_index())
	retry_button.reparent(row, false)
	retry_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_same_course_btn = Button.new()
	_same_course_btn.name = "SameCourseButton"
	_same_course_btn.text = "Aynı Parkur"
	_same_course_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_same_course_btn.custom_minimum_size = Vector2(0.0, retry_button.custom_minimum_size.y)
	ComicUiHelper.style_bitten_button(_same_course_btn, GameConfig.COLOR_GOLD, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON, 645)
	_same_course_btn.pressed.connect(func() -> void: same_course_requested.emit())
	_connect_button_tween(_same_course_btn)
	row.add_child(_same_course_btn)


## Ölüm paneline rekor, kırıntı ve görev satırlarını ve arka karartmayı ekler.
func _build_death_extras() -> void:
	var vbox: VBoxContainer = $DeathPanel/VBox
	vbox.add_theme_constant_override("separation", GameConfig.SP_S)
	death_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	_death_dim = ColorRect.new()
	_death_dim.name = "DeathDim"
	_death_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_dim.color = Color(0.10, 0.06, 0.04, 0.45)
	_death_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_dim.z_index = 59
	_death_dim.visible = false
	add_child(_death_dim)
	move_child(_death_dim, death_panel.get_index())
	_death_host = _make_center_host(death_panel, 60)
	_winner_host = _make_center_host(winner_panel, 60)

	var insert_at: int = final_score_label.get_index() + 1

	_record_label = Label.new()
	_record_label.name = "RecordLabel"
	_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_record_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_record_label.add_theme_font_override("font", AssetHelper.get_title_font())
	_record_label.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	vbox.add_child(_record_label)
	vbox.move_child(_record_label, insert_at)

	_kirinti_label = Label.new()
	_kirinti_label.name = "KirintiLabel"
	_kirinti_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_kirinti_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_kirinti_label.custom_minimum_size = Vector2(240.0, 0.0)
	_kirinti_label.add_theme_font_override("font", AssetHelper.get_title_font())
	_kirinti_label.add_theme_font_size_override("font_size", GameConfig.FS_H2)
	_kirinti_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	_kirinti_label.add_theme_stylebox_override("normal", _pill_style(GameConfig.COLOR_GOLD.lightened(0.25), GameConfig.COLOR_BROWN))
	vbox.add_child(_kirinti_label)
	vbox.move_child(_kirinti_label, insert_at + 1)

	_quest_label = Label.new()
	_quest_label.name = "QuestLabel"
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_quest_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	vbox.add_child(_quest_label)
	vbox.move_child(_quest_label, insert_at + 2)


# ---------------------------------------------------------------------------
# Yerleşim (görünür alan + güvenli alan)
# ---------------------------------------------------------------------------

func _relayout_hud() -> void:
	if _counter_strip == null or not score_label.is_inside_tree():
		return
	var vs: Vector2 = ComicUiHelper.visible_size(score_label)
	var ins: Dictionary = ComicUiHelper.safe_insets(score_label)
	var gut: float = GameConfig.SCREEN_GUTTER
	var left_x: float = float(ins["left"]) + gut
	var right_x: float = vs.x - float(ins["right"]) - gut
	var top_y: float = float(ins["top"]) + gut

	# --- Üst çubuk ---
	score_label.size = Vector2(SCORE_BOX_W, SCORE_BOX_H)
	score_label.position = Vector2((vs.x - SCORE_BOX_W) * 0.5, top_y - 8.0)
	score_label.pivot_offset = score_label.size * 0.5

	var block_w: float = minf(TOP_BLOCK_MAX_W, (vs.x - SCORE_BOX_W) * 0.5 - left_x - GameConfig.SP_XS)
	_left_block.custom_minimum_size = Vector2(block_w, 0.0)
	_left_block.position = Vector2(left_x, top_y)
	_left_block.size = Vector2(block_w, 0.0)
	_left_block.reset_size()
	var bar_bottom: float = maxf(_left_block.position.y + _left_block.size.y, score_label.position.y + SCORE_BOX_H)

	if _pause_btn != null:
		_pause_btn.size = Vector2(PAUSE_BTN_SIZE, PAUSE_BTN_SIZE)
		_pause_btn.position = Vector2(right_x - PAUSE_BTN_SIZE, top_y)
		bar_bottom = maxf(bar_bottom, top_y + PAUSE_BTN_SIZE)
	# Sağ üst köşeye çapalı; yazı uzarsa sola doğru büyür
	_alive_pill.anchor_left = 1.0
	_alive_pill.anchor_right = 1.0
	_alive_pill.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_alive_pill.offset_right = -(vs.x - right_x)
	_alive_pill.offset_left = _alive_pill.offset_right - _alive_pill.get_combined_minimum_size().x
	_alive_pill.offset_top = top_y
	_alive_pill.offset_bottom = top_y + _alive_pill.get_combined_minimum_size().y

	var below_y: float = _left_block.position.y + _left_block.size.y + GameConfig.SP_XS
	if _chat_btn.visible:
		_chat_btn.size = CHAT_BTN_SIZE
		_chat_btn.position = Vector2(left_x, below_y)
		bar_bottom = maxf(bar_bottom, below_y + CHAT_BTN_SIZE.y)

	# --- Bildirim yığını (üst çubuğun altından aşağı) ---
	var stack_right: float = right_x
	if _ghost_strip != null and _ghost_strip.visible:
		stack_right = right_x - GHOST_STRIP_W - GameConfig.SP_XS
	var stack_w: float = minf(STACK_MAX_W, stack_right - left_x)
	_notice_stack.custom_minimum_size = Vector2(stack_w, 0.0)
	_notice_stack.size = Vector2(stack_w, 0.0)
	_notice_stack.position = Vector2(left_x + (stack_right - left_x - stack_w) * 0.5, bar_bottom + GameConfig.SP_S)

	# --- Alt şerit ---
	var bottom_pad: float = maxf(STRIP_BOTTOM_MIN, float(ins["bottom"]) + 4.0)
	var strip_h: float = GameConfig.COUNTER_STRIP_HEIGHT
	_counter_strip.size = Vector2(vs.x, strip_h)
	_counter_strip.position = Vector2(0.0, vs.y - strip_h - bottom_pad)

	var ab: float = GameConfig.ABILITY_BTN_SIZE * clampf(AudioManager.button_scale, 0.8, 1.3)
	ability_button.call("set_button_size", ab)
	_ability2_btn.call("set_button_size", ab)
	var abil_w: float = ab * 2.0 + ABILITY_GAP
	var tray_nat: Vector2 = _tray_natural_size()
	var free_w: float = (right_x - left_x) - abil_w - STRIP_MID_GAP
	var tsc: float = clampf(free_w / tray_nat.x, TRAY_MIN_SCALE, 1.0)
	_powerup_tray.size = tray_nat
	_powerup_tray.scale = Vector2(tsc, tsc)
	var tray_w: float = tray_nat.x * tsc
	var tray_y: float = strip_h - tray_nat.y * tsc - 2.0
	var ab_y: float = strip_h - ab - 2.0
	if AudioManager.left_handed:
		ability_button.position = Vector2(left_x, ab_y)
		_ability2_btn.position = Vector2(left_x + ab + ABILITY_GAP, ab_y)
		_powerup_tray.position = Vector2(right_x - tray_w, tray_y)
	else:
		_powerup_tray.position = Vector2(left_x, tray_y)
		ability_button.position = Vector2(right_x - ab, ab_y)
		_ability2_btn.position = Vector2(right_x - ab * 2.0 - ABILITY_GAP, ab_y)

	var strip_top: float = _counter_strip.position.y + minf(0.0, ab_y)
	_immune_badge.reset_size()
	_immune_badge.position = Vector2(_counter_strip.position.x + _powerup_tray.position.x, _counter_strip.position.y + tray_y - _immune_badge.size.y - GameConfig.SP_XS)
	seed_label.size = Vector2(260.0, 26.0)
	seed_label.position = Vector2((vs.x - 260.0) * 0.5, strip_top - 30.0)

	# --- Diğer katmanlar ---
	_stink_overlay.size = Vector2(vs.x, vs.y * 0.5)
	_aunt_panel.position.y = vs.y * 0.28
	if not _aunt_panel.visible:
		_aunt_panel.position.x = vs.x
	var ghost_top: float = _notice_stack.position.y + 60.0
	_ghost_strip.position = Vector2(right_x - GHOST_STRIP_W, ghost_top)
	_ghost_strip.size = Vector2(GHOST_STRIP_W, maxf(200.0, strip_top - GameConfig.SP_L - ghost_top))

	if _target_panel.visible:
		_layout_target_picker()
	if _skill_summary_card != null and is_instance_valid(_skill_summary_card):
		_layout_skill_card()
	if death_panel.visible:
		_layout_death_panel(angry_char_rect.custom_minimum_size.x)
		_fit_death_portrait.call_deferred()
	_layout_center_panel(_winner_host, winner_panel, WINNER_PANEL_MAX_W)


func _tray_natural_size() -> Vector2:
	var n: float = float(GameConfig.POWERUP_SLOTS)
	return Vector2(TRAY_PAD * 2.0 + SLOT_SIZE * n + SLOT_GAP * (n - 1.0), SLOT_SIZE + TRAY_PAD * 2.0)


## Güvenli alanın içinde kalan kullanılabilir dikdörtgen.
func _safe_rect() -> Rect2:
	var vs: Vector2 = ComicUiHelper.visible_size(score_label)
	var ins: Dictionary = ComicUiHelper.safe_insets(score_label)
	var gut: float = GameConfig.SCREEN_GUTTER
	var pos: Vector2 = Vector2(float(ins["left"]) + gut, float(ins["top"]) + gut)
	var end: Vector2 = Vector2(vs.x - float(ins["right"]) - gut, vs.y - float(ins["bottom"]) - gut)
	return Rect2(pos, end - pos)


## Paneli tam ekran, güvenli alana uyan bir orta kapsayıcıya taşır (kendi ölçer, ortalar).
func _make_center_host(panel: Control, z: int) -> MarginContainer:
	var host: MarginContainer = MarginContainer.new()
	host.name = "%sHost" % panel.name
	host.set_anchors_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = z
	add_child(host)
	move_child(host, panel.get_index())
	var cc: CenterContainer = CenterContainer.new()
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(cc)
	panel.reparent(cc, false)
	return host


## Orta kapsayıcının kenar boşluklarını güvenli alana, panel genişliğini ekrana uydurur.
func _layout_center_panel(host: MarginContainer, panel: Control, max_w: float) -> void:
	if host == null or not is_instance_valid(panel):
		return
	var ins: Dictionary = ComicUiHelper.safe_insets(score_label)
	var gut: float = GameConfig.SCREEN_GUTTER
	host.add_theme_constant_override("margin_top", int(float(ins["top"]) + gut))
	host.add_theme_constant_override("margin_bottom", int(float(ins["bottom"]) + gut))
	host.add_theme_constant_override("margin_left", int(float(ins["left"]) + gut))
	host.add_theme_constant_override("margin_right", int(float(ins["right"]) + gut))
	var sr: Rect2 = _safe_rect()
	panel.custom_minimum_size = Vector2(minf(max_w, sr.size.x), 0.0)


func _layout_death_panel(portrait: float) -> void:
	angry_char_rect.custom_minimum_size = Vector2(portrait, portrait)
	angry_char_rect.pivot_offset = Vector2(portrait, portrait) * 0.5
	_layout_center_panel(_death_host, death_panel, DEATH_PANEL_MAX_W)


## Panel güvenli alana sığmıyorsa portreyi aradaki fark kadar küçültür.
func _fit_death_portrait() -> void:
	var sr: Rect2 = _safe_rect()
	var h: float = death_panel.get_combined_minimum_size().y
	var cur: float = angry_char_rect.custom_minimum_size.x
	var want: float = cur
	if h > sr.size.y:
		want = maxf(DEATH_PORTRAIT_MIN, cur - (h - sr.size.y))
	elif cur < DEATH_PORTRAIT_MAX:
		want = minf(DEATH_PORTRAIT_MAX, cur + (sr.size.y - h))
	if absf(want - cur) >= 1.0:
		_layout_death_panel(want)


## Günlük görev satırı: önce alınmamış ödül, yoksa en yakın tamamlanmamış görev.
func _quest_progress_text() -> String:
	var quests: Array[Dictionary] = Monetization.get_daily_quests()
	var best_q: Dictionary = {}
	var best_ratio: float = -1.0
	for q: Dictionary in quests:
		if bool(q.get("claimed", false)):
			continue
		var goal: int = maxi(int(q.get("goal", 1)), 1)
		var prog: int = int(q.get("progress", 0))
		if prog >= goal:
			return "Görev tamamlandı! Menüde ödülünü al."
		var ratio: float = float(prog) / float(goal)
		if ratio > best_ratio:
			best_ratio = ratio
			best_q = q
	if best_q.is_empty():
		return ""
	return "Görev: %s  %d/%d" % [str(best_q.get("title", "")), int(best_q.get("progress", 0)), int(best_q.get("goal", 1))]


# ---------------------------------------------------------------------------
# Güçlendirme tepsisi
# ---------------------------------------------------------------------------

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
	btn.scale = Vector2(1.18, 1.18)
	var tw: Tween = create_tween()
	tw.tween_property(btn, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var tsc: float = _powerup_tray.scale.x
	_equip_toast.visible = true
	_equip_toast.modulate.a = 1.0
	var start_y: float = _powerup_tray.position.y - 34.0
	_equip_toast.position = Vector2(_powerup_tray.position.x + btn.position.x * tsc, start_y)
	var t_tw: Tween = create_tween()
	t_tw.tween_property(_equip_toast, "position:y", start_y - 24.0, 0.6)
	t_tw.parallel().tween_property(_equip_toast, "modulate:a", 0.0, 0.6)


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


func trigger_leftmost_powerup() -> void:
	_on_powerup_slot_clicked(0)


func _slot_style(bg: Color, border: Color, border_w: int, shadow: bool) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(SLOT_RADIUS)
	if shadow:
		sb.shadow_color = Color(0.14, 0.09, 0.05, 0.35)
		sb.shadow_size = 1
		sb.shadow_offset = Vector2(0.0, 3.0)
	return sb


func _refresh_tray_visuals() -> void:
	for i: int in range(_slot_buttons.size()):
		var btn: Button = _slot_buttons[i]
		for child: Node in btn.get_children():
			if child != _slot_cd_overlays[i]:
				child.queue_free()
		btn.text = ""
		var filled: bool = i < _tray_items.size()
		if filled:
			var item_id: String = _tray_items[i]
			var def: Dictionary = GameConfig.get_item_def(item_id)
			var tint: Color = def.get("color", GameConfig.COLOR_PEACH) as Color
			var bg: Color = GameConfig.COLOR_CREAM.lerp(tint, 0.22)
			btn.add_theme_stylebox_override("normal", _slot_style(bg, GameConfig.COLOR_INK, 3, true))
			btn.add_theme_stylebox_override("hover", _slot_style(bg.lightened(0.06), GameConfig.COLOR_INK, 3, true))
			btn.add_theme_stylebox_override("pressed", _slot_style(bg.darkened(0.08), GameConfig.COLOR_INK, 3, false))
			btn.add_theme_stylebox_override("hover_pressed", _slot_style(bg.darkened(0.08), GameConfig.COLOR_INK, 3, false))

			# Faz 10.1: pastel tabak üstünde gerçek ikon görseli (harf yok)
			var plate_px: float = SLOT_ICON_SIZE + 6.0
			var plate: TextureRect = TextureRect.new()
			plate.name = "Icon"
			plate.texture = IconFactory.plate_texture(int(plate_px))
			plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			plate.size = Vector2(plate_px, plate_px)
			plate.position = Vector2((SLOT_SIZE - plate_px) * 0.5, 5.0)
			plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn.add_child(plate)

			var icon_rect: TextureRect = TextureRect.new()
			icon_rect.texture = IconFactory.item_icon(item_id)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.size = Vector2(plate_px - 12.0, plate_px - 12.0)
			icon_rect.position = Vector2(6.0, 6.0)
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			plate.add_child(icon_rect)

			if bool(def.get("is_signature", false)):
				# İmza ödülü: tabağın kenarında hafif altın parıltı
				var glow: Panel = Panel.new()
				glow.size = Vector2(plate_px + 4.0, plate_px + 4.0)
				glow.position = Vector2(-2.0, -2.0)
				glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var glow_sb: StyleBoxFlat = StyleBoxFlat.new()
				glow_sb.bg_color = Color(0, 0, 0, 0)
				glow_sb.border_color = GameConfig.COLOR_GOLD
				glow_sb.set_border_width_all(3)
				glow_sb.set_corner_radius_all(int(plate_px * 0.5) + 2)
				glow.add_theme_stylebox_override("panel", glow_sb)
				plate.add_child(glow)
				plate.move_child(glow, 0)

			var name_lbl: Label = Label.new()
			name_lbl.text = str(def.get("short_name", item_id))
			name_lbl.position = Vector2(-4.0, SLOT_SIZE - 32.0)
			name_lbl.size = Vector2(SLOT_SIZE + 8.0, 26.0)
			name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			name_lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
			name_lbl.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
			name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
			name_lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
			name_lbl.add_theme_constant_override("outline_size", 4)
			btn.add_child(name_lbl)

			# Sol üstte numara rozeti
			var num_lbl: Label = Label.new()
			num_lbl.text = "%d" % (i + 1)
			num_lbl.position = Vector2(-7.0, -7.0)
			num_lbl.size = Vector2(SLOT_NUM_SIZE, SLOT_NUM_SIZE)
			num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			num_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			num_lbl.z_index = 3
			var num_sb: StyleBoxFlat = StyleBoxFlat.new()
			num_sb.bg_color = GameConfig.COLOR_INK
			num_sb.border_color = GameConfig.COLOR_CREAM
			num_sb.set_border_width_all(2)
			num_sb.set_corner_radius_all(int(SLOT_NUM_SIZE * 0.5))
			num_lbl.add_theme_stylebox_override("normal", num_sb)
			num_lbl.add_theme_font_override("font", AssetHelper.get_title_font())
			num_lbl.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
			num_lbl.add_theme_color_override("font_color", GameConfig.COLOR_CREAM)
			btn.add_child(num_lbl)
		else:
			var empty_bg: Color = Color(0.965, 0.937, 0.894, 0.22)
			var empty_border: Color = Color(0.965, 0.937, 0.894, 0.55)
			for st: String in ["normal", "hover", "pressed", "hover_pressed"]:
				btn.add_theme_stylebox_override(st, _slot_style(empty_bg, empty_border, 2, false))
			var ghost_num: Label = Label.new()
			ghost_num.text = "%d" % (i + 1)
			ghost_num.set_anchors_preset(Control.PRESET_FULL_RECT)
			ghost_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			ghost_num.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ghost_num.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ghost_num.add_theme_font_override("font", AssetHelper.get_title_font())
			ghost_num.add_theme_font_size_override("font_size", GameConfig.FS_H2)
			ghost_num.add_theme_color_override("font_color", Color(0.965, 0.937, 0.894, 0.6))
			btn.add_child(ghost_num)


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
	_level_ratio = clampf(float(passed_pairs - start_p) / float(span), 0.0, 1.0)
	_level_bar.queue_redraw()


## Seviye atlama şeridini bildirim yığınında gösterir ve kenar parlaması oynatır.
func show_level_up_banner(level_num: int, level_name: String) -> void:
	_level_banner_title.text = "SEVİYE %d: %s!" % [level_num, level_name.to_upper()]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var sub_idx: int = rng.randi_range(0, GameConfig.LEVEL_SUBTITLES.size() - 1)
	_level_banner_sub.text = GameConfig.LEVEL_SUBTITLES[sub_idx]
	_level_banner.visible = true
	_level_banner.modulate.a = 0.0

	var tw: Tween = create_tween()
	tw.tween_property(_level_banner, "modulate:a", 1.0, HUD_ANIM_SEC)
	tw.tween_interval(2.0)
	tw.tween_property(_level_banner, "modulate:a", 0.0, 0.25)
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


# ---------------------------------------------------------------------------
# Çok oyunculu: laf, olay akışı, sataşma, teyze, hayalet terlik
# ---------------------------------------------------------------------------

func _toggle_chat_popup() -> void:
	if _chat_cooldown > 0.0:
		return
	_chat_popup.visible = not _chat_popup.visible


## Olay akışına kısa süreli bir satır ekler (en fazla 3 satır, sonra solar).
func push_event_feed(text: String) -> void:
	if _event_feed_vbox == null or text.is_empty():
		return
	while _event_feed_vbox.get_child_count() >= EVENT_FEED_MAX:
		var oldest: Node = _event_feed_vbox.get_child(0)
		_event_feed_vbox.remove_child(oldest)
		oldest.queue_free()
	var lbl: Label = Label.new()
	lbl.text = GameConfig.censor(text)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lbl.add_theme_font_override("font", AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	lbl.add_theme_stylebox_override("normal", _hud_panel_style(12, 10, 3))
	_event_feed_vbox.add_child(lbl)
	var tw: Tween = create_tween()
	tw.tween_interval(EVENT_FEED_LIFE)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		if is_instance_valid(lbl):
			lbl.queue_free()
	)


## Sataşma güçlendirmesi seçilince rakip hedef butonlarını açar (süre dolunca lideri seçer).
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
		btn.custom_minimum_size = Vector2(120.0, 56.0)
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_DEAD_GRAY if immune else GameConfig.COLOR_PEACH, font, GameConfig.FS_BODY, 650)
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
	_target_panel.visible = true
	_layout_target_picker()
	_layout_target_picker.call_deferred()


func _layout_target_picker() -> void:
	var sr: Rect2 = _safe_rect()
	var w: float = minf(TARGET_PANEL_MAX_W, sr.size.x)
	_target_panel.custom_minimum_size = Vector2(w, 0.0)
	_target_panel.size = Vector2(w, 0.0)
	_target_panel.reset_size()
	var strip_top: float = _counter_strip.position.y + minf(0.0, ability_button.position.y)
	_target_panel.position = Vector2(sr.position.x + (sr.size.x - w) * 0.5, strip_top - _target_panel.size.y - GameConfig.SP_M)


func _close_target_picker() -> void:
	_pending_taunt_slot = -1
	if _target_panel != null:
		_target_panel.visible = false


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


## Kurbanın ekranında sataşma uyarısı gösterir (bildirim yığınında).
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
	var vs: Vector2 = ComicUiHelper.visible_size(score_label)
	_stink_overlay.size = Vector2(vs.x, vs.y * 0.5)
	_stink_overlay.position.y = 0.0 if top_half else vs.y * 0.5
	_stink_overlay.visible = true
	_stink_overlay.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_stink_overlay, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		_stink_overlay.visible = false
	)


func show_aunt_popup() -> void:
	var vs: Vector2 = ComicUiHelper.visible_size(score_label)
	var ins: Dictionary = ComicUiHelper.safe_insets(score_label)
	var shown_x: float = vs.x - float(ins["right"]) - AUNT_PANEL_SIZE.x - GameConfig.SCREEN_GUTTER
	_aunt_panel.visible = true
	_aunt_panel.position = Vector2(vs.x, vs.y * 0.28)
	AudioManager.play_sfx("res://assets/sounds/teyze_ayyy.ogg")
	var tw: Tween = create_tween()
	tw.tween_property(_aunt_panel, "position:x", shown_x, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(_aunt_panel, "position:x", vs.x, 0.2)
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


# ---------------------------------------------------------------------------
# Duraklatma, yetenek özeti, ipucu, efektler
# ---------------------------------------------------------------------------

## Dışarıdan (arka plana alınma / Geri tuşu) duraklatma menüsünü açar.
func open_pause_menu() -> void:
	if _pause_btn == null or not _pause_btn.visible:
		return
	_open_pause_menu()


func _open_pause_menu() -> void:
	if death_panel.visible or _pause_overlay != null:
		return
	get_tree().paused = true
	var font: Font = AssetHelper.get_ui_font()
	var modal: Dictionary = ComicUiHelper.build_modal(self, "DURAKLATILDI", GameConfig.COLOR_CREAM, 0.0, false)
	_pause_overlay = modal["root"] as Control
	_pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = modal["body"] as VBoxContainer
	var footer: VBoxContainer = modal["footer"] as VBoxContainer

	var sub: Label = Label.new()
	sub.text = "Terlik de bekliyor, acele etme."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(sub, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	body.add_child(sub)

	var resume_btn: Button = Button.new()
	resume_btn.text = "Devam Et"
	resume_btn.custom_minimum_size = Vector2(0.0, 72.0)
	ComicUiHelper.style_bitten_button(resume_btn, GameConfig.COLOR_GREEN_GO, AssetHelper.get_title_font(), GameConfig.FS_BUTTON + 2, 611)
	resume_btn.pressed.connect(_close_pause_menu)
	footer.add_child(resume_btn)

	var sk_btn: Button = Button.new()
	sk_btn.text = "Yetenekler"
	sk_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(sk_btn, GameConfig.COLOR_DUST_PINK, font, GameConfig.FS_BUTTON, 612)
	sk_btn.pressed.connect(func() -> void:
		var sm: SkillsModal = SkillsModal.new()
		sm.process_mode = Node.PROCESS_MODE_ALWAYS
		_pause_overlay.add_child(sm)
		sm.open_for(NetworkManager.selected_char_id, false)
	)
	footer.add_child(sk_btn)

	var m_btn: Button = Button.new()
	m_btn.text = "Ana Menü"
	m_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(m_btn, GameConfig.COLOR_CREAM.darkened(0.04), font, GameConfig.FS_BUTTON, 613)
	m_btn.pressed.connect(func() -> void:
		get_tree().paused = false
		menu_requested.emit()
	)
	footer.add_child(m_btn)


func _close_pause_menu() -> void:
	get_tree().paused = false
	if _pause_overlay != null and is_instance_valid(_pause_overlay):
		_pause_overlay.queue_free()
	_pause_overlay = null


## Dokunmatik cihazda kontrol şemasına göre, masaüstünde klavyeye göre yetenek ipucu.
func _skill_key_hint(slot: String) -> String:
	if slot == "pasif":
		return "Pasif"
	var is_touch: bool = DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")
	if not is_touch:
		return "E / Sağ" if slot == "aktif1" else "Q / Küçül"
	if AudioManager.control_scheme == "buttons":
		return "Yetenek butonu" if slot == "aktif1" else "Küçül butonu"
	return "Yukarı kaydır" if slot == "aktif1" else "Aşağı kaydır"


## Maç başı geri sayım sırasında yetenek özet kartı gösterir.
func show_match_skill_summary(char_id: String) -> void:
	hide_match_skill_summary()
	var cdata: Dictionary = CharacterData.get_character(char_id)
	_skill_summary_card = PanelContainer.new()
	_skill_summary_card.name = "SkillSummary"
	_skill_summary_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_skill_summary_card, GameConfig.COLOR_CREAM, 620, GameConfig.SP_M)
	add_child(_skill_summary_card)

	var v: VBoxContainer = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	_skill_summary_card.add_child(v)

	var hdr: Label = Label.new()
	hdr.text = "%s: Yeteneklerin" % str(cdata["display_name"])
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(hdr, GameConfig.FS_BODY, GameConfig.COLOR_WARN_RED, true)
	v.add_child(hdr)

	var skills: Array = cdata.get("skills", []) as Array
	for sk_v: Variant in skills:
		var sk: Dictionary = sk_v as Dictionary
		var sl: String = str(sk.get("slot", "pasif"))
		var row: VBoxContainer = VBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_constant_override("separation", 0)
		v.add_child(row)
		var name_lbl: Label = Label.new()
		name_lbl.text = "%s  ·  %s" % [str(sk.get("name", "")), _skill_key_hint(sl)]
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(name_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_INK, true)
		row.add_child(name_lbl)
		var desc_lbl: Label = Label.new()
		desc_lbl.text = str(sk.get("desc", ""))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(desc_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
		row.add_child(desc_lbl)

	_skill_summary_card.modulate.a = 0.0
	_layout_skill_card()
	_layout_skill_card.call_deferred()
	var tw: Tween = create_tween()
	tw.tween_property(_skill_summary_card, "modulate:a", 1.0, HUD_ANIM_SEC)


func _layout_skill_card() -> void:
	if _skill_summary_card == null or not is_instance_valid(_skill_summary_card):
		return
	var sr: Rect2 = _safe_rect()
	var w: float = minf(SKILL_CARD_MAX_W, sr.size.x)
	_skill_summary_card.custom_minimum_size = Vector2(w, 0.0)
	_skill_summary_card.size = Vector2(w, 0.0)
	_skill_summary_card.reset_size()
	var h: float = _skill_summary_card.size.y
	var strip_top: float = _counter_strip.position.y + minf(0.0, ability_button.position.y)
	# Geri sayımın altına, alt şeridin üstüne
	var y: float = sr.get_center().y + 110.0
	y = minf(y, strip_top - h - GameConfig.SP_M)
	y = maxf(y, _notice_stack.position.y)
	_skill_summary_card.position = Vector2(sr.position.x + (sr.size.x - w) * 0.5, y)


func hide_match_skill_summary() -> void:
	if _skill_summary_card != null and is_instance_valid(_skill_summary_card):
		var card: PanelContainer = _skill_summary_card
		_skill_summary_card = null
		var tw: Tween = create_tween()
		tw.tween_property(card, "modulate:a", 0.0, 0.25)
		tw.parallel().tween_property(card, "position:y", card.position.y + 60.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func() -> void:
			if is_instance_valid(card):
				card.queue_free()
		)


## Cihaz başına bir kez gösterilen 2 sn'lik ipucu.
func show_first_time_tip(tip_key: String, text: String) -> void:
	if _tip_banner == null or AudioManager.has_seen_tip(tip_key):
		return
	AudioManager.mark_tip_seen(tip_key)
	var lbl: Label = _tip_banner.get_node_or_null("TipLabel") as Label
	if lbl != null:
		lbl.text = GameConfig.censor(text)
	_tip_banner.visible = true
	_tip_banner.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(_tip_banner, "modulate:a", 1.0, HUD_ANIM_SEC)
	tw.tween_interval(2.0)
	tw.tween_property(_tip_banner, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		if is_instance_valid(_tip_banner):
			_tip_banner.visible = false
	)


## Yerel ölümde 2.5 sn siyah-beyaz efekt (dünya akmaya devam eder).
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


func show_swipe_arrow(from_pos: Vector2, to_pos: Vector2) -> void:
	var arrow: Line2D = Line2D.new()
	arrow.width = 7.0
	arrow.default_color = HUD_TIP_BG
	arrow.add_point(from_pos)
	arrow.add_point(to_pos)
	add_child(arrow)
	var tw: Tween = create_tween()
	tw.tween_property(arrow, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func() -> void:
		if is_instance_valid(arrow):
			arrow.queue_free()
	)


# ---------------------------------------------------------------------------
# Maç sonu: zafer turu ve sıralama
# ---------------------------------------------------------------------------

## Zafer turu bandı ve kazanan için "Bitir" butonu (bildirim yığınında).
func show_victory_lap_banner(is_winner: bool, winner_name: String) -> void:
	if _victory_banner != null and is_instance_valid(_victory_banner):
		_victory_banner.queue_free()
	_victory_banner = PanelContainer.new()
	_victory_banner.name = "VictoryBanner"
	_victory_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_bitten_panel(_victory_banner, HUD_TIP_BG, 630, GameConfig.SP_S)
	_notice_stack.add_child(_victory_banner)
	_notice_stack.move_child(_victory_banner, spectator_label.get_index() + 1)

	var lbl: Label = Label.new()
	if is_winner:
		lbl.text = "KAZANDIN! Zafer turu: bakalım daha ne kadar gidebilirsin"
	else:
		lbl.text = "%s kazandı! Zafer turu izleniyor..." % winner_name
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	_victory_banner.add_child(lbl)

	if _finish_lap_btn != null and is_instance_valid(_finish_lap_btn):
		_finish_lap_btn.queue_free()
		_finish_lap_btn = null
	if is_winner:
		_finish_lap_btn = Button.new()
		_finish_lap_btn.text = "Bitir"
		_finish_lap_btn.custom_minimum_size = Vector2(200.0, 60.0)
		_finish_lap_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ComicUiHelper.style_bitten_button(_finish_lap_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON, 631)
		_finish_lap_btn.pressed.connect(func() -> void:
			finish_victory_lap_requested.emit()
		)
		_notice_stack.add_child(_finish_lap_btn)
		_notice_stack.move_child(_finish_lap_btn, _victory_banner.get_index() + 1)


## "MAHALLE SONUÇLARI" sıralama ekranını sondan başa animasyonla açar.
func show_results_ranking(results: Array, local_pid: int, _is_host: bool) -> void:
	spectator_label.visible = false
	ability_button.visible = false
	if _ability2_btn != null:
		_ability2_btn.visible = false
	_counter_strip.visible = false
	_close_target_picker()
	if _ghost_strip != null:
		_ghost_strip.visible = false
	if _victory_banner != null and is_instance_valid(_victory_banner):
		_victory_banner.queue_free()
	if _finish_lap_btn != null and is_instance_valid(_finish_lap_btn):
		_finish_lap_btn.queue_free()
	if _results_panel != null and is_instance_valid(_results_panel):
		_results_panel.queue_free()

	var font: Font = AssetHelper.get_ui_font()
	var modal: Dictionary = ComicUiHelper.build_modal(self, "MAHALLE SONUÇLARI", GameConfig.COLOR_CREAM, 0.0, false)
	_results_panel = modal["root"] as Control
	_results_panel.z_index = 80
	var title_lbl: Label = modal["title"] as Label
	title_lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	var rows_v: VBoxContainer = modal["body"] as VBoxContainer
	var footer: VBoxContainer = modal["footer"] as VBoxContainer

	# Faz 10.3: yerel oyuncunun önden portresi (1. gururlu, 2. küs, diğerleri sinirli)
	var my_row: Dictionary = {}
	for r_v: Variant in results:
		var rd: Dictionary = r_v as Dictionary
		if int(rd.get("peer_id", -1)) == local_pid:
			my_row = rd
	var portrait_box: CenterContainer = CenterContainer.new()
	portrait_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rows_v.add_child(portrait_box)
	var rank_portrait: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	rank_portrait.custom_minimum_size = Vector2(RESULTS_PORTRAIT_SIZE, RESULTS_PORTRAIT_SIZE)
	portrait_box.add_child(rank_portrait)
	var my_cid: String = str(my_row.get("char_id", NetworkManager.selected_char_id))
	var my_rank: int = int(my_row.get("rank", 3))
	var my_expr: String = CharacterPortrait.EXPR_ANGRY
	var my_line: String = CharacterData.get_random_lose_line(my_cid)
	if my_rank == 1:
		my_expr = CharacterPortrait.EXPR_PROUD
		my_line = CharacterData.get_random_win_line(my_cid)
	elif my_rank == 2:
		my_expr = CharacterPortrait.EXPR_SULK
		my_line = "Az kalmıştı…"
	rank_portrait.setup(my_cid, my_expr)
	rank_portrait.pop_in()
	rank_portrait.say(my_line, 2.4)
	_rematch_portrait = rank_portrait
	_rematch_pressed = false

	# Yer tutucu boş satırlar oluşturup sondan başa doğru doldur
	var row_slots: Array[Control] = []
	for _i: int in range(results.size()):
		var slot_box: Control = Control.new()
		slot_box.custom_minimum_size = Vector2(0.0, RESULTS_ROW_H)
		slot_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rows_v.add_child(slot_box)
		row_slots.append(slot_box)

	# Faz 11.2: herkeste büyük RÖVANŞ! butonu + sayaç
	_rematch_label = Label.new()
	_rematch_label.name = "RematchLabel"
	_rematch_label.text = "Rövanş: 0 / %d" % results.size()
	_rematch_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rematch_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_rematch_label, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	footer.add_child(_rematch_label)

	_rematch_btn = Button.new()
	_rematch_btn.name = "RematchButton"
	_rematch_btn.text = "RÖVANŞ!"
	_rematch_btn.custom_minimum_size = Vector2(0.0, 76.0)
	ComicUiHelper.style_bitten_button(_rematch_btn, GameConfig.COLOR_GREEN_GO, AssetHelper.get_title_font(), GameConfig.FS_H2, 646)
	_rematch_btn.pressed.connect(_on_rematch_pressed)
	_connect_button_tween(_rematch_btn)
	footer.add_child(_rematch_btn)

	_rematch_force_btn = Button.new()
	_rematch_force_btn.name = "RematchForceButton"
	_rematch_force_btn.text = "Kabul edenlerle başlat"
	_rematch_force_btn.custom_minimum_size = Vector2(0.0, 60.0)
	_rematch_force_btn.visible = false
	ComicUiHelper.style_bitten_button(_rematch_force_btn, GameConfig.COLOR_GOLD, font, GameConfig.FS_BODY, 647)
	_rematch_force_btn.pressed.connect(func() -> void:
		_rematch_force_btn.disabled = true
		rematch_force_requested.emit()
	)
	footer.add_child(_rematch_force_btn)

	var footer_h: HBoxContainer = HBoxContainer.new()
	footer_h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer_h.add_theme_constant_override("separation", GameConfig.SP_S)
	footer.add_child(footer_h)

	var share_btn: Button = Button.new()
	share_btn.text = "Paylaş"
	share_btn.custom_minimum_size = Vector2(130.0, 60.0)
	ComicUiHelper.style_bitten_button(share_btn, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_BODY, 643)
	share_btn.pressed.connect(func() -> void:
		var my_scare: int = int(my_row.get("score", 0))
		var txt: String = GameConfig.SHARE_TEXT_KING.replace("{n}", str(my_scare)).replace("{link}", GameConfig.SHARE_SITE_URL)
		share_portrait_card(my_cid, my_expr, my_line, "%d. oldum · %d kişiyi korkuttum" % [my_rank, my_scare], txt, share_btn)
	)
	footer_h.add_child(share_btn)
	if has_death_card():
		footer_h.add_child(_make_death_card_button(font))

	rank_portrait.one_more_requested.connect(func() -> void:
		if _rematch_btn != null and is_instance_valid(_rematch_btn) and not _rematch_btn.disabled:
			_pulse_button(_rematch_btn)
	)

	var lob_btn: Button = Button.new()
	lob_btn.text = "Menüye Dön" if NetworkManager.is_offline_bots else "Lobiye Dön"
	lob_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lob_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(lob_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BODY, 642)
	lob_btn.pressed.connect(func() -> void:
		return_lobby_requested.emit()
	)
	footer_h.add_child(lob_btn)

	# Sondan başa doğru 0.4 sn arayla kayarak gelsin
	for idx: int in range(results.size() - 1, -1, -1):
		var row_data: Dictionary = results[idx] as Dictionary
		var row_card: PanelContainer = _build_result_row(row_data, local_pid, font)
		row_slots[idx].add_child(row_card)
		row_card.anchor_left = 0.0
		row_card.anchor_right = 1.0
		row_card.offset_left = 0.0
		row_card.offset_right = 0.0
		row_card.offset_top = 60.0
		row_card.offset_bottom = 60.0 + RESULTS_ROW_H - 6.0
		row_card.modulate.a = 0.0
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



## Faz 11.2: RÖVANŞ! basıldı: portre ciddileşir, "Bi daha!" der; buton bekleme durumuna geçer.
func _on_rematch_pressed() -> void:
	if _rematch_pressed:
		return
	_rematch_pressed = true
	if _rematch_btn != null and is_instance_valid(_rematch_btn):
		_rematch_btn.disabled = true
		_rematch_btn.text = "Bi daha!"
	if _rematch_portrait != null and is_instance_valid(_rematch_portrait):
		_rematch_portrait.set_expression(CharacterPortrait.EXPR_SERIOUS)
		_rematch_portrait.say("Bi daha!", 2.0)
	rematch_requested.emit()


## Rövanş sayacını ve oda sahibi seçeneklerini günceller.
func update_rematch(accepted: Array, total: int, state: int, seconds_left: float, local_pid: int, is_owner: bool) -> void:
	if _rematch_label == null or not is_instance_valid(_rematch_label):
		return
	var txt: String = "Rövanş: %d / %d" % [accepted.size(), total]
	if state == GameConfig.REMATCH_STATE_STARTING:
		txt += "  ·  Yeni maç başlıyor!"
		if _rematch_btn != null and is_instance_valid(_rematch_btn):
			_rematch_btn.disabled = true
	elif state == GameConfig.REMATCH_STATE_TIMEOUT:
		txt += "  ·  Herkes gelmedi"
	elif seconds_left > 0.0:
		txt += "  ·  %d sn" % ceili(seconds_left)
	_rematch_label.text = txt
	if accepted.has(local_pid) and not _rematch_pressed and _rematch_btn != null and is_instance_valid(_rematch_btn):
		_rematch_pressed = true
		_rematch_btn.disabled = true
		_rematch_btn.text = "Bi daha!"
	if _rematch_force_btn != null and is_instance_valid(_rematch_force_btn):
		_rematch_force_btn.visible = is_owner and state == GameConfig.REMATCH_STATE_TIMEOUT


func _build_result_row(row: Dictionary, local_pid: int, font: Font) -> PanelContainer:
	var rank: int = int(row.get("rank", 1))
	var pid: int = int(row.get("peer_id", 0))
	var p_name: String = str(row.get("name", "Böcek"))
	var row_is_bot: bool = bool(row.get("is_bot", false))
	if row_is_bot:
		p_name += " · BOT"
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
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FBF6EC") if pid != local_pid else Color("#EAF2E2")
	if row_is_bot:
		sb.bg_color = Color("#ECE8E2")
	sb.border_color = GameConfig.COLOR_WARN_RED if pid == local_pid else GameConfig.COLOR_INK
	sb.set_border_width_all(4 if pid == local_pid else 2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(8)
	card.add_theme_stylebox_override("panel", sb)

	var h: HBoxContainer = HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", 10)
	card.add_child(h)

	var rank_col: Color = GameConfig.COLOR_DARK_TEXT
	if rank == 1:
		rank_col = Color("#C8930F")
	elif rank == 2:
		rank_col = Color("#7D8790")
	elif rank == 3:
		rank_col = Color("#B87333")

	var rank_lbl: Label = Label.new()
	rank_lbl.text = "%d." % rank
	rank_lbl.custom_minimum_size = Vector2(44.0, 0.0)
	rank_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(rank_lbl, GameConfig.FS_H2, rank_col, true)
	h.add_child(rank_lbl)

	var icon_r: TextureRect = TextureRect.new()
	icon_r.custom_minimum_size = Vector2(60.0, 60.0)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_r.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	h.add_child(icon_r)

	var info_v: VBoxContainer = VBoxContainer.new()
	info_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_v.alignment = BoxContainer.ALIGNMENT_CENTER
	info_v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_v.add_theme_constant_override("separation", 0)
	h.add_child(info_v)

	var name_lbl: Label = Label.new()
	name_lbl.text = "%s  (+%d Puan)" % [p_name, pts]
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.add_theme_font_override("font", AssetHelper.get_title_font())
	name_lbl.add_theme_font_size_override("font_size", GameConfig.FS_SMALL)
	name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	info_v.add_child(name_lbl)

	var stats_lbl: Label = Label.new()
	stats_lbl.text = "Süre: %02d:%02d  ·  Ödü Kopan: %d" % [mins, secs, scares]
	stats_lbl.clip_text = true
	stats_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	stats_lbl.add_theme_font_override("font", font)
	stats_lbl.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
	stats_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	info_v.add_child(stats_lbl)

	if not badges.is_empty():
		var b_lbl: Label = Label.new()
		b_lbl.text = ", ".join(badges)
		b_lbl.clip_text = true
		b_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b_lbl.add_theme_font_override("font", font)
		b_lbl.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
		b_lbl.add_theme_color_override("font_color", Color("#9E4B3A"))
		info_v.add_child(b_lbl)

	return card


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


# ---------------------------------------------------------------------------
# Küçük stil yardımcıları
# ---------------------------------------------------------------------------

## Yarı saydam krem HUD zemini (ince mürekkep kontur).
func _hud_panel_style(radius: int, pad_x: int, pad_y: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = HUD_PANEL_BG
	sb.border_color = Color(0.141, 0.086, 0.055, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad_x
	sb.content_margin_right = pad_x
	sb.content_margin_top = pad_y
	sb.content_margin_bottom = pad_y
	return sb


## Etiket arkası için yuvarlak hap zemini.
func _pill_style(bg: Color, border: Color) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2 if border.a > 0.0 else 0)
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	return sb


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

# ---------------------------------------------------------------- Faz 10.3 yardımcıları

## Butonu dikkat çekmek için büyütüp nabız gibi attırır.
func _pulse_button(btn: Button) -> void:
	if btn == null or not is_instance_valid(btn) or not btn.visible:
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	btn.pivot_offset = btn.size * 0.5
	_pulse_tween = create_tween().set_loops(6)
	_pulse_tween.tween_property(btn, "scale", Vector2(1.12, 1.12), 0.22).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(btn, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_SINE)


func _ensure_death_share_button() -> void:
	if _death_share_btn != null and is_instance_valid(_death_share_btn):
		if _death_card_btn != null and is_instance_valid(_death_card_btn):
			_death_card_btn.visible = has_death_card()
		return
	var font: Font = AssetHelper.get_ui_font()
	_death_share_btn = Button.new()
	_death_share_btn.text = "Paylaş"
	_death_share_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_death_share_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(_death_share_btn, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_BUTTON, 644)
	_death_share_btn.pressed.connect(func() -> void:
		var txt: String = GameConfig.SHARE_TEXT_SOLO.replace("{skor}", str(_death_score)).replace("{link}", GameConfig.SHARE_SITE_URL)
		share_portrait_card(_death_char_id, CharacterPortrait.EXPR_ANGRY, _death_line, "%d kişiyi sandalyeye çıkardım" % _death_score, txt, _death_share_btn)
	)
	var vbox: Node = menu_button.get_parent()
	# Faz 11.3: Paylaş + Ölüm Karesi yan yana
	var share_row: HBoxContainer = HBoxContainer.new()
	share_row.name = "ShareRow"
	share_row.add_theme_constant_override("separation", GameConfig.SP_S)
	vbox.add_child(share_row)
	vbox.move_child(share_row, menu_button.get_index())
	share_row.add_child(_death_share_btn)
	_connect_button_tween(_death_share_btn)
	_death_card_btn = _make_death_card_button(font)
	share_row.add_child(_death_card_btn)
	_death_card_btn.visible = has_death_card()


## Çok oyunculu elenme anında köşede kısa süre küçük sinirli portre gösterir (izlemeyi engellemez).
func show_mini_portrait(char_id: String) -> void:
	var vis: Rect2 = get_viewport().get_visible_rect()
	var side: float = vis.size.x * 0.4
	var mini: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	mini.interactive = false
	mini.size = Vector2(side, side)
	mini.position = Vector2(12.0, vis.size.y - side - GameConfig.COUNTER_STRIP_HEIGHT - 20.0)
	mini.z_index = 70
	add_child(mini)
	mini.setup(char_id, CharacterPortrait.EXPR_ANGRY)
	mini.pop_in()
	var tw: Tween = create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(mini, "modulate:a", 0.0, 0.3)
	tw.tween_callback(mini.queue_free)


## Faz 10.3: Sinirli büyük yüz + replik balonu + skor ile 1080x1350 dikey paylaşım kartı üretip paylaşır.
func share_portrait_card(char_id: String, expression: String, line: String, stat_text: String, share_text: String, btn: Button = null) -> void:
	var vp: SubViewport = SubViewport.new()
	vp.size = Vector2i(1080, 1350)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)

	var font: Font = AssetHelper.get_ui_font()
	var bg: ColorRect = ColorRect.new()
	bg.color = GameConfig.COLOR_CREAM
	bg.size = Vector2(1080.0, 1350.0)
	vp.add_child(bg)
	var dots: Control = Control.new()
	dots.size = bg.size
	dots.draw.connect(func() -> void:
		for yy: int in range(0, 1350, 36):
			for xx: int in range(0, 1080, 36):
				var off: float = 18.0 if (yy / 36) % 2 == 1 else 0.0
				dots.draw_circle(Vector2(float(xx) + off, float(yy)), 3.0, Color(0.95, 0.79, 0.66, 0.45))
	)
	vp.add_child(dots)

	var logo_path: String = "res://assets/sprites/title_logo.png"
	if ResourceLoader.exists(logo_path):
		var logo: TextureRect = TextureRect.new()
		logo.texture = load(logo_path) as Texture2D
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		logo.position = Vector2(140.0, 30.0)
		logo.size = Vector2(800.0, 220.0)
		vp.add_child(logo)

	var portrait: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	portrait.interactive = false
	portrait.size = Vector2(660.0, 660.0)
	portrait.position = Vector2(210.0, 470.0)
	vp.add_child(portrait)
	portrait.setup(char_id, expression)

	# Replik balonu (kartta sabit konumlu; portrenin kendi balonu kullanılmaz)
	var bubble: PanelContainer = PanelContainer.new()
	var b_sb: StyleBoxFlat = StyleBoxFlat.new()
	b_sb.bg_color = Color(1.0, 1.0, 0.98)
	b_sb.border_color = GameConfig.COLOR_DARK_TEXT
	b_sb.set_border_width_all(5)
	b_sb.set_corner_radius_all(32)
	b_sb.set_content_margin_all(26)
	bubble.add_theme_stylebox_override("panel", b_sb)
	bubble.position = Vector2(110.0, 270.0)
	bubble.custom_minimum_size = Vector2(860.0, 0.0)
	var b_lbl: Label = Label.new()
	b_lbl.text = GameConfig.censor(line)
	b_lbl.custom_minimum_size = Vector2(800.0, 0.0)
	b_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b_lbl.add_theme_font_override("font", font)
	b_lbl.add_theme_font_size_override("font_size", 46)
	b_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	bubble.add_child(b_lbl)
	vp.add_child(bubble)
	var tail: Polygon2D = Polygon2D.new()
	tail.polygon = PackedVector2Array([Vector2(500.0, 0.0), Vector2(580.0, 0.0), Vector2(520.0, 60.0)])
	tail.color = GameConfig.COLOR_DARK_TEXT
	tail.position = Vector2(0.0, 380.0)
	vp.add_child(tail)

	var stat: Label = Label.new()
	stat.text = stat_text
	stat.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stat.position = Vector2(40.0, 1150.0)
	stat.size = Vector2(1000.0, 70.0)
	stat.add_theme_font_override("font", font)
	stat.add_theme_font_size_override("font_size", 52)
	stat.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	vp.add_child(stat)

	var cta: Label = Label.new()
	cta.text = "Sıra sende!  " + GameConfig.SHARE_SITE_URL.replace("https://", "")
	cta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cta.position = Vector2(40.0, 1240.0)
	cta.size = Vector2(1000.0, 60.0)
	cta.add_theme_font_override("font", font)
	cta.add_theme_font_size_override("font_size", 34)
	cta.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	vp.add_child(cta)

	await get_tree().process_frame
	tail.position = Vector2(0.0, bubble.position.y + bubble.size.y - 4.0)
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	vp.queue_free()
	if img == null or img.is_empty():
		share_current_screen(share_text, btn)
		return
	img.save_png("user://paylas.png")
	if Engine.has_singleton("GodotShare"):
		var abs_path: String = ProjectSettings.globalize_path("user://paylas.png")
		Engine.get_singleton("GodotShare").call("sharePic", abs_path, "Skor Paylaş", "Uçan Hamam Böceği", share_text)
	else:
		DisplayServer.clipboard_set(share_text)
		if btn != null:
			btn.text = "Panoya kopyalandı"


# ---------------------------------------------------------------- Faz 11.3: Ölüm Karesi

## GameWorld ölüm anında çağırır: yakalanan kareler + bilgiler (kart butona basınca çizilir).
func set_death_card_data(recorder: DeathFrameRecorder, cause: String, char_id: String, score_val: int, run_sec: float) -> void:
	_death_card_img = null
	if recorder == null or not recorder.has_death:
		_death_card_data = {}
		return
	var t: Dictionary = Time.get_time_dict_from_system()
	var best: int = _load_best_score()
	_death_card_data = {
		"before": recorder.before_frame,
		"death": recorder.death_frame,
		"before_focus": recorder.before_focus,
		"death_focus": recorder.death_focus,
		"cause": cause,
		"char_id": char_id,
		"score": score_val,
		"line": "",
		"bg_id": NetworkManager.selected_bg_id,
		"narration": GameConfig.death_card_narration(int(t["hour"]), int(t["minute"]), score_val, best, run_sec),
	}


func has_death_card() -> bool:
	return not _death_card_data.is_empty()


func _make_death_card_button(font: Font) -> Button:
	var b: Button = Button.new()
	b.name = "DeathCardButton"
	b.text = "Ölüm Karesi"
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(b, GameConfig.COLOR_DUST_PINK, font, GameConfig.FS_BUTTON, 648)
	b.pressed.connect(open_death_card_preview)
	_connect_button_tween(b)
	return b


## Kartı (gerekirse) çizer ve büyük önizleme + Paylaş / Kapat penceresini açar.
func open_death_card_preview() -> void:
	if not has_death_card() or _death_card_busy:
		return
	var font: Font = AssetHelper.get_ui_font()
	var m: Dictionary = ComicUiHelper.build_modal(self, "ÖLÜM KARESİ", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalDeathCard"
	root.z_index = 96
	var body: VBoxContainer = m["body"] as VBoxContainer
	var footer: VBoxContainer = m["footer"] as VBoxContainer
	var status: Label = Label.new()
	status.text = "Çizer böcek çiziyor…"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(status, GameConfig.FS_BODY, GameConfig.COLOR_BROWN, false)
	body.add_child(status)
	var preview: TextureRect = TextureRect.new()
	preview.name = "DeathCardPreview"
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var sr: Rect2 = _safe_rect()
	var pw: float = minf(GameConfig.DEATH_CARD_PREVIEW_MAX_W, sr.size.x - float(GameConfig.SP_L) * 3.0)
	var ph: float = pw * float(GameConfig.DEATH_CARD_SIZE.y) / float(GameConfig.DEATH_CARD_SIZE.x)
	# Kısa ekranda önizleme yüksekliği sığsın (başlık + butonlar payı)
	var max_h: float = sr.size.y - GameConfig.DEATH_CARD_PREVIEW_CHROME_H
	if ph > max_h and max_h > 200.0:
		ph = max_h
		pw = ph * float(GameConfig.DEATH_CARD_SIZE.x) / float(GameConfig.DEATH_CARD_SIZE.y)
	preview.custom_minimum_size = Vector2(pw, ph)
	preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview.visible = false
	body.add_child(preview)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	footer.add_child(row)
	var share_b: Button = Button.new()
	share_b.text = "Paylaş"
	share_b.disabled = true
	share_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	share_b.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(share_b, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON, 649)
	row.add_child(share_b)
	var close_b: Button = Button.new()
	close_b.text = "Kapat"
	close_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_b.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(close_b, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 650)
	close_b.pressed.connect(root.queue_free)
	row.add_child(close_b)
	share_b.pressed.connect(func() -> void:
		_share_death_card(share_b)
	)

	if _death_card_img == null:
		_death_card_busy = true
		var data: Dictionary = _death_card_data.duplicate()
		var line: String = _death_line
		if line.is_empty() or NetworkManager.is_multiplayer_match:
			line = str(CharacterData.get_random_death_entry(str(data.get("char_id", "klasik")))["text"])
		data["line"] = line
		var maker: DeathComicCard = DeathComicCard.new()
		add_child(maker)
		_death_card_img = await maker.render(data)
		if is_instance_valid(maker):
			maker.queue_free()
		_death_card_busy = false
	if not is_instance_valid(root):
		return
	if _death_card_img == null:
		status.text = "Bu cihazda kart çizilemedi."
		return
	status.visible = false
	preview.texture = ImageTexture.create_from_image(_death_card_img)
	preview.visible = true
	share_b.disabled = false


## Kartı görsel + metin olarak paylaşır (eklenti yoksa metni panoya kopyalar). Görev olayı sayılır.
func _share_death_card(btn: Button) -> void:
	if _death_card_img == null:
		return
	if not FileAccess.file_exists(GameConfig.DEATH_CARD_PATH):
		_death_card_img.save_png(GameConfig.DEATH_CARD_PATH)
	var txt: String = GameConfig.SHARE_TEXT_DEATH_CARD.replace("{link}", GameConfig.SHARE_SITE_URL)
	if Engine.has_singleton("GodotShare"):
		var abs_path: String = ProjectSettings.globalize_path(GameConfig.DEATH_CARD_PATH)
		Engine.get_singleton("GodotShare").call("sharePic", abs_path, "Ölüm Karesi", "Uçan Hamam Böceği", txt)
	else:
		DisplayServer.clipboard_set(txt)
		if btn != null:
			btn.text = "Panoya kopyalandı"
	Monetization.quest_event("share_card")


# ---------------------------------------------------------------- Faz 11.4: görev bildirimi

## Maç içinde küçük görev bildirimi: sık güncellemeler seyreltilir, tamamlanma hemen gösterilir.
func _on_quest_progressed(text: String, completed: bool) -> void:
	if _quest_notice == null or not is_instance_valid(_quest_notice):
		return
	var now: int = Time.get_ticks_msec()
	var gap_ms: int = int(GameConfig.QUEST_NOTICE_MIN_GAP_SEC * 1000.0)
	if not completed and now - _quest_notice_last_ms < gap_ms:
		if _quest_notice.visible:
			_quest_notice.text = text
		return
	_quest_notice_last_ms = now
	_quest_notice.text = (text + "  Tamam!") if completed else text
	_quest_notice.visible = true
	_quest_notice.modulate.a = 1.0
	if _quest_notice_tween != null and _quest_notice_tween.is_valid():
		_quest_notice_tween.kill()
	_quest_notice_tween = create_tween()
	_quest_notice_tween.tween_interval(GameConfig.QUEST_NOTICE_LIFE_SEC)
	_quest_notice_tween.tween_property(_quest_notice, "modulate:a", 0.0, 0.3)
	_quest_notice_tween.tween_callback(func() -> void:
		if is_instance_valid(_quest_notice):
			_quest_notice.visible = false
	)


# ---------------------------------------------------------------- Faz 11.5 / 11.6

## Bildirim yığınında olay / albüm şeridi: başlık + (varsa) kısa açıklama.
func show_event_banner(title: String, sub: String, hold_sec: float = 2.2, bg: Color = GameConfig.COLOR_GOLD) -> void:
	if _event_banner == null or not is_instance_valid(_event_banner):
		return
	ComicUiHelper.style_bitten_panel(_event_banner, bg, 606, GameConfig.SP_S)
	_event_banner_title.text = title
	_event_banner_sub.text = sub
	_event_banner_sub.visible = not sub.is_empty()
	_event_banner.visible = true
	_event_banner.modulate.a = 0.0
	if _event_banner_tween != null and _event_banner_tween.is_valid():
		_event_banner_tween.kill()
	_event_banner_tween = create_tween()
	_event_banner_tween.tween_property(_event_banner, "modulate:a", 1.0, HUD_ANIM_SEC)
	_event_banner_tween.tween_interval(hold_sec)
	_event_banner_tween.tween_property(_event_banner, "modulate:a", 0.0, 0.3)
	_event_banner_tween.tween_callback(func() -> void:
		if is_instance_valid(_event_banner):
			_event_banner.visible = false
	)


## Annem Geldi: küçülme butonu parlar (bekleme süresi doldu).
func flash_ability2() -> void:
	if _ability2_btn == null or not is_instance_valid(_ability2_btn):
		return
	_ability2_btn.pivot_offset = _ability2_btn.size * 0.5
	var tw: Tween = create_tween()
	for i: int in range(3):
		tw.tween_property(_ability2_btn, "modulate", Color(1.6, 1.45, 0.7, 1.0), 0.16)
		tw.parallel().tween_property(_ability2_btn, "scale", Vector2(1.18, 1.18), 0.16)
		tw.tween_property(_ability2_btn, "modulate", Color.WHITE, 0.16)
		tw.parallel().tween_property(_ability2_btn, "scale", Vector2.ONE, 0.16)

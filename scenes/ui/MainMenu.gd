extends Control

## Ana menü ekranı: isim girişi ve mod seçimi.

const CARD_SCENE: PackedScene = preload("res://scenes/ui/CharacterCard.tscn")

var _cards: Dictionary = {}
var _bug_float_time: float = 0.0
var _bug_tap_btn: Button = null
var _bug_bubble: Label = null
var _bug_react_until: float = 0.0
var _slipper_peek: Sprite2D = null
var _peek_timer: float = 4.5
var _tap_count: int = 0
var _last_tap_ms: int = 0
var _last_tap_line_idx: int = -1
var _bug_fled: bool = false

@onready var bg_rect: TextureRect = $BgRect
@onready var menu_bug: Sprite2D = $MenuBug
@onready var title_label: Label = $CenterBox/TitleLabel
@onready var name_label: Label = $CenterBox/FormCard/VBox/NameLabel
@onready var name_input: LineEdit = $CenterBox/FormCard/VBox/NameInput
@onready var form_card: PanelContainer = $CenterBox/FormCard
@onready var char_grid: GridContainer = $CenterBox/CharGrid
@onready var bg_button: Button = $CenterBox/ButtonsBox/BgButton
@onready var solo_button: Button = $CenterBox/ButtonsBox/SoloButton
@onready var host_button: Button = $CenterBox/ButtonsBox/HostButton
@onready var join_button: Button = $CenterBox/ButtonsBox/JoinButton
@onready var sound_button: Button = $CenterBox/ButtonsBox/SettingsBox/SoundButton
@onready var vib_button: Button = $CenterBox/ButtonsBox/SettingsBox/VibButton
@onready var notice_label: Label = $CenterBox/NoticeLabel
@onready var join_panel: PanelContainer = $JoinPanel
@onready var join_title: Label = $JoinPanel/VBox/JoinTitle
@onready var rooms_list: VBoxContainer = $JoinPanel/VBox/RoomsScroll/RoomsList
@onready var ip_input: LineEdit = $JoinPanel/VBox/ManualBox/IpInput
@onready var connect_btn: Button = $JoinPanel/VBox/ManualBox/ConnectBtn
@onready var join_status_label: Label = $JoinPanel/VBox/JoinStatusLabel
@onready var close_join_btn: Button = $JoinPanel/VBox/CloseJoinBtn


func _ready() -> void:
	_apply_bg_theme()
	AudioManager.play_music("res://assets/sounds/muzik_menu.ogg")
	name_input.max_length = GameConfig.MAX_NAME_LENGTH
	name_input.text = NetworkManager.local_player_name

	host_button.disabled = false
	join_button.disabled = false
	join_panel.visible = false

	bg_button.pressed.connect(_on_bg_pressed)
	solo_button.pressed.connect(_on_solo_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	sound_button.pressed.connect(_on_sound_pressed)
	vib_button.pressed.connect(_on_vib_pressed)
	connect_btn.pressed.connect(_on_manual_connect_pressed)
	close_join_btn.pressed.connect(_on_close_join_pressed)
	name_input.text_changed.connect(_on_name_changed)

	NetworkManager.get_discovery().rooms_updated.connect(_on_rooms_updated)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)

	if not NetworkManager.pending_notice.is_empty():
		notice_label.text = NetworkManager.pending_notice
		notice_label.visible = true
		NetworkManager.pending_notice = ""

	_populate_character_cards()
	_refresh_menu_bug()
	_refresh_settings_buttons()
	_apply_styles()
	_setup_title_logo()
	_setup_daily_button()
	_setup_menu_polish()
	_connect_button_tween(bg_button)
	_connect_button_tween(solo_button)
	_connect_button_tween(host_button)
	_connect_button_tween(join_button)


func _setup_menu_polish() -> void:
	var font: Font = AssetHelper.get_ui_font()

	# 1. Buzdolabı Notu: hafif eğik FormCard + üst köşelerde sarı koli bandı şeritleri
	form_card.pivot_offset = Vector2(280.0, 40.0)
	form_card.rotation = deg_to_rad(-1.1)
	for tape_idx: int in range(2):
		var tape: ColorRect = ColorRect.new()
		tape.name = "Tape_%d" % tape_idx
		tape.size = Vector2(72.0, 20.0)
		tape.color = Color(0.96, 0.85, 0.44, 0.72)
		tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tape.position = Vector2(18.0 if tape_idx == 0 else 480.0, -8.0)
		tape.rotation = deg_to_rad(-16.0 if tape_idx == 0 else 14.0)
		form_card.add_child(tape)

	# 2. Tek Dokunuşta Hızlı Başlat ("HEMEN UÇ!") + Kompakt 2'li Çoklu Oyun Sırası
	solo_button.text = "HEMEN UÇ!"
	solo_button.custom_minimum_size = Vector2(0.0, 72.0)
	ComicUiHelper.style_bitten_button(solo_button, Color("#8FD17C"), font, 30, 103)

	var btn_box: VBoxContainer = $CenterBox/ButtonsBox
	var mp_row: HBoxContainer = HBoxContainer.new()
	mp_row.name = "MultiplayerRow"
	mp_row.add_theme_constant_override("separation", 12)
	btn_box.add_child(mp_row)
	btn_box.move_child(mp_row, host_button.get_index())
	host_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_button.reparent(mp_row)
	join_button.reparent(mp_row)

	var online_btn: Button = Button.new()
	online_btn.name = "OnlineButton"
	online_btn.text = "Çevrimiçi"
	online_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(online_btn, Color("#A9D2E8"), font, 20, 114)
	online_btn.pressed.connect(_open_online_modal)
	mp_row.add_child(online_btn)

	# Arka Plan butonunu alttaki SettingsBox sırasına kompakt hap olarak ekle
	var settings_box: HBoxContainer = $CenterBox/ButtonsBox/SettingsBox
	bg_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bg_button.reparent(settings_box)
	settings_box.move_child(bg_button, 0)
	ComicUiHelper.style_bitten_button(bg_button, Color("#EDE0CE"), font, 17, 101)
	ComicUiHelper.style_bitten_button(sound_button, Color("#F6EFE4"), font, 17, 106)
	ComicUiHelper.style_bitten_button(vib_button, Color("#F6EFE4"), font, 17, 107)

	# 2b. Yetenekler, Nasıl Oynanır? ve Argo Sansürü sırası
	var extra_row: HBoxContainer = HBoxContainer.new()
	extra_row.name = "ExtraRow"
	extra_row.add_theme_constant_override("separation", 8)
	btn_box.add_child(extra_row)

	var skills_btn: Button = Button.new()
	skills_btn.text = "Yetenekler"
	skills_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(skills_btn, GameConfig.COLOR_DUST_PINK, font, 16, 111)
	skills_btn.pressed.connect(func() -> void:
		var sm: SkillsModal = SkillsModal.new()
		add_child(sm)
		sm.open_for(NetworkManager.selected_char_id, true)
		sm.character_chosen.connect(_on_card_selected)
	)
	extra_row.add_child(skills_btn)

	var guide_btn: Button = Button.new()
	guide_btn.text = "Nasıl Oynanır?"
	guide_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(guide_btn, GameConfig.COLOR_DUST_BLUE, font, 16, 112)
	guide_btn.pressed.connect(func() -> void:
		var gm: GuideModal = GuideModal.new()
		add_child(gm)
	)
	extra_row.add_child(guide_btn)

	var censor_btn: Button = Button.new()
	censor_btn.name = "CensorButton"
	censor_btn.text = "Sansür: %s" % ("Açık" if AudioManager.is_censor_enabled else "Kapalı")
	censor_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(censor_btn, GameConfig.COLOR_CREAM, font, 16, 113)
	censor_btn.pressed.connect(func() -> void:
		AudioManager.set_censor_enabled(not AudioManager.is_censor_enabled)
		censor_btn.text = "Sansür: %s" % ("Açık" if AudioManager.is_censor_enabled else "Kapalı")
	)
	extra_row.add_child(censor_btn)

	var ctrl_btn: Button = Button.new()
	ctrl_btn.text = "Kontroller"
	ctrl_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(ctrl_btn, Color("#EDE0CE"), font, 16, 115)
	ctrl_btn.pressed.connect(_open_controls_modal)
	extra_row.add_child(ctrl_btn)

	var shop_btn: Button = Button.new()
	shop_btn.text = "Pazar"
	shop_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(shop_btn, Color("#F2C96B"), font, 16, 116)
	shop_btn.pressed.connect(func() -> void:
		var sh: ShopModal = ShopModal.new()
		add_child(sh)
		sh.character_equipped.connect(_on_card_selected)
	)
	extra_row.add_child(shop_btn)

	if not AudioManager.guide_seen:
		var gm_auto: GuideModal = GuideModal.new()
		add_child(gm_auto)

	# 3. Canlı Sahne Etkileşimi: Tıklanabilir menü böceği + gizlice uzanan terlik
	_bug_tap_btn = Button.new()
	_bug_tap_btn.name = "BugTapButton"
	_bug_tap_btn.size = Vector2(120.0, 120.0)
	_bug_tap_btn.flat = true
	_bug_tap_btn.focus_mode = Control.FOCUS_NONE
	_bug_tap_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_bug_tap_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_bug_tap_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_bug_tap_btn.pressed.connect(_on_menu_bug_tapped)
	add_child(_bug_tap_btn)

	_bug_bubble = Label.new()
	_bug_bubble.name = "BugBubble"
	_bug_bubble.visible = false
	_bug_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bug_bubble.add_theme_font_override("font", font)
	_bug_bubble.add_theme_font_size_override("font_size", 18)
	_bug_bubble.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	_bug_bubble.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	_bug_bubble.add_theme_constant_override("outline_size", 5)
	add_child(_bug_bubble)

	_slipper_peek = Sprite2D.new()
	_slipper_peek.name = "SlipperPeek"
	_slipper_peek.texture = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(140, 220))
	_slipper_peek.position = Vector2(780.0, 260.0)
	_slipper_peek.rotation = deg_to_rad(-28.0)
	_slipper_peek.scale = Vector2(0.85, 0.85)
	_slipper_peek.z_index = 4
	add_child(_slipper_peek)


func _on_menu_bug_tapped() -> void:
	if _bug_fled:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_tap_ms <= 1500:
		_tap_count += 1
	else:
		_tap_count = 1
	_last_tap_ms = now_ms

	var cid: String = NetworkManager.selected_char_id
	var cdata: Dictionary = CharacterData.get_character(cid)
	_bug_react_until = _bug_float_time + 0.8

	if _tap_count >= 10:
		_bug_fled = true
		_tap_count = 0
		AudioManager.play_character_voice(cid, "kactim")
		_bug_bubble.text = str(cdata.get("flee_line", "Tamam, ben kaçtım!"))
		_bug_bubble.position = menu_bug.position + Vector2(-60.0, -76.0)
		_bug_bubble.visible = true
		_bug_bubble.modulate.a = 1.0
		var ftw: Tween = create_tween()
		ftw.tween_property(menu_bug, "position:x", 840.0, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		ftw.tween_interval(2.0)
		ftw.tween_property(menu_bug, "position:x", 590.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ftw.tween_callback(func() -> void:
			_bug_fled = false
			_bug_bubble.visible = false
		)
		return

	var line_txt: String = ""
	if _tap_count == 3:
		AudioManager.play_character_voice(cid, "durtme")
		line_txt = str(cdata.get("poke_line", "Dürtme beni!"))
	else:
		var taps: Array = cdata.get("tap_lines", ["Efendim?"]) as Array
		var idx: int = randi() % maxi(taps.size(), 1)
		if taps.size() > 1 and idx == _last_tap_line_idx:
			idx = (idx + 1) % taps.size()
		_last_tap_line_idx = idx
		line_txt = str(taps[idx]) if not taps.is_empty() else "Efendim?"
		AudioManager.play_character_voice(cid, "dokun_%d" % (idx + 1))

	_bug_bubble.text = line_txt
	_bug_bubble.position = menu_bug.position + Vector2(-60.0, -76.0)
	_bug_bubble.visible = true
	_bug_bubble.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_property(menu_bug, "scale", Vector2(1.26, 1.26), 0.1)
	tw.tween_property(menu_bug, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK)
	var btw: Tween = create_tween()
	btw.tween_interval(1.1)
	btw.tween_property(_bug_bubble, "modulate:a", 0.0, 0.35)
	btw.tween_callback(func() -> void:
		if is_instance_valid(_bug_bubble):
			_bug_bubble.visible = false
	)


func _setup_title_logo() -> void:
	var scrim: ColorRect = ColorRect.new()
	scrim.name = "BgScrim"
	scrim.color = Color(0.08, 0.05, 0.03, 0.22)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	move_child(scrim, bg_rect.get_index() + 1)

	var logo_path: String = "res://assets/sprites/title_logo.png"
	if not ResourceLoader.exists(logo_path):
		return
	var logo_tex: Texture2D = load(logo_path) as Texture2D
	if logo_tex == null:
		return
	title_label.visible = false
	var logo_rect: TextureRect = TextureRect.new()
	logo_rect.name = "TitleLogo"
	logo_rect.texture = logo_tex
	logo_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_rect.custom_minimum_size = Vector2(640.0, 185.0)
	var center_box: VBoxContainer = $CenterBox
	center_box.add_child(logo_rect)
	center_box.move_child(logo_rect, 0)


func _process(delta: float) -> void:
	_bug_float_time += delta
	menu_bug.position.y = 110.0 + sin(_bug_float_time * 3.0) * 14.0
	if _bug_float_time < _bug_react_until:
		menu_bug.rotation = sin(_bug_float_time * 26.0) * deg_to_rad(18.0)
	else:
		menu_bug.rotation = sin(_bug_float_time * 2.2) * deg_to_rad(8.0)
	if _bug_tap_btn != null:
		_bug_tap_btn.position = menu_bug.position - Vector2(60.0, 60.0)

	_peek_timer -= delta
	if _peek_timer <= 0.0 and _slipper_peek != null:
		_peek_timer = randf_range(7.0, 11.0)
		var ptw: Tween = create_tween()
		ptw.tween_property(_slipper_peek, "position:x", 645.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ptw.tween_interval(0.55)
		ptw.tween_property(_slipper_peek, "position:x", 780.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _refresh_menu_bug() -> void:
	var cdata: Dictionary = CharacterData.get_character(NetworkManager.selected_char_id)
	menu_bug.texture = AssetHelper.texture(
		str(cdata["sprite_path"]),
		str(cdata["fallback_kind"]),
		GameConfig.PLAYER_SPRITE_SIZE
	)


func _refresh_settings_buttons() -> void:
	sound_button.text = "Ses: %s" % ("Kapalı" if AudioManager.is_muted else "Açık")
	vib_button.text = "Titreşim: %s" % ("Açık" if AudioManager.is_vibration_enabled else "Kapalı")


func _on_sound_pressed() -> void:
	AudioManager.set_muted(not AudioManager.is_muted)
	_refresh_settings_buttons()


func _on_vib_pressed() -> void:
	AudioManager.set_vibration_enabled(not AudioManager.is_vibration_enabled)
	_refresh_settings_buttons()


func _apply_bg_theme() -> void:
	var bg_theme: Dictionary = GameConfig.get_bg_theme(NetworkManager.selected_bg_id)
	bg_rect.texture = AssetHelper.texture(
		str(bg_theme["path"]),
		str(bg_theme["kind"]),
		GameConfig.BG_SIZE
	)
	bg_button.text = "Mekan: %s" % str(bg_theme["name"])


func _on_bg_pressed() -> void:
	var idx: int = 0
	for i: int in range(GameConfig.BG_THEMES.size()):
		if str(GameConfig.BG_THEMES[i]["id"]) == NetworkManager.selected_bg_id:
			idx = i
			break
	var next_idx: int = (idx + 1) % GameConfig.BG_THEMES.size()
	NetworkManager.save_selected_bg(str(GameConfig.BG_THEMES[next_idx]["id"]))
	_apply_bg_theme()


func _populate_character_cards() -> void:
	for child: Node in char_grid.get_children():
		child.queue_free()
	_cards.clear()

	char_grid.columns = 4
	char_grid.add_theme_constant_override("h_separation", 8)
	for cid: String in CharacterData.ORDER:
		var card: PanelContainer = CARD_SCENE.instantiate() as PanelContainer
		char_grid.add_child(card)
		card.setup(cid)
		card.set_compact_wanted(true)
		card.card_selected.connect(_on_card_selected)
		_cards[cid] = card

	_refresh_card_selection(NetworkManager.selected_char_id)


func _on_card_selected(char_id: String) -> void:
	NetworkManager.save_selected_char(char_id)
	_refresh_card_selection(char_id)
	_refresh_menu_bug()


func _refresh_card_selection(selected_id: String) -> void:
	for cid: String in _cards.keys():
		var card: PanelContainer = _cards[cid] as PanelContainer
		card.set_selected(cid == selected_id)


func _on_name_changed(new_text: String) -> void:
	NetworkManager.save_player_name(new_text)


func _setup_daily_button() -> void:
	var daily_btn: Button = Button.new()
	daily_btn.name = "DailyButton"
	daily_btn.text = "Günün Mutfağı"
	daily_btn.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(daily_btn, Color("#8CC8EA"), AssetHelper.get_ui_font(), GameConfig.UI_FONT_BODY, 102)
	_connect_button_tween(daily_btn)
	daily_btn.pressed.connect(_on_daily_pressed)
	var btn_box: VBoxContainer = $CenterBox/ButtonsBox
	btn_box.add_child(daily_btn)
	btn_box.move_child(daily_btn, solo_button.get_index() + 1)


func _on_daily_pressed() -> void:
	NetworkManager.save_player_name(name_input.text)
	NetworkManager.is_multiplayer_match = false
	var d: Dictionary = Time.get_date_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
	NetworkManager.current_seed = maxi(abs(date_str.hash()), 1)
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


func _on_solo_pressed() -> void:
	NetworkManager.save_player_name(name_input.text)
	NetworkManager.prepare_single_player_seed()
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


func _on_host_pressed() -> void:
	NetworkManager.save_player_name(name_input.text)
	if NetworkManager.host_game():
		get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")
	else:
		notice_label.text = "Oda açılamadı (Port %d kullanımda olabilir)." % GameConfig.NET_PORT
		notice_label.visible = true


func _on_join_pressed() -> void:
	NetworkManager.save_player_name(name_input.text)
	join_panel.visible = true
	join_status_label.text = "Aynı Wi-Fi'deki odalar aranıyor..."
	_on_rooms_updated([])
	NetworkManager.get_discovery().start_listening()


func _on_close_join_pressed() -> void:
	NetworkManager.get_discovery().stop_all()
	join_panel.visible = false


func _on_manual_connect_pressed() -> void:
	_connect_to_ip(ip_input.text)


func _connect_to_ip(ip: String) -> void:
	join_status_label.text = "%s adresine bağlanılıyor..." % ip
	NetworkManager.join_game(ip)


func _on_rooms_updated(rooms: Array[Dictionary]) -> void:
	for child: Node in rooms_list.get_children():
		child.queue_free()

	var font: Font = AssetHelper.get_ui_font()
	if rooms.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Henüz oda bulunamadı. Elle IP girebilirsiniz."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_override("font", font)
		empty_lbl.add_theme_font_size_override("font_size", 20)
		empty_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
		rooms_list.add_child(empty_lbl)
		return

	for room: Dictionary in rooms:
		var btn: Button = Button.new()
		var r_ip: String = str(room.get("ip", ""))
		var r_host: String = str(room.get("host_name", "Oda"))
		var r_count: int = int(room.get("players", 1))
		var r_match: bool = bool(room.get("in_match", false))
		btn.text = "%s (%d/5) - %s%s" % [r_host, r_count, r_ip, " [Maçta]" if r_match else ""]
		btn.custom_minimum_size = Vector2(0, 56)
		btn.disabled = r_match
		btn.pressed.connect(func() -> void:
			_connect_to_ip(r_ip)
		)
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_SAGE, font, 22, 200 + rooms_list.get_child_count())
		rooms_list.add_child(btn)


func _on_connection_succeeded() -> void:
	NetworkManager.get_discovery().stop_all()
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")


func _on_connection_failed(reason: String) -> void:
	join_status_label.text = reason
	notice_label.text = reason
	notice_label.visible = true


func _apply_styles() -> void:
	var font: Font = AssetHelper.get_ui_font()

	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", GameConfig.UI_FONT_TITLE)
	title_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	title_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	title_label.add_theme_constant_override("outline_size", 8)

	ComicUiHelper.style_bitten_panel(form_card, GameConfig.COLOR_CREAM, 11, 22)

	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", GameConfig.UI_FONT_SMALL)
	name_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	name_input.add_theme_font_override("font", font)
	name_input.add_theme_font_size_override("font_size", GameConfig.UI_FONT_BODY)
	name_input.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	var input_style: StyleBoxFlat = StyleBoxFlat.new()
	input_style.bg_color = Color("#FFFDF8")
	input_style.border_color = ComicUiHelper.INK_COLOR
	input_style.set_border_width_all(3)
	input_style.set_corner_radius_all(14)
	input_style.set_content_margin_all(12)
	name_input.add_theme_stylebox_override("normal", input_style)
	name_input.add_theme_stylebox_override("focus", input_style)

	ComicUiHelper.style_bitten_button(bg_button, Color("#EDE0CE"), font, GameConfig.UI_FONT_BODY, 101)
	ComicUiHelper.style_bitten_button(solo_button, Color("#9CD48C"), font, GameConfig.UI_FONT_BODY, 103)
	ComicUiHelper.style_bitten_button(host_button, Color("#F2C96B"), font, GameConfig.UI_FONT_BODY, 104)
	ComicUiHelper.style_bitten_button(join_button, Color("#F09A7E"), font, GameConfig.UI_FONT_BODY, 105)
	ComicUiHelper.style_bitten_button(sound_button, Color("#F6EFE4"), font, 20, 106)
	ComicUiHelper.style_bitten_button(vib_button, Color("#F6EFE4"), font, 20, 107)
	ComicUiHelper.style_bitten_button(connect_btn, Color("#9CD48C"), font, 22, 108)
	ComicUiHelper.style_bitten_button(close_join_btn, Color("#F09A7E"), font, 22, 109)

	notice_label.add_theme_font_override("font", font)
	notice_label.add_theme_font_size_override("font_size", 22)
	notice_label.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)

	ComicUiHelper.style_bitten_panel(join_panel, GameConfig.COLOR_CREAM, 12, 24)
	join_title.add_theme_font_override("font", font)
	join_title.add_theme_font_size_override("font_size", 32)
	join_title.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	join_status_label.add_theme_font_override("font", font)
	join_status_label.add_theme_font_size_override("font_size", 20)
	join_status_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	ip_input.add_theme_font_override("font", font)
	ip_input.add_theme_font_size_override("font_size", 20)
	ip_input.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	ip_input.add_theme_stylebox_override("normal", input_style)
	ip_input.add_theme_stylebox_override("focus", input_style)


func _style_button(btn: Button, bg: Color, font: Font) -> void:
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", GameConfig.UI_FONT_BODY)
	btn.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.42, 0.40, 0.7))

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = GameConfig.COLOR_DARK_TEXT
	normal.set_border_width_all(GameConfig.UI_BORDER_WIDTH)
	normal.set_corner_radius_all(GameConfig.UI_CORNER_RADIUS)
	normal.shadow_color = Color(0.0, 0.0, 0.0, 0.14)
	normal.shadow_size = 4
	normal.shadow_offset = Vector2(0.0, 3.0)
	normal.set_content_margin_all(16)

	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.08)

	var pressed: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.08)

	var disabled_box: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	disabled_box.bg_color = Color(0.84, 0.82, 0.80, 0.75)
	disabled_box.border_color = Color(0.55, 0.52, 0.50, 0.7)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("disabled", disabled_box)


func _connect_button_tween(btn: Button) -> void:
	btn.button_down.connect(func() -> void:
		if btn.disabled:
			return
		btn.pivot_offset = btn.size * 0.5
		var tw: Tween = create_tween()
		tw.tween_property(btn, "scale", Vector2(GameConfig.BUTTON_PRESS_SCALE, GameConfig.BUTTON_PRESS_SCALE), GameConfig.BUTTON_PRESS_DURATION)
	)
	btn.button_up.connect(func() -> void:
		btn.pivot_offset = btn.size * 0.5
		var tw: Tween = create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, GameConfig.BUTTON_PRESS_DURATION)
	)


func _open_online_modal() -> void:
	NetworkManager.save_player_name(name_input.text)
	var font: Font = AssetHelper.get_ui_font()
	var modal: Control = Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 95

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	modal.add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(60.0, 290.0)
	panel.size = Vector2(600.0, 560.0)
	ComicUiHelper.style_bitten_panel(panel, GameConfig.COLOR_CREAM, 701, 24)
	modal.add_child(panel)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var ttl: Label = Label.new()
	ttl.text = "ÇEVRİMİÇİ OYUN"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", font)
	ttl.add_theme_font_size_override("font_size", 32)
	ttl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	v.add_child(ttl)

	var status_lbl: Label = Label.new()
	status_lbl.text = "Sunucu: %s" % NetworkManager.server_host
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.add_theme_font_override("font", font)
	status_lbl.add_theme_font_size_override("font_size", 18)
	status_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	v.add_child(status_lbl)

	var quick_btn: Button = Button.new()
	quick_btn.text = "Hızlı Oyun"
	quick_btn.custom_minimum_size = Vector2(0.0, 58.0)
	ComicUiHelper.style_bitten_button(quick_btn, Color("#8FD17C"), font, 24, 702)
	quick_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "quick_play", "version": GameConfig.NET_VERSION}, status_lbl)
	)
	v.add_child(quick_btn)

	var priv_btn: Button = Button.new()
	priv_btn.text = "Özel Oda Kur"
	priv_btn.custom_minimum_size = Vector2(0.0, 58.0)
	ComicUiHelper.style_bitten_button(priv_btn, Color("#F2C96B"), font, 24, 703)
	priv_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "create_private", "version": GameConfig.NET_VERSION}, status_lbl)
	)
	v.add_child(priv_btn)

	var code_h: HBoxContainer = HBoxContainer.new()
	code_h.add_theme_constant_override("separation", 10)
	v.add_child(code_h)

	var code_in: LineEdit = LineEdit.new()
	code_in.placeholder_text = "Oda Kodu (örn. KTRB)"
	code_in.max_length = 4
	code_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_in.add_theme_font_override("font", font)
	code_in.add_theme_font_size_override("font_size", 22)
	code_h.add_child(code_in)

	var code_btn: Button = Button.new()
	code_btn.text = "Kodla Katıl"
	code_btn.custom_minimum_size = Vector2(170.0, 54.0)
	ComicUiHelper.style_bitten_button(code_btn, Color("#A9D2E8"), font, 20, 704)
	code_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "join_code", "code": code_in.text.strip_edges().to_upper(), "version": GameConfig.NET_VERSION}, status_lbl)
	)
	code_h.add_child(code_btn)

	var host_edit_btn: Button = Button.new()
	host_edit_btn.text = "Sunucu Adresi Değiştir"
	ComicUiHelper.style_bitten_button(host_edit_btn, GameConfig.COLOR_CREAM, font, 16, 705)
	host_edit_btn.pressed.connect(func() -> void:
		var inp: LineEdit = LineEdit.new()
		inp.text = NetworkManager.server_host
		inp.placeholder_text = "IP veya domain"
		inp.add_theme_font_override("font", font)
		inp.text_submitted.connect(func(new_h: String) -> void:
			NetworkManager.save_server_host(new_h)
			status_lbl.text = "Sunucu: %s" % NetworkManager.server_host
			inp.queue_free()
		)
		v.add_child(inp)
	)
	v.add_child(host_edit_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 52.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, 22, 706)
	close_btn.pressed.connect(func() -> void:
		modal.queue_free()
	)
	v.add_child(close_btn)
	add_child(modal)


func _send_matchmaker_request(req: Dictionary, status_lbl: Label) -> void:
	status_lbl.text = "Sunucuya bağlanılıyor..."
	var tcp: StreamPeerTCP = StreamPeerTCP.new()
	var err: Error = tcp.connect_to_host(NetworkManager.server_host, GameConfig.MATCHMAKER_PORT)
	if err != OK:
		status_lbl.text = "Sunucuya ulaşılamadı. İnternetini kontrol et."
		return
	var deadline: int = Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		tcp.poll()
		if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			break
		if tcp.get_status() == StreamPeerTCP.STATUS_ERROR:
			status_lbl.text = "Sunucuya ulaşılamadı. İnternetini kontrol et."
			return
		await get_tree().process_frame
	if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		status_lbl.text = "Sunucuya ulaşılamadı. İnternetini kontrol et."
		return
	tcp.put_data((JSON.stringify(req) + "\n").to_utf8_buffer())
	var resp_raw: String = ""
	while Time.get_ticks_msec() < deadline:
		tcp.poll()
		var av: int = tcp.get_available_bytes()
		if av > 0:
			resp_raw += tcp.get_utf8_string(av)
			if resp_raw.find("\n") != -1:
				break
		await get_tree().process_frame
	tcp.disconnect_from_host()
	var parsed: Variant = JSON.parse_string(resp_raw.strip_edges())
	if not (parsed is Dictionary):
		status_lbl.text = "Sunucu yanıt vermedi."
		return
	var resp: Dictionary = parsed as Dictionary
	if not bool(resp.get("ok", false)):
		status_lbl.text = str(resp.get("reason", "Bağlantı reddedildi."))
		return
	var port: int = int(resp.get("port", 0))
	var code: String = str(resp.get("code", ""))
	var pub: bool = bool(resp.get("public", true))
	status_lbl.text = "Odaya giriliyor (%s)..." % code
	NetworkManager.join_online_room(port, code, pub)


func _open_controls_modal() -> void:
	var font: Font = AssetHelper.get_ui_font()
	var modal: Control = Control.new()
	modal.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal.z_index = 95

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	modal.add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(60.0, 290.0)
	panel.size = Vector2(600.0, 560.0)
	ComicUiHelper.style_bitten_panel(panel, GameConfig.COLOR_CREAM, 720, 24)
	modal.add_child(panel)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)

	var ttl: Label = Label.new()
	ttl.text = "KONTROL AYARLARI"
	ttl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ttl.add_theme_font_override("font", font)
	ttl.add_theme_font_size_override("font_size", 30)
	ttl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	v.add_child(ttl)

	var scheme_btn: Button = Button.new()
	scheme_btn.text = "Kontrol: %s" % ("Dokun ve Kaydır" if AudioManager.control_scheme == "swipe" else "Sadece Butonlar")
	scheme_btn.custom_minimum_size = Vector2(0.0, 54.0)
	ComicUiHelper.style_bitten_button(scheme_btn, GameConfig.COLOR_DUST_BLUE, font, 21, 721)
	scheme_btn.pressed.connect(func() -> void:
		var next_s: String = "buttons" if AudioManager.control_scheme == "swipe" else "swipe"
		AudioManager.save_control_settings(next_s, AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode)
		scheme_btn.text = "Kontrol: %s" % ("Dokun ve Kaydır" if AudioManager.control_scheme == "swipe" else "Sadece Butonlar")
	)
	v.add_child(scheme_btn)

	var left_btn: Button = Button.new()
	left_btn.text = "Solak Modu: %s" % ("Açık" if AudioManager.left_handed else "Kapalı")
	left_btn.custom_minimum_size = Vector2(0.0, 54.0)
	ComicUiHelper.style_bitten_button(left_btn, GameConfig.COLOR_PEACH, font, 21, 722)
	left_btn.pressed.connect(func() -> void:
		AudioManager.save_control_settings(AudioManager.control_scheme, not AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode)
		left_btn.text = "Solak Modu: %s" % ("Açık" if AudioManager.left_handed else "Kapalı")
	)
	v.add_child(left_btn)

	var scale_lbl: Label = Label.new()
	scale_lbl.text = "Buton Boyutu: %%%d" % int(roundf(AudioManager.button_scale * 100.0))
	scale_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	scale_lbl.add_theme_font_override("font", font)
	scale_lbl.add_theme_font_size_override("font_size", 20)
	scale_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	v.add_child(scale_lbl)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.8
	slider.max_value = 1.3
	slider.step = 0.05
	slider.value = AudioManager.button_scale
	slider.value_changed.connect(func(val: float) -> void:
		AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, val, AudioManager.assist_mode)
		scale_lbl.text = "Buton Boyutu: %%%d" % int(roundf(val * 100.0))
	)
	v.add_child(slider)

	var assist_btn: Button = Button.new()
	assist_btn.text = "Yardımcı Mod (Tek Oyuncu): %s" % ("Açık" if AudioManager.assist_mode else "Kapalı")
	assist_btn.custom_minimum_size = Vector2(0.0, 54.0)
	ComicUiHelper.style_bitten_button(assist_btn, Color("#8FD17C"), font, 19, 723)
	assist_btn.pressed.connect(func() -> void:
		AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, AudioManager.button_scale, not AudioManager.assist_mode)
		assist_btn.text = "Yardımcı Mod (Tek Oyuncu): %s" % ("Açık" if AudioManager.assist_mode else "Kapalı")
	)
	v.add_child(assist_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 54.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_CREAM, font, 22, 724)
	close_btn.pressed.connect(func() -> void:
		modal.queue_free()
	)
	v.add_child(close_btn)
	add_child(modal)

extends Control

## Çok oyunculu lobi ekranı: oyuncu listesi, karakter seçimi ve maç başlatma.
## Tam ekran güvenli alan kenarlığı içinde dikey yerleşim; karakter şeridi yatay kayar.

const CARD_SCENE: PackedScene = preload("res://scenes/ui/CharacterCard.tscn")

const CHIP_SIZE: Vector2 = Vector2(128.0, 144.0)
const CHIP_ICON: float = 76.0
const CHIP_STRIP_PAD: float = 8.0
const CONTENT_MAX_WIDTH: float = 720.0
const START_BTN_HEIGHT: float = 80.0
const SECONDARY_BTN_HEIGHT: float = 64.0
const COLOR_CHIP: Color = Color("#FBF6EE")
const COLOR_CHIP_SELECTED: Color = Color("#5A4436")
const COLOR_START: Color = Color("#9CD48C")
const COLOR_LEAVE: Color = Color("#F09A7E")
## Kısa adlar: şeritte yer kaplamasın diye.
const SHORT_NAMES: Dictionary = {
	"halaybasi": "Halaybaşı",
	"usta": "Usta",
	"dayi": "Dayı",
}

@onready var bg_rect: TextureRect = $BgRect
@onready var safe_margin: MarginContainer = $SafeMargin
@onready var header_panel: PanelContainer = $SafeMargin/MainVBox/HeaderPanel
@onready var title_label: Label = $SafeMargin/MainVBox/HeaderPanel/HeaderBox/TitleLabel
@onready var ip_label: Label = $SafeMargin/MainVBox/HeaderPanel/HeaderBox/IpLabel
@onready var status_label: Label = $SafeMargin/MainVBox/HeaderPanel/HeaderBox/StatusLabel
@onready var players_box: VBoxContainer = $SafeMargin/MainVBox/PlayersScroll/PlayersBox
@onready var char_panel: PanelContainer = $SafeMargin/MainVBox/CharPanel
@onready var char_title: Label = $SafeMargin/MainVBox/CharPanel/CharVBox/CharTitle
@onready var char_scroll: ScrollContainer = $SafeMargin/MainVBox/CharPanel/CharVBox/CharScroll
@onready var char_buttons_box: HBoxContainer = $SafeMargin/MainVBox/CharPanel/CharVBox/CharScroll/CharButtonsBox
@onready var start_button: Button = $SafeMargin/MainVBox/ActionBox/StartButton
@onready var secondary_row: HBoxContainer = $SafeMargin/MainVBox/ActionBox/SecondaryRow
@onready var leave_button: Button = $SafeMargin/MainVBox/ActionBox/SecondaryRow/LeaveButton

var _char_buttons: Dictionary = {}


func _ready() -> void:
	# Deneme hakkı bitmiş karakterle lobiye dönüldüyse varsayılana geç.
	Monetization.end_match_character()
	if not Monetization.is_char_unlocked(NetworkManager.selected_char_id):
		NetworkManager.request_char_change("klasik")
	var bg_theme: Dictionary = GameConfig.get_bg_theme(NetworkManager.selected_bg_id)
	bg_rect.texture = AssetHelper.texture(str(bg_theme["path"]), str(bg_theme["kind"]), GameConfig.BG_SIZE)

	ip_label.text = "Yerel IP: %s (Port %d)" % [LanDiscovery.get_local_ipv4(), GameConfig.NET_PORT]
	NetworkManager.players_updated.connect(_refresh_players)

	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	_apply_styles()
	_build_char_buttons()
	_refresh_players()


## Çentik / jest çubuğu boşluklarını kenar boşluğuna ekler.
func _apply_safe_area() -> void:
	var ins: Dictionary = ComicUiHelper.safe_insets(self)
	var g: float = GameConfig.SCREEN_GUTTER
	# Tablette içerik fazla yayılmasın: genişliği sınırla, ortala.
	var vs: Vector2 = ComicUiHelper.visible_size(self)
	var used_w: float = vs.x - float(ins["left"]) - float(ins["right"]) - g * 2.0
	var extra: float = maxf(0.0, (used_w - CONTENT_MAX_WIDTH) * 0.5)
	safe_margin.add_theme_constant_override("margin_top", int(float(ins["top"]) + g))
	safe_margin.add_theme_constant_override("margin_bottom", int(float(ins["bottom"]) + g))
	safe_margin.add_theme_constant_override("margin_left", int(float(ins["left"]) + g + extra))
	safe_margin.add_theme_constant_override("margin_right", int(float(ins["right"]) + g + extra))


## Seçilebilir böcekler: satın alınmış ya da deneme hakkı olanlar.
func _selectable_chars() -> Array[String]:
	var res: Array[String] = []
	for cid: String in CharacterData.ALL_ORDER:
		if Monetization.is_char_unlocked(cid):
			res.append(cid)
	return res


func _short_name(cid: String) -> String:
	if SHORT_NAMES.has(cid):
		return str(SHORT_NAMES[cid])
	var n: String = str(CharacterData.get_character(cid)["display_name"])
	return n.replace(" Böceği", "").replace(" Böcek", "")


func _build_char_buttons() -> void:
	for child: Node in char_buttons_box.get_children():
		char_buttons_box.remove_child(child)
		child.queue_free()
	_char_buttons.clear()

	for cid: String in _selectable_chars():
		var cdata: Dictionary = CharacterData.get_character(cid)
		var btn: Button = Button.new()
		btn.custom_minimum_size = CHIP_SIZE
		btn.tooltip_text = str(cdata["display_name"])

		var v: VBoxContainer = VBoxContainer.new()
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_top = CHIP_STRIP_PAD
		v.offset_bottom = -CHIP_STRIP_PAD - 4.0
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(v)

		var icon: TextureRect = TextureRect.new()
		icon.name = "Icon"
		icon.custom_minimum_size = Vector2(CHIP_ICON, CHIP_ICON)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
		v.add_child(icon)

		var lbl: Label = Label.new()
		lbl.name = "Name"
		lbl.text = _short_name(cid)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(lbl)

		var trial_lbl: Label = Label.new()
		trial_lbl.name = "Trial"
		trial_lbl.text = "deneme"
		trial_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trial_lbl.visible = not Monetization.unlocked_chars.has(cid) and Monetization.trial_char == cid
		trial_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(trial_lbl)

		btn.pressed.connect(func() -> void:
			if NetworkManager.selected_char_id == cid:
				return
			AudioManager.play_character_voice(cid, "dokun_1")
			NetworkManager.request_char_change(cid)
			_refresh_char_buttons()
		)
		char_buttons_box.add_child(btn)
		# Kaydırılabilir şeritte parmak kaydırması düğmeye takılmasın.
		btn.mouse_filter = Control.MOUSE_FILTER_PASS
		_char_buttons[cid] = btn
	_refresh_char_buttons()
	_scroll_to_selected.call_deferred()


func _refresh_char_buttons() -> void:
	var font: Font = AssetHelper.get_ui_font()
	for cid: String in _char_buttons.keys():
		var btn: Button = _char_buttons[cid] as Button
		var on: bool = cid == NetworkManager.selected_char_id
		ComicUiHelper.style_bitten_button(btn, COLOR_CHIP_SELECTED if on else COLOR_CHIP, font, GameConfig.FS_SMALL, 310)
		btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		var lbl: Label = _find_child_label(btn, "Name")
		var trial_lbl: Label = _find_child_label(btn, "Trial")
		if lbl != null:
			ComicUiHelper.style_label(lbl, GameConfig.FS_SMALL, GameConfig.COLOR_CREAM if on else GameConfig.COLOR_DARK_TEXT, true)
		if trial_lbl != null:
			ComicUiHelper.style_label(trial_lbl, GameConfig.FS_TINY, GameConfig.COLOR_GOLD if on else GameConfig.COLOR_BROWN)


func _find_child_label(btn: Button, n: String) -> Label:
	var found: Node = btn.find_child(n, true, false)
	return found as Label


func _scroll_to_selected() -> void:
	var cid: String = NetworkManager.selected_char_id
	if _char_buttons.has(cid):
		char_scroll.ensure_control_visible(_char_buttons[cid] as Control)


func _refresh_players() -> void:
	for child: Node in players_box.get_children():
		players_box.remove_child(child)
		child.queue_free()

	var ids: Array = NetworkManager.players.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var pa: int = int((NetworkManager.players[int(a)] as Dictionary).get("total_points", 0))
		var pb: int = int((NetworkManager.players[int(b)] as Dictionary).get("total_points", 0))
		if pa != pb:
			return pa > pb
		return int(a) < int(b)
	)
	var local_uid: int = multiplayer.get_unique_id()
	for pid_v: Variant in ids:
		var pid: int = int(pid_v)
		var pdata: Dictionary = NetworkManager.players[pid] as Dictionary
		var card: PanelContainer = CARD_SCENE.instantiate() as PanelContainer
		players_box.add_child(card)
		var prefix: String = "[Oda sahibi] " if pid == 1 else ""
		var pts: int = int(pdata.get("total_points", 0))
		var wins: int = int(pdata.get("wins", 0))
		var extra: String = "%s%s · Puan: %d · Birincilik: %d" % [prefix, str(pdata["name"]), pts, wins]
		var c_id: String = str(pdata["char_id"])
		card.setup(c_id, extra)
		card.set_selected(pid == local_uid)
		var cap_pid: int = pid
		var cap_cid: String = c_id
		card.card_selected.connect(func(_cid: String) -> void:
			var sm: SkillsModal = SkillsModal.new()
			add_child(sm)
			sm.open_for(cap_cid, cap_pid == local_uid)
			if cap_pid == local_uid:
				sm.character_chosen.connect(func(new_cid: String) -> void:
					NetworkManager.request_char_change(new_cid)
					_build_char_buttons()
				)
		)

	_refresh_char_buttons()

	var is_host: bool = NetworkManager.is_room_owner()
	start_button.visible = is_host and not (NetworkManager.is_dedicated_mode and NetworkManager.is_public_room)
	var min_players: int = 1 if GameConfig.DEBUG else 2
	start_button.disabled = NetworkManager.players.size() < min_players
	start_button.text = "Oyunu Başlat" if not start_button.disabled else "Bir kişi daha lazım"
	if NetworkManager.is_dedicated_mode and not NetworkManager.room_code.is_empty():
		status_label.text = "Oda Kodu: %s · Oyuncular: %d / %d" % [NetworkManager.room_code, NetworkManager.players.size(), GameConfig.NET_MAX_CLIENTS + 1]
	else:
		status_label.text = "Oyuncular: %d / %d" % [NetworkManager.players.size(), GameConfig.NET_MAX_CLIENTS + 1]


func _on_start_pressed() -> void:
	if NetworkManager.is_dedicated_mode:
		NetworkManager.request_start_match.rpc_id(1)
	else:
		NetworkManager.host_start_match()


func _on_leave_pressed() -> void:
	NetworkManager.leave_game()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _apply_styles() -> void:
	var font: Font = AssetHelper.get_ui_font()
	ComicUiHelper.style_bitten_panel(header_panel, GameConfig.COLOR_CREAM, 305, GameConfig.SP_M)
	ComicUiHelper.style_bitten_panel(char_panel, GameConfig.COLOR_CREAM, 306, GameConfig.SP_M)
	ComicUiHelper.style_label(title_label, GameConfig.FS_H2, GameConfig.COLOR_WARN_RED, true)
	ComicUiHelper.style_label(status_label, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, true)
	ComicUiHelper.style_label(ip_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	ComicUiHelper.style_label(char_title, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, true)

	start_button.custom_minimum_size.y = START_BTN_HEIGHT
	leave_button.custom_minimum_size.y = SECONDARY_BTN_HEIGHT
	_style_button(start_button, COLOR_START, font, GameConfig.FS_H2 - 4)
	_style_button(leave_button, COLOR_LEAVE, font, GameConfig.FS_BODY)

	if secondary_row.get_node_or_null("InviteButton") == null:
		var inv_btn: Button = Button.new()
		inv_btn.name = "InviteButton"
		inv_btn.text = "Davet Et"
		inv_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inv_btn.custom_minimum_size = Vector2(0.0, SECONDARY_BTN_HEIGHT)
		_style_button(inv_btn, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_BODY)
		inv_btn.pressed.connect(_on_invite_pressed)
		secondary_row.add_child(inv_btn)


func _on_invite_pressed() -> void:
	var msg: String = "Aynı Wi-Fi'ye bağlan, 'Arkadaşlarla' ekranında odamı göreceksin."
	if NetworkManager.is_dedicated_mode and not NetworkManager.room_code.is_empty():
		var link: String = "%s/oda.html?k=%s" % [GameConfig.SHARE_SITE_URL, NetworkManager.room_code]
		msg = "Mutfakta yer açtım! Uçan Hamam Böceği odama gel. Oda kodu: %s  %s" % [NetworkManager.room_code, link]
	if Engine.has_singleton("GodotShare"):
		Engine.get_singleton("GodotShare").call("shareText", "Oda Daveti", "Uçan Hamam Böceği", msg)
	else:
		DisplayServer.clipboard_set(msg)
		status_label.text = "Davet yazısı panoda, yapıştır gönder."


func _style_button(btn: Button, bg: Color, font: Font, font_size: int) -> void:
	ComicUiHelper.style_bitten_button(btn, bg, font, font_size, btn.get_index() + 310)

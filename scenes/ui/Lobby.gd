extends Control

## Çok oyunculu lobi ekranı: oyuncu listesi, karakter seçimi ve maç başlatma.

const CARD_SCENE: PackedScene = preload("res://scenes/ui/CharacterCard.tscn")

@onready var bg_rect: TextureRect = $BgRect
@onready var ip_label: Label = $MainVBox/HeaderBox/IpLabel
@onready var status_label: Label = $MainVBox/HeaderBox/StatusLabel
@onready var players_box: VBoxContainer = $MainVBox/PlayersScroll/PlayersBox
@onready var char_buttons_box: HBoxContainer = $MainVBox/CharButtonsBox
@onready var start_button: Button = $MainVBox/ActionBox/StartButton
@onready var leave_button: Button = $MainVBox/ActionBox/LeaveButton

var _char_buttons: Dictionary = {}


func _ready() -> void:
	var bg_theme: Dictionary = GameConfig.get_bg_theme(NetworkManager.selected_bg_id)
	bg_rect.texture = AssetHelper.texture(str(bg_theme["path"]), str(bg_theme["kind"]), GameConfig.BG_SIZE)

	ip_label.text = "Yerel IP: %s (Port %d)" % [LanDiscovery.get_local_ipv4(), GameConfig.NET_PORT]
	NetworkManager.players_updated.connect(_refresh_players)

	start_button.pressed.connect(_on_start_pressed)
	leave_button.pressed.connect(_on_leave_pressed)

	_build_char_buttons()
	_apply_styles()
	_refresh_players()


func _build_char_buttons() -> void:
	for child: Node in char_buttons_box.get_children():
		child.queue_free()
	_char_buttons.clear()

	var font: Font = AssetHelper.get_ui_font()
	for cid: String in CharacterData.ORDER:
		var cdata: Dictionary = CharacterData.get_character(cid)
		var btn: Button = Button.new()
		btn.text = str(cdata["display_name"]).replace(" Böcek", "")
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 62)
		btn.pressed.connect(func() -> void:
			NetworkManager.request_char_change(cid)
			_refresh_char_buttons()
		)
		_style_button(btn, GameConfig.COLOR_CREAM, font, 20)
		char_buttons_box.add_child(btn)
		_char_buttons[cid] = btn
	_refresh_char_buttons()


func _refresh_char_buttons() -> void:
	for cid: String in _char_buttons.keys():
		var btn: Button = _char_buttons[cid] as Button
		btn.modulate = GameConfig.COLOR_SAGE if cid == NetworkManager.selected_char_id else Color.WHITE


func _refresh_players() -> void:
	for child: Node in players_box.get_children():
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
		var prefix: String = "[HOST] " if pid == 1 else ""
		var pts: int = int(pdata.get("total_points", 0))
		var wins: int = int(pdata.get("wins", 0))
		var extra: String = "%s%s | Puan: %d | 1.lik: %d" % [prefix, str(pdata["name"]), pts, wins]
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
					NetworkManager.save_selected_char(new_cid)
					NetworkManager.update_my_character(new_cid)
					_refresh_char_buttons()
				)
		)

	var is_host: bool = NetworkManager.is_room_owner()
	start_button.visible = is_host and not (NetworkManager.is_dedicated_mode and NetworkManager.is_public_room)
	var min_players: int = 1 if GameConfig.DEBUG else 2
	start_button.disabled = NetworkManager.players.size() < min_players
	if NetworkManager.is_dedicated_mode and not NetworkManager.room_code.is_empty():
		status_label.text = "Oda Kodu: %s  |  Oyuncular: %d / %d" % [NetworkManager.room_code, NetworkManager.players.size(), GameConfig.NET_MAX_CLIENTS + 1]
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
	ip_label.add_theme_font_override("font", font)
	ip_label.add_theme_font_size_override("font_size", 24)
	ip_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	status_label.add_theme_font_override("font", font)
	status_label.add_theme_font_size_override("font_size", 26)
	status_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)

	ComicUiHelper.style_bitten_button(start_button, Color("#9CD48C"), font, GameConfig.UI_FONT_BODY, 301)
	ComicUiHelper.style_bitten_button(leave_button, Color("#F09A7E"), font, GameConfig.UI_FONT_BODY, 302)

	var action_box: HBoxContainer = $MainVBox/ActionBox
	if action_box.get_node_or_null("InviteButton") == null:
		var inv_btn: Button = Button.new()
		inv_btn.name = "InviteButton"
		inv_btn.text = "Arkadaşını Davet Et"
		inv_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ComicUiHelper.style_bitten_button(inv_btn, GameConfig.COLOR_DUST_BLUE, font, 20, 303)
		inv_btn.pressed.connect(_on_invite_pressed)
		action_box.add_child(inv_btn)


func _on_invite_pressed() -> void:
	var msg: String = "Aynı Wi-Fi'ye bağlan, 'Arkadaşlarla' ekranında odamı göreceksin."
	if NetworkManager.is_dedicated_mode and not NetworkManager.room_code.is_empty():
		var link: String = "%s/oda.html?k=%s" % [GameConfig.SHARE_SITE_URL, NetworkManager.room_code]
		msg = "Mutfakta yer açtım! Uçan Hamam Böceği odama gel. Oda kodu: %s  %s" % [NetworkManager.room_code, link]
	if Engine.has_singleton("GodotShare"):
		Engine.get_singleton("GodotShare").call("shareText", "Oda Daveti", "Uçan Hamam Böceği", msg)
	else:
		DisplayServer.clipboard_set(msg)
		status_label.text = "Davet metni panoya kopyalandı!"


func _style_button(btn: Button, bg: Color, font: Font, font_size: int) -> void:
	ComicUiHelper.style_bitten_button(btn, bg, font, font_size, btn.get_index() + 310)

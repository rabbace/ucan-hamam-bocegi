class_name ShopModal
extends Control

## 9.4: "Böcek Pazarı" mağaza ekranı (Böcekler, Kostümler, Paketler).

signal character_equipped(char_id: String)

var _tab: String = "bocekler"
var _kirinti_lbl: Label = null
var _list_box: VBoxContainer = null
var _status_lbl: Label = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 93
	_build_ui()
	Monetization.kirinti_changed.connect(_on_kirinti_changed)
	Monetization.purchase_completed.connect(_on_purchase_completed)
	_refresh_list()


func _build_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(40.0, 120.0)
	panel.size = Vector2(640.0, 1020.0)
	ComicUiHelper.style_bitten_panel(panel, GameConfig.COLOR_CREAM, 801, 22)
	add_child(panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 12)
	panel.add_child(root_v)

	var top_h: HBoxContainer = HBoxContainer.new()
	root_v.add_child(top_h)

	var title_lbl: Label = Label.new()
	title_lbl.text = "BÖCEK PAZARI"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.add_theme_font_override("font", font)
	title_lbl.add_theme_font_size_override("font_size", 32)
	title_lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	top_h.add_child(title_lbl)

	_kirinti_lbl = Label.new()
	_kirinti_lbl.text = "Kırıntı: %d" % Monetization.kirinti
	_kirinti_lbl.add_theme_font_override("font", font)
	_kirinti_lbl.add_theme_font_size_override("font_size", 24)
	_kirinti_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	top_h.add_child(_kirinti_lbl)

	var tabs_h: HBoxContainer = HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", 8)
	root_v.add_child(tabs_h)

	for t_pair: Array in [["bocekler", "Böcekler"], ["kostumler", "Kostümler"], ["paketler", "Paketler"]]:
		var t_id: String = str(t_pair[0])
		var t_btn: Button = Button.new()
		t_btn.text = str(t_pair[1])
		t_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_btn.custom_minimum_size = Vector2(0.0, 48.0)
		ComicUiHelper.style_bitten_button(t_btn, GameConfig.COLOR_PEACH, font, 20, 802)
		t_btn.pressed.connect(func() -> void:
			_tab = t_id
			_refresh_list()
		)
		tabs_h.add_child(t_btn)

	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_override("font", font)
	_status_lbl.add_theme_font_size_override("font_size", 18)
	_status_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	root_v.add_child(_status_lbl)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_v.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

	var bot_h: HBoxContainer = HBoxContainer.new()
	bot_h.add_theme_constant_override("separation", 10)
	root_v.add_child(bot_h)

	var restore_btn: Button = Button.new()
	restore_btn.text = "Satın Alımları Geri Yükle"
	restore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_btn.custom_minimum_size = Vector2(0.0, 52.0)
	ComicUiHelper.style_bitten_button(restore_btn, GameConfig.COLOR_DUST_BLUE, font, 18, 803)
	restore_btn.pressed.connect(func() -> void:
		Monetization.restore_purchases()
	)
	bot_h.add_child(restore_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(150.0, 52.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, 22, 804)
	close_btn.pressed.connect(func() -> void:
		queue_free()
	)
	bot_h.add_child(close_btn)


func _on_kirinti_changed(val: int) -> void:
	if _kirinti_lbl != null:
		_kirinti_lbl.text = "Kırıntı: %d" % val


func _on_purchase_completed(_pid: String, _ok: bool, msg: String) -> void:
	if _status_lbl != null:
		_status_lbl.text = msg
	_refresh_list()


func _refresh_list() -> void:
	for c: Node in _list_box.get_children():
		c.queue_free()
	var font: Font = AssetHelper.get_ui_font()

	if _tab == "bocekler":
		for cid: String in CharacterData.ALL_ORDER:
			var cdata: Dictionary = CharacterData.get_character(cid)
			var price: int = int(cdata.get("price", 0))
			var unlocked: bool = Monetization.is_char_unlocked(cid)
			var row: PanelContainer = PanelContainer.new()
			ComicUiHelper.style_bitten_panel(row, Color("#FFFDF8") if unlocked else Color("#E8E4DF"), 810, 12)
			_list_box.add_child(row)

			var h: HBoxContainer = HBoxContainer.new()
			h.add_theme_constant_override("separation", 10)
			row.add_child(h)

			var icon: TextureRect = TextureRect.new()
			icon.custom_minimum_size = Vector2(56.0, 56.0)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
			if not unlocked:
				icon.modulate = Color(0.4, 0.4, 0.4, 0.85)
			h.add_child(icon)

			var v: VBoxContainer = VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(v)

			var nl: Label = Label.new()
			nl.text = "%s%s" % [str(cdata["display_name"]), "" if unlocked else " (Kilitli)"]
			nl.add_theme_font_override("font", font)
			nl.add_theme_font_size_override("font_size", 20)
			nl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
			v.add_child(nl)

			var dl: Label = Label.new()
			dl.text = str(cdata.get("tagline", ""))
			dl.add_theme_font_override("font", font)
			dl.add_theme_font_size_override("font_size", 15)
			dl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
			v.add_child(dl)

			if unlocked:
				var sel_btn: Button = Button.new()
				sel_btn.text = "Seçili" if NetworkManager.selected_char_id == cid else "Seç"
				sel_btn.custom_minimum_size = Vector2(110.0, 48.0)
				ComicUiHelper.style_bitten_button(sel_btn, Color("#8FD17C"), font, 18, 811)
				sel_btn.pressed.connect(func() -> void:
					AudioManager.play_character_voice(cid, "dokun_1")
					NetworkManager.save_selected_char(cid)
					character_equipped.emit(cid)
					_refresh_list()
				)
				h.add_child(sel_btn)
			else:
				var buy_btn: Button = Button.new()
				buy_btn.text = "%d Kırıntı" % price
				buy_btn.custom_minimum_size = Vector2(130.0, 48.0)
				ComicUiHelper.style_bitten_button(buy_btn, Color("#F2C96B"), font, 17, 812)
				buy_btn.pressed.connect(func() -> void:
					if Monetization.unlock_char_with_kirinti(cid, price):
						AudioManager.play_character_voice(cid, "dokun_1")
						_status_lbl.text = "%s açıldı!" % str(cdata["display_name"])
						NetworkManager.save_selected_char(cid)
						character_equipped.emit(cid)
						_refresh_list()
					else:
						_status_lbl.text = "Yeterli Kırıntı yok!"
				)
				h.add_child(buy_btn)

				var try_btn: Button = Button.new()
				try_btn.text = "1 Maç Dene"
				try_btn.custom_minimum_size = Vector2(115.0, 48.0)
				ComicUiHelper.style_bitten_button(try_btn, GameConfig.COLOR_DUST_BLUE, font, 16, 813)
				try_btn.pressed.connect(func() -> void:
					_status_lbl.text = "Ödüllü reklam izleniyor..."
					Monetization.show_rewarded_ad(func(ok: bool) -> void:
						if ok:
							Monetization.grant_trial(cid)
							NetworkManager.save_selected_char(cid)
							character_equipped.emit(cid)
							_status_lbl.text = "%s 1 maçlığına açıldı!" % str(cdata["display_name"])
							_refresh_list()
					)
				)
				h.add_child(try_btn)
	elif _tab == "kostumler":
		for cid: String in CharacterData.ALL_ORDER:
			var cdata: Dictionary = CharacterData.get_character(cid)
			for sk_idx: int in range(1, 3):
				var sk_key: String = "%s_kostum_%d" % [cid, sk_idx]
				var owned: bool = Monetization.unlocked_skins.has(sk_key)
				var row: PanelContainer = PanelContainer.new()
				ComicUiHelper.style_bitten_panel(row, Color("#FFFDF8"), 820, 12)
				_list_box.add_child(row)
				var h: HBoxContainer = HBoxContainer.new()
				row.add_child(h)
				var lbl: Label = Label.new()
				lbl.text = "%s — Kostüm #%d" % [str(cdata["display_name"]), sk_idx]
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.add_theme_font_override("font", font)
				lbl.add_theme_font_size_override("font_size", 19)
				lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
				h.add_child(lbl)
				var btn: Button = Button.new()
				btn.text = "Açık" if owned else "%d Kırıntı" % GameConfig.SKIN_COST
				btn.custom_minimum_size = Vector2(130.0, 46.0)
				ComicUiHelper.style_bitten_button(btn, Color("#8FD17C") if owned else Color("#F2C96B"), font, 17, 821)
				btn.pressed.connect(func() -> void:
					if Monetization.unlock_skin_with_kirinti(sk_key):
						_status_lbl.text = "Kostüm açıldı!"
						_refresh_list()
					else:
						_status_lbl.text = "Yeterli Kırıntı yok!"
				)
				h.add_child(btn)
	else:
		var packs: Array[Array] = [
			["paket_bocekler", "Böcek Paketi (Tüm 7 Yeni Böcek)"],
			["kirinti_kesesi_kucuk", "Küçük Kırıntı Kesesi (+1500)"],
			["kirinti_kesesi_buyuk", "Büyük Kırıntı Kesesi (+5000)"],
			["reklamsiz", "Reklamsız (Geçiş Reklamları Kalkar)"],
		]
		for pk: Array in packs:
			var p_id: String = str(pk[0])
			var p_title: String = str(pk[1])
			var row: PanelContainer = PanelContainer.new()
			ComicUiHelper.style_bitten_panel(row, Color("#FFFDF8"), 830, 12)
			_list_box.add_child(row)
			var h: HBoxContainer = HBoxContainer.new()
			row.add_child(h)
			var lbl: Label = Label.new()
			lbl.text = p_title
			lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			lbl.add_theme_font_override("font", font)
			lbl.add_theme_font_size_override("font_size", 19)
			lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
			h.add_child(lbl)
			var btn: Button = Button.new()
			btn.text = "Satın Al"
			btn.custom_minimum_size = Vector2(130.0, 46.0)
			ComicUiHelper.style_bitten_button(btn, Color("#8FD17C"), font, 18, 831)
			btn.pressed.connect(func() -> void:
				Monetization.purchase_product(p_id)
			)
			h.add_child(btn)

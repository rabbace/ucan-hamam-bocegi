class_name ShopModal
extends Control

## 9.4: "Böcek Pazarı" mağaza ekranı (Böcekler, Kostümler, Paketler).
## Görünür alanın ortasında açılır, güvenli alana uyar, ekran boyu değişince yeniden yerleşir.

signal character_equipped(char_id: String)

const PANEL_PREF_HEIGHT: float = 1120.0
const COLOR_ROW: Color = Color("#FBF6EE")
const COLOR_ROW_LOCKED: Color = Color("#E9E2D8")
const COLOR_ROW_SELECTED: Color = Color("#E4EEDC")
const TAB_HEIGHT: float = 56.0
const STATUS_HEIGHT: float = 56.0
const FOOTER_BTN_HEIGHT: float = 60.0
const CLOSE_BTN_WIDTH: float = 176.0
const ROW_ICON_SIZE: float = 72.0
const ROW_BTN_HEIGHT: float = 56.0
const ROW_BTN_MIN_W: float = 140.0
const BUY_BTN_MIN_W: float = 168.0
const STATUS_POP_SCALE: float = 0.86
const STATUS_POP_SEC: float = 0.22
const DEFAULT_HINT: String = "Kırıntı biriktir, mahallenin en havalı böceği ol."

var _tab: String = "bocekler"
var _kirinti_lbl: Label = null
var _list_box: VBoxContainer = null
var _list_scroll: ScrollContainer = null
var _status_lbl: Label = null
var _status_tw: Tween = null
var _tab_buttons: Dictionary = {}
var _margin: MarginContainer = null
var _panel: PanelContainer = null
## Faz 13B: ana menüdeki Pazar sekmesine gömülü (karartma ve Kapat yok, sekmeyi doldurur)
var embedded: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS if embedded else Control.MOUSE_FILTER_STOP
	z_index = 0 if embedded else 93
	resized.connect(_relayout)
	_build_ui()
	Monetization.kirinti_changed.connect(_on_kirinti_changed)
	Monetization.purchase_completed.connect(_on_purchase_completed)
	get_viewport().size_changed.connect(_relayout)
	_relayout()
	_refresh_tabs()
	_refresh_list()


func _build_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.10, 0.06, 0.04, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = not embedded
	add_child(dim)

	_margin = MarginContainer.new()
	_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_margin)

	var center: CenterContainer = CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_margin.add_child(center)

	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ComicUiHelper.style_bitten_panel(_panel, GameConfig.COLOR_CREAM, 801, GameConfig.SP_L)
	center.add_child(_panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", GameConfig.SP_S)
	_panel.add_child(root_v)

	# Başlık + Kırıntı hapı
	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.add_theme_constant_override("separation", GameConfig.SP_S)
	root_v.add_child(top_h)

	var title_lbl: Label = Label.new()
	title_lbl.text = "BÖCEK PAZARI"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(title_lbl, GameConfig.FS_H2, GameConfig.COLOR_WARN_RED, true)
	top_h.add_child(title_lbl)

	var pill: PanelContainer = PanelContainer.new()
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var pill_sb: StyleBoxFlat = StyleBoxFlat.new()
	pill_sb.bg_color = GameConfig.COLOR_GOLD
	pill_sb.border_color = GameConfig.COLOR_INK
	pill_sb.set_border_width_all(3)
	pill_sb.set_corner_radius_all(24)
	pill_sb.content_margin_left = GameConfig.SP_M
	pill_sb.content_margin_right = GameConfig.SP_M
	pill_sb.content_margin_top = 4
	pill_sb.content_margin_bottom = 6
	pill_sb.shadow_color = Color(0.14, 0.09, 0.06, 0.35)
	pill_sb.shadow_offset = Vector2(0.0, 3.0)
	pill_sb.shadow_size = 1
	pill.add_theme_stylebox_override("panel", pill_sb)
	top_h.add_child(pill)

	_kirinti_lbl = Label.new()
	_kirinti_lbl.text = _kirinti_text(Monetization.kirinti)
	ComicUiHelper.style_label(_kirinti_lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	pill.add_child(_kirinti_lbl)

	# Sekmeler
	var tabs_h: HBoxContainer = HBoxContainer.new()
	tabs_h.add_theme_constant_override("separation", GameConfig.SP_XS)
	root_v.add_child(tabs_h)

	for t_pair: Array in [["bocekler", "Böcekler"], ["kostumler", "Kostümler"], ["paketler", "Paketler"]]:
		var t_id: String = str(t_pair[0])
		var t_btn: Button = Button.new()
		t_btn.text = str(t_pair[1])
		t_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t_btn.custom_minimum_size = Vector2(0.0, TAB_HEIGHT)
		t_btn.pressed.connect(func() -> void:
			if _tab == t_id:
				return
			_tab = t_id
			_refresh_tabs()
			_refresh_list()
			if _list_scroll != null:
				_list_scroll.scroll_vertical = 0
		)
		tabs_h.add_child(t_btn)
		_tab_buttons[t_id] = t_btn

	# Durum mesajı (yükseklik sabit; mesaj gelince zıplamasın)
	_status_lbl = Label.new()
	_status_lbl.text = DEFAULT_HINT
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_lbl.custom_minimum_size = Vector2(0.0, STATUS_HEIGHT)
	ComicUiHelper.style_label(_status_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	root_v.add_child(_status_lbl)

	_list_scroll = ScrollContainer.new()
	_list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_v.add_child(_list_scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", GameConfig.SP_S)
	_list_scroll.add_child(_list_box)

	# Alt butonlar (kaydırılmaz)
	var bot_h: HBoxContainer = HBoxContainer.new()
	bot_h.add_theme_constant_override("separation", GameConfig.SP_S)
	root_v.add_child(bot_h)

	var restore_btn: Button = Button.new()
	restore_btn.text = "Alımları Geri Yükle"
	restore_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_btn.custom_minimum_size = Vector2(0.0, FOOTER_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(restore_btn, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_SMALL, 803)
	restore_btn.pressed.connect(func() -> void:
		_show_status("Eski alımlarına bakıyorum, bir saniye...")
		Monetization.restore_purchases()
	)
	restore_btn.visible = Monetization.is_store_available()
	bot_h.add_child(restore_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(CLOSE_BTN_WIDTH, FOOTER_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 804)
	close_btn.pressed.connect(func() -> void:
		queue_free()
	)
	close_btn.visible = not embedded
	bot_h.add_child(close_btn)
	bot_h.visible = restore_btn.visible or close_btn.visible


func _relayout() -> void:
	if _panel == null or not is_inside_tree():
		return
	if embedded:
		for k: String in ["margin_top", "margin_bottom", "margin_left", "margin_right"]:
			_margin.add_theme_constant_override(k, 0)
		_panel.custom_minimum_size = size
		return
	var vs: Vector2 = ComicUiHelper.visible_size(self)
	var ins: Dictionary = ComicUiHelper.safe_insets(self)
	var side: float = GameConfig.MODAL_SIDE_MARGIN
	_margin.add_theme_constant_override("margin_top", int(float(ins["top"]) + side))
	_margin.add_theme_constant_override("margin_bottom", int(float(ins["bottom"]) + side))
	_margin.add_theme_constant_override("margin_left", int(float(ins["left"]) + side))
	_margin.add_theme_constant_override("margin_right", int(float(ins["right"]) + side))
	var avail_w: float = vs.x - float(ins["left"]) - float(ins["right"]) - side * 2.0
	var avail_h: float = vs.y - float(ins["top"]) - float(ins["bottom"]) - side * 2.0
	_panel.custom_minimum_size = Vector2(minf(GameConfig.MODAL_MAX_WIDTH, avail_w), minf(PANEL_PREF_HEIGHT, avail_h))


func _kirinti_text(val: int) -> String:
	return "%s Kırıntı" % _fmt_num(val)


## 2500 -> "2.500" (Türkçe binlik ayıracı)
static func _fmt_num(val: int) -> String:
	var s: String = str(absi(val))
	var out: String = ""
	var cnt: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if val < 0 else "") + out


func _refresh_tabs() -> void:
	for t_id: String in _tab_buttons.keys():
		ComicUiHelper.style_tab(_tab_buttons[t_id] as Button, t_id == _tab, GameConfig.FS_BODY)


func _show_status(msg: String, warn: bool = false) -> void:
	if _status_lbl == null:
		return
	_status_lbl.text = msg
	_status_lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED if warn else GameConfig.COLOR_DARK_TEXT)
	if _status_tw != null and _status_tw.is_valid():
		_status_tw.kill()
	_status_lbl.pivot_offset = _status_lbl.size * 0.5
	_status_lbl.scale = Vector2(STATUS_POP_SCALE, STATUS_POP_SCALE)
	_status_lbl.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_status_tw = create_tween().set_parallel(true)
	_status_tw.tween_property(_status_lbl, "scale", Vector2.ONE, STATUS_POP_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_status_tw.tween_property(_status_lbl, "modulate:a", 1.0, 0.14)


func _on_kirinti_changed(val: int) -> void:
	if _kirinti_lbl != null:
		_kirinti_lbl.text = _kirinti_text(val)
	_refresh_list()


func _on_purchase_completed(_pid: String, ok: bool, msg: String) -> void:
	_show_status(msg, not ok)
	_refresh_list()


# ---------------------------------------------------------------------------
# Satır kurucular: ikon + (isim / alt yazı) üstte, butonlar altta sağa yaslı
# ---------------------------------------------------------------------------

func _make_row(bg: Color, icon_tex: Texture2D, title: String, sub: String, dim_icon: bool = false) -> Dictionary:
	var row: PanelContainer = PanelContainer.new()
	ComicUiHelper.style_bitten_panel(row, bg, 810, GameConfig.SP_M)
	_list_box.add_child(row)

	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	row.add_child(v)

	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.add_theme_constant_override("separation", GameConfig.SP_S)
	v.add_child(top_h)

	if icon_tex != null:
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(ROW_ICON_SIZE, ROW_ICON_SIZE)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = icon_tex
		if dim_icon:
			icon.modulate = Color(0.45, 0.42, 0.40, 0.9)
		top_h.add_child(icon)

	var text_v: VBoxContainer = VBoxContainer.new()
	text_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_v.alignment = BoxContainer.ALIGNMENT_CENTER
	text_v.add_theme_constant_override("separation", 0)
	top_h.add_child(text_v)

	var nl: Label = Label.new()
	nl.text = title
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(nl, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, true)
	text_v.add_child(nl)

	var dl: Label = Label.new()
	dl.text = sub
	dl.visible = not sub.is_empty()
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(dl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	text_v.add_child(dl)

	var btn_h: HBoxContainer = HBoxContainer.new()
	btn_h.alignment = BoxContainer.ALIGNMENT_END
	btn_h.add_theme_constant_override("separation", GameConfig.SP_XS)
	v.add_child(btn_h)

	return {"row": row, "buttons": btn_h, "text_box": text_v}


func _add_row_button(box: HBoxContainer, text: String, bg: Color, min_w: float = ROW_BTN_MIN_W) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(min_w, ROW_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(b, bg, AssetHelper.get_ui_font(), GameConfig.FS_BODY, 811)
	box.add_child(b)
	return b


## Satın al butonu: bakiye yetmiyorsa soluk görünür ama dokununca nazikçe söyler.
func _add_buy_button(box: HBoxContainer, price: int, on_buy: Callable) -> Button:
	var affordable: bool = Monetization.kirinti >= price
	var b: Button = _add_row_button(box, _kirinti_text(price), GameConfig.COLOR_GOLD, BUY_BTN_MIN_W)
	if not affordable:
		b.modulate = Color(1.0, 1.0, 1.0, 0.55)
	b.pressed.connect(func() -> void:
		if Monetization.kirinti < price:
			_show_status("Kırıntın yetmedi, biraz daha uç bakalım. (%s eksik)" % _fmt_num(price - Monetization.kirinti), true)
			return
		on_buy.call()
	)
	return b


func _refresh_list() -> void:
	if _list_box == null:
		return
	for c: Node in _list_box.get_children():
		_list_box.remove_child(c)
		c.queue_free()

	if _tab == "bocekler":
		_build_char_rows()
	elif _tab == "kostumler":
		_build_skin_rows()
	else:
		_build_pack_rows()


func _build_char_rows() -> void:
	for cid: String in CharacterData.ALL_ORDER:
		var cdata: Dictionary = CharacterData.get_character(cid)
		var price: int = int(cdata.get("price", 0))
		var owned: bool = Monetization.unlocked_chars.has(cid)
		var on_trial: bool = not owned and Monetization.trial_char == cid
		var usable: bool = owned or on_trial
		var selected: bool = usable and NetworkManager.selected_char_id == cid
		var tex: Texture2D = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
		var sub: String = str(cdata.get("tagline", ""))
		if on_trial:
			sub = "1 maçlık deneme hakkın var. " + sub
		var bg: Color = COLOR_ROW_SELECTED if selected else (COLOR_ROW if usable else COLOR_ROW_LOCKED)
		var parts: Dictionary = _make_row(bg, tex, str(cdata["display_name"]), sub, not usable)
		var box: HBoxContainer = parts["buttons"] as HBoxContainer
		var dname: String = str(cdata["display_name"])

		if usable:
			if selected:
				var sel_on: Button = _add_row_button(box, "Seçili", GameConfig.COLOR_SAGE)
				ComicUiHelper.style_tab(sel_on, true, GameConfig.FS_BODY)
				sel_on.pressed.connect(func() -> void:
					_show_status("%s zaten seninle, keyfine bak." % dname)
				)
			else:
				var sel_btn: Button = _add_row_button(box, "Seç", GameConfig.COLOR_GREEN_GO)
				sel_btn.pressed.connect(func() -> void:
					AudioManager.play_character_voice(cid, "dokun_1")
					NetworkManager.save_selected_char(cid)
					character_equipped.emit(cid)
					_show_status("%s artık seninle uçuyor." % dname)
					_refresh_list()
				)
		else:
			# Ödüllü reklam bu platformda yoksa (Steam / eklentisiz yayın) deneme butonu gösterilmez.
			var try_btn: Button = _add_row_button(box, "1 Maç Dene", GameConfig.COLOR_DUST_BLUE)
			try_btn.visible = Monetization.is_rewarded_ad_available()
			try_btn.pressed.connect(func() -> void:
				_show_status("Kısa bir reklam, sonra kanatlar senin...")
				Monetization.show_rewarded_ad(func(ok: bool) -> void:
					if not is_instance_valid(self):
						return
					if ok:
						Monetization.grant_trial(cid)
						NetworkManager.save_selected_char(cid)
						character_equipped.emit(cid)
						_show_status("%s 1 maçlığına senin!" % dname)
						_refresh_list()
					else:
						_show_status("Reklam yarıda kaldı, bir daha dener misin?", true)
				)
			)
			_add_buy_button(box, price, func() -> void:
				if Monetization.unlock_char_with_kirinti(cid, price):
					AudioManager.play_character_voice(cid, "dokun_1")
					NetworkManager.save_selected_char(cid)
					character_equipped.emit(cid)
					_show_status("%s açıldı, hayırlı uçuşlar!" % dname)
					_refresh_list()
				else:
					_show_status("Kırıntın yetmedi, biraz daha uç bakalım.", true)
			)


func _build_skin_rows() -> void:
	for cid: String in CharacterData.ALL_ORDER:
		var cdata: Dictionary = CharacterData.get_character(cid)
		var tex: Texture2D = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
		for sk_idx: int in range(1, 3):
			var sk_key: String = "%s_kostum_%d" % [cid, sk_idx]
			var owned: bool = Monetization.unlocked_skins.has(sk_key)
			var parts: Dictionary = _make_row(COLOR_ROW if owned else COLOR_ROW_LOCKED, tex,
				"%s" % str(cdata["display_name"]), "Kostüm #%d" % sk_idx)
			var box: HBoxContainer = parts["buttons"] as HBoxContainer
			if owned:
				var ob: Button = _add_row_button(box, "Dolapta", GameConfig.COLOR_SAGE)
				ob.disabled = true
			else:
				_add_buy_button(box, GameConfig.SKIN_COST, func() -> void:
					if Monetization.unlock_skin_with_kirinti(sk_key):
						_show_status("Yeni kostüm dolapta, yakıştı valla!")
						_refresh_list()
					else:
						_show_status("Kırıntın yetmedi, biraz daha uç bakalım.", true)
				)


func _build_pack_rows() -> void:
	if not Monetization.is_store_available():
		var parts_off: Dictionary = _make_row(COLOR_ROW, null, "Kasa şimdilik kapalı", "Paketler yakında burada olacak. O zamana kadar kırıntılar uçarak toplanıyor.")
		(parts_off["buttons"] as Control).visible = false
		return
	var packs: Array[Array] = [
		["paket_bocekler", "Böcek Paketi", "Yeni böceklerin hepsi bir arada"],
		["kirinti_kesesi_kucuk", "Küçük Kırıntı Kesesi", "+1.500 Kırıntı"],
		["kirinti_kesesi_buyuk", "Büyük Kırıntı Kesesi", "+5.000 Kırıntı"],
		["reklamsiz", "Reklamsız", "Maç arası reklamlar kalkar"],
	]
	for pk: Array in packs:
		var p_id: String = str(pk[0])
		var parts: Dictionary = _make_row(COLOR_ROW, null, str(pk[1]), str(pk[2]))
		var box: HBoxContainer = parts["buttons"] as HBoxContainer
		var owned: bool = p_id == "reklamsiz" and Monetization.ad_free
		if owned:
			var ob: Button = _add_row_button(box, "Alındı", GameConfig.COLOR_SAGE)
			ob.disabled = true
		else:
			var btn: Button = _add_row_button(box, "Satın Al", GameConfig.COLOR_GREEN_GO)
			btn.pressed.connect(func() -> void:
				_show_status("Kasaya gidiyoruz...")
				Monetization.purchase_product(p_id)
			)

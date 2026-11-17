class_name SkillsModal
extends Control

## 8.4: Ortada açılan Yetenekler ekranı (canlı mini önizlemeler + karakter geçişi).

signal character_chosen(char_id: String)
signal closed

var _char_idx: int = 0
var _allow_select: bool = true
var _panel: PanelContainer = null
var _portrait: TextureRect = null
var _title_lbl: Label = null
var _tagline_lbl: Label = null
var _rows_box: VBoxContainer = null
var _dots_box: HBoxContainer = null
var _select_btn: Button = null
var _preview_tweens: Array[Tween] = []
var _float_t: float = 0.0
var _drag_start_x: float = 0.0
var _dragging: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	_build_ui()
	_refresh_page()


func open_for(char_id: String, allow_select: bool = true) -> void:
	_allow_select = allow_select
	var idx: int = CharacterData.ALL_ORDER.find(char_id)
	_char_idx = idx if idx >= 0 else 0
	if _select_btn != null:
		_select_btn.visible = allow_select
	_refresh_page()


func _process(delta: float) -> void:
	_float_t += delta
	if _portrait != null:
		_portrait.position.y = sin(_float_t * 3.0) * 5.0


func _build_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	_panel = PanelContainer.new()
	_panel.position = Vector2(50.0, 140.0)
	_panel.size = Vector2(620.0, 980.0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ComicUiHelper.style_bitten_panel(_panel, GameConfig.COLOR_CREAM, 77, 22)
	add_child(_panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 12)
	_panel.add_child(root_v)

	# Üst başlık + oklar + portre
	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_theme_constant_override("separation", 14)
	root_v.add_child(top_h)

	var prev_btn: Button = Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(56.0, 56.0)
	ComicUiHelper.style_bitten_button(prev_btn, GameConfig.COLOR_PEACH, font, 26, 401)
	prev_btn.pressed.connect(func() -> void:
		_step_char(-1)
	)
	top_h.add_child(prev_btn)

	var header_v: VBoxContainer = VBoxContainer.new()
	header_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_v.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_child(header_v)

	var portrait_wrap: Control = Control.new()
	portrait_wrap.custom_minimum_size = Vector2(120.0, 110.0)
	portrait_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	header_v.add_child(portrait_wrap)

	_portrait = TextureRect.new()
	_portrait.size = Vector2(110.0, 110.0)
	_portrait.position = Vector2(5.0, 0.0)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_wrap.add_child(_portrait)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_override("font", font)
	_title_lbl.add_theme_font_size_override("font_size", 30)
	_title_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	header_v.add_child(_title_lbl)

	_tagline_lbl = Label.new()
	_tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_lbl.add_theme_font_override("font", font)
	_tagline_lbl.add_theme_font_size_override("font_size", 18)
	_tagline_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	header_v.add_child(_tagline_lbl)

	var next_btn: Button = Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(56.0, 56.0)
	ComicUiHelper.style_bitten_button(next_btn, GameConfig.COLOR_PEACH, font, 26, 402)
	next_btn.pressed.connect(func() -> void:
		_step_char(1)
	)
	top_h.add_child(next_btn)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", 12)
	root_v.add_child(_rows_box)

	_dots_box = HBoxContainer.new()
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.add_theme_constant_override("separation", 10)
	root_v.add_child(_dots_box)

	var btn_h: HBoxContainer = HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", 12)
	root_v.add_child(btn_h)

	_select_btn = Button.new()
	_select_btn.text = "Bu böceği seç"
	_select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_select_btn.custom_minimum_size = Vector2(0.0, 60.0)
	_select_btn.visible = _allow_select
	ComicUiHelper.style_bitten_button(_select_btn, Color("#8FD17C"), font, 24, 403)
	_select_btn.pressed.connect(func() -> void:
		var cid: String = CharacterData.ALL_ORDER[_char_idx]
		character_chosen.emit(cid)
		closed.emit()
		queue_free()
	)
	btn_h.add_child(_select_btn)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, 24, 404)
	close_btn.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	btn_h.add_child(close_btn)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_dragging = true
				_drag_start_x = mb.position.x
			elif _dragging:
				_dragging = false
				var dx: float = mb.position.x - _drag_start_x
				if absf(dx) > 55.0:
					_step_char(-1 if dx > 0.0 else 1)


func _step_char(delta_idx: int) -> void:
	var n: int = CharacterData.ALL_ORDER.size()
	_char_idx = (_char_idx + delta_idx + n) % n
	_refresh_page()


func _refresh_page() -> void:
	if _panel == null:
		return
	for tw: Tween in _preview_tweens:
		if tw != null and tw.is_valid():
			tw.kill()
	_preview_tweens.clear()

	for child: Node in _rows_box.get_children():
		child.queue_free()
	for child: Node in _dots_box.get_children():
		child.queue_free()

	var cid: String = CharacterData.ALL_ORDER[_char_idx]
	var cdata: Dictionary = CharacterData.get_character(cid)
	var font: Font = AssetHelper.get_ui_font()
	var tex: Texture2D = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	_portrait.texture = tex
	_title_lbl.text = str(cdata["display_name"])
	# Artık tüm karakterler gezilebildiği için kilitli olanı seçtirme
	if _select_btn != null:
		var unlocked: bool = Monetization.is_char_unlocked(cid)
		_select_btn.disabled = not unlocked
		_select_btn.text = "Bu böceği seç" if unlocked else "Kilitli: Pazar'dan aç"
	_tagline_lbl.text = str(cdata.get("tagline", ""))

	var skills: Array = cdata.get("skills", []) as Array
	for sk_v: Variant in skills:
		var sk: Dictionary = sk_v as Dictionary
		_rows_box.add_child(_build_skill_row(sk, tex, font))

	# Faz 10.2: İMZA ÖDÜLÜ satırı
	var sig_id: String = GameConfig.get_signature_for(cid)
	if not sig_id.is_empty():
		_rows_box.add_child(_build_signature_row(sig_id, font))

	for i: int in range(CharacterData.ALL_ORDER.size()):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(14.0 if i == _char_idx else 10.0, 14.0 if i == _char_idx else 10.0)
		var d_sb: StyleBoxFlat = StyleBoxFlat.new()
		d_sb.bg_color = GameConfig.COLOR_DARK_TEXT if i == _char_idx else Color(0.65, 0.60, 0.56, 0.65)
		d_sb.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", d_sb)
		_dots_box.add_child(dot)


func _build_skill_row(sk: Dictionary, bug_tex: Texture2D, font: Font) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.98, 0.94, 0.95)
	sb.border_color = GameConfig.COLOR_DARK_TEXT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(12)
	row.add_theme_stylebox_override("panel", sb)

	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)

	var slot_name: String = str(sk.get("slot", "pasif"))
	var type_lbl_txt: String = str(sk.get("type_label", "PASİF"))
	var pill_col: Color = GameConfig.COLOR_SAGE
	if type_lbl_txt == "AKTİF":
		pill_col = GameConfig.COLOR_DUST_BLUE
	elif type_lbl_txt == "KÜÇÜLME":
		pill_col = GameConfig.COLOR_DUST_PINK

	# Sol ikon rozeti
	var icon_box: Panel = Panel.new()
	icon_box.custom_minimum_size = Vector2(54.0, 54.0)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ic_sb: StyleBoxFlat = StyleBoxFlat.new()
	ic_sb.bg_color = pill_col
	ic_sb.border_color = GameConfig.COLOR_DARK_TEXT
	ic_sb.set_border_width_all(2)
	ic_sb.set_corner_radius_all(27)
	icon_box.add_theme_stylebox_override("panel", ic_sb)
	h.add_child(icon_box)

	var ic_lbl: Label = Label.new()
	ic_lbl.text = "P" if slot_name == "pasif" else ("E" if slot_name == "aktif1" else "Q")
	ic_lbl.size = Vector2(54.0, 54.0)
	ic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic_lbl.add_theme_font_override("font", font)
	ic_lbl.add_theme_font_size_override("font_size", 22)
	ic_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	icon_box.add_child(ic_lbl)

	# Orta açıklama alanı
	var mid_v: VBoxContainer = VBoxContainer.new()
	mid_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_v.add_theme_constant_override("separation", 3)
	h.add_child(mid_v)

	var title_h: HBoxContainer = HBoxContainer.new()
	title_h.add_theme_constant_override("separation", 8)
	mid_v.add_child(title_h)

	var name_lbl: Label = Label.new()
	name_lbl.text = str(sk.get("name", ""))
	name_lbl.add_theme_font_override("font", font)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	title_h.add_child(name_lbl)

	var tag_panel: PanelContainer = PanelContainer.new()
	var tag_sb: StyleBoxFlat = StyleBoxFlat.new()
	tag_sb.bg_color = pill_col
	tag_sb.set_corner_radius_all(8)
	tag_sb.set_content_margin_all(4)
	tag_panel.add_theme_stylebox_override("panel", tag_sb)
	title_h.add_child(tag_panel)

	var tag_lbl: Label = Label.new()
	tag_lbl.text = type_lbl_txt
	tag_lbl.add_theme_font_override("font", font)
	tag_lbl.add_theme_font_size_override("font_size", 12)
	tag_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	tag_panel.add_child(tag_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = str(sk.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", font)
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	mid_v.add_child(desc_lbl)

	var cd_val: float = float(sk.get("cooldown", 0.0))
	var dur_val: float = float(sk.get("duration", 0.0))
	var meta_txt: String = "Sürekli aktif" if slot_name == "pasif" else ("%d sn bekleme · %.1f sn sürer" % [int(cd_val), dur_val])
	var key_txt: String = "Otomatik" if slot_name == "pasif" else ("Dokun ya da E" if slot_name == "aktif1" else "Dokun ya da Q")
	var meta_lbl: Label = Label.new()
	meta_lbl.text = "%s  |  %s" % [meta_txt, key_txt]
	meta_lbl.add_theme_font_override("font", font)
	meta_lbl.add_theme_font_size_override("font_size", 13)
	meta_lbl.add_theme_color_override("font_color", Color("#554A43"))
	mid_v.add_child(meta_lbl)

	# Sağ canlı önizleme mini böceği
	var preview_wrap: Control = Control.new()
	preview_wrap.custom_minimum_size = Vector2(68.0, 68.0)
	preview_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(preview_wrap)

	var mini_bug: TextureRect = TextureRect.new()
	mini_bug.texture = bug_tex
	mini_bug.size = Vector2(54.0, 54.0)
	mini_bug.position = Vector2(7.0, 7.0)
	mini_bug.pivot_offset = Vector2(27.0, 27.0)
	mini_bug.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini_bug.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview_wrap.add_child(mini_bug)

	var p_tw: Tween = create_tween().set_loops()
	if slot_name == "aktif2":
		var sc: float = float(sk.get("scale", 0.6))
		p_tw.tween_property(mini_bug, "scale", Vector2(sc, sc), 0.35)
		p_tw.tween_interval(0.6)
		p_tw.tween_property(mini_bug, "scale", Vector2.ONE, 0.35)
		p_tw.tween_interval(0.5)
	elif slot_name == "aktif1":
		p_tw.tween_property(mini_bug, "modulate", Color(1.0, 0.72, 0.88, 0.55), 0.4)
		p_tw.tween_interval(0.5)
		p_tw.tween_property(mini_bug, "modulate", Color.WHITE, 0.4)
		p_tw.tween_interval(0.4)
	else:
		p_tw.tween_property(mini_bug, "rotation", deg_to_rad(10.0), 0.45)
		p_tw.tween_property(mini_bug, "rotation", deg_to_rad(-10.0), 0.45)
	_preview_tweens.append(p_tw)

	return row


## Karakterin imza ödülünü (ikon, ad, etki, düşme oranı) gösteren 4. satır.
func _build_signature_row(sig_id: String, font: Font) -> PanelContainer:
	var def: Dictionary = GameConfig.get_item_def(sig_id)
	var row: PanelContainer = PanelContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 0.97, 0.86, 0.97)
	sb.border_color = GameConfig.COLOR_DARK_TEXT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(12)
	row.add_theme_stylebox_override("panel", sb)

	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)

	var plate: TextureRect = TextureRect.new()
	plate.texture = IconFactory.plate_texture(54, Color("#FBEFC2"))
	plate.custom_minimum_size = Vector2(54.0, 54.0)
	plate.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(plate)
	var icon: TextureRect = TextureRect.new()
	icon.texture = IconFactory.item_icon(sig_id)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size = Vector2(38.0, 38.0)
	icon.position = Vector2(8.0, 8.0)
	plate.add_child(icon)
	var bob: Tween = create_tween().set_loops()
	bob.tween_property(icon, "position:y", 4.0, 0.5).set_trans(Tween.TRANS_SINE)
	bob.tween_property(icon, "position:y", 8.0, 0.5).set_trans(Tween.TRANS_SINE)
	_preview_tweens.append(bob)

	var mid_v: VBoxContainer = VBoxContainer.new()
	mid_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_v.add_theme_constant_override("separation", 3)
	h.add_child(mid_v)

	var title_h: HBoxContainer = HBoxContainer.new()
	title_h.add_theme_constant_override("separation", 8)
	mid_v.add_child(title_h)
	var name_lbl: Label = Label.new()
	name_lbl.text = str(def.get("name", sig_id))
	name_lbl.add_theme_font_override("font", font)
	name_lbl.add_theme_font_size_override("font_size", 20)
	name_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	title_h.add_child(name_lbl)

	var tag_panel: PanelContainer = PanelContainer.new()
	var tag_sb: StyleBoxFlat = StyleBoxFlat.new()
	tag_sb.bg_color = Color("#F5D76E")
	tag_sb.set_corner_radius_all(8)
	tag_sb.set_content_margin_all(4)
	tag_panel.add_theme_stylebox_override("panel", tag_sb)
	title_h.add_child(tag_panel)
	var tag_lbl: Label = Label.new()
	tag_lbl.text = "İMZA ÖDÜLÜ"
	tag_lbl.add_theme_font_override("font", font)
	tag_lbl.add_theme_font_size_override("font_size", 12)
	tag_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	tag_panel.add_child(tag_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = str(def.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.add_theme_font_override("font", font)
	desc_lbl.add_theme_font_size_override("font_size", 15)
	desc_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	mid_v.add_child(desc_lbl)

	var meta_lbl: Label = Label.new()
	meta_lbl.text = "Kutuların %%%d'u gizemli kutu; bu ödül oradan çıkar" % int(round(GameConfig.SIGNATURE_DROP_RATE * 100.0))
	meta_lbl.add_theme_font_override("font", font)
	meta_lbl.add_theme_font_size_override("font_size", 13)
	meta_lbl.add_theme_color_override("font_color", Color("#554A43"))
	mid_v.add_child(meta_lbl)
	return row

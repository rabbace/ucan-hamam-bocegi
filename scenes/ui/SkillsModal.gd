class_name SkillsModal
extends Control

## 8.4: Ortada açılan Yetenekler ekranı (canlı mini önizlemeler + karakter geçişi).
## Görünür alanda ortalanır, güvenli alana uyar; yana kaydırınca karakter değişir.

signal character_chosen(char_id: String)
signal closed

const ARROW_SIZE: float = 64.0
const PORTRAIT_SIZE: float = 112.0
const PORTRAIT_FLOAT_AMP: float = 5.0
const PORTRAIT_FLOAT_SPEED: float = 3.0
const SKILL_ICON_SIZE: float = 56.0
const PREVIEW_SIZE: float = 72.0
const PREVIEW_BUG_SIZE: float = 64.0
const FOOTER_BTN_HEIGHT: float = 60.0
const SWIPE_MIN_PX: float = 55.0
const DOT_SMALL: float = 10.0
const DOT_BIG: float = 16.0
const MIN_SCROLL_H: float = 160.0
const COLOR_ROW_BG: Color = Color("#FBF6EE")
const COLOR_META: Color = Color("#5E5048")

var _char_idx: int = 0
var _char_list: Array[String] = []
var _allow_select: bool = true
var _margin: MarginContainer = null
var _panel: PanelContainer = null
var _root_v: VBoxContainer = null
var _scroll: ScrollContainer = null
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
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 90
	if _char_list.is_empty():
		_rebuild_char_list("")
	_build_ui()
	get_viewport().size_changed.connect(_queue_relayout)
	_refresh_page()


func open_for(char_id: String, allow_select: bool = true) -> void:
	_allow_select = allow_select
	_rebuild_char_list(char_id)
	var idx: int = _char_list.find(char_id)
	_char_idx = idx if idx >= 0 else 0
	if _select_btn != null:
		_select_btn.visible = allow_select
	_refresh_page()


## Gezilecek karakterler: seçim modunda sahip olunan/denenen böcekler, izleme modunda hepsi.
func _rebuild_char_list(must_include: String) -> void:
	# Faz 10.2: tüm böcekler gezilebilir; kilitli olanın seç butonu kapalı (_show_char).
	_char_list.clear()
	_char_list.append_array(CharacterData.ALL_ORDER)
	if not must_include.is_empty() and not _char_list.has(must_include):
		_char_list.append(must_include)


func _process(delta: float) -> void:
	_float_t += delta
	if _portrait != null:
		_portrait.position.y = sin(_float_t * PORTRAIT_FLOAT_SPEED) * PORTRAIT_FLOAT_AMP


func _build_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.10, 0.06, 0.04, 0.55)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
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
	ComicUiHelper.style_bitten_panel(_panel, GameConfig.COLOR_CREAM, 77, GameConfig.SP_L)
	center.add_child(_panel)

	_root_v = VBoxContainer.new()
	_root_v.add_theme_constant_override("separation", GameConfig.SP_S)
	_panel.add_child(_root_v)

	# Üst: oklar + portre + isim
	var top_h: HBoxContainer = HBoxContainer.new()
	top_h.alignment = BoxContainer.ALIGNMENT_CENTER
	top_h.add_theme_constant_override("separation", GameConfig.SP_S)
	_root_v.add_child(top_h)

	var prev_btn: Button = Button.new()
	prev_btn.text = "<"
	prev_btn.custom_minimum_size = Vector2(ARROW_SIZE, ARROW_SIZE)
	prev_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ComicUiHelper.style_bitten_button(prev_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 401)
	prev_btn.pressed.connect(func() -> void:
		_step_char(-1)
	)
	top_h.add_child(prev_btn)

	var header_v: VBoxContainer = VBoxContainer.new()
	header_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_v.alignment = BoxContainer.ALIGNMENT_CENTER
	header_v.add_theme_constant_override("separation", 0)
	top_h.add_child(header_v)

	var portrait_wrap: Control = Control.new()
	portrait_wrap.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait_wrap.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_v.add_child(portrait_wrap)

	_portrait = TextureRect.new()
	_portrait.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_wrap.add_child(_portrait)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_title_lbl, GameConfig.FS_H2, GameConfig.COLOR_DARK_TEXT, true)
	header_v.add_child(_title_lbl)

	_tagline_lbl = Label.new()
	_tagline_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tagline_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_tagline_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	header_v.add_child(_tagline_lbl)

	var next_btn: Button = Button.new()
	next_btn.text = ">"
	next_btn.custom_minimum_size = Vector2(ARROW_SIZE, ARROW_SIZE)
	next_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ComicUiHelper.style_bitten_button(next_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 402)
	next_btn.pressed.connect(func() -> void:
		_step_char(1)
	)
	top_h.add_child(next_btn)

	# Yetenek satırları (uzunsa kayar)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_root_v.add_child(_scroll)

	_rows_box = VBoxContainer.new()
	_rows_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows_box.add_theme_constant_override("separation", GameConfig.SP_S)
	_rows_box.resized.connect(_queue_relayout)
	_scroll.add_child(_rows_box)

	_dots_box = HBoxContainer.new()
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.add_theme_constant_override("separation", GameConfig.SP_XS)
	_dots_box.custom_minimum_size = Vector2(0.0, DOT_BIG)
	_root_v.add_child(_dots_box)

	var btn_h: HBoxContainer = HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", GameConfig.SP_S)
	_root_v.add_child(btn_h)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.custom_minimum_size = Vector2(0.0, FOOTER_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 404)
	close_btn.pressed.connect(func() -> void:
		closed.emit()
		queue_free()
	)
	btn_h.add_child(close_btn)

	_select_btn = Button.new()
	_select_btn.text = "Bu böceği seç"
	_select_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_select_btn.size_flags_stretch_ratio = 1.4
	_select_btn.custom_minimum_size = Vector2(0.0, FOOTER_BTN_HEIGHT)
	_select_btn.visible = _allow_select
	ComicUiHelper.style_bitten_button(_select_btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON, 403)
	_select_btn.pressed.connect(func() -> void:
		var cid: String = _char_list[_char_idx]
		character_chosen.emit(cid)
		closed.emit()
		queue_free()
	)
	btn_h.add_child(_select_btn)


func _queue_relayout() -> void:
	_relayout.call_deferred()


func _relayout() -> void:
	if _panel == null or not is_inside_tree():
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
	_panel.custom_minimum_size.x = minf(GameConfig.MODAL_MAX_WIDTH, avail_w)
	# Kaydırma alanı içeriğin boyu kadar; ekrana sığmıyorsa sınırlanır.
	var chrome_h: float = _root_v.get_combined_minimum_size().y - _scroll.custom_minimum_size.y \
		+ float(GameConfig.SP_L * 2) + 8.0
	var content_h: float = _rows_box.get_combined_minimum_size().y
	_scroll.custom_minimum_size.y = clampf(content_h, 0.0, maxf(avail_h - chrome_h, MIN_SCROLL_H))


## Kaydırma (swipe) ile karakter değiştirme; butonlara gelen dokunuşları yemez.
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton) or _panel == null:
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_dragging = _panel.get_global_rect().has_point(mb.position)
		_drag_start_x = mb.position.x
	elif _dragging:
		_dragging = false
		var dx: float = mb.position.x - _drag_start_x
		if absf(dx) > SWIPE_MIN_PX:
			_step_char(-1 if dx > 0.0 else 1)


func _step_char(delta_idx: int) -> void:
	var n: int = _char_list.size()
	if n <= 1:
		return
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
		_rows_box.remove_child(child)
		child.queue_free()
	for child: Node in _dots_box.get_children():
		_dots_box.remove_child(child)
		child.queue_free()

	_char_idx = clampi(_char_idx, 0, _char_list.size() - 1)
	var cid: String = _char_list[_char_idx]
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

	for i: int in range(_char_list.size()):
		var on: bool = i == _char_idx
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(DOT_BIG if on else DOT_SMALL, DOT_BIG if on else DOT_SMALL)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d_sb: StyleBoxFlat = StyleBoxFlat.new()
		d_sb.bg_color = GameConfig.COLOR_DARK_TEXT if on else Color(0.65, 0.60, 0.56, 0.65)
		d_sb.set_corner_radius_all(8)
		dot.add_theme_stylebox_override("panel", d_sb)
		_dots_box.add_child(dot)
	_queue_relayout()


func _build_skill_row(sk: Dictionary, bug_tex: Texture2D, font: Font) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = COLOR_ROW_BG
	sb.border_color = GameConfig.COLOR_DARK_TEXT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(GameConfig.SP_S)
	row.add_theme_stylebox_override("panel", sb)

	var h: HBoxContainer = HBoxContainer.new()
	h.add_theme_constant_override("separation", GameConfig.SP_S)
	row.add_child(h)

	var slot_name: String = str(sk.get("slot", "pasif"))
	var type_lbl_txt: String = str(sk.get("type_label", "PASİF"))
	var pill_col: Color = GameConfig.COLOR_SAGE
	if type_lbl_txt == "AKTİF":
		pill_col = GameConfig.COLOR_DUST_BLUE
	elif type_lbl_txt == "KÜÇÜLME":
		pill_col = GameConfig.COLOR_DUST_PINK

	# Sol ikon rozeti
	var icon_box: PanelContainer = PanelContainer.new()
	icon_box.custom_minimum_size = Vector2(SKILL_ICON_SIZE, SKILL_ICON_SIZE)
	icon_box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	icon_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ic_sb: StyleBoxFlat = StyleBoxFlat.new()
	ic_sb.bg_color = pill_col
	ic_sb.border_color = GameConfig.COLOR_DARK_TEXT
	ic_sb.set_border_width_all(2)
	ic_sb.set_corner_radius_all(int(SKILL_ICON_SIZE * 0.5))
	icon_box.add_theme_stylebox_override("panel", ic_sb)
	h.add_child(icon_box)

	var ic_lbl: Label = Label.new()
	ic_lbl.text = "P" if slot_name == "pasif" else ("E" if slot_name == "aktif1" else "Q")
	ic_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ic_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(ic_lbl, GameConfig.FS_BUTTON, GameConfig.COLOR_DARK_TEXT, true)
	icon_box.add_child(ic_lbl)

	# Orta açıklama alanı
	var mid_v: VBoxContainer = VBoxContainer.new()
	mid_v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_v.add_theme_constant_override("separation", 2)
	h.add_child(mid_v)

	var title_h: HFlowContainer = HFlowContainer.new()
	title_h.add_theme_constant_override("h_separation", GameConfig.SP_XS)
	title_h.add_theme_constant_override("v_separation", 4)
	mid_v.add_child(title_h)

	var name_lbl: Label = Label.new()
	name_lbl.text = str(sk.get("name", ""))
	ComicUiHelper.style_label(name_lbl, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, true)
	title_h.add_child(name_lbl)

	var tag_panel: PanelContainer = PanelContainer.new()
	tag_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var tag_sb: StyleBoxFlat = StyleBoxFlat.new()
	tag_sb.bg_color = pill_col
	tag_sb.set_corner_radius_all(10)
	tag_sb.content_margin_left = GameConfig.SP_XS
	tag_sb.content_margin_right = GameConfig.SP_XS
	tag_sb.content_margin_top = 0
	tag_sb.content_margin_bottom = 2
	tag_panel.add_theme_stylebox_override("panel", tag_sb)
	title_h.add_child(tag_panel)

	var tag_lbl: Label = Label.new()
	tag_lbl.text = type_lbl_txt
	ComicUiHelper.style_label(tag_lbl, GameConfig.FS_TINY, GameConfig.COLOR_DARK_TEXT, true)
	tag_panel.add_child(tag_lbl)

	var desc_lbl: Label = Label.new()
	desc_lbl.text = str(sk.get("desc", ""))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(desc_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	mid_v.add_child(desc_lbl)

	var cd_val: float = float(sk.get("cooldown", 0.0))
	var dur_val: float = float(sk.get("duration", 0.0))
	var meta_txt: String = "Hep açık" if slot_name == "pasif" else ("%d sn bekleme · %.1f sn sürer" % [int(cd_val), dur_val])
	var key_txt: String = "kendiliğinden" if slot_name == "pasif" else ("dokun ya da E" if slot_name == "aktif1" else "dokun ya da Q")
	var meta_lbl: Label = Label.new()
	meta_lbl.text = "%s · %s" % [meta_txt, key_txt]
	meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(meta_lbl, GameConfig.FS_TINY, COLOR_META)
	mid_v.add_child(meta_lbl)

	# Sağ canlı önizleme mini böceği
	var preview_wrap: Control = Control.new()
	preview_wrap.custom_minimum_size = Vector2(PREVIEW_SIZE, PREVIEW_SIZE)
	preview_wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(preview_wrap)

	var inset: float = (PREVIEW_SIZE - PREVIEW_BUG_SIZE) * 0.5
	var mini_bug: TextureRect = TextureRect.new()
	mini_bug.texture = bug_tex
	mini_bug.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mini_bug.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mini_bug.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview_wrap.add_child(mini_bug)
	# Çapa ile sabitle: kap ne olursa olsun böcek kutunun içinde kalsın.
	mini_bug.anchor_right = 1.0
	mini_bug.anchor_bottom = 1.0
	mini_bug.offset_left = inset
	mini_bug.offset_top = inset
	mini_bug.offset_right = -inset
	mini_bug.offset_bottom = -inset
	mini_bug.pivot_offset = Vector2(PREVIEW_BUG_SIZE, PREVIEW_BUG_SIZE) * 0.5

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

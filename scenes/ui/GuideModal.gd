class_name GuideModal
extends Control

## 8.5: Sayfalı "Nasıl Oynanır?" kaydırmalı rehber ekranı.
## Görünür alanda ortalanır; mini sahne panel genişliğine göre ölçeklenir.

signal closed

const STAGE_BASE: Vector2 = Vector2(540.0, 220.0)
const SPRITE_SIZE: float = 96.0
const SPRITE_A_X: float = 110.0
const SPRITE_A_Y: float = 78.0
const SPRITE_A_AMP: float = 18.0
const SPRITE_B_X: float = 340.0
const SPRITE_B_Y: float = 66.0
const SPRITE_B_AMP: float = 30.0
const BODY_MIN_LINES: int = 4
const FOOTER_BTN_HEIGHT: float = 64.0
const SWIPE_MIN_PX: float = 55.0
const DOT_SMALL: float = 10.0
const DOT_BIG: float = 16.0

const PAGES: Array[Dictionary] = [
	{"title": "Uç!", "body": "Ekrana dokun, böcek kanat çırpsın. İnsanların arasından geç. Tezgâha ya da tavana çarpma.", "kind": "fly"},
	{"title": "Kontroller", "body": "Dokun = uç, yukarı kaydır = Aktif 1, aşağı kaydır = küçül, iki parmak = güçlendirme! Alttaki alanda kaydırmayı dene.", "kind": "controls"},
	{"title": "Ödü Kopan İnsan", "body": "Bir insanın ne kadar yakınından geçersen o kadar büyük çığlık atar ve o kadar çok puan alırsın. Art arda yakın geçişler kombo yapar.", "kind": "scare"},
	{"title": "Seviyeler", "body": "Engel geçtikçe mahalle ayaklanır: hız artar, aralıklar daralır, yeni sürprizler gelir.", "kind": "levels"},
	{"title": "Karakterler", "body": "Her böceğin 1 pasif ve 2 aktif yeteneği var; hepsi küçülebilir. Yetenekler butonuyla detayları incele.", "kind": "chars"},
	{"title": "Güçlendirmeler", "body": "Yolda çıkan kutuları topla, alttaki yuvarlak tepsiden dokunarak kullan. Dondurma, Turbo, Yedek Bacak, Mıknatıs seni kurtarır. Her böceğin kendine özel bir ödülü var. Gizemli kutuları topla!", "kind": "powerups"},
	{"title": "Şuraları Aydınlat Hele!", "body": "Ortam kararınca füzeler çapraz gelir. Kırmızı çizgi füzenin yolunu gösterir; çizgiden uzak dur.", "kind": "missiles"},
	{"title": "Arkadaşlarla", "body": "Aynı Wi-Fi'de oda kur ya da katıl. Son kalan kazanır. Sataşma güçlendirmeleri, laf atma, Hayalet Terlik ve maç sonu sıralama!", "kind": "multi"},
]

var _page_idx: int = 0
var _margin: MarginContainer = null
var _panel: PanelContainer = null
var _title_lbl: Label = null
var _body_lbl: Label = null
var _stage_panel: Panel = null
var _stage: Control = null
var _dots_box: HBoxContainer = null
var _next_btn: Button = null
var _stage_t: float = 0.0
var _sprite_a: TextureRect = null
var _sprite_b: TextureRect = null
var _drag_start_x: float = 0.0
var _dragging: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 92
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	_relayout()
	_refresh_page()


func _process(delta: float) -> void:
	_stage_t += delta
	if _sprite_a != null:
		_sprite_a.position.y = SPRITE_A_Y + sin(_stage_t * 3.5) * SPRITE_A_AMP
	if _sprite_b != null:
		_sprite_b.position.x = SPRITE_B_X + cos(_stage_t * 2.2) * SPRITE_B_AMP


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
	ComicUiHelper.style_bitten_panel(_panel, GameConfig.COLOR_CREAM, 88, GameConfig.SP_L)
	center.add_child(_panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", GameConfig.SP_M)
	_panel.add_child(root_v)

	var head_v: VBoxContainer = VBoxContainer.new()
	head_v.add_theme_constant_override("separation", 0)
	root_v.add_child(head_v)

	var header_lbl: Label = Label.new()
	header_lbl.text = "NASIL OYNANIR?"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(header_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, true)
	head_v.add_child(header_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_title_lbl, GameConfig.FS_H2, GameConfig.COLOR_WARN_RED, true)
	head_v.add_child(_title_lbl)

	# Canlı mini sahne alanı (540x220 tabanda kurulur, panele göre ölçeklenir)
	_stage_panel = Panel.new()
	_stage_panel.custom_minimum_size = STAGE_BASE
	_stage_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_stage_panel.clip_contents = true
	_stage_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st_sb: StyleBoxFlat = StyleBoxFlat.new()
	st_sb.bg_color = Color("#EDE0CE")
	st_sb.border_color = GameConfig.COLOR_DARK_TEXT
	st_sb.set_border_width_all(3)
	st_sb.set_corner_radius_all(18)
	_stage_panel.add_theme_stylebox_override("panel", st_sb)
	root_v.add_child(_stage_panel)

	_stage = Control.new()
	_stage.size = STAGE_BASE
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage_panel.add_child(_stage)

	_sprite_a = TextureRect.new()
	_sprite_a.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	_sprite_a.position = Vector2(SPRITE_A_X, SPRITE_A_Y)
	_sprite_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_sprite_a)

	_sprite_b = TextureRect.new()
	_sprite_b.size = Vector2(SPRITE_SIZE, SPRITE_SIZE)
	_sprite_b.position = Vector2(SPRITE_B_X, SPRITE_B_Y)
	_sprite_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_sprite_b)

	_body_lbl = Label.new()
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Sayfalar arasında panel boyu zıplamasın diye sabit satır yüksekliği ayrılır.
	_body_lbl.custom_minimum_size = Vector2(0.0, float(GameConfig.FS_BODY) * 1.45 * float(BODY_MIN_LINES))
	ComicUiHelper.style_label(_body_lbl, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT)
	root_v.add_child(_body_lbl)

	_dots_box = HBoxContainer.new()
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.custom_minimum_size = Vector2(0.0, DOT_BIG)
	_dots_box.add_theme_constant_override("separation", GameConfig.SP_XS)
	root_v.add_child(_dots_box)

	var btn_h: HBoxContainer = HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", GameConfig.SP_S)
	root_v.add_child(btn_h)

	var skip_btn: Button = Button.new()
	skip_btn.text = "Atla"
	skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_btn.custom_minimum_size = Vector2(0.0, FOOTER_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(skip_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 501)
	skip_btn.pressed.connect(_finish_guide)
	btn_h.add_child(skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "İleri"
	_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_btn.size_flags_stretch_ratio = 1.4
	_next_btn.custom_minimum_size = Vector2(0.0, FOOTER_BTN_HEIGHT)
	ComicUiHelper.style_bitten_button(_next_btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON, 502)
	_next_btn.pressed.connect(func() -> void:
		if _page_idx >= PAGES.size() - 1:
			_finish_guide()
		else:
			_page_idx += 1
			_refresh_page()
	)
	btn_h.add_child(_next_btn)


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
	var w: float = minf(GameConfig.MODAL_MAX_WIDTH, avail_w)
	_panel.custom_minimum_size.x = w
	# Sahne: iç genişliğe göre ölçek; kısa ekranda yükseklikten de sınırla.
	var inner_w: float = w - float(GameConfig.SP_L * 2)
	var sc: float = inner_w / STAGE_BASE.x
	var max_stage_h: float = avail_h * 0.28
	sc = minf(sc, max_stage_h / STAGE_BASE.y)
	sc = maxf(sc, 0.4)
	_stage_panel.custom_minimum_size = STAGE_BASE * sc
	_stage.scale = Vector2(sc, sc)


## Yana kaydırınca sayfa değişir; butonlara gelen dokunuşları yemez.
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
			_page_idx = clampi(_page_idx + (-1 if dx > 0.0 else 1), 0, PAGES.size() - 1)
			_refresh_page()


func _refresh_page() -> void:
	var p: Dictionary = PAGES[_page_idx]
	_title_lbl.text = str(p["title"])
	_body_lbl.text = str(p["body"])
	_next_btn.text = "Başla!" if _page_idx >= PAGES.size() - 1 else "İleri"

	_sprite_a.texture = AssetHelper.texture("res://assets/sprites/char_klasik.png", "char_klasik", GameConfig.PLAYER_SPRITE_SIZE)
	var kind: String = str(p["kind"])
	if kind == "missiles":
		_sprite_b.texture = AssetHelper.texture(GameConfig.MISSILE_TEX_PATH, "missile", GameConfig.MISSILE_SIZE)
	elif kind == "chars":
		_sprite_b.texture = AssetHelper.texture("res://assets/sprites/char_duktur.png", "char_duktur", GameConfig.PLAYER_SPRITE_SIZE)
	elif kind == "multi":
		_sprite_b.texture = AssetHelper.texture("res://assets/sprites/char_halaybasi.png", "char_halaybasi", GameConfig.PLAYER_SPRITE_SIZE)
	else:
		_sprite_b.texture = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(96, 96))

	for child: Node in _dots_box.get_children():
		_dots_box.remove_child(child)
		child.queue_free()
	for i: int in range(PAGES.size()):
		var on: bool = i == _page_idx
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(DOT_BIG if on else DOT_SMALL, DOT_BIG if on else DOT_SMALL)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var d_sb: StyleBoxFlat = StyleBoxFlat.new()
		d_sb.bg_color = GameConfig.COLOR_DARK_TEXT if on else Color(0.65, 0.60, 0.56, 0.65)
		d_sb.set_corner_radius_all(8)
		dot.add_theme_stylebox_override("panel", d_sb)
		_dots_box.add_child(dot)


func _finish_guide() -> void:
	AudioManager.mark_guide_seen()
	closed.emit()
	queue_free()

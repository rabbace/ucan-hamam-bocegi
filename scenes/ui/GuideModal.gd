class_name GuideModal
extends Control

## 8.5: 7 sayfalık "Nasıl Oynanır?" kaydırmalı rehber ekranı.

signal closed

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
var _title_lbl: Label = null
var _body_lbl: Label = null
var _stage: Control = null
var _dots_box: HBoxContainer = null
var _next_btn: Button = null
var _stage_t: float = 0.0
var _sprite_a: TextureRect = null
var _sprite_b: TextureRect = null
var _drag_start_x: float = 0.0
var _dragging: bool = false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 92
	_build_ui()
	_refresh_page()


func _process(delta: float) -> void:
	_stage_t += delta
	if _sprite_a != null:
		_sprite_a.position.y = 78.0 + sin(_stage_t * 3.5) * 18.0
	if _sprite_b != null:
		_sprite_b.position.x = 340.0 + cos(_stage_t * 2.2) * 30.0


func _build_ui() -> void:
	var font: Font = AssetHelper.get_ui_font()

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel: PanelContainer = PanelContainer.new()
	panel.position = Vector2(50.0, 210.0)
	panel.size = Vector2(620.0, 820.0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	ComicUiHelper.style_bitten_panel(panel, GameConfig.COLOR_CREAM, 88, 26)
	add_child(panel)

	var root_v: VBoxContainer = VBoxContainer.new()
	root_v.add_theme_constant_override("separation", 16)
	panel.add_child(root_v)

	var header_lbl: Label = Label.new()
	header_lbl.text = "NASIL OYNANIR?"
	header_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_lbl.add_theme_font_override("font", font)
	header_lbl.add_theme_font_size_override("font_size", 20)
	header_lbl.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	root_v.add_child(header_lbl)

	_title_lbl = Label.new()
	_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_lbl.add_theme_font_override("font", font)
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	root_v.add_child(_title_lbl)

	# Canlı mini sahne alanı
	var stage_panel: Panel = Panel.new()
	stage_panel.custom_minimum_size = Vector2(540.0, 220.0)
	var st_sb: StyleBoxFlat = StyleBoxFlat.new()
	st_sb.bg_color = Color("#EDE0CE")
	st_sb.border_color = GameConfig.COLOR_DARK_TEXT
	st_sb.set_border_width_all(3)
	st_sb.set_corner_radius_all(18)
	stage_panel.add_theme_stylebox_override("panel", st_sb)
	root_v.add_child(stage_panel)

	_stage = Control.new()
	_stage.size = Vector2(540.0, 220.0)
	_stage.clip_contents = true
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_panel.add_child(_stage)

	_sprite_a = TextureRect.new()
	_sprite_a.size = Vector2(96.0, 96.0)
	_sprite_a.position = Vector2(110.0, 72.0)
	_sprite_a.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_a.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_sprite_a)

	_sprite_b = TextureRect.new()
	_sprite_b.size = Vector2(96.0, 96.0)
	_sprite_b.position = Vector2(340.0, 66.0)
	_sprite_b.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite_b.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_stage.add_child(_sprite_b)

	_body_lbl = Label.new()
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_lbl.add_theme_font_override("font", font)
	_body_lbl.add_theme_font_size_override("font_size", 23)
	_body_lbl.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	root_v.add_child(_body_lbl)

	_dots_box = HBoxContainer.new()
	_dots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots_box.add_theme_constant_override("separation", 10)
	root_v.add_child(_dots_box)

	var btn_h: HBoxContainer = HBoxContainer.new()
	btn_h.add_theme_constant_override("separation", 14)
	root_v.add_child(btn_h)

	var skip_btn: Button = Button.new()
	skip_btn.text = "Geç"
	skip_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(skip_btn, GameConfig.COLOR_PEACH, font, 24, 501)
	skip_btn.pressed.connect(_finish_guide)
	btn_h.add_child(skip_btn)

	_next_btn = Button.new()
	_next_btn.text = "İleri"
	_next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_next_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(_next_btn, Color("#8FD17C"), font, 24, 502)
	_next_btn.pressed.connect(func() -> void:
		if _page_idx >= PAGES.size() - 1:
			_finish_guide()
		else:
			_page_idx += 1
			_refresh_page()
	)
	btn_h.add_child(_next_btn)


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
		child.queue_free()
	for i: int in range(PAGES.size()):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(14.0 if i == _page_idx else 10.0, 14.0 if i == _page_idx else 10.0)
		var d_sb: StyleBoxFlat = StyleBoxFlat.new()
		d_sb.bg_color = GameConfig.COLOR_DARK_TEXT if i == _page_idx else Color(0.65, 0.60, 0.56, 0.65)
		d_sb.set_corner_radius_all(7)
		dot.add_theme_stylebox_override("panel", d_sb)
		_dots_box.add_child(dot)


func _finish_guide() -> void:
	AudioManager.mark_guide_seen()
	closed.emit()
	queue_free()

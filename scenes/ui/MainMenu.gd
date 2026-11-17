extends Control

## Ana menü: üst çubuk (kırıntı + ayarlar), logo, isim notu, karakter şeridi,
## tek baskın "HEMEN UÇ!" eylemi, ikincil sıra ve alt gezinme çubuğu.
## Tüm yerleşim container + güvenli alan ile kurulur; her ekran oranına uyar.

const CARD_SCENE: PackedScene = preload("res://scenes/ui/CharacterCard.tscn")

# Menüye özel yerleşim sabitleri
const CONTENT_MAX_WIDTH: float = 680.0      # tablette içerik sütunu en fazla bu kadar geniş
const TOP_BAR_H: float = 64.0               # üst çubuk buton yüksekliği
const LOGO_MIN_H: float = 150.0             # kısa ekranda logo yüksekliği
const LOGO_MAX_H: float = 230.0             # uzun ekranda logo yüksekliği
const LOGO_GROW_RATIO: float = 0.3          # 1280'in üstündeki her px'in logoya giden payı
const STRIP_H: float = 176.0                # karakter şeridi yüksekliği
const PLAY_BUTTON_H: float = 96.0           # birincil buton yüksekliği
const SECONDARY_BUTTON_H: float = 72.0      # ikincil buton yüksekliği
const NAV_BUTTON_H: float = 92.0            # alt gezinme butonu yüksekliği
const NAV_ICON_SIZE: float = 44.0           # alt gezinme ikon boyutu
const ICON_LINE_W: float = 4.0              # çizilmiş ikon çizgi kalınlığı
const NOTE_TILT_DEG: float = -1.1           # buzdolabı notunun eğikliği
const TAPE_SIZE: Vector2 = Vector2(76.0, 22.0)
const BUG_TARGET_PX: float = 120.0          # menü böceğinin ekrandaki boyu
const BUG_FLOAT_AMP: float = 12.0           # böceğin süzülme genliği
const BUG_FLEE_OFFSET: float = 140.0        # kaçarken ekran dışına gittiği mesafe
const SLIPPER_HIDE_OFFSET: float = 70.0     # terliğin saklandığı ekran dışı mesafe
const SLIPPER_PEEK_IN: float = 70.0         # terliğin içeri uzandığı mesafe
const THEME_THUMB_H: float = 172.0          # mekan önizleme kutusu yüksekliği
const POP_SEC: float = 0.24                 # ödül pop animasyonu süresi
const INPUT_BG: Color = Color("#FFFBF4")
const PANEL_SOFT_BG: Color = Color("#FFF6EA")
const SELECTED_BG: Color = Color("#C4E2BA")

var _cards: Dictionary = {}
var _bug_float_time: float = 0.0
var _bug_tap_btn: Button = null
var _bug_bubble: Label = null
var _bug_react_until: float = 0.0
var _bug_home: Vector2 = Vector2(560.0, 200.0)
var _slipper_peek: Sprite2D = null
var _slipper_home: Vector2 = Vector2(790.0, 600.0)
var _peek_timer: float = 4.5
var _tap_count: int = 0
var _last_tap_ms: int = 0
var _last_tap_line_idx: int = -1
var _bug_fled: bool = false

var _layout: MarginContainer = null
var _column: VBoxContainer = null
var _crumb_btn: Button = null
var _crumb_label: Label = null
var _settings_btn: Button = null
var _logo_rect: TextureRect = null
var _note_wrap: Control = null
var _tapes: Array[ColorRect] = []
var _strip_scroll: ScrollContainer = null
var _strip_box: HBoxContainer = null
var _quest_icon: Control = null
var _bg_thumbs: Dictionary = {}

var form_card: PanelContainer = null
var name_label: Label = null
var name_input: LineEdit = null
var solo_button: Button = null
var daily_button: Button = null
var friends_button: Button = null
var notice_label: Label = null

# Yerel ağ odaları penceresi (açıkken dolu)
var _join_modal: Control = null
var rooms_list: VBoxContainer = null
var ip_input: LineEdit = null
var join_status_label: Label = null

@onready var bg_rect: TextureRect = $BgRect
@onready var menu_bug: Sprite2D = $MenuBug


## Basit çizgi ikonları: tek aile, aynı kalınlık, yuvarlak uçlar.
class MenuIcon extends Control:
	var kind: String = "gear"
	var ink: Color = Color("#24160E")
	var line_w: float = 4.0

	func _init(p_kind: String = "gear", p_size: float = 44.0, p_line_w: float = 4.0) -> void:
		kind = p_kind
		line_w = p_line_w
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _seg(a: Vector2, b: Vector2) -> void:
		draw_line(a, b, ink, line_w, true)
		draw_circle(a, line_w * 0.5, ink)
		draw_circle(b, line_w * 0.5, ink)

	func _poly(pts: PackedVector2Array, closed: bool) -> void:
		for i: int in range(pts.size() - 1):
			_seg(pts[i], pts[i + 1])
		if closed and pts.size() > 2:
			_seg(pts[pts.size() - 1], pts[0])

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var c: Vector2 = size * 0.5
		match kind:
			"gear":
				var r: float = s * 0.27
				draw_arc(c, r, 0.0, TAU, 32, ink, line_w, true)
				draw_arc(c, r * 0.4, 0.0, TAU, 20, ink, line_w, true)
				for i: int in range(8):
					var ang: float = TAU * float(i) / 8.0
					var dir: Vector2 = Vector2(cos(ang), sin(ang))
					_seg(c + dir * r, c + dir * (s * 0.42))
			"shop":
				var top_y: float = c.y - s * 0.06
				_poly(PackedVector2Array([
					Vector2(c.x - s * 0.40, top_y), Vector2(c.x - s * 0.30, c.y + s * 0.36),
					Vector2(c.x + s * 0.30, c.y + s * 0.36), Vector2(c.x + s * 0.40, top_y),
				]), true)
				draw_arc(Vector2(c.x, top_y), s * 0.24, PI, TAU, 18, ink, line_w, true)
				_seg(Vector2(c.x - s * 0.12, top_y + s * 0.12), Vector2(c.x - s * 0.10, c.y + s * 0.24))
				_seg(Vector2(c.x + s * 0.12, top_y + s * 0.12), Vector2(c.x + s * 0.10, c.y + s * 0.24))
			"quests":
				var l: float = c.x - s * 0.30
				var rr: float = c.x + s * 0.30
				var t: float = c.y - s * 0.36
				var b: float = c.y + s * 0.40
				_poly(PackedVector2Array([Vector2(l, t), Vector2(rr, t), Vector2(rr, b), Vector2(l, b)]), true)
				_seg(Vector2(c.x - s * 0.10, t), Vector2(c.x + s * 0.10, t))
				_poly(PackedVector2Array([
					Vector2(l + s * 0.12, c.y - s * 0.08), Vector2(l + s * 0.20, c.y + 0.0),
					Vector2(l + s * 0.34, c.y - s * 0.16),
				]), false)
				_seg(Vector2(l + s * 0.12, c.y + s * 0.20), Vector2(rr - s * 0.12, c.y + s * 0.20))
			"skills":
				_poly(PackedVector2Array([
					Vector2(c.x + s * 0.08, c.y - s * 0.42), Vector2(c.x - s * 0.22, c.y + s * 0.04),
					Vector2(c.x + s * 0.02, c.y + s * 0.04), Vector2(c.x - s * 0.08, c.y + s * 0.42),
					Vector2(c.x + s * 0.24, c.y - s * 0.08), Vector2(c.x + s * 0.0, c.y - s * 0.08),
				]), true)
			"guide":
				var top: float = c.y - s * 0.26
				var bot: float = c.y + s * 0.32
				_poly(PackedVector2Array([
					Vector2(c.x, top + s * 0.06), Vector2(c.x - s * 0.40, top),
					Vector2(c.x - s * 0.40, bot - s * 0.06), Vector2(c.x, bot),
				]), false)
				_poly(PackedVector2Array([
					Vector2(c.x, top + s * 0.06), Vector2(c.x + s * 0.40, top),
					Vector2(c.x + s * 0.40, bot - s * 0.06), Vector2(c.x, bot),
				]), false)
				_seg(Vector2(c.x, top + s * 0.06), Vector2(c.x, bot))
			"plus":
				_seg(Vector2(c.x - s * 0.30, c.y), Vector2(c.x + s * 0.30, c.y))
				_seg(Vector2(c.x, c.y - s * 0.30), Vector2(c.x, c.y + s * 0.30))
			"crumb":
				# Küçük ekmek somunu: altın gövde, mürekkep kontur, üstte çentikler
				var pts: PackedVector2Array = PackedVector2Array()
				for i: int in range(24):
					var a: float = TAU * float(i) / 24.0
					var ry: float = s * (0.30 if sin(a) < 0.0 else 0.22)
					pts.append(c + Vector2(cos(a) * s * 0.42, sin(a) * ry + s * 0.04))
				draw_colored_polygon(pts, Color("#E8B866"))
				_poly(pts, true)
				_seg(c + Vector2(-s * 0.18, -s * 0.10), c + Vector2(-s * 0.08, -s * 0.02))
				_seg(c + Vector2(s * 0.02, -s * 0.14), c + Vector2(s * 0.12, -s * 0.06))


func _ready() -> void:
	get_tree().paused = false
	Monetization.end_match_character()
	if not Monetization.is_char_unlocked(NetworkManager.selected_char_id):
		NetworkManager.save_selected_char("klasik")
	_build_layout()
	_apply_bg_theme()
	AudioManager.play_music("res://assets/sounds/muzik_menu.ogg")

	NetworkManager.get_discovery().rooms_updated.connect(_on_rooms_updated)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	Monetization.kirinti_changed.connect(_on_kirinti_changed)

	if not NetworkManager.pending_notice.is_empty():
		_show_notice(NetworkManager.pending_notice)
		NetworkManager.pending_notice = ""

	_populate_character_cards()
	_refresh_menu_bug()
	_update_crumbs(false)
	_refresh_quest_badge()
	_setup_menu_polish()

	get_viewport().size_changed.connect(_relayout)
	_relayout()
	_fit_pill(_crumb_btn)
	_fit_pill(_settings_btn)

	if not AudioManager.guide_seen:
		var gm_auto: GuideModal = GuideModal.new()
		add_child(gm_auto)


# ---------------------------------------------------------------------------
# Yerleşim
# ---------------------------------------------------------------------------

func _build_layout() -> void:
	var font: Font = AssetHelper.get_ui_font()

	var scrim: ColorRect = ColorRect.new()
	scrim.name = "BgScrim"
	scrim.color = Color(0.08, 0.05, 0.03, 0.24)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)
	move_child(scrim, bg_rect.get_index() + 1)

	_layout = MarginContainer.new()
	_layout.name = "Layout"
	_layout.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layout)

	_column = VBoxContainer.new()
	_column.name = "Column"
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_theme_constant_override("separation", GameConfig.SP_M)
	_layout.add_child(_column)

	# 1. Üst çubuk: kırıntı hapı + ayarlar
	var top_bar: HBoxContainer = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(top_bar)

	_crumb_btn = _make_icon_button("crumb", "0", GameConfig.FS_BODY, false, 36.0)
	_crumb_btn.name = "CrumbPill"
	_crumb_btn.custom_minimum_size.y = TOP_BAR_H
	ComicUiHelper.style_bitten_button(_crumb_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_BODY, 120)
	_crumb_label = _crumb_btn.get_node("Box/Label") as Label
	_crumb_btn.tooltip_text = "Kırıntı bakiyen"
	_crumb_btn.pressed.connect(_open_shop)
	top_bar.add_child(_crumb_btn)

	var top_spacer: Control = Control.new()
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	_settings_btn = _make_icon_button("gear", "Ayarlar", GameConfig.FS_SMALL, false, 36.0)
	_settings_btn.name = "SettingsButton"
	_settings_btn.custom_minimum_size.y = TOP_BAR_H
	ComicUiHelper.style_bitten_button(_settings_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_SMALL, 121)
	_settings_btn.pressed.connect(_open_settings_modal)
	top_bar.add_child(_settings_btn)

	_column.add_child(_make_spacer(1.0))

	# 2. Logo (yoksa yazı başlık)
	var logo_path: String = "res://assets/sprites/title_logo.png"
	var logo_tex: Texture2D = load(logo_path) as Texture2D if ResourceLoader.exists(logo_path) else null
	if logo_tex != null:
		_logo_rect = TextureRect.new()
		_logo_rect.name = "TitleLogo"
		_logo_rect.texture = logo_tex
		_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_logo_rect.custom_minimum_size = Vector2(0.0, LOGO_MIN_H)
		_column.add_child(_logo_rect)
	else:
		var title_lbl: Label = Label.new()
		title_lbl.text = "UÇAN HAMAM BÖCEĞİ"
		title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(title_lbl, GameConfig.FS_HERO, GameConfig.COLOR_DARK_TEXT, true)
		title_lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
		title_lbl.add_theme_constant_override("outline_size", 10)
		_column.add_child(title_lbl)

	_column.add_child(_make_spacer(0.6))

	# 3. Buzdolabı notu: kart bir sarmalayıcıda, bantlar kart yerleşiminden bağımsız
	_note_wrap = Control.new()
	_note_wrap.name = "NoteWrap"
	_note_wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_column.add_child(_note_wrap)

	form_card = PanelContainer.new()
	form_card.name = "FormCard"
	ComicUiHelper.style_bitten_panel(form_card, GameConfig.COLOR_CREAM, 11, GameConfig.SP_M)
	form_card.rotation = deg_to_rad(NOTE_TILT_DEG)
	_note_wrap.add_child(form_card)

	var note_v: VBoxContainer = VBoxContainer.new()
	note_v.add_theme_constant_override("separation", GameConfig.SP_XS)
	form_card.add_child(note_v)

	name_label = Label.new()
	name_label.text = "Böcek adın (en fazla %d harf)" % GameConfig.MAX_NAME_LENGTH
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(name_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	note_v.add_child(name_label)

	name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "Böcek"
	name_input.max_length = GameConfig.MAX_NAME_LENGTH
	name_input.text = NetworkManager.local_player_name
	name_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_input.custom_minimum_size = Vector2(0.0, 56.0)
	_style_line_edit(name_input)
	name_input.text_changed.connect(_on_name_changed)
	note_v.add_child(name_input)

	for tape_idx: int in range(2):
		var tape: ColorRect = ColorRect.new()
		tape.name = "Tape_%d" % tape_idx
		tape.size = TAPE_SIZE
		tape.color = Color(0.96, 0.85, 0.44, 0.78)
		tape.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tape.rotation = deg_to_rad(-12.0 if tape_idx == 0 else 10.0)
		_note_wrap.add_child(tape)
		_tapes.append(tape)

	_note_wrap.resized.connect(_layout_note)
	form_card.minimum_size_changed.connect(_layout_note)

	# 4. Karakter şeridi (yatay kaydırma)
	_strip_scroll = ScrollContainer.new()
	_strip_scroll.name = "CharStrip"
	_strip_scroll.custom_minimum_size = Vector2(0.0, STRIP_H)
	_strip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_strip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_strip_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_column.add_child(_strip_scroll)

	_strip_box = HBoxContainer.new()
	_strip_box.name = "CharRow"
	_strip_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_strip_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_strip_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_strip_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_strip_box.add_theme_constant_override("separation", GameConfig.SP_S)
	_strip_scroll.add_child(_strip_box)

	_column.add_child(_make_spacer(0.4))

	# 5. Tek baskın eylem
	solo_button = Button.new()
	solo_button.name = "SoloButton"
	solo_button.text = "HEMEN UÇ!"
	solo_button.custom_minimum_size = Vector2(0.0, PLAY_BUTTON_H)
	ComicUiHelper.style_bitten_button(solo_button, GameConfig.COLOR_GREEN_GO, AssetHelper.get_title_font(), GameConfig.FS_H1, 103)
	solo_button.pressed.connect(_on_solo_pressed)
	_column.add_child(solo_button)

	# 6. İkincil sıra
	var second_row: HBoxContainer = HBoxContainer.new()
	second_row.name = "SecondRow"
	second_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	second_row.add_theme_constant_override("separation", GameConfig.SP_S)
	_column.add_child(second_row)

	daily_button = Button.new()
	daily_button.name = "DailyButton"
	daily_button.text = "Günün Mutfağı"
	daily_button.custom_minimum_size = Vector2(0.0, SECONDARY_BUTTON_H)
	daily_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(daily_button, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_BUTTON, 102)
	daily_button.pressed.connect(_on_daily_pressed)
	second_row.add_child(daily_button)

	friends_button = Button.new()
	friends_button.name = "FriendsButton"
	friends_button.text = "Arkadaşlarla Oyna"
	friends_button.custom_minimum_size = Vector2(0.0, SECONDARY_BUTTON_H)
	friends_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ComicUiHelper.style_bitten_button(friends_button, GameConfig.COLOR_GOLD, font, GameConfig.FS_BUTTON, 104)
	friends_button.pressed.connect(_open_friends_modal)
	second_row.add_child(friends_button)

	notice_label = Label.new()
	notice_label.name = "NoticeLabel"
	notice_label.visible = false
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(notice_label, GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED, false)
	notice_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	notice_label.add_theme_constant_override("outline_size", 6)
	_column.add_child(notice_label)

	_column.add_child(_make_spacer(1.0))

	# 7. Alt gezinme çubuğu
	var nav_panel: PanelContainer = PanelContainer.new()
	nav_panel.name = "NavBar"
	ComicUiHelper.style_bitten_panel(nav_panel, GameConfig.COLOR_CREAM, 130, GameConfig.SP_XS)
	_column.add_child(nav_panel)

	var nav_row: HBoxContainer = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	nav_panel.add_child(nav_row)

	var nav_items: Array[Array] = [
		["shop", "Pazar", _open_shop],
		["quests", "Görevler", _open_quests_modal],
		["skills", "Yetenekler", _open_skills],
		["guide", "Rehber", _open_guide],
	]
	for item: Array in nav_items:
		var nb: Button = _make_icon_button(str(item[0]), str(item[1]), GameConfig.FS_SMALL, true, NAV_ICON_SIZE)
		nb.name = "Nav_%s" % str(item[0])
		nb.custom_minimum_size = Vector2(0.0, NAV_BUTTON_H)
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.size_flags_stretch_ratio = 1.0
		_style_nav_button(nb)
		nb.pressed.connect(item[2] as Callable)
		nav_row.add_child(nb)
		if str(item[0]) == "quests":
			_quest_icon = nb.get_node("Box/Icon") as Control


func _make_spacer(ratio: float) -> Control:
	var sp: Control = Control.new()
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.size_flags_stretch_ratio = ratio
	return sp


## İçinde çizilmiş ikon + etiket olan buton (dikey: alt gezinme, yatay: hap).
func _make_icon_button(icon_kind: String, text: String, font_size: int, vertical: bool, icon_size: float) -> Button:
	var btn: Button = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2 if vertical else GameConfig.SP_XS)
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	if not vertical:
		box.offset_left = 18.0
		box.offset_right = -18.0
	btn.add_child(box)

	var icon: MenuIcon = MenuIcon.new(icon_kind, icon_size, ICON_LINE_W if icon_size >= 40.0 else 3.5)
	icon.name = "Icon"
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)

	var lbl: Label = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(lbl, font_size, GameConfig.COLOR_INK, false)
	box.add_child(lbl)
	if not vertical:
		box.minimum_size_changed.connect(_fit_pill.bind(btn))
	return btn


## Yatay ikonlu butonun genişliğini içeriğine göre ayarlar.
func _fit_pill(btn: Button) -> void:
	var box: Control = btn.get_node_or_null("Box") as Control
	if box != null:
		btn.custom_minimum_size.x = box.get_combined_minimum_size().x + 36.0


func _style_nav_button(btn: Button) -> void:
	btn.flat = false
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	var empty: StyleBoxEmpty = StyleBoxEmpty.new()
	var pressed_sb: StyleBoxFlat = StyleBoxFlat.new()
	pressed_sb.bg_color = Color(GameConfig.COLOR_PEACH, 0.55)
	pressed_sb.set_corner_radius_all(16)
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("focus", empty)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("hover_pressed", pressed_sb)


func _style_line_edit(le: LineEdit) -> void:
	le.add_theme_font_override("font", AssetHelper.get_ui_font())
	le.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	le.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	le.add_theme_color_override("font_placeholder_color", Color("#9A887C"))
	le.add_theme_color_override("caret_color", GameConfig.COLOR_INK)
	le.add_theme_color_override("selection_color", Color("#F5C9A6"))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = INPUT_BG
	sb.border_color = ComicUiHelper.INK_COLOR
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = GameConfig.SP_S
	sb.content_margin_right = GameConfig.SP_S
	sb.content_margin_top = GameConfig.SP_XS
	sb.content_margin_bottom = GameConfig.SP_XS
	var focus_sb: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	focus_sb.border_color = Color("#B9773F")
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus", focus_sb)
	le.add_theme_stylebox_override("read_only", sb)


func _relayout() -> void:
	if _layout == null:
		return
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var ins: Dictionary = ComicUiHelper.safe_insets(self)
	var side_extra: float = maxf(0.0, (vis.x - CONTENT_MAX_WIDTH) * 0.5 - GameConfig.SCREEN_GUTTER)
	_layout.add_theme_constant_override("margin_left", int(float(ins["left"]) + GameConfig.SCREEN_GUTTER + side_extra))
	_layout.add_theme_constant_override("margin_right", int(float(ins["right"]) + GameConfig.SCREEN_GUTTER + side_extra))
	_layout.add_theme_constant_override("margin_top", int(float(ins["top"]) + GameConfig.SCREEN_GUTTER))
	_layout.add_theme_constant_override("margin_bottom", int(float(ins["bottom"]) + GameConfig.SCREEN_GUTTER))
	if _logo_rect != null:
		var extra_h: float = maxf(0.0, vis.y - GameConfig.VIEWPORT_HEIGHT)
		_logo_rect.custom_minimum_size.y = clampf(LOGO_MIN_H + extra_h * LOGO_GROW_RATIO, LOGO_MIN_H, LOGO_MAX_H)
	_place_actors.call_deferred()
	_scroll_to_selected.call_deferred()


func _layout_note() -> void:
	if _note_wrap == null or form_card == null:
		return
	var card_h: float = form_card.get_combined_minimum_size().y
	if not is_equal_approx(_note_wrap.custom_minimum_size.y, card_h):
		_note_wrap.custom_minimum_size.y = card_h
	form_card.position = Vector2.ZERO
	form_card.size = Vector2(_note_wrap.size.x, card_h)
	form_card.pivot_offset = form_card.size * 0.5
	if _tapes.size() == 2:
		_tapes[0].position = Vector2(-12.0, -8.0)
		_tapes[1].position = Vector2(_note_wrap.size.x - TAPE_SIZE.x + 8.0, -18.0)


## Böcek ve terliğin konumunu görünür alana göre hesaplar.
func _place_actors() -> void:
	if not is_inside_tree():
		return
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var col_rect: Rect2 = _column.get_global_rect()
	var bug_y: float = col_rect.position.y + TOP_BAR_H + BUG_TARGET_PX * 0.5 + GameConfig.SP_S
	if _logo_rect != null:
		var lr: Rect2 = _logo_rect.get_global_rect()
		# Logonun üst kenarına yakın, sağda; üstte yer varsa logonun üstüne çık
		bug_y = maxf(bug_y, lr.position.y - BUG_TARGET_PX * 0.15)
	_bug_home = Vector2(minf(col_rect.end.x - BUG_TARGET_PX * 0.45, vis.x - BUG_TARGET_PX * 0.5), bug_y)
	if not _bug_fled:
		menu_bug.position.x = _bug_home.x
	var note_rect: Rect2 = _note_wrap.get_global_rect()
	_slipper_home = Vector2(vis.x + SLIPPER_HIDE_OFFSET, note_rect.position.y + note_rect.size.y * 0.5)
	if _slipper_peek != null:
		_slipper_peek.position = _slipper_home


func _setup_menu_polish() -> void:
	for b: Button in [solo_button, daily_button, friends_button]:
		_connect_button_tween(b)

	# Canlı sahne: tıklanabilir menü böceği + gizlice uzanan terlik
	_bug_tap_btn = Button.new()
	_bug_tap_btn.name = "BugTapButton"
	_bug_tap_btn.size = Vector2(BUG_TARGET_PX, BUG_TARGET_PX)
	_bug_tap_btn.flat = true
	_bug_tap_btn.focus_mode = Control.FOCUS_NONE
	_bug_tap_btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_bug_tap_btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_bug_tap_btn.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_bug_tap_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_bug_tap_btn.pressed.connect(_on_menu_bug_tapped)
	add_child(_bug_tap_btn)

	_bug_bubble = Label.new()
	_bug_bubble.name = "BugBubble"
	_bug_bubble.visible = false
	_bug_bubble.z_index = 5
	_bug_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bug_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(_bug_bubble, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, true)
	var bubble_sb: StyleBoxFlat = StyleBoxFlat.new()
	bubble_sb.bg_color = INPUT_BG
	bubble_sb.border_color = GameConfig.COLOR_INK
	bubble_sb.set_border_width_all(3)
	bubble_sb.set_corner_radius_all(16)
	bubble_sb.content_margin_left = GameConfig.SP_S
	bubble_sb.content_margin_right = GameConfig.SP_S
	bubble_sb.content_margin_top = GameConfig.SP_XS
	bubble_sb.content_margin_bottom = GameConfig.SP_XS
	_bug_bubble.add_theme_stylebox_override("normal", bubble_sb)
	add_child(_bug_bubble)

	_slipper_peek = Sprite2D.new()
	_slipper_peek.name = "SlipperPeek"
	_slipper_peek.texture = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(140, 220))
	_slipper_peek.position = _slipper_home
	_slipper_peek.rotation = deg_to_rad(-28.0)
	_slipper_peek.scale = Vector2(0.85, 0.85)
	_slipper_peek.z_index = 4
	add_child(_slipper_peek)


# ---------------------------------------------------------------------------
# Menü böceği ve terlik şakası
# ---------------------------------------------------------------------------

func _show_bug_bubble(line_txt: String) -> void:
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	_bug_bubble.text = line_txt
	_bug_bubble.size = Vector2.ZERO
	var bsz: Vector2 = _bug_bubble.get_combined_minimum_size()
	var bx: float = clampf(menu_bug.position.x - bsz.x * 0.5, GameConfig.SCREEN_GUTTER, vis.x - bsz.x - GameConfig.SCREEN_GUTTER)
	_bug_bubble.position = Vector2(bx, _bug_home.y + BUG_TARGET_PX * 0.55)
	_bug_bubble.visible = true
	_bug_bubble.modulate.a = 1.0


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
	var vis: Vector2 = ComicUiHelper.visible_size(self)

	if _tap_count >= 10:
		_bug_fled = true
		_tap_count = 0
		AudioManager.play_character_voice(cid, "kactim")
		_show_bug_bubble(str(cdata.get("flee_line", "Tamam, ben kaçtım!")))
		var ftw: Tween = create_tween()
		ftw.tween_property(menu_bug, "position:x", vis.x + BUG_FLEE_OFFSET, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		ftw.tween_interval(2.0)
		ftw.tween_property(menu_bug, "position:x", _bug_home.x, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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

	_show_bug_bubble(line_txt)
	var tw: Tween = create_tween()
	tw.tween_property(menu_bug, "scale", menu_bug.scale * 1.26, 0.1)
	tw.tween_property(menu_bug, "scale", _bug_base_scale(), 0.18).set_trans(Tween.TRANS_BACK)
	var btw: Tween = create_tween()
	btw.tween_interval(1.1)
	btw.tween_property(_bug_bubble, "modulate:a", 0.0, 0.35)
	btw.tween_callback(func() -> void:
		if is_instance_valid(_bug_bubble):
			_bug_bubble.visible = false
	)


func _process(delta: float) -> void:
	_bug_float_time += delta
	menu_bug.position.y = _bug_home.y + sin(_bug_float_time * 3.0) * BUG_FLOAT_AMP
	if _bug_float_time < _bug_react_until:
		menu_bug.rotation = sin(_bug_float_time * 26.0) * deg_to_rad(18.0)
	else:
		menu_bug.rotation = sin(_bug_float_time * 2.2) * deg_to_rad(8.0)
	if _bug_tap_btn != null:
		_bug_tap_btn.position = menu_bug.position - Vector2(BUG_TARGET_PX, BUG_TARGET_PX) * 0.5

	_peek_timer -= delta
	if _peek_timer <= 0.0 and _slipper_peek != null:
		_peek_timer = randf_range(7.0, 11.0)
		var ptw: Tween = create_tween()
		ptw.tween_property(_slipper_peek, "position:x", _slipper_home.x - SLIPPER_HIDE_OFFSET - SLIPPER_PEEK_IN, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ptw.tween_interval(0.55)
		ptw.tween_property(_slipper_peek, "position:x", _slipper_home.x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _bug_base_scale() -> Vector2:
	if menu_bug.texture == null:
		return Vector2.ONE
	var sz: Vector2 = menu_bug.texture.get_size()
	var md: float = maxf(sz.x, sz.y)
	var sc: float = (BUG_TARGET_PX / md) if md > 0.0 else 1.0
	return Vector2(sc, sc)


func _refresh_menu_bug() -> void:
	var cdata: Dictionary = CharacterData.get_character(NetworkManager.selected_char_id)
	menu_bug.texture = AssetHelper.texture(
		str(cdata["sprite_path"]),
		str(cdata["fallback_kind"]),
		GameConfig.PLAYER_SPRITE_SIZE
	)
	menu_bug.scale = _bug_base_scale()


# ---------------------------------------------------------------------------
# Kırıntı, rozet, arka plan
# ---------------------------------------------------------------------------

func _format_thousands(n: int) -> String:
	var s: String = str(absi(n))
	var out: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" + out) if n < 0 else out


func _update_crumbs(pop: bool) -> void:
	if _crumb_label == null:
		return
	_crumb_label.text = _format_thousands(Monetization.kirinti)
	_fit_pill.call_deferred(_crumb_btn)
	if pop:
		_pop_control(_crumb_btn, 1.12)


func _on_kirinti_changed(_new_amount: int) -> void:
	_update_crumbs(true)


func _pop_control(ctrl: Control, peak: float) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tw: Tween = ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2(peak, peak), POP_SEC * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, POP_SEC * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pending_quest_count() -> int:
	var n: int = 0
	for q: Dictionary in Monetization.get_daily_quests():
		if not bool(q["claimed"]) and int(q["progress"]) >= int(q["goal"]):
			n += 1
	return n


func _refresh_quest_badge() -> void:
	if _quest_icon == null:
		return
	var n: int = _pending_quest_count()
	ComicUiHelper.set_badge_dot(_quest_icon, n > 0, n)


func _apply_bg_theme() -> void:
	var bg_theme: Dictionary = GameConfig.get_bg_theme(NetworkManager.selected_bg_id)
	bg_rect.texture = AssetHelper.texture(
		str(bg_theme["path"]),
		str(bg_theme["kind"]),
		GameConfig.BG_SIZE
	)


func _show_notice(text: String) -> void:
	notice_label.text = text
	notice_label.visible = not text.is_empty()


# ---------------------------------------------------------------------------
# Karakter şeridi
# ---------------------------------------------------------------------------

func _owned_char_ids() -> Array[String]:
	var ids: Array[String] = []
	for cid: String in CharacterData.ALL_ORDER:
		if Monetization.is_char_unlocked(cid):
			ids.append(cid)
	# Seçili karakter artık açık değilse (deneme hakkı bitti) varsayılana dön.
	if not ids.has(NetworkManager.selected_char_id):
		NetworkManager.save_selected_char("klasik")
	return ids


func _populate_character_cards() -> void:
	for child: Node in _strip_box.get_children():
		_strip_box.remove_child(child)
		child.queue_free()
	_cards.clear()

	var owned: Array[String] = _owned_char_ids()
	for cid: String in owned:
		var card: PanelContainer = CARD_SCENE.instantiate() as PanelContainer
		_strip_box.add_child(card)
		card.setup(cid)
		card.set_compact_wanted(true)
		card.card_selected.connect(_on_card_selected)
		_cards[cid] = card

	if owned.size() < CharacterData.ALL_ORDER.size():
		var more: Button = _make_icon_button("plus", "Pazar'da daha\nfazla böcek", GameConfig.FS_TINY, true, 40.0)
		more.name = "MoreBugsCard"
		more.custom_minimum_size = Vector2(150.0, 172.0)
		ComicUiHelper.style_bitten_button(more, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_TINY, 140)
		more.mouse_filter = Control.MOUSE_FILTER_PASS
		more.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
		more.pressed.connect(_open_shop)
		_strip_box.add_child(more)

	_refresh_card_selection(NetworkManager.selected_char_id)
	_scroll_to_selected.call_deferred()


func _scroll_to_selected() -> void:
	if _strip_scroll == null or not _cards.has(NetworkManager.selected_char_id) or not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if not is_instance_valid(_strip_scroll) or not _cards.has(NetworkManager.selected_char_id):
		return
	var card: Control = _cards[NetworkManager.selected_char_id] as Control
	if not is_instance_valid(card):
		return
	var target: float = card.position.x + card.size.x * 0.5 - _strip_scroll.size.x * 0.5
	_strip_scroll.scroll_horizontal = int(maxf(0.0, target))


func _on_card_selected(char_id: String) -> void:
	NetworkManager.save_selected_char(char_id)
	if not _cards.has(char_id):
		_populate_character_cards()
	else:
		_refresh_card_selection(char_id)
		_scroll_to_selected()
	_refresh_menu_bug()


func _refresh_card_selection(selected_id: String) -> void:
	for cid: String in _cards.keys():
		var card: PanelContainer = _cards[cid] as PanelContainer
		card.set_selected(cid == selected_id)


func _on_name_changed(new_text: String) -> void:
	NetworkManager.save_player_name(new_text)


# ---------------------------------------------------------------------------
# Alt gezinme hedefleri
# ---------------------------------------------------------------------------

func _open_shop() -> void:
	var sh: ShopModal = ShopModal.new()
	add_child(sh)
	sh.character_equipped.connect(_on_card_selected)
	sh.tree_exited.connect(_after_shop_closed)


func _after_shop_closed() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_populate_character_cards()
	_update_crumbs(false)
	_refresh_quest_badge()


func _open_skills() -> void:
	var sm: SkillsModal = SkillsModal.new()
	add_child(sm)
	sm.open_for(NetworkManager.selected_char_id, true)
	sm.character_chosen.connect(_on_card_selected)


func _open_guide() -> void:
	var gm: GuideModal = GuideModal.new()
	add_child(gm)


# ---------------------------------------------------------------------------
# Oyun başlatma ve çoklu oyuncu
# ---------------------------------------------------------------------------

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
		_show_notice("Oda açılamadı. Port %d başka bir şeyle meşgul olabilir." % GameConfig.NET_PORT)


func _section_label(parent: Control, text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	ComicUiHelper.style_label(lbl, GameConfig.FS_BODY, GameConfig.COLOR_BROWN, true)
	parent.add_child(lbl)
	return lbl


func _hint_label(parent: Control, text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	parent.add_child(lbl)
	return lbl


func _modal_button(text: String, color: Color, height: float = 64.0, font_size: int = GameConfig.FS_BUTTON) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, height)
	ComicUiHelper.style_bitten_button(btn, color, AssetHelper.get_ui_font(), font_size)
	return btn


func _add_close_button(m: Dictionary, text: String = "Kapat", on_close: Callable = Callable()) -> Button:
	var close_btn: Button = _modal_button(text, GameConfig.COLOR_PEACH)
	var root: Control = m["root"] as Control
	close_btn.pressed.connect(func() -> void:
		if on_close.is_valid():
			on_close.call()
		root.queue_free()
	)
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return close_btn


func _open_friends_modal() -> void:
	NetworkManager.save_player_name(name_input.text)
	var m: Dictionary = ComicUiHelper.build_modal(self, "ARKADAŞLARLA OYNA", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	var body: VBoxContainer = m["body"] as VBoxContainer

	_section_label(body, "Aynı Wi-Fi'de")
	_hint_label(body, "Herkes aynı modemdeyse en hızlısı bu. Biri oda kursun, ötekiler katılsın.")
	var lan_row: HBoxContainer = HBoxContainer.new()
	lan_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(lan_row)
	var host_btn: Button = _modal_button("Oda Kur", GameConfig.COLOR_GOLD, 72.0)
	host_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_btn.pressed.connect(func() -> void:
		root.queue_free()
		_on_host_pressed()
	)
	lan_row.add_child(host_btn)
	var join_btn: Button = _modal_button("Odaya Katıl", GameConfig.COLOR_PEACH, 72.0)
	join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_btn.pressed.connect(func() -> void:
		root.queue_free()
		_on_join_pressed()
	)
	lan_row.add_child(join_btn)

	var gap: Control = Control.new()
	gap.custom_minimum_size = Vector2(0.0, GameConfig.SP_XS)
	body.add_child(gap)

	_section_label(body, "İnternetten")
	_hint_label(body, "Uzaktaki kankayla oda koduyla buluş, ya da rastgele birine sataş.")
	var online_btn: Button = _modal_button("Çevrimiçi Oyna", GameConfig.COLOR_DUST_BLUE, 72.0)
	online_btn.pressed.connect(func() -> void:
		root.queue_free()
		_open_online_modal()
	)
	body.add_child(online_btn)

	_add_close_button(m, "Vazgeç")


func _on_join_pressed() -> void:
	NetworkManager.save_player_name(name_input.text)
	if _join_modal != null and is_instance_valid(_join_modal):
		_join_modal.queue_free()
	var m: Dictionary = ComicUiHelper.build_modal(self, "YEREL AĞ ODALARI")
	_join_modal = m["root"] as Control
	var body: VBoxContainer = m["body"] as VBoxContainer

	join_status_label = Label.new()
	join_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(join_status_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(join_status_label)

	rooms_list = VBoxContainer.new()
	rooms_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rooms_list.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(rooms_list)

	_section_label(body, "Elle bağlan")
	var manual: HBoxContainer = HBoxContainer.new()
	manual.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(manual)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP (ör. 192.168.1.42)"
	ip_input.custom_minimum_size = Vector2(0.0, 60.0)
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(ip_input)
	ip_input.text_submitted.connect(func(_t: String) -> void:
		_on_manual_connect_pressed()
	)
	manual.add_child(ip_input)
	var connect_btn: Button = _modal_button("Bağlan", GameConfig.COLOR_GREEN_GO, 60.0, GameConfig.FS_BODY)
	connect_btn.custom_minimum_size.x = 150.0
	connect_btn.pressed.connect(_on_manual_connect_pressed)
	manual.add_child(connect_btn)

	_add_close_button(m, "Kapat", _on_close_join_pressed)

	join_status_label.text = "Aynı Wi-Fi'deki odalar aranıyor..."
	_on_rooms_updated([])
	NetworkManager.get_discovery().start_listening()


func _on_close_join_pressed() -> void:
	NetworkManager.get_discovery().stop_all()
	if _join_modal != null and is_instance_valid(_join_modal):
		_join_modal.queue_free()
	_join_modal = null
	rooms_list = null
	ip_input = null
	join_status_label = null


func _on_manual_connect_pressed() -> void:
	if ip_input == null or not is_instance_valid(ip_input):
		return
	var ip: String = ip_input.text.strip_edges()
	if ip.is_empty():
		join_status_label.text = "Önce bir IP yaz bakalım."
		return
	_connect_to_ip(ip)


func _connect_to_ip(ip: String) -> void:
	if join_status_label != null and is_instance_valid(join_status_label):
		join_status_label.text = "%s adresine bağlanılıyor..." % ip
	NetworkManager.join_game(ip)


func _on_rooms_updated(rooms: Array[Dictionary]) -> void:
	if rooms_list == null or not is_instance_valid(rooms_list):
		return
	for child: Node in rooms_list.get_children():
		child.queue_free()

	if rooms.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Henüz oda yok. Arkadaşın oda kursun, ya da IP'yi elle yaz."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(empty_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, false)
		rooms_list.add_child(empty_lbl)
		return

	for room: Dictionary in rooms:
		var r_ip: String = str(room.get("ip", ""))
		var r_host: String = str(room.get("host_name", "Oda"))
		var r_count: int = int(room.get("players", 1))
		var r_match: bool = bool(room.get("in_match", false))
		var r_ver_ok: bool = bool(room.get("version_ok", true))
		var suffix: String = "  - maçta" if r_match else ""
		if not r_ver_ok:
			suffix = "  - farklı sürüm"
		var btn: Button = _modal_button("%s  (%d/5)%s" % [r_host, r_count, suffix], GameConfig.COLOR_SAGE, 64.0, GameConfig.FS_BODY)
		btn.disabled = r_match or not r_ver_ok
		btn.pressed.connect(func() -> void:
			_connect_to_ip(r_ip)
		)
		rooms_list.add_child(btn)


func _on_connection_succeeded() -> void:
	NetworkManager.get_discovery().stop_all()
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")


func _on_connection_failed(reason: String) -> void:
	if join_status_label != null and is_instance_valid(join_status_label):
		join_status_label.text = reason
	_show_notice(reason)


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
	var m: Dictionary = ComicUiHelper.build_modal(self, "ÇEVRİMİÇİ OYUN")
	var body: VBoxContainer = m["body"] as VBoxContainer

	var status_lbl: Label = Label.new()
	status_lbl.text = "Sunucu: %s" % NetworkManager.server_host
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(status_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(status_lbl)

	var quick_btn: Button = _modal_button("Hızlı Oyun", GameConfig.COLOR_GREEN_GO, 72.0)
	quick_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "quick_play", "version": GameConfig.NET_VERSION}, status_lbl)
	)
	body.add_child(quick_btn)

	var priv_btn: Button = _modal_button("Özel Oda Kur", GameConfig.COLOR_GOLD, 64.0)
	priv_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "create_private", "version": GameConfig.NET_VERSION}, status_lbl)
	)
	body.add_child(priv_btn)

	_section_label(body, "Kodla katıl")
	var code_h: HBoxContainer = HBoxContainer.new()
	code_h.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(code_h)
	var code_in: LineEdit = LineEdit.new()
	code_in.placeholder_text = "Oda kodu (ör. KTRB)"
	code_in.max_length = 4
	code_in.custom_minimum_size = Vector2(0.0, 60.0)
	code_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(code_in)
	code_h.add_child(code_in)
	var code_btn: Button = _modal_button("Katıl", GameConfig.COLOR_DUST_BLUE, 60.0, GameConfig.FS_BODY)
	code_btn.custom_minimum_size.x = 140.0
	code_btn.pressed.connect(func() -> void:
		_send_matchmaker_request({"op": "join_code", "code": code_in.text.strip_edges().to_upper(), "version": GameConfig.NET_VERSION}, status_lbl)
	)
	code_h.add_child(code_btn)

	_section_label(body, "Sunucu adresi")
	var host_h: HBoxContainer = HBoxContainer.new()
	host_h.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(host_h)
	var host_in: LineEdit = LineEdit.new()
	host_in.text = NetworkManager.server_host
	host_in.placeholder_text = "IP veya alan adı"
	host_in.custom_minimum_size = Vector2(0.0, 60.0)
	host_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(host_in)
	host_h.add_child(host_in)
	var save_btn: Button = _modal_button("Kaydet", GameConfig.COLOR_SAGE, 60.0, GameConfig.FS_BODY)
	save_btn.custom_minimum_size.x = 140.0
	var save_host: Callable = func() -> void:
		var new_h: String = host_in.text.strip_edges()
		if new_h.is_empty():
			status_lbl.text = "Adres boş kalmasın, bir şey yaz."
			return
		NetworkManager.save_server_host(new_h)
		status_lbl.text = "Kaydedildi. Sunucu: %s" % NetworkManager.server_host
	save_btn.pressed.connect(save_host)
	host_in.text_submitted.connect(func(_t: String) -> void:
		save_host.call()
	)
	host_h.add_child(save_btn)

	_add_close_button(m)


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
	if not is_instance_valid(status_lbl):
		return
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


# ---------------------------------------------------------------------------
# Ayarlar
# ---------------------------------------------------------------------------

## Başlık + kısa açıklama + sağda durum butonu. state_fn -> [metin, açık_mı]
func _add_setting_row(parent: Control, title: String, sub: String, state_fn: Callable, press_fn: Callable, btn_w: float = 150.0) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	parent.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var t: Label = Label.new()
	t.text = title
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(t, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	info.add_child(t)
	if not sub.is_empty():
		var s: Label = Label.new()
		s.text = sub
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(s, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
		info.add_child(s)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(btn_w, 56.0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	var refresh: Callable = func() -> void:
		var st: Array = state_fn.call() as Array
		btn.text = str(st[0])
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO if bool(st[1]) else Color("#E6DACB"), AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
	refresh.call()
	btn.pressed.connect(func() -> void:
		press_fn.call()
		refresh.call()
	)


func _on_off(v: bool) -> Array:
	return ["Açık" if v else "Kapalı", v]


func _open_settings_modal() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "AYARLAR", GameConfig.COLOR_CREAM, 0.0, true)
	var body: VBoxContainer = m["body"] as VBoxContainer

	_section_label(body, "Ses ve his")
	_add_setting_row(body, "Ses", "Müzik, çığlık, terlik şaklaması",
		func() -> Array: return _on_off(not AudioManager.is_muted),
		func() -> void: AudioManager.set_muted(not AudioManager.is_muted))
	_add_setting_row(body, "Titreşim", "Terlik yiyince telefon da sarsılsın",
		func() -> Array: return _on_off(AudioManager.is_vibration_enabled),
		func() -> void: AudioManager.set_vibration_enabled(not AudioManager.is_vibration_enabled))
	_add_setting_row(body, "Argo sansürü", "Açıkken ağır laflar bip'lenir",
		func() -> Array: return _on_off(AudioManager.is_censor_enabled),
		func() -> void: AudioManager.set_censor_enabled(not AudioManager.is_censor_enabled))

	_section_label(body, "Mekan")
	_build_theme_grid(body)

	_section_label(body, "Kontroller")
	_build_controls_section(body)

	_add_close_button(m, "Tamam")


func _build_theme_grid(parent: Control) -> void:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", GameConfig.SP_XS)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_XS)
	parent.add_child(grid)
	_bg_thumbs.clear()

	for theme: Dictionary in GameConfig.BG_THEMES:
		var tid: String = str(theme["id"])
		var item: Button = Button.new()
		item.name = "Theme_%s" % tid
		item.focus_mode = Control.FOCUS_NONE
		item.custom_minimum_size = Vector2(0.0, THEME_THUMB_H)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(item)

		var v: VBoxContainer = VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 6.0
		v.offset_top = 6.0
		v.offset_right = -6.0
		v.offset_bottom = -4.0
		v.add_theme_constant_override("separation", 2)
		item.add_child(v)

		var tex: TextureRect = TextureRect.new()
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.texture = AssetHelper.texture(str(theme["path"]), str(theme["kind"]), GameConfig.BG_SIZE)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(tex)

		var lbl: Label = Label.new()
		lbl.text = str(theme["name"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0.0, 48.0)
		ComicUiHelper.style_label(lbl, GameConfig.FS_TINY, GameConfig.COLOR_DARK_TEXT, false)
		v.add_child(lbl)

		item.pressed.connect(func() -> void:
			NetworkManager.save_selected_bg(tid)
			_apply_bg_theme()
			_refresh_theme_grid()
		)
		_bg_thumbs[tid] = item
	_refresh_theme_grid()


func _refresh_theme_grid() -> void:
	for tid: String in _bg_thumbs.keys():
		var item: Button = _bg_thumbs[tid] as Button
		if not is_instance_valid(item):
			continue
		var sel: bool = tid == NetworkManager.selected_bg_id
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.COLOR_GOLD if sel else INPUT_BG
		sb.border_color = GameConfig.COLOR_INK if sel else Color(GameConfig.COLOR_BROWN, 0.45)
		sb.set_border_width_all(4 if sel else 2)
		sb.set_corner_radius_all(14)
		var pressed_sb: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
		pressed_sb.bg_color = sb.bg_color.darkened(0.08)
		item.add_theme_stylebox_override("normal", sb)
		item.add_theme_stylebox_override("hover", sb)
		item.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		item.add_theme_stylebox_override("pressed", pressed_sb)
		item.add_theme_stylebox_override("hover_pressed", pressed_sb)


func _build_controls_section(parent: Control) -> void:
	var scheme_state: Callable = func() -> Array:
		return ["Kaydırma" if AudioManager.control_scheme == "swipe" else "Butonlar", true]
	var scheme_toggle: Callable = func() -> void:
		var next_s: String = "buttons" if AudioManager.control_scheme == "swipe" else "swipe"
		AudioManager.save_control_settings(next_s, AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode)
	_add_setting_row(parent, "Kontrol şekli", "Kaydırma hareketi mi, ekran butonları mı?", scheme_state, scheme_toggle, 170.0)
	_add_setting_row(parent, "Solak modu", "Butonlar sol tarafa geçer",
		func() -> Array: return _on_off(AudioManager.left_handed),
		func() -> void: AudioManager.save_control_settings(AudioManager.control_scheme, not AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode))
	_add_setting_row(parent, "Yardımcı mod", "Tek oyuncuda biraz daha affedici",
		func() -> Array: return _on_off(AudioManager.assist_mode),
		func() -> void: AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, AudioManager.button_scale, not AudioManager.assist_mode))

	var scale_lbl: Label = Label.new()
	scale_lbl.text = "Buton boyutu: %%%d" % int(roundf(AudioManager.button_scale * 100.0))
	ComicUiHelper.style_label(scale_lbl, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	parent.add_child(scale_lbl)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.8
	slider.max_value = 1.3
	slider.step = 0.05
	slider.value = AudioManager.button_scale
	slider.custom_minimum_size = Vector2(0.0, 44.0)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color("#E6DACB")
	track.border_color = GameConfig.COLOR_INK
	track.set_border_width_all(2)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0
	var fill: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	fill.bg_color = GameConfig.COLOR_GREEN_GO
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.value_changed.connect(func(val: float) -> void:
		AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, val, AudioManager.assist_mode)
		scale_lbl.text = "Buton boyutu: %%%d" % int(roundf(val * 100.0))
	)
	parent.add_child(slider)


func _open_controls_modal() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "KONTROL AYARLARI", GameConfig.COLOR_CREAM, 0.0, true)
	_build_controls_section(m["body"] as VBoxContainer)
	_add_close_button(m, "Tamam")


# ---------------------------------------------------------------------------
# Günlük görevler
# ---------------------------------------------------------------------------

func _open_quests_modal() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "GÜNLÜK GÖREVLER", GameConfig.COLOR_CREAM, 0.0, true)
	var body: VBoxContainer = m["body"] as VBoxContainer
	var hint: Label = _hint_label(body, "Her gün yenilenir. Bitir, kırıntıyı kap!")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for q: Dictionary in Monetization.get_daily_quests():
		body.add_child(_build_quest_row(q))

	_add_close_button(m)


func _build_quest_row(q: Dictionary) -> PanelContainer:
	var prog: int = int(q["progress"])
	var goal: int = int(q["goal"])
	var done: bool = prog >= goal
	var claimed: bool = bool(q["claimed"])
	var q_id: String = str(q["id"])

	var card: PanelContainer = PanelContainer.new()
	ComicUiHelper.style_bitten_panel(card, PANEL_SOFT_BG, 750, GameConfig.SP_M)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_M)
	card.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", GameConfig.SP_XS)
	row.add_child(info)

	var title: Label = Label.new()
	title.text = str(q["title"])
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(title, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	info.add_child(title)

	var bar_row: HBoxContainer = HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	info.add_child(bar_row)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = float(maxi(goal, 1))
	bar.value = float(mini(prog, goal))
	bar.custom_minimum_size = Vector2(0.0, 22.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg_sb: StyleBoxFlat = StyleBoxFlat.new()
	bg_sb.bg_color = Color("#E6DACB")
	bg_sb.border_color = GameConfig.COLOR_INK
	bg_sb.set_border_width_all(2)
	bg_sb.set_corner_radius_all(11)
	var fill_sb: StyleBoxFlat = bg_sb.duplicate() as StyleBoxFlat
	fill_sb.bg_color = GameConfig.COLOR_GREEN_GO
	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fill_sb)
	bar_row.add_child(bar)
	var count_lbl: Label = Label.new()
	count_lbl.text = "%d/%d" % [mini(prog, goal), goal]
	ComicUiHelper.style_label(count_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, true)
	bar_row.add_child(count_lbl)

	var reward_lbl: Label = Label.new()
	reward_lbl.text = "Ödül: %d Kırıntı" % int(q["reward"])
	ComicUiHelper.style_label(reward_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	info.add_child(reward_lbl)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(176.0, 64.0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	_style_quest_button(btn, done, claimed)
	btn.pressed.connect(func() -> void:
		var got: int = Monetization.claim_quest_reward(q_id)
		if got <= 0:
			return
		_style_quest_button(btn, true, true)
		reward_lbl.text = "+%d Kırıntı cebe!" % got
		reward_lbl.add_theme_color_override("font_color", Color("#2B7A3D"))
		_pop_control(btn, 1.15)
		_pop_control(reward_lbl, 1.2)
		_refresh_quest_badge()
		_update_crumbs(true)
	)
	return card


func _style_quest_button(btn: Button, done: bool, claimed: bool) -> void:
	var font: Font = AssetHelper.get_ui_font()
	if claimed:
		btn.text = "Alındı"
		btn.disabled = true
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_SAGE, font, GameConfig.FS_SMALL)
	elif done:
		btn.text = "Ödülü Al!"
		btn.disabled = false
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON)
	else:
		btn.text = "Devam ediyor"
		btn.disabled = true
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_SMALL)


## Android Geri tuşu: açık bir pencere varsa onu kapatır, yoksa oyundan çıkar.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	for i: int in range(get_child_count() - 1, -1, -1):
		var c: Node = get_child(i)
		if c is Control and (c as Control).visible and (c.name.begins_with("Modal") or c is ShopModal or c is SkillsModal or c is GuideModal):
			c.queue_free()
			return
	get_tree().quit()

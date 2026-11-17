extends PanelContainer

## Karakter seçim ve lobi gösterim kartı.

signal card_selected(char_id: String)

## Kompakt (menü şeridi) kart boyutu
const COMPACT_SIZE: Vector2 = Vector2(150.0, 172.0)
const COMPACT_ICON: Vector2 = Vector2(84.0, 84.0)
## Dokunma ile kaydırmayı ayırmak için en fazla parmak kayması (px)
const TAP_SLOP_PX: float = 18.0

var char_id: String = "klasik"
var _is_selected: bool = false
var _compact_mode: bool = false
var _stamp_layer: Control = null
var _stamp_label: Label = null
var _press_pos: Vector2 = Vector2.ZERO
var _pressing: bool = false

@onready var icon_rect: TextureRect = $HBox/IconRect
@onready var name_label: Label = $HBox/InfoBox/NameLabel
@onready var desc_label: Label = $HBox/InfoBox/DescLabel


func _ready() -> void:
	# PASS: kaydırılabilir şeritte sürükleme üst ScrollContainer'a da ulaşsın
	mouse_filter = Control.MOUSE_FILTER_PASS
	gui_input.connect(_on_gui_input)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ensure_stamp()
	_apply_style()


func _ensure_stamp() -> void:
	if _stamp_label != null:
		return
	# Damga, kap yerleşiminden etkilenmeyen ayrı bir katmanda serbest konumlanır
	_stamp_layer = Control.new()
	_stamp_layer.name = "StampLayer"
	_stamp_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_stamp_layer)

	_stamp_label = Label.new()
	_stamp_label.name = "WantedStamp"
	_stamp_label.text = "ARANIYOR"
	_stamp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_label(_stamp_label, GameConfig.FS_TINY, Color("#C93B32"), true)
	# Lastik damga görünümü: krem zemin + renkli çerçeve, her kart renginde okunur
	var stamp_sb: StyleBoxFlat = StyleBoxFlat.new()
	stamp_sb.bg_color = Color(1.0, 0.98, 0.94, 0.92)
	stamp_sb.set_border_width_all(2)
	stamp_sb.set_corner_radius_all(6)
	stamp_sb.content_margin_left = 6.0
	stamp_sb.content_margin_right = 6.0
	stamp_sb.content_margin_top = 0.0
	stamp_sb.content_margin_bottom = 0.0
	_stamp_label.add_theme_stylebox_override("normal", stamp_sb)
	_stamp_label.rotation = deg_to_rad(-10.0)
	_stamp_label.position = Vector2(-6.0, -4.0)
	_stamp_layer.add_child(_stamp_label)


func set_compact_wanted(enabled: bool) -> void:
	_compact_mode = enabled
	if _compact_mode and get_node_or_null("CompactVBox") == null:
		custom_minimum_size = COMPACT_SIZE
		var hbox: HBoxContainer = $HBox as HBoxContainer
		var compact_vbox: VBoxContainer = VBoxContainer.new()
		compact_vbox.name = "CompactVBox"
		compact_vbox.alignment = BoxContainer.ALIGNMENT_END
		compact_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		compact_vbox.add_theme_constant_override("separation", 2)
		add_child(compact_vbox)
		move_child(compact_vbox, 0)
		icon_rect.reparent(compact_vbox)
		icon_rect.custom_minimum_size = COMPACT_ICON
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon_rect.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_END
		name_label.reparent(compact_vbox)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.custom_minimum_size = Vector2(0.0, 52.0)
		hbox.visible = false
		desc_label.visible = false
	_apply_style()


## Kartı verilen karakter verisiyle doldurur.
func setup(p_char_id: String, extra_line: String = "") -> void:
	char_id = p_char_id
	var data: Dictionary = CharacterData.get_character(char_id)
	icon_rect.texture = AssetHelper.texture(
		str(data["sprite_path"]),
		str(data["fallback_kind"]),
		GameConfig.PLAYER_SPRITE_SIZE
	)
	name_label.text = str(data["display_name"])

	var desc: String = str(data["ability_name"]) + ": " + str(data["ability_text"])
	var passive: String = str(data["passive_text"])
	if not passive.is_empty():
		desc = passive + "\n" + desc
	if not extra_line.is_empty():
		desc += "\n" + extra_line
	desc_label.text = desc
	_apply_style()


## Kartın seçili görünümünü günceller.
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_style()


func _on_gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb: InputEventMouseButton = event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_pressing = true
		_press_pos = mb.global_position
		return
	# Bırakınca seç: parmak kaydıysa bu bir kaydırmadır, seçim yapma
	if _pressing and mb.global_position.distance_to(_press_pos) <= TAP_SLOP_PX:
		var idx: int = (Time.get_ticks_msec() % 3) + 1
		AudioManager.play_character_voice(char_id, "dokun_%d" % idx)
		_pop()
		card_selected.emit(char_id)
		accept_event()
	_pressing = false


func _pop() -> void:
	pivot_offset = size * 0.5
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.06, 1.06), 0.08)
	tw.tween_property(self, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK)


func _apply_style() -> void:
	if name_label == null:
		return
	ComicUiHelper.style_label(name_label, GameConfig.FS_SMALL if _compact_mode else GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	ComicUiHelper.style_label(desc_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)

	var bg: Color = Color("#C4E2BA") if _is_selected else GameConfig.COLOR_CREAM
	ComicUiHelper.style_bitten_panel(self, bg, char_id.hash() % 97 + 40, GameConfig.SP_S)
	if _stamp_label != null:
		_stamp_label.text = "SEÇİLİ!" if _is_selected else "ARANIYOR"
		var stamp_col: Color = Color("#2B7A3D") if _is_selected else Color("#C93B32")
		_stamp_label.add_theme_color_override("font_color", stamp_col)
		var sb: StyleBoxFlat = _stamp_label.get_theme_stylebox("normal") as StyleBoxFlat
		if sb != null:
			sb.border_color = stamp_col
		# Lobide (kompakt olmayan) damga yalnızca seçili oyuncuda görünür; yazıyı kapatmasın
		_stamp_label.visible = _compact_mode or _is_selected

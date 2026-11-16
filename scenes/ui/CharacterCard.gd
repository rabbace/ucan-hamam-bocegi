extends PanelContainer

## Karakter seçim ve lobi gösterim kartı.

signal card_selected(char_id: String)

var char_id: String = "klasik"
var _is_selected: bool = false
var _compact_mode: bool = false
var _stamp_label: Label = null

@onready var icon_rect: TextureRect = $HBox/IconRect
@onready var name_label: Label = $HBox/InfoBox/NameLabel
@onready var desc_label: Label = $HBox/InfoBox/DescLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_ensure_stamp()
	_apply_style()


func _ensure_stamp() -> void:
	if _stamp_label != null:
		return
	var font: Font = AssetHelper.get_ui_font()
	_stamp_label = Label.new()
	_stamp_label.name = "WantedStamp"
	_stamp_label.text = "ARANIYOR"
	_stamp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stamp_label.add_theme_font_override("font", font)
	_stamp_label.add_theme_font_size_override("font_size", 11)
	_stamp_label.add_theme_color_override("font_color", Color("#C93B32"))
	_stamp_label.add_theme_color_override("font_outline_color", Color(1.0, 0.96, 0.90, 0.9))
	_stamp_label.add_theme_constant_override("outline_size", 3)
	_stamp_label.rotation = deg_to_rad(-10.0)
	_stamp_label.position = Vector2(10.0, 6.0)
	add_child(_stamp_label)


func set_compact_wanted(enabled: bool) -> void:
	_compact_mode = enabled
	if _compact_mode:
		custom_minimum_size = Vector2(144.0, 120.0)
		var hbox: HBoxContainer = $HBox as HBoxContainer
		var compact_vbox: VBoxContainer = VBoxContainer.new()
		compact_vbox.name = "CompactVBox"
		compact_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		compact_vbox.add_theme_constant_override("separation", 4)
		add_child(compact_vbox)
		icon_rect.reparent(compact_vbox)
		icon_rect.custom_minimum_size = Vector2(58.0, 58.0)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		name_label.reparent(compact_vbox)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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


## Kartın seçili görünümünü günceller.
func set_selected(selected: bool) -> void:
	_is_selected = selected
	_apply_style()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var idx: int = (Time.get_ticks_msec() % 3) + 1
			AudioManager.play_character_voice(char_id, "dokun_%d" % idx)
			card_selected.emit(char_id)
			accept_event()


func _apply_style() -> void:
	var font: Font = AssetHelper.get_ui_font()
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 17 if _compact_mode else 22)
	name_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	desc_label.add_theme_font_override("font", font)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)

	var bg: Color = Color("#C4E2BA") if _is_selected else GameConfig.COLOR_CREAM
	ComicUiHelper.style_bitten_panel(self, bg, char_id.hash() % 97 + 40, 10 if _compact_mode else 12)
	if _stamp_label != null:
		_stamp_label.text = "SEÇİLİ!" if _is_selected else "ARANIYOR"
		_stamp_label.add_theme_color_override("font_color", Color("#2B7A3D") if _is_selected else Color("#C93B32"))

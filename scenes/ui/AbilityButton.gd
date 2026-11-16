extends Control

## Sağ alt köşede 150 px yuvarlak yetenek ve bekleme süresi butonu.

signal ability_pressed

var cooldown_remaining: float = 0.0
var cooldown_total: float = 1.0
var is_ability_active: bool = false
var default_label_text: String = "YETENEK"

@onready var title_label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(GameConfig.ABILITY_BTN_SIZE, GameConfig.ABILITY_BTN_SIZE)
	var font: Font = AssetHelper.get_ui_font()
	title_label.add_theme_font_override("font", font)
	title_label.add_theme_font_size_override("font_size", 17)
	title_label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	gui_input.connect(_on_gui_input)
	_refresh_label()


## Bekleme süresini ve toplam süreyi günceller.
func set_cooldown(remaining: float, total: float) -> void:
	cooldown_remaining = maxf(remaining, 0.0)
	cooldown_total = maxf(total, 0.01)
	_refresh_label()
	queue_redraw()


## Yeteneğin aktif olup olmadığını günceller.
func set_active(active: bool) -> void:
	is_ability_active = active
	_refresh_label()
	queue_redraw()


func _refresh_label() -> void:
	if cooldown_remaining > 0.0:
		title_label.text = "%d" % int(ceilf(cooldown_remaining))
	else:
		title_label.text = default_label_text


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			accept_event()
			if cooldown_remaining <= 0.0 and not is_ability_active:
				var tw: Tween = create_tween()
				pivot_offset = size * 0.5
				scale = Vector2(GameConfig.BUTTON_PRESS_SCALE, GameConfig.BUTTON_PRESS_SCALE)
				tw.tween_property(self, "scale", Vector2.ONE, GameConfig.BUTTON_PRESS_DURATION)
				ability_pressed.emit()
	elif event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event as InputEventScreenTouch
		if touch.pressed:
			accept_event()
			if cooldown_remaining <= 0.0 and not is_ability_active:
				ability_pressed.emit()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5 - 4.0

	var bg_col: Color = GameConfig.COLOR_SAGE
	if is_ability_active:
		bg_col = GameConfig.COLOR_DUST_PINK
	elif cooldown_remaining > 0.0:
		bg_col = GameConfig.COLOR_CREAM.darkened(0.12)

	draw_circle(center, radius, bg_col)
	draw_arc(center, radius, 0.0, TAU, 48, GameConfig.COLOR_DARK_TEXT, 3.5, true)

	if cooldown_remaining > 0.0:
		var ratio: float = clampf(cooldown_remaining / cooldown_total, 0.0, 1.0)
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + TAU * ratio
		draw_arc(center, radius - 6.0, start_angle, end_angle, 48, GameConfig.COLOR_WARN_RED, 6.0, true)

extends Node2D

## Karakter üstünde beliren yuvarlak köşeli konuşma balonu.

# Saf beyaz yerine sıcak krem balon zemini
const BUBBLE_BG: Color = Color("#FBF6EC")

var _hide_token: int = 0

@onready var panel: PanelContainer = $Panel
@onready var label: Label = $Panel/Label
@onready var tail: Control = $Tail


func _ready() -> void:
	visible = false
	var font: Font = AssetHelper.get_ui_font()
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	label.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = BUBBLE_BG
	style.border_color = GameConfig.COLOR_DARK_TEXT
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	tail.draw.connect(_on_tail_draw)


## Balonu pop animasyonuyla açar ve belirtilen süre sonunda gizler.
func show_text(text: String, duration: float) -> void:
	_hide_token += 1
	var my_token: int = _hide_token
	label.text = GameConfig.censor(text)
	panel.reset_size()
	visible = true
	scale = Vector2.ZERO

	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(duration).timeout
	if my_token != _hide_token or not is_inside_tree():
		return
	var out_tw: Tween = create_tween()
	out_tw.tween_property(self, "scale", Vector2.ZERO, 0.12)
	await out_tw.finished
	if my_token == _hide_token:
		visible = false


func _on_tail_draw() -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-10.0, 0.0),
		Vector2(10.0, 0.0),
		Vector2(0.0, 14.0),
	])
	tail.draw_colored_polygon(pts, BUBBLE_BG)
	tail.draw_polyline(PackedVector2Array([pts[0], pts[2], pts[1]]), GameConfig.COLOR_DARK_TEXT, 3.0)

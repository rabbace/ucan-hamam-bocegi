extends Control

## Alt şeritteki yuvarlak yetenek butonu: ikon + etiket + bekleme halkası.

signal ability_pressed

# İkonun çizildiği en küçük buton boyu (altında yalnızca etiket kalır)
const ICON_MIN_SIZE: float = 84.0
## Etiket sığmazsa yazı boyutu en fazla buraya kadar küçülür.
const LABEL_MIN_FS: int = 14

var cooldown_remaining: float = 0.0
var cooldown_total: float = 1.0
var is_ability_active: bool = false
var default_label_text: String = "YETENEK":
	set(v):
		default_label_text = v
		if is_node_ready():
			_refresh_label()
## Butonun ana rengi (Aktif 1 adaçayı, Aktif 2 toz mavisi).
var base_color: Color = GameConfig.COLOR_SAGE:
	set(v):
		base_color = v
		queue_redraw()
## "star" (ana yetenek) veya "shrink" (küçülme) ikonu.
var icon_kind: String = "star":
	set(v):
		icon_kind = v
		queue_redraw()

@onready var title_label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_button_size(GameConfig.ABILITY_BTN_SIZE)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.add_theme_font_override("font", AssetHelper.get_title_font())
	title_label.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	title_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	title_label.add_theme_constant_override("outline_size", 4)
	gui_input.connect(_on_gui_input)
	_refresh_label()


## Butonu kare olarak verilen boya getirir (ölçek yerine gerçek boy; yazı küçülmez).
func set_button_size(px: float) -> void:
	custom_minimum_size = Vector2(px, px)
	size = Vector2(px, px)
	pivot_offset = size * 0.5
	if is_node_ready():
		_refresh_label()
	queue_redraw()


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


func _show_icon() -> bool:
	return cooldown_remaining <= 0.0 and size.x >= ICON_MIN_SIZE


func _refresh_label() -> void:
	if cooldown_remaining > 0.0:
		title_label.text = "%d" % int(ceilf(cooldown_remaining))
		title_label.add_theme_font_size_override("font_size", GameConfig.FS_H2)
	else:
		title_label.text = default_label_text
		# Etiket dairenin içine sığsın: gerekirse yazı boyutu biraz küçülür (ekran kenarından taşmasın).
		var fs: int = GameConfig.FS_TINY
		var lbl_font: Font = title_label.get_theme_font("font")
		var max_w: float = maxf(size.x - 14.0, 40.0)
		while fs > LABEL_MIN_FS and lbl_font != null \
				and lbl_font.get_string_size(default_label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > max_w:
			fs -= 1
		title_label.add_theme_font_size_override("font_size", fs)
	# İkon varsa etiket alt yarıda, yoksa ortada
	title_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	if _show_icon():
		title_label.offset_top = size.y * 0.50
		title_label.offset_bottom = -size.y * 0.12
	else:
		title_label.offset_top = 0.0
		title_label.offset_bottom = 0.0
	title_label.offset_left = -6.0
	title_label.offset_right = 6.0


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

	var bg_col: Color = base_color
	if is_ability_active:
		bg_col = GameConfig.COLOR_DUST_PINK
	elif cooldown_remaining > 0.0:
		bg_col = GameConfig.COLOR_CREAM.darkened(0.12)

	# Alt gölge + gövde + kontur
	draw_circle(center + Vector2(0.0, 3.0), radius, Color(0.14, 0.09, 0.05, 0.35))
	draw_circle(center, radius, bg_col)
	draw_arc(center, radius - 5.0, PI * 1.1, PI * 1.6, 16, Color(1.0, 0.97, 0.9, 0.45), 3.0, true)
	draw_arc(center, radius, 0.0, TAU, 48, GameConfig.COLOR_INK, 3.5, true)
	if is_ability_active:
		draw_arc(center, radius + 1.0, 0.0, TAU, 48, GameConfig.COLOR_GOLD, 3.0, true)

	if cooldown_remaining > 0.0:
		var ratio: float = clampf(cooldown_remaining / cooldown_total, 0.0, 1.0)
		var start_angle: float = -PI * 0.5
		var end_angle: float = start_angle + TAU * ratio
		draw_arc(center, radius - 6.0, start_angle, end_angle, 48, GameConfig.COLOR_WARN_RED, 6.0, true)
		return

	if _show_icon():
		_draw_icon(Vector2(center.x, size.y * 0.33), size.x * 0.15)


func _draw_icon(c: Vector2, r: float) -> void:
	var ink: Color = GameConfig.COLOR_INK
	if icon_kind == "shrink":
		# İçe bakan iki ok (saplı) ve ortada küçük böcek noktası
		draw_line(c + Vector2(-r * 1.7, 0.0), c + Vector2(-r * 1.0, 0.0), ink, 3.5, true)
		draw_line(c + Vector2(r * 1.7, 0.0), c + Vector2(r * 1.0, 0.0), ink, 3.5, true)
		var l_tri: PackedVector2Array = PackedVector2Array([
			c + Vector2(-r * 1.1, -r * 0.55), c + Vector2(-r * 0.45, 0.0), c + Vector2(-r * 1.1, r * 0.55)])
		var r_tri: PackedVector2Array = PackedVector2Array([
			c + Vector2(r * 1.1, -r * 0.55), c + Vector2(r * 0.45, 0.0), c + Vector2(r * 1.1, r * 0.55)])
		for tri: PackedVector2Array in [l_tri, r_tri]:
			draw_colored_polygon(tri, GameConfig.COLOR_CREAM)
			draw_polyline(PackedVector2Array([tri[0], tri[1], tri[2], tri[0]]), ink, 2.5, true)
		draw_circle(c, r * 0.32, ink)
		return
	# Beş köşeli yıldız
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(10):
		var ang: float = -PI * 0.5 + float(i) * PI / 5.0
		var rr: float = r * (1.15 if i % 2 == 0 else 0.5)
		pts.append(c + Vector2(cos(ang), sin(ang)) * rr)
	draw_colored_polygon(pts, GameConfig.COLOR_GOLD)
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, ink, 2.5, true)

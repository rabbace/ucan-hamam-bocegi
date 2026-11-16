class_name ComicUiHelper
extends RefCounted

## Hızlı, önbellekli, ısırılmış ve çizgi-roman konturlu UI stil yardımcısı.

const INK_COLOR: Color = Color("#24160E")

static var _tex_normal: ImageTexture = null
static var _tex_pressed: ImageTexture = null


static func style_bitten_button(btn: Button, bg: Color, font: Font, font_size: int = 24, _seed_val: int = 1) -> void:
	btn.focus_mode = Control.FOCUS_NONE
	btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", INK_COLOR)
	btn.add_theme_color_override("font_hover_color", INK_COLOR)
	btn.add_theme_color_override("font_pressed_color", INK_COLOR)
	btn.add_theme_color_override("font_hover_pressed_color", INK_COLOR)
	btn.add_theme_color_override("font_focus_color", INK_COLOR)
	btn.add_theme_color_override("font_disabled_color", Color(0.42, 0.38, 0.35, 0.75))
	btn.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.90, 0.55))
	btn.add_theme_constant_override("outline_size", 2)

	var normal: StyleBoxTexture = make_bitten_stylebox(bg, 18, 14, false)
	var hover: StyleBoxTexture = make_bitten_stylebox(bg.lightened(0.06), 18, 14, false)
	var pressed: StyleBoxTexture = make_bitten_stylebox(bg.darkened(0.08), 18, 14, true)
	var disabled_sb: StyleBoxTexture = make_bitten_stylebox(Color(0.80, 0.77, 0.74, 0.88), 18, 14, false)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("hover_pressed", pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", disabled_sb)


static func style_bitten_panel(panel: PanelContainer, bg: Color, _seed_val: int = 17, pad: int = 24) -> void:
	var sb: StyleBoxTexture = make_bitten_stylebox(bg, 22, 18, false)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad
	sb.content_margin_bottom = pad + 4
	panel.add_theme_stylebox_override("panel", sb)


static func make_bitten_stylebox(
	bg: Color,
	margin_x: int,
	margin_y: int,
	is_pressed: bool
) -> StyleBoxTexture:
	_ensure_master_textures()
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = _tex_pressed if is_pressed else _tex_normal
	sb.modulate_color = bg
	sb.texture_margin_left = margin_x
	sb.texture_margin_right = margin_x
	sb.texture_margin_top = margin_y
	sb.texture_margin_bottom = margin_y
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12 if not is_pressed else 15
	sb.content_margin_bottom = 14 if not is_pressed else 11
	return sb


static func _ensure_master_textures() -> void:
	if _tex_normal == null:
		_tex_normal = _build_master_texture(false)
	if _tex_pressed == null:
		_tex_pressed = _build_master_texture(true)


static func _build_master_texture(is_pressed: bool) -> ImageTexture:
	var w: int = 96
	var h: int = 48
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 0.0))

	var shadow_h: int = 0 if is_pressed else 4
	var top_offset: int = 2 if is_pressed else 0
	var body_h: int = h - shadow_h - top_offset
	var radius: float = 12.0

	# Küçük köşe ısırıkları (şeffaf oyuklar)
	var bites: Array[Vector3] = [
		Vector3(float(w) - 12.0, float(top_offset) + 7.0, 7.0),
		Vector3(14.0, float(top_offset + body_h) - 6.0, 6.5),
		Vector3(float(w) * 0.78, float(top_offset + body_h) - 2.0, 5.5),
	]

	var mask: PackedByteArray = PackedByteArray()
	mask.resize(w * h)
	for y: int in range(top_offset, top_offset + body_h):
		for x: int in range(w):
			if _inside_rounded_rect(float(x), float(y - top_offset), float(w), float(body_h), radius):
				var bitten: bool = false
				for b: Vector3 in bites:
					var dx: float = float(x) - b.x
					var dy: float = float(y) - b.y
					if dx * dx + dy * dy <= b.z * b.z:
						bitten = true
						break
				if not bitten:
					mask[y * w + x] = 1

	var dark_ink: Color = Color(0.22, 0.15, 0.11, 1.0)
	var body_white: Color = Color(1.0, 1.0, 1.0, 1.0)
	var top_hi: Color = Color(1.0, 1.0, 1.0, 1.0)
	var bot_bevel: Color = Color(0.84, 0.82, 0.80, 1.0)

	# Alt gölge (tek piksel adım)
	if shadow_h > 0:
		for y: int in range(top_offset, top_offset + body_h):
			var sy: int = mini(y + shadow_h, h - 1)
			for x: int in range(w):
				if mask[y * w + x] == 1 and mask[sy * w + x] == 0:
					img.set_pixel(x, sy, dark_ink)

	# Hızlı 2 px kenar konturu + gövde
	for y: int in range(top_offset, top_offset + body_h):
		var rel_y: int = y - top_offset
		for x: int in range(w):
			if mask[y * w + x] == 0:
				continue
			var edge: bool = (
				x < 2 or x >= w - 2 or y < top_offset + 2 or y >= top_offset + body_h - 2
				or mask[y * w + (x - 2)] == 0 or mask[y * w + (x + 2)] == 0
				or mask[(y - 2) * w + x] == 0 or mask[(y + 2) * w + x] == 0
			)
			if edge:
				img.set_pixel(x, y, dark_ink)
			elif rel_y < 6:
				img.set_pixel(x, y, top_hi)
			elif rel_y > body_h - 6:
				img.set_pixel(x, y, bot_bevel)
			else:
				img.set_pixel(x, y, body_white)

	return ImageTexture.create_from_image(img)


static func _inside_rounded_rect(px: float, py: float, w: float, h: float, r: float) -> bool:
	if px < 0.0 or py < 0.0 or px >= w or py >= h:
		return false
	var cx: float = clampf(px, r, w - 1.0 - r)
	var cy: float = clampf(py, r, h - 1.0 - r)
	var dx: float = px - cx
	var dy: float = py - cy
	return dx * dx + dy * dy <= r * r

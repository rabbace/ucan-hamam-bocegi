class_name AssetHelper
extends RefCounted

## Doku, ses ve yazı tipi yükleme yardımcısı; eksik varlıklarda yedek üretir.

static var _texture_cache: Dictionary = {}
static var _font_cache: Font = null
static var _font_checked: bool = false
static var _title_font_cache: Font = null

const UI_FONT_PATH: String = "res://assets/fonts/Baloo2.ttf"
const UI_FONT_WEIGHT: int = 600
const TITLE_FONT_WEIGHT: int = 800


## Başlıklar için aynı ailenin daha kalın (ExtraBold) kesimi.
static func get_title_font() -> Font:
	if _title_font_cache != null:
		return _title_font_cache
	if ResourceLoader.exists(UI_FONT_PATH):
		var base: Resource = load(UI_FONT_PATH)
		if base is FontFile:
			var fv: FontVariation = FontVariation.new()
			fv.base_font = base as FontFile
			fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("weight"): TITLE_FONT_WEIGHT}
			_title_font_cache = fv
			return _title_font_cache
	_title_font_cache = get_ui_font()
	return _title_font_cache


## Görsel dosyayı yükler; yoksa yedek pastel dokuyu üretip önbelleğe alır.
static func texture(path: String, fallback_kind: String, size: Vector2i) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		var loaded: Resource = load(path)
		if loaded is Texture2D:
			return loaded as Texture2D

	var cache_key: String = "%s_%dx%d" % [fallback_kind, size.x, size.y]
	if _texture_cache.has(cache_key):
		return _texture_cache[cache_key] as Texture2D

	var tex: Texture2D = _build_fallback_texture(fallback_kind, size)
	_texture_cache[cache_key] = tex
	return tex


## Ses dosyasını güvenli yükler; yoksa null döner.
static func sound(path: String) -> AudioStream:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded: Resource = load(path)
	if loaded is AudioStream:
		return loaded as AudioStream
	return null


## assets/fonts altında .ttf/.otf varsa onu, yoksa varsayılan fontu döner.
static func get_ui_font() -> Font:
	if _font_checked:
		return _font_cache
	_font_checked = true
	# Birincil yol: açık dosya yolu (dışa aktarılmış APK'da .ttf yerine .import bulunur,
	# bu yüzden klasör taraması Android'de fontu kaçırır; açık yol her yerde çalışır).
	if ResourceLoader.exists(UI_FONT_PATH):
		var base: Resource = load(UI_FONT_PATH)
		if base is FontFile:
			var fv: FontVariation = FontVariation.new()
			fv.base_font = base as FontFile
			fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("weight"): UI_FONT_WEIGHT}
			_font_cache = fv
			return _font_cache
	var dir: DirAccess = DirAccess.open("res://assets/fonts")
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir():
				var lower: String = file_name.to_lower()
				if lower.ends_with(".ttf") or lower.ends_with(".otf"):
					var font_path: String = "res://assets/fonts/" + file_name
					if ResourceLoader.exists(font_path):
						var res: Resource = load(font_path)
						if res is Font:
							_font_cache = res as Font
							break
			file_name = dir.get_next()
		dir.list_dir_end()
	if _font_cache == null:
		_font_cache = ThemeDB.fallback_font
	return _font_cache


static func _build_fallback_texture(kind: String, size: Vector2i) -> Texture2D:
	var w: int = maxi(size.x, 4)
	var h: int = maxi(size.y, 4)
	var img: Image = Image.create_empty(w, h, false, Image.FORMAT_RGBA8)

	match kind:
		"bg_mutfak":
			_draw_bg_theme(img, w, h, GameConfig.COLOR_CREAM, GameConfig.COLOR_PEACH, Color(0.82, 0.72, 0.64, 0.35), 128)
		"bg_banyo":
			_draw_bg_theme(img, w, h, Color("#EBF5F0"), GameConfig.COLOR_SAGE, Color(0.55, 0.70, 0.62, 0.35), 96)
		"bg_salon":
			_draw_bg_theme(img, w, h, Color("#F4EFEA"), GameConfig.COLOR_DUST_BLUE, Color(0.62, 0.68, 0.76, 0.35), 160)
		"bg_gece":
			_draw_bg_theme(img, w, h, Color("#2E344B"), Color("#564D65"), Color(0.95, 0.90, 0.75, 0.14), 180)
		"char_klasik":
			_draw_cockroach(img, w, h, GameConfig.COLOR_BROWN, "klasik")
		"char_diva":
			_draw_cockroach(img, w, h, GameConfig.COLOR_DUST_PINK, "diva")
		"char_duktur":
			_draw_cockroach(img, w, h, Color("#EFECE6"), "duktur")
		"char_halaybasi":
			_draw_cockroach(img, w, h, Color("#E89B5A"), "halaybasi")
		"terlik_ust":
			_draw_slipper(img, w, h, true)
		"terlik_alt":
			_draw_slipper(img, w, h, false)
		"fuze":
			_draw_missile(img, w, h)
		_:
			img.fill(GameConfig.COLOR_SAGE)

	return ImageTexture.create_from_image(img)


static func _draw_bg_theme(img: Image, w: int, h: int, top_col: Color, bot_col: Color, line_col: Color, tile_h: int) -> void:
	for y: int in range(h):
		var t: float = float(y) / float(maxi(h - 1, 1))
		var row_col: Color = top_col.lerp(bot_col, t)
		if y % tile_h < 3:
			row_col = row_col.lerp(line_col, 0.55)
		for x: int in range(w):
			var col: Color = row_col
			if (x + (y / tile_h) * 90) % 180 < 2:
				col = col.lerp(line_col, 0.38)
			img.set_pixel(x, y, col)


static func _draw_cockroach(img: Image, w: int, h: int, body_col: Color, variant: String) -> void:
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var cx: float = float(w) * 0.5
	var cy: float = float(h) * 0.54
	var rx: float = float(w) * 0.36
	var ry: float = float(h) * 0.28
	var outline: Color = GameConfig.COLOR_DARK_TEXT

	# Gövde elipsi
	_fill_ellipse(img, cx, cy, rx + 3.0, ry + 3.0, outline)
	_fill_ellipse(img, cx, cy, rx, ry, body_col)

	# Küçük kanat çizgisi
	var wing_col: Color = body_col.darkened(0.14)
	_fill_ellipse(img, cx - rx * 0.15, cy - ry * 0.08, rx * 0.65, ry * 0.68, wing_col)

	# Antenler
	_draw_line(img, cx + rx * 0.65, cy - ry * 0.45, cx + rx * 1.1, cy - ry * 1.15, outline, 3)
	_draw_line(img, cx + rx * 0.72, cy - ry * 0.2, cx + rx * 1.2, cy - ry * 0.6, outline, 3)

	# Gözler veya karaktere özel detay
	var eye_x: float = cx + rx * 0.52
	var eye_y1: float = cy - ry * 0.32
	var eye_y2: float = cy + ry * 0.05
	if variant == "diva":
		_fill_rect(img, int(eye_x - 8.0), int(eye_y1 - 8.0), 18, 34, outline)
	else:
		_fill_ellipse(img, eye_x, eye_y1, 7.0, 7.0, Color.WHITE)
		_fill_ellipse(img, eye_x + 2.0, eye_y1, 3.5, 3.5, outline)
		_fill_ellipse(img, eye_x, eye_y2, 6.0, 6.0, Color.WHITE)
		_fill_ellipse(img, eye_x + 2.0, eye_y2, 3.0, 3.0, outline)

	if variant == "duktur":
		_fill_rect(img, int(cx - 4.0), int(cy - ry - 18.0), 8, 22, GameConfig.COLOR_WARN_RED)
		_fill_rect(img, int(cx - 11.0), int(cy - ry - 11.0), 22, 8, GameConfig.COLOR_WARN_RED)
	elif variant == "halaybasi":
		var mx: int = int(cx - rx * 0.85)
		var my: int = int(cy - ry * 0.6)
		_fill_rect(img, mx - 10, my - 10, 18, 18, GameConfig.COLOR_WARN_RED)


static func _draw_slipper(img: Image, w: int, h: int, is_top: bool) -> void:
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var radius: float = 24.0
	var main_col: Color = GameConfig.COLOR_DUST_BLUE
	var sole_col: Color = GameConfig.COLOR_DUST_BLUE.darkened(0.28)
	var border_col: Color = GameConfig.COLOR_DARK_TEXT
	var sole_h: int = 38
	var band_y: int = h - 90 if is_top else 56

	for y: int in range(h):
		for x: int in range(w):
			if not _inside_rounded_rect(float(x), float(y), float(w), float(h), radius):
				continue
			var edge: bool = not _inside_rounded_rect(float(x) - 3.0, float(y) - 3.0, float(w) - 6.0, float(h) - 6.0, maxf(radius - 3.0, 2.0))
			if x < 3 or x >= w - 3 or y < 3 or y >= h - 3 or edge:
				img.set_pixel(x, y, border_col)
				continue
			var in_sole: bool = (is_top and y >= h - sole_h) or ((not is_top) and y < sole_h)
			if in_sole:
				img.set_pixel(x, y, sole_col)
			elif absi(y - band_y) < 12:
				img.set_pixel(x, y, main_col.lightened(0.18))
			else:
				img.set_pixel(x, y, main_col)


static func _draw_missile(img: Image, w: int, h: int) -> void:
	img.fill(Color(0.0, 0.0, 0.0, 0.0))
	var body_col: Color = Color("#8D99AE")
	var nose_col: Color = GameConfig.COLOR_WARN_RED
	var tail_col: Color = Color("#F4A261")
	_fill_rect(img, 18, 10, w - 42, h - 20, body_col)
	_fill_rect(img, w - 26, 12, 20, h - 24, nose_col)
	_fill_rect(img, 2, 14, 18, h - 28, tail_col)


static func _inside_rounded_rect(x: float, y: float, w: float, h: float, r: float) -> bool:
	if x < 0.0 or y < 0.0 or x >= w or y >= h:
		return false
	var cx: float = clampf(x, r, w - r - 1.0)
	var cy: float = clampf(y, r, h - r - 1.0)
	return Vector2(x - cx, y - cy).length_squared() <= r * r


static func _fill_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var min_x: int = maxi(int(floorf(cx - rx)), 0)
	var max_x: int = mini(int(ceilf(cx + rx)), img.get_width() - 1)
	var min_y: int = maxi(int(floorf(cy - ry)), 0)
	var max_y: int = mini(int(ceilf(cy + ry)), img.get_height() - 1)
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			var dx: float = (float(x) - cx) / maxf(rx, 0.001)
			var dy: float = (float(y) - cy) / maxf(ry, 0.001)
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, col)


static func _fill_rect(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color) -> void:
	var min_x: int = maxi(x0, 0)
	var max_x: int = mini(x0 + rw - 1, img.get_width() - 1)
	var min_y: int = maxi(y0, 0)
	var max_y: int = mini(y0 + rh - 1, img.get_height() - 1)
	for y: int in range(min_y, max_y + 1):
		for x: int in range(min_x, max_x + 1):
			img.set_pixel(x, y, col)


static func _draw_line(img: Image, x0: float, y0: float, x1: float, y1: float, col: Color, thickness: int) -> void:
	var steps: int = maxi(int(Vector2(x0, y0).distance_to(Vector2(x1, y1))), 1)
	var half_t: int = thickness / 2
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		var px: int = int(lerpf(x0, x1, t))
		var py: int = int(lerpf(y0, y1, t))
		_fill_rect(img, px - half_t, py - half_t, thickness, thickness, col)

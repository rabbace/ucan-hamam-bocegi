class_name IconFactory
extends RefCounted

## Güçlendirme ve imza ödülü ikonları: önce res://assets/sprites/items/<id>.png
## (Noto Emoji veya kullanıcının kendi çizimi), yoksa kodla çizilmiş basit şekil.
## Hiçbir durumda harf ikon üretmez.

const ICON_DIR: String = "res://assets/sprites/items/"
const DRAW_SIZE: int = 96

static var _cache: Dictionary = {}
static var _plate_cache: Dictionary = {}


## Verilen güçlendirme kimliği için ikon dokusunu döner.
static func item_icon(item_id: String) -> Texture2D:
	if _cache.has(item_id):
		return _cache[item_id] as Texture2D
	var tex: Texture2D = null
	var path: String = ICON_DIR + item_id + ".png"
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			tex = res as Texture2D
	if tex == null:
		var def: Dictionary = GameConfig.get_item_def(item_id)
		var custom_path: String = str(def.get("icon_path", ""))
		if not custom_path.is_empty() and ResourceLoader.exists(custom_path):
			var res2: Resource = load(custom_path)
			if res2 is Texture2D:
				tex = res2 as Texture2D
	if tex == null:
		tex = _draw_icon(item_id)
	_cache[item_id] = tex
	return tex


## İkonun altına konan pastel "tabak" (kırıntı tepsisi) dokusu.
static func plate_texture(size_px: int, tint: Color = GameConfig.COLOR_CREAM) -> Texture2D:
	var key: String = "%d_%s" % [size_px, tint.to_html()]
	if _plate_cache.has(key):
		return _plate_cache[key] as Texture2D
	var s: int = maxi(size_px, 16)
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var c: float = float(s) * 0.5
	var r_out: float = float(s) * 0.5 - 1.0
	var r_rim: float = r_out - maxf(float(s) * 0.05, 2.0)
	var shadow: Color = Color(0.24, 0.21, 0.19, 0.22)
	var rim: Color = tint.darkened(0.18)
	var edge: Color = GameConfig.COLOR_DARK_TEXT
	for y: int in range(s):
		for x: int in range(s):
			var dx: float = float(x) + 0.5 - c
			var dy: float = float(y) + 0.5 - c
			var d: float = sqrt(dx * dx + dy * dy)
			var dy_shadow: float = dy - float(s) * 0.03
			var d_sh: float = sqrt(dx * dx + dy_shadow * dy_shadow)
			if d <= r_out - 1.5:
				if d >= r_rim:
					img.set_pixel(x, y, rim)
				else:
					# Hafif kâğıt dokusu: piksel konumuna bağlı çok küçük ton oynaması
					var n: float = float((x * 37 + y * 91) % 7) / 7.0 * 0.025
					img.set_pixel(x, y, tint.lightened(0.04 + n))
			elif d <= r_out:
				img.set_pixel(x, y, edge)
			elif d_sh <= r_out + 1.0:
				img.set_pixel(x, y, shadow)
	var tex: ImageTexture = ImageTexture.create_from_image(img)
	_plate_cache[key] = tex
	return tex


static func _draw_icon(item_id: String) -> Texture2D:
	var s: int = DRAW_SIZE
	var img: Image = Image.create_empty(s, s, false, Image.FORMAT_RGBA8)
	var ink: Color = GameConfig.COLOR_DARK_TEXT
	match item_id:
		"dondurma":
			_tri(img, Vector2(30, 50), Vector2(66, 50), Vector2(48, 90), Color("#E0B27A"))
			_ellipse(img, 38, 44, 15, 14, Color("#F5B7C5"))
			_ellipse(img, 58, 44, 15, 14, Color("#FFF1D6"))
			_ellipse(img, 48, 30, 15, 14, Color("#9AD0E6"))
		"turbo":
			_rect(img, 38, 26, 20, 46, Color("#E9E6E0"))
			_tri(img, Vector2(38, 26), Vector2(58, 26), Vector2(48, 8), Color("#D9605A"))
			_tri(img, Vector2(38, 60), Vector2(26, 76), Vector2(38, 72), Color("#D9605A"))
			_tri(img, Vector2(58, 60), Vector2(70, 76), Vector2(58, 72), Color("#D9605A"))
			_tri(img, Vector2(40, 72), Vector2(56, 72), Vector2(48, 92), Color("#F5B041"))
			_ellipse(img, 48, 42, 6, 6, Color("#8BB7D9"))
		"yedek_bacak":
			_line(img, 34, 14, 46, 52, Color("#7A5C4B"), 10)
			_line(img, 46, 52, 40, 82, Color("#7A5C4B"), 9)
			_line(img, 40, 82, 62, 84, Color("#7A5C4B"), 8)
		"miknatis":
			_ring(img, 48, 46, 30, 16, Color("#D9605A"), PI, TAU)
			_rect(img, 18, 46, 16, 26, Color("#D9605A"))
			_rect(img, 62, 46, 16, 26, Color("#D9605A"))
			_rect(img, 18, 72, 16, 12, Color("#D5DBDB"))
			_rect(img, 62, 72, 16, 12, Color("#D5DBDB"))
		"ozel_yetenek":
			_rect(img, 24, 10, 48, 6, Color("#7A5C4B"))
			_rect(img, 24, 80, 48, 6, Color("#7A5C4B"))
			_tri(img, Vector2(30, 16), Vector2(66, 16), Vector2(48, 48), Color("#F2C9A9"))
			_tri(img, Vector2(48, 48), Vector2(30, 80), Vector2(66, 80), Color("#E0B27A"))
		"buz_kalibi":
			_round_rect(img, 18, 18, 60, 60, 12, Color("#A9D8EE"))
			_round_rect(img, 26, 26, 16, 10, 4, Color(1, 1, 1, 0.8))
		"turk_kahvesi":
			_tri(img, Vector2(14, 34), Vector2(14, 62), Vector2(34, 48), Color("#F5B7C5"))
			_tri(img, Vector2(82, 34), Vector2(82, 62), Vector2(62, 48), Color("#F5B7C5"))
			_ellipse(img, 48, 48, 20, 20, Color("#E8B4BC"))
			_line(img, 36, 40, 60, 56, Color(1, 1, 1, 0.8), 4)
		"kirli_corap":
			_rect(img, 34, 12, 22, 50, Color("#B8CDB0"))
			_ellipse(img, 50, 70, 22, 14, Color("#B8CDB0"))
			_rect(img, 34, 12, 22, 8, Color("#9BB87A"))
			_line(img, 66, 18, 72, 30, Color("#9BB87A"), 3)
			_line(img, 74, 14, 80, 26, Color("#9BB87A"), 3)
		"komsu_teyze":
			_ellipse(img, 48, 52, 24, 26, Color("#F2C9A9"))
			_ring(img, 48, 52, 28, 10, Color("#C96F8A"), PI, TAU)
			_ellipse(img, 40, 52, 3, 3, ink)
			_ellipse(img, 56, 52, 3, 3, ink)
			_ellipse(img, 48, 66, 6, 4, Color("#B04A4A"))
		"ayna":
			_ellipse(img, 48, 44, 28, 34, Color("#A07855"))
			_ellipse(img, 48, 44, 22, 28, Color("#DDE8EE"))
			_line(img, 38, 32, 50, 22, Color(1, 1, 1, 0.9), 3)
			_rect(img, 44, 76, 8, 16, Color("#A07855"))
		"gizemli":
			_rect(img, 18, 38, 60, 44, Color("#E8B4BC"))
			_rect(img, 14, 28, 68, 14, Color("#D9879A"))
			_rect(img, 44, 28, 8, 54, Color("#F5D76E"))
			_ellipse(img, 40, 22, 9, 6, Color("#F5D76E"))
			_ellipse(img, 56, 22, 9, 6, Color("#F5D76E"))
		"bayat_ekmek":
			_ellipse(img, 48, 52, 36, 22, Color("#D9A066"))
			_line(img, 30, 44, 38, 56, Color("#A9743F"), 3)
			_line(img, 46, 42, 54, 56, Color("#A9743F"), 3)
			_line(img, 62, 44, 68, 56, Color("#A9743F"), 3)
		"ruj_tazeleme":
			_rect(img, 34, 52, 28, 34, Color("#D4AC48"))
			_rect(img, 38, 26, 20, 28, Color("#C94C5A"))
			_tri(img, Vector2(38, 26), Vector2(58, 26), Vector2(58, 12), Color("#C94C5A"))
		"asi":
			_rect(img, 24, 40, 44, 16, Color("#DDE8EE"))
			_rect(img, 30, 43, 24, 10, Color("#9AD0E6"))
			_rect(img, 68, 44, 10, 8, Color("#9AA4AA"))
			_line(img, 78, 48, 92, 48, Color("#7F8C8D"), 2)
			_rect(img, 10, 44, 14, 8, Color("#9AA4AA"))
		"davul":
			_rect(img, 22, 40, 52, 36, Color("#D9605A"))
			_ellipse(img, 48, 40, 26, 9, Color("#FFF1D6"))
			_line(img, 26, 46, 70, 74, Color("#F5D76E"), 3)
			_line(img, 70, 46, 26, 74, Color("#F5D76E"), 3)
			_line(img, 60, 12, 40, 34, Color("#7A5C4B"), 4)
		"filtre_kahve":
			_round_rect(img, 22, 34, 44, 48, 8, Color("#FFF1D6"))
			_rect(img, 26, 38, 36, 10, Color("#7A5C4B"))
			_ring(img, 68, 56, 12, 5, Color("#FFF1D6"), -PI * 0.5, PI * 0.5)
			_line(img, 34, 26, 38, 12, Color(0.6, 0.6, 0.6, 0.7), 3)
			_line(img, 48, 26, 52, 12, Color(0.6, 0.6, 0.6, 0.7), 3)
		"ingiliz_anahtari":
			_line(img, 28, 72, 62, 34, Color("#9AA4AA"), 10)
			_ring(img, 66, 28, 16, 7, Color("#9AA4AA"), -PI * 0.6, PI * 1.1)
			_ellipse(img, 26, 74, 8, 8, Color("#9AA4AA"))
		"yedek_anahtar":
			_ring(img, 30, 48, 16, 7, Color("#D4AC48"), 0.0, TAU)
			_line(img, 46, 48, 84, 48, Color("#D4AC48"), 7)
			_rect(img, 66, 48, 6, 14, Color("#D4AC48"))
			_rect(img, 76, 48, 6, 10, Color("#D4AC48"))
		"pil":
			_round_rect(img, 22, 30, 50, 36, 6, Color("#9BB87A"))
			_rect(img, 72, 40, 8, 16, Color("#7A8C6E"))
			_rect(img, 26, 34, 18, 28, Color("#B8CDB0"))
		"gece_eristesi":
			_half_ellipse(img, 48, 50, 34, 30, Color("#E8B4BC"))
			_line(img, 26, 46, 70, 40, Color("#F5D76E"), 3)
			_line(img, 30, 42, 66, 46, Color("#F5D76E"), 3)
			_line(img, 60, 16, 46, 44, Color("#7A5C4B"), 3)
			_line(img, 68, 18, 52, 44, Color("#7A5C4B"), 3)
		"demlik_cay":
			_ellipse(img, 46, 58, 26, 22, Color("#A9BCD0"))
			_rect(img, 38, 30, 16, 10, Color("#A9BCD0"))
			_line(img, 70, 54, 86, 42, Color("#A9BCD0"), 6)
			_ring(img, 20, 58, 10, 4, Color("#A9BCD0"), PI * 0.5, PI * 1.5)
		"top":
			_ellipse(img, 48, 48, 32, 32, Color("#FAFAFA"))
			_ellipse(img, 48, 48, 9, 9, ink)
			_ellipse(img, 30, 34, 5, 5, ink)
			_ellipse(img, 66, 34, 5, 5, ink)
			_ellipse(img, 36, 68, 5, 5, ink)
			_ellipse(img, 62, 68, 5, 5, ink)
		"aci_biber":
			_ellipse(img, 50, 56, 14, 30, Color("#D9605A"))
			_tri(img, Vector2(38, 76), Vector2(62, 76), Vector2(44, 92), Color("#D9605A"))
			_line(img, 50, 28, 56, 14, Color("#6E9E5A"), 5)
			_ellipse(img, 50, 30, 10, 5, Color("#6E9E5A"))
		"balon":
			_ellipse(img, 48, 38, 24, 28, Color("#D9605A"))
			_tri(img, Vector2(44, 66), Vector2(52, 66), Vector2(48, 72), Color("#D9605A"))
			_line(img, 48, 72, 44, 92, Color("#7A5C4B"), 2)
			_line(img, 38, 26, 44, 20, Color(1, 1, 1, 0.8), 3)
		_:
			# Bilinmeyen ödül: kırıntı tepsisi üstünde üç kırıntı (harf değil, şekil)
			_ellipse(img, 36, 52, 9, 7, Color("#D9A066"))
			_ellipse(img, 56, 46, 11, 8, Color("#D9A066"))
			_ellipse(img, 50, 64, 7, 6, Color("#D9A066"))
	_outline(img, ink)
	return ImageTexture.create_from_image(img)


# --- Basit çizim yardımcıları ---

static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(maxi(int(cy - ry), 0), mini(int(cy + ry) + 1, h)):
		for x: int in range(maxi(int(cx - rx), 0), mini(int(cx + rx) + 1, w)):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(x, y, col)


static func _half_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	for y: int in range(maxi(int(cy), 0), mini(int(cy + ry) + 1, h)):
		for x: int in range(maxi(int(cx - rx), 0), mini(int(cx + rx) + 1, w)):
			var nx: float = (float(x) + 0.5 - cx) / rx
			var ny: float = (float(y) + 0.5 - cy) / ry
			if nx * nx + ny * ny <= 1.0:
				img.set_pixel(x, y, col)


static func _rect(img: Image, x0: int, y0: int, rw: int, rh: int, col: Color) -> void:
	for y: int in range(maxi(y0, 0), mini(y0 + rh, img.get_height())):
		for x: int in range(maxi(x0, 0), mini(x0 + rw, img.get_width())):
			img.set_pixel(x, y, col)


static func _round_rect(img: Image, x0: int, y0: int, rw: int, rh: int, r: int, col: Color) -> void:
	for y: int in range(maxi(y0, 0), mini(y0 + rh, img.get_height())):
		for x: int in range(maxi(x0, 0), mini(x0 + rw, img.get_width())):
			var lx: float = float(x - x0)
			var ly: float = float(y - y0)
			var cx: float = clampf(lx, float(r), float(rw - r))
			var cy: float = clampf(ly, float(r), float(rh - r))
			if Vector2(lx - cx, ly - cy).length() <= float(r):
				img.set_pixel(x, y, col)


static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	var min_x: int = maxi(int(minf(a.x, minf(b.x, c.x))), 0)
	var max_x: int = mini(int(maxf(a.x, maxf(b.x, c.x))) + 1, img.get_width())
	var min_y: int = maxi(int(minf(a.y, minf(b.y, c.y))), 0)
	var max_y: int = mini(int(maxf(a.y, maxf(b.y, c.y))) + 1, img.get_height())
	for y: int in range(min_y, max_y):
		for x: int in range(min_x, max_x):
			var p: Vector2 = Vector2(float(x) + 0.5, float(y) + 0.5)
			if Geometry2D.point_is_inside_triangle(p, a, b, c):
				img.set_pixel(x, y, col)


static func _line(img: Image, x0: float, y0: float, x1: float, y1: float, col: Color, thick: int) -> void:
	var steps: int = maxi(int(Vector2(x1 - x0, y1 - y0).length()), 1)
	var r: float = float(thick) * 0.5
	for i: int in range(steps + 1):
		var t: float = float(i) / float(steps)
		_ellipse(img, lerpf(x0, x1, t), lerpf(y0, y1, t), maxf(r, 1.0), maxf(r, 1.0), col)


static func _ring(img: Image, cx: float, cy: float, radius: float, thick: float, col: Color, a0: float, a1: float) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var r_out: float = radius + thick * 0.5
	var r_in: float = radius - thick * 0.5
	for y: int in range(maxi(int(cy - r_out), 0), mini(int(cy + r_out) + 1, h)):
		for x: int in range(maxi(int(cx - r_out), 0), mini(int(cx + r_out) + 1, w)):
			var dx: float = float(x) + 0.5 - cx
			var dy: float = float(y) + 0.5 - cy
			var d: float = sqrt(dx * dx + dy * dy)
			if d < r_in or d > r_out:
				continue
			var ang: float = atan2(dy, dx)
			if ang < a0:
				ang += TAU
			if ang >= a0 and ang <= a1:
				img.set_pixel(x, y, col)


## Dolu piksellerin çevresine ince koyu kontur çizer (el çizimi etiket hissi).
static func _outline(img: Image, col: Color) -> void:
	var w: int = img.get_width()
	var h: int = img.get_height()
	var src: Image = img.duplicate() as Image
	for y: int in range(h):
		for x: int in range(w):
			if src.get_pixel(x, y).a > 0.3:
				continue
			var near: bool = false
			for oy: int in range(-2, 3):
				for ox: int in range(-2, 3):
					var nx: int = x + ox
					var ny: int = y + oy
					if nx >= 0 and ny >= 0 and nx < w and ny < h and src.get_pixel(nx, ny).a > 0.5:
						near = true
						break
				if near:
					break
			if near:
				img.set_pixel(x, y, col)

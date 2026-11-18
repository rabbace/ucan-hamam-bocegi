class_name PeopleArt
extends RefCounted

## Faz 11.5: İnsan tiplerinin yedek çizimi (görsel dosyası yoksa).
## Koordinatlar standart 120x600 engel görselinin piksel uzayındadır; çağıran draw_set_transform ile yerleştirir.
## Alt görsel (sandalyedeki kişi): kafa merkezi ~ (72, 385), gövde ~ (35..84, 404..452), sol el ~ (12, 436).
## Üst görsel (yukarıdan uzanan kol): yen x 32..88, y 0..280; bilek/ten 288..395.

const IMG_W: float = 120.0
const IMG_H: float = 600.0
const HEAD: Vector2 = Vector2(72.0, 385.0)
const HEAD_R: float = 22.0
const HAND_L: Vector2 = Vector2(12.0, 436.0)
const SLEEVE_X0: float = 32.0
const SLEEVE_X1: float = 88.0
const SLEEVE_Y1: float = 281.0
const CUFF_Y: float = 284.0
const INK: Color = Color("#24160E")
const LINE_W: float = 2.5
# Albüm portresi: görsel uzayında kafa + gövde + sandalye bölgesi
const PORTRAIT_CROP: Rect2 = Rect2(0.0, 352.0, 120.0, 150.0)
const SILHOUETTE_MOD: Color = Color(0.0, 0.0, 0.0, 0.55)

static var _tex_cache: Dictionary = {}


## Tip için gerçek görsel varsa döner (yoksa null; yedek çizim kullanılır).
static func custom_texture(type_id: String, top: bool) -> Texture2D:
	var path: String = "%s%s_%s.png" % [GameConfig.PEOPLE_DIR, type_id, "ust" if top else "alt"]
	if _tex_cache.has(path):
		return _tex_cache[path] as Texture2D
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path) as Texture2D
	_tex_cache[path] = tex
	return tex


static func _outline_poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color) -> void:
	ci.draw_colored_polygon(pts, fill)
	var loop: PackedVector2Array = pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, INK, LINE_W, true)


static func _ellipse(c: Vector2, rx: float, ry: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(n + 1):
		var a: float = lerpf(a0, a1, float(i) / float(n))
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


static func _rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## Alt kişinin aksesuarı (+ misafir kılığı). custom=true ise yalnızca misafir kılığı çizilir.
static func draw_bottom(ci: CanvasItem, type_id: String, guest: bool, custom: bool = false) -> void:
	var p: Dictionary = GameConfig.get_person(type_id)
	var shirt: Color = p["shirt"] as Color
	var accent: Color = p["accent"] as Color
	if not custom:
		match str(p["acc"]):
			"basortu":
				# Başörtüsü: kafanın üstü ve yanları, çene altında düğüm
				var cap: PackedVector2Array = _ellipse(HEAD + Vector2(0.0, -2.0), HEAD_R + 4.0, HEAD_R + 2.0, PI, TAU, 14)
				cap.append(HEAD + Vector2(HEAD_R + 4.0, 22.0))
				cap.append(HEAD + Vector2(HEAD_R - 6.0, 22.0))
				cap.append(HEAD + Vector2(HEAD_R - 8.0, -2.0))
				cap.append(HEAD + Vector2(-HEAD_R + 8.0, -2.0))
				cap.append(HEAD + Vector2(-HEAD_R + 6.0, 22.0))
				cap.append(HEAD + Vector2(-HEAD_R - 4.0, 22.0))
				_outline_poly(ci, cap, shirt)
				for d: Vector2 in [Vector2(-12.0, -14.0), Vector2(2.0, -19.0), Vector2(14.0, -12.0), Vector2(-20.0, 4.0), Vector2(20.0, 6.0)]:
					ci.draw_circle(HEAD + d, 2.6, accent)
				_outline_poly(ci, PackedVector2Array([HEAD + Vector2(-6.0, 24.0), HEAD + Vector2(6.0, 24.0), HEAD + Vector2(0.0, 33.0)]), accent)
			"bigudi":
				for i: int in range(4):
					var r: Rect2 = Rect2(HEAD + Vector2(-20.0 + float(i) * 10.5, -24.0), Vector2(8.0, 12.0))
					_outline_poly(ci, _rect_pts(r), shirt if i % 2 == 0 else accent)
			"kasket":
				_outline_poly(ci, _ellipse(HEAD + Vector2(-2.0, -14.0), HEAD_R + 2.0, 9.0, PI, TAU, 12), shirt)
				_outline_poly(ci, PackedVector2Array([HEAD + Vector2(8.0, -14.0), HEAD + Vector2(32.0, -12.0), HEAD + Vector2(30.0, -7.0), HEAD + Vector2(6.0, -9.0)]), accent)
			"sapka":
				_outline_poly(ci, _ellipse(HEAD + Vector2(0.0, -16.0), HEAD_R + 8.0, 5.0, 0.0, TAU, 16), shirt)
				_outline_poly(ci, _rect_pts(Rect2(HEAD + Vector2(-12.0, -28.0), Vector2(24.0, 12.0))), shirt)
				ci.draw_circle(HEAD + Vector2(10.0, -22.0), 4.5, accent)
			"kulaklik":
				ci.draw_arc(HEAD + Vector2(0.0, -2.0), HEAD_R + 3.0, PI * 1.05, PI * 1.95, 16, INK, 6.0, true)
				ci.draw_arc(HEAD + Vector2(0.0, -2.0), HEAD_R + 3.0, PI * 1.05, PI * 1.95, 16, accent, 3.0, true)
				_outline_poly(ci, _rect_pts(Rect2(HEAD + Vector2(-HEAD_R - 7.0, -4.0), Vector2(9.0, 16.0))), shirt)
				_outline_poly(ci, _rect_pts(Rect2(HEAD + Vector2(HEAD_R - 2.0, -4.0), Vector2(9.0, 16.0))), shirt)
			"kask":
				_outline_poly(ci, _ellipse(HEAD + Vector2(0.0, -4.0), HEAD_R + 3.0, HEAD_R - 1.0, PI, TAU, 14), accent)
				ci.draw_line(HEAD + Vector2(-HEAD_R, -12.0), HEAD + Vector2(HEAD_R, -12.0), Color.WHITE, 3.0, true)
				_outline_poly(ci, _rect_pts(Rect2(HEAD + Vector2(-HEAD_R - 3.0, -5.0), Vector2(HEAD_R * 2.0 + 6.0, 4.0))), shirt)
			"gozluk":
				ci.draw_arc(HEAD + Vector2(-6.0, 0.0), 6.5, 0.0, TAU, 14, INK, 2.5, true)
				ci.draw_arc(HEAD + Vector2(10.0, 0.0), 6.5, 0.0, TAU, 14, INK, 2.5, true)
				ci.draw_line(HEAD + Vector2(0.5, 0.0), HEAD + Vector2(3.5, 0.0), INK, 2.0)
				_outline_poly(ci, PackedVector2Array([Vector2(60.0, 410.0), Vector2(68.0, 410.0), Vector2(70.0, 440.0), Vector2(64.0, 447.0), Vector2(58.0, 440.0)]), accent)
			"onluk":
				_outline_poly(ci, PackedVector2Array([Vector2(42.0, 414.0), Vector2(80.0, 414.0), Vector2(84.0, 458.0), Vector2(38.0, 458.0)]), shirt)
				_outline_poly(ci, _rect_pts(Rect2(Vector2(52.0, 430.0), Vector2(18.0, 12.0))), accent)
				ci.draw_line(HEAD + Vector2(14.0, -12.0), HEAD + Vector2(30.0, -20.0), Color("#F2C96B"), 4.0, true)
			"maske":
				_outline_poly(ci, _ellipse(HEAD + Vector2(-2.0, -14.0), HEAD_R + 2.0, 9.0, PI, TAU, 12), shirt)
				_outline_poly(ci, PackedVector2Array([HEAD + Vector2(8.0, -14.0), HEAD + Vector2(30.0, -12.0), HEAD + Vector2(28.0, -7.0), HEAD + Vector2(6.0, -9.0)]), shirt.darkened(0.25))
				_outline_poly(ci, _rect_pts(Rect2(HEAD + Vector2(-10.0, 9.0), Vector2(26.0, 14.0))), Color("#F3F6F0"))
				ci.draw_line(HEAD + Vector2(-10.0, 12.0), HEAD + Vector2(-HEAD_R, 4.0), INK, 1.5)
				ci.draw_line(HEAD + Vector2(16.0, 12.0), HEAD + Vector2(HEAD_R, 4.0), INK, 1.5)
			"kusak":
				_outline_poly(ci, PackedVector2Array([Vector2(38.0, 410.0), Vector2(48.0, 406.0), Vector2(86.0, 450.0), Vector2(76.0, 456.0)]), accent)
				ci.draw_circle(Vector2(50.0, 424.0), 6.0, INK)
				ci.draw_circle(Vector2(50.0, 424.0), 4.6, Color("#F2C96B"))
	if guest:
		_draw_guest_bottom(ci, custom)


## Misafir kılığı: başında küçük şapka + fiyonk, elinde çay tepsisi.
static func _draw_guest_bottom(ci: CanvasItem, _custom: bool) -> void:
	var hat_c: Vector2 = HEAD + Vector2(-4.0, -24.0)
	_outline_poly(ci, _ellipse(hat_c + Vector2(0.0, 4.0), 17.0, 4.0, 0.0, TAU, 14), Color("#3D3530"))
	_outline_poly(ci, _rect_pts(Rect2(hat_c + Vector2(-10.0, -8.0), Vector2(20.0, 11.0))), Color("#3D3530"))
	_draw_bow(ci, hat_c + Vector2(0.0, -1.0), 7.0, GameConfig.COLOR_DUST_PINK)
	# Çay tepsisi (sol elde) ve iki ince belli bardak
	var tray_c: Vector2 = HAND_L + Vector2(4.0, -6.0)
	_outline_poly(ci, _ellipse(tray_c, 20.0, 4.5, 0.0, TAU, 16), Color("#E3C27A"))
	for dx: float in [-8.0, 6.0]:
		var b: Vector2 = tray_c + Vector2(dx, -3.0)
		_outline_poly(ci, PackedVector2Array([b + Vector2(-4.0, -12.0), b + Vector2(4.0, -12.0), b + Vector2(2.0, -6.0), b + Vector2(3.5, 0.0), b + Vector2(-3.5, 0.0), b + Vector2(-2.0, -6.0)]), Color("#B5482F"))


static func _draw_bow(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	_outline_poly(ci, PackedVector2Array([c, c + Vector2(-s, -s * 0.7), c + Vector2(-s, s * 0.7)]), col)
	_outline_poly(ci, PackedVector2Array([c, c + Vector2(s, -s * 0.7), c + Vector2(s, s * 0.7)]), col)
	ci.draw_circle(c, s * 0.32, INK)


## Üst kol: tipin yeni (renk/desen) ve bilek aksesuarı (+ misafir fiyonku). extend_up: yen yukarı doğru uzar.
static func draw_top(ci: CanvasItem, type_id: String, guest: bool, extend_up: float, custom: bool = false) -> void:
	var p: Dictionary = GameConfig.get_person(type_id)
	if not custom and type_id != "anne":
		var sleeve: Color = p["sleeve"] as Color
		var accent: Color = p["accent"] as Color
		var r: Rect2 = Rect2(Vector2(SLEEVE_X0, -extend_up), Vector2(SLEEVE_X1 - SLEEVE_X0, SLEEVE_Y1 + extend_up))
		ci.draw_rect(r, sleeve, true)
		match str(p["acc"]):
			"", "kasket", "onluk":
				# Çizgili gömlek / iş önlüğü kolu
				var x: float = SLEEVE_X0 + 6.0
				while x < SLEEVE_X1 - 2.0:
					ci.draw_line(Vector2(x, -extend_up), Vector2(x, SLEEVE_Y1), sleeve.darkened(0.22), 4.0)
					x += 12.0
			"bigudi", "basortu", "sapka":
				# Puantiyeli elbise kolu
				var yy: float = SLEEVE_Y1 - 14.0
				var row: int = 0
				while yy > -extend_up:
					var xx: float = SLEEVE_X0 + (10.0 if row % 2 == 0 else 20.0)
					while xx < SLEEVE_X1 - 4.0:
						ci.draw_circle(Vector2(xx, yy), 3.0, accent)
						xx += 20.0
					yy -= 22.0
					row += 1
			"kask":
				# Reflektörlü kurye montu
				ci.draw_rect(Rect2(Vector2(SLEEVE_X0, SLEEVE_Y1 - 60.0), Vector2(SLEEVE_X1 - SLEEVE_X0, 10.0)), Color("#F2E86D"), true)
			"kusak", "gozluk":
				# Takım elbise kolu + beyaz gömlek manşeti
				ci.draw_rect(Rect2(Vector2(SLEEVE_X0 + 4.0, SLEEVE_Y1 - 12.0), Vector2(SLEEVE_X1 - SLEEVE_X0 - 8.0, 10.0)), Color("#F6EFE4"), true)
			"maske":
				# Yeşil iş eldiveni (bilekten avuca)
				ci.draw_rect(Rect2(Vector2(36.0, 288.0), Vector2(48.0, 60.0)), sleeve.darkened(0.1), true)
				ci.draw_rect(Rect2(Vector2(36.0, 288.0), Vector2(48.0, 60.0)), INK, false, LINE_W)
			"kulaklik":
				ci.draw_rect(Rect2(Vector2(SLEEVE_X0, SLEEVE_Y1 - 30.0), Vector2(SLEEVE_X1 - SLEEVE_X0, 30.0)), accent, true)
		ci.draw_line(Vector2(SLEEVE_X0, -extend_up), Vector2(SLEEVE_X0, SLEEVE_Y1), INK, 3.0)
		ci.draw_line(Vector2(SLEEVE_X1, -extend_up), Vector2(SLEEVE_X1, SLEEVE_Y1), INK, 3.0)
		ci.draw_line(Vector2(SLEEVE_X0, SLEEVE_Y1), Vector2(SLEEVE_X1, SLEEVE_Y1), INK, 4.0)
		# Bilek aksesuarı
		match type_id:
			"teyze", "kayinvalide", "misafir":
				for i: int in range(3):
					ci.draw_line(Vector2(37.0, 298.0 + float(i) * 6.0), Vector2(83.0, 298.0 + float(i) * 6.0), GameConfig.COLOR_GOLD, 3.0)
			"yonetici", "bakkal", "muhtar":
				_outline_poly(ci, _rect_pts(Rect2(Vector2(37.0, 300.0), Vector2(46.0, 10.0))), INK.lightened(0.25))
				ci.draw_circle(Vector2(60.0, 305.0), 6.0, Color("#DDE6EE"))
				ci.draw_arc(Vector2(60.0, 305.0), 6.0, 0.0, TAU, 12, INK, 2.0)
	if guest:
		_draw_bow(ci, Vector2(60.0, CUFF_Y + 4.0), 12.0, GameConfig.COLOR_DUST_PINK)


## Albüm kartı için: dest içine ortalanmış (oran korunur) portre kırpımının üstüne aksesuarları çizer.
## Doku TextureRect ile ayrıca gösterilir; custom=true ise tipin kendi görseli var (aksesuar çizilmez).
static func draw_portrait_accessories(ci: CanvasItem, type_id: String, dest: Rect2, custom: bool) -> void:
	var crop: Rect2 = PORTRAIT_CROP
	var sc: float = minf(dest.size.x / crop.size.x, dest.size.y / crop.size.y)
	var origin: Vector2 = dest.position + (dest.size - crop.size * sc) * 0.5
	ci.draw_set_transform(origin - crop.position * sc, 0.0, Vector2(sc, sc))
	draw_bottom(ci, type_id, false, custom)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

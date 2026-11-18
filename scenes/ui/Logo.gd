class_name GameLogo
extends Control

## Faz 13B: oyunun tek logosu (açılış, menü ve paylaşım kartlarında aynısı).
## title_logo.png varsa onu çizer; yoksa kodla el yazısı afiş: iki satır "UÇAN / HAMAM BÖCEĞİ",
## krem dolgu, kahve kalın dış çizgi, harfler hafif farklı açılarda.
## "Ç" harfinin üstünde küçük bir böcek oturur ve antenlerini oynatır.

## true: antenler oynar ve logo hafifçe süzülür (paylaşım kartında false)
@export var animated: bool = true
@export var floating: bool = false

const LINE_1: String = "UÇAN"
const LINE_2: String = "HAMAM BÖCEĞİ"
const FILL: Color = Color("#F6EFE4")
const OUTLINE: Color = Color("#5B3A26")
const SHADOW: Color = Color(0.141, 0.086, 0.055, 0.28)
## Kod logosunda harf başına sabit açı (derece) ve dikey kayma: el yazısı afiş hissi
const TILTS: Array[float] = [-4.0, 3.0, -2.0, 5.0, -3.0, 2.0, -5.0, 4.0, -1.5, 3.5, -2.5, 1.5]
const BOBS: Array[float] = [0.0, -0.05, 0.03, -0.02, 0.04, -0.04, 0.02, 0.0, -0.03, 0.05, -0.01, 0.02]

var _tex: Texture2D = null
var _t: float = 0.0
var _float_y: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(GameConfig.LOGO_TEXTURE_PATH):
		_tex = load(GameConfig.LOGO_TEXTURE_PATH) as Texture2D
	set_process(animated or floating)


## Sahne örneği oluşturur (yoksa betikten).
static func create(p_animated: bool = true, p_floating: bool = false) -> GameLogo:
	var logo: GameLogo = null
	if ResourceLoader.exists(GameConfig.LOGO_SCENE_PATH):
		var ps: PackedScene = load(GameConfig.LOGO_SCENE_PATH) as PackedScene
		if ps != null:
			logo = ps.instantiate() as GameLogo
	if logo == null:
		logo = GameLogo.new()
	logo.animated = p_animated
	logo.floating = p_floating
	return logo


func _process(_delta: float) -> void:
	# Ortak saat: intro'dan menüye geçerken süzülme ve antenler kesintisiz devam eder
	_t = float(Time.get_ticks_msec()) / 1000.0
	_float_y = sin(_t * GameConfig.LOGO_FLOAT_SPEED) * GameConfig.LOGO_FLOAT_AMP if floating else 0.0
	queue_redraw()


## Logonun çizildiği dikdörtgen (en-boy oranı korunur, ortalanır).
func content_rect() -> Rect2:
	var aspect: float = 0.3
	if _tex != null and _tex.get_width() > 0:
		aspect = float(_tex.get_height()) / float(_tex.get_width())
	var w: float = size.x
	var h: float = w * aspect
	if h > size.y:
		h = size.y
		w = h / aspect
	return Rect2((size.x - w) * 0.5, (size.y - h) * 0.5 + _float_y, w, h)


func _draw() -> void:
	var r: Rect2 = content_rect()
	if r.size.x <= 1.0:
		return
	if _tex != null:
		draw_texture_rect(_tex, r, false)
	else:
		_draw_code_logo(r)
	var anchor: Vector2 = r.position + r.size * GameConfig.LOGO_C_ANCHOR
	_draw_bug(anchor, r.size.x * GameConfig.LOGO_BUG_SIZE_RATIO)


## Görsel yoksa: iki satır, harf harf eğik, kahve dış çizgi + gölge.
func _draw_code_logo(r: Rect2) -> void:
	var font: Font = AssetHelper.get_title_font()
	var idx: int = 0
	var rows: Array[Array] = [[LINE_1, 0.36, 0.30], [LINE_2, 0.82, 0.42]]
	for row: Array in rows:
		var text: String = str(row[0])
		var fs: int = int(r.size.y * float(row[2]))
		var total_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x: float = r.position.x + (r.size.x - total_w) * 0.5
		var base_y: float = r.position.y + r.size.y * float(row[1])
		for ch: String in text:
			var cw: float = font.get_string_size(ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			if ch != " ":
				var tilt: float = deg_to_rad(TILTS[idx % TILTS.size()])
				var bob: float = BOBS[idx % BOBS.size()] * float(fs)
				var pivot: Vector2 = Vector2(x + cw * 0.5, base_y + bob)
				draw_set_transform(pivot, tilt, Vector2.ONE)
				var o: Vector2 = Vector2(-cw * 0.5, 0.0)
				draw_string(font, o + Vector2(0.0, float(fs) * 0.07), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, SHADOW)
				draw_string_outline(font, o, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(6, fs / 7), OUTLINE)
				draw_string(font, o, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, FILL)
				idx += 1
			x += cw
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## "Ç" üstündeki küçük böcek: yan duran gövde, kanat çizgisi, bacaklar, iri göz ve oynayan antenler.
func _draw_bug(at: Vector2, s: float) -> void:
	var ink: Color = GameConfig.COLOR_INK
	var lw: float = maxf(1.5, s * 0.07)
	var breathe: float = 1.0 + (sin(_t * 3.1) * 0.04 if animated else 0.0)
	var body: Vector2 = at + Vector2(-s * 0.08, -s * 0.36)
	# Bacaklar harfin üstüne basar
	for i: int in range(3):
		var lx: float = body.x - s * 0.34 + float(i) * s * 0.3
		draw_line(Vector2(lx, body.y + s * 0.18), Vector2(lx - s * 0.08, at.y + s * 0.02), ink, lw * 0.8, true)
	# Gövde: yatık oval + kanat ayrımı
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(28):
		var a: float = TAU * float(i) / 28.0
		pts.append(body + Vector2(cos(a) * s * 0.55, sin(a) * s * 0.30 * breathe))
	draw_colored_polygon(pts, GameConfig.COLOR_BROWN)
	pts.append(pts[0])
	draw_polyline(pts, ink, lw, true)
	draw_line(body + Vector2(-s * 0.50, -s * 0.02), body + Vector2(s * 0.18, -s * 0.10), Color(1.0, 0.92, 0.8, 0.7), lw * 0.7, true)
	# Kafa (sağda) ve iri göz
	var head: Vector2 = body + Vector2(s * 0.60, -s * 0.08)
	draw_circle(head, s * 0.20, GameConfig.COLOR_BROWN.darkened(0.25))
	draw_arc(head, s * 0.20, 0.0, TAU, 18, ink, lw, true)
	draw_circle(head + Vector2(s * 0.07, -s * 0.04), s * 0.085, FILL)
	draw_circle(head + Vector2(s * 0.09, -s * 0.03), s * 0.04, ink)
	# Antenler: iki ayrı ritimde sallanır
	var a1: float = sin(_t * 5.2) * 0.28 if animated else 0.0
	var a2: float = sin(_t * 4.1 + 1.3) * 0.28 if animated else 0.0
	_antenna(head + Vector2(s * 0.04, -s * 0.16), 0.25 + a1, s, ink, lw)
	_antenna(head + Vector2(s * 0.10, -s * 0.12), 0.75 + a2, s, ink, lw)


## Anten: kafadan yukarı-ileri iki parça kavis, ucunda küçük top.
func _antenna(from: Vector2, ang: float, s: float, ink: Color, lw: float) -> void:
	var mid: Vector2 = from + Vector2.from_angle(-PI * 0.5 + ang) * s * 0.42
	var tip: Vector2 = mid + Vector2.from_angle(-PI * 0.5 + ang * 1.6 + 0.35) * s * 0.36
	draw_polyline(PackedVector2Array([from, mid, tip]), ink, lw * 0.75, true)
	draw_circle(tip, lw * 0.7, ink)

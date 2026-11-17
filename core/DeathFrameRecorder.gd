class_name DeathFrameRecorder
extends Node

## Faz 11.3: Ölüm Karesi için halka tampon. Yerel oyuncu hayattayken belirli aralıkla ekranı
## 360x640'a küçültüp YALNIZCA bellekte tutar (diske yazılmaz). Görüntü sunucusu yoksa
## (headless / test) ya da ayar kapalıysa yakalama yapılmaz; kart yedek kareyle çizilir.

var active: bool = false
var interval: float = GameConfig.DEATH_CARD_CAPTURE_SEC
## Ölüm anı ve ~0.75 sn önceki kare (yoksa null)
var death_frame: Image = null
var before_frame: Image = null
var has_death: bool = false
## Böceğin karedeki konumu (0..1); kart kareyi buna göre ortalar
var death_focus: Vector2 = Vector2(0.5, 0.5)
var before_focus: Vector2 = Vector2(0.5, 0.5)
## Böceğin ekrandaki konumunu (görünür alana oranla 0..1) veren işlev
var focus_source: Callable = Callable()

var _timer: float = 0.0
var _time: float = 0.0
var _frames: Array[Dictionary] = [] # {t: float, img: Image}
var _slow_strikes: int = 0
var _last_crop: Rect2i = Rect2i()
var _last_full: Vector2i = Vector2i.ONE


## Bu cihazda ekran yakalanabilir mi (görüntü var ve ayar açık)?
static func capture_supported() -> bool:
	return DisplayServer.get_name() != "headless" and AudioManager.death_card_enabled


## Yeni maç: tamponu temizler, ayar açıksa yakalamaya başlar.
func start() -> void:
	_frames.clear()
	death_frame = null
	before_frame = null
	has_death = false
	_time = 0.0
	_timer = 0.0
	_slow_strikes = 0
	interval = GameConfig.DEATH_CARD_CAPTURE_SEC
	active = AudioManager.death_card_enabled


## Yakalamayı durdurur ve belleği boşaltır (ölüm karesi korunur).
func stop() -> void:
	active = false
	_frames.clear()


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	if not capture_supported():
		return
	var t0: int = Time.get_ticks_usec()
	var img: Image = _grab()
	var ms: float = float(Time.get_ticks_usec() - t0) / 1000.0
	# Yakalama 1 kareden uzun sürüyorsa aralığı büyüt (FPS düşmesin)
	if ms > GameConfig.DEATH_CARD_SLOW_MS:
		_slow_strikes += 1
		if _slow_strikes >= GameConfig.DEATH_CARD_SLOW_STRIKES:
			interval = GameConfig.DEATH_CARD_CAPTURE_SLOW_SEC
	else:
		_slow_strikes = 0
	if img == null:
		return
	_frames.append({"t": _time, "img": img, "focus": _frame_focus()})
	while _frames.size() > GameConfig.DEATH_CARD_BUFFER_FRAMES:
		_frames.pop_front()


## Ölüm anı (siyah-beyaz efektten ÖNCE çağrılır): son kareyi alır, 1. kareyi seçer.
func capture_death() -> void:
	if not active:
		return
	active = false
	has_death = true
	death_frame = _grab() if capture_supported() else null
	death_focus = _frame_focus()
	before_focus = death_focus
	var want_t: float = _time - GameConfig.DEATH_CARD_BEFORE_SEC
	var best_d: float = INF
	for f: Dictionary in _frames:
		var d: float = absf(float(f["t"]) - want_t)
		if d < best_d:
			best_d = d
			before_frame = f["img"] as Image
			before_focus = f["focus"] as Vector2
	_frames.clear()


## Böceğin son yakalanan karedeki konumu (kırpma hesaba katılır).
func _frame_focus() -> Vector2:
	var r: Vector2 = Vector2(0.5, 0.5)
	if focus_source.is_valid():
		r = focus_source.call() as Vector2
	if _last_crop.size.x <= 0 or _last_crop.size.y <= 0:
		return r.clamp(Vector2.ZERO, Vector2.ONE)
	var px: Vector2 = r * Vector2(_last_full)
	var fr: Vector2 = (px - Vector2(_last_crop.position)) / Vector2(_last_crop.size)
	return fr.clamp(Vector2.ZERO, Vector2.ONE)


## Ekranın görünen kısmını 9:16 ortadan kırpıp 360x640'a küçültür.
func _grab() -> Image:
	var vp: Viewport = get_viewport()
	if vp == null:
		return null
	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return null
	var target: Vector2i = GameConfig.DEATH_CARD_FRAME_SIZE
	var want_ratio: float = float(target.x) / float(target.y)
	var w: int = img.get_width()
	var h: int = img.get_height()
	_last_full = Vector2i(w, h)
	if float(w) / float(h) > want_ratio:
		var cw: int = int(float(h) * want_ratio)
		_last_crop = Rect2i((w - cw) / 2, 0, cw, h)
	else:
		var ch: int = int(float(w) / want_ratio)
		_last_crop = Rect2i(0, (h - ch) / 2, w, ch)
	img = img.get_region(_last_crop)
	img.resize(target.x, target.y, Image.INTERPOLATE_BILINEAR)
	if img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGB8)
	return img

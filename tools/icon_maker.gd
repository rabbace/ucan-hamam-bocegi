extends Node

## Faz 13B: uygulama ikonlarını ve açılış görselini oyunun kendi çizimleriyle üretir.
## Çıktı (res://assets/icon/): icon_192.png, adaptive_fg_432.png (böcek + kanatlar, güvenli bölge
## içinde), adaptive_bg_432.png (krem zemin + fayans deseni), monochrome_432.png (tema ikonu,
## beyaz siluet), splash.png (krem zemin + logo, 1080x1920).
## Kullanım (pencereli; başsız modda çizim yapılmaz):
##   Godot --path . res://tools/IconMaker.tscn

const BUG_SPRITE: String = "res://assets/sprites/char_klasik.png"
## İkon yüzü: Saftirik Böcek'in önden portresi, baş ve el sallayan kol kırpılır (256'lık görselde)
const FACE_SPRITE: String = "res://assets/sprites/char_saftirik_front.png"
const FACE_CROP: Rect2 = Rect2(22.0, 8.0, 212.0, 212.0)
const APP_ICON_PATH: String = "res://assets/sprites/app_icon.png"
const TILE_PX: float = 72.0
const SAFE_ZONE_RATIO: float = 0.61   # 432'lik ikonda 264 px'lik güvenli dairenin içi


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("IconMaker pencereli çalıştırılmalı (başsız modda çizim yapılmaz).")
		get_tree().quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GameConfig.ICON_DIR))
	await get_tree().process_frame
	await _render("icon_192.png", Vector2i(192, 192), _build_legacy, true)
	var app_icon: Image = await _render("", Vector2i(512, 512), _build_legacy, true)
	var app_err: Error = app_icon.save_png(ProjectSettings.globalize_path(APP_ICON_PATH))
	print("ICON app_icon.png ", app_icon.get_size(), " ", "ok" if app_err == OK else "HATA %d" % app_err)
	await _render("adaptive_bg_432.png", Vector2i(432, 432), _build_bg, false)
	await _render("adaptive_fg_432.png", Vector2i(432, 432), _build_fg, true)
	var bug_only: Image = await _render("", Vector2i(432, 432), _build_bug_only, true)
	_save(_silhouette(bug_only), "monochrome_432.png")
	await _render("splash.png", Vector2i(1080, 1920), _build_splash, false)
	print("ICON_MAKER_DONE")
	get_tree().quit(0)


func _render(file_name: String, sz: Vector2i, builder: Callable, transparent: bool) -> Image:
	var vp: SubViewport = SubViewport.new()
	vp.size = sz
	vp.transparent_bg = transparent
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	builder.call(vp, Vector2(sz))
	for i: int in range(4):
		await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	if not file_name.is_empty():
		_save(img, file_name)
	return img


func _save(img: Image, file_name: String) -> void:
	var path: String = ProjectSettings.globalize_path(GameConfig.ICON_DIR + file_name)
	var err: Error = img.save_png(path)
	print("ICON ", file_name, " ", img.get_size(), " ", "ok" if err == OK else "HATA %d" % err)


func _canvas(vp: SubViewport, fn: Callable) -> Control:
	var c: Control = Control.new()
	c.size = Vector2(vp.size)
	c.draw.connect(fn.bind(c))
	vp.add_child(c)
	return c


func _bug_sprite(parent: Node, center: Vector2, px: float, rot_deg: float) -> void:
	var tex: Texture2D = AssetHelper.texture(BUG_SPRITE, "char_klasik", GameConfig.PLAYER_SPRITE_SIZE)
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	var md: float = maxf(tex.get_size().x, tex.get_size().y)
	s.scale = Vector2.ONE * (px / maxf(md, 1.0))
	s.position = center
	s.rotation = deg_to_rad(rot_deg)
	parent.add_child(s)


## Fayans deseni: krem zemin, açık derz, köşelerde soluk mavi-şeftali çiçek
func _draw_tiles(c: Control, sz: Vector2, tile: float) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, sz), GameConfig.COLOR_CREAM)
	var grout: Color = Color(GameConfig.COLOR_BROWN, 0.16)
	var y: float = 0.0
	var row: int = 0
	while y < sz.y + tile:
		var x: float = 0.0
		var col: int = 0
		while x < sz.x + tile:
			var cc: Vector2 = Vector2(x + tile * 0.5, y + tile * 0.5)
			var petal: Color = Color(GameConfig.COLOR_DUST_BLUE, 0.55) if (row + col) % 2 == 0 else Color(GameConfig.COLOR_PEACH, 0.6)
			for k: int in range(4):
				var a: float = TAU * float(k) / 4.0 + PI * 0.25
				c.draw_circle(cc + Vector2(cos(a), sin(a)) * tile * 0.17, tile * 0.11, petal)
			c.draw_circle(cc, tile * 0.07, Color(GameConfig.COLOR_GOLD, 0.8))
			x += tile
			col += 1
		y += tile
		row += 1
	var gx: float = 0.0
	while gx <= sz.x:
		c.draw_line(Vector2(gx, 0.0), Vector2(gx, sz.y), grout, 2.0)
		gx += tile
	var gy: float = 0.0
	while gy <= sz.y:
		c.draw_line(Vector2(0.0, gy), Vector2(sz.x, gy), grout, 2.0)
		gy += tile


func _build_legacy(vp: SubViewport, sz: Vector2) -> void:
	_canvas(vp, func(c: Control) -> void:
		var r: Rect2 = Rect2(Vector2(6.0, 6.0), sz - Vector2(12.0, 12.0))
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.COLOR_CREAM
		sb.border_color = GameConfig.COLOR_INK
		sb.set_border_width_all(6)
		sb.corner_radius_top_left = 44
		sb.corner_radius_top_right = 40
		sb.corner_radius_bottom_right = 46
		sb.corner_radius_bottom_left = 42
		sb.corner_detail = 10
		c.draw_style_box(sb, r)
		c.draw_circle(sz * 0.5 + Vector2(0.0, sz.x * 0.02), sz.x * 0.36, Color(GameConfig.COLOR_PEACH, 0.75))
	)
	# Yüz, kartın iç kenarına kadar; dışarı taşan kısım kırpılır
	var k: float = sz.x / 192.0
	_face_clipped(vp, Rect2(Vector2(12.0, 12.0) * k, sz - Vector2(24.0, 24.0) * k), 38.0 * k, sz.x * 0.86, Vector2(0.0, sz.y * 0.06))


func _build_bg(vp: SubViewport, sz: Vector2) -> void:
	_canvas(vp, func(c: Control) -> void:
		_draw_tiles(c, sz, TILE_PX)
	)


func _build_fg(vp: SubViewport, sz: Vector2) -> void:
	_canvas(vp, func(c: Control) -> void:
		# Böceğin arkasında yumuşak şeftali daire (güvenli bölgenin içinde)
		c.draw_circle(sz * 0.5, sz.x * SAFE_ZONE_RATIO * 0.5, Color(GameConfig.COLOR_PEACH, 0.85))
	)
	var d: float = sz.x * SAFE_ZONE_RATIO
	_face_clipped(vp, Rect2(sz * 0.5 - Vector2(d, d) * 0.5, Vector2(d, d)), d * 0.5, d * 1.02, Vector2(0.0, d * 0.06))
	_canvas(vp, func(c: Control) -> void:
		c.draw_arc(sz * 0.5, sz.x * SAFE_ZONE_RATIO * 0.5, 0.0, TAU, 64, GameConfig.COLOR_INK, 6.0, true)
	)


func _build_bug_only(vp: SubViewport, sz: Vector2) -> void:
	var d: float = sz.x * SAFE_ZONE_RATIO
	_face_clipped(vp, Rect2(sz * 0.5 - Vector2(d, d) * 0.5, Vector2(d, d)), d * 0.5, d * 1.02, Vector2(0.0, d * 0.06))


## Saftirik'in yüzünü verilen yuvarlatılmış alana (radius = yarı boy ise daire) kırparak çizer.
## face_px: kırpılmış portrenin kenar uzunluğu; offset: alanın merkezine göre kaydırma.
func _face_clipped(vp: SubViewport, area: Rect2, radius: float, face_px: float, offset: Vector2) -> void:
	var mask: Control = Control.new()
	mask.position = area.position
	mask.size = area.size
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.draw.connect(func() -> void:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = Color.WHITE
		sb.set_corner_radius_all(int(radius))
		sb.corner_detail = 24
		sb.anti_aliasing = true
		mask.draw_style_box(sb, Rect2(Vector2.ZERO, area.size))
	)
	vp.add_child(mask)
	var tex: Texture2D = load(FACE_SPRITE) as Texture2D
	if tex == null:
		_bug_sprite(mask, area.size * 0.5, face_px * 0.8, -18.0)
		return
	var at: AtlasTexture = AtlasTexture.new()
	at.atlas = tex
	at.region = FACE_CROP
	var s: Sprite2D = Sprite2D.new()
	s.texture = at
	s.scale = Vector2.ONE * (face_px / FACE_CROP.size.x)
	s.position = area.size * 0.5 + offset
	mask.add_child(s)


func _build_splash(vp: SubViewport, sz: Vector2) -> void:
	_canvas(vp, func(c: Control) -> void:
		c.draw_rect(Rect2(Vector2.ZERO, sz), GameConfig.COLOR_CREAM)
	)
	var logo: GameLogo = GameLogo.create(false, false)
	var w: float = sz.x * 0.7
	logo.size = Vector2(w, w * GameConfig.MENU_LOGO_ASPECT)
	logo.position = (sz - logo.size) * 0.5
	vp.add_child(logo)


## Tema (monokrom) ikonu: opak pikseller beyaz, kontur (koyu çizgi) saydam kalır ki yüz okunsun
func _silhouette(src: Image) -> Image:
	var img: Image = src.duplicate() as Image
	img.convert(Image.FORMAT_RGBA8)
	for y: int in range(img.get_height()):
		for x: int in range(img.get_width()):
			var px: Color = img.get_pixel(x, y)
			var ink: float = clampf((0.32 - px.get_luminance()) / 0.12, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, px.a * (1.0 - ink)))
	return img

class_name DeathComicCard
extends Node

## Faz 11.3: 1080x1350 üç kareli çizgi roman (önce / an / sinirli yüz) üreten SubViewport kurucusu.
## Görüntü yoksa (headless) kareler kodla çizilmiş yedek sahneyle kurulur ve PNG üretilmez.
## data: before (Image|null), death (Image|null), cause, char_id, line, score, narration, bg_id

const PORTRAIT_SCENE: PackedScene = preload("res://scenes/ui/CharacterPortrait.tscn")
const NARRATION_BG: Color = Color("#FBE38E")
const BURST_FILL: Color = Color("#F6D04D")
const BURST_EDGE: Color = Color("#D9605A")
const PANEL3_BG: Color = Color("#F7DCD6")
const DOT_COLOR: Color = Color(0.93, 0.72, 0.66, 0.35)
const DOT_STEP: int = 34
const SFX_FONT_SIZE: int = 132
const NARRATION_FONT_SIZE: int = 36
const BUBBLE_FONT_SIZE: int = 40
const STRIP_FONT_SIZE: int = 44
const LINK_FONT_SIZE: int = 30
const PORTRAIT_SIDE: float = 330.0
## Ses efekti yazısının dikey konumu (2. kare yüksekliğine oran)
const SFX_HIGH_Y: float = 0.36
const SFX_LOW_Y: float = 0.68

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## Kartı çizer, user://olum_karesi.png olarak kaydeder ve resmi döner. Görüntü yoksa null.
func render(data: Dictionary) -> Image:
	_rng.seed = 7700 + int(data.get("score", 0))
	var size_i: Vector2i = GameConfig.DEATH_CARD_SIZE
	var vp: SubViewport = SubViewport.new()
	vp.name = "DeathCardViewport"
	vp.size = size_i
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	build_into(vp, data)
	await get_tree().process_frame
	if not is_instance_valid(vp):
		return null
	if DisplayServer.get_name() == "headless":
		vp.queue_free()
		return null
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	if not is_instance_valid(vp):
		return null
	var img: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	vp.queue_free()
	if img == null or img.is_empty():
		return null
	img.save_png(GameConfig.DEATH_CARD_PATH)
	return img


## Kart düğüm ağacını verilen kökün altına kurar (test için ayrı çağrılabilir).
func build_into(root: Node, data: Dictionary) -> void:
	var W: float = float(GameConfig.DEATH_CARD_SIZE.x)
	var H: float = float(GameConfig.DEATH_CARD_SIZE.y)
	var M: float = GameConfig.DEATH_CARD_MARGIN
	var G: float = GameConfig.DEATH_CARD_GAP
	var half_w: float = (W - M * 2.0 - G) * 0.5
	var top_h: float = GameConfig.DEATH_CARD_TOP_H
	var r1: Rect2 = Rect2(M, M, half_w, top_h)
	var r2: Rect2 = Rect2(M + half_w + G, M, half_w, top_h)
	var r3: Rect2 = Rect2(M, M + top_h + G, W - M * 2.0, GameConfig.DEATH_CARD_BOTTOM_H)
	var strip: Rect2 = Rect2(M, r3.end.y + G * 0.5, W - M * 2.0, H - r3.end.y - G * 0.5)

	# Zemin: krem + soluk pastel nokta deseni (halftone)
	var bg: ColorRect = ColorRect.new()
	bg.color = Color.WHITE
	bg.size = Vector2(W, H)
	root.add_child(bg)
	var dots: Control = Control.new()
	dots.size = Vector2(W, H)
	dots.draw.connect(func() -> void:
		for yy: int in range(0, int(H), DOT_STEP):
			for xx: int in range(0, int(W), DOT_STEP):
				var off: float = float(DOT_STEP) * 0.5 if (yy / DOT_STEP) % 2 == 1 else 0.0
				dots.draw_circle(Vector2(float(xx) + off, float(yy)), 4.0, DOT_COLOR)
	)
	root.add_child(dots)

	var cid: String = str(data.get("char_id", "klasik"))
	var before_img: Image = data.get("before") as Image
	var death_img: Image = data.get("death") as Image

	# 1. kare: ölümden hemen önce + sarı anlatı kutusu
	var c1: Control = _make_panel(root, r1)
	_fill_frame(c1, before_img, cid, false, str(data.get("bg_id", "")), data.get("before_focus", Vector2(0.5, 0.5)) as Vector2)
	_add_narration(c1, str(data.get("narration", GameConfig.DEATH_CARD_NARRATION_SHORT)), r1.size)
	_add_border(root, r1)

	# 2. kare: ölüm anı, yakınlaştırılmış ve eğik + büyük ses efekti yazısı
	var c2: Control = _make_panel(root, r2)
	var death_focus: Vector2 = data.get("death_focus", Vector2(0.5, 0.5)) as Vector2
	var zoom_box: Control = Control.new()
	zoom_box.size = r2.size
	# Yakınlaştırma böceğin üzerinde (dikeyde) merkezlensin
	zoom_box.pivot_offset = Vector2(r2.size.x * 0.5, r2.size.y * clampf(death_focus.y, 0.15, 0.85))
	zoom_box.scale = Vector2.ONE * GameConfig.DEATH_CARD_ZOOM
	zoom_box.rotation = deg_to_rad(GameConfig.DEATH_CARD_TILT_DEG)
	c2.add_child(zoom_box)
	_fill_frame(zoom_box, death_img, cid, true, str(data.get("bg_id", "")), death_focus)
	# Yazı böceğin üstünü kapatmasın: tavanda ölünce alta, diğerlerinde üste
	var sfx_y: float = SFX_LOW_Y if death_focus.y < 0.5 else SFX_HIGH_Y
	_add_sfx(c2, GameConfig.death_card_sfx(str(data.get("cause", ""))), r2.size, sfx_y)
	_add_border(root, r2)

	# 3. kare: sinirli büyük yüz + sinir repliği balonu
	var c3: Control = _make_panel(root, r3)
	var p3_bg: ColorRect = ColorRect.new()
	p3_bg.color = PANEL3_BG
	p3_bg.size = r3.size
	c3.add_child(p3_bg)
	var p3_dots: Control = Control.new()
	p3_dots.size = r3.size
	p3_dots.draw.connect(func() -> void:
		for yy: int in range(0, int(r3.size.y), 22):
			for xx: int in range(0, int(r3.size.x), 22):
				p3_dots.draw_circle(Vector2(float(xx), float(yy)), 3.0, Color(0.85, 0.45, 0.42, 0.18))
	)
	c3.add_child(p3_dots)
	var portrait: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	portrait.interactive = false
	portrait.size = Vector2(PORTRAIT_SIDE, PORTRAIT_SIDE)
	portrait.position = Vector2(24.0, (r3.size.y - PORTRAIT_SIDE) * 0.5)
	c3.add_child(portrait)
	portrait.setup(cid, CharacterPortrait.EXPR_ANGRY)
	_add_speech_bubble(c3, GameConfig.censor(str(data.get("line", "Ayy terlik!"))), r3.size)
	_add_border(root, r3)

	# Alt şerit: logo, skor, bağlantı
	_add_strip(root, strip, int(data.get("score", 0)))


## Kırpan kare kutusu (beyaz zemin).
func _make_panel(root: Node, r: Rect2) -> Control:
	var c: Control = Control.new()
	c.position = r.position
	c.size = r.size
	c.clip_contents = true
	root.add_child(c)
	var white: ColorRect = ColorRect.new()
	white.color = GameConfig.COLOR_CREAM
	white.size = r.size
	c.add_child(white)
	return c


## Yakalanan kareyi doldurur; yoksa mekan + böcek yedek sahnesi çizer.
func _fill_frame(parent: Control, img: Image, cid: String, is_death: bool, bg_id: String, focus: Vector2) -> void:
	var sz: Vector2 = parent.size
	if img != null and not img.is_empty():
		# Kareyi kaplayacak kadar büyüt; taşan kısmı böcek ortada kalacak şekilde kırp
		var isz: Vector2 = Vector2(img.get_size())
		var k: float = maxf(sz.x / isz.x, sz.y / isz.y)
		var dsz: Vector2 = isz * k
		var off: Vector2 = sz * 0.5 - focus * dsz
		off.x = clampf(off.x, sz.x - dsz.x, 0.0)
		off.y = clampf(off.y, sz.y - dsz.y, 0.0)
		var tr: TextureRect = TextureRect.new()
		tr.texture = ImageTexture.create_from_image(img)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.position = off
		tr.size = dsz
		parent.add_child(tr)
		return
	var theme: Dictionary = GameConfig.get_bg_theme(bg_id if not bg_id.is_empty() else NetworkManager.selected_bg_id)
	var bg_tr: TextureRect = TextureRect.new()
	bg_tr.texture = AssetHelper.texture(str(theme["path"]), str(theme["kind"]), GameConfig.BG_SIZE)
	bg_tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg_tr.size = sz
	bg_tr.modulate = Color(0.85, 0.85, 0.85)
	parent.add_child(bg_tr)
	var cdata: Dictionary = CharacterData.get_character(cid)
	var bug: TextureRect = TextureRect.new()
	bug.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	bug.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bug.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side: float = sz.x * 0.55
	bug.size = Vector2(side, side)
	bug.pivot_offset = bug.size * 0.5
	bug.position = Vector2((sz.x - side) * 0.5, sz.y * (0.5 if is_death else 0.42) - side * 0.5)
	if is_death:
		bug.rotation = deg_to_rad(150.0)
		bug.modulate = GameConfig.COLOR_DEAD_GRAY
	parent.add_child(bug)


func _add_narration(parent: Control, text: String, sz: Vector2) -> void:
	var box: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = NARRATION_BG
	sb.border_color = GameConfig.COLOR_INK
	sb.set_border_width_all(4)
	sb.set_content_margin_all(14)
	box.add_theme_stylebox_override("panel", sb)
	box.position = Vector2(14.0, 14.0)
	box.custom_minimum_size = Vector2(sz.x * 0.78, 0.0)
	box.rotation = deg_to_rad(-1.2)
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(sz.x * 0.78 - 28.0, 0.0)
	lbl.add_theme_font_override("font", AssetHelper.get_title_font())
	lbl.add_theme_font_size_override("font_size", NARRATION_FONT_SIZE)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	box.add_child(lbl)
	parent.add_child(box)


## Patlama yıldızı + kalın konturlu ses efekti yazısı.
func _add_sfx(parent: Control, text: String, sz: Vector2, y_ratio: float) -> void:
	var center: Vector2 = Vector2(sz.x * 0.5, sz.y * y_ratio)
	var burst: Control = Control.new()
	burst.size = sz
	var pts: PackedVector2Array = PackedVector2Array()
	var spikes: int = 14
	for i: int in range(spikes * 2):
		var a: float = TAU * float(i) / float(spikes * 2)
		var rad: float = (sz.x * 0.46 if i % 2 == 0 else sz.x * 0.30) + _rng.randf_range(-14.0, 14.0)
		pts.append(center + Vector2(cos(a), sin(a) * 0.8) * rad)
	burst.draw.connect(func() -> void:
		burst.draw_colored_polygon(pts, BURST_FILL)
		var closed: PackedVector2Array = pts.duplicate()
		closed.append(pts[0])
		burst.draw_polyline(closed, BURST_EDGE, 7.0, true)
	)
	parent.add_child(burst)
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var fsize: int = SFX_FONT_SIZE if text.length() <= 6 else int(float(SFX_FONT_SIZE) * 0.72)
	lbl.add_theme_font_override("font", AssetHelper.get_title_font())
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_WARN_RED)
	lbl.add_theme_color_override("font_outline_color", GameConfig.COLOR_INK)
	lbl.add_theme_constant_override("outline_size", 22)
	lbl.size = Vector2(sz.x, fsize * 1.6)
	lbl.position = Vector2(0.0, center.y - lbl.size.y * 0.5)
	lbl.pivot_offset = lbl.size * 0.5
	lbl.rotation = deg_to_rad(-9.0)
	parent.add_child(lbl)


## Portrenin sağında replik balonu (kuyruğu portreye bakar).
func _add_speech_bubble(parent: Control, text: String, sz: Vector2) -> void:
	var left: float = PORTRAIT_SIDE + 70.0
	var bw: float = sz.x - left - 30.0
	var bubble: PanelContainer = PanelContainer.new()
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color(1.0, 1.0, 0.98)
	sb.border_color = GameConfig.COLOR_INK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(40)
	sb.set_content_margin_all(26)
	bubble.add_theme_stylebox_override("panel", sb)
	bubble.custom_minimum_size = Vector2(bw, 0.0)
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(bw - 52.0, 0.0)
	lbl.add_theme_font_override("font", AssetHelper.get_title_font())
	lbl.add_theme_font_size_override("font_size", BUBBLE_FONT_SIZE)
	lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	bubble.add_child(lbl)
	var bh: float = bubble.get_combined_minimum_size().y
	bubble.position = Vector2(left, maxf(20.0, (sz.y - bh) * 0.5))
	var tail: Polygon2D = Polygon2D.new()
	var ty: float = bubble.position.y + minf(bh * 0.5, 90.0)
	tail.polygon = PackedVector2Array([Vector2(left + 6.0, ty - 26.0), Vector2(left - 46.0, ty + 18.0), Vector2(left + 6.0, ty + 22.0)])
	tail.color = GameConfig.COLOR_INK
	parent.add_child(tail)
	parent.add_child(bubble)


## El çizimi hissi: köşe ve kenar ortası noktaları birkaç piksel oynayan kalın çerçeve.
func _add_border(root: Node, r: Rect2) -> void:
	var j: float = GameConfig.DEATH_CARD_JITTER_PX
	var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in range(4):
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		pts.append(a + Vector2(_rng.randf_range(-j, j), _rng.randf_range(-j, j)))
		pts.append(a.lerp(b, 0.5) + Vector2(_rng.randf_range(-j, j), _rng.randf_range(-j, j)) * 0.6)
	pts.append(pts[0])
	var line: Control = Control.new()
	line.size = Vector2(float(GameConfig.DEATH_CARD_SIZE.x), float(GameConfig.DEATH_CARD_SIZE.y))
	line.draw.connect(func() -> void:
		line.draw_polyline(pts, GameConfig.COLOR_INK, GameConfig.DEATH_CARD_BORDER_W, true)
		for p: Vector2 in pts:
			line.draw_circle(p, GameConfig.DEATH_CARD_BORDER_W * 0.5, GameConfig.COLOR_INK)
	)
	root.add_child(line)


func _add_strip(root: Node, r: Rect2, score_val: int) -> void:
	var logo_w: float = r.size.x * 0.34
	# Faz 13B: menü ve açılışla aynı logo (görsel yoksa kodla çizilen afiş)
	var logo: GameLogo = GameLogo.create(false, false)
	logo.position = r.position
	logo.size = Vector2(logo_w, r.size.y)
	root.add_child(logo)
	var score_lbl: Label = Label.new()
	score_lbl.text = "%d kişiyi korkuttu" % score_val
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.position = Vector2(r.position.x + logo_w, r.position.y + 6.0)
	score_lbl.size = Vector2(r.size.x - logo_w, r.size.y * 0.55)
	score_lbl.add_theme_font_override("font", AssetHelper.get_title_font())
	score_lbl.add_theme_font_size_override("font_size", STRIP_FONT_SIZE)
	score_lbl.add_theme_color_override("font_color", GameConfig.COLOR_INK)
	root.add_child(score_lbl)
	var link: Label = Label.new()
	link.text = GameConfig.SHARE_SITE_URL.replace("https://", "")
	link.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	link.position = Vector2(r.position.x + logo_w, r.position.y + r.size.y * 0.55)
	link.size = Vector2(r.size.x - logo_w, r.size.y * 0.4)
	link.add_theme_font_override("font", AssetHelper.get_ui_font())
	link.add_theme_font_size_override("font_size", LINK_FONT_SIZE)
	link.add_theme_color_override("font_color", GameConfig.COLOR_BROWN)
	root.add_child(link)

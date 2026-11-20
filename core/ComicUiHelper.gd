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

	# Küçük köşe ısırıkları (şeffaf oyuklar). Hepsi 9-patch köşe bölgelerinin
	# (yatay 18 px, dikey 14 px) TAMAMEN içinde kalır; böylece geniş butonlarda
	# gerilip uzun oyuğa dönüşmez, her boyutta yuvarlak ısırık olarak görünür.
	var bites: Array[Vector3] = [
		Vector3(float(w) - 10.0, float(top_offset) + 6.0, 6.0),
		Vector3(10.0, float(top_offset + body_h) - 4.0, 5.5),
		Vector3(float(w) - 7.0, float(top_offset + body_h) - 2.0, 3.5),
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


# ---------------------------------------------------------------------------
# Ortak yerleşim yardımcıları (her telefona uyum)
# ---------------------------------------------------------------------------

## Cihazın güvenli alan boşluklarını (çentik, kamera deliği, alt jest çubuğu)
## kanvas birimine çevirip döner: {top, bottom, left, right}. Masaüstünde 0'dır.
static func safe_insets(node: CanvasItem) -> Dictionary:
	var res: Dictionary = {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if node == null or not node.is_inside_tree():
		return res
	var vis: Rect2 = node.get_viewport().get_visible_rect()
	var win: Vector2i = DisplayServer.window_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	if win.x <= 0 or win.y <= 0 or safe.size.x <= 0 or safe.size.y <= 0:
		return res
	# Güvenli alan tüm pencereyle aynıysa (masaüstü) boşluk yok.
	if safe.size.x >= win.x and safe.size.y >= win.y:
		return res
	var sx: float = vis.size.x / float(win.x)
	var sy: float = vis.size.y / float(win.y)
	res["top"] = maxf(0.0, float(safe.position.y)) * sy
	res["bottom"] = maxf(0.0, float(win.y - (safe.position.y + safe.size.y))) * sy
	res["left"] = maxf(0.0, float(safe.position.x)) * sx
	res["right"] = maxf(0.0, float(win.x - (safe.position.x + safe.size.x))) * sx
	return res


## Görünür alan boyutu (aspect=expand olduğu için 720x1280'den farklı olabilir).
static func visible_size(node: CanvasItem) -> Vector2:
	if node == null or not node.is_inside_tree():
		return Vector2(GameConfig.VIEWPORT_WIDTH, GameConfig.VIEWPORT_HEIGHT)
	return node.get_viewport().get_visible_rect().size


## Ekranın ortasında (ya da sheet=true ise altta) açılan, güvenli alana ve ekran boyuna uyan
## standart pencere kurar. İçerik uzunsa otomatik kaydırılır. Dönen sözlük:
##   root (Control, tam ekran), panel (PanelContainer), body (VBoxContainer: içerik buraya),
##   footer (VBoxContainer: kaydırılmayan alt butonlar), title (Label)
## max_height <= 0 ise panel içeriğe göre büyür (ekrana sığdığı sürece).
## Faz 13B: alttan kayarak açılır, arka plan %35 kararır; kapatılabilir pencereler (close_on_dim)
## tutamaçtan ya da başlıktan aşağı kaydırılarak da kapanır. Ebeveyn bir menü sekmesiyse
## (meta "embed_page") karartmasız, sekmeyi dolduran gömülü sayfa olarak kurulur (alt butonlar
## gizlenir); gömülü sayfanın içinden açılan pencereler sekmenin "modal_host"una (ana menü) eklenir.
static func build_modal(
	parent: Node,
	title_text: String,
	bg: Color = GameConfig.COLOR_CREAM,
	max_height: float = 0.0,
	close_on_dim: bool = false,
	sheet: bool = false
) -> Dictionary:
	var embed: bool = parent is Control and parent.has_meta("embed_page")
	if not embed:
		parent = modal_host_for(parent)
	var root: Control = Control.new()
	root.name = "Modal"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE if embed else Control.MOUSE_FILTER_STOP
	root.z_index = 0 if embed else 95

	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.10, 0.06, 0.04, GameConfig.MENU_SHEET_DIM)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.visible = not embed
	root.add_child(dim)
	if close_on_dim:
		dim.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				close_modal(root)
		)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "ModalMargin"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)

	var holder: Container = null
	if embed:
		holder = MarginContainer.new()
	elif sheet:
		var vb: VBoxContainer = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_END
		holder = vb
	else:
		holder = CenterContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(holder)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "ModalPanel"
	if sheet:
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = bg
		sb.border_color = INK_COLOR
		sb.border_width_left = 3
		sb.border_width_top = 3
		sb.border_width_right = 3
		sb.corner_radius_top_left = 30
		sb.corner_radius_top_right = 28
		sb.corner_detail = 8
		sb.shadow_color = Color(INK_COLOR, 0.10)
		sb.shadow_size = 10
		sb.content_margin_left = GameConfig.SP_L
		sb.content_margin_right = GameConfig.SP_L
		sb.content_margin_top = GameConfig.SP_S
		sb.content_margin_bottom = GameConfig.SP_L
		panel.add_theme_stylebox_override("panel", sb)
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	else:
		style_bitten_panel(panel, bg, 1, GameConfig.SP_L)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	holder.add_child(panel)

	var outer: VBoxContainer = VBoxContainer.new()
	outer.add_theme_constant_override("separation", GameConfig.SP_S)
	panel.add_child(outer)

	# Kapatılabilir pencerelerde tutamaç: aşağı kaydırınca kapanır
	var grab: Control = null
	if close_on_dim and not embed:
		grab = Control.new()
		grab.name = "GrabHandle"
		grab.custom_minimum_size = Vector2(0.0, 14.0)
		grab.mouse_filter = Control.MOUSE_FILTER_STOP
		grab.draw.connect(func() -> void:
			var cx: float = grab.size.x * 0.5
			grab.draw_line(Vector2(cx - 28.0, 6.0), Vector2(cx + 28.0, 6.0), Color(INK_COLOR, 0.35), 6.0, true)
		)
		outer.add_child(grab)

	var title: Label = Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	style_label(title, GameConfig.FS_H2, GameConfig.COLOR_DARK_TEXT, true)
	title.visible = not title_text.is_empty()
	outer.add_child(title)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	enable_touch_scroll(scroll)
	outer.add_child(scroll)

	var body: VBoxContainer = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", GameConfig.SP_S)
	scroll.add_child(body)

	var footer: VBoxContainer = VBoxContainer.new()
	footer.add_theme_constant_override("separation", GameConfig.SP_S)
	footer.visible = not embed
	outer.add_child(footer)

	parent.add_child(root)

	if embed:
		return {"root": root, "panel": panel, "body": body, "footer": footer, "title": title, "scroll": scroll}

	var relayout: Callable = func() -> void:
		if not is_instance_valid(root) or not root.is_inside_tree():
			return
		var vs: Vector2 = visible_size(root)
		var ins: Dictionary = safe_insets(root)
		var side: float = GameConfig.MODAL_SIDE_MARGIN
		margin.add_theme_constant_override("margin_top", int(float(ins["top"]) + side))
		margin.add_theme_constant_override("margin_bottom", 0 if sheet else int(float(ins["bottom"]) + side))
		margin.add_theme_constant_override("margin_left", int(float(ins["left"]) + side))
		margin.add_theme_constant_override("margin_right", int(float(ins["right"]) + side))
		var avail_w: float = vs.x - float(ins["left"]) - float(ins["right"]) - side * 2.0
		var avail_h: float = vs.y - float(ins["top"]) - float(ins["bottom"]) - side * 2.0
		var w: float = minf(GameConfig.MODAL_MAX_WIDTH, avail_w)
		panel.custom_minimum_size.x = w
		if sheet:
			# Alt boşluk (jest çubuğu) panelin içinde kalsın
			var psb: StyleBox = panel.get_theme_stylebox("panel")
			if psb != null:
				psb.content_margin_bottom = float(GameConfig.SP_L) + float(ins["bottom"])
		# Kaydırma alanı: içeriğin doğal yüksekliği kadar, ama ekrana sığacak şekilde sınırlı.
		var grab_h: float = grab.get_combined_minimum_size().y + float(GameConfig.SP_S) if grab != null else 0.0
		var chrome_h: float = title.get_combined_minimum_size().y + footer.get_combined_minimum_size().y \
			+ float(GameConfig.SP_S * 2) + float(GameConfig.SP_L * 2) + 8.0 + grab_h
		var content_h: float = body.get_combined_minimum_size().y
		var cap_h: float = avail_h - chrome_h
		if max_height > 0.0:
			cap_h = minf(cap_h, max_height - chrome_h)
		scroll.custom_minimum_size = Vector2(0.0, clampf(content_h, 0.0, maxf(cap_h, 120.0)))
	root.get_viewport().size_changed.connect(relayout)
	body.resized.connect(relayout)
	footer.resized.connect(relayout)
	relayout.call_deferred()

	_animate_open(root, dim, margin)
	if grab != null:
		_attach_swipe_close(root, margin, grab)
		_attach_swipe_close(root, margin, title)
	return {"root": root, "panel": panel, "body": body, "footer": footer, "title": title, "scroll": scroll}


## Gömülü bir menü sekmesinin içinden açılan pencere, sekmenin sahibine (ana menü) eklenir.
static func modal_host_for(parent: Node) -> Node:
	var n: Node = parent
	while n != null:
		if n.has_meta("embed_page"):
			var host: Variant = n.get_meta("modal_host", null)
			if host is Node and is_instance_valid(host):
				return host as Node
			return parent
		n = n.get_parent()
	return parent


## Alttan kayarak açılış + karartmanın yumuşakça gelmesi (oyun duraklatılmışken de çalışır).
static func _animate_open(root: Control, dim: ColorRect, margin: Control) -> void:
	var vs: Vector2 = visible_size(root)
	margin.position.y = vs.y * 0.6
	dim.modulate.a = 0.0
	var tw: Tween = root.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.set_parallel(true)
	tw.tween_property(margin, "position:y", 0.0, GameConfig.MENU_SHEET_SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(dim, "modulate:a", 1.0, GameConfig.MENU_SHEET_SLIDE_SEC)


## Tutamaç / başlıktan aşağı sürükleyince pencere iner; eşiği geçerse kapanır, geçmezse geri oturur.
static func _attach_swipe_close(root: Control, margin: Control, handle: Control) -> void:
	handle.mouse_filter = Control.MOUSE_FILTER_STOP
	var st: Dictionary = {"down": false, "y0": 0.0}
	handle.gui_input.connect(func(ev: InputEvent) -> void:
		if not is_instance_valid(root):
			return
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.pressed:
				st["down"] = true
				st["y0"] = mb.global_position.y
			elif bool(st["down"]):
				st["down"] = false
				if margin.position.y > GameConfig.MENU_SHEET_SWIPE_CLOSE_PX:
					close_modal(root)
				else:
					var back: Tween = root.create_tween()
					back.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
					back.tween_property(margin, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif ev is InputEventMouseMotion and bool(st["down"]):
			var mm: InputEventMouseMotion = ev as InputEventMouseMotion
			margin.position.y = maxf(0.0, mm.global_position.y - float(st["y0"]))
	)


## Pencereyi aşağı kaydırarak kapatır (ağaçtan çıkınca bağlı temizlikler çalışır).
static func close_modal(root: Control) -> void:
	if not is_instance_valid(root) or root.is_queued_for_deletion() or root.has_meta("_closing"):
		return
	root.set_meta("_closing", true)
	var margin: Control = root.get_node_or_null("ModalMargin") as Control
	if margin == null or not root.is_inside_tree():
		root.queue_free()
		return
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw: Tween = root.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(margin, "position:y", visible_size(root).y, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_callback(root.queue_free)


## Etikete font, boyut ve renk uygular (başlıklar için kalın kesim).
static func style_label(lbl: Control, size: int, color: Color = GameConfig.COLOR_DARK_TEXT, is_title: bool = false) -> void:
	lbl.add_theme_font_override("font", AssetHelper.get_title_font() if is_title else AssetHelper.get_ui_font())
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)


## Sekme butonu: seçili sekme koyu mürekkep zemin + krem yazı, diğerleri soluk krem.
static func style_tab(btn: Button, active: bool, font_size: int = GameConfig.FS_BUTTON) -> void:
	var font: Font = AssetHelper.get_ui_font()
	if active:
		style_bitten_button(btn, Color("#5A4436"), font, font_size)
		var light: Color = GameConfig.COLOR_CREAM
		for k: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
			btn.add_theme_color_override(k, light)
		btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.0))
	else:
		style_bitten_button(btn, Color("#EDE3D6"), font, font_size)


## Butonun sağ üst köşesine kırmızı bildirim noktası (●) ekler / kaldırır.
static func set_badge_dot(btn: Control, show_dot: bool, count: int = 0) -> void:
	var existing: Node = btn.get_node_or_null("BadgeDot")
	if not show_dot:
		if existing != null:
			existing.queue_free()
		return
	var dot: Label = existing as Label
	if dot == null:
		dot = Label.new()
		dot.name = "BadgeDot"
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		dot.custom_minimum_size = Vector2(28.0, 28.0)
		dot.size = Vector2(28.0, 28.0)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.COLOR_BADGE_RED
		sb.border_color = GameConfig.COLOR_CREAM
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(14)
		dot.add_theme_stylebox_override("normal", sb)
		style_label(dot, GameConfig.FS_TINY, GameConfig.COLOR_CREAM, true)
		dot.anchor_left = 1.0
		dot.anchor_right = 1.0
		dot.anchor_top = 0.0
		dot.anchor_bottom = 0.0
		dot.offset_left = -22.0
		dot.offset_right = 6.0
		dot.offset_top = -10.0
		dot.offset_bottom = 18.0
		dot.z_index = 2
		btn.add_child(dot)
	dot.text = str(count) if count > 0 else ""


static func _inside_rounded_rect(px: float, py: float, w: float, h: float, r: float) -> bool:
	if px < 0.0 or py < 0.0 or px >= w or py >= h:
		return false
	var cx: float = clampf(px, r, w - 1.0 - r)
	var cy: float = clampf(py, r, h - 1.0 - r)
	var dx: float = px - cx
	var dy: float = py - cy
	return dx * dx + dy * dy <= r * r


## Kaydırma içeriğindeki kart/panel/butonlar dokunmayı yutmasın: parmak kartın üstünden de
## listeyi kaydırsın. STOP olan Control'ler PASS yapılır (kaydırıcı, yazı kutusu hariç);
## içerik sonradan değişince yeniden uygulanır. Parmak deadzone'u aşınca motor butonun
## basışını kendisi iptal eder, yanlışlıkla Seç/Al tetiklenmez.
static func enable_touch_scroll(scroll: ScrollContainer) -> void:
	scroll.scroll_deadzone = GameConfig.TOUCH_SCROLL_DEADZONE_PX
	var apply: Callable = func() -> void:
		if is_instance_valid(scroll):
			_make_scroll_children_pass(scroll)
	scroll.sort_children.connect(apply)
	scroll.child_entered_tree.connect(func(_n: Node) -> void: apply.call_deferred())


static func _make_scroll_children_pass(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Range or child is LineEdit or child is TextEdit:
			continue
		if child is Control and (child as Control).mouse_filter == Control.MOUSE_FILTER_STOP:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_PASS
		_make_scroll_children_pass(child)


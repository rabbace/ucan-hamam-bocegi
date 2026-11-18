class_name AlbumModal
extends RefCounted

## Faz 11.5: "Mahalle Albümü" penceresi. 12 kartlık ızgara (kilitliler silüet + seviye ipucu),
## karta dokununca büyük kart (görsel, ad, açıklama, korkutma sayısı, çığlık sesi) ve tamamlama ödülleri.


## Kişi görseli: alt engel görseli (veya tipin kendi görseli) + yedek aksesuar; kilitliyse silüet.
## Doku TextureRect ile gösterilir (betikten draw_texture ile çizilen doku bazı sürücülerde beyaz kalıyor);
## aksesuarlar üstteki katmanda aynı ölçekle çizilir.
class PersonArt extends Control:
	const INSET: float = 6.0
	var type_id: String = "amca"
	var locked: bool = false
	var _custom: bool = false

	func _init(p_type: String, p_locked: bool, h: float) -> void:
		type_id = p_type
		locked = p_locked
		custom_minimum_size = Vector2(0.0, h)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var crop: Rect2 = PeopleArt.PORTRAIT_CROP
		var tex: Texture2D = PeopleArt.custom_texture(type_id, false)
		_custom = tex != null
		if tex == null:
			tex = AssetHelper.texture(GameConfig.SLIPPER_BOTTOM_PATH, "terlik_alt", GameConfig.SLIPPER_SIZE)
		var sx: float = float(tex.get_width()) / PeopleArt.IMG_W
		var sy: float = float(tex.get_height()) / PeopleArt.IMG_H
		var atlas: AtlasTexture = AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(crop.position * Vector2(sx, sy), crop.size * Vector2(sx, sy))
		var tr: TextureRect = TextureRect.new()
		tr.name = "Art"
		tr.texture = atlas
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		tr.offset_left = INSET
		tr.offset_top = INSET
		tr.offset_right = -INSET
		tr.offset_bottom = -INSET
		if locked:
			tr.modulate = PeopleArt.SILHOUETTE_MOD
		add_child(tr)
		var top: Control = Control.new()
		top.name = "Accessories"
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		top.draw.connect(_draw_top.bind(top))
		add_child(top)

	func _draw_top(ci: Control) -> void:
		var dest: Rect2 = Rect2(Vector2(INSET, INSET), ci.size - Vector2(INSET, INSET) * 2.0)
		if not locked:
			PeopleArt.draw_portrait_accessories(ci, type_id, dest, _custom)
			return
		var font: Font = AssetHelper.get_title_font()
		var fs: int = GameConfig.FS_H1
		var ts: Vector2 = font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		var at: Vector2 = Vector2((ci.size.x - ts.x) * 0.5, ci.size.y * 0.5 + ts.y * 0.3)
		ci.draw_string_outline(font, at, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 8, GameConfig.COLOR_INK)
		ci.draw_string(font, at, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, GameConfig.COLOR_CREAM)


static func _tier_bg(tier: int) -> Color:
	if tier <= 0:
		return GameConfig.ALBUM_LOCKED_COLOR
	return GameConfig.ALBUM_TIER_COLORS[tier - 1]


static func _label(text: String, size: int, color: Color, bold: bool, wrap: bool = true) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(l, size, color, bold)
	return l


## Albüm penceresini açar; kök düğüm "ModalAlbum" (Android Geri tuşu kapatır).
static func open(parent: Control) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "MAHALLE ALBÜMÜ", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalAlbum"
	var body: VBoxContainer = m["body"] as VBoxContainer

	var opened: int = Monetization.album_open_count()
	body.add_child(_label("Bir komşunun yanından kıl payı geç, kartı açılsın!", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false))
	body.add_child(_label("%d / %d komşu  ·  1 Bronz · 10 Gümüş · 50 Altın" % [opened, GameConfig.PEOPLE.size()], GameConfig.FS_SMALL, GameConfig.COLOR_INK, true))

	var grid: GridContainer = GridContainer.new()
	grid.name = "AlbumGrid"
	grid.columns = GameConfig.ALBUM_COLUMNS
	grid.add_theme_constant_override("h_separation", GameConfig.SP_S)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_S)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)
	for p: Dictionary in GameConfig.PEOPLE:
		grid.add_child(_build_card(root, str(p["id"])))

	body.add_child(_build_rewards())

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return root


static func _build_card(root: Control, type_id: String) -> PanelContainer:
	var p: Dictionary = GameConfig.get_person(type_id)
	var cnt: int = Monetization.album_count(type_id)
	var tier: int = GameConfig.album_tier_for(cnt)
	var locked: bool = tier <= 0
	var card: PanelContainer = PanelContainer.new()
	card.name = "Card_%s" % type_id
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0.0, GameConfig.ALBUM_CARD_H)
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	ComicUiHelper.style_bitten_panel(card, _tier_bg(tier), 900 + type_id.length(), GameConfig.SP_XS)
	var v: VBoxContainer = VBoxContainer.new()
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 2)
	card.add_child(v)
	var art: PersonArt = PersonArt.new(type_id, locked, GameConfig.ALBUM_CARD_H * 0.56)
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(art)
	if locked:
		v.add_child(_label("???", GameConfig.FS_TINY, GameConfig.COLOR_INK, true))
		v.add_child(_label(GameConfig.level_hint_text(int(p["level"])), GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false))
	else:
		v.add_child(_label(str(p["name"]), GameConfig.FS_TINY, GameConfig.COLOR_INK, true))
		v.add_child(_label("%s · %d" % [GameConfig.ALBUM_TIER_NAMES[tier - 1], cnt], GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false))
	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			open_detail(root.get_parent() as Control, type_id)
	)
	return card


## Tamamlama ödülleri: tümü bronz / gümüş / altın.
static func _build_rewards() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "AlbumRewards"
	ComicUiHelper.style_bitten_panel(panel, Color("#FFF6EA"), 931, GameConfig.SP_M)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	panel.add_child(v)
	var head: Label = _label("Tamamlama ödülleri", GameConfig.FS_BODY, GameConfig.COLOR_BROWN, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(head)
	var rows: Array[Array] = [
		[1, "bronz", "Hepsi Bronz", "%d Kırıntı" % GameConfig.ALBUM_BRONZE_REWARD],
		[2, "gumus", "Hepsi Gümüş", "Özel kostüm"],
		[3, "altin", "Hepsi Altın", "\"%s\" unvanı" % GameConfig.title_text(GameConfig.ALBUM_GOLD_TITLE_ID)],
	]
	for row: Array in rows:
		var tier: int = int(row[0])
		var done: bool = Monetization.album_rewards.has(str(row[1]))
		var reached: int = 0
		for p: Dictionary in GameConfig.PEOPLE:
			if Monetization.album_tier(str(p["id"])) >= tier:
				reached += 1
		var h: HBoxContainer = HBoxContainer.new()
		h.add_theme_constant_override("separation", GameConfig.SP_S)
		v.add_child(h)
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(22.0, 22.0)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.ALBUM_TIER_COLORS[tier - 1]
		sb.border_color = GameConfig.COLOR_INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(11)
		dot.add_theme_stylebox_override("panel", sb)
		h.add_child(dot)
		var txt: Label = _label("%s → %s" % [str(row[2]), str(row[3])], GameConfig.FS_SMALL, GameConfig.COLOR_INK, false)
		txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(txt)
		var st: Label = _label("Alındı" if done else "%d/%d" % [reached, GameConfig.PEOPLE.size()], GameConfig.FS_SMALL, GameConfig.COLOR_GREEN_GO.darkened(0.35) if done else GameConfig.COLOR_BROWN, true, false)
		h.add_child(st)
	return panel


## Büyük kart: görsel, ad, açıklama, korkutma sayısı; açılırken kişinin çığlığı çalar.
static func open_detail(parent: Control, type_id: String) -> Control:
	var p: Dictionary = GameConfig.get_person(type_id)
	var cnt: int = Monetization.album_count(type_id)
	var tier: int = GameConfig.album_tier_for(cnt)
	var locked: bool = tier <= 0
	var m: Dictionary = ComicUiHelper.build_modal(parent, "???" if locked else str(p["name"]).to_upper(), _tier_bg(tier).lerp(GameConfig.COLOR_CREAM, 0.55), 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalAlbumCard"
	root.z_index = 96
	var body: VBoxContainer = m["body"] as VBoxContainer
	var frame: PanelContainer = PanelContainer.new()
	ComicUiHelper.style_bitten_panel(frame, _tier_bg(tier), 940, GameConfig.SP_S)
	body.add_child(frame)
	frame.add_child(PersonArt.new(type_id, locked, GameConfig.ALBUM_DETAIL_ART_H))
	if locked:
		body.add_child(_label(GameConfig.level_hint_text(int(p["level"])), GameConfig.FS_BODY, GameConfig.COLOR_INK, true))
		body.add_child(_label("Bu komşunun yanından kıl payı geçince kartı açılır.", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false))
	else:
		body.add_child(_label("%s kart" % GameConfig.ALBUM_TIER_NAMES[tier - 1], GameConfig.FS_BODY, GameConfig.COLOR_BROWN, true))
		body.add_child(_label("\"%s\"" % str(p["desc"]), GameConfig.FS_BODY, GameConfig.COLOR_INK, false))
		var next_txt: String = ""
		if tier < GameConfig.ALBUM_TIER_COUNTS.size():
			next_txt = "  ·  %s karta %d kaldı" % [GameConfig.ALBUM_TIER_NAMES[tier], GameConfig.ALBUM_TIER_COUNTS[tier] - cnt]
		body.add_child(_label("%d kez korkuttun%s" % [cnt, next_txt], GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false))
		var pitch: float = float(p.get("pitch", 1.0))
		var scream_btn: Button = Button.new()
		scream_btn.text = "Çığlığını dinle"
		scream_btn.custom_minimum_size = Vector2(0.0, 60.0)
		ComicUiHelper.style_bitten_button(scream_btn, GameConfig.COLOR_DUST_PINK, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
		scream_btn.pressed.connect(func() -> void:
			AudioManager.play_sfx(GameConfig.ALBUM_SCREAM_SFX, pitch, pitch)
		)
		(m["footer"] as VBoxContainer).add_child(scream_btn)
		AudioManager.play_sfx(GameConfig.ALBUM_SCREAM_SFX, pitch, pitch)
	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return root

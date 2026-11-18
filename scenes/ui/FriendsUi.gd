class_name FriendsUi
extends RefCounted

## Faz 12.1–12.3 arayüzü: Arkadaşlar ekranı (3 sekme), Arkadaş Ekle, profil kartı, Hesabım
## (Kurtarma Kodu / Kimliğimi Geri Yükle) ve paylaşım bağlantısı onayı. Hepsi ComicUiHelper.build_modal ile.
## Faz 12.4–12.5: bekleyen davetler, "Katıl" / "Davet Et", oda gizliliği seçici, Engelle / Bildir,
## Engellenenler ve "Hesabımı Sil".

const PORTRAIT_SCENE: PackedScene = preload("res://scenes/ui/CharacterPortrait.tscn")
const ROW_ICON: float = 64.0
const ROW_BTN_H: float = 52.0
const ROW_BTN_W: float = 120.0
const DOT_SIZE: float = 16.0
const PROFILE_PORTRAIT: float = 220.0
const LONG_PRESS_SEC: float = 0.5
const TAP_SLOP_PX: float = 18.0
const TAB_FRIENDS: int = 0
const TAB_REQUESTS: int = 1
const TAB_RECENT: int = 2


## Durum noktası (yeşil / sarı / turuncu / gri)
class PresenceDot extends Control:
	var col: Color = Color.GRAY

	func _init(p_col: Color) -> void:
		col = p_col
		custom_minimum_size = Vector2(FriendsUi.DOT_SIZE, FriendsUi.DOT_SIZE)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.5
		draw_circle(size * 0.5, r, col)
		draw_arc(size * 0.5, r - 1.0, 0.0, TAU, 20, GameConfig.COLOR_INK, 2.0, true)


# ---------------------------------------------------------------------------
# Arkadaşlar ekranı
# ---------------------------------------------------------------------------

static func open_friends(parent: Node, start_tab: int = TAB_FRIENDS) -> Control:
	Mahalle.activate()
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ARKADAŞLAR", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalFriends"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()

	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(head)
	var id_lbl: Label = Label.new()
	id_lbl.name = "MyId"
	id_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	id_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(id_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	head.add_child(id_lbl)
	var add_btn: Button = Button.new()
	add_btn.name = "AddFriendButton"
	add_btn.text = "Arkadaş Ekle"
	add_btn.custom_minimum_size = Vector2(200.0, ROW_BTN_H)
	add_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ComicUiHelper.style_bitten_button(add_btn, GameConfig.COLOR_GOLD, font, GameConfig.FS_SMALL, 910)
	add_btn.pressed.connect(func() -> void: open_add_friend(root))
	head.add_child(add_btn)

	var link_lbl: Label = _hint("")
	link_lbl.name = "LinkStatus"
	body.add_child(link_lbl)

	var tabs: HBoxContainer = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(tabs)
	var tab_btns: Array[Button] = []
	for t_name: String in ["Arkadaşlar", "İstekler", "Son Oynadıkların"]:
		var tb: Button = Button.new()
		tb.name = "Tab_%d" % tab_btns.size()
		tb.text = t_name
		tb.clip_text = true
		tb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tb.custom_minimum_size = Vector2(0.0, ROW_BTN_H)
		tabs.add_child(tb)
		tab_btns.append(tb)

	var list: VBoxContainer = VBoxContainer.new()
	list.name = "FriendList"
	list.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(list)

	var state: Dictionary = {"tab": start_tab}
	var rebuild: Callable = func() -> void:
		if not is_instance_valid(list):
			return
		id_lbl.text = "Kimliğin: %s" % Mahalle.formatted_id() if Mahalle.has_account() else "Kimliğin bağlanınca verilecek."
		link_lbl.text = Mahalle.link_status_text()
		link_lbl.visible = not Mahalle.is_online()
		var n_in: int = Mahalle.requests_in.size()
		tab_btns[TAB_FRIENDS].text = "Arkadaşlar (%d)" % Mahalle.friends.size()
		ComicUiHelper.set_badge_dot(tab_btns[TAB_FRIENDS], not Mahalle.live_invites().is_empty(), Mahalle.live_invites().size())
		tab_btns[TAB_REQUESTS].text = "İstekler (%d)" % n_in if n_in > 0 else "İstekler"
		for i: int in range(tab_btns.size()):
			ComicUiHelper.style_tab(tab_btns[i], i == int(state["tab"]), GameConfig.FS_TINY)
		ComicUiHelper.set_badge_dot(tab_btns[TAB_REQUESTS], n_in > 0, n_in)
		for ch: Node in list.get_children():
			list.remove_child(ch)
			ch.queue_free()
		match int(state["tab"]):
			TAB_FRIENDS:
				_fill_friends(root, list)
			TAB_REQUESTS:
				_fill_requests(root, list)
			TAB_RECENT:
				_fill_recent(root, list)
	for i: int in range(tab_btns.size()):
		var idx: int = i
		tab_btns[i].pressed.connect(func() -> void:
			state["tab"] = idx
			rebuild.call()
		)
	Mahalle.friends_changed.connect(rebuild)
	Mahalle.status_changed.connect(rebuild)
	Mahalle.identity_changed.connect(rebuild)
	Mahalle.invites_changed.connect(rebuild)
	root.tree_exiting.connect(func() -> void:
		Mahalle.friends_changed.disconnect(rebuild)
		Mahalle.status_changed.disconnect(rebuild)
		Mahalle.identity_changed.disconnect(rebuild)
		Mahalle.invites_changed.disconnect(rebuild)
	)
	rebuild.call()
	Mahalle.refresh_list()
	_add_close(m)
	return root


static func _fill_friends(root: Control, list: VBoxContainer) -> void:
	_fill_invites(root, list)
	if not Mahalle.auto_join_wait.is_empty():
		var wait_row: HBoxContainer = HBoxContainer.new()
		wait_row.name = "AutoJoinRow"
		wait_row.add_theme_constant_override("separation", GameConfig.SP_S)
		var wl: Label = _hint("Maç bitince otomatik katılacaksın.")
		wl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wait_row.add_child(wl)
		var cancel: Button = _small_button("Vazgeç", GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), 940)
		cancel.pressed.connect(func() -> void: Mahalle.cancel_auto_join())
		wait_row.add_child(cancel)
		list.add_child(wait_row)
	var arr: Array = Mahalle.sorted_friends()
	if arr.is_empty():
		list.add_child(_hint("Henüz arkadaşın yok. Kimliğini paylaş ya da \"Arkadaş Ekle\" ile kimlik gir." if Mahalle.list_loaded or not Mahalle.is_online() else "Liste geliyor..."))
		return
	for f_v: Variant in arr:
		var f: Dictionary = f_v as Dictionary
		var uid: String = str(f.get("id", ""))
		var st: String = str(f.get("state", GameConfig.PRESENCE_OFFLINE))
		var status: String = Mahalle.presence_text(f)
		if st == GameConfig.PRESENCE_MATCH:
			status += " · Maç bitince katılabilirsin"
		var row: PanelContainer = _person_row(str(f.get("name", "Böcek")), uid, str(f.get("char", "klasik")), st, status)
		list.add_child(row)
		var p_name: String = str(f.get("name", "Böcek"))
		var p_char: String = str(f.get("char", "klasik"))
		# Faz 12.4: odadaki / maçtaki arkadaşın odasına katıl (gizliliğe göre)
		if (st == GameConfig.PRESENCE_ROOM or st == GameConfig.PRESENCE_MATCH) and Mahalle.is_online():
			var box: HBoxContainer = row.get_node("H/Actions") as HBoxContainer
			box.add_child(_join_button(root, uid, p_name))
		_attach_press(row,
			func() -> void: open_profile(root, uid, p_name, p_char),
			func() -> void: _open_friend_menu(root, uid, p_name, p_char))


static func _fill_requests(root: Control, list: VBoxContainer) -> void:
	if Mahalle.requests_in.is_empty() and Mahalle.requests_out.is_empty():
		list.add_child(_hint("Bekleyen istek yok."))
		return
	var font: Font = AssetHelper.get_ui_font()
	if not Mahalle.requests_in.is_empty():
		list.add_child(_section("Gelen istekler"))
	for r_v: Variant in Mahalle.requests_in:
		var r: Dictionary = r_v as Dictionary
		var uid: String = str(r.get("id", ""))
		var row: PanelContainer = _person_row(str(r.get("name", "Böcek")), uid, str(r.get("char", "klasik")), "", "Arkadaş olmak istiyor")
		list.add_child(row)
		var box: HBoxContainer = row.get_node("H/Actions") as HBoxContainer
		var acc: Button = _small_button("Kabul", GameConfig.COLOR_GREEN_GO, font, 911)
		acc.name = "Accept_%s" % uid
		acc.pressed.connect(func() -> void:
			acc.disabled = true
			Mahalle.respond_request(uid, true, func(res: Dictionary) -> void:
				_toast_result(root, res, "Artık arkadaşsınız!"))
		)
		box.add_child(acc)
		var rej: Button = _small_button("Reddet", GameConfig.COLOR_PEACH, font, 912)
		rej.name = "Reject_%s" % uid
		rej.pressed.connect(func() -> void:
			rej.disabled = true
			Mahalle.respond_request(uid, false)
		)
		box.add_child(rej)
		var p_name: String = str(r.get("name", "Böcek"))
		var p_char: String = str(r.get("char", "klasik"))
		_attach_press(row, func() -> void: open_profile(root, uid, p_name, p_char), Callable())
	if not Mahalle.requests_out.is_empty():
		list.add_child(_section("Gönderdiklerin"))
	for r_v: Variant in Mahalle.requests_out:
		var r: Dictionary = r_v as Dictionary
		list.add_child(_person_row(str(r.get("name", "Böcek")), str(r.get("id", "")), str(r.get("char", "klasik")), "", "Yanıt bekleniyor"))


static func _fill_recent(root: Control, list: VBoxContainer) -> void:
	if Mahalle.recent_players.is_empty():
		list.add_child(_hint("Çevrimiçi ya da LAN maçında birlikte oynadığın son %d gerçek oyuncu burada görünür (botlar hariç)." % GameConfig.RECENT_PLAYERS_MAX))
		return
	var font: Font = AssetHelper.get_ui_font()
	for r_v: Variant in Mahalle.recent_players:
		var r: Dictionary = r_v as Dictionary
		var uid: String = str(r.get("id", ""))
		var p_name: String = str(r.get("name", "Böcek"))
		var p_char: String = str(r.get("char", "klasik"))
		var row: PanelContainer = _person_row(p_name, uid, p_char, "", "")
		list.add_child(row)
		var box: HBoxContainer = row.get_node("H/Actions") as HBoxContainer
		box.add_child(_relation_widget(root, uid, font))
		_attach_press(row, func() -> void: open_profile(root, uid, p_name, p_char), Callable())


## Kişi satırı: ikon, ad, kimlik, durum noktası + yazısı, sağda eylem kutusu (H/Actions).
static func _person_row(p_name: String, uid: String, char_id: String, state: String, status: String) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "Row_%s" % uid
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FBF6EC")
	sb.border_color = GameConfig.COLOR_INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(GameConfig.SP_XS)
	card.add_theme_stylebox_override("panel", sb)
	var h: HBoxContainer = HBoxContainer.new()
	h.name = "H"
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_theme_constant_override("separation", GameConfig.SP_S)
	card.add_child(h)
	var cdata: Dictionary = CharacterData.get_character(char_id)
	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = Vector2(ROW_ICON, ROW_ICON)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
	h.add_child(icon)
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_theme_constant_override("separation", 0)
	h.add_child(info)
	var n_lbl: Label = Label.new()
	n_lbl.text = p_name
	n_lbl.clip_text = true
	n_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ComicUiHelper.style_label(n_lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	info.add_child(n_lbl)
	var id_lbl: Label = Label.new()
	id_lbl.text = GameConfig.format_account_id(uid)
	ComicUiHelper.style_label(id_lbl, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	info.add_child(id_lbl)
	if not status.is_empty():
		var s_row: HBoxContainer = HBoxContainer.new()
		s_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		s_row.add_theme_constant_override("separation", GameConfig.SP_XS)
		info.add_child(s_row)
		if not state.is_empty():
			var dot: PresenceDot = PresenceDot.new(GameConfig.PRESENCE_COLORS.get(state, Color.GRAY) as Color)
			dot.name = "Dot"
			s_row.add_child(dot)
		var s_lbl: Label = Label.new()
		s_lbl.name = "Status"
		s_lbl.text = status
		s_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		s_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(s_lbl, GameConfig.FS_TINY, GameConfig.COLOR_DARK_TEXT, false)
		s_row.add_child(s_lbl)
	var actions: HBoxContainer = HBoxContainer.new()
	actions.name = "Actions"
	actions.add_theme_constant_override("separation", GameConfig.SP_XS)
	actions.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(actions)
	return card


## Dokun = on_tap, uzun bas = on_long (kaydırma için küçük kayma payı).
static func _attach_press(ctrl: Control, on_tap: Callable, on_long: Callable) -> void:
	var st: Dictionary = {"down": false, "pos": Vector2.ZERO, "ms": 0, "long_done": false}
	ctrl.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var mb: InputEventMouseButton = ev as InputEventMouseButton
			if mb.pressed:
				st["down"] = true
				st["pos"] = mb.position
				st["ms"] = Time.get_ticks_msec()
				st["long_done"] = false
				if on_long.is_valid():
					var press_ms: int = int(st["ms"])
					ctrl.get_tree().create_timer(LONG_PRESS_SEC).timeout.connect(func() -> void:
						if is_instance_valid(ctrl) and bool(st["down"]) and int(st["ms"]) == press_ms:
							st["long_done"] = true
							st["down"] = false
							on_long.call()
					)
			elif bool(st["down"]):
				st["down"] = false
				if not bool(st["long_done"]) and on_tap.is_valid():
					on_tap.call()
		elif ev is InputEventMouseMotion and bool(st["down"]):
			if ((ev as InputEventMouseMotion).position - (st["pos"] as Vector2)).length() > TAP_SLOP_PX:
				st["down"] = false
	)


static func _open_friend_menu(parent: Node, uid: String, p_name: String, p_char: String) -> void:
	var m: Dictionary = ComicUiHelper.build_modal(parent, p_name, GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalFriendMenu"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()
	var prof: Button = _wide_button("Profil", GameConfig.COLOR_DUST_BLUE, font, 913)
	prof.pressed.connect(func() -> void:
		root.queue_free()
		open_profile(parent, uid, p_name, p_char)
	)
	body.add_child(prof)
	if NetworkManager.is_dedicated_mode and not NetworkManager.room_code.is_empty() and not NetworkManager.is_public_room:
		var inv: Button = _wide_button("Odama Davet Et", GameConfig.COLOR_GREEN_GO, font, 941)
		inv.name = "InviteFriend"
		inv.pressed.connect(func() -> void:
			inv.disabled = true
			_send_invite(root, uid, p_name, inv)
		)
		body.add_child(inv)
	var rem: Button = _wide_button("Arkadaşlıktan Çıkar", GameConfig.COLOR_PEACH, font, 914)
	rem.name = "RemoveFriend"
	rem.pressed.connect(func() -> void:
		Mahalle.remove_friend(uid)
		root.queue_free()
	)
	body.add_child(rem)
	var blk: Button = _wide_button("Engelle", GameConfig.COLOR_DUST_PINK, font, 942)
	blk.name = "BlockFriend"
	blk.pressed.connect(func() -> void:
		root.queue_free()
		open_block_confirm(parent, uid, p_name)
	)
	body.add_child(blk)
	_add_close(m)


# ---------------------------------------------------------------------------
# Arkadaş Ekle
# ---------------------------------------------------------------------------

static func open_add_friend(parent: Node, preset_id: String = "") -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ARKADAŞ EKLE", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalAddFriend"
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_hint("Arkadaşının Böcek Kimliğini yaz (# ve tire şart değil, küçük harf de olur). Paylaşım bağlantısını da yapıştırabilirsin."))
	var input: LineEdit = LineEdit.new()
	input.name = "IdInput"
	input.placeholder_text = "#7K3M-QX9P"
	input.max_length = 96
	input.text = GameConfig.format_account_id(preset_id)
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(0.0, 60.0)
	style_line_edit(input)
	body.add_child(input)
	var result: Label = _hint("")
	result.name = "Result"
	result.visible = false
	body.add_child(result)
	var send: Button = _wide_button("İstek Gönder", GameConfig.COLOR_GREEN_GO, AssetHelper.get_ui_font(), 915)
	send.name = "SendButton"
	var do_send: Callable = func() -> void:
		send.disabled = true
		Mahalle.send_friend_request(input.text, func(res: Dictionary) -> void:
			if not is_instance_valid(result):
				return
			send.disabled = false
			result.visible = true
			if bool(res.get("ok", false)):
				if bool(res.get("queued", false)):
					result.text = str(res.get("reason", ""))
				elif bool(res.get("accepted", false)):
					result.text = "O da seni eklemişti: artık arkadaşsınız!"
				else:
					result.text = "İstek gönderildi. Kabul edince listende görünür."
				input.text = ""
			else:
				result.text = str(res.get("reason", "Gönderilemedi."))
		)
	send.pressed.connect(do_send)
	input.text_submitted.connect(func(_t: String) -> void: do_send.call())
	body.add_child(send)
	_add_close(m)
	return root


## Paylaşım bağlantısıyla açıldı: "İstek gönderilsin mi?"
static func open_link_confirm(parent: Node, uid: String) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ARKADAŞ OLALIM MI?", GameConfig.COLOR_CREAM, 0.0, false)
	var root: Control = m["root"] as Control
	root.name = "ModalFriendLink"
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_hint("%s kimlikli böceğe arkadaşlık isteği gönderilsin mi?" % GameConfig.format_account_id(uid)))
	var result: Label = _hint("")
	result.visible = false
	body.add_child(result)
	var font: Font = AssetHelper.get_ui_font()
	var yes: Button = _wide_button("İstek Gönder", GameConfig.COLOR_GREEN_GO, font, 916)
	yes.pressed.connect(func() -> void:
		yes.disabled = true
		Mahalle.activate()
		Mahalle.send_friend_request(uid, func(res: Dictionary) -> void:
			if not is_instance_valid(result):
				return
			result.visible = true
			result.text = str(res.get("reason", "İstek gönderildi.")) if not bool(res.get("ok", false)) or bool(res.get("queued", false)) else "İstek gönderildi."
		)
	)
	body.add_child(yes)
	_add_close(m, "Vazgeç")
	return root


# ---------------------------------------------------------------------------
# Profil kartı
# ---------------------------------------------------------------------------

static func open_profile(parent: Node, uid: String, fallback_name: String = "Böcek", fallback_char: String = "klasik") -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalProfile"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()

	var portrait: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	portrait.interactive = false
	portrait.custom_minimum_size = Vector2(PROFILE_PORTRAIT, PROFILE_PORTRAIT)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(portrait)
	portrait.setup(fallback_char if CharacterData.CHARACTERS.has(fallback_char) else "klasik", CharacterPortrait.EXPR_PROUD)

	var name_lbl: Label = Label.new()
	name_lbl.name = "Name"
	name_lbl.text = fallback_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(name_lbl, GameConfig.FS_H2, GameConfig.COLOR_DARK_TEXT, true)
	body.add_child(name_lbl)
	var id_lbl: Label = _center(GameConfig.format_account_id(uid), GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	id_lbl.name = "Id"
	body.add_child(id_lbl)
	var title_lbl: Label = _center("", GameConfig.FS_BODY, Color("#B07A12"))
	title_lbl.visible = false
	body.add_child(title_lbl)
	var status_row: HBoxContainer = HBoxContainer.new()
	status_row.alignment = BoxContainer.ALIGNMENT_CENTER
	status_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	status_row.visible = false
	body.add_child(status_row)

	var grid: GridContainer = GridContainer.new()
	grid.name = "Stats"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GameConfig.SP_S)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_XS)
	body.add_child(grid)
	var info_lbl: Label = _center("Profil yükleniyor..." if Mahalle.is_online() else "Profil için internet bağlantısı gerekli.", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN)
	body.add_child(info_lbl)

	var action_box: VBoxContainer = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", GameConfig.SP_XS)
	(m["footer"] as VBoxContainer).add_child(action_box)
	var fill_actions: Callable = func() -> void:
		if not is_instance_valid(action_box):
			return
		for ch: Node in action_box.get_children():
			ch.queue_free()
		var rel: String = Mahalle.relation(uid)
		if rel == "self" or uid.is_empty():
			return
		action_box.add_child(_relation_widget(root, uid, font, true))
		# Faz 12.5: Bildir ve Engelle (yan yana)
		var safety: HBoxContainer = HBoxContainer.new()
		safety.name = "SafetyRow"
		safety.add_theme_constant_override("separation", GameConfig.SP_S)
		action_box.add_child(safety)
		var rep_btn: Button = _small_button("Bildir", GameConfig.COLOR_DUST_PINK, font, 943)
		rep_btn.name = "ReportButton"
		rep_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rep_btn.pressed.connect(func() -> void: open_report_profile(root, uid, name_lbl.text))
		safety.add_child(rep_btn)
		var blk_btn: Button = _small_button("Engelle", GameConfig.COLOR_CREAM.darkened(0.08), font, 944)
		blk_btn.name = "BlockButton"
		blk_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		blk_btn.pressed.connect(func() -> void: open_block_confirm(root, uid, name_lbl.text))
		safety.add_child(blk_btn)
	fill_actions.call()

	Mahalle.get_profile(uid, func(res: Dictionary) -> void:
		if not is_instance_valid(grid):
			return
		if not bool(res.get("ok", false)):
			info_lbl.text = str(res.get("reason", "Profil alınamadı."))
			return
		info_lbl.visible = false
		name_lbl.text = str(res.get("name", fallback_name))
		# Engellenmişse düğme "Engeli Kaldır" olur
		var blk: Button = action_box.find_child("BlockButton", true, false) as Button
		if blk != null and bool(res.get("blocked", false)):
			blk.text = "Engeli Kaldır"
			for cn: Dictionary in blk.pressed.get_connections():
				blk.pressed.disconnect(cn["callable"] as Callable)
			blk.pressed.connect(func() -> void:
				blk.disabled = true
				Mahalle.unblock_user(uid, func(r2: Dictionary) -> void:
					if is_instance_valid(blk) and bool(r2.get("ok", false)):
						blk.text = "Engel kalktı"
				)
			)
		var cid: String = str(res.get("char", fallback_char))
		portrait.setup(cid if CharacterData.CHARACTERS.has(cid) else "klasik", CharacterPortrait.EXPR_PROUD)
		var t_txt: String = GameConfig.title_text(str(res.get("title", "")))
		title_lbl.text = t_txt
		title_lbl.visible = not t_txt.is_empty()
		if bool(res.get("friend", false)):
			status_row.visible = true
			var stt: String = str(res.get("state", GameConfig.PRESENCE_OFFLINE))
			status_row.add_child(PresenceDot.new(GameConfig.PRESENCE_COLORS.get(stt, Color.GRAY) as Color))
			var s_lbl: Label = Label.new()
			s_lbl.text = Mahalle.presence_text(res)
			ComicUiHelper.style_label(s_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, false)
			status_row.add_child(s_lbl)
		var st: Dictionary = res.get("stats", {}) as Dictionary
		var rows: Array[Array] = [
			["Toplam maç", str(int(st.get("matches", 0)))],
			["Galibiyet", str(int(st.get("wins", 0)))],
			["Mahalle Muhtarı", str(int(st.get("muhtar", 0)))],
			["Albüm", "%d / %d" % [int(st.get("album", 0)), GameConfig.PEOPLE.size()]],
		]
		for pair: Array in rows:
			var k: Label = Label.new()
			k.text = str(pair[0])
			k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ComicUiHelper.style_label(k, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
			grid.add_child(k)
			var v: Label = Label.new()
			v.text = str(pair[1])
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			ComicUiHelper.style_label(v, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
			grid.add_child(v)
	)
	_add_close(m)
	return root


## İlişkiye göre düğme: Arkadaş Ekle / İstek gitti / Kabul Et / Arkadaşsınız (geniş = profil kartı).
static func _relation_widget(root: Control, uid: String, font: Font, wide: bool = false) -> Control:
	var rel: String = Mahalle.relation(uid)
	var btn: Button = _wide_button("", GameConfig.COLOR_GOLD, font, 917) if wide else _small_button("", GameConfig.COLOR_GOLD, font, 917)
	btn.name = "RelationButton"
	match rel:
		"friend":
			btn.text = "Arkadaşlıktan Çıkar" if wide else "Arkadaş"
			btn.disabled = not wide
			if wide:
				ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 918)
				btn.pressed.connect(func() -> void:
					Mahalle.remove_friend(uid)
					root.queue_free()
				)
		"out":
			btn.text = "İstek gitti"
			btn.disabled = true
		"in":
			btn.text = "Kabul Et"
			ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON if wide else GameConfig.FS_SMALL, 919)
			btn.pressed.connect(func() -> void:
				btn.disabled = true
				Mahalle.respond_request(uid, true)
			)
		_:
			btn.text = "Arkadaş Ekle" if wide else "Ekle"
			btn.pressed.connect(func() -> void:
				btn.disabled = true
				Mahalle.send_friend_request(uid, func(res: Dictionary) -> void:
					if not is_instance_valid(btn):
						return
					if bool(res.get("ok", false)):
						btn.text = "İstek gitti" if not bool(res.get("accepted", false)) else "Arkadaşsınız"
					else:
						btn.disabled = false
						_toast_result(root, res, "")
				)
			)
	return btn


# ---------------------------------------------------------------------------
# Hesabım: kimlik, Kurtarma Kodu, Kimliğimi Geri Yükle
# ---------------------------------------------------------------------------

static func open_account(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "HESABIM", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalAccount"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()

	body.add_child(_section("Böcek Kimliğin"))
	var id_big: Label = _center("", GameConfig.FS_H2, GameConfig.COLOR_INK)
	id_big.name = "AccountId"
	body.add_child(id_big)
	var link_lbl: Label = _hint("")
	link_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(link_lbl)
	var get_btn: Button = _wide_button("Kimlik Al", GameConfig.COLOR_GREEN_GO, font, 920)
	get_btn.pressed.connect(func() -> void: Mahalle.activate())
	body.add_child(get_btn)
	var reset_btn: Button = _wide_button("Bu cihaza yeni kimlik al", GameConfig.COLOR_PEACH, font, 921)
	reset_btn.pressed.connect(func() -> void: Mahalle.reset_identity())
	body.add_child(reset_btn)
	body.add_child(_hint("Şifre, e-posta ya da telefon istemiyoruz. Kimliğin sunucuda rastgele bir kod olarak durur."))

	body.add_child(_section("Kurtarma Kodu"))
	var code_lbl: Label = _center("", GameConfig.FS_H2, GameConfig.COLOR_WARN_RED)
	code_lbl.name = "RecoveryCode"
	code_lbl.visible = false
	body.add_child(code_lbl)
	var warn: Label = _hint("Bu kodu bir yere yaz. Telefon değiştirirsen veya oyunu silersen kimliğini ve arkadaşlarını bununla geri alırsın.")
	body.add_child(warn)
	var code_msg: Label = _hint("Yeni kod üretince eskisi geçersiz olur. Kod bir kez gösterilir.")
	body.add_child(code_msg)
	var code_row: HBoxContainer = HBoxContainer.new()
	code_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(code_row)
	var code_btn: Button = _wide_button("Kurtarma Kodu", GameConfig.COLOR_GOLD, font, 922)
	code_btn.name = "RecoveryButton"
	code_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_row.add_child(code_btn)
	var copy_btn: Button = _small_button("Kopyala", GameConfig.COLOR_DUST_BLUE, font, 923)
	copy_btn.custom_minimum_size = Vector2(ROW_BTN_W + 20.0, 64.0)
	copy_btn.visible = false
	code_row.add_child(copy_btn)
	code_btn.pressed.connect(func() -> void:
		code_btn.disabled = true
		code_msg.text = "Kod isteniyor..."
		Mahalle.new_recovery_code(func(res: Dictionary) -> void:
			if not is_instance_valid(code_lbl):
				return
			code_btn.disabled = false
			if bool(res.get("ok", false)):
				var code: String = GameConfig.format_recovery_code(str(res.get("code", "")))
				code_lbl.text = code
				code_lbl.visible = true
				copy_btn.visible = true
				code_msg.text = "Yeni kodun hazır; eski kod artık geçmez."
				copy_btn.pressed.connect(func() -> void:
					DisplayServer.clipboard_set(code)
					code_msg.text = "Kod panoda. Güvenli bir yere yapıştır."
				)
			else:
				code_msg.text = str(res.get("reason", "Kod alınamadı."))
		)
	)

	body.add_child(_section("Kimliğimi Geri Yükle"))
	body.add_child(_hint("Eski kimliğini ve kurtarma kodunu gir. Geri yüklenince eski cihazdaki anahtar geçersiz olur."))
	var id_in: LineEdit = LineEdit.new()
	id_in.name = "RestoreId"
	id_in.placeholder_text = "Kimlik (#7K3M-QX9P)"
	id_in.custom_minimum_size = Vector2(0.0, 60.0)
	style_line_edit(id_in)
	body.add_child(id_in)
	var code_in: LineEdit = LineEdit.new()
	code_in.name = "RestoreCode"
	code_in.placeholder_text = "Kurtarma kodu (16 harf)"
	code_in.custom_minimum_size = Vector2(0.0, 60.0)
	style_line_edit(code_in)
	body.add_child(code_in)
	var restore_msg: Label = _hint("")
	restore_msg.visible = false
	body.add_child(restore_msg)
	var restore_btn: Button = _wide_button("Kimliğimi Geri Yükle", GameConfig.COLOR_DUST_BLUE, font, 924)
	restore_btn.name = "RestoreButton"
	restore_btn.pressed.connect(func() -> void:
		restore_btn.disabled = true
		restore_msg.visible = true
		restore_msg.text = "Kontrol ediliyor..."
		Mahalle.restore(id_in.text, code_in.text, func(res: Dictionary) -> void:
			if not is_instance_valid(restore_msg):
				return
			restore_btn.disabled = false
			if bool(res.get("ok", false)):
				restore_msg.text = "Kimliğin geri geldi: %s" % Mahalle.formatted_id()
				code_in.text = ""
			else:
				restore_msg.text = str(res.get("reason", "Geri yüklenemedi."))
		)
	)
	body.add_child(restore_btn)

	# Faz 12.5: engellenenler ve hesap silme
	body.add_child(_section("Güvenlik"))
	var blocked_btn: Button = _wide_button("Engellenenler", GameConfig.COLOR_DUST_BLUE, font, 945)
	blocked_btn.name = "BlockedButton"
	blocked_btn.pressed.connect(func() -> void: open_blocked_list(root))
	body.add_child(blocked_btn)
	body.add_child(_hint("Hesabını silersen kimliğin, arkadaşların ve istatistiklerin sunucudan kalıcı olarak silinir. Kırıntı, karakterler ve satın alımlar bu cihazda kalır."))
	var del_btn: Button = _wide_button("Hesabımı Sil", GameConfig.COLOR_WARN_RED, font, 946)
	del_btn.name = "DeleteAccountButton"
	del_btn.pressed.connect(func() -> void: open_delete_account(root))
	body.add_child(del_btn)

	var refresh: Callable = func() -> void:
		if not is_instance_valid(id_big):
			return
		id_big.text = Mahalle.formatted_id() if Mahalle.has_account() else "Henüz yok"
		link_lbl.text = Mahalle.link_status_text()
		get_btn.visible = not Mahalle.has_account() and not Mahalle.is_connecting()
		reset_btn.visible = Mahalle.is_auth_failed()
		code_btn.disabled = not Mahalle.is_online()
		blocked_btn.disabled = not Mahalle.is_online()
		del_btn.disabled = not Mahalle.is_online() or not Mahalle.has_account()
	Mahalle.status_changed.connect(refresh)
	Mahalle.identity_changed.connect(refresh)
	root.tree_exiting.connect(func() -> void:
		Mahalle.status_changed.disconnect(refresh)
		Mahalle.identity_changed.disconnect(refresh)
	)
	refresh.call()
	_add_close(m)
	return root


# ---------------------------------------------------------------------------
# Faz 12.4: oda gizliliği, davetler, "Katıl"
# ---------------------------------------------------------------------------

## Oda gizliliği seçici (3 düğme). state["p"] seçili değeri tutar; on_pick yeni değerle çağrılır.
static func build_privacy_selector(state: Dictionary, hint: Label, on_pick: Callable) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "PrivacyRow"
	row.add_theme_constant_override("separation", GameConfig.SP_XS)
	var btns: Array[Button] = []
	var short_names: Dictionary = {"code": "Kodla açık", "friends": "Arkadaşlar", "invite": "Davetliler"}
	for p: String in GameConfig.ROOM_PRIVACY_ORDER:
		var b: Button = Button.new()
		b.name = "Privacy_%s" % p
		b.text = str(short_names[p])
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, ROW_BTN_H)
		row.add_child(b)
		btns.append(b)
	var refresh: Callable = func() -> void:
		var cur: String = str(state["p"])
		for i: int in range(btns.size()):
			if is_instance_valid(btns[i]):
				ComicUiHelper.style_tab(btns[i], GameConfig.ROOM_PRIVACY_ORDER[i] == cur, GameConfig.FS_TINY)
		if is_instance_valid(hint):
			hint.text = "%s: %s" % [str(GameConfig.ROOM_PRIVACY_NAMES.get(cur, "")), str(GameConfig.ROOM_PRIVACY_HINTS.get(cur, ""))]
	state["refresh"] = refresh
	for i: int in range(btns.size()):
		var pv: String = GameConfig.ROOM_PRIVACY_ORDER[i]
		btns[i].pressed.connect(func() -> void:
			state["p"] = pv
			refresh.call()
			on_pick.call(pv)
		)
	refresh.call()
	return row


## Bekleyen davetler (Arkadaşlar sekmesinin başında): Katıl / Sil.
static func _fill_invites(root: Control, list: VBoxContainer) -> void:
	var live: Array = Mahalle.live_invites()
	if live.is_empty():
		return
	list.add_child(_section("Bekleyen davetler"))
	var font: Font = AssetHelper.get_ui_font()
	for i: int in range(live.size() - 1, -1, -1):
		var inv: Dictionary = live[i] as Dictionary
		var from: Dictionary = inv.get("from", {}) as Dictionary
		var fid: String = str(from.get("id", ""))
		var left_min: int = maxi(1, ceili(float(int(inv.get("exp", 0)) - int(Time.get_unix_time_from_system())) / 60.0))
		var row: PanelContainer = _person_row(str(from.get("name", "Böcek")), fid, str(from.get("char", "klasik")), "",
			"Oda: %s (%d/%d) · %d dk" % [str(inv.get("code", "")), int(inv.get("n", 1)), int(inv.get("max", 5)), left_min])
		row.name = "Invite_%s" % fid
		list.add_child(row)
		var box: HBoxContainer = row.get_node("H/Actions") as HBoxContainer
		var join: Button = _small_button("Katıl", GameConfig.COLOR_GREEN_GO, font, 947)
		join.name = "AcceptInvite"
		join.pressed.connect(func() -> void:
			join.disabled = true
			Mahalle.accept_invite(fid, false, func(res: Dictionary) -> void:
				if not is_instance_valid(join):
					return
				join.disabled = false
				if bool(res.get("in_match", false)):
					_open_wait_offer(root, func() -> void: Mahalle.accept_invite(fid, true, func(r2: Dictionary) -> void: _toast_result(root, r2, "Maç bitince otomatik katılacaksın.")))
				elif not bool(res.get("ok", false)):
					_toast_result(root, res, "")
			)
		)
		box.add_child(join)
		var del: Button = _small_button("Sil", GameConfig.COLOR_PEACH, font, 948)
		del.custom_minimum_size.x = 72.0
		del.pressed.connect(func() -> void: Mahalle.decline_invite(fid))
		box.add_child(del)
	list.add_child(_section("Arkadaşların"))


## Arkadaş satırındaki "Katıl": gizliliğe göre girer; maç sürüyorsa "Maç bitince otomatik katıl" önerir.
static func _join_button(root: Control, uid: String, p_name: String) -> Button:
	var btn: Button = _small_button("Katıl", GameConfig.COLOR_GREEN_GO, AssetHelper.get_ui_font(), 949)
	btn.name = "Join_%s" % uid
	btn.disabled = Mahalle.auto_join_wait == uid
	btn.pressed.connect(func() -> void:
		btn.disabled = true
		Mahalle.join_friend(uid, false, func(res: Dictionary) -> void:
			if not is_instance_valid(btn):
				return
			btn.disabled = false
			if bool(res.get("ok", false)):
				return
			if bool(res.get("in_match", false)):
				_open_wait_offer(root, func() -> void:
					Mahalle.join_friend(uid, true, func(r2: Dictionary) -> void:
						_toast_result(root, r2, "Maç bitince %s'in odasına otomatik katılacaksın." % p_name))
				)
			else:
				_toast_result(root, res, "")
		)
	)
	return btn


## "Maç sürüyor" penceresi: [Maç bitince otomatik katıl] [Vazgeç]
static func _open_wait_offer(parent: Node, on_wait: Callable) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "MAÇ SÜRÜYOR", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalAutoJoin"
	(m["body"] as VBoxContainer).add_child(_center("Arkadaşın şu an maçta. Maç bitince seni lobiye alalım mı? (Rövanş başlamadan önce)", GameConfig.FS_BODY, GameConfig.COLOR_INK))
	var yes: Button = _wide_button("Maç bitince otomatik katıl", GameConfig.COLOR_GREEN_GO, AssetHelper.get_ui_font(), 950)
	yes.name = "AutoJoinButton"
	yes.pressed.connect(func() -> void:
		on_wait.call()
		root.queue_free()
	)
	(m["footer"] as VBoxContainer).add_child(yes)
	_add_close(m, "Vazgeç")
	return root


## Lobideki "Arkadaş Davet Et": arkadaş listesinden seç (odadakiler hariç). Çevrimdışına paylaşım önerilir.
static func open_invite_friends(parent: Node) -> Control:
	Mahalle.activate()
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ARKADAŞ DAVET ET", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalInviteFriends"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()
	body.add_child(_hint("Oda: %s · %s" % [NetworkManager.room_code, str(GameConfig.ROOM_PRIVACY_NAMES.get(NetworkManager.room_privacy, ""))]))
	var list: VBoxContainer = VBoxContainer.new()
	list.name = "InviteList"
	list.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(list)
	var in_room: Array = NetworkManager.room_user_ids()
	var rebuild: Callable = func() -> void:
		if not is_instance_valid(list):
			return
		for ch: Node in list.get_children():
			list.remove_child(ch)
			ch.queue_free()
		if not Mahalle.is_online():
			list.add_child(_hint(Mahalle.link_status_text()))
			return
		var shown: int = 0
		for f_v: Variant in Mahalle.sorted_friends():
			var f: Dictionary = f_v as Dictionary
			var uid: String = str(f.get("id", ""))
			if in_room.has(uid):
				continue
			shown += 1
			var st: String = str(f.get("state", GameConfig.PRESENCE_OFFLINE))
			var p_name: String = str(f.get("name", "Böcek"))
			var row: PanelContainer = _person_row(p_name, uid, str(f.get("char", "klasik")), st, Mahalle.presence_text(f))
			list.add_child(row)
			var box: HBoxContainer = row.get_node("H/Actions") as HBoxContainer
			var b: Button = _small_button("Davet Et", GameConfig.COLOR_GREEN_GO if st != GameConfig.PRESENCE_OFFLINE else GameConfig.COLOR_GOLD, font, 951)
			b.name = "Invite_%s" % uid
			b.pressed.connect(func() -> void:
				b.disabled = true
				_send_invite(root, uid, p_name, b)
			)
			box.add_child(b)
		if shown == 0:
			list.add_child(_hint("Davet edilecek arkadaşın yok. Arkadaşlar ekranından kimlikle arkadaş ekleyebilirsin."))
	Mahalle.friends_changed.connect(rebuild)
	Mahalle.status_changed.connect(rebuild)
	root.tree_exiting.connect(func() -> void:
		Mahalle.friends_changed.disconnect(rebuild)
		Mahalle.status_changed.disconnect(rebuild)
	)
	rebuild.call()
	Mahalle.refresh_list()
	_add_close(m)
	return root


static func _send_invite(root: Control, uid: String, p_name: String, btn: Button) -> void:
	Mahalle.invite_friend(uid, func(res: Dictionary) -> void:
		if not is_instance_valid(root):
			return
		if not bool(res.get("ok", false)):
			if is_instance_valid(btn):
				btn.disabled = false
			_toast_result(root, res, "")
			return
		if is_instance_valid(btn):
			btn.text = "Davet gitti"
		if bool(res.get("offline", false)):
			open_offline_share(root, p_name)
	)


## Davet edilen çevrimdışı: davet 10 dk saklanır; bağlantıyı paylaşma önerisi (Faz 9.5 paylaşımı).
static func open_offline_share(parent: Node, p_name: String) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalOfflineShare"
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_center("%s çevrimdışı. Davetin 10 dk saklanacak." % p_name, GameConfig.FS_BODY, GameConfig.COLOR_INK))
	body.add_child(_center("Arkadaşın çevrimdışı. Bağlantıyı WhatsApp'tan gönder?", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN))
	var res_lbl: Label = _hint("")
	res_lbl.visible = false
	body.add_child(res_lbl)
	var send: Button = _wide_button("Bağlantıyı Gönder", GameConfig.COLOR_GREEN_GO, AssetHelper.get_ui_font(), 952)
	send.name = "ShareRoomButton"
	send.pressed.connect(func() -> void:
		var msg: String = share_room_link()
		if not msg.is_empty():
			res_lbl.text = msg
			res_lbl.visible = true
	)
	(m["footer"] as VBoxContainer).add_child(send)
	_add_close(m, "Gerek yok")
	return root


## Oda bağlantısını paylaşır (eklenti yoksa panoya). Dönen metin kullanıcıya gösterilebilir.
static func share_room_link() -> String:
	var link: String = "%s/oda.html?k=%s" % [GameConfig.SHARE_SITE_URL, NetworkManager.room_code]
	var msg: String = "Mutfakta yer açtım! Uçan Hamam Böceği odama gel. Oda kodu: %s  %s" % [NetworkManager.room_code, link]
	Monetization.quest_event("invite")
	if Engine.has_singleton("GodotShare"):
		Engine.get_singleton("GodotShare").call("shareText", "Oda Daveti", "Uçan Hamam Böceği", msg)
		return ""
	DisplayServer.clipboard_set(msg)
	return "Davet yazısı panoda, yapıştır gönder."


# ---------------------------------------------------------------------------
# Faz 12.5: Engelle, Bildir, Engellenenler, Hesabımı Sil
# ---------------------------------------------------------------------------

static func open_block_confirm(parent: Node, uid: String, p_name: String) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ENGELLE", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalBlock"
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_center("%s (%s) engellensin mi?" % [p_name, GameConfig.format_account_id(uid)], GameConfig.FS_BODY, GameConfig.COLOR_INK))
	body.add_child(_hint("Arkadaşlığınız ve istekler silinir. Seni listesinde göremez, istek ve davet gönderemez, aynı odaya giremez; Hızlı Oyun'da aynı odaya düşmezsiniz. Hesabım → Engellenenler'den kaldırabilirsin."))
	var res_lbl: Label = _hint("")
	res_lbl.visible = false
	body.add_child(res_lbl)
	var yes: Button = _wide_button("Engelle", GameConfig.COLOR_WARN_RED, AssetHelper.get_ui_font(), 953)
	yes.name = "ConfirmBlock"
	yes.pressed.connect(func() -> void:
		yes.disabled = true
		Mahalle.block_user(uid, func(res: Dictionary) -> void:
			if not is_instance_valid(res_lbl):
				return
			res_lbl.visible = true
			res_lbl.text = "Engellendi." if bool(res.get("ok", false)) else str(res.get("reason", "Engellenemedi."))
			if not bool(res.get("ok", false)):
				yes.disabled = false
		)
	)
	(m["footer"] as VBoxContainer).add_child(yes)
	_add_close(m, "Vazgeç")
	return root


## Profil kartından bildirim (oda içi bildirimle aynı kayıt dosyası). Sebepler: uygunsuz isim, taciz, hile, diğer.
static func open_report_profile(parent: Node, uid: String, p_name: String) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "BİLDİR", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalReportProfile"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_hint("%s (%s) neden bildiriliyor? Kimlik, ad ve sebep iletilir." % [p_name, GameConfig.format_account_id(uid)]))
	var res_lbl: Label = _hint("")
	res_lbl.visible = false
	var font: Font = AssetHelper.get_ui_font()
	var btns: Array[Button] = []
	for i: int in range(GameConfig.PROFILE_REPORT_REASONS.size()):
		var b: Button = Button.new()
		b.name = "Reason_%d" % i
		b.text = GameConfig.PROFILE_REPORT_REASONS[i]
		b.custom_minimum_size = Vector2(0.0, 56.0)
		ComicUiHelper.style_bitten_button(b, GameConfig.COLOR_PEACH, font, GameConfig.FS_SMALL, 954 + i)
		var idx: int = i
		b.pressed.connect(func() -> void:
			for rb: Button in btns:
				rb.disabled = true
			Mahalle.report_user(uid, idx, func(res: Dictionary) -> void:
				if not is_instance_valid(res_lbl):
					return
				res_lbl.visible = true
				res_lbl.text = "Bildirimin iletildi. Teşekkürler!" if bool(res.get("ok", false)) else str(res.get("reason", "Gönderilemedi."))
			)
		)
		btns.append(b)
		body.add_child(b)
	body.add_child(res_lbl)
	_add_close(m)
	return root


static func open_blocked_list(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "ENGELLENENLER", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalBlocked"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var list: VBoxContainer = VBoxContainer.new()
	list.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(list)
	list.add_child(_hint("Yükleniyor..."))
	var font: Font = AssetHelper.get_ui_font()
	Mahalle.blocked_list(func(res: Dictionary) -> void:
		if not is_instance_valid(list):
			return
		for ch: Node in list.get_children():
			ch.queue_free()
		var arr: Array = res.get("blocked", []) as Array
		if not bool(res.get("ok", false)) or arr.is_empty():
			list.add_child(_hint(str(res.get("reason", "Engellediğin kimse yok.")) if not bool(res.get("ok", false)) else "Engellediğin kimse yok."))
			return
		for b_v: Variant in arr:
			var b: Dictionary = b_v as Dictionary
			var uid: String = str(b.get("id", ""))
			var row: PanelContainer = _person_row(str(b.get("name", "Böcek")), uid, str(b.get("char", "klasik")), "", "")
			list.add_child(row)
			var un: Button = _small_button("Kaldır", GameConfig.COLOR_SAGE, font, 958)
			un.pressed.connect(func() -> void:
				un.disabled = true
				Mahalle.unblock_user(uid, func(r2: Dictionary) -> void:
					if bool(r2.get("ok", false)) and is_instance_valid(row):
						row.queue_free()
				)
			)
			(row.get_node("H/Actions") as HBoxContainer).add_child(un)
	)
	_add_close(m)
	return root


## Hesabımı Sil: uyarı + kimliği yazarak onay.
static func open_delete_account(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "HESABIMI SİL", GameConfig.COLOR_CREAM, 0.0, false)
	var root: Control = m["root"] as Control
	root.name = "ModalDeleteAccount"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var warn: Label = _center("Kimliğin, arkadaşların ve istatistiklerin kalıcı olarak silinir. Bu geri alınamaz.", GameConfig.FS_BODY, GameConfig.COLOR_WARN_RED)
	warn.name = "Warning"
	body.add_child(warn)
	body.add_child(_hint("Kırıntı, açılan karakterler ve satın alımlar bu cihazda kalır (satın alımlar Google hesabına bağlıdır, geri yüklenebilir)."))
	body.add_child(_hint("Onaylamak için kimliğini yaz: %s" % Mahalle.formatted_id()))
	var input: LineEdit = LineEdit.new()
	input.name = "ConfirmInput"
	input.placeholder_text = "#XXXX-XXXX"
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	input.custom_minimum_size = Vector2(0.0, 60.0)
	style_line_edit(input)
	body.add_child(input)
	var res_lbl: Label = _hint("")
	res_lbl.name = "Result"
	res_lbl.visible = false
	body.add_child(res_lbl)
	var del_btn: Button = _wide_button("Kalıcı Olarak Sil", GameConfig.COLOR_WARN_RED, AssetHelper.get_ui_font(), 959)
	del_btn.name = "ConfirmDelete"
	del_btn.disabled = true
	input.text_changed.connect(func(t: String) -> void:
		del_btn.disabled = GameConfig.normalize_account_id(t) != Mahalle.account_id or Mahalle.account_id.is_empty()
	)
	del_btn.pressed.connect(func() -> void:
		del_btn.disabled = true
		res_lbl.visible = true
		res_lbl.text = "Siliniyor..."
		Mahalle.delete_account(input.text, func(res: Dictionary) -> void:
			if not is_instance_valid(res_lbl):
				return
			if bool(res.get("ok", false)):
				res_lbl.text = "Hesabın silindi. Bu cihazdaki kimlik bilgisi de silindi."
				input.editable = false
			else:
				res_lbl.text = str(res.get("reason", "Silinemedi."))
				del_btn.disabled = false
		)
	)
	(m["footer"] as VBoxContainer).add_child(del_btn)
	_add_close(m, "Vazgeç")
	return root


# ---------------------------------------------------------------------------
# Paylaşım
# ---------------------------------------------------------------------------

## Kimliği paylaşır (Android paylaşım eklentisi yoksa panoya). Dönen metin kullanıcıya gösterilebilir.
static func share_identity() -> String:
	if not Mahalle.has_account():
		return "Kimliğin bağlanınca verilecek."
	var txt: String = Mahalle.share_text()
	if Engine.has_singleton("GodotShare"):
		Engine.get_singleton("GodotShare").call("shareText", "Arkadaş olalım", "Uçan Hamam Böceği", txt)
		return ""
	DisplayServer.clipboard_set(txt)
	return "Davet yazısı panoda, yapıştır gönder."


# ---------------------------------------------------------------------------
# Küçük yardımcılar
# ---------------------------------------------------------------------------

static func _toast_result(root: Control, res: Dictionary, ok_text: String) -> void:
	if not is_instance_valid(root):
		return
	var txt: String = ok_text if bool(res.get("ok", false)) else str(res.get("reason", ""))
	if txt.is_empty():
		return
	var m: Dictionary = ComicUiHelper.build_modal(root, "", GameConfig.COLOR_CREAM, 0.0, true)
	(m["root"] as Control).name = "ModalFriendToast"
	(m["body"] as VBoxContainer).add_child(_center(txt, GameConfig.FS_BODY, GameConfig.COLOR_INK))
	_add_close(m, "Tamam")


static func style_line_edit(le: LineEdit) -> void:
	le.add_theme_font_override("font", AssetHelper.get_ui_font())
	le.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	le.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	le.add_theme_color_override("font_placeholder_color", Color("#9A887C"))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFBF4")
	sb.border_color = ComicUiHelper.INK_COLOR
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = GameConfig.SP_S
	sb.content_margin_right = GameConfig.SP_S
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus", sb)


static func _small_button(text: String, col: Color, font: Font, seed_val: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(ROW_BTN_W, ROW_BTN_H)
	ComicUiHelper.style_bitten_button(b, col, font, GameConfig.FS_SMALL, seed_val)
	return b


static func _wide_button(text: String, col: Color, font: Font, seed_val: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(b, col, font, GameConfig.FS_BUTTON, seed_val)
	return b


static func _section(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	ComicUiHelper.style_label(l, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, true)
	return l


static func _hint(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(l, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	return l


static func _center(text: String, fs: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(l, fs, col, false)
	return l


static func _add_close(m: Dictionary, text: String = "Kapat") -> void:
	var root: Control = m["root"] as Control
	var close_btn: Button = Button.new()
	close_btn.name = "CloseButton"
	close_btn.text = text
	close_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)

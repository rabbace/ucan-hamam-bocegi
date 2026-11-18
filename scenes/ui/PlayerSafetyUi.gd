class_name PlayerSafetyUi
extends RefCounted

## Faz 11.7: "Bu oyuncuyu sustur" ve "Bildir" arayüzü. Lobide oyuncu kartının altında,
## maç içinde hayatta kalan hapına ya da sıralama satırına dokununca açılan pencerede kullanılır.

const ROW_BTN_H: float = 52.0


## Sustur + Bildir düğme satırı (botlar ve kendin için boş satır döner).
static func build_actions_row(host: Node, pid: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "SafetyRow_%d" % pid
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	if NetworkManager.is_bot_id(pid) or pid == NetworkManager._local_pid():
		return row
	var font: Font = AssetHelper.get_ui_font()
	var mute_btn: Button = Button.new()
	mute_btn.name = "MuteButton"
	mute_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mute_btn.custom_minimum_size = Vector2(0.0, ROW_BTN_H)
	mute_btn.clip_text = true
	row.add_child(mute_btn)
	var refresh: Callable = func() -> void:
		var muted: bool = NetworkManager.is_peer_muted(pid)
		mute_btn.text = "Susturuldu (aç)" if muted else "Bu oyuncuyu sustur"
		ComicUiHelper.style_bitten_button(mute_btn, GameConfig.COLOR_DUST_BLUE if muted else GameConfig.COLOR_CREAM.darkened(0.05), font, GameConfig.FS_TINY, 840)
	refresh.call()
	mute_btn.pressed.connect(func() -> void:
		NetworkManager.toggle_mute_peer(pid)
		if is_instance_valid(mute_btn):
			refresh.call()
	)
	var rep_btn: Button = Button.new()
	rep_btn.name = "ReportButton"
	rep_btn.text = "Bildir"
	rep_btn.custom_minimum_size = Vector2(110.0, ROW_BTN_H)
	ComicUiHelper.style_bitten_button(rep_btn, GameConfig.COLOR_DUST_PINK, font, GameConfig.FS_TINY, 841)
	rep_btn.pressed.connect(func() -> void:
		open_report_modal(host, pid)
	)
	row.add_child(rep_btn)
	return row


## Maç içi: odadaki diğer gerçek oyuncular ve her biri için Sustur / Bildir.
static func open_players_modal(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "OYUNCULAR", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalPlayers"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	var any: bool = false
	for k: Variant in NetworkManager.players.keys():
		var pid: int = int(k)
		if NetworkManager.is_bot_id(pid) or pid == NetworkManager._local_pid():
			continue
		any = true
		var name_lbl: Label = Label.new()
		name_lbl.text = str((NetworkManager.players[pid] as Dictionary).get("name", "Böcek"))
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		ComicUiHelper.style_label(name_lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
		body.add_child(name_lbl)
		body.add_child(build_actions_row(root, pid))
	if not any:
		body.add_child(_hint("Odada senden başka gerçek oyuncu yok."))
	else:
		body.add_child(_hint("Susturma bu oturum boyunca geçerli: o kişinin özel sesleri ve lafları çalmaz, görünmez."))
	_add_close(m)
	return root


## Bildirim sebebi seçimi. Ses verisi gönderilmez; yalnızca isim, oda kodu ve sebep.
static func open_report_modal(parent: Node, pid: int) -> Control:
	var p_name: String = str((NetworkManager.players.get(pid, {}) as Dictionary).get("name", "Böcek"))
	var m: Dictionary = ComicUiHelper.build_modal(parent, "BİLDİR", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalReport"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	body.add_child(_hint("%s neden bildiriliyor? Oyuncu adı, oda kodu ve sebep iletilir; ses kaydı gönderilmez." % p_name))
	var result_lbl: Label = _hint("")
	result_lbl.visible = false
	var font: Font = AssetHelper.get_ui_font()
	var reason_btns: Array[Button] = []
	for i: int in range(GameConfig.REPORT_REASONS.size()):
		var b: Button = Button.new()
		b.text = GameConfig.REPORT_REASONS[i]
		b.custom_minimum_size = Vector2(0.0, 56.0)
		ComicUiHelper.style_bitten_button(b, GameConfig.COLOR_PEACH, font, GameConfig.FS_SMALL, 850 + i)
		var idx: int = i
		b.pressed.connect(func() -> void:
			var msg: String = NetworkManager.report_player(pid, idx)
			for rb: Button in reason_btns:
				rb.disabled = true
			result_lbl.text = msg if not msg.is_empty() else "Bu oyuncu bildirilemez."
			result_lbl.visible = true
		)
		reason_btns.append(b)
		body.add_child(b)
	body.add_child(result_lbl)
	_add_close(m)
	return root


static func _hint(text: String) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(l, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	return l


static func _add_close(m: Dictionary) -> void:
	var root: Control = m["root"] as Control
	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)

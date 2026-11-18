class_name VoiceChatUi
extends RefCounted

## Faz 13A: sesli sohbet arayüzü. Katılma penceresi, Ayarlar bölümü, kişi başına ses penceresi,
## lobi satırları, HUD mikrofon ikonu ve Bas-Konuş butonu. Eklenti yoksa hiçbiri gösterilmez
## (çağıran VoiceChat.ui_available() ile kontrol eder).

const ROW_BTN_W: float = 170.0
const ROW_BTN_H: float = 56.0
const COLOR_OFF: Color = Color("#E6DACB")
const COLOR_MIC_IDLE: Color = Color("#8C8079")


## Mikrofon çizimi (kapsül + ayak), merkez ve boyuta göre.
static func draw_mic_glyph(ci: CanvasItem, c: Vector2, s: float, col: Color) -> void:
	var w: float = s * 0.26
	var h: float = s * 0.40
	var body: StyleBoxFlat = StyleBoxFlat.new()
	body.bg_color = col
	body.set_corner_radius_all(int(w * 0.5))
	ci.draw_style_box(body, Rect2(c + Vector2(-w * 0.5, -s * 0.30), Vector2(w, h)))
	ci.draw_arc(c + Vector2(0.0, -s * 0.06), s * 0.22, deg_to_rad(10.0), deg_to_rad(170.0), 14, col, maxf(2.0, s * 0.06), true)
	ci.draw_line(c + Vector2(0.0, s * 0.16), c + Vector2(0.0, s * 0.27), col, maxf(2.0, s * 0.06), true)
	ci.draw_line(c + Vector2(-s * 0.13, s * 0.28), c + Vector2(s * 0.13, s * 0.28), col, maxf(2.0, s * 0.06), true)


## Ses dalgası çubukları (konuşurken oynar) ve isteğe bağlı küçük anten (böcek sesi).
static func draw_wave(ci: CanvasItem, origin: Vector2, h: float, col: Color, t: float, active: bool, antenna: bool) -> void:
	var bar_w: float = maxf(2.0, h * 0.16)
	for i: int in range(3):
		var amp: float = 0.35 + 0.65 * absf(sin(t * 9.0 + float(i) * 1.7)) if active else 0.3
		var bh: float = h * amp
		var x: float = origin.x + float(i) * bar_w * 1.8
		ci.draw_line(Vector2(x, origin.y - bh * 0.5), Vector2(x, origin.y + bh * 0.5), col, bar_w, true)
	if antenna:
		var ax: float = origin.x + bar_w * 6.2
		var base: Vector2 = Vector2(ax, origin.y + h * 0.4)
		ci.draw_line(base, base + Vector2(-h * 0.18, -h * 0.75), col, maxf(1.5, bar_w * 0.6), true)
		ci.draw_line(base, base + Vector2(h * 0.18, -h * 0.75), col, maxf(1.5, bar_w * 0.6), true)
		ci.draw_circle(base + Vector2(-h * 0.18, -h * 0.75), bar_w * 0.8, col)
		ci.draw_circle(base + Vector2(h * 0.18, -h * 0.75), bar_w * 0.8, col)


## HUD / lobi mikrofon ikonu: konuşurken yeşil dalga, sessizde gri, kapalıyken üstü çizili.
## Dokununca kendini susturur / açar. Dokunuşu tüketir (maçta zıplatmaz).
class MicIcon extends Control:
	var vc: VoiceChat = null
	## -1: durumu VoiceChat'ten al; 0/1/2: sabit gösterim (pencere süsü)
	var fixed_state: int = -1
	var _t: float = 0.0

	func _init(p_vc: VoiceChat, p_size: float) -> void:
		vc = p_vc
		name = "VoiceMicIcon"
		custom_minimum_size = Vector2(p_size, p_size)
		size = custom_minimum_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE
		tooltip_text = "Mikrofon: dokun = sustur / aç"

	func _process(delta: float) -> void:
		_t += delta
		if is_visible_in_tree():
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			if mb.pressed and vc != null:
				vc.toggle_self_mute()

	func state() -> int:
		# 0 kapalı (üstü çizili), 1 açık sessiz (gri), 2 konuşuyor (yeşil)
		if fixed_state >= 0:
			return fixed_state
		if vc == null or vc.local_mode() != GameConfig.VOICE_MODE_TALK or vc.self_muted:
			return 0
		if vc.local_talking:
			return 2
		return 1

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var c: Vector2 = size * 0.5
		var st: int = state()
		var bg: Color = GameConfig.COLOR_GREEN_GO if st == 2 else GameConfig.COLOR_CREAM
		draw_circle(c, s * 0.47, bg)
		draw_arc(c, s * 0.47, 0.0, TAU, 28, GameConfig.COLOR_INK, 2.5, true)
		var glyph_col: Color = GameConfig.COLOR_INK if st == 2 else VoiceChatUi.COLOR_MIC_IDLE
		VoiceChatUi.draw_mic_glyph(self, c + Vector2(-s * 0.08 if st == 2 else 0.0, 0.0), s * 0.78, glyph_col)
		if st == 2:
			VoiceChatUi.draw_wave(self, c + Vector2(s * 0.16, -s * 0.02), s * 0.34, GameConfig.COLOR_INK, _t, true, false)
		elif st == 1 and vc != null and vc.mic_level > 0.0:
			var lvl: float = clampf(vc.mic_level / maxf(AudioManager.vc_vad_threshold * 2.0, 0.01), 0.0, 1.0)
			draw_arc(c, s * 0.40, -PI * 0.5, -PI * 0.5 + TAU * lvl, 24, GameConfig.COLOR_GREEN_GO, 3.0, true)
		if st == 0:
			draw_line(c + Vector2(-s * 0.30, -s * 0.30), c + Vector2(s * 0.30, s * 0.30), GameConfig.COLOR_WARN_RED, maxf(3.0, s * 0.08), true)


## Basılı tut = konuş. Maç içinde küçük, izlerken/sıralamada ve lobide büyük. Dokunuşu tüketir.
class PttButton extends Control:
	var vc: VoiceChat = null
	var _label: Label = null
	var _t: float = 0.0

	func _init(p_vc: VoiceChat, p_size: Vector2, show_label: bool) -> void:
		vc = p_vc
		name = "VoicePttButton"
		custom_minimum_size = p_size
		size = p_size
		mouse_filter = Control.MOUSE_FILTER_STOP
		focus_mode = Control.FOCUS_NONE
		if show_label:
			_label = Label.new()
			_label.text = "Basılı tut, konuş"
			_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ComicUiHelper.style_label(_label, GameConfig.FS_SMALL, GameConfig.COLOR_INK, true)
			add_child(_label)
		resized.connect(_layout)

	func _layout() -> void:
		if _label != null:
			var d: float = minf(size.x, size.y)
			_label.position = Vector2(d + 8.0, 0.0)
			_label.size = Vector2(maxf(0.0, size.x - d - 12.0), size.y)

	func _process(delta: float) -> void:
		_t += delta
		if is_visible_in_tree():
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb != null and mb.button_index == MOUSE_BUTTON_LEFT:
			accept_event()
			if vc != null:
				vc.set_ptt(mb.pressed)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree() and vc != null:
			vc.set_ptt(false)

	func _draw() -> void:
		var d: float = minf(size.x, size.y)
		var c: Vector2 = Vector2(d * 0.5, size.y * 0.5)
		var held: bool = vc != null and vc.ptt_held
		if _label != null:
			var sb: StyleBoxFlat = StyleBoxFlat.new()
			sb.bg_color = GameConfig.COLOR_GREEN_GO if held else GameConfig.COLOR_CREAM
			sb.border_color = GameConfig.COLOR_INK
			sb.set_border_width_all(3)
			sb.set_corner_radius_all(int(size.y * 0.5))
			draw_style_box(sb, Rect2(Vector2.ZERO, size))
		else:
			draw_circle(c, d * 0.47, GameConfig.COLOR_GREEN_GO if held else GameConfig.COLOR_CREAM)
			draw_arc(c, d * 0.47, 0.0, TAU, 32, GameConfig.COLOR_INK, 3.0, true)
		VoiceChatUi.draw_mic_glyph(self, c, d * 0.7, GameConfig.COLOR_INK)
		if held:
			draw_arc(c, d * 0.40, 0.0, TAU, 32, Color(GameConfig.COLOR_INK, 0.35 + 0.25 * sin(_t * 8.0)), 3.0, true)


## Ses dalgası ikonu (lobide konuşan kartın yanında; anten = böcek sesi zorunlu).
class WaveIcon extends Control:
	var active: bool = false
	var antenna: bool = false
	var _t: float = 0.0

	func _init(p_size: Vector2) -> void:
		custom_minimum_size = p_size
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		if active and is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		VoiceChatUi.draw_wave(self, Vector2(size.y * 0.2, size.y * 0.5), size.y * 0.7, GameConfig.COLOR_INK, _t, active, antenna)


## Canlı mikrofon seviyesi çubuğu ve eşik işareti (Ayarlar).
class LevelBar extends Control:
	var vc: VoiceChat = null

	func _init() -> void:
		custom_minimum_size = Vector2(0.0, 28.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		if is_visible_in_tree():
			queue_redraw()

	func _draw() -> void:
		var r: Rect2 = Rect2(Vector2.ZERO, size)
		var bg: StyleBoxFlat = StyleBoxFlat.new()
		bg.bg_color = Color("#3A2A20")
		bg.set_corner_radius_all(8)
		draw_style_box(bg, r)
		var range_max: float = GameConfig.VOICE_CHAT_VAD_MAX * 1.5
		var lvl: float = clampf((vc.mic_level if vc != null and is_instance_valid(vc) else 0.0) / range_max, 0.0, 1.0)
		if lvl > 0.0:
			var fill: StyleBoxFlat = StyleBoxFlat.new()
			var talking: bool = vc != null and is_instance_valid(vc) and vc.local_talking
			fill.bg_color = GameConfig.COLOR_GREEN_GO if talking else GameConfig.COLOR_SAGE
			fill.set_corner_radius_all(6)
			draw_style_box(fill, Rect2(Vector2(3.0, 3.0), Vector2((size.x - 6.0) * lvl, size.y - 6.0)))
		var tx: float = 3.0 + (size.x - 6.0) * clampf(AudioManager.vc_vad_threshold / range_max, 0.0, 1.0)
		draw_line(Vector2(tx, 0.0), Vector2(tx, size.y), GameConfig.COLOR_GOLD, 4.0)


# ---------------------------------------------------------------------------
# Pencereler
# ---------------------------------------------------------------------------

## Sesli sohbeti açık bir odaya ilk girişte: Katıl / Sadece Dinle / Hayır (settings.cfg'ye yazılır).
static func open_join_modal(parent: Node, vc: VoiceChat) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "SESLİ SOHBET", GameConfig.COLOR_CREAM, 0.0, false)
	var root: Control = m["root"] as Control
	root.name = "ModalVoiceJoin"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	var icon_row: HBoxContainer = HBoxContainer.new()
	icon_row.alignment = BoxContainer.ALIGNMENT_CENTER
	var mic: MicIcon = MicIcon.new(null, 84.0)
	mic.fixed_state = 2
	mic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_row.add_child(mic)
	body.add_child(icon_row)
	body.add_child(_hint(GameConfig.VOICE_JOIN_TEXT, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT))
	body.add_child(_hint(GameConfig.VOICE_ECHO_HINT, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN))
	body.add_child(_hint("Seçimini sonra Ayarlar > Sesli Sohbet'ten değiştirebilirsin.", GameConfig.FS_TINY, GameConfig.COLOR_BROWN))
	var footer: VBoxContainer = m["footer"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()
	var defs: Array = [
		["Katıl", GameConfig.VOICE_CHOICE_JOIN, GameConfig.COLOR_GREEN_GO, "JoinButton"],
		["Sadece Dinle", GameConfig.VOICE_CHOICE_LISTEN, GameConfig.COLOR_DUST_BLUE, "ListenButton"],
		["Hayır", GameConfig.VOICE_CHOICE_NO, GameConfig.COLOR_PEACH, "NoButton"],
	]
	for d: Array in defs:
		var b: Button = Button.new()
		b.name = str(d[3])
		b.text = str(d[0])
		b.custom_minimum_size = Vector2(0.0, 60.0)
		ComicUiHelper.style_bitten_button(b, d[2] as Color, font, GameConfig.FS_BUTTON, 870 + footer.get_child_count())
		var choice: String = str(d[1])
		b.pressed.connect(func() -> void:
			root.queue_free()
			if vc != null and is_instance_valid(vc):
				vc.choose(choice)
			else:
				AudioManager.set_vc_choice(choice)
		)
		footer.add_child(b)
	return root


## Ayarlar > Sesli Sohbet bölümü (yalnızca eklenti varsa çağrılır).
static func build_settings_section(body: VBoxContainer, host: Node) -> void:
	var title: Label = Label.new()
	title.text = "Sesli Sohbet"
	ComicUiHelper.style_label(title, GameConfig.FS_BODY, GameConfig.COLOR_BROWN, true)
	body.add_child(title)
	body.add_child(_hint("Yalnızca Özel Oda, arkadaş odaları ve LAN'da. Hızlı Oyun'da hiç açılmaz.", GameConfig.FS_TINY, GameConfig.COLOR_BROWN))

	var choice_names: Dictionary = {
		GameConfig.VOICE_CHOICE_UNSET: "Sorulsun",
		GameConfig.VOICE_CHOICE_JOIN: "Katıl",
		GameConfig.VOICE_CHOICE_LISTEN: "Sadece Dinle",
		GameConfig.VOICE_CHOICE_NO: "Hayır",
	}
	var cycle: Array[String] = [GameConfig.VOICE_CHOICE_JOIN, GameConfig.VOICE_CHOICE_LISTEN, GameConfig.VOICE_CHOICE_NO]
	var choice_row: Dictionary = {}
	var made: Dictionary = _row(body, "Katılım", "Katıl: konuş ve dinle. Mikrofon izni yalnızca Katıl'da istenir.",
		func() -> Array:
			return [str(choice_names.get(AudioManager.vc_choice, "Sorulsun")), AudioManager.vc_choice == GameConfig.VOICE_CHOICE_JOIN],
		func() -> void:
			var idx: int = cycle.find(AudioManager.vc_choice)
			var next_c: String = cycle[(idx + 1) % cycle.size()]
			AudioManager.set_vc_choice(next_c)
			if next_c == GameConfig.VOICE_CHOICE_JOIN:
				VoiceChat.request_mic_permission(host.get_tree(), func(granted: bool) -> void:
					if not granted:
						AudioManager.set_vc_choice(GameConfig.VOICE_CHOICE_LISTEN)
					if choice_row.has("refresh"):
						(choice_row["refresh"] as Callable).call()
				)
	)
	choice_row["refresh"] = made["refresh"]
	_row(body, "Konuşma şekli", "Otomatik: konuşunca açılır. Bas-Konuş: butonu basılı tut.",
		func() -> Array:
			return ["Bas-Konuş" if AudioManager.vc_talk_mode == GameConfig.VOICE_TALK_PTT else "Otomatik", true],
		func() -> void:
			AudioManager.set_vc_talk_mode(GameConfig.VOICE_TALK_AUTO if AudioManager.vc_talk_mode == GameConfig.VOICE_TALK_PTT else GameConfig.VOICE_TALK_PTT)
	)

	# Ses etkinliği eşiği + canlı seviye çubuğu ("Dene" ile mikrofon açılır, hiçbir şey gönderilmez)
	var vad_lbl: Label = _hint("Ses etkinliği eşiği (sarı çizgi): konuşunca çubuk çizgiyi geçmeli.", GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT)
	body.add_child(vad_lbl)
	var meter_row: HBoxContainer = HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(meter_row)
	var bar: LevelBar = LevelBar.new()
	bar.name = "VoiceLevelBar"
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter_row.add_child(bar)
	var test_btn: Button = Button.new()
	test_btn.name = "VoiceTestButton"
	test_btn.custom_minimum_size = Vector2(120.0, ROW_BTN_H)
	meter_row.add_child(test_btn)
	var test_state: Dictionary = {"vc": null}
	var test_refresh: Callable = func() -> void:
		var on: bool = test_state["vc"] != null
		test_btn.text = "Durdur" if on else "Dene"
		ComicUiHelper.style_bitten_button(test_btn, GameConfig.COLOR_GREEN_GO if on else COLOR_OFF, AssetHelper.get_ui_font(), GameConfig.FS_SMALL, 880)
	test_refresh.call()
	test_btn.pressed.connect(func() -> void:
		if test_state["vc"] != null:
			(test_state["vc"] as VoiceChat).queue_free()
			test_state["vc"] = null
			bar.vc = null
			test_refresh.call()
			return
		VoiceChat.request_mic_permission(host.get_tree(), func(granted: bool) -> void:
			if not granted or not is_instance_valid(bar):
				return
			var tvc: VoiceChat = VoiceChat.new()
			tvc.test_mode = true
			bar.add_child(tvc)
			test_state["vc"] = tvc
			bar.vc = tvc
			test_refresh.call()
		)
	)
	body.add_child(_slider(GameConfig.VOICE_CHAT_VAD_MIN, GameConfig.VOICE_CHAT_VAD_MAX, 0.01, AudioManager.vc_vad_threshold,
		func(v: float) -> void: AudioManager.set_vc_vad_threshold(v)))

	var vol_lbl: Label = _hint("Sesli sohbet ses seviyesi: %%%d" % int(roundf(AudioManager.vc_volume * 100.0)), GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT)
	body.add_child(vol_lbl)
	body.add_child(_slider(0.0, 1.0, 0.05, AudioManager.vc_volume, func(v: float) -> void:
		AudioManager.set_vc_volume(v)
		vol_lbl.text = "Sesli sohbet ses seviyesi: %%%d" % int(roundf(v * 100.0))
	))
	_row(body, "Yankı önleme", "Kulaklıksız oynarken açık kalsın. Kulaklık takıyorsan kapatabilirsin.",
		func() -> Array: return ["Açık" if AudioManager.vc_echo_gate else "Kapalı", AudioManager.vc_echo_gate],
		func() -> void: AudioManager.set_vc_echo_gate(not AudioManager.vc_echo_gate)
	)
	_row(body, "Arkadaşları böcek sesiyle duy", "Gelen her ses konuşanın böceğinin perdesiyle çalar.",
		func() -> Array: return ["Açık" if AudioManager.vc_bug_listen else "Kapalı", AudioManager.vc_bug_listen],
		func() -> void: AudioManager.set_vc_bug_listen(not AudioManager.vc_bug_listen)
	)
	body.add_child(_hint(GameConfig.VOICE_ECHO_HINT, GameConfig.FS_TINY, GameConfig.COLOR_BROWN))


## Kişiye özel: sesli sohbette sustur + ses seviyesi. Engellenen kişi otomatik susturulur.
static func open_peer_modal(parent: Node, pid: int) -> Control:
	var p_name: String = str((NetworkManager.players.get(pid, {}) as Dictionary).get("name", "Böcek"))
	var m: Dictionary = ComicUiHelper.build_modal(parent, "SES", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalVoicePeer"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer
	var name_lbl: Label = Label.new()
	name_lbl.text = p_name
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ComicUiHelper.style_label(name_lbl, GameConfig.FS_H2, GameConfig.COLOR_INK, true)
	body.add_child(name_lbl)
	if NetworkManager.is_peer_blocked(pid):
		body.add_child(_hint("Bu kişiyi engelledin: sesi hiç çalınmaz.", GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED))
	else:
		_row(body, "Sustur", "Bu oturum boyunca sesi, lafları ve özel sesleri çalmaz.",
			func() -> Array:
				var muted: bool = NetworkManager.is_peer_muted(pid)
				return ["Susturuldu" if muted else "Açık", not muted],
			func() -> void: NetworkManager.toggle_mute_peer(pid)
		)
		var vol_lbl: Label = _hint("Bu kişinin sesi: %%%d" % int(roundf(NetworkManager.get_voice_peer_volume(pid) * 100.0)), GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT)
		body.add_child(vol_lbl)
		var sl: HSlider = _slider(0.0, 1.0, 0.05, NetworkManager.get_voice_peer_volume(pid), func(v: float) -> void:
			NetworkManager.set_voice_peer_volume(pid, v)
			vol_lbl.text = "Bu kişinin sesi: %%%d" % int(roundf(v * 100.0))
		)
		sl.name = "PeerVolumeSlider"
		body.add_child(sl)
	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return root


## "Herkesi sustur" düğmesi (lobi ve oyuncular penceresi).
static func build_mute_all_button(height: float) -> Button:
	var b: Button = Button.new()
	b.name = "VoiceMuteAllButton"
	b.custom_minimum_size = Vector2(0.0, height)
	b.clip_text = true
	var refresh: Callable = func() -> void:
		var on: bool = NetworkManager.voice_mute_all
		b.text = "Herkesi aç" if on else "Herkesi sustur"
		ComicUiHelper.style_bitten_button(b, GameConfig.COLOR_DUST_BLUE if on else COLOR_OFF, AssetHelper.get_ui_font(), GameConfig.FS_SMALL, 881)
	refresh.call()
	b.pressed.connect(func() -> void:
		NetworkManager.set_voice_mute_all(not NetworkManager.voice_mute_all)
		if is_instance_valid(b):
			refresh.call()
	)
	return b


## Lobi: oda sahibi anahtarları (yalnızca sahip) ve tek satırlık sesli sohbet paneli: mikrofon ikonu,
## durum yazısı ya da büyük Bas-Konuş butonu, "Herkesi sustur". "Herkes Böcek Sesiyle" açıkken panel
## sarı şeride döner ve dalga ikonunun yanında anten görünür.
## Dönen kutunun "refresh" meta'sı oyuncu listesi değişince çağrılır.
static func build_lobby_box(vc: VoiceChat, btn_h: float) -> VBoxContainer:
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "VoiceChatBox"
	box.add_theme_constant_override("separation", GameConfig.SP_XS)
	var font: Font = AssetHelper.get_ui_font()

	var owner_row: HBoxContainer = HBoxContainer.new()
	owner_row.name = "VoiceOwnerRow"
	owner_row.add_theme_constant_override("separation", GameConfig.SP_S)
	var chat_btn: Button = Button.new()
	chat_btn.name = "RoomVoiceChatButton"
	var bug_btn: Button = Button.new()
	bug_btn.name = "RoomBugVoiceButton"
	for b: Button in [chat_btn, bug_btn]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0.0, btn_h)
		b.clip_text = true
		owner_row.add_child(b)
	chat_btn.pressed.connect(func() -> void:
		NetworkManager.request_room_voice_chat.rpc_id(1, not NetworkManager.room_voice_chat_enabled, NetworkManager.room_bug_voice_forced)
	)
	bug_btn.pressed.connect(func() -> void:
		NetworkManager.request_room_voice_chat.rpc_id(1, NetworkManager.room_voice_chat_enabled, not NetworkManager.room_bug_voice_forced)
	)
	box.add_child(owner_row)

	var panel: PanelContainer = PanelContainer.new()
	panel.name = "VoiceUserPanel"
	var panel_sb: StyleBoxFlat = StyleBoxFlat.new()
	panel_sb.border_color = GameConfig.COLOR_INK
	panel_sb.set_border_width_all(2)
	panel_sb.set_corner_radius_all(16)
	panel_sb.content_margin_left = 8.0
	panel_sb.content_margin_right = 8.0
	panel_sb.content_margin_top = 4.0
	panel_sb.content_margin_bottom = 4.0
	panel.add_theme_stylebox_override("panel", panel_sb)
	var user_row: HBoxContainer = HBoxContainer.new()
	user_row.name = "VoiceUserRow"
	user_row.add_theme_constant_override("separation", GameConfig.SP_S)
	panel.add_child(user_row)
	var mic: MicIcon = MicIcon.new(vc, 48.0)
	mic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	user_row.add_child(mic)
	var wave: WaveIcon = WaveIcon.new(Vector2(40.0, 26.0))
	wave.name = "BugVoiceWave"
	wave.antenna = true
	wave.active = true
	wave.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	user_row.add_child(wave)
	var ptt: PttButton = PttButton.new(vc, Vector2(0.0, GameConfig.VOICE_LOBBY_PTT_H), true)
	ptt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	user_row.add_child(ptt)
	var status: Label = Label.new()
	status.name = "VoiceStatusLabel"
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(status, GameConfig.FS_TINY, GameConfig.COLOR_INK, false)
	user_row.add_child(status)
	var mute_all: Button = build_mute_all_button(btn_h - 4.0)
	mute_all.custom_minimum_size.x = 190.0
	mute_all.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	user_row.add_child(mute_all)
	box.add_child(panel)

	var refresh: Callable = func() -> void:
		var allowed: bool = VoiceChat.ui_available() and NetworkManager.voice_chat_room_allowed()
		box.visible = allowed
		if not allowed:
			return
		var is_owner: bool = NetworkManager.is_room_owner()
		var active: bool = NetworkManager.room_voice_chat_enabled
		var forced: bool = active and NetworkManager.room_bug_voice_forced
		owner_row.visible = is_owner and not NetworkManager.in_match
		chat_btn.text = "Sesli Sohbet: %s" % ("Açık" if active else "Kapalı")
		bug_btn.text = "Herkes Böcek Sesiyle: %s" % ("Açık" if NetworkManager.room_bug_voice_forced else "Kapalı")
		ComicUiHelper.style_bitten_button(chat_btn, GameConfig.COLOR_GREEN_GO if active else COLOR_OFF, font, GameConfig.FS_SMALL, 882)
		ComicUiHelper.style_bitten_button(bug_btn, GameConfig.COLOR_GOLD if NetworkManager.room_bug_voice_forced else COLOR_OFF, font, GameConfig.FS_SMALL, 883)
		bug_btn.disabled = not active
		panel_sb.bg_color = GameConfig.COLOR_GOLD if forced else Color(GameConfig.COLOR_CREAM, 0.94)
		wave.visible = forced
		var mode: int = vc.local_mode() if vc != null and is_instance_valid(vc) else GameConfig.VOICE_MODE_OFF
		var talk: bool = active and mode == GameConfig.VOICE_MODE_TALK
		mic.visible = talk
		ptt.visible = talk and vc.is_ptt_mode() and not vc.self_muted
		status.visible = not ptt.visible
		mute_all.visible = active and mode >= GameConfig.VOICE_MODE_LISTEN
		var txt: String = ""
		if not active:
			txt = "Oda sahibi sesli sohbeti kapattı."
		elif mode == GameConfig.VOICE_MODE_OFF:
			txt = "Sesli sohbete katılmadın (Ayarlar)."
		elif mode == GameConfig.VOICE_MODE_LISTEN:
			txt = "Sesli sohbeti dinliyorsun."
		elif vc.self_muted:
			txt = "Mikrofonun kapalı. Açmak için ikona dokun."
		else:
			txt = "Konuşunca mikrofon açılır."
		if forced:
			txt = "Herkes böcek sesiyle! " + txt
		status.text = txt
	box.set_meta("refresh", refresh)
	if vc != null:
		vc.state_changed.connect(func() -> void:
			if is_instance_valid(box):
				refresh.call()
		)
	refresh.call()
	return box


# ---------------------------------------------------------------------------
# Yardımcılar
# ---------------------------------------------------------------------------

static func _hint(text: String, fs: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(l, fs, col, false)
	return l


## Ayar satırı: solda başlık + açıklama, sağda durum düğmesi. {refresh} döner.
static func _row(parent: Control, title: String, sub: String, state_fn: Callable, press_fn: Callable) -> Dictionary:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	parent.add_child(row)
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var t: Label = _hint(title, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT)
	info.add_child(t)
	if not sub.is_empty():
		info.add_child(_hint(sub, GameConfig.FS_TINY, GameConfig.COLOR_BROWN))
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(ROW_BTN_W, ROW_BTN_H)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.clip_text = true
	row.add_child(btn)
	var refresh: Callable = func() -> void:
		if not is_instance_valid(btn):
			return
		var st: Array = state_fn.call() as Array
		btn.text = str(st[0])
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO if bool(st[1]) else COLOR_OFF, AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
	refresh.call()
	btn.pressed.connect(func() -> void:
		press_fn.call()
		refresh.call()
	)
	return {"row": row, "button": btn, "refresh": refresh}


static func _slider(min_v: float, max_v: float, step: float, value: float, on_change: Callable) -> HSlider:
	var slider: HSlider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.step = step
	slider.value = value
	slider.custom_minimum_size = Vector2(0.0, 44.0)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = COLOR_OFF
	track.border_color = GameConfig.COLOR_INK
	track.set_border_width_all(2)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0
	var fill: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	fill.bg_color = GameConfig.COLOR_GREEN_GO
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.value_changed.connect(func(v: float) -> void: on_change.call(v))
	return slider

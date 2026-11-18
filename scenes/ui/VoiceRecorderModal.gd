class_name VoiceRecorderModal
extends Node

## Faz 11.7: Ayarlar → "Benim Lafım" kayıt ekranı. 3 yuva (Laf atma / Sataşma / Zafer);
## büyük mikrofon butonu basılı tutulunca en fazla 2.0 sn kaydeder, canlı dalga formu çizer;
## kayıttan sonra sessizlik kırpılır ve normalize edilir. Dinle (ham), Böcek Sesiyle Dinle, Kaydet, Sil.
## Mikrofon yalnızca buton basılıyken açıktır; Android izni yalnızca ilk basışta istenir.

const MIC_BTN_H: float = 120.0
const WAVE_H: float = 96.0
const ACTION_BTN_H: float = 56.0
const ANDROID_MIC_PERMISSION: String = "android.permission.RECORD_AUDIO"
const MSG_DENIED: String = "Mikrofon izni verilmedi. Benim Lafım kapalı kalacak; oyunun geri kalanı etkilenmez. İstersen telefonun Ayarlar > Uygulamalar bölümünden izin verebilirsin."


## Mikrofon simgesi (kapsül + ayak), kayıtta kırmızı.
class MicIcon extends Control:
	var active: bool = false

	func _init() -> void:
		custom_minimum_size = Vector2(44.0, 56.0)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var ink: Color = GameConfig.COLOR_INK
		var fill: Color = GameConfig.COLOR_CREAM if not active else GameConfig.COLOR_WARN_RED
		var cap: StyleBoxFlat = StyleBoxFlat.new()
		cap.bg_color = fill
		cap.border_color = ink
		cap.set_border_width_all(3)
		cap.set_corner_radius_all(int(w * 0.25))
		var cap_rect: Rect2 = Rect2(w * 0.28, 2.0, w * 0.44, h * 0.58)
		draw_style_box(cap, cap_rect)
		var cx: float = w * 0.5
		var arc_c: Vector2 = Vector2(cx, h * 0.40)
		draw_arc(arc_c, w * 0.36, 0.15, PI - 0.15, 18, ink, 3.0, true)
		draw_line(Vector2(cx, arc_c.y + w * 0.36), Vector2(cx, h - 6.0), ink, 3.0, true)
		draw_line(Vector2(cx - w * 0.2, h - 4.0), Vector2(cx + w * 0.2, h - 4.0), ink, 3.0, true)


## Dalga formu: kayıtta canlı sütunlar, sonra taslağın/kaydın zarfı.
class WaveView extends Control:
	var bars: PackedFloat32Array = PackedFloat32Array()
	var live: bool = false
	var progress: float = 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(0.0, VoiceRecorderModal.WAVE_H)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var bg: StyleBoxFlat = StyleBoxFlat.new()
		bg.bg_color = Color("#FFF8EC")
		bg.border_color = Color(GameConfig.COLOR_BROWN, 0.5)
		bg.set_border_width_all(2)
		bg.set_corner_radius_all(14)
		draw_style_box(bg, Rect2(Vector2.ZERO, size))
		var mid: float = size.y * 0.5
		var n: int = GameConfig.VOICE_WAVE_BARS
		var inner_w: float = size.x - 20.0
		var step: float = inner_w / float(n)
		draw_line(Vector2(10.0, mid), Vector2(size.x - 10.0, mid), Color(GameConfig.COLOR_BROWN, 0.25), 2.0)
		var col: Color = GameConfig.COLOR_WARN_RED if live else GameConfig.COLOR_GREEN_GO.darkened(0.25)
		for i: int in range(mini(n, bars.size())):
			var a: float = clampf(bars[i], 0.0, 1.0)
			var bh: float = maxf(3.0, a * (size.y - 18.0))
			var x: float = 10.0 + step * (float(i) + 0.5)
			draw_line(Vector2(x, mid - bh * 0.5), Vector2(x, mid + bh * 0.5), col, maxf(2.0, step * 0.55), true)
		if live:
			var px: float = 10.0 + inner_w * clampf(progress, 0.0, 1.0)
			draw_line(Vector2(px, 6.0), Vector2(px, size.y - 6.0), GameConfig.COLOR_INK, 2.0)


var _slot: String = "laf"
var _drafts: Dictionary = {} # yuva -> PackedFloat32Array (kaydedilmemiş)
var _recording: bool = false
var _rec_time: float = 0.0
var _mic_player: AudioStreamPlayer = null
var _live: PackedFloat32Array = PackedFloat32Array()
var _perm_requested: bool = false
var _perm_denied: bool = false
var _waiting_perm: bool = false

var _tabs: Dictionary = {} # yuva -> Button
var _hint_lbl: Label = null
var _mic_btn: Button = null
var _mic_icon: MicIcon = null
var _mic_lbl: Label = null
var _wave: WaveView = null
var _status_lbl: Label = null
var _msg_lbl: Label = null
var _play_btn: Button = null
var _bug_btn: Button = null
var _save_btn: Button = null
var _del_btn: Button = null


## Pencereyi açar; kök düğüm "ModalBenimLafim" (Android Geri tuşu kapatır).
static func open(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "BENİM LAFIM", GameConfig.COLOR_CREAM, 0.0, false)
	var root: Control = m["root"] as Control
	root.name = "ModalBenimLafim"
	var rec: VoiceRecorderModal = VoiceRecorderModal.new()
	rec.name = "Recorder"
	root.add_child(rec)
	rec._build(m)
	return root


func _build(m: Dictionary) -> void:
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()

	var intro: Label = _label("Kendi sesinle 2 saniyelik laf kaydet. Yalnızca arkadaş odalarında (Özel Oda ve LAN) duyulur.", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(intro)

	var tab_row: HBoxContainer = HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(tab_row)
	for slot: String in GameConfig.VOICE_SLOTS:
		var t: Button = Button.new()
		t.name = "Tab_%s" % slot
		t.text = str(GameConfig.VOICE_SLOT_NAMES[slot])
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size = Vector2(0.0, 52.0)
		t.clip_text = true
		var cap: String = slot
		t.pressed.connect(func() -> void: _select_slot(cap))
		tab_row.add_child(t)
		_tabs[slot] = t

	_hint_lbl = _label("", GameConfig.FS_SMALL, GameConfig.COLOR_INK, false)
	body.add_child(_hint_lbl)

	_mic_btn = Button.new()
	_mic_btn.name = "MicButton"
	_mic_btn.custom_minimum_size = Vector2(0.0, MIC_BTN_H)
	_mic_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	_mic_btn.focus_mode = Control.FOCUS_NONE
	ComicUiHelper.style_bitten_button(_mic_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 870)
	var mic_box: HBoxContainer = HBoxContainer.new()
	mic_box.alignment = BoxContainer.ALIGNMENT_CENTER
	mic_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mic_box.add_theme_constant_override("separation", GameConfig.SP_S)
	_mic_btn.add_child(mic_box)
	_mic_icon = MicIcon.new()
	_mic_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mic_box.add_child(_mic_icon)
	_mic_lbl = _label("Basılı tut, konuş", GameConfig.FS_BUTTON, GameConfig.COLOR_INK, true)
	_mic_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	_mic_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mic_box.add_child(_mic_lbl)
	_mic_btn.button_down.connect(_on_mic_down)
	_mic_btn.button_up.connect(_on_mic_up)
	body.add_child(_mic_btn)

	_wave = WaveView.new()
	_wave.name = "Wave"
	body.add_child(_wave)

	_status_lbl = _label("", GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	_status_lbl.name = "Status"
	body.add_child(_status_lbl)

	var grid: GridContainer = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GameConfig.SP_S)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_S)
	body.add_child(grid)
	_play_btn = _action_button(grid, "Dinle", GameConfig.COLOR_DUST_BLUE, 871)
	_bug_btn = _action_button(grid, "Böcek Sesiyle Dinle", GameConfig.COLOR_GOLD, 872)
	_save_btn = _action_button(grid, "Kaydet", GameConfig.COLOR_GREEN_GO, 873)
	_del_btn = _action_button(grid, "Sil", GameConfig.COLOR_DUST_PINK, 874)
	_play_btn.pressed.connect(func() -> void: _play(false))
	_bug_btn.pressed.connect(func() -> void: _play(true))
	_save_btn.pressed.connect(_save_current)
	_del_btn.pressed.connect(_delete_current)

	_msg_lbl = _label("", GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED, false)
	_msg_lbl.name = "Message"
	_msg_lbl.visible = false
	body.add_child(_msg_lbl)

	body.add_child(_label("Mikrofon yalnızca butonu basılı tuttuğunda açılır. Kayıt bu cihazda saklanır, Hızlı Oyun'da asla gönderilmez.", GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false))

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 60.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 875)
	var root: Control = m["root"] as Control
	close_btn.pressed.connect(root.queue_free)
	(m["footer"] as VBoxContainer).add_child(close_btn)

	tree_exiting.connect(_shutdown_mic)
	_select_slot(_slot)


func _label(text: String, size: int, color: Color, bold: bool) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_label(l, size, color, bold)
	return l


func _action_button(parent: Control, text: String, color: Color, seed_val: int) -> Button:
	var b: Button = Button.new()
	b.text = text
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.custom_minimum_size = Vector2(0.0, ACTION_BTN_H)
	b.clip_text = true
	ComicUiHelper.style_bitten_button(b, color, AssetHelper.get_ui_font(), GameConfig.FS_SMALL, seed_val)
	parent.add_child(b)
	return b


func _select_slot(slot: String) -> void:
	if _recording:
		return
	_slot = slot
	for s: String in _tabs.keys():
		ComicUiHelper.style_tab(_tabs[s] as Button, s == _slot, GameConfig.FS_SMALL)
	_hint_lbl.text = str(GameConfig.VOICE_SLOT_HINTS[_slot])
	_hide_msg()
	_refresh()


## Seçili yuvanın çalınacak örnekleri: önce kaydedilmemiş taslak, yoksa dosya.
func _current_samples() -> PackedFloat32Array:
	if _drafts.has(_slot):
		return _drafts[_slot] as PackedFloat32Array
	var s: AudioStreamWAV = VoiceClip.load_slot(_slot)
	if s == null:
		return PackedFloat32Array()
	return VoiceClip.wav_to_mono(s)


func _refresh() -> void:
	var samples: PackedFloat32Array = _current_samples()
	var saved: bool = VoiceClip.has_slot(_slot)
	var draft: bool = _drafts.has(_slot)
	var secs: float = float(samples.size()) / float(GameConfig.VOICE_STORE_RATE)
	if draft:
		_status_lbl.text = "Yeni kayıt: %.1f sn. Beğendiysen Kaydet'e bas." % secs
	elif saved:
		_status_lbl.text = "Kayıtlı: %.1f sn." % secs
	else:
		_status_lbl.text = "Bu yuva boş."
	_wave.live = false
	_wave.bars = VoiceClip.peaks(samples, GameConfig.VOICE_WAVE_BARS)
	_wave.queue_redraw()
	var has_any: bool = not samples.is_empty()
	_play_btn.disabled = not has_any
	_bug_btn.disabled = not has_any
	_save_btn.disabled = not draft
	_del_btn.disabled = not (draft or saved)
	_mic_btn.disabled = _perm_denied
	_mic_lbl.text = "Basılı tut, konuş" if not _perm_denied else "Mikrofon kapalı"
	_mic_icon.active = false
	_mic_icon.queue_redraw()


func _show_msg(text: String, warn: bool = true) -> void:
	_msg_lbl.text = text
	ComicUiHelper.style_label(_msg_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED if warn else GameConfig.COLOR_GREEN_GO.darkened(0.35), false)
	_msg_lbl.visible = true


func _hide_msg() -> void:
	if _msg_lbl != null:
		_msg_lbl.visible = false


# ---------------------------------------------------------------------------
# İzin ve kayıt
# ---------------------------------------------------------------------------

func _on_mic_down() -> void:
	if _perm_denied or _recording:
		return
	if OS.get_name() == "Android" and not _android_mic_granted():
		_ask_android_permission()
		return
	_start_recording()


func _on_mic_up() -> void:
	if _recording:
		_stop_recording()


func _android_mic_granted() -> bool:
	return OS.get_granted_permissions().has(ANDROID_MIC_PERMISSION)


## İzin yalnızca burada, kullanıcı mikrofon butonuna ilk bastığında istenir.
func _ask_android_permission() -> void:
	if _waiting_perm:
		return
	if _perm_requested:
		# Daha önce sorulup reddedildiyse tekrar sormadan kapat
		_on_permission_result(ANDROID_MIC_PERMISSION, _android_mic_granted())
		return
	_perm_requested = true
	_waiting_perm = true
	var tree: SceneTree = get_tree()
	if not tree.on_request_permissions_result.is_connected(_on_permission_result):
		tree.on_request_permissions_result.connect(_on_permission_result)
	_show_msg("Mikrofon izni isteniyor...", false)
	if OS.request_permission(ANDROID_MIC_PERMISSION):
		# Zaten verilmiş
		_on_permission_result(ANDROID_MIC_PERMISSION, true)


func _on_permission_result(permission: String, granted: bool) -> void:
	if not permission.ends_with("RECORD_AUDIO"):
		return
	_waiting_perm = false
	if granted:
		_show_msg("İzin verildi. Şimdi butonu basılı tutup konuş.", false)
	else:
		_perm_denied = true
		_show_msg(MSG_DENIED)
	_refresh()


func _start_recording() -> void:
	_hide_msg()
	AudioManager.stop_custom_voices()
	var record: AudioEffectRecord = AudioManager.get_mic_record()
	var capture: AudioEffectCapture = AudioManager.get_mic_capture()
	if record == null or capture == null:
		_show_msg("Mikrofon başlatılamadı.")
		return
	capture.clear_buffer()
	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "MicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = StringName(GameConfig.VOICE_MIC_BUS)
	add_child(_mic_player)
	_mic_player.play()
	record.set_recording_active(true)
	_recording = true
	_rec_time = 0.0
	_live = PackedFloat32Array()
	_live.resize(GameConfig.VOICE_WAVE_BARS)
	_mic_icon.active = true
	_mic_icon.queue_redraw()
	_wave.live = true
	_set_tabs_disabled(true)


func _stop_recording() -> void:
	if not _recording:
		return
	_recording = false
	var record: AudioEffectRecord = AudioManager.get_mic_record()
	var wav: AudioStreamWAV = null
	if record != null:
		record.set_recording_active(false)
		wav = record.get_recording()
	_shutdown_mic()
	_set_tabs_disabled(false)
	finish_recording_with(wav)


## Kaydı işler (mono, 16 kHz, kırpma, normalize) ve taslak yapar. Testler sentetik WAV ile çağırır.
func finish_recording_with(wav: AudioStreamWAV) -> bool:
	var samples: PackedFloat32Array = VoiceClip.process_recording(wav)
	if samples.is_empty():
		_refresh()
		_show_msg("Ses duyulmadı ya da çok kısa. Biraz daha yüksek sesle tekrar dene.")
		return false
	_drafts[_slot] = samples
	_refresh()
	return true


## Mikrofon akışını kapatır (pencere kapanınca da).
func _shutdown_mic() -> void:
	if _mic_player != null and is_instance_valid(_mic_player):
		_mic_player.stop()
		_mic_player.queue_free()
	_mic_player = null
	if _recording:
		_recording = false
		var record: AudioEffectRecord = AudioManager.get_mic_record()
		if record != null:
			record.set_recording_active(false)


func _set_tabs_disabled(v: bool) -> void:
	for s: String in _tabs.keys():
		(_tabs[s] as Button).disabled = v


func _process(delta: float) -> void:
	if not _recording:
		return
	_rec_time += delta
	var capture: AudioEffectCapture = AudioManager.get_mic_capture()
	if capture != null:
		var n: int = capture.get_frames_available()
		if n > 0:
			var buf: PackedVector2Array = capture.get_buffer(n)
			var mx: float = 0.0
			for f: Vector2 in buf:
				mx = maxf(mx, maxf(absf(f.x), absf(f.y)))
			var idx: int = clampi(int(_rec_time / GameConfig.VOICE_MAX_SEC * float(GameConfig.VOICE_WAVE_BARS)), 0, GameConfig.VOICE_WAVE_BARS - 1)
			_live[idx] = maxf(_live[idx], minf(1.0, mx * 1.6))
	_wave.bars = _live
	_wave.progress = _rec_time / GameConfig.VOICE_MAX_SEC
	_wave.queue_redraw()
	_mic_lbl.text = "Kaydediyor %.1f / %.1f" % [minf(_rec_time, GameConfig.VOICE_MAX_SEC), GameConfig.VOICE_MAX_SEC]
	if _rec_time >= GameConfig.VOICE_MAX_SEC:
		_stop_recording()


# ---------------------------------------------------------------------------
# Dinle / Kaydet / Sil
# ---------------------------------------------------------------------------

func _play(bug_voice: bool) -> void:
	var samples: PackedFloat32Array = _current_samples()
	if samples.is_empty():
		return
	var s: AudioStreamWAV = VoiceClip.make_stream(samples, GameConfig.VOICE_STORE_RATE)
	if bug_voice:
		AudioManager.play_custom_voice(s, NetworkManager.selected_char_id)
	else:
		AudioManager.play_raw_voice(s)


func _save_current() -> void:
	if not _drafts.has(_slot):
		return
	var err: Error = VoiceClip.save_slot(_slot, _drafts[_slot] as PackedFloat32Array)
	if err != OK:
		_show_msg("Kaydedilemedi (hata %d)." % err)
		return
	_drafts.erase(_slot)
	NetworkManager.invalidate_own_voices()
	_refresh()
	_show_msg("Kaydedildi! %s yuvası hazır." % str(GameConfig.VOICE_SLOT_NAMES[_slot]), false)


func _delete_current() -> void:
	_drafts.erase(_slot)
	VoiceClip.delete_slot(_slot)
	NetworkManager.invalidate_own_voices()
	AudioManager.stop_custom_voices()
	_refresh()
	_show_msg("Silindi.", false)

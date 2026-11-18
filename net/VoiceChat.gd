class_name VoiceChat
extends Node

## Faz 13A: Sesli sohbet katmanı (autoload değil; Lobby ve GameWorld'e eklenen düğüm).
## Mikrofon -> TwoVoip Opus kodlayıcı (RnNoise) -> ağ (NetworkManager, kanal 3) -> titreşim tamponu
## -> konuşan başına AudioStreamOpus oynatıcı ve "VoiceChat_<peer>" alt bus'ı (böcek sesi için PitchShift).
## TwoVoip eklentisi yoksa hiçbir şey yapmaz; eklenti sınıflarına statik tipli başvuru yoktur
## (yalnızca ClassDB / call), böylece eklenti olmadan da betik derlenir.

signal speaking_changed(pid: int, active: bool)
signal state_changed

const ENCODER_CLASS: String = "TwovoipOpusEncoder"
const STREAM_CLASS: String = "AudioStreamOpus"
const MIC_PERMISSION: String = "android.permission.RECORD_AUDIO"

## Yalnızca test / ekran görüntüsü: eklenti yokken de arayüzü gösterir (ses işlenmez).
static var ui_preview: bool = false

## Katılma penceresi bu düğümün bulunduğu ekranda açılabilir mi (lobi evet, maç hayır).
var prompt_enabled: bool = false
## Pencerelerin açılacağı düğüm (boşsa üst düğüm).
var ui_parent: Node = null
## Ayarlar ekranındaki canlı seviye çubuğu: mikrofon açılır ama hiçbir şey gönderilmez.
var test_mode: bool = false

var self_muted: bool = false
var ptt_held: bool = false
var mic_level: float = 0.0
var local_talking: bool = false
var frames_encoded: int = 0
var frames_decoded: int = 0
var frames_dropped: int = 0

var _encoder: Object = null
var _encoder_failed: bool = false
var _chunk_frames: int = 0
var _mic_active: bool = false
var _seq: int = 0
var _hang_until_ms: int = 0
var _echo_until_ms: int = 0
var _in_background: bool = false
var _speakers: Dictionary = {} # pid -> {player, playback, jitter, bus, pitch, last_ms, speaking, open}
var _join_modal: Control = null
var _permission_waiting: bool = false
var _ducking: bool = false


## TwoVoip yüklü mü (Opus kodlayıcı ve çalıcı sınıfları)?
static func is_supported() -> bool:
	return ClassDB.class_exists(ENCODER_CLASS) and ClassDB.class_exists(STREAM_CLASS)


## Sesli sohbet arayüzü gösterilsin mi (eklenti var ya da önizleme)?
static func ui_available() -> bool:
	return is_supported() or ui_preview


## Mikrofon izni var mı (Android dışında her zaman var sayılır)?
static func has_mic_permission() -> bool:
	if OS.get_name() != "Android":
		return true
	return OS.get_granted_permissions().has(MIC_PERMISSION)


## Mikrofon iznini (gerekiyorsa) ister; sonuç cb(granted: bool) ile döner.
static func request_mic_permission(tree: SceneTree, cb: Callable) -> void:
	if has_mic_permission():
		cb.call(true)
		return
	if OS.request_permission(MIC_PERMISSION):
		cb.call(true)
		return
	tree.on_request_permissions_result.connect(func(permission: String, granted: bool) -> void:
		if permission == MIC_PERMISSION:
			cb.call(granted)
	, CONNECT_ONE_SHOT)


## Ağ paketi: [bayrak][sıra LE 2 bayt][Opus]. Sunucu bu baytları çözmez.
static func build_packet(seq: int, payload: PackedByteArray, is_end: bool) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(GameConfig.VOICE_CHAT_HEADER)
	out[0] = GameConfig.VOICE_CHAT_FLAG_END if is_end else 0
	out[1] = seq & 0xFF
	out[2] = (seq >> 8) & 0xFF
	out.append_array(payload)
	return out


## Paketi ayrıştırır: {seq, end, payload}; geçersizse boş sözlük.
static func parse_packet(data: PackedByteArray) -> Dictionary:
	if data.size() < GameConfig.VOICE_CHAT_HEADER or data.size() > GameConfig.VOICE_CHAT_MAX_BYTES:
		return {}
	var flags: int = data[0]
	if flags & ~GameConfig.VOICE_CHAT_FLAG_END != 0:
		return {}
	return {
		"seq": int(data[1]) | (int(data[2]) << 8),
		"end": (flags & GameConfig.VOICE_CHAT_FLAG_END) != 0,
		"payload": data.slice(GameConfig.VOICE_CHAT_HEADER),
	}


## Ham mikrofon parçasının tepe değeri (0..1).
static func peak_of(frames: PackedVector2Array) -> float:
	var p: float = 0.0
	for f: Vector2 in frames:
		p = maxf(p, maxf(absf(f.x), absf(f.y)))
	return p


## Yankı önleme açıkken eşik (hoparlörden sohbet sesi çalıyorsa yükseltilir).
static func effective_threshold(base: float, echo_active: bool) -> float:
	return base * GameConfig.VOICE_CHAT_ECHO_MULT if echo_active else base


## Oyuncunun seçimine, izne ve odaya göre sesli sohbet kipi.
static func compute_mode(room_active: bool, supported: bool, choice: String, permission: bool) -> int:
	if not room_active or not supported:
		return GameConfig.VOICE_MODE_OFF
	if choice == GameConfig.VOICE_CHOICE_JOIN:
		return GameConfig.VOICE_MODE_TALK if permission else GameConfig.VOICE_MODE_LISTEN
	if choice == GameConfig.VOICE_CHOICE_LISTEN:
		return GameConfig.VOICE_MODE_LISTEN
	return GameConfig.VOICE_MODE_OFF


func _ready() -> void:
	name = "VoiceChat"
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not test_mode:
		NetworkManager.voice_chat_packet.connect(_on_packet)
		NetworkManager.voice_chat_state_changed.connect(_refresh)
		NetworkManager.players_updated.connect(_refresh)
	_refresh.call_deferred()


func _exit_tree() -> void:
	_set_mic_active(false)
	for pid_v: Variant in _speakers.keys():
		_remove_speaker(int(pid_v))
	if _ducking:
		AudioManager.set_voice_duck(false)
		_ducking = false
	if not test_mode and is_instance_valid(NetworkManager):
		NetworkManager.set_local_voice_mode(GameConfig.VOICE_MODE_OFF)


func _notification(what: int) -> void:
	var to_bg: bool = what == NOTIFICATION_APPLICATION_PAUSED or (OS.has_feature("mobile") and what == NOTIFICATION_APPLICATION_FOCUS_OUT)
	var to_fg: bool = what == NOTIFICATION_APPLICATION_RESUMED or (OS.has_feature("mobile") and what == NOTIFICATION_APPLICATION_FOCUS_IN)
	if to_bg:
		# Arka plana alınınca mikrofon anında kapanır
		_in_background = true
		ptt_held = false
		_set_mic_active(false)
		state_changed.emit()
	elif to_fg and _in_background:
		_in_background = false
		_refresh()


## Bu odada sesli sohbet arayüzü görünsün mü?
func room_active() -> bool:
	if test_mode:
		return ui_available()
	return ui_available() and NetworkManager.voice_chat_active()


## Yerel kip (0 kapalı, 1 dinliyor, 2 konuşabilir).
func local_mode() -> int:
	if test_mode:
		return GameConfig.VOICE_MODE_TALK if has_mic_permission() else GameConfig.VOICE_MODE_OFF
	return compute_mode(NetworkManager.voice_chat_active(), is_supported() or ui_preview, AudioManager.vc_choice, has_mic_permission())


func is_ptt_mode() -> bool:
	return AudioManager.vc_talk_mode == GameConfig.VOICE_TALK_PTT


## Mikrofon şu an dinleniyor mu (HUD ikonu: gri / yeşil)?
func mic_open() -> bool:
	return _mic_active


func toggle_self_mute() -> void:
	self_muted = not self_muted
	_refresh()


func set_ptt(held: bool) -> void:
	if ptt_held == held:
		return
	ptt_held = held and not _in_background
	_refresh()


## Konuşan bu an konuşuyor mu (ağız / dalga / kart parlaması)?
func is_speaking(pid: int) -> bool:
	if pid == _my_pid():
		return local_talking
	var sp: Dictionary = _speakers.get(pid, {}) as Dictionary
	return bool(sp.get("speaking", false))


## Katılma penceresinden ya da ayarlardan seçim. "Katıl" gerekiyorsa mikrofon izni ister;
## izin verilmezse "Sadece Dinle" ile devam eder.
func choose(choice: String) -> void:
	if choice != GameConfig.VOICE_CHOICE_JOIN:
		AudioManager.set_vc_choice(choice)
		_refresh()
		return
	AudioManager.set_vc_choice(GameConfig.VOICE_CHOICE_JOIN)
	if not is_supported():
		_refresh()
		return
	_permission_waiting = true
	request_mic_permission(get_tree(), func(granted: bool) -> void:
		_permission_waiting = false
		if not granted:
			AudioManager.set_vc_choice(GameConfig.VOICE_CHOICE_LISTEN)
		if is_inside_tree():
			_refresh()
	)


func _my_pid() -> int:
	return NetworkManager._local_pid()


## Kip ve mikrofon durumunu yeniden hesaplar (ağ durumu / ayar / izin değişince).
func _refresh() -> void:
	if not is_inside_tree():
		return
	var mode: int = local_mode()
	if not test_mode:
		NetworkManager.set_local_voice_mode(mode)
		# Ayrılan oyuncunun bus'ı silinir
		for pid_v: Variant in _speakers.keys():
			var pid: int = int(pid_v)
			if not NetworkManager.players.has(pid) or not NetworkManager.voice_peer_audible(pid) or mode < GameConfig.VOICE_MODE_LISTEN:
				_remove_speaker(pid)
			else:
				_apply_speaker_settings(pid)
		if prompt_enabled and room_active() and AudioManager.vc_choice == GameConfig.VOICE_CHOICE_UNSET:
			_open_join_prompt()
	var want_mic: bool = mode == GameConfig.VOICE_MODE_TALK and is_supported() and not self_muted \
		and not _in_background and (test_mode or not is_ptt_mode() or ptt_held)
	if not test_mode and not NetworkManager.voice_chat_can_send():
		want_mic = false
	_set_mic_active(want_mic)
	state_changed.emit()


func _open_join_prompt() -> void:
	if _join_modal != null and is_instance_valid(_join_modal):
		return
	var parent: Node = ui_parent if ui_parent != null else get_parent()
	if parent == null:
		return
	_join_modal = VoiceChatUi.open_join_modal(parent, self)


# ---------------------------------------------------------------------------
# Mikrofon ve kodlama
# ---------------------------------------------------------------------------

func _set_mic_active(on: bool) -> void:
	if on == _mic_active:
		return
	if on:
		if not _ensure_encoder():
			return
		if AudioServer.set_input_device_active(true) != OK:
			return
		_mic_active = true
		_hang_until_ms = 0
	else:
		_end_talk_spurt()
		_mic_active = false
		mic_level = 0.0
		AudioServer.set_input_device_active(false)


## TwoVoip kodlayıcısını kurar: 48 kHz mono, 20 ms, RnNoise gürültü filtresi (yoksa filtresiz).
func _ensure_encoder() -> bool:
	if _encoder != null:
		return true
	if _encoder_failed or not is_supported():
		return false
	var enc: Object = ClassDB.instantiate(ENCODER_CLASS)
	if enc == null:
		_encoder_failed = true
		return false
	var frame_n: int = GameConfig.VOICE_CHAT_OPUS_RATE * GameConfig.VOICE_CHAT_FRAME_MS / 1000
	var mix_rate: int = int(AudioServer.get_input_mix_rate())
	var agc: int = _class_const("AGC_DISABLED", 0)
	var err: int = int(enc.call("initialize", mix_rate, GameConfig.VOICE_CHAT_OPUS_RATE, 1, _class_const("RNNOISE", 0), agc, frame_n))
	if err != OK:
		err = int(enc.call("initialize", mix_rate, GameConfig.VOICE_CHAT_OPUS_RATE, 1, _class_const("DENOISER_DISABLED", 0), agc, frame_n))
	if err != OK or not bool(enc.call("create_opus_encoder", GameConfig.VOICE_CHAT_BITRATE, GameConfig.VOICE_CHAT_COMPLEXITY, true)):
		push_warning("Sesli sohbet: TwoVoip kodlayıcı kurulamadı (%d)." % err)
		_encoder_failed = true
		return false
	_chunk_frames = int(enc.call("get_required_input_chunk_size"))
	if _chunk_frames <= 0:
		_encoder_failed = true
		return false
	_encoder = enc
	return true


## Kodlayıcı sınıfındaki sabiti adına göre bulur (örn. "RNNOISE" -> DENOISER_RNNOISE).
func _class_const(fragment: String, fallback: int) -> int:
	for c: String in ClassDB.class_get_integer_constant_list(ENCODER_CLASS, true):
		if c == fragment or c.ends_with("_" + fragment) or (fragment == "RNNOISE" and c.contains("RNNOISE")):
			return ClassDB.class_get_integer_constant(ENCODER_CLASS, c)
	return fallback


func _process(_delta: float) -> void:
	var now_ms: int = Time.get_ticks_msec()
	_update_echo(now_ms)
	if _mic_active:
		_pump_mic(now_ms)
	_pump_speakers(now_ms)


func _update_echo(now_ms: int) -> void:
	if not AudioManager.vc_echo_gate:
		_echo_until_ms = 0
		return
	var idx: int = AudioServer.get_bus_index(GameConfig.VOICE_CHAT_BUS)
	if idx < 0:
		return
	var db: float = maxf(AudioServer.get_bus_peak_volume_left_db(idx, 0), AudioServer.get_bus_peak_volume_right_db(idx, 0))
	if db > GameConfig.VOICE_CHAT_ECHO_DB:
		_echo_until_ms = now_ms + GameConfig.VOICE_CHAT_ECHO_HOLD_MS


## Yarı çift yönlü kapı açık mı (hoparlörden sohbet sesi çalıyor)?
func echo_gate_active() -> bool:
	return Time.get_ticks_msec() < _echo_until_ms


func _pump_mic(now_ms: int) -> void:
	if _encoder == null:
		return
	var threshold: float = effective_threshold(AudioManager.vc_vad_threshold, echo_gate_active())
	var guard: int = 0
	while guard < 16:
		guard += 1
		var frames: PackedVector2Array = AudioServer.get_input_frames(_chunk_frames)
		if frames.is_empty():
			break
		if int(_encoder.call("process_chunk", frames)) < 0:
			break
		var peak: float = float(_encoder.call("get_peak"))
		mic_level = maxf(peak, mic_level * 0.85)
		var talking: bool = false
		if is_ptt_mode() and not test_mode:
			talking = ptt_held
		else:
			if peak >= threshold:
				_hang_until_ms = now_ms + GameConfig.VOICE_CHAT_VAD_HANG_MS
			talking = now_ms < _hang_until_ms
		if test_mode:
			_set_local_talking(talking)
			continue
		if talking and not local_talking:
			_encoder.call("reset_opus_encoder")
			_set_local_talking(true)
		elif not talking and local_talking:
			_end_talk_spurt()
		if local_talking:
			var opus: PackedByteArray = _encoder.call("encode_chunk", PackedByteArray(), 0) as PackedByteArray
			if not opus.is_empty() and opus.size() <= GameConfig.VOICE_CHAT_MAX_BYTES - GameConfig.VOICE_CHAT_HEADER:
				NetworkManager.send_voice_frame(build_packet(_seq, opus, false))
				_seq = (_seq + 1) & 0xFFFF
				frames_encoded += 1


## Konuşma bitti: alıcıların akışı kapansın diye bitiş işareti (boş parça).
func _end_talk_spurt() -> void:
	if not local_talking:
		return
	if not test_mode:
		NetworkManager.send_voice_frame(build_packet(_seq, PackedByteArray(), true))
		_seq = (_seq + 1) & 0xFFFF
	_set_local_talking(false)


func _set_local_talking(on: bool) -> void:
	if local_talking == on:
		return
	local_talking = on
	speaking_changed.emit(_my_pid(), on)


# ---------------------------------------------------------------------------
# Çalma: konuşan başına oynatıcı + alt bus, titreşim tamponu, ducking
# ---------------------------------------------------------------------------

func _on_packet(sender_id: int, data: PackedByteArray) -> void:
	if not is_supported() or local_mode() < GameConfig.VOICE_MODE_LISTEN:
		return
	var pkt: Dictionary = parse_packet(data)
	if pkt.is_empty():
		frames_dropped += 1
		return
	var sp: Dictionary = _ensure_speaker(sender_id)
	if sp.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	(sp["jitter"] as VoiceJitterBuffer).push(int(pkt["seq"]), pkt["payload"] as PackedByteArray, bool(pkt["end"]), now_ms)
	if not bool(pkt["end"]):
		sp["last_ms"] = now_ms


func _ensure_speaker(pid: int) -> Dictionary:
	if _speakers.has(pid):
		return _speakers[pid] as Dictionary
	if _speakers.size() >= GameConfig.NET_MAX_CLIENTS + 1:
		return {}
	var stream: Object = ClassDB.instantiate(STREAM_CLASS)
	if stream == null or not (stream is AudioStream):
		return {}
	stream.set("opus_sample_rate", GameConfig.VOICE_CHAT_OPUS_RATE)
	stream.set("opus_channels", 1)
	var bus_name: String = GameConfig.VOICE_CHAT_PEER_BUS_PREFIX + str(pid)
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		AudioManager.ensure_voice_chat_bus()
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, GameConfig.VOICE_CHAT_BUS)
		var fx: AudioEffectPitchShift = AudioEffectPitchShift.new()
		AudioServer.add_bus_effect(idx, fx)
	var player: AudioStreamPlayer = AudioStreamPlayer.new()
	player.name = "VoicePeer_%d" % pid
	player.bus = bus_name
	player.stream = stream as AudioStream
	add_child(player)
	var sp: Dictionary = {
		"player": player,
		"playback": null,
		"jitter": VoiceJitterBuffer.new(),
		"bus": bus_name,
		"last_ms": 0,
		"speaking": false,
		"open": false,
	}
	_speakers[pid] = sp
	_apply_speaker_settings(pid)
	return sp


## Kişiye özel ses seviyesi ve böcek sesi (dinleyici ayarı ya da oda zorunluluğu) perdesi.
func _apply_speaker_settings(pid: int) -> void:
	var sp: Dictionary = _speakers.get(pid, {}) as Dictionary
	if sp.is_empty():
		return
	var player: AudioStreamPlayer = sp["player"] as AudioStreamPlayer
	var vol: float = NetworkManager.get_voice_peer_volume(pid)
	player.volume_db = linear_to_db(maxf(vol, 0.001))
	var idx: int = AudioServer.get_bus_index(str(sp["bus"]))
	if idx < 0 or AudioServer.get_bus_effect_count(idx) == 0:
		return
	var bug: bool = NetworkManager.room_bug_voice_forced or AudioManager.vc_bug_listen
	var c_id: String = str((NetworkManager.players.get(pid, {}) as Dictionary).get("char_id", "klasik"))
	var fx: AudioEffectPitchShift = AudioServer.get_bus_effect(idx, 0) as AudioEffectPitchShift
	if fx != null:
		fx.pitch_scale = clampf(CharacterData.get_voice_pitch(c_id) * GameConfig.VOICE_CHAT_BUG_PITCH_MULT, 0.5, 2.5)
	AudioServer.set_bus_effect_enabled(idx, 0, bug)
	AudioServer.set_bus_mute(idx, vol <= 0.01)


## Konuşan için kullanılan perde (testler ve arayüz için); böcek sesi kapalıysa 1.0.
func speaker_pitch(pid: int) -> float:
	var sp: Dictionary = _speakers.get(pid, {}) as Dictionary
	if sp.is_empty():
		return 1.0
	var idx: int = AudioServer.get_bus_index(str(sp["bus"]))
	if idx < 0 or not AudioServer.is_bus_effect_enabled(idx, 0):
		return 1.0
	return (AudioServer.get_bus_effect(idx, 0) as AudioEffectPitchShift).pitch_scale


func _remove_speaker(pid: int) -> void:
	var sp: Dictionary = _speakers.get(pid, {}) as Dictionary
	_speakers.erase(pid)
	if sp.is_empty():
		return
	var player: AudioStreamPlayer = sp["player"] as AudioStreamPlayer
	if is_instance_valid(player):
		player.stop()
		player.queue_free()
	var idx: int = AudioServer.get_bus_index(str(sp["bus"]))
	if idx > 0:
		AudioServer.remove_bus(idx)
	if bool(sp["speaking"]):
		speaking_changed.emit(pid, false)


func _pump_speakers(now_ms: int) -> void:
	var any_speaking: bool = false
	for pid_v: Variant in _speakers.keys():
		var pid: int = int(pid_v)
		var sp: Dictionary = _speakers[pid] as Dictionary
		var jitter: VoiceJitterBuffer = sp["jitter"] as VoiceJitterBuffer
		var frames: Array[PackedByteArray] = jitter.pop_ready(now_ms)
		if not frames.is_empty():
			_feed_decoder(sp, frames)
		elif bool(sp["open"]) and not jitter.is_open():
			# Konuşma bitti: kalan sesi çal, sonra duraklat
			sp["open"] = false
			var pb: Object = sp["playback"] as Object
			if pb != null and pb.has_method("mark_end_opus_stream"):
				pb.call("mark_end_opus_stream", false)
		var speaking: bool = now_ms - int(sp["last_ms"]) <= GameConfig.VOICE_CHAT_SPEAK_HOLD_MS
		if speaking != bool(sp["speaking"]):
			sp["speaking"] = speaking
			speaking_changed.emit(pid, speaking)
		any_speaking = any_speaking or speaking
	if any_speaking != _ducking:
		_ducking = any_speaking
		AudioManager.set_voice_duck(any_speaking)


func _feed_decoder(sp: Dictionary, frames: Array[PackedByteArray]) -> void:
	var player: AudioStreamPlayer = sp["player"] as AudioStreamPlayer
	var pb: Object = sp["playback"] as Object
	if not player.playing or pb == null:
		player.play()
		pb = player.get_stream_playback()
		sp["playback"] = pb
	if pb == null or not pb.has_method("push_opus_packet"):
		return
	if not bool(sp["open"]):
		sp["open"] = true
		if pb.has_method("mark_end_opus_stream"):
			pb.call("mark_end_opus_stream", true)
	for f: PackedByteArray in frames:
		if pb.has_method("queue_length_frames"):
			var q_ms: int = int(pb.call("queue_length_frames")) * 1000 / GameConfig.VOICE_CHAT_OPUS_RATE
			if q_ms > GameConfig.VOICE_CHAT_MAX_QUEUE_MS:
				# Gecikme birikmesin: parça atılır (çalma hızı değiştirilmez)
				frames_dropped += 1
				continue
		pb.call("push_opus_packet", f, 0, 0)
		frames_decoded += 1

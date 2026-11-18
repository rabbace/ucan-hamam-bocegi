extends Node

## Ses yöneticisi: 8'li SFX havuzu, müzik oynatıcı, önbellek ve titreşim ayarları.

const SFX_POOL_SIZE: int = 8

var is_muted: bool = false
var is_vibration_enabled: bool = true
var is_censor_enabled: bool = false
var guide_seen: bool = false
var _seen_tips: Dictionary = {}
var control_scheme: String = "swipe" # "swipe" | "buttons"
var left_handed: bool = false
var button_scale: float = 1.0
var assist_mode: bool = false
var voice_volume: float = 1.0
## Faz 11.3: Ölüm Karesi yakalama (zayıf telefonlarda kapatılabilir)
var death_card_enabled: bool = true
## Faz 11.7: arkadaşların özel seslerini (Benim Lafım) çal
var friend_voices_enabled: bool = true
## Faz 13A: sesli sohbet ayarları (settings.cfg [voice_chat])
var vc_choice: String = GameConfig.VOICE_CHOICE_UNSET
var vc_talk_mode: String = GameConfig.VOICE_TALK_AUTO
var vc_vad_threshold: float = GameConfig.VOICE_CHAT_VAD_DEFAULT
var vc_volume: float = 1.0
var vc_echo_gate: bool = true
var vc_bug_listen: bool = false

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_index: int = 0
var _music_player: AudioStreamPlayer = null
var _death_music_player: AudioStreamPlayer = null
var _voice_player: AudioStreamPlayer = null
var _voice_pitch_fx: AudioEffectPitchShift = null
var _custom_voice_player: AudioStreamPlayer = null
var _raw_voice_player: AudioStreamPlayer = null
var _death_music_tween: Tween = null
var _current_music_path: String = ""
var _sound_cache: Dictionary = {}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _duck_amount: float = 0.0
var _duck_target: float = 0.0
var _music_base_db: float = 0.0
var _sfx_base_db: float = 0.0


func _ready() -> void:
	_rng.randomize()
	for i: int in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)

	_death_music_player = AudioStreamPlayer.new()
	_death_music_player.bus = &"Music"
	add_child(_death_music_player)

	_setup_voice_bus()
	var m_idx: int = AudioServer.get_bus_index("Music")
	var s_idx: int = AudioServer.get_bus_index("SFX")
	_music_base_db = AudioServer.get_bus_volume_db(m_idx) if m_idx >= 0 else 0.0
	_sfx_base_db = AudioServer.get_bus_volume_db(s_idx) if s_idx >= 0 else 0.0
	load_audio_settings()
	ensure_voice_chat_bus()


func _setup_voice_bus() -> void:
	var v_idx: int = AudioServer.get_bus_index("Voice")
	if v_idx < 0:
		AudioServer.add_bus()
		v_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(v_idx, "Voice")
		AudioServer.set_bus_send(v_idx, "Master")
	_voice_pitch_fx = AudioEffectPitchShift.new()
	_voice_pitch_fx.pitch_scale = 1.15
	AudioServer.add_bus_effect(v_idx, _voice_pitch_fx)
	AudioServer.add_bus_effect(v_idx, AudioEffectCompressor.new())
	AudioServer.add_bus_effect(v_idx, AudioEffectEQ.new())

	_voice_player = AudioStreamPlayer.new()
	_voice_player.bus = &"Voice"
	add_child(_voice_player)
	_custom_voice_player = AudioStreamPlayer.new()
	_custom_voice_player.bus = &"Voice"
	add_child(_custom_voice_player)
	_raw_voice_player = AudioStreamPlayer.new()
	_raw_voice_player.bus = &"SFX"
	add_child(_raw_voice_player)


## Faz 11.7: özel sesi karakterin böcek filtresiyle (Voice bus, voice_pitch) çalar.
func play_custom_voice(stream: AudioStream, char_id: String) -> void:
	if stream == null or is_muted or voice_volume <= 0.01:
		return
	if _voice_pitch_fx != null:
		_voice_pitch_fx.pitch_scale = CharacterData.get_voice_pitch(char_id) * GameConfig.VOICE_BUG_PITCH_MULT
	_custom_voice_player.stream = stream
	_custom_voice_player.play()


## Faz 11.7: kaydı filtresiz (ham) çalar; yalnızca Benim Lafım ekranında.
func play_raw_voice(stream: AudioStream) -> void:
	if stream == null or is_muted:
		return
	_raw_voice_player.stream = stream
	_raw_voice_player.play()


func stop_custom_voices() -> void:
	_custom_voice_player.stop()
	_raw_voice_player.stop()


## Faz 11.7: mikrofon bus'ı (sessiz; önce canlı dalga için Capture, sonra Record). Yalnızca kayıt ekranı çağırır.
func ensure_mic_bus() -> int:
	var idx: int = AudioServer.get_bus_index(GameConfig.VOICE_MIC_BUS)
	if idx >= 0:
		return idx
	AudioServer.add_bus()
	idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, GameConfig.VOICE_MIC_BUS)
	AudioServer.set_bus_send(idx, "Master")
	# Kendi sesini hoparlörden duymasın: bus sessiz, efektler yine de çalışır
	AudioServer.set_bus_mute(idx, true)
	var cap: AudioEffectCapture = AudioEffectCapture.new()
	cap.buffer_length = 0.5
	AudioServer.add_bus_effect(idx, cap)
	AudioServer.add_bus_effect(idx, AudioEffectRecord.new())
	return idx


func get_mic_capture() -> AudioEffectCapture:
	var idx: int = ensure_mic_bus()
	return AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture


func get_mic_record() -> AudioEffectRecord:
	var idx: int = ensure_mic_bus()
	return AudioServer.get_bus_effect(idx, 1) as AudioEffectRecord


## 9.6: Karakter sesini Voice bus üzerinden karakterin pitch değeriyle çalar.
func play_character_voice(char_id: String, clip_name: String) -> void:
	if is_muted or voice_volume <= 0.01:
		return
	var stream: AudioStream = null
	for ext: String in [".ogg", ".wav"]:
		var path: String = "res://assets/sounds/chars/%s/%s%s" % [char_id, clip_name, ext]
		stream = _get_cached_sound(path)
		if stream != null:
			break
	if stream == null:
		return
	if _voice_pitch_fx != null:
		_voice_pitch_fx.pitch_scale = CharacterData.get_voice_pitch(char_id)
	_voice_player.stream = stream
	_voice_player.play()


## Ses ve titreşim ayarlarını config dosyasından yükler.
func load_audio_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(GameConfig.SETTINGS_PATH)
	if err == OK:
		is_muted = bool(cfg.get_value("audio", "muted", false))
		is_vibration_enabled = bool(cfg.get_value("audio", "vibration", true))
		is_censor_enabled = bool(cfg.get_value("audio", "censor", false))
		guide_seen = bool(cfg.get_value("guide", "guide_seen", false))
		_seen_tips = cfg.get_value("guide", "seen_tips", {}) as Dictionary
		control_scheme = str(cfg.get_value("controls", "scheme", "swipe"))
		left_handed = bool(cfg.get_value("controls", "left_handed", false))
		button_scale = clampf(float(cfg.get_value("controls", "button_scale", 1.0)), 0.8, 1.3)
		assist_mode = bool(cfg.get_value("controls", "assist_mode", false))
		voice_volume = clampf(float(cfg.get_value("audio", "voice_volume", 1.0)), 0.0, 1.0)
		death_card_enabled = bool(cfg.get_value("game", "death_card", true))
		friend_voices_enabled = bool(cfg.get_value("audio", "friend_voices", true))
		var ch: String = str(cfg.get_value("voice_chat", "choice", GameConfig.VOICE_CHOICE_UNSET))
		vc_choice = ch if [GameConfig.VOICE_CHOICE_JOIN, GameConfig.VOICE_CHOICE_LISTEN, GameConfig.VOICE_CHOICE_NO].has(ch) else GameConfig.VOICE_CHOICE_UNSET
		vc_talk_mode = GameConfig.VOICE_TALK_PTT if str(cfg.get_value("voice_chat", "mode", GameConfig.VOICE_TALK_AUTO)) == GameConfig.VOICE_TALK_PTT else GameConfig.VOICE_TALK_AUTO
		vc_vad_threshold = clampf(float(cfg.get_value("voice_chat", "vad", GameConfig.VOICE_CHAT_VAD_DEFAULT)), GameConfig.VOICE_CHAT_VAD_MIN, GameConfig.VOICE_CHAT_VAD_MAX)
		vc_volume = clampf(float(cfg.get_value("voice_chat", "volume", 1.0)), 0.0, 1.0)
		vc_echo_gate = bool(cfg.get_value("voice_chat", "echo_gate", true))
		vc_bug_listen = bool(cfg.get_value("voice_chat", "bug_listen", false))
	_apply_mute_state()


func save_control_settings(scheme: String, is_left: bool, btn_sc: float, assist: bool) -> void:
	control_scheme = scheme
	left_handed = is_left
	button_scale = clampf(btn_sc, 0.8, 1.3)
	assist_mode = assist
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("controls", "scheme", control_scheme)
	cfg.set_value("controls", "left_handed", left_handed)
	cfg.set_value("controls", "button_scale", button_scale)
	cfg.set_value("controls", "assist_mode", assist_mode)
	cfg.save(GameConfig.SETTINGS_PATH)


func set_voice_volume(vol: float) -> void:
	voice_volume = clampf(vol, 0.0, 1.0)
	var v_idx: int = AudioServer.get_bus_index("Voice")
	if v_idx >= 0:
		AudioServer.set_bus_volume_db(v_idx, linear_to_db(maxf(voice_volume, 0.001)))
		AudioServer.set_bus_mute(v_idx, voice_volume <= 0.01)
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("audio", "voice_volume", voice_volume)
	cfg.save(GameConfig.SETTINGS_PATH)


## Argo sansürünü açıp kapatır ve kaydeder.
func set_censor_enabled(enabled: bool) -> void:
	is_censor_enabled = enabled
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("audio", "censor", is_censor_enabled)
	cfg.save(GameConfig.SETTINGS_PATH)


## Rehberin görüldüğünü kaydeder.
func mark_guide_seen() -> void:
	guide_seen = true
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("guide", "guide_seen", true)
	cfg.save(GameConfig.SETTINGS_PATH)


func has_seen_tip(key: String) -> bool:
	return bool(_seen_tips.get(key, false))


func mark_tip_seen(key: String) -> void:
	_seen_tips[key] = true
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("guide", "seen_tips", _seen_tips)
	cfg.save(GameConfig.SETTINGS_PATH)


## Sesi açıp kapatır ve ayarlara kaydeder.
func set_muted(muted: bool) -> void:
	is_muted = muted
	_apply_mute_state()
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("audio", "muted", is_muted)
	cfg.save(GameConfig.SETTINGS_PATH)


## Titreşimi açıp kapatır ve ayarlara kaydeder.
func set_vibration_enabled(enabled: bool) -> void:
	is_vibration_enabled = enabled
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("audio", "vibration", is_vibration_enabled)
	cfg.save(GameConfig.SETTINGS_PATH)


## Ölüm Karesi yakalamayı açıp kapatır ve kaydeder.
func set_death_card_enabled(enabled: bool) -> void:
	death_card_enabled = enabled
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("game", "death_card", death_card_enabled)
	cfg.save(GameConfig.SETTINGS_PATH)


## Faz 11.7: arkadaşların özel seslerini çalma ayarı.
func set_friend_voices_enabled(enabled: bool) -> void:
	friend_voices_enabled = enabled
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("audio", "friend_voices", friend_voices_enabled)
	cfg.save(GameConfig.SETTINGS_PATH)


# ---------------------------------------------------------------------------
# Faz 13A: sesli sohbet ayarları, bus'ı ve ducking
# ---------------------------------------------------------------------------

## Sesli sohbet ayarlarını settings.cfg [voice_chat] bölümüne yazar.
func save_voice_chat_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("voice_chat", "choice", vc_choice)
	cfg.set_value("voice_chat", "mode", vc_talk_mode)
	cfg.set_value("voice_chat", "vad", vc_vad_threshold)
	cfg.set_value("voice_chat", "volume", vc_volume)
	cfg.set_value("voice_chat", "echo_gate", vc_echo_gate)
	cfg.set_value("voice_chat", "bug_listen", vc_bug_listen)
	cfg.save(GameConfig.SETTINGS_PATH)


func set_vc_choice(choice: String) -> void:
	if not [GameConfig.VOICE_CHOICE_UNSET, GameConfig.VOICE_CHOICE_JOIN, GameConfig.VOICE_CHOICE_LISTEN, GameConfig.VOICE_CHOICE_NO].has(choice):
		return
	vc_choice = choice
	save_voice_chat_settings()


func set_vc_talk_mode(mode: String) -> void:
	vc_talk_mode = GameConfig.VOICE_TALK_PTT if mode == GameConfig.VOICE_TALK_PTT else GameConfig.VOICE_TALK_AUTO
	save_voice_chat_settings()


func set_vc_vad_threshold(v: float) -> void:
	vc_vad_threshold = clampf(v, GameConfig.VOICE_CHAT_VAD_MIN, GameConfig.VOICE_CHAT_VAD_MAX)
	save_voice_chat_settings()


func set_vc_volume(v: float) -> void:
	vc_volume = clampf(v, 0.0, 1.0)
	_apply_vc_volume()
	save_voice_chat_settings()


func set_vc_echo_gate(on: bool) -> void:
	vc_echo_gate = on
	save_voice_chat_settings()


func set_vc_bug_listen(on: bool) -> void:
	vc_bug_listen = on
	save_voice_chat_settings()


## Sesli sohbet ana bus'ı (konuşan başına alt bus'lar buraya gönderir).
func ensure_voice_chat_bus() -> int:
	var idx: int = AudioServer.get_bus_index(GameConfig.VOICE_CHAT_BUS)
	if idx < 0:
		AudioServer.add_bus()
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, GameConfig.VOICE_CHAT_BUS)
		AudioServer.set_bus_send(idx, "Master")
	_apply_vc_volume()
	return idx


func _apply_vc_volume() -> void:
	var idx: int = AudioServer.get_bus_index(GameConfig.VOICE_CHAT_BUS)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(vc_volume, 0.001)))
	AudioServer.set_bus_mute(idx, vc_volume <= 0.01)


## Biri konuşurken müzik -6 dB, efekt -3 dB; bitince 0.4 sn'de geri gelir.
func set_voice_duck(active: bool) -> void:
	_duck_target = 1.0 if active else 0.0
	set_process(true)


func duck_amount() -> float:
	return _duck_amount


func _process(delta: float) -> void:
	if is_equal_approx(_duck_amount, _duck_target):
		set_process(false)
		return
	var dur: float = GameConfig.VOICE_CHAT_DUCK_IN_SEC if _duck_target > _duck_amount else GameConfig.VOICE_CHAT_DUCK_OUT_SEC
	_duck_amount = move_toward(_duck_amount, _duck_target, delta / maxf(dur, 0.01))
	var m_idx: int = AudioServer.get_bus_index("Music")
	var s_idx: int = AudioServer.get_bus_index("SFX")
	if m_idx >= 0:
		AudioServer.set_bus_volume_db(m_idx, _music_base_db + GameConfig.VOICE_CHAT_DUCK_MUSIC_DB * _duck_amount)
	if s_idx >= 0:
		AudioServer.set_bus_volume_db(s_idx, _sfx_base_db + GameConfig.VOICE_CHAT_DUCK_SFX_DB * _duck_amount)


func _apply_mute_state() -> void:
	AudioServer.set_bus_mute(0, is_muted)


## Karaktere göre elenme sesini çalar (8.8: kufur.ogg artık çalınmaz).
func play_death_sfx(char_id: String) -> void:
	if char_id == "diva":
		var idx: int = _rng.randi_range(1, 3)
		play_sfx("res://assets/sounds/diva_kufur_%d.wav" % idx, 0.96, 1.05)


## 8.8: Ölüm müziğini çalar (yerel: tam 6 sn, uzak: ilk 2 sn -10 dB).
func play_death_music(is_local: bool) -> void:
	var path: String = "res://assets/sounds/olum_muzigi.ogg"
	var stream: AudioStream = _get_cached_sound(path)
	if stream == null:
		return
	if not is_local and _death_music_player.playing:
		return
	if _death_music_tween != null and _death_music_tween.is_valid():
		_death_music_tween.kill()

	_death_music_player.stream = stream
	if is_local:
		_death_music_player.volume_db = 0.0
		_death_music_player.play()
		_death_music_tween = create_tween()
		_death_music_tween.tween_property(_music_player, "volume_db", -24.0, 0.3)
		_death_music_tween.tween_interval(GameConfig.DEATH_MUSIC_MAX)
		_death_music_tween.tween_property(_death_music_player, "volume_db", -40.0, 1.0)
		_death_music_tween.parallel().tween_property(_music_player, "volume_db", 0.0, 1.0)
		_death_music_tween.tween_callback(func() -> void:
			_death_music_player.stop()
		)
	else:
		_death_music_player.volume_db = -10.0
		_death_music_player.play()
		_death_music_tween = create_tween()
		_death_music_tween.tween_interval(2.0)
		_death_music_tween.tween_property(_death_music_player, "volume_db", -40.0, 0.5)
		_death_music_tween.tween_callback(func() -> void:
			_death_music_player.stop()
		)


func stop_death_music() -> void:
	if _death_music_tween != null and _death_music_tween.is_valid():
		_death_music_tween.kill()
	if _death_music_player != null:
		_death_music_player.stop()
	if _music_player != null:
		_music_player.volume_db = 0.0


## Karaktere göre kazanma sesini çalar (Diva için kadın sesi).
func play_win_sfx(char_id: String) -> void:
	if char_id == "diva":
		var idx: int = _rng.randi_range(1, 2)
		play_sfx("res://assets/sounds/diva_sevinc_%d.wav" % idx, 0.98, 1.04)
	else:
		play_sfx("res://assets/sounds/sevinc_argo.ogg", 0.98, 1.04)


## Efekt sesini havuzdan çalar (dosya yoksa sessizce geçer).
func play_sfx(path: String, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	if is_muted or path.is_empty():
		return
	var stream: AudioStream = _get_cached_sound(path)
	if stream == null:
		return

	var player: AudioStreamPlayer = _sfx_pool[_sfx_index]
	_sfx_index = (_sfx_index + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.pitch_scale = _rng.randf_range(pitch_min, pitch_max)
	player.play()


## Döngülü arka plan müziği çalar (dosya yoksa sessizce geçer).
func play_music(path: String) -> void:
	if path == _current_music_path and _music_player.playing:
		return
	_current_music_path = path
	var stream: AudioStream = _get_cached_sound(path)
	if stream == null:
		_music_player.stop()
		return
	_music_player.stream = stream
	_music_player.play()


## Müziği durdurur.
func stop_music() -> void:
	_current_music_path = ""
	_music_player.stop()


func _get_cached_sound(path: String) -> AudioStream:
	if path.ends_with("kufur.ogg"):
		var death_pool: Array[String] = [
			"res://assets/sounds/kufur_1.wav",
			"res://assets/sounds/kufur_2.wav",
			"res://assets/sounds/kufur_3.wav",
			"res://assets/sounds/kufur_4.wav",
			"res://assets/sounds/kufur_5.wav",
			"res://assets/sounds/kufur_6.wav",
			"res://assets/sounds/kufur_7.wav",
			"res://assets/sounds/kufur_8.wav",
			"res://assets/sounds/gahpe.wav",
			"res://assets/sounds/duktur_yok_mu.wav",
		]
		var pool_path: String = death_pool[_rng.randi_range(0, death_pool.size() - 1)]
		var pool_stream: AudioStream = AssetHelper.sound(pool_path)
		if pool_stream != null:
			return pool_stream
	if path.ends_with("sevinc_argo.ogg"):
		var win_pool: Array[String] = [
			"res://assets/sounds/sevinc_1.wav",
			"res://assets/sounds/sevinc_2.wav",
			"res://assets/sounds/sevinc_3.wav",
			"res://assets/sounds/sevinc_4.wav",
			"res://assets/sounds/makara_1.wav",
			"res://assets/sounds/makara_2.wav",
		]
		var pool_path: String = win_pool[_rng.randi_range(0, win_pool.size() - 1)]
		var pool_stream: AudioStream = AssetHelper.sound(pool_path)
		if pool_stream != null:
			return pool_stream
	if path.ends_with("kufur.ogg") and AssetHelper.sound(path) == null and AssetHelper.sound(path.replace(".ogg", ".wav")) == null:
		if _rng.randf() < 0.35:
			return _synth_tone(1000.0, 1000.0, 1.85, 0.24, false)
		return _synth_tone(320.0, 110.0, 0.42, 0.30, true)
	if _sound_cache.has(path):
		return _sound_cache[path] as AudioStream
	var stream: AudioStream = AssetHelper.sound(path)
	if stream == null:
		var wav_path: String = path.replace(".ogg", ".wav")
		stream = AssetHelper.sound(wav_path)
	if stream == null and not path.contains("muzik_"):
		stream = _build_fallback_sfx(path)
	_sound_cache[path] = stream
	return stream


func _build_fallback_sfx(path: String) -> AudioStream:
	if path.ends_with("ucus.ogg"):
		return _synth_tone(260.0, 420.0, 0.07, 0.22, false)
	if path.ends_with("kufur.ogg"):
		return _synth_tone(320.0, 110.0, 0.42, 0.30, true)
	if path.ends_with("sevinc_argo.ogg"):
		return _synth_fanfare()
	if path.ends_with("aydinlat.ogg"):
		return _synth_tone(220.0, 520.0, 0.30, 0.28, false)
	if path.ends_with("fuze.ogg"):
		return _synth_tone(780.0, 260.0, 0.24, 0.20, false)
	if path.ends_with("terlik_kirildi.ogg"):
		return _synth_tone(480.0, 140.0, 0.12, 0.28, true)
	# Faz 11.6 ani olay sesleri (dosya yoksa)
	if path.ends_with("anahtar.ogg"):
		return _synth_sequence([2400.0, 3100.0, 2700.0, 3300.0, 2500.0], 0.07, 0.16, true)
	if path.ends_with("siren.ogg"):
		return _synth_sequence([660.0, 880.0, 660.0, 880.0], 0.28, 0.18, false)
	if path.ends_with("klik.ogg"):
		return _synth_tone(1800.0, 900.0, 0.05, 0.30, true)
	if path.ends_with("buzdolabi.ogg"):
		return _synth_tone(90.0, 110.0, 0.9, 0.22, true)
	if path.ends_with("kapi_zili.ogg"):
		return _synth_sequence([988.0, 784.0], 0.32, 0.22, false)
	if path.ends_with("ciglik.ogg"):
		return _synth_tone(900.0, 1500.0, 0.45, 0.20, true)
	if path.ends_with("kalkan.ogg") or path.ends_with("kucul.ogg") or path.ends_with("mendil.ogg") or path.ends_with("fren.ogg"):
		return _synth_tone(440.0, 740.0, 0.16, 0.22, false)
	return _synth_tone(520.0, 660.0, 0.12, 0.20, false)


func _synth_tone(freq_start: float, freq_end: float, duration: float, volume: float, noisy: bool) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var count: int = maxi(int(duration * float(mix_rate)), 1)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(count * 2)
	var phase: float = 0.0

	for i: int in range(count):
		var t: float = float(i) / float(count)
		var freq: float = lerpf(freq_start, freq_end, t)
		phase += TAU * freq / float(mix_rate)
		var env: float = (1.0 - t) * (1.0 - t)
		var sample_val: float = sin(phase)
		if noisy:
			sample_val = sample_val * 0.65 + _rng.randf_range(-0.35, 0.35)
		var s16: int = clampi(int(sample_val * env * volume * 32767.0), -32767, 32767)
		bytes.encode_s16(i * 2, s16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav


func _synth_fanfare() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var notes: Array[float] = [523.25, 659.25, 783.99]
	var note_dur: float = 0.13
	var total_samples: int = int(note_dur * float(notes.size()) * float(mix_rate))
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples * 2)
	var phase: float = 0.0
	var samples_per_note: int = int(note_dur * float(mix_rate))

	for i: int in range(total_samples):
		var note_idx: int = mini(i / samples_per_note, notes.size() - 1)
		var local_t: float = float(i % samples_per_note) / float(samples_per_note)
		phase += TAU * notes[note_idx] / float(mix_rate)
		var env: float = 1.0 - local_t * 0.7
		var s16: int = clampi(int(sin(phase) * env * 0.25 * 32767.0), -32767, 32767)
		bytes.encode_s16(i * 2, s16)

	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav


## Ardışık notalardan kısa ses (zil, siren, anahtar şıngırtısı).
func _synth_sequence(freqs: Array[float], note_dur: float, volume: float, noisy: bool) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var per_note: int = maxi(int(note_dur * float(mix_rate)), 1)
	var total: int = per_note * freqs.size()
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total * 2)
	var phase: float = 0.0
	for i: int in range(total):
		var n_idx: int = mini(i / per_note, freqs.size() - 1)
		var lt: float = float(i % per_note) / float(per_note)
		phase += TAU * freqs[n_idx] / float(mix_rate)
		var env: float = (1.0 - lt) * minf(lt * 20.0, 1.0)
		var v: float = sin(phase)
		if noisy:
			v = v * 0.7 + _rng.randf_range(-0.3, 0.3)
		var s16: int = clampi(int(v * env * volume * 32767.0), -32767, 32767)
		bytes.encode_s16(i * 2, s16)
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

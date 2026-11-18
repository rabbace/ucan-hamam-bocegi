class_name VoiceClip
extends RefCounted

## Faz 11.7: "Benim Lafım" ses işleme. Mikrofon kaydını mono'ya çevirir, 16 kHz'e indirir,
## baştaki/sondaki sessizliği kırpar, normalize eder; WAV olarak saklar/okur;
## ağ için 11025 Hz 16 bit PCM + ZSTD paketler ve gelen paketi sınırlarla doğrular.
## Mikrofondan bağımsızdır: birim testleri sentetik PCM ile aynı yolu kullanır.


## AudioStreamWAV (8/16 bit, mono/stereo) verisini [-1, 1] aralığında mono örneklere çevirir.
static func wav_to_mono(wav: AudioStreamWAV) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	if wav == null:
		return out
	var data: PackedByteArray = wav.data
	var channels: int = 2 if wav.stereo else 1
	if wav.format == AudioStreamWAV.FORMAT_16_BITS:
		var frames: int = data.size() / (2 * channels)
		out.resize(frames)
		for i: int in range(frames):
			var acc: float = 0.0
			for c: int in range(channels):
				acc += float(data.decode_s16((i * channels + c) * 2)) / 32768.0
			out[i] = acc / float(channels)
	elif wav.format == AudioStreamWAV.FORMAT_8_BITS:
		var frames8: int = data.size() / channels
		out.resize(frames8)
		for i: int in range(frames8):
			var acc8: float = 0.0
			for c: int in range(channels):
				acc8 += float(data.decode_s8(i * channels + c)) / 128.0
			out[i] = acc8 / float(channels)
	return out


## Doğrusal yeniden örnekleme; indirirken pencere ortalamasıyla basit alçak geçiren süzgeç uygular.
static func resample(samples: PackedFloat32Array, src_rate: int, dst_rate: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	if samples.is_empty() or src_rate <= 0 or dst_rate <= 0:
		return out
	if src_rate == dst_rate:
		return samples.duplicate()
	var ratio: float = float(src_rate) / float(dst_rate)
	var n_out: int = maxi(1, int(floor(float(samples.size()) / ratio)))
	out.resize(n_out)
	var last: int = samples.size() - 1
	var half: int = int(floor(ratio * 0.5))
	for i: int in range(n_out):
		var pos: float = float(i) * ratio
		if ratio > 1.5 and half > 0:
			var center: int = int(pos)
			var a: int = maxi(0, center - half)
			var b: int = mini(last, center + half)
			var acc: float = 0.0
			for k: int in range(a, b + 1):
				acc += samples[k]
			out[i] = acc / float(b - a + 1)
		else:
			var i0: int = mini(int(pos), last)
			var i1: int = mini(i0 + 1, last)
			var f: float = pos - float(i0)
			out[i] = lerpf(samples[i0], samples[i1], f)
	return out


## Baştaki ve sondaki sessizliği kırpar (eşik üstü ilk/son örnek + pay). Hiç ses yoksa boş döner.
static func trim_silence(samples: PackedFloat32Array, rate: int, threshold: float, pad_sec: float) -> PackedFloat32Array:
	var first: int = -1
	var last: int = -1
	for i: int in range(samples.size()):
		if absf(samples[i]) > threshold:
			first = i
			break
	if first < 0:
		return PackedFloat32Array()
	for i: int in range(samples.size() - 1, -1, -1):
		if absf(samples[i]) > threshold:
			last = i
			break
	var pad: int = int(float(rate) * pad_sec)
	var a: int = maxi(0, first - pad)
	var b: int = mini(samples.size(), last + pad + 1)
	return samples.slice(a, b)


## Tepe değeri hedefe çeker (çok sessiz kayıtta en fazla 30 kat yükseltir).
static func normalize(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var out: PackedFloat32Array = samples.duplicate()
	var mx: float = 0.0
	for v: float in samples:
		mx = maxf(mx, absf(v))
	if mx < 0.0001:
		return out
	var gain: float = minf(peak / mx, 30.0)
	for i: int in range(out.size()):
		out[i] = clampf(out[i] * gain, -1.0, 1.0)
	return out


## Mikrofon kaydının tam işleme yolu: mono → en fazla 2.0 sn → 16 kHz → kırp → normalize.
## Kırpmadan sonra çok kısaysa boş döner.
static func process_recording(wav: AudioStreamWAV) -> PackedFloat32Array:
	if wav == null:
		return PackedFloat32Array()
	var src_rate: int = wav.mix_rate
	var mono: PackedFloat32Array = wav_to_mono(wav)
	var max_src: int = int(float(src_rate) * GameConfig.VOICE_MAX_SEC)
	if mono.size() > max_src:
		mono = mono.slice(0, max_src)
	return process_mono(mono, src_rate)


static func process_mono(mono: PackedFloat32Array, src_rate: int) -> PackedFloat32Array:
	var rate: int = GameConfig.VOICE_STORE_RATE
	var down: PackedFloat32Array = resample(mono, src_rate, rate)
	var max_out: int = int(float(rate) * GameConfig.VOICE_MAX_SEC)
	if down.size() > max_out:
		down = down.slice(0, max_out)
	var trimmed: PackedFloat32Array = trim_silence(down, rate, GameConfig.VOICE_SILENCE_THRESHOLD, GameConfig.VOICE_TRIM_PAD_SEC)
	if float(trimmed.size()) < float(rate) * GameConfig.VOICE_MIN_SEC:
		return PackedFloat32Array()
	return normalize(trimmed, GameConfig.VOICE_NORMALIZE_PEAK)


static func pcm16_from_floats(samples: PackedFloat32Array) -> PackedByteArray:
	var out: PackedByteArray = PackedByteArray()
	out.resize(samples.size() * 2)
	for i: int in range(samples.size()):
		out.encode_s16(i * 2, int(roundf(clampf(samples[i], -1.0, 1.0) * 32767.0)))
	return out


static func floats_from_pcm16(bytes: PackedByteArray) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	var n: int = bytes.size() / 2
	out.resize(n)
	for i: int in range(n):
		out[i] = float(bytes.decode_s16(i * 2)) / 32768.0
	return out


## 16 bit mono AudioStreamWAV kurar.
static func make_stream(samples: PackedFloat32Array, rate: int) -> AudioStreamWAV:
	var s: AudioStreamWAV = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = false
	s.data = pcm16_from_floats(samples)
	return s


static func stream_seconds(s: AudioStreamWAV) -> float:
	if s == null or s.mix_rate <= 0:
		return 0.0
	var bps: int = 2 if s.format == AudioStreamWAV.FORMAT_16_BITS else 1
	var ch: int = 2 if s.stereo else 1
	return float(s.data.size()) / float(bps * ch * s.mix_rate)


# ---------------------------------------------------------------------------
# Cihazda saklama (user://benim_lafim_<yuva>.wav)
# ---------------------------------------------------------------------------

static func slot_path(slot: String) -> String:
	return GameConfig.VOICE_FILE_FMT % slot


static func has_slot(slot: String) -> bool:
	return GameConfig.VOICE_SLOTS.has(slot) and FileAccess.file_exists(slot_path(slot))


static func save_slot(slot: String, samples: PackedFloat32Array) -> Error:
	if not GameConfig.VOICE_SLOTS.has(slot) or samples.is_empty():
		return ERR_INVALID_PARAMETER
	return make_stream(samples, GameConfig.VOICE_STORE_RATE).save_to_wav(slot_path(slot))


static func delete_slot(slot: String) -> void:
	if has_slot(slot):
		DirAccess.remove_absolute(slot_path(slot))


## Yuvanın WAV dosyasını okur (16 bit PCM, mono/stereo); bozuk ya da yoksa null.
static func load_slot(slot: String) -> AudioStreamWAV:
	if not has_slot(slot):
		return null
	return load_wav_file(slot_path(slot))


## Küçük RIFF/WAVE okuyucu: yalnızca PCM 16 bit, en fazla 2.0 sn'nin biraz üstü kabul edilir.
static func load_wav_file(path: String) -> AudioStreamWAV:
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF" or bytes.slice(8, 12).get_string_from_ascii() != "WAVE":
		return null
	var pos: int = 12
	var channels: int = 0
	var rate: int = 0
	var bits: int = 0
	var fmt_tag: int = 0
	var pcm: PackedByteArray = PackedByteArray()
	while pos + 8 <= bytes.size():
		var cid: String = bytes.slice(pos, pos + 4).get_string_from_ascii()
		var csize: int = int(bytes.decode_u32(pos + 4))
		var body: int = pos + 8
		if csize < 0 or body + csize > bytes.size():
			csize = bytes.size() - body
		if cid == "fmt " and csize >= 16:
			fmt_tag = bytes.decode_u16(body)
			channels = bytes.decode_u16(body + 2)
			rate = int(bytes.decode_u32(body + 4))
			bits = bytes.decode_u16(body + 14)
		elif cid == "data":
			pcm = bytes.slice(body, body + csize)
		pos = body + csize + (csize % 2)
	if fmt_tag != 1 or bits != 16 or channels < 1 or channels > 2 or rate < 4000 or rate > 96000 or pcm.is_empty():
		return null
	var max_bytes: int = int(float(rate) * (GameConfig.VOICE_MAX_SEC + 0.5)) * 2 * channels
	if pcm.size() > max_bytes:
		return null
	var s: AudioStreamWAV = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.stereo = channels == 2
	s.data = pcm
	return s


# ---------------------------------------------------------------------------
# Ağ paketi: 11025 Hz 16 bit PCM + ZSTD (yuva başına en fazla 48 KB)
# ---------------------------------------------------------------------------

## {raw_size, data} döner; sınırı aşarsa veya boşsa {}.
static func encode_for_net(stream: AudioStreamWAV) -> Dictionary:
	if stream == null:
		return {}
	var mono: PackedFloat32Array = wav_to_mono(stream)
	var down: PackedFloat32Array = resample(mono, stream.mix_rate, GameConfig.VOICE_NET_RATE)
	var max_n: int = int(float(GameConfig.VOICE_NET_RATE) * GameConfig.VOICE_MAX_SEC)
	if down.size() > max_n:
		down = down.slice(0, max_n)
	if down.is_empty():
		return {}
	var raw: PackedByteArray = pcm16_from_floats(down)
	var packed: PackedByteArray = raw.compress(FileAccess.COMPRESSION_ZSTD)
	if not is_net_size_ok(raw.size(), packed.size()):
		return {}
	return {"raw_size": raw.size(), "data": packed}


## Paket boyut sınırları (sıkıştırılmış ≤ 48 KB, açılmış ≤ 2.0 sn PCM, çift bayt).
static func is_net_size_ok(raw_size: int, packed_size: int) -> bool:
	if packed_size <= 0 or packed_size > GameConfig.VOICE_NET_MAX_BYTES:
		return false
	if raw_size <= 0 or raw_size > GameConfig.VOICE_NET_MAX_RAW or raw_size % 2 != 0:
		return false
	return true


## Gelen paketi doğrular ve açar; geçersizse null. Diske yazılmaz.
static func decode_from_net(raw_size: int, data: PackedByteArray) -> AudioStreamWAV:
	if not is_net_size_ok(raw_size, data.size()):
		return null
	var raw: PackedByteArray = data.decompress(raw_size, FileAccess.COMPRESSION_ZSTD)
	if raw.size() != raw_size:
		return null
	var s: AudioStreamWAV = AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = GameConfig.VOICE_NET_RATE
	s.stereo = false
	s.data = raw
	return s


## Dalga formu için sütun başına tepe değerleri (0..1).
static func peaks(samples: PackedFloat32Array, bars: int) -> PackedFloat32Array:
	var out: PackedFloat32Array = PackedFloat32Array()
	out.resize(maxi(bars, 1))
	if samples.is_empty():
		return out
	var per: float = float(samples.size()) / float(out.size())
	for b: int in range(out.size()):
		var a: int = int(float(b) * per)
		var e: int = mini(samples.size(), maxi(a + 1, int(float(b + 1) * per)))
		var mx: float = 0.0
		for i: int in range(a, e):
			mx = maxf(mx, absf(samples[i]))
		out[b] = mx
	return out

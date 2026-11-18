class_name VoiceJitterBuffer
extends RefCounted

## Faz 13A: konuşan başına titreşim tamponu (eklentiden bağımsız, saf GDScript).
## Konuşma başında ~100 ms biriktirir, parçaları sıra numarasıyla dizer; geç gelen parça atılır,
## kayıp parça için en fazla birkaç parça beklenir sonra atlanır. Çalma hızı hiç değiştirilmez.

const SEQ_MOD: int = 65536
## Bu kadar parçadan (1 sn) büyük sıçrama yeni konuşma sayılır
const NEW_STREAM_JUMP: int = 50

var playing: bool = false
var late_dropped: int = 0
var skipped: int = 0
var last_packet_ms: int = 0

var _queue: Dictionary = {} # seq -> PackedByteArray
var _next_seq: int = -1
var _end_seq: int = -1
var _started_ms: int = 0


## 16 bitlik sıra numaraları arasındaki işaretli fark (a - b), taşmaya dayanıklı.
static func seq_diff(a: int, b: int) -> int:
	var d: int = (a - b) & (SEQ_MOD - 1)
	if d >= SEQ_MOD / 2:
		d -= SEQ_MOD
	return d


## Bir konuşma akışı açık mı (ilk parça geldi, bitiş henüz oynatılmadı)?
func is_open() -> bool:
	return _next_seq >= 0


func buffered_count() -> int:
	return _queue.size()


## Gelen parça. payload boş olabilir (yalnızca bitiş işareti).
func push(seq: int, payload: PackedByteArray, is_end: bool, now_ms: int) -> void:
	seq = seq & (SEQ_MOD - 1)
	last_packet_ms = now_ms
	if _next_seq < 0 or absi(seq_diff(seq, _next_seq)) > NEW_STREAM_JUMP:
		# Yeni konuşma (ya da çok büyük sıçrama): sıfırdan başla
		_reset()
		_next_seq = seq
		_started_ms = now_ms
	elif seq_diff(seq, _next_seq) < 0:
		late_dropped += 1
		return
	if is_end:
		_end_seq = seq
	if not payload.is_empty() and _queue.size() < GameConfig.VOICE_CHAT_MAX_QUEUE_MS / GameConfig.VOICE_CHAT_FRAME_MS:
		_queue[seq] = payload


## Şimdi çözücüye verilecek parçalar (sırayla). Akış bitince kapanır.
func pop_ready(now_ms: int) -> Array[PackedByteArray]:
	var out: Array[PackedByteArray] = []
	if _next_seq < 0:
		return out
	if not playing:
		var buffered_ms: int = _queue.size() * GameConfig.VOICE_CHAT_FRAME_MS
		if buffered_ms >= GameConfig.VOICE_CHAT_JITTER_MS or now_ms - _started_ms >= GameConfig.VOICE_CHAT_JITTER_MS or _end_seq >= 0:
			playing = true
		else:
			return out
	while true:
		if _queue.has(_next_seq):
			out.append(_queue[_next_seq] as PackedByteArray)
			_queue.erase(_next_seq)
			_next_seq = (_next_seq + 1) & (SEQ_MOD - 1)
			continue
		if _end_seq >= 0 and seq_diff(_next_seq, _end_seq) >= 0 and _queue.is_empty():
			_reset()
			break
		var ahead: int = _max_ahead()
		if ahead >= GameConfig.VOICE_CHAT_REORDER_FRAMES or (_end_seq >= 0 and not _queue.is_empty()):
			# Kayıp parça: beklemeden atla (ses hızlanıp yavaşlamaz, yalnızca kısa boşluk)
			skipped += 1
			_next_seq = (_next_seq + 1) & (SEQ_MOD - 1)
			continue
		if _queue.is_empty() and _end_seq < 0 and now_ms - last_packet_ms > GameConfig.VOICE_CHAT_SPEAK_HOLD_MS * 2:
			# Bitiş işareti kayboldu: akışı kapat
			_reset()
		break
	return out


func _max_ahead() -> int:
	var best: int = -1
	for k: Variant in _queue.keys():
		best = maxi(best, seq_diff(int(k), _next_seq))
	return best


func _reset() -> void:
	_queue.clear()
	_next_seq = -1
	_end_seq = -1
	playing = false

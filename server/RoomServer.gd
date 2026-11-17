extends Node

## 8.9: Ayrılmış Oda Sunucusu (RoomServer) — tek odayı headless ENet sunucusu olarak yönetir.
## Bu düğüm maç boyunca sahnede kalır; NetworkManager sunucuda sahne değiştirmez.

var _port: int = 7801
var _code: String = "KTRB"
var _is_public: bool = true
var _mm_peer: StreamPeerTCP = null
var _mm_connect_started_ms: int = 0
var _mm_announced: bool = false
var _mm_retry_in: float = 0.0
var _mm_backoff: float = GameConfig.ROOM_MM_RECONNECT_MIN_SEC
var _status_timer: float = 0.0
var _empty_timer: float = 0.0
var _quick_timer: float = GameConfig.ROOM_QUICK_START_SEC
var _was_in_match: bool = false


func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--port="):
			_port = int(arg.substr(7))
		elif arg.begins_with("--code="):
			_code = arg.substr(7).strip_edges().to_upper()
		elif arg.begins_with("--public="):
			_is_public = int(arg.substr(9)) == 1

	if not NetworkManager.start_dedicated_room(_port, _code, _is_public):
		push_error("[RoomServer] Port %d başlatılamadı." % _port)
		get_tree().quit(1)
		return

	_connect_matchmaker()
	print("[RoomServer] Hazır: port=%d code=%s public=%s" % [_port, _code, str(_is_public)])


func _process(delta: float) -> void:
	_update_matchmaker_link(delta)

	# Odada belirli süre kimse yoksa kendini kapat
	if NetworkManager.players.is_empty():
		_empty_timer += delta
		if _empty_timer >= GameConfig.ROOM_EMPTY_SHUTDOWN_SEC:
			print("[RoomServer] %d sn boş kaldı, kapanıyor: %s" % [int(GameConfig.ROOM_EMPTY_SHUTDOWN_SEC), _code])
			_mm_close()
			get_tree().quit(0)
	else:
		_empty_timer = 0.0

	_update_quick_play(delta)


## Eşleştirici bağlantısı: bağlanınca room_ready, sonra düzenli room_status; hata/kopmada geri çekilmeli yeniden bağlanma.
func _update_matchmaker_link(delta: float) -> void:
	if _mm_peer == null:
		_mm_retry_in -= delta
		if _mm_retry_in <= 0.0:
			_connect_matchmaker()
		return
	_mm_peer.poll()
	var st: StreamPeerTCP.Status = _mm_peer.get_status()
	if st == StreamPeerTCP.STATUS_CONNECTED:
		if not _mm_announced:
			_mm_announced = true
			_mm_backoff = GameConfig.ROOM_MM_RECONNECT_MIN_SEC
			_send_to_matchmaker("room_ready")
			_status_timer = 0.0
		_status_timer += delta
		if _status_timer >= GameConfig.ROOM_STATUS_INTERVAL_SEC:
			_status_timer = 0.0
			_send_to_matchmaker("room_status")
		# Eşleştirici odaya veri göndermez; gelen olursa tamponda birikmesin
		var avail: int = _mm_peer.get_available_bytes()
		if avail > 0:
			_mm_peer.get_data(avail)
	elif st == StreamPeerTCP.STATUS_CONNECTING:
		if Time.get_ticks_msec() - _mm_connect_started_ms > int(GameConfig.ROOM_MM_CONNECT_TIMEOUT_SEC * 1000.0):
			_schedule_reconnect()
	else:
		# STATUS_ERROR veya STATUS_NONE
		_schedule_reconnect()


func _connect_matchmaker() -> void:
	_mm_peer = StreamPeerTCP.new()
	_mm_announced = false
	_mm_connect_started_ms = Time.get_ticks_msec()
	var err: Error = _mm_peer.connect_to_host(GameConfig.MM_LOCAL_HOST, GameConfig.MATCHMAKER_PORT)
	if err != OK:
		_schedule_reconnect()


func _schedule_reconnect() -> void:
	_mm_close()
	_mm_retry_in = _mm_backoff
	_mm_backoff = minf(_mm_backoff * 2.0, GameConfig.ROOM_MM_RECONNECT_MAX_SEC)


func _mm_close() -> void:
	if _mm_peer != null:
		_mm_peer.disconnect_from_host()
	_mm_peer = null
	_mm_announced = false


func _send_to_matchmaker(op: String) -> void:
	var payload: Dictionary = {
		"op": op,
		"port": _port,
		"code": _code,
		"public": _is_public,
		"players": NetworkManager.real_player_count(),
		"in_match": NetworkManager.in_match,
		"pid": OS.get_process_id(),
	}
	var err: Error = _mm_peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())
	if err != OK:
		_schedule_reconnect()


## Hızlı Oyun otomatik başlatma: 5 kişi hemen; en az 1 gerçek oyuncuyla süre dolunca botlarla 4'e tamamlanıp başlar.
## Her maçtan sonra süre yeniden başlar.
func _update_quick_play(delta: float) -> void:
	var in_match_now: bool = NetworkManager.in_match
	if in_match_now != _was_in_match:
		_was_in_match = in_match_now
		_quick_timer = GameConfig.ROOM_QUICK_START_SEC
	# Sonuç ekranında rövanş akışı sürerken bekleme sayacı işlemez
	if not _is_public or in_match_now or NetworkManager.rematch_state != GameConfig.REMATCH_STATE_CLOSED:
		NetworkManager.quick_play_countdown = -1.0
		return
	var count: int = NetworkManager.players.size()
	var real: int = NetworkManager.real_player_count()
	if count >= GameConfig.NET_MAX_CLIENTS + 1 and real >= 1:
		_start_quick_match()
	elif real >= 1:
		_quick_timer -= delta
		NetworkManager.quick_play_countdown = _quick_timer
		if _quick_timer <= 0.0:
			NetworkManager.fill_with_bots(GameConfig.BOT_QUICK_FILL_TO)
			_start_quick_match()
	else:
		_quick_timer = GameConfig.ROOM_QUICK_START_SEC
		NetworkManager.quick_play_countdown = -1.0


func _start_quick_match() -> void:
	_quick_timer = GameConfig.ROOM_QUICK_START_SEC
	NetworkManager.quick_play_countdown = -1.0
	NetworkManager.host_start_match()

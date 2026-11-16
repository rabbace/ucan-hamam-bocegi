extends Node

## 8.9: Ayrılmış Oda Sunucusu (RoomServer) — tek odayı headless ENet sunucusu olarak yönetir.

var _port: int = 7801
var _code: String = "KTRB"
var _is_public: bool = true
var _mm_peer: StreamPeerTCP = StreamPeerTCP.new()
var _status_timer: float = 0.0
var _empty_timer: float = 0.0
var _quick_timer: float = 25.0


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

	_mm_peer.connect_to_host("127.0.0.1", GameConfig.MATCHMAKER_PORT)
	print("[RoomServer] Hazır: port=%d code=%s public=%s" % [_port, _code, str(_is_public)])


func _process(delta: float) -> void:
	_mm_peer.poll()
	_status_timer += delta
	if _status_timer >= 2.0:
		_status_timer = 0.0
		if _mm_peer.get_status() == StreamPeerTCP.STATUS_CONNECTED:
			var payload: Dictionary = {
				"op": "room_status",
				"port": _port,
				"code": _code,
				"public": _is_public,
				"players": NetworkManager.players.size(),
				"in_match": NetworkManager.in_match,
			}
			_mm_peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())
		elif _mm_peer.get_status() == StreamPeerTCP.STATUS_NONE:
			_mm_peer.connect_to_host("127.0.0.1", GameConfig.MATCHMAKER_PORT)

	# Odada 60 sn kimse yoksa kendini kapat
	if NetworkManager.players.is_empty():
		_empty_timer += delta
		if _empty_timer >= 60.0:
			print("[RoomServer] 60 sn boş kaldı, kapanıyor: %s" % _code)
			get_tree().quit(0)
	else:
		_empty_timer = 0.0

	# Hızlı Oyun otomatik başlatma (5 kişi veya 2+ kişiyle 25 sn)
	if _is_public and not NetworkManager.in_match:
		var count: int = NetworkManager.players.size()
		if count >= GameConfig.NET_MAX_CLIENTS + 1:
			NetworkManager.host_start_match()
		elif count >= 2:
			_quick_timer -= delta
			NetworkManager.quick_play_countdown = _quick_timer
			if _quick_timer <= 0.0:
				NetworkManager.host_start_match()
		else:
			_quick_timer = 25.0
			NetworkManager.quick_play_countdown = -1.0

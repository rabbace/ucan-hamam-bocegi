extends Node

## 8.9: Çevrimiçi Eşleştirici (Matchmaker) — TCP 7700 üzerinden oda yönlendirme ve süreç yönetimi.

const CODE_CHARS: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

var _server: TCPServer = TCPServer.new()
var _clients: Array[Dictionary] = [] # {peer: StreamPeerTCP, buf: String}
var _rooms: Dictionary = {} # port -> {code, public, players, in_match, last_seen, pid}
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	var err: Error = _server.listen(GameConfig.MATCHMAKER_PORT, "0.0.0.0")
	if err != OK:
		push_error("Matchmaker TCP %d dinlenemedi: %d" % [GameConfig.MATCHMAKER_PORT, err])
		get_tree().quit(1)
		return
	print("[Matchmaker] TCP %d dinleniyor..." % GameConfig.MATCHMAKER_PORT)


func _process(_delta: float) -> void:
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if peer != null:
			_clients.append({"peer": peer, "buf": ""})

	var kept: Array[Dictionary] = []
	for c: Dictionary in _clients:
		var peer: StreamPeerTCP = c["peer"] as StreamPeerTCP
		peer.poll()
		var st: int = peer.get_status()
		if st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE:
			continue
		var avail: int = peer.get_available_bytes()
		if avail > 0:
			var chunk: String = peer.get_utf8_string(avail)
			var buf: String = str(c["buf"]) + chunk
			var lines: PackedStringArray = buf.split("\n", false)
			if not buf.ends_with("\n") and not lines.is_empty():
				c["buf"] = lines[lines.size() - 1]
				lines.remove_at(lines.size() - 1)
			else:
				c["buf"] = ""
			for line: String in lines:
				var trimmed: String = line.strip_edges()
				if not trimmed.is_empty():
					_handle_message(peer, trimmed)
		kept.append(c)
	_clients = kept

	var now_sec: float = Time.get_unix_time_from_system()
	var stale: Array[int] = []
	for port_v: Variant in _rooms.keys():
		var port: int = int(port_v)
		var r: Dictionary = _rooms[port] as Dictionary
		if now_sec - float(r.get("last_seen", now_sec)) > 10.0:
			stale.append(port)
	for p: int in stale:
		print("[Matchmaker] Zaman aşımı nedeniyle oda silindi: %d" % p)
		_rooms.erase(p)


func _handle_message(peer: StreamPeerTCP, raw_json: String) -> void:
	var parsed: Variant = JSON.parse_string(raw_json)
	if not (parsed is Dictionary):
		_send_json(peer, {"ok": false, "reason": "Geçersiz istek"})
		return
	var msg: Dictionary = parsed as Dictionary
	var op: String = str(msg.get("op", ""))

	if op == "room_ready":
		var port: int = int(msg.get("port", 0))
		if port > 0:
			_rooms[port] = {
				"code": str(msg.get("code", "")),
				"public": bool(msg.get("public", true)),
				"players": 0,
				"in_match": false,
				"last_seen": Time.get_unix_time_from_system(),
			}
		return

	if op == "room_status":
		var port: int = int(msg.get("port", 0))
		if _rooms.has(port):
			_rooms[port]["players"] = int(msg.get("players", 0))
			_rooms[port]["in_match"] = bool(msg.get("in_match", false))
			_rooms[port]["last_seen"] = Time.get_unix_time_from_system()
		return

	var ver: int = int(msg.get("version", GameConfig.NET_VERSION))
	if ver != GameConfig.NET_VERSION:
		_send_json(peer, {"ok": false, "reason": "Sürüm eski, oyunu güncelle"})
		return

	if op == "hello":
		_send_json(peer, {"ok": true, "version": GameConfig.NET_VERSION})
	elif op == "get_event":
		var ev_data: Dictionary = {}
		if FileAccess.file_exists("res://server/events.json"):
			var f: FileAccess = FileAccess.open("res://server/events.json", FileAccess.READ)
			if f != null:
				var p_ev: Variant = JSON.parse_string(f.get_as_text())
				if p_ev is Dictionary:
					ev_data = p_ev as Dictionary
		_send_json(peer, {"ok": true, "event": ev_data})
	elif op == "quick_play":
		for port_v: Variant in _rooms.keys():
			var port: int = int(port_v)
			var r: Dictionary = _rooms[port] as Dictionary
			if bool(r["public"]) and not bool(r["in_match"]) and int(r["players"]) < GameConfig.NET_MAX_CLIENTS + 1:
				_send_json(peer, {"ok": true, "port": port, "code": str(r["code"]), "public": true})
				return
		var new_room: Dictionary = _spawn_room(true)
		if new_room.is_empty():
			_send_json(peer, {"ok": false, "reason": "Sunucu dolu, birazdan tekrar dene."})
		else:
			_send_json(peer, {"ok": true, "port": int(new_room["port"]), "code": str(new_room["code"]), "public": true})
	elif op == "create_private":
		var new_room: Dictionary = _spawn_room(false)
		if new_room.is_empty():
			_send_json(peer, {"ok": false, "reason": "Sunucu dolu, birazdan tekrar dene."})
		else:
			_send_json(peer, {"ok": true, "port": int(new_room["port"]), "code": str(new_room["code"]), "public": false})
	elif op == "join_code":
		var code: String = str(msg.get("code", "")).strip_edges().to_upper()
		for port_v: Variant in _rooms.keys():
			var port: int = int(port_v)
			var r: Dictionary = _rooms[port] as Dictionary
			if str(r["code"]) == code:
				if bool(r["in_match"]):
					_send_json(peer, {"ok": false, "reason": "Maç başlamış"})
					return
				if int(r["players"]) >= GameConfig.NET_MAX_CLIENTS + 1:
					_send_json(peer, {"ok": false, "reason": "Oda dolu"})
					return
				_send_json(peer, {"ok": true, "port": port, "code": code, "public": bool(r["public"])})
				return
		_send_json(peer, {"ok": false, "reason": "Oda bulunamadı"})


func _spawn_room(is_public: bool) -> Dictionary:
	var free_port: int = 0
	for p: int in range(GameConfig.ROOM_PORT_MIN, GameConfig.ROOM_PORT_MAX + 1):
		if not _rooms.has(p):
			free_port = p
			break
	if free_port == 0:
		return {}

	var code: String = _generate_room_code()
	var args: PackedStringArray = PackedStringArray([
		"--headless",
		"--",
		"--room",
		"--port=%d" % free_port,
		"--code=%s" % code,
		"--public=%d" % (1 if is_public else 0),
	])
	var pid: int = OS.create_process(OS.get_executable_path(), args)
	if pid <= 0:
		return {}
	_rooms[free_port] = {
		"code": code,
		"public": is_public,
		"players": 0,
		"in_match": false,
		"last_seen": Time.get_unix_time_from_system(),
		"pid": pid,
	}
	print("[Matchmaker] Oda açıldı: port=%d code=%s public=%s" % [free_port, code, str(is_public)])
	return {"port": free_port, "code": code}


func _generate_room_code() -> String:
	var out: String = ""
	for _i: int in range(4):
		out += CODE_CHARS[_rng.randi_range(0, CODE_CHARS.length() - 1)]
	return out


func _send_json(peer: StreamPeerTCP, payload: Dictionary) -> void:
	var txt: String = JSON.stringify(payload) + "\n"
	peer.put_data(txt.to_utf8_buffer())

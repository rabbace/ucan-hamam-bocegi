extends Node

## 8.9: Çevrimiçi Eşleştirici (Matchmaker) — TCP 7700 üzerinden oda yönlendirme ve süreç yönetimi.
## Güvenlik: oda mesajları yalnızca yerelden, IP başına hız sınırı, toplam oda/bağlantı sınırı,
## boşta kalan veya yanıtı verilmiş bağlantılar kapatılır, okuma tamponu sınırlıdır.
## Faz 12: "hello" ile kimliği doğrulanan bağlantı kalıcı Mahalle oturumuna yükselir (kurallar: server/MahalleHub.gd);
## kullanıcı kayıtları server/data/users.json (server/UserStore.gd).

const CODE_CHARS: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH: int = 4
const LOCAL_ADDRESSES: Array[String] = ["127.0.0.1", "::1", "::ffff:127.0.0.1"]

var _server: TCPServer = TCPServer.new()
var _clients: Array[Dictionary] = [] # {peer, buf, ip, local, last_ms}
var _rooms: Dictionary = {} # port -> {code, public, players, in_match, last_seen, ready, pid, reservations}
var _rate_log: Dictionary = {} # "ip|tür" -> Array[float] (unix sn)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _store: UserStore = null
var _hub: MahalleHub = null
var _prune_timer: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_store = UserStore.new(UserStore.default_data_dir())
	_store.load_all()
	_hub = MahalleHub.new(_store, _rooms)
	var err: Error = _server.listen(GameConfig.MATCHMAKER_PORT, "0.0.0.0")
	if err != OK:
		push_error("Matchmaker TCP %d dinlenemedi: %d" % [GameConfig.MATCHMAKER_PORT, err])
		get_tree().quit(1)
		return
	print("[Matchmaker] TCP %d dinleniyor..." % GameConfig.MATCHMAKER_PORT)


func _process(delta: float) -> void:
	_accept_connections()
	_poll_clients()
	_expire_rooms()
	_store.tick()
	_prune_timer += delta
	if _prune_timer >= GameConfig.MM_RATE_WINDOW_SEC:
		_prune_timer = 0.0
		_hub.prune()
		_prune_rate_log(Time.get_unix_time_from_system())


## Kapanırken bekleyen kullanıcı değişiklikleri diske yazılır.
func _exit_tree() -> void:
	if _store != null:
		_store.flush()


func _accept_connections() -> void:
	while _server.is_connection_available():
		var peer: StreamPeerTCP = _server.take_connection()
		if peer == null:
			continue
		var ip: String = peer.get_connected_host()
		var is_local: bool = LOCAL_ADDRESSES.has(ip)
		# Sınırlar yalnızca kimliksiz (kısa) bağlantılara uygulanır; Mahalle oturumları MahalleHub'da sayılır
		if _count_short_clients("") >= GameConfig.MM_MAX_CONNECTIONS:
			peer.disconnect_from_host()
			continue
		if not is_local and _count_short_clients(ip) >= GameConfig.MM_MAX_CONNECTIONS_PER_IP:
			peer.disconnect_from_host()
			continue
		_clients.append({
			"peer": peer,
			"buf": PackedByteArray(),
			"ip": ip,
			"local": is_local,
			"last_ms": Time.get_ticks_msec(),
			"session": false,
		})


func _poll_clients() -> void:
	var now_ms: int = Time.get_ticks_msec()
	var idle_ms: int = int(GameConfig.MM_IDLE_TIMEOUT_SEC * 1000.0)
	var session_idle_ms: int = int(GameConfig.MM_SESSION_IDLE_SEC * 1000.0)
	var kept: Array[Dictionary] = []
	for c: Dictionary in _clients:
		var peer: StreamPeerTCP = c["peer"] as StreamPeerTCP
		peer.poll()
		if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED or bool(c.get("close", false)):
			_drop_client(c)
			continue
		var keep_open: bool = true
		var avail: int = peer.get_available_bytes()
		if avail > 0:
			var buf: PackedByteArray = c["buf"] as PackedByteArray
			if buf.size() + avail > GameConfig.MM_READ_BUFFER_MAX:
				# Tampon taşması: bağlantıyı kes
				_drop_client(c)
				continue
			var res: Array = peer.get_data(avail)
			if int(res[0]) != OK:
				_drop_client(c)
				continue
			buf.append_array(res[1] as PackedByteArray)
			c["last_ms"] = now_ms
			var nl: int = buf.find(10)
			while nl != -1 and keep_open:
				var line: String = buf.slice(0, nl).get_string_from_utf8().strip_edges()
				buf = buf.slice(nl + 1)
				if not line.is_empty():
					keep_open = _handle_message(c, line)
				nl = buf.find(10)
			c["buf"] = buf
		var limit_ms: int = session_idle_ms if bool(c.get("session", false)) else idle_ms
		if keep_open and now_ms - int(c["last_ms"]) > limit_ms:
			keep_open = false
		if not keep_open or bool(c.get("close", false)):
			_drop_client(c)
			continue
		kept.append(c)
	_clients = kept


## Bağlantıyı kapatır; Mahalle oturumuysa durum ve son görülme güncellenir.
func _drop_client(c: Dictionary) -> void:
	(c["peer"] as StreamPeerTCP).disconnect_from_host()
	_hub.on_session_closed(c)


## Uzun süre haber alınamayan odaları siler ve sürecini sonlandırır.
func _expire_rooms() -> void:
	var now_sec: float = Time.get_unix_time_from_system()
	var stale: Array[int] = []
	for port_v: Variant in _rooms.keys():
		var r: Dictionary = _rooms[port_v] as Dictionary
		var limit: float = GameConfig.MM_ROOM_STALE_SEC if bool(r.get("ready", false)) else GameConfig.MM_ROOM_BOOT_GRACE_SEC
		if now_sec - float(r.get("last_seen", now_sec)) > limit:
			stale.append(int(port_v))
	for p: int in stale:
		var pid: int = int((_rooms[p] as Dictionary).get("pid", 0))
		if pid > 0:
			OS.kill(pid)
		print("[Matchmaker] Zaman aşımı nedeniyle oda silindi: %d" % p)
		var gone_uids: Array = ((_rooms[p] as Dictionary).get("uids", []) as Array).duplicate()
		_rooms.erase(p)
		_hub.on_room_changed(gone_uids, [])


## Bir satırlık JSON isteğini işler; bağlantı açık kalmalıysa true döner.
func _handle_message(client: Dictionary, raw_json: String) -> bool:
	var peer: StreamPeerTCP = client["peer"] as StreamPeerTCP
	var ip: String = str(client["ip"])
	var parsed: Variant = JSON.parse_string(raw_json)
	if not (parsed is Dictionary):
		_send_json(peer, {"ok": false, "reason": "Geçersiz istek"})
		return false
	var msg: Dictionary = parsed as Dictionary
	var op: String = str(msg.get("op", ""))

	# Faz 12: kimliği doğrulanmış kalıcı Mahalle oturumu
	if bool(client.get("session", false)):
		return _hub.handle_session_message(client, msg)

	if op == "room_ready" or op == "room_status":
		# Oda mesajları yalnızca aynı makinedeki oda süreçlerinden kabul edilir
		if not bool(client["local"]):
			return false
		_register_room_message(msg)
		return true
	if op == "room_result":
		if not bool(client["local"]):
			return false
		_hub.on_room_result(_clean_code(str(msg.get("code", ""))), str(msg.get("winner_uid", "")))
		return true
	if op == "hello":
		return _hub.handle_hello(client, msg)

	var ver: int = int(msg.get("version", -1))
	if ver != GameConfig.NET_VERSION:
		_send_json(peer, {"ok": false, "reason": "Sürüm eski, oyunu güncelle"})
		return false

	if op == "get_event":
		_send_json(peer, {"ok": true, "event": _load_event()})
	elif op == "quick_play":
		var port: int = _find_open_public_room()
		if port > 0:
			_reserve_slot(port)
			_send_json(peer, {"ok": true, "port": port, "code": str(_rooms[port]["code"]), "public": true})
		else:
			_send_spawn_result(peer, ip, true)
	elif op == "create_private":
		_send_spawn_result(peer, ip, false)
	elif op == "join_code":
		_handle_join_code(peer, ip, str(msg.get("code", "")))
	else:
		_send_json(peer, {"ok": false, "reason": "Geçersiz istek"})
	return false


## room_ready / room_status: bilinmeyen oda da kayıt olarak kabul edilir (eşleştirici yeniden başlarsa).
func _register_room_message(msg: Dictionary) -> void:
	var port: int = int(msg.get("port", 0))
	if port < GameConfig.ROOM_PORT_MIN or port > GameConfig.ROOM_PORT_MAX:
		return
	var code: String = _clean_code(str(msg.get("code", "")))
	if not _rooms.has(port):
		_rooms[port] = {
			"code": code,
			"public": bool(msg.get("public", true)),
			"players": 0,
			"in_match": false,
			"pid": int(msg.get("pid", 0)),
			"reservations": [],
		}
		print("[Matchmaker] Oda kaydedildi: port=%d code=%s" % [port, code])
	var r: Dictionary = _rooms[port] as Dictionary
	if not code.is_empty():
		r["code"] = code
	var old_key: String = "%s|%d|%s" % [str(r.get("in_match", false)), int(r.get("players", 0)), str(r.get("uids", []))]
	var old_uids: Array = (r.get("uids", []) as Array).duplicate()
	r["public"] = bool(msg.get("public", r.get("public", true)))
	r["players"] = clampi(int(msg.get("players", 0)), 0, GameConfig.NET_MAX_CLIENTS + 1)
	r["in_match"] = bool(msg.get("in_match", false))
	# Faz 12.2: odadaki kullanıcı kimlikleri (12C'deki giriş biletine kadar oda sunucusunda doğrulanmaz)
	var uids: Array = []
	var raw_uids: Variant = msg.get("uids", [])
	if raw_uids is Array:
		for u_v: Variant in raw_uids as Array:
			var u: String = GameConfig.normalize_account_id(str(u_v))
			if not u.is_empty() and not uids.has(u) and uids.size() < GameConfig.NET_MAX_CLIENTS + 1:
				uids.append(u)
	r["uids"] = uids
	var new_key: String = "%s|%d|%s" % [str(r["in_match"]), int(r["players"]), str(uids)]
	if new_key != old_key:
		_hub.on_room_changed(old_uids, uids)
	if int(r.get("pid", 0)) <= 0:
		r["pid"] = int(msg.get("pid", 0))
	r["ready"] = true
	r["last_seen"] = Time.get_unix_time_from_system()


func _find_open_public_room() -> int:
	for port_v: Variant in _rooms.keys():
		var port: int = int(port_v)
		var r: Dictionary = _rooms[port] as Dictionary
		if bool(r["public"]) and not bool(r["in_match"]) and _effective_players(port) < GameConfig.NET_MAX_CLIENTS + 1:
			return port
	return 0


## Odadaki oyuncu sayısı + henüz bağlanmamış yönlendirmeler (bağlanma süresi kadar geçerli).
func _effective_players(port: int) -> int:
	var r: Dictionary = _rooms[port] as Dictionary
	var now_sec: float = Time.get_unix_time_from_system()
	var fresh: Array = []
	for t_v: Variant in r.get("reservations", []) as Array:
		if now_sec - float(t_v) <= GameConfig.NET_CONNECT_TIMEOUT_SEC:
			fresh.append(t_v)
	r["reservations"] = fresh
	return int(r["players"]) + fresh.size()


func _reserve_slot(port: int) -> void:
	var r: Dictionary = _rooms[port] as Dictionary
	(r["reservations"] as Array).append(Time.get_unix_time_from_system())


func _send_spawn_result(peer: StreamPeerTCP, ip: String, is_public: bool) -> void:
	if _rooms.size() >= GameConfig.MM_MAX_ROOMS:
		_send_json(peer, {"ok": false, "reason": "Sunucu dolu, birazdan tekrar dene."})
		return
	if not _rate_ok(ip, "spawn", GameConfig.MM_ROOM_SPAWN_PER_MIN_PER_IP):
		_send_json(peer, {"ok": false, "reason": "Çok sık oda açtın, biraz bekle."})
		return
	var new_room: Dictionary = _spawn_room(is_public)
	if new_room.is_empty():
		_send_json(peer, {"ok": false, "reason": "Sunucu dolu, birazdan tekrar dene."})
		return
	var port: int = int(new_room["port"])
	_reserve_slot(port)
	_send_json(peer, {"ok": true, "port": port, "code": str(new_room["code"]), "public": is_public})


func _handle_join_code(peer: StreamPeerTCP, ip: String, raw_code: String) -> void:
	# Oda kodu tahminine karşı IP başına deneme sınırı
	if not _rate_ok(ip, "join", GameConfig.MM_JOIN_CODE_PER_MIN_PER_IP):
		_send_json(peer, {"ok": false, "reason": "Çok fazla deneme, biraz bekle."})
		return
	var code: String = _clean_code(raw_code)
	if code.length() != CODE_LENGTH:
		_send_json(peer, {"ok": false, "reason": "Oda bulunamadı"})
		return
	for port_v: Variant in _rooms.keys():
		var port: int = int(port_v)
		var r: Dictionary = _rooms[port] as Dictionary
		if str(r["code"]) != code:
			continue
		if bool(r["in_match"]):
			_send_json(peer, {"ok": false, "reason": "Maç başlamış"})
			return
		if _effective_players(port) >= GameConfig.NET_MAX_CLIENTS + 1:
			_send_json(peer, {"ok": false, "reason": "Oda dolu"})
			return
		_reserve_slot(port)
		_send_json(peer, {"ok": true, "port": port, "code": code, "public": bool(r["public"])})
		return
	_send_json(peer, {"ok": false, "reason": "Oda bulunamadı"})


## Kayan pencere hız sınırı: pencere içindeki istek sayısı sınırın altındaysa kaydedip true döner.
func _rate_ok(ip: String, kind: String, limit: int) -> bool:
	var key: String = "%s|%s" % [ip, kind]
	var now_sec: float = Time.get_unix_time_from_system()
	var recent: Array = []
	for t_v: Variant in _rate_log.get(key, []) as Array:
		if now_sec - float(t_v) < GameConfig.MM_RATE_WINDOW_SEC:
			recent.append(t_v)
	if recent.size() >= limit:
		_rate_log[key] = recent
		return false
	recent.append(now_sec)
	_rate_log[key] = recent
	_prune_rate_log(now_sec)
	return true


## Süresi dolmuş hız kayıtlarını temizler (bellek şişmesin).
func _prune_rate_log(now_sec: float) -> void:
	var dead: Array[String] = []
	for key_v: Variant in _rate_log.keys():
		var arr: Array = _rate_log[key_v] as Array
		if arr.is_empty() or now_sec - float(arr[arr.size() - 1]) >= GameConfig.MM_RATE_WINDOW_SEC:
			dead.append(str(key_v))
	for k: String in dead:
		_rate_log.erase(k)


## Kimliksiz (kısa) bağlantı sayısı; ip boşsa tümü.
func _count_short_clients(ip: String) -> int:
	var n: int = 0
	for c: Dictionary in _clients:
		if bool(c.get("session", false)):
			continue
		if ip.is_empty() or str(c["ip"]) == ip:
			n += 1
	return n


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
		"ready": false,
		"pid": pid,
		"reservations": [],
	}
	print("[Matchmaker] Oda açıldı: port=%d code=%s public=%s pid=%d" % [free_port, code, str(is_public), pid])
	return {"port": free_port, "code": code}


func _generate_room_code() -> String:
	for _attempt: int in range(32):
		var out: String = ""
		for _i: int in range(CODE_LENGTH):
			out += CODE_CHARS[_rng.randi_range(0, CODE_CHARS.length() - 1)]
		if not _code_in_use(out):
			return out
	return "ZZZZ"


func _code_in_use(code: String) -> bool:
	for r_v: Variant in _rooms.values():
		if str((r_v as Dictionary).get("code", "")) == code:
			return true
	return false


## Kodu büyük harfe çevirip yalnızca izinli karakterleri bırakır.
func _clean_code(raw: String) -> String:
	var up: String = raw.strip_edges().to_upper().substr(0, 16)
	var out: String = ""
	for i: int in range(up.length()):
		if CODE_CHARS.contains(up[i]):
			out += up[i]
	return out.substr(0, CODE_LENGTH)


func _load_event() -> Dictionary:
	if not FileAccess.file_exists("res://server/events.json"):
		return {}
	var f: FileAccess = FileAccess.open("res://server/events.json", FileAccess.READ)
	if f == null:
		return {}
	var p_ev: Variant = JSON.parse_string(f.get_as_text())
	return p_ev as Dictionary if p_ev is Dictionary else {}


func _send_json(peer: StreamPeerTCP, payload: Dictionary) -> void:
	var txt: String = JSON.stringify(payload) + "\n"
	peer.put_data(txt.to_utf8_buffer())

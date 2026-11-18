extends Node

## 8.9: Çevrimiçi Eşleştirici (Matchmaker) — TCP 7700 üzerinden oda yönlendirme ve süreç yönetimi.
## Güvenlik: oda mesajları yalnızca yerelden, IP başına hız sınırı, toplam oda/bağlantı sınırı,
## boşta kalan veya yanıtı verilmiş bağlantılar kapatılır, okuma tamponu sınırlıdır.
## Faz 12: "hello" ile kimliği doğrulanan bağlantı kalıcı Mahalle oturumuna yükselir (kurallar: server/MahalleHub.gd);
## kullanıcı kayıtları server/data/users.json (server/UserStore.gd).
## Faz 12.4–12.5: odalar yalnızca Mahalle oturumundan açılır / katılınır (giriş bileti, HMAC-SHA256, 60 sn);
## bilet imza anahtarı oda süreçlerine ortam değişkeniyle verilir. TLS açıksa (GameConfig.tls_enabled) dış
## bağlantılar StreamPeerTLS ile şifrelenir. Web hesap silme ucu: server/DeleteHttp.gd (TCP MM_HTTP_PORT).

const CODE_CHARS: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH: int = 4
const LOCAL_ADDRESSES: Array[String] = ["127.0.0.1", "::1", "::ffff:127.0.0.1"]

var _server: TCPServer = TCPServer.new()
var _clients: Array[Dictionary] = [] # {tcp, peer (TCP ya da TLS), buf, ip, local, last_ms}
## port -> {code, public, privacy, owner_uid, allow, players, in_match, uids, last_seen, ready, pid, reservations[{t, uid}]}
var _rooms: Dictionary = {}
var _rate_log: Dictionary = {} # "ip|tür" -> Array[float] (unix sn)
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _store: UserStore = null
var _hub: MahalleHub = null
var _prune_timer: float = 0.0
var _tls_options: TLSOptions = null
var _http: DeleteHttp = null
var _moderation_path: String = ""
var _moderation_mtime: int = -1
var _moderation_timer: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_store = UserStore.new(UserStore.default_data_dir())
	_store.load_all()
	_hub = MahalleHub.new(_store, _rooms)
	_hub.mm = self
	_hub.ticket_key = _init_ticket_key()
	NetStream.warn_if_insecure("Eşleştirici")
	if GameConfig.tls_enabled():
		_tls_options = NetStream.load_server_options(_store.data_dir)
		if _tls_options == null:
			push_error("TLS açık ama sertifika yüklenemedi; kapanıyor.")
			get_tree().quit(1)
			return
	_moderation_path = _find_moderation_path()
	_reload_moderation()
	var err: Error = _server.listen(GameConfig.MATCHMAKER_PORT, "0.0.0.0")
	if err != OK:
		push_error("Matchmaker TCP %d dinlenemedi: %d" % [GameConfig.MATCHMAKER_PORT, err])
		get_tree().quit(1)
		return
	_http = DeleteHttp.new(_hub, _tls_options)
	var http_port: int = GameConfig.MM_HTTP_PORT
	var hp_arg: String = GameConfig.cmdline_value("--http-port=")
	if hp_arg.is_valid_int():
		http_port = int(hp_arg)
	if _http.start(http_port) != OK:
		push_warning("[Matchmaker] Hesap silme ucu (TCP %d) açılamadı." % http_port)
		_http = null
	print("[Matchmaker] TCP %d dinleniyor (TLS: %s)..." % [GameConfig.MATCHMAKER_PORT, "açık" if _tls_options != null else "kapalı"])


## Bilet imza anahtarı: ortam değişkeni verilmişse o, yoksa her açılışta rastgele. Oda süreçleri
## alt süreç olarak ortamı devralır (komut satırında görünmez).
func _init_ticket_key() -> PackedByteArray:
	var hex: String = OS.get_environment(GameConfig.TICKET_KEY_ENV)
	if hex.length() < 32:
		hex = Crypto.new().generate_random_bytes(32).hex_encode()
		OS.set_environment(GameConfig.TICKET_KEY_ENV, hex)
	return hex.hex_decode()


func _process(delta: float) -> void:
	_accept_connections()
	_poll_clients()
	_expire_rooms()
	_store.tick()
	if _http != null:
		_http.poll()
	_prune_timer += delta
	if _prune_timer >= GameConfig.MM_RATE_WINDOW_SEC:
		_prune_timer = 0.0
		_hub.prune()
		if _http != null:
			_http.prune()
		_prune_rate_log(Time.get_unix_time_from_system())
	_moderation_timer += delta
	if _moderation_timer >= GameConfig.MODERATION_RELOAD_SEC:
		_moderation_timer = 0.0
		_reload_moderation()


## Kapanırken bekleyen kullanıcı değişiklikleri diske yazılır.
func _exit_tree() -> void:
	if _store != null:
		_store.flush()
	if _http != null:
		_http.stop()


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
		var stream: StreamPeer = peer
		if _tls_options != null:
			var tls: StreamPeerTLS = StreamPeerTLS.new()
			if tls.accept_stream(peer, _tls_options) != OK:
				peer.disconnect_from_host()
				continue
			stream = tls
		_clients.append({
			"tcp": peer,
			"peer": stream,
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
		var peer: StreamPeer = c["peer"] as StreamPeer
		var st: int = NetStream.poll_state(peer)
		if st == NetStream.DEAD or bool(c.get("close", false)):
			_drop_client(c)
			continue
		if st == NetStream.PENDING:
			# TLS el sıkışması: kısa bağlantı süresi içinde bitmeli
			if now_ms - int(c["last_ms"]) > idle_ms:
				_drop_client(c)
				continue
			kept.append(c)
			continue
		var keep_open: bool = true
		var avail: int = peer.get_available_bytes()
		if avail > 0:
			var buf: PackedByteArray = c["buf"] as PackedByteArray
			if buf.size() + avail > GameConfig.MM_READ_BUFFER_MAX:
				# Tampon taşması: bağlantıyı kes
				_drop_client(c)
				continue
			var res: Array = peer.get_partial_data(avail)
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
	NetStream.close(c["peer"] as StreamPeer)
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
	var peer: StreamPeer = client["peer"] as StreamPeer
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
	elif op == "quick_play" or op == "create_private" or op == "join_code":
		# Faz 12.4: odalara yalnızca Mahalle oturumundan (giriş biletiyle) girilir
		_send_json(peer, {"ok": false, "reason": "Önce Mahalle'ye bağlan (oyunu güncelle)."})
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
			"privacy": GameConfig.ROOM_PRIVACY_DEFAULT,
			"owner_uid": "",
			"allow": {},
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
	var was_in_match: bool = bool(r.get("in_match", false))
	r["public"] = bool(msg.get("public", r.get("public", true)))
	r["players"] = clampi(int(msg.get("players", 0)), 0, GameConfig.NET_MAX_CLIENTS + 1)
	r["in_match"] = bool(msg.get("in_match", false))
	# Faz 12.4: oda sahibinin değiştirdiği gizlilik ve (sahip ayrılınca) yeni sahibin kimliği
	var priv: String = str(msg.get("privacy", ""))
	if GameConfig.room_privacy_valid(priv):
		r["privacy"] = priv
	var owner: String = GameConfig.normalize_account_id(str(msg.get("owner_uid", "")))
	if not owner.is_empty():
		r["owner_uid"] = owner
	# Odadaki kullanıcı kimlikleri: oda sunucusu bunları giriş biletinden alır (doğrulanmış)
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
	if was_in_match and not bool(r["in_match"]):
		_hub.on_room_match_end(port)
	if int(r.get("pid", 0)) <= 0:
		r["pid"] = int(msg.get("pid", 0))
	r["ready"] = true
	r["last_seen"] = Time.get_unix_time_from_system()


## Hızlı Oyun için açık oda: herkese açık, maçta değil, dolu değil ve odadakilerle (ya da yoldakilerle)
## engelleme ilişkisi yok. Bulunamazsa 0. (MahalleHub çağırır.)
func find_public_room(uid: String) -> int:
	for port_v: Variant in _rooms.keys():
		var port: int = int(port_v)
		var r: Dictionary = _rooms[port] as Dictionary
		if not bool(r["public"]) or bool(r["in_match"]) or effective_players(port) >= GameConfig.NET_MAX_CLIENTS + 1:
			continue
		if _hub.entry_denied(r, uid).is_empty():
			return port
	return 0


## Odadaki oyuncu sayısı + henüz bağlanmamış yönlendirmeler (bağlanma süresi kadar geçerli).
func effective_players(port: int) -> int:
	var r: Dictionary = _rooms[port] as Dictionary
	var now_sec: float = Time.get_unix_time_from_system()
	var fresh: Array = []
	for t_v: Variant in r.get("reservations", []) as Array:
		var res: Dictionary = t_v as Dictionary
		if now_sec - float(res.get("t", 0.0)) <= GameConfig.NET_CONNECT_TIMEOUT_SEC and not (r.get("uids", []) as Array).has(str(res.get("uid", ""))):
			fresh.append(t_v)
	r["reservations"] = fresh
	return int(r["players"]) + fresh.size()


func reserve_slot(port: int, uid: String) -> void:
	var r: Dictionary = _rooms[port] as Dictionary
	(r["reservations"] as Array).append({"t": Time.get_unix_time_from_system(), "uid": uid})


## Yeni oda süreci açar (IP başına dakikalık sınır). {port, code} ya da {reason}. (MahalleHub çağırır.)
func spawn_for(ip: String, is_public: bool, privacy: String, owner_uid: String) -> Dictionary:
	if _rooms.size() >= GameConfig.MM_MAX_ROOMS:
		return {"reason": "Sunucu dolu, birazdan tekrar dene."}
	if not _rate_ok(ip, "spawn", GameConfig.MM_ROOM_SPAWN_PER_MIN_PER_IP):
		return {"reason": "Çok sık oda açtın, biraz bekle."}
	var new_room: Dictionary = _spawn_room(is_public, privacy, owner_uid)
	if new_room.is_empty():
		return {"reason": "Sunucu dolu, birazdan tekrar dene."}
	return new_room


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


func _spawn_room(is_public: bool, privacy: String, owner_uid: String) -> Dictionary:
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
		"--privacy=%s" % privacy,
	])
	if _tls_options != null:
		args.append("--tls")
	var pid: int = OS.create_process(OS.get_executable_path(), args)
	if pid <= 0:
		return {}
	_rooms[free_port] = {
		"code": code,
		"public": is_public,
		"privacy": privacy,
		"owner_uid": owner_uid,
		"allow": {},
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


func _send_json(peer: StreamPeer, payload: Dictionary) -> void:
	NetStream.put_line(peer, payload)


# ---------------------------------------------------------------------------
# Faz 12.5: moderation.json (elle işaretlenen kimliklerin adı "Böcek #7K3M" görünür)
# ---------------------------------------------------------------------------

## Önce veri klasöründeki moderation.json (dışa aktarılmış sunucuda düzenlenebilir), yoksa server/moderation.json.
func _find_moderation_path() -> String:
	var in_data: String = _store.data_dir.path_join(GameConfig.MODERATION_FILE)
	if FileAccess.file_exists(in_data):
		return in_data
	return "res://server/" + GameConfig.MODERATION_FILE


## Dosya değiştiyse yeniden okur: {"hide_names": ["7K3MQX9P", ...]}
func _reload_moderation() -> void:
	if not FileAccess.file_exists(_moderation_path):
		_moderation_path = _find_moderation_path()
		if not FileAccess.file_exists(_moderation_path):
			return
	var mt: int = int(FileAccess.get_modified_time(_moderation_path))
	if mt == _moderation_mtime:
		return
	_moderation_mtime = mt
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(_moderation_path))
	if not (parsed is Dictionary):
		push_warning("[Matchmaker] moderation.json okunamadı.")
		return
	var hidden: Dictionary = {}
	for v: Variant in (parsed as Dictionary).get("hide_names", []) as Array:
		var uid: String = GameConfig.normalize_account_id(str(v))
		if not uid.is_empty():
			hidden[uid] = true
	_hub.hidden_names = hidden
	print("[Matchmaker] Moderasyon: %d gizli ad." % hidden.size())

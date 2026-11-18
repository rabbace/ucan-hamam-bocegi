extends Node

## Faz 12.1–12.3: "Mahalle" — Böcek Kimliği, eşleştiriciye kalıcı TCP bağlantısı, durum ve arkadaşlık.
## Kimlik ve gizli anahtar user://hesap.cfg'de şifreli durur. Anahtar ve kurtarma kodu hiçbir zaman loglanmaz.
## Çevrimiçi özellik ilk kez kullanılınca (Çevrimiçi / Arkadaşlar ekranı) bağlanır; sonra her açılışta bağlanır.
## Ping 20 sn; kopunca 2, 4, 8 … 60 sn geri çekilmeyle yeniden bağlanır; arka planda 30 sn sonra kapanır.

signal status_changed
signal identity_changed
signal friends_changed
signal friend_request_received(info: Dictionary)
signal presence_changed(uid: String)

enum Link { OFF, CONNECTING, HELLO, ONLINE, WAIT_RETRY, AUTH_FAILED }

var account_id: String = ""
var link_state: int = Link.OFF
var last_error: String = ""
## Son bağlantı denemesi başarısızsa false: çevrimiçi özellikler gri görünür
var reachable: bool = true
var friends: Dictionary = {} # uid -> {id, name, char, title, state, room_n, room_max, last_seen}
var requests_in: Array = [] # [{id, name, char, title}]
var requests_out: Array = []
var recent_players: Array = [] # [{id, name, char, at}] en yenisi başta
var muhtar_count: int = 0
var list_loaded: bool = false
## Paylaşım bağlantısıyla gelen ve onay bekleyen kimlik
var pending_link_id: String = ""

var _token: String = ""
var _enabled: bool = false
var _server_mode: bool = false
var _account_path: String = GameConfig.ACCOUNT_PATH
var _peer: StreamPeerTCP = null
var _buf: PackedByteArray = PackedByteArray()
var _connect_started_ms: int = 0
var _retry_in: float = 0.0
var _backoff: float = GameConfig.MAHALLE_RECONNECT_MIN_SEC
var _ping_timer: float = 0.0
var _sync_timer: float = 0.0
var _profile_timer: float = 0.0
var _rid: int = 0
var _pending: Dictionary = {} # rid -> {cb, at_ms}
var _paused: bool = false
var _paused_at_ms: int = 0
var _bg_closed: bool = false
var _sent_room: String = "-"
var _sent_profile_key: String = ""
var _restore_req: Dictionary = {} # {id, code, cb}
var _offline_queue: Array = [] # bağlantı yokken gönderilen arkadaşlık istekleri (kimlikler)
var _last_list_ms: int = -100000

var _notice_layer: CanvasLayer = null
var _notice_panel: PanelContainer = null
var _notice_queue: Array = [] # [{text, from_id}]
var _notice_left: float = 0.0


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--matchmaker") or args.has("--room"):
		_server_mode = true
		set_process(false)
		return
	for a: String in args:
		if a.begins_with("--hesap="):
			_account_path = a.substr(8)
	for a: String in OS.get_cmdline_args() + args:
		if a.begins_with(GameConfig.FRIEND_LINK_SCHEME):
			handle_deep_link(a)
	_poll_platform_link()
	_load_account()
	NetworkManager.results_ready.connect(_on_results_ready)
	_build_notice_layer()
	if _enabled:
		_open.call_deferred()


# ---------------------------------------------------------------------------
# Hesap dosyası
# ---------------------------------------------------------------------------

func _load_account() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if not FileAccess.file_exists(_account_path) or cfg.load_encrypted_pass(_account_path, GameConfig.ACCOUNT_SAVE_PASS) != OK:
		return
	account_id = GameConfig.normalize_account_id(str(cfg.get_value("hesap", "id", "")))
	_token = str(cfg.get_value("hesap", "token", ""))
	_enabled = bool(cfg.get_value("hesap", "enabled", false)) or not account_id.is_empty()
	muhtar_count = int(cfg.get_value("hesap", "muhtar", 0))
	recent_players = cfg.get_value("hesap", "recent", []) as Array
	_offline_queue = cfg.get_value("hesap", "queue", []) as Array


func _save_account() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("hesap", "id", account_id)
	cfg.set_value("hesap", "token", _token)
	cfg.set_value("hesap", "enabled", _enabled)
	cfg.set_value("hesap", "muhtar", muhtar_count)
	cfg.set_value("hesap", "recent", recent_players)
	cfg.set_value("hesap", "queue", _offline_queue)
	cfg.save_encrypted_pass(_account_path, GameConfig.ACCOUNT_SAVE_PASS)


func has_account() -> bool:
	return not account_id.is_empty()


func formatted_id() -> String:
	return GameConfig.format_account_id(account_id)


func is_online() -> bool:
	return link_state == Link.ONLINE


func is_connecting() -> bool:
	return link_state == Link.CONNECTING or link_state == Link.HELLO


func is_auth_failed() -> bool:
	return link_state == Link.AUTH_FAILED


## Çevrimiçi bir özelliğe girildi: kimlik yoksa alınır, bağlantı açılır.
func activate() -> void:
	if _server_mode:
		return
	if not _enabled:
		_enabled = true
		_save_account()
	if link_state == Link.OFF or link_state == Link.WAIT_RETRY:
		_backoff = GameConfig.MAHALLE_RECONNECT_MIN_SEC
		_open()


## Kimliği doğrulanamayınca (başka cihazda geri yüklendi) bu cihaz için yeni kimlik alır.
func reset_identity() -> void:
	account_id = ""
	_token = ""
	friends.clear()
	requests_in.clear()
	requests_out.clear()
	list_loaded = false
	_save_account()
	identity_changed.emit()
	_close_link(Link.OFF)
	activate()


# ---------------------------------------------------------------------------
# Bağlantı
# ---------------------------------------------------------------------------

func _open() -> void:
	if _server_mode:
		return
	_close_link(Link.CONNECTING)
	_peer = StreamPeerTCP.new()
	_buf = PackedByteArray()
	_connect_started_ms = Time.get_ticks_msec()
	if _peer.connect_to_host(NetworkManager.server_host, GameConfig.MATCHMAKER_PORT) != OK:
		_fail("Sunucuya ulaşılamadı.")
		return
	status_changed.emit()


func _close_link(new_state: int) -> void:
	if _peer != null:
		_peer.disconnect_from_host()
	_peer = null
	_buf = PackedByteArray()
	var was_online: bool = link_state == Link.ONLINE
	link_state = new_state
	for rid_v: Variant in _pending.keys():
		var cb: Callable = (_pending[rid_v] as Dictionary)["cb"] as Callable
		if cb.is_valid():
			cb.call({"ok": false, "reason": "Bağlantı koptu."})
	_pending.clear()
	if was_online:
		# Arkadaşların durumu artık bilinmiyor
		for f_v: Variant in friends.values():
			(f_v as Dictionary)["state"] = GameConfig.PRESENCE_OFFLINE
		friends_changed.emit()
	status_changed.emit()


## Bağlantı başarısız: geri çekilmeli yeniden deneme.
func _fail(reason: String) -> void:
	last_error = reason
	reachable = false
	var was_restore: bool = not _restore_req.is_empty()
	if was_restore:
		_finish_restore({"ok": false, "reason": reason})
		if account_id.is_empty():
			_close_link(Link.OFF)
			return
	_close_link(Link.WAIT_RETRY)
	_retry_in = _backoff
	_backoff = minf(_backoff * 2.0, GameConfig.MAHALLE_RECONNECT_MAX_SEC)


func _process(delta: float) -> void:
	_update_background()
	_update_notice(delta)
	match link_state:
		Link.WAIT_RETRY:
			if _bg_closed:
				return
			_retry_in -= delta
			if _retry_in <= 0.0:
				_open()
		Link.CONNECTING:
			_peer.poll()
			var st: StreamPeerTCP.Status = _peer.get_status()
			if st == StreamPeerTCP.STATUS_CONNECTED:
				link_state = Link.HELLO
				_send_hello()
			elif st == StreamPeerTCP.STATUS_ERROR or st == StreamPeerTCP.STATUS_NONE \
					or Time.get_ticks_msec() - _connect_started_ms > int(GameConfig.MAHALLE_CONNECT_TIMEOUT_SEC * 1000.0):
				_fail("Sunucuya ulaşılamadı.")
		Link.HELLO, Link.ONLINE:
			_poll_peer()
			if link_state == Link.HELLO and Time.get_ticks_msec() - _connect_started_ms > int(GameConfig.MAHALLE_CONNECT_TIMEOUT_SEC * 2000.0):
				_fail("Sunucu yanıt vermedi.")
			elif link_state == Link.ONLINE:
				_update_online(delta)


func _poll_peer() -> void:
	if _peer == null:
		return
	_peer.poll()
	if _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		_fail("Bağlantı koptu.")
		return
	var avail: int = _peer.get_available_bytes()
	if avail <= 0:
		return
	if _buf.size() + avail > GameConfig.MAHALLE_READ_MAX:
		_fail("Sunucudan geçersiz veri.")
		return
	var res: Array = _peer.get_data(avail)
	if int(res[0]) != OK:
		_fail("Bağlantı koptu.")
		return
	_buf.append_array(res[1] as PackedByteArray)
	var nl: int = _buf.find(10)
	while nl != -1 and _peer != null:
		var line: String = _buf.slice(0, nl).get_string_from_utf8().strip_edges()
		_buf = _buf.slice(nl + 1)
		if not line.is_empty():
			var parsed: Variant = JSON.parse_string(line)
			if parsed is Dictionary:
				_handle(parsed as Dictionary)
		nl = _buf.find(10) if _peer != null else -1


func _update_online(delta: float) -> void:
	_ping_timer += delta
	if _ping_timer >= GameConfig.MAHALLE_PING_SEC:
		_ping_timer = 0.0
		_send_raw({"op": "ping"})
	var now_ms: int = Time.get_ticks_msec()
	for rid_v: Variant in _pending.keys():
		var p: Dictionary = _pending[rid_v] as Dictionary
		if now_ms - int(p["at_ms"]) > int(GameConfig.MAHALLE_REQUEST_TIMEOUT_SEC * 1000.0):
			_pending.erase(rid_v)
			var cb: Callable = p["cb"] as Callable
			if cb.is_valid():
				cb.call({"ok": false, "reason": "Sunucu yanıt vermedi."})
	_sync_timer += delta
	if _sync_timer >= GameConfig.MAHALLE_SYNC_CHECK_SEC:
		_sync_timer = 0.0
		_sync_room_status()
	_profile_timer += delta
	if _profile_timer >= GameConfig.MAHALLE_PROFILE_CHECK_SEC:
		_profile_timer = 0.0
		_sync_profile()


func _send_hello() -> void:
	var msg: Dictionary = {
		"op": "hello",
		"version": GameConfig.NET_VERSION,
		"name": NetworkManager.local_player_name,
		"char": NetworkManager.selected_char_id,
	}
	if not _restore_req.is_empty():
		msg["id"] = str(_restore_req["id"])
		msg["recovery"] = str(_restore_req["code"])
	elif not account_id.is_empty():
		msg["id"] = account_id
		msg["token"] = _token
	_send_raw(msg)


func _send_raw(payload: Dictionary) -> void:
	if _peer == null or _peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	_peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())


## İstek gönderir; yanıt (ya da hata) cb'ye {ok, ...} olarak gelir.
func request(op: String, data: Dictionary, cb: Callable) -> void:
	if not is_online():
		if cb.is_valid():
			cb.call({"ok": false, "reason": "Mahalle'ye bağlı değilsin. İnternetini kontrol et."})
		return
	_rid += 1
	var payload: Dictionary = data.duplicate()
	payload["op"] = op
	payload["rid"] = _rid
	_pending[_rid] = {"cb": cb, "at_ms": Time.get_ticks_msec()}
	_send_raw(payload)


# ---------------------------------------------------------------------------
# Sunucu mesajları
# ---------------------------------------------------------------------------

func _handle(msg: Dictionary) -> void:
	match str(msg.get("op", "")):
		"welcome":
			_on_welcome(msg)
		"error":
			_on_error(msg)
		"kicked":
			_on_kicked(msg)
		"res":
			var rid: int = int(msg.get("rid", 0))
			if _pending.has(rid):
				var cb: Callable = (_pending[rid] as Dictionary)["cb"] as Callable
				_pending.erase(rid)
				if cb.is_valid():
					cb.call(msg)
		"presence":
			var uid: String = str(msg.get("id", ""))
			if friends.has(uid):
				var f: Dictionary = friends[uid] as Dictionary
				for k: String in ["state", "room_n", "room_max", "last_seen"]:
					if msg.has(k):
						f[k] = msg[k]
				presence_changed.emit(uid)
				friends_changed.emit()
		"friend_request":
			var info: Dictionary = msg.get("from", {}) as Dictionary
			var fid: String = str(info.get("id", ""))
			if not fid.is_empty() and _index_of(requests_in, fid) == -1:
				requests_in.append(info)
				friends_changed.emit()
				friend_request_received.emit(info)
				_queue_notice("%s (%s) arkadaş olmak istiyor" % [str(info.get("name", "Böcek")), GameConfig.format_account_id(fid)], fid)
		"friend_added":
			var fe: Dictionary = msg.get("friend", {}) as Dictionary
			var aid: String = str(fe.get("id", ""))
			if not aid.is_empty():
				var was_out: bool = _index_of(requests_out, aid) != -1
				friends[aid] = fe
				_remove_from(requests_in, aid)
				_remove_from(requests_out, aid)
				friends_changed.emit()
				if was_out:
					_queue_notice("%s artık arkadaşın!" % str(fe.get("name", "Böcek")), "")
		"friend_removed":
			friends.erase(str(msg.get("id", "")))
			friends_changed.emit()
		"request_gone":
			_remove_from(requests_out, str(msg.get("id", "")))
			_remove_from(requests_in, str(msg.get("id", "")))
			friends_changed.emit()


func _on_welcome(msg: Dictionary) -> void:
	var new_id: String = GameConfig.normalize_account_id(str(msg.get("id", "")))
	if new_id.is_empty():
		_fail("Sunucudan geçersiz yanıt.")
		return
	var id_changed: bool = new_id != account_id
	if msg.has("token"):
		_token = str(msg["token"])
	if id_changed:
		friends.clear()
		requests_in.clear()
		requests_out.clear()
		list_loaded = false
	account_id = new_id
	_enabled = true
	_save_account()
	link_state = Link.ONLINE
	reachable = true
	last_error = ""
	_backoff = GameConfig.MAHALLE_RECONNECT_MIN_SEC
	_ping_timer = 0.0
	_sent_room = "-"
	_sent_profile_key = ""
	if not _restore_req.is_empty():
		_finish_restore({"ok": true, "id": account_id})
	if id_changed:
		identity_changed.emit()
	status_changed.emit()
	_sync_profile()
	_sync_room_status()
	refresh_list(true)
	_flush_offline_queue()


func _on_error(msg: Dictionary) -> void:
	var code: String = str(msg.get("code", ""))
	var reason: String = str(msg.get("reason", "Bağlanılamadı."))
	if not _restore_req.is_empty():
		# Geri yükleme başarısız: eski kimlikle devam
		_finish_restore({"ok": false, "reason": reason})
		last_error = reason
		if account_id.is_empty():
			# Bu cihazda kimlik yok: yanlış kodla yeni kimlik açılmasın
			_close_link(Link.OFF)
		else:
			_close_link(Link.WAIT_RETRY)
			_retry_in = GameConfig.MAHALLE_RECONNECT_MIN_SEC
		return
	if code == "auth":
		last_error = reason
		_close_link(Link.AUTH_FAILED)
	elif code == "version":
		last_error = reason
		_close_link(Link.OFF)
	else:
		_fail(reason)
		reachable = true


func _on_kicked(msg: Dictionary) -> void:
	var code: String = str(msg.get("code", ""))
	last_error = str(msg.get("reason", ""))
	if code == "restored":
		_close_link(Link.AUTH_FAILED)
	elif code == "replaced":
		_close_link(Link.OFF)
	else:
		_close_link(Link.WAIT_RETRY)
		_retry_in = GameConfig.MM_SESSION_BAN_SEC


# ---------------------------------------------------------------------------
# Durum ve profil eşitleme
# ---------------------------------------------------------------------------

## Ayrılmış bir odadaysa oda kodu bildirilir (eşleştirici oda sunucusunun listesiyle çapraz kontrol eder).
func _sync_room_status() -> void:
	var code: String = ""
	if NetworkManager.is_dedicated_mode and NetworkManager.multiplayer.multiplayer_peer != null and not NetworkManager.room_code.is_empty():
		code = NetworkManager.room_code
	if code != _sent_room:
		_sent_room = code
		_send_raw({"op": "status", "room": code})


func _sync_profile() -> void:
	var prof: Vector2 = NetworkManager.get_local_profile()
	var data: Dictionary = {
		"name": NetworkManager.local_player_name,
		"char": NetworkManager.selected_char_id,
		"title": Monetization.album_title_id(),
		"matches": int(prof.y),
		"muhtar": muhtar_count,
		"album": Monetization.album_open_count(),
	}
	var key: String = JSON.stringify(data)
	if key == _sent_profile_key:
		return
	_sent_profile_key = key
	data["op"] = "profile"
	_send_raw(data)


func _on_results_ready(results: Array) -> void:
	if not NetworkManager.is_multiplayer_match or NetworkManager.multiplayer.multiplayer_peer == null:
		return
	var my_pid: int = NetworkManager.multiplayer.get_unique_id()
	var changed: bool = false
	for r_v: Variant in results:
		var r: Dictionary = r_v as Dictionary
		var pid: int = int(r.get("peer_id", 0))
		if pid == my_pid:
			if int(r.get("rank", 0)) == 1:
				var crown: int = int((NetworkManager.players.get(pid, {}) as Dictionary).get("crown", 0))
				if crown == GameConfig.CROWN_MUHTAR_STREAK:
					muhtar_count += 1
					changed = true
			continue
		if bool(r.get("is_bot", false)):
			continue
		var uid: String = GameConfig.normalize_account_id(str(r.get("uid", "")))
		if uid.is_empty() or uid == account_id:
			continue
		_remove_from(recent_players, uid)
		recent_players.push_front({
			"id": uid,
			"name": str(r.get("name", "Böcek")),
			"char": str(r.get("char_id", "klasik")),
			"at": int(Time.get_unix_time_from_system()),
		})
		changed = true
	while recent_players.size() > GameConfig.RECENT_PLAYERS_MAX:
		recent_players.pop_back()
	if changed:
		_save_account()
		friends_changed.emit()


# ---------------------------------------------------------------------------
# Arkadaşlık API'si
# ---------------------------------------------------------------------------

func refresh_list(force: bool = false) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if not force and now_ms - _last_list_ms < int(GameConfig.MAHALLE_LIST_MIN_INTERVAL_SEC * 1000.0):
		return
	_last_list_ms = now_ms
	request("list", {}, func(res: Dictionary) -> void:
		if not bool(res.get("ok", false)):
			return
		friends.clear()
		for f_v: Variant in res.get("friends", []) as Array:
			var f: Dictionary = f_v as Dictionary
			friends[str(f.get("id", ""))] = f
		requests_in = (res.get("requests_in", []) as Array).duplicate()
		requests_out = (res.get("requests_out", []) as Array).duplicate()
		list_loaded = true
		friends_changed.emit()
	)


## Kimlikle istek. Bağlantı yoksa sıraya alınır, bağlanınca gönderilir.
func send_friend_request(raw_id: String, cb: Callable) -> void:
	var uid: String = GameConfig.normalize_account_id(raw_id)
	if uid.is_empty():
		cb.call({"ok": false, "reason": "Kimlik 8 karakter olmalı (ör. #7K3M-QX9P)."})
		return
	if uid == account_id:
		cb.call({"ok": false, "reason": "Bu senin kendi kimliğin."})
		return
	if not is_online():
		if not _offline_queue.has(uid) and _offline_queue.size() < GameConfig.MAHALLE_OFFLINE_QUEUE_MAX:
			_offline_queue.append(uid)
			_save_account()
		activate()
		cb.call({"ok": true, "queued": true, "reason": "İnternet gelince istek gönderilecek."})
		return
	request("friend_request", {"id": uid}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			if bool(res.get("accepted", false)):
				var fe: Dictionary = res.get("friend", {}) as Dictionary
				friends[str(fe.get("id", uid))] = fe
				_remove_from(requests_in, uid)
			elif _index_of(requests_out, uid) == -1:
				requests_out.append({"id": uid, "name": _known_name(uid), "char": "klasik"})
			friends_changed.emit()
			refresh_list(true)
		cb.call(res)
	)


func respond_request(uid: String, accept: bool, cb: Callable = Callable()) -> void:
	request("friend_respond", {"id": uid, "accept": accept}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			_remove_from(requests_in, uid)
			if accept and res.has("friend"):
				var fe: Dictionary = res["friend"] as Dictionary
				friends[str(fe.get("id", uid))] = fe
			friends_changed.emit()
		if cb.is_valid():
			cb.call(res)
	)


func remove_friend(uid: String, cb: Callable = Callable()) -> void:
	request("friend_remove", {"id": uid}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			friends.erase(uid)
			friends_changed.emit()
		if cb.is_valid():
			cb.call(res)
	)


func get_profile(uid: String, cb: Callable) -> void:
	request("get_profile", {"id": uid}, cb)


func new_recovery_code(cb: Callable) -> void:
	request("recovery_new", {}, cb)


## Kimlik + kurtarma kodu ile geri yükleme. Başarılıysa bu cihaz yeni anahtarı alır, eski cihazınki geçersizleşir.
func restore(raw_id: String, raw_code: String, cb: Callable) -> void:
	var uid: String = GameConfig.normalize_account_id(raw_id)
	var code: String = GameConfig.normalize_recovery_code(raw_code)
	if uid.is_empty():
		cb.call({"ok": false, "reason": "Kimlik 8 karakter olmalı (ör. #7K3M-QX9P)."})
		return
	if code.is_empty():
		cb.call({"ok": false, "reason": "Kurtarma kodu 16 karakter olmalı."})
		return
	_restore_req = {"id": uid, "code": code, "cb": cb}
	_enabled = true
	_backoff = GameConfig.MAHALLE_RECONNECT_MIN_SEC
	_open()


func _finish_restore(res: Dictionary) -> void:
	var cb: Callable = _restore_req.get("cb", Callable()) as Callable
	_restore_req = {}
	if cb.is_valid():
		cb.call(res)


func _flush_offline_queue() -> void:
	if _offline_queue.is_empty():
		return
	var q: Array = _offline_queue.duplicate()
	_offline_queue.clear()
	_save_account()
	for uid_v: Variant in q:
		# Yanıt yalnızca listeyi tazeler; sonuç arkadaş listesinde görünür
		send_friend_request(str(uid_v), func(_res: Dictionary) -> void: refresh_list())


## self / friend / out / in / none
func relation(uid: String) -> String:
	if uid.is_empty():
		return "none"
	if uid == account_id:
		return "self"
	if friends.has(uid):
		return "friend"
	if _index_of(requests_out, uid) != -1 or _offline_queue.has(uid):
		return "out"
	if _index_of(requests_in, uid) != -1:
		return "in"
	return "none"


## Odada (0) → maçta (1) → çevrimiçi (2) → çevrimdışı (3, son görülmeye göre).
func sorted_friends() -> Array:
	var arr: Array = friends.values()
	var order: Dictionary = {"room": 0, "match": 1, "online": 2, "offline": 3}
	arr.sort_custom(func(a: Variant, b: Variant) -> bool:
		var da: Dictionary = a as Dictionary
		var db: Dictionary = b as Dictionary
		var oa: int = int(order.get(str(da.get("state", "offline")), 3))
		var ob: int = int(order.get(str(db.get("state", "offline")), 3))
		if oa != ob:
			return oa < ob
		if oa == 3:
			return int(da.get("last_seen", 0)) > int(db.get("last_seen", 0))
		return str(da.get("name", "")).naturalnocasecmp_to(str(db.get("name", ""))) < 0
	)
	return arr


static func presence_text(entry: Dictionary) -> String:
	match str(entry.get("state", "offline")):
		"online":
			return "Çevrimiçi"
		"room":
			return "Odada (%d/%d)" % [int(entry.get("room_n", 1)), int(entry.get("room_max", GameConfig.NET_MAX_CLIENTS + 1))]
		"match":
			return "Maçta"
	return GameConfig.last_seen_text(int(entry.get("last_seen", 0)), int(Time.get_unix_time_from_system()))


func link_status_text() -> String:
	match link_state:
		Link.ONLINE:
			return "Mahalle'ye bağlı"
		Link.CONNECTING, Link.HELLO:
			return "Mahalle'ye bağlanılıyor..."
		Link.WAIT_RETRY:
			return "Bağlantı yok, tekrar denenecek. %s" % last_error
		Link.AUTH_FAILED:
			return last_error if not last_error.is_empty() else "Kimlik doğrulanamadı."
	return last_error if not last_error.is_empty() else "Çevrimdışı"


func share_link() -> String:
	return "%s/arkadas.html?k=%s" % [GameConfig.SHARE_SITE_URL, account_id]


func share_text() -> String:
	return GameConfig.SHARE_TEXT_FRIEND.replace("{kimlik}", formatted_id()).replace("{link}", share_link())


## ucanbocek://arkadas/<ID> ya da paylaşım sayfası bağlantısı: onay için bekletilir.
func handle_deep_link(url: String) -> void:
	var uid: String = GameConfig.normalize_account_id(url)
	if not uid.is_empty() and uid != account_id:
		pending_link_id = uid


## Android'de bağlantıyı ileten küçük eklenti varsa (bkz. web/README.md) bekleyen bağlantıyı alır.
func _poll_platform_link() -> void:
	if not Engine.has_singleton("UcanBocekDeepLink"):
		return
	var url: String = str(Engine.get_singleton("UcanBocekDeepLink").call("getPendingLink"))
	if url.begins_with(GameConfig.FRIEND_LINK_SCHEME):
		handle_deep_link(url)


func _known_name(uid: String) -> String:
	var i: int = _index_of(recent_players, uid)
	return str((recent_players[i] as Dictionary).get("name", "Böcek")) if i != -1 else GameConfig.format_account_id(uid)


static func _index_of(arr: Array, uid: String) -> int:
	for i: int in range(arr.size()):
		if str((arr[i] as Dictionary).get("id", "")) == uid:
			return i
	return -1


static func _remove_from(arr: Array, uid: String) -> void:
	var i: int = _index_of(arr, uid)
	while i != -1:
		arr.remove_at(i)
		i = _index_of(arr, uid)


# ---------------------------------------------------------------------------
# Arka plan
# ---------------------------------------------------------------------------

func _notification(what: int) -> void:
	if _server_mode:
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused = true
		_paused_at_ms = Time.get_ticks_msec()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		var long_away: bool = _paused and Time.get_ticks_msec() - _paused_at_ms >= int(GameConfig.MAHALLE_BACKGROUND_CLOSE_SEC * 1000.0)
		_paused = false
		_poll_platform_link()
		if (_bg_closed or long_away) and _enabled:
			_bg_closed = false
			_backoff = GameConfig.MAHALLE_RECONNECT_MIN_SEC
			_open()


## Arka planda 30 sn geçince bağlantı kapanır (geri gelince yeniden açılır).
func _update_background() -> void:
	if not _paused or _bg_closed:
		return
	if Time.get_ticks_msec() - _paused_at_ms >= int(GameConfig.MAHALLE_BACKGROUND_CLOSE_SEC * 1000.0):
		_bg_closed = true
		_close_link(Link.WAIT_RETRY)


# ---------------------------------------------------------------------------
# Gelen istek bildirim şeridi (maç sırasında bekletilir)
# ---------------------------------------------------------------------------

func _build_notice_layer() -> void:
	_notice_layer = CanvasLayer.new()
	_notice_layer.name = "MahalleNotice"
	_notice_layer.layer = 110
	_notice_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_notice_layer)


func _queue_notice(text: String, from_id: String) -> void:
	_notice_queue.append({"text": text, "from_id": from_id})


func _update_notice(delta: float) -> void:
	if _notice_panel != null and is_instance_valid(_notice_panel):
		_notice_left -= delta
		if _notice_left <= 0.0 or NetworkManager.in_match:
			_notice_panel.queue_free()
			_notice_panel = null
		return
	if _notice_queue.is_empty() or NetworkManager.in_match:
		return
	var n: Dictionary = _notice_queue.pop_front() as Dictionary
	var fid: String = str(n.get("from_id", ""))
	# Bu arada kabul/ret edildiyse butonlu şerit gösterilmez
	if not fid.is_empty() and _index_of(requests_in, fid) == -1:
		return
	_show_notice(str(n["text"]), fid)


func _show_notice(text: String, from_id: String) -> void:
	var font: Font = AssetHelper.get_ui_font()
	var vis: Vector2 = get_viewport().get_visible_rect().size
	_notice_panel = PanelContainer.new()
	_notice_panel.name = "FriendNotice"
	ComicUiHelper.style_bitten_panel(_notice_panel, GameConfig.COLOR_CREAM, 901, GameConfig.SP_S)
	var w: float = minf(vis.x - GameConfig.SCREEN_GUTTER * 2.0, GameConfig.MODAL_MAX_WIDTH)
	_notice_panel.custom_minimum_size = Vector2(w, 0.0)
	_notice_panel.position = Vector2((vis.x - w) * 0.5, _top_inset() + GameConfig.SCREEN_GUTTER)
	_notice_layer.add_child(_notice_panel)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	_notice_panel.add_child(v)
	var lbl: Label = Label.new()
	lbl.name = "Text"
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, false)
	v.add_child(lbl)
	_notice_left = GameConfig.MAHALLE_NOTICE_SEC
	if from_id.is_empty():
		return
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	v.add_child(row)
	var acc: Button = Button.new()
	acc.name = "AcceptButton"
	acc.text = "Kabul"
	acc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acc.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(acc, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BODY, 902)
	row.add_child(acc)
	var rej: Button = Button.new()
	rej.name = "RejectButton"
	rej.text = "Reddet"
	rej.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rej.custom_minimum_size = Vector2(0.0, 56.0)
	ComicUiHelper.style_bitten_button(rej, GameConfig.COLOR_PEACH, font, GameConfig.FS_BODY, 903)
	row.add_child(rej)
	var panel: PanelContainer = _notice_panel
	acc.pressed.connect(func() -> void:
		respond_request(from_id, true)
		panel.queue_free()
	)
	rej.pressed.connect(func() -> void:
		respond_request(from_id, false)
		panel.queue_free()
	)


func _top_inset() -> float:
	var win: Vector2i = DisplayServer.window_get_size()
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var vis: Vector2 = get_viewport().get_visible_rect().size
	if win.y <= 0 or safe.size.y <= 0 or (safe.size.x >= win.x and safe.size.y >= win.y):
		return 0.0
	return maxf(0.0, float(safe.position.y)) * vis.y / float(win.y)

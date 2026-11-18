extends Node

## Faz 12.1–12.3: "Mahalle" — Böcek Kimliği, eşleştiriciye kalıcı TCP bağlantısı, durum ve arkadaşlık.
## Kimlik ve gizli anahtar user://hesap.cfg'de şifreli durur. Anahtar ve kurtarma kodu hiçbir zaman loglanmaz.
## Çevrimiçi özellik ilk kez kullanılınca (Çevrimiçi / Arkadaşlar ekranı) bağlanır; sonra her açılışta bağlanır.
## Ping 20 sn; kopunca 2, 4, 8 … 60 sn geri çekilmeyle yeniden bağlanır; arka planda 30 sn sonra kapanır.
## Faz 12.4–12.5: odalara giriş (giriş bileti), davetler ve davet penceresi, "maç bitince otomatik katıl",
## engelleme, bildirme, hesap silme; GameConfig.tls_enabled() ise bağlantı TLS ile şifrelenir.

const PORTRAIT_SCENE: PackedScene = preload("res://scenes/ui/CharacterPortrait.tscn")
const INVITE_PORTRAIT: float = 180.0

signal status_changed
signal identity_changed
signal friends_changed
signal friend_request_received(info: Dictionary)
signal presence_changed(uid: String)
signal invites_changed
## Hesap silindi (cihazdaki hesap.cfg de silindi)
signal account_deleted

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
## Bekleyen davetler: [{from: {id, name, char, title}, code, n, max, exp}]
var invites: Array = []
## "Maç bitince otomatik katıl" bekleyen arkadaş kimliği (ya da davet eden)
var auto_join_wait: String = ""

var _token: String = ""
var _enabled: bool = false
var _server_mode: bool = false
var _account_path: String = GameConfig.ACCOUNT_PATH
var _tcp: StreamPeerTCP = null
var _peer: StreamPeer = null # TCP ya da TLS
var _buf: PackedByteArray = PackedByteArray()
var _connect_started_ms: int = 0
var _retry_in: float = 0.0
var _backoff: float = GameConfig.MAHALLE_RECONNECT_MIN_SEC
var _ping_timer: float = 0.0
var _profile_timer: float = 0.0
var _rid: int = 0
var _pending: Dictionary = {} # rid -> {cb, at_ms}
var _paused: bool = false
var _paused_at_ms: int = 0
var _bg_closed: bool = false
var _sent_profile_key: String = ""
var _restore_req: Dictionary = {} # {id, code, cb}
var _offline_queue: Array = [] # bağlantı yokken gönderilen arkadaşlık istekleri (kimlikler)
var _last_list_ms: int = -100000

var _notice_layer: CanvasLayer = null
var _notice_panel: PanelContainer = null
var _notice_queue: Array = [] # [{text, from_id}]
var _notice_left: float = 0.0
var _invite_queue: Array = [] # gösterilecek davetler (maç sırasında bekletilir)
var _invite_modal: Control = null
var _invite_left: float = 0.0
var _deferred: Array = [] # bağlantı bekleyen istekler [{op, data, cb, until_ms}]
var _join_pending: bool = false


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
	NetworkManager.connection_succeeded.connect(_on_room_connected)
	NetStream.warn_if_insecure("İstemci")
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
	_tcp = StreamPeerTCP.new()
	_peer = _tcp
	_buf = PackedByteArray()
	_connect_started_ms = Time.get_ticks_msec()
	if _tcp.connect_to_host(NetworkManager.server_host, GameConfig.MATCHMAKER_PORT) != OK:
		_fail("Sunucuya ulaşılamadı.")
		return
	status_changed.emit()


func _close_link(new_state: int) -> void:
	if _peer != null:
		NetStream.close(_peer)
	if _tcp != null:
		_tcp.disconnect_from_host()
	_peer = null
	_tcp = null
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
	_update_invite_popup(delta)
	_update_deferred()
	match link_state:
		Link.WAIT_RETRY:
			if _bg_closed:
				return
			_retry_in -= delta
			if _retry_in <= 0.0:
				_open()
		Link.CONNECTING:
			var st: int = NetStream.poll_state(_peer)
			if st == NetStream.OK_STATE and _peer is StreamPeerTCP and GameConfig.tls_enabled():
				# TCP hazır: TLS el sıkışması başlar (sertifika ve alan adı doğrulanır)
				var tls: StreamPeerTLS = NetStream.wrap_client(_tcp, _tls_host(), NetStream.client_options())
				if tls == null:
					_fail("Güvenli bağlantı kurulamadı.")
				else:
					_peer = tls
			elif st == NetStream.OK_STATE:
				link_state = Link.HELLO
				_send_hello()
			elif st == NetStream.DEAD or Time.get_ticks_msec() - _connect_started_ms > int(GameConfig.MAHALLE_CONNECT_TIMEOUT_SEC * 1000.0):
				_fail("Güvenli bağlantı kurulamadı." if _peer is StreamPeerTLS else "Sunucuya ulaşılamadı.")
		Link.HELLO, Link.ONLINE:
			_poll_peer()
			if link_state == Link.HELLO and Time.get_ticks_msec() - _connect_started_ms > int(GameConfig.MAHALLE_CONNECT_TIMEOUT_SEC * 2000.0):
				_fail("Sunucu yanıt vermedi.")
			elif link_state == Link.ONLINE:
				_update_online(delta)


func _poll_peer() -> void:
	if _peer == null:
		return
	if NetStream.poll_state(_peer) != NetStream.OK_STATE:
		_fail("Bağlantı koptu.")
		return
	var avail: int = _peer.get_available_bytes()
	if avail <= 0:
		return
	if _buf.size() + avail > GameConfig.MAHALLE_READ_MAX:
		_fail("Sunucudan geçersiz veri.")
		return
	var res: Array = _peer.get_partial_data(avail)
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
	if _peer == null:
		return
	NetStream.put_line(_peer, payload)


## TLS'te doğrulanacak ad: sunucu adresi (debug'da "--tls-cn=" ile değiştirilebilir).
func _tls_host() -> String:
	return NetworkManager.server_host


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
		"invite":
			var inv: Dictionary = msg.get("invite", {}) as Dictionary
			_add_invite(inv)
			_invite_queue.append(inv)
		"auto_join":
			auto_join_wait = ""
			if NetworkManager.in_match:
				return
			_queue_notice("Maç bitti, odaya katılıyorsun (%s)..." % str(msg.get("code", "")), "")
			join_with(msg)
		"auto_join_failed":
			auto_join_wait = ""
			_queue_notice(str(msg.get("reason", "Odaya katılamadın.")), "")


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
	_sent_profile_key = ""
	if not _restore_req.is_empty():
		_finish_restore({"ok": true, "id": account_id})
	if id_changed:
		identity_changed.emit()
	status_changed.emit()
	_sync_profile()
	refresh_list(true)
	refresh_invites()
	_flush_offline_queue()
	_flush_deferred()


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
	elif code == "deleted":
		_wipe_local_account()
	elif code == "replaced":
		_close_link(Link.OFF)
	else:
		_close_link(Link.WAIT_RETRY)
		_retry_in = GameConfig.MM_SESSION_BAN_SEC


# ---------------------------------------------------------------------------
# Durum ve profil eşitleme
# ---------------------------------------------------------------------------

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
# Faz 12.4: odaya giriş (giriş bileti), davetler, arkadaşının odasına katılma
# ---------------------------------------------------------------------------

## Bağlı değilse bağlantıyı açar ve kısa süre bekler; bağlanınca isteği gönderir (bağlanamazsa cb hata alır).
func request_online(op: String, data: Dictionary, cb: Callable) -> void:
	if is_online():
		request(op, data, cb)
		return
	if _server_mode:
		cb.call({"ok": false, "reason": "Sunucu modunda kullanılamaz."})
		return
	activate()
	_deferred.append({"op": op, "data": data, "cb": cb, "until_ms": Time.get_ticks_msec() + int(GameConfig.MAHALLE_CONNECT_TIMEOUT_SEC * 2000.0)})


func _flush_deferred() -> void:
	var q: Array = _deferred.duplicate()
	_deferred.clear()
	for d_v: Variant in q:
		var d: Dictionary = d_v as Dictionary
		request(str(d["op"]), d["data"] as Dictionary, d["cb"] as Callable)


func _update_deferred() -> void:
	if _deferred.is_empty() or is_online():
		return
	var now_ms: int = Time.get_ticks_msec()
	var give_up: bool = link_state == Link.AUTH_FAILED or link_state == Link.OFF
	for i: int in range(_deferred.size() - 1, -1, -1):
		var d: Dictionary = _deferred[i] as Dictionary
		if give_up or now_ms > int(d["until_ms"]):
			_deferred.remove_at(i)
			var cb: Callable = d["cb"] as Callable
			if cb.is_valid():
				cb.call({"ok": false, "reason": last_error if not last_error.is_empty() else "Mahalle'ye bağlanılamadı. İnternetini kontrol et."})


## Yanıt bilet içeriyorsa odaya bağlanır, sonra cb.
func _join_cb(cb: Callable) -> Callable:
	return func(res: Dictionary) -> void:
		if bool(res.get("ok", false)) and not str(res.get("ticket", "")).is_empty():
			join_with(res)
		if cb.is_valid():
			cb.call(res)


func quick_play(cb: Callable) -> void:
	request_online("room_quick", {}, _join_cb(cb))


func create_room(privacy: String, cb: Callable) -> void:
	request_online("room_create", {"privacy": privacy}, _join_cb(cb))


func join_code(code: String, cb: Callable) -> void:
	request_online("room_join_code", {"code": code}, _join_cb(cb))


## Arkadaşlar listesindeki "Katıl". wait=true: maç sürüyorsa bitince otomatik katıl.
func join_friend(uid: String, wait: bool, cb: Callable) -> void:
	request_online("join_friend", {"id": uid, "wait": wait}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			if bool(res.get("waiting", false)):
				auto_join_wait = uid
				status_changed.emit()
			else:
				join_with(res)
		if cb.is_valid():
			cb.call(res)
	)


func cancel_auto_join() -> void:
	auto_join_wait = ""
	request("join_cancel", {}, Callable())
	status_changed.emit()


## Odadayken arkadaşını davet eder. Yanıtta offline=true ise paylaşım önerilir.
func invite_friend(uid: String, cb: Callable) -> void:
	request("invite", {"id": uid}, cb)


func refresh_invites() -> void:
	request("invites", {}, func(res: Dictionary) -> void:
		if not bool(res.get("ok", false)):
			return
		invites = (res.get("invites", []) as Array).duplicate()
		invites_changed.emit()
	)


func accept_invite(from_id: String, wait: bool, cb: Callable) -> void:
	request_online("invite_accept", {"from": from_id, "wait": wait}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			_remove_invite(from_id)
			if bool(res.get("waiting", false)):
				auto_join_wait = from_id
				status_changed.emit()
			else:
				join_with(res)
		elif not bool(res.get("in_match", false)) and not bool(res.get("denied", false)) and str(res.get("reason", "")).contains("Oda"):
			_remove_invite(from_id)
		if cb.is_valid():
			cb.call(res)
	)


func decline_invite(from_id: String) -> void:
	_remove_invite(from_id)
	request("invite_decline", {"from": from_id}, Callable())


## Süresi geçmemiş davetler (en yenisi sonda).
func live_invites() -> Array:
	var now: int = int(Time.get_unix_time_from_system())
	var out: Array = []
	for i_v: Variant in invites:
		if int((i_v as Dictionary).get("exp", 0)) >= now:
			out.append(i_v)
	return out


func _add_invite(inv: Dictionary) -> void:
	var fid: String = str((inv.get("from", {}) as Dictionary).get("id", ""))
	if fid.is_empty():
		return
	_remove_invite(fid, false)
	invites.append(inv)
	invites_changed.emit()


func _remove_invite(from_id: String, emit: bool = true) -> void:
	for i: int in range(invites.size() - 1, -1, -1):
		if str(((invites[i] as Dictionary).get("from", {}) as Dictionary).get("id", "")) == from_id:
			invites.remove_at(i)
	if emit:
		invites_changed.emit()


static func invite_text(inv: Dictionary) -> String:
	var from: Dictionary = inv.get("from", {}) as Dictionary
	return "%s seni mutfağa çağırıyor! (Oda: %s, %d/%d)" % [
		str(from.get("name", "Böcek")), str(inv.get("code", "")), int(inv.get("n", 1)), int(inv.get("max", GameConfig.NET_MAX_CLIENTS + 1))]


## Bileti alınmış odaya bağlanır; bağlanınca sahne Lobi'ye geçer (ana menü bunu kendisi yapar).
func join_with(res: Dictionary) -> bool:
	var port: int = int(res.get("port", 0))
	var ticket: String = str(res.get("ticket", ""))
	if port <= 0 or ticket.is_empty():
		return false
	_join_pending = true
	if not NetworkManager.connection_failed.is_connected(_on_room_connect_failed):
		NetworkManager.connection_failed.connect(_on_room_connect_failed)
	return NetworkManager.join_online_room(port, str(res.get("code", "")), bool(res.get("public", false)), ticket)


func _on_room_connected() -> void:
	if not _join_pending:
		return
	_join_pending = false
	if _on_main_menu():
		return
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")


func _on_room_connect_failed(reason: String) -> void:
	if not _join_pending:
		return
	_join_pending = false
	if _on_main_menu():
		return
	NetworkManager.pending_notice = reason
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_main_menu() -> bool:
	var cur: Node = get_tree().current_scene
	return cur != null and cur.scene_file_path == "res://scenes/ui/MainMenu.tscn"


# ---------------------------------------------------------------------------
# Faz 12.5: engelleme, bildirme, hesap silme
# ---------------------------------------------------------------------------

## Engelle: arkadaşlık ve istekler silinir; o kişi seni göremez, istek/davet gönderemez, aynı odaya giremez.
func block_user(uid: String, cb: Callable = Callable()) -> void:
	request("block", {"id": uid}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			friends.erase(uid)
			_remove_from(requests_in, uid)
			_remove_from(requests_out, uid)
			_remove_invite(uid)
			friends_changed.emit()
		if cb.is_valid():
			cb.call(res)
	)


func unblock_user(uid: String, cb: Callable = Callable()) -> void:
	request("unblock", {"id": uid}, cb)


func blocked_list(cb: Callable) -> void:
	request("blocked_list", {}, cb)


## Profil kartından bildirim (GameConfig.PROFILE_REPORT_REASONS).
func report_user(uid: String, reason_idx: int, cb: Callable) -> void:
	request("report", {"id": uid, "reason": reason_idx}, cb)


## Hesabımı Sil: kimliği yazarak onay. Başarılıysa cihazdaki hesap.cfg de silinir.
func delete_account(confirm_text: String, cb: Callable) -> void:
	var typed: String = GameConfig.normalize_account_id(confirm_text)
	if typed.is_empty() or typed != account_id:
		cb.call({"ok": false, "reason": "Onay için kendi kimliğini (%s) yaz." % formatted_id()})
		return
	request("delete_account", {"confirm": typed}, func(res: Dictionary) -> void:
		if bool(res.get("ok", false)):
			_wipe_local_account()
		cb.call(res)
	)


## Cihazdaki hesap bilgisini siler (Kırıntı, karakterler, satın alımlar ayrı dosyalarda kalır).
func _wipe_local_account() -> void:
	account_id = ""
	_token = ""
	_enabled = false
	friends.clear()
	requests_in.clear()
	requests_out.clear()
	invites.clear()
	recent_players.clear()
	_offline_queue.clear()
	_invite_queue.clear()
	muhtar_count = 0
	list_loaded = false
	auto_join_wait = ""
	var path: String = ProjectSettings.globalize_path(_account_path) if _account_path.begins_with("user://") else _account_path
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	_close_link(Link.OFF)
	last_error = "Hesabın silindi."
	reachable = true
	identity_changed.emit()
	friends_changed.emit()
	invites_changed.emit()
	account_deleted.emit()


# ---------------------------------------------------------------------------
# Davet penceresi: ortada, davet edenin portresi ve balonla; 30 sn sonra kendiliğinden kapanır.
# Maç sırasında bekletilir, maç bitince gösterilir. Kapanan davet "Bekleyen davetler"de kalır.
# ---------------------------------------------------------------------------

func _update_invite_popup(delta: float) -> void:
	if _invite_modal != null and is_instance_valid(_invite_modal):
		_invite_left -= delta
		var cd: Label = _invite_modal.find_child("Countdown", true, false) as Label
		if cd != null:
			cd.text = "%d sn" % ceili(maxf(_invite_left, 0.0))
		if _invite_left <= 0.0 or NetworkManager.in_match:
			_invite_modal.queue_free()
			_invite_modal = null
		return
	_invite_modal = null
	if _invite_queue.is_empty() or NetworkManager.in_match:
		return
	var inv: Dictionary = _invite_queue.pop_front() as Dictionary
	var fid: String = str((inv.get("from", {}) as Dictionary).get("id", ""))
	var still: bool = false
	for i_v: Variant in live_invites():
		if str(((i_v as Dictionary).get("from", {}) as Dictionary).get("id", "")) == fid:
			still = true
	if still:
		show_invite_popup(inv)


func show_invite_popup(inv: Dictionary) -> Control:
	var from: Dictionary = inv.get("from", {}) as Dictionary
	var fid: String = str(from.get("id", ""))
	var font: Font = AssetHelper.get_ui_font()
	var m: Dictionary = ComicUiHelper.build_modal(_notice_layer, "", GameConfig.COLOR_CREAM, 0.0, false)
	var root: Control = m["root"] as Control
	root.name = "ModalInvite"
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	var body: VBoxContainer = m["body"] as VBoxContainer

	# Balon (davet metni) ve altında davet edenin portresi
	var bubble: PanelContainer = PanelContainer.new()
	bubble.name = "Bubble"
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FFFDF8")
	sb.border_color = GameConfig.COLOR_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(22)
	sb.set_content_margin_all(GameConfig.SP_S)
	bubble.add_theme_stylebox_override("panel", sb)
	body.add_child(bubble)
	var txt: Label = Label.new()
	txt.name = "InviteText"
	txt.text = invite_text(inv)
	txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	txt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(txt, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	bubble.add_child(txt)
	var portrait: CharacterPortrait = PORTRAIT_SCENE.instantiate() as CharacterPortrait
	portrait.interactive = false
	portrait.custom_minimum_size = Vector2(INVITE_PORTRAIT, INVITE_PORTRAIT)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(portrait)
	var cid: String = str(from.get("char", "klasik"))
	portrait.setup(cid if CharacterData.CHARACTERS.has(cid) else "klasik", CharacterPortrait.EXPR_PROUD)
	var info: Label = Label.new()
	info.name = "Info"
	info.text = "%s · Davet 10 dk geçerli" % GameConfig.format_account_id(fid)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(info, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	body.add_child(info)

	var footer: VBoxContainer = m["footer"] as VBoxContainer
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	footer.add_child(row)
	var join_btn: Button = Button.new()
	join_btn.name = "JoinButton"
	join_btn.text = "Katıl"
	join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_btn.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(join_btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON, 930)
	row.add_child(join_btn)
	var later_btn: Button = Button.new()
	later_btn.name = "LaterButton"
	later_btn.text = "Sonra"
	later_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	later_btn.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(later_btn, GameConfig.COLOR_PEACH, font, GameConfig.FS_BUTTON, 931)
	row.add_child(later_btn)
	var cd: Label = Label.new()
	cd.name = "Countdown"
	cd.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(cd, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	footer.add_child(cd)

	var state: Dictionary = {"wait": false}
	join_btn.pressed.connect(func() -> void:
		join_btn.disabled = true
		accept_invite(fid, bool(state["wait"]), func(res: Dictionary) -> void:
			if not is_instance_valid(root):
				return
			if bool(res.get("ok", false)):
				if bool(res.get("waiting", false)):
					txt.text = "Tamam! Maç bitince otomatik katılacaksın."
					_invite_left = 3.0
				else:
					root.queue_free()
				return
			join_btn.disabled = false
			txt.text = str(res.get("reason", "Katılamadın."))
			if bool(res.get("in_match", false)):
				state["wait"] = true
				join_btn.text = "Maç bitince otomatik katıl"
		)
	)
	later_btn.pressed.connect(root.queue_free)
	_invite_modal = root
	_invite_left = GameConfig.INVITE_POPUP_SEC
	return root


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

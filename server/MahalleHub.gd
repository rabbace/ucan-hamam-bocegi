class_name MahalleHub
extends RefCounted

## Faz 12.2–12.3: Eşleştiricinin "Mahalle" katmanı — kimliği doğrulanmış kalıcı bağlantılar, durum ve arkadaşlık.
## Kısa ömürlü oda isteklerinden ayrı kurallar: hello + anahtar sonrası boşta kalma 60 sn (20 sn'lik ping ile canlı),
## kimlik başına en fazla 2 bağlantı (yenisi gelince en eskisi kapanır), kimlik başına dakikada 60 mesaj
## (aşan kimliğin bağlantıları kapanır, 5 dk bekletilir), IP başına 16 oturum, toplam MM_MAX_SESSIONS.
## Gizli anahtar ve kurtarma kodu hiçbir zaman loglanmaz.

const NAME_FILTER := preload("res://net/NameFilter.gd")

var store: UserStore = null
var rooms: Dictionary = {} # Matchmaker._rooms (port -> oda kaydı) referansı
var sessions: Dictionary = {} # uid -> Array[Dictionary] (Matchmaker istemci kayıtları)
var _rate_log: Dictionary = {} # anahtar -> Array[float]
var _banned_until: Dictionary = {} # uid -> unix sn
var _last_presence: Dictionary = {} # uid -> JSON metni


func _init(p_store: UserStore, p_rooms: Dictionary) -> void:
	store = p_store
	rooms = p_rooms


func session_count() -> int:
	var n: int = 0
	for arr_v: Variant in sessions.values():
		n += (arr_v as Array).size()
	return n


func _sessions_from_ip(ip: String) -> int:
	var n: int = 0
	for arr_v: Variant in sessions.values():
		for c_v: Variant in arr_v as Array:
			if str((c_v as Dictionary)["ip"]) == ip:
				n += 1
	return n


# ---------------------------------------------------------------------------
# hello: kimliksiz -> yeni kimlik; id+token -> doğrula; id+recovery -> geri yükle
# ---------------------------------------------------------------------------

## Kısa bağlantıyı kalıcı oturuma yükseltir. Bağlantı açık kalmalıysa true.
func handle_hello(c: Dictionary, msg: Dictionary) -> bool:
	var ip: String = str(c["ip"])
	if int(msg.get("version", -1)) != GameConfig.NET_VERSION:
		_send(c, {"op": "error", "code": "version", "reason": "Sürüm eski, oyunu güncelle."})
		return false
	if session_count() >= GameConfig.MM_MAX_SESSIONS:
		_send(c, {"op": "error", "code": "full", "reason": "Mahalle şu an çok kalabalık, birazdan tekrar dene."})
		return false
	if not bool(c["local"]) and _sessions_from_ip(ip) >= GameConfig.MM_MAX_SESSIONS_PER_IP:
		_send(c, {"op": "error", "code": "full", "reason": "Bu ağdan çok fazla bağlantı var."})
		return false
	var now: float = Time.get_unix_time_from_system()
	var raw_id: String = str(msg.get("id", ""))
	var uid: String = GameConfig.normalize_account_id(raw_id) if not raw_id.is_empty() else ""
	var token: String = str(msg.get("token", "")).substr(0, 128)
	var recovery: String = GameConfig.normalize_recovery_code(str(msg.get("recovery", "")))
	var p_name: String = NAME_FILTER.sanitize(str(msg.get("name", "")))
	var p_char: String = _clean_char(str(msg.get("char", "klasik")))
	var welcome: Dictionary = {"op": "welcome"}

	if not uid.is_empty() and float(_banned_until.get(uid, 0.0)) > now:
		_send(c, {"op": "error", "code": "rate", "reason": "Çok fazla istek. 5 dakika sonra tekrar dene."})
		return false
	if not _rate_peek(ip + "|authfail", GameConfig.MM_AUTH_FAIL_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC):
		_send(c, {"op": "error", "code": "rate", "reason": "Çok fazla deneme, biraz bekle."})
		return false

	if raw_id.is_empty():
		# Yeni kimlik (IP başına saatlik sınır)
		if not _rate_ok(ip + "|register", GameConfig.MM_REGISTER_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC):
			_send(c, {"op": "error", "code": "rate", "reason": "Çok fazla yeni kimlik istendi, biraz bekle."})
			return false
		var created: Dictionary = store.create_user(p_name, p_char)
		if created.is_empty():
			_send(c, {"op": "error", "code": "full", "reason": "Kimlik üretilemedi, tekrar dene."})
			return false
		uid = str(created["id"])
		welcome["token"] = str(created["token"])
		welcome["new"] = true
		print("[Mahalle] Yeni kimlik: %s" % uid)
	elif not recovery.is_empty():
		# Kurtarma koduyla geri yükleme (IP ve kimlik başına saatlik sınır)
		if uid.is_empty() \
				or not _rate_ok(ip + "|recover", GameConfig.MM_RECOVER_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC) \
				or not _rate_ok(uid + "|recover", GameConfig.MM_RECOVER_PER_HOUR_PER_ID, GameConfig.MM_HOUR_SEC):
			_send(c, {"op": "error", "code": "rate", "reason": "Çok fazla geri yükleme denemesi. Bir saat sonra tekrar dene."})
			return false
		if not store.check_recovery(uid, recovery):
			_rate_ok(ip + "|authfail", GameConfig.MM_AUTH_FAIL_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC)
			_send(c, {"op": "error", "code": "recover", "reason": "Kimlik ya da kurtarma kodu yanlış."})
			return false
		welcome["token"] = store.rotate_token(uid)
		welcome["restored"] = true
		# Eski cihazın anahtarı geçersiz: açık oturumları kapanır
		for old_v: Variant in (sessions.get(uid, []) as Array).duplicate():
			var old: Dictionary = old_v as Dictionary
			_send(old, {"op": "kicked", "code": "restored", "reason": "Kimliğin başka bir cihazda geri yüklendi."})
			old["close"] = true
		print("[Mahalle] Kimlik geri yüklendi: %s" % uid)
	else:
		if uid.is_empty() or not store.check_token(uid, token):
			_rate_ok(ip + "|authfail", GameConfig.MM_AUTH_FAIL_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC)
			_send(c, {"op": "error", "code": "auth", "reason": "Kimlik doğrulanamadı. Kurtarma koduyla geri yükleyebilirsin."})
			return false

	# Kimlik başına en fazla MM_SESSIONS_PER_ID bağlantı: en eskisi kapanır
	var arr: Array = sessions.get(uid, []) as Array
	var live: Array = []
	for s_v: Variant in arr:
		if not bool((s_v as Dictionary).get("close", false)):
			live.append(s_v)
	while live.size() >= GameConfig.MM_SESSIONS_PER_ID:
		var oldest: Dictionary = live.pop_front() as Dictionary
		_send(oldest, {"op": "kicked", "code": "replaced", "reason": "Başka bir bağlantı açıldı."})
		oldest["close"] = true
	live.append(c)
	sessions[uid] = live

	c["session"] = true
	c["uid"] = uid
	c["room"] = ""
	var u: Dictionary = store.get_user(uid)
	if not str(msg.get("name", "")).is_empty():
		u["name"] = p_name
	u["char"] = p_char
	u["last_seen"] = int(now)
	store.mark_dirty()
	welcome["id"] = uid
	welcome["name"] = str(u["name"])
	welcome["requests_in"] = (u["requests_in"] as Array).size()
	_send(c, welcome)
	refresh_presence(uid)
	return true


## Oturum kapanınca: listeden çıkar, son görülmeyi yaz, arkadaşlara haber ver.
func on_session_closed(c: Dictionary) -> void:
	if not bool(c.get("session", false)):
		return
	var uid: String = str(c.get("uid", ""))
	c["session"] = false
	var arr: Array = sessions.get(uid, []) as Array
	for i: int in range(arr.size() - 1, -1, -1):
		if is_same(arr[i], c):
			arr.remove_at(i)
	if arr.is_empty():
		sessions.erase(uid)
	if store.has_user(uid):
		store.get_user(uid)["last_seen"] = int(Time.get_unix_time_from_system())
		store.mark_dirty()
	refresh_presence(uid)


# ---------------------------------------------------------------------------
# Oturum mesajları
# ---------------------------------------------------------------------------

## Kimliği doğrulanmış oturumdan gelen mesaj. Bağlantı açık kalmalıysa true.
func handle_session_message(c: Dictionary, msg: Dictionary) -> bool:
	var uid: String = str(c["uid"])
	if not store.has_user(uid):
		return false
	if not _rate_ok(uid + "|msg", GameConfig.MM_SESSION_MSG_PER_MIN, GameConfig.MM_RATE_WINDOW_SEC):
		_banned_until[uid] = Time.get_unix_time_from_system() + GameConfig.MM_SESSION_BAN_SEC
		for s_v: Variant in (sessions.get(uid, []) as Array).duplicate():
			var s: Dictionary = s_v as Dictionary
			_send(s, {"op": "kicked", "code": "rate", "reason": "Çok fazla istek. 5 dakika sonra tekrar bağlanılacak."})
			s["close"] = true
		print("[Mahalle] Hız sınırı aşıldı, 5 dk bekletiliyor: %s" % uid)
		return false
	var op: String = str(msg.get("op", ""))
	var rid: int = int(msg.get("rid", 0))
	match op:
		"ping":
			_send(c, {"op": "pong"})
		"status":
			var code: String = str(msg.get("room", "")).strip_edges().to_upper().substr(0, 8)
			c["room"] = code
			refresh_presence(uid)
		"profile":
			_handle_profile(uid, msg)
		"list":
			_reply(c, rid, true, _build_list(uid))
		"get_profile":
			_handle_get_profile(c, rid, str(msg.get("id", "")))
		"friend_request":
			_handle_friend_request(c, rid, uid, str(msg.get("id", "")))
		"friend_respond":
			_handle_friend_respond(c, rid, uid, str(msg.get("id", "")), bool(msg.get("accept", false)))
		"friend_remove":
			_handle_friend_remove(c, rid, uid, str(msg.get("id", "")))
		"recovery_new":
			if not _rate_ok(uid + "|recnew", GameConfig.MM_RECOVERY_NEW_PER_HOUR, GameConfig.MM_HOUR_SEC):
				_reply(c, rid, false, {"reason": "Bu saat için kod hakkın doldu. Biraz sonra tekrar dene."})
			else:
				_reply(c, rid, true, {"code": store.new_recovery_code(uid)})
		_:
			_reply(c, rid, false, {"reason": "Geçersiz istek"})
	return true


func _handle_profile(uid: String, msg: Dictionary) -> void:
	var u: Dictionary = store.get_user(uid)
	if msg.has("name"):
		u["name"] = NAME_FILTER.sanitize(str(msg["name"]))
	if msg.has("char"):
		u["char"] = _clean_char(str(msg["char"]))
	if msg.has("title"):
		var t: String = str(msg["title"]).substr(0, 16)
		u["title"] = t if t.is_empty() or GameConfig.ALBUM_TITLES.has(t) else ""
	var st: Dictionary = u["stats"] as Dictionary
	# Galibiyet istemciden kabul edilmez; yalnızca oda sunucusu raporuyla artar
	st["matches"] = clampi(int(msg.get("matches", st.get("matches", 0))), 0, GameConfig.PROFILE_STAT_MAX)
	st["muhtar"] = clampi(int(msg.get("muhtar", st.get("muhtar", 0))), 0, GameConfig.PROFILE_STAT_MAX)
	st["album"] = clampi(int(msg.get("album", st.get("album", 0))), 0, GameConfig.PEOPLE.size())
	store.mark_dirty()


func _handle_get_profile(c: Dictionary, rid: int, raw_id: String) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	if tid.is_empty() or not store.has_user(tid):
		_reply(c, rid, false, {"reason": "Bu kimlikte bir böcek yok."})
		return
	var u: Dictionary = store.get_user(tid)
	var me: Dictionary = store.get_user(str(c["uid"]))
	if (u["blocked"] as Array).has(str(c["uid"])):
		_reply(c, rid, false, {"reason": "Profil görüntülenemiyor."})
		return
	var out: Dictionary = _brief(tid)
	out["stats"] = (u["stats"] as Dictionary).duplicate()
	out["friend"] = (me["friends"] as Array).has(tid)
	if out["friend"]:
		out.merge(presence_of(tid))
	_reply(c, rid, true, out)


func _handle_friend_request(c: Dictionary, rid: int, uid: String, raw_id: String) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	if tid.is_empty():
		_reply(c, rid, false, {"reason": "Kimlik 8 karakter olmalı (ör. #7K3M-QX9P)."})
		return
	if tid == uid:
		_reply(c, rid, false, {"reason": "Kendine istek gönderemezsin."})
		return
	if not store.has_user(tid):
		_reply(c, rid, false, {"reason": "Bu kimlikte bir böcek yok."})
		return
	var me: Dictionary = store.get_user(uid)
	var tr: Dictionary = store.get_user(tid)
	if (me["friends"] as Array).has(tid):
		_reply(c, rid, false, {"reason": "Zaten arkadaşsınız."})
		return
	if (tr["blocked"] as Array).has(uid) or (me["blocked"] as Array).has(tid):
		_reply(c, rid, false, {"reason": "İstek gönderilemedi."})
		return
	if (me["requests_in"] as Array).has(tid):
		# O da sana istek göndermiş: karşılıklı istek = arkadaşlık
		_handle_friend_respond(c, rid, uid, tid, true)
		return
	if (me["requests_out"] as Array).has(tid):
		_reply(c, rid, true, {"pending": true, "id": tid})
		return
	var now: int = int(Time.get_unix_time_from_system())
	var rej: Dictionary = me["rejected_by"] as Dictionary
	if now - int(rej.get(tid, 0)) < GameConfig.FRIEND_REJECT_COOLDOWN_SEC:
		_reply(c, rid, false, {"reason": "Bu böcek isteğini reddetti. 24 saat sonra tekrar deneyebilirsin."})
		return
	if (me["friends"] as Array).size() >= GameConfig.FRIENDS_MAX:
		_reply(c, rid, false, {"reason": "Arkadaş listen dolu (en fazla %d)." % GameConfig.FRIENDS_MAX})
		return
	if (tr["friends"] as Array).size() >= GameConfig.FRIENDS_MAX:
		_reply(c, rid, false, {"reason": "Onun arkadaş listesi dolu."})
		return
	var today: String = UserStore._today()
	if str(me["req_day"]) != today:
		me["req_day"] = today
		me["req_count"] = 0
	if int(me["req_count"]) >= GameConfig.FRIEND_REQUESTS_PER_DAY:
		_reply(c, rid, false, {"reason": "Bugünlük istek hakkın bitti (%d). Yarın tekrar dene." % GameConfig.FRIEND_REQUESTS_PER_DAY})
		return
	me["req_count"] = int(me["req_count"]) + 1
	(me["requests_out"] as Array).append(tid)
	(tr["requests_in"] as Array).append(uid)
	rej.erase(tid)
	store.mark_dirty()
	_reply(c, rid, true, {"pending": true, "id": tid})
	_push(tid, {"op": "friend_request", "from": _brief(uid)})


func _handle_friend_respond(c: Dictionary, rid: int, uid: String, raw_id: String, accept: bool) -> void:
	var fid: String = GameConfig.normalize_account_id(raw_id)
	var me: Dictionary = store.get_user(uid)
	if fid.is_empty() or not store.has_user(fid) or not (me["requests_in"] as Array).has(fid):
		_reply(c, rid, false, {"reason": "İstek bulunamadı."})
		return
	var other: Dictionary = store.get_user(fid)
	if accept and ((me["friends"] as Array).size() >= GameConfig.FRIENDS_MAX or (other["friends"] as Array).size() >= GameConfig.FRIENDS_MAX):
		_reply(c, rid, false, {"reason": "Arkadaş listesi dolu (en fazla %d)." % GameConfig.FRIENDS_MAX})
		return
	(me["requests_in"] as Array).erase(fid)
	(other["requests_out"] as Array).erase(uid)
	if accept:
		if not (me["friends"] as Array).has(fid):
			(me["friends"] as Array).append(fid)
		if not (other["friends"] as Array).has(uid):
			(other["friends"] as Array).append(uid)
		# Ters yönde bekleyen istek de temizlenir
		(me["requests_out"] as Array).erase(fid)
		(other["requests_in"] as Array).erase(uid)
		store.mark_dirty()
		_reply(c, rid, true, {"accepted": true, "friend": friend_entry(fid)})
		_push(fid, {"op": "friend_added", "friend": friend_entry(uid)})
		_push(uid, {"op": "friend_added", "friend": friend_entry(fid)}, c)
	else:
		(other["rejected_by"] as Dictionary)[uid] = int(Time.get_unix_time_from_system())
		store.mark_dirty()
		_reply(c, rid, true, {"accepted": false, "id": fid})
		_push(fid, {"op": "request_gone", "id": uid})


func _handle_friend_remove(c: Dictionary, rid: int, uid: String, raw_id: String) -> void:
	var fid: String = GameConfig.normalize_account_id(raw_id)
	var me: Dictionary = store.get_user(uid)
	if fid.is_empty() or not (me["friends"] as Array).has(fid):
		_reply(c, rid, false, {"reason": "Arkadaş listende yok."})
		return
	(me["friends"] as Array).erase(fid)
	if store.has_user(fid):
		(store.get_user(fid)["friends"] as Array).erase(uid)
	store.mark_dirty()
	_reply(c, rid, true, {"id": fid})
	_push(fid, {"op": "friend_removed", "id": uid})
	_push(uid, {"op": "friend_removed", "id": fid}, c)


func _build_list(uid: String) -> Dictionary:
	var me: Dictionary = store.get_user(uid)
	var friends: Array = []
	for fid_v: Variant in me["friends"] as Array:
		if store.has_user(str(fid_v)):
			friends.append(friend_entry(str(fid_v)))
	var req_in: Array = []
	for rid_v: Variant in me["requests_in"] as Array:
		if store.has_user(str(rid_v)):
			req_in.append(_brief(str(rid_v)))
	var req_out: Array = []
	for rid_v: Variant in me["requests_out"] as Array:
		if store.has_user(str(rid_v)):
			req_out.append(_brief(str(rid_v)))
	return {"friends": friends, "requests_in": req_in, "requests_out": req_out}


# ---------------------------------------------------------------------------
# Durum (presence)
# ---------------------------------------------------------------------------

## Durum: oturum yoksa çevrimdışı; oturum bir oda bildirmiş ve o oda sunucusu da bu kimliği
## odasında bildiriyorsa odada / maçta; aksi hâlde çevrimiçi. (Kimlik oda sunucusunda 12C'deki
## giriş biletine kadar doğrulanmadığı için iki tarafın uyuşması aranır.)
func presence_of(uid: String) -> Dictionary:
	var arr: Array = sessions.get(uid, []) as Array
	var live: Array = []
	for s_v: Variant in arr:
		if not bool((s_v as Dictionary).get("close", false)):
			live.append(s_v)
	if live.is_empty():
		return {"state": GameConfig.PRESENCE_OFFLINE, "last_seen": int(store.get_user(uid).get("last_seen", 0))}
	for s_v: Variant in live:
		var code: String = str((s_v as Dictionary).get("room", ""))
		if code.is_empty():
			continue
		var room: Dictionary = room_with_uid(code, uid)
		if not room.is_empty():
			var st: String = GameConfig.PRESENCE_MATCH if bool(room.get("in_match", false)) else GameConfig.PRESENCE_ROOM
			return {"state": st, "room_n": int(room.get("players", 0)), "room_max": GameConfig.NET_MAX_CLIENTS + 1}
	return {"state": GameConfig.PRESENCE_ONLINE}


func room_with_uid(code: String, uid: String) -> Dictionary:
	for r_v: Variant in rooms.values():
		var r: Dictionary = r_v as Dictionary
		if str(r.get("code", "")) == code and (r.get("uids", []) as Array).has(uid):
			return r
	return {}


## Durum değiştiyse çevrimiçi arkadaşlara anında bildirir.
func refresh_presence(uid: String) -> void:
	if not store.has_user(uid):
		return
	var p: Dictionary = presence_of(uid)
	var key: String = JSON.stringify(p)
	if str(_last_presence.get(uid, "")) == key:
		return
	if p["state"] == GameConfig.PRESENCE_OFFLINE:
		_last_presence.erase(uid)
	else:
		_last_presence[uid] = key
	var payload: Dictionary = {"op": "presence", "id": uid}
	payload.merge(p)
	for fid_v: Variant in store.get_user(uid)["friends"] as Array:
		_push(str(fid_v), payload)


## Oda durumu değişince odadaki (eski ve yeni) kimliklerin durumu yeniden hesaplanır.
func on_room_changed(old_uids: Array, new_uids: Array) -> void:
	var seen: Dictionary = {}
	for u_v: Variant in old_uids + new_uids:
		var u: String = str(u_v)
		if seen.has(u):
			continue
		seen[u] = true
		if sessions.has(u):
			refresh_presence(u)


## Oda sunucusunun maç sonucu: galibiyet yalnızca buradan sayılır (oturumu o odayı bildirmiş kimliğe).
func on_room_result(code: String, winner_uid: String) -> void:
	var uid: String = GameConfig.normalize_account_id(winner_uid)
	if uid.is_empty() or not store.has_user(uid):
		return
	var declared: bool = false
	for s_v: Variant in sessions.get(uid, []) as Array:
		if str((s_v as Dictionary).get("room", "")) == code:
			declared = true
	if not declared:
		return
	var st: Dictionary = store.get_user(uid)["stats"] as Dictionary
	st["wins"] = mini(int(st.get("wins", 0)) + 1, GameConfig.PROFILE_STAT_MAX)
	store.mark_dirty()


# ---------------------------------------------------------------------------
# Yardımcılar
# ---------------------------------------------------------------------------

func _brief(uid: String) -> Dictionary:
	var u: Dictionary = store.get_user(uid)
	return {"id": uid, "name": str(u.get("name", "Böcek")), "char": str(u.get("char", "klasik")), "title": str(u.get("title", ""))}


func friend_entry(uid: String) -> Dictionary:
	var e: Dictionary = _brief(uid)
	e["last_seen"] = int(store.get_user(uid).get("last_seen", 0))
	e.merge(presence_of(uid), true)
	return e


func _clean_char(cid: String) -> String:
	return cid if CharacterData.CHARACTERS.has(cid) else "klasik"


## Bir kimliğin tüm açık oturumlarına gönderir (except: zaten yanıt alan bağlantı).
func _push(uid: String, payload: Dictionary, except: Dictionary = {}) -> void:
	for s_v: Variant in sessions.get(uid, []) as Array:
		var s: Dictionary = s_v as Dictionary
		if is_same(s, except) or bool(s.get("close", false)):
			continue
		_send(s, payload)


func _reply(c: Dictionary, rid: int, ok: bool, data: Dictionary) -> void:
	var payload: Dictionary = {"op": "res", "rid": rid, "ok": ok}
	payload.merge(data)
	_send(c, payload)


func _send(c: Dictionary, payload: Dictionary) -> void:
	var peer: StreamPeerTCP = c["peer"] as StreamPeerTCP
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return
	peer.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())


## Kayan pencere sınırı: altındaysa kaydedip true.
func _rate_ok(key: String, limit: int, window: float) -> bool:
	var now: float = Time.get_unix_time_from_system()
	var recent: Array = []
	for t_v: Variant in _rate_log.get(key, []) as Array:
		if now - float(t_v) < window:
			recent.append(t_v)
	if recent.size() >= limit:
		_rate_log[key] = recent
		return false
	recent.append(now)
	_rate_log[key] = recent
	return true


## Kaydetmeden yalnızca bakar.
func _rate_peek(key: String, limit: int, window: float) -> bool:
	var now: float = Time.get_unix_time_from_system()
	var n: int = 0
	for t_v: Variant in _rate_log.get(key, []) as Array:
		if now - float(t_v) < window:
			n += 1
	return n < limit


## Süresi dolmuş hız ve yasak kayıtlarını temizler (dakikada bir çağrılır).
func prune() -> void:
	var now: float = Time.get_unix_time_from_system()
	var dead: Array[String] = []
	for k_v: Variant in _rate_log.keys():
		var arr: Array = _rate_log[k_v] as Array
		if arr.is_empty() or now - float(arr[arr.size() - 1]) >= GameConfig.MM_HOUR_SEC:
			dead.append(str(k_v))
	for k: String in dead:
		_rate_log.erase(k)
	for u_v: Variant in _banned_until.keys():
		if float(_banned_until[u_v]) <= now:
			_banned_until.erase(u_v)

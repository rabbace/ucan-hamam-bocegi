class_name MahalleHub
extends RefCounted

## Faz 12.2–12.3: Eşleştiricinin "Mahalle" katmanı — kimliği doğrulanmış kalıcı bağlantılar, durum ve arkadaşlık.
## Kısa ömürlü oda isteklerinden ayrı kurallar: hello + anahtar sonrası boşta kalma 60 sn (20 sn'lik ping ile canlı),
## kimlik başına en fazla 2 bağlantı (yenisi gelince en eskisi kapanır), kimlik başına dakikada 60 mesaj
## (aşan kimliğin bağlantıları kapanır, 5 dk bekletilir), IP başına 16 oturum, toplam MM_MAX_SESSIONS.
## Gizli anahtar ve kurtarma kodu hiçbir zaman loglanmaz.
## Faz 12.4–12.5: oda girişi yalnızca bu oturumdan (giriş bileti), oda gizliliği, davetler, "maç bitince
## otomatik katıl", engelleme, profil kartından bildirme, moderasyonla ad gizleme ve hesap silme.

const NAME_FILTER := preload("res://net/NameFilter.gd")

var store: UserStore = null
var rooms: Dictionary = {} # Matchmaker._rooms (port -> oda kaydı) referansı
var sessions: Dictionary = {} # uid -> Array[Dictionary] (Matchmaker istemci kayıtları)
var _rate_log: Dictionary = {} # anahtar -> Array[float]
var _banned_until: Dictionary = {} # uid -> unix sn
var _last_presence: Dictionary = {} # uid -> JSON metni
## Oda süreçleriyle paylaşılan bilet imza anahtarı
var ticket_key: PackedByteArray = PackedByteArray()
## Oda açma / ayırma için eşleştirici (spawn_private, find_public_room, reserve_slot, effective_players)
var mm: Object = null
var invites: Dictionary = {} # davet edilen uid -> Array[{from, port, code, exp}]
var waiters: Dictionary = {} # uid -> {port, code, exp} ("Maç bitince otomatik katıl")
var hidden_names: Dictionary = {} # moderation.json ile adı gizlenen kimlikler
## Profil kartı bildirimlerinin yazıldığı dosya (boşsa oda bildirimleriyle aynı reports.log)
var report_path: String = ""


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
	var u: Dictionary = store.get_user(uid)
	if not str(msg.get("name", "")).is_empty():
		u["name"] = p_name
	u["char"] = p_char
	u["last_seen"] = int(now)
	store.mark_dirty()
	welcome["id"] = uid
	welcome["name"] = str(u["name"])
	welcome["requests_in"] = (u["requests_in"] as Array).size()
	welcome["invites"] = _live_invites(uid).size()
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
		"room_quick":
			_handle_room_quick(c, rid, uid)
		"room_create":
			_handle_room_create(c, rid, uid, str(msg.get("privacy", GameConfig.ROOM_PRIVACY_DEFAULT)))
		"room_join_code":
			_handle_room_join_code(c, rid, uid, str(msg.get("code", "")))
		"join_friend":
			_handle_join_friend(c, rid, uid, str(msg.get("id", "")), bool(msg.get("wait", false)))
		"join_cancel":
			waiters.erase(uid)
			_reply(c, rid, true, {})
		"invite":
			_handle_invite(c, rid, uid, str(msg.get("id", "")))
		"invites":
			_reply(c, rid, true, {"invites": _invite_list_for(uid)})
		"invite_accept":
			_handle_invite_accept(c, rid, uid, str(msg.get("from", "")), bool(msg.get("wait", false)))
		"invite_decline":
			_drop_invite(uid, GameConfig.normalize_account_id(str(msg.get("from", ""))))
			_reply(c, rid, true, {})
		"block":
			_handle_block(c, rid, uid, str(msg.get("id", "")))
		"unblock":
			_handle_unblock(c, rid, uid, str(msg.get("id", "")))
		"blocked_list":
			var bl: Array = []
			for b_v: Variant in store.get_user(uid)["blocked"] as Array:
				if store.has_user(str(b_v)):
					bl.append(_brief(str(b_v)))
			_reply(c, rid, true, {"blocked": bl})
		"report":
			_handle_report(c, rid, uid, str(msg.get("id", "")), int(msg.get("reason", -1)))
		"delete_account":
			if GameConfig.normalize_account_id(str(msg.get("confirm", ""))) != uid:
				_reply(c, rid, false, {"reason": "Onay için kendi kimliğini yaz."})
			else:
				_reply(c, rid, true, {"deleted": true})
				delete_account(uid)
				return false
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
	out["blocked"] = (me["blocked"] as Array).has(tid)
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

## Durum: oturum yoksa çevrimdışı; oda sunucusu bu kimliği odasında bildiriyorsa odada / maçta; aksi hâlde
## çevrimiçi. Odadaki kimlikler giriş biletinden geldiği için (12C) doğrudan güvenilir.
func presence_of(uid: String) -> Dictionary:
	var arr: Array = sessions.get(uid, []) as Array
	var live: bool = false
	for s_v: Variant in arr:
		if not bool((s_v as Dictionary).get("close", false)):
			live = true
	if not live:
		return {"state": GameConfig.PRESENCE_OFFLINE, "last_seen": int(store.get_user(uid).get("last_seen", 0))}
	var room: Dictionary = room_of(uid)
	if not room.is_empty():
		var st: String = GameConfig.PRESENCE_MATCH if bool(room.get("in_match", false)) else GameConfig.PRESENCE_ROOM
		return {"state": st, "room_n": int(room.get("players", 0)), "room_max": GameConfig.NET_MAX_CLIENTS + 1}
	return {"state": GameConfig.PRESENCE_ONLINE}


## Kimliğin bulunduğu oda kaydı (yoksa boş).
func room_of(uid: String) -> Dictionary:
	for r_v: Variant in rooms.values():
		var r: Dictionary = r_v as Dictionary
		if (r.get("uids", []) as Array).has(uid):
			return r
	return {}


func port_of(room: Dictionary) -> int:
	for p_v: Variant in rooms.keys():
		if is_same(rooms[p_v], room):
			return int(p_v)
	return 0


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


## Oda sunucusunun maç sonucu: galibiyet yalnızca buradan sayılır (kazanan o odada, bilet doğrulamalı).
func on_room_result(code: String, winner_uid: String) -> void:
	var uid: String = GameConfig.normalize_account_id(winner_uid)
	if uid.is_empty() or not store.has_user(uid):
		return
	if str(room_of(uid).get("code", "")) != code:
		return
	var st: Dictionary = store.get_user(uid)["stats"] as Dictionary
	st["wins"] = mini(int(st.get("wins", 0)) + 1, GameConfig.PROFILE_STAT_MAX)
	store.mark_dirty()


# ---------------------------------------------------------------------------
# Faz 12.4: odalar, giriş bileti, oda gizliliği, davet ve arkadaşının odasına katılma
# ---------------------------------------------------------------------------

## Odaya giriş izni: boş metin = izinli, değilse sebep. Engelleme her oda türünde geçerlidir
## (odadakiler ve yolda olanlar dahil). Özel odada yetki oda sahibinin arkadaş listesine ve davetlere bağlıdır.
func entry_denied(room: Dictionary, uid: String) -> String:
	for other_v: Variant in _room_members(room):
		var other: String = str(other_v)
		if other != uid and store.blocked_between(uid, other):
			return "Bu odaya giremezsin."
	if bool(room.get("public", true)):
		return ""
	var owner: String = str(room.get("owner_uid", ""))
	if uid == owner:
		return ""
	var allow: Dictionary = room.get("allow", {}) as Dictionary
	var invited: bool = int(allow.get(uid, 0)) >= int(Time.get_unix_time_from_system())
	match str(room.get("privacy", GameConfig.ROOM_PRIVACY_DEFAULT)):
		GameConfig.ROOM_PRIVACY_CODE:
			return ""
		GameConfig.ROOM_PRIVACY_FRIENDS:
			if invited or (not owner.is_empty() and (store.get_user(owner).get("friends", []) as Array).has(uid)):
				return ""
			return "Bu oda sadece oda sahibinin arkadaşlarına açık."
	if invited:
		return ""
	return "Bu oda sadece davetlilere açık."


## Odadakiler + bileti verilmiş ama henüz bağlanmamış olanlar.
func _room_members(room: Dictionary) -> Array:
	var out: Array = (room.get("uids", []) as Array).duplicate()
	var now: float = Time.get_unix_time_from_system()
	for r_v: Variant in room.get("reservations", []) as Array:
		var r: Dictionary = r_v as Dictionary
		var u: String = str(r.get("uid", ""))
		if not u.is_empty() and now - float(r.get("t", 0.0)) <= GameConfig.NET_CONNECT_TIMEOUT_SEC and not out.has(u):
			out.append(u)
	var owner: String = str(room.get("owner_uid", ""))
	if not owner.is_empty() and not out.has(owner):
		out.append(owner)
	return out


## İzin verilen odaya yer ayırır ve giriş bileti üretir.
func _grant_payload(uid: String, port: int) -> Dictionary:
	var room: Dictionary = rooms[port] as Dictionary
	if mm != null:
		mm.call("reserve_slot", port, uid)
	var ticket: String = RoomTicket.issue(ticket_key, uid, str(room["code"]), is_name_hidden(uid), int(Time.get_unix_time_from_system()))
	return {
		"port": port,
		"code": str(room["code"]),
		"public": bool(room.get("public", true)),
		"privacy": str(room.get("privacy", GameConfig.ROOM_PRIVACY_DEFAULT)),
		"ticket": ticket,
	}


func _room_full(port: int) -> bool:
	if mm == null:
		return int((rooms[port] as Dictionary).get("players", 0)) >= GameConfig.NET_MAX_CLIENTS + 1
	return int(mm.call("effective_players", port)) >= GameConfig.NET_MAX_CLIENTS + 1


## Odaya giriş denemesi: maç / doluluk / izin kontrolü, uygunsa bilet.
func _try_enter(c: Dictionary, rid: int, uid: String, port: int) -> bool:
	var room: Dictionary = rooms[port] as Dictionary
	if (room.get("uids", []) as Array).has(uid):
		_reply(c, rid, false, {"reason": "Zaten bu odadasın."})
		return false
	if bool(room.get("in_match", false)):
		_reply(c, rid, false, {"reason": "Maç sürüyor.", "in_match": true})
		return false
	if _room_full(port):
		_reply(c, rid, false, {"reason": "Oda dolu."})
		return false
	var denied: String = entry_denied(room, uid)
	if not denied.is_empty():
		_reply(c, rid, false, {"reason": denied, "denied": true})
		return false
	_reply(c, rid, true, _grant_payload(uid, port))
	return true


func _handle_room_quick(c: Dictionary, rid: int, uid: String) -> void:
	if mm == null:
		_reply(c, rid, false, {"reason": "Sunucu hazır değil."})
		return
	var port: int = int(mm.call("find_public_room", uid))
	if port <= 0:
		var made: Dictionary = mm.call("spawn_for", str(c["ip"]), true, GameConfig.ROOM_PRIVACY_CODE, "") as Dictionary
		if made.has("reason"):
			_reply(c, rid, false, made)
			return
		port = int(made["port"])
	_reply(c, rid, true, _grant_payload(uid, port))


func _handle_room_create(c: Dictionary, rid: int, uid: String, privacy: String) -> void:
	if mm == null:
		_reply(c, rid, false, {"reason": "Sunucu hazır değil."})
		return
	var p: String = privacy if GameConfig.room_privacy_valid(privacy) else GameConfig.ROOM_PRIVACY_DEFAULT
	var made: Dictionary = mm.call("spawn_for", str(c["ip"]), false, p, uid) as Dictionary
	if made.has("reason"):
		_reply(c, rid, false, made)
		return
	_reply(c, rid, true, _grant_payload(uid, int(made["port"])))


func _handle_room_join_code(c: Dictionary, rid: int, uid: String, raw_code: String) -> void:
	# Oda kodu tahminine karşı kimlik ve IP başına sınır
	if not _rate_ok(uid + "|join", GameConfig.MM_JOIN_CODE_PER_MIN_PER_IP, GameConfig.MM_RATE_WINDOW_SEC) \
			or not _rate_ok(str(c["ip"]) + "|join", GameConfig.MM_JOIN_CODE_PER_MIN_PER_IP * 2, GameConfig.MM_RATE_WINDOW_SEC):
		_reply(c, rid, false, {"reason": "Çok fazla deneme, biraz bekle."})
		return
	var code: String = _clean_room_code(raw_code)
	for port_v: Variant in rooms.keys():
		var r: Dictionary = rooms[port_v] as Dictionary
		if code.length() == 4 and str(r.get("code", "")) == code:
			_try_enter(c, rid, uid, int(port_v))
			return
	_reply(c, rid, false, {"reason": "Oda bulunamadı."})


## Arkadaşlar listesindeki "Katıl": arkadaşın odasına, gizliliğe göre. Maç sürüyorsa wait=true ile
## "maç bitince otomatik katıl" kaydı açılır.
func _handle_join_friend(c: Dictionary, rid: int, uid: String, raw_id: String, wait: bool) -> void:
	var fid: String = GameConfig.normalize_account_id(raw_id)
	if fid.is_empty() or not (store.get_user(uid)["friends"] as Array).has(fid):
		_reply(c, rid, false, {"reason": "Yalnızca arkadaşlarının odasına katılabilirsin."})
		return
	var room: Dictionary = room_of(fid)
	if room.is_empty():
		_reply(c, rid, false, {"reason": "Arkadaşın şu an bir odada değil."})
		return
	var port: int = port_of(room)
	if wait and bool(room.get("in_match", false)):
		var denied: String = entry_denied(room, uid)
		if not denied.is_empty():
			_reply(c, rid, false, {"reason": denied, "denied": true})
			return
		waiters[uid] = {"port": port, "code": str(room["code"]), "exp": int(Time.get_unix_time_from_system()) + GameConfig.AUTO_JOIN_WAIT_SEC}
		_reply(c, rid, true, {"waiting": true, "code": str(room["code"])})
		return
	_try_enter(c, rid, uid, port)


## Maç bittiğinde (oda lobiye / sonuç ekranına döndü) bekleyenlere bilet gönderilir.
func on_room_match_end(port: int) -> void:
	if not rooms.has(port):
		return
	var room: Dictionary = rooms[port] as Dictionary
	for u_v: Variant in waiters.keys():
		var uid: String = str(u_v)
		var w: Dictionary = waiters[u_v] as Dictionary
		if int(w["port"]) != port or str(w["code"]) != str(room.get("code", "")):
			continue
		waiters.erase(u_v)
		if not sessions.has(uid) or _room_full(port) or not entry_denied(room, uid).is_empty():
			_push(uid, {"op": "auto_join_failed", "reason": "Odaya katılamadın (dolu ya da izin yok)."})
			continue
		var payload: Dictionary = _grant_payload(uid, port)
		payload["op"] = "auto_join"
		_push(uid, payload)


func _handle_invite(c: Dictionary, rid: int, uid: String, raw_id: String) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	if tid.is_empty() or not store.has_user(tid) or not (store.get_user(uid)["friends"] as Array).has(tid):
		_reply(c, rid, false, {"reason": "Yalnızca arkadaşlarını davet edebilirsin."})
		return
	if store.blocked_between(uid, tid):
		_reply(c, rid, false, {"reason": "Davet gönderilemedi."})
		return
	var room: Dictionary = room_of(uid)
	if room.is_empty():
		_reply(c, rid, false, {"reason": "Önce bir özel odaya gir."})
		return
	if bool(room.get("public", true)):
		_reply(c, rid, false, {"reason": "Hızlı Oyun odasına davet edilemez."})
		return
	if str(room.get("privacy", "")) == GameConfig.ROOM_PRIVACY_INVITE and str(room.get("owner_uid", "")) != uid:
		_reply(c, rid, false, {"reason": "Bu odada yalnızca oda sahibi davet edebilir."})
		return
	if (room.get("uids", []) as Array).has(tid):
		_reply(c, rid, false, {"reason": "Zaten bu odada."})
		return
	if not _rate_ok(uid + "|invite", GameConfig.INVITES_PER_MIN, GameConfig.MM_RATE_WINDOW_SEC):
		_reply(c, rid, false, {"reason": "Çok fazla davet gönderdin, biraz bekle."})
		return
	var now: int = int(Time.get_unix_time_from_system())
	var exp: int = now + GameConfig.INVITE_TTL_SEC
	if not room.has("allow"):
		room["allow"] = {}
	(room["allow"] as Dictionary)[tid] = exp
	var port: int = port_of(room)
	# Aynı kişiden önceki davet yenisiyle değişir; en fazla INVITES_PENDING_MAX bekler
	var list: Array = _live_invites(tid)
	for i: int in range(list.size() - 1, -1, -1):
		if str((list[i] as Dictionary)["from"]) == uid:
			list.remove_at(i)
	list.append({"from": uid, "port": port, "code": str(room["code"]), "exp": exp})
	while list.size() > GameConfig.INVITES_PENDING_MAX:
		list.pop_front()
	invites[tid] = list
	var online: bool = sessions.has(tid)
	_reply(c, rid, true, {"id": tid, "offline": not online, "code": str(room["code"])})
	_push(tid, {"op": "invite", "invite": _invite_view(list[list.size() - 1] as Dictionary)})


func _handle_invite_accept(c: Dictionary, rid: int, uid: String, raw_from: String, wait: bool) -> void:
	var from_id: String = GameConfig.normalize_account_id(raw_from)
	var inv: Dictionary = {}
	for i_v: Variant in _live_invites(uid):
		if str((i_v as Dictionary)["from"]) == from_id:
			inv = i_v as Dictionary
	if inv.is_empty():
		_reply(c, rid, false, {"reason": "Davetin süresi doldu."})
		return
	var port: int = int(inv["port"])
	if not rooms.has(port) or str((rooms[port] as Dictionary).get("code", "")) != str(inv["code"]):
		_drop_invite(uid, from_id)
		_reply(c, rid, false, {"reason": "Oda kapanmış."})
		return
	var room: Dictionary = rooms[port] as Dictionary
	if wait and bool(room.get("in_match", false)):
		waiters[uid] = {"port": port, "code": str(room["code"]), "exp": int(Time.get_unix_time_from_system()) + GameConfig.AUTO_JOIN_WAIT_SEC}
		_drop_invite(uid, from_id)
		_reply(c, rid, true, {"waiting": true, "code": str(room["code"])})
		return
	if _try_enter(c, rid, uid, port):
		_drop_invite(uid, from_id)


func _live_invites(uid: String) -> Array:
	var now: int = int(Time.get_unix_time_from_system())
	var out: Array = []
	for i_v: Variant in invites.get(uid, []) as Array:
		var inv: Dictionary = i_v as Dictionary
		if int(inv["exp"]) >= now and store.has_user(str(inv["from"])):
			out.append(inv)
	return out


func _invite_list_for(uid: String) -> Array:
	var out: Array = []
	for i_v: Variant in _live_invites(uid):
		out.append(_invite_view(i_v as Dictionary))
	return out


## İstemciye giden davet: davet edenin kısa bilgisi, oda kodu, odadaki kişi sayısı, bitiş zamanı.
func _invite_view(inv: Dictionary) -> Dictionary:
	var port: int = int(inv["port"])
	var n: int = int((rooms.get(port, {}) as Dictionary).get("players", 0))
	return {
		"from": _brief(str(inv["from"])),
		"code": str(inv["code"]),
		"n": n,
		"max": GameConfig.NET_MAX_CLIENTS + 1,
		"exp": int(inv["exp"]),
	}


func _drop_invite(uid: String, from_id: String) -> void:
	var list: Array = invites.get(uid, []) as Array
	for i: int in range(list.size() - 1, -1, -1):
		if str((list[i] as Dictionary)["from"]) == from_id:
			list.remove_at(i)
	if list.is_empty():
		invites.erase(uid)


static func _clean_room_code(raw: String) -> String:
	var up: String = raw.strip_edges().to_upper().substr(0, 16)
	var out: String = ""
	for ch: String in up:
		if GameConfig.ACCOUNT_ID_CHARS.contains(ch):
			out += ch
	return out.substr(0, 4)


# ---------------------------------------------------------------------------
# Faz 12.5: engelleme, bildirme, hesap silme
# ---------------------------------------------------------------------------

## Engelle: arkadaşlık ve istekler iki yönde silinir, aradaki davetler kalkar. Engellenen kişi
## seni listesinde görmez, istek/davet gönderemez, aynı odaya giremez.
func _handle_block(c: Dictionary, rid: int, uid: String, raw_id: String) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	if tid.is_empty() or tid == uid or not store.has_user(tid):
		_reply(c, rid, false, {"reason": "Bu kimlikte bir böcek yok."})
		return
	var me: Dictionary = store.get_user(uid)
	var other: Dictionary = store.get_user(tid)
	var blocked: Array = me["blocked"] as Array
	if not blocked.has(tid):
		if blocked.size() >= GameConfig.BLOCKED_MAX:
			_reply(c, rid, false, {"reason": "Engel listen dolu."})
			return
		blocked.append(tid)
	var was_friend: bool = (me["friends"] as Array).has(tid)
	(me["friends"] as Array).erase(tid)
	(other["friends"] as Array).erase(uid)
	var had_req: bool = (other["requests_out"] as Array).has(uid) or (other["requests_in"] as Array).has(uid)
	for field: String in ["requests_in", "requests_out"]:
		(me[field] as Array).erase(tid)
		(other[field] as Array).erase(uid)
	_drop_invite(uid, tid)
	_drop_invite(tid, uid)
	if waiters.has(tid) and str(room_of(uid).get("code", "")) == str((waiters[tid] as Dictionary)["code"]):
		waiters.erase(tid)
	store.mark_dirty()
	_reply(c, rid, true, {"id": tid})
	if was_friend:
		_push(tid, {"op": "friend_removed", "id": uid})
		_push(uid, {"op": "friend_removed", "id": tid}, c)
	if had_req:
		_push(tid, {"op": "request_gone", "id": uid})


func _handle_unblock(c: Dictionary, rid: int, uid: String, raw_id: String) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	(store.get_user(uid)["blocked"] as Array).erase(tid)
	store.mark_dirty()
	_reply(c, rid, true, {"id": tid})


## Profil kartından bildirim: reports.log'a tek satır (kimlikler, ad, sebep). Saatte en fazla PROFILE_REPORTS_PER_HOUR.
func _handle_report(c: Dictionary, rid: int, uid: String, raw_id: String, reason_idx: int) -> void:
	var tid: String = GameConfig.normalize_account_id(raw_id)
	if tid.is_empty() or tid == uid or not store.has_user(tid) or reason_idx < 0 or reason_idx >= GameConfig.PROFILE_REPORT_REASONS.size():
		_reply(c, rid, false, {"reason": "Bildirim gönderilemedi."})
		return
	if not _rate_ok(uid + "|report", GameConfig.PROFILE_REPORTS_PER_HOUR, GameConfig.MM_HOUR_SEC):
		_reply(c, rid, false, {"reason": "Bu saat için bildirim hakkın doldu."})
		return
	var line: String = "%s\tkaynak=profil\tbildiren=%s\thedef=%s\thedef_ad=%s\tsebep=%s" % [
		Time.get_datetime_string_from_unix_time(int(Time.get_unix_time_from_system()), true),
		uid, tid, _log_field(str(store.get_user(tid).get("name", ""))),
		GameConfig.PROFILE_REPORT_REASONS[reason_idx],
	]
	_append_report(line)
	_reply(c, rid, true, {"id": tid})


func _append_report(line: String) -> void:
	var path: String = report_path if not report_path.is_empty() else NetworkManager.report_log_path()
	var f: FileAccess = null
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("[Mahalle] Bildirim yazılamadı.")
		return
	f.store_line(line)
	f.close()


static func _log_field(v: String) -> String:
	return v.replace("\t", " ").replace("\n", " ").replace("\r", " ").substr(0, 32)


## Hesabı ve tüm izlerini siler; açık oturumlar kapanır, eski arkadaşlara ve istek sahiplerine haber gider.
func delete_account(uid: String) -> void:
	if not store.has_user(uid):
		return
	var u: Dictionary = store.get_user(uid)
	var req_people: Array = (u["requests_in"] as Array) + (u["requests_out"] as Array)
	var former: Array = store.delete_user(uid)
	invites.erase(uid)
	for k_v: Variant in invites.keys():
		_drop_invite(str(k_v), uid)
	waiters.erase(uid)
	for r_v: Variant in rooms.values():
		((r_v as Dictionary).get("allow", {}) as Dictionary).erase(uid)
	_last_presence.erase(uid)
	for key: String in [uid + "|msg", uid + "|recover", uid + "|recnew", uid + "|join", uid + "|invite", uid + "|report", uid + "|delete"]:
		_rate_log.erase(key)
	for s_v: Variant in (sessions.get(uid, []) as Array).duplicate():
		var s: Dictionary = s_v as Dictionary
		_send(s, {"op": "kicked", "code": "deleted", "reason": "Hesabın silindi."})
		s["close"] = true
	sessions.erase(uid)
	for f_v: Variant in former:
		_push(str(f_v), {"op": "friend_removed", "id": uid})
	for p_v: Variant in req_people:
		_push(str(p_v), {"op": "request_gone", "id": uid})
	print("[Mahalle] Bir hesap silindi (toplam silinmiş: %d)." % store.deleted_ids.size())


## Web silme ucu: kimlik + kurtarma kodu. IP ve kimlik başına saatlik sınır. {ok, reason}
func delete_with_recovery(raw_id: String, raw_code: String, ip: String) -> Dictionary:
	if not _rate_ok(ip + "|http", GameConfig.MM_HTTP_PER_HOUR_PER_IP, GameConfig.MM_HOUR_SEC):
		return {"ok": false, "reason": "Çok fazla deneme. Bir saat sonra tekrar dene."}
	var uid: String = GameConfig.normalize_account_id(raw_id)
	var code: String = GameConfig.normalize_recovery_code(raw_code)
	if uid.is_empty() or code.is_empty():
		return {"ok": false, "reason": "Kimlik 8, kurtarma kodu 16 karakter olmalı."}
	if not _rate_ok(uid + "|delete", GameConfig.MM_DELETE_PER_HOUR_PER_ID, GameConfig.MM_HOUR_SEC):
		return {"ok": false, "reason": "Bu kimlik için çok fazla deneme. Bir saat sonra tekrar dene."}
	if not store.check_recovery(uid, code):
		return {"ok": false, "reason": "Kimlik ya da kurtarma kodu yanlış."}
	delete_account(uid)
	return {"ok": true, "reason": "Hesabın ve tüm kayıtların silindi."}


# ---------------------------------------------------------------------------
# Yardımcılar
# ---------------------------------------------------------------------------

func _brief(uid: String) -> Dictionary:
	var u: Dictionary = store.get_user(uid)
	return {"id": uid, "name": display_name(uid), "char": str(u.get("char", "klasik")), "title": str(u.get("title", ""))}


## moderation.json'da işaretli kimliğin adı başkalarına "Böcek #7K3M" görünür.
func display_name(uid: String) -> String:
	if hidden_names.has(uid):
		return GameConfig.masked_name(uid)
	return str(store.get_user(uid).get("name", "Böcek"))


func is_name_hidden(uid: String) -> bool:
	return hidden_names.has(uid)


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
	NetStream.put_line(c["peer"] as StreamPeer, payload)


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
	var now_i: int = int(now)
	for u_v: Variant in invites.keys():
		var live: Array = _live_invites(str(u_v))
		if live.is_empty():
			invites.erase(u_v)
		else:
			invites[u_v] = live
	for u_v: Variant in waiters.keys():
		var w: Dictionary = waiters[u_v] as Dictionary
		if int(w["exp"]) < now_i or not rooms.has(int(w["port"])):
			waiters.erase(u_v)
	for r_v: Variant in rooms.values():
		var allow: Dictionary = (r_v as Dictionary).get("allow", {}) as Dictionary
		for a_v: Variant in allow.keys():
			if int(allow[a_v]) < now_i:
				allow.erase(a_v)

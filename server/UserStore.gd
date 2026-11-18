class_name UserStore
extends RefCounted

## Faz 12.1: Eşleştiricinin kullanıcı kayıtları (server/data/users.json).
## Bellekte tutulur; değişiklik en geç MM_USERS_FLUSH_SEC içinde güvenli yazımla (geçici dosya + yeniden adlandırma)
## diske gider. Her gün users_YYYYMMDD.json yedeği alınır, son MM_USERS_BACKUP_KEEP yedek tutulur.
## Gizli anahtar ve kurtarma kodu yalnızca SHA-256 özeti olarak saklanır, hiçbir zaman loglanmaz.

var users: Dictionary = {} # id -> kayıt (bkz. new_record)
## Faz 12.5: silinmiş kimlikler (bir daha kimseye verilmez); data/deleted_ids.json
var deleted_ids: Dictionary = {} # id -> true
var data_dir: String = ""
var _dirty: bool = false
var _dirty_since_ms: int = 0
var _last_backup_day: String = ""
var _next_backup_check_ms: int = 0
var _crypto: Crypto = Crypto.new()


func _init(p_data_dir: String) -> void:
	data_dir = p_data_dir


## Veri klasörü: --data-dir=... verilirse o; editörde res://server/data; dışa aktarılmış sunucuda çalıştırılabilir dosyanın yanındaki data/.
static func default_data_dir() -> String:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--data-dir="):
			return arg.substr(11)
	if OS.has_feature("template"):
		return OS.get_executable_path().get_base_dir().path_join("data")
	return ProjectSettings.globalize_path("res://server/data")


func users_path() -> String:
	return data_dir.path_join(GameConfig.MM_USERS_FILE)


## Kayıtları yükler. Ana dosya bozuksa sırasıyla geçici dosya ve en yeni yedek denenir.
func load_all() -> void:
	DirAccess.make_dir_recursive_absolute(data_dir)
	_load_deleted_ids()
	var candidates: Array[String] = [users_path(), users_path() + ".tmp"]
	var backups: Array[String] = list_backups()
	backups.reverse()
	for b: String in backups:
		candidates.append(data_dir.path_join(b))
	for path: String in candidates:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Dictionary:
			users = {}
			var src: Dictionary = parsed as Dictionary
			for k: Variant in src.keys():
				if src[k] is Dictionary and str(k).length() == GameConfig.ACCOUNT_ID_LEN and not deleted_ids.has(str(k)):
					users[str(k)] = _upgrade_record(src[k] as Dictionary)
			print("[UserStore] %d kullanıcı yüklendi (%s)" % [users.size(), path.get_file()])
			if path != users_path():
				mark_dirty()
			return
	users = {}
	print("[UserStore] Kayıt yok, boş başlıyor: %s" % users_path())


## Eski/eksik alanları tamamlar (12C/12D alanları burada da hazır durur).
func _upgrade_record(r: Dictionary) -> Dictionary:
	var base: Dictionary = new_record("", "", "")
	for k: Variant in base.keys():
		if not r.has(k):
			r[k] = base[k]
	return r


static func new_record(p_name: String, token_hash: String, char_id: String) -> Dictionary:
	var now: int = int(Time.get_unix_time_from_system())
	return {
		"name": p_name,
		"char": char_id,
		"title": "",
		"token_hash": token_hash,
		"recovery_hash": "",
		"created": now,
		"last_seen": now,
		"friends": [],
		"requests_in": [],
		"requests_out": [],
		"blocked": [],
		"rejected_by": {},
		"req_day": "",
		"req_count": 0,
		"stats": {"matches": 0, "wins": 0, "muhtar": 0, "album": 0},
	}


func has_user(uid: String) -> bool:
	return users.has(uid)


func get_user(uid: String) -> Dictionary:
	return users.get(uid, {}) as Dictionary


func mark_dirty() -> void:
	if not _dirty:
		_dirty = true
		_dirty_since_ms = Time.get_ticks_msec()


## Her karede çağrılır: bekleyen değişikliği yazar, gün değişince yedek alır.
func tick() -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _dirty and now_ms - _dirty_since_ms >= int(GameConfig.MM_USERS_FLUSH_SEC * 1000.0):
		flush()
	if now_ms >= _next_backup_check_ms:
		_next_backup_check_ms = now_ms + int(GameConfig.MM_USERS_FLUSH_SEC * 1000.0)
		var day: String = _today()
		if day != _last_backup_day and daily_backup():
			_last_backup_day = day


## Güvenli yazım: önce .tmp, sonra asıl dosyanın yerine taşı.
func flush() -> bool:
	DirAccess.make_dir_recursive_absolute(data_dir)
	var tmp: String = users_path() + ".tmp"
	var f: FileAccess = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("[UserStore] Geçici dosya açılamadı: %s" % tmp)
		return false
	f.store_string(JSON.stringify(users))
	f.flush()
	f.close()
	var err: Error = DirAccess.rename_absolute(tmp, users_path())
	if err != OK:
		push_error("[UserStore] Yeniden adlandırma başarısız: %d" % err)
		return false
	_dirty = false
	return true


## Günün yedeği yoksa alır (önce bekleyen değişiklikleri yazar), sonra eski yedekleri budar. Yedek varsa true.
func daily_backup() -> bool:
	if users.is_empty() and not FileAccess.file_exists(users_path()):
		return false
	var fname: String = "users_%s.json" % _today()
	var dst: String = data_dir.path_join(fname)
	if not FileAccess.file_exists(dst):
		if _dirty or not FileAccess.file_exists(users_path()):
			flush()
		var err: Error = DirAccess.copy_absolute(users_path(), dst)
		if err != OK:
			return false
		print("[UserStore] Günlük yedek: %s" % fname)
	prune_backups()
	return true


func list_backups() -> Array[String]:
	var out: Array[String] = []
	var da: DirAccess = DirAccess.open(data_dir)
	if da == null:
		return out
	var re: RegEx = RegEx.new()
	re.compile("^users_\\d{8}\\.json$")
	for f: String in da.get_files():
		if re.search(f) != null:
			out.append(f)
	out.sort()
	return out


func prune_backups() -> void:
	var all: Array[String] = list_backups()
	while all.size() > GameConfig.MM_USERS_BACKUP_KEEP:
		var old: String = all.pop_front()
		DirAccess.remove_absolute(data_dir.path_join(old))


static func _today() -> String:
	var d: Dictionary = Time.get_date_dict_from_system(true)
	return "%04d%02d%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


# ---------------------------------------------------------------------------
# Kimlik ve gizli bilgiler
# ---------------------------------------------------------------------------

## Kriptografik rastgele kodla benzersiz kimlik (32 karakterlik alfabe, 256 % 32 == 0 olduğu için sapmasız).
func generate_unique_id() -> String:
	for _attempt: int in range(64):
		var code: String = random_code(GameConfig.ACCOUNT_ID_LEN)
		if not users.has(code) and not deleted_ids.has(code):
			return code
	return ""


func random_code(length: int) -> String:
	var bytes: PackedByteArray = _crypto.generate_random_bytes(length)
	var out: String = ""
	for b: int in bytes:
		out += GameConfig.ACCOUNT_ID_CHARS[b % GameConfig.ACCOUNT_ID_CHARS.length()]
	return out


func new_token() -> String:
	return _crypto.generate_random_bytes(GameConfig.ACCOUNT_TOKEN_BYTES).hex_encode()


static func hash_secret(secret: String) -> String:
	return secret.sha256_text()


## Sabit zamanlı karşılaştırma (özetler aynı uzunlukta; erken çıkış yok).
static func secure_equals(a: String, b: String) -> bool:
	var ab: PackedByteArray = a.to_utf8_buffer()
	var bb: PackedByteArray = b.to_utf8_buffer()
	var diff: int = ab.size() ^ bb.size()
	var n: int = maxi(ab.size(), bb.size())
	for i: int in range(n):
		var x: int = ab[i] if i < ab.size() else 0
		var y: int = bb[i] if i < bb.size() else 0
		diff |= x ^ y
	return diff == 0 and ab.size() > 0


func check_token(uid: String, token: String) -> bool:
	if not users.has(uid) or token.is_empty():
		# Zamanlama farkı olmasın diye yine özet hesaplanır
		secure_equals(hash_secret(token), hash_secret("x"))
		return false
	return secure_equals(hash_secret(token), str(users[uid].get("token_hash", "")))


func check_recovery(uid: String, code: String) -> bool:
	if not users.has(uid) or code.is_empty():
		secure_equals(hash_secret(code), hash_secret("x"))
		return false
	var stored: String = str(users[uid].get("recovery_hash", ""))
	if stored.is_empty():
		return false
	return secure_equals(hash_secret(code), stored)


## Yeni kullanıcı: {id, token}. Anahtarın kendisi saklanmaz.
func create_user(p_name: String, char_id: String) -> Dictionary:
	var uid: String = generate_unique_id()
	if uid.is_empty():
		return {}
	var token: String = new_token()
	users[uid] = new_record(p_name, hash_secret(token), char_id)
	mark_dirty()
	return {"id": uid, "token": token}


## Yeni gizli anahtar üretir; eskisi geçersizleşir.
func rotate_token(uid: String) -> String:
	var token: String = new_token()
	users[uid]["token_hash"] = hash_secret(token)
	mark_dirty()
	return token


## Yeni kurtarma kodu üretir; eskisi geçersizleşir. Kod yalnızca bir kez istemciye gider.
func new_recovery_code(uid: String) -> String:
	var code: String = random_code(GameConfig.RECOVERY_CODE_LEN)
	users[uid]["recovery_hash"] = hash_secret(code)
	mark_dirty()
	return code


# ---------------------------------------------------------------------------
# Faz 12.5: engelleme ve hesap silme
# ---------------------------------------------------------------------------

## İki kimlikten biri diğerini engellediyse true.
func blocked_between(a: String, b: String) -> bool:
	if a.is_empty() or b.is_empty():
		return false
	var ua: Dictionary = get_user(a)
	var ub: Dictionary = get_user(b)
	return (ua.get("blocked", []) as Array).has(b) or (ub.get("blocked", []) as Array).has(a)


## Kullanıcıyı ve tüm izlerini siler: kendi kaydı, karşı tarafların arkadaş/istek/engel/ret listeleri ve
## günlük yedeklerdeki kopyaları. Kimlik silinmiş kimlikler listesine girer. Eski arkadaşların kimliklerini döner.
func delete_user(uid: String) -> Array:
	if not users.has(uid):
		return []
	var former: Array = ((users[uid] as Dictionary).get("friends", []) as Array).duplicate()
	users.erase(uid)
	_scrub_refs(users, uid)
	deleted_ids[uid] = true
	_save_deleted_ids()
	flush()
	_scrub_backups(uid)
	return former


## Bir kullanıcı sözlüğünde (users ya da yedek) kimliğe ait tüm başvuruları temizler.
static func _scrub_refs(all: Dictionary, uid: String) -> void:
	for k: Variant in all.keys():
		var r_v: Variant = all[k]
		if not (r_v is Dictionary):
			continue
		var r: Dictionary = r_v as Dictionary
		for field: String in ["friends", "requests_in", "requests_out", "blocked"]:
			if r.get(field) is Array:
				var arr: Array = r[field] as Array
				while arr.has(uid):
					arr.erase(uid)
		if r.get("rejected_by") is Dictionary:
			(r["rejected_by"] as Dictionary).erase(uid)


func _scrub_backups(uid: String) -> void:
	for b: String in list_backups():
		var path: String = data_dir.path_join(b)
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not (parsed is Dictionary):
			continue
		var d: Dictionary = parsed as Dictionary
		d.erase(uid)
		_scrub_refs(d, uid)
		_safe_write(path, JSON.stringify(d))


func _deleted_path() -> String:
	return data_dir.path_join(GameConfig.DELETED_IDS_FILE)


func _load_deleted_ids() -> void:
	deleted_ids = {}
	for path: String in [_deleted_path(), _deleted_path() + ".tmp"]:
		if not FileAccess.file_exists(path):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Array:
			for v: Variant in parsed as Array:
				if str(v).length() == GameConfig.ACCOUNT_ID_LEN:
					deleted_ids[str(v)] = true
			return


func _save_deleted_ids() -> void:
	_safe_write(_deleted_path(), JSON.stringify(deleted_ids.keys()))


## Geçici dosya + yeniden adlandırma.
func _safe_write(path: String, text: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f: FileAccess = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	f.close()
	return DirAccess.rename_absolute(path + ".tmp", path) == OK

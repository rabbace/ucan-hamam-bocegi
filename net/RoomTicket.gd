class_name RoomTicket
extends RefCounted

## Faz 12.4: Oda giriş bileti. Eşleştirici izin verdiğinde üretir, oda sunucusu ilk mesajda (register_player) doğrular.
## Biçim: base64(JSON {u: kimlik, c: oda kodu, e: bitiş unix sn, n: tek kullanımlık rastgele, m: ad gizli mi}) + "." + HMAC-SHA256 (hex).
## İmza anahtarı eşleştirici ile oda süreçleri arasında paylaşılır; oda sürecine komut satırıyla değil ortam değişkeniyle verilir.


## Yeni bilet. key boşsa "" döner.
static func issue(key: PackedByteArray, uid: String, room_code: String, masked: bool, now_unix: int) -> String:
	if key.is_empty() or uid.is_empty() or room_code.is_empty():
		return ""
	var crypto: Crypto = Crypto.new()
	var payload: Dictionary = {
		"u": uid,
		"c": room_code,
		"e": now_unix + GameConfig.TICKET_TTL_SEC,
		"n": crypto.generate_random_bytes(8).hex_encode(),
		"m": 1 if masked else 0,
	}
	var body: String = Marshalls.utf8_to_base64(JSON.stringify(payload))
	return body + "." + sign_body(key, body)


static func sign_body(key: PackedByteArray, body: String) -> String:
	var crypto: Crypto = Crypto.new()
	return crypto.hmac_digest(HashingContext.HASH_SHA256, key, body.to_utf8_buffer()).hex_encode()


## Doğrular: imza, oda kodu, süre ve biçim. Geçerliyse {uid, nonce, exp, masked}; değilse {"error": sebep}.
static func verify(key: PackedByteArray, ticket: String, room_code: String, now_unix: int) -> Dictionary:
	if key.is_empty():
		return {"error": "anahtar yok"}
	if ticket.is_empty() or ticket.length() > GameConfig.TICKET_MAX_LEN:
		return {"error": "bilet yok"}
	var dot: int = ticket.rfind(".")
	if dot <= 0:
		return {"error": "biçim"}
	var body: String = ticket.substr(0, dot)
	var sig: String = ticket.substr(dot + 1)
	if not UserStore.secure_equals(sign_body(key, body), sig):
		return {"error": "imza"}
	var parsed: Variant = JSON.parse_string(Marshalls.base64_to_utf8(body))
	if not (parsed is Dictionary):
		return {"error": "biçim"}
	var p: Dictionary = parsed as Dictionary
	var uid: String = GameConfig.normalize_account_id(str(p.get("u", "")))
	if uid.is_empty() or uid != str(p.get("u", "")):
		return {"error": "kimlik"}
	if str(p.get("c", "")) != room_code:
		return {"error": "oda"}
	var exp: int = int(p.get("e", 0))
	if exp < now_unix or exp > now_unix + GameConfig.TICKET_TTL_SEC + 5:
		return {"error": "süre"}
	return {"uid": uid, "nonce": str(p.get("n", "")), "exp": exp, "masked": int(p.get("m", 0)) == 1}


## Oda süreci: anahtarı ortam değişkeninden okur (hex). Okuduktan sonra ortamdan silinir.
static func key_from_env() -> PackedByteArray:
	var hex: String = OS.get_environment(GameConfig.TICKET_KEY_ENV)
	if hex.is_empty():
		return PackedByteArray()
	return hex.hex_decode()

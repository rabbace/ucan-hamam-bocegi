class_name DeleteHttp
extends RefCounted

## Faz 12.5: web/hesap-silme.html formunun gönderildiği tek uçlu, en küçük HTTP dinleyici (TCPServer üzerinde).
## Yalnızca "POST /hesap-sil" (application/x-www-form-urlencoded: id, recovery). Başka yöntem 405, başka yol 404.
## Sınırlar: başlık 4 KB, gövde 1 KB, bağlantı 5 sn, en fazla 16 eşzamanlı bağlantı, IP başına dakikada 20 istek
## (silme denemesi ayrıca IP başına saatte 10, kimlik başına saatte 5). CORS başlığı verilmez: form düz HTML
## gönderimi olduğu için gerekmez; başka sitelerin betikleri yanıtı okuyamaz. TLS açıksa aynı sertifikayla HTTPS.

const PATH: String = "/hesap-sil"
const REQ_PER_MIN_PER_IP: int = 20

var hub: MahalleHub = null
var port: int = 0
var _server: TCPServer = TCPServer.new()
var _tls_options: TLSOptions = null
var _clients: Array[Dictionary] = [] # {tcp, peer, buf, ip, start_ms}
var _rate_log: Dictionary = {} # ip -> Array[float]


func _init(p_hub: MahalleHub, p_tls: TLSOptions) -> void:
	hub = p_hub
	_tls_options = p_tls


func start(p_port: int, bind: String = "0.0.0.0") -> Error:
	port = p_port
	return _server.listen(p_port, bind)


func stop() -> void:
	for c: Dictionary in _clients:
		NetStream.close(c["peer"] as StreamPeer)
	_clients.clear()
	_server.stop()


func poll() -> void:
	while _server.is_connection_available():
		var tcp: StreamPeerTCP = _server.take_connection()
		if tcp == null:
			continue
		var ip: String = tcp.get_connected_host()
		if _clients.size() >= GameConfig.MM_HTTP_MAX_CLIENTS or not _rate_ok(ip):
			tcp.disconnect_from_host()
			continue
		var peer: StreamPeer = tcp
		if _tls_options != null:
			var tls: StreamPeerTLS = StreamPeerTLS.new()
			if tls.accept_stream(tcp, _tls_options) != OK:
				tcp.disconnect_from_host()
				continue
			peer = tls
		_clients.append({"tcp": tcp, "peer": peer, "buf": PackedByteArray(), "ip": ip, "start_ms": Time.get_ticks_msec()})
	var kept: Array[Dictionary] = []
	var limit_ms: int = int(GameConfig.MM_HTTP_TIMEOUT_SEC * 1000.0)
	for c: Dictionary in _clients:
		var peer: StreamPeer = c["peer"] as StreamPeer
		var st: int = NetStream.poll_state(peer)
		if st == NetStream.DEAD or Time.get_ticks_msec() - int(c["start_ms"]) > limit_ms:
			NetStream.close(peer)
			continue
		if st == NetStream.PENDING:
			kept.append(c)
			continue
		if _read_and_maybe_answer(c):
			NetStream.close(peer)
			continue
		kept.append(c)
	_clients = kept


## Veriyi okur; yanıt verildiyse (ya da bağlantı kapanmalıysa) true.
func _read_and_maybe_answer(c: Dictionary) -> bool:
	var peer: StreamPeer = c["peer"] as StreamPeer
	var avail: int = peer.get_available_bytes()
	if avail <= 0:
		return false
	var buf: PackedByteArray = c["buf"] as PackedByteArray
	if buf.size() + avail > GameConfig.MM_HTTP_MAX_HEADER + GameConfig.MM_HTTP_MAX_BODY:
		_respond(peer, 413, "İstek çok büyük.")
		return true
	var res: Array = peer.get_partial_data(avail)
	if int(res[0]) != OK:
		return true
	buf.append_array(res[1] as PackedByteArray)
	c["buf"] = buf
	var parsed: Dictionary = parse_request(buf)
	if parsed.is_empty():
		if buf.size() > GameConfig.MM_HTTP_MAX_HEADER and _header_end(buf) == -1:
			_respond(peer, 431, "Başlık çok büyük.")
			return true
		return false
	if parsed.has("status"):
		_respond(peer, int(parsed["status"]), str(parsed["message"]))
		return true
	var form: Dictionary = parsed["form"] as Dictionary
	var out: Dictionary = hub.delete_with_recovery(str(form.get("id", "")), str(form.get("recovery", "")), str(c["ip"]))
	# Kimlik ve kod loglanmaz
	print("[HesapSilme] %s -> %s" % [str(c["ip"]), "silindi" if bool(out["ok"]) else "reddedildi"])
	_respond(peer, 200 if bool(out["ok"]) else 400, str(out["reason"]))
	return true


static func _header_end(buf: PackedByteArray) -> int:
	for i: int in range(maxi(0, buf.size() - 3)):
		if buf[i] == 13 and buf[i + 1] == 10 and buf[i + 2] == 13 and buf[i + 3] == 10:
			return i
	return -1


## İsteği ayrıştırır. Eksikse {}; hatalıysa {status, message}; tamamsa {form}.
static func parse_request(buf: PackedByteArray) -> Dictionary:
	var he: int = _header_end(buf)
	if he == -1:
		return {}
	if he > GameConfig.MM_HTTP_MAX_HEADER:
		return {"status": 431, "message": "Başlık çok büyük."}
	var head: String = buf.slice(0, he).get_string_from_utf8()
	var lines: PackedStringArray = head.split("\r\n")
	var first: PackedStringArray = lines[0].split(" ")
	if first.size() < 3:
		return {"status": 400, "message": "Geçersiz istek."}
	var path: String = first[1].split("?")[0]
	if path != PATH:
		return {"status": 404, "message": "Bulunamadı."}
	if first[0] != "POST":
		return {"status": 405, "message": "Yalnızca form gönderimi kabul edilir."}
	var length: int = -1
	for i: int in range(1, lines.size()):
		var colon: int = lines[i].find(":")
		if colon > 0 and lines[i].substr(0, colon).strip_edges().to_lower() == "content-length":
			var v: String = lines[i].substr(colon + 1).strip_edges()
			length = int(v) if v.is_valid_int() else -1
	if length < 0:
		return {"status": 411, "message": "Uzunluk bilgisi eksik."}
	if length > GameConfig.MM_HTTP_MAX_BODY:
		return {"status": 413, "message": "İstek çok büyük."}
	var body_start: int = he + 4
	if buf.size() - body_start < length:
		return {}
	var body: String = buf.slice(body_start, body_start + length).get_string_from_utf8()
	return {"form": parse_form(body)}


## application/x-www-form-urlencoded çözümü ("+" boşluk, %XX).
static func parse_form(body: String) -> Dictionary:
	var out: Dictionary = {}
	for pair: String in body.split("&", false):
		var eq: int = pair.find("=")
		if eq <= 0:
			continue
		var k: String = pair.substr(0, eq).replace("+", " ").uri_decode()
		var v: String = pair.substr(eq + 1).replace("+", " ").uri_decode()
		if k.length() <= 32 and not out.has(k):
			out[k] = v.substr(0, 64)
	return out


static func _status_text(code: int) -> String:
	match code:
		200:
			return "OK"
		400:
			return "Bad Request"
		404:
			return "Not Found"
		405:
			return "Method Not Allowed"
		411:
			return "Length Required"
		413:
			return "Payload Too Large"
		431:
			return "Request Header Fields Too Large"
	return "Error"


static func build_response(code: int, message: String) -> PackedByteArray:
	var safe: String = message.xml_escape()
	var title: String = "Hesap silindi" if code == 200 else "Silinemedi"
	var html: String = "<!DOCTYPE html><html lang=\"tr\"><head><meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><title>%s</title><style>body{font-family:system-ui,sans-serif;background:#F6EFE4;color:#3D3530;display:flex;justify-content:center;padding:32px 12px}.c{background:#FFFDF8;border:4px solid #24160E;border-radius:20px;padding:24px;max-width:460px}</style></head><body><div class=\"c\"><h1>%s</h1><p>%s</p></div></body></html>" % [title, title, safe]
	var body: PackedByteArray = html.to_utf8_buffer()
	var head: String = "HTTP/1.1 %d %s\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\nCache-Control: no-store\r\nX-Content-Type-Options: nosniff\r\nReferrer-Policy: no-referrer\r\nContent-Security-Policy: default-src 'none'; style-src 'unsafe-inline'\r\n" % [code, _status_text(code), body.size()]
	if code == 405:
		head += "Allow: POST\r\n"
	var out: PackedByteArray = (head + "\r\n").to_utf8_buffer()
	out.append_array(body)
	return out


func _respond(peer: StreamPeer, code: int, message: String) -> void:
	peer.put_data(build_response(code, message))


func _rate_ok(ip: String) -> bool:
	var now: float = Time.get_unix_time_from_system()
	var recent: Array = []
	for t_v: Variant in _rate_log.get(ip, []) as Array:
		if now - float(t_v) < GameConfig.MM_RATE_WINDOW_SEC:
			recent.append(t_v)
	if recent.size() >= REQ_PER_MIN_PER_IP:
		_rate_log[ip] = recent
		return false
	recent.append(now)
	_rate_log[ip] = recent
	return true


func prune() -> void:
	var now: float = Time.get_unix_time_from_system()
	for k_v: Variant in _rate_log.keys():
		var arr: Array = _rate_log[k_v] as Array
		if arr.is_empty() or now - float(arr[arr.size() - 1]) >= GameConfig.MM_RATE_WINDOW_SEC:
			_rate_log.erase(k_v)

class_name NetStream
extends RefCounted

## Faz 12.5: Eşleştirici bağlantıları için TCP / TLS ortak yardımcıları.
## Sunucu: TLSOptions.server(anahtar, sertifika). İstemci: yayında sistemin güvendiği sertifikalar;
## yalnızca debug derlemede "--tls-trust=<pem>" ile yerel test sertifikasına güvenilebilir.

const PENDING: int = 0
const OK_STATE: int = 1
const DEAD: int = -1


## Akışı ilerletir ve durumunu döner: PENDING (bağlanıyor / el sıkışma), OK_STATE, DEAD.
static func poll_state(s: StreamPeer) -> int:
	if s is StreamPeerTLS:
		var tls: StreamPeerTLS = s as StreamPeerTLS
		tls.poll()
		match tls.get_status():
			StreamPeerTLS.STATUS_HANDSHAKING:
				return PENDING
			StreamPeerTLS.STATUS_CONNECTED:
				return OK_STATE
		return DEAD
	if s is StreamPeerTCP:
		var tcp: StreamPeerTCP = s as StreamPeerTCP
		tcp.poll()
		match tcp.get_status():
			StreamPeerTCP.STATUS_CONNECTING:
				return PENDING
			StreamPeerTCP.STATUS_CONNECTED:
				return OK_STATE
		return DEAD
	return DEAD


## Durumu ilerletmeden yalnızca bakar.
static func is_open(s: StreamPeer) -> bool:
	if s is StreamPeerTLS:
		return (s as StreamPeerTLS).get_status() == StreamPeerTLS.STATUS_CONNECTED
	if s is StreamPeerTCP:
		return (s as StreamPeerTCP).get_status() == StreamPeerTCP.STATUS_CONNECTED
	return false


static func close(s: StreamPeer) -> void:
	if s is StreamPeerTLS:
		(s as StreamPeerTLS).disconnect_from_stream()
	elif s is StreamPeerTCP:
		(s as StreamPeerTCP).disconnect_from_host()


static func put_line(s: StreamPeer, payload: Dictionary) -> Error:
	if not is_open(s):
		return ERR_CONNECTION_ERROR
	return s.put_data((JSON.stringify(payload) + "\n").to_utf8_buffer())


## Sunucu sertifikası ve anahtarı: "--tls-cert=" / "--tls-key=" ya da veri klasöründeki tls/fullchain.pem, tls/privkey.pem.
static func load_server_options(data_dir: String) -> TLSOptions:
	var cert_path: String = GameConfig.cmdline_value(GameConfig.TLS_CERT_ARG)
	var key_path: String = GameConfig.cmdline_value(GameConfig.TLS_KEY_ARG)
	if cert_path.is_empty():
		cert_path = data_dir.path_join("tls/fullchain.pem")
	if key_path.is_empty():
		key_path = data_dir.path_join("tls/privkey.pem")
	var cert: X509Certificate = X509Certificate.new()
	var key: CryptoKey = CryptoKey.new()
	if cert.load(cert_path) != OK or key.load(key_path) != OK:
		push_error("[TLS] Sertifika/anahtar yüklenemedi: %s , %s" % [cert_path, key_path])
		return null
	return TLSOptions.server(key, cert)


## İstemci seçenekleri. Debug derlemede "--tls-trust=<pem>" verilirse yalnızca o sertifikaya güvenir.
static func client_options() -> TLSOptions:
	if OS.is_debug_build():
		var trust_path: String = GameConfig.cmdline_value(GameConfig.TLS_TRUST_ARG)
		if not trust_path.is_empty():
			var cert: X509Certificate = X509Certificate.new()
			if cert.load(trust_path) == OK:
				return TLSOptions.client(cert, GameConfig.cmdline_value(GameConfig.TLS_CN_ARG))
	return TLSOptions.client()


## İstemci: bağlanmış (ya da bağlanmakta olan) TCP akışını TLS ile sarar. Başarısızsa null.
static func wrap_client(tcp: StreamPeerTCP, host: String, options: TLSOptions) -> StreamPeerTLS:
	var tls: StreamPeerTLS = StreamPeerTLS.new()
	if tls.connect_to_stream(tcp, host, options) != OK:
		return null
	return tls


## Yayın derlemesinde TLS kapalıysa konsola büyük uyarı.
static func warn_if_insecure(who: String) -> void:
	if OS.is_debug_build() or GameConfig.tls_enabled():
		return
	var bar: String = "!".repeat(72)
	printerr(bar)
	printerr("!!  UYARI (%s): GameConfig.USE_TLS = false — eşleştirici bağlantısı ŞİFRESİZ." % who)
	printerr("!!  Yayın sürümünde TLS açılmalı (bkz. server/SUNUCU_KURULUM.md, TLS bölümü).")
	printerr(bar)

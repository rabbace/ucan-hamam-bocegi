class_name LanDiscovery
extends Node

## Aynı Wi-Fi / LAN ağında UDP 7778 üzerinden oda yayınlama ve bulma.

signal rooms_updated(rooms: Array[Dictionary])

const BROADCAST_INTERVAL: float = 1.0
const ROOM_EXPIRE_SEC: float = 3.5

var _udp_sender: PacketPeerUDP = null
var _udp_listener: PacketPeerUDP = null
var _is_broadcasting: bool = false
var _is_listening: bool = false
var _broadcast_timer: float = 0.0
var _broadcast_payload: Dictionary = {}
var _discovered_rooms: Dictionary = {} # ip -> {data, last_seen}


func _process(delta: float) -> void:
	if _is_broadcasting and _udp_sender != null:
		_broadcast_timer += delta
		if _broadcast_timer >= BROADCAST_INTERVAL:
			_broadcast_timer = 0.0
			_send_broadcast()

	if _is_listening and _udp_listener != null:
		_poll_listener()


## Host olarak saniyede 1 kez oda bilgisini ağa yayınlamaya başlar.
func start_broadcast(host_name: String, player_count: int, in_match: bool) -> void:
	stop_all()
	_udp_sender = PacketPeerUDP.new()
	_udp_sender.set_broadcast_enabled(true)
	_udp_sender.set_dest_address("255.255.255.255", GameConfig.DISCOVERY_PORT)
	_broadcast_payload = {
		"game": "hamam_bocegi",
		"version": GameConfig.NET_VERSION,
		"host_name": host_name,
		"players": player_count,
		"in_match": in_match,
	}
	_is_broadcasting = true
	_broadcast_timer = BROADCAST_INTERVAL


## Yayınlanan oyuncu sayısı ve maç durumunu günceller.
func update_broadcast_info(player_count: int, in_match: bool) -> void:
	_broadcast_payload["players"] = player_count
	_broadcast_payload["in_match"] = in_match


## İstemci olarak yerel ağdaki oda yayınlarını dinlemeye başlar.
func start_listening() -> void:
	stop_all()
	_udp_listener = PacketPeerUDP.new()
	var err: Error = _udp_listener.bind(GameConfig.DISCOVERY_PORT)
	if err != OK:
		push_warning("LAN dinleme portu açılamadı: %d" % err)
		return
	_is_listening = true
	_discovered_rooms.clear()


## Tüm UDP soketlerini kapatır.
func stop_all() -> void:
	_is_broadcasting = false
	_is_listening = false
	if _udp_sender != null:
		_udp_sender.close()
		_udp_sender = null
	if _udp_listener != null:
		_udp_listener.close()
		_udp_listener = null
	_discovered_rooms.clear()


func _send_broadcast() -> void:
	var json_text: String = JSON.stringify(_broadcast_payload)
	_udp_sender.put_packet(json_text.to_utf8_buffer())


func _poll_listener() -> void:
	var now: float = Time.get_ticks_msec() * 0.001
	var changed: bool = false

	while _udp_listener.get_available_packet_count() > 0:
		var pkt: PackedByteArray = _udp_listener.get_packet()
		var sender_ip: String = _udp_listener.get_packet_ip()
		var parsed: Variant = JSON.parse_string(pkt.get_string_from_utf8())
		if parsed is Dictionary:
			var d: Dictionary = parsed as Dictionary
			if str(d.get("game", "")) == "hamam_bocegi":
				d["ip"] = sender_ip
				_discovered_rooms[sender_ip] = {"data": d, "last_seen": now}
				changed = true

	var expired: Array[String] = []
	for ip: String in _discovered_rooms.keys():
		var entry: Dictionary = _discovered_rooms[ip] as Dictionary
		if now - float(entry["last_seen"]) > ROOM_EXPIRE_SEC:
			expired.append(ip)
	for ip: String in expired:
		_discovered_rooms.erase(ip)
		changed = true

	if changed:
		var list: Array[Dictionary] = []
		for ip: String in _discovered_rooms.keys():
			var entry: Dictionary = _discovered_rooms[ip] as Dictionary
			list.append(entry["data"] as Dictionary)
		rooms_updated.emit(list)


## Cihazın yerel Wi-Fi / LAN IPv4 adresini döner.
static func get_local_ipv4() -> String:
	for addr: String in IP.get_local_addresses():
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
		if addr.begins_with("172."):
			var parts: PackedStringArray = addr.split(".")
			if parts.size() >= 2:
				var second: int = int(parts[1])
				if second >= 16 and second <= 31:
					return addr
	return "127.0.0.1"

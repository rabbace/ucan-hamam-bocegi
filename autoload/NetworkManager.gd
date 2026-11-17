extends Node

## Çok oyunculu ağ yöneticisi: lobi durumu, senkronizasyon ve maç akışı.
## Sunucu tarafı maç saati ve sonuç hesabı sahneden bağımsızdır (ayrılmış oda sunucusu GameWorld yüklemez).

signal players_updated
signal connection_succeeded
signal connection_failed(reason: String)
signal match_countdown_started
signal player_eliminated(peer_id: int, cause: String)
signal player_left_match(peer_id: int)
signal winner_announced(winner_id: int, is_draw: bool)
signal victory_lap_started(winner_id: int)
signal results_ready(results: Array)
signal taunt_applied(sender_id: int, target_id: int, item_id: String)
signal quick_chat_received(sender_id: int, text: String)
signal ghost_slipper_spawned(thrower_id: int, y: float, launch_match_time: float)
signal awards_ready(awards: Array)
signal item_fx_received(sender_id: int, item_id: String)
## Yerel oyuncu ağ tarafından öldürüldü (ör. uzun süre arka planda kaldı); GameWorld yerel oyuncuyu öldürmeli.
signal local_death_forced(cause: String)

const NAME_FILTER := preload("res://net/NameFilter.gd")
# Eşya efekti yayınında kabul edilen kimlikler
const ITEM_FX_IDS: Array[String] = ["turbo", "taunt"]
# Ayrılmış sunucuda istemcilerin GameWorld yolunu taklit eden hafif ayna (Player RPC'leri için)
const MIRROR_ROOT_NAME: String = "GameWorld"
const MIRROR_LAYER_NAME: String = "PlayersLayer"
const PLAYER_SCENE_PATH: String = "res://scenes/entities/Player.tscn"

var local_player_name: String = "Böcek"
var selected_char_id: String = "klasik"
var selected_bg_id: String = "mutfak"
var current_seed: int = 0

var is_multiplayer_match: bool = false
var is_dedicated_mode: bool = false
var in_match: bool = false
var players: Dictionary = {} # peer_id -> {name, char_id, is_alive, score, wins}
var pending_notice: String = ""
var server_host: String = GameConfig.DEFAULT_SERVER_HOST
var room_code: String = ""
var room_owner_id: int = 1
var is_public_room: bool = false
var quick_play_countdown: float = -1.0
## Geri sayım başladı mı (geç yüklenen GameWorld _ready'de kontrol eder)
var countdown_started: bool = false
## Geri sayım bildiriminin bu cihaza ulaştığı an (Time.get_ticks_msec)
var countdown_start_ms: int = 0
var current_match_time: float = 0.0

var _rpc_counts: Dictionary = {} # peer_id -> {sec, n}
var _paused_since_ms: int = 0
var _transport: NetTransport = ENetTransport.new()
var _discovery: LanDiscovery = null
var _connect_timer: SceneTreeTimer = null
var _local_death_reported: bool = false
var _item_fx_last_ms: Dictionary = {} # peer_id -> int (her alıcıda)
var _immune_until_ms: Dictionary = {} # peer_id -> int

# Yalnızca sunucuda kullanılan durum
var _pending_register: Dictionary = {} # peer_id -> bağlanma ms
var _kick_at_ms: Dictionary = {} # peer_id -> kesme ms
var _loaded_peers: Dictionary = {}
var _death_order: Array[int] = []
var _death_causes: Dictionary = {} # peer_id -> String
var _taunts_sent: Dictionary = {} # peer_id -> int
var _last_taunt_ms: Dictionary = {} # peer_id -> int
var _last_chat_ms: Dictionary = {} # peer_id -> int
var _ghost_kills: Dictionary = {} # peer_id -> int
var _pending_ghost_kill: Dictionary = {} # kurban -> atan
var _ghost_kill_counted: Dictionary = {} # kurban -> bool
var _survival_times: Dictionary = {} # peer_id -> float (sunucu saati)
var _match_roster: Dictionary = {} # peer_id -> {name, char_id, score}
var _disconnected_in_match: Dictionary = {} # peer_id -> bool
var _victory_lap_active: bool = false
var _victory_winner_id: int = 0
var _victory_lap_deadline_ms: int = 0
var _results_sent: bool = false
var _match_start_ms: int = 0
var _server_countdown_ms: int = 0
var _server_timeline: ObstacleTimeline = null
var _last_ghost_throw_ms: Dictionary = {} # peer_id -> int
var _mirror_active: Dictionary = {} # peer_id -> bool
var _server_mirror: Node = null


func _ready() -> void:
	load_local_settings()
	_discovery = LanDiscovery.new()
	add_child(_discovery)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Sunucu tarafı zamanlayıcılar: kayıt süresi, gecikmeli atma, yükleme süresi, zafer turu.
func _process(_delta: float) -> void:
	if not is_multiplayer_match or multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	var now_ms: int = Time.get_ticks_msec()
	var connected: PackedInt32Array = multiplayer.get_peers()

	for pid_v: Variant in _kick_at_ms.keys():
		var pid: int = int(pid_v)
		if now_ms >= int(_kick_at_ms[pid]):
			_kick_at_ms.erase(pid)
			if connected.has(pid):
				multiplayer.multiplayer_peer.disconnect_peer(pid)

	var reg_limit_ms: int = int(GameConfig.NET_REGISTER_TIMEOUT_SEC * 1000.0)
	for pid_v: Variant in _pending_register.keys():
		var pid: int = int(pid_v)
		if now_ms - int(_pending_register[pid]) >= reg_limit_ms:
			_pending_register.erase(pid)
			if connected.has(pid) and not players.has(pid):
				multiplayer.multiplayer_peer.disconnect_peer(pid)

	if not in_match:
		return
	if is_dedicated_mode:
		current_match_time = _server_match_time()
	if _server_countdown_ms == 0 and now_ms - _match_start_ms >= int(GameConfig.NET_LOAD_TIMEOUT_SEC * 1000.0):
		_begin_countdown_now()
	if _victory_lap_active and _victory_lap_deadline_ms > 0 and now_ms >= _victory_lap_deadline_ms:
		_finalize_match_results()


## Yerel oyuncu adını ve ayarları config dosyasından yükler.
func load_local_settings() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	var err: Error = cfg.load(GameConfig.SETTINGS_PATH)
	if err != OK:
		return
	var saved_name: String = str(cfg.get_value("player", "name", "Böcek"))
	local_player_name = saved_name.substr(0, GameConfig.MAX_NAME_LENGTH)
	selected_char_id = str(cfg.get_value("player", "char_id", "klasik"))
	selected_bg_id = str(cfg.get_value("player", "bg_id", "mutfak"))
	server_host = str(cfg.get_value("online", "server_host", GameConfig.DEFAULT_SERVER_HOST))


func save_server_host(new_host: String) -> void:
	var clean: String = new_host.strip_edges()
	server_host = clean if not clean.is_empty() else GameConfig.DEFAULT_SERVER_HOST
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("online", "server_host", server_host)
	cfg.save(GameConfig.SETTINGS_PATH)


func is_dedicated_server() -> bool:
	return is_dedicated_mode and multiplayer.multiplayer_peer != null and multiplayer.is_server()


func is_room_owner() -> bool:
	if not is_dedicated_mode:
		return multiplayer.is_server()
	return multiplayer.multiplayer_peer != null and multiplayer.get_unique_id() == room_owner_id


func _notification(what: int) -> void:
	if not is_dedicated_mode or not in_match or multiplayer.multiplayer_peer == null or multiplayer.is_server():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused_since_ms = Time.get_ticks_msec()
	elif what == NOTIFICATION_APPLICATION_RESUMED and _paused_since_ms > 0:
		var elapsed: float = float(Time.get_ticks_msec() - _paused_since_ms) * 0.001
		_paused_since_ms = 0
		if elapsed >= 10.0 and not _local_death_reported:
			notify_local_death("arka_plan")
			# Sunucu zaten ölü saydı; yerel oyuncu da ölmeli (ikinci bildirim sunucuda yok sayılır)
			local_death_forced.emit("arka_plan")


## Yerel oyuncu adını config dosyasına kaydeder.
func save_player_name(player_name: String) -> void:
	var trimmed: String = player_name.strip_edges().substr(0, GameConfig.MAX_NAME_LENGTH)
	if trimmed.is_empty():
		trimmed = "Böcek"
	local_player_name = trimmed
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("player", "name", local_player_name)
	cfg.save(GameConfig.SETTINGS_PATH)


## Seçilen karakter kimliğini config dosyasına kaydeder.
func save_selected_char(char_id: String) -> void:
	selected_char_id = char_id
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("player", "char_id", selected_char_id)
	cfg.save(GameConfig.SETTINGS_PATH)


## Seçilen arka plan temasını config dosyasına kaydeder.
func save_selected_bg(bg_id: String) -> void:
	selected_bg_id = bg_id
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value("player", "bg_id", selected_bg_id)
	cfg.save(GameConfig.SETTINGS_PATH)


## Yeni tek oyunculu maç için seed belirler.
func prepare_single_player_seed(custom_seed: int = 0) -> int:
	is_multiplayer_match = false
	is_dedicated_mode = false
	room_code = ""
	room_owner_id = 1
	is_public_room = false
	in_match = false
	countdown_started = false
	if custom_seed != 0:
		current_seed = custom_seed
	else:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.randomize()
		current_seed = int(rng.randi())
		if current_seed == 0:
			current_seed = 1
	return current_seed


## LAN keşif düğümünü döner.
func get_discovery() -> LanDiscovery:
	return _discovery


## Host olarak oda kurar.
func host_game() -> bool:
	leave_game()
	var peer: MultiplayerPeer = _transport.create_host(GameConfig.NET_PORT, GameConfig.NET_MAX_CLIENTS)
	if peer == null:
		return false
	multiplayer.multiplayer_peer = peer
	is_multiplayer_match = true
	in_match = false
	players.clear()
	var host_name: String = sanitize_player_name(local_player_name)
	players[1] = {
		"name": host_name,
		"char_id": selected_char_id if CharacterData.CHARACTERS.has(selected_char_id) else "klasik",
		"is_alive": true,
		"score": 0,
		"wins": 0,
		"awards": 0,
		"total_points": 0,
	}
	_discovery.start_broadcast(host_name, players.size(), false)
	players_updated.emit()
	return true


## 8.9: Ayrılmış oda sunucusu başlatır (peer 1 sunucudur, oyuncu değildir).
func start_dedicated_room(port: int, code: String, p_is_public: bool) -> bool:
	leave_game()
	var peer: MultiplayerPeer = _transport.create_host(port, GameConfig.NET_MAX_CLIENTS + 1)
	if peer == null:
		return false
	multiplayer.multiplayer_peer = peer
	is_multiplayer_match = true
	is_dedicated_mode = true
	in_match = false
	room_code = code
	is_public_room = p_is_public
	room_owner_id = 0
	players.clear()
	return true


## 8.9: Çevrimiçi eşleştirici tarafından verilen odaya bağlanır.
func join_online_room(port: int, code: String, p_is_public: bool) -> bool:
	leave_game()
	var peer: MultiplayerPeer = _transport.create_client(server_host, port)
	if peer == null:
		connection_failed.emit("Sunucuya ulaşılamadı. İnternetini kontrol et.")
		return false
	multiplayer.multiplayer_peer = peer
	is_multiplayer_match = true
	is_dedicated_mode = true
	in_match = false
	room_code = code
	is_public_room = p_is_public
	_connect_timer = get_tree().create_timer(GameConfig.NET_CONNECT_TIMEOUT_SEC)
	_connect_timer.timeout.connect(_on_connect_timeout)
	return true


@rpc("any_peer", "call_local", "reliable")
func request_start_match() -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, false):
		return
	if sender_id != _owner_peer_id() or in_match:
		return
	host_start_match()


@rpc("any_peer", "call_local", "reliable")
func request_return_lobby() -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, false):
		return
	if sender_id != _owner_peer_id() or in_match:
		return
	host_return_to_lobby()


## Oyuncu adını temizler (bkz. net/NameFilter.gd): harf/rakam/boşluk, Türkçe küçültme, kelime bazlı argo süzgeci.
func sanitize_player_name(raw_name: String) -> String:
	return NAME_FILTER.sanitize(raw_name)


## Verilen IP adresine istemci olarak bağlanır (6 sn zaman aşımı ile).
func join_game(address: String) -> bool:
	leave_game()
	var clean_ip: String = address.strip_edges()
	if clean_ip.is_empty():
		connection_failed.emit("Geçerli bir IP adresi girin.")
		return false
	var peer: MultiplayerPeer = _transport.create_client(clean_ip, GameConfig.NET_PORT)
	if peer == null:
		connection_failed.emit("Bağlantı başlatılamadı.")
		return false
	multiplayer.multiplayer_peer = peer
	is_multiplayer_match = true
	in_match = false
	players.clear()

	_connect_timer = get_tree().create_timer(GameConfig.NET_CONNECT_TIMEOUT_SEC)
	_connect_timer.timeout.connect(_on_connect_timeout)
	return true


## Aktif ağ bağlantısını ve LAN yayınını kapatır.
func leave_game() -> void:
	_discovery.stop_all()
	_connect_timer = null
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	_pending_register.clear()
	_kick_at_ms.clear()
	_rpc_counts.clear()
	_item_fx_last_ms.clear()
	_reset_match_state()
	is_multiplayer_match = false
	is_dedicated_mode = false
	room_code = ""
	room_owner_id = 1
	is_public_room = false
	in_match = false
	quick_play_countdown = -1.0


## İstemci karakter değiştirmek istediğinde çağrılır.
func request_char_change(char_id: String) -> void:
	save_selected_char(char_id)
	if multiplayer.multiplayer_peer != null and is_multiplayer_match:
		request_char.rpc_id(1, char_id)


## Host maçı başlatır ve tüm eşlere seed gönderir.
func host_start_match() -> void:
	if not multiplayer.is_server() or in_match or players.is_empty():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var new_seed: int = int(rng.randi())
	if new_seed == 0:
		new_seed = 1
	_reset_match_state()
	in_match = true
	_match_start_ms = Time.get_ticks_msec()
	# Skor tavanı için istemcilerle aynı deterministik zaman çizelgesi
	_server_timeline = ObstacleTimeline.new()
	_server_timeline.generate(new_seed, true)
	for pid: int in players.keys():
		_match_roster[pid] = {
			"name": str(players[pid].get("name", "Böcek")),
			"char_id": str(players[pid].get("char_id", "klasik")),
			"score": 0,
		}
		players[pid]["is_alive"] = true
		players[pid]["score"] = 0
	if not is_dedicated_mode:
		_discovery.update_broadcast_info(players.size(), true)
	sync_players.rpc(players)
	start_match.rpc(new_seed)


## Maç bittiğinde Host herkesi lobiye döndürür.
func host_return_to_lobby() -> void:
	if not multiplayer.is_server():
		return
	in_match = false
	_victory_lap_active = false
	if not is_dedicated_mode:
		_discovery.update_broadcast_info(players.size(), false)
	return_to_lobby.rpc()


## Yerel oyuncu öldüğünde sunucuya bildirir (maç başına bir kez).
func notify_local_death(cause: String, m_time: float = -1.0) -> void:
	if not is_multiplayer_match or multiplayer.multiplayer_peer == null:
		return
	if _local_death_reported:
		return
	_local_death_reported = true
	var my_id: int = multiplayer.get_unique_id()
	# İstemcide sayaç hemen güncellensin; LAN host'ta players yetkili veridir, sunucu işlesin
	if not multiplayer.is_server() and players.has(my_id):
		players[my_id]["is_alive"] = false
	var t_val: float = m_time if m_time >= 0.0 else current_match_time
	report_death.rpc_id(1, cause, t_val)


## Hayatta kalan ve toplam oyuncu sayılarını döner.
func get_alive_counts() -> Vector2i:
	var alive: int = 0
	var total: int = players.size()
	for pid: int in players.keys():
		if bool(players[pid].get("is_alive", false)):
			alive += 1
	return Vector2i(alive, total)


## Geri sayım başladıysa bu cihazda geçen süre (sn); başlamadıysa -1.
func get_countdown_elapsed() -> float:
	if not countdown_started:
		return -1.0
	return float(Time.get_ticks_msec() - countdown_start_ms) * 0.001


## İstemci: hızlı sohbet metnini indekse çevirip sunucuya yollar (serbest metin gönderilmez).
func send_quick_chat_text(text: String) -> void:
	if not is_multiplayer_match or multiplayer.multiplayer_peer == null:
		return
	var idx: int = _quick_chat_index_for(text, selected_char_id)
	if idx < 0:
		return
	request_quick_chat.rpc_id(1, idx)


func _on_connect_timeout() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		leave_game()
		connection_failed.emit("Bağlantı zaman aşımına uğradı (6 sn).")


func _on_connected_to_server() -> void:
	_connect_timer = null
	_apply_peer_timeout(1)
	register_player.rpc_id(1, local_player_name, selected_char_id, GameConfig.NET_VERSION)
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	_connect_timer = null
	leave_game()
	connection_failed.emit("Odaya bağlanılamadı.")


func _on_server_disconnected() -> void:
	_connect_timer = null
	leave_game()
	pending_notice = "Oda sahibi ayrıldı."
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return
	_apply_peer_timeout(peer_id)
	_pending_register[peer_id] = Time.get_ticks_msec()


func _on_peer_disconnected(peer_id: int) -> void:
	_pending_register.erase(peer_id)
	_kick_at_ms.erase(peer_id)
	_rpc_counts.erase(peer_id)
	_item_fx_last_ms.erase(peer_id)
	if not players.has(peer_id):
		return
	var is_server_side: bool = multiplayer.multiplayer_peer != null and multiplayer.is_server()
	if in_match and is_server_side:
		# Maç içinde kopan oyuncu o an ölü sayılır
		_disconnected_in_match[peer_id] = true
		if not _survival_times.has(peer_id):
			_survival_times[peer_id] = _server_match_time()
		if _match_roster.has(peer_id):
			_match_roster[peer_id]["score"] = int(players[peer_id].get("score", 0))
	players.erase(peer_id)
	_loaded_peers.erase(peer_id)
	if is_server_side:
		if is_dedicated_mode and room_owner_id == peer_id:
			var rem: Array = players.keys()
			rem.sort()
			room_owner_id = int(rem[0]) if not rem.is_empty() else 0
			sync_room_meta.rpc(room_owner_id, room_code, is_public_room)
		if not is_dedicated_mode:
			_discovery.update_broadcast_info(players.size(), in_match)
		sync_players.rpc(players)
		if in_match:
			if players.is_empty():
				# Herkes çıktı: maçı sessizce kapat, oda lobiye döner
				_reset_match_state()
				in_match = false
			elif _victory_lap_active and peer_id == _victory_winner_id:
				_finalize_match_results()
			elif not _victory_lap_active:
				_check_all_loaded()
				_check_match_end_after_elimination()
	player_left_match.emit(peer_id)
	players_updated.emit()


@rpc("any_peer", "call_remote", "reliable")
func register_player(p_name: String, p_char_id: String, p_version: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0 or not _rpc_guard(sender_id, false):
		return
	if players.has(sender_id):
		return
	_pending_register.erase(sender_id)
	if p_version != GameConfig.NET_VERSION:
		_reject_peer(sender_id, "Sürüm uyuşmazlığı! Oyunu güncelleyin.")
		return
	if in_match:
		_reject_peer(sender_id, "Maç devam ediyor, daha sonra katılın.")
		return
	if players.size() >= GameConfig.NET_MAX_CLIENTS + 1:
		_reject_peer(sender_id, "Oda dolu (en fazla 5 oyuncu).")
		return

	var clean_name: String = sanitize_player_name(p_name)
	var valid_char: String = p_char_id if CharacterData.CHARACTERS.has(p_char_id) else "klasik"

	players[sender_id] = {
		"name": clean_name,
		"char_id": valid_char,
		"is_alive": true,
		"score": 0,
		"wins": 0,
		"awards": 0,
		"total_points": 0,
	}
	if is_dedicated_mode and room_owner_id == 0:
		room_owner_id = sender_id
	if not is_dedicated_mode:
		_discovery.update_broadcast_info(players.size(), in_match)
	sync_room_meta.rpc(room_owner_id, room_code, is_public_room)
	sync_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func sync_room_meta(owner_id: int, code: String, p_is_public: bool) -> void:
	room_owner_id = owner_id
	room_code = code
	is_public_room = p_is_public
	players_updated.emit()


@rpc("authority", "call_remote", "reliable")
func reject_client(reason: String) -> void:
	pending_notice = reason
	leave_game()
	connection_failed.emit(reason)
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")


@rpc("any_peer", "call_local", "reliable")
func request_char(char_id: String) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or in_match:
		return
	if not CharacterData.CHARACTERS.has(char_id):
		return
	if str(players[sender_id].get("char_id", "")) == char_id:
		return
	players[sender_id]["char_id"] = char_id
	sync_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func sync_players(p_players: Dictionary) -> void:
	players = p_players.duplicate(true)
	players_updated.emit()


@rpc("authority", "call_local", "reliable")
func start_match(world_seed: int) -> void:
	current_seed = world_seed
	is_multiplayer_match = true
	in_match = true
	countdown_started = false
	countdown_start_ms = 0
	current_match_time = 0.0
	_local_death_reported = false
	_immune_until_ms.clear()
	_item_fx_last_ms.clear()
	# Ayrılmış sunucu sahne değiştirmez: RoomServer düğümü yaşamaya devam etmeli
	if is_dedicated_server():
		_build_server_mirror()
		return
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


@rpc("any_peer", "call_local", "reliable")
func client_loaded() -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not in_match:
		return
	_loaded_peers[sender_id] = true
	_check_all_loaded()


## Odadaki tüm oyuncular yüklendiyse geri sayımı başlatır.
func _check_all_loaded() -> void:
	if not in_match or _server_countdown_ms != 0 or players.is_empty():
		return
	for pid: int in players.keys():
		if not _loaded_peers.has(pid):
			return
	_begin_countdown_now()


func _begin_countdown_now() -> void:
	if _server_countdown_ms != 0:
		return
	_server_countdown_ms = Time.get_ticks_msec()
	begin_countdown.rpc()


@rpc("authority", "call_local", "reliable")
func begin_countdown() -> void:
	countdown_started = true
	countdown_start_ms = Time.get_ticks_msec()
	match_countdown_started.emit()


@rpc("any_peer", "call_local", "reliable")
func report_death(cause: String, m_time: float = -1.0) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not in_match or _results_sent:
		return
	var server_t: float = _server_match_time()
	# İstemci saati sunucu saatini geçemez (sıralama hilesine karşı)
	var t_val: float = server_t
	if m_time >= 0.0 and not is_nan(m_time):
		t_val = minf(m_time, server_t)
	var clean_cause: String = _clean_cause(cause)

	# Zafer turunda kazanan ölürse zafer turu biter
	if _victory_lap_active:
		if sender_id == _victory_winner_id and not _survival_times.has(sender_id):
			_survival_times[sender_id] = t_val
			_death_causes[sender_id] = clean_cause
			_recheck_victory_lap_winner(t_val)
			_finalize_match_results()
		return

	# Aynı eşin ikinci ölüm bildirimi yok sayılır
	if not bool(players[sender_id].get("is_alive", false)):
		return
	players[sender_id]["is_alive"] = false
	_survival_times[sender_id] = t_val
	_death_causes[sender_id] = clean_cause
	if _match_roster.has(sender_id):
		_match_roster[sender_id]["score"] = int(players[sender_id].get("score", 0))
	if not _death_order.has(sender_id):
		_death_order.append(sender_id)
	_count_ghost_kill(sender_id)
	announce_elimination.rpc(sender_id, clean_cause)
	_check_match_end_after_elimination()


@rpc("authority", "call_local", "reliable")
func announce_elimination(peer_id: int, cause: String) -> void:
	if players.has(peer_id):
		players[peer_id]["is_alive"] = false
	player_eliminated.emit(peer_id, cause)
	players_updated.emit()


func _check_match_end_after_elimination() -> void:
	if not in_match or _victory_lap_active or _results_sent:
		return
	var alive_ids: Array[int] = []
	for pid: int in players.keys():
		if bool(players[pid].get("is_alive", false)):
			alive_ids.append(pid)

	if alive_ids.size() == 1 and _match_roster.size() >= 2:
		var winner_id: int = alive_ids[0]
		_victory_lap_active = true
		_victory_winner_id = winner_id
		_victory_lap_deadline_ms = Time.get_ticks_msec() + int((GameConfig.VICTORY_LAP_DURATION + GameConfig.NET_VICTORY_LAP_GRACE_SEC) * 1000.0)
		if players.has(winner_id):
			players[winner_id]["wins"] = int(players[winner_id].get("wins", 0)) + 1
		sync_players.rpc(players)
		start_victory_lap.rpc(winner_id)
	elif alive_ids.is_empty():
		# Herkes öldü: kazanan paket sırasıyla değil, sunucu saatindeki hayatta kalma süresiyle belirlenir
		_victory_winner_id = _pick_winner_by_survival()
		if _victory_winner_id > 0 and players.has(_victory_winner_id):
			players[_victory_winner_id]["wins"] = int(players[_victory_winner_id].get("wins", 0)) + 1
		_finalize_match_results()


## Hayatta kalma süresi en uzun (ayrılmayan) oyuncuyu döner; ilk ikisi çok yakınsa 0 (berabere).
func _pick_winner_by_survival() -> int:
	var best_id: int = 0
	var best_t: float = -1.0
	var second_t: float = -1.0
	for pid: int in _match_roster.keys():
		if bool(_disconnected_in_match.get(pid, false)) or not _survival_times.has(pid):
			continue
		var t_s: float = float(_survival_times[pid])
		if t_s > best_t:
			second_t = best_t
			best_t = t_s
			best_id = pid
		elif t_s > second_t:
			second_t = t_s
	if best_id == 0:
		return 0
	if second_t >= 0.0 and best_t - second_t <= GameConfig.NET_SIMULTANEOUS_DEATH_SEC:
		return 0
	return best_id


## Zafer turu, iki ölüm neredeyse aynı anda olduğu için paket sırasıyla başladıysa kazananı düzeltir.
func _recheck_victory_lap_winner(winner_death_t: float) -> void:
	var runner_t: float = -1.0
	for pid: int in _match_roster.keys():
		if pid == _victory_winner_id or bool(_disconnected_in_match.get(pid, false)):
			continue
		runner_t = maxf(runner_t, float(_survival_times.get(pid, -1.0)))
	if runner_t < 0.0 or winner_death_t > runner_t + GameConfig.NET_SIMULTANEOUS_DEATH_SEC:
		return
	var old_winner: int = _victory_winner_id
	if players.has(old_winner):
		players[old_winner]["wins"] = maxi(int(players[old_winner].get("wins", 0)) - 1, 0)
	_victory_winner_id = _pick_winner_by_survival()
	if _victory_winner_id > 0 and players.has(_victory_winner_id):
		players[_victory_winner_id]["wins"] = int(players[_victory_winner_id].get("wins", 0)) + 1


@rpc("authority", "call_local", "reliable")
func start_victory_lap(winner_id: int) -> void:
	_victory_lap_active = true
	_victory_winner_id = winner_id
	victory_lap_started.emit(winner_id)


@rpc("any_peer", "call_local", "reliable")
func request_finish_victory_lap() -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, false) or not _victory_lap_active:
		return
	if sender_id == _victory_winner_id or sender_id == multiplayer.get_unique_id():
		_finalize_match_results()


func _finalize_match_results() -> void:
	if not multiplayer.is_server() or _results_sent:
		return
	_results_sent = true
	_victory_lap_active = false
	_victory_lap_deadline_ms = 0
	var now_t: float = _server_match_time()

	# Roster'daki güncel skorları kaydet
	for pid: int in _match_roster.keys():
		if players.has(pid):
			_match_roster[pid]["score"] = int(players[pid].get("score", 0))

	# Rozetleri hesapla
	var awards: Array = _build_and_apply_awards(_victory_winner_id)
	var badge_map: Dictionary = {} # pid -> Array[String]
	var best_scare_id: int = 0
	var best_scare: int = -1
	for pid: int in _match_roster.keys():
		var sc: int = int(_match_roster[pid].get("score", 0))
		if sc > best_scare:
			best_scare = sc
			best_scare_id = pid
	if best_scare_id > 0 and best_scare > 0:
		_add_badge(badge_map, best_scare_id, "Çığlık Ustası")

	var top_taunt_id: int = _top_counter_id(_taunts_sent)
	if top_taunt_id > 0:
		_add_badge(badge_map, top_taunt_id, "Baş Belası")

	if not _death_order.is_empty():
		_add_badge(badge_map, _death_order[0], "Terlik Mıknatısı")

	var top_ghost_id: int = _top_counter_id(_ghost_kills)
	if top_ghost_id > 0:
		_add_badge(badge_map, top_ghost_id, "İntikam Meleği")

	# Sıralama: sunucu saatine göre hayatta kalma süresi (kazanan en üstte)
	var entries: Array[Dictionary] = []
	for pid: int in _match_roster.keys():
		var info: Dictionary = _match_roster[pid] as Dictionary
		var t_surv: float = float(_survival_times.get(pid, now_t))
		var t_display: float = t_surv
		if pid == _victory_winner_id and _victory_winner_id > 0:
			t_surv = now_t + 999.0
		entries.append({
			"peer_id": pid,
			"name": str(info.get("name", "Böcek")),
			"char_id": str(info.get("char_id", "klasik")),
			"score": int(info.get("score", 0)),
			"survival_time": t_surv,
			"display_time": t_display,
			"left": bool(_disconnected_in_match.get(pid, false)),
			"badges": badge_map.get(pid, []) as Array,
		})

	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["survival_time"]) > float(b["survival_time"])
	)

	# Sıra numarası ve ±0.05 sn beraberlik
	var results: Array = []
	var cur_rank: int = 1
	for i: int in range(entries.size()):
		if i > 0:
			var prev_t: float = float(entries[i - 1]["survival_time"])
			var cur_t: float = float(entries[i]["survival_time"])
			if absf(prev_t - cur_t) > GameConfig.NET_SIMULTANEOUS_DEATH_SEC:
				cur_rank = i + 1
		var row: Dictionary = entries[i]
		row["rank"] = cur_rank
		var pts: int = GameConfig.RANK_POINTS[mini(cur_rank - 1, GameConfig.RANK_POINTS.size() - 1)]
		row["points"] = pts
		var pid: int = int(row["peer_id"])
		if players.has(pid):
			players[pid]["total_points"] = int(players[pid].get("total_points", 0)) + pts
		results.append(row)

	sync_players.rpc(players)
	sync_awards.rpc(awards)
	show_results.rpc(results)


func _add_badge(badge_map: Dictionary, pid: int, title: String) -> void:
	if not badge_map.has(pid):
		badge_map[pid] = []
	(badge_map[pid] as Array).append(title)


## Sayaç sözlüğünde en yüksek (sıfırdan büyük) değere sahip eşi döner.
func _top_counter_id(counter: Dictionary) -> int:
	var top_id: int = 0
	var top_val: int = 0
	for pid_v: Variant in counter.keys():
		var cnt: int = int(counter[pid_v])
		if cnt > top_val:
			top_val = cnt
			top_id = int(pid_v)
	return top_id


@rpc("authority", "call_local", "reliable")
func show_results(results: Array) -> void:
	in_match = false
	_victory_lap_active = false
	results_ready.emit(results)


## Eşya efekti doğrudan yayınlanır; her alıcı göndericiyi, eşyayı ve sıklığı doğrular.
@rpc("any_peer", "call_local", "reliable")
func show_item_fx(item_id: String) -> void:
	var sender_id: int = _sender_id()
	if multiplayer.is_server() and not _rpc_guard(sender_id, true):
		return
	if not in_match or not ITEM_FX_IDS.has(item_id):
		return
	if not players.has(sender_id) or not bool(players[sender_id].get("is_alive", false)):
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - int(_item_fx_last_ms.get(sender_id, -100000)) < int(GameConfig.NET_ITEM_FX_COOLDOWN_SEC * 1000.0):
		return
	_item_fx_last_ms[sender_id] = now_ms
	item_fx_received.emit(sender_id, item_id)


func _build_and_apply_awards(winner_id: int) -> Array:
	var awards: Array = []
	if winner_id > 0 and players.has(winner_id):
		players[winner_id]["awards"] = int(players[winner_id].get("awards", 0)) + 1
		awards.append({"title": "Mahallenin Kralı", "name": str(players[winner_id]["name"])})

	var best_scare_id: int = 0
	var best_scare: int = -1
	for pid: int in players.keys():
		var sc: int = int(players[pid].get("score", 0))
		if sc > best_scare:
			best_scare = sc
			best_scare_id = pid
	if best_scare_id > 0 and players.has(best_scare_id):
		players[best_scare_id]["awards"] = int(players[best_scare_id].get("awards", 0)) + 1
		awards.append({"title": "Çığlık Ustası", "name": "%s (%d)" % [str(players[best_scare_id]["name"]), best_scare]})

	var top_taunt_id: int = _top_counter_id(_taunts_sent)
	if top_taunt_id > 0 and players.has(top_taunt_id):
		var top_taunts: int = int(_taunts_sent[top_taunt_id])
		players[top_taunt_id]["awards"] = int(players[top_taunt_id].get("awards", 0)) + 1
		awards.append({"title": "Baş Belası", "name": "%s (%d)" % [str(players[top_taunt_id]["name"]), top_taunts]})

	if not _death_order.is_empty():
		var first_dead: int = _death_order[0]
		if players.has(first_dead):
			players[first_dead]["awards"] = int(players[first_dead].get("awards", 0)) + 1
			awards.append({"title": "Terlik Mıknatısı", "name": str(players[first_dead]["name"])})

	var top_ghost_id: int = _top_counter_id(_ghost_kills)
	if top_ghost_id > 0 and players.has(top_ghost_id):
		players[top_ghost_id]["awards"] = int(players[top_ghost_id].get("awards", 0)) + 1
		awards.append({"title": "İntikam Meleği", "name": str(players[top_ghost_id]["name"])})
	return awards


@rpc("authority", "call_local", "reliable")
func sync_awards(awards: Array) -> void:
	awards_ready.emit(awards)


## Hedef oyuncunun sataşmaya karşı bağışık olup olmadığını döner (istemci arayüzü için).
func is_player_immune(pid: int) -> bool:
	return Time.get_ticks_msec() < int(_immune_until_ms.get(pid, 0))


@rpc("any_peer", "call_local", "reliable")
func send_taunt_item(target_id: int, item_id: String) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not _match_running():
		return
	if not bool(players[sender_id].get("is_alive", false)):
		return
	if not GameConfig.TAUNT_DEFS.has(item_id):
		return
	# Sunucu eşya alımını bilmediği için: eş başına bekleme süresi ve maç başına üst sınır
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - int(_last_taunt_ms.get(sender_id, -100000)) < int(GameConfig.NET_TAUNT_COOLDOWN_SEC * 1000.0):
		return
	if int(_taunts_sent.get(sender_id, 0)) >= GameConfig.NET_TAUNT_MAX_PER_MATCH:
		return
	if item_id == "ayna":
		_last_taunt_ms[sender_id] = now_ms
		_mirror_active[sender_id] = true
		_taunts_sent[sender_id] = int(_taunts_sent.get(sender_id, 0)) + 1
		apply_taunt.rpc(sender_id, sender_id, item_id)
		return
	if target_id == sender_id or not players.has(target_id) or not bool(players[target_id].get("is_alive", false)):
		return
	if now_ms < int(_immune_until_ms.get(target_id, 0)):
		return
	_last_taunt_ms[sender_id] = now_ms
	_taunts_sent[sender_id] = int(_taunts_sent.get(sender_id, 0)) + 1
	var actual_target: int = target_id
	if bool(_mirror_active.get(target_id, false)):
		_mirror_active[target_id] = false
		actual_target = sender_id
	_immune_until_ms[actual_target] = now_ms + int((GameConfig.TAUNT_IMMUNITY_SEC + GameConfig.TAUNT_WARN_DELAY) * 1000.0)
	apply_taunt.rpc(sender_id, actual_target, item_id)


@rpc("authority", "call_local", "reliable")
func apply_taunt(sender_id: int, target_id: int, item_id: String) -> void:
	_immune_until_ms[target_id] = Time.get_ticks_msec() + int((GameConfig.TAUNT_IMMUNITY_SEC + GameConfig.TAUNT_WARN_DELAY) * 1000.0)
	taunt_applied.emit(sender_id, target_id, item_id)


## Eski istemci yolu: metin yalnızca beyaz listedeki satırlardan biriyse indekse çevrilir.
@rpc("any_peer", "call_local", "reliable")
func send_quick_chat(text: String) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true):
		return
	var idx: int = _quick_chat_index_for(text.substr(0, 96), str(players[sender_id].get("char_id", "")))
	if idx >= 0:
		_handle_quick_chat(sender_id, idx)


@rpc("any_peer", "call_local", "reliable")
func request_quick_chat(line_idx: int) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true):
		return
	_handle_quick_chat(sender_id, line_idx)


func _handle_quick_chat(sender_id: int, line_idx: int) -> void:
	if _quick_chat_text(sender_id, line_idx).is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - int(_last_chat_ms.get(sender_id, -100000)) < int(GameConfig.NET_QUICK_CHAT_MIN_INTERVAL_SEC * 1000.0):
		return
	_last_chat_ms[sender_id] = now_ms
	broadcast_quick_chat.rpc(sender_id, line_idx)


@rpc("authority", "call_local", "reliable")
func broadcast_quick_chat(sender_id: int, line_idx: int) -> void:
	var text: String = _quick_chat_text(sender_id, line_idx)
	if not text.is_empty():
		quick_chat_received.emit(sender_id, text)


## Sohbet metnini indekse çevirir: sabit satırlar 0..N-1, karakter repliği özel indeks; yoksa -1.
func _quick_chat_index_for(text: String, char_id: String) -> int:
	var idx: int = GameConfig.QUICK_CHAT_LINES.find(text)
	if idx >= 0:
		return idx
	var c_line: String = str(CharacterData.get_character(char_id).get("taunt_line", ""))
	if not c_line.is_empty() and text == c_line:
		return GameConfig.NET_QUICK_CHAT_CHAR_INDEX
	return -1


## İndeksi gönderenin karakterine göre metne çevirir; geçersizse boş döner.
func _quick_chat_text(sender_id: int, line_idx: int) -> String:
	if line_idx >= 0 and line_idx < GameConfig.QUICK_CHAT_LINES.size():
		return GameConfig.QUICK_CHAT_LINES[line_idx]
	if line_idx == GameConfig.NET_QUICK_CHAT_CHAR_INDEX and players.has(sender_id):
		var c_id: String = str(players[sender_id].get("char_id", ""))
		return str(CharacterData.get_character(c_id).get("taunt_line", ""))
	return ""


@rpc("any_peer", "call_local", "reliable")
func throw_ghost_slipper(y: float, _client_time: float) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not _match_running():
		return
	if bool(players[sender_id].get("is_alive", true)) or is_nan(y) or is_inf(y):
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_last_ghost_throw_ms.get(sender_id, -100000))
	if now_ms - last_ms < int(GameConfig.GHOST_SLIPPER_COOLDOWN * 1000.0):
		return
	_last_ghost_throw_ms[sender_id] = now_ms
	var clamped_y: float = clampf(y, 120.0, GameConfig.FLOOR_Y - 60.0)
	# Yalnızca öncü süre gönderilir; her alıcı kendi maç saatine göre zamanlar
	spawn_ghost_slipper.rpc(sender_id, clamped_y, GameConfig.GHOST_SLIPPER_LEAD_SEC)


@rpc("authority", "call_local", "reliable")
func spawn_ghost_slipper(thrower_id: int, y: float, lead_sec: float) -> void:
	ghost_slipper_spawned.emit(thrower_id, y, current_match_time + lead_sec)


@rpc("any_peer", "call_local", "unreliable_ordered")
func report_score_update(new_score: int) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not in_match:
		return
	if not bool(players[sender_id].get("is_alive", false)):
		return
	var cap: int = _max_score_at(_server_match_time() + GameConfig.NET_SCORE_TIME_TOLERANCE_SEC)
	players[sender_id]["score"] = clampi(new_score, 0, cap)


@rpc("any_peer", "call_local", "reliable")
func report_ghost_kill(thrower_id: int) -> void:
	var sender_id: int = _sender_id()
	if not _rpc_guard(sender_id, true) or not in_match:
		return
	if thrower_id == sender_id or not _match_roster.has(thrower_id):
		return
	if players.has(thrower_id) and bool(players[thrower_id].get("is_alive", true)):
		return
	var since_throw_ms: int = Time.get_ticks_msec() - int(_last_ghost_throw_ms.get(thrower_id, -1000000))
	if since_throw_ms > int(GameConfig.NET_GHOST_KILL_WINDOW_SEC * 1000.0):
		return
	# Kurbanın ölüm bildirimiyle birlikte (bir kez) sayılır
	_pending_ghost_kill[sender_id] = thrower_id
	if not bool(players[sender_id].get("is_alive", true)):
		_count_ghost_kill(sender_id)


func _count_ghost_kill(victim_id: int) -> void:
	if bool(_ghost_kill_counted.get(victim_id, false)) or not _pending_ghost_kill.has(victim_id):
		return
	if str(_death_causes.get(victim_id, "")) != "hayalet_terlik":
		return
	var thrower_id: int = int(_pending_ghost_kill[victim_id])
	_ghost_kill_counted[victim_id] = true
	_ghost_kills[thrower_id] = int(_ghost_kills.get(thrower_id, 0)) + 1


@rpc("authority", "call_local", "reliable")
func announce_winner(winner_id: int, is_draw: bool) -> void:
	in_match = false
	winner_announced.emit(winner_id, is_draw)


@rpc("authority", "call_local", "reliable")
func return_to_lobby() -> void:
	in_match = false
	countdown_started = false
	# Ayrılmış sunucu sahne değiştirmez
	if is_dedicated_server():
		_free_server_mirror()
		return
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")


# ---------------------------------------------------------------------------
# Sunucu yardımcıları
# ---------------------------------------------------------------------------

## Uzak çağrıda göndereni, yerel çağrıda kendi kimliğini döner.
func _sender_id() -> int:
	var sid: int = multiplayer.get_remote_sender_id()
	return sid if sid != 0 else multiplayer.get_unique_id()


## Lobi/maç yönetimi yetkisi olan eş: ayrılmış sunucuda oda sahibi, LAN'da host.
func _owner_peer_id() -> int:
	return room_owner_id if is_dedicated_mode else 1


## Sunucuda any_peer RPC kapısı: üyelik ve eş başına saniyelik mesaj sınırı.
func _rpc_guard(sender_id: int, require_member: bool) -> bool:
	if multiplayer.multiplayer_peer == null or not multiplayer.is_server():
		return false
	if sender_id == multiplayer.get_unique_id():
		return not require_member or players.has(sender_id)
	if _kick_at_ms.has(sender_id):
		return false
	var sec: int = floori(float(Time.get_ticks_msec()) * 0.001)
	var entry: Dictionary = _rpc_counts.get(sender_id, {}) as Dictionary
	if int(entry.get("sec", -1)) != sec:
		entry = {"sec": sec, "n": 0}
	var count: int = int(entry["n"]) + 1
	entry["n"] = count
	_rpc_counts[sender_id] = entry
	if count > GameConfig.NET_RPC_KICK_PER_SEC:
		_schedule_kick(sender_id)
		return false
	if count > GameConfig.NET_RPC_RATE_PER_SEC:
		return false
	return not require_member or players.has(sender_id)


## Ret mesajını gönderir ve kısa süre sonra bağlantıyı keser.
func _reject_peer(peer_id: int, reason: String) -> void:
	reject_client.rpc_id(peer_id, reason)
	_schedule_kick(peer_id)


func _schedule_kick(peer_id: int) -> void:
	if peer_id == multiplayer.get_unique_id() or _kick_at_ms.has(peer_id):
		return
	_kick_at_ms[peer_id] = Time.get_ticks_msec() + int(GameConfig.NET_KICK_DELAY_SEC * 1000.0)


## ENet eşinin zaman aşımını kısaltır (varsayılan ~30 sn).
func _apply_peer_timeout(peer_id: int) -> void:
	var enet: ENetMultiplayerPeer = multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if enet == null:
		return
	var pkt_peer: ENetPacketPeer = enet.get_peer(peer_id)
	if pkt_peer != null:
		pkt_peer.set_timeout(GameConfig.NET_PEER_TIMEOUT_LIMIT, GameConfig.NET_PEER_TIMEOUT_MIN_MS, GameConfig.NET_PEER_TIMEOUT_MAX_MS)


## Sunucunun kendi maç saati (geri sayım bitişinden itibaren, sn).
func _server_match_time() -> float:
	if _server_countdown_ms == 0:
		return 0.0
	var countdown_total: float = GameConfig.COUNTDOWN_STEP_SEC * float(GameConfig.NET_COUNTDOWN_STEP_COUNT)
	return maxf(float(Time.get_ticks_msec() - _server_countdown_ms) * 0.001 - countdown_total, 0.0)


## Maç sürüyor ve geri sayım başlamış mı (sunucu tarafı).
func _match_running() -> bool:
	return in_match and _server_countdown_ms != 0 and not _results_sent


## Verilen maç zamanına kadar geçilebilecek azami skor (her çift en fazla 2 puan).
func _max_score_at(t: float) -> int:
	if _server_timeline == null:
		return 0
	var dist: float = _server_timeline.distance_at(t)
	var pairs: int = 0
	for s: Dictionary in _server_timeline.slippers:
		if float(s["distance"]) >= dist:
			break
		pairs += 1
	return pairs * 2


## Ölüm sebebini kısa ve yalnızca [a-z0-9_] olacak şekilde temizler.
func _clean_cause(cause: String) -> String:
	var out: String = ""
	for i: int in range(mini(cause.length(), GameConfig.NET_CAUSE_MAX_LENGTH)):
		var code: int = cause.unicode_at(i)
		if (code >= 97 and code <= 122) or (code >= 48 and code <= 57) or code == 95:
			out += cause[i]
	return out if not out.is_empty() else "bilinmiyor"


## Maça özel tüm sunucu/istemci durumunu sıfırlar.
func _reset_match_state() -> void:
	_loaded_peers.clear()
	_death_order.clear()
	_death_causes.clear()
	_taunts_sent.clear()
	_last_taunt_ms.clear()
	_last_chat_ms.clear()
	_ghost_kills.clear()
	_pending_ghost_kill.clear()
	_ghost_kill_counted.clear()
	_survival_times.clear()
	_match_roster.clear()
	_disconnected_in_match.clear()
	_victory_lap_active = false
	_victory_winner_id = 0
	_victory_lap_deadline_ms = 0
	_results_sent = false
	_match_start_ms = 0
	_server_countdown_ms = 0
	_server_timeline = null
	_immune_until_ms.clear()
	_last_ghost_throw_ms.clear()
	_mirror_active.clear()
	_free_server_mirror()
	countdown_started = false
	countdown_start_ms = 0
	current_match_time = 0.0
	_local_death_reported = false


## Ayrılmış sunucu: istemcilerin "GameWorld/PlayersLayer/<pid>" yolunu taklit eden pasif Player düğümleri kurar.
## Böylece aktarılan Player RPC'leri (sync_state, use_ability) sunucuda "düğüm bulunamadı" hatası vermez.
func _build_server_mirror() -> void:
	_free_server_mirror()
	var scene: PackedScene = load(PLAYER_SCENE_PATH) as PackedScene
	if scene == null:
		return
	var mirror_root: Node2D = Node2D.new()
	mirror_root.name = MIRROR_ROOT_NAME
	mirror_root.process_mode = Node.PROCESS_MODE_DISABLED
	var layer: Node2D = Node2D.new()
	layer.name = MIRROR_LAYER_NAME
	mirror_root.add_child(layer)
	get_tree().root.add_child(mirror_root)
	_server_mirror = mirror_root
	for pid: int in players.keys():
		var p: Node = scene.instantiate()
		p.name = str(pid)
		layer.add_child(p)
		if p.has_method("configure_network"):
			p.call("configure_network", pid, str(players[pid].get("name", "Böcek")), str(players[pid].get("char_id", "klasik")))


func _free_server_mirror() -> void:
	if _server_mirror == null or not is_instance_valid(_server_mirror):
		_server_mirror = null
		return
	# Hemen ağaçtan çıkar ki aynı isimle yenisi kurulabilsin
	if _server_mirror.get_parent() != null:
		_server_mirror.get_parent().remove_child(_server_mirror)
	_server_mirror.queue_free()
	_server_mirror = null

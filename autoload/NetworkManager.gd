extends Node

## Çok oyunculu ağ yöneticisi: lobi durumu, senkronizasyon ve maç akışı.

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
var _rpc_counts: Dictionary = {}
var _paused_since_ms: int = 0

var _transport: NetTransport = ENetTransport.new()
var _discovery: LanDiscovery = null
var _loaded_peers: Dictionary = {}
var _death_order: Array[int] = []
var _last_death_frame: int = -1
var _same_frame_deaths: int = 0
var _connect_timer: SceneTreeTimer = null
var _taunts_sent: Dictionary = {} # peer_id -> int
var _ghost_kills: Dictionary = {} # peer_id -> int
var _survival_times: Dictionary = {} # peer_id -> float
var _match_roster: Dictionary = {} # peer_id -> {name, char_id}
var _disconnected_in_match: Dictionary = {} # peer_id -> bool
var _victory_lap_active: bool = false
var _victory_winner_id: int = 0
var _results_sent: bool = false
var current_match_time: float = 0.0
var _immune_until_ms: Dictionary = {} # peer_id -> int
var _last_ghost_throw_ms: Dictionary = {} # peer_id -> int
var _mirror_active: Dictionary = {} # peer_id -> bool


func _ready() -> void:
	load_local_settings()
	_discovery = LanDiscovery.new()
	add_child(_discovery)

	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


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
	return is_dedicated_mode and multiplayer.is_server()


func is_room_owner() -> bool:
	if not is_dedicated_mode:
		return multiplayer.is_server()
	return multiplayer.multiplayer_peer != null and multiplayer.get_unique_id() == room_owner_id


func _notification(what: int) -> void:
	if not is_dedicated_mode or not in_match or multiplayer.is_server():
		return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		_paused_since_ms = Time.get_ticks_msec()
	elif what == NOTIFICATION_APPLICATION_RESUMED and _paused_since_ms > 0:
		var elapsed: float = float(Time.get_ticks_msec() - _paused_since_ms) * 0.001
		_paused_since_ms = 0
		if elapsed >= 10.0:
			notify_local_death("arka_plan")


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
	players[1] = {
		"name": local_player_name,
		"char_id": selected_char_id,
		"is_alive": true,
		"score": 0,
		"wins": 0,
		"awards": 0,
	}
	_discovery.start_broadcast(local_player_name, players.size(), false)
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
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if is_dedicated_mode and sender_id != room_owner_id:
		return
	host_start_match()


@rpc("any_peer", "call_local", "reliable")
func request_return_lobby() -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if is_dedicated_mode and sender_id != room_owner_id:
		return
	host_return_to_lobby()


func sanitize_player_name(raw_name: String) -> String:
	var clean: String = raw_name.strip_edges().substr(0, GameConfig.MAX_NAME_LENGTH)
	if clean.is_empty():
		return "Böcek"
	var lower: String = clean.to_lower()
	for bad: String in GameConfig.BANNED_NAME_WORDS:
		if lower.find(bad) != -1:
			return "Böcek"
	return clean


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
	_loaded_peers.clear()
	_death_order.clear()
	is_multiplayer_match = false
	is_dedicated_mode = false
	room_code = ""
	room_owner_id = 1
	is_public_room = false
	in_match = false


## İstemci karakter değiştirmek istediğinde çağrılır.
func request_char_change(char_id: String) -> void:
	save_selected_char(char_id)
	if multiplayer.multiplayer_peer != null and is_multiplayer_match:
		request_char.rpc_id(1, char_id)


## Host maçı başlatır ve tüm eşlere seed gönderir.
func host_start_match() -> void:
	if not multiplayer.is_server():
		return
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var new_seed: int = int(rng.randi())
	if new_seed == 0:
		new_seed = 1
	in_match = true
	_loaded_peers.clear()
	_death_order.clear()
	_last_death_frame = -1
	_same_frame_deaths = 0
	_taunts_sent.clear()
	_ghost_kills.clear()
	_survival_times.clear()
	_match_roster.clear()
	_disconnected_in_match.clear()
	_victory_lap_active = false
	_victory_winner_id = 0
	_results_sent = false
	current_match_time = 0.0
	_immune_until_ms.clear()
	_last_ghost_throw_ms.clear()
	_mirror_active.clear()
	for pid: int in players.keys():
		_match_roster[pid] = {
			"name": str(players[pid].get("name", "Böcek")),
			"char_id": str(players[pid].get("char_id", "klasik")),
			"score": 0,
		}
	for pid: int in players.keys():
		players[pid]["is_alive"] = true
		players[pid]["score"] = 0
	_discovery.update_broadcast_info(players.size(), true)
	sync_players.rpc(players)
	start_match.rpc(new_seed)


## Maç bittiğinde Host herkesi lobiye döndürür.
func host_return_to_lobby() -> void:
	if not multiplayer.is_server():
		return
	in_match = false
	_discovery.update_broadcast_info(players.size(), false)
	return_to_lobby.rpc()


## Yerel oyuncu öldüğünde Host'a bildirir.
func notify_local_death(cause: String, m_time: float = -1.0) -> void:
	if not is_multiplayer_match or multiplayer.multiplayer_peer == null:
		return
	var t_val: float = m_time if m_time >= 0.0 else current_match_time
	report_death.rpc(cause, t_val)


## Hayatta kalan ve toplam oyuncu sayılarını döner.
func get_alive_counts() -> Vector2i:
	var alive: int = 0
	var total: int = players.size()
	for pid: int in players.keys():
		if bool(players[pid].get("is_alive", false)):
			alive += 1
	return Vector2i(alive, total)


func _on_connect_timeout() -> void:
	if multiplayer.multiplayer_peer == null:
		return
	if multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		leave_game()
		connection_failed.emit("Bağlantı zaman aşımına uğradı (6 sn).")


func _on_connected_to_server() -> void:
	_connect_timer = null
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


func _on_peer_disconnected(peer_id: int) -> void:
	if not players.has(peer_id):
		return
	if in_match and multiplayer.is_server():
		_disconnected_in_match[peer_id] = true
		if not _survival_times.has(peer_id):
			_survival_times[peer_id] = current_match_time
		if _match_roster.has(peer_id):
			_match_roster[peer_id]["score"] = int(players[peer_id].get("score", 0))
	players.erase(peer_id)
	if multiplayer.is_server():
		if is_dedicated_mode and room_owner_id == peer_id:
			var rem: Array = players.keys()
			rem.sort()
			room_owner_id = int(rem[0]) if not rem.is_empty() else 0
			sync_room_meta.rpc(room_owner_id, room_code, is_public_room)
		if not is_dedicated_mode:
			_discovery.update_broadcast_info(players.size(), in_match)
		sync_players.rpc(players)
		if in_match:
			if _victory_lap_active and peer_id == _victory_winner_id:
				_finalize_match_results()
			elif not _victory_lap_active:
				_check_match_end_after_elimination()
	player_left_match.emit(peer_id)
	players_updated.emit()


@rpc("any_peer", "call_remote", "reliable")
func register_player(p_name: String, p_char_id: String, p_version: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if p_version != GameConfig.NET_VERSION:
		reject_client.rpc_id(sender_id, "Sürüm uyuşmazlığı! Oyunu güncelleyin.")
		return
	if in_match:
		reject_client.rpc_id(sender_id, "Maç devam ediyor, daha sonra katılın.")
		return
	if players.size() >= GameConfig.NET_MAX_CLIENTS + 1:
		reject_client.rpc_id(sender_id, "Oda dolu (en fazla 5 oyuncu).")
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
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if not players.has(sender_id) or in_match:
		return
	if not CharacterData.CHARACTERS.has(char_id):
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
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


@rpc("any_peer", "call_local", "reliable")
func client_loaded() -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	_loaded_peers[sender_id] = true
	if _loaded_peers.size() >= players.size():
		begin_countdown.rpc()


@rpc("authority", "call_local", "reliable")
func begin_countdown() -> void:
	match_countdown_started.emit()


@rpc("any_peer", "call_local", "reliable")
func report_death(cause: String, m_time: float = -1.0) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()

	# Zafer turunda kazanan ölürse sıralama değişmez, sadece zafer turu biter
	if multiplayer.is_server() and _victory_lap_active:
		if sender_id == _victory_winner_id:
			_finalize_match_results()
		return

	if players.has(sender_id):
		players[sender_id]["is_alive"] = false
	player_eliminated.emit(sender_id, cause)
	players_updated.emit()

	if multiplayer.is_server():
		if not _survival_times.has(sender_id):
			_survival_times[sender_id] = m_time if m_time >= 0.0 else current_match_time
		if _match_roster.has(sender_id) and players.has(sender_id):
			_match_roster[sender_id]["score"] = int(players[sender_id].get("score", 0))
		var frame_now: int = Engine.get_process_frames()
		if frame_now == _last_death_frame:
			_same_frame_deaths += 1
		else:
			_last_death_frame = frame_now
			_same_frame_deaths = 1
		if not _death_order.has(sender_id):
			_death_order.append(sender_id)
		_check_match_end_after_elimination()


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
		_survival_times[winner_id] = current_match_time + 999.0
		if players.has(winner_id):
			players[winner_id]["wins"] = int(players[winner_id].get("wins", 0)) + 1
		sync_players.rpc(players)
		start_victory_lap.rpc(winner_id)
	elif alive_ids.is_empty():
		if _same_frame_deaths >= 2:
			_victory_winner_id = 0
			_finalize_match_results()
		elif not _death_order.is_empty():
			var last_id: int = _death_order[_death_order.size() - 1]
			_victory_winner_id = last_id
			if players.has(last_id):
				players[last_id]["wins"] = int(players[last_id].get("wins", 0)) + 1
			_finalize_match_results()


@rpc("authority", "call_local", "reliable")
func start_victory_lap(winner_id: int) -> void:
	_victory_lap_active = true
	_victory_winner_id = winner_id
	victory_lap_started.emit(winner_id)


@rpc("any_peer", "call_local", "reliable")
func request_finish_victory_lap() -> void:
	if not multiplayer.is_server() or not _victory_lap_active:
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
	if sender_id == _victory_winner_id or sender_id == 1:
		_finalize_match_results()


func _finalize_match_results() -> void:
	if not multiplayer.is_server() or _results_sent:
		return
	_results_sent = true
	_victory_lap_active = false

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

	var top_taunt_id: int = 0
	var top_taunts: int = 0
	for pid_v: Variant in _taunts_sent.keys():
		var pid: int = int(pid_v)
		var cnt: int = int(_taunts_sent[pid])
		if cnt > top_taunts:
			top_taunts = cnt
			top_taunt_id = pid
	if top_taunt_id > 0:
		_add_badge(badge_map, top_taunt_id, "Baş Belası")

	if not _death_order.is_empty():
		_add_badge(badge_map, _death_order[0], "Terlik Mıknatısı")

	var top_ghost_id: int = 0
	var top_ghost: int = 0
	for pid_v: Variant in _ghost_kills.keys():
		var pid: int = int(pid_v)
		var cnt: int = int(_ghost_kills[pid])
		if cnt > top_ghost:
			top_ghost = cnt
			top_ghost_id = pid
	if top_ghost_id > 0:
		_add_badge(badge_map, top_ghost_id, "İntikam Meleği")

	# Sıralama: hayatta kalma süresine göre azalan (kazanan en yüksek)
	var entries: Array[Dictionary] = []
	for pid: int in _match_roster.keys():
		var info: Dictionary = _match_roster[pid] as Dictionary
		var t_surv: float = float(_survival_times.get(pid, current_match_time))
		if pid == _victory_winner_id and _victory_winner_id > 0:
			t_surv = maxf(t_surv, current_match_time + 999.0)
		entries.append({
			"peer_id": pid,
			"name": str(info.get("name", "Böcek")),
			"char_id": str(info.get("char_id", "klasik")),
			"score": int(info.get("score", 0)),
			"survival_time": t_surv,
			"display_time": current_match_time if pid == _victory_winner_id else t_surv,
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
			if absf(prev_t - cur_t) > 0.05:
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


@rpc("authority", "call_local", "reliable")
func show_results(results: Array) -> void:
	in_match = false
	_victory_lap_active = false
	results_ready.emit(results)


@rpc("any_peer", "call_local", "reliable")
func show_item_fx(item_id: String) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = multiplayer.get_unique_id()
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

	var top_taunt_id: int = 0
	var top_taunts: int = 0
	for pid_v: Variant in _taunts_sent.keys():
		var pid: int = int(pid_v)
		var cnt: int = int(_taunts_sent[pid])
		if cnt > top_taunts:
			top_taunts = cnt
			top_taunt_id = pid
	if top_taunt_id > 0 and players.has(top_taunt_id):
		players[top_taunt_id]["awards"] = int(players[top_taunt_id].get("awards", 0)) + 1
		awards.append({"title": "Baş Belası", "name": "%s (%d)" % [str(players[top_taunt_id]["name"]), top_taunts]})

	if not _death_order.is_empty():
		var first_dead: int = _death_order[0]
		if players.has(first_dead):
			players[first_dead]["awards"] = int(players[first_dead].get("awards", 0)) + 1
			awards.append({"title": "Terlik Mıknatısı", "name": str(players[first_dead]["name"])})

	var top_ghost_id: int = 0
	var top_ghost: int = 0
	for pid_v: Variant in _ghost_kills.keys():
		var pid: int = int(pid_v)
		var cnt: int = int(_ghost_kills[pid])
		if cnt > top_ghost:
			top_ghost = cnt
			top_ghost_id = pid
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
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if not players.has(sender_id) or not bool(players[sender_id].get("is_alive", false)):
		return
	if not GameConfig.TAUNT_DEFS.has(item_id):
		return
	if item_id == "ayna":
		_mirror_active[sender_id] = true
		_taunts_sent[sender_id] = int(_taunts_sent.get(sender_id, 0)) + 1
		apply_taunt.rpc(sender_id, sender_id, item_id)
		return
	if not players.has(target_id) or not bool(players[target_id].get("is_alive", false)):
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms < int(_immune_until_ms.get(target_id, 0)):
		return
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


@rpc("any_peer", "call_local", "reliable")
func send_quick_chat(text: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if not players.has(sender_id):
		return
	var clean_text: String = text.strip_edges().substr(0, 48)
	if clean_text.is_empty():
		return
	broadcast_quick_chat.rpc(sender_id, clean_text)


@rpc("authority", "call_local", "reliable")
func broadcast_quick_chat(sender_id: int, text: String) -> void:
	quick_chat_received.emit(sender_id, text)


@rpc("any_peer", "call_local", "reliable")
func throw_ghost_slipper(y: float, current_match_time: float) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if not players.has(sender_id) or bool(players[sender_id].get("is_alive", true)):
		return
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_last_ghost_throw_ms.get(sender_id, 0))
	if now_ms - last_ms < int(GameConfig.GHOST_SLIPPER_COOLDOWN * 1000.0):
		return
	_last_ghost_throw_ms[sender_id] = now_ms
	var clamped_y: float = clampf(y, 120.0, GameConfig.FLOOR_Y - 60.0)
	spawn_ghost_slipper.rpc(sender_id, clamped_y, current_match_time + GameConfig.GHOST_SLIPPER_LEAD_SEC)


@rpc("authority", "call_local", "reliable")
func spawn_ghost_slipper(thrower_id: int, y: float, launch_match_time: float) -> void:
	ghost_slipper_spawned.emit(thrower_id, y, launch_match_time)


@rpc("any_peer", "call_local", "unreliable_ordered")
func report_score_update(new_score: int) -> void:
	if not multiplayer.is_server():
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = 1
	if players.has(sender_id):
		players[sender_id]["score"] = new_score


@rpc("any_peer", "call_local", "reliable")
func report_ghost_kill(thrower_id: int) -> void:
	if not multiplayer.is_server():
		return
	if players.has(thrower_id):
		_ghost_kills[thrower_id] = int(_ghost_kills.get(thrower_id, 0)) + 1


@rpc("authority", "call_local", "reliable")
func announce_winner(winner_id: int, is_draw: bool) -> void:
	in_match = false
	winner_announced.emit(winner_id, is_draw)


@rpc("authority", "call_local", "reliable")
func return_to_lobby() -> void:
	in_match = false
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")

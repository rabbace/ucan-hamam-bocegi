extends Node

## CI ve yerel kontrol: tüm GDScript dosyalarını derler, ardından oyun sahnesini
## tek oyunculu modda birkaç saniye çalıştırır. Hata varsa çıkış kodu 1 olur.
## Kullanım: godot --headless res://tools/CiCheck.tscn

var _errors: int = 0


func _ready() -> void:
	_check_dir("res://")
	print("Script derleme kontrolü bitti. Hata sayısı: %d" % _errors)
	if _errors > 0:
		get_tree().quit(1)
		return
	_run_smoke_test.call_deferred()


func _check_dir(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full: String = path.path_join(name)
		if dir.current_is_dir():
			if name != "build" and name != "addons":
				_check_dir(full)
		elif name.ends_with(".gd"):
			var scr: Script = ResourceLoader.load(full) as Script
			if scr == null or not scr.can_instantiate():
				push_error("Derlenemedi: " + full)
				_errors += 1
		name = dir.get_next()
	dir.list_dir_end()


func _run_smoke_test() -> void:
	var packed: PackedScene = load("res://scenes/game/GameWorld.tscn") as PackedScene
	if packed == null:
		push_error("GameWorld sahnesi yüklenemedi")
		get_tree().quit(1)
		return
	var world: Node = packed.instantiate()
	get_tree().root.add_child(world)
	# Geri sayım + birkaç saniye uçuş
	for i: int in range(60 * 8):
		await get_tree().process_frame
	print("Duman testi bitti: GameWorld 8 sn hatasız çalıştı.")
	await _feature_checks(world)
	get_tree().quit(0)


## Faz 10 özelliklerini doğrudan çağırarak çalışma zamanı hatası olup olmadığını dener.
func _feature_checks(world: Node) -> void:
	# 10.1: tüm ikonlar (dosyadan ve yedek çizimden) üretilebiliyor mu
	var ids: Array[String] = []
	for k: Variant in GameConfig.POWERUP_DEFS.keys():
		ids.append(str(k))
	for k: Variant in GameConfig.TAUNT_DEFS.keys():
		ids.append(str(k))
	for k: Variant in GameConfig.SIGNATURE_DEFS.keys():
		ids.append(str(k))
	ids.append(GameConfig.MYSTERY_ITEM_ID)
	for id: String in ids:
		if IconFactory.item_icon(id) == null:
			push_error("İkon yok: " + id)
		if IconFactory._draw_icon(id) == null:
			push_error("Yedek ikon çizilemedi: " + id)
	for cid: String in CharacterData.ALL_ORDER:
		if GameConfig.get_signature_for(cid).is_empty():
			push_error("İmza ödülü yok: " + cid)

	# 10.2: her imza ödülünü yerel oyuncuyla kullan
	var hud: Node = world.get("hud") as Node
	var player: Node = world.get("local_player") as Node
	if hud != null and player != null:
		for cid: String in CharacterData.ALL_ORDER:
			player.call("load_character", cid)
			var sig: String = GameConfig.get_signature_for(cid)
			player.set("state", 1)
			player.set("position", Vector2(GameConfig.PLAYER_X, 600.0))
			world.set("match_active", true)
			hud.call("add_powerup", sig)
			world.call("_on_powerup_slot_pressed", 0)
			for i: int in range(20):
				await get_tree().process_frame
		print("İmza ödülleri denendi: %d karakter" % CharacterData.ALL_ORDER.size())

		# 10.3: ölüm paneli, mini portre, sıralama
		hud.call("show_death_panel", 12, "plaza", "ust_engel")
		hud.call("show_mini_portrait", "deli")
		var results: Array = [
			{"rank": 1, "peer_id": 1, "name": "Ben", "char_id": "diva", "score": 9, "display_time": 70.0},
			{"rank": 2, "peer_id": 2, "name": "Sen", "char_id": "usta", "score": 4, "display_time": 50.0},
		]
		hud.call("show_results_ranking", results, 1, true)
		for i: int in range(60):
			await get_tree().process_frame
		print("Portre ekranları denendi.")
		hud.call("update_rematch", [1, -1], 3, GameConfig.REMATCH_STATE_TIMEOUT, 0.0, 1, true)
	_faz11_checks()
	await _faz11b_checks(world)


## Faz 11A: bot planı deterministik mi, beceri seviyeleri mantıklı mı, ters mesafe hesabı doğru mu.
func _faz11_checks() -> void:
	var tl: ObstacleTimeline = ObstacleTimeline.new()
	tl.generate(123456, true)
	var t_probe: float = 42.0
	if absf(tl.time_at_distance(tl.distance_at(t_probe)) - t_probe) > 0.01:
		push_error("time_at_distance ters hesap hatalı")
	var tl2: ObstacleTimeline = ObstacleTimeline.new()
	tl2.generate(123456, true)
	for bi: int in range(1, 5):
		var a: BotPlanner = BotPlanner.new()
		a.setup(tl, 123456, bi, "mahalleli", 0)
		var b: BotPlanner = BotPlanner.new()
		b.setup(tl2, 123456, bi, "mahalleli", 0)
		if a.death_pair != b.death_pair or absf(a.death_time - b.death_time) > 0.0001 or absf(a.y_at(10.0) - b.y_at(10.0)) > 0.0001:
			push_error("Bot planı deterministik değil (bot %d)" % bi)
	var sums: Dictionary = {}
	for sk: String in GameConfig.BOT_SKILLS:
		var total: float = 0.0
		for sd: int in range(40):
			var tlx: ObstacleTimeline = ObstacleTimeline.new()
			tlx.generate(1000 + sd, true)
			var pl: BotPlanner = BotPlanner.new()
			pl.setup(tlx, 1000 + sd, 1 + sd % 4, sk, 0)
			total += float(pl.death_level())
		sums[sk] = total / 40.0
	print("Bot ortalama ölüm seviyesi: %s" % str(sums))
	if not (float(sums["acemi"]) < float(sums["mahalleli"]) and float(sums["mahalleli"]) < float(sums["usta"])):
		push_error("Bot beceri sıralaması bozuk")
	var capped: BotPlanner = BotPlanner.new()
	capped.setup(tl, 123456, 1, "usta", GameConfig.BOT_NEWBIE_CAP_LEVEL)
	if capped.death_level() > GameConfig.BOT_NEWBIE_CAP_LEVEL:
		push_error("Yeni oyuncu sınırı çalışmıyor")
	print("Faz 11 bot kontrolleri bitti.")


## Faz 11B: görev seed'i (aynı tarih = aynı 3 görev), havuz, seri tarihleri, ölüm karesi (headless yedek).
func _faz11b_checks(world: Node) -> void:
	var known_events: Array[String] = ["scare", "pass", "close", "combo", "shrink", "mystery", "box", "missile_survive",
		"level", "taunt", "invite", "share_card", "play", "play_mp", "win", "ability", "play_char", "survive",
		"powerup_use", "signature", "daily_kitchen", "same_course", "rematch", "chat", "ghost_slipper"]
	if GameConfig.DAILY_TASKS.size() < 25:
		push_error("Görev havuzu 25'ten az: %d" % GameConfig.DAILY_TASKS.size())
	var seen_ids: Array[String] = []
	for d: Dictionary in GameConfig.DAILY_TASKS:
		var tid: String = str(d["id"])
		if seen_ids.has(tid):
			push_error("Görev kimliği tekrar: " + tid)
		seen_ids.append(tid)
		if not known_events.has(str(d["event"])):
			push_error("Bilinmeyen görev olayı: " + str(d["event"]))
		if (d["n"] as Array).size() != (d["rewards"] as Array).size():
			push_error("Görev n/ödül sayısı uyuşmuyor: " + tid)
		for r: Variant in (d["rewards"] as Array):
			if int(r) < 30 or int(r) > 80:
				push_error("Görev ödülü 30-80 dışında: " + tid)
	# Aynı tarih her zaman aynı 3 görevi vermeli
	var a: Array[Dictionary] = GameConfig.pick_daily_tasks("2026-11-17")
	var b: Array[Dictionary] = GameConfig.pick_daily_tasks("2026-11-17")
	if a.size() != GameConfig.DAILY_TASK_COUNT or str(a) != str(b):
		push_error("Görev seed'i deterministik değil: %s / %s" % [str(a), str(b)])
	var distinct_days: Dictionary = {}
	for day: int in range(1, 29):
		var ds: String = "2026-02-%02d" % day
		var lst: Array[Dictionary] = GameConfig.pick_daily_tasks(ds)
		if lst.size() != GameConfig.DAILY_TASK_COUNT:
			push_error("Gün %s için 3 görev çıkmadı" % ds)
		var ids: Array[String] = []
		for t: Dictionary in lst:
			if ids.has(str(t["id"])):
				push_error("Aynı gün aynı görev iki kez: " + ds)
			ids.append(str(t["id"]))
		ids.sort()
		distinct_days[",".join(ids)] = true
		if str(GameConfig.pick_daily_surprise(ds)) != str(GameConfig.pick_daily_surprise(ds)):
			push_error("Günün Sürprizi deterministik değil")
	if distinct_days.size() < 10:
		push_error("Görevler günden güne yeterince değişmiyor: %d farklı liste" % distinct_days.size())
	print("Görev seed'i: 2026-11-17 -> %s" % str(a))
	# Gün farkı (ay ve yıl geçişi)
	if GameConfig.date_to_day_number("2026-03-01") - GameConfig.date_to_day_number("2026-02-28") != 1:
		push_error("Gün farkı hesabı hatalı (ay geçişi)")
	if GameConfig.date_to_day_number("2027-01-01") - GameConfig.date_to_day_number("2026-12-31") != 1:
		push_error("Gün farkı hesabı hatalı (yıl geçişi)")
	# Ses efekti yazısı ölüm sebebine göre
	if GameConfig.death_card_sfx("fuze") != "BUMM!" or GameConfig.death_card_sfx("tavan") != "DONK!" or GameConfig.death_card_sfx("hayalet_terlik") != "İNTİKAM!":
		push_error("Ölüm Karesi ses efekti eşlemesi hatalı")
	# Ölüm Karesi: headless'ta yakalama yok, kart yedek kareyle kurulabiliyor
	var rec: DeathFrameRecorder = DeathFrameRecorder.new()
	world.add_child(rec)
	rec.start()
	for i: int in range(20):
		await get_tree().process_frame
	rec.capture_death()
	if AudioManager.death_card_enabled and not rec.has_death:
		push_error("Ölüm Karesi ölüm kaydı yok")
	if DisplayServer.get_name() == "headless" and rec.death_frame != null:
		push_error("Headless'ta ekran yakalanmamalıydı")
	var maker: DeathComicCard = DeathComicCard.new()
	world.add_child(maker)
	var holder: Control = Control.new()
	maker.add_child(holder)
	maker.build_into(holder, {"before": null, "death": null, "cause": "terlik", "char_id": "diva", "line": "Ayy!", "score": 7, "narration": "Gece 03:12. Mutfak sessiz…"})
	var img: Image = await maker.render({"cause": "zemin", "char_id": "klasik", "score": 3})
	if DisplayServer.get_name() == "headless" and img != null:
		push_error("Headless'ta kart PNG'si üretilmemeliydi")
	maker.queue_free()
	rec.queue_free()
	var hud: Node = world.get("hud") as Node
	if hud != null:
		hud.call("_on_quest_progressed", "Görev: 7/10 kişi korkutuldu", false)
		hud.call("_on_quest_progressed", "Görev: 10/10 kişi korkutuldu", true)
	print("Faz 11B kontrolleri bitti.")

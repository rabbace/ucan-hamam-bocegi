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
	await _faz11c_checks(world)


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
		"powerup_use", "signature", "daily_kitchen", "same_course", "rematch", "chat", "ghost_slipper", "annem_escape"]
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


## Faz 11C: insan tipleri ve ani olaylar (aynı seed = aynı çıktı; 45 sn, füze çakışmaması, seviye kuralları),
## sis duvarlı bot planı determinizmi, albüm eşikleri ve olay oynatıcısının çalışma zamanı.
func _faz11c_checks(world: Node) -> void:
	var counts: Dictionary = {}
	var fog_deaths: int = 0
	var types_seen: Dictionary = {}
	for sd: int in range(1, 41):
		var a: ObstacleTimeline = ObstacleTimeline.new()
		a.generate(5000 + sd * 7, true)
		var b: ObstacleTimeline = ObstacleTimeline.new()
		b.generate(5000 + sd * 7, true)
		if _event_sig(a) != _event_sig(b):
			push_error("Olay zamanlaması deterministik değil (seed %d)" % (5000 + sd * 7))
		var prev_end: float = -1000.0
		var boss_levels: Array[int] = []
		for ev: Dictionary in a.events:
			var eid: String = str(ev["id"])
			var st: float = float(ev["start_time"])
			var en: float = float(ev["end_time"])
			counts[eid] = int(counts.get(eid, 0)) + 1
			if st - prev_end < GameConfig.EVENT_MIN_GAP_SEC - 0.001:
				push_error("İki olay arası 45 sn'den kısa: %.1f -> %.1f" % [prev_end, st])
			prev_end = en
			for ph: Dictionary in a.dark_phases:
				if st < float(ph["end_time"]) and en > float(ph["start_time"]):
					push_error("Olay füze evresiyle çakışıyor: %s %.1f" % [eid, st])
			var lv: int = a._level_at_time(st)
			if eid != "belediye" and lv < int(GameConfig.get_event_def(eid)["min_level"]):
				push_error("Olay seviyesi düşük: %s seviye %d" % [eid, lv])
			if eid == "belediye":
				boss_levels.append(int(ev["level"]))
				if not GameConfig.is_boss_level(int(ev["level"])):
					push_error("Belediye yanlış seviyede: %d" % int(ev["level"]))
		if not boss_levels.has(GameConfig.EVENT_BOSS_FIRST_LEVEL):
			push_error("Seviye 5'te Belediye İlaçlıyor yok (seed %d)" % (5000 + sd * 7))
		# Sis duvarları: delik sınırlar içinde, art arda erişilebilir, bölgede normal engel yok
		var prev_hole: float = -1.0
		var prev_start: float = -1.0
		for w: Dictionary in a.fog_walls:
			var hy: float = float(w["hole_y"])
			if hy < GameConfig.GAP_MIN_Y - 0.01 or hy > GameConfig.GAP_MAX_Y + 0.01:
				push_error("Sis deliği ekran dışında: %.1f" % hy)
			if float(w["event_start"]) == prev_start and absf(hy - prev_hole) > GameConfig.EVENT_FOG_MAX_DELTA_Y + 0.01:
				push_error("Sis delikleri arası fazla dik")
			prev_hole = hy
			prev_start = float(w["event_start"])
			for s: Dictionary in a.slippers:
				if absf(float(s["distance"]) - float(w["distance"])) < GameConfig.EVENT_FOG_CLEAR_BEFORE_PX - 1.0:
					push_error("Sis duvarının yanında normal engel var")
					break
		# Elektrik: o sırada gelen engellerin aralığı +40
		for ev: Dictionary in a.events:
			if str(ev["id"]) != "elektrik":
				continue
			for i: int in range(a.slippers.size()):
				var sl: Dictionary = a.slippers[i]
				var inside: bool = float(sl["distance"]) >= float(ev["start_dist"]) and float(sl["distance"]) <= float(ev["end_dist"])
				if inside != bool(sl.get("elec", false)) or (inside and absf(float(sl["gap_size"]) - float(b.slippers[i]["gap_size"])) > 0.001):
					push_error("Elektrik aralık bonusu tutarsız")
		# İnsan tipleri: seviyeye uygun ve herkeste aynı
		for i: int in range(a.slippers.size()):
			var sl: Dictionary = a.slippers[i]
			for k: String in ["top_type", "bottom_type"]:
				var tid: String = str(sl[k])
				types_seen[tid] = true
				if int(GameConfig.get_person(tid)["level"]) > int(sl["level"]):
					push_error("İnsan tipi seviyesinden önce çıktı: %s" % tid)
				if tid != str(b.slippers[i][k]):
					push_error("İnsan tipi deterministik değil")
		# Bot planı sis duvarlarıyla da aynı (sunucu ve istemci aynı listeyi kurar)
		for bi: int in range(1, 5):
			var pa: BotPlanner = BotPlanner.new()
			pa.setup(a, a.seed_value, bi, "usta", 0)
			var pb: BotPlanner = BotPlanner.new()
			pb.setup(b, b.seed_value, bi, "usta", 0)
			if pa.death_pair != pb.death_pair or absf(pa.death_time - pb.death_time) > 0.0001 or pa.death_cause != pb.death_cause:
				push_error("Sis duvarlı bot planı deterministik değil")
			if pa.death_cause == "belediye":
				fog_deaths += 1
	if types_seen.size() != GameConfig.PEOPLE.size():
		push_error("Tüm insan tipleri görülmedi: %d" % types_seen.size())
	for eid: String in GameConfig.EVENT_ORDER:
		if int(counts.get(eid, 0)) == 0:
			push_error("Olay hiç çıkmadı: " + eid)
	print("Ani olay sayıları (40 seed): %s · sis duvarında ölen usta bot: %d" % [str(counts), fog_deaths])

	# Zorla tetikleme (ekran görüntüsü aracı) ve zaman sorgusu
	for eid: String in GameConfig.EVENT_ORDER:
		ObstacleTimeline.debug_force_event = eid
		var f: ObstacleTimeline = ObstacleTimeline.new()
		f.generate(777, false)
		var ev0: Dictionary = f.event_at_time(GameConfig.EVENT_DEBUG_START_SEC + 0.5)
		if str(ev0.get("id", "")) != eid:
			push_error("Zorla tetiklenen olay yok: " + eid)
	ObstacleTimeline.debug_force_event = ""

	# Albüm eşikleri ve metinler
	if GameConfig.album_tier_for(0) != 0 or GameConfig.album_tier_for(1) != 1 or GameConfig.album_tier_for(9) != 1 \
			or GameConfig.album_tier_for(10) != 2 or GameConfig.album_tier_for(49) != 2 or GameConfig.album_tier_for(50) != 3:
		push_error("Albüm kart eşikleri hatalı")
	if GameConfig.level_hint_text(4) != "Seviye 4'te ortaya çıkar" or GameConfig.level_hint_text(6) != "Seviye 6'da ortaya çıkar":
		push_error("Seviye ipucu eki hatalı")
	if GameConfig.PEOPLE.size() != 12:
		push_error("Albüm 12 kart olmalı")
	for p: Dictionary in GameConfig.PEOPLE:
		if (p["scream_lines"] as Array).size() != 3:
			push_error("Çığlık lafı 3 olmalı: " + str(p["id"]))

	# Olay oynatıcısı: her olayı çalışan dünyada başlat / ilerlet / bitir (çalışma zamanı hatası olmasın)
	var gw: GameWorld = world as GameWorld
	if gw != null and gw.events_dir != null:
		var hud: Node = gw.hud
		# Tanıtım şeridi "görüldü" bayrakları test sonrası eski haline döner
		var seen_bak: Dictionary = (AudioManager.get("_seen_tips") as Dictionary).duplicate()
		for eid: String in GameConfig.EVENT_ORDER:
			var t0: float = gw.match_time
			var ev: Dictionary = {"index": 99, "id": eid, "start_time": t0, "end_time": t0 + 3.0, "level": 5, "start_dist": 0.0, "end_dist": 0.0}
			gw.events_dir._start_event(ev)
			for i: int in range(10):
				await get_tree().process_frame
			gw.events_dir._tick_active(t0 + GameConfig.EVENT_ANNEM_WARN_SEC + 0.05)
			gw.events_dir.queue_redraw()
			for i: int in range(5):
				await get_tree().process_frame
			gw.events_dir._end_active()
		AudioManager.set("_seen_tips", seen_bak)
		var scfg: ConfigFile = ConfigFile.new()
		scfg.load(GameConfig.SETTINGS_PATH)
		scfg.set_value("guide", "seen_tips", seen_bak)
		scfg.save(GameConfig.SETTINGS_PATH)
		if hud != null:
			hud.call("show_event_banner", "Yeni komşu: Çığlıkçı Teyze!", "Mahalle Albümü'ne eklendi")
			hud.call("flash_ability2")
		# Albüm penceresi ve büyük kart kurulabiliyor mu
		var holder: Control = Control.new()
		gw.add_child(holder)
		var album: Control = AlbumModal.open(holder)
		var detail: Control = AlbumModal.open_detail(holder, "teyze")
		for i: int in range(5):
			await get_tree().process_frame
		if album.get_node_or_null("Margin") == null and album.find_child("AlbumGrid", true, false) == null:
			push_error("Albüm ızgarası kurulmadı")
		elif (album.find_child("AlbumGrid", true, false) as GridContainer).get_child_count() != 12:
			push_error("Albüm ızgarasında 12 kart yok")
		detail.queue_free()
		holder.queue_free()
	print("Faz 11C kontrolleri bitti.")


func _event_sig(t: ObstacleTimeline) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for ev: Dictionary in t.events:
		parts.append("%s@%.4f-%.4f" % [str(ev["id"]), float(ev["start_time"]), float(ev["end_time"])])
	for w: Dictionary in t.fog_walls:
		parts.append("w%.3f/%.3f" % [float(w["distance"]), float(w["hole_y"])])
	return ",".join(parts)

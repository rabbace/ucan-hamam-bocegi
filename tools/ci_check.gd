extends Node

## CI ve yerel kontrol: tüm GDScript dosyalarını derler, ardından oyun sahnesini
## tek oyunculu modda birkaç saniye çalıştırır. Hata varsa çıkış kodu 1 olur.
## Kullanım: godot --headless res://tools/CiCheck.tscn

var _errors: int = 0


## Faz 12: gönderilen mesajları yakalayan Mahalle katmanı (ağsız birim testi)
class CiHub extends MahalleHub:
	var sent: Array = []

	func _send(_c: Dictionary, payload: Dictionary) -> void:
		sent.append(payload)

	## Son istek yanıtı (anlık bildirimler atlanır)
	func last() -> Dictionary:
		for i: int in range(sent.size() - 1, -1, -1):
			if str((sent[i] as Dictionary).get("op", "")) == "res":
				return sent[i] as Dictionary
		return {}


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
	await _faz11d_checks(world)
	await _faz12_checks()
	await _faz12cd_checks()
	await _faz13a_checks()
	await _faz13b_checks()
	_online_flag_checks()
	_difficulty_checks()


## Çevrimiçi kapalıyken: davet görevi hiç çıkmaz, Mahalle bağlantı açmaz.
func _online_flag_checks() -> void:
	if GameConfig.ONLINE_ENABLED:
		return
	for d_i: int in range(60):
		var day: String = "2026-%02d-%02d" % [1 + d_i / 28, 1 + d_i % 28]
		for t: Dictionary in GameConfig.pick_daily_tasks(day):
			if str(t["id"]) == "davet":
				push_error("Çevrimiçi kapalıyken davet görevi çıktı: " + day)
	var mh: Node = get_node_or_null("/root/Mahalle")
	if mh != null:
		mh.call("activate")
		if int(mh.get("link_state")) != 0:
			push_error("Çevrimiçi kapalıyken Mahalle bağlantı açmaya çalıştı")
	print("Çevrimiçi kapalı kontrolleri bitti.")


## Zorluk: Normal eski değerlerle aynı, Kolay/Zor beklenen yönde, aralık tabanın altına inmez.
func _difficulty_checks() -> void:
	for lv: int in [1, 3, 6, 9]:
		var base: Dictionary = GameConfig.get_level_config(lv)
		var n: Dictionary = GameConfig.get_level_config_for(lv, GameConfig.DIFFICULTY_NORMAL)
		var e: Dictionary = GameConfig.get_level_config_for(lv, GameConfig.DIFFICULTY_EASY)
		var h: Dictionary = GameConfig.get_level_config_for(lv, GameConfig.DIFFICULTY_HARD)
		if n != base:
			push_error("Zorluk: Normal seviye %d ayarı değişmiş" % lv)
		if not (float(e["speed"]) < float(n["speed"]) and float(h["speed"]) > float(n["speed"])):
			push_error("Zorluk: hız sırası yanlış (seviye %d)" % lv)
		if not (float(e["gap"]) > float(n["gap"]) and float(h["gap"]) <= float(n["gap"])):
			push_error("Zorluk: aralık sırası yanlış (seviye %d)" % lv)
		if float(h["gap"]) < minf(float(n["gap"]), GameConfig.DIFFICULTY_GAP_FLOOR) - 0.01:
			push_error("Zorluk: zor aralık tabanın altında (seviye %d)" % lv)
	var tn: ObstacleTimeline = ObstacleTimeline.new()
	tn.generate(424242, false)
	var th: ObstacleTimeline = ObstacleTimeline.new()
	th.difficulty = GameConfig.DIFFICULTY_HARD
	th.generate(424242, false)
	if th.distance_at(60.0) <= tn.distance_at(60.0):
		push_error("Zorluk: zor parkur daha hızlı akmıyor")
	print("Zorluk kontrolleri bitti.")


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
		var prev_ev_start: float = -1000.0
		var boss_levels: Array[int] = []
		for ev: Dictionary in a.events:
			var eid: String = str(ev["id"])
			var st: float = float(ev["start_time"])
			var en: float = float(ev["end_time"])
			counts[eid] = int(counts.get(eid, 0)) + 1
			if st - prev_ev_start < GameConfig.EVENT_MIN_GAP_SEC - 0.001:
				push_error("İki olayın başlangıçları arası 45 sn'den kısa: %.1f -> %.1f" % [prev_ev_start, st])
			if st - prev_end < GameConfig.EVENT_MIN_END_GAP_SEC - 0.001:
				push_error("Olay bitişinden sonra nefes payı kısa: %.1f -> %.1f" % [prev_end, st])
			prev_end = en
			prev_ev_start = st
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
		# Elektrik: o sırada gelen engellerin aralığı +40 (parkurda birden çok elektrik olayı olabilir)
		for i: int in range(a.slippers.size()):
			var sl: Dictionary = a.slippers[i]
			var inside: bool = false
			for ev: Dictionary in a.events:
				if str(ev["id"]) == "elektrik" and float(sl["distance"]) >= float(ev["start_dist"]) and float(sl["distance"]) <= float(ev["end_dist"]):
					inside = true
					break
			if inside != bool(sl.get("elec", false)) or (inside and absf(float(sl["gap_size"]) - float(b.slippers[i]["gap_size"])) > 0.001):
				push_error("Elektrik aralık bonusu tutarsız (seed %d, engel %d)" % [5000 + sd * 7, i])
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


## Faz 11D: "Benim Lafım" kayıt yolu sentetik PCM ile (mikrofon yok): kırpma, normalize, 16 kHz,
## WAV yaz/oku, ağ paketi ≤ 48 KB, sınır aşımı reddi, Hızlı Oyun kapısı, kayıt penceresi.
func _faz11d_checks(world: Node) -> void:
	# Mikrofon bus'ı oyun başlarken kurulmamalı (yalnızca kayıt ekranında, butona basınca)
	if AudioServer.get_bus_index(GameConfig.VOICE_MIC_BUS) >= 0:
		push_error("Mic bus'ı kayıt ekranı dışında kurulmuş")
	var rate: int = GameConfig.VOICE_STORE_RATE
	var wav: AudioStreamWAV = _ci_synth_wav(44100, 0.3, 1.0, 0.4, 0.2, true)
	var out: PackedFloat32Array = VoiceClip.process_recording(wav)
	var secs: float = float(out.size()) / float(rate)
	if secs < 0.98 or secs > 1.0 + GameConfig.VOICE_TRIM_PAD_SEC * 2.0 + 0.02:
		push_error("Sessizlik kırpma hatalı: %.3f sn" % secs)
	var peak: float = 0.0
	for v: float in out:
		peak = maxf(peak, absf(v))
	if absf(peak - GameConfig.VOICE_NORMALIZE_PEAK) > 0.02:
		push_error("Normalize hatalı: tepe %.3f" % peak)
	# 16 kHz'e indirmede frekans korunuyor mu (440 Hz → saniyede ~880 sıfır geçişi)
	var zc: int = 0
	for i: int in range(1, out.size()):
		if (out[i - 1] < 0.0) != (out[i] < 0.0):
			zc += 1
	# Kırpma payı (baş/son) sessiz; yalnızca ton süresine böl
	var zc_rate: float = float(zc) / maxf(0.1, secs - GameConfig.VOICE_TRIM_PAD_SEC * 2.0)
	if absf(zc_rate - 880.0) > 60.0:
		push_error("16 kHz'e indirme frekansı bozdu: %.0f geçiş/sn" % zc_rate)
	var long_out: PackedFloat32Array = VoiceClip.process_recording(_ci_synth_wav(48000, 0.0, 2.6, 0.0, 0.5, false))
	if long_out.size() > int(float(rate) * GameConfig.VOICE_MAX_SEC):
		push_error("2.0 sn sınırı aşıldı: %d örnek" % long_out.size())
	if not VoiceClip.process_recording(_ci_synth_wav(44100, 1.0, 0.0, 0.0, 0.0, true)).is_empty():
		push_error("Sessiz kayıt reddedilmedi")
	# WAV yaz / oku (gerçek yuvalara dokunmadan)
	var test_path: String = "user://ci_ses_testi.wav"
	if VoiceClip.make_stream(out, rate).save_to_wav(test_path) != OK:
		push_error("WAV kaydedilemedi")
	var back: AudioStreamWAV = VoiceClip.load_wav_file(test_path)
	if back == null or back.mix_rate != rate or back.stereo or back.data.size() != out.size() * 2:
		push_error("WAV geri okunamadı")
	DirAccess.remove_absolute(test_path)
	if VoiceClip.save_slot("bilinmeyen", out) == OK:
		push_error("Geçersiz yuva adı kabul edildi")
	# Ağ paketi: 11025 Hz 16 bit + ZSTD, ≤ 48 KB; en kötü durum (2 sn gürültü) de sığmalı
	var noise: PackedFloat32Array = PackedFloat32Array()
	var nrng: RandomNumberGenerator = RandomNumberGenerator.new()
	nrng.seed = 11
	noise.resize(int(float(rate) * GameConfig.VOICE_MAX_SEC))
	for i: int in range(noise.size()):
		noise[i] = nrng.randf_range(-0.9, 0.9)
	for src: PackedFloat32Array in [out, noise]:
		var pkt: Dictionary = VoiceClip.encode_for_net(VoiceClip.make_stream(src, rate))
		if pkt.is_empty():
			push_error("Ağ paketi üretilemedi")
			continue
		var data: PackedByteArray = pkt["data"] as PackedByteArray
		if data.size() > GameConfig.VOICE_NET_MAX_BYTES:
			push_error("Ağ paketi 48 KB'yi aştı: %d" % data.size())
		var dec: AudioStreamWAV = VoiceClip.decode_from_net(int(pkt["raw_size"]), data)
		if dec == null or dec.mix_rate != GameConfig.VOICE_NET_RATE or dec.data.size() != int(pkt["raw_size"]):
			push_error("Ağ paketi açılamadı")
		if VoiceClip.decode_from_net(int(pkt["raw_size"]) - 2, data) != null:
			push_error("Yanlış boyutlu paket kabul edildi")
		print("Ses paketi: %d bayt PCM -> %d bayt ZSTD" % [int(pkt["raw_size"]), data.size()])
	var big: PackedByteArray = PackedByteArray()
	big.resize(GameConfig.VOICE_NET_MAX_BYTES + 1)
	if VoiceClip.decode_from_net(40000, big) != null or VoiceClip.is_net_size_ok(GameConfig.VOICE_NET_MAX_RAW + 2, 1000):
		push_error("Sınırı aşan ses paketi reddedilmedi")
	var bomb: PackedByteArray = PackedByteArray()
	bomb.resize(400000)
	var bomb_z: PackedByteArray = bomb.compress(FileAccess.COMPRESSION_ZSTD)
	if VoiceClip.decode_from_net(GameConfig.VOICE_NET_MAX_RAW, bomb_z) != null:
		push_error("Açılınca büyüyen paket reddedilmedi")
	# Hızlı sohbet indeksi ve Hızlı Oyun kapısı
	if NetworkManager._quick_chat_index_for(GameConfig.VOICE_LAF_MENU_TEXT, "klasik") != GameConfig.NET_QUICK_CHAT_CUSTOM_INDEX:
		push_error("Benim Lafım hızlı sohbet indeksi yanlış")
	var bak_mp: bool = NetworkManager.is_multiplayer_match
	var bak_ded: bool = NetworkManager.is_dedicated_mode
	var bak_pub: bool = NetworkManager.is_public_room
	NetworkManager.is_multiplayer_match = true
	NetworkManager.is_dedicated_mode = true
	NetworkManager.is_public_room = true
	if NetworkManager.custom_voices_active() or NetworkManager.voice_sharing_allowed():
		push_error("Hızlı Oyun'da özel ses açık görünüyor")
	NetworkManager.is_public_room = false
	if not NetworkManager.custom_voices_active():
		push_error("Özel odada özel ses kapalı görünüyor")
	NetworkManager.is_multiplayer_match = bak_mp
	NetworkManager.is_dedicated_mode = bak_ded
	NetworkManager.is_public_room = bak_pub
	# Kayıt penceresi: sentetik kayıt taslak olur, mikrofon açılmaz
	var holder: Control = Control.new()
	world.add_child(holder)
	var modal: Control = VoiceRecorderModal.open(holder)
	await get_tree().process_frame
	var rec: VoiceRecorderModal = modal.get_node_or_null("Recorder") as VoiceRecorderModal
	if rec == null:
		push_error("Benim Lafım penceresi kurulmadı")
	else:
		if not rec.finish_recording_with(wav):
			push_error("Sentetik kayıt taslak olmadı")
		var st: Label = modal.find_child("Status", true, false) as Label
		if st == null or not st.text.begins_with("Yeni kayıt"):
			push_error("Taslak durumu görünmüyor")
		if modal.find_child("MicPlayer", true, false) != null:
			push_error("Mikrofon akışı butona basılmadan açıldı")
		rec._select_slot("zafer")
		rec._select_slot("laf")
	var players_modal: Control = PlayerSafetyUi.open_players_modal(holder)
	for i: int in range(3):
		await get_tree().process_frame
	if players_modal == null:
		push_error("Oyuncular penceresi kurulmadı")
	holder.queue_free()
	if AudioServer.get_bus_index(GameConfig.VOICE_MIC_BUS) >= 0:
		push_error("Mic bus'ı kayıt başlamadan kuruldu")
	print("Faz 11D kontrolleri bitti.")


## Sentetik kayıt: sessizlik + sinüs (440 Hz) + sessizlik, 16 bit.
func _ci_synth_wav(src_rate: int, pre_sec: float, tone_sec: float, post_sec: float, amp: float, stereo: bool) -> AudioStreamWAV:
	var n_pre: int = int(float(src_rate) * pre_sec)
	var n_tone: int = int(float(src_rate) * tone_sec)
	var n_post: int = int(float(src_rate) * post_sec)
	var total: int = n_pre + n_tone + n_post
	var ch: int = 2 if stereo else 1
	var data: PackedByteArray = PackedByteArray()
	data.resize(total * ch * 2)
	for i: int in range(total):
		var v: float = 0.0
		if i >= n_pre and i < n_pre + n_tone:
			v = sin(TAU * 440.0 * float(i - n_pre) / float(src_rate)) * amp
		for c: int in range(ch):
			data.encode_s16((i * ch + c) * 2, int(v * 32767.0))
	var w: AudioStreamWAV = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = src_rate
	w.stereo = stereo
	w.data = data
	return w


## Faz 12A-B: kimlik biçimi, güvenli saklama, yedek budama, arkadaşlık sınırları, hız sınırları, kurtarma.
func _faz12_checks() -> void:
	if GameConfig.normalize_account_id("#7k3m-qx9p") != "7K3MQX9P":
		push_error("Kimlik normalleştirme (küçük harf, #, tire) hatalı")
	if GameConfig.normalize_account_id("https://x.io/arkadas.html?k=7K3MQX9P&a=1") != "7K3MQX9P":
		push_error("Bağlantıdan kimlik çıkarılamadı")
	if GameConfig.normalize_account_id("ucanbocek://arkadas/7K3MQX9P") != "7K3MQX9P":
		push_error("Uygulama bağlantısından kimlik çıkarılamadı")
	if not GameConfig.normalize_account_id("7K3M-QX9").is_empty() or not GameConfig.normalize_account_id("OOOO0000").is_empty():
		push_error("Geçersiz kimlik kabul edildi")
	if GameConfig.format_account_id("7K3MQX9P") != "#7K3M-QX9P":
		push_error("Kimlik biçimi hatalı")
	if GameConfig.normalize_recovery_code("abcd-efgh-jkmn-pqrs") != "ABCDEFGHJKMNPQRS":
		push_error("Kurtarma kodu normalleştirme hatalı")
	if not UserStore.secure_equals("abc", "abc") or UserStore.secure_equals("abc", "abd") or UserStore.secure_equals("", ""):
		push_error("Sabit zamanlı karşılaştırma hatalı")

	# Güvenli yazım ve yedek budama (geçici klasör)
	var tmp_dir: String = ProjectSettings.globalize_path("user://ci_mahalle_tmp")
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	for i: int in range(9):
		var bf: FileAccess = FileAccess.open(tmp_dir.path_join("users_2020010%d.json" % (i + 1)), FileAccess.WRITE)
		bf.store_string("{}")
		bf.close()
	var store: UserStore = UserStore.new(tmp_dir)
	store.load_all()
	var made: Dictionary = store.create_user("Deneme", "klasik")
	var token: String = str(made.get("token", ""))
	if token.length() != GameConfig.ACCOUNT_TOKEN_BYTES * 2 or str(made.get("id", "")).length() != GameConfig.ACCOUNT_ID_LEN:
		push_error("Kimlik/anahtar üretimi hatalı")
	if not store.flush() or FileAccess.file_exists(store.users_path() + ".tmp"):
		push_error("users.json güvenli yazımı başarısız")
	if FileAccess.get_file_as_string(store.users_path()).contains(token):
		push_error("Gizli anahtar düz metin saklanmış")
	if not store.daily_backup() or store.list_backups().size() != GameConfig.MM_USERS_BACKUP_KEEP:
		push_error("Günlük yedek / son 7 budaması hatalı: %d" % store.list_backups().size())
	var reload: UserStore = UserStore.new(tmp_dir)
	reload.load_all()
	if not reload.check_token(str(made["id"]), token) or reload.check_token(str(made["id"]), token + "x"):
		push_error("Yeniden yüklenen kayıtta anahtar doğrulaması hatalı")
	var da: DirAccess = DirAccess.open(tmp_dir)
	for f: String in da.get_files():
		DirAccess.remove_absolute(tmp_dir.path_join(f))
	DirAccess.remove_absolute(tmp_dir)

	# Mahalle katmanı (bellekte, ağsız)
	var mem: UserStore = UserStore.new(tmp_dir)
	var hub: CiHub = CiHub.new(mem, {})
	var cl: Array[Dictionary] = []
	for i: int in range(3):
		var c: Dictionary = {"peer": StreamPeerTCP.new(), "ip": "10.0.0.%d" % i, "local": false, "session": false}
		hub.handle_hello(c, {"op": "hello", "version": GameConfig.NET_VERSION, "name": "Ci%d" % i})
		cl.append(c)
	var a_id: String = str(cl[0].get("uid", ""))
	var b_id: String = str(cl[1].get("uid", ""))
	var c_id: String = str(cl[2].get("uid", ""))
	if a_id.is_empty() or b_id.is_empty() or c_id.is_empty() or not bool(cl[0]["session"]):
		push_error("hello ile kimlik/oturum oluşmadı")
		return
	var a_token: String = str((hub.sent[0] as Dictionary).get("token", ""))
	# Ret sonrası 24 saat
	hub.handle_session_message(cl[1], {"op": "friend_request", "rid": 1, "id": c_id})
	hub.handle_session_message(cl[2], {"op": "friend_respond", "rid": 2, "id": b_id, "accept": false})
	hub.handle_session_message(cl[1], {"op": "friend_request", "rid": 3, "id": c_id})
	if bool(hub.last().get("ok", true)) or not str(hub.last().get("reason", "")).contains("24 saat"):
		push_error("Reddedilene 24 saat kuralı çalışmadı: %s" % str(hub.last()))
	(mem.get_user(b_id)["rejected_by"] as Dictionary)[c_id] = int(Time.get_unix_time_from_system()) - GameConfig.FRIEND_REJECT_COOLDOWN_SEC - 1
	hub.handle_session_message(cl[1], {"op": "friend_request", "rid": 4, "id": c_id})
	if not bool(hub.last().get("ok", false)):
		push_error("24 saat sonra istek gönderilemedi: %s" % str(hub.last()))
	hub.handle_session_message(cl[2], {"op": "friend_respond", "rid": 5, "id": b_id, "accept": true})
	if not (mem.get_user(b_id)["friends"] as Array).has(c_id) or not (mem.get_user(c_id)["friends"] as Array).has(b_id):
		push_error("Arkadaşlık karşılıklı değil")
	# Günde 30 istek
	var extra: Array[String] = []
	for i: int in range(GameConfig.FRIEND_REQUESTS_PER_DAY + 1):
		extra.append(str(mem.create_user("Ek%d" % i, "klasik")["id"]))
	var ok_n: int = 0
	for i: int in range(extra.size()):
		hub.handle_session_message(cl[0], {"op": "friend_request", "rid": 10 + i, "id": extra[i]})
		if bool(hub.last().get("ok", false)):
			ok_n += 1
	if ok_n != GameConfig.FRIEND_REQUESTS_PER_DAY or not str(hub.last().get("reason", "")).contains("Bugünlük"):
		push_error("Günlük istek sınırı hatalı: %d" % ok_n)
	# 100 arkadaş sınırı
	var full: Array = []
	for i: int in range(GameConfig.FRIENDS_MAX):
		full.append("X%07d" % i)
	mem.get_user(c_id)["friends"] = full
	mem.get_user(c_id)["req_count"] = 0
	hub.handle_session_message(cl[2], {"op": "friend_request", "rid": 60, "id": a_id})
	if bool(hub.last().get("ok", true)) or not str(hub.last().get("reason", "")).contains("dolu"):
		push_error("100 arkadaş sınırı çalışmadı: %s" % str(hub.last()))
	# Kimlik başına en fazla 2 bağlantı: üçüncüsü gelince en eskisi kapanır
	var extra_sessions: Array[Dictionary] = []
	for i: int in range(2):
		var c2: Dictionary = {"peer": StreamPeerTCP.new(), "ip": "10.0.1.%d" % i, "local": false, "session": false}
		hub.handle_hello(c2, {"op": "hello", "version": GameConfig.NET_VERSION, "id": a_id, "token": a_token})
		extra_sessions.append(c2)
	if not bool(cl[0].get("close", false)) or (hub.sessions.get(a_id, []) as Array).size() != GameConfig.MM_SESSIONS_PER_ID:
		push_error("Kimlik başına bağlantı sınırı çalışmadı")
	# Kurtarma: yanlış kodla kaba kuvvet kimlik başına sınırlı, doğru kod da sınırdan sonra reddedilir
	var a_live: Dictionary = extra_sessions[1]
	hub.handle_session_message(a_live, {"op": "recovery_new", "rid": 70})
	var code: String = str(hub.last().get("code", ""))
	if code.length() != GameConfig.RECOVERY_CODE_LEN:
		push_error("Kurtarma kodu üretilemedi")
	var restored_ok: bool = false
	for i: int in range(GameConfig.MM_RECOVER_PER_HOUR_PER_ID + 1):
		var rc: Dictionary = {"peer": StreamPeerTCP.new(), "ip": "10.0.2.%d" % i, "local": false, "session": false}
		var use_code: String = code if i == GameConfig.MM_RECOVER_PER_HOUR_PER_ID else "AAAAAAAAAAAAAAAA"
		if hub.handle_hello(rc, {"op": "hello", "version": GameConfig.NET_VERSION, "id": a_id, "recovery": use_code}):
			restored_ok = true
	if restored_ok:
		push_error("Kurtarma denemesi sınırı aşıldığı hâlde geri yükleme kabul edildi")
	hub._rate_log.erase(a_id + "|recover")
	var good: Dictionary = {"peer": StreamPeerTCP.new(), "ip": "10.0.3.1", "local": false, "session": false}
	if not hub.handle_hello(good, {"op": "hello", "version": GameConfig.NET_VERSION, "id": a_id, "recovery": code}):
		push_error("Doğru kurtarma koduyla geri yüklenemedi")
	if mem.check_token(a_id, a_token) or not bool(a_live.get("close", false)):
		push_error("Geri yüklemeden sonra eski anahtar geçerli kaldı")
	# Dakikada 60 mesaj: aşan kimliğin bağlantısı kapanır ve 5 dk bekletilir
	var kept: bool = true
	for i: int in range(GameConfig.MM_SESSION_MSG_PER_MIN + 1):
		kept = hub.handle_session_message(cl[1], {"op": "ping"})
	if kept or not hub._banned_until.has(b_id):
		push_error("Mesaj hız sınırı çalışmadı")
	# Arayüz: Arkadaşlar, profil kartı ve Hesabım pencereleri kurulabiliyor mu
	var holder: Control = Control.new()
	get_tree().root.add_child(holder)
	var fm: Control = FriendsUi.open_friends(holder)
	var pm: Control = FriendsUi.open_profile(holder, "7K3MQX9P", "Deneme", "diva")
	var am: Control = FriendsUi.open_account(holder)
	var adm: Control = FriendsUi.open_add_friend(holder, "7K3MQX9P")
	for i: int in range(5):
		await get_tree().process_frame
	if fm == null or pm == null or am == null or adm == null:
		push_error("Faz 12 pencereleri kurulamadı")
	if fm != null and fm.find_child("Tab_2", true, false) == null:
		push_error("Arkadaşlar ekranında 3 sekme yok")
	holder.queue_free()
	print("Faz 12A-B kontrolleri bitti.")


## Faz 12C-D: giriş bileti, oda gizliliği, davet, otomatik katılma, engelleme, moderasyon, hesap silme, HTTP ucu.
func _faz12cd_checks() -> void:
	var now: int = int(Time.get_unix_time_from_system())
	var key: PackedByteArray = Crypto.new().generate_random_bytes(32)
	# Giriş bileti: geçerli / başka oda / süresi geçmiş / sahte imza / başka anahtar / boş
	var t: String = RoomTicket.issue(key, "7K3MQX9P", "KTRB", false, now)
	if str(RoomTicket.verify(key, t, "KTRB", now).get("uid", "")) != "7K3MQX9P":
		push_error("Geçerli bilet doğrulanmadı")
	if not RoomTicket.verify(key, t, "ABCD", now).has("error"):
		push_error("Başka odanın bileti kabul edildi")
	if not RoomTicket.verify(key, t, "KTRB", now + GameConfig.TICKET_TTL_SEC + 1).has("error"):
		push_error("Süresi geçmiş bilet kabul edildi")
	var forged: String = t.substr(0, t.rfind(".") + 1) + "0".repeat(64)
	if not RoomTicket.verify(key, forged, "KTRB", now).has("error"):
		push_error("Sahte imzalı bilet kabul edildi")
	var body_swap: String = Marshalls.utf8_to_base64(JSON.stringify({"u": "AAAAAAAA", "c": "KTRB", "e": now + 30, "n": "x", "m": 0})) + t.substr(t.rfind("."))
	if not RoomTicket.verify(key, body_swap, "KTRB", now).has("error"):
		push_error("İçeriği değiştirilmiş bilet kabul edildi")
	if not RoomTicket.verify(Crypto.new().generate_random_bytes(32), t, "KTRB", now).has("error") or not RoomTicket.verify(key, "", "KTRB", now).has("error"):
		push_error("Başka anahtarla / biletsiz doğrulama geçti")
	# Oda sunucusu tarafı: tek kullanımlık
	var old_key: PackedByteArray = NetworkManager.room_ticket_key
	var old_code: String = NetworkManager.room_code
	NetworkManager.room_ticket_key = key
	NetworkManager.room_code = "KTRB"
	var t2: String = RoomTicket.issue(key, "7K3MQX9P", "KTRB", true, now)
	var first: Dictionary = NetworkManager.verify_join_ticket(t2)
	if first.has("error") or not bool(first.get("masked", false)) or not NetworkManager.verify_join_ticket(t2).has("error"):
		push_error("Bilet tek kullanımlık değil ya da ad gizleme bayrağı taşınmadı")
	NetworkManager.room_ticket_key = old_key
	NetworkManager.room_code = old_code
	NetworkManager._used_ticket_nonces.clear()

	# Mahalle katmanı: 4 kullanıcı (A oda sahibi, B arkadaşı, C yabancı, D sonra engelleyen)
	var tmp_dir: String = ProjectSettings.globalize_path("user://ci_mahalle_cd")
	DirAccess.make_dir_recursive_absolute(tmp_dir)
	var mem: UserStore = UserStore.new(tmp_dir)
	var rooms: Dictionary = {}
	var hub: CiHub = CiHub.new(mem, rooms)
	hub.ticket_key = key
	hub.report_path = tmp_dir.path_join("reports.log")
	var cl: Array[Dictionary] = []
	for i: int in range(4):
		var c: Dictionary = {"peer": StreamPeerTCP.new(), "ip": "10.1.0.%d" % i, "local": false, "session": false}
		hub.handle_hello(c, {"op": "hello", "version": GameConfig.NET_VERSION, "name": "Cd%d" % i})
		cl.append(c)
	var a: String = str(cl[0]["uid"])
	var b: String = str(cl[1]["uid"])
	var c_id: String = str(cl[2]["uid"])
	var d: String = str(cl[3]["uid"])
	hub.handle_session_message(cl[0], {"op": "friend_request", "rid": 1, "id": b})
	hub.handle_session_message(cl[1], {"op": "friend_respond", "rid": 2, "id": a, "accept": true})
	hub.handle_session_message(cl[0], {"op": "friend_request", "rid": 3, "id": d})
	hub.handle_session_message(cl[3], {"op": "friend_respond", "rid": 4, "id": a, "accept": true})
	var room: Dictionary = {"code": "KTRB", "public": false, "privacy": GameConfig.ROOM_PRIVACY_FRIENDS, "owner_uid": a,
		"allow": {}, "players": 1, "in_match": false, "uids": [a], "reservations": []}
	rooms[7801] = room
	# Gizlilik: arkadaşlarım / davetliler / kodla açık
	if not hub.entry_denied(room, b).is_empty() or hub.entry_denied(room, c_id).is_empty():
		push_error("'Sadece arkadaşlarım' izni hatalı")
	hub.handle_session_message(cl[2], {"op": "room_join_code", "rid": 5, "code": "ktrb"})
	if bool(hub.last().get("ok", true)) or not bool(hub.last().get("denied", false)):
		push_error("İzinsiz kişi kodla 'Sadece arkadaşlarım' odasına girdi: %s" % str(hub.last()))
	room["privacy"] = GameConfig.ROOM_PRIVACY_INVITE
	if hub.entry_denied(room, b).is_empty():
		push_error("'Sadece davetliler' odasına davetsiz arkadaş girebildi")
	# Davet: yalnızca oda sahibi (davetliler), arkadaşa; anlık bildirim ve izin listesi
	hub.handle_session_message(cl[0], {"op": "invite", "rid": 6, "id": c_id})
	if bool(hub.last().get("ok", true)):
		push_error("Arkadaş olmayana davet gönderildi")
	hub.sent.clear()
	hub.handle_session_message(cl[0], {"op": "invite", "rid": 7, "id": b})
	var pushed: bool = false
	for m_v: Variant in hub.sent:
		if str((m_v as Dictionary).get("op", "")) == "invite" and str((((m_v as Dictionary).get("invite", {}) as Dictionary).get("from", {}) as Dictionary).get("id", "")) == a:
			pushed = true
	if not bool(hub.last().get("ok", false)) or not pushed or not hub.entry_denied(room, b).is_empty():
		push_error("Davet gönderilemedi / bildirim gitmedi / izin verilmedi: %s" % str(hub.last()))
	hub.handle_session_message(cl[1], {"op": "invites", "rid": 8})
	if (hub.last().get("invites", []) as Array).size() != 1:
		push_error("Bekleyen davet listesi hatalı")
	hub.handle_session_message(cl[1], {"op": "invite_accept", "rid": 9, "from": a})
	var tk: String = str(hub.last().get("ticket", ""))
	if not bool(hub.last().get("ok", false)) or str(RoomTicket.verify(key, tk, "KTRB", now).get("uid", "")) != b:
		push_error("Davet kabulünde bilet alınamadı: %s" % str(hub.last()))
	# Maç sürerken arkadaşının odasına katılma ve "maç bitince otomatik katıl"
	room["privacy"] = GameConfig.ROOM_PRIVACY_FRIENDS
	room["in_match"] = true
	hub.handle_session_message(cl[3], {"op": "join_friend", "rid": 10, "id": a})
	if bool(hub.last().get("ok", true)) or not bool(hub.last().get("in_match", false)):
		push_error("Maçtaki arkadaşa katılma 'maç sürüyor' demedi")
	hub.handle_session_message(cl[3], {"op": "join_friend", "rid": 11, "id": a, "wait": true})
	if not bool(hub.last().get("waiting", false)):
		push_error("Otomatik katılma kaydı açılmadı")
	room["in_match"] = false
	hub.sent.clear()
	hub.on_room_match_end(7801)
	var auto_ok: bool = false
	for m_v: Variant in hub.sent:
		if str((m_v as Dictionary).get("op", "")) == "auto_join" and not str((m_v as Dictionary).get("ticket", "")).is_empty():
			auto_ok = true
	if not auto_ok:
		push_error("Maç bitince otomatik katılma bileti gitmedi")
	# Engelleme: istek, davet, aynı oda (kodla açık dahil) ve Hızlı Oyun
	room["privacy"] = GameConfig.ROOM_PRIVACY_CODE
	if not hub.entry_denied(room, c_id).is_empty():
		push_error("'Kodla açık' odasına girilemedi")
	hub.handle_session_message(cl[3], {"op": "block", "rid": 12, "id": a})
	if (mem.get_user(a)["friends"] as Array).has(d) or hub.entry_denied(room, d).is_empty():
		push_error("Engelleme arkadaşlığı silmedi ya da odaya girişi engellemedi")
	hub.handle_session_message(cl[0], {"op": "friend_request", "rid": 13, "id": d})
	if bool(hub.last().get("ok", true)):
		push_error("Engellenen kişi istek gönderebildi")
	hub.handle_session_message(cl[0], {"op": "invite", "rid": 14, "id": d})
	if bool(hub.last().get("ok", true)):
		push_error("Engellenen kişiye davet gidebildi")
	var quick: Dictionary = {"code": "QQQQ", "public": true, "players": 1, "in_match": false, "uids": [a], "reservations": [], "allow": {}}
	if hub.entry_denied(quick, d).is_empty() or not hub.entry_denied(quick, c_id).is_empty():
		push_error("Hızlı Oyun engelleme ayrımı hatalı")
	hub.handle_session_message(cl[3], {"op": "get_profile", "rid": 15, "id": a})
	if not bool(hub.last().get("blocked", false)):
		push_error("Profil kartında engel durumu yok")
	# Moderasyon: gizli ad başkalarına "Böcek #XXXX"
	hub.hidden_names[c_id] = true
	if hub.display_name(c_id) != GameConfig.masked_name(c_id) or not bool(RoomTicket.verify(key, hub._grant_payload(c_id, 7801)["ticket"], "KTRB", now)["masked"]):
		push_error("Moderasyonla ad gizleme çalışmadı")
	# Bildir: reports.log'a satır
	hub.handle_session_message(cl[1], {"op": "report", "rid": 16, "id": c_id, "reason": 2})
	if not bool(hub.last().get("ok", false)) or not FileAccess.get_file_as_string(hub.report_path).contains("sebep=Hile"):
		push_error("Profil bildirimi yazılmadı")
	# Hesap silme: kimliği yazarak onay; tüm izler silinir, kimlik bir daha verilmez
	hub.handle_session_message(cl[1], {"op": "recovery_new", "rid": 17})
	var b_code: String = str(hub.last().get("code", ""))
	hub.handle_session_message(cl[0], {"op": "delete_account", "rid": 18, "confirm": b})
	if bool(hub.last().get("ok", true)):
		push_error("Başkasının kimliğiyle hesap silme onayı kabul edildi")
	hub.handle_session_message(cl[0], {"op": "invite", "rid": 19, "id": b})
	hub.handle_session_message(cl[0], {"op": "delete_account", "rid": 20, "confirm": GameConfig.format_account_id(a).to_lower()})
	var clean: bool = not mem.has_user(a) and mem.deleted_ids.has(a) and bool(cl[0].get("close", false))
	for u_v: Variant in mem.users.values():
		var u: Dictionary = u_v as Dictionary
		for f: String in ["friends", "requests_in", "requests_out", "blocked"]:
			if (u[f] as Array).has(a):
				clean = false
		if (u["rejected_by"] as Dictionary).has(a):
			clean = false
	if not clean or hub._live_invites(b).size() != 0 or FileAccess.get_file_as_string(mem.users_path()).contains(a):
		push_error("Hesap silme izleri temizlemedi")
	var reload: UserStore = UserStore.new(tmp_dir)
	reload.load_all()
	if reload.has_user(a) or not reload.deleted_ids.has(a):
		push_error("Silinmiş kimlik listesi kalıcı değil")
	# Web ucu: kimlik + kurtarma kodu
	if bool(hub.delete_with_recovery(b, "AAAAAAAAAAAAAAAA", "10.9.9.9")["ok"]) or not bool(hub.delete_with_recovery(GameConfig.format_account_id(b), b_code, "10.9.9.9")["ok"]) or mem.has_user(b):
		push_error("Web hesap silme ucu hatalı")
	# HTTP ayrıştırma: yalnızca POST /hesap-sil, boyut sınırı
	var req_ok: String = "POST /hesap-sil HTTP/1.1\r\nHost: x\r\nContent-Type: application/x-www-form-urlencoded\r\nContent-Length: 38\r\n\r\nid=%237K3M-QX9P&recovery=ABCD+EFGH%2D1"
	var pr: Dictionary = DeleteHttp.parse_request(req_ok.to_utf8_buffer())
	if str((pr.get("form", {}) as Dictionary).get("id", "")) != "#7K3M-QX9P" or str((pr.get("form", {}) as Dictionary).get("recovery", "")) != "ABCD EFGH-1":
		push_error("HTTP form ayrıştırma hatalı: %s" % str(pr))
	if int(DeleteHttp.parse_request("GET /hesap-sil HTTP/1.1\r\n\r\n".to_utf8_buffer()).get("status", 0)) != 405 \
			or int(DeleteHttp.parse_request("POST /x HTTP/1.1\r\nContent-Length: 0\r\n\r\n".to_utf8_buffer()).get("status", 0)) != 404 \
			or int(DeleteHttp.parse_request("POST /hesap-sil HTTP/1.1\r\nContent-Length: 99999\r\n\r\n".to_utf8_buffer()).get("status", 0)) != 413:
		push_error("HTTP yöntem/yol/boyut kontrolü hatalı")
	if DeleteHttp.build_response(200, "<b>").get_string_from_utf8().contains("<b>") or DeleteHttp.build_response(200, "x").get_string_from_utf8().contains("Access-Control"):
		push_error("HTTP yanıtı kaçışsız ya da CORS başlıklı")
	var da: DirAccess = DirAccess.open(tmp_dir)
	for f: String in da.get_files():
		DirAccess.remove_absolute(tmp_dir.path_join(f))
	DirAccess.remove_absolute(tmp_dir)
	# Arayüz: davet penceresi, arkadaş davet listesi, engelle, bildir, hesap silme onayı
	var holder: Control = Control.new()
	get_tree().root.add_child(holder)
	var pop: Control = Mahalle.show_invite_popup({"from": {"id": "7K3MQX9P", "name": "Ayşe", "char": "diva"}, "code": "KTRB", "n": 2, "max": 5, "exp": now + 600})
	var wins: Array = [
		pop,
		FriendsUi.open_invite_friends(holder),
		FriendsUi.open_block_confirm(holder, "7K3MQX9P", "Ayşe"),
		FriendsUi.open_report_profile(holder, "7K3MQX9P", "Ayşe"),
		FriendsUi.open_delete_account(holder),
		FriendsUi.open_offline_share(holder, "Ayşe"),
	]
	for i: int in range(5):
		await get_tree().process_frame
	for w_v: Variant in wins:
		if w_v == null or not is_instance_valid(w_v):
			push_error("Faz 12C-D penceresi kurulamadı")
	if pop != null and (pop.find_child("InviteText", true, false) as Label).text != "Ayşe seni mutfağa çağırıyor! (Oda: KTRB, 2/5)":
		push_error("Davet penceresi metni hatalı")
	if is_instance_valid(pop):
		pop.queue_free()
	holder.queue_free()
	print("Faz 12C-D kontrolleri bitti.")


## Faz 13A: sesli sohbet paketi, titreşim tamponu, kip/eşik, istemci kapısı, ducking, pencereler.
## Eklenti yokken her şey sessizce kapalı olmalı.
func _faz13a_checks() -> void:
	# Paket biçimi: [bayrak][sıra LE][Opus]; boyut ve bayrak doğrulaması
	var payload: PackedByteArray = PackedByteArray([7, 8, 9])
	var pkt: PackedByteArray = VoiceChat.build_packet(0x1234, payload, false)
	var parsed: Dictionary = VoiceChat.parse_packet(pkt)
	if pkt.size() != 6 or int(parsed.get("seq", -1)) != 0x1234 or bool(parsed.get("end", true)) or (parsed.get("payload", PackedByteArray()) as PackedByteArray) != payload:
		push_error("Sesli sohbet paketi bozuk: %s" % str(parsed))
	if not bool(VoiceChat.parse_packet(VoiceChat.build_packet(5, PackedByteArray(), true)).get("end", false)):
		push_error("Bitiş işareti okunamadı")
	var big: PackedByteArray = PackedByteArray()
	big.resize(GameConfig.VOICE_CHAT_MAX_BYTES + 1)
	var bad_flag: PackedByteArray = PackedByteArray([0x80, 0, 0, 1])
	if not VoiceChat.parse_packet(big).is_empty() or not VoiceChat.parse_packet(PackedByteArray([0, 1])).is_empty() or not VoiceChat.parse_packet(bad_flag).is_empty():
		push_error("Geçersiz sesli sohbet paketi kabul edildi")
	# Titreşim tamponu: ~100 ms bekleme, sıralama, geç gelen atılır, kayıp atlanır, bitişte kapanır
	var jb: VoiceJitterBuffer = VoiceJitterBuffer.new()
	for sq: int in [100, 101, 102]:
		jb.push(sq, PackedByteArray([sq & 0xFF]), false, 0)
	if not jb.pop_ready(50).is_empty():
		push_error("Titreşim tamponu 100 ms beklemedi")
	if jb.pop_ready(GameConfig.VOICE_CHAT_JITTER_MS).size() != 3:
		push_error("Titreşim tamponu 100 ms sonra çalmadı")
	jb.push(104, PackedByteArray([104]), false, 120)
	jb.push(103, PackedByteArray([103]), false, 121)
	var ordered: Array[PackedByteArray] = jb.pop_ready(122)
	if ordered.size() != 2 or ordered[0][0] != 103 or ordered[1][0] != 104:
		push_error("Titreşim tamponu sıralamadı")
	jb.push(102, PackedByteArray([102]), false, 130)
	if jb.late_dropped != 1:
		push_error("Geç gelen parça atılmadı")
	jb.push(106, PackedByteArray([106]), false, 140)
	if not jb.pop_ready(141).is_empty():
		push_error("Kayıp parça için hiç beklenmedi")
	jb.push(107, PackedByteArray([107]), false, 160)
	var after_gap: Array[PackedByteArray] = jb.pop_ready(161)
	if jb.skipped != 1 or after_gap.size() != 2 or after_gap[0][0] != 106:
		push_error("Kayıp parça atlanmadı (atlanan %d, çıkan %d)" % [jb.skipped, after_gap.size()])
	jb.push(108, PackedByteArray(), true, 180)
	jb.pop_ready(181)
	if jb.is_open():
		push_error("Bitiş işaretiyle akış kapanmadı")
	if VoiceJitterBuffer.seq_diff(2, 65534) != 4 or VoiceJitterBuffer.seq_diff(65534, 2) != -4:
		push_error("Sıra numarası taşması hatalı")
	# Kip: Hızlı Oyun / eklentisiz / Hayır = kapalı; izinsiz Katıl = Sadece Dinle
	if VoiceChat.compute_mode(false, true, GameConfig.VOICE_CHOICE_JOIN, true) != GameConfig.VOICE_MODE_OFF 			or VoiceChat.compute_mode(true, false, GameConfig.VOICE_CHOICE_JOIN, true) != GameConfig.VOICE_MODE_OFF 			or VoiceChat.compute_mode(true, true, GameConfig.VOICE_CHOICE_JOIN, false) != GameConfig.VOICE_MODE_LISTEN 			or VoiceChat.compute_mode(true, true, GameConfig.VOICE_CHOICE_JOIN, true) != GameConfig.VOICE_MODE_TALK 			or VoiceChat.compute_mode(true, true, GameConfig.VOICE_CHOICE_NO, true) != GameConfig.VOICE_MODE_OFF 			or VoiceChat.compute_mode(true, true, GameConfig.VOICE_CHOICE_UNSET, true) != GameConfig.VOICE_MODE_OFF:
		push_error("Sesli sohbet kipi hatalı")
	if not is_equal_approx(VoiceChat.effective_threshold(0.1, true), 0.1 * GameConfig.VOICE_CHAT_ECHO_MULT) or not is_equal_approx(VoiceChat.effective_threshold(0.1, false), 0.1):
		push_error("Yankı önleme eşiği hatalı")
	if not is_equal_approx(VoiceChat.peak_of(PackedVector2Array([Vector2(0.1, -0.4), Vector2(0.2, 0.0)])), 0.4):
		push_error("Tepe ölçümü hatalı")
	# İstemci kapısı: ağ yokken (ve tek oyunculuda) asla gönderilmez
	if NetworkManager.voice_chat_can_send() or NetworkManager.send_voice_frame(pkt) or NetworkManager.voice_chat_room_allowed():
		push_error("Ağsız ortamda sesli sohbet kapısı açık")
	# Eklenti yokken: hiçbir arayüz görünmez, düğüm hatasız eklenip çıkarılır
	if not VoiceChat.is_supported() and VoiceChat.ui_available():
		push_error("Eklenti yokken sesli sohbet arayüzü açık")
	var holder: Control = Control.new()
	get_tree().root.add_child(holder)
	var vc: VoiceChat = VoiceChat.new()
	holder.add_child(vc)
	var box: VBoxContainer = VoiceChatUi.build_lobby_box(vc, 64.0)
	holder.add_child(box)
	for i: int in range(3):
		await get_tree().process_frame
	if box.visible or vc.mic_open() or vc.local_mode() != GameConfig.VOICE_MODE_OFF:
		push_error("Sesli sohbet tek oyunculuda / eklentisiz açık")
	# Önizleme: pencereler ve ayar bölümü kurulabiliyor
	VoiceChat.ui_preview = true
	var settings_body: VBoxContainer = VBoxContainer.new()
	holder.add_child(settings_body)
	VoiceChatUi.build_settings_section(settings_body, holder)
	var join: Control = VoiceChatUi.open_join_modal(holder, vc)
	var peer: Control = VoiceChatUi.open_peer_modal(holder, 2)
	for i: int in range(3):
		await get_tree().process_frame
	if join.find_child("JoinButton", true, false) == null or join.find_child("ListenButton", true, false) == null or join.find_child("NoButton", true, false) == null:
		push_error("Katılma penceresi düğmeleri eksik")
	if settings_body.find_child("VoiceLevelBar", true, false) == null or peer == null:
		push_error("Sesli sohbet ayarları / kişi penceresi kurulamadı")
	VoiceChat.ui_preview = false
	holder.queue_free()
	await get_tree().process_frame
	# Ducking: müzik -6 dB, efekt -3 dB; bitince geri
	var m_idx: int = AudioServer.get_bus_index("Music")
	var base_db: float = AudioServer.get_bus_volume_db(m_idx)
	AudioManager.set_voice_duck(true)
	await get_tree().create_timer(0.35).timeout
	var ducked: float = AudioServer.get_bus_volume_db(m_idx)
	AudioManager.set_voice_duck(false)
	await get_tree().create_timer(0.7).timeout
	if absf(ducked - (base_db + GameConfig.VOICE_CHAT_DUCK_MUSIC_DB)) > 0.3 or absf(AudioServer.get_bus_volume_db(m_idx) - base_db) > 0.05:
		push_error("Ducking hatalı: %.2f -> %.2f" % [ducked, AudioServer.get_bus_volume_db(m_idx)])
	# Konuşan alt bus'ı kalmamalı
	for i: int in range(AudioServer.bus_count):
		if AudioServer.get_bus_name(i).begins_with(GameConfig.VOICE_CHAT_PEER_BUS_PREFIX):
			push_error("Artık sesli sohbet bus'ı: " + AudioServer.get_bus_name(i))
	print("Faz 13A kontrolleri bitti.")


## Metni verilen bir Label/Button alt düğümde var mı?
func _has_text(n: Node, text: String) -> bool:
	if (n is Label and (n as Label).text == text) or (n is Button and (n as Button).text == text):
		return true
	for c: Node in n.get_children():
		if _has_text(c, text):
			return true
	return false


## Faz 13B: açılış atlama kuralları, gece saatleri, tema/yazı tipi ve ana menü giriş noktaları.
func _faz13b_checks() -> void:
	# Sunucu kipinde ve başsız çalışmada intro atlanır
	if IntroScene.skip_reason(PackedStringArray(["--room"]), "Windows") != "server" 			or IntroScene.skip_reason(PackedStringArray(["--matchmaker"]), "headless") != "server":
		push_error("Sunucu kipinde intro atlanmıyor")
	if IntroScene.skip_reason(PackedStringArray([]), "headless") != "headless" or IntroScene.skip_reason(PackedStringArray([]), "Windows") != "":
		push_error("Başsız/pencereli intro kararı hatalı")
	if IntroScene.pick_kind(true, false) != "full" or IntroScene.pick_kind(true, true) != "short" or IntroScene.pick_kind(false, false) != "logo":
		push_error("Intro türü seçimi hatalı")
	for p: String in IntroScene.preload_paths():
		if not ResourceLoader.exists(p):
			push_error("Ön yükleme yolu yok: " + p)
	if str(ProjectSettings.get_setting("application/run/main_scene")) != GameConfig.INTRO_SCENE_PATH:
		push_error("Ana sahne Intro olmalı")
	# Gece modu sınırları (22:00-06:00)
	if not KitchenScene.is_night_hour(22) or not KitchenScene.is_night_hour(5) or KitchenScene.is_night_hour(6) or KitchenScene.is_night_hour(21):
		push_error("Gece saati sınırları hatalı")
	# Tema ve Türkçe harfler
	var th: Theme = load(GameConfig.THEME_PATH) as Theme
	if th == null or str(ProjectSettings.get_setting("gui/theme/custom")) != GameConfig.THEME_PATH:
		push_error("Tema yüklenemedi ya da proje ayarına bağlı değil")
	elif not CreditsModal.font_has_all(th.default_font, CreditsModal.TURKISH_TEST):
		push_error("Tema yazı tipinde Türkçe harf eksik")
	if not CreditsModal.font_has_all(AssetHelper.get_ui_font(), CreditsModal.TURKISH_TEST):
		push_error("Arayüz yazı tipinde Türkçe harf eksik")
	# Yerleşim: üst çubuk < logo < OYNA < alt menü, hepsi ekranda
	for vis: Vector2 in [Vector2(720.0, 1280.0), Vector2(720.0, 1600.0), Vector2(960.0, 1280.0)]:
		var lay: Dictionary = KitchenScene.menu_layout(vis, {"top": 40.0, "bottom": 24.0})
		var tb: Rect2 = lay["top_bar"] as Rect2
		var lg: Rect2 = lay["logo"] as Rect2
		var pl: Rect2 = lay["play"] as Rect2
		var nv: Rect2 = lay["nav"] as Rect2
		if not (tb.end.y <= lg.position.y and lg.end.y < pl.position.y and pl.end.y <= nv.position.y and nv.end.y <= vis.y):
			push_error("Menü yerleşimi üst üste biniyor: %s" % str(vis))
	# Logo ve paylaşım kartı aynı sahneyi kullanır
	var logo: GameLogo = GameLogo.create(false, false)
	if logo == null:
		push_error("Logo sahnesi oluşturulamadı")
	else:
		logo.free()

	# Ana menü: tüm giriş noktaları
	var packed: PackedScene = load(GameConfig.MENU_SCENE_PATH) as PackedScene
	var menu: Control = packed.instantiate() as Control
	get_tree().root.add_child(menu)
	for i: int in range(10):
		await get_tree().process_frame
	for path: String in ["Kitchen", "Ui/TopBar/ProfileCard", "Ui/TopBar/CrumbPill", "Ui/TopBar/StreakPill",
			"Ui/Pages/Page_home/PlayButton", "Ui/Pages/Page_home/GearButton", "Ui/Pages/Page_home/Logo"]:
		if menu.find_child(path.get_file(), true, false) == null:
			push_error("Menü öğesi yok: " + path)
	for t: String in ["shop", "bugs", "home", "quests", "friends"]:
		if menu.find_child("Nav_" + t, true, false) == null:
			push_error("Alt menü sekmesi yok: " + t)
	var expect_tab: Dictionary = {"shop": "ShopPage", "bugs": "SkillsButton", "quests": "StreakCard", "friends": "FriendsPage"}
	for t: String in expect_tab.keys():
		menu.call("_switch_tab", t)
		for i: int in range(8):
			await get_tree().process_frame
		if menu.find_child(str(expect_tab[t]), true, false) == null:
			push_error("Sekme içeriği eksik: %s/%s" % [t, str(expect_tab[t])])
	if menu.find_child("MoreBugsCard", true, false) == null and CharacterData.ALL_ORDER.size() > 4:
		push_error("Böcekler sekmesinde Pazar kartı yok")
	menu.call("_switch_tab", "home")
	for i: int in range(8):
		await get_tree().process_frame
	# OYNA → mod kartı
	menu.call("_open_mode_sheet")
	await get_tree().process_frame
	var play_sheet: Node = menu.find_child("ModalPlay", true, false)
	if play_sheet == null:
		push_error("Mod seçim kartı açılmadı")
	else:
		for m: String in ["Mode_solo", "Mode_daily", "Mode_bots", "Mode_lan", "Mode_online"]:
			if play_sheet.find_child(m, true, false) == null:
				push_error("Mod eksik: " + m)
		play_sheet.queue_free()
		await get_tree().process_frame
	# Profil kartı ve dişli menüsü: aynı bağlantılar
	for opener: String in ["_open_profile_sheet", "_open_more_sheet"]:
		menu.call(opener)
		await get_tree().process_frame
		var sheet: Node = menu.find_child("ModalProfile" if opener == "_open_profile_sheet" else "ModalMore", true, false)
		if sheet == null:
			push_error("Pencere açılmadı: " + opener)
			continue
		var want_links: Array[String] = ["Link_settings", "Link_album", "Link_guide", "Link_credits"]
		if GameConfig.ONLINE_ENABLED:
			want_links.append("Link_account")
		for l: String in want_links:
			if sheet.find_child(l, true, false) == null:
				push_error("%s içinde bağlantı yok: %s" % [opener, l])
		if opener == "_open_profile_sheet" and (sheet.find_child("NameInput", true, false) == null or sheet.find_child("IdRow", true, false) == null):
			push_error("Profil kartında ad/kimlik yok")
		sheet.queue_free()
		await get_tree().process_frame
	# Ayarlar: yeni anahtarlar
	menu.call("_open_settings_modal")
	await get_tree().process_frame
	var st: Node = menu.find_child("ModalSettings", true, false)
	if st == null or not _has_text(st, "Buton tık ve titreşimi") or not _has_text(st, "Açılış animasyonunu göster"):
		push_error("Ayarlarda tık/titreşim veya açılış anahtarı yok")
	if st != null:
		st.queue_free()
		await get_tree().process_frame
	# Emeği Geçenler: harf testi satırı
	var cr: Control = CreditsModal.open(menu)
	if cr == null or cr.find_child("TurkishTest", true, false) == null:
		push_error("Emeği Geçenler harf testi yok")
	if cr != null:
		cr.queue_free()
	# Botlar ve LAN pencereleri
	menu.call("_open_bots_modal")
	menu.call("_open_lan_sheet")
	await get_tree().process_frame
	if menu.find_child("BotsStartButton", true, false) == null or menu.find_child("LanHost", true, false) == null:
		push_error("Botlar / Wi-Fi penceresi eksik")
	menu.queue_free()
	await get_tree().process_frame
	print("Faz 13B kontrolleri bitti.")

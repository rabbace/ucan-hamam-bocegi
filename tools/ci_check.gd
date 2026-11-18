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
	await _faz11d_checks(world)


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

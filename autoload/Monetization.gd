extends Node

## 9.4: Kırıntı ekonomisi, kilitli karakter/kostüm kaydı ve reklam/mağaza servisleri.

signal kirinti_changed(new_amount: int)
signal purchase_completed(product_id: String, ok: bool, msg: String)
signal rewarded_ad_finished(success: bool)

var kirinti: int = 0
var unlocked_chars: Array[String] = ["klasik", "diva", "duktur", "halaybasi"]
var unlocked_skins: Array[String] = []
var selected_skins: Dictionary = {} # char_id -> skin_id
var trial_char: String = ""
var ad_free: bool = false
var last_daily_date: String = ""
var total_matches: int = 0
var matches_since_interstitial: int = 0
## Faz 11.4: biriken kostüm parçaları (3 parça = 1 kostüm)
var costume_parts: int = 0


## Kayıt dosyası şifreli tutulur (düz metin düzenlemeye karşı caydırıcı; tam koruma değildir).
const SAVE_PASS: String = "ucan-hamam-bocegi-kirinti-v1"

## Bu maç için kullanılan deneme karakteri (hak maç başında tüketilir, maç bitene kadar geçerli).
var _match_trial_char: String = ""
## Görülen en ileri tarih: saat geri alınınca günlük ödül/görev yeniden verilmez.
var max_seen_date: String = ""


func _ready() -> void:
	load_save()
	claim_daily_bonus()


## Şifreli kaydı açar; yoksa eski düz metin kaydı okuyup şifreliye taşır.
func _load_cfg() -> ConfigFile:
	var cfg: ConfigFile = ConfigFile.new()
	if not FileAccess.file_exists(GameConfig.SAVE_PATH):
		return cfg
	if cfg.load_encrypted_pass(GameConfig.SAVE_PATH, SAVE_PASS) == OK:
		return cfg
	var plain: ConfigFile = ConfigFile.new()
	if plain.load(GameConfig.SAVE_PATH) == OK:
		plain.save_encrypted_pass(GameConfig.SAVE_PATH, SAVE_PASS)
		return plain
	return ConfigFile.new()


func _save_cfg(cfg: ConfigFile) -> void:
	cfg.save_encrypted_pass(GameConfig.SAVE_PATH, SAVE_PASS)


static func _today_str() -> String:
	var d: Dictionary = Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]


func load_save() -> void:
	var cfg: ConfigFile = _load_cfg()
	if not cfg.has_section("eco"):
		return
	kirinti = int(cfg.get_value("eco", "kirinti", 0))
	var uc: Variant = cfg.get_value("eco", "unlocked_chars", ["klasik", "diva", "duktur", "halaybasi"])
	if uc is Array:
		unlocked_chars.clear()
		for c: Variant in (uc as Array):
			unlocked_chars.append(str(c))
	var us: Variant = cfg.get_value("eco", "unlocked_skins", [])
	if us is Array:
		unlocked_skins.clear()
		for s: Variant in (us as Array):
			unlocked_skins.append(str(s))
	selected_skins = cfg.get_value("eco", "selected_skins", {}) as Dictionary
	trial_char = str(cfg.get_value("eco", "trial_char", ""))
	ad_free = bool(cfg.get_value("eco", "ad_free", false))
	last_daily_date = str(cfg.get_value("eco", "last_daily_date", ""))
	total_matches = int(cfg.get_value("eco", "total_matches", 0))
	matches_since_interstitial = int(cfg.get_value("eco", "matches_since_interstitial", 0))
	max_seen_date = str(cfg.get_value("eco", "max_seen_date", last_daily_date))
	costume_parts = int(cfg.get_value("eco", "costume_parts", 0))


func save_data() -> void:
	# Önce mevcut dosyayı oku: aynı dosyadaki [quests] bölümü silinmesin.
	var cfg: ConfigFile = _load_cfg()
	cfg.set_value("eco", "kirinti", kirinti)
	cfg.set_value("eco", "unlocked_chars", unlocked_chars)
	cfg.set_value("eco", "unlocked_skins", unlocked_skins)
	cfg.set_value("eco", "selected_skins", selected_skins)
	cfg.set_value("eco", "trial_char", trial_char)
	cfg.set_value("eco", "ad_free", ad_free)
	cfg.set_value("eco", "last_daily_date", last_daily_date)
	cfg.set_value("eco", "total_matches", total_matches)
	cfg.set_value("eco", "matches_since_interstitial", matches_since_interstitial)
	cfg.set_value("eco", "max_seen_date", max_seen_date)
	cfg.set_value("eco", "costume_parts", costume_parts)
	_save_cfg(cfg)


## Günlük ödül yalnızca tarih İLERİ gittiğinde verilir (ISO tarih dizgeleri sözlük sırasıyla
## karşılaştırılır). Saat geri alınıp yeniden ileri alınsa da görülen en ileri tarih aşılmadıkça ödül yok.
func claim_daily_bonus() -> int:
	var today: String = _today_str()
	if today > last_daily_date and today > max_seen_date:
		last_daily_date = today
		max_seen_date = today
		add_kirinti(GameConfig.KIRINTI_DAILY_BONUS)
		return GameConfig.KIRINTI_DAILY_BONUS
	return 0


func add_kirinti(amount: int) -> void:
	if amount <= 0:
		return
	kirinti += amount
	save_data()
	kirinti_changed.emit(kirinti)


func spend_kirinti(amount: int) -> bool:
	if kirinti < amount:
		return false
	kirinti -= amount
	save_data()
	kirinti_changed.emit(kirinti)
	return true


func is_char_unlocked(char_id: String) -> bool:
	if char_id.is_empty():
		return false
	return unlocked_chars.has(char_id) or trial_char == char_id or _match_trial_char == char_id


## Maç başında çağrılır: seçili karakter gerçekten oynanabilir mi kontrol eder, değilse
## "klasik"e düşer. Deneme karakteriyse hak HEMEN tüketilir (maç ortası çıkış/kapatma
## hakkı geri vermez) ama karakter bu maç bitene kadar oynanabilir kalır.
func begin_match_character(char_id: String) -> String:
	var cid: String = char_id
	if not CharacterData.CHARACTERS.has(cid):
		return "klasik"
	if unlocked_chars.has(cid):
		_match_trial_char = ""
		return cid
	if trial_char == cid:
		_match_trial_char = cid
		trial_char = ""
		save_data()
		return cid
	_match_trial_char = ""
	return "klasik"


## Maç bittiğinde (ölüm/sonuç/menüye dönüş) deneme karakterinin geçici iznini kapatır.
func end_match_character() -> void:
	_match_trial_char = ""


func unlock_char_with_kirinti(char_id: String, price: int) -> bool:
	if unlocked_chars.has(char_id):
		return true
	if not spend_kirinti(price):
		return false
	unlocked_chars.append(char_id)
	save_data()
	return true


func grant_trial(char_id: String) -> void:
	trial_char = char_id
	save_data()


## Hak artık maç başında tüketiliyor (begin_match_character); burada yalnızca maçlık izin kapanır.
func consume_trial() -> void:
	end_match_character()


func unlock_skin_with_kirinti(skin_key: String) -> bool:
	if unlocked_skins.has(skin_key):
		return true
	if not spend_kirinti(GameConfig.SKIN_COST):
		return false
	unlocked_skins.append(skin_key)
	save_data()
	return true


## Sahte servisler yalnızca geliştirme sürümünde (editör / debug dışa aktarım) çalışır.
## Yayın sürümünde gerçek eklenti yoksa ödül ya da satın alma VERİLMEZ.
func uses_fake_services() -> bool:
	return OS.is_debug_build()


## Reklamın hiç gösterilmediği platformlar: Steam / masaüstü yayın sürümü.
func ad_free_platform() -> bool:
	return OS.has_feature("steam") or (OS.has_feature("pc") and not OS.is_debug_build())


## Ödüllü reklam bu platformda kullanılabilir mi?
func is_rewarded_ad_available() -> bool:
	if ad_free_platform():
		return false
	return has_real_admob() or uses_fake_services()


## Mağaza (uygulama içi satın alma) bu platformda kullanılabilir mi?
func is_store_available() -> bool:
	return has_real_billing() or uses_fake_services()


## Sahte veya gerçek ödüllü reklam akışı (otomatik açılmaz, sadece kullanıcı basınca).
func show_rewarded_ad(on_done: Callable) -> void:
	if not is_rewarded_ad_available() or not uses_fake_services():
		# Gerçek reklam eklentisi bağlanana kadar yayın sürümünde ödül verilmez.
		rewarded_ad_finished.emit(false)
		if on_done.is_valid():
			on_done.call(false)
		return
	# Geliştirme sürümü sahte servis: kısa bekleme sonrası ödül verir
	await get_tree().create_timer(1.2).timeout
	rewarded_ad_finished.emit(true)
	if on_done.is_valid():
		on_done.call(true)


## Geçiş reklamı kuralı: ilk 2 maçta yok, reklamsız alındıysa yok, en fazla 3 maçta bir.
func record_match_end_and_check_interstitial() -> bool:
	total_matches += 1
	matches_since_interstitial += 1
	if ad_free or total_matches <= 2 or matches_since_interstitial < 3:
		save_data()
		return false
	matches_since_interstitial = 0
	save_data()
	return true


## Sahte veya gerçek mağaza satın alma akışı.
func purchase_product(product_id: String) -> void:
	if not uses_fake_services():
		# Gerçek mağaza eklentisi (Play Billing / StoreKit / Steam) bağlanana kadar satış kapalı.
		purchase_completed.emit(product_id, false, "Mağaza şu an kapalı, birazdan tekrar dene.")
		return
	match product_id:
		"paket_bocekler":
			for cid: String in CharacterData.ALL_ORDER:
				if not unlocked_chars.has(cid):
					unlocked_chars.append(cid)
			save_data()
			purchase_completed.emit(product_id, true, "Tüm böcekler açıldı!")
		"kirinti_kesesi_kucuk":
			add_kirinti(1500)
			purchase_completed.emit(product_id, true, "+1500 Kırıntı eklendi!")
		"kirinti_kesesi_buyuk":
			add_kirinti(5000)
			purchase_completed.emit(product_id, true, "+5000 Kırıntı eklendi!")
		"reklamsiz":
			ad_free = true
			save_data()
			purchase_completed.emit(product_id, true, "Geçiş reklamları kaldırıldı!")


func restore_purchases() -> void:
	save_data()
	purchase_completed.emit("restore", true, "Satın alımlar kontrol edildi.")


# --- Faz 11.4: Günlük görevler (tarih seed'li), Günün Sürprizi, seri ve kostüm parçası ---

## Görev ilerledi (maç içi küçük bildirim için). completed: görev bu olayla bitti.
signal quest_progressed(text: String, completed: bool)
signal streak_changed(count: int)

const QUEST_SAVE_VERSION: int = 2

var quest_date: String = ""
## Bugünün görevleri: {id, n, reward, char, progress, claimed}
var quest_tasks: Array[Dictionary] = []
var quest_rerolls_used: int = 0
var quest_surprise_claimed: bool = false
## Bir sonraki maçın etiketi (ör. "gunun_mutfagi"); maç başında okunur
var next_match_tag: String = ""
var _match_tag: String = ""
var _in_match: bool = false
var _quest_dirty: bool = false
## "match" kipindeki görevler için bu maçtaki sayaçlar (görev kimliği -> sayı)
var _quest_match_counts: Dictionary = {}

var streak_count: int = 0
var streak_best: int = 0
var streak_last_play: String = ""
var streak_reward_date: String = ""
var streak_save_day: int = -100000
var streak_celebrated: int = 0
var _streak_loaded: bool = false


func _ensure_daily_quests() -> void:
	var today: String = _today_str()
	# Aynı gün ya da saat geri alındı: mevcut liste geçerli (sıfırlanmaz)
	if quest_date != "" and today <= quest_date:
		return
	var cfg: ConfigFile = _load_cfg()
	var saved_date: String = str(cfg.get_value("quests", "date", ""))
	var ver: int = int(cfg.get_value("quests", "version", 1))
	if saved_date != "" and today < saved_date:
		today = saved_date
	if saved_date == today and ver == QUEST_SAVE_VERSION:
		quest_date = today
		quest_tasks.clear()
		var raw: Variant = cfg.get_value("quests", "tasks", [])
		if raw is Array:
			for t_v: Variant in (raw as Array):
				if t_v is Dictionary and not GameConfig.get_daily_task_def(str((t_v as Dictionary).get("id", ""))).is_empty():
					quest_tasks.append(t_v as Dictionary)
		quest_rerolls_used = int(cfg.get_value("quests", "rerolls", 0))
		quest_surprise_claimed = bool(cfg.get_value("quests", "surprise_claimed", false))
		if quest_tasks.size() == GameConfig.DAILY_TASK_COUNT:
			return
	# Yeni gün (veya eski biçimli kayıt): tarihten seçilen 3 görev
	quest_date = today
	quest_tasks.clear()
	for t: Dictionary in GameConfig.pick_daily_tasks(today):
		var row: Dictionary = t.duplicate()
		row["progress"] = 0
		row["claimed"] = false
		quest_tasks.append(row)
	quest_rerolls_used = 0
	quest_surprise_claimed = false
	_quest_match_counts.clear()
	_save_quests()


func _save_quests() -> void:
	var cfg: ConfigFile = _load_cfg()
	# Eski (v1) anahtarlar temizlenir
	for k: String in ["progress", "claimed"]:
		if cfg.has_section_key("quests", k):
			cfg.erase_section_key("quests", k)
	cfg.set_value("quests", "version", QUEST_SAVE_VERSION)
	cfg.set_value("quests", "date", quest_date)
	cfg.set_value("quests", "tasks", quest_tasks)
	cfg.set_value("quests", "rerolls", quest_rerolls_used)
	cfg.set_value("quests", "surprise_claimed", quest_surprise_claimed)
	_save_cfg(cfg)
	_quest_dirty = false


## Arayüz için görev listesi (başlık, hedef, ödül, ilerleme, alındı mı).
func get_daily_quests() -> Array[Dictionary]:
	_ensure_daily_quests()
	var out: Array[Dictionary] = []
	for t: Dictionary in quest_tasks:
		var tid: String = str(t["id"])
		out.append({
			"id": tid,
			"title": GameConfig.daily_task_text(tid, int(t["n"]), str(t.get("char", ""))),
			"goal": int(t["n"]),
			"reward": int(t["reward"]),
			"progress": int(t.get("progress", 0)),
			"claimed": bool(t.get("claimed", false)),
			"char": str(t.get("char", "")),
		})
	return out


## Oyunun bildirdiği görev olayı. YALNIZCA yerel insan oyuncu için çağrılır (botlar ilerletmez).
func quest_event(event: String, amount: int = 1, char_id: String = "") -> void:
	if amount <= 0:
		return
	_ensure_daily_quests()
	var changed: bool = false
	for t: Dictionary in quest_tasks:
		var d: Dictionary = GameConfig.get_daily_task_def(str(t["id"]))
		if str(d.get("event", "")) != event:
			continue
		var t_char: String = str(t.get("char", ""))
		if not t_char.is_empty() and t_char != char_id:
			continue
		var goal: int = int(t["n"])
		var before: int = int(t.get("progress", 0))
		if before >= goal or bool(t.get("claimed", false)):
			continue
		var after: int = before
		match str(d.get("mode", "sum")):
			"match":
				var key: String = str(t["id"])
				var cnt: int = int(_quest_match_counts.get(key, 0)) + amount
				_quest_match_counts[key] = cnt
				after = maxi(before, mini(cnt, goal))
			"max":
				after = maxi(before, mini(amount, goal))
			_:
				after = mini(before + amount, goal)
		if after == before:
			continue
		t["progress"] = after
		changed = true
		var hud_txt: String = str(d.get("hud", "{p}/{n}")).replace("{p}", str(after)).replace("{n}", str(goal))
		quest_progressed.emit("Görev: " + hud_txt, after >= goal)
	if changed:
		if _in_match:
			_quest_dirty = true
		else:
			_save_quests()


## Maç başı: maçlık sayaçlar sıfırlanır.
func quest_match_begin() -> void:
	_ensure_daily_quests()
	_in_match = true
	_quest_match_counts.clear()
	_match_tag = next_match_tag
	next_match_tag = ""


## Maç bitti (ölüm / sonuç). info: char, mp, won, survive (sn), level. Seriyi de işler.
func quest_match_end(info: Dictionary) -> void:
	if not _in_match:
		return
	var cid: String = str(info.get("char", ""))
	quest_event("play", 1, cid)
	quest_event("play_char", 1, cid)
	if bool(info.get("mp", false)):
		quest_event("play_mp", 1, cid)
		if bool(info.get("won", false)):
			quest_event("win", 1, cid)
	quest_event("survive", int(info.get("survive", 0)), cid)
	quest_event("level", int(info.get("level", 0)), cid)
	if _match_tag == "gunun_mutfagi":
		quest_event("daily_kitchen", 1, cid)
	_in_match = false
	_match_tag = ""
	_save_quests()
	record_streak_play()


## Maç yarıda bırakıldı (menüye dönüş): ilerleme kaydedilir, maç sayılmaz.
func quest_match_abort() -> void:
	if not _in_match:
		return
	_in_match = false
	_match_tag = ""
	if _quest_dirty:
		_save_quests()


func claim_quest_reward(q_id: String) -> int:
	_ensure_daily_quests()
	for t: Dictionary in quest_tasks:
		if str(t["id"]) == q_id and not bool(t.get("claimed", false)) and int(t.get("progress", 0)) >= int(t["n"]):
			t["claimed"] = true
			_save_quests()
			var rew: int = int(t["reward"])
			add_kirinti(rew)
			return rew
	return 0


## Günde 1 kez, ödüllü reklam varsa, bitmemiş bir görev değiştirilebilir.
func can_reroll_quest(q_id: String) -> bool:
	_ensure_daily_quests()
	if quest_rerolls_used >= GameConfig.DAILY_TASK_REROLLS_PER_DAY or not is_rewarded_ad_available():
		return false
	for t: Dictionary in quest_tasks:
		if str(t["id"]) == q_id:
			return not bool(t.get("claimed", false)) and int(t.get("progress", 0)) < int(t["n"])
	return false


## Görevi tarih seed'inden sıradaki uygun görevle değiştirir (reklam izlendikten sonra çağrılır).
func reroll_quest(q_id: String) -> bool:
	if not can_reroll_quest(q_id):
		return false
	var cur_ids: Array[String] = []
	var other_events: Array[String] = []
	var mp_n: int = 0
	var social_n: int = 0
	for t: Dictionary in quest_tasks:
		cur_ids.append(str(t["id"]))
		if str(t["id"]) == q_id:
			continue
		var od: Dictionary = GameConfig.get_daily_task_def(str(t["id"]))
		var oev: String = str(od.get("event", ""))
		other_events.append("play" if oev == "play_char" else oev)
		if str(od.get("group", "")) == "mp":
			mp_n += 1
		elif str(od.get("group", "")) == "social":
			social_n += 1
	var candidates: Array[Dictionary] = GameConfig.pick_daily_tasks(quest_date, GameConfig.DAILY_TASKS.size(), cur_ids)
	for c: Dictionary in candidates:
		var cd: Dictionary = GameConfig.get_daily_task_def(str(c["id"]))
		var cev: String = str(cd.get("event", ""))
		if other_events.has("play" if cev == "play_char" else cev):
			continue
		var grp: String = str(cd.get("group", ""))
		if grp == "mp" and mp_n >= GameConfig.DAILY_TASK_MAX_MP:
			continue
		if grp == "social" and social_n >= GameConfig.DAILY_TASK_MAX_SOCIAL:
			continue
		for i: int in range(quest_tasks.size()):
			if str(quest_tasks[i]["id"]) == q_id:
				var row: Dictionary = c.duplicate()
				row["progress"] = 0
				row["claimed"] = false
				quest_tasks[i] = row
		quest_rerolls_used += 1
		_save_quests()
		return true
	return false


func all_quests_claimed() -> bool:
	_ensure_daily_quests()
	for t: Dictionary in quest_tasks:
		if not bool(t.get("claimed", false)):
			return false
	return not quest_tasks.is_empty()


func can_claim_surprise() -> bool:
	return all_quests_claimed() and not quest_surprise_claimed


## Günün Sürprizi'ni açar. Dönüş: {kind, amount, text}; açılamazsa boş sözlük.
func claim_surprise() -> Dictionary:
	if not can_claim_surprise():
		return {}
	quest_surprise_claimed = true
	_save_quests()
	var s: Dictionary = GameConfig.pick_daily_surprise(quest_date)
	return _grant_reward(str(s["kind"]), int(s["amount"]))


## Ödülü verir: "kirinti" doğrudan, "part" kostüm parçası. Dönüş metni arayüz içindir.
func _grant_reward(kind: String, amount: int) -> Dictionary:
	if kind == "part":
		var txt: String = grant_costume_parts(amount)
		return {"kind": kind, "amount": amount, "text": txt}
	add_kirinti(amount)
	return {"kind": "kirinti", "amount": amount, "text": "+%d Kırıntı" % amount}


## Kostüm parçası ekler; yeterli parça birikince Pazar'daki sıradaki kilitli kostüm açılır.
## Tüm kostümler açıksa parça Kırıntıya döner.
func grant_costume_parts(amount: int) -> String:
	costume_parts += maxi(amount, 0)
	var msgs: Array[String] = ["+%d kostüm parçası" % amount]
	while costume_parts >= GameConfig.COSTUME_PARTS_PER_SKIN:
		var key: String = _next_locked_skin()
		if key.is_empty():
			break
		costume_parts -= GameConfig.COSTUME_PARTS_PER_SKIN
		unlocked_skins.append(key)
		msgs.append("Yeni kostüm dolapta!")
	if _next_locked_skin().is_empty() and costume_parts > 0:
		var k: int = costume_parts * GameConfig.COSTUME_PART_KIRINTI
		costume_parts = 0
		kirinti += k
		kirinti_changed.emit(kirinti)
		msgs = ["Dolap dolu: +%d Kırıntı" % k]
	save_data()
	return ", ".join(msgs)


func _next_locked_skin() -> String:
	for cid: String in CharacterData.ALL_ORDER:
		for sk_idx: int in range(1, 3):
			var key: String = "%s_kostum_%d" % [cid, sk_idx]
			if not unlocked_skins.has(key):
				return key
	return ""


# --- Seri ---

func _ensure_streak() -> void:
	if _streak_loaded:
		return
	_streak_loaded = true
	var cfg: ConfigFile = _load_cfg()
	streak_count = int(cfg.get_value("streak", "count", 0))
	streak_best = int(cfg.get_value("streak", "best", streak_count))
	streak_last_play = str(cfg.get_value("streak", "last_play", ""))
	streak_reward_date = str(cfg.get_value("streak", "reward_date", ""))
	streak_save_day = int(cfg.get_value("streak", "save_day", -100000))
	streak_celebrated = int(cfg.get_value("streak", "celebrated", 0))


func _save_streak() -> void:
	var cfg: ConfigFile = _load_cfg()
	cfg.set_value("streak", "count", streak_count)
	cfg.set_value("streak", "best", streak_best)
	cfg.set_value("streak", "last_play", streak_last_play)
	cfg.set_value("streak", "reward_date", streak_reward_date)
	cfg.set_value("streak", "save_day", streak_save_day)
	cfg.set_value("streak", "celebrated", streak_celebrated)
	_save_cfg(cfg)


## Son oynanan günden bugüne kaç gün geçti (hiç oynanmadıysa -1).
func _streak_gap_days() -> int:
	if streak_last_play.is_empty():
		return -1
	return GameConfig.date_to_day_number(_today_str()) - GameConfig.date_to_day_number(streak_last_play)


## O gün ilk maç bitince seri 1 artar; bir gün kaçtıysa 1'den başlar. Saat geri alınırsa sayılmaz.
func record_streak_play() -> void:
	_ensure_streak()
	var today: String = _today_str()
	if not streak_last_play.is_empty() and today <= streak_last_play:
		return
	var gap: int = _streak_gap_days()
	if gap == 1 or streak_last_play.is_empty():
		streak_count += 1
	else:
		streak_count = 1
		# Yeni seri: 7/30/100 kutlamaları yeniden kazanılabilir
		streak_celebrated = 0
	streak_last_play = today
	streak_best = maxi(streak_best, streak_count)
	_save_streak()
	streak_changed.emit(streak_count)


## Ekranda gösterilecek seri (tehlikedeyse hâlâ sayı; daha çok gün kaçtıysa 0).
func get_streak() -> int:
	_ensure_streak()
	var gap: int = _streak_gap_days()
	if gap > GameConfig.STREAK_SAVE_MAX_GAP_DAYS or (gap == GameConfig.STREAK_SAVE_MAX_GAP_DAYS and not can_save_streak()):
		return 0
	return streak_count


func played_today() -> bool:
	_ensure_streak()
	return streak_last_play == _today_str()


## Seri tehlikede mi (tam 1 gün kaçırıldı, bugün henüz oynanmadı)?
func streak_at_risk() -> bool:
	_ensure_streak()
	return streak_count > 0 and _streak_gap_days() == GameConfig.STREAK_SAVE_MAX_GAP_DAYS


## Seriyi Kurtar: tehlikedeyse, haftada 1 kez, ödüllü reklam varsa.
func can_save_streak() -> bool:
	if not streak_at_risk() or not is_rewarded_ad_available():
		return false
	var today_n: int = GameConfig.date_to_day_number(_today_str())
	return today_n - streak_save_day >= GameConfig.STREAK_SAVE_COOLDOWN_DAYS


## Reklam izlendikten sonra: kaçan gün "oynanmış" sayılır, seri korunur.
func save_streak() -> bool:
	if not can_save_streak():
		return false
	var today_n: int = GameConfig.date_to_day_number(_today_str())
	streak_save_day = today_n
	streak_last_play = Time.get_datetime_string_from_unix_time((today_n - 1) * 86400).substr(0, 10)
	_save_streak()
	streak_changed.emit(streak_count)
	return true


## Takvimde bugünün hücresi (0..6). Bugün oynandıysa bugünkü gün, değilse oynanınca gelecek gün.
func streak_calendar_index() -> int:
	_ensure_streak()
	if played_today():
		return (streak_count - 1) % GameConfig.STREAK_REWARDS.size()
	# Tehlikedeki seri kurtarılmadıkça bir sonraki maç 1. günden başlar
	if streak_at_risk():
		return 0
	return get_streak() % GameConfig.STREAK_REWARDS.size()


func can_claim_streak_reward() -> bool:
	_ensure_streak()
	return played_today() and streak_reward_date != _today_str()


## Takvim ödülü (20..80 Kırıntı, 7. gün kostüm parçası).
func claim_streak_reward() -> Dictionary:
	if not can_claim_streak_reward():
		return {}
	streak_reward_date = _today_str()
	_save_streak()
	var amount: int = GameConfig.STREAK_REWARDS[streak_calendar_index()]
	if amount <= 0:
		return _grant_reward("part", 1)
	return _grant_reward("kirinti", amount)


## Kutlanmamış seri eşiği (7/30/100), yoksa 0.
func pending_streak_milestone() -> int:
	_ensure_streak()
	var cur: int = get_streak()
	var found: int = 0
	for m: int in GameConfig.STREAK_MILESTONES:
		if cur >= m and streak_celebrated < m:
			found = m
	return found


func mark_streak_milestone(m: int) -> void:
	_ensure_streak()
	streak_celebrated = maxi(streak_celebrated, m)
	_save_streak()


## Ana menü rozeti: alınabilir ödül sayısı (görev + takvim + sürpriz).
func pending_reward_count() -> int:
	var n: int = 0
	for q: Dictionary in get_daily_quests():
		if not bool(q["claimed"]) and int(q["progress"]) >= int(q["goal"]):
			n += 1
	if can_claim_streak_reward():
		n += 1
	if can_claim_surprise():
		n += 1
	return n


func has_unfinished_quests() -> bool:
	for q: Dictionary in get_daily_quests():
		if int(q["progress"]) < int(q["goal"]):
			return true
	return false


# --- Gerçek Android eklenti köprüleri ---

func has_real_admob() -> bool:
	return Engine.has_singleton("PoingGodotAdMob")


func has_real_billing() -> bool:
	return Engine.has_singleton("GodotGooglePlayBilling")

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


# --- Günlük Görevler ve Gerçek Android Eklenti Köprüleri ---

var quest_date: String = ""
var quest_progress: Dictionary = {"pass": 0, "scare": 0, "play": 0}
var quest_claimed: Dictionary = {"pass": false, "scare": false, "play": false}


func _ensure_daily_quests() -> void:
	var today: String = _today_str()
	# Saat geri alındıysa görevler sıfırlanmaz: en ileri görülen tarih geçerli sayılır.
	if quest_date != "" and today < quest_date:
		return
	if quest_date != today:
		var cfg: ConfigFile = _load_cfg()
		var saved_date: String = str(cfg.get_value("quests", "date", ""))
		if saved_date != "" and today < saved_date:
			today = saved_date
		if saved_date == today:
			quest_date = today
			quest_progress = cfg.get_value("quests", "progress", {"pass": 0, "scare": 0, "play": 0}) as Dictionary
			quest_claimed = cfg.get_value("quests", "claimed", {"pass": false, "scare": false, "play": false}) as Dictionary
		else:
			quest_date = today
			quest_progress = {"pass": 0, "scare": 0, "play": 0}
			quest_claimed = {"pass": false, "scare": false, "play": false}
			_save_quests()


func _save_quests() -> void:
	var cfg: ConfigFile = _load_cfg()
	cfg.set_value("quests", "date", quest_date)
	cfg.set_value("quests", "progress", quest_progress)
	cfg.set_value("quests", "claimed", quest_claimed)
	_save_cfg(cfg)


func get_daily_quests() -> Array[Dictionary]:
	_ensure_daily_quests()
	return [
		{"id": "pass", "title": "20 Engel Geç", "goal": 20, "reward": 100, "progress": int(quest_progress.get("pass", 0)), "claimed": bool(quest_claimed.get("pass", false))},
		{"id": "scare", "title": "Tek Maçta 3 Yakın Kaçış", "goal": 3, "reward": 150, "progress": int(quest_progress.get("scare", 0)), "claimed": bool(quest_claimed.get("scare", false))},
		{"id": "play", "title": "2 Maç Oyna", "goal": 2, "reward": 75, "progress": int(quest_progress.get("play", 0)), "claimed": bool(quest_claimed.get("play", false))},
	]


func record_quest_progress(passed: int, close_scares: int) -> void:
	_ensure_daily_quests()
	quest_progress["pass"] = mini(int(quest_progress.get("pass", 0)) + passed, 20)
	quest_progress["scare"] = maxi(int(quest_progress.get("scare", 0)), mini(close_scares, 3))
	quest_progress["play"] = mini(int(quest_progress.get("play", 0)) + 1, 2)
	_save_quests()


func claim_quest_reward(q_id: String) -> int:
	_ensure_daily_quests()
	for q: Dictionary in get_daily_quests():
		if str(q["id"]) == q_id and not bool(q["claimed"]) and int(q["progress"]) >= int(q["goal"]):
			quest_claimed[q_id] = true
			_save_quests()
			var rew: int = int(q["reward"])
			add_kirinti(rew)
			return rew
	return 0


func has_real_admob() -> bool:
	return Engine.has_singleton("PoingGodotAdMob")


func has_real_billing() -> bool:
	return Engine.has_singleton("GodotGooglePlayBilling")

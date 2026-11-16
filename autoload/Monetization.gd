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


func _ready() -> void:
	load_save()
	claim_daily_bonus()


func load_save() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(GameConfig.SAVE_PATH) != OK:
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


func save_data() -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.set_value("eco", "kirinti", kirinti)
	cfg.set_value("eco", "unlocked_chars", unlocked_chars)
	cfg.set_value("eco", "unlocked_skins", unlocked_skins)
	cfg.set_value("eco", "selected_skins", selected_skins)
	cfg.set_value("eco", "trial_char", trial_char)
	cfg.set_value("eco", "ad_free", ad_free)
	cfg.set_value("eco", "last_daily_date", last_daily_date)
	cfg.set_value("eco", "total_matches", total_matches)
	cfg.set_value("eco", "matches_since_interstitial", matches_since_interstitial)
	cfg.save(GameConfig.SAVE_PATH)


func claim_daily_bonus() -> int:
	var d: Dictionary = Time.get_date_dict_from_system()
	var today: String = "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
	if last_daily_date != today:
		last_daily_date = today
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
	return unlocked_chars.has(char_id) or trial_char == char_id


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


func consume_trial() -> void:
	if not trial_char.is_empty():
		trial_char = ""
		save_data()


func unlock_skin_with_kirinti(skin_key: String) -> bool:
	if unlocked_skins.has(skin_key):
		return true
	if not spend_kirinti(GameConfig.SKIN_COST):
		return false
	unlocked_skins.append(skin_key)
	save_data()
	return true


## Sahte veya gerçek ödüllü reklam akışı (otomatik açılmaz, sadece kullanıcı basınca).
func show_rewarded_ad(on_done: Callable) -> void:
	# Editör / masaüstü sahte servis: kısa bekleme sonrası ödül verir
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

class_name GameConfig
extends RefCounted

## Tüm oyun sabitleri ve deterministik dünya formülleri.

const DEBUG: bool = true

# Ekran ve dünya boyutları
const VIEWPORT_WIDTH: float = 720.0
const VIEWPORT_HEIGHT: float = 1280.0
const CEILING_Y: float = 0.0
const COUNTER_STRIP_HEIGHT: float = 104.0
const FLOOR_Y: float = VIEWPORT_HEIGHT - COUNTER_STRIP_HEIGHT
const FLOOR_DEATH_MARGIN: float = 180.0

# Görsel renk paleti (yumuşak pastel tonlar)
const COLOR_CREAM: Color = Color("#F6EFE4")
const COLOR_PEACH: Color = Color("#F2C9A9")
const COLOR_SAGE: Color = Color("#B8CDB0")
const COLOR_DUST_BLUE: Color = Color("#A9BCD0")
const COLOR_DUST_PINK: Color = Color("#E8B4BC")
const COLOR_BROWN: Color = Color("#7A5C4B")
const COLOR_WARN_RED: Color = Color("#D9605A")
const COLOR_DARK_TEXT: Color = Color("#3D3530")
const COLOR_DEAD_GRAY: Color = Color(0.55, 0.55, 0.55, 1.0)

# UI stil sabitleri
const UI_CORNER_RADIUS: int = 20
const UI_BORDER_WIDTH: int = 3
const UI_SHADOW_OFFSET: Vector2 = Vector2(0.0, 4.0)
const UI_SHADOW_SIZE: int = 6
const UI_FONT_TITLE: int = 56
const UI_FONT_BODY: int = 30
const UI_FONT_SMALL: int = 22
const BUTTON_PRESS_SCALE: float = 0.95
const BUTTON_PRESS_DURATION: float = 0.08
const MAX_NAME_LENGTH: int = 12
const SETTINGS_PATH: String = "user://settings.cfg"

# Oyuncu fiziği
const PLAYER_X: float = 200.0
const PLAYER_START_Y: float = 580.0
const PLAYER_SPRITE_SIZE: Vector2i = Vector2i(128, 128)
const PLAYER_VISUAL_SCALE: float = 1.60
const PLAYER_HITBOX_RADIUS: float = 30.0
const GRAVITY: float = 1900.0
const FLAP_VELOCITY: float = -640.0
const MAX_FALL_SPEED: float = 950.0
const ROT_UP_DEG: float = -25.0
const ROT_DOWN_DEG: float = 70.0
const ROT_LERP_SPEED: float = 10.0
const FLAP_SQUASH_SCALE: Vector2 = Vector2(1.1, 0.9)
const FLAP_SQUASH_DURATION: float = 0.12

# Çarpışma katmanları
const LAYER_PLAYER: int = 1
const LAYER_SLIPPER: int = 2
const LAYER_MISSILE: int = 4

# Faz 9A: Animasyon, ekran uyumu ve kontrol sabitleri
const BODY_TILT_MAX: float = 0.0
const PLAY_HEIGHT: float = 1100.0
const SWIPE_THRESHOLD_PX: float = 70.0
const SWIPE_MAX_MS: int = 250
const SWIPE_CANCELS_FLAP: bool = false
const ABILITY_BUFFER_SEC: float = 0.2
const TEST_RESOLUTIONS: Array[Vector2i] = [
	Vector2i(720, 1280),
	Vector2i(720, 1560),
	Vector2i(720, 1600),
	Vector2i(720, 1680),
	Vector2i(960, 1280),
]

# Deterministik dünya ve engel zaman çizelgesi
const TIMELINE_DURATION_SEC: float = 900.0
const BASE_SPEED: float = 260.0
const MAX_SPEED: float = 520.0
const SPEED_ACCEL: float = 4.0
const FIRST_OBSTACLE_DIST: float = 720.0
const OBSTACLE_SPACING: float = 420.0
const GAP_START: float = 320.0
const GAP_MIN: float = 235.0
const GAP_SHRINK_PER_SEC: float = 0.45
const GAP_MIN_Y: float = 230.0
const GAP_MAX_Y: float = 820.0
const GAP_MAX_DELTA_Y: float = 380.0
const SPAWN_AHEAD_PX: float = 200.0
const DESPAWN_BEHIND_PX: float = 200.0

# Terlik boyutları
const SLIPPER_SIZE: Vector2i = Vector2i(120, 600)
const SLIPPER_HITBOX_WIDTH_RATIO: float = 0.9
const BG_SIZE: Vector2i = Vector2i(720, 1280)
const BG_PARALLAX_RATIO: float = 0.3

# Geri sayım ve ölüm efektleri
const COUNTDOWN_STEP_SEC: float = 0.6
const COUNTDOWN_FLOAT_AMP: float = 14.0
const COUNTDOWN_FLOAT_SPEED: float = 4.0
const DEATH_SHAKE_DURATION: float = 0.25
const DEATH_SHAKE_STRENGTH: float = 14.0
const DEATH_SPIN_SPEED: float = 10.0
const DEATH_PANEL_DELAY: float = 0.55

# Varsayılan varlık yolları
const BG_TEXTURE_PATH: String = "res://assets/sprites/bg_mutfak.png"
const CHAR_KLASIK_PATH: String = "res://assets/sprites/char_klasik.png"
const SLIPPER_TOP_PATH: String = "res://assets/sprites/terlik_ust.png"
const SLIPPER_BOTTOM_PATH: String = "res://assets/sprites/terlik_alt.png"

const BG_THEMES: Array[Dictionary] = [
	{"id": "mutfak", "name": "Mutfak", "path": "res://assets/sprites/bg_mutfak.png", "kind": "bg_mutfak"},
	{"id": "pavyon", "name": "Pavyon", "path": "res://assets/sprites/bg_pavyon.png", "kind": "bg_salon"},
	{"id": "banyo", "name": "Banyo", "path": "res://assets/sprites/bg_banyo.png", "kind": "bg_banyo"},
	{"id": "sokak", "name": "Gece Sokağı", "path": "res://assets/sprites/bg_sokak.png", "kind": "bg_gece"},
]


## Arka plan kimliğine göre tema sözlüğünü döner.
static func get_bg_theme(bg_id: String) -> Dictionary:
	for theme: Dictionary in BG_THEMES:
		if str(theme["id"]) == bg_id:
			return theme
	return BG_THEMES[0]

# Faz 2: Yetenek ve balon sabitleri
const KLASIK_BRAKE_GRAVITY_MULT: float = 0.2
const DUKTUR_SHRINK_SCALE: float = 0.5
const DUKTUR_SHRINK_GRAVITY_MULT: float = 0.7
const DUKTUR_TWEEN_SEC: float = 0.15
const DUKTUR_POST_INVULN_SEC: float = 0.3
const HALAY_GHOST_ALPHA: float = 0.55
const HALAY_GHOST_TINT: Color = Color(1.0, 0.76, 0.45, 0.55)
const HALAY_JITTER_PX: float = 4.0
const HALAY_CONFETTI_DURATION: float = 1.5
const HALAY_CONFETTI_STRIP_WIDTH: float = 110.0
const SHATTER_DURATION: float = 0.3
const SPEECH_ABILITY_DURATION: float = 1.5
const ABILITY_BTN_SIZE: float = 94.0
const ABILITY_BTN_MARGIN: float = 32.0

# Faz 3: Karanlık evre ve füze yağmuru sabitleri
const DARK_FIRST_TIME: float = 20.0
const DARK_INTERVAL: float = 25.0
const DARK_DURATION: float = 6.0
const DARK_SLIPPER_PAD_SEC: float = 1.0
const DARK_TWEEN_SEC: float = 0.8
const DARK_MODULATE_COLOR: Color = Color(0.16, 0.16, 0.24, 1.0)
const DARK_BANNER_TEXT: String = "İKİ GÖZÜM ŞURALARI BİR AYDINLAT HELE!"
const DARK_BANNER_DURATION: float = 1.5
const MISSILE_SPEED: float = 650.0
const MISSILE_WARN_LEAD_SEC: float = 0.9
const MISSILE_MIN_GAP_SEC: float = 0.55
const MISSILE_MAX_GAP_SEC: float = 0.82
const MISSILE_MAX_ACTIVE: int = 3
const MISSILE_SIZE: Vector2i = Vector2i(96, 48)
const MISSILE_TEX_PATH: String = "res://assets/sprites/fuze.png"
const MISSILE_SPAWN_X_MIN: float = 380.0
const MISSILE_SPAWN_X_MAX: float = 820.0
const MISSILE_SPAWN_Y: float = -80.0
const MISSILE_ANGLE_MIN_DEG: float = 45.0
const MISSILE_ANGLE_MAX_DEG: float = 60.0

# Faz 4: Çok oyunculu ağ ve yeni engel sabitleri
const NET_PORT: int = 7777
const DISCOVERY_PORT: int = 7778
const MATCHMAKER_PORT: int = 7700
const ROOM_PORT_MIN: int = 7801
const ROOM_PORT_MAX: int = 7850
const DEFAULT_SERVER_HOST: String = "127.0.0.1"
const SAVE_PATH: String = "user://save.cfg"
const KIRINTI_DAILY_BONUS: int = 25
const KIRINTI_RANK_BONUS: Array[int] = [30, 20, 12, 6, 3]
const SKIN_COST: int = 600
const PRODUCT_IDS: Array[String] = ["paket_bocekler", "kirinti_kesesi_kucuk", "kirinti_kesesi_buyuk", "reklamsiz"]
const SHARE_SITE_URL: String = "https://aykut.github.io/hamam-bocegi"
const ANDROID_PACKAGE_NAME: String = "com.aykut.ucanhamambocegi"
const SHARE_TEXT_KING: String = "Mahallenin Kralı oldum! {n} kişiyi sandalyeye çıkardım. Sıra sende: {link}"
const SHARE_TEXT_SOLO: String = "Uçan Hamam Böceği'nde {skor} puan yaptım! Sen kaç geçersin? {link}"
# Yayından önce gerçek AdMob kimlikleriyle doldur (şu an Google test kimlikleri)
const ADMOB_APP_ID: String = "ca-app-pub-3940256099942544~3347511713"
const REWARDED_ID: String = "ca-app-pub-3940256099942544/5224354917"
const INTERSTITIAL_ID: String = "ca-app-pub-3940256099942544/1033173712"

const BANNED_NAME_WORDS: Array[String] = ["admin", "server", "mod", "amk", "sik", "göt", "piç"]
const NET_MAX_CLIENTS: int = 4
const NET_VERSION: int = 1
const NET_CONNECT_TIMEOUT_SEC: float = 6.0
const NET_STATE_SYNC_HZ: float = 20.0
const NET_STATE_LERP_SPEED: float = 16.0
const REMOTE_PLAYER_ALPHA: float = 0.4
const WINNER_WAIT_BTN_SEC: float = 4.0
const ANNE_ELI_BOB_AMP: float = 24.0
const ANNE_ELI_BOB_SPEED: float = 2.4
const CLOSE_SCARE_DIST_PX: float = 115.0
const CLOSE_SCARE_EDGE_PX: float = 18.0
const SPRAY_SLOW_DURATION: float = 1.0
const SPRAY_SLOW_MULT: float = 0.65

# Faz 6: Seviye, kombo, güçlendirme ve komik ölüm sabitleri
const SPEED_PROFILE_STEP: float = 0.05
const SPEED_TRANSITION_SEC: float = 2.0
const LEVEL_BREATH_PAIRS: int = 2
const LEVEL_BREATH_GAP_BONUS: float = 30.0

const LEVELS: Array[Dictionary] = [
	{"level": 1, "name": "Mutfak Turu", "start_pairs": 0, "speed": 230.0, "gap": 360.0, "bob_amp": 0.0, "surprise_chance": 0.0, "missiles": 0},
	{"level": 2, "name": "Salon Paniği", "start_pairs": 10, "speed": 260.0, "gap": 335.0, "bob_amp": 10.0, "surprise_chance": 0.08, "missiles": 0},
	{"level": 3, "name": "Anne Uyandı", "start_pairs": 22, "speed": 295.0, "gap": 315.0, "bob_amp": 20.0, "surprise_chance": 0.14, "missiles": 5},
	{"level": 4, "name": "Komşular Toplandı", "start_pairs": 36, "speed": 330.0, "gap": 295.0, "bob_amp": 30.0, "surprise_chance": 0.20, "missiles": 6},
	{"level": 5, "name": "Belediye İlaçlıyor", "start_pairs": 52, "speed": 370.0, "gap": 275.0, "bob_amp": 45.0, "surprise_chance": 0.26, "missiles": 7},
	{"level": 6, "name": "Efsane Böcek", "start_pairs": 72, "speed": 410.0, "gap": 260.0, "bob_amp": 55.0, "surprise_chance": 0.32, "missiles": 8},
]

const WARMUP_PAIR_COUNT: int = 5
const WARMUP_GAP_BONUS: float = 40.0
const SOPALI_GAP_MIN: float = 240.0
const SURPRISE_MIN_NORMAL_BETWEEN: int = 3
const SURPRISE_INTRO_TEXTS: Dictionary = {
	"sprey": "YENİ: Böcek İlacı Bulutu! Sis bulutuna girme, yavaşlatır.",
	"dolap": "YENİ: Açılan Dolap Kapağı! Kapak açılmadan aralığı yakala.",
	"firlayan_terlik": "YENİ: Fırlayan Terlik! Uyarıyı görünce yön değiştir.",
	"sopa": "YENİ: Süpürge Sapı! Altından ya da üstünden geç.",
}

const VICTORY_LAP_DURATION: float = 15.0
const RANK_POINTS: Array[int] = [5, 3, 2, 1, 0]
const SHRINK_TWEEN_SEC: float = 0.15
const SHRINK_UNGROW_INVULN: float = 0.3
const DEATH_MUSIC_MAX: float = 6.0

const CENSOR_MAP: Dictionary = {
	"amk": "a**",
	"piçiz": "p****",
	"piç": "p**",
	"gahpe": "g****",
	"kahpe": "k****",
	"oçuz": "o***",
	"oç": "o*",
	"göt": "g**",
	"sik": "s**",
}

const LEVEL_SUBTITLES: Array[String] = [
	"Terlikler bilendi.",
	"Mahallede söylenti yayıldı.",
	"Biri 'Ayyy!' dedi.",
	"Böcek ilacı stokları tükeniyor.",
	"Bu böcek ruhsatlı mı?",
]

const LEVEL_BG_TINTS: Array[Color] = [
	Color(1.0, 1.0, 1.0, 1.0),
	Color(1.0, 0.94, 0.88, 1.0),
	Color(1.0, 0.90, 0.92, 1.0),
	Color(0.90, 0.95, 1.0, 1.0),
	Color(0.90, 0.98, 0.92, 1.0),
	Color(0.96, 0.90, 1.0, 1.0),
]

const COMBO_TITLES: Array[Dictionary] = [
	{"min": 12, "title": "BELEDİYE SENİ ARIYOR"},
	{"min": 8, "title": "Mahallenin Korkulu Rüyası"},
	{"min": 5, "title": "Böcek Lord"},
	{"min": 3, "title": "Kanatlar ısındı"},
	{"min": 2, "title": "Fena değil"},
]

const POWERUP_SLOTS: int = 3
const POWERUP_SLOT_SIZE: float = 74.0
const POWERUP_GLOBAL_COOLDOWN: float = 1.5
const POWERUP_SPAWN_MIN_STEP: int = 5
const POWERUP_SPAWN_MAX_STEP: int = 7
const POWERUP_FREEZE_DURATION: float = 3.5
const POWERUP_FREEZE_GAP_MULT: float = 1.15
const POWERUP_TURBO_DURATION: float = 2.0
const POWERUP_TURBO_TARGET_X: float = 330.0
const POWERUP_SPARE_LEG_INVULN: float = 1.0
const POWERUP_MAGNET_DURATION: float = 8.0
const POWERUP_MAGNET_RADIUS: float = 220.0

const POWERUP_DEFS: Dictionary = {
	"dondurma": {
		"id": "dondurma",
		"name": "Dondurma",
		"short_name": "Dondurma",
		"letter": "D",
		"color": Color("#8BD3E6"),
		"icon_path": "res://assets/sprites/item_dondurma.png",
		"duration": 3.5,
		"quote": "Beyin dondu ama değdi.",
	},
	"turbo": {
		"id": "turbo",
		"name": "Turbo Kanat",
		"short_name": "Turbo",
		"letter": "T",
		"color": Color("#F5B041"),
		"icon_path": "res://assets/sprites/item_turbo.png",
		"duration": 2.0,
		"quote": "Fren tutmuyooor!",
	},
	"yedek_bacak": {
		"id": "yedek_bacak",
		"name": "Yedek Bacak",
		"short_name": "Bacak",
		"letter": "B",
		"color": Color("#B8CDB0"),
		"icon_path": "res://assets/sprites/item_yedek_bacak.png",
		"duration": 0.0,
		"quote": "Altı tane var zaten.",
	},
	"miknatis": {
		"id": "miknatis",
		"name": "Kırıntı Mıknatısı",
		"short_name": "Mıknatıs",
		"letter": "M",
		"color": Color("#E8B4BC"),
		"icon_path": "res://assets/sprites/item_miknatis.png",
		"duration": 8.0,
		"quote": "Kırıntılar bana gelsin!",
	},
	"ozel_yetenek": {
		"id": "ozel_yetenek",
		"name": "Tavşan Kanı",
		"short_name": "Çay",
		"letter": "Ç",
		"color": Color("#D97A54"),
		"icon_path": "res://assets/sprites/item_tavsan_kani.png",
		"duration": 0.0,
		"quote": "Tavşan kanı gibi oldu!",
	},
}

const POWERUP_WEIGHTS_EARLY: Array[Dictionary] = [
	{"id": "dondurma", "weight": 35},
	{"id": "miknatis", "weight": 35},
	{"id": "ozel_yetenek", "weight": 15},
	{"id": "turbo", "weight": 10},
	{"id": "yedek_bacak", "weight": 5},
]

const POWERUP_WEIGHTS_MID: Array[Dictionary] = [
	{"id": "dondurma", "weight": 25},
	{"id": "miknatis", "weight": 20},
	{"id": "ozel_yetenek", "weight": 20},
	{"id": "turbo", "weight": 20},
	{"id": "yedek_bacak", "weight": 15},
]

const POWERUP_WEIGHTS_LATE: Array[Dictionary] = [
	{"id": "turbo", "weight": 30},
	{"id": "yedek_bacak", "weight": 25},
	{"id": "dondurma", "weight": 20},
	{"id": "ozel_yetenek", "weight": 15},
	{"id": "miknatis", "weight": 10},
]

const DEATH_CAUSE_LINES: Dictionary = {
	"ust_engel": [
		"{isim} annenin terliğine kafa attı.",
		"{isim} terliğin altını öptü.",
	],
	"alt_engel": [
		"{isim} sandalyedeki amcanın çorabına daldı.",
		"{isim} çığlık atan teyzeye tosladı.",
	],
	"surpriz": [
		"{isim} süpürge sapına takıldı.",
		"{isim} mutfak kazasına kurban gitti.",
	],
	"fuze": [
		"{isim} aydınlandı. Hem de çok.",
		"{isim} füze ile yakın temas kurdu.",
	],
	"zemin": [
		"{isim} tezgâha yapıştı.",
		"{isim} mutfak mermerini test etti.",
	],
	"tavan": [
		"{isim} tavanda lambayla tanıştı.",
		"{isim} avizeye kafa attı.",
	],
	"hayalet_terlik": [
		"{isim}, intikam terliğine kurban gitti.",
	],
}


## Verilen seviye numarasına (1+) göre seviye ayar sözlüğünü döner.
static func get_level_config(level_num: int) -> Dictionary:
	var lv: int = maxi(level_num, 1)
	if lv <= LEVELS.size():
		return LEVELS[lv - 1]
	var extra: int = lv - LEVELS.size()
	return {
		"level": lv,
		"name": "Efsane Böcek +%d" % extra,
		"start_pairs": 72 + extra * 20,
		"speed": minf(410.0 + float(extra) * 15.0, 520.0),
		"gap": maxf(260.0 - float(extra) * 5.0, 235.0),
		"bob_amp": minf(55.0 + float(extra) * 5.0, 80.0),
		"surprise_chance": minf(0.32 + float(extra) * 0.03, 0.50),
		"missiles": 9,
	}


## Geçilen engel çifti sayısına göre mevcut seviye numarasını (1+) döner.
static func level_for_passed_pairs(passed_pairs: int) -> int:
	var lv: int = 1
	for i: int in range(LEVELS.size()):
		if passed_pairs >= int(LEVELS[i]["start_pairs"]):
			lv = int(LEVELS[i]["level"])
		else:
			return lv
	if passed_pairs >= 92:
		lv = 7 + int((passed_pairs - 92) / 20)
	return lv


## Verilen ölüm sebebine göre komik bir ölüm mesajı döner (görsel RNG).
static func get_random_death_cause_line(cause: String, player_name: String) -> String:
	var pool: Array = DEATH_CAUSE_LINES.get(cause, ["{isim} talihsiz bir kaza geçirdi."]) as Array
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	var tmpl: String = str(pool[rng.randi_range(0, pool.size() - 1)])
	return tmpl.replace("{isim}", player_name)


## Kombo sayısına göre unvan metnini döner (yoksa boş string).
static func get_combo_title(combo_count: int) -> String:
	for entry: Dictionary in COMBO_TITLES:
		if combo_count >= int(entry["min"]):
			return str(entry["title"])
	return ""


# Faz 7: Çoklu oyunda sataşma, laf atma ve hayalet terlik sabitleri
const TAUNT_WARN_DELAY: float = 0.6
const TAUNT_IMMUNITY_SEC: float = 4.0
const TAUNT_TARGET_TIMEOUT: float = 2.0
const QUICK_CHAT_COOLDOWN: float = 3.0
const GHOST_SLIPPER_COOLDOWN: float = 8.0
const GHOST_SLIPPER_LEAD_SEC: float = 1.2
const GHOST_SLIPPER_SPEED: float = 520.0

const QUICK_CHAT_LINES: Array[String] = [
	"Uç bakalım uç!",
	"Terliği yedin mi?",
	"Annen çağırıyor!",
	"Bu ne hız ya?",
	"Hadi ordan böcek!",
	"Kahve ısmarlarım, yeter ki öl.",
]

const TAUNT_DEFS: Dictionary = {
	"buz_kalibi": {
		"id": "buz_kalibi",
		"name": "Buz Kalıbı",
		"short_name": "Buz",
		"letter": "K",
		"color": Color("#85C1E9"),
		"icon_path": "res://assets/sprites/item_buz_kalibi.png",
		"duration": 2.5,
		"is_taunt": true,
		"is_self": false,
	},
	"turk_kahvesi": {
		"id": "turk_kahvesi",
		"name": "Türk Kahvesi",
		"short_name": "Kahve",
		"letter": "H",
		"color": Color("#A07855"),
		"icon_path": "res://assets/sprites/item_turk_kahvesi.png",
		"duration": 3.0,
		"is_taunt": true,
		"is_self": false,
	},
	"kirli_corap": {
		"id": "kirli_corap",
		"name": "Kirli Çorap",
		"short_name": "Çorap",
		"letter": "R",
		"color": Color("#9BB87A"),
		"icon_path": "res://assets/sprites/item_kirli_corap.png",
		"duration": 2.5,
		"is_taunt": true,
		"is_self": false,
	},
	"komsu_teyze": {
		"id": "komsu_teyze",
		"name": "Komşu Teyze",
		"short_name": "Teyze",
		"letter": "Y",
		"color": Color("#E6A5B8"),
		"icon_path": "res://assets/sprites/item_komsu_teyze.png",
		"duration": 1.5,
		"is_taunt": true,
		"is_self": false,
	},
	"ayna": {
		"id": "ayna",
		"name": "Ayna",
		"short_name": "Ayna",
		"letter": "A",
		"color": Color("#D5DBDB"),
		"icon_path": "res://assets/sprites/item_ayna.png",
		"duration": 10.0,
		"is_taunt": true,
		"is_self": true,
	},
}

const TAUNT_WEIGHTS_MULTIPLAYER: Array[Dictionary] = [
	{"id": "buz_kalibi", "weight": 22},
	{"id": "turk_kahvesi", "weight": 22},
	{"id": "kirli_corap", "weight": 22},
	{"id": "komsu_teyze", "weight": 20},
	{"id": "ayna", "weight": 14},
]


## Güçlendirme veya sataşma kimliğine göre tanım sözlüğünü döner.
static func get_item_def(item_id: String) -> Dictionary:
	if POWERUP_DEFS.has(item_id):
		return POWERUP_DEFS[item_id] as Dictionary
	if TAUNT_DEFS.has(item_id):
		return TAUNT_DEFS[item_id] as Dictionary
	return {}


## t anındaki dünya kaydırma hızını döner (px/s).
static func speed_at(t: float) -> float:
	if t <= 0.0:
		return BASE_SPEED
	return minf(BASE_SPEED + SPEED_ACCEL * t, MAX_SPEED)


## 0..t arasında kat edilen toplam mesafeyi kapalı formülle hesaplar.
static func distance_at(t: float) -> float:
	if t <= 0.0:
		return 0.0
	var t_max: float = (MAX_SPEED - BASE_SPEED) / SPEED_ACCEL
	if t <= t_max:
		return BASE_SPEED * t + 0.5 * SPEED_ACCEL * t * t
	var accel_dist: float = BASE_SPEED * t_max + 0.5 * SPEED_ACCEL * t_max * t_max
	return accel_dist + MAX_SPEED * (t - t_max)


## t anındaki terlik aralığı (gap) yüksekliğini döner.
static func gap_at(t: float) -> float:
	if t <= 0.0:
		return GAP_START
	return maxf(GAP_START - GAP_SHRINK_PER_SEC * t, GAP_MIN)


## Verilen mesafe için yaklaşık maç süresini döner (timeline üretimi için).
static func time_for_distance(dist: float) -> float:
	if dist <= 0.0:
		return 0.0
	var t_max: float = (MAX_SPEED - BASE_SPEED) / SPEED_ACCEL
	var accel_dist: float = BASE_SPEED * t_max + 0.5 * SPEED_ACCEL * t_max * t_max
	if dist <= accel_dist:
		var disc: float = BASE_SPEED * BASE_SPEED + 2.0 * SPEED_ACCEL * dist
		return (-BASE_SPEED + sqrt(disc)) / SPEED_ACCEL
	return t_max + (dist - accel_dist) / MAX_SPEED


## Argo sansürü açıksa metindeki argo kelimeleri ilk harfi kalacak şekilde yıldızlar.
static func censor(text: String) -> String:
	if not AudioManager.is_censor_enabled:
		return text
	var out: String = text
	for word_key: String in CENSOR_MAP.keys():
		var rep: String = str(CENSOR_MAP[word_key])
		var rx: RegEx = RegEx.new()
		rx.compile("(?i)\\b" + word_key + "\\b")
		out = rx.sub(out, rep, true)
	return out

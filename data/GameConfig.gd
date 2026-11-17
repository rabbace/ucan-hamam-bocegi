class_name GameConfig
extends RefCounted

## Tüm oyun sabitleri ve deterministik dünya formülleri.

## Yalnızca editörden çalıştırılınca açık (seed etiketi, F9, tek kişilik LAN maçı).
## Dışa aktarılmış hiçbir sürümde (debug APK dahil) açık kalmaz.
static var DEBUG: bool = OS.has_feature("editor")

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
# Yazı ölçeği (720 px taban genişlik). 360 dp'lik telefonda 1 birim ≈ 0.5 dp olduğundan
# okunabilir alt sınır 18'dir; bu ölçeğin dışında yazı boyutu kullanılmaz.
const FS_TINY: int = 18     # rozet, numara, küçük etiket
const FS_SMALL: int = 21    # ikincil açıklama, alt yazı
const FS_BODY: int = 24     # gövde metni, liste satırı
const FS_BUTTON: int = 26   # standart buton
const FS_H2: int = 32       # pencere başlığı
const FS_H1: int = 44       # büyük duyuru / banner
const FS_HERO: int = 64     # skor, geri sayım
# Boşluk ölçeği (8'in katları)
const SP_XS: int = 8
const SP_S: int = 12
const SP_M: int = 16
const SP_L: int = 24
const SP_XL: int = 32
# Ekran kenar boşluğu (güvenli alanın üstüne eklenir)
const SCREEN_GUTTER: float = 16.0
# Modal genişliği: ekranın en fazla bu kadarı; tablette fazla yayılmasın diye üst sınır
const MODAL_MAX_WIDTH: float = 640.0
const MODAL_SIDE_MARGIN: float = 24.0
const COLOR_INK: Color = Color("#24160E")
const COLOR_GOLD: Color = Color("#F2C96B")
const COLOR_GREEN_GO: Color = Color("#8FD17C")
const COLOR_BADGE_RED: Color = Color("#D9483F")
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
## Üst engel kutusu tavanın bu kadar üstüne uzar; alt engel kutusu zemin ölüm çizgisine kadar iner.
const SLIPPER_EXTEND_PX: float = 400.0
## Alt engelde kafanın üstündeki saç/ter damlası payı (çarpışma kutusu biraz içeriden başlar).
const SLIPPER_HEAD_INSET_PX: float = 8.0
const PEDESTAL_COLOR: Color = Color("#8A5A3B")
const PEDESTAL_LINE_COLOR: Color = Color("#6B4229")
## Kaide çizimi zeminin bu kadar altına iner (uzun ekranlarda havada kalmasın).
const PEDESTAL_DRAW_BELOW_FLOOR: float = 600.0
## Fırlayan terliğin dönüş hızı (rad/sn; eski 0.14 rad/kare x 60).
const FLYING_SLIPPER_SPIN: float = 8.4
## Tek karede dünyanın ilerleyebileceği en uzun süre (arka plandan dönüş sıçramasını keser).
const MAX_FRAME_DELTA: float = 0.1
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
	{"id": "kahvehane", "name": "Kahvehane", "path": "res://assets/sprites/bg_kahvehane.png", "kind": "bg_mutfak"},
	{"id": "otobus", "name": "Belediye Otobüsü", "path": "res://assets/sprites/bg_otobus.png", "kind": "bg_salon"},
	{"id": "sanayi", "name": "Oto Sanayi", "path": "res://assets/sprites/bg_sanayi.png", "kind": "bg_gece"},
	{"id": "dugun", "name": "Kır Düğünü", "path": "res://assets/sprites/bg_dugun.png", "kind": "bg_salon"},
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
const NET_VERSION: int = 3
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
		"color": Color("#8BD3E6"),
		"icon_path": "res://assets/sprites/items/dondurma.png",
		"duration": 3.5,
		"quote": "Beyin dondu ama değdi.",
	},
	"turbo": {
		"id": "turbo",
		"name": "Turbo Kanat",
		"short_name": "Turbo",
		"color": Color("#F5B041"),
		"icon_path": "res://assets/sprites/items/turbo.png",
		"duration": 2.0,
		"quote": "Bas bas kökle amk kökleeee",
	},
	"yedek_bacak": {
		"id": "yedek_bacak",
		"name": "Yedek Bacak",
		"short_name": "Bacak",
		"color": Color("#B8CDB0"),
		"icon_path": "res://assets/sprites/items/yedek_bacak.png",
		"duration": 0.0,
		"quote": "Altı tane var zaten.",
	},
	"miknatis": {
		"id": "miknatis",
		"name": "Kırıntı Mıknatısı",
		"short_name": "Mıknatıs",
		"color": Color("#E8B4BC"),
		"icon_path": "res://assets/sprites/items/miknatis.png",
		"duration": 8.0,
		"quote": "Kırıntılar bana gelsin!",
	},
	"ozel_yetenek": {
		"id": "ozel_yetenek",
		"name": "Kum Saati",
		"short_name": "Kum Saati",
		"color": Color("#D97A54"),
		"icon_path": "res://assets/sprites/items/ozel_yetenek.png",
		"duration": 0.0,
		"quote": "Kum saati döndü, yetenek hazır!",
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
	"terlik": [
		"{isim} uçan terliği göremedi, terlik onu gördü.",
		"{isim} havadan gelen terliğe yakalandı.",
	],
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
		"color": Color("#85C1E9"),
		"icon_path": "res://assets/sprites/items/buz_kalibi.png",
		"duration": 2.5,
		"is_taunt": true,
		"is_self": false,
	},
	"turk_kahvesi": {
		"id": "turk_kahvesi",
		"name": "Şeker Bombası",
		"short_name": "Şeker",
		"color": Color("#E8B4BC"),
		"icon_path": "res://assets/sprites/items/turk_kahvesi.png",
		"duration": 3.0,
		"is_taunt": true,
		"is_self": false,
	},
	"kirli_corap": {
		"id": "kirli_corap",
		"name": "Kirli Çorap",
		"short_name": "Çorap",
		"color": Color("#9BB87A"),
		"icon_path": "res://assets/sprites/items/kirli_corap.png",
		"duration": 2.5,
		"is_taunt": true,
		"is_self": false,
	},
	"komsu_teyze": {
		"id": "komsu_teyze",
		"name": "Komşu Teyze",
		"short_name": "Teyze",
		"color": Color("#E6A5B8"),
		"icon_path": "res://assets/sprites/items/komsu_teyze.png",
		"duration": 1.5,
		"is_taunt": true,
		"is_self": false,
	},
	"ayna": {
		"id": "ayna",
		"name": "Ayna",
		"short_name": "Ayna",
		"color": Color("#D5DBDB"),
		"icon_path": "res://assets/sprites/items/ayna.png",
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


## Faz 10.2: Karaktere özel imza ödülleri. Kutuların bu oranı "gizemli kutu"dur;
## içeriği toplayan oyuncunun karakterine göre açılır.
const SIGNATURE_DROP_RATE: float = 0.30
const MYSTERY_ITEM_ID: String = "gizemli"
const MYSTERY_DEF: Dictionary = {
	"id": "gizemli",
	"name": "Gizemli Kutu",
	"short_name": "Sürpriz",
	"color": Color("#E8B4BC"),
	"icon_path": "res://assets/sprites/items/gizemli.png",
	"duration": 0.0,
}

const CHAR_SIGNATURE: Dictionary = {
	"klasik": "bayat_ekmek",
	"diva": "ruj_tazeleme",
	"duktur": "asi",
	"halaybasi": "davul",
	"plaza": "filtre_kahve",
	"usta": "ingiliz_anahtari",
	"emlakci": "yedek_anahtar",
	"siber": "pil",
	"yurt": "gece_eristesi",
	"dayi": "demlik_cay",
	"taraftar": "top",
	"saftirik": "balon",
	"deli": "aci_biber",
}

# Süreler ve oranlar
const SIG_BREAD_DURATION: float = 5.0
const SIG_BREAD_HITBOX_MULT: float = 0.85
const SIG_LIPSTICK_SHIELD_BONUS: float = 1.0
const SIG_VACCINE_DURATION: float = 8.0
const SIG_DRUM_DURATION: float = 4.0
const SIG_DRUM_BOB_SPEED: float = 1.2
const SIG_COFFEE_DURATION: float = 6.0
const SIG_COFFEE_CD_MULT: float = 2.0
const SIG_KEY_DURATION: float = 5.0
const SIG_KEY_GAP_MULT: float = 1.25
const SIG_TEA_DURATION: float = 6.0
const SIG_TEA_SCARE_EXTRA_PX: float = 10.0
const SIG_PEPPER_DURATION: float = 4.0
const SIG_PEPPER_FLAP_MULT: float = 1.2
const SIG_PEPPER_FLAP_JITTER: float = 0.10
const SIG_BALLOON_DURATION: float = 3.0
const SIG_BALLOON_GRAVITY_MULT: float = 0.4

const SIGNATURE_DEFS: Dictionary = {
	"bayat_ekmek": {"id": "bayat_ekmek", "name": "Bayat Ekmek", "short_name": "Ekmek", "color": Color("#D9A066"), "icon_path": "res://assets/sprites/items/bayat_ekmek.png", "duration": 5.0, "is_signature": true, "owner": "klasik", "desc": "5 sn boyunca hitbox ayrıca %15 küçülür ve yakın kaçış puanı ikiye katlanır.", "quote": "Eski dost, eski ekmek."},
	"ruj_tazeleme": {"id": "ruj_tazeleme", "name": "Ruj Tazeleme", "short_name": "Ruj", "color": Color("#E8B4BC"), "icon_path": "res://assets/sprites/items/ruj_tazeleme.png", "duration": 0.0, "is_signature": true, "owner": "diva", "desc": "Kalkan bekleme süresini anında sıfırlar; bir sonraki kalkan 1 sn uzun sürer.", "quote": "Önce makyaj, sonra kaçış."},
	"asi": {"id": "asi", "name": "Aşı", "short_name": "Aşı", "color": Color("#A9D8EE"), "icon_path": "res://assets/sprites/items/asi.png", "duration": 8.0, "is_signature": true, "owner": "duktur", "desc": "8 sn boyunca tüm sataşmalara ve böcek ilacı bulutuna bağışıklık.", "quote": "Aşını oldun mu?"},
	"davul": {"id": "davul", "name": "Davul", "short_name": "Davul", "color": Color("#D9605A"), "icon_path": "res://assets/sprites/items/davul.png", "duration": 4.0, "is_signature": true, "owner": "halaybasi", "desc": "4 sn boyunca insan engelleri aynı ritimde, yavaş ve öngörülebilir sallanır. Rakiplere kısa konfeti.", "quote": "Davulcu geldi, halay başlasın!"},
	"filtre_kahve": {"id": "filtre_kahve", "name": "Filtre Kahve", "short_name": "Kahve", "color": Color("#A07855"), "icon_path": "res://assets/sprites/items/filtre_kahve.png", "duration": 6.0, "is_signature": true, "owner": "plaza", "desc": "6 sn boyunca iki yeteneğin bekleme süresi 2 kat hızlı dolar.", "quote": "Üçüncü kahve, toplantıya hazırım."},
	"ingiliz_anahtari": {"id": "ingiliz_anahtari", "name": "İngiliz Anahtarı", "short_name": "Anahtar", "color": Color("#9AA4AA"), "icon_path": "res://assets/sprites/items/ingiliz_anahtari.png", "duration": 0.0, "is_signature": true, "owner": "usta", "desc": "Önündeki ilk engel çiftini anında söker.", "quote": "Söktüm abi, hayırlı olsun."},
	"yedek_anahtar": {"id": "yedek_anahtar", "name": "Yedek Anahtar", "short_name": "Anahtar", "color": Color("#D4AC48"), "icon_path": "res://assets/sprites/items/yedek_anahtar.png", "duration": 5.0, "is_signature": true, "owner": "emlakci", "desc": "5 sn boyunca engellerin kapısı açılır: aralıklar %25 genişler.", "quote": "Anahtar teslim, buyrun."},
	"pil": {"id": "pil", "name": "Pil", "short_name": "Pil", "color": Color("#9BB87A"), "icon_path": "res://assets/sprites/items/pil.png", "duration": 0.0, "is_signature": true, "owner": "siber", "desc": "İki yeteneğin bekleme süresini anında doldurur.", "quote": "Şarj yüzde yüz."},
	"gece_eristesi": {"id": "gece_eristesi", "name": "Gece Eriştesi", "short_name": "Erişte", "color": Color("#F5D76E"), "icon_path": "res://assets/sprites/items/gece_eristesi.png", "duration": 0.0, "is_signature": true, "owner": "yurt", "desc": "Oda Arkadaşı'nı bekleme süresine bakmadan anında çağırır.", "quote": "Erişte kokusuna geldi."},
	"demlik_cay": {"id": "demlik_cay", "name": "Demlik Çay", "short_name": "Çay", "color": Color("#A9BCD0"), "icon_path": "res://assets/sprites/items/demlik_cay.png", "duration": 6.0, "is_signature": true, "owner": "dayi", "desc": "6 sn boyunca yakın kaçış mesafesi +10 px ve her yakın kaçışa +1 Kırıntı.", "quote": "Tavşan kanı, tam kıvamında."},
	"top": {"id": "top", "name": "Top", "short_name": "Top", "color": Color("#FAFAFA"), "icon_path": "res://assets/sprites/items/top.png", "duration": 0.0, "is_signature": true, "owner": "taraftar", "desc": "Frikik'i bekleme süresine bakmadan bir kez kullanır.", "quote": "Ver topu bana!"},
	"balon": {"id": "balon", "name": "Balon", "short_name": "Balon", "color": Color("#D9605A"), "icon_path": "res://assets/sprites/items/balon.png", "duration": 3.0, "is_signature": true, "owner": "saftirik", "desc": "3 sn boyunca balona tutunur: yerçekimi çok azalır, yavaşça süzülür.", "quote": "Balonla uçuyorum, bakın!"},
	"aci_biber": {"id": "aci_biber", "name": "Acı Biber", "short_name": "Biber", "color": Color("#D9605A"), "icon_path": "res://assets/sprites/items/aci_biber.png", "duration": 4.0, "is_signature": true, "owner": "deli", "desc": "4 sn kıpkırmızı olur, antenlerinden duman çıkar; zıplama gücü ×1.2 ve ilk çarptığı engeli yakıp geçer. Kontrol biraz çılgınlaşır.", "quote": "Acı mı? Ben acıyı yerim!"},
}


## Karakterin imza ödülü kimliğini döner (yoksa boş).
static func get_signature_for(char_id: String) -> String:
	return str(CHAR_SIGNATURE.get(char_id, ""))


## Güçlendirme, sataşma, imza ödülü veya gizemli kutu kimliğine göre tanım sözlüğünü döner.
static func get_item_def(item_id: String) -> Dictionary:
	if POWERUP_DEFS.has(item_id):
		return POWERUP_DEFS[item_id] as Dictionary
	if TAUNT_DEFS.has(item_id):
		return TAUNT_DEFS[item_id] as Dictionary
	if SIGNATURE_DEFS.has(item_id):
		return SIGNATURE_DEFS[item_id] as Dictionary
	if item_id == MYSTERY_ITEM_ID:
		return MYSTERY_DEF
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


# Ağ güvenliği
# ENet eş zaman aşımı (varsayılan ~30 sn yerine 5-8 sn)
const NET_PEER_TIMEOUT_LIMIT: int = 32
const NET_PEER_TIMEOUT_MIN_MS: int = 5000
const NET_PEER_TIMEOUT_MAX_MS: int = 8000
# Bağlanan eşin register_player göndermesi için süre
const NET_REGISTER_TIMEOUT_SEC: float = 5.0
# Ret mesajı ulaşsın diye bağlantıyı kesmeden önce bekleme
const NET_KICK_DELAY_SEC: float = 0.5
# Eş başına saniyedeki RPC sınırı ve atılma eşiği
const NET_RPC_RATE_PER_SEC: int = 30
const NET_RPC_KICK_PER_SEC: int = 120
# Herkes yüklenmezse geri sayımın yine de başlayacağı süre
const NET_LOAD_TIMEOUT_SEC: float = 15.0
# Geri sayım adım sayısı ("3", "2", "1", "UÇ!")
const NET_COUNTDOWN_STEP_COUNT: int = 4
# Skor tavanı için sunucu saatine eklenen tolerans
const NET_SCORE_TIME_TOLERANCE_SEC: float = 2.0
# Bu süreden yakın ölümler berabere sayılır
const NET_SIMULTANEOUS_DEATH_SEC: float = 0.05
# Zafer turu sunucu tarafında bu kadar ek süreyle kapanır
const NET_VICTORY_LAP_GRACE_SEC: float = 2.0
# Hayalet terlik atışından sonra öldürme bildiriminin geçerli olduğu süre
const NET_GHOST_KILL_WINDOW_SEC: float = 6.0
# Sataşma gönderimi: eş başına bekleme ve maç başına üst sınır
const NET_TAUNT_COOLDOWN_SEC: float = 3.0
const NET_TAUNT_MAX_PER_MATCH: int = 12
# Eşya efekti yayını için eş başına bekleme
const NET_ITEM_FX_COOLDOWN_SEC: float = 1.0
# Hızlı sohbet: sunucu tarafı en kısa aralık ve karakter repliği indeksi
const NET_QUICK_CHAT_MIN_INTERVAL_SEC: float = 2.5
const NET_QUICK_CHAT_CHAR_INDEX: int = 99
# Ölüm sebebi metni üst sınırı
const NET_CAUSE_MAX_LENGTH: int = 32

# Eşleştirici (Matchmaker) sınırları
const MM_LOCAL_HOST: String = "127.0.0.1"
const MM_MAX_CONNECTIONS: int = 64
const MM_MAX_CONNECTIONS_PER_IP: int = 4
const MM_IDLE_TIMEOUT_SEC: float = 5.0
const MM_READ_BUFFER_MAX: int = 4096
const MM_RATE_WINDOW_SEC: float = 60.0
const MM_ROOM_SPAWN_PER_MIN_PER_IP: int = 2
const MM_JOIN_CODE_PER_MIN_PER_IP: int = 10
const MM_MAX_ROOMS: int = 10
const MM_ROOM_STALE_SEC: float = 10.0
const MM_ROOM_BOOT_GRACE_SEC: float = 15.0

# Oda sunucusu (RoomServer) zamanlamaları
const ROOM_STATUS_INTERVAL_SEC: float = 2.0
const ROOM_EMPTY_SHUTDOWN_SEC: float = 60.0
const ROOM_QUICK_START_SEC: float = 15.0
const ROOM_MM_RECONNECT_MIN_SEC: float = 1.0
const ROOM_MM_RECONNECT_MAX_SEC: float = 16.0
const ROOM_MM_CONNECT_TIMEOUT_SEC: float = 5.0

# Faz 11.1: Bot oyuncular
## Bot isim havuzu (komik, dürüst: etiketin yanında "BOT" rozeti olur)
const BOT_NAMES: Array[String] = [
	"Komşu Remzi", "Kapıcı Böcek", "Lavabo Altı Ferit", "Bakkal Şükrü'nün Böceği", "Gece Vardiyası",
	"Kırıntı Avcısı", "Kalorifer Kaçkını", "Buzdolabı Arkası", "Çöp Kovası Sakini", "Teyze'nin Kâbusu",
]
const BOT_SKILLS: Array[String] = ["acemi", "mahalleli", "usta"]
const BOT_SKILL_NAMES: Dictionary = {"acemi": "Acemi", "mahalleli": "Mahalleli", "usta": "Usta"}
const BOT_DEFAULT_SKILL: String = "mahalleli"
## Seviye başına (1..6, sonrası son değer) engel çifti başına başarısızlık olasılığı
const BOT_FAIL_CHANCE: Dictionary = {
	"acemi": [0.05, 0.12, 0.30, 0.45, 0.60, 0.70],
	"mahalleli": [0.01, 0.03, 0.05, 0.09, 0.20, 0.35],
	"usta": [0.0, 0.005, 0.01, 0.025, 0.05, 0.08, 0.15],
}
## Oda başına en fazla bot ve Hızlı Oyun'da tamamlanacak toplam kişi
const BOT_MAX: int = 4
const BOT_QUICK_FILL_TO: int = 4
## Yeni oyuncu eşikleri: ilk N maçta botlar en geç bu seviyede ölür; ilk M maçta acemi
const BOT_NEWBIE_CAP_MATCHES: int = 3
const BOT_NEWBIE_CAP_LEVEL: int = 3
const BOT_NEWBIE_SKILL_MATCHES: int = 5
## Bot engele bu kadar px kala çarpar (ölüm anı)
const BOT_HIT_LEAD_PX: float = 40.0
## Engel çevresinde düz tutulan yol yarı genişliği ve aralık içi sapma payı
const BOT_PATH_HOLD_PX: float = 60.0
const BOT_GAP_MARGIN_PX: float = 55.0
const BOT_GAP_OFFSET_MAX: float = 0.7
const BOT_FLAP_AMP_PX: float = 10.0
const BOT_FLAP_HZ: float = 1.6
## Laf atma, görsel yetenek ve sataşma aralıkları (sn)
const BOT_CHAT_MIN_SEC: float = 9.0
const BOT_CHAT_MAX_SEC: float = 18.0
const BOT_ABILITY_MIN_SEC: float = 10.0
const BOT_ABILITY_MAX_SEC: float = 20.0
const BOT_TAUNT_FIRST_MIN_SEC: float = 12.0
const BOT_TAUNT_FIRST_MAX_SEC: float = 22.0
const BOT_TAUNT_MIN_GAP_SEC: float = 20.0
const BOT_TAUNT_EXTRA_MAX_SEC: float = 15.0
const BOT_TAUNT_ITEMS: Array[String] = ["buz_kalibi", "turk_kahvesi", "kirli_corap", "komsu_teyze"]
## Gerçek oyuncuların hepsi ölünce kalan botlar bu süre sonra önceden hesaplanmış zamanlarıyla sıralanır
const BOT_FINISH_AFTER_REAL_DEAD_SEC: float = 4.0
## Sunucu duyurusu yerel ölüm anından bu kadar erken gelirse bot yerelde planına göre ölür
const BOT_DEATH_SYNC_TOLERANCE_SEC: float = 0.5
## Kişisel istatistik: son kaç maçın seviyesi tutulur
const STATS_RECENT_MATCHES: int = 5

# Faz 11.2: Rövanş ve taht
const REMATCH_WAIT_SEC: float = 15.0
const REMATCH_START_DELAY_SEC: float = 2.0
const CROWN_MUHTAR_STREAK: int = 3
const REMATCH_STATE_OPEN: int = 0
const REMATCH_STATE_TIMEOUT: int = 1
const REMATCH_STATE_STARTING: int = 2
const REMATCH_STATE_CLOSED: int = 3
## Tek oyunculu hayalet (önceki deneme)
const GHOST_RUN_PATH: String = "user://son_deneme.dat"
const GHOST_RUN_STEP_SEC: float = 0.1
const GHOST_RUN_ALPHA: float = 0.55
const GHOST_RUN_MAX_SAMPLES: int = 9000


## Seviye ve beceriye göre bir engel çiftinde başarısız olma olasılığı.
static func bot_fail_chance(level_num: int, skill: String) -> float:
	var table: Array = BOT_FAIL_CHANCE.get(skill, BOT_FAIL_CHANCE[BOT_DEFAULT_SKILL]) as Array
	var idx: int = clampi(level_num - 1, 0, table.size() - 1)
	return float(table[idx])

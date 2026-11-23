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
## Duraklatmadan "Devam Et" sonrası geri sayım (kaçtan, adım süresi)
const RESUME_COUNTDOWN_FROM: int = 3
const RESUME_COUNTDOWN_STEP_SEC: float = 0.6
## Kaydırma listelerinde parmak bu kadar kaymadan kaydırma başlamaz (dokunuş buton basışı sayılır)
const TOUCH_SCROLL_DEADZONE_PX: int = 12
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
## Çevrimiçi özellikler (Hızlı Oyun, Özel Oda, Böcek Kimliği, Arkadaşlar, Hesabım). Sunucu alınana kadar kapalı;
## açmak için true yap, DEFAULT_SERVER_HOST'u sunucu adresine çevir ve TLS'yi kur (server/SUNUCU_KURULUM.md).
const ONLINE_ENABLED: bool = false
const ONLINE_SOON_TITLE: String = "Çevrimiçi mod yakında!"
const ONLINE_SOON_TEXT: String = "Uzaktaki kankalarla oynamak için mutfağı hazırlıyoruz. Şimdilik botlarla ya da aynı Wi-Fi'deki arkadaşlarınla oynayabilirsin."
const SAVE_PATH: String = "user://save.cfg"
const KIRINTI_DAILY_BONUS: int = 25
## Dirilme (yalnızca Tek Başına; Günün Mutfağı ve çok oyunculuda yok): kırıntıyla ya da ödüllü reklamla,
## maç başına en fazla REVIVE_MAX_PER_RUN kez, skor en az REVIVE_MIN_SCORE ise teklif edilir.
## Kıl payı geçişte "lülülü" en fazla bu aralıkla çalar (ses 1.5 sn); arada agucuk çalar.
const LULULU_COOLDOWN_SEC: float = 4.0
## Kıl payı "agucuk bugucuk" (4.7 sn) bekleme; arada kısa agucuk.wav çalar.
const AGUCUK_COOLDOWN_SEC: float = 10.0
## Füze iniş sesi (3.7 sn) en fazla bu aralıkla; yağmurdaki diğer füzelerde kısa ses.
const FUZE_INIS_COOLDOWN_SEC: float = 5.0

const REVIVE_COST_KIRINTI: int = 100
const REVIVE_MAX_PER_RUN: int = 1
const REVIVE_MIN_SCORE: int = 5
## Ölümden sonra teklif penceresi bu kadar bekleyip açılır; cevap verilmezse bu kadar sonra kapanır
const REVIVE_OFFER_DELAY: float = 0.9
const REVIVE_OFFER_SEC: float = 6.0
## Dirildikten sonra (3-2-1 bitince) dokunulmazlık süresi
const REVIVE_INVULN_SEC: float = 3.0
## Güvenli yükseklik: oyuncunun bu kadar gerisine kadar uzanan ilk terlik aralığının ortası
const REVIVE_BEHIND_PX: float = 60.0
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
const NET_VERSION: int = 9
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

## Zorluk (yalnızca Tek Başına; Günün Mutfağı ve çok oyunculu her zaman Normal).
## speed: kaydırma hızı, gap: terlik aralığı, bob: terlik salınımı, surprise: sürpriz engel olasılığı,
## missiles: karanlıktaki füze sayısı çarpanı; reward: kırıntı ödülü çarpanı.
const DIFFICULTY_EASY: String = "kolay"
const DIFFICULTY_NORMAL: String = "normal"
const DIFFICULTY_HARD: String = "zor"
const DIFFICULTY_ORDER: Array[String] = ["kolay", "normal", "zor"]
const DIFFICULTIES: Dictionary = {
	"kolay": {"name": "Kolay", "speed": 0.88, "gap": 1.15, "bob": 0.6, "surprise": 0.6, "missiles": 0.6, "reward": 1.0},
	"normal": {"name": "Normal", "speed": 1.0, "gap": 1.0, "bob": 1.0, "surprise": 1.0, "missiles": 1.0, "reward": 1.0},
	"zor": {"name": "Zor", "speed": 1.12, "gap": 0.9, "bob": 1.3, "surprise": 1.4, "missiles": 1.35, "reward": 1.25},
}
## Zorda aralık bundan dar olmaz (oyuncu hitbox'ı + pay)
const DIFFICULTY_GAP_FLOOR: float = 225.0


static func get_difficulty(id: String) -> Dictionary:
	return DIFFICULTIES.get(id, DIFFICULTIES[DIFFICULTY_NORMAL]) as Dictionary


## Seviye ayarını zorluğa göre ölçekler (Normal'de olduğu gibi döner).
static func get_level_config_for(level_num: int, difficulty: String) -> Dictionary:
	var base: Dictionary = get_level_config(level_num)
	if difficulty == DIFFICULTY_NORMAL or not DIFFICULTIES.has(difficulty):
		return base
	var d: Dictionary = DIFFICULTIES[difficulty] as Dictionary
	var out: Dictionary = base.duplicate()
	out["speed"] = float(base["speed"]) * float(d["speed"])
	out["gap"] = maxf(float(base["gap"]) * float(d["gap"]), minf(float(base["gap"]), DIFFICULTY_GAP_FLOOR))
	out["bob_amp"] = float(base["bob_amp"]) * float(d["bob"])
	out["surprise_chance"] = clampf(float(base["surprise_chance"]) * float(d["surprise"]), 0.0, 0.6)
	out["missiles"] = int(roundf(float(base["missiles"]) * float(d["missiles"])))
	return out


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
	"belediye": [
		"{isim} belediyenin sisine daldı.",
		"{isim} ilaçlamaya yakalandı.",
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
## Kimliksiz (kısa ömürlü) bağlantı üst sınırı; Mahalle oturumları ayrı sayılır (MM_MAX_SESSIONS)
const MM_MAX_CONNECTIONS: int = 128
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



# ---------------------------------------------------------------------------
# Faz 11.3: Ölüm Karesi (3 kareli çizgi roman)
# ---------------------------------------------------------------------------
## Halka tampon: her 0.25 sn'de 360x640 kare, son 8 kare (yalnızca bellekte)
const DEATH_CARD_CAPTURE_SEC: float = 0.25
const DEATH_CARD_CAPTURE_SLOW_SEC: float = 0.5
const DEATH_CARD_FRAME_SIZE: Vector2i = Vector2i(360, 640)
const DEATH_CARD_BUFFER_FRAMES: int = 8
## Yakalama bu kadar ms'den uzun sürerse (1 kare) yavaş sayılır; art arda bu kadar yavaşsa aralık büyür
const DEATH_CARD_SLOW_MS: float = 16.7
const DEATH_CARD_SLOW_STRIKES: int = 2
## 1. kare ölümden bu kadar önceki kareden seçilir
const DEATH_CARD_BEFORE_SEC: float = 0.75
const DEATH_CARD_SIZE: Vector2i = Vector2i(1080, 1350)
const DEATH_CARD_PATH: String = "user://olum_karesi.png"
const DEATH_CARD_MARGIN: float = 36.0
const DEATH_CARD_GAP: float = 24.0
const DEATH_CARD_TOP_H: float = 760.0
const DEATH_CARD_BOTTOM_H: float = 380.0
const DEATH_CARD_BORDER_W: float = 10.0
## Çerçeve köşelerinin el çizimi oynaması (px)
const DEATH_CARD_JITTER_PX: float = 5.0
const DEATH_CARD_ZOOM: float = 1.18
const DEATH_CARD_TILT_DEG: float = -4.0
const DEATH_CARD_PREVIEW_MAX_W: float = 560.0
## Önizleme penceresinde başlık + butonlar için ayrılan yükseklik
const DEATH_CARD_PREVIEW_CHROME_H: float = 300.0
## 3+ böcekte isim etiketleri üst üste binmesin: dikey en az aralık ve yumuşatma hızı
const NAME_LABEL_STACK_GAP: float = 32.0
const NAME_LABEL_Z: int = 20
const NAME_LABEL_SHIFT_SPEED: float = 60.0
const SHARE_TEXT_DEATH_CARD: String = "Böyle öldüm. Sen daha iyisini yapabilir misin? {link}"
## Ölüm sebebine göre ses efekti yazısı
const DEATH_CARD_SFX: Dictionary = {
	"terlik": "ŞAPP!",
	"ust_engel": "ŞAPP!",
	"alt_engel": "ŞAPP!",
	"fuze": "BUMM!",
	"zemin": "PIRT!",
	"tavan": "DONK!",
	"surpriz": "FIŞŞŞ!",
	"hayalet_terlik": "İNTİKAM!",
	"belediye": "FIŞŞŞ!",
}
const DEATH_CARD_SFX_DEFAULT: String = "ŞAPP!"
## Anlatı kutusu: saate göre (başlangıç saati, şablon); {saat} -> "03:12"
const DEATH_CARD_NARRATION_BY_HOUR: Array[Array] = [
	[0, "Gece {saat}. Mutfak sessiz…"],
	[6, "Sabah {saat}. Çaydanlık fokurduyor…"],
	[12, "Öğlen {saat}. Kimse mutfakta yok sanıyordu…"],
	[18, "Akşam {saat}. Annem bulaşıkta…"],
]
const DEATH_CARD_NARRATION_RECORD: String = "Rekor kapıdaydı…"
const DEATH_CARD_NARRATION_SHORT: String = "Her şey yolunda gidiyordu…"
## Skor rekorun bu oranını geçtiyse "Rekor kapıdaydı…"
const DEATH_CARD_RECORD_RATIO: float = 0.8
## Bu süreden kısa maçta "Her şey yolunda gidiyordu…"
const DEATH_CARD_SHORT_RUN_SEC: float = 12.0


## Ölüm sebebine göre büyük ses efekti yazısı.
static func death_card_sfx(cause: String) -> String:
	return str(DEATH_CARD_SFX.get(cause, DEATH_CARD_SFX_DEFAULT))


## Çizgi romanın 1. karesindeki anlatı cümlesi (saate, rekora ve maç süresine göre).
static func death_card_narration(hour: int, minute: int, score_val: int, best: int, run_sec: float) -> String:
	if best > 0 and score_val >= int(ceilf(float(best) * DEATH_CARD_RECORD_RATIO)):
		return DEATH_CARD_NARRATION_RECORD
	if run_sec < DEATH_CARD_SHORT_RUN_SEC:
		return DEATH_CARD_NARRATION_SHORT
	var tmpl: String = str(DEATH_CARD_NARRATION_BY_HOUR[0][1])
	for row: Array in DEATH_CARD_NARRATION_BY_HOUR:
		if hour >= int(row[0]):
			tmpl = str(row[1])
	return tmpl.replace("{saat}", "%02d:%02d" % [hour, minute])


# ---------------------------------------------------------------------------
# Faz 11.4: Günlük görevler ve seri
# ---------------------------------------------------------------------------
const DAILY_TASK_COUNT: int = 3
## Tarih seed'i: YYYYMMDD * çarpan + ek (her cihazda aynı)
const DAILY_TASK_SEED_MUL: int = 7919
const DAILY_TASK_SEED_ADD: int = 104729
## Görevlerde {karakter} için yalnızca herkesin baştan sahip olduğu böcekler
const DAILY_TASK_CHARS: Array[String] = ["klasik", "diva", "duktur", "halaybasi"]
## Bir günde en fazla bu kadar çok oyunculu / sosyal görev
const DAILY_TASK_MAX_MP: int = 1
const DAILY_TASK_MAX_SOCIAL: int = 1
## Günde 1 ödüllü reklamla görev değiştirme
const DAILY_TASK_REROLLS_PER_DAY: int = 1
## HUD görev bildirimi en sık bu aralıkla yenilenir (tamamlanma hemen gösterilir)
const QUEST_NOTICE_MIN_GAP_SEC: float = 2.0
const QUEST_NOTICE_LIFE_SEC: float = 2.2

## Görev havuzu. text: {n}, {karakter}; hud: maç içi küçük bildirim ({p}/{n});
## event: oyunun bildirdiği olay; mode: sum (gün boyu toplam), match (tek maçta toplam), max (ulaşılan değer);
## char: {karakter} parametresi var mı; group: "" | "mp" | "social"; rewards: n seçeneklerine karşılık 30–80 Kırıntı.
const DAILY_TASKS: Array[Dictionary] = [
	{"id": "korkut_mac", "text": "Bir maçta {n} kişiyi korkut", "hud": "{p}/{n} kişi korkutuldu", "event": "scare", "mode": "match", "n": [15, 25, 40], "rewards": [40, 55, 75]},
	{"id": "korkut_gun", "text": "Bugün toplam {n} kişiyi korkut", "hud": "{p}/{n} kişi korkutuldu", "event": "scare", "mode": "sum", "n": [40, 80, 120], "rewards": [30, 45, 60]},
	{"id": "engel_gec", "text": "{n} engel geç", "hud": "{p}/{n} engel geçildi", "event": "pass", "mode": "sum", "n": [20, 40, 60], "rewards": [30, 40, 55]},
	{"id": "engel_mac", "text": "Bir maçta {n} engel geç", "hud": "{p}/{n} engel geçildi", "event": "pass", "mode": "match", "n": [15, 25, 35], "rewards": [35, 50, 70]},
	{"id": "yakin_gun", "text": "{n} yakın kaçış yap", "hud": "{p}/{n} yakın kaçış", "event": "close", "mode": "sum", "n": [5, 10, 15], "rewards": [35, 50, 65]},
	{"id": "yakin_mac", "text": "Bir maçta {n} yakın kaçış yap", "hud": "{p}/{n} yakın kaçış", "event": "close", "mode": "match", "n": [4, 7, 10], "rewards": [40, 55, 75]},
	{"id": "kombo", "text": "Yakın kaçışla x{n} kombo yap", "hud": "Kombo x{p}/{n}", "event": "combo", "mode": "max", "n": [3, 5, 7], "rewards": [40, 60, 80]},
	{"id": "kucul_karakter", "text": "{karakter} ile {n} kez küçül", "hud": "{p}/{n} kez küçüldün", "event": "shrink", "mode": "sum", "char": true, "n": [3, 5, 8], "rewards": [35, 45, 60]},
	{"id": "gizemli_kutu", "text": "{n} gizemli kutu topla", "hud": "{p}/{n} gizemli kutu", "event": "mystery", "mode": "sum", "n": [1, 2, 3], "rewards": [40, 55, 70]},
	{"id": "kutu_topla", "text": "{n} kutu topla", "hud": "{p}/{n} kutu toplandı", "event": "box", "mode": "sum", "n": [5, 10, 15], "rewards": [30, 40, 55]},
	{"id": "fuze_sag", "text": "Füze yağmurundan {n} kez sağ çık", "hud": "{p}/{n} füze yağmuru atlatıldı", "event": "missile_survive", "mode": "sum", "n": [1, 2, 3], "rewards": [45, 60, 80]},
	{"id": "seviye", "text": "Seviye {n}'e ulaş", "hud": "Seviye {p}/{n}", "event": "level", "mode": "max", "n": [3, 4, 5], "rewards": [35, 55, 80]},
	{"id": "satasma_mac", "text": "Bir maçta {n} kez sataşma gönder", "hud": "{p}/{n} sataşma", "event": "taunt", "mode": "match", "group": "mp", "n": [1, 2, 3], "rewards": [40, 55, 75]},
	{"id": "davet", "text": "Bir arkadaşını davet et", "hud": "Davet gönderildi", "event": "invite", "mode": "sum", "group": "social", "n": [1], "rewards": [40]},
	{"id": "kare_paylas", "text": "Ölüm Kareni paylaş", "hud": "Ölüm Karesi paylaşıldı", "event": "share_card", "mode": "sum", "group": "social", "n": [1], "rewards": [35]},
	{"id": "mac_oyna", "text": "{n} maç oyna", "hud": "{p}/{n} maç oynandı", "event": "play", "mode": "sum", "n": [2, 3, 5], "rewards": [30, 40, 55]},
	{"id": "cok_oyunculu", "text": "{n} çok oyunculu maç oyna", "hud": "{p}/{n} çok oyunculu maç", "event": "play_mp", "mode": "sum", "group": "mp", "n": [1, 2, 3], "rewards": [40, 55, 70]},
	{"id": "kazan", "text": "Çok oyunculu {n} maç kazan", "hud": "{p}/{n} galibiyet", "event": "win", "mode": "sum", "group": "mp", "n": [1, 2], "rewards": [60, 80]},
	{"id": "yetenek", "text": "Yeteneğini {n} kez kullan", "hud": "{p}/{n} yetenek", "event": "ability", "mode": "sum", "n": [5, 10, 15], "rewards": [30, 40, 55]},
	{"id": "karakter_mac", "text": "{karakter} ile {n} maç oyna", "hud": "{p}/{n} maç", "event": "play_char", "mode": "sum", "char": true, "n": [1, 2, 3], "rewards": [30, 40, 50]},
	{"id": "hayatta_kal", "text": "Bir maçta {n} saniye hayatta kal", "hud": "{p}/{n} saniye", "event": "survive", "mode": "max", "n": [30, 60, 90], "rewards": [35, 55, 75]},
	{"id": "guclendirme", "text": "{n} güçlendirme kullan", "hud": "{p}/{n} güçlendirme", "event": "powerup_use", "mode": "sum", "n": [3, 6, 10], "rewards": [30, 40, 55]},
	{"id": "imza", "text": "İmza ödülünü {n} kez kullan", "hud": "{p}/{n} imza ödülü", "event": "signature", "mode": "sum", "n": [1, 2, 3], "rewards": [40, 55, 70]},
	{"id": "gunun_mutfagi", "text": "Günün Mutfağı'nda {n} kez uç", "hud": "{p}/{n} Günün Mutfağı", "event": "daily_kitchen", "mode": "sum", "n": [1, 2], "rewards": [35, 50]},
	{"id": "ayni_parkur", "text": "Aynı Parkur'da {n} deneme yap", "hud": "{p}/{n} Aynı Parkur", "event": "same_course", "mode": "sum", "n": [1, 2], "rewards": [30, 40]},
	{"id": "rovans", "text": "{n} kez rövanş iste", "hud": "{p}/{n} rövanş", "event": "rematch", "mode": "sum", "group": "mp", "n": [1, 2], "rewards": [35, 50]},
	{"id": "laf_at", "text": "Maçta {n} kez laf at", "hud": "{p}/{n} laf", "event": "chat", "mode": "sum", "group": "mp", "n": [2, 4], "rewards": [30, 40]},
	{"id": "hayalet_terlik", "text": "Elendikten sonra {n} hayalet terlik fırlat", "hud": "{p}/{n} hayalet terlik", "event": "ghost_slipper", "mode": "sum", "group": "mp", "n": [1, 2, 3], "rewards": [35, 45, 60]},
	{"id": "annem_kac", "text": "Annem Geldi olayında {n} kez yakalanma", "hud": "{p}/{n} kez sıvıştın", "event": "annem_escape", "mode": "sum", "n": [1, 2], "rewards": [50, 70]},
]

## Günün Sürprizi (3 görev bitince). Gerçek parayla alınamaz; olası içerikler ekranda yazar.
## kind: "kirinti" | "part" (kostüm parçası); weight: seçilme ağırlığı (tarih seed'iyle)
const DAILY_SURPRISE_POOL: Array[Dictionary] = [
	{"kind": "kirinti", "amount": 100, "weight": 4},
	{"kind": "kirinti", "amount": 150, "weight": 3},
	{"kind": "kirinti", "amount": 200, "weight": 2},
	{"kind": "part", "amount": 1, "weight": 3},
]
const DAILY_SURPRISE_TEXT: String = "Olası içerik: 100, 150 ya da 200 Kırıntı veya 1 kostüm parçası"

## Kostüm parçası: bu kadar parça = Pazar'daki sıradaki kilitli kostüm. Hepsi açıksa parça Kırıntıya döner.
const COSTUME_PARTS_PER_SKIN: int = 3
const COSTUME_PART_KIRINTI: int = 200

## Seri takvimi (7 gün döngü): 0 = kostüm parçası
const STREAK_REWARDS: Array[int] = [20, 30, 40, 50, 60, 80, 0]
const STREAK_MILESTONES: Array[int] = [7, 30, 100]
## Seriyi Kurtar: yalnızca 1 gün kaçırıldıysa (son oyun 2 gün önce), haftada 1 kez (ödüllü reklam)
const STREAK_SAVE_MAX_GAP_DAYS: int = 2
const STREAK_SAVE_COOLDOWN_DAYS: int = 7
## Ana menüdeki kanat çırpan böcek ikonu
const STREAK_ICON_SIZE: float = 40.0
const STREAK_WING_SPEED: float = 18.0


## Bir tarih dizgesinden ("YYYY-MM-DD") görev seed'i üretir (platformdan bağımsız).
static func daily_task_seed(date_str: String) -> int:
	var digits: int = int(date_str.replace("-", ""))
	return digits * DAILY_TASK_SEED_MUL + DAILY_TASK_SEED_ADD


static func get_daily_task_def(task_id: String) -> Dictionary:
	for d: Dictionary in DAILY_TASKS:
		if str(d["id"]) == task_id:
			return d
	return {}


## Tarihe göre o günün görevlerini seçer: aynı tarih her cihazda aynı listeyi verir.
## Dönüş: [{id, n, reward, char}]. exclude: değiştirmede hariç tutulacak görev kimlikleri.
static func pick_daily_tasks(date_str: String, count: int = DAILY_TASK_COUNT, exclude: Array = []) -> Array[Dictionary]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = daily_task_seed(date_str)
	# Fisher-Yates karıştırma (yalnızca seed'li rng)
	var order: Array[int] = []
	for i: int in range(DAILY_TASKS.size()):
		order.append(i)
	for i: int in range(order.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: int = order[i]
		order[i] = order[j]
		order[j] = tmp
	var out: Array[Dictionary] = []
	var used_events: Array[String] = []
	var mp_n: int = 0
	var social_n: int = 0
	for idx: int in order:
		var d: Dictionary = DAILY_TASKS[idx]
		var n_opts: Array = d["n"] as Array
		var rewards: Array = d["rewards"] as Array
		# Parametreler de seed'den; atlanan görevler de aynı sayıda sayı tüketir (sıra sabit kalır)
		var n_idx: int = rng.randi_range(0, n_opts.size() - 1)
		var char_idx: int = rng.randi_range(0, DAILY_TASK_CHARS.size() - 1)
		if out.size() >= count:
			continue
		var tid: String = str(d["id"])
		if exclude.has(tid):
			continue
		var ev: String = str(d["event"])
		if ev == "play_char":
			ev = "play"
		if used_events.has(ev):
			continue
		var grp: String = str(d.get("group", ""))
		# Çevrimiçi kapalıyken yapılamayan görev (arkadaş daveti) çıkmasın
		if not ONLINE_ENABLED and ev == "invite":
			continue
		if grp == "mp" and mp_n >= DAILY_TASK_MAX_MP:
			continue
		if grp == "social" and social_n >= DAILY_TASK_MAX_SOCIAL:
			continue
		used_events.append(ev)
		if grp == "mp":
			mp_n += 1
		elif grp == "social":
			social_n += 1
		out.append({
			"id": tid,
			"n": int(n_opts[n_idx]),
			"reward": int(rewards[mini(n_idx, rewards.size() - 1)]),
			"char": DAILY_TASK_CHARS[char_idx] if bool(d.get("char", false)) else "",
		})
	return out


## Görev metnini parametreleriyle doldurur.
static func daily_task_text(task_id: String, n: int, char_id: String) -> String:
	var d: Dictionary = get_daily_task_def(task_id)
	var cname: String = str(CharacterData.get_character(char_id).get("display_name", char_id)) if not char_id.is_empty() else ""
	return str(d.get("text", task_id)).replace("{n}", str(n)).replace("{karakter}", cname)


## Günün Sürprizi içeriği (tarih seed'iyle, herkeste aynı).
static func pick_daily_surprise(date_str: String) -> Dictionary:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = daily_task_seed(date_str) + 31
	var total: int = 0
	for s: Dictionary in DAILY_SURPRISE_POOL:
		total += int(s["weight"])
	var roll: int = rng.randi_range(0, maxi(total - 1, 0))
	for s: Dictionary in DAILY_SURPRISE_POOL:
		roll -= int(s["weight"])
		if roll < 0:
			return s
	return DAILY_SURPRISE_POOL[0]


## "YYYY-MM-DD" -> gün numarası (Unix gün). Hatalı dizge -> -1.
static func date_to_day_number(date_str: String) -> int:
	if date_str.length() != 10:
		return -1
	var unix: int = Time.get_unix_time_from_datetime_string(date_str + "T00:00:00")
	return int(floor(float(unix) / 86400.0))


# ---------------------------------------------------------------------------
# Faz 11.5: Mahalle Albümü (insan tipleri)
# ---------------------------------------------------------------------------
## Görsel dosyası: res://assets/sprites/insanlar/<id>_ust.png / <id>_alt.png (yoksa yedek çizim).
## shirt/accent: yedek çizim renkleri; acc: kafa/gövde aksesuarı; sleeve: üst kolun yen rengi.
const PEOPLE_DIR: String = "res://assets/sprites/insanlar/"
const PEOPLE_SEED_XOR: int = 0x5A17C3
const PEOPLE: Array[Dictionary] = [
	{"id": "anne", "name": "Terlikli Anne", "level": 1, "desc": "Terliği fırlatmadan önce üç kez uyarır. Üçüncüde nişan alır.",
		"scream_lines": ["Gel buraya!", "Terlik nerede?!", "Üç diyorum, üç!"], "shirt": Color("#D98C8C"), "accent": Color("#7B4B8E"), "sleeve": Color("#D69486"), "acc": "basortu", "pitch": 1.25},
	{"id": "amca", "name": "Sandalyedeki Amca", "level": 1, "desc": "Kırk yıldır bu sandalyede. Böcek görünce ilk kez kalktı.",
		"scream_lines": ["Hanıım!", "Gözlüğüm nerede?!", "Ayy belim!"], "shirt": Color("#7FA3C2"), "accent": Color("#5B4636"), "sleeve": Color("#7FA3C2"), "acc": "", "pitch": 0.82},
	{"id": "teyze", "name": "Çığlıkçı Teyze", "level": 2, "desc": "Sesi üç apartman öteden duyulur.",
		"scream_lines": ["AAAAAAA!", "Kurtarın beni!", "Komşulaaar!"], "shirt": Color("#E8A0BF"), "accent": Color("#3F8F7A"), "sleeve": Color("#E8A0BF"), "acc": "bigudi", "pitch": 1.45},
	{"id": "kapici", "name": "Kapıcı Efendi", "level": 2, "desc": "Ekmekleri bırakır, böceği kovalar.",
		"scream_lines": ["Ekmekler düştü!", "Yönetime söylicem!", "Hop hop hop!"], "shirt": Color("#8E7F5A"), "accent": Color("#3D3A33"), "sleeve": Color("#8E7F5A"), "acc": "kasket", "pitch": 0.9},
	{"id": "misafir", "name": "Misafir Teyze", "level": 3, "desc": "Tam kek yerken gördü. Kek de uçtu.",
		"scream_lines": ["Kekim!", "Bu evde böcek mi var?!", "Hemen kalkalım!"], "shirt": Color("#B79AD6"), "accent": Color("#F2C96B"), "sleeve": Color("#B79AD6"), "acc": "sapka", "pitch": 1.3},
	{"id": "ev_arkadasi", "name": "Ev Arkadaşı", "level": 3, "desc": "Bulaşığı o yıkamadı, böcek de oradan geldi.",
		"scream_lines": ["Bulaşık senindi!", "Ev sahibine yazma!", "Kanka kaç!"], "shirt": Color("#8FC6A5"), "accent": Color("#3B3B4F"), "sleeve": Color("#8FC6A5"), "acc": "kulaklik", "pitch": 1.1},
	{"id": "kurye", "name": "Kapıdaki Kurye", "level": 3, "desc": "Siparişi bıraktı, koşarak kaçtı.",
		"scream_lines": ["Afiyet olsun!", "Puan verin ama!", "Ben kaçtım!"], "shirt": Color("#F0A35E"), "accent": Color("#D9483F"), "sleeve": Color("#F0A35E"), "acc": "kask", "pitch": 1.05},
	{"id": "yonetici", "name": "Apartman Yöneticisi", "level": 4, "desc": "Aidatı ödemeyen böceklere karşı.",
		"scream_lines": ["Aidat!", "Toplantı var!", "Karar defterine yaz!"], "shirt": Color("#9AA6B5"), "accent": Color("#B23A48"), "sleeve": Color("#6E7B8C"), "acc": "gozluk", "pitch": 0.95},
	{"id": "bakkal", "name": "Bakkal Amca", "level": 4, "desc": "Veresiye defterine böceği de yazdı.",
		"scream_lines": ["Veresiye yok!", "Defter nerede?!", "Kapatıyoruz!"], "shirt": Color("#F4EEDF"), "accent": Color("#4A7A9C"), "sleeve": Color("#F4EEDF"), "acc": "onluk", "pitch": 0.86},
	{"id": "kayinvalide", "name": "Kayınvalide", "level": 5, "desc": "Böceği görünce gelinine baktı.",
		"scream_lines": ["Gelin hanım!", "Bizim evde olmazdı!", "Tövbe tövbe!"], "shirt": Color("#9C6B98"), "accent": Color("#E8D8A8"), "sleeve": Color("#9C6B98"), "acc": "basortu", "pitch": 1.2},
	{"id": "belediye", "name": "Belediye Görevlisi", "level": 5, "desc": "Elinde ilaç, gözünde intikam.",
		"scream_lines": ["İlaçlıyoruz!", "Kaçamazsın!", "Maskemi takayım!"], "shirt": Color("#7FB069"), "accent": Color("#F2E86D"), "sleeve": Color("#7FB069"), "acc": "maske", "pitch": 0.92},
	{"id": "muhtar", "name": "Mahalle Muhtarı", "level": 6, "desc": "Mahalleyi böcekten temizleme sözü verdi. Seçim yakın.",
		"scream_lines": ["Oylarınızı bekliyorum!", "Muhtarlığa gel!", "Söz verdim!"], "shirt": Color("#3F5F8A"), "accent": Color("#D9483F"), "sleeve": Color("#3F5F8A"), "acc": "kusak", "pitch": 0.8},
]
## Kart seviyeleri: bu kadar korkutma = Bronz / Gümüş / Altın
const ALBUM_TIER_COUNTS: Array[int] = [1, 10, 50]
const ALBUM_TIER_NAMES: Array[String] = ["Bronz", "Gümüş", "Altın"]
const ALBUM_TIER_COLORS: Array[Color] = [Color("#D9A57B"), Color("#C9D3DC"), Color("#F2D27A")]
const ALBUM_LOCKED_COLOR: Color = Color("#D8CFC4")
## Tamamlama ödülleri
const ALBUM_BRONZE_REWARD: int = 500
## Tümü gümüş: özel kostüm (sıradaki kilitli kostüm); hepsi açıksa bu kadar Kırıntı
const ALBUM_SILVER_FALLBACK_KIRINTI: int = 1000
const ALBUM_GOLD_TITLE_ID: String = "kabus"
const ALBUM_TITLES: Dictionary = {"kabus": "Mahallenin Kâbusu"}
const ALBUM_SCREAM_SFX: String = "res://assets/sounds/ciglik.ogg"
## Albüm ızgarası
const ALBUM_COLUMNS: int = 3
const ALBUM_CARD_H: float = 250.0
const ALBUM_DETAIL_ART_H: float = 300.0
## Seviye ipucu ekleri ("Seviye 4'te ortaya çıkar")
const LEVEL_SUFFIX_DE: Dictionary = {1: "'de", 2: "'de", 3: "'te", 4: "'te", 5: "'te", 6: "'da", 7: "'de", 8: "'de", 9: "'da", 10: "'da"}


static func get_person(type_id: String) -> Dictionary:
	for p: Dictionary in PEOPLE:
		if str(p["id"]) == type_id:
			return p
	return PEOPLE[1]


## Seviyede havuzda olan insan tipleri (sıra sabit).
static func people_pool_for_level(level_num: int) -> Array[String]:
	var out: Array[String] = []
	for p: Dictionary in PEOPLE:
		if int(p["level"]) <= level_num:
			out.append(str(p["id"]))
	return out


## Korkutma sayısına göre kart seviyesi: 0 yok, 1 Bronz, 2 Gümüş, 3 Altın.
static func album_tier_for(count: int) -> int:
	var tier: int = 0
	for i: int in range(ALBUM_TIER_COUNTS.size()):
		if count >= ALBUM_TIER_COUNTS[i]:
			tier = i + 1
	return tier


static func level_hint_text(level_num: int) -> String:
	return "Seviye %d%s ortaya çıkar" % [level_num, str(LEVEL_SUFFIX_DE.get(level_num, "'de"))]


static func title_text(title_id: String) -> String:
	return str(ALBUM_TITLES.get(title_id, ""))


# ---------------------------------------------------------------------------
# Faz 11.6: Ani olaylar
# ---------------------------------------------------------------------------
## Zamanlama: aynı anda tek olay, füze (karanlık) evresiyle çakışmaz,
## iki olayın başlangıçları arası en az EVENT_MIN_GAP_SEC, bir olayın bitişiyle sonrakinin başlangıcı arası
## en az EVENT_MIN_END_GAP_SEC (art arda binmesin).
const EVENT_SEED_XOR: int = 0x3E7A11
const EVENT_FOG_SEED_XOR: int = 0x6B05D2
const EVENT_FIRST_MIN_SEC: float = 28.0
const EVENT_FIRST_JITTER_SEC: float = 10.0
const EVENT_MIN_GAP_SEC: float = 45.0
const EVENT_MIN_END_GAP_SEC: float = 15.0
const EVENT_EXTRA_GAP_SEC: float = 20.0
## Karanlık (füze) evresinin önünde ve arkasında boş bırakılan süre
const EVENT_DARK_PAD_SEC: float = 2.0
const EVENT_RETRY_STEP_SEC: float = 4.0
## Zorla tetikleme (yalnızca hata ayıklama / ekran görüntüsü) başlangıç anı
const EVENT_DEBUG_START_SEC: float = 3.0
## id, ad, en düşük seviye, süre, seçilme ağırlığı, tanıtım ve rehber cümlesi
const EVENTS: Dictionary = {
	"annem": {"id": "annem", "name": "Annem Geldi!", "min_level": 3, "duration": 3.4, "weight": 3, "boss": false,
		"intro": "Anahtar sesi gelince küçül! Işık yanınca büyüksen yakalanırsın.",
		"guide": "Anahtar sesi gelince küçül; ışık yandığında büyüksen 1 sn donarsın."},
	"belediye": {"id": "belediye", "name": "Belediye İlaçlıyor!", "min_level": 5, "duration": 0.0, "weight": 0, "boss": true,
		"intro": "Sis duvarlarındaki delikten geç! Ok, deliğin yerini gösterir.",
		"guide": "Seviye 5'te ve her 3 seviyede sis duvarları gelir; oka bak, delikten geç, +40 Kırıntı kap."},
	"elektrik": {"id": "elektrik", "name": "Elektrik Kesildi!", "min_level": 4, "duration": 6.0, "weight": 3, "boss": false,
		"intro": "Her yer karanlık! Engel konturlarına bak; aralıklar biraz geniş.",
		"guide": "6 sn zifiri karanlık olur; yalnızca gözler ve engel konturları görünür, aralıklar genişler."},
	"misafir": {"id": "misafir", "name": "Misafir Var!", "min_level": 2, "duration": 8.0, "weight": 4, "boss": false,
		"intro": "Misafir önünde rezil olma! Korkutma puanı iki katı, kutular sık.",
		"guide": "8 sn boyunca korkutma puanı iki katı olur ve kutular daha sık çıkar."},
}
const EVENT_ORDER: Array[String] = ["annem", "belediye", "elektrik", "misafir"]

## Annem Geldi
const EVENT_ANNEM_WARN_SEC: float = 1.2
const EVENT_ANNEM_LIGHT_SEC: float = 1.2
const EVENT_ANNEM_CAUGHT_SEC: float = 1.0
const EVENT_ANNEM_FLASH_ALPHA: float = 0.4
const EVENT_ANNEM_WARM_TINT: Color = Color(1.0, 0.95, 0.85, 1.0)
const EVENT_ANNEM_STRIP_COLOR: Color = Color(1.0, 0.86, 0.35, 0.75)
const EVENT_ANNEM_STRIP_W: float = 210.0
## Bot görsel olarak bu olasılıkla küçülür (ölüm anını değiştirmez)
const EVENT_ANNEM_BOT_SHRINK_CHANCE: float = 0.7

## Belediye İlaçlıyor (patron anı): Seviye 5'e girerken ve sonra her 3 seviyede
const EVENT_BOSS_FIRST_LEVEL: int = 5
const EVENT_BOSS_EVERY: int = 3
const EVENT_BOSS_DELAY_SEC: float = 1.0
const EVENT_FOG_WALLS: int = 5
## İlk sis duvarı oyuncunun hizasına olay başından bu kadar sonra varır
# İlk duvar ekrana olay başladıktan bu kadar sonra girer (şerit + ok uyarısı süresi)
const EVENT_FOG_FIRST_SEC: float = 1.5
# Son duvar oyuncuyu geçtikten sonra olayın bitmesine kalan süre
const EVENT_FOG_TAIL_SEC: float = 0.8
const EVENT_FOG_SPACING_SEC: float = 1.1
## Ok uyarısı, duvar ekrana girmeden bu kadar önce çıkar
const EVENT_FOG_WARN_SEC: float = 0.9
const EVENT_FOG_WALL_W: float = 84.0
const EVENT_FOG_HOLE: float = 300.0
const EVENT_FOG_MAX_DELTA_Y: float = 240.0
## Sis bölgesinde normal engel konmayan mesafe payları
const EVENT_FOG_CLEAR_BEFORE_PX: float = 330.0
const EVENT_FOG_CLEAR_AFTER_PX: float = 330.0
const EVENT_FOG_REWARD: int = 40
const EVENT_FOG_COLOR: Color = Color(0.45, 0.80, 0.42, 0.80)
const EVENT_FOG_EDGE_COLOR: Color = Color(0.20, 0.52, 0.24, 0.95)
const EVENT_TRUCK_SEC: float = 3.2
## Botun sis duvarında başarısız olma olasılığı, aynı seviyedeki engel çiftine göre çarpanı
const EVENT_FOG_BOT_FAIL_MULT: float = 1.0

## Elektrik Kesildi
const EVENT_ELEC_GAP_BONUS: float = 40.0
const EVENT_ELEC_DARK_ALPHA: float = 0.93
const EVENT_ELEC_FADE_SEC: float = 0.35
const EVENT_ELEC_CONTOUR_COLOR: Color = Color(0.75, 0.82, 1.0, 0.42)
const EVENT_ELEC_EYE_COLOR: Color = Color(1.0, 0.95, 0.55, 1.0)

## Misafir Var
const EVENT_GUEST_SCORE_MULT: int = 2
const EVENT_GUEST_BOX_MULT: float = 1.5
const EVENT_GUEST_DEATH_SUFFIX: String = " …hem de misafirin önünde!"

## Ses dosyaları (yoksa sentezlenir)
const EVENT_SFX: Dictionary = {
	"annem": "res://assets/sounds/anahtar.ogg",
	"belediye": "res://assets/sounds/siren.ogg",
	"elektrik": "res://assets/sounds/klik.ogg",
	"elektrik_end": "res://assets/sounds/buzdolabi.ogg",
	"misafir": "res://assets/sounds/kapi_zili.ogg",
}


static func get_event_def(event_id: String) -> Dictionary:
	return EVENTS.get(event_id, {}) as Dictionary


## Belediye seviyesi mi (5, 8, 11 ...)?
static func is_boss_level(level_num: int) -> bool:
	return level_num >= EVENT_BOSS_FIRST_LEVEL and (level_num - EVENT_BOSS_FIRST_LEVEL) % EVENT_BOSS_EVERY == 0


## Belediye olayının süresi: duvarların ekranı geçme süresi hıza bağlı; en yavaş hızla üst sınır alınır.
static func belediye_duration_bound() -> float:
	var travel: float = (VIEWPORT_WIDTH - PLAYER_X) / BASE_SPEED
	return EVENT_FOG_FIRST_SEC + travel + float(EVENT_FOG_WALLS - 1) * EVENT_FOG_SPACING_SEC + EVENT_FOG_TAIL_SEC


# ---------------------------------------------------------------------------
# Faz 11.7: Kendi lafını kaydet ("Benim Lafım")
# ---------------------------------------------------------------------------

## Ses yuvaları: laf (hazır laf menüsünde 8. seçenek), sataşma, zafer
const VOICE_SLOTS: Array[String] = ["laf", "satasma", "zafer"]
const VOICE_SLOT_NAMES: Dictionary = {"laf": "Laf atma", "satasma": "Sataşma", "zafer": "Zafer"}
const VOICE_SLOT_HINTS: Dictionary = {
	"laf": "Laf menüsünde 8. seçenek olur.",
	"satasma": "Sataşınca \"Özür dilerim pıttığım\" yerine çalar.",
	"zafer": "Maçı kazanınca çalar.",
}
const VOICE_FILE_FMT: String = "user://benim_lafim_%s.wav"
## Kayıt: en fazla 2.0 sn, cihazda 16 kHz mono 16 bit
const VOICE_MAX_SEC: float = 2.0
const VOICE_STORE_RATE: int = 16000
## Sessizlik kırpma eşiği (tam ölçeğe göre) ve baş/son pay
const VOICE_SILENCE_THRESHOLD: float = 0.04
const VOICE_TRIM_PAD_SEC: float = 0.04
## En kısa geçerli kayıt (kırpmadan sonra)
const VOICE_MIN_SEC: float = 0.15
## Normalize tepe değeri
const VOICE_NORMALIZE_PEAK: float = 0.89
## Böcek sesi: karakterin voice_pitch değeri bu katsayıyla çarpılır
const VOICE_BUG_PITCH_MULT: float = 1.2
## Mikrofon kayıt bus'ı
const VOICE_MIC_BUS: String = "Mic"
## Canlı dalga formu sütun sayısı
const VOICE_WAVE_BARS: int = 48

## Ağ: 11025 Hz 16 bit PCM + ZSTD, yuva başına en fazla 48 KB (sıkıştırılmış ve açılmış)
const VOICE_NET_RATE: int = 11025
const VOICE_NET_MAX_BYTES: int = 48 * 1024
## Açılmış PCM üst sınırı: 2.0 sn x 11025 x 2 bayt (+ küçük pay)
const VOICE_NET_MAX_RAW: int = 44200
## Ses paketleri için ayrı güvenilir kanal
const VOICE_NET_CHANNEL: int = 2
## Hızlı sohbette "Benim Lafım" indeksi (99 = karakter repliği)
const NET_QUICK_CHAT_CUSTOM_INDEX: int = 98
## Bildirim sebepleri (ses verisi gönderilmez)
const REPORT_REASONS: Array[String] = [
	"Rahatsız edici ses",
	"Küfür / hakaret",
	"Uygunsuz isim",
	"Diğer",
]
## Bir oturumda en fazla bildirim; LAN'da yerel kuyruk sınırı
const REPORT_MAX_PER_SESSION: int = 5
const REPORT_QUEUE_MAX: int = 10
const REPORT_QUEUE_PATH: String = "user://bildirim_kuyrugu.cfg"
const REPORT_LOG_NAME: String = "reports.log"
## Laf menüsündeki 8. seçenek ve konuşma balonu
const VOICE_LAF_MENU_TEXT: String = "Benim Lafım (sesli)"
const VOICE_LAF_BUBBLE: String = "(sesli laf)"


# ---------------------------------------------------------------------------
# Faz 13A: Sesli sohbet (TwoVoip eklentisi varsa; Hızlı Oyun'da kod seviyesinde kapalı)
# ---------------------------------------------------------------------------
## Ses paketleri ayrı ENet kanalında, unreliable_ordered. Kanal 2, 11D'nin güvenilir büyük
## Benim Lafım aktarımına ayrıldığı için (aynı kanalda sıralama beklemesi olmasın) sesli sohbet kanal 3.
const VOICE_CHAT_CHANNEL: int = 3
## Sunucu/LAN host sınırları: oyuncu başına saniyede en fazla paket, paket başına en fazla bayt
const VOICE_CHAT_MAX_PPS: int = 60
const VOICE_CHAT_MAX_BYTES: int = 400
## Saniyede bu kadar paketi aşan eş atılır (sel saldırısı)
const VOICE_CHAT_KICK_PPS: int = 240
## Paket başlığı: 1 bayt bayrak + 2 bayt sıra numarası (LE); geri kalanı Opus parçası (sunucu çözmez)
const VOICE_CHAT_HEADER: int = 3
const VOICE_CHAT_FLAG_END: int = 1
## Opus: 48 kHz mono, 20 ms parça (saniyede 50 paket), ~10 kbit/sn
const VOICE_CHAT_OPUS_RATE: int = 48000
const VOICE_CHAT_FRAME_MS: int = 20
const VOICE_CHAT_BITRATE: int = 10000
const VOICE_CHAT_COMPLEXITY: int = 5
## Alıcı titreşim tamponu: çalmaya başlamadan önce ~100 ms biriktir; eksik parça için en fazla 2 parça bekle
const VOICE_CHAT_JITTER_MS: int = 100
const VOICE_CHAT_REORDER_FRAMES: int = 2
## Çözücü kuyruğu bundan uzunsa yeni parça atılır (gecikme birikmesin, hız değişmesin)
const VOICE_CHAT_MAX_QUEUE_MS: int = 300
## Bu kadar ms paket gelmezse konuşma bitti sayılır
const VOICE_CHAT_SPEAK_HOLD_MS: int = 250
## Ses etkinliği algılama (tepe değeri): varsayılan eşik, ayar aralığı, konuşma sonrası bekleme
const VOICE_CHAT_VAD_DEFAULT: float = 0.07
const VOICE_CHAT_VAD_MIN: float = 0.02
const VOICE_CHAT_VAD_MAX: float = 0.30
const VOICE_CHAT_VAD_HANG_MS: int = 500
## Yankı önleme (yarı çift yönlü kapı): hoparlörden çalan sohbet sesi bu dB'yi geçerse
## eşik bu katsayıyla yükselir ve ses bittikten sonra bu kadar ms yüksek kalır
const VOICE_CHAT_ECHO_DB: float = -38.0
const VOICE_CHAT_ECHO_MULT: float = 3.5
const VOICE_CHAT_ECHO_HOLD_MS: int = 300
## Ducking: biri konuşurken müzik ve efekt kısılır; bitince bu sürede geri gelir
const VOICE_CHAT_DUCK_MUSIC_DB: float = -6.0
const VOICE_CHAT_DUCK_SFX_DB: float = -3.0
const VOICE_CHAT_DUCK_IN_SEC: float = 0.12
const VOICE_CHAT_DUCK_OUT_SEC: float = 0.4
## Böcek sesi: konuşanın voice_pitch değeri x bu katsayı (Benim Lafım ile aynı)
const VOICE_CHAT_BUG_PITCH_MULT: float = 1.2
## Bus adları: ana sohbet bus'ı ve konuşan başına alt bus öneki
const VOICE_CHAT_BUS: String = "VoiceChat"
const VOICE_CHAT_PEER_BUS_PREFIX: String = "VoiceChat_"
## Katılım seçimi (settings.cfg [voice_chat] choice) ve odadaki oyuncu kipi (players[pid].vc)
const VOICE_CHOICE_UNSET: String = ""
const VOICE_CHOICE_JOIN: String = "join"
const VOICE_CHOICE_LISTEN: String = "listen"
const VOICE_CHOICE_NO: String = "no"
const VOICE_MODE_OFF: int = 0
const VOICE_MODE_LISTEN: int = 1
const VOICE_MODE_TALK: int = 2
## Konuşma kipi
const VOICE_TALK_AUTO: String = "auto"
const VOICE_TALK_PTT: String = "ptt"
## Arayüz: HUD mikrofon ikonu, maç içi küçük ve izlerken büyük Bas-Konuş butonu, lobi butonu
const VOICE_HUD_ICON: float = 52.0
const VOICE_HUD_PTT_SMALL: float = 64.0
const VOICE_HUD_PTT_BIG: float = 120.0
const VOICE_LOBBY_PTT_H: float = 96.0
const VOICE_JOIN_TEXT: String = "Bu odada sesli sohbet var. Katılmak ister misin? (En iyi deneyim için kulaklık tak.)"
const VOICE_ECHO_HINT: String = "Hoparlörden oynarken yankı olabilir; kulaklık en iyisi."


# ---------------------------------------------------------------------------
# Faz 12.1–12.3: Böcek Kimliği, Mahalle bağlantısı ve arkadaşlık
# ---------------------------------------------------------------------------
## Cihazdaki hesap dosyası (şifreli) ve şifresi (caydırıcı; tam koruma değildir)
const ACCOUNT_PATH: String = "user://hesap.cfg"
const ACCOUNT_SAVE_PASS: String = "ucan-hamam-bocegi-hesap-v1"
## Kimlik: 8 karakter, karışmayan harf/rakam (O, 0, I, 1 yok)
const ACCOUNT_ID_CHARS: String = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const ACCOUNT_ID_LEN: int = 8
const ACCOUNT_TOKEN_BYTES: int = 32
const RECOVERY_CODE_LEN: int = 16
## Mahalle bağlantısı (istemci)
const MAHALLE_PING_SEC: float = 20.0
const MAHALLE_CONNECT_TIMEOUT_SEC: float = 6.0
const MAHALLE_RECONNECT_MIN_SEC: float = 2.0
const MAHALLE_RECONNECT_MAX_SEC: float = 60.0
const MAHALLE_BACKGROUND_CLOSE_SEC: float = 30.0
const MAHALLE_REQUEST_TIMEOUT_SEC: float = 10.0
const MAHALLE_SYNC_CHECK_SEC: float = 0.5
const MAHALLE_PROFILE_CHECK_SEC: float = 2.0
const MAHALLE_LIST_MIN_INTERVAL_SEC: float = 2.0
const MAHALLE_NOTICE_SEC: float = 10.0
const MAHALLE_OFFLINE_QUEUE_MAX: int = 10
const MAHALLE_READ_MAX: int = 262144
## Arkadaşlık sınırları
const FRIENDS_MAX: int = 100
const FRIEND_REQUESTS_PER_DAY: int = 30
const FRIEND_REJECT_COOLDOWN_SEC: int = 86400
const RECENT_PLAYERS_MAX: int = 20
const PROFILE_STAT_MAX: int = 1000000
## Eşleştirici: kimliği doğrulanmış kalıcı oturumlar (kısa bağlantı kurallarından ayrı)
const MM_SESSION_IDLE_SEC: float = 60.0
const MM_SESSION_MSG_PER_MIN: int = 60
const MM_SESSION_BAN_SEC: float = 300.0
const MM_MAX_SESSIONS: int = 2000
const MM_MAX_SESSIONS_PER_IP: int = 16
const MM_SESSIONS_PER_ID: int = 2
## Kaba kuvvete karşı: kimlik oluşturma / geri yükleme / kurtarma kodu üretme sınırları (saatlik)
const MM_HOUR_SEC: float = 3600.0
const MM_REGISTER_PER_HOUR_PER_IP: int = 10
const MM_RECOVER_PER_HOUR_PER_IP: int = 10
const MM_RECOVER_PER_HOUR_PER_ID: int = 5
const MM_RECOVERY_NEW_PER_HOUR: int = 5
const MM_AUTH_FAIL_PER_HOUR_PER_IP: int = 30
## users.json: değişiklik en geç bu sürede diske; günlük yedek sayısı
const MM_USERS_FILE: String = "users.json"
const MM_USERS_FLUSH_SEC: float = 5.0
const MM_USERS_BACKUP_KEEP: int = 7
## Durum adları (sunucu ve istemci ortak)
const PRESENCE_ONLINE: String = "online"
const PRESENCE_ROOM: String = "room"
const PRESENCE_MATCH: String = "match"
const PRESENCE_OFFLINE: String = "offline"
const PRESENCE_COLORS: Dictionary = {
	"online": Color("#5DBB4C"),
	"room": Color("#E8B930"),
	"match": Color("#E8853A"),
	"offline": Color("#A39C94"),
}
## Paylaşım metni ve bağlantı
const SHARE_TEXT_FRIEND: String = "Uçan Hamam Böceği'nde arkadaş olalım! Kimliğim: {kimlik} {link}"
const FRIEND_LINK_SCHEME: String = "ucanbocek://arkadas/"


## "7K3MQX9P" -> "#7K3M-QX9P"
static func format_account_id(raw_id: String) -> String:
	if raw_id.length() != ACCOUNT_ID_LEN:
		return ""
	return "#%s-%s" % [raw_id.substr(0, 4), raw_id.substr(4, 4)]


## Girilen kimliği temizler: bağlantıdan da çıkarır, # ve tire isteğe bağlı, küçük harf kabul. Geçersizse "".
static func normalize_account_id(raw: String) -> String:
	var txt: String = raw.strip_edges()
	var k_pos: int = txt.find("k=")
	if k_pos != -1:
		txt = txt.substr(k_pos + 2)
	var a_pos: int = txt.find("arkadas/")
	if a_pos != -1:
		txt = txt.substr(a_pos + 8)
	var out: String = ""
	for ch: String in txt.to_upper().substr(0, 32):
		if ACCOUNT_ID_CHARS.contains(ch):
			out += ch
		elif ch == "&" or ch == "?" or ch == "/":
			break
	return out if out.length() == ACCOUNT_ID_LEN else ""


## Kurtarma kodunu temizler (tire/boşluk serbest). Geçersizse "".
static func normalize_recovery_code(raw: String) -> String:
	var out: String = ""
	for ch: String in raw.strip_edges().to_upper().substr(0, 48):
		if ACCOUNT_ID_CHARS.contains(ch):
			out += ch
	return out if out.length() == RECOVERY_CODE_LEN else ""


## "ABCD-EFGH-JKLM-NPQR" biçimi
static func format_recovery_code(code: String) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for i: int in range(0, code.length(), 4):
		parts.append(code.substr(i, 4))
	return "-".join(parts)


## "Son görülme: 2 saat önce"
static func last_seen_text(last_seen_unix: int, now_unix: int) -> String:
	if last_seen_unix <= 0:
		return "Çevrimdışı"
	var d: int = maxi(0, now_unix - last_seen_unix)
	if d < 60:
		return "Son görülme: az önce"
	if d < 3600:
		return "Son görülme: %d dk önce" % (d / 60)
	if d < 86400:
		return "Son görülme: %d saat önce" % (d / 3600)
	return "Son görülme: %d gün önce" % (d / 86400)


# ---------------------------------------------------------------------------
# Faz 12.4–12.5: Davet, oda gizliliği, giriş bileti, engelleme, bildirme, hesap silme, TLS
# ---------------------------------------------------------------------------
## Oda gizliliği (Özel Oda): kodla açık / sadece arkadaşlarım (varsayılan) / sadece davetliler
const ROOM_PRIVACY_CODE: String = "code"
const ROOM_PRIVACY_FRIENDS: String = "friends"
const ROOM_PRIVACY_INVITE: String = "invite"
const ROOM_PRIVACY_DEFAULT: String = "friends"
const ROOM_PRIVACY_ORDER: Array[String] = ["code", "friends", "invite"]
const ROOM_PRIVACY_NAMES: Dictionary = {
	"code": "Kodla açık",
	"friends": "Sadece arkadaşlarım",
	"invite": "Sadece davetliler",
}
const ROOM_PRIVACY_HINTS: Dictionary = {
	"code": "Oda kodunu bilen herkes girebilir.",
	"friends": "Oda sahibinin arkadaşları ve davet edilenler girebilir.",
	"invite": "Yalnızca oda sahibinin davet ettiği kişiler girebilir.",
}
## Davet: geçerlilik, ekrandaki pencere süresi, kişi başına bekleyen davet ve dakikalık gönderim sınırı
const INVITE_TTL_SEC: int = 600
const INVITE_POPUP_SEC: float = 30.0
const INVITES_PENDING_MAX: int = 10
const INVITES_PER_MIN: int = 10
## "Maç bitince otomatik katıl" bekleyişinin en uzun süresi
const AUTO_JOIN_WAIT_SEC: int = 900
## Giriş bileti: HMAC-SHA256, 60 sn; imza anahtarı oda süreçlerine ortam değişkeniyle verilir
const TICKET_TTL_SEC: int = 60
const TICKET_KEY_ENV: String = "UCAN_BOCEK_TICKET_KEY"
const TICKET_MAX_LEN: int = 512
## Moderasyon: elle işaretlenen kimliklerin adı gizlenir ("Böcek #7K3M")
const MODERATION_FILE: String = "moderation.json"
const MODERATION_RELOAD_SEC: float = 60.0
## Profil kartından bildirim sebepleri (Mahalle; oda içi bildirim REPORT_REASONS'ı kullanır)
const PROFILE_REPORT_REASONS: Array[String] = ["Uygunsuz isim", "Taciz", "Hile", "Diğer"]
const PROFILE_REPORTS_PER_HOUR: int = 10
const BLOCKED_MAX: int = 200
## Hesap silme: silinmiş kimlikler listesi (bir daha verilmez) ve web silme ucu
const DELETED_IDS_FILE: String = "deleted_ids.json"
const MM_HTTP_PORT: int = 7701
const MM_HTTP_MAX_CLIENTS: int = 16
const MM_HTTP_MAX_HEADER: int = 4096
const MM_HTTP_MAX_BODY: int = 1024
const MM_HTTP_TIMEOUT_SEC: float = 5.0
const MM_HTTP_PER_HOUR_PER_IP: int = 10
const MM_DELETE_PER_HOUR_PER_ID: int = 5
## Destek e-postası (yayından önce doldur)
const SUPPORT_EMAIL: String = "aykutdiren2@gmail.com"
## Bağlantı güvenliği: yayında true olmalı (eşleştirici bağlantısı TLS). Yerel testte "--tls" argümanıyla da açılır.
const USE_TLS: bool = false
const TLS_CERT_ARG: String = "--tls-cert="
const TLS_KEY_ARG: String = "--tls-key="
## Yalnızca debug derlemede: yerel test sertifikasına güven ("--tls-trust=<pem>") ve ad eşleştirme ("--tls-cn=")
const TLS_TRUST_ARG: String = "--tls-trust="
const TLS_CN_ARG: String = "--tls-cn="


## TLS açık mı (sabit ya da yerel test argümanı)?
static func tls_enabled() -> bool:
	return USE_TLS or OS.get_cmdline_user_args().has("--tls")


## Komut satırındaki "--ad=değer" argümanı (yoksa boş).
static func cmdline_value(prefix: String) -> String:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return ""


## Gizlenmiş ad: "Böcek #7K3M"
static func masked_name(uid: String) -> String:
	return "Böcek #%s" % uid.substr(0, 4)


static func room_privacy_valid(p: String) -> bool:
	return ROOM_PRIVACY_ORDER.has(p)


# ---------------------------------------------------------------------------
# Faz 13B: açılış, logo ve ana menü
# ---------------------------------------------------------------------------
## Proje geneli tema (gui/theme/custom) ve logo sahnesi
const THEME_PATH: String = "res://ui/tema.tres"
const LOGO_SCENE_PATH: String = "res://scenes/ui/Logo.tscn"
const LOGO_TEXTURE_PATH: String = "res://assets/sprites/title_logo.png"
const MENU_SCENE_PATH: String = "res://scenes/ui/MainMenu.tscn"
const INTRO_SCENE_PATH: String = "res://scenes/ui/Intro.tscn"
## Logonun "Ç" harfinin üst ortası (logo görselinde oran olarak) ve üstündeki böceğin boyu
const LOGO_C_ANCHOR: Vector2 = Vector2(0.474, 0.13)
const LOGO_BUG_SIZE_RATIO: float = 0.07
const LOGO_FLOAT_AMP: float = 6.0
const LOGO_FLOAT_SPEED: float = 1.6
## Intro: tam sürüm ~3 sn, kısa sürüm 1 sn; ışık parlaması 0.2 sn
const INTRO_FULL_SEC: float = 3.0
const INTRO_SHORT_SEC: float = 1.0
const INTRO_FLASH_SEC: float = 0.2
const INTRO_PULLBACK_ZOOM: float = 1.08
const INTRO_PULLBACK_SEC: float = 0.35
const INTRO_NIGHT_TINT: Color = Color("#1B2240")
## Intro sırasında arka planda yüklenenler (karakter görselleri CharacterData'dan eklenir)
const INTRO_PRELOAD: Array[String] = [
	"res://scenes/ui/MainMenu.tscn",
	"res://scenes/game/GameWorld.tscn",
	"res://scenes/ui/Lobby.tscn",
	"res://assets/sounds/muzik_menu.ogg",
	"res://assets/sounds/muzik_oyun.ogg",
	"res://assets/sprites/terlik.png",
	"res://assets/sprites/bg_mutfak.png",
]
## Menü müziği intro bitince bu sürede yükselir
const MENU_MUSIC_FADE_SEC: float = 1.0
const MENU_MUSIC_START_DB: float = -30.0
## Canlı mutfak: görsel boyutu (bg_mutfak.png), yavaş kayma, perde, saat, buhar, şakalar
const KITCHEN_IMG_SIZE: Vector2 = Vector2(720.0, 1280.0)
const KITCHEN_IMG_COUNTER_Y: float = 940.0     # görselde tezgâh üst kenarı (ön katman buraya oturur)
const KITCHEN_OVERSCAN: float = 1.05            # kayma payı
const KITCHEN_PAN_PX: float = 14.0              # arka katman yatay kayma genliği
const KITCHEN_PAN_FRONT_MULT: float = 1.45      # ön katman daha çok kayar (paralaks)
const KITCHEN_PAN_PERIOD: float = 38.0          # bir gidiş-geliş süresi (sn)
const KITCHEN_CURTAIN_RECT: Rect2 = Rect2(316.0, 248.0, 66.0, 362.0)
const KITCHEN_CURTAIN_SKEW: float = 0.035
const KITCHEN_CLOCK_POS: Vector2 = Vector2(96.0, 596.0)
const KITCHEN_CLOCK_R: float = 38.0
const KITCHEN_FRIDGE_RECT: Rect2 = Rect2(556.0, 432.0, 164.0, 560.0)
const KITCHEN_FRIDGE_DOOR_RECT: Rect2 = Rect2(560.0, 438.0, 160.0, 200.0)
const KITCHEN_KETTLE_STEAM: Vector2 = Vector2(252.0, 618.0)
const KITCHEN_WINDOW_RECT: Rect2 = Rect2(230.0, 262.0, 82.0, 300.0)
const KITCHEN_STEAM_EVERY: float = 0.45
const KITCHEN_FRIDGE_HUM_EVERY: Vector2 = Vector2(9.0, 16.0)
const KITCHEN_JOKE_EVERY: Vector2 = Vector2(20.0, 40.0)
const KITCHEN_NIGHT_START_H: int = 22
const KITCHEN_NIGHT_END_H: int = 6
const KITCHEN_NIGHT_TINT: Color = Color(0.13, 0.10, 0.22, 0.5)
const KITCHEN_NIGHT_LAMP: Color = Color(1.0, 0.72, 0.38, 0.55)
const KITCHEN_COUNTER_WOOD: Color = Color("#C98F58")
const KITCHEN_COUNTER_EDGE: Color = Color("#9C6A3E")
const KITCHEN_CABINET: Color = Color("#B57E4B")
const KITCHEN_ACTOR_PX: float = 184.0          # tezgâhtaki karakterin boyu
## Ana menü yerleşimi (720 genişlikli tuval birimi)
const MENU_TOP_BAR_H: float = 84.0
const MENU_NAV_H: float = 108.0
const MENU_PLAY_H: float = 112.0
const MENU_LOGO_MAX_W: float = 560.0
const MENU_LOGO_ASPECT: float = 0.30            # yükseklik / genişlik
const MENU_GEAR_SIZE: float = 64.0
const MENU_CONTENT_MAX_W: float = 680.0         # tablette içerik sütunu en fazla bu kadar geniş
const MENU_PLAY_MAX_W: float = 560.0
const MENU_COUNTER_GAP: float = 30.0            # tezgâh üst kenarı OYNA'nın bu kadar üstünde
const MENU_TAB_SLIDE_SEC: float = 0.2
const MENU_LONG_PRESS_SEC: float = 0.5
const MENU_SHEET_DIM: float = 0.35
const MENU_SHEET_SLIDE_SEC: float = 0.26
const MENU_SHEET_SWIPE_CLOSE_PX: float = 110.0
## Buton hissi: basınca 0.95, bırakınca yay; tık sesi ve kısa titreşim (ayarlardan kapanır)
const UI_PRESS_SCALE: float = 0.95
const UI_PRESS_IN_SEC: float = 0.06
const UI_RELEASE_SEC: float = 0.22
const UI_VIBRATE_MS: int = 12
const UI_TICK_SFX: String = "res://assets/sounds/tik.ogg"
## Mağaza / ikon araçları
const ICON_DIR: String = "res://assets/icon/"
const STORE_OUTPUT_DIR: String = "res://store_output/"
const STORE_SHOT_SIZE: Vector2i = Vector2i(1080, 1920)
const STORE_FEATURE_SIZE: Vector2i = Vector2i(1024, 500)
const STORE_CAPTIONS: Array[String] = [
	"Arkadaşlarınla son böcek sen ol!",
	"Annem Geldi! Küçül ve saklan",
	"13 komik böcek, hepsinin yeteneği farklı",
	"Sinirlen, paylaş, rövanş iste",
	"Sesli sohbetle mahalle toplantısı",
	"Her gün yeni görevler",
]

extends Control

## Ana menü (Faz 13B): canlı mutfak sahnesinin önünde üst çubuk (profil kartı + Kırıntı + seri),
## 5 sekme (Pazar · Böcekler · Ana Sayfa · Görevler · Arkadaşlar) ve Ana Sayfa'da logo, tezgâhtaki
## karakter, dişli ve büyük OYNA. OYNA alttan mod seçim kartını açar; basılı tutunca son mod başlar.
## Sekmeler yatay kayar, mutfak yerinde kalır. Yerleşim güvenli alana göre mutlak hesaplanır
## (KitchenScene.menu_layout) ki intro ile menü aynı kareyi paylaşsın.

const CARD_SCENE: PackedScene = preload("res://scenes/ui/CharacterCard.tscn")

const TAB_ORDER: Array[String] = ["shop", "bugs", "home", "quests", "friends"]
const TAB_NAMES: Dictionary = {"shop": "Pazar", "bugs": "Böcekler", "home": "Ana Sayfa", "quests": "Görevler", "friends": "Arkadaşlar"}
const MODE_NAMES: Dictionary = {"solo": "Tek Başına", "daily": "Günün Mutfağı", "bots": "Botlarla Oyna", "lan": "Arkadaşlarla (Aynı Wi-Fi)", "online": "Çevrimiçi"}
const MENU_CFG_SECTION: String = "menu"

# Menüye özel ölçüler
const ICON_LINE_W: float = 4.0
const NAV_ICON_SIZE: float = 44.0
const NAV_HOME_ICON: float = 56.0
const AVATAR_SIZE: float = 60.0
const PILL_ICON: float = 36.0
const MODE_CARD_H: float = 104.0
const PLAY_FONT: int = 54
const MODE_ICON: float = 76.0
const BUG_FLEE_OFFSET: float = 160.0
const POP_SEC: float = 0.24
const INPUT_BG: Color = Color("#FFFBF4")
const PANEL_SOFT_BG: Color = Color("#FFF6EA")
const QUEST_BTN_W: float = 176.0
const STREAK_CARD_ICON: float = 64.0
const STREAK_PARTY_ICON: float = 180.0
const ID_BTN_W: float = 108.0
const ID_BTN_H: float = 48.0
const OFFLINE_ALPHA: float = 0.5
const THEME_THUMB_H: float = 172.0
const LAST_MODE_TAG: Color = Color("#F2C96B")
const CARD_SIZE: Vector2 = Vector2(150.0, 172.0)   # CharacterCard küçük boyu

var _kitchen: KitchenScene = null
var _ui: Control = null
var _top_bar: HBoxContainer = null
var _profile_btn: Button = null
var _avatar: Control = null
var _profile_name: Label = null
var _profile_id: Label = null
var _crumb_btn: Button = null
var _crumb_label: Label = null
var _streak_btn: Button = null
var _streak_label: Label = null
var _pages_clip: Control = null
var _pages: Dictionary = {}
var _tab: String = "home"
var _tab_tween: Tween = null
var _nav_panel: PanelContainer = null
var _nav_buttons: Dictionary = {}
var _quest_icon: Control = null
var _friends_nav: Button = null
var _gear_btn: Button = null
var _logo: GameLogo = null
var _play_btn: Button = null
var _play_sub: Label = null
var _play_hold: Dictionary = {"down": false, "fired": false, "t": 0.0}
var _layout_rects: Dictionary = {}
var _bg_thumbs: Dictionary = {}

# Tezgâhtaki karakter: dokunma, laf balonu, 10 dokunuşta kaçış
var _bug_tap_btn: Button = null
var _bug_bubble: Label = null
var _tap_count: int = 0
var _last_tap_ms: int = 0
var _last_tap_line_idx: int = -1
var _bug_fled: bool = false
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Böcekler sekmesi
var _cards: Dictionary = {}

var name_input: LineEdit = null
var notice_label: Label = null
## Faz 12.1: Böcek Kimliği (profil kartında ve profil penceresinde)
var _id_label: Label = null
var _id_copy_btn: Button = null
var _id_share_btn: Button = null

# Yerel ağ odaları penceresi (açıkken dolu)
var _join_modal: Control = null
var rooms_list: VBoxContainer = null
var ip_input: LineEdit = null
var join_status_label: Label = null


## Faz 11.4: seri ikonu: kanat çırpan küçük böcek (alev yerine).
class StreakBugIcon extends Control:
	var _t: float = 0.0

	func _init(p_size: float = GameConfig.STREAK_ICON_SIZE) -> void:
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var c: Vector2 = size * 0.5 + Vector2(0.0, s * 0.06)
		var ink: Color = GameConfig.COLOR_INK
		var lw: float = maxf(2.0, s * 0.05)
		# Kanatlar: dikeyde açılıp kapanır
		var flap: float = 0.35 + 0.65 * absf(sin(_t * GameConfig.STREAK_WING_SPEED))
		var wing_col: Color = Color(0.93, 0.96, 1.0, 0.9)
		for side: float in [-1.0, 1.0]:
			var wc: Vector2 = c + Vector2(side * s * 0.20, -s * 0.16)
			draw_set_transform(wc, side * 0.5, Vector2(1.0, flap))
			draw_circle(Vector2.ZERO, s * 0.20, wing_col)
			draw_arc(Vector2.ZERO, s * 0.20, 0.0, TAU, 20, ink, lw * 0.7, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# Gövde ve baş
		draw_set_transform(c, 0.0, Vector2(0.72, 1.0))
		draw_circle(Vector2.ZERO, s * 0.26, GameConfig.COLOR_BROWN)
		draw_arc(Vector2.ZERO, s * 0.26, 0.0, TAU, 24, ink, lw, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var head: Vector2 = c + Vector2(0.0, -s * 0.30)
		draw_circle(head, s * 0.12, GameConfig.COLOR_BROWN.darkened(0.25))
		# Antenler hafif sallanır
		var sway: float = sin(_t * 4.0) * s * 0.04
		draw_line(head, head + Vector2(-s * 0.16 + sway, -s * 0.16), ink, lw * 0.7, true)
		draw_line(head, head + Vector2(s * 0.16 + sway, -s * 0.16), ink, lw * 0.7, true)


## Yuvarlak karakter portresi (profil kartı): krem zemin, mürekkep halka, karakter görseli.
class Avatar extends Control:
	var tex: Texture2D = null

	func _init(p_size: float = 60.0) -> void:
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_char(char_id: String) -> void:
		var cdata: Dictionary = CharacterData.get_character(char_id)
		tex = AssetHelper.texture(str(cdata["sprite_path"]), str(cdata["fallback_kind"]), GameConfig.PLAYER_SPRITE_SIZE)
		queue_redraw()

	func _draw() -> void:
		var r: float = minf(size.x, size.y) * 0.5
		var c: Vector2 = size * 0.5
		draw_circle(c + Vector2(0.0, 3.0), r, Color(0.141, 0.086, 0.055, 0.12))
		draw_circle(c, r, GameConfig.COLOR_PEACH)
		if tex != null:
			var s: float = r * 1.7
			draw_texture_rect(tex, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false)
		draw_arc(c, r - 1.5, 0.0, TAU, 32, GameConfig.COLOR_INK, 3.0, true)


## Basit çizgi ikonları: tek aile, aynı kalınlık, yuvarlak uçlar.
class MenuIcon extends Control:
	var kind: String = "gear"
	var ink: Color = Color("#24160E")
	var line_w: float = 4.0

	func _init(p_kind: String = "gear", p_size: float = 44.0, p_line_w: float = 4.0) -> void:
		kind = p_kind
		line_w = p_line_w
		custom_minimum_size = Vector2(p_size, p_size)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _seg(a: Vector2, b: Vector2) -> void:
		draw_line(a, b, ink, line_w, true)
		draw_circle(a, line_w * 0.5, ink)
		draw_circle(b, line_w * 0.5, ink)

	func _poly(pts: PackedVector2Array, closed: bool) -> void:
		for i: int in range(pts.size() - 1):
			_seg(pts[i], pts[i + 1])
		if closed and pts.size() > 2:
			_seg(pts[pts.size() - 1], pts[0])

	## Küçük böcek (mod kartı çizimleri için)
	func _bug(at: Vector2, s: float, col: Color) -> void:
		draw_set_transform(at, 0.0, Vector2(1.0, 0.7))
		draw_circle(Vector2.ZERO, s, col)
		draw_arc(Vector2.ZERO, s, 0.0, TAU, 20, ink, line_w * 0.7 / 0.7, true)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var head: Vector2 = at + Vector2(0.0, -s * 0.85)
		draw_circle(head, s * 0.42, col.darkened(0.3))
		_seg(head, head + Vector2(-s * 0.5, -s * 0.6))
		_seg(head, head + Vector2(s * 0.5, -s * 0.6))

	func _draw() -> void:
		var s: float = minf(size.x, size.y)
		var c: Vector2 = size * 0.5
		match kind:
			"gear":
				var r: float = s * 0.27
				draw_arc(c, r, 0.0, TAU, 32, ink, line_w, true)
				draw_arc(c, r * 0.4, 0.0, TAU, 20, ink, line_w, true)
				for i: int in range(8):
					var ang: float = TAU * float(i) / 8.0
					var dir: Vector2 = Vector2(cos(ang), sin(ang))
					_seg(c + dir * r, c + dir * (s * 0.42))
			"shop":
				var top_y: float = c.y - s * 0.06
				_poly(PackedVector2Array([
					Vector2(c.x - s * 0.40, top_y), Vector2(c.x - s * 0.30, c.y + s * 0.36),
					Vector2(c.x + s * 0.30, c.y + s * 0.36), Vector2(c.x + s * 0.40, top_y),
				]), true)
				draw_arc(Vector2(c.x, top_y), s * 0.24, PI, TAU, 18, ink, line_w, true)
				_seg(Vector2(c.x - s * 0.12, top_y + s * 0.12), Vector2(c.x - s * 0.10, c.y + s * 0.24))
				_seg(Vector2(c.x + s * 0.12, top_y + s * 0.12), Vector2(c.x + s * 0.10, c.y + s * 0.24))
			"quests":
				var l: float = c.x - s * 0.30
				var rr: float = c.x + s * 0.30
				var t: float = c.y - s * 0.36
				var b: float = c.y + s * 0.40
				_poly(PackedVector2Array([Vector2(l, t), Vector2(rr, t), Vector2(rr, b), Vector2(l, b)]), true)
				_seg(Vector2(c.x - s * 0.10, t), Vector2(c.x + s * 0.10, t))
				_poly(PackedVector2Array([
					Vector2(l + s * 0.12, c.y - s * 0.08), Vector2(l + s * 0.20, c.y + 0.0),
					Vector2(l + s * 0.34, c.y - s * 0.16),
				]), false)
				_seg(Vector2(l + s * 0.12, c.y + s * 0.20), Vector2(rr - s * 0.12, c.y + s * 0.20))
			"skills":
				_poly(PackedVector2Array([
					Vector2(c.x + s * 0.08, c.y - s * 0.42), Vector2(c.x - s * 0.22, c.y + s * 0.04),
					Vector2(c.x + s * 0.02, c.y + s * 0.04), Vector2(c.x - s * 0.08, c.y + s * 0.42),
					Vector2(c.x + s * 0.24, c.y - s * 0.08), Vector2(c.x + s * 0.0, c.y - s * 0.08),
				]), true)
			"guide":
				var top: float = c.y - s * 0.26
				var bot: float = c.y + s * 0.32
				_poly(PackedVector2Array([
					Vector2(c.x, top + s * 0.06), Vector2(c.x - s * 0.40, top),
					Vector2(c.x - s * 0.40, bot - s * 0.06), Vector2(c.x, bot),
				]), false)
				_poly(PackedVector2Array([
					Vector2(c.x, top + s * 0.06), Vector2(c.x + s * 0.40, top),
					Vector2(c.x + s * 0.40, bot - s * 0.06), Vector2(c.x, bot),
				]), false)
				_seg(Vector2(c.x, top + s * 0.06), Vector2(c.x, bot))
			"album":
				# İki üst üste kart (arkadaki eğik) + öndeki kartta gülen yüz
				var back: PackedVector2Array = PackedVector2Array([
					c + Vector2(-s * 0.36, -s * 0.30), c + Vector2(s * 0.10, -s * 0.40),
					c + Vector2(s * 0.22, s * 0.16), c + Vector2(-s * 0.24, s * 0.26),
				])
				draw_colored_polygon(back, Color("#E8B4BC"))
				_poly(back, true)
				var front: PackedVector2Array = PackedVector2Array([
					c + Vector2(-s * 0.16, -s * 0.24), c + Vector2(s * 0.38, -s * 0.24),
					c + Vector2(s * 0.38, s * 0.40), c + Vector2(-s * 0.16, s * 0.40),
				])
				draw_colored_polygon(front, Color("#F2C96B"))
				_poly(front, true)
				var fc: Vector2 = c + Vector2(s * 0.11, s * 0.06)
				draw_circle(fc + Vector2(-s * 0.08, -s * 0.06), line_w * 0.6, ink)
				draw_circle(fc + Vector2(s * 0.08, -s * 0.06), line_w * 0.6, ink)
				draw_arc(fc + Vector2(0.0, s * 0.02), s * 0.10, 0.2, PI - 0.2, 10, ink, line_w * 0.7, true)
			"friends":
				# İki böcek kafası + omuzlar (arkadaşlar)
				var back_c: Vector2 = c + Vector2(s * 0.16, -s * 0.12)
				draw_circle(back_c, s * 0.14, Color("#B8CDB0"))
				draw_arc(back_c, s * 0.14, 0.0, TAU, 20, ink, line_w * 0.8, true)
				draw_arc(back_c + Vector2(0.0, s * 0.36), s * 0.22, PI + 0.35, TAU - 0.35, 14, ink, line_w * 0.8, true)
				var front_c: Vector2 = c + Vector2(-s * 0.12, -s * 0.04)
				draw_circle(front_c, s * 0.16, Color("#F2C96B"))
				draw_arc(front_c, s * 0.16, 0.0, TAU, 20, ink, line_w, true)
				draw_arc(front_c + Vector2(0.0, s * 0.42), s * 0.26, PI + 0.3, TAU - 0.3, 16, ink, line_w, true)
				_seg(front_c + Vector2(-s * 0.06, -s * 0.15), front_c + Vector2(-s * 0.14, -s * 0.30))
				_seg(front_c + Vector2(s * 0.06, -s * 0.15), front_c + Vector2(s * 0.14, -s * 0.30))
			"plus":
				_seg(Vector2(c.x - s * 0.30, c.y), Vector2(c.x + s * 0.30, c.y))
				_seg(Vector2(c.x, c.y - s * 0.30), Vector2(c.x, c.y + s * 0.30))
			"crumb":
				# Küçük ekmek somunu: altın gövde, mürekkep kontur, üstte çentikler
				var pts: PackedVector2Array = PackedVector2Array()
				for i: int in range(24):
					var a: float = TAU * float(i) / 24.0
					var ry: float = s * (0.30 if sin(a) < 0.0 else 0.22)
					pts.append(c + Vector2(cos(a) * s * 0.42, sin(a) * ry + s * 0.04))
				draw_colored_polygon(pts, Color("#E8B866"))
				_poly(pts, true)
				_seg(c + Vector2(-s * 0.18, -s * 0.10), c + Vector2(-s * 0.08, -s * 0.02))
				_seg(c + Vector2(s * 0.02, -s * 0.14), c + Vector2(s * 0.12, -s * 0.06))
			"home":
				# Çatılı küçük ev, kapısı açık
				_poly(PackedVector2Array([
					Vector2(c.x - s * 0.40, c.y - s * 0.02), Vector2(c.x, c.y - s * 0.40), Vector2(c.x + s * 0.40, c.y - s * 0.02),
				]), false)
				_poly(PackedVector2Array([
					Vector2(c.x - s * 0.30, c.y - s * 0.10), Vector2(c.x - s * 0.30, c.y + s * 0.38),
					Vector2(c.x + s * 0.30, c.y + s * 0.38), Vector2(c.x + s * 0.30, c.y - s * 0.10),
				]), false)
				_poly(PackedVector2Array([
					Vector2(c.x - s * 0.09, c.y + s * 0.38), Vector2(c.x - s * 0.09, c.y + s * 0.12),
					Vector2(c.x + s * 0.09, c.y + s * 0.12), Vector2(c.x + s * 0.09, c.y + s * 0.38),
				]), false)
			"bugs":
				_bug(c + Vector2(0.0, s * 0.12), s * 0.26, GameConfig.COLOR_BROWN)
			"solo":
				_bug(c + Vector2(0.0, s * 0.10), s * 0.24, GameConfig.COLOR_BROWN)
				# Kanat hızı çizgileri
				_seg(c + Vector2(-s * 0.42, -s * 0.05), c + Vector2(-s * 0.30, -s * 0.05))
				_seg(c + Vector2(-s * 0.44, s * 0.08), c + Vector2(-s * 0.32, s * 0.08))
			"daily":
				# Takvim yaprağı + güneş
				_poly(PackedVector2Array([
					c + Vector2(-s * 0.34, -s * 0.26), c + Vector2(s * 0.34, -s * 0.26),
					c + Vector2(s * 0.34, s * 0.36), c + Vector2(-s * 0.34, s * 0.36),
				]), true)
				_seg(c + Vector2(-s * 0.34, -s * 0.10), c + Vector2(s * 0.34, -s * 0.10))
				draw_circle(c + Vector2(0.0, s * 0.14), s * 0.11, Color("#F2C96B"))
				draw_arc(c + Vector2(0.0, s * 0.14), s * 0.11, 0.0, TAU, 16, ink, line_w * 0.7, true)
			"bots":
				_bug(c + Vector2(-s * 0.16, s * 0.14), s * 0.2, GameConfig.COLOR_BROWN)
				_bug(c + Vector2(s * 0.20, s * 0.18), s * 0.16, Color("#A9BCD0"))
				# Robot böceğin anteninde şimşek
				_poly(PackedVector2Array([
					c + Vector2(s * 0.30, -s * 0.36), c + Vector2(s * 0.22, -s * 0.22),
					c + Vector2(s * 0.32, -s * 0.22), c + Vector2(s * 0.24, -s * 0.08),
				]), false)
			"wifi":
				var wc: Vector2 = c + Vector2(0.0, -s * 0.02)
				for i: int in range(3):
					var rr2: float = s * (0.14 + 0.12 * float(i))
					draw_arc(wc, rr2, -PI * 0.78, -PI * 0.22, 14, ink, line_w, true)
				draw_circle(wc, line_w * 0.9, ink)
				_bug(c + Vector2(-s * 0.26, s * 0.30), s * 0.13, GameConfig.COLOR_BROWN)
				_bug(c + Vector2(s * 0.26, s * 0.30), s * 0.13, Color("#E8B4BC"))
			"online":
				var r3: float = s * 0.34
				draw_circle(c, r3, Color("#B8CDB0"))
				draw_arc(c, r3, 0.0, TAU, 28, ink, line_w, true)
				draw_set_transform(c, 0.0, Vector2(0.45, 1.0))
				draw_arc(Vector2.ZERO, r3, 0.0, TAU, 28, ink, line_w * 0.8, true)
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				_seg(c + Vector2(-r3, 0.0), c + Vector2(r3, 0.0))
				_seg(c + Vector2(-r3 * 0.85, -r3 * 0.5), c + Vector2(r3 * 0.85, -r3 * 0.5))
			"credits":
				# Kalp
				var hp: PackedVector2Array = PackedVector2Array()
				for i: int in range(32):
					var tt: float = TAU * float(i) / 32.0
					var hx: float = 16.0 * pow(sin(tt), 3.0)
					var hy: float = -(13.0 * cos(tt) - 5.0 * cos(2.0 * tt) - 2.0 * cos(3.0 * tt) - cos(4.0 * tt))
					hp.append(c + Vector2(hx, hy) * s * 0.022)
				draw_colored_polygon(hp, Color("#E8B4BC"))
				_poly(hp, true)
			"account":
				draw_circle(c + Vector2(0.0, -s * 0.12), s * 0.16, Color("#F2C9A9"))
				draw_arc(c + Vector2(0.0, -s * 0.12), s * 0.16, 0.0, TAU, 20, ink, line_w, true)
				draw_arc(c + Vector2(0.0, s * 0.40), s * 0.30, PI + 0.25, TAU - 0.25, 16, ink, line_w, true)


func _ready() -> void:
	get_tree().paused = false
	_rng.randomize()
	Monetization.end_match_character()
	if not Monetization.is_char_unlocked(NetworkManager.selected_char_id):
		NetworkManager.save_selected_char("klasik")
	_build_layout()
	var handoff: bool = get_tree().root.has_meta("intro_handoff")
	if handoff:
		get_tree().root.remove_meta("intro_handoff")
		AudioManager.play_music_fade_in("res://assets/sounds/muzik_menu.ogg", GameConfig.MENU_MUSIC_FADE_SEC)
		# Logo ve mutfak intro'daki yerinde kalır; diğer öğeler belirir
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		for c: Control in [_top_bar, _nav_panel, _play_btn, _gear_btn]:
			c.modulate.a = 0.0
			tw.tween_property(c, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE)
	else:
		AudioManager.play_music("res://assets/sounds/muzik_menu.ogg")

	NetworkManager.get_discovery().rooms_updated.connect(_on_rooms_updated)
	NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
	NetworkManager.connection_failed.connect(_on_connection_failed)
	Monetization.kirinti_changed.connect(_on_kirinti_changed)
	Mahalle.status_changed.connect(_refresh_identity)
	Mahalle.identity_changed.connect(_refresh_identity)
	Mahalle.friends_changed.connect(_refresh_identity)
	Mahalle.invites_changed.connect(_refresh_identity)

	if not NetworkManager.pending_notice.is_empty():
		_show_notice(NetworkManager.pending_notice)
		NetworkManager.pending_notice = ""

	_refresh_profile()
	_update_crumbs(false)
	_refresh_quest_badge()
	_refresh_streak_pill()
	_refresh_identity()
	_refresh_play_sub()

	get_viewport().size_changed.connect(_relayout)
	_relayout()

	if not AudioManager.guide_seen:
		var gm_auto: GuideModal = GuideModal.new()
		add_child(gm_auto)
	else:
		_check_streak_celebration()
	# Faz 12.3: paylaşım bağlantısıyla açıldıysa "İstek gönderilsin mi?"
	if not Mahalle.pending_link_id.is_empty():
		var link_id: String = Mahalle.pending_link_id
		Mahalle.pending_link_id = ""
		FriendsUi.open_link_confirm(self, link_id)


# ---------------------------------------------------------------------------
# Yerleşim
# ---------------------------------------------------------------------------

func _build_layout() -> void:
	var font: Font = AssetHelper.get_ui_font()

	_kitchen = KitchenScene.new()
	_kitchen.name = "Kitchen"
	add_child(_kitchen)

	# Tezgâhtaki karaktere dokunma alanı (görünmez)
	_bug_tap_btn = Button.new()
	_bug_tap_btn.name = "BugTapButton"
	_bug_tap_btn.set_meta(UiFeel.META_SKIP, true)
	_bug_tap_btn.flat = true
	_bug_tap_btn.focus_mode = Control.FOCUS_NONE
	_bug_tap_btn.size = Vector2(GameConfig.KITCHEN_ACTOR_PX, GameConfig.KITCHEN_ACTOR_PX)
	for st: String in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		_bug_tap_btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	_bug_tap_btn.pressed.connect(_on_menu_bug_tapped)
	add_child(_bug_tap_btn)

	_ui = Control.new()
	_ui.name = "Ui"
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)

	_build_top_bar(font)
	_build_pages()
	_build_nav()

	_bug_bubble = Label.new()
	_bug_bubble.name = "BugBubble"
	_bug_bubble.visible = false
	_bug_bubble.z_index = 5
	_bug_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bug_bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bug_bubble.autowrap_mode = TextServer.AUTOWRAP_OFF
	ComicUiHelper.style_label(_bug_bubble, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, true)
	var bubble_sb: StyleBoxFlat = StyleBoxFlat.new()
	bubble_sb.bg_color = INPUT_BG
	bubble_sb.border_color = GameConfig.COLOR_INK
	bubble_sb.set_border_width_all(3)
	bubble_sb.set_corner_radius_all(16)
	bubble_sb.content_margin_left = GameConfig.SP_S
	bubble_sb.content_margin_right = GameConfig.SP_S
	bubble_sb.content_margin_top = GameConfig.SP_XS
	bubble_sb.content_margin_bottom = GameConfig.SP_XS
	_bug_bubble.add_theme_stylebox_override("normal", bubble_sb)
	(_pages["home"] as Control).add_child(_bug_bubble)


func _build_top_bar(font: Font) -> void:
	_top_bar = HBoxContainer.new()
	_top_bar.name = "TopBar"
	_top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_bar.add_theme_constant_override("separation", GameConfig.SP_XS)
	_ui.add_child(_top_bar)

	# Profil kartı: portre + ad + Böcek Kimliği; dokununca profil penceresi
	_profile_btn = Button.new()
	_profile_btn.name = "ProfileCard"
	_profile_btn.focus_mode = Control.FOCUS_NONE
	_profile_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_profile_btn.clip_contents = true
	ComicUiHelper.style_bitten_button(_profile_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_SMALL, 120)
	_profile_btn.pressed.connect(_open_profile_sheet)
	_top_bar.add_child(_profile_btn)
	var ph: HBoxContainer = HBoxContainer.new()
	ph.name = "Box"
	ph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ph.offset_left = 8.0
	ph.offset_right = -10.0
	ph.offset_top = 2.0
	ph.offset_bottom = -6.0
	ph.add_theme_constant_override("separation", GameConfig.SP_XS)
	_profile_btn.add_child(ph)
	var av: Avatar = Avatar.new(AVATAR_SIZE)
	av.name = "Avatar"
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ph.add_child(av)
	_avatar = av
	var pv: VBoxContainer = VBoxContainer.new()
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pv.add_theme_constant_override("separation", -6)
	ph.add_child(pv)
	_profile_name = Label.new()
	_profile_name.name = "ProfileName"
	_profile_name.clip_text = true
	_profile_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ComicUiHelper.style_label(_profile_name, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	pv.add_child(_profile_name)
	_profile_id = Label.new()
	_profile_id.name = "ProfileId"
	_profile_id.clip_text = true
	_profile_id.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	ComicUiHelper.style_label(_profile_id, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	pv.add_child(_profile_id)

	_crumb_btn = _make_icon_button("crumb", "0", GameConfig.FS_BODY, false, PILL_ICON)
	_crumb_btn.name = "CrumbPill"
	ComicUiHelper.style_bitten_button(_crumb_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_BODY, 121)
	_crumb_label = _crumb_btn.get_node("Box/Label") as Label
	_crumb_btn.tooltip_text = "Kırıntı bakiyen"
	_crumb_btn.pressed.connect(_open_shop)
	_top_bar.add_child(_crumb_btn)

	# Faz 11.4: seri hapı (kanat çırpan böcek + gün sayısı)
	_streak_btn = Button.new()
	_streak_btn.name = "StreakPill"
	_streak_btn.focus_mode = Control.FOCUS_NONE
	_streak_btn.tooltip_text = "Seri: her gün 1 maç oyna"
	var sbox: HBoxContainer = HBoxContainer.new()
	sbox.name = "Box"
	sbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sbox.alignment = BoxContainer.ALIGNMENT_CENTER
	sbox.add_theme_constant_override("separation", 2)
	sbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sbox.offset_left = 14.0
	sbox.offset_right = -14.0
	_streak_btn.add_child(sbox)
	var sicon: StreakBugIcon = StreakBugIcon.new(GameConfig.STREAK_ICON_SIZE)
	sicon.name = "Icon"
	sicon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sbox.add_child(sicon)
	_streak_label = Label.new()
	_streak_label.name = "Label"
	_streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_streak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(_streak_label, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	sbox.add_child(_streak_label)
	sbox.minimum_size_changed.connect(_fit_pill.bind(_streak_btn))
	ComicUiHelper.style_bitten_button(_streak_btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_BODY, 122)
	_streak_btn.pressed.connect(_open_quests_modal)
	_top_bar.add_child(_streak_btn)


func _build_pages() -> void:
	_pages_clip = Control.new()
	_pages_clip.name = "Pages"
	_pages_clip.clip_contents = true
	_pages_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_pages_clip)
	for t: String in TAB_ORDER:
		var page: Control = Control.new()
		page.name = "Page_%s" % t
		page.mouse_filter = Control.MOUSE_FILTER_IGNORE
		page.visible = t == "home"
		page.set_meta("embed_page", true)
		page.set_meta("modal_host", self)
		_pages_clip.add_child(page)
		_pages[t] = page
	_build_home_page(_pages["home"] as Control)


func _build_home_page(page: Control) -> void:
	_logo = GameLogo.create(true, true)
	_logo.name = "Logo"
	page.add_child(_logo)

	_gear_btn = Button.new()
	_gear_btn.name = "GearButton"
	_gear_btn.tooltip_text = "Ayarlar ve daha fazlası"
	_gear_btn.focus_mode = Control.FOCUS_NONE
	ComicUiHelper.style_bitten_button(_gear_btn, GameConfig.COLOR_CREAM, AssetHelper.get_ui_font(), GameConfig.FS_SMALL, 124)
	var gi: MenuIcon = MenuIcon.new("gear", GameConfig.MENU_GEAR_SIZE * 0.62, 3.5)
	gi.set_anchors_preset(Control.PRESET_CENTER)
	gi.position = -gi.custom_minimum_size * 0.5
	_gear_btn.add_child(gi)
	_gear_btn.pressed.connect(_open_more_sheet)
	page.add_child(_gear_btn)

	notice_label = Label.new()
	notice_label.name = "NoticeLabel"
	notice_label.visible = false
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	notice_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(notice_label, GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED, true)
	notice_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	notice_label.add_theme_constant_override("outline_size", 8)
	page.add_child(notice_label)

	# Büyük OYNA: dokun = mod seçim kartı, basılı tut = son mod
	_play_btn = Button.new()
	_play_btn.name = "PlayButton"
	_play_btn.focus_mode = Control.FOCUS_NONE
	ComicUiHelper.style_bitten_button(_play_btn, GameConfig.COLOR_GREEN_GO, AssetHelper.get_title_font(), GameConfig.FS_H1, 103)
	_play_btn.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	var pv: VBoxContainer = VBoxContainer.new()
	pv.name = "Box"
	pv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pv.alignment = BoxContainer.ALIGNMENT_CENTER
	pv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pv.offset_bottom = -4.0
	pv.add_theme_constant_override("separation", -18)
	_play_btn.add_child(pv)
	var pl: Label = Label.new()
	pl.text = "OYNA"
	pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ComicUiHelper.style_label(pl, PLAY_FONT, GameConfig.COLOR_INK, true)
	pl.add_theme_color_override("font_outline_color", Color(1.0, 0.97, 0.9, 0.6))
	pl.add_theme_constant_override("outline_size", 4)
	pv.add_child(pl)
	_play_sub = Label.new()
	_play_sub.name = "PlaySub"
	_play_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_play_sub.clip_text = true
	ComicUiHelper.style_label(_play_sub, GameConfig.FS_TINY, Color(GameConfig.COLOR_INK, 0.75), false)
	pv.add_child(_play_sub)
	_play_btn.button_down.connect(func() -> void:
		_play_hold["down"] = true
		_play_hold["fired"] = false
		_play_hold["t"] = 0.0
	)
	_play_btn.button_up.connect(func() -> void:
		_play_hold["down"] = false
	)
	_play_btn.pressed.connect(func() -> void:
		if bool(_play_hold["fired"]):
			return
		_open_mode_sheet()
	)
	page.add_child(_play_btn)


func _build_nav() -> void:
	_nav_panel = PanelContainer.new()
	_nav_panel.name = "NavBar"
	ComicUiHelper.style_bitten_panel(_nav_panel, GameConfig.COLOR_CREAM, 130, GameConfig.SP_XS)
	_ui.add_child(_nav_panel)
	var nav_row: HBoxContainer = HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 2)
	_nav_panel.add_child(nav_row)
	var icons: Dictionary = {"shop": "shop", "bugs": "bugs", "home": "home", "quests": "quests", "friends": "friends"}
	for t: String in TAB_ORDER:
		var is_home: bool = t == "home"
		var nb: Button = _make_icon_button(str(icons[t]), str(TAB_NAMES[t]), GameConfig.FS_TINY, true, NAV_HOME_ICON if is_home else NAV_ICON_SIZE)
		nb.name = "Nav_%s" % t
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.size_flags_stretch_ratio = 1.25 if is_home else 1.0
		nb.pressed.connect(_switch_tab.bind(t))
		nav_row.add_child(nb)
		_nav_buttons[t] = nb
		if t == "quests":
			_quest_icon = nb.get_node("Box/Icon") as Control
		elif t == "friends":
			_friends_nav = nb
	_style_nav()


func _style_nav() -> void:
	for t: String in TAB_ORDER:
		var nb: Button = _nav_buttons[t] as Button
		var active: bool = t == _tab
		nb.flat = false
		nb.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		var empty: StyleBoxEmpty = StyleBoxEmpty.new()
		var on_sb: StyleBoxFlat = StyleBoxFlat.new()
		on_sb.bg_color = Color(GameConfig.COLOR_PEACH, 0.75)
		on_sb.border_color = Color(GameConfig.COLOR_INK, 0.35)
		on_sb.set_border_width_all(2)
		on_sb.set_corner_radius_all(18)
		var base: StyleBox = on_sb if active else empty
		nb.add_theme_stylebox_override("normal", base)
		nb.add_theme_stylebox_override("hover", base)
		nb.add_theme_stylebox_override("focus", empty)
		nb.add_theme_stylebox_override("pressed", on_sb)
		nb.add_theme_stylebox_override("hover_pressed", on_sb)
		var lbl: Label = nb.get_node("Box/Label") as Label
		ComicUiHelper.style_label(lbl, GameConfig.FS_TINY, GameConfig.COLOR_INK if active else GameConfig.COLOR_BROWN, active)


## Görünür alan ve güvenli alana göre üst çubuk, sayfalar, alt gezinme ve Ana Sayfa öğelerinin yeri.
func _relayout() -> void:
	if _ui == null or not is_inside_tree():
		return
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var ins: Dictionary = ComicUiHelper.safe_insets(self)
	var L: Dictionary = KitchenScene.menu_layout(vis, ins)
	_layout_rects = L
	_kitchen.counter_y = float(L["counter_y"])
	var tb: Rect2 = L["top_bar"] as Rect2
	_top_bar.position = tb.position
	_top_bar.size = tb.size
	for b: Button in [_profile_btn, _crumb_btn, _streak_btn]:
		b.custom_minimum_size.y = tb.size.y
	_fit_pill(_crumb_btn)
	_fit_pill(_streak_btn)
	var nav: Rect2 = L["nav"] as Rect2
	_nav_panel.position = nav.position
	_nav_panel.size = nav.size
	_nav_panel.custom_minimum_size = nav.size
	var pr: Rect2 = L["pages"] as Rect2
	_pages_clip.position = pr.position
	_pages_clip.size = pr.size
	for t: String in TAB_ORDER:
		var page: Control = _pages[t] as Control
		page.size = pr.size
		if t == _tab:
			page.position = Vector2.ZERO
	# Ana Sayfa öğeleri (sayfa koordinatı)
	var lr: Rect2 = L["logo"] as Rect2
	_logo.position = lr.position - pr.position
	_logo.size = lr.size
	var gs: float = GameConfig.MENU_GEAR_SIZE
	_gear_btn.size = Vector2(gs, gs)
	_gear_btn.position = Vector2(pr.size.x - gs, 0.0)
	var play: Rect2 = L["play"] as Rect2
	_play_btn.position = play.position - pr.position
	_play_btn.size = play.size
	notice_label.size = Vector2(play.size.x, 0.0)
	notice_label.position = Vector2(_play_btn.position.x, _logo.position.y + _logo.size.y + GameConfig.SP_XS)
	_place_actor_tap()
	for t: String in TAB_ORDER:
		if t != "home" and (_pages[t] as Control).get_child_count() > 0:
			_fit_page_content(_pages[t] as Control)


func _place_actor_tap() -> void:
	if _kitchen == null:
		return
	var home: Vector2 = _kitchen.actor_home()
	_bug_tap_btn.position = home - _bug_tap_btn.size * 0.5
	_bug_tap_btn.visible = _tab == "home" and not _bug_fled


func _make_spacer(ratio: float) -> Control:
	var sp: Control = Control.new()
	sp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sp.size_flags_stretch_ratio = ratio
	return sp


## İçinde çizilmiş ikon + etiket olan buton (dikey: alt gezinme, yatay: hap).
func _make_icon_button(icon_kind: String, text: String, font_size: int, vertical: bool, icon_size: float) -> Button:
	var btn: Button = Button.new()
	btn.focus_mode = Control.FOCUS_NONE
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.name = "Box"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0 if vertical else GameConfig.SP_XS)
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not vertical:
		box.offset_left = 18.0
		box.offset_right = -18.0
	btn.add_child(box)

	var icon: MenuIcon = MenuIcon.new(icon_kind, icon_size, ICON_LINE_W if icon_size >= 40.0 else 3.5)
	icon.name = "Icon"
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.add_child(icon)

	var lbl: Label = Label.new()
	lbl.name = "Label"
	lbl.text = text
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(lbl, font_size, GameConfig.COLOR_INK, false)
	box.add_child(lbl)
	if not vertical:
		box.minimum_size_changed.connect(_fit_pill.bind(btn))
	return btn


## Yatay ikonlu butonun genişliğini içeriğine göre ayarlar.
func _fit_pill(btn: Button) -> void:
	var box: Control = btn.get_node_or_null("Box") as Control
	if box != null:
		btn.custom_minimum_size.x = box.get_combined_minimum_size().x + 36.0


func _style_line_edit(le: LineEdit) -> void:
	le.add_theme_font_override("font", AssetHelper.get_ui_font())
	le.add_theme_font_size_override("font_size", GameConfig.FS_BODY)
	le.add_theme_color_override("font_color", GameConfig.COLOR_DARK_TEXT)
	le.add_theme_color_override("font_placeholder_color", Color("#9A887C"))
	le.add_theme_color_override("caret_color", GameConfig.COLOR_INK)
	le.add_theme_color_override("selection_color", Color("#F5C9A6"))
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = INPUT_BG
	sb.border_color = ComicUiHelper.INK_COLOR
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.content_margin_left = GameConfig.SP_S
	sb.content_margin_right = GameConfig.SP_S
	sb.content_margin_top = GameConfig.SP_XS
	sb.content_margin_bottom = GameConfig.SP_XS
	var focus_sb: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
	focus_sb.border_color = Color("#B9773F")
	le.add_theme_stylebox_override("normal", sb)
	le.add_theme_stylebox_override("focus", focus_sb)
	le.add_theme_stylebox_override("read_only", sb)


# ---------------------------------------------------------------------------
# Sekmeler: yatay kayma (0.2 sn), mutfak yerinde kalır
# ---------------------------------------------------------------------------

func _switch_tab(t: String) -> void:
	if not _pages.has(t):
		return
	if t == _tab:
		if t != "home":
			_build_page(t)
		return
	var old: String = _tab
	var old_page: Control = _pages[old] as Control
	var new_page: Control = _pages[t] as Control
	_tab = t
	_style_nav()
	_build_page(t)
	if old == "shop":
		_after_shop_closed()
	var w: float = _pages_clip.size.x
	var dir: float = 1.0 if TAB_ORDER.find(t) > TAB_ORDER.find(old) else -1.0
	new_page.visible = true
	new_page.position = Vector2(w * dir, 0.0)
	if _tab_tween != null and _tab_tween.is_valid():
		_tab_tween.kill()
		for other: String in TAB_ORDER:
			if other != t and other != old:
				(_pages[other] as Control).visible = false
	_tab_tween = create_tween()
	_tab_tween.set_parallel(true)
	_tab_tween.tween_property(new_page, "position:x", 0.0, GameConfig.MENU_TAB_SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tab_tween.tween_property(old_page, "position:x", -w * dir, GameConfig.MENU_TAB_SLIDE_SEC).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tab_tween.chain().tween_callback(func() -> void:
		if is_instance_valid(old_page) and _tab != old:
			old_page.visible = false
			if old != "home":
				_clear_page(old_page)
	)
	_kitchen.show_actor = true
	_place_actor_tap()


func current_tab() -> String:
	return _tab


func _clear_page(page: Control) -> void:
	for ch: Node in page.get_children():
		page.remove_child(ch)
		ch.queue_free()


## Sekme içeriğini (yeniden) kurar. Ana Sayfa kalıcıdır.
func _build_page(t: String) -> void:
	if t == "home":
		return
	var page: Control = _pages[t] as Control
	_clear_page(page)
	match t:
		"shop":
			var sh: ShopModal = ShopModal.new()
			sh.embedded = true
			sh.name = "ShopPage"
			page.add_child(sh)
			sh.character_equipped.connect(_on_card_selected)
		"bugs":
			_build_bugs_page(page)
		"quests":
			_build_quests_page(page)
		"friends":
			_commit_name()
			var froot: Control = FriendsUi.open_friends(page)
			froot.name = "FriendsPage"
	_fit_page_content(page)


## Gömülü sayfanın kökü sekmeyi doldursun.
func _fit_page_content(page: Control) -> void:
	for ch: Node in page.get_children():
		if ch is Control:
			var c: Control = ch as Control
			c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Sekme içeriği için kâğıt panel + başlık + kaydırılan gövde.
func _page_shell(page: Control, title_text: String) -> VBoxContainer:
	var m: Dictionary = ComicUiHelper.build_modal(page, title_text, GameConfig.COLOR_CREAM)
	(m["root"] as Control).name = "PageRoot"
	return m["body"] as VBoxContainer


func _build_bugs_page(page: Control) -> void:
	var body: VBoxContainer = _page_shell(page, "BÖCEKLERİN")
	_hint_label(body, "Kime dokunursan o uçar. Yeteneklerine aşağıdan bakabilirsin.")
	var grid: GridContainer = GridContainer.new()
	grid.name = "CharGrid"
	var cols: int = maxi(2, int((page.size.x - 80.0) / (CARD_SIZE.x + GameConfig.SP_S)))
	grid.columns = cols
	grid.add_theme_constant_override("h_separation", GameConfig.SP_S)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_S)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(grid)
	_cards.clear()
	var owned: Array[String] = _owned_char_ids()
	for cid: String in owned:
		var card: PanelContainer = CARD_SCENE.instantiate() as PanelContainer
		grid.add_child(card)
		card.setup(cid)
		card.set_compact_wanted(true)
		card.card_selected.connect(_on_card_selected)
		_cards[cid] = card
	if owned.size() < CharacterData.ALL_ORDER.size():
		var more: Button = _make_icon_button("plus", "Pazar'da daha\nfazla böcek", GameConfig.FS_TINY, true, 40.0)
		more.name = "MoreBugsCard"
		more.custom_minimum_size = CARD_SIZE
		ComicUiHelper.style_bitten_button(more, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_TINY, 140)
		more.pressed.connect(_switch_tab.bind("shop"))
		grid.add_child(more)
	_refresh_card_selection(NetworkManager.selected_char_id)

	var skills_btn: Button = _modal_button("Yeteneklerine Bak", GameConfig.COLOR_GOLD, 72.0)
	skills_btn.name = "SkillsButton"
	skills_btn.pressed.connect(_open_skills)
	body.add_child(skills_btn)


func _build_quests_page(page: Control) -> void:
	var body: VBoxContainer = _page_shell(page, "GÖREVLER")
	body.add_child(_build_streak_card())
	_section_label(body, "Bugünün görevleri")
	_hint_label(body, "Herkes bugün aynı 3 görevi alır. Arkadaşınla yarış!")
	for q: Dictionary in Monetization.get_daily_quests():
		body.add_child(_build_quest_row(q))
	body.add_child(_build_surprise_box())


# ---------------------------------------------------------------------------
# Tezgâhtaki karakter
# ---------------------------------------------------------------------------

func _show_bug_bubble(line_txt: String) -> void:
	var page: Control = _pages["home"] as Control
	_bug_bubble.text = line_txt
	_bug_bubble.size = Vector2.ZERO
	var bsz: Vector2 = _bug_bubble.get_combined_minimum_size()
	var home: Vector2 = _kitchen.actor_home() - _pages_clip.position
	var bx: float = clampf(home.x - bsz.x * 0.5, 0.0, page.size.x - bsz.x)
	_bug_bubble.position = Vector2(bx, home.y - GameConfig.KITCHEN_ACTOR_PX * 0.55 - bsz.y)
	_bug_bubble.visible = true
	_bug_bubble.modulate.a = 1.0


func _on_menu_bug_tapped() -> void:
	if _bug_fled:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_tap_ms <= 1500:
		_tap_count += 1
	else:
		_tap_count = 1
	_last_tap_ms = now_ms

	var cid: String = NetworkManager.selected_char_id
	var cdata: Dictionary = CharacterData.get_character(cid)
	_kitchen.poke_actor()
	var vis: Vector2 = ComicUiHelper.visible_size(self)

	if _tap_count >= 10:
		_bug_fled = true
		_tap_count = 0
		_place_actor_tap()
		AudioManager.play_character_voice(cid, "kactim")
		_show_bug_bubble(str(cdata.get("flee_line", "Tamam, ben kaçtım!")))
		var away: float = vis.x * 0.5 + BUG_FLEE_OFFSET
		var ftw: Tween = create_tween()
		ftw.tween_property(_kitchen, "actor_offset:x", away, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		ftw.tween_interval(2.0)
		ftw.tween_property(_kitchen, "actor_offset:x", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		ftw.tween_callback(func() -> void:
			_bug_fled = false
			_bug_bubble.visible = false
			_place_actor_tap()
		)
		return

	var line_txt: String = ""
	if _tap_count == 3:
		AudioManager.play_character_voice(cid, "durtme")
		line_txt = str(cdata.get("poke_line", "Dürtme beni!"))
	else:
		var taps: Array = cdata.get("tap_lines", ["Efendim?"]) as Array
		var idx: int = _rng.randi_range(0, maxi(taps.size(), 1) - 1)
		if taps.size() > 1 and idx == _last_tap_line_idx:
			idx = (idx + 1) % taps.size()
		_last_tap_line_idx = idx
		line_txt = str(taps[idx]) if not taps.is_empty() else "Efendim?"
		AudioManager.play_character_voice(cid, "dokun_%d" % (idx + 1))

	_show_bug_bubble(line_txt)
	var btw: Tween = create_tween()
	btw.tween_interval(1.1)
	btw.tween_property(_bug_bubble, "modulate:a", 0.0, 0.35)
	btw.tween_callback(func() -> void:
		if is_instance_valid(_bug_bubble):
			_bug_bubble.visible = false
	)


func _process(delta: float) -> void:
	# OYNA'ya basılı tutma: süre dolunca son mod doğrudan başlar
	if bool(_play_hold["down"]) and not bool(_play_hold["fired"]):
		_play_hold["t"] = float(_play_hold["t"]) + delta
		if float(_play_hold["t"]) >= GameConfig.MENU_LONG_PRESS_SEC:
			_play_hold["fired"] = true
			if AudioManager.is_vibration_enabled and OS.has_feature("mobile"):
				Input.vibrate_handheld(30)
			_start_last_mode()


# ---------------------------------------------------------------------------
# Profil, Kırıntı, rozetler
# ---------------------------------------------------------------------------

func _refresh_profile() -> void:
	if _profile_name == null:
		return
	var nm: String = NetworkManager.local_player_name.strip_edges()
	_profile_name.text = nm if not nm.is_empty() else "Böcek"
	(_avatar as Avatar).set_char(NetworkManager.selected_char_id)
	if _kitchen != null:
		_kitchen.set_actor(NetworkManager.selected_char_id)
	_refresh_identity()


func _format_thousands(n: int) -> String:
	var s: String = str(absi(n))
	var out: String = ""
	var count: int = 0
	for i: int in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "." + out
	return ("-" + out) if n < 0 else out


func _update_crumbs(pop: bool) -> void:
	if _crumb_label == null:
		return
	_crumb_label.text = _format_thousands(Monetization.kirinti)
	_fit_pill.call_deferred(_crumb_btn)
	if pop:
		_pop_control(_crumb_btn, 1.12)


func _on_kirinti_changed(_new_amount: int) -> void:
	_update_crumbs(true)


func _pop_control(ctrl: Control, peak: float) -> void:
	if ctrl == null or not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tw: Tween = ctrl.create_tween()
	tw.tween_property(ctrl, "scale", Vector2(peak, peak), POP_SEC * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, POP_SEC * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Görevler rozeti: alınabilir ödül sayısı; ödül yok ama bitmemiş görev varsa küçük nokta.
func _refresh_quest_badge() -> void:
	if _quest_icon == null:
		return
	var n: int = Monetization.pending_reward_count()
	ComicUiHelper.set_badge_dot(_quest_icon, n > 0 or Monetization.has_unfinished_quests(), n)
	_refresh_streak_pill()


func _show_notice(text: String) -> void:
	if notice_label == null:
		return
	notice_label.text = text
	notice_label.visible = not text.is_empty()


# ---------------------------------------------------------------------------
# Böcek seçimi
# ---------------------------------------------------------------------------

func _owned_char_ids() -> Array[String]:
	var ids: Array[String] = []
	for cid: String in CharacterData.ALL_ORDER:
		if Monetization.is_char_unlocked(cid):
			ids.append(cid)
	# Seçili karakter artık açık değilse (deneme hakkı bitti) varsayılana dön.
	if not ids.has(NetworkManager.selected_char_id):
		NetworkManager.save_selected_char("klasik")
	return ids


func _on_card_selected(char_id: String) -> void:
	NetworkManager.save_selected_char(char_id)
	if _tab == "bugs":
		if not _cards.has(char_id):
			_build_page("bugs")
		else:
			_refresh_card_selection(char_id)
	_refresh_profile()


func _refresh_card_selection(selected_id: String) -> void:
	for cid: String in _cards.keys():
		var card: PanelContainer = _cards[cid] as PanelContainer
		if is_instance_valid(card):
			card.set_selected(cid == selected_id)


func _on_name_changed(new_text: String) -> void:
	NetworkManager.save_player_name(new_text)
	_refresh_profile()


## İsim kutusu açıksa yazılanı kaydeder (kutu yalnızca profil penceresinde).
func _commit_name() -> void:
	if name_input != null and is_instance_valid(name_input):
		NetworkManager.save_player_name(name_input.text)


# ---------------------------------------------------------------------------
# Sekme ve pencere hedefleri (eski giriş noktaları da buraya bağlanır)
# ---------------------------------------------------------------------------

func _open_shop() -> void:
	_switch_tab("shop")


func _after_shop_closed() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	_update_crumbs(false)
	_refresh_quest_badge()
	_refresh_profile()


func _open_skills() -> void:
	var sm: SkillsModal = SkillsModal.new()
	add_child(sm)
	sm.open_for(NetworkManager.selected_char_id, true)
	sm.character_chosen.connect(_on_card_selected)


## Faz 12.3: Arkadaşlar sekmesi (ilk girişte kimlik alınır)
func _open_friends_screen() -> void:
	_switch_tab("friends")


## Eski "Görevler" penceresi artık sekme; ödül alınca sekme yeniden kurulur.
func _open_quests_modal() -> void:
	if _tab == "quests":
		_build_page("quests")
	else:
		_switch_tab("quests")


## Profil kartı, Böcek Kimliği satırı, Arkadaşlar rozeti ve internet yokken gri görünüm.
func _refresh_identity() -> void:
	var has_id: bool = Mahalle.has_account()
	if _profile_id != null:
		_profile_id.text = Mahalle.formatted_id() if has_id else "Kimlik çevrimiçi ilk girişte"
	if _id_label != null and is_instance_valid(_id_label):
		_id_label.text = "Böcek Kimliğin: %s" % Mahalle.formatted_id() if has_id else "Böcek Kimliğin çevrimiçi ilk girişte verilir"
		_id_copy_btn.visible = has_id
		_id_share_btn.visible = has_id
	if _friends_nav != null:
		# Rozet: gelen istekler + bekleyen davetler
		var n_in: int = Mahalle.requests_in.size() + Mahalle.live_invites().size()
		ComicUiHelper.set_badge_dot(_friends_nav.get_node("Box/Icon") as Control, n_in > 0, n_in)
		_friends_nav.modulate = Color(1.0, 1.0, 1.0, 1.0 if Mahalle.reachable else OFFLINE_ALPHA)


func _open_album() -> void:
	AlbumModal.open(self)


func _open_guide() -> void:
	var gm: GuideModal = GuideModal.new()
	add_child(gm)


func _open_credits() -> void:
	CreditsModal.open(self)


## Profil penceresi: portre, ad, Böcek Kimliği (kopyala/paylaş) ve menü bağlantıları.
func _open_profile_sheet() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "PROFİLİN", GameConfig.COLOR_CREAM, 0.0, true, true)
	var root: Control = m["root"] as Control
	root.name = "ModalProfile"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var font: Font = AssetHelper.get_ui_font()

	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", GameConfig.SP_M)
	body.add_child(head)
	var av: Avatar = Avatar.new(104.0)
	av.set_char(NetworkManager.selected_char_id)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(av)
	var hv: VBoxContainer = VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 4)
	head.add_child(hv)
	var nl: Label = Label.new()
	nl.text = "Böcek adın (en fazla %d harf)" % GameConfig.MAX_NAME_LENGTH
	nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(nl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	hv.add_child(nl)
	name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.placeholder_text = "Böcek"
	name_input.max_length = GameConfig.MAX_NAME_LENGTH
	name_input.text = NetworkManager.local_player_name
	name_input.custom_minimum_size = Vector2(0.0, 56.0)
	_style_line_edit(name_input)
	name_input.text_changed.connect(_on_name_changed)
	hv.add_child(name_input)

	var id_row: HBoxContainer = HBoxContainer.new()
	id_row.name = "IdRow"
	id_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	body.add_child(id_row)
	_id_label = Label.new()
	_id_label.name = "IdLabel"
	_id_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_id_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(_id_label, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	id_row.add_child(_id_label)
	_id_copy_btn = Button.new()
	_id_copy_btn.name = "IdCopy"
	_id_copy_btn.text = "Kopyala"
	_id_copy_btn.custom_minimum_size = Vector2(ID_BTN_W, ID_BTN_H)
	ComicUiHelper.style_bitten_button(_id_copy_btn, GameConfig.COLOR_SAGE, font, GameConfig.FS_TINY, 131)
	_id_copy_btn.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(Mahalle.formatted_id())
		_show_notice("Kimliğin panoda: %s" % Mahalle.formatted_id())
	)
	id_row.add_child(_id_copy_btn)
	_id_share_btn = Button.new()
	_id_share_btn.name = "IdShare"
	_id_share_btn.text = "Paylaş"
	_id_share_btn.custom_minimum_size = Vector2(ID_BTN_W, ID_BTN_H)
	ComicUiHelper.style_bitten_button(_id_share_btn, GameConfig.COLOR_DUST_BLUE, font, GameConfig.FS_TINY, 132)
	_id_share_btn.pressed.connect(func() -> void:
		var msg: String = FriendsUi.share_identity()
		if not msg.is_empty():
			_show_notice(msg)
	)
	id_row.add_child(_id_share_btn)
	_refresh_identity()

	_build_menu_links(body, root)
	root.tree_exiting.connect(func() -> void:
		_commit_name()
		_refresh_profile()
	)


## Dişli: Albüm, Ayarlar, Nasıl Oynanır, Emeği Geçenler (+ Hesabım)
func _open_more_sheet() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "MENÜ", GameConfig.COLOR_CREAM, 0.0, true, true)
	var root: Control = m["root"] as Control
	root.name = "ModalMore"
	_build_menu_links(m["body"] as VBoxContainer, root)


func _build_menu_links(body: VBoxContainer, root: Control) -> void:
	var grid: GridContainer = GridContainer.new()
	grid.name = "MenuLinks"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GameConfig.SP_S)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_S)
	body.add_child(grid)
	var items: Array[Array] = [
		["settings", "gear", "Ayarlar", _open_settings_modal],
		["album", "album", "Albüm", _open_album],
		["guide", "guide", "Nasıl Oynanır", _open_guide],
		["credits", "credits", "Emeği Geçenler", _open_credits],
		["account", "account", "Hesabım", func() -> void: FriendsUi.open_account(self)],
	]
	for it: Array in items:
		var b: Button = _make_icon_button(str(it[1]), str(it[2]), GameConfig.FS_SMALL, false, 34.0)
		b.name = "Link_%s" % str(it[0])
		b.custom_minimum_size.y = 72.0
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ComicUiHelper.style_bitten_button(b, PANEL_SOFT_BG, AssetHelper.get_ui_font(), GameConfig.FS_SMALL, 150)
		var cb: Callable = it[3] as Callable
		b.pressed.connect(func() -> void:
			ComicUiHelper.close_modal(root)
			cb.call()
		)
		grid.add_child(b)


# ---------------------------------------------------------------------------
# OYNA: mod seçim kartı ve son mod
# ---------------------------------------------------------------------------

static func _menu_cfg_get(key: String, def: Variant) -> Variant:
	var cfg: ConfigFile = ConfigFile.new()
	if cfg.load(GameConfig.SETTINGS_PATH) != OK:
		return def
	return cfg.get_value(MENU_CFG_SECTION, key, def)


static func _menu_cfg_set(key: String, value: Variant) -> void:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(GameConfig.SETTINGS_PATH)
	cfg.set_value(MENU_CFG_SECTION, key, value)
	cfg.save(GameConfig.SETTINGS_PATH)


static func last_mode() -> String:
	var m: String = str(_menu_cfg_get("last_mode", "solo"))
	return m if MODE_NAMES.has(m) else "solo"


func _remember_mode(mode: String) -> void:
	_menu_cfg_set("last_mode", mode)
	_refresh_play_sub()


func _refresh_play_sub() -> void:
	if _play_sub != null:
		_play_sub.text = "Basılı tut: %s" % str(MODE_NAMES[last_mode()])


func _open_mode_sheet() -> void:
	_commit_name()
	var m: Dictionary = ComicUiHelper.build_modal(self, "NASIL OYNAYALIM?", GameConfig.COLOR_CREAM, 0.0, true, true)
	var root: Control = m["root"] as Control
	root.name = "ModalPlay"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var last: String = last_mode()

	var solo_card: PanelContainer = _mode_card(root, "solo", "Tek Başına", "Mutfak senin, terlikler senin. Hemen uç.", last == "solo" or last == "daily", _on_solo_pressed)
	var daily: Button = _modal_button("Günün Mutfağı · bugün herkes aynı parkurda", GameConfig.COLOR_DUST_BLUE, 56.0, GameConfig.FS_SMALL)
	daily.name = "Mode_daily"
	daily.clip_text = true
	daily.pressed.connect(func() -> void:
		ComicUiHelper.close_modal(root)
		_on_daily_pressed()
	)
	(solo_card.get_node("V") as VBoxContainer).add_child(daily)
	body.add_child(solo_card)
	body.add_child(_mode_card(root, "bots", "Botlarla Oyna", "İnternet yoksa mahallenin botlarıyla yarış.", last == "bots", _open_bots_modal))
	body.add_child(_mode_card(root, "lan", "Arkadaşlarla (Aynı Wi-Fi)", "Aynı modemdeyseniz biri oda kursun.", last == "lan", _open_lan_sheet))
	var online: PanelContainer = _mode_card(root, "online", "Çevrimiçi", "Uzaktaki kankayla kodla buluş ya da rastgele sataş.", last == "online", _open_online_modal)
	online.modulate.a = 1.0 if Mahalle.reachable else 0.75
	body.add_child(online)


## Mod kartı: solda küçük çizim, sağda başlık ve tek satır açıklama. Son mod vurgulu.
func _mode_card(root: Control, mode: String, title: String, desc: String, is_last: bool, action: Callable) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "Card_%s" % mode
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = Color("#FBEFC4") if is_last else PANEL_SOFT_BG
	sb.border_color = GameConfig.COLOR_INK if is_last else Color(GameConfig.COLOR_BROWN, 0.5)
	sb.set_border_width_all(4 if is_last else 2)
	sb.corner_radius_top_left = 20
	sb.corner_radius_top_right = 17
	sb.corner_radius_bottom_right = 21
	sb.corner_radius_bottom_left = 18
	sb.shadow_color = Color(GameConfig.COLOR_INK, 0.07)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(0.0, 3.0)
	sb.set_content_margin_all(GameConfig.SP_S)
	card.add_theme_stylebox_override("panel", sb)
	var v: VBoxContainer = VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	card.add_child(v)

	var btn: Button = Button.new()
	btn.name = "Mode_%s" % mode
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(0.0, MODE_CARD_H)
	btn.flat = true
	for st: String in ["normal", "hover", "focus"]:
		btn.add_theme_stylebox_override(st, StyleBoxEmpty.new())
	var press_sb: StyleBoxFlat = StyleBoxFlat.new()
	press_sb.bg_color = Color(GameConfig.COLOR_PEACH, 0.5)
	press_sb.set_corner_radius_all(14)
	btn.add_theme_stylebox_override("pressed", press_sb)
	btn.add_theme_stylebox_override("hover_pressed", press_sb)
	v.add_child(btn)
	var h: HBoxContainer = HBoxContainer.new()
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.add_theme_constant_override("separation", GameConfig.SP_M)
	btn.add_child(h)
	var icon: MenuIcon = MenuIcon.new("wifi" if mode == "lan" else mode, MODE_ICON, 3.5)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(icon)
	var tv: VBoxContainer = VBoxContainer.new()
	tv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_theme_constant_override("separation", -2)
	h.add_child(tv)
	var tl: Label = Label.new()
	tl.text = title
	tl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(tl, GameConfig.FS_BUTTON, GameConfig.COLOR_INK, true)
	tv.add_child(tl)
	var dl: Label = Label.new()
	dl.text = desc
	dl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(dl, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	tv.add_child(dl)
	if is_last:
		var tag: Label = Label.new()
		tag.name = "LastTag"
		tag.text = "Son oynadığın"
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tsb: StyleBoxFlat = StyleBoxFlat.new()
		tsb.bg_color = LAST_MODE_TAG
		tsb.border_color = GameConfig.COLOR_INK
		tsb.set_border_width_all(2)
		tsb.set_corner_radius_all(12)
		tsb.content_margin_left = 10
		tsb.content_margin_right = 10
		tag.add_theme_stylebox_override("normal", tsb)
		ComicUiHelper.style_label(tag, GameConfig.FS_TINY, GameConfig.COLOR_INK, true)
		tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(tag)
	btn.pressed.connect(func() -> void:
		ComicUiHelper.close_modal(root)
		action.call()
	)
	return card


## Basılı tutulan OYNA: son mod. Tek Başına / Günün Mutfağı / Botlar doğrudan başlar,
## Wi-Fi ve Çevrimiçi seçim gerektirdiği için kendi penceresini açar.
func _start_last_mode() -> void:
	match last_mode():
		"daily":
			_on_daily_pressed()
		"bots":
			_commit_name()
			var cnt: int = clampi(int(_menu_cfg_get("bots_count", 3)), 1, GameConfig.BOT_MAX)
			var sk: String = str(_menu_cfg_get("bots_skill", GameConfig.BOT_DEFAULT_SKILL))
			if not GameConfig.BOT_SKILLS.has(sk):
				sk = GameConfig.BOT_DEFAULT_SKILL
			NetworkManager.start_offline_bot_match(cnt, sk)
		"lan":
			_open_lan_sheet()
		"online":
			_open_online_modal()
		_:
			_on_solo_pressed()


## Aynı Wi-Fi: Oda Kur / Odaya Katıl
func _open_lan_sheet() -> void:
	_remember_mode("lan")
	_commit_name()
	var m: Dictionary = ComicUiHelper.build_modal(self, "AYNI WI-FI'DE", GameConfig.COLOR_CREAM, 0.0, true, true)
	var root: Control = m["root"] as Control
	root.name = "ModalLan"
	var body: VBoxContainer = m["body"] as VBoxContainer
	_hint_label(body, "Herkes aynı modemdeyse en hızlısı bu. Biri oda kursun, ötekiler katılsın.")
	var lan_row: HBoxContainer = HBoxContainer.new()
	lan_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(lan_row)
	var host_btn: Button = _modal_button("Oda Kur", GameConfig.COLOR_GOLD, 72.0)
	host_btn.name = "LanHost"
	host_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	host_btn.pressed.connect(func() -> void:
		ComicUiHelper.close_modal(root)
		_on_host_pressed()
	)
	lan_row.add_child(host_btn)
	var join_btn: Button = _modal_button("Odaya Katıl", GameConfig.COLOR_PEACH, 72.0)
	join_btn.name = "LanJoin"
	join_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	join_btn.pressed.connect(func() -> void:
		ComicUiHelper.close_modal(root)
		_on_join_pressed()
	)
	lan_row.add_child(join_btn)


# ---------------------------------------------------------------------------
# Oyun başlatma ve çoklu oyuncu
# ---------------------------------------------------------------------------

func _on_daily_pressed() -> void:
	_commit_name()
	_remember_mode("daily")
	NetworkManager.is_multiplayer_match = false
	var d: Dictionary = Time.get_date_dict_from_system()
	var date_str: String = "%04d-%02d-%02d" % [int(d["year"]), int(d["month"]), int(d["day"])]
	NetworkManager.current_seed = maxi(abs(date_str.hash()), 1)
	Monetization.next_match_tag = "gunun_mutfagi"
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


func _on_solo_pressed() -> void:
	_commit_name()
	_remember_mode("solo")
	NetworkManager.prepare_single_player_seed()
	get_tree().change_scene_to_file("res://scenes/game/GameWorld.tscn")


func _on_host_pressed() -> void:
	_commit_name()
	if NetworkManager.host_game():
		get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")
	else:
		_show_notice("Oda açılamadı. Port %d başka bir şeyle meşgul olabilir." % GameConfig.NET_PORT)


func _section_label(parent: Control, text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	ComicUiHelper.style_label(lbl, GameConfig.FS_BODY, GameConfig.COLOR_BROWN, true)
	parent.add_child(lbl)
	return lbl


func _hint_label(parent: Control, text: String) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	parent.add_child(lbl)
	return lbl


func _modal_button(text: String, color: Color, height: float = 64.0, font_size: int = GameConfig.FS_BUTTON) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, height)
	ComicUiHelper.style_bitten_button(btn, color, AssetHelper.get_ui_font(), font_size)
	return btn


func _add_close_button(m: Dictionary, text: String = "Kapat", on_close: Callable = Callable()) -> Button:
	var close_btn: Button = _modal_button(text, GameConfig.COLOR_PEACH)
	var root: Control = m["root"] as Control
	close_btn.pressed.connect(func() -> void:
		if on_close.is_valid():
			on_close.call()
		ComicUiHelper.close_modal(root)
	)
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return close_btn


## Faz 11.1: "Botlarla Oyna" ayarı: 1–4 bot ve seviye, internetsiz başlar.
func _open_bots_modal() -> void:
	_commit_name()
	var m: Dictionary = ComicUiHelper.build_modal(self, "BOTLARLA OYNA", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	var body: VBoxContainer = m["body"] as VBoxContainer
	var saved_skill: String = str(_menu_cfg_get("bots_skill", GameConfig.BOT_DEFAULT_SKILL))
	var state: Dictionary = {
		"count": clampi(int(_menu_cfg_get("bots_count", 3)), 1, GameConfig.BOT_MAX),
		"skill": saved_skill if GameConfig.BOT_SKILLS.has(saved_skill) else GameConfig.BOT_DEFAULT_SKILL,
	}
	root.name = "ModalBots"

	_section_label(body, "Kaç bot?")
	var count_row: HBoxContainer = HBoxContainer.new()
	count_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(count_row)
	var count_btns: Array[Button] = []
	for n: int in range(1, GameConfig.BOT_MAX + 1):
		var cb: Button = Button.new()
		cb.text = str(n)
		cb.custom_minimum_size = Vector2(0.0, 64.0)
		cb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		count_row.add_child(cb)
		count_btns.append(cb)

	_section_label(body, "Seviye")
	var skill_row: HBoxContainer = HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(skill_row)
	var skill_btns: Array[Button] = []
	for sk: String in GameConfig.BOT_SKILLS:
		var sb: Button = Button.new()
		sb.text = str(GameConfig.BOT_SKILL_NAMES[sk])
		sb.custom_minimum_size = Vector2(0.0, 64.0)
		sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.clip_text = true
		skill_row.add_child(sb)
		skill_btns.append(sb)
	var hint: Label = _hint_label(body, "")

	var refresh: Callable = func() -> void:
		for i: int in range(count_btns.size()):
			ComicUiHelper.style_tab(count_btns[i], i + 1 == int(state["count"]), GameConfig.FS_BODY)
		for i: int in range(skill_btns.size()):
			ComicUiHelper.style_tab(skill_btns[i], GameConfig.BOT_SKILLS[i] == str(state["skill"]), GameConfig.FS_SMALL)
		var tips: Dictionary = {
			"acemi": "Acemi: çoğu ilk iki seviyede pes eder.",
			"mahalleli": "Mahalleli: 2. ile 4. seviye arası, tam kıvamında.",
			"usta": "Usta: 4. seviyeden önce kolay kolay düşmez.",
		}
		hint.text = str(tips.get(str(state["skill"]), ""))
	for i: int in range(count_btns.size()):
		var n_cap: int = i + 1
		count_btns[i].pressed.connect(func() -> void:
			state["count"] = n_cap
			refresh.call()
		)
	for i: int in range(skill_btns.size()):
		var sk_cap: String = GameConfig.BOT_SKILLS[i]
		skill_btns[i].pressed.connect(func() -> void:
			state["skill"] = sk_cap
			refresh.call()
		)
	refresh.call()

	var start_btn: Button = _modal_button("Başla!", GameConfig.COLOR_GREEN_GO, 72.0)
	start_btn.name = "BotsStartButton"
	start_btn.pressed.connect(func() -> void:
		root.queue_free()
		_menu_cfg_set("bots_count", int(state["count"]))
		_menu_cfg_set("bots_skill", str(state["skill"]))
		_remember_mode("bots")
		NetworkManager.start_offline_bot_match(int(state["count"]), str(state["skill"]))
	)
	(m["footer"] as VBoxContainer).add_child(start_btn)
	_add_close_button(m, "Vazgeç")


func _on_join_pressed() -> void:
	_commit_name()
	if _join_modal != null and is_instance_valid(_join_modal):
		_join_modal.queue_free()
	var m: Dictionary = ComicUiHelper.build_modal(self, "YEREL AĞ ODALARI")
	_join_modal = m["root"] as Control
	var body: VBoxContainer = m["body"] as VBoxContainer

	join_status_label = Label.new()
	join_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	join_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(join_status_label, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(join_status_label)

	rooms_list = VBoxContainer.new()
	rooms_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rooms_list.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(rooms_list)

	_section_label(body, "Elle bağlan")
	var manual: HBoxContainer = HBoxContainer.new()
	manual.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(manual)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "IP (ör. 192.168.1.42)"
	ip_input.custom_minimum_size = Vector2(0.0, 60.0)
	ip_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(ip_input)
	ip_input.text_submitted.connect(func(_t: String) -> void:
		_on_manual_connect_pressed()
	)
	manual.add_child(ip_input)
	var connect_btn: Button = _modal_button("Bağlan", GameConfig.COLOR_GREEN_GO, 60.0, GameConfig.FS_BODY)
	connect_btn.custom_minimum_size.x = 150.0
	connect_btn.pressed.connect(_on_manual_connect_pressed)
	manual.add_child(connect_btn)

	_add_close_button(m, "Kapat", _on_close_join_pressed)

	join_status_label.text = "Aynı Wi-Fi'deki odalar aranıyor..."
	_on_rooms_updated([])
	NetworkManager.get_discovery().start_listening()


func _on_close_join_pressed() -> void:
	NetworkManager.get_discovery().stop_all()
	if _join_modal != null and is_instance_valid(_join_modal):
		_join_modal.queue_free()
	_join_modal = null
	rooms_list = null
	ip_input = null
	join_status_label = null


func _on_manual_connect_pressed() -> void:
	if ip_input == null or not is_instance_valid(ip_input):
		return
	var ip: String = ip_input.text.strip_edges()
	if ip.is_empty():
		join_status_label.text = "Önce bir IP yaz bakalım."
		return
	_connect_to_ip(ip)


func _connect_to_ip(ip: String) -> void:
	if join_status_label != null and is_instance_valid(join_status_label):
		join_status_label.text = "%s adresine bağlanılıyor..." % ip
	NetworkManager.join_game(ip)


func _on_rooms_updated(rooms: Array[Dictionary]) -> void:
	if rooms_list == null or not is_instance_valid(rooms_list):
		return
	for child: Node in rooms_list.get_children():
		child.queue_free()

	if rooms.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Henüz oda yok. Arkadaşın oda kursun, ya da IP'yi elle yaz."
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(empty_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, false)
		rooms_list.add_child(empty_lbl)
		return

	for room: Dictionary in rooms:
		var r_ip: String = str(room.get("ip", ""))
		var r_host: String = str(room.get("host_name", "Oda"))
		var r_count: int = int(room.get("players", 1))
		var r_match: bool = bool(room.get("in_match", false))
		var r_ver_ok: bool = bool(room.get("version_ok", true))
		var suffix: String = "  - maçta" if r_match else ""
		if not r_ver_ok:
			suffix = "  - farklı sürüm"
		var btn: Button = _modal_button("%s  (%d/5)%s" % [r_host, r_count, suffix], GameConfig.COLOR_SAGE, 64.0, GameConfig.FS_BODY)
		btn.disabled = r_match or not r_ver_ok
		btn.pressed.connect(func() -> void:
			_connect_to_ip(r_ip)
		)
		rooms_list.add_child(btn)


func _on_connection_succeeded() -> void:
	NetworkManager.get_discovery().stop_all()
	get_tree().change_scene_to_file("res://scenes/ui/Lobby.tscn")


func _on_connection_failed(reason: String) -> void:
	if join_status_label != null and is_instance_valid(join_status_label):
		join_status_label.text = reason
	_show_notice(reason)


func _open_online_modal() -> void:
	_commit_name()
	_remember_mode("online")
	# Faz 12.1: ilk çevrimiçi girişte Böcek Kimliği alınır
	Mahalle.activate()
	var m: Dictionary = ComicUiHelper.build_modal(self, "ÇEVRİMİÇİ OYUN")
	var body: VBoxContainer = m["body"] as VBoxContainer

	var status_lbl: Label = Label.new()
	status_lbl.text = "Sunucu: %s" % NetworkManager.server_host
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(status_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(status_lbl)

	# Faz 12.4: odalar Mahalle oturumundan açılır; eşleştirici giriş bileti verir
	var quick_btn: Button = _modal_button("Hızlı Oyun", GameConfig.COLOR_GREEN_GO, 72.0)
	quick_btn.pressed.connect(func() -> void:
		status_lbl.text = "Sunucuya bağlanılıyor..."
		Mahalle.quick_play(_room_result_cb(status_lbl))
	)
	body.add_child(quick_btn)

	_section_label(body, "Özel oda: kim girebilir?")
	var priv_state: Dictionary = {"p": GameConfig.ROOM_PRIVACY_DEFAULT}
	var priv_hint: Label = Label.new()
	priv_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(priv_hint, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	var priv_row: Control = FriendsUi.build_privacy_selector(priv_state, priv_hint, func(_p: String) -> void: pass)
	body.add_child(priv_row)
	body.add_child(priv_hint)
	var priv_btn: Button = _modal_button("Özel Oda Kur", GameConfig.COLOR_GOLD, 64.0)
	priv_btn.name = "CreatePrivateButton"
	priv_btn.pressed.connect(func() -> void:
		status_lbl.text = "Oda kuruluyor..."
		Mahalle.create_room(str(priv_state["p"]), _room_result_cb(status_lbl))
	)
	body.add_child(priv_btn)

	_section_label(body, "Kodla katıl")
	var code_h: HBoxContainer = HBoxContainer.new()
	code_h.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(code_h)
	var code_in: LineEdit = LineEdit.new()
	code_in.placeholder_text = "Oda kodu (ör. KTRB)"
	code_in.max_length = 4
	code_in.custom_minimum_size = Vector2(0.0, 60.0)
	code_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(code_in)
	code_h.add_child(code_in)
	var code_btn: Button = _modal_button("Katıl", GameConfig.COLOR_DUST_BLUE, 60.0, GameConfig.FS_BODY)
	code_btn.custom_minimum_size.x = 140.0
	code_btn.pressed.connect(func() -> void:
		status_lbl.text = "Oda aranıyor..."
		Mahalle.join_code(code_in.text.strip_edges().to_upper(), _room_result_cb(status_lbl))
	)
	code_h.add_child(code_btn)

	_section_label(body, "Sunucu adresi")
	var host_h: HBoxContainer = HBoxContainer.new()
	host_h.add_theme_constant_override("separation", GameConfig.SP_S)
	body.add_child(host_h)
	var host_in: LineEdit = LineEdit.new()
	host_in.text = NetworkManager.server_host
	host_in.placeholder_text = "IP veya alan adı"
	host_in.custom_minimum_size = Vector2(0.0, 60.0)
	host_in.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_line_edit(host_in)
	host_h.add_child(host_in)
	var save_btn: Button = _modal_button("Kaydet", GameConfig.COLOR_SAGE, 60.0, GameConfig.FS_BODY)
	save_btn.custom_minimum_size.x = 140.0
	var save_host: Callable = func() -> void:
		var new_h: String = host_in.text.strip_edges()
		if new_h.is_empty():
			status_lbl.text = "Adres boş kalmasın, bir şey yaz."
			return
		NetworkManager.save_server_host(new_h)
		status_lbl.text = "Kaydedildi. Sunucu: %s" % NetworkManager.server_host
	save_btn.pressed.connect(save_host)
	host_in.text_submitted.connect(func(_t: String) -> void:
		save_host.call()
	)
	host_h.add_child(save_btn)

	_add_close_button(m)


## Oda isteği yanıtı: başarılıysa Mahalle bileti alıp bağlanır (bağlanınca Lobi'ye geçilir), değilse sebep yazılır.
func _room_result_cb(status_lbl: Label) -> Callable:
	return func(res: Dictionary) -> void:
		if not is_instance_valid(status_lbl):
			return
		if bool(res.get("ok", false)):
			status_lbl.text = "Odaya giriliyor (%s)..." % str(res.get("code", ""))
		else:
			status_lbl.text = str(res.get("reason", "Bağlantı reddedildi."))


# ---------------------------------------------------------------------------
# Ayarlar
# ---------------------------------------------------------------------------

## Başlık + kısa açıklama + sağda durum butonu. state_fn -> [metin, açık_mı]
func _add_setting_row(parent: Control, title: String, sub: String, state_fn: Callable, press_fn: Callable, btn_w: float = 150.0) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_S)
	parent.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	row.add_child(info)
	var t: Label = Label.new()
	t.text = title
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(t, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	info.add_child(t)
	if not sub.is_empty():
		var s: Label = Label.new()
		s.text = sub
		s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(s, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
		info.add_child(s)

	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(btn_w, 56.0)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(btn)
	var refresh: Callable = func() -> void:
		var st: Array = state_fn.call() as Array
		btn.text = str(st[0])
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO if bool(st[1]) else Color("#E6DACB"), AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
	refresh.call()
	btn.pressed.connect(func() -> void:
		press_fn.call()
		refresh.call()
	)


func _on_off(v: bool) -> Array:
	return ["Açık" if v else "Kapalı", v]


func _open_settings_modal() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "AYARLAR", GameConfig.COLOR_CREAM, 0.0, true)
	(m["root"] as Control).name = "ModalSettings"
	var body: VBoxContainer = m["body"] as VBoxContainer

	_section_label(body, "Ses ve his")
	_add_setting_row(body, "Ses", "Müzik, çığlık, terlik şaklaması",
		func() -> Array: return _on_off(not AudioManager.is_muted),
		func() -> void: AudioManager.set_muted(not AudioManager.is_muted))
	_add_setting_row(body, "Titreşim", "Terlik yiyince telefon da sarsılsın",
		func() -> Array: return _on_off(AudioManager.is_vibration_enabled),
		func() -> void: AudioManager.set_vibration_enabled(not AudioManager.is_vibration_enabled))
	_add_setting_row(body, "Argo sansürü", "Açıkken ağır laflar bip'lenir",
		func() -> Array: return _on_off(AudioManager.is_censor_enabled),
		func() -> void: AudioManager.set_censor_enabled(not AudioManager.is_censor_enabled))
	_add_setting_row(body, "Ölüm Karesi", "Ölünce 3 kareli çizgi roman. Telefon zorlanırsa kapat.",
		func() -> Array: return _on_off(AudioManager.death_card_enabled),
		func() -> void: AudioManager.set_death_card_enabled(not AudioManager.death_card_enabled))
	# Faz 13B: buton hissi ve açılış animasyonu
	_add_setting_row(body, "Buton tık ve titreşimi", "Butona basınca hafif tık sesi ve kısa titreşim",
		func() -> Array: return _on_off(AudioManager.ui_feedback_enabled),
		func() -> void: AudioManager.set_ui_feedback_enabled(not AudioManager.ui_feedback_enabled))
	_add_setting_row(body, "Açılış animasyonunu göster", "Kapalıyken açılışta yalnızca logo görünür",
		func() -> Array: return _on_off(AudioManager.intro_enabled),
		func() -> void: AudioManager.set_intro_enabled(not AudioManager.intro_enabled))

	# Faz 11.7: kendi lafını kaydet
	_section_label(body, "Benim Lafım")
	var filled: int = 0
	for slot: String in GameConfig.VOICE_SLOTS:
		if VoiceClip.has_slot(slot):
			filled += 1
	_add_setting_row(body, "Kendi sesini kaydet", "Laf atma, sataşma ve zafer için 2 sn'lik sesin (%d / 3 dolu)" % filled,
		func() -> Array: return ["Aç", true],
		func() -> void: VoiceRecorderModal.open(self))
	_add_setting_row(body, "Arkadaşların özel seslerini çal", "Yalnızca Özel Oda ve LAN'da. Hızlı Oyun'da hiç çalmaz.",
		func() -> Array: return _on_off(AudioManager.friend_voices_enabled),
		func() -> void: AudioManager.set_friend_voices_enabled(not AudioManager.friend_voices_enabled))

	# Faz 13A: sesli sohbet (TwoVoip eklentisi yoksa bölüm gizli)
	if VoiceChat.ui_available():
		VoiceChatUi.build_settings_section(body, self)

	# Faz 12.1: kimlik, kurtarma kodu, geri yükleme
	_section_label(body, "Hesabım")
	_add_setting_row(body, "Böcek Kimliği", Mahalle.formatted_id() + " · Kurtarma Kodu, Kimliğimi Geri Yükle" if Mahalle.has_account() else "Kurtarma Kodu, Kimliğimi Geri Yükle",
		func() -> Array: return ["Aç", true],
		func() -> void: FriendsUi.open_account(self))

	_section_label(body, "Mekan")
	_build_theme_grid(body)

	_section_label(body, "Kontroller")
	_build_controls_section(body)

	_add_close_button(m, "Tamam")


func _build_theme_grid(parent: Control) -> void:
	var grid: GridContainer = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", GameConfig.SP_XS)
	grid.add_theme_constant_override("v_separation", GameConfig.SP_XS)
	parent.add_child(grid)
	_bg_thumbs.clear()

	for theme: Dictionary in GameConfig.BG_THEMES:
		var tid: String = str(theme["id"])
		var item: Button = Button.new()
		item.name = "Theme_%s" % tid
		item.focus_mode = Control.FOCUS_NONE
		item.custom_minimum_size = Vector2(0.0, THEME_THUMB_H)
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(item)

		var v: VBoxContainer = VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 6.0
		v.offset_top = 6.0
		v.offset_right = -6.0
		v.offset_bottom = -4.0
		v.add_theme_constant_override("separation", 2)
		item.add_child(v)

		var tex: TextureRect = TextureRect.new()
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tex.texture = AssetHelper.texture(str(theme["path"]), str(theme["kind"]), GameConfig.BG_SIZE)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex.size_flags_vertical = Control.SIZE_EXPAND_FILL
		v.add_child(tex)

		var lbl: Label = Label.new()
		lbl.text = str(theme["name"])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.custom_minimum_size = Vector2(0.0, 48.0)
		ComicUiHelper.style_label(lbl, GameConfig.FS_TINY, GameConfig.COLOR_DARK_TEXT, false)
		v.add_child(lbl)

		item.pressed.connect(func() -> void:
			NetworkManager.save_selected_bg(tid)
			_refresh_theme_grid()
		)
		_bg_thumbs[tid] = item
	_refresh_theme_grid()


func _refresh_theme_grid() -> void:
	for tid: String in _bg_thumbs.keys():
		var item: Button = _bg_thumbs[tid] as Button
		if not is_instance_valid(item):
			continue
		var sel: bool = tid == NetworkManager.selected_bg_id
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.COLOR_GOLD if sel else INPUT_BG
		sb.border_color = GameConfig.COLOR_INK if sel else Color(GameConfig.COLOR_BROWN, 0.45)
		sb.set_border_width_all(4 if sel else 2)
		sb.set_corner_radius_all(14)
		var pressed_sb: StyleBoxFlat = sb.duplicate() as StyleBoxFlat
		pressed_sb.bg_color = sb.bg_color.darkened(0.08)
		item.add_theme_stylebox_override("normal", sb)
		item.add_theme_stylebox_override("hover", sb)
		item.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		item.add_theme_stylebox_override("pressed", pressed_sb)
		item.add_theme_stylebox_override("hover_pressed", pressed_sb)


func _build_controls_section(parent: Control) -> void:
	var scheme_state: Callable = func() -> Array:
		return ["Kaydırma" if AudioManager.control_scheme == "swipe" else "Butonlar", true]
	var scheme_toggle: Callable = func() -> void:
		var next_s: String = "buttons" if AudioManager.control_scheme == "swipe" else "swipe"
		AudioManager.save_control_settings(next_s, AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode)
	_add_setting_row(parent, "Kontrol şekli", "Kaydırma hareketi mi, ekran butonları mı?", scheme_state, scheme_toggle, 170.0)
	_add_setting_row(parent, "Solak modu", "Butonlar sol tarafa geçer",
		func() -> Array: return _on_off(AudioManager.left_handed),
		func() -> void: AudioManager.save_control_settings(AudioManager.control_scheme, not AudioManager.left_handed, AudioManager.button_scale, AudioManager.assist_mode))
	_add_setting_row(parent, "Yardımcı mod", "Tek oyuncuda biraz daha affedici",
		func() -> Array: return _on_off(AudioManager.assist_mode),
		func() -> void: AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, AudioManager.button_scale, not AudioManager.assist_mode))

	var scale_lbl: Label = Label.new()
	scale_lbl.text = "Buton boyutu: %%%d" % int(roundf(AudioManager.button_scale * 100.0))
	ComicUiHelper.style_label(scale_lbl, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	parent.add_child(scale_lbl)

	var slider: HSlider = HSlider.new()
	slider.min_value = 0.8
	slider.max_value = 1.3
	slider.step = 0.05
	slider.value = AudioManager.button_scale
	slider.custom_minimum_size = Vector2(0.0, 44.0)
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = Color("#E6DACB")
	track.border_color = GameConfig.COLOR_INK
	track.set_border_width_all(2)
	track.set_corner_radius_all(8)
	track.content_margin_top = 6.0
	track.content_margin_bottom = 6.0
	var fill: StyleBoxFlat = track.duplicate() as StyleBoxFlat
	fill.bg_color = GameConfig.COLOR_GREEN_GO
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill)
	slider.value_changed.connect(func(val: float) -> void:
		AudioManager.save_control_settings(AudioManager.control_scheme, AudioManager.left_handed, val, AudioManager.assist_mode)
		scale_lbl.text = "Buton boyutu: %%%d" % int(roundf(val * 100.0))
	)
	parent.add_child(slider)


func _open_controls_modal() -> void:
	var m: Dictionary = ComicUiHelper.build_modal(self, "KONTROL AYARLARI", GameConfig.COLOR_CREAM, 0.0, true)
	_build_controls_section(m["body"] as VBoxContainer)
	_add_close_button(m, "Tamam")


# ---------------------------------------------------------------------------
# Günlük görevler, seri takvimi ve Günün Sürprizi (Faz 11.4)
# ---------------------------------------------------------------------------

## Seri başlığı (kanat çırpan böcek + sayı), 7 günlük takvim, ödül ve Seriyi Kurtar.
func _build_streak_card() -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.name = "StreakCard"
	ComicUiHelper.style_bitten_panel(card, PANEL_SOFT_BG, 760, GameConfig.SP_M)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", GameConfig.SP_S)
	card.add_child(v)

	var head: HBoxContainer = HBoxContainer.new()
	head.add_theme_constant_override("separation", GameConfig.SP_S)
	v.add_child(head)
	var icon: StreakBugIcon = StreakBugIcon.new(STREAK_CARD_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(icon)
	var hv: VBoxContainer = VBoxContainer.new()
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_theme_constant_override("separation", 0)
	head.add_child(hv)
	var streak: int = Monetization.get_streak()
	var title: Label = Label.new()
	title.text = "Seri: %d gün" % streak
	ComicUiHelper.style_label(title, GameConfig.FS_H2, GameConfig.COLOR_INK, true)
	hv.add_child(title)
	var sub: Label = Label.new()
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub.text = "Her gün 1 maç oyna, seri büyüsün. En iyi: %d gün" % maxi(Monetization.streak_best, streak)
	ComicUiHelper.style_label(sub, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	hv.add_child(sub)

	# 7 günlük takvim
	var cal: HBoxContainer = HBoxContainer.new()
	cal.name = "StreakCalendar"
	cal.add_theme_constant_override("separation", 4)
	v.add_child(cal)
	var today_idx: int = Monetization.streak_calendar_index()
	var played: bool = Monetization.played_today()
	var claimed_today: bool = played and not Monetization.can_claim_streak_reward()
	for i: int in range(GameConfig.STREAK_REWARDS.size()):
		var state: int = 0 # 0 gelecek, 1 geçti, 2 bugün
		if i < today_idx:
			state = 1
		elif i == today_idx:
			state = 1 if claimed_today else 2
		cal.add_child(_build_calendar_cell(i, state))

	if Monetization.can_claim_streak_reward():
		var amt: int = GameConfig.STREAK_REWARDS[today_idx]
		var claim: Button = _modal_button("Bugünün ödülünü al: %s" % (("+%d Kırıntı" % amt) if amt > 0 else "Kostüm parçası"), GameConfig.COLOR_GREEN_GO, 60.0, GameConfig.FS_BODY)
		claim.pressed.connect(func() -> void:
			var got: Dictionary = Monetization.claim_streak_reward()
			if not got.is_empty():
				_show_notice(str(got.get("text", "")))
			_update_crumbs(true)
			_refresh_quest_badge()
			_open_quests_modal()
		)
		v.add_child(claim)
	elif not played:
		var hint: Label = Label.new()
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.text = "Bugün bir maç oyna, takvimdeki ödül açılsın."
		ComicUiHelper.style_label(hint, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
		v.add_child(hint)

	if Monetization.streak_at_risk():
		var risk: Label = Label.new()
		risk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		risk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		risk.text = "Dün uçmadın! %d günlük serin tehlikede." % Monetization.streak_count
		ComicUiHelper.style_label(risk, GameConfig.FS_SMALL, GameConfig.COLOR_WARN_RED, true)
		v.add_child(risk)
		if Monetization.can_save_streak():
			var save_b: Button = _modal_button("Seriyi Kurtar (reklam izle)", GameConfig.COLOR_GOLD, 60.0, GameConfig.FS_BODY)
			save_b.pressed.connect(func() -> void:
				save_b.disabled = true
				save_b.text = "Reklam açılıyor…"
				Monetization.show_rewarded_ad(func(ok: bool) -> void:
					if ok and Monetization.save_streak():
						_show_notice("Seri kurtarıldı! Bugün uçmayı unutma.")
					if is_instance_valid(self):
						_refresh_streak_pill()
						_open_quests_modal()
				)
			)
			v.add_child(save_b)
	return card


func _build_calendar_cell(idx: int, state: int) -> PanelContainer:
	var cell: PanelContainer = PanelContainer.new()
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = [INPUT_BG, GameConfig.COLOR_SAGE, GameConfig.COLOR_GOLD][state]
	sb.border_color = GameConfig.COLOR_INK if state == 2 else Color(GameConfig.COLOR_BROWN, 0.45)
	sb.set_border_width_all(3 if state == 2 else 2)
	sb.set_corner_radius_all(10)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	cell.add_theme_stylebox_override("panel", sb)
	var cv: VBoxContainer = VBoxContainer.new()
	cv.add_theme_constant_override("separation", 0)
	cell.add_child(cv)
	var d: Label = Label.new()
	d.text = "%d" % (idx + 1)
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(d, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	cv.add_child(d)
	var r: Label = Label.new()
	var amt: int = GameConfig.STREAK_REWARDS[idx]
	r.text = str(amt) if amt > 0 else "Kostüm"
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	r.clip_text = true
	ComicUiHelper.style_label(r, GameConfig.FS_TINY, GameConfig.COLOR_INK, true)
	cv.add_child(r)
	return cell


func _build_quest_row(q: Dictionary) -> PanelContainer:
	var prog: int = int(q["progress"])
	var goal: int = int(q["goal"])
	var done: bool = prog >= goal
	var claimed: bool = bool(q["claimed"])
	var q_id: String = str(q["id"])

	var card: PanelContainer = PanelContainer.new()
	card.name = "Quest_%s" % q_id
	ComicUiHelper.style_bitten_panel(card, PANEL_SOFT_BG, 750, GameConfig.SP_M)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", GameConfig.SP_M)
	card.add_child(row)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", GameConfig.SP_XS)
	row.add_child(info)

	var title: Label = Label.new()
	title.text = str(q["title"])
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ComicUiHelper.style_label(title, GameConfig.FS_BODY, GameConfig.COLOR_DARK_TEXT, false)
	info.add_child(title)

	var bar_row: HBoxContainer = HBoxContainer.new()
	bar_row.add_theme_constant_override("separation", GameConfig.SP_XS)
	info.add_child(bar_row)
	var bar: ProgressBar = ProgressBar.new()
	bar.show_percentage = false
	bar.min_value = 0.0
	bar.max_value = float(maxi(goal, 1))
	bar.value = float(mini(prog, goal))
	bar.custom_minimum_size = Vector2(0.0, 22.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bg_sb: StyleBoxFlat = StyleBoxFlat.new()
	bg_sb.bg_color = Color("#E6DACB")
	bg_sb.border_color = GameConfig.COLOR_INK
	bg_sb.set_border_width_all(2)
	bg_sb.set_corner_radius_all(11)
	var fill_sb: StyleBoxFlat = bg_sb.duplicate() as StyleBoxFlat
	fill_sb.bg_color = GameConfig.COLOR_GREEN_GO
	bar.add_theme_stylebox_override("background", bg_sb)
	bar.add_theme_stylebox_override("fill", fill_sb)
	bar_row.add_child(bar)
	var count_lbl: Label = Label.new()
	count_lbl.text = "%d/%d" % [mini(prog, goal), goal]
	ComicUiHelper.style_label(count_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, true)
	bar_row.add_child(count_lbl)

	var reward_lbl: Label = Label.new()
	reward_lbl.text = "Ödül: %d Kırıntı" % int(q["reward"])
	ComicUiHelper.style_label(reward_lbl, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	info.add_child(reward_lbl)

	var btn_col: VBoxContainer = VBoxContainer.new()
	btn_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn_col.add_theme_constant_override("separation", GameConfig.SP_XS)
	row.add_child(btn_col)
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(QUEST_BTN_W, 64.0)
	btn_col.add_child(btn)
	_style_quest_button(btn, done, claimed)
	btn.pressed.connect(func() -> void:
		var got: int = Monetization.claim_quest_reward(q_id)
		if got <= 0:
			return
		_update_crumbs(true)
		_refresh_quest_badge()
		_open_quests_modal()
	)
	# Günde 1 kez ödüllü reklamla görev değiştirme (reklam yoksa buton hiç görünmez)
	if Monetization.can_reroll_quest(q_id):
		var rr: Button = Button.new()
		rr.text = "Değiştir (reklam)"
		rr.custom_minimum_size = Vector2(QUEST_BTN_W, 48.0)
		ComicUiHelper.style_bitten_button(rr, GameConfig.COLOR_DUST_BLUE, AssetHelper.get_ui_font(), GameConfig.FS_TINY)
		rr.pressed.connect(func() -> void:
			rr.disabled = true
			Monetization.show_rewarded_ad(func(ok: bool) -> void:
				if ok:
					Monetization.reroll_quest(q_id)
				if is_instance_valid(self):
					_refresh_quest_badge()
					_open_quests_modal()
			)
		)
		btn_col.add_child(rr)
	return card


func _style_quest_button(btn: Button, done: bool, claimed: bool) -> void:
	var font: Font = AssetHelper.get_ui_font()
	if claimed:
		btn.text = "Alındı"
		btn.disabled = true
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_SAGE, font, GameConfig.FS_SMALL)
	elif done:
		btn.text = "Al!"
		btn.disabled = false
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_GREEN_GO, font, GameConfig.FS_BUTTON)
	else:
		btn.text = "Devam ediyor"
		btn.disabled = true
		ComicUiHelper.style_bitten_button(btn, GameConfig.COLOR_CREAM, font, GameConfig.FS_SMALL)


## Günün Sürprizi kutusu: olası içerikler yazılı, 3 görev bitince açılır.
func _build_surprise_box() -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.name = "SurpriseBox"
	ComicUiHelper.style_bitten_panel(box, Color("#FBEFC4"), 770, GameConfig.SP_M)
	var v: VBoxContainer = VBoxContainer.new()
	v.add_theme_constant_override("separation", GameConfig.SP_XS)
	box.add_child(v)
	var t: Label = Label.new()
	t.text = "Günün Sürprizi"
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(t, GameConfig.FS_H2, GameConfig.COLOR_INK, true)
	v.add_child(t)
	var d: Label = Label.new()
	d.text = GameConfig.DAILY_SURPRISE_TEXT + ". Satın alınamaz, yalnızca görevle açılır."
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(d, GameConfig.FS_TINY, GameConfig.COLOR_BROWN, false)
	v.add_child(d)
	var parts: Label = Label.new()
	parts.text = "Kostüm parçası: %d / %d" % [Monetization.costume_parts, GameConfig.COSTUME_PARTS_PER_SKIN]
	parts.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(parts, GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT, false)
	v.add_child(parts)
	var open_b: Button = Button.new()
	open_b.custom_minimum_size = Vector2(0.0, 60.0)
	if Monetization.quest_surprise_claimed:
		open_b.text = "Bugünün sürprizi açıldı"
		open_b.disabled = true
		ComicUiHelper.style_bitten_button(open_b, GameConfig.COLOR_SAGE, AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
	elif Monetization.can_claim_surprise():
		open_b.text = "Sürprizi Aç!"
		ComicUiHelper.style_bitten_button(open_b, GameConfig.COLOR_GREEN_GO, AssetHelper.get_title_font(), GameConfig.FS_BUTTON)
		open_b.pressed.connect(func() -> void:
			var got: Dictionary = Monetization.claim_surprise()
			if not got.is_empty():
				_show_notice("Günün Sürprizi: %s" % str(got.get("text", "")))
			_update_crumbs(true)
			_refresh_quest_badge()
			_open_quests_modal()
		)
	else:
		open_b.text = "3 görevi bitir, kutu açılsın"
		open_b.disabled = true
		ComicUiHelper.style_bitten_button(open_b, GameConfig.COLOR_CREAM, AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
	v.add_child(open_b)
	return box


# ---------------------------------------------------------------------------
# Seri: ana menü hapı ve 7 / 30 / 100 kutlaması
# ---------------------------------------------------------------------------

func _refresh_streak_pill() -> void:
	if _streak_label == null:
		return
	_streak_label.text = str(Monetization.get_streak())
	_fit_pill.call_deferred(_streak_btn)


## Kutlanmamış seri eşiği varsa kutlama ekranı açar.
func _check_streak_celebration() -> void:
	var m_val: int = Monetization.pending_streak_milestone()
	if m_val <= 0:
		return
	Monetization.mark_streak_milestone(m_val)
	var m: Dictionary = ComicUiHelper.build_modal(self, "SERİ %d!" % m_val, Color("#FBEFC4"), 0.0, true)
	(m["root"] as Control).name = "ModalStreakParty"
	var body: VBoxContainer = m["body"] as VBoxContainer
	var center: CenterContainer = CenterContainer.new()
	body.add_child(center)
	var bug: StreakBugIcon = StreakBugIcon.new(STREAK_PARTY_ICON)
	center.add_child(bug)
	var lines: Dictionary = {7: "Bir hafta boyunca mutfağı birbirine kattın!", 30: "Bir ay! Mahallede adın efsane oldu.", 100: "100 gün! Terlikler artık senden korkuyor."}
	var lbl: Label = Label.new()
	lbl.text = str(lines.get(m_val, "Seri devam ediyor!"))
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(lbl, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
	body.add_child(lbl)
	_add_close_button(m, "Böcek gibi devam!")
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var conf: CPUParticles2D = CPUParticles2D.new()
	conf.position = Vector2(vis.x * 0.5, -10.0)
	conf.one_shot = true
	conf.explosiveness = 0.6
	conf.amount = 60
	conf.lifetime = 2.4
	conf.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	conf.emission_rect_extents = Vector2(vis.x * 0.5, 8.0)
	conf.direction = Vector2(0.0, 1.0)
	conf.spread = 25.0
	conf.gravity = Vector2(0.0, 380.0)
	conf.initial_velocity_min = 120.0
	conf.initial_velocity_max = 300.0
	conf.scale_amount_min = 8.0
	conf.scale_amount_max = 14.0
	conf.color = GameConfig.COLOR_GOLD
	conf.z_index = 99
	(m["root"] as Control).add_child(conf)
	conf.emitting = true


## Android Geri tuşu: açık bir pencere varsa onu kapatır, Ana Sayfa dışındaysa Ana Sayfa'ya döner,
## yoksa oyundan çıkar.
func _notification(what: int) -> void:
	if what != NOTIFICATION_WM_GO_BACK_REQUEST:
		return
	for i: int in range(get_child_count() - 1, -1, -1):
		var c: Node = get_child(i)
		if c is Control and (c as Control).visible and (c.name.begins_with("Modal") or c is ShopModal or c is SkillsModal or c is GuideModal):
			if c.name.begins_with("Modal"):
				ComicUiHelper.close_modal(c as Control)
			else:
				c.queue_free()
			return
	if _tab != "home":
		_switch_tab("home")
		return
	get_tree().quit()

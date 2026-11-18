class_name IntroScene
extends Control

## Faz 13B: açılış animasyonu (oyunun ana sahnesi).
## Tam sürüm ~3 sn (ilk açılış): krem açılış karesi -> karanlık mutfak, buzdolabı aralığından ışık ->
## "klik" ışık yanar, karakter donakalır -> kenardan dönerek gelen terlik, böcek son anda uçar,
## terlik tezgâha "ŞAPP!" -> logo düşer, iki kez sekip oturur, karakter laf atar -> kamera geri çekilir.
## Sonraki açılışlarda kısa sürüm (1 sn: ışık + logo). Ayarlardan kapatılırsa yalnızca logo.
## Herhangi bir dokunuş animasyonu geçer. Arka planda menü, oyun dünyası, karakterler ve sesler
## yüklenir; yükleme bitmeden menüye geçilmez (bitmezse logonun altında ince ilerleme çizgisi).
## Sunucu kipleri (--room, --matchmaker) ve başsız (headless) çalıştırma intro'yu atlar.

const KIND_FULL: String = "full"
const KIND_SHORT: String = "short"
const KIND_LOGO: String = "logo"

## Önceden yüklenen kaynaklar sahne değişince de önbellekte kalsın
static var preloaded: Array[Resource] = []

var kind: String = KIND_FULL
var _kitchen: KitchenScene = null
var _logo: GameLogo = null
var _cover: ColorRect = null
var _cover_logo: GameLogo = null
var _slipper: Sprite2D = null
var _sapp: Label = null
var _shout: Label = null
var _bubble: Label = null
var _bar: Control = null
var _loads: Array[String] = []
var _progress: float = 0.0
var _loads_done: bool = false
var _anim_done: bool = false
var _leaving: bool = false
var _timeline: Tween = null
var _layout: Dictionary = {}


## Intro atlanmalı mı? "server": sunucu kipi (Boot sahneyi değiştirir), "headless": doğrudan menü.
static func skip_reason(args: PackedStringArray, display_name: String) -> String:
	if args.has("--matchmaker") or args.has("--room"):
		return "server"
	if display_name == "headless":
		return "headless"
	return ""


## Hangi intro oynatılır: kapalıysa yalnızca logo, ilk açılışta tam, sonra kısa.
static func pick_kind(enabled: bool, seen: bool) -> String:
	if not enabled:
		return KIND_LOGO
	return KIND_SHORT if seen else KIND_FULL


## Arka planda yüklenecek yollar (var olanlar).
static func preload_paths() -> Array[String]:
	var out: Array[String] = []
	for p: String in GameConfig.INTRO_PRELOAD:
		if ResourceLoader.exists(p):
			out.append(p)
	for cid: String in CharacterData.ALL_ORDER:
		var sp: String = str(CharacterData.get_character(cid).get("sprite_path", ""))
		if not sp.is_empty() and ResourceLoader.exists(sp) and not out.has(sp):
			out.append(sp)
	return out


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var reason: String = skip_reason(OS.get_cmdline_user_args(), DisplayServer.get_name())
	if reason == "server":
		return
	if reason == "headless":
		_go_menu_direct.call_deferred()
		return
	kind = pick_kind(AudioManager.intro_enabled, AudioManager.intro_seen)
	_build()
	_start_loads()
	match kind:
		KIND_FULL:
			_play_full()
		KIND_SHORT:
			_play_short()
		_:
			_play_logo_only()


func _go_menu_direct() -> void:
	get_tree().change_scene_to_file(GameConfig.MENU_SCENE_PATH)


func _build() -> void:
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var ins: Dictionary = ComicUiHelper.safe_insets(self)
	_layout = KitchenScene.menu_layout(vis, ins)

	_kitchen = KitchenScene.new()
	_kitchen.name = "Kitchen"
	_kitchen.jokes_enabled = false
	add_child(_kitchen)
	_kitchen.counter_y = float(_layout["counter_y"])
	_kitchen.pivot_offset = vis * 0.5

	_slipper = Sprite2D.new()
	_slipper.name = "Slipper"
	_slipper.texture = AssetHelper.texture("res://assets/sprites/terlik.png", "slipper", Vector2i(140, 220))
	_slipper.visible = false
	var tsz: Vector2 = _slipper.texture.get_size()
	var sc: float = 170.0 / maxf(tsz.y, 1.0)
	_slipper.scale = Vector2(sc, sc)
	add_child(_slipper)

	_shout = _pop_label("!", GameConfig.FS_HERO, GameConfig.COLOR_WARN_RED)
	_sapp = _pop_label("ŞAPP!", GameConfig.FS_HERO, GameConfig.COLOR_INK)
	_bubble = _pop_label("", GameConfig.FS_SMALL, GameConfig.COLOR_DARK_TEXT)
	var bsb: StyleBoxFlat = StyleBoxFlat.new()
	bsb.bg_color = Color("#FFFBF4")
	bsb.border_color = GameConfig.COLOR_INK
	bsb.set_border_width_all(3)
	bsb.set_corner_radius_all(16)
	bsb.set_content_margin_all(GameConfig.SP_XS)
	bsb.content_margin_left = GameConfig.SP_S
	bsb.content_margin_right = GameConfig.SP_S
	_bubble.add_theme_stylebox_override("normal", bsb)
	_bubble.add_theme_constant_override("outline_size", 0)

	var lr: Rect2 = _layout["logo"] as Rect2
	_logo = GameLogo.create(true, false)
	_logo.name = "Logo"
	_logo.size = lr.size
	_logo.position = Vector2(lr.position.x, -lr.size.y - 40.0)
	add_child(_logo)

	_bar = Control.new()
	_bar.name = "ProgressLine"
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.visible = false
	_bar.size = Vector2(lr.size.x * 0.6, 10.0)
	_bar.position = Vector2(lr.position.x + lr.size.x * 0.2, lr.end.y + GameConfig.SP_M)
	_bar.draw.connect(func() -> void:
		var w: float = _bar.size.x
		_bar.draw_line(Vector2(0.0, 5.0), Vector2(w, 5.0), Color(GameConfig.COLOR_INK, 0.18), 6.0, true)
		_bar.draw_line(Vector2(0.0, 5.0), Vector2(maxf(w * _progress, 1.0), 5.0), GameConfig.COLOR_BROWN, 6.0, true)
	)
	add_child(_bar)

	# Açılış karesiyle aynı: krem zemin + ortada logo (beyaz/siyah ara kare olmasın)
	_cover = ColorRect.new()
	_cover.name = "Cover"
	_cover.color = GameConfig.COLOR_CREAM
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)
	_cover_logo = GameLogo.create(false, false)
	var cw: float = vis.x * 0.7
	_cover_logo.size = Vector2(cw, cw * GameConfig.MENU_LOGO_ASPECT)
	_cover_logo.position = (vis - _cover_logo.size) * 0.5
	_cover.add_child(_cover_logo)


func _pop_label(text: String, fs: int, col: Color) -> Label:
	var l: Label = Label.new()
	l.text = text
	l.visible = false
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(l, fs, col, true)
	l.add_theme_color_override("font_outline_color", GameConfig.COLOR_CREAM)
	l.add_theme_constant_override("outline_size", 12)
	add_child(l)
	return l


func _place_label(l: Label, center: Vector2) -> void:
	l.size = Vector2.ZERO
	var sz: Vector2 = l.get_combined_minimum_size()
	l.size = sz
	l.pivot_offset = sz * 0.5
	l.position = center - sz * 0.5


# ---------------------------------------------------------------------------
# Zaman çizelgeleri
# ---------------------------------------------------------------------------

func _play_full() -> void:
	_kitchen.darkness = 1.0
	_kitchen.scale = Vector2.ONE * GameConfig.INTRO_PULLBACK_ZOOM
	var home: Vector2 = _kitchen.actor_home()
	var vis: Vector2 = ComicUiHelper.visible_size(self)
	var tl: Tween = create_tween()
	_timeline = tl
	# 1) Krem kare -> karanlık mutfak, buzdolabı aralığından ışık sızar
	tl.tween_property(_cover, "modulate:a", 0.0, 0.35)
	tl.parallel().tween_property(_kitchen, "fridge_crack", 1.0, 0.4).set_delay(0.15)
	tl.tween_interval(0.25)
	# 2) Klik: ışık yanar, karakter donakalır
	tl.tween_callback(func() -> void:
		AudioManager.play_sfx("res://assets/sounds/klik.ogg")
		_kitchen.flash = 1.0
		_kitchen.darkness = 0.0
		_kitchen.fridge_crack = 0.0
		_kitchen.actor_scared = true
		_shout.visible = true
		_place_label(_shout, home + Vector2(60.0, -GameConfig.KITCHEN_ACTOR_PX * 0.75))
	)
	tl.tween_property(_kitchen, "flash", 0.0, GameConfig.INTRO_FLASH_SEC)
	tl.tween_interval(0.15)
	# 3) Terlik kenardan dönerek gelir, böcek son anda kanat açıp uçar
	var from: Vector2 = Vector2(-120.0, home.y - 260.0)
	tl.tween_callback(func() -> void:
		_slipper.visible = true
		_slipper.position = from
		_slipper.rotation = 0.0
	)
	tl.tween_property(_slipper, "position", home + Vector2(0.0, 20.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tl.parallel().tween_property(_slipper, "rotation", TAU * 1.75, 0.45)
	tl.parallel().tween_callback(func() -> void:
		_kitchen.actor_scared = false
		_shout.visible = false
	).set_delay(0.3)
	tl.parallel().tween_property(_kitchen, "actor_offset", Vector2(vis.x * 0.22, -300.0), 0.35).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tl.tween_callback(func() -> void:
		AudioManager.play_sfx("res://assets/sounds/terlik_kirildi.ogg", 0.9, 1.0)
		_sapp.visible = true
		_place_label(_sapp, home + Vector2(0.0, -20.0))
		_sapp.scale = Vector2(0.4, 0.4)
		var pop: Tween = create_tween()
		pop.tween_property(_sapp, "scale", Vector2(1.15, 1.15), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop.tween_property(_sapp, "scale", Vector2.ONE, 0.1)
		_shake(10.0, 0.25)
	)
	tl.tween_interval(0.2)
	# 4) Logo düşer, iki kez sekip oturur; böcek tezgâha döner ve laf atar
	var lr: Rect2 = _layout["logo"] as Rect2
	tl.tween_property(_logo, "position:y", lr.position.y, 0.7).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tl.parallel().tween_property(_slipper, "modulate:a", 0.0, 0.3).set_delay(0.15)
	tl.parallel().tween_property(_sapp, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tl.parallel().tween_property(_kitchen, "actor_offset", Vector2.ZERO, 0.55).set_delay(0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tl.parallel().tween_callback(_say_line).set_delay(0.55)
	# 5) Kamera hafifçe geri çekilir -> menü
	tl.tween_property(_kitchen, "scale", Vector2.ONE, GameConfig.INTRO_PULLBACK_SEC).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tl.parallel().tween_property(_bubble, "modulate:a", 0.0, 0.3).set_delay(0.2)
	tl.tween_callback(_on_anim_done)


func _play_short() -> void:
	_kitchen.darkness = 1.0
	_kitchen.scale = Vector2.ONE * GameConfig.INTRO_PULLBACK_ZOOM
	var lr: Rect2 = _layout["logo"] as Rect2
	var tl: Tween = create_tween()
	_timeline = tl
	tl.tween_property(_cover, "modulate:a", 0.0, 0.15)
	tl.tween_callback(func() -> void:
		AudioManager.play_sfx("res://assets/sounds/klik.ogg")
		_kitchen.flash = 1.0
		_kitchen.darkness = 0.0
	)
	tl.tween_property(_kitchen, "flash", 0.0, GameConfig.INTRO_FLASH_SEC)
	tl.parallel().tween_property(_logo, "position:y", lr.position.y, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tl.tween_property(_kitchen, "scale", Vector2.ONE, GameConfig.INTRO_SHORT_SEC * 0.3).set_trans(Tween.TRANS_SINE)
	tl.tween_callback(_on_anim_done)


func _play_logo_only() -> void:
	var lr: Rect2 = _layout["logo"] as Rect2
	_logo.position = lr.position
	_logo.visible = false
	var tl: Tween = create_tween()
	_timeline = tl
	tl.tween_interval(0.35)
	tl.tween_callback(func() -> void:
		_logo.visible = true
	)
	tl.tween_property(_cover_logo, "position", lr.position, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tl.parallel().tween_property(_cover_logo, "size", lr.size, 0.4)
	tl.parallel().tween_property(_cover, "color:a", 0.0, 0.4)
	tl.tween_callback(_on_anim_done)


func _say_line() -> void:
	var cid: String = NetworkManager.selected_char_id
	var cdata: Dictionary = CharacterData.get_character(cid)
	AudioManager.play_character_voice(cid, "kactim")
	_bubble.text = str(cdata.get("flee_line", "Kıl payı!"))
	_bubble.visible = true
	var home: Vector2 = _kitchen.actor_home()
	_place_label(_bubble, home + Vector2(0.0, -GameConfig.KITCHEN_ACTOR_PX * 0.75))


func _shake(px: float, sec: float) -> void:
	var tw: Tween = create_tween()
	var steps: int = 6
	for i: int in range(steps):
		var k: float = 1.0 - float(i) / float(steps)
		var off: Vector2 = Vector2(px * k * (1.0 if i % 2 == 0 else -1.0), px * 0.5 * k * (1.0 if i % 3 == 0 else -1.0))
		tw.tween_property(_kitchen, "position", off, sec / float(steps))
	tw.tween_property(_kitchen, "position", Vector2.ZERO, 0.04)


## Dokununca: animasyonu son karesine atla.
func _input(event: InputEvent) -> void:
	if _anim_done or _kitchen == null:
		return
	var pressed: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed) \
		or (event is InputEventKey and (event as InputEventKey).pressed)
	if pressed:
		get_viewport().set_input_as_handled()
		skip()


func skip() -> void:
	if _anim_done:
		return
	if _timeline != null and _timeline.is_valid():
		_timeline.kill()
	var lr: Rect2 = _layout["logo"] as Rect2
	_kitchen.darkness = 0.0
	_kitchen.fridge_crack = 0.0
	_kitchen.flash = 0.0
	_kitchen.actor_scared = false
	_kitchen.actor_offset = Vector2.ZERO
	_kitchen.scale = Vector2.ONE
	_kitchen.position = Vector2.ZERO
	_cover.visible = false
	_slipper.visible = false
	_sapp.visible = false
	_shout.visible = false
	_bubble.visible = false
	_logo.visible = true
	_logo.position = lr.position
	_on_anim_done()


func _on_anim_done() -> void:
	_anim_done = true
	if kind == KIND_FULL:
		AudioManager.mark_intro_seen()
	_logo.floating = true
	_logo.set_process(true)


# ---------------------------------------------------------------------------
# Arka planda yükleme ve menüye geçiş
# ---------------------------------------------------------------------------

func _start_loads() -> void:
	_loads = preload_paths()
	for p: String in _loads:
		ResourceLoader.load_threaded_request(p)


func _poll_loads() -> void:
	if _loads_done:
		return
	var total: float = 0.0
	var all_done: bool = true
	for p: String in _loads:
		var prog: Array = []
		var st: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(p, prog)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			all_done = false
			total += float(prog[0]) if not prog.is_empty() else 0.0
		else:
			total += 1.0
	_progress = total / float(maxi(_loads.size(), 1))
	if all_done:
		_loads_done = true
		_progress = 1.0
		for p: String in _loads:
			if ResourceLoader.load_threaded_get_status(p) == ResourceLoader.THREAD_LOAD_LOADED:
				var r: Resource = ResourceLoader.load_threaded_get(p)
				if r != null:
					preloaded.append(r)


func is_loading_done() -> bool:
	return _loads_done


func loading_progress() -> float:
	return _progress


func _process(_delta: float) -> void:
	if _kitchen == null:
		return
	_poll_loads()
	if _anim_done:
		_bar.visible = not _loads_done
		_bar.queue_redraw()
		if _loads_done and not _leaving:
			_leaving = true
			_go_menu()


func _go_menu() -> void:
	var packed: PackedScene = null
	for r: Resource in preloaded:
		if r is PackedScene and (r as PackedScene).resource_path == GameConfig.MENU_SCENE_PATH:
			packed = r as PackedScene
	if packed == null:
		packed = load(GameConfig.MENU_SCENE_PATH) as PackedScene
	# Menü aynı mutfağı aynı yerde kurar; logo yerinde kalır, diğer öğeler belirir
	get_tree().root.set_meta("intro_handoff", true)
	get_tree().change_scene_to_packed(packed)

extends Node

## Faz 13B: mağaza görselleri. Gerçek sahneleri 1080x1920 çizer, üstüne Türkçe başlık koyar.
## Çıktı (res://store_output/, .gitignore'da): shot_1..6.png (1080x1920) ve feature_1024x500.png.
## Kullanım (pencereli): Godot --path . --resolution 540x960 res://tools/StoreShots.tscn
## Ayarlar diske yazılmaz; yalnızca bellekte değiştirilir. Sahne, 720x1280 tasarım boyutunda
## ölçeklenen bir SubViewport'a taşınır; başlık ikinci bir SubViewport'ta birleştirilir.

const DESIGN_SIZE: Vector2i = Vector2i(720, 1280)
const CAPTION_H: float = 330.0
const FRAME_SCALE: float = 0.80
const SETTLE_SEC: float = 1.2

var _nm: Node = null
var _scene_vp: SubViewport = null
var _keep_alive: bool = false
var _scene: Node = null   # SubViewport'a taşınan güncel sahne


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("StoreShots pencereli çalıştırılmalı (başsız modda çizim yapılmaz).")
		get_tree().quit(1)
		return
	# Bu düğüm sahne değişince silinmesin: güncel sahne yerine boş bir düğüm konur
	var holder: Node = Node.new()
	holder.name = "StoreShotsHolder"
	get_tree().root.add_child.call_deferred(holder)
	await get_tree().process_frame
	get_tree().current_scene = holder
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GameConfig.STORE_OUTPUT_DIR))
	_nm = get_node("/root/NetworkManager")
	var am: Node = get_node("/root/AudioManager")
	am.set("guide_seen", true)
	am.set("intro_seen", true)
	_nm.set("local_player_name", "Aykut")
	set_physics_process(true)
	await _run_all()
	print("STORE_SHOTS_DONE")
	get_tree().quit(0)


func _physics_process(_delta: float) -> void:
	# Oyun görüntüsünde yerel böcek ortada uçsun (düşüp ölmesin)
	if not _keep_alive:
		return
	var sc: Node = _scene
	if sc == null or not is_instance_valid(sc) or sc.name != "GameWorld":
		return
	var lp: Node = sc.get("local_player")
	if lp != null and int(lp.get("state")) == 1:
		lp.set("velocity_y", -200.0 if (lp.get("position") as Vector2).y > 560.0 else 0.0)


func _run_all() -> void:
	var caps: Array[String] = GameConfig.STORE_CAPTIONS

	# 1-2: Botlarla maç, ardından Annem Geldi olayı
	_keep_alive = true
	_nm.call("start_offline_bot_match", 4, "usta")
	var gw: Node = await _adopt_scene("GameWorld")
	await _wait(3.2)
	await _capture(caps[0], "shot_1.png")
	var t0: float = float(gw.get("match_time"))
	var ev: Dictionary = {"index": 99, "id": "annem", "start_time": t0, "end_time": t0 + 3.4, "level": 5, "start_dist": 0.0, "end_dist": 0.0}
	var ed: Node = gw.get("events_dir")
	ed.call("_start_event", ev)
	await _wait(GameConfig.EVENT_ANNEM_WARN_SEC + 0.3)
	await _capture(caps[1], "shot_2.png")
	ed.call("_end_active")
	_keep_alive = false
	_nm.call("leave_game")

	# 3: Böcekler sekmesi
	var menu: Node = await _open_scene(GameConfig.MENU_SCENE_PATH, "MainMenu")
	menu.call("_switch_tab", "bugs")
	await _wait(SETTLE_SEC)
	await _capture(caps[2], "shot_3.png")

	# 4: Tek başına ölüm karesi (paylaş / rövanş)
	_nm.call("prepare_single_player_seed", 777)
	gw = await _open_scene("res://scenes/game/GameWorld.tscn", "GameWorld")
	_keep_alive = true
	await _wait(1.6)
	_keep_alive = false
	var lp: Node = gw.get("local_player")
	if lp != null:
		lp.call("die", "terlik")
	await _wait(2.8)
	await _capture(caps[3], "shot_4.png")
	_nm.call("leave_game")

	# 5: Sesli sohbetli oda (yalnızca arayüz önizlemesi; mikrofon açılmaz)
	VoiceChat.ui_preview = true
	get_tree().get_multiplayer().multiplayer_peer = OfflineMultiplayerPeer.new()
	var am: Node = get_node("/root/AudioManager")
	am.set("vc_choice", "join")
	_nm.set("is_multiplayer_match", true)
	_nm.set("room_owner_id", 1)
	_nm.set("room_voice_chat_enabled", true)
	_nm.set("is_offline_bots", false)
	_nm.set("players", {
		1: {"name": "Aykut", "char_id": "klasik", "uid": "7NF6P22R", "total_points": 6, "wins": 1, "vc": 2, "is_alive": true},
		2: {"name": "Ayşe", "char_id": "diva", "uid": "AB12CD34", "total_points": 3, "wins": 0, "vc": 2, "is_alive": true},
		3: {"name": "Mehmet", "char_id": "duktur", "uid": "QW7EPL9N", "total_points": 1, "wins": 0, "vc": 1, "is_alive": true},
	})
	await _open_scene("res://scenes/ui/Lobby.tscn", "")
	await _wait(SETTLE_SEC)
	await _capture(caps[4], "shot_5.png")
	VoiceChat.ui_preview = false
	_nm.set("room_voice_chat_enabled", false)
	_nm.set("is_multiplayer_match", false)
	_nm.set("players", {})

	# 6: Görevler sekmesi
	menu = await _open_scene(GameConfig.MENU_SCENE_PATH, "MainMenu")
	menu.call("_switch_tab", "quests")
	await _wait(SETTLE_SEC)
	await _capture(caps[5], "shot_6.png")

	await _feature_graphic()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


## Sahneyi aç ve tasarım boyutlu SubViewport'a taşı.
func _open_scene(path: String, expect: String) -> Node:
	get_tree().change_scene_to_file(path)
	return await _adopt_scene(expect)


func _adopt_scene(expect: String) -> Node:
	var sc: Node = null
	for i: int in range(600):
		await get_tree().process_frame
		sc = get_tree().current_scene
		if sc != null and sc.name != "StoreShotsHolder" and (expect.is_empty() or sc.name == expect) and sc.is_node_ready():
			break
	if _scene_vp != null and is_instance_valid(_scene_vp):
		_scene_vp.queue_free()
	_scene_vp = SubViewport.new()
	_scene_vp.size = GameConfig.STORE_SHOT_SIZE
	_scene_vp.size_2d_override = DESIGN_SIZE
	_scene_vp.size_2d_override_stretch = true
	_scene_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_scene_vp.disable_3d = true
	add_child(_scene_vp)
	sc.get_parent().remove_child(sc)
	_scene_vp.add_child(sc)
	_scene = sc
	# İlk açılış rehberi gibi araya giren pencereler görüntüye girmesin
	for c: Node in sc.get_children():
		if c.get_script() != null and str(c.get_script().resource_path).ends_with("GuideModal.gd"):
			c.queue_free()
	return sc


## Başlık + çerçeveli sahne görüntüsünü birleştirip kaydeder.
func _capture(caption: String, file_name: String) -> void:
	await RenderingServer.frame_post_draw
	var shot: Image = _scene_vp.get_texture().get_image()
	var tex: ImageTexture = ImageTexture.create_from_image(shot)
	var sz: Vector2 = Vector2(GameConfig.STORE_SHOT_SIZE)
	var vp: SubViewport = _compose_vp(GameConfig.STORE_SHOT_SIZE)
	var bg: Control = Control.new()
	bg.size = sz
	bg.draw.connect(func() -> void:
		bg.draw_rect(Rect2(Vector2.ZERO, sz), GameConfig.COLOR_CREAM)
		var fw: float = sz.x * FRAME_SCALE
		var fh: float = sz.y * FRAME_SCALE
		var fr: Rect2 = Rect2((sz.x - fw) * 0.5, CAPTION_H, fw, fh)
		bg.draw_rect(Rect2(fr.position + Vector2(10.0, 14.0), fr.size), Color(GameConfig.COLOR_INK, 0.12))
		bg.draw_texture_rect(tex, fr, false)
		bg.draw_rect(fr.grow(3.0), GameConfig.COLOR_INK, false, 6.0)
	)
	vp.add_child(bg)
	var lbl: Label = Label.new()
	lbl.text = caption
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(70.0, 40.0)
	lbl.size = Vector2(sz.x - 140.0, CAPTION_H - 70.0)
	ComicUiHelper.style_label(lbl, 74, GameConfig.COLOR_INK, true)
	lbl.add_theme_constant_override("line_spacing", -26)
	vp.add_child(lbl)
	await _save_vp(vp, file_name)


func _compose_vp(sz: Vector2i) -> SubViewport:
	var vp: SubViewport = SubViewport.new()
	vp.size = sz
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.disable_3d = true
	add_child(vp)
	return vp


func _save_vp(vp: SubViewport, file_name: String) -> void:
	for i: int in range(3):
		await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	var path: String = ProjectSettings.globalize_path(GameConfig.STORE_OUTPUT_DIR + file_name)
	var err: Error = img.save_png(path)
	print("STORE ", file_name, " ", img.get_size(), " ", "ok" if err == OK else "HATA %d" % err)
	vp.queue_free()


## 1024x500 tanıtım görseli: gündüz mutfak, ortada logo, tezgâhta böcek.
func _feature_graphic() -> void:
	var fs: Vector2i = GameConfig.STORE_FEATURE_SIZE
	var vp: SubViewport = _compose_vp(fs)
	var k: KitchenScene = KitchenScene.new()
	k.force_night = 0
	k.jokes_enabled = false
	vp.add_child(k)
	k.position = Vector2.ZERO
	k.size = Vector2(fs)
	k.counter_y = float(fs.y) - 40.0
	k.set_actor("klasik")
	var logo: GameLogo = GameLogo.create(false, false)
	var w: float = float(fs.x) * 0.62
	logo.size = Vector2(w, w * GameConfig.MENU_LOGO_ASPECT)
	logo.position = Vector2((float(fs.x) - w) * 0.5, 28.0)
	vp.add_child(logo)
	await _wait(0.6)
	await _save_vp(vp, "feature_1024x500.png")

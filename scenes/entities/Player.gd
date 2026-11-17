extends Area2D

## Oyuncu hamam böceği kontrolcüsü: fizik, yetenekler, ağ senkronizasyonu ve halay zaferi.

signal died(cause: String)
signal ability_cooldown_changed(remaining: float, total: float)
signal ability_active_changed(active: bool)
signal ability2_cooldown_changed(remaining: float, total: float)
signal ability2_active_changed(active: bool)
signal confetti_requested
signal spray_hit
signal spare_leg_triggered
signal powerup_quick_use_requested
signal swipe_visual_requested(from_pos: Vector2, to_pos: Vector2)

enum State { IDLE_COUNTDOWN, ACTIVE, DEAD, HALAY }

var state: State = State.IDLE_COUNTDOWN
var velocity_y: float = 0.0
var char_id: String = "klasik"
var char_data: Dictionary = {}
var peer_id: int = 1
var is_local_player: bool = true
## Faz 11.1: deterministik bot (pozisyonu GameWorld plandan verir, çarpışma yok)
var is_bot: bool = false
## İsim etiketinin çakışma önleme kayması (GameWorld her kare verir)
var _name_base_y: float = 0.0
var _name_base_x: float = 0.0
var _name_shift: float = 0.0
## Faz 11.2: taç serisi (0 yok, 1+ son kazanan, 3+ Mahalle Muhtarı)
var crown_streak: int = 0
var _bot_badge: Label = null
var _crown_node: Node2D = null
var _title_label: Label = null

var _float_time: float = 0.0
var _squash_tween: Tween = null
var _cooldown_remaining: float = 0.0
var _ability_remaining: float = 0.0
var _cooldown2_remaining: float = 0.0
var _ability2_remaining: float = 0.0
var _post_invuln_remaining: float = 0.0
var _spray_slow_remaining: float = 0.0
var _shield_active: bool = false
var _ghost_active: bool = false
var _shrink_active: bool = false
var _gravity_ability_mult: float = 1.0
var _shrink_gravity_mult: float = 1.0
var _max_fall_mult: float = 1.0
var _pulse_time: float = 0.0
var _base_sprite_pos: Vector2 = Vector2.ZERO
var _base_sprite_scale: Vector2 = Vector2(GameConfig.PLAYER_VISUAL_SCALE, GameConfig.PLAYER_VISUAL_SCALE)

var _sync_timer: float = 0.0
var _target_y: float = GameConfig.PLAYER_START_Y
var _target_rot: float = 0.0
var _halay_time: float = 0.0
var _halay_base_pos: Vector2 = Vector2.ZERO
var _wing_time: float = 0.0
var _wing_boost: float = 0.0
var _limb_overlay: Node2D = null
var _rig: CharacterRig = null
var _ability_buffer_slot: int = 0
var _ability_buffer_rem: float = 0.0
var _touches: Dictionary = {} # touch_idx -> {start_pos, start_ms, swiped}
var nearest_danger_dir: Vector2 = Vector2.RIGHT

var has_spare_leg: bool = false
var used_spare_leg_in_match: bool = false
var turbo_remaining: float = 0.0
var _turbo_pierce_ready: bool = false
var magnet_remaining: float = 0.0
var _combo_label: Label = null
var _ice_taunt_remaining: float = 0.0
var _coffee_taunt_remaining: float = 0.0
var _aunt_taunt_remaining: float = 0.0
var last_taunt_sender_name: String = ""

# Faz 10.2: imza ödülü etkileri
var sig_bread_remaining: float = 0.0
var sig_vaccine_remaining: float = 0.0
var sig_coffee_remaining: float = 0.0
var sig_pepper_remaining: float = 0.0
var sig_balloon_remaining: float = 0.0
var _pepper_pierce_ready: bool = false
var _next_shield_bonus: float = 0.0
var _base_hitbox_radius: float = 0.0
var _pepper_smoke: CPUParticles2D = null
var _fx_rng: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var back_aura: Node2D = $BackAura
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var wing_overlay: Node2D = $WingOverlay
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var shield_ring: Node2D = $ShieldRing
@onready var player_light: PointLight2D = $PlayerLight
@onready var name_label: Label = $NameLabel
@onready var speech_bubble: Node2D = $SpeechBubble


func _ready() -> void:
	_fx_rng.randomize()
	_name_base_y = name_label.position.y
	_name_base_x = name_label.position.x
	# İsim etiketleri tüm böceklerin üstünde çizilsin (yerel böcek etiketleri örtmesin)
	name_label.z_as_relative = false
	name_label.z_index = GameConfig.NAME_LABEL_Z
	collision_layer = GameConfig.LAYER_PLAYER
	collision_mask = GameConfig.LAYER_SLIPPER | GameConfig.LAYER_MISSILE
	monitoring = true
	monitorable = true

	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = GameConfig.PLAYER_HITBOX_RADIUS
	hitbox.shape = circle

	shield_ring.draw.connect(_on_shield_draw)
	back_aura.draw.connect(_on_back_aura_draw)
	wing_overlay.draw.connect(_on_wing_draw)
	_limb_overlay = Node2D.new()
	_limb_overlay.name = "LimbOverlay"
	_limb_overlay.draw.connect(_on_limb_draw)
	add_child(_limb_overlay)
	move_child(_limb_overlay, sprite.get_index())

	_rig = CharacterRig.new()
	_rig.name = "CharacterRig"
	add_child(_rig)
	move_child(_rig, sprite.get_index())
	area_entered.connect(_on_area_entered)
	_setup_light_and_name()
	if not NetworkManager.is_multiplayer_match:
		load_character(NetworkManager.selected_char_id)
		reset_for_countdown()
	back_aura.queue_redraw()


## Çok oyunculu modda oyuncuyu ağ kimliği ve yetkisine göre ayarlar.
func configure_network(p_peer_id: int, p_name: String, p_char_id: String) -> void:
	peer_id = p_peer_id
	set_multiplayer_authority(peer_id)
	is_local_player = (peer_id == multiplayer.get_unique_id())
	load_character(p_char_id)
	name_label.text = p_name

	if is_local_player:
		z_index = 10
		modulate.a = 1.0
		name_label.visible = false
		monitoring = true
		hitbox.set_deferred("disabled", false)
	else:
		z_index = 5
		modulate.a = GameConfig.REMOTE_PLAYER_ALPHA
		name_label.visible = true
		monitoring = false
		hitbox.set_deferred("disabled", true)

	reset_for_countdown()


## Faz 11.1: Bot olarak ayarlar: uzak oyuncu gibi yarı saydam, isim + "BOT" rozeti, çarpışmasız.
func configure_bot(p_peer_id: int, p_name: String, p_char_id: String) -> void:
	peer_id = p_peer_id
	is_bot = true
	is_local_player = false
	load_character(p_char_id)
	name_label.text = p_name
	z_index = 5
	modulate.a = GameConfig.REMOTE_PLAYER_ALPHA
	name_label.visible = true
	# Gövde yarı saydam kalsın ama isim ve BOT rozeti okunsun
	name_label.modulate = Color(1.0, 1.0, 1.0, 0.9 / GameConfig.REMOTE_PLAYER_ALPHA)
	monitoring = false
	hitbox.set_deferred("disabled", true)
	if _bot_badge == null:
		_bot_badge = Label.new()
		_bot_badge.name = "BotBadge"
		_bot_badge.text = "BOT"
		_bot_badge.add_theme_font_override("font", AssetHelper.get_title_font())
		_bot_badge.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
		_bot_badge.add_theme_color_override("font_color", GameConfig.COLOR_CREAM)
		var sb: StyleBoxFlat = StyleBoxFlat.new()
		sb.bg_color = GameConfig.COLOR_BROWN
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 6
		sb.content_margin_right = 6
		sb.content_margin_top = 0
		sb.content_margin_bottom = 1
		_bot_badge.add_theme_stylebox_override("normal", sb)
		name_label.add_child(_bot_badge)
		name_label.resized.connect(_layout_name_extras)
	_layout_name_extras()
	_layout_name_extras.call_deferred()
	reset_for_countdown()


## İsim etiketini yazı genişliğine göre ortalar, BOT rozetini hemen sağına koyar.
func _layout_name_extras() -> void:
	if _bot_badge == null or not is_instance_valid(_bot_badge):
		return
	var font: Font = name_label.get_theme_font("font")
	var fsize: int = name_label.get_theme_font_size("font_size")
	var text_w: float = font.get_string_size(name_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x if font != null else 80.0
	var badge_sz: Vector2 = _bot_badge.get_combined_minimum_size()
	var lbl_w: float = name_label.size.x
	var text_start: float = (lbl_w - text_w) * 0.5
	# Yazı + rozet birlikte ortalansın: etiketi rozet payının yarısı kadar sola kaydır
	name_label.position.x = -lbl_w * 0.5 - (badge_sz.x + 6.0) * 0.5
	_name_base_x = name_label.position.x
	_bot_badge.position = Vector2(text_start + text_w + 6.0, (name_label.size.y - badge_sz.y) * 0.5)
	_bot_badge.size = badge_sz


## İsim etiketini dikeyde kaydırır (yumuşak geçişle); yalnızca görsel.
func set_name_shift(target: float, delta: float) -> void:
	_name_shift = lerpf(_name_shift, target, clampf(delta * GameConfig.NAME_LABEL_SHIFT_SPEED, 0.0, 1.0))


## Bot görsel pozu (GameWorld her kare plandan verir).
func set_bot_pose(y: float, rot: float) -> void:
	if state != State.ACTIVE:
		return
	position.y = y
	rotation = rot
	if _rig != null:
		_rig.update_secondary(get_physics_process_delta_time(), nearest_danger_dir, false, false)


## Bot görsel yetenek/imza kullanımı (ölüm anını değiştirmez; yalnızca balon ve efekt).
func bot_visual_ability(slot: int) -> void:
	if state != State.ACTIVE:
		return
	if slot == 2 or slot == 1:
		_execute_ability(slot)


## Bot imza ödülü balonu (görsel).
func bot_visual_signature() -> void:
	if state != State.ACTIVE:
		return
	var sig_id: String = GameConfig.get_signature_for(char_id)
	if sig_id.is_empty():
		return
	speech_bubble.show_text(str(GameConfig.get_item_def(sig_id).get("quote", "")), 1.6)


## Faz 11.2: Taç (son kazanan) ve 3+ seride "Mahalle Muhtarı" unvanı.
func set_crown(streak: int) -> void:
	crown_streak = maxi(streak, 0)
	if crown_streak <= 0:
		if _crown_node != null and is_instance_valid(_crown_node):
			_crown_node.queue_free()
		_crown_node = null
		if _title_label != null and is_instance_valid(_title_label):
			_title_label.queue_free()
		_title_label = null
		return
	if _crown_node == null:
		_crown_node = Node2D.new()
		_crown_node.name = "Crown"
		_crown_node.z_index = 2
		_crown_node.draw.connect(_on_crown_draw)
		add_child(_crown_node)
	var big: bool = crown_streak >= GameConfig.CROWN_MUHTAR_STREAK
	_crown_node.scale = Vector2.ONE * (1.5 if big else 1.0)
	_crown_node.position = Vector2(0.0, -112.0 if name_label.visible else -78.0)
	_crown_node.queue_redraw()
	if big:
		if _title_label == null:
			_title_label = Label.new()
			_title_label.name = "TitleLabel"
			_title_label.text = "Mahalle Muhtarı"
			_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			_title_label.size = Vector2(220.0, 26.0)
			_title_label.position = Vector2(-110.0, 40.0)
			_title_label.add_theme_font_override("font", AssetHelper.get_title_font())
			_title_label.add_theme_font_size_override("font_size", GameConfig.FS_TINY)
			_title_label.add_theme_color_override("font_color", GameConfig.COLOR_GOLD)
			_title_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_INK)
			_title_label.add_theme_constant_override("outline_size", 5)
			add_child(_title_label)
	elif _title_label != null and is_instance_valid(_title_label):
		_title_label.queue_free()
		_title_label = null


func _on_crown_draw() -> void:
	if _crown_node == null:
		return
	var gold: Color = GameConfig.COLOR_GOLD
	var ink: Color = GameConfig.COLOR_INK
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(-20.0, 8.0), Vector2(-22.0, -10.0), Vector2(-10.0, -1.0), Vector2(0.0, -16.0),
		Vector2(10.0, -1.0), Vector2(22.0, -10.0), Vector2(20.0, 8.0),
	])
	_crown_node.draw_colored_polygon(pts, gold)
	var outline: PackedVector2Array = pts.duplicate()
	outline.append(pts[0])
	_crown_node.draw_polyline(outline, ink, 2.5, true)
	_crown_node.draw_circle(Vector2(0.0, -16.0), 3.2, GameConfig.COLOR_WARN_RED)
	_crown_node.draw_circle(Vector2(-22.0, -10.0), 2.6, GameConfig.COLOR_DUST_BLUE)
	_crown_node.draw_circle(Vector2(22.0, -10.0), 2.6, GameConfig.COLOR_DUST_BLUE)


func _setup_light_and_name() -> void:
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(1.0, 0.92, 0.78, 0.85))
	grad.set_color(1, Color(1.0, 0.92, 0.78, 0.0))
	var gtex: GradientTexture2D = GradientTexture2D.new()
	gtex.width = 128
	gtex.height = 128
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.gradient = grad
	player_light.texture = gtex
	player_light.texture_scale = 2.2
	player_light.energy = 0.85
	player_light.enabled = false

	var font: Font = AssetHelper.get_ui_font()
	name_label.add_theme_font_override("font", font)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	name_label.add_theme_constant_override("outline_size", 5)


## Karanlık evrede oyuncunun kendi ışığını açar veya kapatır.
func set_dark_light(active: bool) -> void:
	player_light.enabled = active and is_local_player


## Seçilen karakterin görselini ve pasif istatistiklerini uygular.
func load_character(p_char_id: String) -> void:
	char_id = p_char_id
	char_data = CharacterData.get_character(char_id)
	sprite.texture = AssetHelper.texture(
		str(char_data["sprite_path"]),
		str(char_data["fallback_kind"]),
		GameConfig.PLAYER_SPRITE_SIZE
	)
	var tex_sz: Vector2 = sprite.texture.get_size() if sprite.texture != null else Vector2(128.0, 128.0)
	var max_dim: float = maxf(tex_sz.x, tex_sz.y)
	var norm: float = (128.0 / max_dim) if max_dim > 0.0 else 1.0
	_base_sprite_scale = Vector2(norm * GameConfig.PLAYER_VISUAL_SCALE, norm * GameConfig.PLAYER_VISUAL_SCALE)
	sprite.scale = _base_sprite_scale
	shadow_sprite.texture = sprite.texture
	shadow_sprite.scale = sprite.scale

	var circle: CircleShape2D = hitbox.shape as CircleShape2D
	if circle != null:
		circle.radius = GameConfig.PLAYER_HITBOX_RADIUS * float(char_data["hitbox_scale"])
		_base_hitbox_radius = circle.radius
	if _rig != null:
		_rig.setup(char_id)
	# Diva pasifi: Işıltı (%50 geniş ışık)
	player_light.texture_scale = 3.3 if char_id == "diva" else 2.2


## Geri sayım başlangıcı için oyuncuyu başlangıç konumuna alır.
func reset_for_countdown() -> void:
	state = State.IDLE_COUNTDOWN
	position = Vector2(GameConfig.PLAYER_X, GameConfig.PLAYER_START_Y)
	_target_y = GameConfig.PLAYER_START_Y
	_target_rot = 0.0
	rotation = 0.0
	scale = Vector2.ONE
	velocity_y = 0.0
	_float_time = 0.0
	_cooldown_remaining = 0.0
	_ability_remaining = 0.0
	_cooldown2_remaining = 0.0
	_ability2_remaining = 0.0
	_post_invuln_remaining = 0.0
	_spray_slow_remaining = 0.0
	_shield_active = false
	_ghost_active = false
	_shrink_active = false
	_gravity_ability_mult = 1.0
	_shrink_gravity_mult = 1.0
	_max_fall_mult = 1.0
	visible = true
	sprite.modulate.a = 1.0
	_ghost_active = false
	_gravity_ability_mult = 1.0
	has_spare_leg = false
	used_spare_leg_in_match = false
	turbo_remaining = 0.0
	_turbo_pierce_ready = false
	magnet_remaining = 0.0
	_ice_taunt_remaining = 0.0
	_coffee_taunt_remaining = 0.0
	_aunt_taunt_remaining = 0.0
	last_taunt_sender_name = ""
	_clear_signature_effects()
	modulate = Color(1.0, 1.0, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
	sprite.position = _base_sprite_pos
	sprite.scale = _base_sprite_scale
	if is_local_player:
		hitbox.set_deferred("disabled", false)
	shield_ring.queue_redraw()
	ability_cooldown_changed.emit(0.0, float(char_data.get("cooldown", 1.0)))
	ability_active_changed.emit(false)


## Geri sayım bittiğinde uçuşu başlatır.
func start_flying() -> void:
	if state == State.DEAD:
		return
	state = State.ACTIVE
	velocity_y = GameConfig.FLAP_VELOCITY * 0.55 * float(char_data.get("flap_mult", 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if not is_local_player or state != State.ACTIVE:
		return
	if AudioManager.control_scheme == "swipe":
		if event is InputEventScreenTouch:
			var st: InputEventScreenTouch = event as InputEventScreenTouch
			if st.pressed:
				_touches[st.index] = {"start_pos": st.position, "start_ms": Time.get_ticks_msec(), "swiped": false}
				if _touches.size() >= 2:
					powerup_quick_use_requested.emit()
				else:
					flap()
				get_viewport().set_input_as_handled()
				return
			else:
				_touches.erase(st.index)
				return
		elif event is InputEventScreenDrag:
			var sd: InputEventScreenDrag = event as InputEventScreenDrag
			if _touches.has(sd.index):
				var tinfo: Dictionary = _touches[sd.index] as Dictionary
				if not bool(tinfo["swiped"]) and (Time.get_ticks_msec() - int(tinfo["start_ms"])) <= GameConfig.SWIPE_MAX_MS:
					var dy: float = sd.position.y - (tinfo["start_pos"] as Vector2).y
					if dy <= -GameConfig.SWIPE_THRESHOLD_PX:
						tinfo["swiped"] = true
						swipe_visual_requested.emit(tinfo["start_pos"] as Vector2, sd.position)
						activate_ability_slot(1)
						get_viewport().set_input_as_handled()
						return
					elif dy >= GameConfig.SWIPE_THRESHOLD_PX:
						tinfo["swiped"] = true
						swipe_visual_requested.emit(tinfo["start_pos"] as Vector2, sd.position)
						activate_ability_slot(2)
						get_viewport().set_input_as_handled()
						return

	if event.is_action_pressed("flap"):
		flap()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability"):
		activate_ability_slot(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_2"):
		activate_ability_slot(2)
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	speech_bubble.rotation = -rotation
	name_label.rotation = -rotation
	# Etiket gövdeyle birlikte dönmesin: konumu da ters döndürülür (hep böceğin tam üstünde, dik)
	name_label.position = Vector2(_name_base_x, _name_base_y + _name_shift).rotated(-rotation)
	shadow_sprite.scale = sprite.scale
	_wing_boost = maxf(_wing_boost - delta * 3.0, 0.0)
	_wing_time += delta * (26.0 + _wing_boost * 24.0)
	if state == State.ACTIVE or state == State.IDLE_COUNTDOWN:
		wing_overlay.queue_redraw()
		if _limb_overlay != null:
			_limb_overlay.queue_redraw()
		if _squash_tween == null or not _squash_tween.is_running():
			var breath: float = 1.0 + sin(_wing_time * 0.45) * 0.035
			# Normalize edilmiş temel ölçek korunur (256 px görseller 2 kat büyük çizilmesin).
			sprite.scale = _base_sprite_scale * Vector2(breath, 2.0 - breath)

	if state == State.HALAY:
		_halay_time += delta
		var sway_x: float = sin(_halay_time * 6.0) * 14.0
		var bounce_y: float = -absf(sin(_halay_time * 9.0)) * 22.0
		position = _halay_base_pos + Vector2(sway_x, bounce_y)
		rotation = sin(_halay_time * 6.0) * deg_to_rad(10.0)
		return

	if state == State.ACTIVE:
		_update_ability_timers(delta)

	if not is_local_player:
		_process_remote(delta)
		return

	match state:
		State.IDLE_COUNTDOWN:
			_float_time += delta
			position.y = GameConfig.PLAYER_START_Y + sin(_float_time * GameConfig.COUNTDOWN_FLOAT_SPEED) * GameConfig.COUNTDOWN_FLOAT_AMP
		State.ACTIVE:
			var g_mult: float = float(char_data.get("gravity_mult", 1.0)) * _gravity_ability_mult * _shrink_gravity_mult
			if sig_balloon_remaining > 0.0:
				g_mult *= GameConfig.SIG_BALLOON_GRAVITY_MULT
			velocity_y = minf(velocity_y + GameConfig.GRAVITY * g_mult * delta, GameConfig.MAX_FALL_SPEED * _max_fall_mult)
			position.y += velocity_y * delta

			if GameConfig.BODY_TILT_MAX > 0.0:
				var target_deg: float = clampf(GameConfig.ROT_UP_DEG if velocity_y < 0.0 else GameConfig.ROT_DOWN_DEG, -GameConfig.BODY_TILT_MAX, GameConfig.BODY_TILT_MAX)
				rotation = lerpf(rotation, deg_to_rad(target_deg), clampf(delta * GameConfig.ROT_LERP_SPEED, 0.0, 1.0))
			else:
				rotation = 0.0
			if _rig != null:
				_rig.update_secondary(delta, nearest_danger_dir, velocity_y > 380.0, false)

			if position.y < GameConfig.CEILING_Y:
				die("tavan")
			elif position.y > GameConfig.FLOOR_Y:
				die("zemin")

			var target_x: float = GameConfig.POWERUP_TURBO_TARGET_X if turbo_remaining > 0.0 else GameConfig.PLAYER_X
			position.x = lerpf(position.x, target_x, clampf(delta * 5.0, 0.0, 1.0))

			if NetworkManager.is_multiplayer_match:
				_sync_timer += delta
				if _sync_timer >= 1.0 / GameConfig.NET_STATE_SYNC_HZ:
					_sync_timer = 0.0
					sync_state.rpc(position.y, rotation, _ability_remaining > 0.0)
		State.DEAD:
			velocity_y = minf(velocity_y + GameConfig.GRAVITY * delta, GameConfig.MAX_FALL_SPEED * 1.4)
			position.y += velocity_y * delta
			rotation += GameConfig.DEATH_SPIN_SPEED * delta
			if position.y > GameConfig.VIEWPORT_HEIGHT + 120.0:
				visible = false


func _process_remote(delta: float) -> void:
	match state:
		State.IDLE_COUNTDOWN:
			_float_time += delta
			position.y = GameConfig.PLAYER_START_Y + sin(_float_time * GameConfig.COUNTDOWN_FLOAT_SPEED) * GameConfig.COUNTDOWN_FLOAT_AMP
		State.ACTIVE:
			if is_bot:
				return
			var weight: float = clampf(delta * GameConfig.NET_STATE_LERP_SPEED, 0.0, 1.0)
			position.y = lerpf(position.y, _target_y, weight)
			rotation = lerp_angle(rotation, _target_rot, weight)
		State.DEAD:
			velocity_y = minf(velocity_y + GameConfig.GRAVITY * delta, GameConfig.MAX_FALL_SPEED * 1.4)
			position.y += velocity_y * delta
			rotation += GameConfig.DEATH_SPIN_SPEED * delta
			if position.y > GameConfig.VIEWPORT_HEIGHT + 120.0:
				visible = false


func _update_ability_timers(delta: float) -> void:
	var sk1: Dictionary = CharacterData.get_skill(char_id, "aktif1")
	var total_cd1: float = float(sk1.get("cooldown", char_data.get("cooldown", 10.0))) * _cooldown_mult()
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - delta, 0.0)
		if is_local_player:
			ability_cooldown_changed.emit(_cooldown_remaining, total_cd1)
			if _cooldown_remaining <= 0.0 and AudioManager.is_vibration_enabled:
				Input.vibrate_handheld(20)
			if _cooldown_remaining <= 0.0 and _ability_buffer_slot == 1 and _ability_buffer_rem > 0.0:
				_ability_buffer_slot = 0
				activate_ability_slot(1)

	var sk2: Dictionary = CharacterData.get_skill(char_id, "aktif2")
	var total_cd2: float = float(sk2.get("cooldown", 12.0))
	if _cooldown2_remaining > 0.0:
		_cooldown2_remaining = maxf(_cooldown2_remaining - delta, 0.0)
		if is_local_player:
			ability2_cooldown_changed.emit(_cooldown2_remaining, total_cd2)
			if _cooldown2_remaining <= 0.0 and AudioManager.is_vibration_enabled:
				Input.vibrate_handheld(20)
			if _cooldown2_remaining <= 0.0 and _ability_buffer_slot == 2 and _ability_buffer_rem > 0.0:
				_ability_buffer_slot = 0
				activate_ability_slot(2)

	if _ability_buffer_rem > 0.0:
		_ability_buffer_rem = maxf(_ability_buffer_rem - delta, 0.0)

	if _post_invuln_remaining > 0.0:
		_post_invuln_remaining = maxf(_post_invuln_remaining - delta, 0.0)
		sprite.modulate.a = 0.52 if int(_post_invuln_remaining * 20.0) % 2 == 0 else 1.0
		if _post_invuln_remaining <= 0.0:
			sprite.modulate.a = 1.0
			_recheck_overlaps()

	if _spray_slow_remaining > 0.0:
		_spray_slow_remaining = maxf(_spray_slow_remaining - delta, 0.0)

	if turbo_remaining > 0.0:
		turbo_remaining = maxf(turbo_remaining - delta, 0.0)
		if int(turbo_remaining * 20.0) != int((turbo_remaining + delta) * 20.0):
			_spawn_flap_puff()

	if magnet_remaining > 0.0:
		magnet_remaining = maxf(magnet_remaining - delta, 0.0)

	_update_signature_timers(delta)

	if _ice_taunt_remaining > 0.0:
		_ice_taunt_remaining = maxf(_ice_taunt_remaining - delta, 0.0)
		if _ice_taunt_remaining <= 0.0:
			modulate = Color(1.0, 1.0, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
			last_taunt_sender_name = ""
	if _coffee_taunt_remaining > 0.0:
		_coffee_taunt_remaining = maxf(_coffee_taunt_remaining - delta, 0.0)
		sprite.position = _base_sprite_pos + Vector2(sin(_wing_time * 3.0) * 5.0, cos(_wing_time * 3.7) * 5.0)
		if _coffee_taunt_remaining <= 0.0:
			sprite.position = _base_sprite_pos
			last_taunt_sender_name = ""
	if _aunt_taunt_remaining > 0.0:
		_aunt_taunt_remaining = maxf(_aunt_taunt_remaining - delta, 0.0)
		if _aunt_taunt_remaining <= 0.0:
			last_taunt_sender_name = ""

	if _ability_remaining > 0.0:
		_ability_remaining = maxf(_ability_remaining - delta, 0.0)
		_pulse_time += delta
		if _shield_active:
			shield_ring.queue_redraw()
		if _ghost_active:
			sprite.position = Vector2(
				sin(_pulse_time * 48.0) * GameConfig.HALAY_JITTER_PX,
				cos(_pulse_time * 39.0) * GameConfig.HALAY_JITTER_PX
			)
		if _ability_remaining <= 0.0:
			_end_ability(1)

	if _ability2_remaining > 0.0:
		_ability2_remaining = maxf(_ability2_remaining - delta, 0.0)
		_pulse_time += delta
		if _shrink_active and char_id == "halaybasi":
			sprite.position = Vector2(sin(_pulse_time * 18.0) * 6.0, 0.0)
		if _ability2_remaining <= 0.0:
			_end_ability(2)


func reduce_cooldowns(amount: float) -> void:
	var sk1: Dictionary = CharacterData.get_skill(char_id, "aktif1")
	var sk2: Dictionary = CharacterData.get_skill(char_id, "aktif2")
	if _cooldown_remaining > 0.0:
		_cooldown_remaining = maxf(_cooldown_remaining - amount, 0.0)
		if is_local_player:
			ability_cooldown_changed.emit(_cooldown_remaining, float(sk1.get("cooldown", 10.0)))
	if _cooldown2_remaining > 0.0:
		_cooldown2_remaining = maxf(_cooldown2_remaining - amount, 0.0)
		if is_local_player:
			ability2_cooldown_changed.emit(_cooldown2_remaining, float(sk2.get("cooldown", 12.0)))


## Kanat çırpma zıplaması ve squash animasyonu uygular.
func flap() -> void:
	# Dayı "Çay Molası": havada asılı kalırken zıplama kapalı (yoksa sabit hızla tavana çakılıyordu).
	if char_id == "dayi" and _ability_remaining > 0.0:
		return
	var f_mult: float = float(char_data.get("flap_mult", 1.0))
	if _spray_slow_remaining > 0.0:
		f_mult *= GameConfig.SPRAY_SLOW_MULT
	if _ice_taunt_remaining > 0.0:
		f_mult *= 0.70
	if _coffee_taunt_remaining > 0.0:
		f_mult *= 1.35
	if _aunt_taunt_remaining > 0.0:
		velocity_y = absf(GameConfig.FLAP_VELOCITY) * 0.85
	else:
		if sig_pepper_remaining > 0.0:
			var jitter: float = GameConfig.SIG_PEPPER_FLAP_JITTER
			f_mult *= GameConfig.SIG_PEPPER_FLAP_MULT * (1.0 + _fx_rng.randf_range(-jitter, jitter))
		velocity_y = GameConfig.FLAP_VELOCITY * f_mult
	if _squash_tween != null and _squash_tween.is_valid():
		_squash_tween.kill()
	var base_scale: Vector2 = _base_sprite_scale
	sprite.scale = base_scale * GameConfig.FLAP_SQUASH_SCALE
	_squash_tween = create_tween()
	_squash_tween.tween_property(sprite, "scale", base_scale, GameConfig.FLAP_SQUASH_DURATION)
	_wing_boost = 1.0
	_spawn_flap_puff()
	if is_local_player:
		AudioManager.play_sfx("res://assets/sounds/ucus.ogg", 0.9, 1.15)


func _spawn_flap_puff() -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.position = Vector2(-28.0, 18.0)
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.85
	p.amount = 6
	p.lifetime = 0.28
	p.direction = Vector2(-1.0, 0.4)
	p.spread = 35.0
	p.gravity = Vector2(0.0, 120.0)
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 130.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 11.0
	p.color = Color(1.0, 0.98, 0.92, 0.7)
	add_child(p)
	# Sahne değişirse zamanlayıcı serbest bırakılmış düğümü yakalamasın
	p.finished.connect(p.queue_free)


## Karakterin 1. aktif yeteneğini tetikler.
func activate_ability() -> void:
	activate_ability_slot(1)


## Karakterin seçili aktif yetenek yuvasını (1 veya 2) tetikler.
func activate_ability_slot(slot: int) -> void:
	if not is_local_player or state != State.ACTIVE:
		return
	if slot == 1 and (_cooldown_remaining > 0.0 or _ability_remaining > 0.0):
		if _cooldown_remaining > 0.0 and _cooldown_remaining <= GameConfig.ABILITY_BUFFER_SEC:
			_ability_buffer_slot = 1
			_ability_buffer_rem = GameConfig.ABILITY_BUFFER_SEC
		return
	if slot == 2 and (_cooldown2_remaining > 0.0 or _ability2_remaining > 0.0):
		if _cooldown2_remaining > 0.0 and _cooldown2_remaining <= GameConfig.ABILITY_BUFFER_SEC:
			_ability_buffer_slot = 2
			_ability_buffer_rem = GameConfig.ABILITY_BUFFER_SEC
		return
	if NetworkManager.is_multiplayer_match:
		use_ability.rpc(slot)
	else:
		_execute_ability(slot)


@rpc("any_peer", "call_local", "reliable")
func use_ability(slot: int = 1) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != 0 and sender_id != get_multiplayer_authority():
		return
	_execute_ability(slot)


func _execute_ability(slot: int = 1) -> void:
	if slot == 2:
		var sk2: Dictionary = CharacterData.get_skill(char_id, "aktif2")
		var total_cd2: float = float(sk2.get("cooldown", 12.0))
		var dur2: float = float(sk2.get("duration", 2.5))
		var target_scale: float = float(sk2.get("scale", 0.65))
		_cooldown2_remaining = total_cd2
		_ability2_remaining = dur2
		_shrink_active = true
		_shrink_gravity_mult = float(sk2.get("gravity_mult", 1.0))
		if is_local_player:
			ability2_active_changed.emit(true)
			ability2_cooldown_changed.emit(_cooldown2_remaining, total_cd2)
		speech_bubble.show_text(str(sk2.get("line", "")), GameConfig.SPEECH_ABILITY_DURATION)
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2(target_scale, target_scale), GameConfig.SHRINK_TWEEN_SEC)
		AudioManager.play_sfx("res://assets/sounds/kucul.ogg")
		return

	var sk1: Dictionary = CharacterData.get_skill(char_id, "aktif1")
	var total_cd: float = float(sk1.get("cooldown", char_data.get("cooldown", 10.0))) * _cooldown_mult()
	var duration: float = float(sk1.get("duration", char_data.get("duration", 1.0)))
	if _next_shield_bonus > 0.0:
		duration += _next_shield_bonus
		_next_shield_bonus = 0.0
	_cooldown_remaining = total_cd
	_ability_remaining = duration
	_pulse_time = 0.0

	if is_local_player:
		ability_active_changed.emit(true)
		ability_cooldown_changed.emit(_cooldown_remaining, total_cd)
	speech_bubble.show_text(str(sk1.get("line", char_data.get("ability_line", ""))), GameConfig.SPEECH_ABILITY_DURATION)

	match char_id:
		"klasik":
			velocity_y = 0.0
			_gravity_ability_mult = GameConfig.KLASIK_BRAKE_GRAVITY_MULT
			AudioManager.play_sfx("res://assets/sounds/fren.ogg")
		"diva", "yurt":
			_shield_active = true
			shield_ring.queue_redraw()
			AudioManager.play_sfx("res://assets/sounds/kalkan.ogg")
		"duktur", "siber":
			_gravity_ability_mult = 0.55
			_max_fall_mult = 0.6
			AudioManager.play_sfx("res://assets/sounds/fren.ogg")
		"dayi":
			velocity_y = 0.0
			_gravity_ability_mult = 0.0
			_max_fall_mult = 0.0
			AudioManager.play_sfx("res://assets/sounds/fren.ogg")
		"halaybasi":
			_ghost_active = true
			modulate = GameConfig.HALAY_GHOST_TINT
			AudioManager.play_sfx("res://assets/sounds/mendil.ogg")
			if not NetworkManager.is_multiplayer_match or not is_local_player:
				confetti_requested.emit()
		"taraftar", "usta", "plaza", "emlakci", "saftirik", "deli":
			_shield_active = true
			shield_ring.queue_redraw()
			if char_id == "emlakci":
				position.y = clampf(position.y, 240.0, 760.0)
			AudioManager.play_sfx("res://assets/sounds/turbo.ogg")


func _end_ability(slot: int = 1) -> void:
	if slot == 2:
		_shrink_active = false
		_shrink_gravity_mult = 1.0
		sprite.position = _base_sprite_pos
		_post_invuln_remaining = GameConfig.SHRINK_UNGROW_INVULN
		if is_local_player:
			ability2_active_changed.emit(false)
		var tw: Tween = create_tween()
		tw.tween_property(self, "scale", Vector2.ONE, GameConfig.SHRINK_TWEEN_SEC)
		return

	if is_local_player:
		ability_active_changed.emit(false)
	match char_id:
		"klasik":
			_gravity_ability_mult = 1.0
		"diva", "yurt", "taraftar", "usta", "plaza", "emlakci", "saftirik", "deli":
			_shield_active = false
			shield_ring.queue_redraw()
		"duktur", "siber", "dayi":
			_gravity_ability_mult = 1.0
			_max_fall_mult = 1.0
		"halaybasi":
			_ghost_active = false
			sprite.position = _base_sprite_pos
			modulate = Color(1.0, 1.0, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
			_recheck_overlaps()


@rpc("any_peer", "call_remote", "unreliable_ordered")
func sync_state(y: float, rot: float, _ability_active: bool) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	if sender_id != get_multiplayer_authority():
		return
	_target_y = y
	_target_rot = rot


## Çarpışma veya sınır dışı durumda yerel oyuncuyu eler.
func die(cause: String) -> void:
	if state == State.DEAD:
		return
	_apply_death_visuals()
	if NetworkManager.is_multiplayer_match and is_local_player:
		NetworkManager.notify_local_death(cause)
	died.emit(cause)


## Uzak oyuncunun elenme animasyonunu ve eşleşen argo balonunu + sesini oynatır.
func play_remote_death() -> void:
	if state == State.DEAD:
		return
	var entry: Dictionary = CharacterData.get_random_death_entry(char_id)
	_apply_death_visuals(str(entry["sound"]))
	speech_bubble.show_text(str(entry["text"]), 2.5)


func _apply_death_visuals(death_sound_path: String = "") -> void:
	state = State.DEAD
	_shield_active = false
	_ghost_active = false
	_ability_remaining = 0.0
	_gravity_ability_mult = 1.0
	sprite.position = _base_sprite_pos
	shield_ring.queue_redraw()
	hitbox.set_deferred("disabled", true)
	velocity_y = minf(velocity_y, -180.0)

	var gray_tween: Tween = create_tween()
	gray_tween.tween_property(self, "modulate", GameConfig.COLOR_DEAD_GRAY, 0.18)

	_spawn_death_crumbs()
	if is_local_player and AudioManager.is_vibration_enabled:
		Input.vibrate_handheld(40)
	if NetworkManager.is_multiplayer_match:
		if not death_sound_path.is_empty():
			AudioManager.play_sfx(death_sound_path, 0.96, 1.05)
		else:
			AudioManager.play_death_sfx(char_id)


func _spawn_death_crumbs() -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.explosiveness = 0.9
	p.amount = 18
	p.lifetime = 0.65
	p.direction = Vector2(0.0, -1.0)
	p.spread = 160.0
	p.gravity = Vector2(0.0, 600.0)
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	p.color = GameConfig.COLOR_BROWN
	add_child(p)
	# Sahne değişirse zamanlayıcı serbest bırakılmış düğümü yakalamasın
	p.finished.connect(p.queue_free)


## Çok oyunculu maç sonunda kazanan/hayatta kalanları senkronize halay dansına başlatır.
func start_halay_dance(slot_index: int, total_winners: int, win_text: String = "") -> void:
	state = State.HALAY
	_shield_active = false
	_ghost_active = false
	_ability_remaining = 0.0
	_halay_time = 0.0
	hitbox.set_deferred("disabled", true)
	modulate = Color.WHITE
	rotation = 0.0
	scale = Vector2.ONE
	shield_ring.queue_redraw()

	var spacing: float = 110.0
	var start_x: float = GameConfig.VIEWPORT_WIDTH * 0.5 - float(maxi(total_winners - 1, 0)) * spacing * 0.5
	_halay_base_pos = Vector2(start_x + float(slot_index) * spacing, 760.0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "position", _halay_base_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var line: String = win_text if not win_text.is_empty() else CharacterData.get_random_win_line(char_id)
	speech_bubble.show_text(line, 3.0)


## Siber pasifi: aktif yetenek bekleme süresi %15 kısa.
func _cooldown_mult() -> float:
	return 0.85 if char_id == "siber" else 1.0


## Dokunulmazlık/hayalet biterken hâlâ bir engelin içindeysen area_entered tekrar gelmez;
## bu yüzden çakışmalar elle yeniden değerlendirilir.
func _recheck_overlaps() -> void:
	if not is_local_player or state != State.ACTIVE:
		return
	for a: Area2D in get_overlapping_areas():
		if not is_instance_valid(a) or not a.monitorable:
			continue
		if a.get_meta("is_spray_cloud", false):
			continue
		_on_area_entered(a)
		if state != State.ACTIVE:
			return


func _on_area_entered(area: Area2D) -> void:
	if not is_local_player or state != State.ACTIVE:
		return
	if area.get_meta("is_spray_cloud", false):
		if sig_vaccine_remaining > 0.0:
			return
		_spray_slow_remaining = GameConfig.SPRAY_SLOW_DURATION
		AudioManager.play_sfx("res://assets/sounds/ilac.ogg", 0.96, 1.05)
		spray_hit.emit()
		return
	if _ghost_active or _post_invuln_remaining > 0.0:
		return
	var pepper_pierce: bool = sig_pepper_remaining > 0.0 and _pepper_pierce_ready
	if _shield_active or (turbo_remaining > 0.0 and _turbo_pierce_ready) or pepper_pierce:
		if not _shield_active:
			if turbo_remaining > 0.0 and _turbo_pierce_ready:
				_turbo_pierce_ready = false
			elif pepper_pierce:
				_pepper_pierce_ready = false
		AudioManager.play_sfx("res://assets/sounds/terlik_kirildi.ogg", 0.95, 1.08)
		var obstacle: Node = area.get_parent()
		if obstacle != null and obstacle.has_method("shatter_part"):
			obstacle.call("shatter_part", area)
		elif area.has_method("shatter"):
			area.call("shatter")
		return
	if has_spare_leg:
		has_spare_leg = false
		_post_invuln_remaining = GameConfig.POWERUP_SPARE_LEG_INVULN
		AudioManager.play_sfx("res://assets/sounds/bacak_koptu.ogg")
		speech_bubble.show_text("Altı tane var zaten.", 1.6)
		_spawn_falling_leg()
		spare_leg_triggered.emit()
		return
	var death_cause: String = str(area.get_meta("death_cause", ""))
	if death_cause.is_empty():
		death_cause = "fuze" if area.collision_layer == GameConfig.LAYER_MISSILE else "ust_engel"
	var ghost_thrower: int = int(area.get_meta("ghost_thrower_id", 0))
	if ghost_thrower > 0 and NetworkManager.is_multiplayer_match:
		NetworkManager.report_ghost_kill.rpc_id(1, ghost_thrower)
	die(death_cause)


## Çok oyunculu sataşma etkisini uygular.
func apply_taunt_effect(item_id: String, sender_name: String) -> void:
	if state != State.ACTIVE:
		return
	if sig_vaccine_remaining > 0.0 and item_id != "ayna":
		speech_bubble.show_text("Aşılıyım, etkilemez!", 1.4)
		return
	last_taunt_sender_name = sender_name
	var dur_mult: float = 0.6 if char_id == "duktur" else 1.0
	match item_id:
		"buz_kalibi":
			_ice_taunt_remaining = 2.5 * dur_mult
			modulate = Color(0.65, 0.88, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
		"turk_kahvesi":
			_coffee_taunt_remaining = 3.0 * dur_mult
			speech_bubble.show_text("Şeker komasına girdin!", 1.8)
			AudioManager.play_sfx("res://assets/sounds/kahve_hupletme.ogg")
		"komsu_teyze":
			_aunt_taunt_remaining = 1.5 * dur_mult
		"ayna":
			speech_bubble.show_text("Ayna kalkanı!", 1.4)
			last_taunt_sender_name = ""


## Turbo Kanat güçlendirmesini etkinleştirir.
func activate_turbo() -> void:
	turbo_remaining = GameConfig.POWERUP_TURBO_DURATION
	_turbo_pierce_ready = true
	speech_bubble.show_text("Bas bas kökle amk kökleeee", 2.0)
	if ResourceLoader.exists("res://assets/sounds/turbo_kokle.ogg"):
		AudioManager.play_sfx("res://assets/sounds/turbo_kokle.ogg")
	else:
		AudioManager.play_sfx("res://assets/sounds/turbo.ogg")


## Yedek Bacak sigortasını etkinleştirir (maçta en fazla 1 kez).
func activate_spare_leg() -> bool:
	if used_spare_leg_in_match:
		return false
	has_spare_leg = true
	used_spare_leg_in_match = true
	speech_bubble.show_text("Altı tane var zaten.", 1.5)
	return true


## Kırıntı Mıknatısı güçlendirmesini etkinleştirir.
func activate_magnet() -> void:
	magnet_remaining = GameConfig.POWERUP_MAGNET_DURATION
	speech_bubble.show_text("Kırıntılar bana gelsin!", 1.5)


## Kum Saati ile karakter yeteneğinin bekleme süresini anında sıfırlar.
func refresh_ability_cooldown() -> void:
	_cooldown_remaining = 0.0
	var total_cd: float = float(char_data.get("cooldown", 10.0))
	ability_cooldown_changed.emit(0.0, total_cd)
	speech_bubble.show_text("Kum saati döndü, yetenek hazır!", 1.5)


## Faz 10.2: Oyuncunun kendisine etki eden imza ödüllerini uygular.
## Dünya etkili olanlar (Davul, İngiliz Anahtarı, Yedek Anahtar, Demlik Çay) GameWorld'dedir.
## Kullanılamıyorsa false döner (ödül tepside kalır).
func activate_signature(item_id: String) -> bool:
	if state != State.ACTIVE:
		return false
	var def: Dictionary = GameConfig.get_item_def(item_id)
	match item_id:
		"bayat_ekmek":
			sig_bread_remaining = GameConfig.SIG_BREAD_DURATION
			var circle: CircleShape2D = hitbox.shape as CircleShape2D
			if circle != null and _base_hitbox_radius > 0.0:
				circle.radius = _base_hitbox_radius * GameConfig.SIG_BREAD_HITBOX_MULT
		"ruj_tazeleme":
			_cooldown_remaining = 0.0
			_next_shield_bonus = GameConfig.SIG_LIPSTICK_SHIELD_BONUS
			_emit_cooldowns()
		"asi":
			sig_vaccine_remaining = GameConfig.SIG_VACCINE_DURATION
			_spray_slow_remaining = 0.0
			_ice_taunt_remaining = 0.0
			_coffee_taunt_remaining = 0.0
			_aunt_taunt_remaining = 0.0
			sprite.position = _base_sprite_pos
			modulate = Color(1.0, 1.0, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
		"filtre_kahve":
			sig_coffee_remaining = GameConfig.SIG_COFFEE_DURATION
		"pil":
			_cooldown_remaining = 0.0
			_cooldown2_remaining = 0.0
			_emit_cooldowns()
		"gece_eristesi", "top":
			force_ability(1)
		"aci_biber":
			sig_pepper_remaining = GameConfig.SIG_PEPPER_DURATION
			_pepper_pierce_ready = true
			modulate = Color(1.0, 0.62, 0.55, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
			_start_pepper_smoke()
		"balon":
			sig_balloon_remaining = GameConfig.SIG_BALLOON_DURATION
			velocity_y = minf(velocity_y, 0.0)
		_:
			return false
	speech_bubble.show_text(str(def.get("quote", "")), 1.6)
	return true


## Bekleme süresine bakmadan verilen yetenek yuvasını bir kez tetikler.
func force_ability(slot: int) -> void:
	if slot == 1:
		if _ability_remaining > 0.0:
			return
		_cooldown_remaining = 0.0
	else:
		if _ability2_remaining > 0.0:
			return
		_cooldown2_remaining = 0.0
	activate_ability_slot(slot)


func _emit_cooldowns() -> void:
	if not is_local_player:
		return
	var sk1: Dictionary = CharacterData.get_skill(char_id, "aktif1")
	var sk2: Dictionary = CharacterData.get_skill(char_id, "aktif2")
	ability_cooldown_changed.emit(_cooldown_remaining, float(sk1.get("cooldown", 10.0)))
	ability2_cooldown_changed.emit(_cooldown2_remaining, float(sk2.get("cooldown", 12.0)))


func _update_signature_timers(delta: float) -> void:
	if sig_bread_remaining > 0.0:
		sig_bread_remaining = maxf(sig_bread_remaining - delta, 0.0)
		if sig_bread_remaining <= 0.0:
			var circle: CircleShape2D = hitbox.shape as CircleShape2D
			if circle != null and _base_hitbox_radius > 0.0:
				circle.radius = _base_hitbox_radius
	if sig_vaccine_remaining > 0.0:
		sig_vaccine_remaining = maxf(sig_vaccine_remaining - delta, 0.0)
	if sig_coffee_remaining > 0.0:
		sig_coffee_remaining = maxf(sig_coffee_remaining - delta, 0.0)
		# Bekleme süreleri normalin 2 katı hızla dolar (normal düşüşe ek olarak)
		var extra: float = delta * (GameConfig.SIG_COFFEE_CD_MULT - 1.0)
		if _cooldown_remaining > 0.0 or _cooldown2_remaining > 0.0:
			_cooldown_remaining = maxf(_cooldown_remaining - extra, 0.0)
			_cooldown2_remaining = maxf(_cooldown2_remaining - extra, 0.0)
			_emit_cooldowns()
		sprite.position = _base_sprite_pos + Vector2(sin(_wing_time * 2.3) * 1.5, 0.0)
		if sig_coffee_remaining <= 0.0:
			sprite.position = _base_sprite_pos
	if sig_pepper_remaining > 0.0:
		sig_pepper_remaining = maxf(sig_pepper_remaining - delta, 0.0)
		if sig_pepper_remaining <= 0.0:
			_pepper_pierce_ready = false
			modulate = Color(1.0, 1.0, 1.0, 1.0 if is_local_player else GameConfig.REMOTE_PLAYER_ALPHA)
			_stop_pepper_smoke()
	if sig_balloon_remaining > 0.0:
		sig_balloon_remaining = maxf(sig_balloon_remaining - delta, 0.0)


func _start_pepper_smoke() -> void:
	_stop_pepper_smoke()
	_pepper_smoke = CPUParticles2D.new()
	_pepper_smoke.position = Vector2(14.0, -40.0)
	_pepper_smoke.amount = 14
	_pepper_smoke.lifetime = 0.7
	_pepper_smoke.direction = Vector2(0.2, -1.0)
	_pepper_smoke.spread = 25.0
	_pepper_smoke.gravity = Vector2(-40.0, -60.0)
	_pepper_smoke.initial_velocity_min = 40.0
	_pepper_smoke.initial_velocity_max = 90.0
	_pepper_smoke.scale_amount_min = 6.0
	_pepper_smoke.scale_amount_max = 12.0
	_pepper_smoke.color = Color(0.85, 0.85, 0.85, 0.55)
	_pepper_smoke.emitting = true
	add_child(_pepper_smoke)


func _stop_pepper_smoke() -> void:
	if _pepper_smoke != null and is_instance_valid(_pepper_smoke):
		_pepper_smoke.queue_free()
	_pepper_smoke = null


func _clear_signature_effects() -> void:
	sig_bread_remaining = 0.0
	sig_vaccine_remaining = 0.0
	sig_coffee_remaining = 0.0
	sig_pepper_remaining = 0.0
	sig_balloon_remaining = 0.0
	_pepper_pierce_ready = false
	_next_shield_bonus = 0.0
	_stop_pepper_smoke()
	var circle: CircleShape2D = hitbox.shape as CircleShape2D if hitbox != null else null
	if circle != null and _base_hitbox_radius > 0.0:
		circle.radius = _base_hitbox_radius


## Yakın kaçış kombo unvanını böceğin yanında kısa süreli gösterir.
func show_combo_title(title: String) -> void:
	if title.is_empty():
		return
	if _combo_label != null and is_instance_valid(_combo_label):
		_combo_label.queue_free()
	_combo_label = Label.new()
	_combo_label.text = title
	_combo_label.position = Vector2(38.0, -54.0)
	_combo_label.add_theme_font_override("font", AssetHelper.get_ui_font())
	_combo_label.add_theme_font_size_override("font_size", 22)
	_combo_label.add_theme_color_override("font_color", Color("#FFF3B0"))
	_combo_label.add_theme_color_override("font_outline_color", GameConfig.COLOR_DARK_TEXT)
	_combo_label.add_theme_constant_override("outline_size", 5)
	add_child(_combo_label)
	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(_combo_label, "position:y", -90.0, 1.1)
	tw.tween_property(_combo_label, "modulate:a", 0.0, 1.1)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(_combo_label):
			_combo_label.queue_free()
	)


func _spawn_falling_leg() -> void:
	var leg: Node2D = Node2D.new()
	leg.position = position
	var leg_tex_path: String = "res://assets/sprites/bacak.png"
	if ResourceLoader.exists(leg_tex_path):
		var sp: Sprite2D = Sprite2D.new()
		sp.texture = load(leg_tex_path) as Texture2D
		leg.add_child(sp)
	else:
		var rect: ColorRect = ColorRect.new()
		rect.color = GameConfig.COLOR_BROWN
		rect.size = Vector2(28.0, 8.0)
		rect.position = Vector2(-14.0, -4.0)
		leg.add_child(rect)
	get_parent().add_child(leg)
	var tw: Tween = leg.create_tween().set_parallel(true)
	tw.tween_property(leg, "position", leg.position + Vector2(-80.0, 260.0), 0.75)
	tw.tween_property(leg, "rotation", TAU * 1.5, 0.75)
	tw.tween_property(leg, "modulate:a", 0.0, 0.75)
	tw.chain().tween_callback(func() -> void:
		if is_instance_valid(leg):
			leg.queue_free()
	)


func _on_shield_draw() -> void:
	if not _shield_active:
		return
	var pulse: float = 1.0 + sin(_pulse_time * 9.0) * 0.08
	var radius: float = 72.0 * pulse
	var fill_col: Color = GameConfig.COLOR_DUST_PINK
	fill_col.a = 0.32
	var rim_col: Color = GameConfig.COLOR_DUST_PINK.lightened(0.2)
	rim_col.a = 0.85
	shield_ring.draw_circle(Vector2.ZERO, radius, fill_col)
	shield_ring.draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, rim_col, 4.0, true)


func _on_back_aura_draw() -> void:
	back_aura.draw_circle(Vector2.ZERO, 88.0, Color(1.0, 0.96, 0.84, 0.22))
	back_aura.draw_circle(Vector2.ZERO, 62.0, Color(1.0, 0.98, 0.90, 0.42))
	back_aura.draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 44, Color(1.0, 0.94, 0.72, 0.55), 2.5, true)


func _on_wing_draw() -> void:
	var flap_ang: float = sin(_wing_time) * 0.48
	var wing_col: Color = Color(0.95, 0.92, 0.86, 0.65)
	var rim_col: Color = Color(0.35, 0.28, 0.24, 0.55)
	for side: float in [-1.0, 1.0]:
		var tip: Vector2 = Vector2(-46.0, -14.0 + side * (22.0 + flap_ang * 26.0))
		var mid: Vector2 = Vector2(-26.0, -24.0 + side * (16.0 + flap_ang * 14.0))
		var root_pt: Vector2 = Vector2(-6.0, -6.0)
		var pts: PackedVector2Array = PackedVector2Array([root_pt, mid, tip, Vector2(-22.0, 6.0)])
		wing_overlay.draw_colored_polygon(pts, wing_col)
		wing_overlay.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), rim_col, 2.0)


func _on_limb_draw() -> void:
	if state == State.DEAD:
		return
	var leg_col: Color = Color(0.28, 0.16, 0.10, 0.95)
	var ant_col: Color = Color(0.32, 0.18, 0.11, 0.95)
	var kick_speed: float = 1.25 if (_wing_boost > 0.05 or turbo_remaining > 0.0) else 0.72
	var fall_drag: float = clampf(velocity_y / 700.0, -0.7, 0.9)

	# 6 eklemli bacak (uçuşta/kaçışta sırayla çırpınır)
	var leg_bases: Array[Vector2] = [
		Vector2(-24.0, 20.0),
		Vector2(-4.0, 24.0),
		Vector2(18.0, 20.0),
		Vector2(-20.0, 14.0),
		Vector2(2.0, 18.0),
		Vector2(22.0, 14.0),
	]
	for i: int in range(leg_bases.size()):
		var root: Vector2 = leg_bases[i]
		var phase: float = _wing_time * kick_speed + float(i) * 1.35
		var swing: float = sin(phase) * (13.0 if _wing_boost > 0.05 else 8.0)
		var tuck: float = cos(phase) * 7.0 - fall_drag * 9.0
		var knee: Vector2 = root + Vector2(-8.0 + swing * 0.45, 16.0 + tuck * 0.4)
		var foot: Vector2 = knee + Vector2(-12.0 + swing, 14.0 + tuck)
		_limb_overlay.draw_line(root, knee, leg_col, 4.5, true)
		_limb_overlay.draw_line(knee, foot, leg_col, 3.2, true)
		_limb_overlay.draw_circle(knee, 2.4, leg_col)

	# 2 esnek anten (hıza ve zıplamaya göre arkaya kıvrılır)
	for side_idx: int in range(2):
		var y_off: float = -22.0 if side_idx == 0 else -15.0
		var ant_root: Vector2 = Vector2(26.0, y_off)
		var wave: float = sin(_wing_time * 0.55 + float(side_idx) * 1.4) * 8.0
		var mid: Vector2 = ant_root + Vector2(22.0, -18.0 - fall_drag * 12.0 + wave * 0.4)
		var tip: Vector2 = mid + Vector2(20.0 - absf(fall_drag) * 8.0, -12.0 - fall_drag * 18.0 + wave)
		_limb_overlay.draw_line(ant_root, mid, ant_col, 3.2, true)
		_limb_overlay.draw_line(mid, tip, ant_col, 2.0, true)

extends Area2D

## Çapraz füze engeli: zamana bağlı konum, radyal ışık ve parçalanma animasyonu.

var start_pos: Vector2 = Vector2.ZERO
var dir: Vector2 = Vector2(-0.7, 0.7)
var launch_time: float = 0.0
var is_shattered: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D
@onready var light: PointLight2D = $PointLight2D


func _ready() -> void:
	collision_layer = GameConfig.LAYER_MISSILE
	collision_mask = 0
	monitoring = false
	monitorable = true

	sprite.texture = AssetHelper.texture(
		GameConfig.MISSILE_TEX_PATH,
		"fuze",
		GameConfig.MISSILE_SIZE
	)

	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 14.0
	capsule.height = 68.0
	hitbox.shape = capsule
	hitbox.rotation = PI * 0.5

	light.texture = _create_radial_light_texture(128, Color(1.0, 0.62, 0.24, 1.0))
	light.energy = 1.6
	light.texture_scale = 2.4


## Füzenin başlangıç noktası, yönü ve fırlatma zamanını ayarlar.
func setup(p_start: Vector2, p_dir: Vector2, p_launch_time: float) -> void:
	start_pos = p_start
	dir = p_dir.normalized()
	launch_time = p_launch_time
	position = start_pos
	rotation = dir.angle()


## Füze konumunu maç süresine göre deterministik olarak günceller.
func update_at_time(match_time: float) -> void:
	if is_shattered:
		return
	var elapsed: float = maxf(match_time - launch_time, 0.0)
	position = start_pos + dir * GameConfig.MISSILE_SPEED * elapsed


## Diva kalkanı çarptığında füzeyi 0.3 sn içinde parçalar.
func shatter() -> void:
	if is_shattered:
		return
	is_shattered = true
	hitbox.set_deferred("disabled", true)
	set_deferred("monitorable", false)

	var tw: Tween = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(0.1, 0.1), GameConfig.SHATTER_DURATION)
	tw.tween_property(self, "rotation", rotation + PI * 1.8, GameConfig.SHATTER_DURATION)
	tw.tween_property(self, "modulate:a", 0.0, GameConfig.SHATTER_DURATION)
	tw.chain().tween_callback(queue_free)


func _create_radial_light_texture(tex_size: int, center_col: Color) -> GradientTexture2D:
	var grad: Gradient = Gradient.new()
	grad.set_color(0, center_col)
	grad.set_color(1, Color(center_col.r, center_col.g, center_col.b, 0.0))

	var gtex: GradientTexture2D = GradientTexture2D.new()
	gtex.width = tex_size
	gtex.height = tex_size
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.gradient = grad
	return gtex

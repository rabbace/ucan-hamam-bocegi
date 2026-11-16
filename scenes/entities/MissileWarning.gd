extends Node2D

## Füze fırlatılmadan önce rotayı ve ekran giriş noktasını gösteren uyarı.

var launch_time: float = 0.0
var _blink_time: float = 0.0
var _badge_pos: Vector2 = Vector2(680.0, 40.0)

@onready var line: Line2D = $Line2D
@onready var badge: Node2D = $Badge
@onready var bang_label: Label = $Badge/BangLabel


func _ready() -> void:
	line.width = 6.0
	line.default_color = GameConfig.COLOR_WARN_RED

	var font: Font = AssetHelper.get_ui_font()
	bang_label.add_theme_font_override("font", font)
	bang_label.add_theme_font_size_override("font_size", 28)
	bang_label.add_theme_color_override("font_color", Color.WHITE)
	badge.draw.connect(_on_badge_draw)


## Uyarı çizgisini ve kenar "!" ikonunu rotaya göre kurar.
func setup(start_pos: Vector2, dir: Vector2, p_launch_time: float) -> void:
	launch_time = p_launch_time
	var n_dir: Vector2 = dir.normalized()
	line.clear_points()
	line.add_point(start_pos)
	line.add_point(start_pos + n_dir * 2400.0)

	_badge_pos = _compute_entry_point(start_pos, n_dir)
	badge.position = _badge_pos
	badge.queue_redraw()


func _process(delta: float) -> void:
	_blink_time += delta
	var alpha: float = lerpf(0.25, 0.8, (sin(_blink_time * 22.0) + 1.0) * 0.5)
	line.modulate.a = alpha
	badge.modulate.a = clampf(alpha + 0.2, 0.4, 1.0)


func _compute_entry_point(start_pos: Vector2, n_dir: Vector2) -> Vector2:
	var t_y: float = 0.0
	if absf(n_dir.y) > 0.001:
		t_y = maxf((0.0 - start_pos.y) / n_dir.y, 0.0)
	var t_x: float = 0.0
	if start_pos.x > GameConfig.VIEWPORT_WIDTH and n_dir.x < -0.001:
		t_x = (GameConfig.VIEWPORT_WIDTH - start_pos.x) / n_dir.x
	var t_enter: float = maxf(t_x, t_y)
	var p: Vector2 = start_pos + n_dir * t_enter
	p.x = clampf(p.x, 32.0, GameConfig.VIEWPORT_WIDTH - 32.0)
	p.y = clampf(p.y, 32.0, GameConfig.VIEWPORT_HEIGHT - 32.0)
	return p


func _on_badge_draw() -> void:
	badge.draw_circle(Vector2.ZERO, 22.0, GameConfig.COLOR_WARN_RED)
	badge.draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color.WHITE, 3.0, true)

extends Node

## 8.9: Başlatma yöneticisi — komut satırından sunucu veya normal oyun modunu seçer.


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--matchmaker"):
		call_deferred("_switch_to", "res://server/Matchmaker.tscn")
	elif args.has("--room"):
		call_deferred("_switch_to", "res://server/RoomServer.tscn")
	elif DisplayServer.get_name() != "headless":
		# Faz 13B: her butona basma hissi (ölçek + tık + titreşim)
		get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		UiFeel.attach(node as BaseButton)


func _switch_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


## Masaüstünde (Steam) F11 veya Alt+Enter ile tam ekran / pencere geçişi.
func _input(event: InputEvent) -> void:
	if not OS.has_feature("pc") or DisplayServer.get_name() == "headless":
		return
	if not (event is InputEventKey):
		return
	var key_ev: InputEventKey = event as InputEventKey
	if not key_ev.pressed or key_ev.echo:
		return
	var is_toggle: bool = key_ev.keycode == KEY_F11 or (key_ev.keycode == KEY_ENTER and key_ev.alt_pressed)
	if not is_toggle:
		return
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	get_viewport().set_input_as_handled()

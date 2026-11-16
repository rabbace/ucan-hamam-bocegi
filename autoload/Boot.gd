extends Node

## 8.9: Başlatma yöneticisi — komut satırından sunucu veya normal oyun modunu seçer.


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--matchmaker"):
		call_deferred("_switch_to", "res://server/Matchmaker.tscn")
	elif args.has("--room"):
		call_deferred("_switch_to", "res://server/RoomServer.tscn")


func _switch_to(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)

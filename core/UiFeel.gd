class_name UiFeel
extends RefCounted

## Faz 13B: tüm butonlarda basma hissi. Basınca 0.95 ölçek + tık sesi + kısa titreşim,
## bırakınca küçük yay ile 1.0'a döner. Boot, sahneye eklenen her BaseButton'a bağlar.
## Hariç tutmak için butona "no_press_feel" meta'sı verilir.

const META_DONE: String = "_press_feel"
const META_SKIP: String = "no_press_feel"


static func attach(btn: BaseButton) -> void:
	if btn == null or btn.has_meta(META_DONE) or btn.has_meta(META_SKIP):
		return
	btn.set_meta(META_DONE, true)
	btn.button_down.connect(_on_down.bind(btn))
	btn.button_up.connect(_on_up.bind(btn))


static func _on_down(btn: BaseButton) -> void:
	if not is_instance_valid(btn) or btn.disabled or btn.has_meta(META_SKIP):
		return
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(btn, "scale", Vector2(GameConfig.UI_PRESS_SCALE, GameConfig.UI_PRESS_SCALE), GameConfig.UI_PRESS_IN_SEC)
	var am: Node = btn.get_node_or_null("/root/AudioManager")
	if am != null:
		am.call("play_ui_tick")


static func _on_up(btn: BaseButton) -> void:
	if not is_instance_valid(btn) or not btn.is_inside_tree():
		return
	btn.pivot_offset = btn.size * 0.5
	var tw: Tween = btn.create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(btn, "scale", Vector2.ONE, GameConfig.UI_RELEASE_SEC).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

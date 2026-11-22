@tool
extends EditorPlugin

## Play, screenOrientation="portrait" ve Wi-Fi izinlerinden bu özellikleri zorunlu sayıyor;
## tabletler / masaüstü / Wi-Fi'siz cihazlar oyunu yükleyemiyordu. Açıkça isteğe bağlı beyan edilir.

var _export_plugin: AndroidFeatureExport = null


func _enter_tree() -> void:
	_export_plugin = AndroidFeatureExport.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
	_export_plugin = null


class AndroidFeatureExport extends EditorExportPlugin:
	func _get_name() -> String:
		return "AndroidOzellikBeyani"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_element_contents(_platform: EditorExportPlatform, _debug: bool) -> String:
		return "\n    <uses-feature android:name=\"android.hardware.screen.portrait\" android:required=\"false\" />\n    <uses-feature android:name=\"android.hardware.wifi\" android:required=\"false\" />\n"

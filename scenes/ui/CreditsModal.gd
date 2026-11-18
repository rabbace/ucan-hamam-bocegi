class_name CreditsModal
extends RefCounted

## Faz 13B: "Emeği Geçenler" penceresi — yazı tipi, ikon ve motor lisansları, Türkçe harf testi.

const TURKISH_TEST: String = "ĞÜŞİÖÇ ğüşıöç"
const FONT_LICENSE_PATH: String = "res://assets/fonts/Baloo2_OFL.txt"
const EMOJI_LICENSE_PATH: String = "res://assets/sprites/items/LICENSE_NOTO_EMOJI.txt"

## Her satır: [başlık, açıklama, lisans dosyası (boş olabilir)]
const ENTRIES: Array[Array] = [
	["Oyun", "Uçan Hamam Böceği. Mahallenin bütün terlikleri ve böcekleri bu mutfakta büyüdü.", ""],
	["Yazı tipi: Baloo 2", "Ek Type ve Baloo 2 Projesi yazarları. SIL Open Font License 1.1 ile kullanılıyor.", FONT_LICENSE_PATH],
	["Eşya ikonları: Noto Emoji", "Google LLC. SIL Open Font License 1.1 ile kullanılıyor.", EMOJI_LICENSE_PATH],
	["Oyun motoru: Godot Engine", "Juan Linietsky, Ariel Manzur ve Godot katkıcıları. MIT Lisansı.", ""],
]


static func open(parent: Node) -> Control:
	var m: Dictionary = ComicUiHelper.build_modal(parent, "EMEĞİ GEÇENLER", GameConfig.COLOR_CREAM, 0.0, true)
	var root: Control = m["root"] as Control
	root.name = "ModalCredits"
	var body: VBoxContainer = m["body"] as VBoxContainer

	for e: Array in ENTRIES:
		var card: PanelContainer = PanelContainer.new()
		card.theme_type_variation = &"KartPanel"
		body.add_child(card)
		var v: VBoxContainer = VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		card.add_child(v)
		var t: Label = Label.new()
		t.text = str(e[0])
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(t, GameConfig.FS_BODY, GameConfig.COLOR_INK, true)
		v.add_child(t)
		var d: Label = Label.new()
		d.text = str(e[1])
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ComicUiHelper.style_label(d, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
		v.add_child(d)
		var lic_path: String = str(e[2])
		if not lic_path.is_empty() and FileAccess.file_exists(lic_path):
			var lic_btn: Button = Button.new()
			lic_btn.text = "Lisans metnini göster"
			lic_btn.custom_minimum_size = Vector2(0.0, 52.0)
			ComicUiHelper.style_bitten_button(lic_btn, GameConfig.COLOR_SAGE, AssetHelper.get_ui_font(), GameConfig.FS_SMALL)
			v.add_child(lic_btn)
			var lic_lbl: Label = Label.new()
			lic_lbl.visible = false
			lic_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ComicUiHelper.style_label(lic_lbl, GameConfig.FS_TINY, GameConfig.COLOR_DARK_TEXT, false)
			v.add_child(lic_lbl)
			lic_btn.pressed.connect(func() -> void:
				if lic_lbl.text.is_empty():
					lic_lbl.text = FileAccess.get_file_as_string(lic_path).strip_edges()
				lic_lbl.visible = not lic_lbl.visible
				lic_btn.text = "Lisans metnini gizle" if lic_lbl.visible else "Lisans metnini göster"
			)

	# Türkçe harf testi: yazı tipi bütün harfleri çiziyor mu?
	var test_title: Label = Label.new()
	test_title.text = "Harf testi"
	ComicUiHelper.style_label(test_title, GameConfig.FS_SMALL, GameConfig.COLOR_BROWN, false)
	body.add_child(test_title)
	var test: Label = Label.new()
	test.name = "TurkishTest"
	test.text = TURKISH_TEST
	test.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ComicUiHelper.style_label(test, GameConfig.FS_H1, GameConfig.COLOR_INK, true)
	body.add_child(test)

	var close_btn: Button = Button.new()
	close_btn.text = "Kapat"
	close_btn.custom_minimum_size = Vector2(0.0, 64.0)
	ComicUiHelper.style_bitten_button(close_btn, GameConfig.COLOR_PEACH, AssetHelper.get_ui_font(), GameConfig.FS_BUTTON)
	close_btn.pressed.connect(func() -> void: ComicUiHelper.close_modal(root))
	(m["footer"] as VBoxContainer).add_child(close_btn)
	return root


## Yazı tipinde verilen metnin tüm harfleri var mı? (CI ve harf testi için)
static func font_has_all(font: Font, text: String) -> bool:
	if font == null:
		return false
	for ch: String in text:
		if ch == " ":
			continue
		if not font.has_char(ch.unicode_at(0)):
			return false
	return true

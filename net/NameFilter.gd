extends RefCounted

## Oyuncu/oda adı temizleyici: yalnızca harf/rakam/boşluk (Türkçe harfler dahil),
## Türkçe küçültme (İ→i, I→ı) ve kelime sınırıyla argo süzgeci.

# İsimde izin verilen Türkçe harfler (ASCII harf/rakam ayrıca kabul edilir)
const EXTRA_CHARS: String = "çÇğĞıİöÖşŞüÜ"
const DEFAULT_NAME: String = "Böcek"


## Ham adı temizler; boş kalırsa veya yasaklı kelime içerirse varsayılan adı döner.
static func sanitize(raw_name: String) -> String:
	var filtered: String = ""
	var last_space: bool = true
	for i: int in range(mini(raw_name.length(), GameConfig.MAX_NAME_LENGTH * 4)):
		var ch: String = raw_name[i]
		if is_name_char(ch):
			filtered += ch
			last_space = false
		elif ch == " " or ch == "\t":
			if not last_space:
				filtered += " "
				last_space = true
	var clean: String = filtered.strip_edges().substr(0, GameConfig.MAX_NAME_LENGTH).strip_edges()
	if clean.is_empty():
		return DEFAULT_NAME
	for word: String in turkish_lower(clean).split(" ", false):
		var letters_only: String = ""
		for j: int in range(word.length()):
			if not word[j].is_valid_int():
				letters_only += word[j]
		for bad: String in GameConfig.BANNED_NAME_WORDS:
			if word == bad or letters_only == bad:
				return DEFAULT_NAME
	return clean


## Karakter ASCII harf/rakam ya da Türkçe harf mi (kontrol ve sıfır genişlikli karakterler elenir).
static func is_name_char(ch: String) -> bool:
	if ch.length() != 1:
		return false
	var code: int = ch.unicode_at(0)
	if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122):
		return true
	return EXTRA_CHARS.contains(ch)


## Türkçe büyük/küçük harf eşlemesiyle küçültür.
static func turkish_lower(text: String) -> String:
	return text.replace("İ", "i").replace("I", "ı").to_lower()

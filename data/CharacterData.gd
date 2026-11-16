class_name CharacterData
extends RefCounted

## Karakter tanımları, yetenek parametreleri ve replik havuzları.

const ORDER: Array[String] = ["klasik", "diva", "duktur", "halaybasi"]
const ALL_ORDER: Array[String] = ["klasik", "diva", "duktur", "halaybasi", "plaza", "usta", "emlakci", "siber", "yurt", "dayi", "taraftar", "saftirik", "deli"]

const CHARACTERS: Dictionary = {
	"klasik": {
		"id": "klasik",
		"display_name": "Klasik Böcek",
		"sprite_path": "res://assets/sprites/char_klasik.png",
		"front_path": "res://assets/sprites/char_klasik_front.png",
		"angry_path": "res://assets/sprites/char_klasik_angry.png",
		"fallback_kind": "char_klasik",
		"tagline": "Mutfağın eskisi",
		"passive_text": "Pasif: Çevik Kanatlar (Hitbox %20 küçük)",
		"ability_name": "Ani Fren",
		"ability_text": "Düşüşü durdurur, 0.5 sn havada asılı kalır.",
		"cooldown": 8.0,
		"duration": 0.5,
		"hitbox_scale": 0.8,
		"gravity_mult": 0.95,
		"flap_mult": 1.05,
		"ability_line": "Kaç kaç kaç!",
		"taunt_line": "Ben bu mutfağın eskisiyim.",
		"voice_pitch": 1.15,
		"tap_lines": ["Efendim?", "Ben buranın eskisiyim.", "Işığı kapat, utanıyorum."],
		"poke_line": "Dürtme beni!",
		"flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "cevik_kanatlar", "name": "Çevik Kanatlar", "type_label": "PASİF", "desc": "Hitbox %20 küçük, kanat çırpması biraz daha keskin.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "ani_fren", "name": "Ani Fren", "type_label": "AKTİF", "desc": "Düşüşü anında durdurur, 0.5 sn havada asılı kalır.", "cooldown": 8.0, "duration": 0.5, "line": "Kaç kaç kaç!"},
			{"slot": "aktif2", "id": "kanat_toplama", "name": "Kanat Toplama", "type_label": "KÜÇÜLME", "desc": "Hafif (%70 boyut) ama sık kullanılabilen küçülme.", "cooldown": 10.0, "duration": 2.0, "scale": 0.7, "gravity_mult": 1.0, "line": "Kendimi topluyorum."},
		],
		"death_lines": [
			"Kaybettin lan g.t!!!",
			"Ulan @#% yine mi terlik?!",
			"Böcek gibi ezildin lan!",
			"Ah be #@%& gitti maç!",
			"Gahpe oğlu gahpe!",
			"Aaaa duktur yok mu duktur!",
		],
		"win_lines": ["Kim tutar beni!", "Mutfağın kralı benim!", "Makara abi bunlar!", "Makarayız abiiii!"],
	},
	"diva": {
		"id": "diva",
		"display_name": "Diva Böcek",
		"sprite_path": "res://assets/sprites/char_diva.png",
		"front_path": "res://assets/sprites/char_diva_front.png",
		"angry_path": "res://assets/sprites/char_diva_angry.png",
		"fallback_kind": "char_diva",
		"tagline": "Gözlüklü, süslü, alıngan",
		"passive_text": "Pasif: Işıltı (Karanlıkta %50 geniş ışık)",
		"ability_name": "Ayy Terlik Geliyor!",
		"ability_text": "2.5 sn pembe kalkan; çarptığı engeli parçalar.",
		"cooldown": 12.0,
		"duration": 2.5,
		"hitbox_scale": 1.0,
		"gravity_mult": 1.0,
		"flap_mult": 1.0,
		"ability_line": "Ayy terlik geliyor!",
		"taunt_line": "Ayy ne bakıyorsun?",
		"voice_pitch": 1.30,
		"tap_lines": ["Ayy dokunma, ojem yeni!", "Fotoğrafım çekilecekse önce haber verin.", "Bu mutfak bana küçük."],
		"poke_line": "Dürtme beni ayol!",
		"flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "isilti", "name": "Işıltı", "type_label": "PASİF", "desc": "Füze evresinde ışığı %50 geniş; uyarı çizgilerini 0.2 sn erken görür.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "pembe_kalkan", "name": "Ayy Terlik Geliyor!", "type_label": "AKTİF", "desc": "2.5 sn pembe kalkan; çarptığı terlik, füze ve engeli parçalar.", "cooldown": 12.0, "duration": 2.5, "line": "Ayy terlik geliyor!"},
			{"slot": "aktif2", "id": "kucuk_hissettim", "name": "Kendimi Küçük Hissettim", "type_label": "KÜÇÜLME", "desc": "%60 boyuta küçülür, küçükken düşüş hızı %20 yavaşlar.", "cooldown": 14.0, "duration": 2.5, "scale": 0.6, "gravity_mult": 0.8, "line": "Kimse beni anlamıyor…"},
		],
		"death_lines": [
			"Kaybettin lan g.t!!!",
			"Gözlüğüm kırıldı @#%!",
			"Bu ne biçim terlik be ★★★!",
			"Makyajım aktı lan!",
			"Gahpe oğlu gahpe!",
			"Aaaa duktur yok mu duktur!",
		],
		"win_lines": ["Terlik mi? Hı hı, kesin!", "Sahne benim canım!", "Makara abi bunlar!", "Makarayız abiiii!"],
	},
	"duktur": {
		"id": "duktur",
		"display_name": "Duktur Böcek",
		"sprite_path": "res://assets/sprites/char_duktur.png",
		"front_path": "res://assets/sprites/char_duktur_front.png",
		"angry_path": "res://assets/sprites/char_duktur_angry.png",
		"fallback_kind": "char_duktur",
		"tagline": "Önlüklü, reçeteli",
		"passive_text": "Pasif: Bağışıklık Sistemi (Sataşmalar %40 kısa)",
		"ability_name": "Serum Takviyesi",
		"ability_text": "4 sn boyunca kontrollü süzülme (yerçekimi ×0.55).",
		"cooldown": 12.0,
		"duration": 4.0,
		"hitbox_scale": 1.0,
		"gravity_mult": 1.0,
		"flap_mult": 1.0,
		"ability_line": "Serumu taktım, rahatım.",
		"taunt_line": "Reçeteni yazdım bile.",
		"voice_pitch": 1.05,
		"tap_lines": ["Ağzını aç, aaa de.", "Bu kırıntı çok yağlı.", "Randevun var mıydı?"],
		"poke_line": "Dürtme hastayım!",
		"flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "bagisiklik", "name": "Bağışıklık Sistemi", "type_label": "PASİF", "desc": "Rakiplerden gelen sataşmaların süresi %40 kısa sürer.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "serum", "name": "Serum Takviyesi", "type_label": "AKTİF", "desc": "4 sn boyunca yerçekimi ×0.55 ve maksimum düşüş hızı ×0.6.", "cooldown": 12.0, "duration": 4.0, "line": "Serumu taktım, rahatım."},
			{"slot": "aktif2", "id": "duktur_mudahalesi", "name": "Duktur Müdahalesi", "type_label": "KÜÇÜLME", "desc": "%50 boyuta (en güçlü küçülme) iner, yerçekimi ×0.7.", "cooldown": 12.0, "duration": 3.0, "scale": 0.5, "gravity_mult": 0.7, "line": "Duktur müdahalesi!"},
		],
		"death_lines": [
			"Kaybettin lan g.t!!!",
			"Reçeteyi yanlış yazdık @#%!",
			"Yandık anam, müdahale yetmedi!",
			"Bu nasıl refleks lan?!",
			"Gahpe oğlu gahpe!",
			"Aaaa duktur yok mu duktur!",
		],
		"win_lines": ["Tıbben kanıtlandı!", "Hepinizi yedim lan!", "Makara abi bunlar!", "Makarayız abiiii!"],
	},
	"halaybasi": {
		"id": "halaybasi",
		"display_name": "Halay Başı Böcek",
		"sprite_path": "res://assets/sprites/char_halaybasi.png",
		"front_path": "res://assets/sprites/char_halaybasi_front.png",
		"angry_path": "res://assets/sprites/char_halaybasi_angry.png",
		"fallback_kind": "char_halaybasi",
		"tagline": "Mendil elde, omuz omuza",
		"passive_text": "Pasif: Davul Zurna (5 Yakın Kaçışta -2 sn CD)",
		"ability_name": "Mendil Sallama",
		"ability_text": "2 sn hayalet fazı; engellerden geçer + konfeti.",
		"cooldown": 14.0,
		"duration": 2.0,
		"hitbox_scale": 1.0,
		"gravity_mult": 1.0,
		"flap_mult": 1.0,
		"ability_line": "Hadi bakalım halaya!",
		"taunt_line": "Halaya gel, halaya!",
		"voice_pitch": 1.10,
		"tap_lines": ["Hadi kalk, halaya!", "Mendil nerde mendil?", "Davulcu nerde kaldı?"],
		"poke_line": "Dürtme, sırayı bozma!",
		"flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "davul_zurna", "name": "Davul Zurna", "type_label": "PASİF", "desc": "Her 5 Yakın Kaçışta iki aktif yeteneğinin beklemesi 2 sn kısalır.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "mendil_sallama", "name": "Mendil Sallama", "type_label": "AKTİF", "desc": "2 sn hayalet fazı; rakiplerin ekran kenarlarında konfeti uçar.", "cooldown": 14.0, "duration": 2.0, "line": "Hadi bakalım halaya!"},
			{"slot": "aktif2", "id": "omuz_omuza", "name": "Omuz Omuza", "type_label": "KÜÇÜLME", "desc": "%65 boyuta küçülür, halay adımıyla sağa sola sallanır.", "cooldown": 13.0, "duration": 2.5, "scale": 0.65, "gravity_mult": 1.0, "line": "Sıkışın biraz, sıkışın!"},
		],
		"death_lines": [
			"Kaybettin lan g.t!!!",
			"Mendil düştü @#%!",
			"Annem bunu duymasın… kaybettin!",
			"Halay bozuldu lan!",
			"Gahpe oğlu gahpe!",
			"Aaaa duktur yok mu duktur!",
		],
		"win_lines": ["Çek halayı!", "Kim tutar beni!", "Makara abi bunlar!", "Makarayız abiiii!"],
	},
	"plaza": {
		"id": "plaza", "display_name": "Plaza Böceği", "price": 2500, "tagline": "Gömlek, kravat, yaka kartı",
		"sprite_path": "res://assets/sprites/char_plaza.png", "front_path": "res://assets/sprites/char_plaza.png", "angry_path": "res://assets/sprites/char_klasik_angry.png", "fallback_kind": "char_klasik",
		"passive_text": "Pasif: Excel Gözü (Mıknatıs menzili +%30)", "ability_name": "Hücreyi Genişlet", "ability_text": "Önündeki ilk engelin aralığını %30 açar.",
		"cooldown": 14.0, "duration": 1.0, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Bunu Excel'e sığdırırız.", "taunt_line": "Toplantıya yetişmem lazım.",
		"voice_pitch": 1.12, "tap_lines": ["Toplantıdayım, sonra dönerim.", "Bunu mail atar mısın?", "Cuma'ya yetiştiririz."], "poke_line": "Mesai saatindeyim!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "excel_gozu", "name": "Excel Gözü", "type_label": "PASİF", "desc": "Güçlendirmeleri daha uzaktan çeker (Mıknatıs +%30).", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "hucre_genislet", "name": "Hücreyi Genişlet", "type_label": "AKTİF", "desc": "Önündeki ilk engel çiftinin aralığını yerelde %30 genişletir.", "cooldown": 14.0, "duration": 1.0, "line": "Bunu Excel'e sığdırırız."},
			{"slot": "aktif2", "id": "kompakt_mod", "name": "Kompakt Mod", "type_label": "KÜÇÜLME", "desc": "%65 boyuta küçülür.", "cooldown": 12.0, "duration": 2.5, "scale": 0.65, "gravity_mult": 1.0, "line": "Toplantıya sığarım."},
		],
		"death_lines": ["Deadline kaçtı!", "Gahpe oğlu gahpe!"], "win_lines": ["Sunum harikaydı!", "Makara abi bunlar!"],
	},
	"usta": {
		"id": "usta", "display_name": "Sanayi Ustası", "price": 2500, "tagline": "Baret, yelek, usta eli",
		"sprite_path": "res://assets/sprites/char_isci.png", "front_path": "res://assets/sprites/char_isci.png", "angry_path": "res://assets/sprites/char_duktur_angry.png", "fallback_kind": "char_duktur",
		"passive_text": "Pasif: Usta Eli (2 Yedek Bacak taşır)", "ability_name": "Motor İnecek", "ability_text": "Önündeki ilk engeli anahtarla söker.",
		"cooldown": 14.0, "duration": 1.0, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Abi motor inecek.", "taunt_line": "Bu orijinal parça değil.",
		"voice_pitch": 1.02, "tap_lines": ["Abi motor inecek.", "Bir kahve koy, bakarız.", "Bu orijinal parça değil."], "poke_line": "Çırak mısın sen?", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "usta_eli", "name": "Usta Eli", "type_label": "PASİF", "desc": "Yedek Bacak sigortasından 2 tane taşıyabilir.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "motor_inecek", "name": "Motor İnecek", "type_label": "AKTİF", "desc": "Önündeki ilk engeli İngiliz anahtarıyla söker.", "cooldown": 14.0, "duration": 1.0, "line": "Abi motor inecek."},
			{"slot": "aktif2", "id": "kaporta_alti", "name": "Kaportanın Altı", "type_label": "KÜÇÜLME", "desc": "%60 boyuta küçülür.", "cooldown": 13.0, "duration": 2.5, "scale": 0.6, "gravity_mult": 1.0, "line": "Altına bi bakayım."},
		],
		"death_lines": ["Conta yaktık!", "Aaaa duktur yok mu duktur!"], "win_lines": ["Sıfır hata!", "Makarayız abiiii!"],
	},
	"emlakci": {
		"id": "emlakci", "display_name": "Emlakçı Böcek", "price": 3000, "tagline": "Takım elbise, anahtar demeti",
		"sprite_path": "res://assets/sprites/char_emlakci.png", "front_path": "res://assets/sprites/char_emlakci.png", "angry_path": "res://assets/sprites/char_klasik_angry.png", "fallback_kind": "char_klasik",
		"passive_text": "Pasif: Komisyon (+%20 Kırıntı)", "ability_name": "Daireyi Gezdir", "ability_text": "En yakın aralığın ortasına ışınlanır.",
		"cooldown": 16.0, "duration": 0.3, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Bakın burası güney cephe.", "taunt_line": "Depozito iki kira.",
		"voice_pitch": 1.15, "tap_lines": ["Depozito iki kira.", "Metroya yürüme mesafesi.", "Lavabo altı, ferah daire."], "poke_line": "Komisyonsuz olmaz!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "komisyon", "name": "Komisyon", "type_label": "PASİF", "desc": "Maç sonu Kırıntı kazancı +%20 artar.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "daireyi_gezdir", "name": "Daireyi Gezdir", "type_label": "AKTİF", "desc": "En yakın gap'in ortasına 0.3 sn ışınlanma efektiyle geçer.", "cooldown": 16.0, "duration": 0.3, "line": "Bakın burası güney cephe."},
			{"slot": "aktif2", "id": "studyo_daire", "name": "Stüdyo Daire", "type_label": "KÜÇÜLME", "desc": "%55 boyuta küçülür.", "cooldown": 13.0, "duration": 2.5, "scale": 0.55, "gravity_mult": 1.0, "line": "1+0'a da sığarım."},
		],
		"death_lines": ["Kira arttı!", "Gahpe oğlu gahpe!"], "win_lines": ["Satıldı!", "Makara abi bunlar!"],
	},
	"siber": {
		"id": "siber", "display_name": "Siber Böcek", "price": 3500, "tagline": "Sırt pili, LED antenler",
		"sprite_path": "res://assets/sprites/char_siber.png", "front_path": "res://assets/sprites/char_siber.png", "angry_path": "res://assets/sprites/char_diva_angry.png", "fallback_kind": "char_diva",
		"passive_text": "Pasif: Pil Tasarrufu (%15 kısa bekleme)", "ability_name": "Uzaktan Kumanda", "ability_text": "3 sn yumuşak süzülme modu.",
		"cooldown": 15.0, "duration": 3.0, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Bağlantı kuruldu.", "taunt_line": "Şarjım yüzde on beş.",
		"voice_pitch": 0.95, "tap_lines": ["Sistem başlatıldı.", "Şarjım yüzde on beş.", "Güncelleme var, yükleyeyim mi?"], "poke_line": "Hata kodu 404!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "pil_tasarrufu", "name": "Pil Tasarrufu", "type_label": "PASİF", "desc": "Tüm bekleme süreleri %15 kısa sürer.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "uzaktan_kumanda", "name": "Uzaktan Kumanda", "type_label": "AKTİF", "desc": "3 sn boyunca kontrollü yumuşak süzülme sağlar.", "cooldown": 15.0, "duration": 3.0, "line": "Bağlantı kuruldu."},
			{"slot": "aktif2", "id": "mikro_mod", "name": "Mikro Mod", "type_label": "KÜÇÜLME", "desc": "%50 boyuta küçülür.", "cooldown": 12.0, "duration": 2.0, "scale": 0.5, "gravity_mult": 1.0, "line": "Boyut optimize edildi."},
		],
		"death_lines": ["Mavi ekran!", "Aaaa duktur yok mu duktur!"], "win_lines": ["%100 verimlilik!", "Makarayız abiiii!"],
	},
	"yurt": {
		"id": "yurt", "display_name": "Yurt Böceği", "price": 3000, "tagline": "Pijama, kulaklık",
		"sprite_path": "res://assets/sprites/char_yurt.png", "front_path": "res://assets/sprites/char_yurt.png", "angry_path": "res://assets/sprites/char_halaybasi_angry.png", "fallback_kind": "char_halaybasi",
		"passive_text": "Pasif: Alıştık (Sprey/Çorap işlemez)", "ability_name": "Oda Arkadaşı", "ability_text": "4 sn kalkan; ilk çarpışmayı üstlenir.",
		"cooldown": 16.0, "duration": 4.0, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Kanka sen al bunu.", "taunt_line": "Yoklamaya beni de yaz.",
		"voice_pitch": 1.18, "tap_lines": ["Yemekhane açık mı?", "Oda arkadaşım yine yok.", "Yoklamaya beni de yaz."], "poke_line": "Etüt saatindeyim!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "alistik", "name": "Alıştık", "type_label": "PASİF", "desc": "Böcek ilacı bulutu ve Kirli Çorap ona etki etmez.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "oda_arkadasi", "name": "Oda Arkadaşı", "type_label": "AKTİF", "desc": "4 sn yanında minik böcek uçar; ilk ölümcül çarpışmayı üstlenir.", "cooldown": 16.0, "duration": 4.0, "line": "Kanka sen al bunu."},
			{"slot": "aktif2", "id": "ranzaya_saklan", "name": "Ranzaya Saklan", "type_label": "KÜÇÜLME", "desc": "%60 boyuta küçülür.", "cooldown": 13.0, "duration": 2.5, "scale": 0.6, "gravity_mult": 1.0, "line": "Yoklama mı var?"},
		],
		"death_lines": ["Yemekhane kapanmış!", "Gahpe oğlu gahpe!"], "win_lines": ["İzin kağıdı onaylandı!", "Makara abi bunlar!"],
	},
	"dayi": {
		"id": "dayi", "display_name": "Kahvehane Dayısı", "price": 2500, "tagline": "Atlet, bıyık, telefon elde",
		"sprite_path": "res://assets/sprites/char_dayi.png", "front_path": "res://assets/sprites/char_dayi.png", "angry_path": "res://assets/sprites/char_duktur_angry.png", "fallback_kind": "char_duktur",
		"passive_text": "Pasif: Tecrübe (+6 px yakın kaçış)", "ability_name": "Çay Molası", "ability_text": "2 sn olduğu yükseklikte sabit süzülür.",
		"cooldown": 14.0, "duration": 2.0, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Bi çay söyle evladım.", "taunt_line": "Okey dördüncüsü lazım.",
		"voice_pitch": 1.06, "tap_lines": ["Bir çay söyle evladım.", "Bizim zamanımızda terlik yoktu.", "Okey dördüncüsü lazım."], "poke_line": "Saygısızlık etme yeğen!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "tecrube", "name": "Tecrübe", "type_label": "PASİF", "desc": "Yakın kaçış mesafesi +6 px geniş sayılır.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "cay_molasi", "name": "Çay Molası", "type_label": "AKTİF", "desc": "2 sn boyunca olduğu yükseklikte sabit süzülür.", "cooldown": 14.0, "duration": 2.0, "line": "Bi çay söyle evladım."},
			{"slot": "aktif2", "id": "tabureye_sig", "name": "Tabureye Sığ", "type_label": "KÜÇÜLME", "desc": "%65 boyuta küçülür.", "cooldown": 12.0, "duration": 2.5, "scale": 0.65, "gravity_mult": 1.0, "line": "Yer var, yer var."},
		],
		"death_lines": ["Çay soğudu!", "Aaaa duktur yok mu duktur!"], "win_lines": ["Okey döndü!", "Makarayız abiiii!"],
	},
	"taraftar": {
		"id": "taraftar", "display_name": "Taraftar Böcek", "price": 3000, "tagline": "Forma, atkı (sadece renkler)",
		"sprite_path": "res://assets/sprites/char_taraftar.png", "front_path": "res://assets/sprites/char_taraftar.png", "angry_path": "res://assets/sprites/char_halaybasi_angry.png", "fallback_kind": "char_halaybasi",
		"passive_text": "Pasif: Tribün (Elenen rakipte -3 sn CD)", "ability_name": "Frikik", "ability_text": "1.2 sn ileri şutlanır, ilk engeli deler.",
		"cooldown": 15.0, "duration": 1.2, "hitbox_scale": 1.0, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Doksana!", "taunt_line": "Bu sene bizim sene!",
		"voice_pitch": 1.16, "tap_lines": ["Bu sene bizim sene!", "Hakem kör mü?", "Doksana takarım!"], "poke_line": "Sarı kart mı o?!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "tribun", "name": "Tribün", "type_label": "PASİF", "desc": "Her elenen rakip için bekleme süreleri 3 sn kısalır.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "frikik", "name": "Frikik", "type_label": "AKTİF", "desc": "1.2 sn top gibi ileri şutlanır, ilk engeli delip geçer.", "cooldown": 15.0, "duration": 1.2, "line": "Doksana!"},
			{"slot": "aktif2", "id": "baraj", "name": "Baraj", "type_label": "KÜÇÜLME", "desc": "%60 boyuta küçülür.", "cooldown": 13.0, "duration": 2.5, "scale": 0.6, "gravity_mult": 1.0, "line": "Barajı kurdum."},
		],
		"death_lines": ["Ofsayt var!", "Gahpe oğlu gahpe!"], "win_lines": ["Şampiyon!", "Makara abi bunlar!"],
	},
	"saftirik": {
		"id": "saftirik", "display_name": "Saftirik Böcek", "price": 2000, "tagline": "İki dişli, şaşkın otobüs yolcusu",
		"sprite_path": "res://assets/sprites/char_saftirik.png", "front_path": "res://assets/sprites/char_saftirik.png", "angry_path": "res://assets/sprites/char_klasik_angry.png", "fallback_kind": "char_klasik",
		"passive_text": "Pasif: Şaşkın Bakış (Hitbox %10 küçük)", "ability_name": "Otobüsü Kaçırdım!", "ability_text": "1.8 sn şaşkınlık kalkanı; çarptığı engeli savurur.",
		"cooldown": 13.0, "duration": 1.8, "hitbox_scale": 0.9, "gravity_mult": 1.0, "flap_mult": 1.0,
		"ability_line": "Abi durak burası mı?!", "taunt_line": "Akbil basmadı galiba.",
		"voice_pitch": 1.24, "tap_lines": ["Abi bu otobüs Taksim'e gider mi?", "Akbilim bitmiş ya.", "Bana mı baktın abi?"], "poke_line": "Dürtme, koltuktan düşecem!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "saskin_bakis", "name": "Şaşkın Bakış", "type_label": "PASİF", "desc": "Hitbox %10 küçük, masum bakışlarla sıyrılır.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "otobus_kacirdim", "name": "Otobüsü Kaçırdım!", "type_label": "AKTİF", "desc": "1.8 sn şaşkınlık kalkanı açar.", "cooldown": 13.0, "duration": 1.8, "line": "Abi durak burası mı?!"},
			{"slot": "aktif2", "id": "koltuk_arasi", "name": "Koltuk Arası", "type_label": "KÜÇÜLME", "desc": "%60 boyuta küçülür.", "cooldown": 12.0, "duration": 2.5, "scale": 0.6, "gravity_mult": 1.0, "line": "Ben şuraya sıkışırım."},
		],
		"death_lines": ["İnecek var!", "Aaaa duktur yok mu duktur!"], "win_lines": ["Koltuk buldum!", "Makara abi bunlar!"],
	},
	"deli": {
		"id": "deli", "display_name": "Deli Böcek", "price": 2500, "tagline": "Beyaz önlük, sıfır fren",
		"sprite_path": "res://assets/sprites/char_deli.png", "front_path": "res://assets/sprites/char_deli.png", "angry_path": "res://assets/sprites/char_klasik_angry.png", "fallback_kind": "char_klasik",
		"passive_text": "Pasif: Deli Cesareti (Kanat %8 keskin)", "ability_name": "Tımarhane Firarı", "ability_text": "2 sn deli kalkanı; önündeki engeli parçalar.",
		"cooldown": 13.0, "duration": 2.0, "hitbox_scale": 0.95, "gravity_mult": 1.0, "flap_mult": 1.08,
		"ability_line": "Benim raporum var!", "taunt_line": "Gömleği arkadan bağlamışlar.",
		"voice_pitch": 1.28, "tap_lines": ["Benim raporum var!", "Terlikler uçuyor mu?", "Doktor bey kapıyı aç!"], "poke_line": "Bana iğne yapma!", "flee_line": "Tamam, ben kaçtım!",
		"skills": [
			{"slot": "pasif", "id": "deli_cesareti", "name": "Deli Cesareti", "type_label": "PASİF", "desc": "Kanat çırpması %8 daha keskindir.", "cooldown": 0.0, "duration": 0.0, "line": ""},
			{"slot": "aktif1", "id": "timarhane_firari", "name": "Tımarhane Firarı", "type_label": "AKTİF", "desc": "2 sn koruma kalkanı; çarptığı engeli parçalar.", "cooldown": 13.0, "duration": 2.0, "line": "Benim raporum var!"},
			{"slot": "aktif2", "id": "deli_gomlegi", "name": "Deli Gömleği", "type_label": "KÜÇÜLME", "desc": "%55 boyuta sıkışıp küçülür.", "cooldown": 12.0, "duration": 2.5, "scale": 0.55, "gravity_mult": 1.0, "line": "Kollarım bağlı ama sığarım!"},
		],
		"death_lines": ["Rapor bitti!", "Gahpe oğlu gahpe!"], "win_lines": ["Firar tamam!", "Makarayız abiiii!"],
	},
}


## Verilen kimliğe ait karakter sözlüğünü döner (yoksa klasik).
static func get_character(char_id: String) -> Dictionary:
	if CHARACTERS.has(char_id):
		return CHARACTERS[char_id] as Dictionary
	return CHARACTERS["klasik"] as Dictionary


static func get_skill(char_id: String, slot_name: String) -> Dictionary:
	var cdata: Dictionary = get_character(char_id)
	var skills: Array = cdata.get("skills", []) as Array
	for sk: Variant in skills:
		var d: Dictionary = sk as Dictionary
		if str(d.get("slot", "")) == slot_name:
			return d
	return {}


static func get_voice_pitch(char_id: String) -> float:
	var cdata: Dictionary = get_character(char_id)
	return float(cdata.get("voice_pitch", 1.15))


const DEATH_AUDIO_ENTRIES_MALE: Array[Dictionary] = [
	{"text": "Kaybettin lan! @#%", "sound": "res://assets/sounds/kufur_1.wav"},
	{"text": "Ulan! @#% yine mi terlik?!", "sound": "res://assets/sounds/kufur_2.wav"},
	{"text": "Bu ne biçim refleks be! @#%", "sound": "res://assets/sounds/kufur_3.wav"},
	{"text": "Böcek gibi ezildin lan! @#%", "sound": "res://assets/sounds/kufur_4.wav"},
	{"text": "Ah be! @#% gitti maç!", "sound": "res://assets/sounds/kufur_5.wav"},
	{"text": "Yine mi çaktın duvara! @#%", "sound": "res://assets/sounds/kufur_6.wav"},
	{"text": "Annem bunu duymasın! @#%", "sound": "res://assets/sounds/kufur_7.wav"},
	{"text": "Terliği kim attı lan?! @#%", "sound": "res://assets/sounds/kufur_8.wav"},
	{"text": "Gahpe oğlu gahpe!", "sound": "res://assets/sounds/gahpe.wav"},
	{"text": "Aaaa duktur yok mu duktur!", "sound": "res://assets/sounds/duktur_yok_mu.wav"},
	{"text": "Oçuz abi, piçiz abi!", "sound": "res://assets/sounds/ocuz.wav"},
]

const DEATH_AUDIO_ENTRIES_DIVA: Array[Dictionary] = [
	{"text": "Kaybettin lan! @#%", "sound": "res://assets/sounds/diva_kufur_1.wav"},
	{"text": "Ayy gözlüğüm kırıldı! @#%", "sound": "res://assets/sounds/diva_kufur_2.wav"},
	{"text": "Bu ne biçim terlik ayol! @#% makyajım aktı!", "sound": "res://assets/sounds/diva_kufur_3.wav"},
]

const WIN_AUDIO_ENTRIES_MALE: Array[Dictionary] = [
	{"text": "Kim tutar beni! Mutfağın kralı benim!", "sound": "res://assets/sounds/sevinc_1.wav"},
	{"text": "Hepinizi yedim lan! Terlik mi? Hı hı, kesin!", "sound": "res://assets/sounds/sevinc_2.wav"},
	{"text": "Mutfağın kralı geldi!", "sound": "res://assets/sounds/sevinc_3.wav"},
	{"text": "Halaya gelin lan!", "sound": "res://assets/sounds/sevinc_4.wav"},
	{"text": "Makara abi bunlar!", "sound": "res://assets/sounds/makara_1.wav"},
	{"text": "Makarayız abiiii!", "sound": "res://assets/sounds/makara_2.wav"},
]

const WIN_AUDIO_ENTRIES_DIVA: Array[Dictionary] = [
	{"text": "Terlik mi? Hı hı, kesin canım!", "sound": "res://assets/sounds/diva_sevinc_1.wav"},
	{"text": "Sahne benim! Kim tutar beni!", "sound": "res://assets/sounds/diva_sevinc_2.wav"},
]


## Elenmede ekrandaki yazı ile birebir eşleşen replik + ses çiftini döner.
static func get_random_death_entry(char_id: String) -> Dictionary:
	var pool: Array[Dictionary] = DEATH_AUDIO_ENTRIES_DIVA if char_id == "diva" else DEATH_AUDIO_ENTRIES_MALE
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return pool[rng.randi_range(0, pool.size() - 1)]


## Kazanmada ekrandaki yazı ile birebir eşleşen replik + ses çiftini döner.
static func get_random_win_entry(char_id: String) -> Dictionary:
	var pool: Array[Dictionary] = WIN_AUDIO_ENTRIES_DIVA if char_id == "diva" else WIN_AUDIO_ENTRIES_MALE
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	return pool[rng.randi_range(0, pool.size() - 1)]


## Karakterin elenme repliklerinden rastgele birini seçer (görsel RNG).
static func get_random_death_line(char_id: String) -> String:
	return str(get_random_death_entry(char_id)["text"])


## Karakterin kazanma repliklerinden rastgele birini seçer (görsel RNG).
static func get_random_win_line(char_id: String) -> String:
	return str(get_random_win_entry(char_id)["text"])

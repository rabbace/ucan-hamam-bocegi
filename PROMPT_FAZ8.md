# UÇAN HAMAM BÖCEĞİ — Faz 8: Düzeltmeler, Denge, Yetenek Setleri, Rehber ve Sıralama

> **Ajan için:** Bu dosya `PROMPT.md` ve `PROMPT_FAZ6_7.md`'nin devamıdır. Oradaki **GENEL KURALLAR** aynen geçerlidir (statik tip, eksiksiz dosya, tüm sayılar `GameConfig`'de, global `randi()` yasak, deterministik dünya, pastel stil, `ResourceLoader.exists()` ile güvenli yükleme, oyun içi yazılarda emoji yok).
>
> Bu faz, oyun test edildikten sonra gelen geri bildirimlerdir. Maddeleri **sırayla** uygula. Önce 8.1'deki hatayı düzelt ve test et, sonra diğerlerine geç. Mevcut çalışan özellikleri bozma; değiştirdiğin her dosyayı sonunda listele.

---

## 8.1 HATA: Çok oyunculuda biri ölünce oyun diğerleri için durmamalı

**Beklenen davranış:** Odada biri elendiğinde, hayattaki diğer oyuncular hiçbir kesinti olmadan oynamaya devam eder. Maç yalnızca hayatta 1 kişi kaldığında biter. **Host elense bile** maç diğerleri için devam eder.

**Kontrol et ve düzelt:**
1. Ölümde `get_tree().paused = true`, `change_scene_to_*`, `queue_free()` ile GameWorld/Player silme veya `set_process(false)` ile dünyayı durdurma **çok oyunculu modda kesinlikle olmamalı**. Bunlar yalnızca tek oyunculu modda yapılabilir.
2. Ölen oyuncunun kendi cihazında dünya akmaya devam eder (`match_time` artar, engeller kayar, hayaletler güncellenir). Ölen oyuncu sadece **izleyici** olur: girdisi zıplatmaz, çarpışması kapanır, böceği grileşip ekranın altına düşer ve orada görünmez olur.
3. "ELENDİN – Arkadaşlarını İzliyorsun" paneli oyunu **engellemez**: panel `mouse_filter = IGNORE` olmalı, sadece kendi butonları tıklanabilir. Çok oyunculuda "Tekrar Dene" butonu **gizlenir**.
4. Host elendiğinde de: RPC'leri dinlemeye, `players` sözlüğünü güncellemeye, kazananı belirlemeye devam eder. Host'un oyuncu ölümü ile Host'un ağ görevleri birbirinden tamamen ayrı tutulur (`NetworkManager` hiçbir zaman Player düğümüne bağlı olmasın).
5. Uzak bir oyuncu ölünce yerel oyuncunun ekranında yalnızca o hayalet grileşip düşer; yerel oyuncunun kontrolü, kamerası, HUD'u hiç etkilenmez.

**Zafer Turu (kazanan da hemen durmasın):**
- Hayatta tek kişi kalınca kazanan ilan edilir (`announce_winner`), ama kazanan **uçmaya devam eder**. Ekranının üstünde: **"KAZANDIN! Zafer turu — bakalım daha ne kadar gidebilirsin"**.
- Zafer turu, kazanan ölünce ya da 15 sn dolunca biter. Kazananın ekranında "Bitir" butonu da olur. Zafer turunda ölmek sıralamayı değiştirmez.
- Diğer oyuncular bu sırada kazananın hayaletini izler.
- Zafer turu bitince herkes **8.6 Sıralama ekranına** geçer.

**Test:** 3 pencerede (*Debug → Run Multiple Instances*) önce Host'u, sonra bir istemciyi öldür. Kalan oyuncu kesintisiz oynamalı, sayaç "Hayatta Kalan: 1 / 3" olmalı, Zafer Turu başlamalı. Ardından 2 pencereyle aynı testi yap.

---

## 8.2 Zorluk dengesi: başlangıç kolaylaşsın, süpürge sapı sonraya kalsın

Oyun başlangıçta çok zor. `GameConfig.LEVELS` tablosunu aşağıdakiyle **değiştir**:

| Sv | Ad | Başlangıç (geçilen çift) | Hız (px/s) | Gap (px) | Sallanma | Sürpriz şansı | Sürpriz havuzu | Füze evresi |
|---|---|---|---|---|---|---|---|---|
| 1 | Mutfak Turu | 0 | 230 | 360 | 0 | %0 | — | yok |
| 2 | Salon Paniği | 10 | 260 | 335 | 10 px | %8 | böcek ilacı bulutu | yok |
| 3 | Anne Uyandı | 22 | 295 | 315 | 20 px | %14 | + dolap kapağı | 5 füze |
| 4 | Komşular Toplandı | 36 | 330 | 295 | 30 px | %20 | + fırlayan terlik | 6 füze |
| 5 | Belediye İlaçlıyor | 52 | 370 | 275 | 45 px | %26 | **+ süpürge sapı** | 7 füze |
| 6 | Efsane Böcek | 72 | 410 | 260 | 55 px | %32 | hepsi | 8 füze |
| 7+ | Efsane Böcek +N | her +20 çiftte | +15 (en fazla 520) | −5 (en az 235) | +5 (en fazla 80) | +3% (en fazla %50) | hepsi | 9 füze |

**Ek kurallar:**
- **Isınma:** Maçın ilk 5 engel çiftinin gap'i ayrıca +40 px geniş gelir.
- **Süpürge sapı** (kullanıcının "sopa" dediği engel) **Seviye 5'ten önce hiç çıkmaz.** Çıktığında geçiş aralığı en az 240 px olur ve önce/sonra en az 3 normal engel çifti bulunur.
- İki sürpriz engel arasında her zaman en az 3 normal çift olur. Füze evresinden hemen önceki ve sonraki 2 çift sürpriz olamaz.
- **Yeni engel tanıtımı:** Bir sürpriz engel türü maçta ilk kez gelecekse, 1.5 sn önce ekranın üstünde küçük bir şerit çıkar. Örnek: **"YENİ: Süpürge Sapı! Altından ya da üstünden geç."** Her tür için bir tanıtım cümlesi `GameConfig`'de olsun.
- Sürpriz havuzu ve tanıtımlar da seed'den önceden üretilir; tüm cihazlarda aynıdır.

---

## 8.3 Her karakterin kendine özgü 3 yeteneği (hepsi küçülebilir)

Her karakterin artık **1 pasif + 2 aktif** yeteneği var. 2. aktif yetenek her karakterde bir **küçülme** yeteneğidir. Ancak her karakterin küçülmesi farklıdır: oran, süre ve yan etki değişir. Duktur en iyi küçülendir.

`CharacterData` yapısını şöyle değiştir: her karakterde `skills` dizisi, her yetenek bir sözlük:
`{ "slot": "pasif" | "aktif1" | "aktif2", "id", "name", "type_label", "desc", "cooldown", "duration", "icon_path", "line" }`

### Klasik Böcek — "Mutfağın eskisi"
| Slot | Ad | Etki | CD / Süre |
|---|---|---|---|
| Pasif | **Çevik Kanatlar** | Hitbox %20 küçük, kanat çırpması biraz daha keskin (`flap_mult 1.05`). | — |
| Aktif 1 | **Ani Fren** | Düşüşü anında durdurur, 0.5 sn havada asılı kalır (yerçekimi ×0.2). Replik: *"Kaç kaç kaç!"* | 8 sn / 0.5 sn |
| Aktif 2 | **Kanat Toplama** (küçülme) | `scale 0.7`. Hafif ama sık kullanılabilen küçülme. Replik: *"Kendimi topluyorum."* | 10 sn / 2 sn |

### Diva Böcek — "Gözlüklü, süslü, alıngan"
| Slot | Ad | Etki | CD / Süre |
|---|---|---|---|
| Pasif | **Işıltı** | Füze evresinde kendi ışığı %50 daha geniş; füze uyarı çizgilerini 0.2 sn erken görür. | — |
| Aktif 1 | **Ayy Terlik Geliyor!** | 2.5 sn pembe kalkan; çarptığı terlik/füze/engel parçalanır. Replik: *"Ayy terlik geliyor!"* | 12 sn / 2.5 sn |
| Aktif 2 | **Kendimi Küçük Hissettim** (küçülme) | `scale 0.6`, küçükken düşüş hızı %20 yavaş. Dramatik iç çekme animasyonu. Replik: *"Kimse beni anlamıyor…"* | 14 sn / 2.5 sn |

### Duktur Böcek — "Önlüklü, reçeteli"
| Slot | Ad | Etki | CD / Süre |
|---|---|---|---|
| Pasif | **Bağışıklık Sistemi** | Rakiplerden gelen sataşmaların süresi onda %40 kısa sürer. | — |
| Aktif 1 | **Serum Takviyesi** | 4 sn boyunca yerçekimi ×0.55, en yüksek düşüş hızı ×0.6. Çok kontrollü süzülme. Replik: *"Serumu taktım, rahatım."* | 12 sn / 4 sn |
| Aktif 2 | **Duktur Müdahalesi** (küçülme) | `scale 0.5` (en güçlü küçülme), yerçekimi ×0.7. Replik: *"Duktur müdahalesi!"* | 12 sn / 3 sn |

### Halay Başı Böcek — "Mendil elde, omuz omuza"
| Slot | Ad | Etki | CD / Süre |
|---|---|---|---|
| Pasif | **Davul Zurna** | Her 5 "Yakın Kaçış"ta iki aktif yeteneğinin bekleme süresi 2 sn kısalır. | — |
| Aktif 1 | **Mendil Sallama** | 2 sn hayalet fazı (engel/füze içinden geçer). Rakiplerin ekran kenarlarında 1.5 sn konfeti. Replik: *"Hadi bakalım halaya!"* | 14 sn / 2 sn |
| Aktif 2 | **Omuz Omuza** (küçülme) | `scale 0.65`, küçükken halay adımı gibi sağa sola sallanır (yalnızca görsel). Replik: *"Sıkışın biraz, sıkışın!"* | 13 sn / 2.5 sn |

**Küçülme kuralları (hepsi için):**
- Küçülme ve büyüme 0.15 sn tween ile olur; `CollisionShape2D` de aynı oranda küçülür.
- Normal boyuta dönerken 0.3 sn dokunulmazlık olur (dar aralıkta büyüyüp haksız ölmesin). Bu sürede böcek hafifçe yanıp söner.
- Küçülme, diğer aktif yetenek ve güçlendirmelerle birlikte kullanılabilir.

**Kontroller:**
- Alt şeridin sağında iki yetenek butonu: **Aktif 1** büyük (140 px), **Aktif 2** biraz küçük (115 px), Aktif 1'in solunda. Her ikisinde de dairesel bekleme göstergesi ve küçük yetenek ikonu.
- Güçlendirme tepsisi alt şeridin solunda kalır.
- PC: Aktif 1 = `E` / Sağ Tık, Aktif 2 = `Q`. Input Map'e `ability_2` eklenir.
- Ağ: `use_ability(slot: int)` — `@rpc("any_peer", "call_local", "reliable")`, gönderen doğrulamasıyla. Tüm cihazlarda efekt + replik balonu gösterilir.

---

## 8.4 Yetenekler ekranı (ortada açılan panel)

Ekranın ortasında açılan, arkası karartılmış (`Color(0,0,0,0.45)`) bir panel. Boyut ~620x980, yuvarlatılmış köşe, pastel.

**İçerik:**
- Üstte: karakterin büyük görseli (hafifçe süzülür), adı ve tek satırlık tanımı.
- Altında 3 yetenek satırı. Her satırda:
  - Yetenek ikonu
  - Ad ve tür etiketi: **PASİF** (adaçayı yeşili), **AKTİF** (toz mavi), **KÜÇÜLME** (toz pembe)
  - 1–2 cümlelik açıklama
  - Bekleme süresi ve etki süresi ("12 sn bekleme · 3 sn sürer")
  - Tuş ipucu ("Dokun ya da E")
- Her satırın yanında küçük bir **canlı önizleme**: mini böcek ikonu yeteneği tekrar tekrar gösterir. Örneğin küçülüp büyür, kalkan açılır, yanıp söner (tween döngüsü).
- Sağa/sola kaydırarak (veya oklarla) diğer karakterlere geçilir; altta 4 nokta göstergesi.
- En altta **"Bu böceği seç"** ve **"Kapat"** butonları.

**Nereden açılır:**
- Karakter seçim ekranında her kartta "Yetenekler" butonu
- Lobide bir oyuncu kartına dokununca (seçim butonu yalnızca kendi kartında aktiftir)
- Tek oyunculuda duraklatma menüsünden

**Maç başında:** 3-2-1 geri sayımı sırasında ekranın ortasında küçük bir özet kartı belirir: karakterin 3 yeteneğinin ikonu, adı ve tuşu. Geri sayım bitince kart kayarak kaybolur.

---

## 8.5 "Nasıl Oynanır?" rehberi

- Ana menüde **"Nasıl Oynanır?"** butonu. Oyun **ilk kez** açıldığında rehber otomatik açılır (`settings.cfg`'de `guide_seen`).
- Kaydırmalı sayfalar, altta nokta göstergesi, "Geç" ve "İleri" butonları. Her sayfada büyük bir başlık, en fazla 3 kısa cümle ve mevcut sprite'larla yapılmış küçük canlı bir sahne.
- Dil esprili ve kısa olsun.

| # | Başlık | İçerik özeti |
|---|---|---|
| 1 | **Uç!** | Ekrana dokun, böcek kanat çırpsın. İnsanların arasından geç. Tezgâha ya da tavana çarpma. |
| 2 | **Ödü Kopan İnsan** | Bir insanın ne kadar yakınından geçersen o kadar büyük çığlık atar ve o kadar çok puan alırsın. Art arda yakın geçişler kombo yapar. |
| 3 | **Seviyeler** | Engel geçtikçe mahalle ayaklanır: hız artar, aralıklar daralır, yeni sürprizler gelir. |
| 4 | **Karakterler** | Her böceğin 1 pasif ve 2 aktif yeteneği var; hepsi küçülebilir. Butonla **Yetenekler ekranını** açar. |
| 5 | **Güçlendirmeler** | Yolda çıkan kutuları topla, alttaki tepsiden dokunarak kullan. Tüm kendine avantaj sağlayan güçlendirmeler ikonlarıyla listelenir. |
| 6 | **Şuraları Aydınlat Hele!** | Ortam kararınca füzeler çapraz gelir. Kırmızı çizgi füzenin yolunu gösterir; çizgiden uzak dur. |
| 7 | **Arkadaşlarla** | Aynı Wi-Fi'de oda kur ya da katıl. Son kalan kazanır. Sataşma güçlendirmeleri, laf atma, Hayalet Terlik. Maç sonunda sıralama. |

**İlk kez ipuçları:** Bir güçlendirme ilk kez toplandığında, bir sürpriz engel ilk kez geldiğinde veya ilk kez elendiğinde ekranın üstünde 2 sn'lik küçük bir ipucu çıksın. Örnek: "Dondurma aldın! Alttaki tepsiden dokun." Her ipucu cihaz başına yalnızca bir kez gösterilir.

---

## 8.6 Maç sonu sıralama ekranı (1., 2., 3., …)

Faz 7'deki ayrı ödül kartları kaldırılır; ödüller bu ekrandaki satırlara rozet olarak eklenir.

**Sıralama kuralı (Host hesaplar ve `show_results(results: Array)` ile yayınlar — `authority, call_local, reliable`):**
- 1. = son hayatta kalan (Zafer Turu sıralamayı değiştirmez).
- Diğerleri **ölüm sırasının tersine** göre: en son ölen 2., ondan önce ölen 3., …
- Aynı anda ölenler (aynı `match_time` ± 0.05 sn) aynı sırayı paylaşır ("2." ve "2."), sonraki sıra atlanır.
- Maçtan kopan oyuncu, koptuğu ana göre sıralanır ve adının yanında "(kaçtı)" yazar.

**Ekran:**
- Başlık: **"MAHALLE SONUÇLARI"**.
- Satırlar **sondan başa** doğru, aşağıdan kayarak gelir (her biri 0.4 sn arayla). Merak uyansın, 1. en son gelsin.
- Her satırda:
  - Büyük sıra numarası. 1. altın, 2. gümüş, 3. bronz tonunda (pastel versiyonları); diğerleri koyu metin rengi.
  - Karakter ikonu ve oyuncu adı
  - Hayatta kalma süresi (`dk:sn`) ve "Ödü Kopan" sayısı
  - Bu maçtan kazanılan puan: 1. **+5**, 2. **+3**, 3. **+2**, 4. **+1**, 5. **0**
  - Varsa rozetler: Çığlık Ustası, Baş Belası, Terlik Mıknatısı (ilk elenen), İntikam Meleği
- 1. satır gelince konfeti ve sevinç sesi çalar, kazananın böceği satırın yanında zıplar.
- Yerel oyuncunun satırı ince bir çerçeveyle vurgulanır.
- 4 sn sonra Host'ta **"Tekrar Oyna"** ve **"Lobiye Dön"** butonları belirir; istemcilerde "Host'un kararı bekleniyor…" yazısı görünür.

**Lobide oturum tablosu:** Oyuncu kartları toplam puana göre sıralanır, her kartta toplam puan ve kaç kez 1. olduğu yazar.

---

## 8.7 Yeni replikler ve argo sansürü

**Yeni replikler:**
- **Turbo Kanat kullanıldığında** (hız devreye girdiği an): böceğin üstünde balon **"Bas bas kökle amk kökleeee"**, 2 sn. Varsa `turbo_kokle.ogg` çalar. Önceki "Fren tutmuyooor!" repliği kaldırılır.
- **Rakibe sataşma gönderildiğinde:** gönderenin böceğinin üstünde balon **"Özür dilerim pıttığım"**, 1.8 sn. Varsa `ozur_dilerim.ogg` çalar.
- Bu iki replik tüm oyuncuların ekranında görünür. Güçlendirme kullanımı artık çok oyunculuda kozmetik olarak yayınlanır: `show_item_fx(item_id: String)` — `@rpc("any_peer", "call_local", "reliable")`, gönderen doğrulamasıyla. Yalnızca görsel efekt, balon ve ses; oyun mantığı yerel kalır.

**Argo sansürü ayarı:**
- Ayarlarda **"Argo Sansürü: Açık / Kapalı"**, varsayılan **Kapalı**.
- Açıkken tüm balon ve akış yazılarından geçen bir filtre çalışır: `GameConfig.CENSOR_MAP` sözlüğündeki kelimeleri ilk harfi kalacak şekilde yıldızlar ("amk" → "a**"). Filtre tek bir fonksiyonda olsun: `static func censor(text: String) -> String`.
- Sansür her oyuncunun kendi cihazındaki ayara göre uygulanır.

---

## 8.8 Ölüm müziği

Elenme sesi artık kullanıcının ekleyeceği dramatik bir müzik parçasıdır: `res://assets/sounds/olum_muzigi.ogg`. Dosya yoksa sessiz geçilir.

- **Yerel oyuncu ölünce:**
  - Oyun müziği 0.3 sn'de kısılır, `olum_muzigi.ogg` baştan çalar. 6 sn sonra (`GameConfig.DEATH_MUSIC_MAX`) 1 sn'de söner, oyun müziği geri gelir.
  - Aynı anda görsel dram: ekran 2.5 sn siyah-beyaza döner (`ColorRect` + basit gri tonlama shader'ı, CanvasLayer üzerinde), böcek yavaşça dönerek düşer, üstünde sansürlü argo balonu. Sonra renkler geri gelir ve izleyici moduna geçilir. Dünya zamanı **durmaz**, bu yalnızca görsel bir efekttir.
- **Başka bir oyuncu ölünce:** Müzik zaten çalmıyorsa parçanın ilk 2 sn'si −10 dB'de çalar ve söner. Çalıyorsa tekrar başlatılmaz (üst üste binmesin).
- **Kazanan belli olunca:** ölüm müziği hemen kesilir, sevinç sesi çalar.
- Ölüm müziği `Music` bus'ında çalar; menüdeki ses ayarı onu da etkiler.
- `kufur.ogg` artık elenmede çalınmaz.

---

## 8.9 Çevrimiçi sunucu modu (internet üzerinden, yabancılarla da)

> Bu bölüm büyüktür. 8.1–8.8 bitip test edildikten **sonra**, ayrı bir oturumda uygula. Aynı Wi-Fi modu (LAN) olduğu gibi kalır; bu yeni bir moddur.

### Mimari
Telefonlar internet üzerinden birbirine doğrudan bağlanamaz (NAT). Bu yüzden herkes bir **sunucuya** bağlanır. Sunucu, oyunun kendisinin **headless (ekransız)** çalıştırılan hâlidir; ayrı bir dil veya framework kullanılmaz.

İki parça var, ikisi de aynı Godot projesinden:
1. **Eşleştirici (Matchmaker)** — `res://server/Matchmaker.gd`. Sabit TCP portunda (`GameConfig.MATCHMAKER_PORT = 7700`) dinler (`TCPServer` + `StreamPeerTCP`, satır başına bir JSON mesajı). Odaları yönetir.
2. **Oda Sunucusu (Room Server)** — `res://server/RoomServer.gd`. Her oda ayrı bir süreçtir. Eşleştirici bunu `OS.create_process(OS.get_executable_path(), ["--headless", "--", "--room", "--port=78xx", "--code=XXXX", "--public=1"])` ile başlatır. UDP port aralığı: 7801–7850 (en fazla 50 eşzamanlı oda).

**Başlatma:** `res://autoload/Boot.gd` (ilk autoload) komut satırını okur (`OS.get_cmdline_user_args()`):
- `--matchmaker` → Matchmaker sahnesini açar
- `--room` → RoomServer sahnesini açar
- Hiçbiri yoksa → normal oyun (MainMenu)

### Ayrılmış sunucuda "Host" kavramı değişir
Çevrimiçi modda peer 1 **sunucudur**, oyuncu değildir. Mevcut kodda "Host = oyuncu" varsayımı olan her yeri ayır:
- `players` sözlüğünde sunucu yoktur.
- Sunucu RPC yetkisini (`authority`) elinde tutar: seed üretir, ölümleri ve sataşmaları doğrular, kazananı ve sıralamayı belirler, `match_time` yayınlar.
- **"Oda Sahibi"** = odaya ilk giren oyuncu (o çıkarsa sıradaki). "Oyunu Başlat", "Tekrar Oyna", "Lobiye Dön" butonları oda sahibinde görünür; bunlar `request_start()` gibi RPC'lerle sunucuya **istek** gönderir, kararı sunucu verir.
- Sunucu dünyayı simüle etmez, ekran çizmez. Yalnızca zaman, doğrulama ve yayın işi yapar.
- LAN modunda eski davranış (Host hem oyuncu hem otorite) aynen çalışmaya devam eder. Ortak kod `NetworkManager.is_dedicated_server()` ile ayrılır.

### Oyuncu akışı
Ana menü butonları: **"Tek Başına"**, **"Arkadaşlarla (Aynı Wi-Fi)"**, **"Çevrimiçi"**.

"Çevrimiçi" ekranında:
- **Hızlı Oyun:** Eşleştirici, dolmamış ve maçta olmayan herkese açık bir odaya yollar; yoksa yeni oda açar. Oda 5 kişi olunca **veya** 2+ oyuncu varken 25 sn geçince maç otomatik başlar (lobide geri sayım görünür). Hızlı Oyun odalarında oda sahibi butonu yoktur.
- **Özel Oda Kur:** 4 harfli oda kodu üretilir (karışmasın diye O, 0, I, 1 yok; örn. "KTRB"). Lobide kod büyük harflerle görünür. Kodu kopyala butonu da olur (`DisplayServer.clipboard_set`). Maçı oda sahibi başlatır.
- **Kodla Katıl:** Kod girilir, eşleştirici o odanın portunu döner.

Eşleştirici mesajları (JSON): `{"op":"quick_play"}`, `{"op":"create_private"}`, `{"op":"join_code","code":"KTRB"}`, `{"op":"hello","version":X}`. Yanıt: `{"ok":true,"port":7812,"code":"KTRB"}` veya `{"ok":false,"reason":"Oda dolu" | "Oda bulunamadı" | "Maç başlamış" | "Sürüm eski, oyunu güncelle"}`. İstemci yanıtı alınca TCP'yi kapatır ve `ENetTransport.create_client(SERVER_HOST, port)` ile odaya bağlanır.

### Oda yaşam döngüsü
- Oda süreci açılınca eşleştiriciye kendi TCP bağlantısıyla `{"op":"room_ready","port":..}` bildirir ve her 2 sn'de durum gönderir: oyuncu sayısı, maçta mı, açık mı.
- Odada 60 sn kimse yoksa oda süreci kendini kapatır (`get_tree().quit()`). Eşleştirici o portu boşa çıkarır.
- Eşleştirici bir oda sürecinden 10 sn haber alamazsa o odayı listeden siler.
- Maç sürerken yeni oyuncu alınmaz; maç bitince oda lobiye döner ve tekrar katılıma açılır.

### Güvenlik ve sağlamlık (temel seviye)
- İsimler sunucuda kırpılır (en fazla 12 karakter, başta/sonda boşluk yok) ve `GameConfig.BANNED_NAME_WORDS` listesine göre filtrelenir.
- Her `any_peer` RPC'de gönderen doğrulaması (zaten var) **ve** hız sınırı: aynı oyuncudan saniyede en fazla 30 `sync_state` ve 5 diğer RPC. Aşan paketler yok sayılır, sürekli aşan oyuncu atılır.
- Hayatta olmayan oyuncunun ölüm/sataşma RPC'leri reddedilir.
- Sürüm uyuşmazlığında açıklayıcı mesaj gösterilir.
- Sunucu adresi `GameConfig.SERVER_HOST` sabitindedir; geliştirme için Ayarlar'da gizli bir alandan değiştirilebilir (logo üzerine 5 kez dokununca açılır).

### Bağlantı ve gecikme
- Bağlantı zaman aşımı 6 sn; hata mesajları Türkçe ve anlaşılır ("Sunucuya ulaşılamadı. İnternetini kontrol et.").
- Lobide her oyuncunun yanında ping göstergesi (yeşil/sarı/kırmızı nokta, `ENetPacketPeer.get_statistic(PEER_ROUND_TRIP_TIME)`).
- Hayalet oyuncu interpolasyonu 100 ms geriden oynatılır (titremesin).
- Maç ortasında bağlantı koparsa: "Bağlantı koptu" mesajı ve ana menüye dönüş. O oyuncu sunucuda elenmiş sayılır.

### Sunucu kurulumu (ajan bunu da hazırlasın)
- `export_presets.cfg` içinde **Linux/X11 headless** export ön ayarı ("Server").
- Proje kökünde `server/SUNUCU_KURULUM.md` dosyası. İçinde basit Türkçe ve adım adım şunlar olsun:
  1. En küçük bir Linux VPS kiralama (Ubuntu)
  2. Export edilen sunucu dosyasını yükleme (`scp`)
  3. Güvenlik duvarında TCP 7700 ve UDP 7801–7850'yi açma (`ufw`)
  4. Eşleştiriciyi `systemd` servisi olarak çalıştırma (çökünce yeniden başlasın): örnek `.service` dosyası
  5. Logları izleme (`journalctl`)
  6. Oyundaki `SERVER_HOST` değerini VPS IP'si ile değiştirme
- `server/run_local.sh` (ve Windows için `run_local.bat`): eşleştiriciyi yerelde başlatan betik. `SERVER_HOST = "127.0.0.1"` ile aynı bilgisayarda 3 istemciyle test edilebilsin.

### Android
- Çevrimiçi mod için ek izin gerekmez (`INTERNET` zaten var).
- Uygulama arka plana alınırsa (`NOTIFICATION_APPLICATION_PAUSED`) çevrimiçi maçta oyuncu 10 sn içinde dönmezse elenmiş sayılır.

---

## Bitti sayılması için (Faz 8)

- [ ] 3 ve 2 pencereyle test: Host dahil kim ölürse ölsün, diğerleri kesintisiz oynuyor; tek kişi kalınca Zafer Turu başlıyor ve sonra sıralama geliyor.
- [ ] Seviye 1–2 belirgin şekilde kolay; süpürge sapı Seviye 5'ten önce hiç çıkmıyor; yeni engel tanıtım şeridi görünüyor.
- [ ] 4 karakterin her birinde 1 pasif + 2 aktif yetenek çalışıyor; dört farklı küçülme farklı oran ve sürelerle çalışıyor; büyürken 0.3 sn dokunulmazlık var.
- [ ] Yetenekler ekranı ortada açılıyor, karakterler arasında kayılıyor, canlı önizlemeler oynuyor; maç başında özet kartı görünüyor.
- [ ] "Nasıl Oynanır?" rehberi ilk açılışta otomatik geliyor, 7 sayfa da gösteriliyor; ilk kez ipuçları yalnızca bir kez çıkıyor.
- [ ] Sıralama ekranı doğru sırayla (beraberlik ve "kaçtı" dahil) sondan başa doluyor; puanlar lobideki tabloya ekleniyor.
- [ ] Turbo ve sataşma replikleri tüm ekranlarda görünüyor; Argo Sansürü açıkken yıldızlanıyor.
- [ ] Ölüm müziği ve siyah-beyaz efekt yerel ölümde çalışıyor, başkasının ölümünde kısa ve kısık çalıyor, üst üste binmiyor; dosya yokken hata yok.
- [ ] (8.9) `run_local.sh` ile eşleştirici yerelde açılıyor. 3 istemciden ikisi "Özel Oda Kur" + "Kodla Katıl" ile aynı odaya giriyor; üçüncüsü "Hızlı Oyun" ile ayrı bir odaya düşüyor ve 25 sn sonra tek başına başlamıyor (en az 2 kişi şartı).
- [ ] (8.9) Ayrılmış sunucuda oda sahibi maçı başlatabiliyor; oda sahibi çıkınca yetki sıradakine geçiyor; boş oda 60 sn sonra kapanıyor.
- [ ] (8.9) LAN modu hâlâ eskisi gibi çalışıyor.

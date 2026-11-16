# UÇAN HAMAM BÖCEĞİ — Faz 9: Animasyon, Ekran Uyumu, Kontroller, Yeni Karakterler, Mağaza, Davet

> **Ajan için:** Bu dosya `PROMPT.md`, `PROMPT_FAZ6_7.md` ve `PROMPT_FAZ8.md`'nin devamıdır. **GENEL KURALLAR** aynen geçerlidir (statik tip, eksiksiz dosya, sayılar `GameConfig`'de, global `randi()` yasak, deterministik dünya, pastel stil, `ResourceLoader.exists()`, oyun içi yazılarda emoji yok).
>
> Bu faz büyük. **Alt fazlar halinde, sırayla** uygula ve her birinin sonunda test et: **9A** (9.1–9.3) → **9B** (9.6) → **9C** (9.4) → **9D** (9.5). Hangi alt fazı istediğimi söyleyeceğim.
>
> **Harici eklenti istisnası:** Genel Kurallar'daki "harici eklenti yok" kuralı yalnızca 9.4 ve 9.5 için kaldırılır. Bu iki bölümde reklam, satın alma, paylaşım ve derin bağlantı için aşağıda adı geçen Android eklentileri kullanılabilir. Bu eklentiler **Android Gradle build** ister; bunu kur. Masaüstünde ve editörde eklentiler yokken her şey **sahte (fake) servislerle** çalışmaya devam etmeli.

---

## 9.1 Böcek animasyonu: gövde sabit, uzuvlar canlı (9A)

### Kural: gövde sallanmaz
- Uçarken gövde **öne arkaya dönmez, salınım yapmaz.** Hıza bağlı rotasyon kodu (yükselirken −25°, düşerken +70°) tamamen kaldırılır. `GameConfig.BODY_TILT_MAX = 0.0` olsun (ileride istersem 3–4° yaparım).
- Gövdenin dönmesine yalnızca **ölüm animasyonunda** izin var.
- Hareketin canlılığını **kanatlar, kafa, antenler, kollar, gözler ve ağız** verir.

### Parçalı (cutout) karakter yapısı
Her karakter tek bir sprite yerine parçalardan oluşan bir `Node2D` ağacıdır. Her parçanın kendi pivotu vardır.

```
CharacterRig (Node2D)
├── KanatArka_Sol / KanatArka_Sag   (zar kanatlar, yarı saydam)
├── KanatOn_Sol / KanatOn_Sag       (sert dış kanatlar)
├── Bacaklar (3 adet görünen bacak)
├── Govde
├── KolArka
├── Kafa
│   ├── Anten_Sol / Anten_Sag
│   ├── Gozler (Goz_Sol, Goz_Sag, her birinde Bebek)
│   ├── Agiz
│   └── KafaAksesuar   (gözlük, kasket vb.)
├── KolOn
└── GovdeAksesuar      (önlük, mendil, kravat vb.)
```

**Görseller:** `res://assets/sprites/chars/<char_id>/` altında
`govde.png, kafa.png, anten.png, kanat_on.png, kanat_arka.png, kol.png, bacak.png, goz.png, goz_bebek.png, agiz_kapali.png, agiz_acik.png, kafa_aksesuar.png, govde_aksesuar.png`.
- Parça dosyaları yoksa ama eski tek parça `char_<id>.png` varsa: gövde/kafa yerine o tek görsel kullanılır; kanat, anten, göz ve ağız yine kodla çizilen yedek parçalarla üstüne eklenir. Böylece eski görsellerle de animasyon çalışır.
- Hiçbir dosya yoksa: tüm parçalar pastel yedek şekillerle çizilir (elips gövde, daire kafa, ince çizgi antenler, yarı saydam oval kanatlar).
- Parça boyutları ve pivot noktaları `CharacterData` içindeki `rig` sözlüğünde tanımlanır. Karakter görsellerinin nasıl hazırlanacağını anlatan `res://assets/sprites/chars/PARCA_REHBERI.md` dosyasını da yaz: her parçanın beklenen boyutu, pivot noktası ve örnek yerleşim.

### Animasyonlar (`AnimationPlayer`, karakter başına aynı isimler)
| Ad | Ne zaman | Ne olur |
|---|---|---|
| `hover` | Sürekli (zıplama arasında) | Arka kanatlar çok hızlı titrer (2 kare arası geçiş + hafif iz/ghost efekti), ön kanatlar hafif açık durur, antenler yaylanır, kollar hafifçe "kürek çeker". |
| `flap` | Her dokunuşta (0.14 sn) | Kanatlar büyük bir vuruş yapar, kollar aşağı iner, kafa hafifçe yukarı kalkar. Gövdede yalnızca dikey ±%4 squash/stretch olur, **dönme yok**. |
| `fall` | Düşüş hızı yüksekken | Kollar havaya kalkar ("panik"), gözler büyür, antenler geriye yatar, ağız açılır. |
| `near_miss` | Yakın kaçışta | Kafa kısa süre engele döner, göz kırpar veya dil çıkarır (karaktere göre). |
| `talk` | Balon açıkken | Ağız açılıp kapanır (`agiz_acik` / `agiz_kapali`, 8–10 Hz). |
| `ability_1`, `ability_2` | Yetenek kullanılınca | Karaktere özel poz (Diva saç savurur, Duktur steteskop sallar, Halay Başı mendil sallar…). |
| `taunt` | Laf/sataşma gönderince | Kol sallama, kafa sallama. |
| `win` | Kazanınca / Zafer Turu | Halay adımı veya zıplama dansı. |
| `death` | Ölünce | Gövde döner, gözler "X" olur, bacaklar havada titrer (klasik ters dönmüş böcek pozu), aşağı düşer. |
| `idle_menu` | Menüde ve seçim ekranında | Yerinde durur, etrafa bakınır, ara sıra anteniyle kafasını kaşır. |

### İkincil hareketler (kodla, her karede)
- **Antenler:** basit sönümlü yay fiziği. Böcek zıplayınca geriye yatar, sonra salınarak geri döner.
- **Göz kırpma:** 2–5 sn'de bir rastgele (görsel RNG, oyun seed'inden bağımsız).
- **Göz bebekleri:** en yakın tehlikeye (engel/füze) doğru en fazla 4 px kayar. Böcek tehlikeye "bakar".
- **Kanat izleri:** hover sırasında arka kanatların 2 soluk kopyası (motion blur hissi).

### Engel ve sahne animasyonları
- İnsan engelleri: anne eli terliği sallar (bekleme pozu ve tehdit pozu), sandalyedeki amcanın dizleri titrer; böcek yaklaşınca ağzı açılır ve çığlık atar. Çığlık yakın kaçışta daha büyük olur.
- Böcek ilacı bulutu "puf" diye büyür ve dalgalanır. Dolap kapağı menteşesinden açılır.
- Toz/kırıntı parçacıkları: kanat çırpınca minik toz (`CPUParticles2D`, düşük sayı), yakın kaçışta ter damlası.
- Sahne geçişleri: 0.25 sn kararıp açılma.
- Performans: 60 FPS hedef. Orta seviye bir Android telefonda 5 oyuncu ve 3 füze aynı anda ekrandayken FPS 50'nin altına düşmemeli. Parçacık sayılarını `GameConfig`'den düşür.

---

## 9.2 Ekran uyumu: her telefonda tam ekran, altta boşluk yok (9A)

**Sorun:** Bazı telefonlarda ekranın altında boş şerit kalıyor.

**Çözüm ilkeleri:**
1. `stretch/aspect = expand` kalır. Ancak hiçbir öğe sabit `y = 1280`'e göre konumlanmaz. Her şey görünür alana göre hesaplanır: `get_viewport().get_visible_rect()`.
2. **Oyun alanı (çarpışma bandı) her cihazda aynı yüksekliktedir:** `GameConfig.PLAY_HEIGHT` (ör. 1100 px). Çok oyunculuda adalet bozulmasın diye engel ve gap koordinatları bu banda göre hesaplanır. Bant görünür alanda dikey olarak yerleşir.
3. **Fazla dikey alan dekor ve kontrollere gider:**
   - Üstte tavan ve dolap dekoru uzar.
   - Altta tezgâh şeridi uzar; yetenek butonları ve tepsi büyür (uzun telefonlarda daha rahat basılır).
   - Arka plan "cover" mantığıyla ölçeklenir: en-boy oranı korunur, ekranı tamamen doldurur, taşan kısım kırpılır.
4. **Genişlik farkı:** Daha geniş ekranlarda engeller görünür alanın sağ kenarına göre daha erken oluşturulur (`spawn_x = visible_rect.end.x + 200`). Oyun alanı genişliği farklı olsa da dünya koordinatları değişmez.
5. **Güvenli alan:** `DisplayServer.get_display_safe_area()` ile çentik, kamera deliği ve alttaki hareket çubuğu hesaba katılır. HUD, butonlar ve tepsi güvenli alanın içinde kalır; arka plan ise güvenli alanın dışına kadar uzanır (kenardan kenara).
6. **Android tam ekran:** Gezinme çubuğu gizlenir (Godot sürümüne göre export'ta *Immersive Mode* ya da `display/window/size/mode = fullscreen`). Uygulama arka plandan dönünce tam ekran yeniden uygulanır.
7. Ekran boyutu değişince (`get_viewport().size_changed`) tüm yerleşim yeniden hesaplanır.

**Test:** Editörde pencere boyutunu şu oranlarla dene ve her birinin ekran görüntüsünü `res://test_screens/` altına kaydet: 9:16 (720x1280), 9:19.5 (720x1560), 9:20 (720x1600), 9:21 (720x1680), 3:4 tablet (960x1280). Hiçbirinde boş şerit, kesik buton ya da güvenli alana taşan HUD olmamalı. `GameConfig.DEBUG` açıkken F9 tuşu bu boyutlar arasında geçiş yapsın.

---

## 9.3 Kontroller: oyun sırasında yetenek kullanmak kolay olsun (9A)

**Sorun:** Uçmak için sürekli dokunurken küçük butonlara basmak zor.

### Yeni varsayılan kontrol: "Dokun ve Kaydır"
- **Ekranın herhangi bir yerine dokunmak = uç.** Zıplama dokunma *başladığı anda* olur, gecikme yok.
- **Aynı dokunuşla yukarı kaydırmak (≥ 70 px, 250 ms içinde) = Aktif 1.**
- **Aşağı kaydırmak = Aktif 2 (küçülme).**
- **İki parmakla aynı anda dokunmak = tepsideki en soldaki güçlendirmeyi kullan.**
- Kaydırma yetenek tetiklediğinde, o dokunuşun başında yapılan zıplama geri alınmaz (doğal hissettirir). İsteğe bağlı olarak `GameConfig.SWIPE_CANCELS_FLAP` ile bu davranış değiştirilebilir.
- Kaydırma algılanınca ekranda kısa bir ok izi belirir. Oyuncu ne yaptığını görür.

### Butonlar da kalsın ama büyüsün
- Yetenek butonları en az **160 px** (uzun ekranlarda 190 px'e kadar). Dokunma alanı görselden %25 daha büyük.
- Yetenek hazır olduğunda buton nabız gibi parlar ve kısa bir titreşim verir (`Input.vibrate_handheld(20)`, ayarlardan kapatılabilir).
- **Girdi tamponu:** Bekleme süresinin bitmesine 0.2 sn kala basılan yetenek, süre dolunca otomatik tetiklenir.
- Bekleme halkası kalın ve kontrastlı olsun; kalan saniye büyük yazılsın.

### Ayarlar → Kontroller
- Kontrol şeması: **Dokun ve Kaydır** (varsayılan) / **Sadece Butonlar**
- **Solak modu:** yetenek butonları sola, tepsi sağa geçer.
- Buton boyutu kaydırıcısı (%80–%130)
- Titreşim aç/kapat
- **Yardımcı Mod** (yalnızca tek oyunculu): Diva kalkanı ve Klasik Ani Fren, bekleme süresi dolmuşsa çarpışmadan 0.15 sn önce otomatik tetiklenir. Çok oyunculuda bu seçenek görünmez.

### Rehber güncellemesi
Faz 8.5'teki "Nasıl Oynanır?" rehberine **"Kontroller"** sayfası eklenir (2. sıraya): dokun = uç, yukarı kaydır = yetenek, aşağı kaydır = küçül, iki parmak = güçlendirme. Kaydırmayı gösteren küçük bir el animasyonu olsun. Oyuncu bu sayfada kaydırmayı **deneyebilsin** (sayfa üzerinde mini deneme alanı).

---

## 9.4 Yeni karakterler, Kırıntı ekonomisi, reklam ve satın alma (9C)

### İlke: para gücü satın almaz
- Çok oyunculuda **ödeme ile güç avantajı yoktur.** Yeni karakterler mevcutlardan güçlü değil, farklıdır (yan seçenek). Kostümler yalnızca kozmetiktir.
- Mevcut 4 karakter (Klasik, Diva, Duktur, Halay Başı) **ücretsiz ve açık** kalır.

### Kırıntı (oyun içi para)
- Kazanım: geçilen engel başına 1, her "Ödü Kopan İnsan" için +1, çok oyunculuda sıralamaya göre +30/+20/+12/+6/+3, günlük ilk giriş +25.
- Maç sonu: **"Reklam izle, Kırıntıyı 2 katına çıkar"** butonu (ödüllü reklam, kullanıcı basarsa).
- Kayıt: `user://save.cfg`. Kırıntı, açılan karakterler, kostümler, satın alımlar burada tutulur.

### Yeni karakterler
Her biri 1 pasif + 2 aktif (2. aktif küçülme) yapısındadır ve Faz 8.3'teki kurallara uyar. Hepsi `CharacterData`'ya eklenir, rig ve yedek görselleri vardır.

| id | Ad / görünüş | Pasif | Aktif 1 | Aktif 2 (küçülme) | Fiyat |
|---|---|---|---|---|---|
| `plaza` | **Plaza Böceği** (gömlek, kravat, yaka kartı) | **Excel Gözü:** güçlendirme kutularını 1 sn önce parlak görür, mıknatıs menzili +%30. | **Hücreyi Genişlet** (14 sn): önündeki ilk engel çiftinin gap'i yerelde %30 açılır. Replik: *"Bunu Excel'e sığdırırız."* | **Kompakt Mod** `0.65`, 2.5 sn. *"Toplantıya sığarım."* | 2500 Kırıntı |
| `usta` | **Sanayi Ustası** (tulum, İngiliz anahtarı) | **Usta Eli:** Yedek Bacak güçlendirmesinden 2 tane taşıyabilir. | **Motor İnecek** (14 sn): ileri bir İngiliz anahtarı fırlatır, önündeki ilk engeli söker (yerel). *"Abi motor inecek."* | **Kaportanın Altı** `0.6`, 2.5 sn. *"Altına bi bakayım."* | 2500 Kırıntı |
| `emlakci` | **Emlakçı Böcek** (takım elbise, anahtar demeti) | **Komisyon:** maç sonu Kırıntı kazancı +%20 (yalnızca ekonomi, oyun avantajı değil). | **Daireyi Gezdir** (16 sn): 0.3 sn'lik ışınlanma efektiyle en yakın gap'in ortasına geçer. *"Bakın burası güney cephe."* | **Stüdyo Daire** `0.55`, 2.5 sn. *"1+0'a da sığarım."* | 3000 Kırıntı |
| `siber` | **Siber Böcek** (sırt pili, LED antenler, metal bacaklar) | **Pil Tasarrufu:** tüm bekleme süreleri %15 kısa. | **Uzaktan Kumanda** (15 sn, 3 sn): bu sürede zıplama yerine dokunduğun yüksekliğe yumuşakça süzülür. *"Bağlantı kuruldu."* | **Mikro Mod** `0.5`, 2 sn. *"Boyut optimize edildi."* | 3500 Kırıntı |
| `yurt` | **Yurt Böceği** (pijama, kulaklık) | **Alıştık:** böcek ilacı bulutu ve Kirli Çorap ona etki etmez. | **Oda Arkadaşı** (16 sn): 4 sn yanında minik bir böcek uçar; ilk ölümcül çarpışmayı o üstlenir. *"Kanka sen al bunu."* | **Ranzaya Saklan** `0.6`, 2.5 sn. *"Yoklama mı var?"* | 3000 Kırıntı |
| `dayi` | **Kahvehane Dayısı** (kasket, tespih, çay bardağı) | **Tecrübe:** yakın kaçış mesafesi onun için +6 px geniş sayılır (daha çok "Ödü Kopan"). | **Çay Molası** (14 sn): 2 sn boyunca olduğu yükseklikte sabit süzülür (yerçekimi 0, zıplama kapalı). *"Bi çay söyle evladım."* | **Tabureye Sığ** `0.65`, 2.5 sn. *"Yer var, yer var."* | 2500 Kırıntı |
| `taraftar` | **Taraftar Böcek** (forma, atkı; takım adı ve logosu **yok**, sadece renkler) | **Tribün:** her elenen rakip için yetenek bekleme süreleri 3 sn kısalır. | **Frikik** (15 sn): 1.2 sn top gibi ileri şutlanır, ilk engeli delip geçer. *"Doksana!"* | **Baraj** `0.6`, 2.5 sn. *"Barajı kurdum."* | 3000 Kırıntı |

- Gerçek marka, takım logosu, kişi adı veya yüzü kullanılmaz.
- **Kostümler:** her karaktere 2 kostüm (yalnızca renk/aksesuar değişimi), 600 Kırıntı veya ödemeyle.

### Kilit açma yolları
1. **Kırıntı ile satın al.**
2. **Reklam izle, 1 maç dene:** kilitli karakter kartında "Reklam izle, bu maçta dene" butonu. Ödüllü reklam tamamlanınca karakter yalnızca bir sonraki maç için açılır.
3. **Gerçek parayla:** "Böcek Paketi" (tüm yeni karakterler), "Kırıntı Kesesi" (tüketilebilir), "Reklamsız" (geçiş reklamlarını kaldırır; ödüllü reklamlar isteğe bağlı kalır).

### Mağaza ekranı: "Böcek Pazarı"
- Ana menüde buton. Sekmeler: **Böcekler**, **Kostümler**, **Paketler**.
- Kilitli kartlarda gri silüet ve kilit ikonu. Karta dokununca Yetenekler ekranı (8.4) açılır, altında satın alma ve "1 maç dene" butonları görünür.
- Üst köşede Kırıntı sayacı. Satın alınca konfeti ve karakterin dokunma sesi (9.6).
- "Satın Alımları Geri Yükle" butonu.

### Teknik yapı
- `res://autoload/Monetization.gd` iki arayüz kullanır: `AdsService` ve `StoreService`.
  - Android'de: AdMob için **Poing Studios "AdMob" eklentisi** (Godot Asset Library) ve satın alma için Godot'un resmi **GodotGooglePlayBilling** eklentisi.
  - Editör/masaüstünde: `FakeAdsService` (3 sn bekleyip "ödül kazanıldı" der) ve `FakeStoreService` (anında başarılı satın alma). Oyun mantığı hangi servisin çalıştığını bilmez.
- **Reklam kuralları:**
  - Ödüllü reklam **asla otomatik açılmaz**; yalnızca oyuncu butona basınca. Ödül yalnızca "kullanıcı ödülü kazandı" sinyalinde verilir.
  - Geçiş reklamı: yalnızca maç sonu sıralama ekranından **çıkarken**, en fazla 3 maçta bir, "Reklamsız" alındıysa hiç. Çok oyunculu lobi geri sayımında, oyun sırasında, ilk 2 maçta asla gösterilmez.
  - Banner reklam yok (oyun alanını daraltır).
  - Reklam yüklenemezse buton "Reklam şu an yok" der ve devre dışı kalır; oyun asla reklam bekleyerek takılmaz.
  - Google'ın **test reklam kimlikleri** `GameConfig` içinde kullanılır; gerçek kimlikler için `ADMOB_APP_ID`, `REWARDED_ID`, `INTERSTITIAL_ID` sabitleri boş bırakılır ve yorumda "yayından önce doldur" yazar.
  - AB/KVKK kullanıcı onayı için eklentinin UMP (kullanıcı mesajları) desteği ilk açılışta çalıştırılır.
- **Satın alma kuralları:**
  - Ürün kimlikleri `GameConfig`'de: `paket_bocekler`, `kirinti_kesesi_kucuk`, `kirinti_kesesi_buyuk`, `reklamsiz`.
  - Tüketilebilirler (`kirinti_*`) `consume`, kalıcılar `acknowledge` edilir. **3 gün içinde onaylanmayan satın alımı Google iade eder**; bu yüzden onay her açılışta da kontrol edilir.
  - Açılışta `query_purchases` ile kalıcı satın alımlar geri yüklenir.
  - "Bekleyen" (pending) satın alımlar için "Ödeme onay bekliyor" mesajı gösterilir.
- **Yaş/içerik:** Oyun argo içerdiği için çocuklara yönelik değildir; mağaza açıklaması ve içerik derecelendirmesi buna göre yapılacak. Kodda "çocuklara yönelik" reklam ayarı açılmaz.

---

## 9.5 Paylaş ve davet et (9D)

### Oda daveti
- Oda kurulunca lobide büyük **"Arkadaşını Davet Et"** butonu. Android paylaşım menüsünü açar (WhatsApp, Telegram vb.). Eklenti: **godot-share** (Android Share Plugin).
- Paylaşılan metin:
  `Mutfakta yer açtım! Uçan Hamam Böceği odama gel. Oda kodu: KTRB  https://<SITE>/oda.html?k=KTRB`
- Çevrimiçi odalarda bağlantı çalışır. LAN odalarında bağlantı yerine şu metin paylaşılır: "Aynı Wi-Fi'ye bağlan, 'Arkadaşlarla' ekranında odamı göreceksin."

### Bağlantı oyunu açsın (derin bağlantı)
- Oyun `ucanbocek://oda/KTRB` şemasını dinler (eklenti: **godot-deeplink**). Bu bağlantıyla açılınca doğrudan çevrimiçi "Kodla Katıl" akışı KTRB koduyla başlar (isim kayıtlıysa onay bile sorma).
- WhatsApp özel şemalı bağlantıları tıklanabilir yapmadığı için, paylaşılan bağlantı küçük bir **web sayfasına** gider. Ajan bu sayfayı da hazırlasın: `res://web/oda.html` (tek dosya, pastel, oyunun logosuyla):
  - Sayfa açılınca `intent://oda/<KOD>#Intent;scheme=ucanbocek;package=<PAKET_ADI>;end` ile oyunu açmayı dener.
  - Altında büyük "Oyunu Aç" butonu, kod büyük harflerle ve "Oyun yüklü değil mi? İndir" bağlantısı (Play Store veya APK adresi, `oda.html` başındaki sabitten).
  - `web/README.md`: bu sayfanın GitHub Pages'te ücretsiz nasıl yayınlanacağı, adım adım.
- `GameConfig.SHARE_SITE_URL` ve `ANDROID_PACKAGE_NAME` sabitleri.

### Sonuç ve skor paylaşımı
- Sıralama ekranında ve tek oyunculu ölüm ekranında **"Paylaş"** butonu.
- Ekranın o anki görüntüsü (`get_viewport().get_texture().get_image()`) üstüne küçük bir oyun logosu ve bağlantı yazısı eklenip `user://paylas.png` olarak kaydedilir ve görsel + metin olarak paylaşılır.
- Metin şablonları (`GameConfig`), örnek:
  - "Mahallenin Kralı oldum! {n} kişiyi sandalyeye çıkardım. Sıra sende: {link}"
  - "Günün Mutfağı'nda {skor} engel geçtim. Sen kaç geçersin? {link}"
- Eklenti yoksa (masaüstü) metin panoya kopyalanır ve "Panoya kopyalandı" yazar.

---

## 9.6 Karakterlerin kendi sesleri, dokununca konuşsunlar (9B)

### Dokununca ses
- Ana menüdeki böceğe, karakter seçim kartlarına, Yetenekler ekranındaki büyük görsele ve lobideki kendi kartına **dokununca** karakter kendine özgü bir laf söyler: ses + balon + `talk` ve küçük bir zıplama/kanat açma animasyonu.
- Her karakterin 3 dokunma lafı vardır, sırayla değil rastgele çalar (aynı laf art arda gelmez).
- **Dürtme şakası:** 1.5 sn içinde 3. dokunuşta sinirli bir laf ("Dürtme beni!"). 10. dokunuşta böcek "Tamam, ben kaçtım!" deyip ekrandan uçarak çıkar ve 2 sn sonra geri gelir.

### Ses dosyası düzeni
`res://assets/sounds/chars/<char_id>/` altında:
`dokun_1.ogg, dokun_2.ogg, dokun_3.ogg, durtme.ogg, kactim.ogg, yetenek_1.ogg, yetenek_2.ogg, olum.ogg, kazanma.ogg, laf.ogg`
- Her dosya yoksa sessizce geçilir; balon yine görünür.
- Varsa karakterin kendi `olum.ogg`'si ölüm müziğinden 0.2 sn önce kısa çalar; `kazanma.ogg` sevinç sesinin üstüne biner.

### Örnek laflar (CharacterData'ya `tap_lines`, `poke_line`, `flee_line` olarak)
| Karakter | Dokunma lafları |
|---|---|
| Klasik | "Efendim?" · "Ben buranın eskisiyim." · "Işığı kapat, utanıyorum." |
| Diva | "Ayy dokunma, ojem yeni!" · "Fotoğrafım çekilecekse önce haber verin." · "Bu mutfak bana küçük." |
| Duktur | "Ağzını aç, aaa de." · "Bu kırıntı çok yağlı." · "Randevun var mıydı?" |
| Halay Başı | "Hadi kalk, halaya!" · "Mendil nerde mendil?" · "Davulcu nerde kaldı?" |
| Plaza | "Toplantıdayım, sonra dönerim." · "Bunu mail atar mısın?" · "Cuma'ya yetiştiririz." |
| Usta | "Abi motor inecek." · "Bir kahve koy, bakarız." · "Bu orijinal parça değil." |
| Emlakçı | "Depozito iki kira." · "Metroya yürüme mesafesi." · "Lavabo altı, ferah daire." |
| Siber | "Sistem başlatıldı." · "Şarjım yüzde on beş." · "Güncelleme var, yükleyeyim mi?" |
| Yurt | "Yemekhane açık mı?" · "Oda arkadaşım yine yok." · "Yoklamaya beni de yaz." |
| Dayı | "Bir çay söyle evladım." · "Bizim zamanımızda terlik yoktu." · "Okey dördüncüsü lazım." |
| Taraftar | "Bu sene bizim sene!" · "Hakem kör mü?" · "Doksana takarım!" |

### Böcek sesi efekti
- `AudioManager`'a `Voice` bus'ı eklenir; üzerinde `AudioEffectPitchShift` (tempo bozulmadan ses inceltir) ve hafif `AudioEffectCompressor` + `AudioEffectEQ` (orta frekansları öne çıkarır, sesin "telefonda daha dolgun" duyulması için).
- `CharacterData`'ya `voice_pitch` alanı: Klasik 1.15, Diva 1.3, Duktur 1.05, Halay Başı 1.1, Siber 0.95 (+ hafif `AudioEffectDistortion`), diğerleri 1.1–1.2.
- Böylece kullanıcı kendi sesini normal kaydedip koyabilir; oyun bunu otomatik olarak "böcek sesine" çevirir.
- Tüm karakter sesleri `Voice` bus'ından geçer. Ayarlarda ayrı **"Böcek Sesleri"** ses seviyesi kaydırıcısı olur.

---

## 9.7 Gündem etkinlikleri (opsiyonel, 9D ile birlikte)

Mizah gündemi hızlı değiştiği için uygulama güncellemeden yeni içerik eklenebilsin:
- Eşleştirici sunucu `{"op":"get_event"}` isteğine haftalık etkinlik JSON'u döner (`server/events.json` dosyasından okunur, sunucu yeniden başlatılmadan değiştirilebilir):
  `{"id":"fatura_gunu","title":"Ayın 15'i: Fatura Günü","banner":"Faturalar geldi, kaçın!","start":"2026-12-01","end":"2026-12-07","skin_tint":"#F2C9A9","obstacle_variant":"fatura","bonus_kirinti":1.5}`
- Etkinlik varsa ana menüde şerit görünür, belirtilen sürede engel varyantı (görseli `res://assets/sprites/events/<variant>/`) ve Kırıntı bonusu uygulanır. Etkinlik varyantları önceden oyuna eklenmiş görsellerden seçilir; sunucu yalnızca hangisinin açık olduğunu söyler.
- Sunucuya ulaşılamazsa etkinlik yokmuş gibi davranılır.

---

## Bitti sayılması için

**9A**
- [ ] Uçarken gövde hiç dönmüyor; kanat, anten, kol, göz ve ağız animasyonları akıcı; ölümde böcek ters dönüyor.
- [ ] Parça görselleri yokken yedek parçalarla, eski tek parça görsel varken onunla animasyon çalışıyor; `PARCA_REHBERI.md` yazıldı.
- [ ] 5 farklı ekran oranında altta veya üstte boş şerit yok; HUD güvenli alanda; oyun alanı yüksekliği tüm oranlarda aynı.
- [ ] Dokun = uç, yukarı kaydır = Aktif 1, aşağı kaydır = Aktif 2, iki parmak = güçlendirme çalışıyor; butonlar büyük; solak modu ve buton boyutu ayarı çalışıyor; rehberde kontroller sayfası var.

**9B**
- [ ] Menüde, seçim kartlarında, Yetenekler ekranında ve lobide karaktere dokununca kendi lafı ses + balon + animasyonla geliyor; dürtme ve kaçma şakası çalışıyor.
- [ ] `Voice` bus'ı ve karakter başına `voice_pitch` uygulanıyor; ses dosyaları yokken hata yok.

**9C**
- [ ] 7 yeni karakter yeteneğiyle birlikte çalışıyor; kilitli olanlar mağazada görünüyor.
- [ ] Kırıntı kazanılıyor, harcanıyor ve kaydediliyor; "1 maç dene" yalnızca bir maç geçerli.
- [ ] Editörde sahte servislerle tüm satın alma ve ödüllü reklam akışları uçtan uca test edilebiliyor; ödüllü reklam hiçbir yerde otomatik açılmıyor; geçiş reklamı yalnızca kurala uygun anda çıkıyor.
- [ ] Android build'de test reklam kimlikleriyle ödüllü reklam açılıyor (gerçek cihazda test).

**9D**
- [ ] Lobide "Arkadaşını Davet Et" Android paylaşım menüsünü açıyor; `oda.html` sayfası hazır ve README'si yazıldı.
- [ ] `ucanbocek://oda/KTRB` bağlantısı oyunu açıp doğrudan odaya bağlanıyor.
- [ ] Sonuç ve skor paylaşımı görsel + metinle çalışıyor; masaüstünde panoya kopyalıyor.
- [ ] (Opsiyonel) `events.json` değişince ana menüde etkinlik şeridi beliriyor.

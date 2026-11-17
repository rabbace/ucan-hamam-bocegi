# UÇAN HAMAM BÖCEĞİ — Faz 11: Botlar, Rövanş, Ölüm Karesi, Görevler, Albüm, Ani Olaylar, Ses Kaydı

> **Ajan için:** Önceki tüm prompt dosyalarının (PROMPT.md, FAZ6_7, FAZ8, FAZ9, FAZ10) devamıdır. **GENEL KURALLAR** aynen geçerlidir (statik tip, eksiksiz dosya, sayılar `GameConfig`'de, global `randi()` yasak, deterministik dünya, pastel stil, güvenli yükleme, oyun içi yazıda emoji yok).
>
> Alt fazlar halinde, sırayla uygula ve her birinin sonunda test et:
> **11A** Botlar + Rövanş → **11B** Ölüm Karesi + Günlük Görevler → **11C** Mahalle Albümü + Ani Olaylar → **11D** Kendi Lafını Kaydet.

---

## 11.1 Bot oyuncular (11A)

**Amaç:** Çevrimiçi Hızlı Oyun hiç boş kalmasın. Arkadaş yokken de "kalabalık maç" hissi olsun.

### Deterministik bot mantığı
Botlar ağ üzerinden pozisyon göndermez. Her cihaz botları **seed'den aynı şekilde hesaplar**:
- Her botun kendi RNG'si vardır: `RandomNumberGenerator`, seed = `world_seed ^ (bot_index * 7919)`.
- **Botun öleceği engel önceden belirlenir:** Bot her engel çiftinde `fail_chance(seviye, beceri)` olasılığıyla "başarısız" olur. İlk başarısız olduğu engel indeksi = ölüm anı. Bu hesap maç başında yapılır; herkeste sonuç aynıdır.
- **Botun hareketi** yalnızca görseldir: gap merkezleri arasında, flappy fiziğini taklit eden yumuşak bir yol izler (seed'li küçük sapmalarla, ara sıra yakın kaçış yapar). Ölüm engeline geldiğinde o engele çarpacak şekilde yolu sapar ve Faz 8'deki ölüm akışı oynar.
- Bot ölüm zamanı = o engelin dünya mesafesine ulaşılan `match_time`. Sunucu/Host bu hesabı `ObstacleTimeline` ile kendisi de yapar. Sıralama, ölüm akışı ve "Hayatta Kalan" sayacı botları içerir.
- Botlar yeteneklerini ve imza ödüllerini seed'li zamanlarda **görsel olarak** kullanır (balon, efekt). Bunlar botun ölüm anını değiştirmez.
- **Bot sataşması:** Otorite (sunucu ya da LAN Host'u) seed'li zamanlarda, bot başına en fazla 20 sn'de bir, hayattaki gerçek oyunculardan birine sataşma gönderir. Normal 0.6 sn uyarı ve bağışıklık kuralları geçerlidir. Bot da sataşırken "Özür dilerim pıttığım" der.
- **Botlar laf atar:** Seed'li aralıklarla hazır laf havuzundan.

### Beceri seviyeleri
| Seviye | Ortalama hayatta kalma | Kullanım |
|---|---|---|
| Acemi | Sv 1–2 | Yeni oyuncu (ilk 5 maç) |
| Mahalleli | Sv 2–4 | Varsayılan |
| Usta | Sv 4–6 | Oyuncunun son 5 maç ortalaması yüksekse |

Hızlı Oyun'da botların becerisi, odadaki gerçek oyuncuların son 5 maç ortalamasına göre karışık seçilir (kolay maç → biraz daha zor bot). Gerçek oyuncu her zaman en az ara sıra kazanabilmeli: ilk 3 maçta botlar en geç Sv 3'te ölür.

### Nerede botlar var
- **Hızlı Oyun:** 15 sn içinde oda 5 kişiye dolmazsa ve en az 1 gerçek oyuncu varsa, oda botlarla 4'e tamamlanır ve maç başlar. Maç başlamadan gerçek biri gelirse bir botun yerini alır.
- **Özel oda ve LAN:** Oda sahibinde **"Bot Ekle / Çıkar"** butonu (0–4 bot, seviye seçilebilir).
- **Tek oyunculu menüde yeni mod: "Botlarla Oyna":** internet gerekmez, 1–4 bot, seviye seçimi. Sıralama ekranı, sataşma ve rövanş burada da çalışır.

### Görünüm
- Bot isimleri komik bir havuzdan (`GameConfig.BOT_NAMES`): "Komşu Remzi", "Kapıcı Böcek", "Lavabo Altı Ferit", "Bakkal Şükrü'nün Böceği", "Gece Vardiyası", "Kırıntı Avcısı", "Kalorifer Kaçkını", "Buzdolabı Arkası", "Çöp Kovası Sakini", "Teyze'nin Kâbusu".
- Bot karakterleri tüm karakterlerden rastgele seçilir (kilit gerektirmez, sadece görüntü).
- Bot isim etiketinin yanında küçük bir "BOT" rozeti olur (dürüst olsun, oyuncu kandırılmasın).
- Botlar Kırıntı kazanmaz, albüm/görev ilerletmez, sıralamada puan alır ama lobideki oturum tablosunda gri görünür.

---

## 11.2 Rövanş (11A)

### Çok oyunculu
- Sıralama ekranında **herkeste** büyük **"RÖVANŞ!"** butonu. Basan oyuncunun portresi "ciddi" ifadeye geçer ve balonda *"Bi daha!"* yazar.
- Ekranda sayaç: "Rövanş: 3 / 4". Botlar otomatik kabul eder.
- Tüm gerçek oyuncular kabul edince **lobiye dönmeden** 2 sn sonra yeni maç başlar (yeni seed, aynı karakterler). Karakter değiştirmek isteyen "Lobiye Dön" seçer.
- 15 sn içinde herkes kabul etmezse oda sahibine "Kabul edenlerle başlat" ve "Lobiye Dön" seçenekleri çıkar. Hızlı Oyun'da 15 sn sonra kabul edenlerle otomatik başlar, eksikler botla tamamlanır.
- **Taht sistemi:** Son maçın kazananının hayaletinin üstünde küçük bir taç olur. Maç başında ekranda *"{isim}'i tahtından indirin!"* yazar. Üst üste 3 kez kazanana geçici unvan: **"Mahalle Muhtarı"** (taç büyür). Muhtarı eleyen oyuncuya ölüm akışında özel satır: *"{isim} muhtarı devirdi!"*

### Tek oyunculu
- Ölüm ekranında iki buton: **"Tekrar Dene"** (yeni seed) ve **"Aynı Parkur"** (aynı seed). Aynı parkurda önceki denemenin hayaleti (gri, yarı saydam, "Önceki sen" etiketi) da uçar. Rekor denemesi için çok bağımlılık yapan bir özellik.
- Hayalet için önceki denemenin Y pozisyonları 0.1 sn aralıkla kaydedilir (`user://son_deneme.dat`, sadece son deneme).

---

## 11.3 Ölüm Karesi: 3 kareli çizgi roman (11B)

**Amaç:** Her ölüm paylaşılabilir komik bir an olsun.

### Kareleri yakalama
- Yerel oyuncu hayattayken her 0.25 sn'de ekran görüntüsü alınır, 360x640'a küçültülür ve son 8 kare (2 sn) bir halka tamponda tutulur. Görüntüler yalnızca bellekte tutulur, diske yazılmaz.
- Ölüm anında (siyah-beyaz efektten **önce**) son bir kare daha alınır.
- Ayarlarda **"Ölüm Karesi"** kapatılabilir (zayıf telefonlar için). Kapalıysa yakalama yapılmaz.
- Performans: Yakalama mobilde 1 kareden uzun sürerse aralık otomatik 0.5 sn'ye çıkar.

### Çizgi roman düzeni (`SubViewport`, 1080x1350)
| Kare | İçerik | Yazı kutusu |
|---|---|---|
| 1 | Ölümden ~0.75 sn önceki kare | Üst köşede sarı anlatı kutusu: zamana göre değişen cümle, ör. *"Gece 03:12. Mutfak sessiz…"*, *"Her şey yolunda gidiyordu…"*, *"Rekor kapıdaydı…"* |
| 2 | Ölüm anı karesi, hafif yakınlaştırılmış ve eğik | Büyük ses efekti yazısı, ölüm sebebine göre: terlik → **"ŞAPP!"**, füze → **"BUMM!"**, zemin → **"PIRT!"**, tavan → **"DONK!"**, sürpriz engel → **"FIŞŞŞ!"**, hayalet terlik → **"İNTİKAM!"** |
| 3 | Karakterin sinirli büyük yüzü (Faz 10.3 portresi) | Konuşma balonunda karakterin sinir repliği |

- Kenarlarda kalın koyu çerçeve, kareler arası beyaz boşluk, arka planda soluk pastel nokta deseni (halftone).
- Altta şerit: oyun logosu, skor ("{n} kişiyi korkuttu"), paylaşım bağlantısı.
- Kareler hafif el çizimi hissi versin diye çerçeve çizgileri çok hafif düzensiz olsun (birkaç piksel oynayan köşe noktaları).

### Kullanım
- Ölüm ekranında ve çok oyunculu sıralama ekranında **"Ölüm Karesi"** butonu. Dokununca kart büyük önizleme olarak açılır. Altında **"Paylaş"** (Faz 9.5 paylaşım sistemi, görsel + metin) ve **"Kapat"** butonları.
- Kart `user://olum_karesi.png` olarak kaydedilir (sadece sonuncusu).
- Metin şablonu: *"Böyle öldüm. Sen daha iyisini yapabilir misin? {link}"*

---

## 11.4 Günlük görevler ve seri (11B)

### Günlük görevler
- Her gün 3 görev. Görevler tarihten üretilen seed ile seçilir, yani **herkes aynı gün aynı görevleri alır**; arkadaşlar konuşabilir.
- Görev havuzu (`GameConfig.DAILY_TASKS`, en az 25 görev; parametreli). Örnekler:
  - "Bir maçta {n} kişiyi korkut" (Ödü Kopan)
  - "{karakter} ile {n} kez küçül"
  - "{n} gizemli kutu topla"
  - "Füze yağmurundan {n} kez sağ çık"
  - "Seviye {n}'e ulaş"
  - "Bir maçta {n} kez sataşma gönder" (çok oyunculu veya Botlarla Oyna)
  - "Bir arkadaşını davet et"
  - "Ölüm Kareni paylaş"
  - "Yakın kaçışla x{n} kombo yap"
  - "Annem Geldi olayında yakalanma" (bkz. 11.6)
- Ödül: görev zorluğuna göre 30–80 Kırıntı. Üç görev de bitince **"Günün Sürprizi"**: Kırıntı veya bir kostüm parçası. Gerçek parayla satın alınamaz; olası içerikler ekranda yazar.
- Günde 1 kez, ödüllü reklam izleyerek bir görev değiştirilebilir (oyuncu isterse).
- Görev ilerlemesi maç içinde küçük bir bildirimle görünür: *"Görev: 7/10 kişi korkutuldu"*.

### Seri (her gün oyna)
- O gün en az 1 maç oynanırsa seri 1 artar. Günlük ödül takvimi 7 gün: 20 → 30 → 40 → 50 → 60 → 80 Kırıntı → 7. gün kostüm parçası. Sonra döngü baştan başlar ama seri sayısı artmaya devam eder.
- Bir gün kaçırılırsa seri sıfırlanır. Haftada 1 kez **"Seriyi Kurtar"** (ödüllü reklam, isteğe bağlı) ile sıfırlanma önlenebilir.
- Ana menüde alev yerine **kanat çırpan küçük bir böcek ikonu** ve yanında seri sayısı. Seri 7, 30, 100 olunca kutlama ekranı.
- Tarih cihazın yerel saatinden alınır.

### Görevler ekranı
Ana menüde **"Görevler"** butonu (bitmemiş görev varsa üstünde küçük nokta). Ekranda: 3 görev kartı (ilerleme çubuğu, ödül, "Al" butonu), seri takvimi, Günün Sürprizi kutusu.

---

## 11.5 Mahalle Albümü (11C)

### İnsan tipleri
Engellerdeki insanlar artık tek tip değil. Engel çiftinin üst ve alt insanı bir **varyant** listesinden seed ile seçilir (herkeste aynı). Seviye ilerledikçe yeni tipler havuza girer.

| id | Ad | İlk seviye | Albüm açıklaması (komik) |
|---|---|---|---|
| `anne` | Terlikli Anne | 1 | "Terliği fırlatmadan önce üç kez uyarır. Üçüncüde nişan alır." |
| `amca` | Sandalyedeki Amca | 1 | "Kırk yıldır bu sandalyede. Böcek görünce ilk kez kalktı." |
| `teyze` | Çığlıkçı Teyze | 2 | "Sesi üç apartman öteden duyulur." |
| `kapici` | Kapıcı Efendi | 2 | "Ekmekleri bırakır, böceği kovalar." |
| `misafir` | Misafir Teyze | 3 | "Tam kek yerken gördü. Kek de uçtu." |
| `ev_arkadasi` | Ev Arkadaşı | 3 | "Bulaşığı o yıkamadı, böcek de oradan geldi." |
| `kurye` | Kapıdaki Kurye | 3 | "Siparişi bıraktı, koşarak kaçtı." |
| `yonetici` | Apartman Yöneticisi | 4 | "Aidatı ödemeyen böceklere karşı." |
| `bakkal` | Bakkal Amca | 4 | "Veresiye defterine böceği de yazdı." |
| `kayinvalide` | Kayınvalide | 5 | "Böceği görünce gelinine baktı." |
| `belediye` | Belediye Görevlisi | 5 | "Elinde ilaç, gözünde intikam." |
| `muhtar` | Mahalle Muhtarı | 6 | "Mahalleyi böcekten temizleme sözü verdi. Seçim yakın." |

- Görseller: `res://assets/sprites/insanlar/<id>_ust.png` (yukarıdan uzanan kol/gövde) ve `<id>_alt.png` (aşağıda duran kişi). Yoksa her tip farklı renk, farklı aksesuar şekliyle (başörtüsü, kasket, önlük, kask) yedek çizilir. Faz 9.1'deki çığlık animasyonu tüm tiplerde çalışır.
- Her tipin kendi çığlık balon lafları olsun (`scream_lines`, 3'er tane).

### Albüm
- Bir insan tipini **ilk kez korkuttuğunda** (yakın kaçış) kartı açılır: ekranın üstünde *"Yeni komşu: Çığlıkçı Teyze!"*
- Kart seviyeleri, o tipi kaç kez korkuttuğuna göre: 1 → **Bronz**, 10 → **Gümüş**, 50 → **Altın** çerçeve (pastel tonlarda).
- Albüm ekranı (ana menüde **"Mahalle Albümü"**): 12 kartlık ızgara; kilitli kartlar silüet ve ipucu ("Seviye 4'te ortaya çıkar"). Karta dokununca büyür: görsel, ad, açıklama, korkutma sayısı ve kişinin çığlık sesi çalar.
- Tamamlama ödülleri: tüm kartlar bronz → 500 Kırıntı; tümü gümüş → özel kostüm; tümü altın → **"Mahallenin Kâbusu"** unvanı (isim etiketinin altında görünür).
- Botlarla Oyna ve çok oyunculu maçlarda da ilerler; botlar ilerletmez.

---

## 11.6 Ani olaylar (11C)

Olayların zamanı ve türü seed'den belirlenir (herkeste aynı). Kurallar: aynı anda tek olay; füze evresiyle çakışmaz; iki olay arası en az 45 sn; her olayın ilk görülüşünde tanıtım şeridi çıkar. `GameConfig.EVENTS` ile ayarlanır.

### "Annem Geldi!" (Seviye 3+)
1. **Uyarı (1.2 sn):** Anahtar şıngırtısı sesi, ekranın sol kenarından sızan sarı ışık şeridi, ortada *"ANAHTAR SESİ! KÜÇÜL!"* yazısı. Herkesin Aktif 2 (küçülme) yeteneğinin bekleme süresi **anında dolar**, buton parlar.
2. **Işık yandı (1.2 sn):** Ekran sıcak beyaz parlar (`CanvasModulate` + beyaz `ColorRect` %40).
3. Işık anında **küçülmüş değilse** ve kalkan/hayalet fazı yoksa böcek **"yakalanır"**: 1 sn donar (zıplayamaz, yerçekimi normal), üstünde *"Yakalandım!"* balonu. Donma ölüme yol açabilir ama olay kendisi öldürmez.
4. Yakalanmayanlara +1 kombo ve *"Sıvıştın!"* yazısı.

### "Belediye İlaçlıyor!" (patron anı, Seviye 5'e girerken ve sonra her 3 seviyede)
1. Siren sesi, ekranın altında tezgâh şeridi boyunca soldan sağa geçen bir **ilaçlama arabası** (yedek: pastel kamyonet şekli, üstünde dönen ışık).
2. 6 sn boyunca normal engeller durur. Yerine **5 sis duvarı** gelir: ekranı boydan boya kaplayan yeşil sis sütunları, her birinde bir geçiş deliği. Deliklerin yüksekliği seed'den. Her duvardan 0.9 sn önce delik yerinde yanıp sönen ok uyarısı.
3. Sis duvarına çarpmak öldürür (Diva kalkanı, Halay hayalet fazı ve Yurt Böceği'nin pasifi korur).
4. Atlatanlara +40 Kırıntı ve olay akışında *"{isim} belediyeyi atlattı!"*

### "Elektrik Kesildi!" (Seviye 4+)
1. Klik sesi, 6 sn boyunca ekran neredeyse tamamen kararır (füze evresinden daha koyu).
2. Sadece böceklerin gözleri parlar (her böceğin gözünde küçük `PointLight2D`) ve engellerin kenarlarında soluk bir kontur görünür.
3. Bu sırada engel aralıkları +40 px geniş gelir (adil olsun).
4. Işık gelince *"Elektrik geldi!"* yazısı ve buzdolabı motoru sesi.

### "Misafir Var!" (Seviye 2+)
1. Kapı zili sesi, 8 sn boyunca tüm insan engelleri "misafir kılığına" girer: üstlerinde küçük şapka ve fiyonk, ellerinde çay tepsisi.
2. Bu sürede **"Ödü Kopan" puanı ×2** ve kutu çıkma ihtimali ×1.5.
3. Misafir önünde rezil olmamak için ölen oyuncunun ölüm akışına ek: *"…hem de misafirin önünde!"*

### Rehber
"Nasıl Oynanır?" rehberine **"Ani Olaylar"** sayfası: 4 olayın her biri tek cümleyle ve küçük ikonla.

---

## 11.7 Kendi lafını kaydet (11D)

### Kayıt ekranı (Ayarlar → **"Benim Lafım"**)
- 3 ses yuvası: **Laf atma** (hazır laf menüsünde 8. seçenek olur), **Sataşma** ("Özür dilerim pıttığım" yerine çalar), **Zafer** (kazanınca çalar).
- Her yuvada büyük mikrofon butonu: **basılı tut = kaydet** (en fazla 2.0 sn). Kayıt sırasında canlı dalga formu çizilir.
- Kayıttan sonra otomatik: baştaki/sondaki sessizlik kırpılır, ses seviyesi normalize edilir.
- "Dinle" (ham) ve **"Böcek Sesiyle Dinle"** (seçili karakterin `voice_pitch` ve Voice bus filtresiyle) butonları. "Kaydet" ve "Sil".
- Teknik: `AudioStreamMicrophone` + `Mic` bus üzerinde `AudioEffectRecord`. Kayıt 16 kHz mono'ya indirilir, `user://benim_lafim_<yuva>.wav` olarak saklanır (`AudioStreamWAV.save_to_wav`).
- Android: `RECORD_AUDIO` izni export ayarına eklenir ve **yalnızca kullanıcı bu ekranda mikrofon butonuna ilk kez bastığında** istenir (`OS.request_permissions()`). İzin reddedilirse açıklayıcı mesaj gösterilir ve özellik devre dışı kalır; oyunun geri kalanı etkilenmez. Mikrofon başka hiçbir yerde açılmaz.

### Ağ üzerinden paylaşım (yalnızca arkadaş odaları)
- Özel sesler **yalnızca Özel Oda ve LAN odalarında** paylaşılır. **Hızlı Oyun'da asla gönderilmez ve çalınmaz** (yabancılarla kötüye kullanım olmasın).
- Gönderim lobide, oyuncu odaya katıldığında bir kez yapılır (maç sırasında değil): 11025 Hz, 16 bit PCM, `PackedByteArray.compress(FileAccess.COMPRESSION_ZSTD)`; yuva başına en fazla 48 KB. Sınırı aşan veri reddedilir.
- Alıcılar sesleri bellekte tutar, diske yazmaz. Ayrılmış sunucu yalnızca aktarır, **saklamaz ve kaydetmez**.
- Çalma: ses, gönderenin karakterinin böcek filtresinden geçer (Voice bus).

### Kontrol ve güvenlik
- Ayarlar: **"Arkadaşların özel seslerini çal"** aç/kapat.
- Oda sahibi lobide **"Özel sesler: Açık/Kapalı"** seçebilir.
- Lobide ve maç içi oyuncu kartında **"Bu oyuncuyu sustur"** (o oturum boyunca o kişinin özel sesleri ve lafları çalmaz/görünmez).
- **"Bildir"** butonu: oyuncu adını, oda kodunu ve sebebi (seçenekli) sunucuya gönderir; sunucu bunu `server/reports.log` dosyasına yazar. Ses verisi gönderilmez.
- Gizlilik politikasına eklenecek metin taslağını `web/gizlilik.html` içine yaz: mikrofonun yalnızca kullanıcı basılı tutarken açıldığı, kaydın cihazda saklandığı, yalnızca davet edilen oda üyelerine iletildiği ve sunucuda saklanmadığı.

---

## Bitti sayılması için

**11A**
- [ ] Hızlı Oyun 15 sn'de dolmayınca botlarla 4'e tamamlanıyor; botların ölüm anı tüm cihazlarda aynı; botlar sıralamada doğru yerde.
- [ ] Özel oda ve LAN'da "Bot Ekle" çalışıyor; tek oyunculu "Botlarla Oyna" internetsiz çalışıyor.
- [ ] Bot isim etiketinde "BOT" rozeti var; botlar Kırıntı/görev/albüm ilerletmiyor.
- [ ] Rövanş sayacı çalışıyor; herkes kabul edince lobisiz yeni maç başlıyor; taç ve Mahalle Muhtarı unvanı görünüyor.
- [ ] Tek oyunculuda "Aynı Parkur" önceki denemenin hayaletiyle çalışıyor.

**11B**
- [ ] Ölümde 3 kareli çizgi roman (önce / an / sinirli yüz) doğru ses efekti yazısıyla oluşuyor ve paylaşılabiliyor; ayardan kapatılabiliyor; orta seviye telefonda FPS düşüşü yok.
- [ ] Her gün 3 görev geliyor (aynı tarihte her cihazda aynı), ilerleme ve ödüller çalışıyor; seri takvimi ve "Seriyi Kurtar" çalışıyor.

**11C**
- [ ] 12 insan tipi seviyeye göre ortaya çıkıyor; ilk korkutmada kart açılıyor; bronz/gümüş/altın sayaçları ve tamamlama ödülleri çalışıyor.
- [ ] 4 ani olay seed'e göre herkeste aynı anda oluyor, çakışmıyor; "Annem Geldi"de küçülmeyen donuyor; "Belediye İlaçlıyor" sis duvarları adil uyarıyla geliyor.

**11D**
- [ ] Mikrofon izni yalnızca kayıt butonuna ilk basışta isteniyor; 3 yuvaya kayıt, kırpma, normalize ve böcek sesiyle dinleme çalışıyor.
- [ ] Özel sesler yalnızca özel oda/LAN'da paylaşılıyor, Hızlı Oyun'da hiç gönderilmiyor; susturma ve bildirme çalışıyor; sunucu ses saklamıyor.
- [ ] `web/gizlilik.html` mikrofon bölümüyle hazır.

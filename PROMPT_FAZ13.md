# UÇAN HAMAM BÖCEĞİ — Faz 13: Sesli Sohbet ve Profesyonel Açılış / Ana Menü

> **Ajan için:** Önceki tüm prompt dosyalarının devamıdır; **GENEL KURALLAR** aynen geçerlidir. İki bağımsız alt faz var, sırayla uygula: **13A** Sesli sohbet → **13B** Açılış ve ana menü. Her birinin sonunda test et.
>
> **Harici eklenti istisnası:** 13A için **TwoVoip** GDExtension'ı (`goatchurchprime/two-voip-godot-4`, MIT, Godot Asset Library'de "TwoVoip") kullanılabilir. Eklenti yoksa veya yüklenemezse sesli sohbet sessizce devre dışı kalır, oyunun geri kalanı etkilenmez.

---

## 13A — Sesli sohbet

### Nerede açık
| Oda türü | Sesli sohbet |
|---|---|
| Özel Oda (Faz 8.9) | Açık (oda sahibi kapatabilir) |
| Arkadaş odaları (Faz 12: "Sadece arkadaşlarım" / "Sadece davetliler") | Açık (oda sahibi kapatabilir) |
| LAN odası | Açık (Host kapatabilir) |
| **Hızlı Oyun** | **Her zaman kapalı.** Kod seviyesinde engellenir; ses paketi gönderilmez ve kabul edilmez. |
| Tek oyunculu / Botlarla Oyna | Yok |

- Oda sahibinin lobide **"Sesli Sohbet: Açık / Kapalı"** anahtarı olur. Kapalıysa hiçbir istemci ses göndermez.
- Her oyuncu **kendisi katılmayı seçer.** Sesli sohbeti açık bir odaya ilk kez girince ortada bir pencere çıkar: *"Bu odada sesli sohbet var. Katılmak ister misin? (En iyi deneyim için kulaklık tak.)"* [**Katıl**] [**Sadece Dinle**] [**Hayır**]. Seçim `settings.cfg`'ye kaydedilir, sonradan ayarlardan değiştirilebilir.
- Mikrofon izni (`RECORD_AUDIO`) yalnızca "Katıl"a basıldığında, gerekiyorsa istenir. Reddedilirse oyuncu "Sadece Dinle" modunda devam eder.

### Konuşma modları
- **Otomatik (varsayılan):** Konuşunca mikrofon açılır (ses etkinliği algılama), sessizken paket gönderilmez. Eşik ayarlardan değiştirilebilir. Maç sırasında parmaklar ekranda olduğu için bu en uygunu.
- **Bas-Konuş:** Lobide, sıralama ekranında ve elenip izlerken ekranda büyük bir mikrofon butonu; basılı tutunca konuşulur. Maç sırasında bu modda HUD'da küçük bir buton olur (zıplatmaz).
- Ayarlar → **Sesli Sohbet**: mod seçimi, ses etkinliği eşiği (konuşurken canlı seviye çubuğuyla), sesli sohbet ses seviyesi, "Yankı önleme" (aşağıda), "Arkadaşları böcek sesiyle duy".

### Kendi mikrofonun
- Mikrofon açıkken HUD'un sol üstünde **her zaman görünen** küçük mikrofon ikonu olur: konuşurken yeşil dalga, sessizde gri, kapalıyken üstü çizili. Dokununca kendini susturur / açar.
- Uygulama arka plana alınınca mikrofon **anında** kapanır.

### Diğerlerini duymak
- Konuşan oyuncunun böceğinin **ağzı oynar** (Faz 9.1 `talk` animasyonu) ve isim etiketinin yanında küçük ses dalgası belirir. Lobide konuşanın kartı hafifçe parlar.
- Oyuncu kartına dokununca: o kişiyi **sustur**, kişiye özel ses seviyesi kaydırıcısı. "Herkesi sustur" butonu da olur. Faz 12'de engellenen kişi otomatik susturulur ve ses paketleri hiç çalınmaz.
- Biri konuşurken oyun müziği −6 dB, efektler −3 dB kısılır; konuşma bitince 0.4 sn'de geri gelir.

### Böcek Sesi modu (eğlence)
- **Dinleyici ayarı:** "Arkadaşları böcek sesiyle duy" açıksa gelen her ses, konuşanın karakterinin `voice_pitch` değeriyle `VoiceChat` bus'ındaki `AudioEffectPitchShift`'ten geçer (Faz 9.6'daki filtre mantığı).
- **Oda modu:** Oda sahibi lobide **"Herkes Böcek Sesiyle"** açarsa bu, tüm dinleyiciler için zorunlu olur. Lobide bir şerit ve ses dalgası ikonunun yanında küçük anten simgesi görünür.
- Her konuşan için ayrı bir oynatıcı ve ayrı bir pitch değeri gerektiğinden, konuşan başına ayrı bir alt bus (`VoiceChat_<peer>`) oluşturulur ve konuşan ayrılınca silinir.

### Yankı ve gürültü
- TwoVoip'in **RnNoise** gürültü filtresi açık olsun.
- **Yankı önleme (kulaklıksız)** ayarı varsayılan açıktır. Basit yarı çift yönlü kapı mantığı: o an hoparlörden çalan ses seviyesi yüksekse, mikrofonun ses gönderme eşiği geçici olarak yükseltilir. Böylece telefon hoparlörden gelen arkadaş sesini geri göndermez. Kulaklık takanlar bu ayarı kapatabilir.
- İlk katılımda ve ayarlarda tek cümlelik uyarı: *"Hoparlörden oynarken yankı olabilir; kulaklık en iyisi."*

### Ağ
- Ses paketleri oyun RPC'lerinden ayrı bir ENet kanalında (`channel 2`) ve `unreliable_ordered` gider. TwoVoip'in Opus parçaları (yaklaşık 1 KB/sn) olduğu gibi gönderilir.
- **Ayrılmış sunucu modunda:** Oda sunucusu paketleri yalnızca **aktarır**: gönderenin kimliğini doğrular, paketi aynı odadaki ve sesli sohbete katılmış diğer oyunculara iletir. Ses **çözülmez, saklanmaz, loglanmaz.** LAN'da Host aynı şekilde aktarır.
- Doğrulamalar: gönderen gerçekten odada ve "Katıl" seçmiş mi, oda sesli sohbete açık mı, oda Hızlı Oyun değil mi. Hız sınırı: oyuncu başına saniyede en fazla 60 paket, paket başına en fazla 400 bayt. Aşanlar düşürülür.
- Alıcı tarafta ~100 ms titreşim tamponu (jitter buffer). Gecikmeli paketler atılır, ses kesik kesik hızlanıp yavaşlamaz.
- Ses katmanı `res://net/VoiceChat.gd` (autoload değil, GameWorld ve Lobby'ye eklenen bir düğüm) içinde toplanır. Oyun mantığından tamamen ayrıdır; TwoVoip yoksa bu düğüm hiçbir şey yapmaz.

### Gizlilik ve mağaza
- `web/gizlilik.html`'e sesli sohbet bölümü: mikrofonun yalnızca sesli sohbete katılan oyuncunun cihazında, sesli sohbete açık arkadaş odalarında çalıştığı; sesin yalnızca o odadaki oyunculara gerçek zamanlı iletildiği; sunucuda saklanmadığı ve kaydedilmediği.
- `web/README.md`'ye not: Play Console "Veri güvenliği" formunda ses verisinin "aktarılan ama saklanmayan" olarak beyan edileceği.
- Rehbere (Faz 8.5) **"Sesli Sohbet"** sayfası: nasıl açılır, nasıl susturulur, böcek sesi modu.

### Bitti sayılması için (13A)
- [ ] İki gerçek Android telefonla (ve editörde iki pencereyle) özel odada sesli konuşuluyor; konuşan böceğin ağzı oynuyor.
- [ ] Hızlı Oyun'da ses tamamen kapalı; kod seviyesinde paket gönderilmiyor, sunucu gelen paketi reddediyor.
- [ ] Katılma penceresi, Sadece Dinle modu, kendini susturma, kişi susturma, kişiye özel ses seviyesi ve engellenen kişinin otomatik susturulması çalışıyor.
- [ ] Otomatik ve Bas-Konuş modları çalışıyor; maçta konuşmak zıplatmıyor; uygulama arka plana alınınca mikrofon kapanıyor.
- [ ] "Herkes Böcek Sesiyle" modunda her konuşanın sesi kendi karakterinin perdesinde duyuluyor.
- [ ] Hoparlörle iki telefon yan yana test edildiğinde yankı önleme açıkken belirgin geri besleme yok.
- [ ] TwoVoip eklentisi kaldırılınca oyun hatasız açılıyor, sesli sohbet seçenekleri gizleniyor.

---

## 13B — Profesyonel açılış ve ana menü

> **Tarz kuralı:** "Profesyonel" demek parlak, soğuk ya da yapay zekâ üretimi gibi görünen bir arayüz demek **değil**. Hedef: özenle el yapımı hissi veren, sıcak, pastel bir mutfak dünyası. Çizgiler hafif düzensiz, yüzeylerde çok hafif kâğıt dokusu, gölgeler yumuşak. Neon, parlak gradyan ve cam efekti yok.

### 1) Yazı tipi
- Türkçe karakterleri (ç, ğ, ı, İ, ö, ş, ü) eksiksiz destekleyen, açık lisanslı (SIL OFL) yuvarlak hatlı bir yazı tipi kullan. Öncelik sırası: **Baloo 2**, **Fredoka**, **Nunito**. Google Fonts'un GitHub deposundan indir, `res://assets/fonts/` altına koy, lisans dosyasını yanına ekle, "Emeği Geçenler" ekranına yaz.
- İndirdiğin fontta "ĞÜŞİÖÇ ğüşıöç" satırını içeren bir test etiketiyle tüm harflerin doğru çizildiğini doğrula. Eksik harf varsa sıradaki fonta geç.
- Proje genelinde bir **Theme** kaynağı (`res://ui/tema.tres`): başlık 64 px, alt başlık 40 px, gövde 30 px, küçük 24 px; buton stilleri (normal, basılı, devre dışı), panel stili, ince koyu kenar ve yumuşak gölge. Tüm ekranlar bu temayı kullansın; tek tek stil verilmesin.

### 2) Logo
- `res://assets/sprites/ui/logo.png` varsa o kullanılır. Yoksa kodla oluşturulan bir logo: iki satır **"UÇAN / HAMAM BÖCEĞİ"**, kalın font, krem dolgu, kahve kalın dış çizgi, harfler hafif farklı açılarda (el yazısı afiş hissi). "Ç" harfinin üstünde küçük bir böcek oturur ve antenleri oynar.
- Logo sahnesi ayrı olsun (`res://scenes/ui/Logo.tscn`); açılışta, menüde ve paylaşım kartlarında aynısı kullanılsın.

### 3) Açılış (splash) ve intro
- **Godot açılış ekranı:** `application/boot_splash` arka plan rengi krem (`#F6EFE4`), görsel olarak logo (varsa), "Godot" yazısı gösterilmez (`show_image` sadece logo için). Beyaz/siyah bir ara kare olmamalı.
- **Intro animasyonu** (`res://scenes/ui/Intro.tscn`, toplam ~3 sn, herhangi bir dokunuşla geçilebilir):
  1. Gece mutfağı, karanlık (`CanvasModulate` koyu lacivert). Ortada sadece buzdolabının kapı aralığından sızan ışık.
  2. "Klik": ışık yanar (0.2 sn beyaz parlama). Tezgâhın üstünde seçili karakter yakalanmış şekilde donakalır, gözleri kocaman.
  3. Ekranın kenarından bir terlik dönerek gelir; böcek son anda kanat açıp uçar, terlik tezgâha "ŞAPP!" diye çarpar.
  4. Logo yukarıdan düşer, iki kez sekip yerine oturur; Faz 9.6'daki karakter sesiyle kısa bir laf.
  5. Menüye kesintisiz geçiş: intro sahnesinin mutfağı, ana menünün arka planına dönüşür (kamera hafifçe geri çekilir).
- İlk açılışta tam intro, sonraki açılışlarda kısaltılmış (1 sn: sadece ışık yanma + logo). Ayarlarda "Açılış animasyonunu göster" seçeneği.
- Intro sürerken arka planda `ResourceLoader.load_threaded_request` ile menü, oyun dünyası, karakterler ve sesler yüklenir. Yükleme bitmeden menüye geçilmez; bitmezse logonun altında ince bir ilerleme çizgisi görünür.

### 4) Ana menü yeniden tasarımı
**Arka plan: canlı mutfak sahnesi** (katmanlı, hafif paralaks: telefon yatırıldıkça değil, yavaş otomatik kayma ile)
- Arka katman: fayanslı duvar, pencere, perde (rüzgârla hafif sallanır), duvar saati (gerçek saati gösterir).
- Orta katman: dolaplar, buzdolabı (ara sıra motoru titrer), ocakta çaydanlık (buhar çıkar).
- Ön katman: tezgâh. Seçili karakter tezgâhın ortasında `idle_menu` animasyonuyla durur. Dokununca konuşur (Faz 9.6).
- Ara sıra ortam şakaları (20–40 sn'de bir, rastgele): duvardan başka bir böcek geçer; kapının altından bir terlik ucu görünüp kaybolur; buzdolabı kapısı aralanıp kapanır.
- Gece 22:00–06:00 arası (cihaz saati) mutfak loş ve sıcak ışıklı "gece modu"nda olur.

**Yerleşim (dikey, güvenli alan içinde)**
- **Üst çubuk:** solda profil kartı (karakter portresi küçük, oyuncu adı, Böcek Kimliği küçük yazıyla; dokununca Profil/Hesabım), sağda Kırıntı sayacı ve seri sayacı (kanat çırpan böcek ikonu + sayı). Etkinlik varsa (Faz 9.7) üst çubuğun altında ince bir şerit.
- **Orta:** logo (üstte, hafifçe süzülür) ve tezgâhtaki karakter.
- **Büyük OYNA butonu:** alt navigasyonun hemen üstünde, ekranın en baskın öğesi. Dokununca alttan bir **mod seçim kartı** açılır (4 büyük kart, her birinde küçük illüstrasyon ve tek satır açıklama): **Tek Başına**, **Botlarla Oyna**, **Arkadaşlarla (Aynı Wi-Fi)**, **Çevrimiçi**. Son seçilen mod kartın üstünde vurgulu; OYNA'ya uzun basınca doğrudan son mod başlar.
- **Alt navigasyon çubuğu** (5 sekme, ikonlu ve yazılı): **Pazar** · **Böcekler** (karakter seçimi + Yetenekler ekranı) · **Ana Sayfa** (ortada, büyük, menünün kendisi) · **Görevler** · **Arkadaşlar**. Bekleyen görev ödülü, arkadaş isteği ya da davet varsa ilgili sekmede küçük sayı rozeti.
- **Albüm, Ayarlar, Nasıl Oynanır, Emeği Geçenler** profil kartından açılan menüde ve Ana Sayfa'nın sağ üst köşesindeki küçük dişli ikonunda.
- Günün Mutfağı (Faz 6.4), mod seçim kartında Tek Başına'nın altında ikinci satır olarak.

**Hareket ve his**
- Sekmeler arası geçiş: içerik yatay kayar (0.2 sn), mutfak arka planı yerinde kalır.
- Tüm butonlarda: basınca 0.95 ölçek + hafif "tık" sesi + kısa titreşim (ayarlardan kapatılabilir). Bırakınca küçük yay efektiyle 1.0'a döner.
- Panel açılışları: alttan kayarak + arka plan %35 kararır. Kapanış: aşağı kaydırma hareketiyle de kapanabilir.
- Menü müziği (`muzik_menu.ogg`) intro bitişinde 1 sn'de yükselerek başlar.

### 5) Mağaza ve ikon görselleri (profesyonel vitrin)
- **Android uygulama ikonu:** `res://assets/icon/` altında: `icon_192.png`, uyarlanabilir ikon için `adaptive_fg_432.png` (böcek + kanatlar, güvenli bölge içinde) ve `adaptive_bg_432.png` (krem zemin + fayans deseni), tema ikonları için `monochrome_432.png`. Dosyalar yoksa ajan bunları `SubViewport`'ta oyunun kendi çizimleriyle üretip PNG olarak kaydeden bir araç sahnesi (`res://tools/IconMaker.tscn`) yazsın. Export ayarlarına bağla.
- **Play Store görselleri için araç sahnesi** (`res://tools/StoreShots.tscn`): oyunun kendi sahnelerini kullanarak şunları PNG olarak üretir:
  - Öne çıkan görsel 1024x500: mutfak, uçan 3 böcek, logo.
  - 6 dikey ekran görüntüsü (1080x1920) üst kısmında kısa başlıkla: "Arkadaşlarınla son böcek sen ol!", "Annem Geldi! Küçül ve saklan", "12 komik böcek, hepsinin yeteneği farklı", "Sinirlen, paylaş, rövanş iste", "Sesli sohbetle mahalle toplantısı", "Her gün yeni görevler".
  - Çıktılar `res://store_output/` altına yazılır.

### Bitti sayılması için (13B)
- [ ] Türkçe karakterleri eksiksiz çizen açık lisanslı font ve proje geneli Theme uygulandı; lisans ve atıf eklendi.
- [ ] Açılışta beyaz/siyah ara kare yok; ilk açılışta tam intro, sonrakilerde kısa intro; dokununca geçiliyor; intro sırasında kaynaklar arka planda yükleniyor.
- [ ] Ana menüde canlı mutfak sahnesi, büyük OYNA butonu ve mod seçim kartı, 5 sekmeli alt navigasyon, üst çubukta profil + Kırıntı + seri çalışıyor; rozetler doğru.
- [ ] Gece saatinde menü gece moduna geçiyor; ortam şakaları rastgele oluyor.
- [ ] Tüm butonlarda basma animasyonu, ses ve titreşim var; Faz 9.2'deki 5 ekran oranında menü düzgün görünüyor.
- [ ] `IconMaker` ve `StoreShots` araçları ikonları, öne çıkan görseli ve 6 ekran görüntüsünü üretiyor.

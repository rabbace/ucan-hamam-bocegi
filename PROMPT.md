# UÇAN HAMAM BÖCEĞİ — Geliştirme Prompt'u (Godot 4.3+ / GDScript)

> **Ajan için kullanım talimatı:** Bu dosya 5 faza bölünmüştür. Sana hangi faz söylenirse **yalnızca o fazı** uygula. Önceki fazların kodunu koru, bozma; sonraki fazların kodunu yazma (ama aşağıda belirtilen bağlantı noktalarını hazır bırak). Her fazın sonunda "Bitti sayılması için" maddelerini tek tek kontrol et, projeyi çalıştır, hata ve uyarı varsa düzelt, sonra ne yaptığını kısa bir listeyle özetle.
>
> **"GENEL KURALLAR" bölümü her fazda geçerlidir.**

---

## GENEL KURALLAR

### Oyunun özeti
Flappy Bird tarzında, dikey mobil ekranda oynanan 2D bir oyun. Oyuncu bir hamam böceğini dokunarak uçurur, sağdan gelen terlik çiftlerinin arasından geçer. 2–5 kişi aynı maçta oynar, son hayatta kalan kazanır. Her böceğin farklı bir yeteneği vardır. Belirli aralıklarla ortam kararır ve çapraz füze yağmuru başlar. Ton: Türk internet mizahı, sevimli ve komik; sansürlü argo.

### Teknik çerçeve
- Godot **4.3 veya üstü**, yalnızca **GDScript**. Harici eklenti/addon kullanma.
- Tüm değişken ve fonksiyonlarda **statik tip** kullan (`var hiz: float`, `func f() -> void`).
- Her dosya **eksiksiz** olsun: `TODO`, `pass` ile bırakılmış boş fonksiyon, "buraya kod gelecek" yorumu yasak.
- Yorumlar kısa ve Türkçe. Değişken/fonksiyon isimleri İngilizce olabilir.
- Sayısal ayarların hiçbiri koda gömülmesin; hepsi `res://data/GameConfig.gd` içinde `const` olarak dursun (ayar yapmak tek dosyadan olsun).
- `.tscn` dosyalarını elle yazarken geçerli Godot 4 formatı kullan. Karmaşık düğüm ağaçlarını gerekirse script içinde `_ready()`'de oluştur.

### project.godot ayarları
- `application/run/main_scene` = `res://scenes/ui/MainMenu.tscn`
- `display/window/size/viewport_width` = 720, `viewport_height` = 1280
- `display/window/size/window_width_override` = 405, `window_height_override` = 720 (PC'de test penceresi)
- `display/window/stretch/mode` = `canvas_items`, `display/window/stretch/aspect` = `expand` (uzun telefonlarda siyah bant olmasın)
- `display/window/handheld/orientation` = portrait
- `rendering/renderer/rendering_method` ve `rendering_method.mobile` = `gl_compatibility`
- `input_devices/pointing/emulate_mouse_from_touch` = true
- Autoload'lar: `NetworkManager`, `AudioManager` (Faz 4–5'te dolacak; Faz 1'de iskelet hâlinde, çalışır durumda eklenir)
- Input Map:
  - `flap` → Space, Sol fare tuşu (dokunma da bu tuşa düşer)
  - `ability` → E, Sağ fare tuşu
- Zıplama girdisi **`_unhandled_input`** ile alınmalı; böylece YETENEK butonuna veya başka bir UI öğesine dokunmak aynı anda böceği zıplatmaz.

### Klasör yapısı
```
res://
├── autoload/
│   ├── NetworkManager.gd
│   └── AudioManager.gd
├── core/
│   └── AssetHelper.gd          # class_name AssetHelper — güvenli doku/ses yükleme
├── data/
│   ├── GameConfig.gd           # class_name GameConfig — tüm sabitler
│   └── CharacterData.gd        # class_name CharacterData — karakterler
├── net/
│   ├── NetTransport.gd         # soyut taşıma katmanı
│   ├── ENetTransport.gd
│   └── LanDiscovery.gd         # aynı Wi-Fi'de oda bulma
├── scenes/
│   ├── ui/       MainMenu, Lobby, Hud, SpeechBubble, AbilityButton (.tscn + .gd)
│   ├── game/     GameWorld (.tscn + .gd), ObstacleTimeline.gd
│   └── entities/ Player, SlipperObstacle, Missile, MissileWarning (.tscn + .gd)
└── assets/
    ├── sprites/
    ├── sounds/
    └── fonts/
```
`assets/sprites`, `assets/sounds` ve `assets/fonts` klasörleri boş olsa bile oluşturulsun (içlerine `.gdkeep` dosyası koy).

### Görsel varlıklar ve güvenli yükleme (`AssetHelper.gd`)
Kullanıcı kendi .png dosyalarını sonradan ekleyecek. Dosya yokken oyun **çökmemeli ve oynanabilir görünmeli**.

| Dosya | Boyut | Yedek görünüm |
|---|---|---|
| `bg_mutfak.png` | 720x1280 | Dikey pastel gradyan (krem → açık şeftali) + birkaç soluk yatay "fayans" çizgisi |
| `char_klasik.png` | 128x128 | Kahverengi elips gövde, 2 küçük göz |
| `char_diva.png` | 128x128 | Pembe elips, göz yerinde siyah gözlük çubuğu |
| `char_duktur.png` | 128x128 | Beyazımsı elips, üstte kırmızı küçük artı |
| `char_halaybasi.png` | 128x128 | Turuncu elips, yanında küçük kırmızı mendil üçgeni |
| `terlik_ust.png`, `terlik_alt.png` | 120x600 | Yuvarlak köşeli mavi-gri dikdörtgen + uçta koyu "taban" bandı |
| `fuze.png` | 96x48 | Gri gövde + kırmızı burun + turuncu kuyruk |

Kurallar:
- Kontrol **`ResourceLoader.exists(path)`** ile yapılır. (`FileAccess.file_exists()` kullanma; export edilmiş APK'da import edilmiş kaynaklar için yanlış sonuç verir.)
- **`PlaceholderTexture2D` kullanma** — oyun içinde görünmez. Yedekler `Image.create_empty()` ile çizilip `ImageTexture.create_from_image()` ile oluşturulsun (elips/dikdörtgen basit piksel doldurma yeterli) veya `GradientTexture2D` kullanılsın.
- Fonksiyonlar: `static func texture(path: String, fallback_kind: String, size: Vector2i) -> Texture2D` ve `static func sound(path: String) -> AudioStream` (yoksa `null` döner, çağıran taraf sessizce geçer).
- Üretilen yedek dokular bir sözlükte önbelleğe alınsın; her karede yeniden üretilmesin.

### Görsel stil
- Yumuşak, pastel, "el yapımı" his. Neon ve aşırı doygun renk yok.
- Palet (`GameConfig` içinde sabit):
  krem `#F6EFE4`, şeftali `#F2C9A9`, adaçayı yeşili `#B8CDB0`, toz mavi `#A9BCD0`, toz pembe `#E8B4BC`, kahve `#7A5C4B`, uyarı kırmızısı `#D9605A`, koyu metin `#3D3530`.
- UI: yuvarlatılmış köşeler (StyleBoxFlat, radius 18–24), ince koyu kenarlık, hafif gölge. Butonlara basınca 0.95 ölçeğe küçülen kısa tween.
- Font: `res://assets/fonts/` altında bir .ttf varsa onu kullan, yoksa Godot varsayılan fontu. Başlıklar 48–64 px, gövde 28–32 px (720 genişlik için).

### Oyun fiziği (GameConfig başlangıç değerleri — sonradan ayarlanacak)
- Böcek X konumu sabit: `PLAYER_X = 200`. Ekranda görünen boyut ~96 px (128 px sprite × 0.75).
- `GRAVITY = 1900`, `FLAP_VELOCITY = -640`, `MAX_FALL_SPEED = 950`. Rotasyon hıza göre: yükselirken -25°, düşerken en fazla +70°, `lerp` ile yumuşak.
- Hitbox: `CircleShape2D`, yarıçap 30 px (görselden bilerek küçük; oyuncuyu affetsin).
- Zemin/tavan: ekranın üst kenarı (y < 0) ve alt kenarı (y > 1280 − 60) ölüm sayılır; ayrı collider gerekmez, pozisyon kontrolü yeterli.
- Çarpışma katmanları: 1 = oyuncu, 2 = terlik, 3 = füze.

### Deterministik dünya (çok önemli — tüm fazların temeli)
Tüm cihazlarda terlik ve füzelerin aynı sırada, aynı konumda gelmesi için engeller **kare sayısına veya `_process` birikimine göre değil, maç süresine (`match_time`) göre** konumlandırılır:
1. Maç başında tek bir `world_seed` ile `RandomNumberGenerator` oluşturulur (global `randi()`/`randf()` **asla** kullanılmaz).
2. `ObstacleTimeline.gd` bu RNG ile maçın ilk 15 dakikasının tüm terlik ve füze listesini **baştan** üretir.
3. Kaydırma hızı zamana bağlı: `speed(t) = min(BASE_SPEED + SPEED_ACCEL * t, MAX_SPEED)` (başlangıç: 260 → 520 px/s, ivme 4 px/s²). Kat edilen mesafe `distance_at(t)` kapalı formülle hesaplanır (`GameConfig` içinde statik fonksiyon).
4. i'nci terlik çiftinin dünya mesafesi `D_i = FIRST_OBSTACLE_DIST + i * OBSTACLE_SPACING` (420 px). Ekrandaki X = `PLAYER_X + (D_i − distance_at(match_time))`. Ekrana girmeden 200 px önce oluşturulur, soldan çıkınca silinir.
5. Terlik aralığı (gap) zamanla daralır: 320 px → en az 235 px. Gap merkezinin Y'si 330–950 arası, ardışık iki gap arasındaki fark en fazla 380 px (imkânsız geçiş olmasın).
6. Tek oyunculu modda seed rastgele üretilir; çok oyunculu modda Host gönderir.

---

## FAZ 1 — Tek oyunculu çekirdek

**Yapılacaklar**
1. Yukarıdaki klasör yapısı, `project.godot` ayarları, `GameConfig.gd`, `AssetHelper.gd`. `NetworkManager.gd` ve `AudioManager.gd` şimdilik boş ama hatasız çalışan autoload'lar.
2. **MainMenu**: oyun adı ("UÇAN HAMAM BÖCEĞİ"), isim giriş kutusu (en fazla 12 karakter, `user://settings.cfg`'ye kaydedilir), "Tek Başına Dene" butonu. Faz 4'te eklenecek "Oda Kur" ve "Odaya Katıl" butonları şimdilik görünür ama devre dışı.
3. **GameWorld**:
   - Arka plan: `bg_mutfak` dokusu, iki kopya yan yana sonsuz yatay kayar (hız, dünya hızının %30'u — derinlik hissi).
   - `ObstacleTimeline` ile terlik çiftleri (deterministik dünya kurallarına göre).
   - Maç başı: ekranda "3 – 2 – 1 – UÇ!" geri sayımı; bu sırada böcek ekranın ortasında hafifçe aşağı yukarı süzülür, yerçekimi yok.
   - Skor: geçilen terlik çifti sayısı (üst ortada büyük rakam).
4. **Player**: zıplama, yerçekimi, rotasyon, hitbox. Kanat çırpınca kısa bir "squash" tween'i (scale 1.1/0.9 → 1).
5. **SlipperObstacle**: üst (ters) ve alt terlik; `Area2D` + `RectangleShape2D` (görselden %10 dar).
6. **Ölüm**: böcek grileşir (`modulate` gri tona tween), hızla dönerek aşağı düşer, kamera/ekran 0.25 sn hafif sarsılır. Ardından ortada "ELENDİN" paneli ve "Tekrar Dene" / "Menü" butonları.
7. **Hud**: `CanvasLayer` içinde (ileride `CanvasModulate` karanlığı UI'ı etkilemesin diye).

**Bitti sayılması için**
- Hiçbir görsel/ses dosyası yokken oyun hatasız açılıyor, her şey pastel yedek görsellerle görünüyor.
- Space / tıklama / dokunma ile böcek uçuyor; terliğe, tavana, zemine çarpınca eleniyor.
- Aynı seed ile iki kez oynandığında terlikler birebir aynı yerlerde geliyor (debug için seed'i ekranın köşesinde küçük yazıyla göster; `GameConfig.DEBUG` false iken gizlensin).
- Uzun süre oynayınca hız artıyor, gap daralıyor.

---

## FAZ 2 — Karakterler ve yetenekler (hâlâ tek oyunculu)

**CharacterData.gd** — `class_name CharacterData`, her karakter için sözlük:
`id, display_name, sprite_path, fallback_kind, passive_text, ability_name, ability_text, cooldown, duration, hitbox_scale, gravity_mult, flap_mult, ability_line, death_lines (Array), win_lines (Array)`

| id | İsim | Yetenek | Detay |
|---|---|---|---|
| `klasik` | Klasik Böcek | **Pasif – Çevik Kanatlar** + **Aktif – Ani Fren** (8 sn CD) | Pasif: hitbox %20 küçük (`hitbox_scale = 0.8`), `flap_mult = 1.05`, `gravity_mult = 0.95`. Aktif: dikey hızı anında sıfırlar, 0.5 sn boyunca yerçekimi ×0.2 (havada asılı kalır). Replik: *"Kaç kaç kaç!"* |
| `diva` | Diva Böcek | **Ayy Terlik Geliyor!** (12 sn CD, 2.5 sn) | Etrafında toz pembe, nabız gibi atan yarı saydam kalkan halkası. Bu sürede terlik veya füzeye çarparsa elenmez; çarptığı engel **yalnızca o oyuncunun ekranında** parçalanma animasyonu (küçülme + dönme + solma, 0.3 sn) ile yok olur. Zemin/tavan yine öldürür. Replik: *"Ayy terlik geliyor!"* |
| `duktur` | Duktur Böcek | **Duktur Müdahalesi** (12 sn CD, 3 sn) | 0.15 sn tween ile `scale = 0.5` (hitbox da küçülür), `gravity_mult = 0.7`. Süre bitince 0.15 sn'de normale döner; dönüşte 0.3 sn dokunulmazlık (dar aralıkta büyüyüp haksız ölmesin). Replik: *"Duktur müdahalesi!"* |
| `halaybasi` | Halay Başı Böcek | **Mendil Sallama** (14 sn CD, 2 sn) | Hayalet fazı: terlik ve füze çarpışması kapalı (zemin/tavan açık). Görsel: titreyen, açık turuncu tonlu, %55 saydam (diğer oyuncuların %40 hayalet görünümünden ayırt edilsin). Rakiplerin ekranında 1.5 sn konfeti/mendil yağar (Faz 4'te ağ üzerinden; Faz 2'de test için kendi ekranında küçük versiyonu). Konfeti **yalnızca ekranın sol ve sağ kenar şeritlerinde** uçuşsun, oyun alanının ortasını kapatmasın. Replik: *"Hadi bakalım halaya!"* |

**Yapılacaklar**
1. MainMenu'de "Tek Başına Dene"den önce basit karakter seçim ekranı: 4 kart (görsel, isim, yetenek açıklaması). Seçim `settings.cfg`'ye kaydedilir. Bu kart bileşeni Faz 4 lobisinde tekrar kullanılacak; ayrı sahne olarak yaz (`CharacterCard.tscn`).
2. **AbilityButton** (sağ alt köşe, 150 px yuvarlak): ortada "YETENEK" yazısı, etrafında dairesel cooldown göstergesi (`_draw()` ile yay çizimi), bekleme sırasında kalan saniye. PC'de E veya Sağ Tık aynı işi yapar.
3. **SpeechBubble** (`PanelContainer` + `Label`): böceğin üstünde, beyaz yuvarlak köşeli balon, altında küçük üçgen kuyruk. `show_text(text, duration)`; açılırken 0 → 1 ölçek "pop" tween'i. Yetenek kullanılınca karakterin repliği 1.5 sn görünür.
4. Yetenek mantığı `Player.gd` içinde, karaktere göre `match char_id:` ile. Yetenek tetikleme tek bir fonksiyondan geçsin: `func activate_ability() -> void` (Faz 4'te ağ çağrısı buraya bağlanacak).

**Bitti sayılması için**
- 4 karakter de seçilebiliyor, her birinin yeteneği tarif edildiği gibi çalışıyor, cooldown göstergesi doğru sayıyor.
- YETENEK butonuna dokunmak böceği zıplatmıyor.
- Diva kalkanı açıkken terliğe çarpınca terlik parçalanıyor, oyuncu devam ediyor.

---

## FAZ 3 — "Şuraları Aydınlat Hele!" ve füze yağmuru

**Zamanlama (GameConfig):** ilk evre maçın 20. saniyesinde, sonra her 25 saniyede bir, her evre 6 sn. Evre takvimi de `ObstacleTimeline` içinde seed'den üretilir.

**Yapılacaklar**
1. Evre başlarken:
   - `CanvasModulate` 0.8 sn'de `Color(0.16, 0.16, 0.24, 1.0)` rengine tween'lenir.
   - Ekranın ortasında **"ŞURALARI AYDINLAT HELE!"** yazısı pop animasyonuyla belirir, 1.5 sn kalır, söner.
   - `AudioManager` üzerinden `aydinlat.ogg` çalınır (Faz 5'e kadar dosya yoksa sessiz geçer).
   - Oyuncunun kendi böceğinde küçük, sönük bir `PointLight2D` yanar (karanlıkta kendini görebilsin).
2. **Terlik boşluğu:** evre süresine denk gelen dünya mesafesinde (önünde ve arkasında 1 sn'lik pay ile) terlik üretilmez. Oyuncu aynı anda hem terlik hem füzeyle uğraşmaz.
3. **Füzeler (Missile.tscn):**
   - Ekranın sağ üstünden (X: 380–820, Y: −80) sol alta doğru **45–60° açıyla** iner. Yön: `Vector2(-cos(a), sin(a))`.
   - Hız 650 px/s. Konum zamana bağlı hesaplanır: `start + dir * speed * (match_time − launch_time)`.
   - Evre başına 6–9 füze (zamanla artar), ardışık iki füze arasında en az 0.55 sn. Aynı anda ekranda en fazla 3 füze.
   - Her füzede radyal `GradientTexture2D` (`fill = FILL_RADIAL`, merkez sıcak turuncu → kenar şeffaf) dokulu `PointLight2D`; karanlıkta etrafını aydınlatır.
   - Hitbox: füze gövdesinden küçük `CapsuleShape2D`.
4. **Uyarı (MissileWarning.tscn):** füze fırlatılmadan **0.9 sn önce**, izleyeceği rota boyunca ekranı baştan sona kesen yarı saydam uyarı kırmızısı `Line2D` (genişlik 6 px) belirir ve hızlıca yanıp söner (alfa 0.25 ↔ 0.8). Rotanın ekrana girdiği noktada, ekran kenarına sıkıştırılmış kırmızı daire içinde **"!"** ikonu. Füze fırlayınca uyarı kaybolur.
5. Evre bitişinde `CanvasModulate` 0.8 sn'de beyaza döner, oyuncu ışığı söner.

**Bitti sayılması için**
- Aynı seed ile iki oyunda füzeler aynı anda, aynı rotadan geliyor.
- Her füzeden önce mutlaka uyarı görülüyor; karanlıkta füzeler ve oyuncu seçilebiliyor.
- HUD karanlıktan etkilenmiyor.
- Diva kalkanı füzeyi de parçalıyor; Halay Başı hayalet fazında füzenin içinden geçiyor.

---

## FAZ 4 — Çok oyunculu (aynı Wi-Fi / LAN)

> İlk sürüm **aynı yerel ağda** (ev/ofis Wi-Fi'si, telefonun hotspot'u) çalışır. İnternet üzerinden oynamak için ileride relay/WebRTC eklenecek; bu yüzden taşıma katmanı soyut olmalı.

### Taşıma katmanı
- `NetTransport.gd` (`class_name NetTransport`, `RefCounted`): `create_host(port: int, max_clients: int) -> MultiplayerPeer`, `create_client(address: String, port: int) -> MultiplayerPeer`.
- `ENetTransport.gd` bunu `ENetMultiplayerPeer` ile uygular. Port 7777. `max_clients = 4` (Host + 4 = 5 oyuncu).
- `NetworkManager` yalnızca `NetTransport` arayüzünü kullanır; ileride `WebRTCTransport` veya `RelayTransport` eklemek tek satır değişiklik olmalı.

### Oda bulma (LanDiscovery.gd)
- Host, `PacketPeerUDP` ile 7778 portundan saniyede 1 kez yayın (broadcast) yapar: `{"game":"hamam_bocegi","version":X,"host_name":..,"players":n,"in_match":bool}`.
- "Odaya Katıl" ekranı bu yayınları dinler ve bulunan odaları liste hâlinde gösterir; dokununca bağlanır.
- Yedek olarak elle IP girme kutusu da olsun. Lobide Host'un yerel IP'si (`IP.get_local_addresses()` içinden 192.168.x / 10.x / 172.16–31.x olanı) görünsün.

### Oyuncu verisi
- `players = { peer_id: {"name": String, "char_id": String, "is_alive": bool, "score": int} }` — **tek doğru kaynak Host'tadır.**
- İstemci bağlanınca Host'a `register_player(name, char_id, version)` gönderir. Sürüm uyuşmazsa veya maç sürüyorsa Host bağlantıyı açıklayıcı mesajla reddeder.
- Karakter değişikliği: istemci `request_char(char_id)` → Host doğrular → `sync_players(players)` ile herkese yayınlar (`@rpc("authority", "call_local", "reliable")`).
- `any_peer` RPC'lerin hepsinde `multiplayer.get_remote_sender_id()` kontrol edilir; bir oyuncu başkası adına işlem yapamaz.

### Lobi (Lobby.tscn)
- Bağlı oyuncular `CharacterCard` ile listelenir (görsel, isim, karakter adı, yetenek açıklaması, galibiyet sayısı). Host'un kartında küçük taç ikonu.
- Alt kısımda 4 karakter seçim butonu.
- **"Oyunu Başlat"** yalnızca Host'ta görünür; en az 2 oyuncu varken aktif (`GameConfig.DEBUG` true iken 1 oyuncuyla da başlatılabilir).
- "Lobiden Çık" butonu.

### Maç başlatma
1. Host bir `world_seed` (int) üretir ve `start_match(seed)` gönderir — `@rpc("authority", "call_local", "reliable")`. Herkes GameWorld'e geçer.
2. Her istemci sahne yüklenince Host'a `client_loaded()` gönderir. Herkes yüklenince Host `begin_countdown()` gönderir (`authority, call_local, reliable`). `match_time` herkeste geri sayım bitince 0'dan başlar.
3. GameWorld her peer için bir Player oluşturur: `name = str(peer_id)`, `set_multiplayer_authority(peer_id)`.

### Oyuncu görünümü ve senkronizasyon
- Yerel oyuncu: `modulate.a = 1.0`, `z_index = 10`.
- Diğerleri: `modulate.a = 0.4`, `z_index = 5`, üstlerinde isim etiketi (`Label`, koyu kenarlıklı beyaz yazı).
- **Yalnızca yerel oyuncunun** çarpışması açık; uzak oyuncuların `CollisionShape2D`'leri `set_deferred("disabled", true)` ile kapatılır.
- Her oyuncunun dünyası kendi cihazında yereldir: terlik ve füzeler her cihazda seed'den aynı üretilir, ağ üzerinden **gönderilmez**. Diva'nın kırdığı engel sadece onun ekranında kırılır.
- Yerel oyuncu saniyede 20 kez `sync_state(y: float, rot: float, ability_active: bool)` gönderir — `@rpc("any_peer", "unreliable_ordered")`. Alıcı, gönderenin o Player'ın authority'si olduğunu kontrol eder ve hedefe `lerp` ile yumuşakça yaklaşır. X sabit olduğu için gönderilmez.

### Yetenekler ağda
- `activate_ability()` → `use_ability()` — `@rpc("any_peer", "call_local", "reliable")`. Tüm cihazlarda görsel efekt + replik balonu + yetenek sesi oynar.
- Halay Başı'nın konfetisi **yalnızca rakiplerin** ekranında çıkar, kullananın ekranında çıkmaz.

### Elenme ve kazanma
- Ölümü yalnızca yerel cihaz algılar → `report_death(cause: String)` — `@rpc("any_peer", "call_local", "reliable")`. Tüm cihazlarda o böcek grileşip düşer ve üstünde 2.5 sn sansürlü argo balonu çıkar.
- Host `is_alive` değerini günceller, hayatta kalan sayısını kontrol eder:
  - 1 kişi kaldıysa → `announce_winner(peer_id)` (`authority, call_local, reliable`).
  - Aynı anda herkes öldüyse (0 kişi) → en son ölen kazanır; aynı karede öldülerse "BERABERE".
- Kazananın skoru +1, üstünde argo sevinç balonu, ekranda büyük "{isim} KAZANDI!" yazısı.
- Elenen oyuncunun dünyası **akmaya devam eder**; diğerlerinin hayaletlerini izler. Üstte **"ELENDİN – Arkadaşlarını İzliyorsun"** bandı.
- HUD sağ üst: **"Hayatta Kalan: X / Y"**.
- Maç bitiminden 4 sn sonra Host'ta **"Tekrar Oyna"** ve **"Lobiye Dön"** butonları çıkar; istemcilerde "Host'un kararı bekleniyor…" yazısı.

### Bağlantı kopmaları
- Maç sırasında çıkan oyuncu elenmiş sayılır (balon yok, sadece kaybolur ve sayaç güncellenir).
- Host çıkarsa istemciler "Oda sahibi ayrıldı" mesajıyla ana menüye döner.
- Bağlanılamazsa (zaman aşımı 6 sn) anlaşılır bir hata mesajı gösterilir.

### Android export notları
- İzinler: `INTERNET`, `ACCESS_NETWORK_STATE`, `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`.
- Oyun sırasında ekran kapanmasın: `DisplayServer.screen_set_keep_on(true)`.

**Bitti sayılması için**
- Godot'ta *Debug → Run Multiple Instances* ile 3 pencere açıldığında: biri oda kurar, diğerleri listeden bulup katılır, karakter seçimleri tüm pencerelerde anında görünür.
- Maç başlar, üç pencerede terlik ve füzeler aynı sırada gelir, hayaletler akıcı hareket eder.
- Birini öldürünce tüm pencerelerde grileşir; son kalan kazanır; "Tekrar Oyna" yeni seed'le yeni maç başlatır.
- Bir pencereyi maç ortasında kapatmak oyunu bozmaz.

---

## FAZ 5 — Ses, replikler ve cila

### AudioManager.gd
- Ses yolları: `Master`, `Music`, `SFX` bus'ları (`default_bus_layout.tres` oluştur).
- 8 adet `AudioStreamPlayer` havuzu; `play_sfx(path: String, pitch_min := 1.0, pitch_max := 1.0)`. Ses `AssetHelper.sound()` ile yüklenir, önbelleğe alınır, yoksa sessizce geçilir.
- Menüde ses aç/kapat düğmesi (`settings.cfg`'ye kaydedilir).

| Dosya | Ne zaman |
|---|---|
| `ucus.ogg` | Her kanat çırpışında, **yalnızca yerel**, pitch 0.90–1.15 rastgele (görsel RNG, oyun seed'inden bağımsız) |
| `kufur.ogg` | Elenmede, tüm cihazlarda |
| `sevinc_argo.ogg` | Kazanan belli olunca, tüm cihazlarda |
| `aydinlat.ogg` | Füze evresi başında |
| `kalkan.ogg`, `kucul.ogg`, `mendil.ogg`, `fren.ogg` | Yetenekler (opsiyonel) |
| `terlik_kirildi.ogg`, `fuze.ogg` | Engel kırılması, füze fırlaması (opsiyonel) |
| `muzik_menu.ogg`, `muzik_oyun.ogg` | Döngülü müzik (opsiyonel, Music bus) |

### Replik havuzları (CharacterData içinde, karaktere özel tatlar eklenebilir)
- **Elenme (sansürlü):** "Ulan @#%!", "Terliği kim attı lan?!", "Yandık anam!", "Bu ne biçim terlik be ★★★!", "Ah be #@%&!", "Annem bunu duymasın…"
- **Kazanma:** "Kim tutar beni!", "Hepinizi yedim lan!", "Mutfağın kralı benim!", "Terlik mi? Hı hı, kesin!"
- Balon her seferinde havuzdan rastgele seçer (görsel RNG).

### Cila
- Elenmede küçük parçacık efekti (`CPUParticles2D`, kahverengi kırıntılar) ve Android'de `Input.vibrate_handheld(40)` (yalnızca yerel oyuncu).
- Terlik geçilince skor rakamı kısa "pop" yapar.
- Menüde böcek ekranın ortasında kendi kendine süzülsün (canlı görünsün).
- Ayarlarda titreşim aç/kapat.

**Bitti sayılması için**
- Ses dosyaları yokken hiçbir hata/uyarı çıkmıyor; dosyalar eklenince doğru anlarda çalıyor.
- Uçuş sesi sadece yerel oyuncuda, elenme ve kazanma sesleri tüm cihazlarda çalıyor.
- Projeyi Android'e export edip iki telefonda aynı Wi-Fi'de oynamak mümkün.

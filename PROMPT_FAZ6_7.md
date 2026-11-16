# UÇAN HAMAM BÖCEĞİ — Ek Fazlar: Seviyeler, Güçlendirmeler, Sataşma

> **Ajan için:** Bu dosya `PROMPT.md`'nin devamıdır; oradaki **GENEL KURALLAR** burada da aynen geçerlidir (statik tip, eksiksiz dosya, tüm sayılar `GameConfig`'de, global `randi()` yasak, pastel stil, `ResourceLoader.exists()` ile güvenli yükleme). Sana hangi faz söylenirse yalnızca onu uygula. Faz 6 en erken Faz 3 bittikten sonra, Faz 7 ise Faz 4 bittikten sonra uygulanır.
>
> **Oyunun ruhu:** Tamamen geyik. Her 20–30 saniyede bir oyuncuyu güldürecek küçük bir şey olsun (bir yazı, bir çığlık, bir sataşma). Ceza adil, ölüm hızlı, "bir el daha" isteği yüksek.
>
> **Emoji yasak:** Oyun içindeki hiçbir yazıda emoji kullanma; Android'de varsayılan font emojiyi göstermeyebilir. İkonlar sprite (veya yedek çizim) olsun.

---

## DEĞİŞİKLİK NOTU (önceki fazlara etkisi)

1. **Ekranın alt şeridi:** Alttaki 180 px "tezgâh şeridi" olur (mutfak tezgâhı görünümünde, pastel). Güçlendirme tepsisi ve YETENEK butonu bu şeritte durur. **Zemin ölüm çizgisi `y = 1280 − 180`** olarak güncellenir. Engellerin alt parçaları bu çizgiye kadar uzanır.
2. **Hız artık seviyeye bağlıdır:** Genel Kurallar'daki `speed(t)` formülü kaldırılır. `ObstacleTimeline`, maç başında seviye tablosundan bir **hız profili** üretir: 0.05 sn adımlarla `speed` ve kümülatif `distance` tablosu (15 dakikalık). `distance_at(t)` bu tablodan doğrusal enterpolasyonla okunur. Böylece hız seviyeye bağlı olur ama tüm cihazlarda yine birebir aynı kalır.
3. **Seviye, geçilen engel çiftinin indeksine göre belirlenir.** Engeller sabit dünya mesafelerinde durduğu için hayattaki tüm oyuncular aynı engeli aynı anda geçer; seviye herkeste aynı anda değişir.
4. **Ağır çekim (`Engine.time_scale`) kullanma.** Dünya zamanını bozar ve senkronu kırar. Tüm "vay be" efektleri yalnızca görsel olsun (yazı, sarsıntı, parçacık).

---

## FAZ 6 — Seviyeler ve güçlendirmeler (tek oyunculuda da çalışır)

### 6.1 Seviye sistemi

`GameConfig.LEVELS` dizisi (her seviye bir sözlük):

| Sv | Ad | Başlangıç (geçilen çift) | Hız (px/s) | Gap (px) | Engel sallanma genliği | Sürpriz engel şansı | Füze evresi |
|---|---|---|---|---|---|---|---|
| 1 | Mutfak Turu | 0 | 260 | 320 | 0 | %0 | yok |
| 2 | Salon Paniği | 8 | 300 | 300 | 20 px | %10 | yok |
| 3 | Anne Uyandı | 18 | 340 | 285 | 35 px | %18 | var (6 füze) |
| 4 | Komşular Toplandı | 30 | 380 | 270 | 50 px | %25 | var (7 füze) |
| 5 | Belediye İlaçlıyor | 45 | 425 | 255 | 60 px | %32 | var (8 füze) |
| 6 | Efsane Böcek | 65 | 470 | 245 | 70 px | %40 | var (9 füze) |
| 7+ | Efsane Böcek +N | her +20 çiftte | +15 (en fazla 560) | −5 (en az 230) | +5 (en fazla 90) | +3% (en fazla %55) | 10 füze |

- Hız geçişleri 2 saniyede yumuşak olur; hız profiline bu yumuşama da dahildir.
- "Sürpriz engel" = kullanıcının eklediği ara engeller (böcek ilacı bulutu, fırlayan terlik, süpürge sapı, açılan dolap kapağı vb.). Hangi çiftin sürpriz olacağı seed'den önceden belirlenir.
- Füze evresi zamanlaması aynı kalır (ilk evre 20. sn, sonra 25 sn'de bir), fakat Seviye 1–2'deyken evre **atlanır**. Füze sayısı o anki seviyeden alınır.
- Seviyeler arasında bir "nefes" bırak: her yeni seviyenin ilk 2 engel çifti gap'i +30 px geniş gelir.

**Seviye atlama anı:**
- Ekranın üstünden kayan pastel bir şerit: **"SEVİYE 3: ANNE UYANDI!"** ve altında küçük, rastgele bir alt yazı. Alt yazı havuzu (`GameConfig`):
  - "Terlikler bilendi."
  - "Mahallede söylenti yayıldı."
  - "Biri 'Ayyy!' dedi."
  - "Böcek ilacı stokları tükeniyor."
  - "Bu böcek ruhsatlı mı?"
- Kısa bir "ding" (`seviye.ogg`, opsiyonel), ekranın kenarında 0.3 sn hafif parlama.
- Arka plan rengi her seviyede hafifçe değişir (krem → şeftali → toz pembe → toz mavi…), oyuncu ilerlediğini hisseder.

**HUD:** Sol üstte küçük seviye rozeti ("Sv 3") ve altında sonraki seviyeye ilerleme çubuğu (ince, pastel).

### 6.2 Kombo ve yakın kaçış

- Bir engelin yanından çok yakın geçmek (hitbox kenarı ile engel arasında < 18 px) **"Yakın Kaçış"** sayılır; kullanıcının eklediği "Ödü Kopan İnsan" bonusu buna bağlanır.
- Art arda yakın kaçışlar kombo sayacını büyütür; ilk ölümsüz çarpışmada, yakın kaçış olmayan bir geçişte veya ölümde sıfırlanır.
- Kombo unvanları (böceğin yanında kısa yazı):
  x2 "Fena değil" → x3 "Kanatlar ısındı" → x5 "Böcek Lord" → x8 "Mahallenin Korkulu Rüyası" → x12 "BELEDİYE SENİ ARIYOR".

### 6.3 Güçlendirmeler (alt şerit)

**Toplama:**
- Güçlendirme kutuları dünya mesafesine göre seed'den önceden üretilir: ortalama her 6 engel çiftinde bir, (5–7 arası rastgele). Kutu, o çiftin gap'inin içinde ya da hemen arkasında durur; almak hafif risk ister.
- Görünüm: ekmek kırıntısı tepsisi üstünde dönen küçük ikon (yedek: pastel daire + harf).
- Tüm oyuncular aynı kutuları aynı yerlerde görür; **her oyuncu kutuyu kendi ekranında toplar** (biri alınca diğerlerinden kaybolmaz). Şans eşit, beceri farkı belirler.

**Tepsi (alt şerit, sol ve orta):**
- 3 yuvalı tepsi, her yuva 120 px yuvarlak kare. Dolu yuvada ikon ve altında kısa ad.
- Yuvaya dokununca güçlendirme kullanılır. Kullanımlar arasında 1.5 sn genel bekleme süresi var.
- Tepsi doluyken toplanan yeni güçlendirme en soldakini atar (kayarak çıkma animasyonu).
- PC'de 1, 2, 3 tuşları. Tepsiye dokunmak böceği **zıplatmaz** (`_unhandled_input` kuralı).
- Yeni bir güçlendirme gelince yuva hafifçe zıplar ve "Kuşanıldı!" yazısı çıkar.

**Kendine avantaj sağlayanlar (tek oyunculuda ve çoklu oyunda):**

| id | Ad | Etki | Süre |
|---|---|---|---|
| `dondurma` | **Dondurma** | Ekrandaki tüm engeller "donar": sallanma durur, dolap kapakları açılmaz, fırlayan terlikler havada asılı kalır. Engeller buz mavisi tonlu görünür. Üstüne gap'ler %15 genişler. Böcek külah yalar gibi bir replik atar: *"Beyin dondu ama değdi."* | 3.5 sn |
| `turbo` | **Turbo Kanat** (hızlandırma) | Böcek ekranda ileri atılır (X: 200 → 330), hız çizgileri çıkar, bu sürede **ilk çarptığı engeli delip geçer**. Süre bitince yavaşça X 200'e döner. Replik: *"Fren tutmuyooor!"* | 2 sn |
| `yedek_bacak` | **Yedek Bacak** | Bir kerelik sigorta: bir sonraki ölümcül çarpışmada ölmezsin. Bunun yerine bir bacağın uçar (küçük bacak sprite'ı dönerek düşer), 1 sn dokunulmaz olursun. Replik: *"Altı tane var zaten."* Maçta en fazla 1 kez taşınabilir. | Kullanılana kadar |
| `miknatis` | **Kırıntı Mıknatısı** | Yakındaki güçlendirme kutularını kendine çeker. | 8 sn |
| `ozel_yetenek` | **Tavşan Kanı** | Karakter yeteneğinin bekleme süresini anında sıfırlar. | Anında |

**Kurallar:**
- Dondurma ve Turbo yerel dünyayı değiştirir ama dünya zamanını değil (engeller dünya mesafesinde durmaya devam eder; sadece görüntü/çarpışma tepkisi değişir). Senkron bozulmaz.
- Güçlendirme etkileri karakter yetenekleriyle üst üste binebilir (Diva kalkanı + Turbo serbest), aynı güçlendirmenin iki kopyası birlikte çalışmaz (süre yenilenir).
- Seviye yükseldikçe kutu içeriği değişir: Sv 1–2'de çoğunlukla Dondurma ve Mıknatıs, Sv 4+'ta Turbo ve Yedek Bacak şansı artar (ağırlıklar `GameConfig`'de).

### 6.4 Tek oyunculuya ekler

- **En iyi skor:** `user://settings.cfg`'ye kaydedilir. Ölüm ekranında "Rekor: X" ve rekor kırılınca konfeti + *"Mahalle seni konuşuyor!"*
- **Günün Mutfağı:** Menüde ikinci buton. Seed, günün tarihinden üretilir (`hash("YYYY-MM-DD")`). Herkes aynı gün aynı parkuru oynar; arkadaşlar skorlarını kıyaslayabilir.
- **Ölüm sebebi yazısı:** Ölüm ekranında komik bir ölüm sebebi gösterilir (bkz. 7.4 havuzu).

**Bitti sayılması için (Faz 6)**
- Seviyeler engel geçtikçe değişiyor; şerit, alt yazı ve renk değişimi görünüyor.
- Aynı seed ile iki oyunda seviye geçişleri aynı engel çiftinde oluyor.
- Kutular toplanıyor, tepsiye giriyor, dokununca çalışıyor; tepsiye dokunmak zıplatmıyor.
- Dondurma, Turbo ve Yedek Bacak tarif edildiği gibi çalışıyor ve hiçbir görsel/ses dosyası yokken oyun hatasız.

---

## FAZ 7 — Çoklu oyunda sataşma

### 7.1 Sataşma güçlendirmeleri (yalnızca çoklu oyunda kutulardan çıkar)

Bu güçlendirmeler **rakibe** etki eder. Tek oyunculuda kutu tablosundan çıkarılır.

| id | Ad | Rakibe etkisi | Süre |
|---|---|---|---|
| `buz_kalibi` | **Buz Kalıbı** | Rakibin böceği buz mavisine döner, kanat çırpması %30 zayıflar. | 2.5 sn |
| `turk_kahvesi` | **Türk Kahvesi** | Rakip hiperaktif olur: zıplama gücü ×1.35, böcek titrer. Ekranında *"Üçüncü fincan…"* yazar. | 3 sn |
| `kirli_corap` | **Kirli Çorap** | Rakibin ekranının üst ya da alt yarısında yeşil koku bulutu belirir (en fazla %60 opak; oyun alanı asla tamamen kapanmaz). | 2.5 sn |
| `komsu_teyze` | **Komşu Teyze** | Rakibin ekranının kenarından bir teyze kafası uzanır ve bağırır: *"Ayyy bu ne böcek!"* Bu sırada rakibin kontrolleri **ters** çalışır (dokununca aşağı itilir). | 1.5 sn |
| `ayna` | **Ayna** | Kendine: sana gelen bir sonraki sataşmayı gönderene geri yansıtır. | Kullanılana kadar (en fazla 10 sn) |

**Hedef seçimi:**
- Sataşma güçlendirmesine dokununca hayattaki rakiplerin küçük isim baloncukları tepsinin üstünde açılır; birine dokunarak hedef seçilir.
- 2 sn içinde seçilmezse hedef otomatik olarak **en uzun hayatta kalan / en yüksek skorlu** rakip olur (liderin sırtında hedef olsun).
- PC'de: sataşma tuşuna basınca otomatik hedef kullanılır.

**Adalet kuralları:**
- Kurbanın ekranında etki başlamadan **0.6 sn önce** uyarı belirir: gönderenin karakter ikonu + "AYŞE SANA KİRLİ ÇORAP ATTI!" yazısı. Uyarı süresi içinde kurban hazırlanabilir.
- Bir oyuncu sataşma yedikten sonra 4 sn boyunca yeni sataşmalara karşı bağışıktır (ekranında küçük kalkan rozeti). Bağışık oyuncu hedef listesinde gri görünür.
- Sataşmalar üst üste binmez.
- Diva kalkanı ve Halay Başı hayalet fazı **sataşmayı engellemez** (bunlar engel savunmasıdır); sadece Ayna engeller.

**Ağ:**
- `send_taunt_item(target_id: int, item_id: String)` → `@rpc("any_peer", "call_local", "reliable")`. Gönderen kimliği `multiplayer.get_remote_sender_id()` ile doğrulanır. Host, gönderenin gerçekten hayatta olduğunu ve hedefin bağışık olmadığını kontrol eder, sonra `apply_taunt(sender_id, target_id, item_id)` ile herkese yayınlar (`authority, call_local, reliable`).
- Tüm oyuncuların ekranında küçük bir olay akışı görünür (sol üst, son 3 olay, 3 sn'de solar): "Mehmet → Ayşe: Türk Kahvesi".

### 7.2 Laf atma (hızlı mesaj)

- Sol üstte, seviye rozetinin yanında küçük bir **konuşma balonu butonu**. Dokununca 6 hazır laf açılır, birine dokununca gönderilir:
  1. "Uç bakalım uç!"
  2. "Terliği yedin mi?"
  3. "Annen çağırıyor!"
  4. "Bu ne hız ya?"
  5. "Hadi ordan böcek!"
  6. "Kahve ısmarlarım, yeter ki öl."
- Laf, gönderenin böceğinin üstünde balon olarak tüm ekranlarda 2 sn görünür (`@rpc("any_peer", "call_local", "reliable")` + gönderen doğrulaması). Bekleme süresi 3 sn.
- Karaktere özel bir 7. laf olsun (CharacterData'ya `taunt_line` alanı ekle):
  - Klasik: "Ben bu mutfağın eskisiyim."
  - Diva: "Ayy ne bakıyorsun?"
  - Duktur: "Reçeteni yazdım bile."
  - Halay Başı: "Halaya gel, halaya!"

### 7.3 Elenenler oyundan kopmasın: Hayalet Terlik

Elenen oyuncu izlerken sıkılmasın ve maç sonsuza uzamasın:
- Elenen oyuncunun ekranının sağ kenarında dikey bir **"Terlik At"** şeridi belirir. Şeride dokunduğu yükseklikten, hayattaki oyuncuların ekranına bir terlik fırlar.
- Terlik, dokunulduktan **1.2 sn sonra** ekrana girer; bu sürede hayattaki oyuncuların ekranında o yükseklikte kırmızı "!" uyarısı yanıp söner.
- Her elenen oyuncu 8 sn'de bir terlik atabilir. Terlik dönerek yatay uçar; çarpan oyuncu ölür (Diva kalkanı, Halay Başı hayalet fazı, Turbo ve Yedek Bacak normal şekilde korur).
- Ağ: elenen oyuncu `throw_ghost_slipper(y: float)` gönderir → Host doğrular (gönderen gerçekten elenmiş mi, bekleme süresi geçmiş mi) → `spawn_ghost_slipper(thrower_id, y, launch_match_time)` ile herkese yayınlar. `launch_match_time = şimdiki match_time + 1.2`; her cihaz terliği bu zamanda oluşturur.
- Atılan terliğin üstünde küçük isim etiketi: "Mehmet'ten sevgilerle".
- Elenenler laf atmaya da devam edebilir (7.2).

### 7.4 Komik ölüm akışı

Biri elendiğinde tüm ekranlarda olay akışına ölüm sebebine göre bir satır düşer. `report_death(cause)` içindeki `cause` şunlardan biridir: `ust_engel`, `alt_engel`, `surpriz`, `fuze`, `zemin`, `tavan`, `hayalet_terlik`. Her sebebin kendi havuzu olsun (`GameConfig`), örnekler:
- `ust_engel`: "{isim} annenin terliğine kafa attı."
- `alt_engel`: "{isim} sandalyedeki amcanın çorabına daldı."
- `fuze`: "{isim} aydınlandı. Hem de çok."
- `zemin`: "{isim} tezgâha yapıştı."
- `tavan`: "{isim} tavanda lambayla tanıştı."
- `hayalet_terlik`: "{isim}, {atan}'ın intikamına kurban gitti."
- Sataşma sırasında ölürse ek: "(Teşekkürler {gönderen}!)"

### 7.5 Maç sonu ödül ekranı

Kazanan duyurulduktan sonra, "Tekrar Oyna" butonundan önce 3 sn'lik bir ödül kartı dizisi (her kart 1 sn, kayarak gelir). Değerler maç boyunca Host'ta tutulur:
- **Mahallenin Kralı** — kazanan
- **Çığlık Ustası** — en çok "Ödü Kopan İnsan" toplayan
- **Baş Belası** — en çok sataşma gönderen
- **Terlik Mıknatısı** — ilk elenen
- **İntikam Meleği** — Hayalet Terlik ile birini deviren (varsa)

Lobide galibiyetlerin yanında bu unvanlar da sayılsın (oturum boyunca).

**Bitti sayılması için (Faz 7)**
- 3 pencerede sataşma gönderiliyor, kurbanda 0.6 sn uyarıdan sonra etki başlıyor, bağışıklık çalışıyor, Ayna geri yansıtıyor.
- Hazır laflar tüm pencerelerde doğru böceğin üstünde görünüyor.
- Elenen oyuncu Hayalet Terlik atabiliyor; hayattaki oyuncular uyarıyı görüyor ve terlik herkeste aynı anda geliyor.
- Ölüm akışı ve maç sonu ödül kartları doğru isimlerle görünüyor.
- Tek oyunculuda sataşma güçlendirmeleri hiç çıkmıyor.

---

## Opsiyonel sesler (Faz 5'teki tabloya ekle)
`seviye.ogg`, `kutu_al.ogg`, `dondurma.ogg`, `turbo.ogg`, `bacak_koptu.ogg`, `sataşma_geldi.ogg`, `teyze_ayyy.ogg`, `kahve_hupletme.ogg`, `terlik_at.ogg`, `odul.ogg` — yoksa sessiz geçilir.

## Opsiyonel görseller (`res://assets/sprites/`)
`item_dondurma.png`, `item_turbo.png`, `item_yedek_bacak.png`, `item_miknatis.png`, `item_tavsan_kani.png`, `item_buz_kalibi.png`, `item_turk_kahvesi.png`, `item_kirli_corap.png`, `item_komsu_teyze.png`, `item_ayna.png` (her biri 96x96), `teyze_kafa.png` (300x300), `bacak.png` (48x24), `tezgah.png` (720x180). Yoksa pastel daire + baş harf yedeği kullanılır.

# UÇAN HAMAM BÖCEĞİ — Faz 12: Böcek Kimliği (Kullanıcı ID) ve Arkadaşlarla Oynama

> **Ajan için:** Önceki tüm prompt dosyalarının devamıdır; **GENEL KURALLAR** aynen geçerlidir. Bu faz, Faz 8.9'daki çevrimiçi sunucu (Eşleştirici + Oda Sunucuları) üzerine kurulur; 8.9 çalışmıyorsa önce onu tamamla.
>
> Sırayla uygula ve her birinin sonunda test et: **12A** Kimlik ve hesap → **12B** Arkadaşlık ve durum → **12C** Davet ve arkadaş odaları → **12D** Güvenlik, gizlilik, hesap silme.

---

## 12.1 Böcek Kimliği (12A)

### Kimlik nasıl oluşur
- Oyuncu çevrimiçi bir özelliğe ilk kez girdiğinde (Çevrimiçi ekranı, Arkadaşlar ekranı) sunucu ona kalıcı bir **Böcek Kimliği** verir.
- Biçim: `#XXXX-XXXX`. 8 karakter, karışmayan harf ve rakamlardan (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`; O, 0, I, 1 yok). Örnek: **#7K3M-QX9P**. Sunucu benzersizliği garanti eder.
- Sunucu kimlikle birlikte bir **gizli anahtar** (32 bayt rastgele, `Crypto.generate_random_bytes`) üretir. Cihaz kimliği ve anahtarı `user://hesap.cfg`'de saklar. Sunucu anahtarın kendisini değil, **SHA-256 özetini** saklar.
- Kimlik kalıcıdır. Oyuncu adı (Faz 1) istenildiği zaman değiştirilebilir; kimlik değişmez.
- Şifre, e-posta, telefon numarası **istenmez.**

### Kimliğin görünmesi
- Ana menüde isim kutusunun altında küçük yazıyla: **"Böcek Kimliğin: #7K3M-QX9P"**. Yanında **kopyala** ve **paylaş** butonları.
- Lobide ve sıralama ekranında her gerçek oyuncunun kartında kimliği küçük yazıyla görünür (botlarda görünmez).

### Kimliği kaybetmemek: Kurtarma Kodu
- Ayarlar → **"Hesabım"** ekranında **"Kurtarma Kodu"** butonu. 16 karakterlik bir kod gösterir (sunucu üretir, özetini saklar). Altında uyarı: *"Bu kodu bir yere yaz. Telefon değiştirirsen veya oyunu silersen kimliğini ve arkadaşlarını bununla geri alırsın."*
- **"Kimliğimi Geri Yükle"**: kimlik + kurtarma kodu girilir; sunucu doğrularsa yeni gizli anahtar üretir ve eski cihazın anahtarını geçersiz kılar.
- Kurtarma kodu yeniden üretilebilir (eskisi geçersiz olur).

### Sunucu tarafı veri saklama
- Eşleştirici, kullanıcı verisini `server/data/users.json` dosyasında tutar: `{ id: { name, token_hash, recovery_hash, created, last_seen, friends: [], requests_in: [], requests_out: [], blocked: [], stats: {...} } }`.
- Bellekte tutulur. Değişiklik olunca en geç 10 sn içinde diske yazılır. Yazma güvenli olmalı: önce geçici dosyaya yaz, sonra eski dosyanın yerine taşı. Her gün `users_YYYYMMDD.json` yedeği alınır, son 7 yedek tutulur.
- `server/SUNUCU_KURULUM.md`'ye yedekleme notu eklenir. Kullanıcı sayısı büyürse SQLite gibi bir veritabanına geçilebileceğini belirten bir not da olsun.

---

## 12.2 Kalıcı bağlantı ve çevrimiçi durum (12B)

### Mahalle bağlantısı
- Oyun açıkken ve çevrimiçi özellikler kullanılmışsa, istemci eşleştiriciye **sürekli açık bir TCP bağlantısı** tutar (`res://autoload/Mahalle.gd`, yeni autoload).
- Açılışta: `{"op":"hello","version":X,"id":"7K3MQX9P","token":"..."}` → `{"op":"welcome","id":...,"name":...}`. Kimliği yoksa `hello` kimliksiz gelir ve sunucu yeni kimlik ile anahtar döner.
- Her 20 sn'de bir `{"op":"ping"}`. Bağlantı koparsa 2, 4, 8, … en fazla 60 sn aralıkla yeniden bağlanır.
- Uygulama arka plana alınınca bağlantı 30 sn sonra kapatılır; geri gelince yeniden açılır.
- İnternet yoksa çevrimiçi özellikler gri görünür; oyunun geri kalanı (tek oyunculu, LAN, Botlarla Oyna) etkilenmez.

### Durumlar
| Durum | Ne zaman | Gösterim |
|---|---|---|
| Çevrimiçi | Menüde | Yeşil nokta |
| Odada | Bir lobide | Sarı nokta + "Odada (3/5)" |
| Maçta | Maç oynanıyor | Turuncu nokta + "Maçta" |
| Çevrimdışı | Bağlı değil | Gri nokta + "Son görülme: 2 saat önce" |

Oda sunucuları, odadaki kullanıcı kimliklerini eşleştiriciye her 2 sn'lik durum mesajında bildirir. Eşleştirici bir arkadaşın durumu değişince o kişinin çevrimiçi arkadaşlarına anında haber verir (`{"op":"presence", ...}`).

---

## 12.3 Arkadaşlık (12B)

### Arkadaş ekleme yolları
1. **Kimlikle:** Arkadaşlar ekranında "Arkadaş Ekle" → kimlik girilir (tire ve # isteğe bağlı, küçük harf kabul edilir) → istek gönderilir.
2. **Paylaşım bağlantısıyla:** Ana menüde kimliğin yanındaki paylaş butonu şu metni gönderir: *"Uçan Hamam Böceği'nde arkadaş olalım! Kimliğim: #7K3M-QX9P {SITE}/arkadas.html?k=7K3MQX9P"*. Bağlantı oyunu `ucanbocek://arkadas/7K3MQX9P` ile açar ve "İstek gönderilsin mi?" sorar. `web/arkadas.html` sayfası Faz 9.5'teki `oda.html` mantığıyla hazırlanır.
3. **Birlikte oynadıklarından:** Arkadaşlar ekranında "Son Oynadıkların" sekmesi: son 20 gerçek oyuncu (botlar hariç), yanlarında "Ekle" butonu.
4. **Maç içinden:** Lobide ve sıralama ekranında bir oyuncunun kartına dokununca profil kartı açılır, altında "Arkadaş Ekle".

### İstekler
- Gelen istek, oyuncu çevrimiçiyse anında küçük bir bildirim şeridiyle gelir: *"Ayşe (#AB12-CD34) arkadaş olmak istiyor [Kabul] [Reddet]"*. Çevrimdışıysa bekler; Arkadaşlar butonunun üstünde sayı rozeti görünür.
- Arkadaşlık karşılıklıdır: kabul edilince iki taraf da birbirini görür.
- Sınırlar: en fazla 100 arkadaş, günde en fazla 30 istek gönderme. Reddedilen kişiye 24 saat yeniden istek gönderilemez.

### Arkadaşlar ekranı (ana menüde "Arkadaşlar")
- Sekmeler: **Arkadaşlar**, **İstekler**, **Son Oynadıkların**.
- Liste sırası: önce odada olanlar, sonra çevrimiçi, sonra çevrimdışı (son görülmeye göre).
- Her satırda: karakter ikonu, ad, kimlik, durum noktası, durum yazısı ve duruma göre bir buton:
  - Çevrimiçi → **"Davet Et"** (benim odam varsa) veya **"Oda Kur ve Davet Et"**
  - Odada ve oda arkadaşlara açıksa → **"Katıl"**
  - Maçta → buton yok, "Maç bitince katılabilirsin"
- Satıra uzun basınca: Profil, Arkadaşlıktan Çıkar, Engelle.

### Profil kartı
Ad, kimlik, seçili karakterin önden portresi (Faz 10.3, `gururlu` ifade), istatistikler (toplam maç, galibiyet, Mahalle Muhtarı sayısı, albüm tamamlama), unvanı. İstatistikler her maç sonunda istemciden sunucuya gönderilir; sunucu yalnızca çok oyunculu maçlarda kendi hesapladığı galibiyet sayısını doğru kabul eder.

---

## 12.4 Davet ve arkadaş odaları (12C)

### Oda gizliliği
Özel Oda kurarken (ve lobide oda sahibi tarafından değiştirilebilir) 3 seçenek:
| Seçenek | Kim girebilir |
|---|---|
| **Kodla açık** | Oda kodunu bilen herkes (Faz 8.9'daki eski davranış) |
| **Sadece arkadaşlarım** (varsayılan) | Oda sahibinin arkadaşları ve davet edilenler |
| **Sadece davetliler** | Yalnızca oda sahibinin kimlikle davet ettiği kişiler |

Bir arkadaş odaya girince, onun arkadaşları otomatik olarak giremez; yetki oda sahibinin arkadaş listesine bağlıdır.

### Davet akışı
1. Oda sahibi (veya oda gizliliği "Kodla açık" ya da "Sadece arkadaşlarım" ise odadaki herhangi bir oyuncu) lobideki **"Arkadaş Davet Et"** listesinden çevrimiçi bir arkadaşını seçer.
2. Sunucu davet edilen kişiyi o odanın izin listesine ekler ve ona anlık bildirim gönderir: büyük, ortada bir pencere. Davet edenin portresi ve balonla: *"Ayşe seni mutfağa çağırıyor! (Oda: KTRB, 2/5)"* [**Katıl**] [**Sonra**]. Pencere 30 sn sonra kendiliğinden kapanır.
3. Davet 10 dk geçerlidir. Oyuncu menüye dönerse "Bekleyen davetler" listesinde görür.
4. Davet edilen kişi maçtaysa davet bekletilir, maç bitince gösterilir (maçı bölmez).
5. Davet edilen kişi çevrimdışıysa: davet 10 dk saklanır ve davet edene "Arkadaşın çevrimdışı. Bağlantıyı WhatsApp'tan gönder?" seçeneği sunulur (Faz 9.5 paylaşımı).

### Arkadaşının odasına katılma
- Arkadaşlar listesinde "Katıl" butonu, sunucuya `{"op":"join_friend","id":"..."}` gönderir. Sunucu oda gizliliğine göre izin verir veya *"Bu oda sadece davetlilere açık"* der.
- Maç sürüyorsa: *"Maç bitince otomatik katıl"* seçeneği; maç bitince oyuncu lobiye alınır (Rövanş başlamadan önce).

### Giriş bileti (güvenlik)
- Oyuncu bir odaya artık yalnızca oda kodu ve portla bağlanamaz. Eşleştirici, izin verdiğinde kısa ömürlü bir **giriş bileti** üretir: `{user_id, room_code, expires (60 sn)}` + HMAC-SHA256 imzası (`HMACContext`). İmza anahtarı eşleştirici ile oda süreçleri arasında paylaşılır; oda süreci başlatılırken komut satırıyla değil ortam değişkeniyle verilir.
- İstemci odaya bağlanınca ilk mesajı `register_player(name, char_id, version, ticket)` olur. Oda sunucusu imzayı ve süreyi doğrular, bilet yoksa ya da geçersizse bağlantıyı keser.
- `players` sözlüğüne `user_id` alanı eklenir.

### LAN modu
- LAN odaları sunucusuz çalışmaya devam eder; kimlik gerekmez.
- Oyuncunun kimliği varsa LAN lobisinde kartında görünür ve "Arkadaş Ekle" butonu çalışır (istek, internet olduğunda sunucuya iletilmek üzere sıraya alınır).

---

## 12.5 Güvenlik, gizlilik ve hesap silme (12D)

### Bağlantı güvenliği
- Yayın sürümünde eşleştirici bağlantısı **TLS** ile şifrelenir (`StreamPeerTLS`, sunucu tarafında `TLSOptions.server()`). Bunun için sunucuya bir alan adı ve Let's Encrypt sertifikası gerekir. `SUNUCU_KURULUM.md`'ye adım adım ekle: alan adını VPS'e yönlendirme, `certbot` ile sertifika alma, otomatik yenileme, Godot sunucusuna sertifika yollarını verme.
- Geliştirme sırasında `GameConfig.USE_TLS = false` ile şifresiz çalışabilir. Yayın derlemesinde false ise açılışta konsola büyük bir uyarı yazılır.
- Gizli anahtar ve kurtarma kodu hiçbir zaman loglara yazılmaz.

### Kötüye kullanıma karşı
- **Engelle:** Engellenen kişi seni arkadaş listesinde göremez, istek ve davet gönderemez, aynı özel odaya giremez. Hızlı Oyun'da aynı odaya düşürülmez (sunucu eşleştirirken kontrol eder).
- **Bildir:** Profil kartında (Faz 11.7'deki bildirim sistemiyle aynı). Sebepler: uygunsuz isim, taciz, hile, diğer.
- İsimler sunucuda filtrelenir (Faz 8.9). Uygunsuz isim bildirilen hesabın adı oda sahibi ve diğer oyunculara "Böcek #7K3M" olarak gösterilebilir (`server/moderation.json`'da elle işaretlenen kimlikler için).
- Sunucu hız sınırları: kimlik başına dakikada en fazla 60 mesaj; aşan bağlantı 5 dk kapatılır.

### Hesap silme (Play Store zorunluluğu)
- Ayarlar → Hesabım → **"Hesabımı Sil"**. Önce uyarı: *"Kimliğin, arkadaşların ve istatistiklerin kalıcı olarak silinir. Bu geri alınamaz."* Ardından kimliği yazarak onaylama.
- Sunucu kullanıcı kaydını, arkadaş bağlantılarını (karşı tarafların listelerinden de), istekleri ve davetleri siler; kimlik bir daha başkasına verilmez (silinmiş kimlikler listesi tutulur).
- Cihazdaki `hesap.cfg` silinir. Kırıntı, açılan karakterler ve satın alımlar cihazda kalır; satın alımlar zaten Google hesabına bağlıdır ve geri yüklenebilir.
- `web/hesap-silme.html`: Play Store'un istediği **web üzerinden silme talebi** sayfası. Oyuncunun kimliğini ve kurtarma kodunu girip silme isteği göndermesini sağlayan basit bir form. Form, eşleştiricinin `{"op":"delete_account","id":..,"recovery":..}` mesajını işleyen küçük bir HTTP ucuna gönderir; sunucu tarafında bunun için basit bir HTTP dinleyici (`TCPServer` üzerinde minimal bir HTTP yanıtlayıcı, sadece bu tek uç) yaz. Alternatif olarak sayfada e-posta ile talep yolu da yazsın (`{DESTEK_EPOSTA}` yer tutucusu).
- `web/gizlilik.html`'e kimlik bölümü eklenir: hangi verinin tutulduğu (rastgele kimlik, oyuncu adı, arkadaş listesi, oyun istatistikleri, son görülme), neden tutulduğu, nasıl silineceği. Kişisel bilgi (e-posta, telefon, konum) toplanmadığı belirtilir.

---

## Bitti sayılması için

**12A**
- [ ] İlk çevrimiçi girişte `#XXXX-XXXX` kimliği veriliyor, ana menüde görünüyor, kopyalanıyor ve paylaşılıyor.
- [ ] Uygulama silinip yeniden kurulunca kurtarma koduyla aynı kimlik ve arkadaşlar geri geliyor; eski cihazın anahtarı geçersiz oluyor.
- [ ] Sunucu yeniden başlatılınca kullanıcılar kaybolmuyor; günlük yedek oluşuyor.

**12B**
- [ ] Yerelde 3 istemciyle: kimlikle istek gönderiliyor, kabul ediliyor, iki tarafta da görünüyor; durum noktaları (çevrimiçi/odada/maçta/çevrimdışı) anında değişiyor.
- [ ] Paylaşım bağlantısı ve "Son Oynadıkların" ile arkadaş ekleniyor; sınırlar çalışıyor.

**12C**
- [ ] Davet edilen arkadaşa ortada davet penceresi çıkıyor, "Katıl" ile odaya giriyor; maçtaki arkadaşa davet maç bitince gösteriliyor.
- [ ] "Sadece arkadaşlarım" ve "Sadece davetliler" odalarına izinsiz kişi kodla giremiyor; giriş bileti olmadan oda sunucusuna bağlanılamıyor.
- [ ] Arkadaşlar listesindeki "Katıl" butonu oda gizliliğine uygun çalışıyor.

**12D**
- [ ] Engellenen kişi istek/davet gönderemiyor, aynı odaya düşmüyor.
- [ ] "Hesabımı Sil" sunucudaki tüm kayıtları ve karşı tarafların listelerindeki bağlantıları siliyor; `hesap-silme.html` ve güncel `gizlilik.html` hazır.
- [ ] TLS kurulum adımları `SUNUCU_KURULUM.md`'de var; `USE_TLS = true` ile yerel test sertifikasıyla bağlantı kuruluyor.

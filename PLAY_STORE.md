# Play Console — Kapalı Test Kılavuzu

Bu sürüm: **1.0 (sürüm kodu 1)** · Paket: `com.aykut.ucanhamambocegi` · Çevrimdışı sürüm (sunucu, hesap, reklam, satın alma yok).

## Yüklenecek dosyalar (`play_teslim/` klasörü, git dışı)

| Dosya | Play Console'da nereye |
|---|---|
| `ucan_hamam_bocegi.aab` | Test → Kapalı test → Yeni sürüm oluştur → App bundle |
| `ikon_512.png` | Ana mağaza girişi → Uygulama simgesi (512x512) |
| `tanitim_1024x500.png` | Ana mağaza girişi → Öne çıkan grafik |
| `ekran_1.png` … `ekran_6.png` | Ana mağaza girişi → Telefon ekran görüntüleri (1080x1920) |

**İmza:** AAB, upload anahtarıyla imzalı. İlk yüklemede Play "Play Uygulama İmzalama"yı açmanı ister: **Google'ın oluşturduğu anahtarı kullan** seçeneğini kabul et.
Upload anahtarı ve şifresi: `%APPDATA%\Godot\keystores\ucan_hamam_upload.keystore` ve yanındaki `ucan_hamam_upload_SIFRE.txt`. **İkisini de yedekle** (USB/bulut). Kaybedersen Play'den upload anahtarı sıfırlama istenebilir ama günler sürer.

## Mağaza metinleri

**Uygulama adı (30):** Uçan Hamam Böceği

**Kısa açıklama (80):**
Terliklerden kaç, mutfağın son böceği sen ol! Komik, hızlı, mahalle usulü.

**Tam açıklama:**
```
Mutfakta ışık yandı, terlikler havada! Uçan Hamam Böceği'nde ekrana dokun, kanat çırp ve mahallenin en inatçı böceği ol.

• 13 komik böcek: Diva, Duktur, Halay Başı, Kahvehane Dayısı, Saftirik ve diğerleri. Her birinin kendi yeteneği var.
• Annem Geldi, Elektrik Kesildi, Misafir Var, Belediye İlaçlıyor: oyun ortasında patlayan ani olaylar.
• Günün Mutfağı: bugün herkes aynı parkurda, rekorunu kır.
• Kolay, Normal, Zor: kendine göre zorluk seç.
• Aynı Wi-Fi'deki arkadaşlarınla oda kur, botlarla yarış, son böcek sen ol.
• Günlük görevler, seri ödülleri, böcek albümü ve elenme kartı: sinirlen, paylaş, rövanş iste.

Not: Oyun hafif argo içeren mizah barındırır; Ayarlar'dan argo sansürünü açabilirsin.
```

**Sürüm notu (kapalı test):**
```
İlk kapalı test sürümü. Sesler ve çevrimiçi mod henüz yok; hata, takılma ve zorluk hakkındaki görüşlerini bekliyoruz.
```

## Uygulama içeriği formları

| Form | Cevap |
|---|---|
| Gizlilik politikası | https://rabbace.github.io/ucan-hamam-bocegi/gizlilik.html |
| Uygulama erişimi | Tüm işlevler özel erişim gerektirmez (giriş yok) |
| Reklamlar | Hayır, reklam içermiyor |
| Hedef kitle | 13–15, 16–17, 18+ (13 altını **seçme**; argo var) · Çocuklara hitap ediyor mu: Hayır |
| Kategori | Oyun → Arcade |
| İletişim e-postası | aykutdiren2@gmail.com |
| Haber uygulaması / COVID / devlet / finans / sağlık | Hayır |

**İçerik derecelendirmesi (anket) — önerilen cevaplar:**
- Şiddet: **Evet, çizgi film/fantastik** (terlikle böcek kovalama; kan yok, gerçekçi değil).
- Küfür / kaba dil: **Evet, hafif** (argo şakalar; sansür ayarı var).
- Cinsellik, uyuşturucu, kumar: Hayır. (Repliklerde "sigara, içki, kumar" lafı ses dosyaları gelince eklenecek; o zaman anketi güncelle.)
- Kullanıcılar etkileşim kurabilir mi: **Evet** (aynı Wi-Fi'de sesli sohbet ve hazır laflar).
- Konum paylaşımı: Hayır. Dijital satın alma: Hayır (bu sürümde mağaza kapalı).
- Beklenen sonuç: PEGI 12 / USK 12 civarı.

**Veri güvenliği (Data safety) — temkinli öneri:**
Oyun bize hiçbir veri göndermez. Ama aynı Wi-Fi'de ses ve oyuncu adı başka cihazlara gittiği için şu şekilde beyan etmek en güvenlisi:
- Veri topluyor veya paylaşıyor mu: **Evet**
- Aktarım sırasında şifreleniyor mu: **Hayır** (yerel ağ bağlantısı şifresiz)
- Silme talebi: Sunucuda veri yok; "uygulamayı kaldırınca silinir" açıklaması.
- **Ses ve sesli kayıtlar → Ses kayıtları:** Toplanıyor · Paylaşılmıyor · **Geçici işleniyor** · İsteğe bağlı · Amaç: Uygulama işlevselliği
- **Uygulama etkinliği → Diğer kullanıcı içeriği** (oyuncu adı): Toplanıyor · Paylaşılmıyor · Geçici işleniyor · İsteğe bağlı · Amaç: Uygulama işlevselliği
- Diğer tüm kategoriler: Hayır.

> Bu yorum Google'ın tanımlarına göre benim en iyi tahminim; form ekranındaki açıklamalarla bir kez karşılaştır.

## Kapalı test kuralı (yeni kişisel hesaplar)

2023'ten sonra açılan kişisel geliştirici hesaplarında üretime çıkmadan önce **en az 12 test kullanıcısının 14 gün kesintisiz** kapalı testte kalması gerekiyor. Test kullanıcılarını Gmail adresleriyle bir e-posta listesine ekle; Play'in verdiği katılma bağlantısını onlara gönder.

## Bilinen eksikler (test kullanıcılarına söyle)

- Seslerin çoğu henüz yok (Flow videoları bekleniyor).
- Çevrimiçi mod "Yakında"; aynı Wi-Fi ve botlar çalışıyor.
- 7 mahalle insanı görselinin bir yarısı kodla çizilmiş yedek.

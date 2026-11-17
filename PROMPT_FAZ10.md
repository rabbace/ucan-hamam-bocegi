# UÇAN HAMAM BÖCEĞİ — Faz 10: Karaktere Özel Ödüller, Gerçek İkonlar, Sinirli Büyük Yüz

> **Ajan için:** Önceki tüm prompt dosyalarının (PROMPT.md, FAZ6_7, FAZ8, FAZ9) devamıdır. **GENEL KURALLAR** aynen geçerlidir. Sırayla uygula: önce 10.1 (ikonlar), sonra 10.2 (karaktere özel ödüller), sonra 10.3 (sinirli yüz). Her birinin sonunda test et.

---

## 10.1 İkon sistemi: harf yok, gerçek görsel var

**Kural:** Oyunun hiçbir yerinde güçlendirme veya ödül ikonu olarak **harf kullanılmaz** ("D", "M" gibi yedekler kaldırılır). Her ikon bir görseldir.

### Kaynak: Noto Emoji görselleri
- İkonlar Google'ın açık kaynak **Noto Emoji** setinden alınır (Apache 2.0 lisansı, ticari kullanım serbest; lisans metni ve atıf eklenmesi şartıyla).
- Ajan, aşağıdaki tablodaki her ikon için `https://github.com/googlefonts/noto-emoji` deposunun `png/128/emoji_u<kod>.png` dosyasını indirip `res://assets/sprites/items/<item_id>.png` adıyla kaydetsin.
- Lisans: `res://assets/sprites/items/LICENSE_NOTO_EMOJI.txt` (Apache 2.0 metni) ve ana menüde **"Emeği Geçenler"** ekranına şu satır: "Güçlendirme ikonları: Noto Emoji, Google (Apache 2.0)".
- İkonlar ekranda tek başına bırakılmaz: altında pastel yuvarlak bir **"tabak"** (kırıntı tepsisi), hafif gölge ve ince koyu kenar olur. Böylece emoji hazır görünmez, oyunun el yapımı tarzına oturur.
- Kullanıcı kendi çizimini aynı dosya adıyla koyarsa o kullanılır.

### Yedek (indirilemezse)
`res://core/IconFactory.gd`: her ikon için kodla çizilmiş basit bir şekil (ör. dondurma = koni + iki top, mıknatıs = kırmızı U + gri uçlar, kahve = fincan + buhar çizgileri, anahtar = İngiliz anahtarı silueti). `Image` üzerine çizilir, `ImageTexture` olarak önbelleğe alınır. **Harf değil, şekil.**

### Genel güçlendirme ikonları (Faz 6–7'deki isimler güncellendi)
| item_id | Ad | Emoji | Noto kodu |
|---|---|---|---|
| `dondurma` | Dondurma | 🍨 | `1f368` |
| `turbo` | Turbo Kanat | 🚀 | `1f680` |
| `yedek_bacak` | Yedek Bacak | 🦵 | `1f9b5` |
| `miknatis` | Kırıntı Mıknatısı | 🧲 | `1f9f2` |
| `kum_saati` | **Kum Saati** (eski adı "Tavşan Kanı"; yetenek bekleme süresini sıfırlar) | ⏳ | `23f3` |
| `buz_kalibi` | Buz Kalıbı (sataşma) | 🧊 | `1f9ca` |
| `seker_bombasi` | **Şeker Bombası** (eski adı "Türk Kahvesi"; etkisi aynı: rakip hiperaktif olur) | 🍬 | `1f36c` |
| `kirli_corap` | Kirli Çorap (sataşma) | 🧦 | `1f9e6` |
| `komsu_teyze` | Komşu Teyze (sataşma) | 👵 | `1f475` |
| `ayna` | Ayna | 🪞 | `1fa9e` |
| `gizemli` | Gizemli kutu (bkz. 10.2) | 🎁 | `1f381` |

> İsim değişikliklerinin nedeni: kahve ikonu artık Plaza Böceği'ne, çay ikonu Kahvehane Dayısı'na özel. Tüm metinlerde, rehberde ve `GameConfig` replik havuzlarında eski adları yenileriyle değiştir. Şeker Bombası'nda kurbanın ekranındaki yazı: *"Şeker komasına girdin!"*

---

## 10.2 Her karakterin kendine özel ödülü

### Kural
- Her karakterin bir **imza ödülü** vardır. Bu ödül yalnızca o karakterle oynarken kutulardan çıkar.
- Kutu dağılımı: bir kutunun **%30**'u "imza" kutusudur, gerisi genel güçlendirmedir. Oranlar `GameConfig.SIGNATURE_DROP_RATE` ile ayarlanır.
- **Çok oyunculuda adalet:** Kutuların yeri ve "genel mi imza mı" bilgisi seed'den gelir; herkeste aynıdır. İmza kutusunun içeriği her oyuncunun kendi karakterine göre değişir. Bu yüzden imza kutuları dünyada **🎁 gizemli kutu** olarak görünür ve ikon toplanınca açılır. Genel kutular kendi ikonuyla görünür.
- İmza ödülü tepsiye normal güçlendirme gibi girer ve aynı şekilde kullanılır (dokun / iki parmak).
- Toplandığında karakter kendi repliğini söyler ve ikon tepside parıltıyla belirir.

### İmza ödülleri
| Karakter | Ödül | Emoji / Noto kodu | Etki | Replik |
|---|---|---|---|---|
| Klasik | **Bayat Ekmek** | 🍞 `1f35e` | 5 sn boyunca hitbox ayrıca %15 küçülür ve yakın kaçış puanı ×2. | *"Eski dost, eski ekmek."* |
| Diva | **Ruj Tazeleme** | 💄 `1f484` | Kalkan bekleme süresini anında sıfırlar; bir sonraki kalkan 1 sn uzun sürer. | *"Önce makyaj, sonra kaçış."* |
| Duktur | **Aşı** | 💉 `1f489` | 8 sn boyunca tüm sataşmalara ve böcek ilacı bulutuna bağışıklık. | *"Aşını oldun mu?"* |
| Halay Başı | **Davul** | 🥁 `1f941` | 4 sn boyunca ekrandaki insan engelleri aynı ritimde, yavaş ve öngörülebilir şekilde sallanır (halay çeker). Rakiplerin ekranında 1 sn kısa konfeti. | *"Davulcu geldi, halay başlasın!"* |
| Plaza (ofis böceği) | **Filtre Kahve** | ☕ `2615` | 6 sn boyunca iki yeteneğin bekleme süresi 2 kat hızlı dolar. Böcek hafifçe titrer. | *"Üçüncü kahve, toplantıya hazırım."* |
| Sanayi Ustası | **İngiliz Anahtarı** | 🔧 `1f527` | Önündeki ilk engel çiftini anında söker (yerel). Anahtar dönerek uçar, engel parçalanır. | *"Söktüm abi, hayırlı olsun."* |
| Emlakçı | **Yedek Anahtar** | 🔑 `1f511` | 5 sn boyunca engellerin "kapısı açılır": gap'ler %25 genişler. | *"Anahtar teslim, buyrun."* |
| Siber | **Pil** | 🔋 `1f50b` | İki yeteneğin bekleme süresini anında doldurur. | *"Şarj yüzde yüz."* |
| Yurt | **Gece Eriştesi** | 🍜 `1f35c` | Oda Arkadaşı'nı anında çağırır (bekleme süresine bakmaz). | *"Erişte kokusuna geldi."* |
| Kahvehane Dayısı | **Demlik Çay** | 🫖 `1fad6` | 6 sn boyunca yakın kaçış mesafesi +10 px ve her yakın kaçışa +1 Kırıntı. | *"Tavşan kanı, tam kıvamında."* |
| Taraftar | **Top** | ⚽ `26bd` | Frikik'i bekleme süresine bakmadan bir kez kullanır. | *"Ver topu bana!"* |
| Deli Böcek | **Acı Biber** | 🌶️ `1f336` | 4 sn boyunca böcek kıpkırmızı olur, kulaklarından (antenlerinden) duman çıkar, zıplama gücü ×1.2 ve ilk çarptığı engeli yakıp geçer. Kontrol biraz "çılgınlaşır": her zıplamada ±%10 rastgele güç (görsel RNG). | *"Acı mı? Ben acıyı yerim!"* |

> **Deli Böcek:** Projede bu karakter zaten varsa yalnızca imza ödülünü ekle. Yoksa Faz 8.3 yapısına uygun yeni bir karakter olarak ekle: pasif **"Delilik Sınırı"** (bekleme süreleri her maç rastgele ±%20; görsel RNG, oyuncuya maç başında gösterilir), Aktif 1 **"Kuduruk Dans"** (2 sn hayalet fazı + ekranda zikzak çizer, 15 sn), Aktif 2 **"Kafayı Yedim"** küçülme `0.55`, 2.5 sn. Fiyatı 3000 Kırıntı.

### Yetenekler ekranına ekleme
Faz 8.4'teki Yetenekler ekranında 3 yetenek satırının altına 4. satır gelir: **İMZA ÖDÜLÜ** etiketi (pastel sarı), ikon, ad, etki ve "Kutulardan %30 ihtimalle çıkar" notu.

### Rehber
"Güçlendirmeler" sayfasına bir cümle ekle: "Her böceğin kendine özel bir ödülü var. Gizemli kutuları topla!"

---

## 10.3 Oyun sonunda sinirli, büyük, önden yüz

### Önden portre (Portrait Rig)
Her karakter için oyuncuya dönük, büyük bir **önden yüz** düzeni. Ayrı bir sahne: `res://scenes/ui/CharacterPortrait.tscn`.

```
CharacterPortrait (Control, ortalanmış)
├── Antenler (Sol/Sag, yay fiziği, sinirde titrer)
├── Kafa
├── Kaslar (Sol/Sag, ifadeye göre açı değişir)
├── Gozler (iri, bebekler oyuncuyu izler: dokunma noktasına bakar)
├── Agiz (bagir / gul / kapali / dudak_buz)
├── Aksesuar (gözlük, kasket, steteskop, kravat…)
├── Eller (Sol/Sag: yumruk sallama, parmak sallama)
└── BuharParcacik (kafanın iki yanından buhar)
```

**Görseller:** `res://assets/sprites/chars/<id>/portre/` altında `kafa.png, kas.png, goz.png, goz_bebek.png, agiz_bagir.png, agiz_gul.png, agiz_kapali.png, aksesuar.png, el_yumruk.png, el_parmak.png` (önerilen kafa boyutu 512x512). Dosyalar yoksa pastel yedek şekiller çizilir (büyük daire kafa, iri beyaz gözler, kalın kaş çizgileri, açık ağız). `PARCA_REHBERI.md`'ye portre bölümünü ekle.

### İfadeler
| İfade | Kaşlar | Gözler | Ağız | Eller | Ek efekt |
|---|---|---|---|---|---|
| `sinirli` | Çatık, içe doğru | Kısık, kırmızımsı ton | `bagir` | Yumruk sallar | Kafanın iki yanından buhar, kafa hafif kızarır (nabız gibi), titreme |
| `cok_sinirli` (5. dokunuş) | Daha çatık | Damarlı | `bagir`, daha büyük | İki yumruk | Buhar ×2, ekran sarsılır |
| `gururlu` (kazanınca) | Bir kaş kalkık | Bir göz kırpar | `gul` | Parmak sallar | Parıltılar, karakterin aksesuarı parlar (Diva gözlük indirir) |
| `kus` (2. olunca) | Düz | Yarı kapalı | `dudak_buz` | — | Tek damla gözyaşı, "Az kalmıştı" balonu |

### Ne zaman, nasıl çıkar
- **Tek oyunculu ölüm:** Faz 8.8'deki 2.5 sn siyah-beyaz efektten sonra portre ekranın altından fırlar. Animasyon: ölçek 0.6 → 1.08 → 1.0, 0.35 sn. Ekran genişliğinin ~%70'ini kaplar, ekranın ortasında durur. "ELENDİN" paneli ve butonlar portrenin altında kalır.
- **Çok oyunculu sıralama ekranı (8.6):** Ekranın üst kısmında yerel oyuncunun portresi. 1. olduysa `gururlu`, 2. olduysa `kus`, diğer sıralarda `sinirli`. Satırlar portrenin altından kayarak gelir.
- **Çok oyunculu elenme anı:** Oyun bitmeden elenince portre yalnızca 1.5 sn küçük boyutta (ekranın %40'ı) köşede belirip kaybolur. İzlemeyi engellememeli.

### Sinir repliği (balon + ses)
Portre çıkınca yanında büyük bir konuşma balonu ve karakterin `sinir.ogg` sesi (`res://assets/sounds/chars/<id>/`; yoksa sessiz) çalar. `CharacterData`'ya `lose_lines` (en az 3) ve `win_lines` eklenir. Örnekler:
| Karakter | Sinirli replik |
|---|---|
| Klasik | "Bu mutfakta bir daha görüşeceğiz!" |
| Diva | "Bu terlik bana mı fırlatıldı?! Avukatım arayacak!" |
| Duktur | "Bu bir tıbbi hataydı, rapor yazıyorum!" |
| Halay Başı | "Halayı bozdunuz ya, halayı!" |
| Plaza | "Bunu İK'ya bildiriyorum!" |
| Usta | "Abi bu parça orijinal değildi!" |
| Emlakçı | "Depozitonu yaktım, haberin olsun!" |
| Siber | "HATA 404: Hayat bulunamadı." |
| Yurt | "Yurttan atılmak bundan iyiydi!" |
| Kahvehane Dayısı | "Bizim zamanımızda böyle terlik yoktu!" |
| Taraftar | "Hakem! Penaltı bu, penaltı!" |
| Deli Böcek | "Hahaha… şaka şaka. ÇOK SİNİRLİYİM!" |

### Etkileşim
- **Portreye dokununca** karakter yeni bir sinir repliği söyler ve gözleri dokunulan yere bakar.
- **5. dokunuşta** `cok_sinirli` ifadeye geçer ve şöyle bağırır: *"Tamam! Bi el daha!"* Ardından "Tekrar Dene" (tek oyunculu) veya "Tekrar Oyna" (oda sahibinde) butonu büyüyüp nabız gibi atar. Oyuncuyu tatlı bir şekilde yeni ele iter.
- Portre, Faz 9.5'teki **paylaşım görseline** de girer: sinirli büyük yüz + replik balonu + skor + "Sıra sende" yazısı. Paylaşım kartı için ekran görüntüsü yerine ayrı bir `SubViewport` (1080x1350, dikey gönderi oranı) içinde düzenli bir kart oluştur.

### Performans
Portre animasyonları `Tween` ve `AnimationPlayer` ile yapılır. Buhar parçacıkları en fazla 24 adet olsun. Portre sahnesi menüden önceden yüklenir; ölüm anında takılma olmasın.

---

## Bitti sayılması için (Faz 10)
- [ ] Oyunda hiçbir yerde harf ikonu kalmadı; tüm güçlendirmeler Noto Emoji görseliyle ve pastel tabak üstünde görünüyor; indirme başarısızsa kodla çizilmiş şekiller çıkıyor; lisans dosyası ve "Emeği Geçenler" satırı var.
- [ ] "Tavşan Kanı" → "Kum Saati", "Türk Kahvesi" → "Şeker Bombası" isim değişiklikleri her yere yansıdı.
- [ ] Her karakterle oynarken gizemli kutulardan o karakterin imza ödülü çıkıyor ve etkisi çalışıyor. Çok oyunculuda kutu yerleri herkeste aynı, içerikleri karaktere göre farklı.
- [ ] Yetenekler ekranında İMZA ÖDÜLÜ satırı görünüyor.
- [ ] Tek oyunculu ölümde sinirli büyük yüz fırlıyor, replik söylüyor; 5 dokunuşta "Bi el daha!" diyor ve tekrar butonu nabız atıyor.
- [ ] Sıralama ekranında 1. gururlu, 2. küs, diğerleri sinirli portreyle görünüyor.
- [ ] Paylaşım kartı portreyle birlikte 1080x1350 olarak oluşuyor.
- [ ] Görsel ve ses dosyaları yokken hata yok.

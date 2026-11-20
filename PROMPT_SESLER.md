# Eksik Sesler (Antigravity / Google AI Studio / Flow için)

Bu dosya hem insan (elle üretirken) hem de Antigravity ajanı için yazıldı.
Oyun aşağıdaki dosyalar **yokken de çalışır** (kodla üretilen bip/ton ya da sessizlik kullanılır); dosya klasöre konduğu anda kendiliğinden kullanılır.
**Kod değiştirmeye gerek yok.** Sadece doğru ada ve klasöre koymak yeterli.

Mevcut sesler (`assets/sounds/kufur_*.wav`, `sevinc_*.wav`, `diva_*.wav`, `gahpe.wav` ...) **24 kHz, mono, 16-bit WAV**. Bu, Gemini TTS'in doğrudan verdiği biçim; yeni konuşmalar da aynı yoldan üretilirse tını tutarlı olur. Referans olarak bu dosyaları dinle.

## Hangi araçla?

| Tür | Önerilen araç | Not |
|---|---|---|
| Konuşma (replik) | **Gemini TTS** (AI Studio "Generate speech" ya da API: `gemini-2.5-pro-preview-tts` / `gemini-2.5-flash-preview-tts`) | Türkçe destekli; tarz istemle verilir ("sinirli, Karadenizli dayı gibi"...). Çıktı 24 kHz PCM. |
| Efekt (terlik, kapı zili, siren...) | Önce Veo / Flow (videonun sesini al), olmazsa CC0 kütüphane (freesound.org, sadece **CC0** lisanslı) | Flow videosundan ses: `ffmpeg -i video.mp4 -vn -ac 1 -ar 44100 cikti.wav` |
| Müzik | Lyria (AI Studio / MusicFX) | Döngü olacak; başı-sonu temiz kesilsin. |

**Önemli:** Sosyal medyada dolaşan hazır böcek videolarının sesini **kesip kullanma** (başkasının içeriği, mağazada telif şikâyeti alır). Aynı **tarzda**, aşağıdaki **kendi repliklerimizle** yeni ses üret.

## Teslim kuralları

- Dosya adı ve uzantısı birebir tablodaki gibi (küçük harf, Türkçe karakter yok).
- **Mono**, 44.1 kHz (konuşmada 24 kHz da olur), başta ve sonda sessizlik **kırpılmış** (en fazla 50 ms).
- Ses seviyesi: tepe −1 dBFS, konuşmalar birbirine yakın yükseklikte (yaklaşık −16 LUFS).
- `.ogg` yazan yerde Ogg Vorbis ver: `ffmpeg -i girdi.wav -ac 1 -ar 44100 -c:a libvorbis -q:a 5 cikti.ogg`
- `ozur_dilerim.ogg` ve `turbo_kokle.ogg` **mutlaka .ogg** olmalı (kod yalnızca bu adı arıyor). Diğerlerinde `.wav` de çalışır.
- Konuşmaları **doğal perdede** üret; oyun her karakterin sesini kendisi inceltiyor (`voice_pitch` 0.95–1.30). Sincap gibi tiz üretme, iki kat incelir.
- Küfür yok: repliklerde `@#%` yazan yerde gerçek küfür söylenmez, yerine kısa bir **"dıııt" bip** ya da yutulmuş bir "ulan..." gelir.
- Klasörü yoksa oluştur. Bittikten sonra: `Godot --headless --path . --import` hatasız çalışmalı.

---

## 1) Karakter dokunma replikleri — öncelik YÜKSEK (39 dosya)

Karakter seçme ekranında karta dokununca çalar. Klasör: `assets/sounds/chars/<id>/`, dosyalar `dokun_1.ogg`, `dokun_2.ogg`, `dokun_3.ogg` (sırasıyla tablodaki 1., 2., 3. replik). Her biri 0.8–2.5 sn.

| id | Karakter | Ses tarifi (TTS istemine ekle) | dokun_1 | dokun_2 | dokun_3 |
|---|---|---|---|---|---|
| `klasik` | Klasik Böcek | sıradan mahalle delikanlısı, rahat, hafif alaycı | Efendim? | Ben buranın eskisiyim. | Işığı kapat, utanıyorum. |
| `diva` | Diva Böcek | kadın, şımarık, "ayol"lu, abartılı | Ayy dokunma, ojem yeni! | Fotoğrafım çekilecekse önce haber verin. | Bu mutfak bana küçük. |
| `duktur` | Duktur Böcek | kendini doktor sanan, ağır, "duktur" diye söyleyen | Ağzını aç, aaa de. | Bu kırıntı çok yağlı. | Randevun var mıydı? |
| `halaybasi` | Halay Başı | coşkulu, düğün havasında, bağırarak | Hadi kalk, halaya! | Mendil nerde mendil? | Davulcu nerde kaldı? |
| `plaza` | Plaza Böceği | aceleci beyaz yaka, telefonla konuşur gibi | Toplantıdayım, sonra dönerim. | Bunu mail atar mısın? | Cuma'ya yetiştiririz. |
| `usta` | Sanayi Ustası | kalın sesli, işini bilen usta, ağır | Abi motor inecek. | Bir kahve koy, bakarız. | Bu orijinal parça değil. |
| `emlakci` | Emlakçı | tatlı dilli satıcı, hızlı konuşan | Depozito iki kira. | Metroya yürüme mesafesi. | Lavabo altı, ferah daire. |
| `siber` | Siber Böcek | robotik, düz tonlu, hafif dijital | Sistem başlatıldı. | Şarjım yüzde on beş. | Güncelleme var, yükleyeyim mi? |
| `yurt` | Yurt Böceği | uykulu öğrenci, esneyerek | Yemekhane açık mı? | Oda arkadaşım yine yok. | Yoklamaya beni de yaz. |
| `dayi` | Kahvehane Dayısı | yaşlı, tok sesli, nasihat eden | Bir çay söyle evladım. | Bizim zamanımızda terlik yoktu. | Okey dördüncüsü lazım. |
| `taraftar` | Taraftar | maç tribününde, bağıran, kısık sesli | Bu sene bizim sene! | Hakem kör mü? | Doksana takarım! |
| `saftirik` | Saftirik | şaşkın, saf, ağzı açık konuşan | Abi bu otobüs Taksim'e gider mi? | Akbilim bitmiş ya. | Bana mı baktın abi? |
| `deli` | Deli Böcek | çılgın, kahkahalı, hızlı | Benim raporum var! | Terlikler uçuyor mu? | Doktor bey kapıyı aç! |

Örnek TTS istemi (AI Studio "Style instructions" alanına):
> Bir çizgi film hamam böceği karakterisin. Sıcak, komik, Türk mahalle mizahı. Tarz: yaşlı, tok sesli, nasihat eden kahvehane dayısı. Doğal hızda, abartılı tonlamayla söyle: "Bir çay söyle evladım."

## 2) Oyun içi sesli replikler — öncelik YÜKSEK (3 dosya)

Klasör: `assets/sounds/`

| Dosya | Ne zaman | Tarif |
|---|---|---|
| `ozur_dilerim.ogg` | Rakibe sataşma eşyası atınca | Alaycı, sırıtarak: "Özür dilerim pıttığım!" (≈1.5 sn) |
| `teyze_ayyy.ogg` | Komşu teyze olayı başlayınca | Yaşlı kadın, şaşkın tiz çığlık: "Ayyyy! Böcek!" (≈1 sn) |
| `kahve_hupletme.ogg` | Türk kahvesi sataşması | Kahveyi yüksek sesle höpürdetme + "aaah" (≈1 sn), konuşma yok |

## 3) Efektler — öncelik ORTA (19 dosya)

Klasör: `assets/sounds/`. Hepsi kısa ve vurucu; mobil hoparlörde net duyulsun (çok bas olmasın).

| Dosya | Süre | Ne zaman / tarif |
|---|---|---|
| `ucus.ogg` | 0.1 sn | Her kanat çırpışı: kısa, hafif "vırt" kanat vızıltısı (çok sık çalar, yorucu olmasın) |
| `terlik_at.ogg` | 0.4 sn | Terlik fırlatılıyor: havada "vuuş" |
| `terlik_kirildi.ogg` | 0.4 sn | Terlik kırıldı: plastik "krak" |
| `bacak_koptu.ogg` | 0.3 sn | Komik "pıt" kopma sesi (iğrenç değil, çizgi film) |
| `fuze.ogg` | 0.6 sn | Oyuncak füze geçişi: "fiiyuuu" |
| `turbo.ogg` | 0.6 sn | Turbo: motor "vınnn" hızlanma |
| `turbo_kokle.ogg` | 1.0 sn | Turbo sataşması: motoru kökleme, egzoz patlaması |
| `dondurma.ogg` | 0.8 sn | Beyin donması: buz "çıtırtı" + titrek "ıııh" |
| `kutu_al.ogg` | 0.3 sn | Eşya kutusu toplama: neşeli "pling" |
| `odul.ogg` | 1.2 sn | Maç sonu ödül: kısa fanfar |
| `seviye.ogg` | 0.8 sn | Hız seviyesi arttı: yükselen "vuup" |
| `satasma_geldi.ogg` | 0.6 sn | Sana sataşma geldi uyarısı: komik alarm "ding-ding" |
| `anahtar.ogg` | 1.0 sn | "Annem geldi" olayı: kapıda anahtar şıkırtısı |
| `siren.ogg` | 1.2 sn | Belediye ilaçlaması: kısa belediye sireni |
| `klik.ogg` | 0.15 sn | Elektrik kesildi: şalter "klik" |
| `buzdolabi.ogg` | 1.0 sn | Elektrik geldi: buzdolabı motoru "vrrr" devreye girer |
| `kapi_zili.ogg` | 1.0 sn | Misafir geldi: ding-dong kapı zili |
| `ciglik.ogg` | 0.6 sn | Albüm ekranı şakası: kadın "iiiy!" çığlığı |
| `tik.ogg` | 0.03 sn | Arayüz dokunma tıkı: çok kısa, yumuşak (çok sık çalar) |

## 4) Müzik — öncelik DÜŞÜK (3 dosya)

Klasör: `assets/sounds/`. Ogg, stereo olabilir, 128–160 kbps.

| Dosya | Süre | Tarif |
|---|---|---|
| `muzik_menu.ogg` | 60–90 sn, **döngü** | Sakin, komik mahalle havası; darbuka + bağlama + pizzicato, orta tempo |
| `muzik_oyun.ogg` | 90–120 sn, **döngü** | Hızlı, gergin ama komik kovalamaca; 130–140 BPM, Türk perküsyonu |
| `olum_muzigi.ogg` | 3–5 sn, döngü değil | Elenince: dramatik-komik "düm düm düüüm" (trombon iniş) |

Örnek Lyria istemi:
> Playful Turkish neighborhood comedy chase loop, darbuka and baglama with pizzicato strings, 135 BPM, cartoon energy, no vocals, seamless loop.

---

## Antigravity için talimat

1. `tools/ses_uret.py` gibi bir betik yaz: Gemini API (`GEMINI_API_KEY` ortam değişkeni) ile Bölüm 1–2'deki replikleri TTS'e gönder; dönen 24 kHz PCM'i WAV yap, `ffmpeg` ile sessizliği kırp (`silenceremove`), seviyeyi eşitle (`loudnorm=I=-16`), `.ogg`'ye çevir, tablodaki yola yaz. Anahtarı dosyaya **yazma**.
2. Her karaktere tek bir hazır ses (voice name) seç ve 3 repliğinde aynısını kullan; karakterler arasında ses farklı olsun. Diva kadın sesi, diğerleri erkek.
3. Efekt ve müzik üretebiliyorsan üret; üretemiyorsan atla ve `gecmis.md`'ye "yapılamadı" diye yaz. Lisansı belirsiz dosya **ekleme**.
4. Sonunda `Godot --headless --path . --import` çalıştır, `gecmis.md`'ye yeni bir `#N — Sesler` kaydı ekle (dosya listesi + hangi araç/ses adı kullanıldı).
5. Kod dosyalarına dokunma.

# Eksik Görseller (Gemini / Antigravity için)

Bu dosya hem insan (Gemini'ye elle yaptırırken) hem de Antigravity ajanı için yazıldı.
Oyun, aşağıdaki dosyalar **yokken de çalışır** (kodla çizilmiş yedek kullanılır); dosya eklendiği anda kendiliğinden kullanılır.
**Kod değiştirmeye gerek yok.** Sadece doğru ada ve klasöre koymak yeterli.

## Ortak tarz (her istemin başına ekle)

> Cartoon cockroach character, thick clean black outlines, flat soft cel shading, warm brown chitin body,
> big expressive eyes, two long antennae, Turkish neighborhood humor, sticker style,
> **fully transparent background (PNG with alpha)**, no text, no frame, no shadow on the ground, centered.

Referans görseller (aynı tarzda olsun): `assets/sprites/char_diva_front.png`, `assets/sprites/char_diva_angry.png`,
`assets/sprites/char_duktur_angry.png`, karakterin yan görünümü için `assets/sprites/char_<id>.png`.

Teslim kuralları:
- PNG, **şeffaf arka plan** (beyaz zemin olmasın), sRGB.
- Boyut tabloda yazan; daha büyük üretildiyse aynı orana küçültülür (kare → kare).
- Dosya adı birebir tablodaki gibi (küçük harf, Türkçe karakter yok).

---

## 1) Önden portreler — öncelik YÜKSEK (19 dosya)

Oyun sonunda (Elendin / Sonuçlar ekranı) büyük görünen yüz. **256x256**, belden yukarı, oyuncuya dönük.
- `_front` = gururlu / hafif sırıtan, rahat poz (bir el belde ya da el sallıyor).
- `_angry` = çok sinirli: çatık kaşlar, açık bağıran ağız, yumruklar sıkılı, kafanın yanında küçük buhar bulutları.

Klasör: `assets/sprites/`

| Dosya | Karakter | Görünüş (isteme ekle) |
|---|---|---|
| `char_klasik_front.png` | Klasik Böcek | plain classic cockroach, no clothes, friendly cheeky grin (sinirli hali zaten var) |
| `char_plaza_front.png` / `char_plaza_angry.png` | Plaza Böceği | navy business suit, white shirt, tie, ID badge on lanyard, takeaway coffee cup |
| `char_usta_front.png` / `char_usta_angry.png` | Sanayi Ustası | yellow hard hat, orange work vest, oily hands, wrench |
| `char_emlakci_front.png` / `char_emlakci_angry.png` | Emlakçı Böcek | shiny suit, slick hair, big bunch of keys, salesman smile |
| `char_siber_front.png` / `char_siber_angry.png` | Siber Böcek | battery pack on back, glowing LED antenna tips, tech visor |
| `char_yurt_front.png` / `char_yurt_angry.png` | Yurt Böceği | student in pajamas, headphones around neck, sleepy eyes |
| `char_dayi_front.png` / `char_dayi_angry.png` | Kahvehane Dayısı | white undershirt (atlet), thick mustache, old phone in hand, tea glass |
| `char_taraftar_front.png` / `char_taraftar_angry.png` | Taraftar Böcek | football jersey and scarf in generic colors (no club logos, no real team colors combo) |
| `char_saftirik_front.png` / `char_saftirik_angry.png` | Saftirik Böcek | two big buck teeth, confused naive look, bus passenger |
| `char_deli_front.png` / `char_deli_angry.png` | Deli Böcek | white lab coat, wild messy look, crazy spiral eyes, grin |

Örnek Gemini istemi:
> [Ortak tarz] Front-facing half-body portrait of a cockroach "office worker": navy business suit, white shirt, tie,
> ID badge on lanyard, holding a takeaway coffee cup. Expression: very angry, frowning eyebrows, open shouting mouth,
> clenched fists, small steam puffs next to the head. 256x256, transparent background.

---

## 2) Mahalle insanları (engeller) — öncelik ORTA (24 dosya)

Terlik atan insanlar. Her tip için **iki dikey şerit**, ikisi de **120x600**.
Klasör: `assets/sprites/insanlar/` (yoksa oluştur)

- `<id>_ust.png` — **yukarıdan aşağı uzanan kol**: üstte kumaş yen (x 32–88, y 0–280), altta bilek ve el (y ~288–395),
  elde terlik. Görselin altı (y 400–600) **boş/şeffaf**.
- `<id>_alt.png` — **sandalyede oturan kişi**, aşağıdan yukarı bakan: kafa merkezi yaklaşık (72, 385),
  gövde (35–84, 404–452), sandalye altta. Görselin üstü (y 0–340) **boş/şeffaf**.

Tarz: aynı kalın konturlu çizgi film, insanlar hafif karikatür; yüz panik/öfke.

| id | Tip | Ayırt edici |
|---|---|---|
| `anne` | Terlikli Anne | başörtüsü, pembe ev elbisesi |
| `amca` | Sandalyedeki Amca | mavi gömlek, kalın gözlük, göbek |
| `teyze` | Çığlıkçı Teyze | bigudiler, pembe sabahlık, çığlık |
| `kapici` | Kapıcı Efendi | kasket, haki iş kıyafeti, ekmek poşeti |
| `misafir` | Misafir Teyze | şık şapka, elde kek tabağı |
| `ev_arkadasi` | Ev Arkadaşı | kulaklık, eşofman |
| `kurye` | Kapıdaki Kurye | kask, kurye montu |
| `yonetici` | Apartman Yöneticisi | gözlük, yelek, aidat defteri |
| `bakkal` | Bakkal Amca | beyaz önlük, kalem kulakta |
| `kayinvalide` | Kayınvalide | başörtüsü, mor hırka, sert bakış |
| `belediye` | Belediye Görevlisi | maske, ilaçlama tulumu |
| `muhtar` | Mahalle Muhtarı | takım elbise, omuzdan kuşak |

> Not: Bu şeritlerin hizası önemli. Üretilen görsel hizaya oturmuyorsa önce 1–2 tip deneyip oyunda bak.

---

## 3) Küçük parçalar — öncelik DÜŞÜK

| Dosya | Boyut | Açıklama |
|---|---|---|
| `assets/sprites/fuze.png` | 96x48 | sağa doğru uçan karikatür füze (aslında fırlatılmış böcek ilacı kutusu), şeffaf |
| `assets/sprites/bacak.png` | 28x28 civarı | kopan tek böcek bacağı, kahverengi, şeffaf |

---

## Antigravity ajanı için talimat

1. Yukarıdaki tablolardaki görselleri üret (önce Bölüm 1). Her görsel şeffaf arka planlı PNG olmalı; beyaz zemin varsa temizle.
2. Tablodaki boyuta getir ve tam dosya adıyla tablodaki klasöre kaydet. **Mevcut dosyaların üzerine yazma.**
3. Kod, sahne, `project.godot`, `export_presets.cfg` dosyalarına dokunma.
4. Kontrol: `C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` çalıştır; hata çıkmamalı.
5. `gecmis.md` sonuna yeni bir `## #N — Görseller` kaydı ekle (hangi dosyalar eklendi).
6. Commit at: `Gorseller: <kısa liste>`. Push etme.

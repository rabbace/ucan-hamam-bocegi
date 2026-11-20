# Flow (Veo) Senaryoları — Oyun Sesleri

Her sahne 8 saniyelik bir Veo videosu. Videonun **sesini** oyuna alacağız; görüntü de sosyal medyada oyunun tanıtımında kullanılabilir.

## Nasıl üretilir

1. Flow'da yeni proje → **Text to Video** (karakter tutarlılığı için **Ingredients to Video**).
   Ingredients'a ilgili böceğin portresini ekle: `assets/sprites/char_<id>_front.png` (ör. `char_dayi_front.png`).
2. Her sahne için önce aşağıdaki **ORTAK STİL** bloğunu, sonra sahnenin istemini yapıştır.
3. Her sahneden **2–4 varyasyon** üret; Türkçe telaffuzu en düzgün ve tonu en komik olanı seç.
4. İndirdiğin MP4'ün adını tablodaki **dosya adı** yap (ör. `duktur_yok_mu.mp4`) ve proje içindeki `flow_videolari/` klasörüne koy (klasör git'e girmez).
5. Bana "videolar hazır" de: sesi ayırma, kırpma, seviye eşitleme ve oyuna bağlama işini ben yaparım.

**En önemli kural:** istemde **müzik ve altyazı olmasın** dedik; yine de müzikli çıkarsa o varyasyonu kullanma (konuşmayı müzikten ayıramayız).

## ORTAK STİL (her istemin başına)

```
2D cartoon animation, a brown cockroach character with big expressive eyes, two long antennae,
thick clean black outlines, flat soft cel shading, Turkish neighborhood comedy, warm home kitchen at night.
The character speaks Turkish clearly, loudly and expressively, with exaggerated comedic timing.
Audio: only the character's voice and the sound effects described. NO background music. NO subtitles, NO on-screen text.
Single continuous shot, 8 seconds.
```

---

## 1. `duktur_yok_mu` — Elenince
**Karakter:** Duktur Böcek (beyaz önlük) · **Oyunda:** terlikle elenince (şu anki sesin yerine)
```
The cockroach in a white doctor's coat lies flat on its back on the kitchen floor next to a giant slipper,
legs twitching in the air. It lifts its head in panic and wails dramatically, stretching the words:
"Duktur yok mu duktur?!"
Then it drops its head back down with a comic thud.
```

## 2a. `makara_reels` — Kazanınca
**Karakter:** Yurt Böceği (pijama, kulaklık) · **Oyunda:** maçı kazanınca
```
Late night, a cockroach in pajamas lies in bed with a tiny phone glowing on its face, scrolling fast,
eyes red and tired but grinning. It says to the camera in a proud, lazy voice:
"Biz yarın iş olmasına rağmen sabaha kadar Reels kaydırıyoruz."
Sound: soft phone tap sounds while scrolling.
```

## 2b. `makara_piciz` — Kazanınca
**Karakter:** Yurt Böceği · **Oyunda:** maçı kazanınca
```
Same pajama cockroach jumps up on the bed, points at the camera and laughs, then shrugs happily:
"Makarayız ya, piçiz ya! Sonra sabah seve seve işe gidiyoruz."
It ends with a big cheesy thumbs up.
```
*(Ayarlar'daki "argo sansürü" açıksa oyun yazıyı yıldızlar; ses için sansürlü ikinci bir varyasyon da üret: "piçiz" yerine "deliyiz".)*

## 3. `babanin_soyu` — Sataşma atınca
**Karakter:** Kahvehane Dayısı (atlet, bıyık) · **Oyunda:** rakibe sataşma eşyası atınca
```
A mustached cockroach in a white undershirt sits at a tiny teahouse table with a glass of tea,
waves its hand dismissively without even looking, and says with heavy, wise authority:
"O babanın soyu oğlum, bizi ilgilendirmez!"
Then it takes a loud sip of tea.
```

## 4. `bos_gectik` — Elenince
**Karakter:** Taraftar Böcek (forma, atkı) · **Oyunda:** elenince
```
A cockroach wearing a football jersey and scarf sits on the edge of a kitchen counter, shoulders slumped,
staring into the distance with deep disappointment. It sighs heavily and says slowly:
"Bu sene de boş geçtik karı."
Sound: one long tired sigh.
```
*(Sansürlü varyasyon: "karı" yerine "be".)*

## 5. `abi_uyuyor_musun` — "Elektrik Kesildi!" olayı
**Karakter:** Saftirik Böcek (iki diş) · **Oyunda:** elektrik kesilince
```
Pitch-dark room, only two glowing cartoon eyes visible. A buck-toothed cockroach slowly leans
into frame right next to the camera and whispers loudly, innocently:
"Abi... uyuyor musun?"
Then the camera shakes as if someone jumps awake in shock (slow-motion feel).
Sound: a light switch click at the very start.
```

## 6. `lululu` — Terliği kıl payı atlatınca
**Karakter:** Halay Başı Böcek (mendil) · **Oyunda:** yakın kaçışta (şu anki sesin yerine)
```
A cockroach waving a red handkerchief panics as a slipper flies past it, then breaks into
a loud, high-pitched celebratory ululation:
"Lülülülülülülü!"
Short and energetic, about 2 seconds of ululating, then it freezes in a proud pose.
```

## 7. `kiz_isteme` — "Misafir Var!" olayı
**Karakterler:** Kahvehane Dayısı + Diva Böcek · **Oyunda:** misafir gelince
```
Living room, formal visit. The mustached cockroach in a suit-jacket sits upright holding a tiny
box of chocolates and says ceremonially:
"Allah'ın emriyle kızını istiyoruz!"
A glamorous lady cockroach with sunglasses (the host mother) narrows her eyes and asks sharply:
"Oğlunun sigara, içki, kumarı var mıdır?"
```

## 7b. `kiz_isteme_cevap` — "Misafir Var!" olayı (devam)
**Karakter:** Saftirik Böcek · **Oyunda:** misafir olayının sonunda
```
A naive buck-toothed cockroach (the groom) sitting on the sofa answers cheerfully and honestly, nodding:
"Hepsi var, bi' tek karı eksik, onu da alıp gideceğim!"
The lady cockroach gasps and drops her teacup. Sound: teacup clink.
```
*(Sansürlü varyasyon: "karı" yerine "eş".)*

## 8. `ayran_ictik` — Çok oyunculuda bir rakip elenince
**Karakter:** Klasik Böcek · **Oyunda:** botlu/çok oyunculu maçta yanındaki elenince
```
Two cockroaches stand side by side; one gets swept away by a slipper. The remaining cockroach
reaches out dramatically toward where its friend disappeared and cries out:
"Ayran içtik, ayrı mı düştük?!"
Sound: a slipper swoosh at the start.
```

## 9. `aydinlat` — Karanlık evre bitince ışıklar yanınca
**Karakter:** Kahvehane Dayısı · **Oyunda:** ışıklar geri gelince (şu anki sesin yerine; dosya adı zaten oyunda var)
```
Dark kitchen. An old mustached cockroach holds up an old phone with a tiny flashlight,
squinting, and says warmly in an Eastern Anatolian accent:
"Kurban olduğum, şuraları aydınlat hele."
Then the kitchen lights suddenly turn on. Sound: light switch click.
```

## 10. `soz_alacagim` — Rekoru kıl payı kaçırınca
**Karakter:** Klasik Böcek · **Oyunda:** elenme panelinde, rekora çok yaklaşmışken
```
Slow dramatic close-up: a cockroach looks out of a rainy kitchen window, a single tear rolling down,
fist clenched. It whispers with exaggerated drama:
"Söz... bir gün alacağım."
Sound: gentle rain on the window. (No music.)
```

## 11. `elimi_tut` — Dirilme teklifi açılınca
**Karakter:** Diva Böcek · **Oyunda:** "Dirilmek ister misin?" penceresi açılınca
```
A glamorous lady cockroach lies dramatically on the floor next to a slipper, one hand reaching
up toward the camera, eyes half closed, and says weakly but theatrically:
"Elimi tut."
```

## 12. `kis_kisligini` — Buz kalıbı / dondurma (donma) anı
**Karakter:** Kahvehane Dayısı · **Oyunda:** buz kalıbı ya da dondurma sataşması gelince
```
The mustached cockroach shivers in front of an open freezer, frost forming on its mustache,
wrapping a tiny scarf around itself, and says with calm wisdom:
"Kış kışlığını yapacak anlaşılan, her şey zamanında."
Sound: freezer hum and teeth chattering.
```

---

## Efektler (konuşmasız, öncelik orta)

Aynı ORTAK STİL bloğunu kullan ama ikinci satırı şöyle değiştir: `No dialogue. Audio: only the sound effect described, nothing else.`

| Dosya adı | İstem |
|---|---|
| `terlik_at` | A plastic house slipper is thrown across the kitchen; one sharp whoosh sound. |
| `terlik_kirildi` | A plastic slipper hits a wall and cracks in half; one plastic crack sound. |
| `kapi_zili` | Close-up of an apartment door; the doorbell rings once: ding-dong. |
| `anahtar` | Close-up of a door lock; a bunch of keys jingles and turns in the lock. |
| `siren` | A municipal pest-control truck passes outside the window with a short siren. |
| `fuze` | A toy rocket flies across the kitchen with a comic whistling "fiiyuuu". |
| `kahve_hupletme` | A cockroach loudly slurps hot Turkish coffee from a tiny cup, then sighs "aaah". |
| `teyze_ayyy` | An old lady (only her slippers and skirt visible) sees a cockroach and shrieks: "Ayyyy! Böcek!" |

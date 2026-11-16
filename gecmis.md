# UÇAN HAMAM BÖCEĞİ — Değişiklik Geçmişi

Her büyük adımdan sonra geriye dönülebilmesi için `#` ile numaralandırılmış kayıt tutulur.

## #1 — Faz 1–5 Temel Oyun, Çok Oyunculu ve Türkçe TTS Seslendirme
- **Kapsam:** Godot 4.7.2 proje iskeleti (`MainMenu`, `Lobby`, `GameWorld`, `Player`, `SlipperObstacle`, `Missile`, `MissileWarning`, `Hud`, `AbilityButton`, `SpeechBubble`, `CharacterCard`, `ObstacleTimeline`, `NetworkManager`, `AudioManager`, `AssetHelper`, `GameConfig`, `CharacterData`).
- **Karakterler:** Klasik, Diva, Duktur, Halay Başı (yan profil `128x128` ve ön portre `256x256` PNG'ler).
- **Sesler:** Google Cloud TTS ile argo/bipli ölüm, sevinç, yetenek ve böcek ilacı `.wav` dosyaları (`assets/sounds/`).
- **Çok Oyunculu:** ENet + LAN keşif, deterministik engel zaman çizelgesi, bitişte senkronize halay dansı.

## #2 — Komedi Sesleri ve Sürpriz Engeller
- **Tarih:** 2026-11-15
- **Dosyalar:** `autoload/AudioManager.gd`, `data/CharacterData.gd`, `scenes/game/ObstacleTimeline.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/game/GameWorld.gd`
- **Eklenenler:**
  - Yeni `.wav` sesleri: `sopa.wav`, `makara_1.wav`, `makara_2.wav`, `lululu.wav`, `gahpe.wav`, `duktur_yok_mu.wav`.
  - Süpürge sapı (`sopa`) ve açılan dolap kapağı (`dolap`) sürpriz engelleri.
  - Yakın geçişte `"Lülülülü"`, sopa gelişinde `"Zopayı getür seni bi hışır ediyim"` tetiklenmesi.

## #3 — Böcek İlacı Sis Bulutu, Yırtık Logo ve Sinirli Ölüm Portreleri
- **Tarih:** 2026-11-15
- **Dosyalar:** `scenes/entities/SlipperObstacle.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Hud.gd`, `data/CharacterData.gd`, `assets/sprites/title_logo.png`, `assets/sprites/char_*_angry.png`
- **Eklenenler:**
  - Böcek ilacı için 7 katmanlı zehirli yeşil sis bulutu ve yükselen parçacıklar.
  - Ana menüde yağ lekeli, yırtık pırtık ve ısırılmış `"UÇAN HAMAM BÖCEĞİ"` logosu (`title_logo.png`).
  - Kaybetme ekranı için 4 karaktere özel öfkeli/diş sıkan portreler (`char_*_angry.png`).

## #4 — Faz 6: Seviyeler, Kombo, Güçlendirmeler ve Tek Oyunculu Ekleri
- **Tarih:** 2026-11-15
- **Dosyalar:** `data/GameConfig.gd`, `scenes/game/ObstacleTimeline.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/entities/Player.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`
- **Eklenenler:**
  - Alt `180 px` mutfak tezgâhı şeridi (`FLOOR_Y = 1100`), 3 yuvalı güçlendirme tepsisi ve `1/2/3` kısayolları.
  - Seviye tablosu (`Sv 1..7+`), `0.05 sn` adımlı deterministik hız profili, seviye atlama şeridi ve renk geçişi.
  - `< 18 px` yakın kaçış kombo sistemi ve unvanlar.
  - Güçlendirmeler: `dondurma`, `turbo`, `yedek_bacak`, `miknatis`, `ozel_yetenek` (Tavşan Kanı).
  - `user://settings.cfg` rekor kaydı, komik ölüm sebepleri ve ana menüde **"Günün Mutfağı"** modu.

## #5 — Canlı Mekan Arka Planları, Uzuv Animasyonu ve Geçmiş Kaydı
- **Tarih:** 2026-11-15
- **Dosyalar:** `gecmis.md`, `data/GameConfig.gd`, `scenes/entities/Player.gd`, `assets/sprites/bg_mutfak.png`, `assets/sprites/bg_pavyon.png`, `assets/sprites/bg_banyo.png`, `assets/sprites/bg_sokak.png`
- **Eklenenler:**
  - `720x1280` canlı karikatür mekan arka planları üretildi: **Mutfak**, **Pavyon**, **Banyo**, **Gece Sokağı**.
  - `Player.gd` içine uçuş/kaçış sırasında hıza ve zıplamaya göre hareket eden 6 eklemli bacak ve 2 esnek anten (`LimbOverlay`) eklendi.
  - Her adımdan sonra geriye dönülebilmesi için `gecmis.md` başlatıldı.

## #6 — Oyun Başlığı Kontrast ve Okunabilirlik Düzeltmesi
- **Tarih:** 2026-11-15
- **Dosyalar:** `assets/sprites/title_logo.png`, `scenes/ui/MainMenu.gd`
- **Eklenenler:**
  - `title_logo.png` üzerine parlak krem sticker dış konturu (`#FFF8E8`) ve daha canlı altın-turuncu harf dolgusu eklendi.
  - [MainMenu.gd](file:///C:/Users/aykut/Desktop/Claude_Uygulamalar/hamam_bocegi/scenes/ui/MainMenu.gd) içinde arka plan üzerine hafif karartma katmanı (`BgScrim`) eklendi.

## #7 — Oyun Sonu Yazısı ile Seslendirme Birebir Eşleştirildi
- **Tarih:** 2026-11-15
- **Dosyalar:** `data/CharacterData.gd`, `scenes/ui/Hud.gd`, `scenes/entities/Player.gd`, `scenes/game/GameWorld.gd`
- **Eklenenler:**
  - `CharacterData.get_random_death_entry()` ve `get_random_win_entry()` ile her `.wav` dosyası kendi birebir metniyle eşleştirildi.
  - Kaybetme panelinde (`Hud.show_death_panel`), uzak oyuncu elenmesinde (`Player.play_remote_death`) ve maç sonu halayında (`GameWorld._on_winner_announced`) artık ekranda yazan cümle ile çalan ses birebir aynı.

## #8 — Faz 7: Çoklu Oyunda Sataşma, Laf Atma, Hayalet Terlik ve Ödüller
- **Tarih:** 2026-11-15
- **Dosyalar:** `data/GameConfig.gd`, `data/CharacterData.gd`, `scenes/game/ObstacleTimeline.gd`, `autoload/NetworkManager.gd`, `scenes/entities/Player.gd`, `scenes/ui/Hud.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/Lobby.gd`
- **Eklenenler:**
  - Sataşma güçlendirmeleri (`buz_kalibi`, `turk_kahvesi`, `kirli_corap`, `komsu_teyze`, `ayna`) yalnızca çoklu oyunda üretilir.
  - Hedef seçici (2 sn sonra otomatik lider), `0.6 sn` uyarı, `4 sn` bağışıklık, Ayna geri yansıtma ve sol üst 3 satırlık olay akışı eklendi.
  - 6 hazır laf + karaktere özel 7. laf (`taunt_line`) ile `3 sn` bekleme süreli hızlı mesaj eklendi.
  - Elenen oyuncular için sağ kenarda `8 sn` bekleme süreli **Hayalet Terlik** atma şeridi eklendi (`1.2 sn` uyarı + isim etiketli dönen terlik).
  - Maç sonu 5 ödül (*Mahallenin Kralı*, *Çığlık Ustası*, *Baş Belası*, *Terlik Mıknatısı*, *İntikam Meleği*) ve lobi unvan sayacı eklendi.

## #9 — Uygulama İkonu (`app_icon.png`)
- **Tarih:** 2026-11-15
- **Dosyalar:** `assets/sprites/app_icon.png`, `project.godot`
- **Eklenenler:**
  - `512x512` kare mobil oyun ikonu (terlikten kaçan uçan hamam böceği) üretildi ve `project.godot` içinde `config/icon` olarak atandı.

## #10 — Yeni Komedi Sesleri ve Erken Karanlık Evre
- **Tarih:** 2026-11-15
- **Dosyalar:** `assets/sounds/ocuz.wav`, `assets/sounds/aydinlat.wav`, `assets/sounds/agucuk.wav`, `data/CharacterData.gd`, `data/GameConfig.gd`, `scenes/game/ObstacleTimeline.gd`, `scenes/game/GameWorld.gd`
- **Eklenenler:**
  - `"Oçuz abi, piçiz abi!"` (`ocuz.wav`) ölüm ses/metin havuzuna eklendi.
  - `"Agucuk bugucuk hele!"` (`agucuk.wav`) yakın geçiş seslerine eklendi.
  - Karanlık evre (ışıkların sönmesi) Seviye 1–2'de de zorluk için aktif edildi; `DARK_BANNER_TEXT` ve `aydinlat.wav` *"İki gözüm şuraları bir aydınlat hele!"* olarak güncellendi.


## #11 — Android APK Dışa Aktarımı
- **Tarih:** 2026-11-15
- **Dosyalar:** `export_presets.cfg`, `project.godot`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `project.godot` içinde Android için zorunlu `textures/vram_compression/import_etc2_astc=true` ayarı açıldı.
  - `Godot 4.7.2` dışa aktarma şablonları ve imzalı debug keystore ile Android APK (`build/ucan_hamam_bocegi.apk`, `73.904.502` bayt) derlenip `apksigner` ile imzalanarak doğrulandı.

## #12 — Kompakt Yuvarlak Tepsi Butonları (1, 2, 3) ve İnce Alt Şerit
- **Tarih:** 2026-11-15
- **Dosyalar:** `data/GameConfig.gd`, `scenes/ui/AbilityButton.gd`, `scenes/ui/Hud.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - Alt tezgâh şeridi `180 px`'den `116 px`'e küçültüldü (`FLOOR_Y = 1164`), yetenek butonu `94 px`, güçlendirme yuvaları `74 px` yuvarlak butonlara küçültüldü.
  - 3 güçlendirme yuvası yuvarlak kenarlı `PowerupTray` tepsi konteyneri içine yerleştirildi; her yuvaya temaya uygun farklı pastel renkler (Şeftali `#F5C9A6`, Adaçayı Yeşili `#B8D4B0`, Toz Mavi `#B2C9DF`), yuvarlak bekleme süresi katmanı, anlık basış/dokunuş tepkisi (`ACTION_MODE_BUTTON_PRESS` + ölçek animasyonu) ve ortalı ikon/numara rozeti eklendi.
  - Güncel `build/ucan_hamam_bocegi.apk` yeniden derlenip imzalandı.

## #13 — Şeffaf Alt Kontrol Alanı ve Isırılmış Çizgi-Roman Menü Tasarımı
- **Tarih:** 2026-11-15
- **Dosyalar:** `core/ComicUiHelper.gd`, `data/GameConfig.gd`, `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - Alt şerit (`_counter_strip`) tamamen şeffaf yapıldı (`StyleBoxEmpty`, `MOUSE_FILTER_IGNORE`), opak tezgâh arka planı kaldırıldı ve `COUNTER_STRIP_HEIGHT = 104` (`FLOOR_Y = 1176`) ile arka plan tamamen görünür hale getirildi.
  - `PowerupTray` yarı şeffaf buzlu kapsül görünümüne alındı; içindeki 3 farklı pastel renkli yuvarlak buton ve sağdaki `YETENEK` butonu arka plan üzerinde yüzer şekilde konumlandırıldı.
  - `ComicUiHelper` (`core/ComicUiHelper.gd`) eklendi: gerçek şeffaf kenar ısırıkları (`alpha = 0`), el çizimi koyu mürekkep konturu (`#24160E`), sert çizgi-roman alt gölgesi, yağ lekeleri ve pençe çizikleri üreten önbellekli `StyleBoxTexture` stili `MainMenu`, `Lobby`, `DeathPanel` ve `WinnerPanel` buton/kartlarına uygulandı.
  - Güncel `build/ucan_hamam_bocegi.apk` yeniden derlenip imzalandı.

## #14 — Menü Cilası (Sabıka Kartları, Bantlı Not, Canlı Böcek/Terlik) ve Karakter Görünürlüğü
- **Tarih:** 2026-11-15
- **Dosyalar:** `scenes/ui/CharacterCard.gd`, `scenes/ui/MainMenu.gd`, `scenes/game/GameWorld.gd`, `scenes/entities/Player.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - Oyun içinde `BgScrim` (`Color(0.06, 0.05, 0.06, 0.36)`) arka plan perdesi ve `Player.back_aura` parlak sıcak kontur halesi (`62 px`, `alpha = 0.42` + altın halka) ile karakterin tüm mekanlarda net görünmesi sağlandı.
  - `CharacterCard` içine kırmızı `"ARANIYOR"` / yeşil `"SEÇİLİ!"` damgalı kompakt 4'lü sabıka kartı modu eklendi.
  - `MainMenu` içinde `FormCard` hafif eğilip sarı koli bandı şeritleriyle "Buzdolabı Notu" görünümüne alındı; `"HEMEN UÇ!"` ana butonu büyütülüp çoklu oyun ve ayarlar kompakt alt sıralara toplandı.
  - Menü böceğine dokunma tepkisi (ses + konuşma balonu + zıplama) ve sağ kenardan gizlice uzanan terlik animasyonu eklendi.
  - Güncel `build/ucan_hamam_bocegi.apk` yeniden derlenip imzalandı.

## #15 — Buton Focus / Hover Yazı Kaybolma Hatası Düzeltmesi
- **Tarih:** 2026-11-15
- **Dosyalar:** `core/ComicUiHelper.gd`, `scenes/ui/Hud.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `ComicUiHelper.style_bitten_button` ve `Hud.gd` yuvarlak yuva butonlarına `focus_mode = Control.FOCUS_NONE`, `focus` (`StyleBoxEmpty`), `hover_pressed` ve `font_focus_color` / `font_hover_pressed_color` geçersiz kılmaları eklendi; böylece dokunulan/basılan butonun yazısı asla kaybolmuyor.
  - Güncel `build/ucan_hamam_bocegi.apk` yeniden derlenip imzalandı.

## #16 — Açılış Hızı ve Buton Tepki Performans Düzeltmesi
- **Tarih:** 2026-11-16
- **Dosyalar:** `core/ComicUiHelper.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `ComicUiHelper` içindeki her buton/kart için ayrı ayrı üretilen ağır piksel döngüleri (`~45 milyon` işlem) kaldırıldı; bunun yerine başlangıçta yalnızca 2 küçük `96x48` 9-patch ana doku (`_tex_normal`, `_tex_pressed`) üretilip `StyleBoxTexture.modulate_color` ile renklendirmeye geçildi (~2.500 kat daha hızlı açılış).
  - Tüm menü ve panel butonlarına `ACTION_MODE_BUTTON_PRESS` verilerek mobilde anlık tepki sağlandı.
  - Güncel `build/ucan_hamam_bocegi.apk` yeniden derlenip imzalandı.

## #17 — Faz 8.1–8.8: Denge, 3 Yetenekli Karakterler, Rehber, Zafer Turu, Sıralama, Sansür ve Ölüm Müziği
- **Tarih:** 2026-11-16
- **Dosyalar:** `data/GameConfig.gd`, `data/CharacterData.gd`, `autoload/AudioManager.gd`, `autoload/NetworkManager.gd`, `scenes/game/ObstacleTimeline.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/entities/Player.gd`, `scenes/ui/AbilityButton.gd`, `scenes/ui/SpeechBubble.gd`, `scenes/ui/SkillsModal.gd`, `scenes/ui/GuideModal.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `scenes/game/GameWorld.gd`, `project.godot`
- **Eklenenler:**
  - **8.1:** Çok oyunculuda ölüm oyunu durdurmaz; son kalan 15 sn'lik **Zafer Turu**'na çıkar ("Bitir" butonu dahil), bitince sıralamaya geçilir.
  - **8.2:** `LEVELS` kolaylaştırıldı; ilk 5 çift +40 px ısınma, `sopa` yalnızca Sv 5+, sürprizler arası en az 3 normal çift, füze evresi çevresi korumalı, `firlayan_terlik` ve ilk kez yeni engel tanıtım şeridi eklendi.
  - **8.3:** 4 karakterin tamamına **1 pasif + 2 aktif (2.'si özel küçülme + 0.3 sn büyüme dokunulmazlığı)** ve alt şeritte 2. yetenek butonu (`Q`) eklendi.
  - **8.4:** Ortada açılan **Yetenekler ekranı** (`SkillsModal`, canlı mini önizleme) ve maç başı `3-2-1` yetenek özet kartı + tek oyunculuda duraklatma menüsü eklendi.
  - **8.5:** 7 sayfalık **"Nasıl Oynanır?"** rehberi (`GuideModal`, ilk açılışta otomatik) ve cihaz başına tek seferlik oyun içi ipuçları eklendi.
  - **8.6:** Sondan başa animasyonlu **"MAHALLE SONUÇLARI"** sıralama ekranı (beraberlik, `(kaçtı)`, `+5/+3/+2/+1/0` puan, rozetler) ve puan sıralı lobi tablosu eklendi.
  - **8.7:** Turbo (`"Bas bas kökle amk kökleeee"`) ve sataşma (`"Özür dilerim pıttığım"`) replikleri + `show_item_fx` RPC ve menüde **Argo Sansürü** (`GameConfig.censor`) eklendi.
  - **8.8:** `olum_muzigi.ogg` (yerel 6 sn, uzak 2 sn -10 dB) ve 2.5 sn siyah-beyaz ölüm shader efekti eklendi.

## #18 — Faz 8.9: Çevrimiçi Sunucu Modu (Matchmaker + RoomServer)
- **Tarih:** 2026-11-16
- **Dosyalar:** `autoload/Boot.gd`, `autoload/NetworkManager.gd`, `data/GameConfig.gd`, `server/Matchmaker.gd`, `server/Matchmaker.tscn`, `server/RoomServer.gd`, `server/RoomServer.tscn`, `server/SUNUCU_KURULUM.md`, `server/run_local.sh`, `server/run_local.bat`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/game/GameWorld.gd`, `export_presets.cfg`, `project.godot`
- **Eklenenler:**
  - `Boot.gd` (`--matchmaker` / `--room` komut satırı ayrımı) ve TCP `7700` Eşleştirici + UDP `7801..7850` Oda Sunucusu süreçleri eklendi.
  - Ayrılmış sunucu desteği (`is_dedicated_server()`, `is_room_owner()`, oda sahibi devri, 60 sn boş oda kapanışı, Hızlı Oyun 2+ kişi 25 sn otomatik başlatma, isim temizleme, arka plan 10 sn kuralı).
  - Ana menüde **"Çevrimiçi"** penceresi (*Hızlı Oyun*, *Özel Oda Kur*, *Kodla Katıl*, sunucu adresi ayarı) ve lobide oda kodu gösterimi eklendi.
  - `export_presets.cfg` içine Linux `Server` ön ayarı ve `server/SUNUCU_KURULUM.md` + `run_local.sh` / `run_local.bat` eklendi.

## #19 — Faz 9A: Parçalı Karakter Animasyonu, Tam Ekran Uyumu ve Dokun-Kaydır Kontrolleri
- **Tarih:** 2026-11-16
- **Dosyalar:** `scenes/entities/CharacterRig.gd`, `assets/sprites/chars/PARCA_REHBERI.md`, `scenes/entities/Player.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/GuideModal.gd`, `data/GameConfig.gd`, `autoload/AudioManager.gd`
- **Eklenenler:**
  - **9.1:** `CharacterRig` (`AnimationPlayer`, yaylı anten, 2–5 sn göz kırpma, tehlikeye bakan göz bebekleri, kanat motion-blur izi) eklendi; uçuşta gövde dönmesi kaldırıldı (`BODY_TILT_MAX = 0.0`), yalnızca ölümde döner.
  - **9.2:** `cover` arka plan ölçekleme, dinamik görünür alan yerleşimi (`size_changed`), `DisplayServer.get_display_safe_area()` alt boşluk uyumu ve `F9` 5 çözünürlük test geçişi eklendi.
  - **9.3:** "Dokun ve Kaydır" kontrolleri (dokun = uç, yukarı kaydır = Aktif 1, aşağı kaydır = Aktif 2, iki parmak = güçlendirme, `0.2 sn` girdi tamponu, ok izi) + Kontrol Ayarları penceresi (Solak modu, Buton boyutu `%80–%130`, Yardımcı Mod) ve rehberde *"Kontroller"* sayfası eklendi.

## #20 — Faz 9B: Voice Ses Kanalı, Karakter Sesleri ve Dürtme Şakası
- **Tarih:** 2026-11-16
- **Dosyalar:** `autoload/AudioManager.gd`, `data/CharacterData.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/CharacterCard.gd`
- **Eklenenler:**
  - `AudioManager` içine `Voice` bus'ı (`AudioEffectPitchShift`, `Compressor`, `EQ`), `voice_volume` ve `play_character_voice()` eklendi.
  - `CharacterData` içine her karakter için `voice_pitch`, `tap_lines` (3 replik), `poke_line` ve `flee_line` eklendi.
  - Ana menü böceğine dokununca rastgele (tekrarsız) karakter lafı + balon, 1.5 sn içinde 3. dokunuşta *"Dürtme beni!"*, 10. dokunuşta *"Tamam, ben kaçtım!"* diyerek ekrandan kaçıp 2 sn sonra dönme şakası eklendi.

## #21 — Faz 9C: 7 Yeni Karakter, Kırıntı Ekonomisi, Böcek Pazarı ve Monetization
- **Tarih:** 2026-11-16
- **Dosyalar:** `autoload/Monetization.gd`, `data/CharacterData.gd`, `data/GameConfig.gd`, `scenes/ui/ShopModal.gd`, `scenes/ui/MainMenu.gd`, `scenes/entities/Player.gd`, `scenes/game/GameWorld.gd`, `project.godot`
- **Eklenenler:**
  - `Monetization` (`user://save.cfg`): Kırıntı ekonomisi (günlük +25, geçilen engel +1, sıralama +30/+20/+12/+6/+3), `1 Maç Dene` ödüllü reklam akışı, sahte/gerçek mağaza satın alma (`paket_bocekler`, `kirinti_kesesi_*`, `reklamsiz`), geçiş reklamı sıklık kuralı eklendi.
  - 7 yeni karakter (`plaza`, `usta`, `emlakci`, `siber`, `yurt`, `dayi`, `taraftar`) 1 pasif + 2 aktif yetenek, replikler ve 2'şer kostümle eklendi.
  - **"Böcek Pazarı"** (`ShopModal`: *Böcekler*, *Kostümler*, *Paketler*) ana menüye eklendi.

## #22 — Faz 9D: Oda Daveti, Derin Bağlantı Web Sayfası, Skor Paylaşımı ve Etkinlikler
- **Tarih:** 2026-11-16
- **Dosyalar:** `data/GameConfig.gd`, `web/oda.html`, `web/README.md`, `server/events.json`, `server/Matchmaker.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - Lobide **"Arkadaşını Davet Et"** butonu (çevrimiçi link veya LAN Wi-Fi daveti), `web/oda.html` (`ucanbocek://oda/KOD` yönlendirmesi) ve `web/README.md` (GitHub Pages rehberi) eklendi.
  - Sıralama ekranına **"Paylaş"** butonu (`user://paylas.png` ekran görüntüsü + pano / Android paylaşım) eklendi.
  - `server/events.json` ve `Matchmaker` `get_event` desteği eklendi.
  - Tüm Faz 8 ve Faz 9 (9A–9D) güncellemeleriyle `build/ucan_hamam_bocegi.apk` derlenip imzalandı.

## #23 — 5 Yeni Karakter Sprite'ı (Dayı, Emlakçı, Plaza, Taraftar, Saftirik) ve Gerçek Terlik Görseli
- **Tarih:** 2026-11-16
- **Dosyalar:** `assets/sprites/char_dayi.png`, `assets/sprites/char_emlakci.png`, `assets/sprites/char_plaza.png`, `assets/sprites/char_taraftar.png`, `assets/sprites/char_saftirik.png`, `assets/sprites/terlik.png`, `assets/sprites/terlik_ust.png`, `data/CharacterData.gd`, `scenes/entities/Player.gd`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - Kullanıcının bıraktığı `dayi`, `emlakci`, `plaza`, `taraftar` ve yeni `saftirik` (*Saftirik Böcek*) karakterleri için arka plansız `256x256` oyun içi PNG sprite'ları üretilip `CharacterData` + `Player.gd` ile bağlandı.
  - Dikdörtgen terlik yerine gerçek karikatür Türk ev terliği (`terlik.png` ve el/kol tutuşlu `terlik_ust.png`) üretildi.
  - Güncel `build/ucan_hamam_bocegi.apk` derlenip imzalandı.

## #24 — Yüksek Kontrastlı Logo ve GitHub Deposu
- **Tarih:** 2026-11-16
- **Dosyalar:** `assets/sprites/title_logo.png`, `.gitignore`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `title_logo.png` okunurluğu artırıldı: harflerin üzerindeki koyu lekeler kaldırılarak parlak sarı-turuncu gradyan dolgu, kalın koyu mürekkep konturu ve parlak krem sticker dış çerçevesi uygulandı.
  - `.gitignore` eklenerek proje GitHub üzerinde `ucan-hamam-bocegi` reposuna yüklendi.

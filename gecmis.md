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

## #25 — İsim Alanı Okunurluğu, Karakter Boyut Normalizasyonu, Deli/İşçi/Klasik Sprite'ları ve 4 Yeni Arka Plan
- **Tarih:** 2026-11-16
- **Dosyalar:** `scenes/ui/MainMenu.gd`, `scenes/entities/Player.gd`, `data/CharacterData.gd`, `data/GameConfig.gd`, `assets/sprites/char_deli.png`, `assets/sprites/char_isci.png`, `assets/sprites/char_klasik.png`, `assets/sprites/bg_kahvehane.png`, `assets/sprites/bg_otobus.png`, `assets/sprites/bg_sanayi.png`, `assets/sprites/bg_dugun.png`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `MainMenu.gd` içinde isim giriş alanı (`name_input` ve `name_label`) tam beyaz zemin + yüksek kontrastlı koyu yazı/imleç ile okunaklı hale getirildi.
  - `Player.gd` ve `MainMenu.gd` içinde sprite boyutu doku çözünürlüğüne göre `128 px` referansına normalize edildi; yeni eklenen büyük çözünürlüklü böceklerin oyunda dev görünmesi düzeltildi.
  - `deli` (*Deli Böcek*), `usta` (`char_isci.png`) ve güncellenen `klasik` (`char_klasik.png`) için `128x128` şeffaf PNG sprite'lar üretilip bağlandı.
  - 4 yeni arka plan eklendi (*Kahvehane*, *Belediye Otobüsü*, *Oto Sanayi*, *Kır Düğünü* — toplam 8 mekan).
  - Güncel APK derlenip GitHub (`main`) deposuna yüklendi.

## #26 — Siber/Yurt Sprite'ları, Gerçek Alt Engel (Sandalyedeki İnsan), Mekâna Özel Engeller, Günlük Görevler ve AAB Ön Ayarı
- **Tarih:** 2026-11-16
- **Dosyalar:** `assets/sprites/char_siber.png`, `assets/sprites/char_yurt.png`, `assets/sprites/terlik_alt.png`, `data/CharacterData.gd`, `scenes/entities/SlipperObstacle.gd`, `autoload/AudioManager.gd`, `autoload/Monetization.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/MainMenu.gd`, `export_presets.cfg`, `build/ucan_hamam_bocegi.apk`
- **Eklenenler:**
  - `siber` (`char_siber.png`), `yurt` (`char_yurt.png`) ve alt engel (`terlik_alt.png` — sandalyeye çıkmış bağıran insan) görselleri eklendi.
  - `SlipperObstacle.gd` içinde sürpriz çubuk engeli seçili mekâna göre özelleştirildi (*Kahvehane* okey ıstakası, *Oto Sanayi* İngiliz anahtarı, *Otobüs* sarı tutunma borusu, *Düğün* takı kurdelesi, *Pavyon* neon çubuk, *Banyo* paspas sapı).
  - `Monetization.gd` içine **Günlük Görevler** (`20 Engel Geç`, `Tek Maçta 3 Yakın Kaçış`, `2 Maç Oyna` → Kırıntı ödülü) + `MainMenu` **"Görevler"** penceresi ve Android `PoingGodotAdMob` / `GodotGooglePlayBilling` köprüleri eklendi.
  - `export_presets.cfg` içine `Android Release (AAB)` ön ayarı eklendi; `AudioManager.play_character_voice()` `.ogg` ve `.wav` destekli hale getirildi.
  - Güncel APK derlenip GitHub (`main`) deposuna yüklendi.

## #27 — Faz 10: Gerçek İkonlar, Karaktere Özel İmza Ödülleri ve Sinirli Büyük Yüz
- **Tarih:** 2026-11-17
- **Yapan:** Claude (telefondan, GitHub üzerinden; Antigravity yerine)
- **Dosyalar:** `core/IconFactory.gd` (yeni), `assets/sprites/items/*.png` (yeni, Noto Emoji), `assets/sprites/items/LICENSE_NOTO_EMOJI.txt`, `data/GameConfig.gd`, `data/CharacterData.gd`, `scenes/entities/Player.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/game/GameWorld.gd`, `scenes/game/ObstacleTimeline.gd`, `scenes/ui/Hud.gd`, `scenes/ui/SkillsModal.gd`, `scenes/ui/GuideModal.gd`, `scenes/ui/CharacterPortrait.gd/.tscn` (yeni), `tools/ci_check.gd`, `tools/CiCheck.tscn` (yeni), `export_presets.cfg`, `assets/sprites/chars/PARCA_REHBERI.md`
- **10.1 İkonlar:**
  - Harf ikonları ("D", "M"…) tamamen kaldırıldı. 24 ikon Google Noto Emoji setinden (Apache 2.0) `assets/sprites/items/<item_id>.png` olarak eklendi; lisans dosyası yanında.
  - `IconFactory`: dosya yoksa harf değil, kodla çizilmiş şekil (dondurma külahı, mıknatıs, kahve fincanı…) üretir; ikonlar pastel "kırıntı tabağı" üstünde durur.
  - İsim değişikliği: "Tavşan Kanı" → **Kum Saati** (iç kimlik `ozel_yetenek` aynı kaldı), "Türk Kahvesi" → **Şeker Bombası** (iç kimlik `turk_kahvesi` aynı kaldı; ağ uyumluluğu için).
- **10.2 İmza ödülleri:**
  - Kutuların %30'u 🎁 gizemli kutu (`SIGNATURE_DROP_RATE`). Yeri herkeste aynı, içeriği toplayanın karakterine göre açılır.
  - 13 karakterin imza ödülü: Klasik Bayat Ekmek, Diva Ruj Tazeleme, Duktur Aşı, Halay Başı Davul, Plaza Filtre Kahve, Usta İngiliz Anahtarı, Emlakçı Yedek Anahtar, Siber Pil, Yurt Gece Eriştesi, Dayı Demlik Çay, Taraftar Top, Saftirik Balon (prompt'ta yoktu, eklendi), Deli Acı Biber.
  - Yetenekler ekranına "İMZA ÖDÜLÜ" satırı eklendi; ekran artık 13 karakterin hepsini geziyor, kilitli karakter seçilemiyor.
- **10.3 Sinirli büyük yüz:**
  - `CharacterPortrait`: sinirli / çok sinirli / gururlu / küs ifadeleri, buhar, titreme, kızarma, anten yayı, dokunulan yere bakan gözler, replik balonu.
  - Tek oyunculu ölüm panelinde portre fırlıyor ve küfür repliğini (sesle birebir) söylüyor; 5 dokunuşta "Tamam! Bi el daha!" diyor, Tekrar Dene butonu nabız atıyor. Panele "Paylaş" butonu eklendi.
  - Sıralama ekranında yerel oyuncunun portresi (1. gururlu, 2. küs, diğerleri sinirli). Çok oyunculu elenmede köşede 1.5 sn küçük portre.
  - Paylaşım kartı: 1080x1350 dikey, logo + replik balonu + portre + skor.
  - Yeni 9 karakter başka böceklerin sinirli görselini ödünç alıyordu; kaldırıldı, kendi yüzleri görsel eklenene kadar kodla çiziliyor.
- **Test:** `godot --headless res://tools/CiCheck.tscn` → tüm scriptler derleniyor, oyun 8 sn duman testi, 13 imza ödülü ve portre ekranları hatasız.

## #28 — Arayüz Yenilemesi: Font, Her Telefona Uyum, Sade Ana Menü ve Okunur HUD
- **Tarih:** 2026-11-16
- **Dosyalar:** `assets/fonts/Baloo2.ttf`, `assets/fonts/Baloo2_OFL.txt`, `core/AssetHelper.gd`, `core/ComicUiHelper.gd`, `data/GameConfig.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/MainMenu.tscn`, `scenes/ui/CharacterCard.gd`, `scenes/ui/Hud.gd`, `scenes/ui/AbilityButton.gd`, `scenes/ui/AbilityButton.tscn`, `scenes/ui/SpeechBubble.gd`, `scenes/ui/ShopModal.gd`, `scenes/ui/SkillsModal.gd`, `scenes/ui/GuideModal.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Lobby.tscn`
- **Eklenenler:**
  - **Font:** Baloo 2 (OFL, Türkçe destekli) eklendi; `get_ui_font()` (SemiBold) ve `get_title_font()` (ExtraBold). Eski klasör taraması APK'da fontu bulamıyordu, artık açık yol ile yükleniyor.
  - **Tema:** `GameConfig` içine yazı ölçeği (`FS_TINY 18` … `FS_HERO 64`, 18 altı yok), boşluk ölçeği (`SP_*`) ve ortak renkler eklendi.
  - **Ortak yardımcılar (`ComicUiHelper`):** `safe_insets` (çentik/jest çubuğu), `visible_size`, `build_modal` (ortalanan, güvenli alana uyan, kayan pencere), `style_tab`, `style_label`, `set_badge_dot`. Isırık izleri 9-patch köşelerine alındı (geniş butonlarda uzamıyor).
  - **Ana menü:** Üst çubuk (kırıntı bakiyesi + Ayarlar), logo, isim notu, sahip olunan tüm böceklerin yatay şeridi, tek baskın "HEMEN UÇ!", "Günün Mutfağı" / "Arkadaşlarla Oyna", ikonlu alt gezinme (Pazar · Görevler · Yetenekler · Rehber), Görevler'de bildirim rozeti. Ses/Titreşim/Sansür/Mekan (önizlemeli ızgara)/Kontroller tek **Ayarlar** penceresinde. İsim kartını sarı kaplayan koli bandı hatası ve 6'lı buton sırasının ekrandan taşması giderildi.
  - **HUD:** Üst üste binen sol üst öğeler tek üst çubukta toplandı (güvenli alana uyumlu); bildirimler tek dikey yığında; uzun ekranda kesilen YETENEK butonu düzeltildi; KÜÇÜL butonu Aktif 1 ile aynı boyda; güçlendirme yuvalarında harfler yerine çizilmiş ikonlar; dokunmatikte klavye yerine kaydırma/buton ipuçları; ölüm panelinde "+N Kırıntı" sayacı ve görev ilerlemesi; duraklatma/sonuç/kazanan pencereleri ortalı.
  - **Pazar / Yetenekler / Rehber / Lobi:** Ortalı ve güvenli alana uyumlu; Pazar'da aktif sekme belli, butonlar alt satırda (taşma yok); lobide satın alınmış tüm böcekler seçilebiliyor; Yetenekler/Rehber'de kaydırma (swipe) gerçekten çalışır hale geldi; lobide olmayan `update_my_character` çağrısı düzeltildi.
  - 360x640, 405x900, 390x844, 360x800 ve 600x800 (tablet) çözünürlüklerinde ekran görüntüsüyle doğrulandı.

## #29 — Fizik ve Ekonomi Düzeltmeleri
- **Tarih:** 2026-11-16
- **Dosyalar:** `autoload/Monetization.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/entities/Player.gd`, `scenes/entities/CharacterRig.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/ShopModal.gd`, `scenes/ui/Hud.gd`, `data/GameConfig.gd`, `project.godot`
- **Eklenenler:**
  - **Alt engel:** Çarpışma kutusu görselin boş üst kısmını da kapsıyordu (adamın başının ~340 px üstünde görünmez duvar) ve zemine inmiyordu (alttan geçiş kanalı). Kafa artık aralığın alt kenarına hizalı, kutu kafadan zemine kadar; sandalyenin altına zemine inen ahşap kaide çizildi. Üst engel kutusu tavanın üstüne uzatıldı.
  - **Player:** 256 px karakterlerin her karede 2 kat büyük çizilmesi (nefes animasyonu ölçeği eziyordu), dokunulmazlık/hayalet biterken engel içinde kalanın ölmemesi, Dayı "Çay Molası"nda kanat çırpmanın tavana çakması, Siber bekleme göstergesi ve rig çift gövde hataları düzeltildi; fırlayan terlik dönüşü kare hızından bağımsız.
  - **GameWorld:** Kare süresi sınırı (`MAX_FRAME_DELTA`), tek oyunculuda arka plana alınınca / Android Geri tuşunda otomatik duraklatma, kutu/hayalet terlik doğma konumları görünür alana bağlı, tek oyunculu kırıntı tasarıma uygun (= skor).
  - **Ekonomi:** `save_data()` görev bölümünü siliyordu (görev ödülü tekrar alınabiliyordu) — düzeltildi. Günlük ödül/görev yalnızca tarih ileri gidince (saat geri alma istismarı kapandı). Kayıt dosyası şifreli (eski düz kayıt otomatik taşınır). Sahte reklam/satın alma yalnızca debug sürümde; yayında gerçek eklenti yoksa ödül verilmez, Pazar'da ilgili butonlar gizlenir; Steam'de reklam yok. Deneme hakkı maç başında tüketiliyor, kilitli karakterle oynanamıyor.
  - `DEBUG` yalnızca editörde açık (dışa aktarılmış sürümde seed etiketi / tek kişilik LAN maçı kapalı). `quit_on_go_back=false` + menüde Geri tuşu önce pencereyi kapatır.
  - **Ertelendi:** Hız profilinin karanlık evrelerde gerçek seviyeden önde gitmesi (O2) — karanlık evre zamanlaması ile döngüsel bağlı, oyun testiyle ayrıca ele alınacak.

## #30 — Ağ ve Sunucu Güvenliği
- **Tarih:** 2026-11-16
- **Dosyalar:** `autoload/NetworkManager.gd`, `server/Matchmaker.gd`, `server/RoomServer.gd`, `server/SUNUCU_KURULUM.md`, `net/LanDiscovery.gd`, `net/NameFilter.gd` (yeni), `data/GameConfig.gd` (`NET_VERSION` 2 + "Ağ güvenliği" sabitleri), `scenes/game/GameWorld.gd`, `scenes/ui/MainMenu.gd`
- **Eklenenler:**
  - Oda sunucusu maç başında kendi sahnesini siliyordu (süreç sızıntısı, port karışıklığı) — sunucu artık sahne değiştirmiyor; maç saati/zaman aşımı/zafer turu sahneden bağımsız.
  - Matchmaker: `room_*` mesajları yalnızca 127.0.0.1'den, IP başına oda açma ve kod deneme hız sınırı, en fazla 10 oda / 64 bağlantı, 5 sn boşta kapanma, 4 KB tampon; oda yeniden kayıt (RoomServer geri çekilmeli yeniden bağlanma, `KillMode=process` notu).
  - Hile önlemleri: ölüm zamanı ve skor sunucu saatiyle sınırlı, hayalet terlik/sataşma doğrulaması, LAN'da yalnızca host maç başlatır, reddedilen/kayıt olmayan eş atılır, tüm RPC'lerde üyelik + hız sınırı, hızlı sohbet serbest metin yerine indeks.
  - Geri sayım tüm oyuncular yüklenince başlar (geç yüklenen istemci de yakalar); kazanan sunucu saatine göre; ENet zaman aşımı 5–8 sn; arka planda kalan oyuncu yerelde de ölür.
  - İsim filtresi (Türkçe İ/ı, kelime sınırı, gizli karakterler), LAN'da farklı sürüm odaları işaretlenir, her arayüze yönlendirilmiş yayın.
  - Yerel uçtan uca testler: ayrılmış oda ile 2 tam maç, LAN host+istemci, Matchmaker hız sınırı/127.0.0.1 kısıtı.

## #31 — Steam ve iOS Dışa Aktarımı, Android Derleme Ortamı
- **Tarih:** 2026-11-16
- **Dosyalar:** `export_presets.cfg`, `project.godot`, `autoload/Boot.gd`, `build/ucan_hamam_bocegi.apk`, `build/steam/windows/UcanHamamBocegi.exe`, `build/steam/linux/UcanHamamBocegi.x86_64`
- **Eklenenler:**
  - Godot dışa aktarma şablonları gerçek `AppData\Roaming\Godot\export_templates\4.7.2.stable` klasörüne kuruldu (önceden yalnızca Antigravity'nin geçici klasöründeydi); Java SDK yolu editör ayarına yazıldı.
  - Debug keystore kalıcı yere taşındı: `AppData\Roaming\Godot\keystores\ucan_hamam_debug.keystore`.
  - Yeni ön ayarlar: **Windows (Steam)**, **Linux (Steam Deck)** (tek dosya, `server/` hariç, `steam` özelliği) ve **iOS** (Xcode projesi, yerel ağ izni metni).
  - Masaüstünde 540x960 boyutlandırılabilir pencere + yanlarda bant (`keep`); F11 / Alt+Enter tam ekran. Mobil ayarlar değişmedi.
  - Debug APK derlendi ve imzası doğrulandı (v2+v3); Windows ve Linux sürümleri derlendi, Windows paketi çalıştırılarak denendi. iOS için Apple Ekip Kimliği (Team ID) bekleniyor.

## #32 — Faz 11A: Botlar ve Rövanş
- **Tarih:** 2026-11-17
- **Dosyalar:** `core/BotPlanner.gd` (yeni), `autoload/NetworkManager.gd`, `server/RoomServer.gd`, `data/GameConfig.gd` (`NET_VERSION` 3, `ROOM_QUICK_START_SEC` 15, "Faz 11" sabitleri), `scenes/game/ObstacleTimeline.gd`, `scenes/game/GameWorld.gd`, `scenes/entities/Player.gd`, `scenes/ui/Hud.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/CharacterPortrait.gd`, `tools/ci_check.gd`
- **Eklenenler:**
  - **Botlar:** Seed'den deterministik plan (`BotPlanner`): ölüm anı engel çiftine göre beceri olasılığıyla (acemi/mahalleli/usta), görsel yol boşluklardan geçer, ölüm anında engele sapar; sohbet, yetenek, imza ve sataşma zamanları da seed'den. Negatif kimlikler (-1..-4), `BOT_NAMES`'ten isim, gri "BOT" rozeti, sonuç satırında "· BOT". Botlar Kırıntı/görev/albüm ilerletmez. Yeni oyuncuya (ilk 3 maç) botlar en fazla 3. seviyeye kadar gider; son 5 maç ortalamasına göre seviye otomatik.
  - **Sunucu yetkisi:** Bot ölümlerini sunucu kendi `ObstacleTimeline`'ıyla hesaplar; istemciden gelen bot ölümü/skoru kabul edilmez, istemci bot ekleyemez. Gerçek oyuncular ölünce botlar 4 sn içinde planlarına göre biter.
  - **Hızlı Oyun:** 15 sn sonunda en az 1 gerçek oyuncu varsa oda botlarla 4'e tamamlanır; gerçek oyuncu gelirse bot yerini ona bırakır.
  - **Özel oda / LAN:** Oda sahibine lobide "Bot Ekle / Bot Çıkar / Seviye" satırı.
  - **Botlarla Oyna (internetsiz):** "Arkadaşlarla Oyna" penceresinde yeni bölüm; bot sayısı (1–4) ve seviye seçimi, `OfflineMultiplayerPeer` ile aynı kod yolu (sataşma, rövanş dahil).
  - **Rövanş:** Sonuç ekranında herkese büyük "RÖVANŞ!" butonu ve "Rövanş: a / t · sn" sayacı; basınca portre ciddileşip "Bi daha!" der. Herkes kabul edince lobisiz yeni maç (2 sn). 15 sn kuralı: Hızlı Oyun'da kabul edenlerle otomatik başlar (kimse kabul etmezse oda lobiye döner), özel oda/LAN'da sahibine "Kabul edenlerle başlat"; kabul etmeyenler "Rövanş seni beklemeden başladı." ile ayrılır.
  - **Taç:** Önceki maçın birincisi taçla başlar, banner "{isim}'i tahtından indirin!"; 3 seri galibiyette büyük taç + "Mahalle Muhtarı" unvanı, devrilince özel duyuru.
  - **Tek oyunculu "Aynı Parkur":** Ölüm panelinde "Tekrar Dene" yanında; aynı seed ile yeniden başlar ve önceki deneme gri "Önceki sen" hayaleti olarak uçar (`user://son_deneme.dat`).
  - Küçük düzeltmeler: sahne değişince serbest kalan düğümü yakalayan zamanlayıcı lambdaları (`Lambda capture ... freed`) giderildi.
- **Testler:** İçe aktarma, load_all (`CHECKED 49 BAD 0`), CI (0 hata; yeni bot determinizm / beceri sıralaması / yeni oyuncu sınırı kontrolleri — ortalama ölüm seviyesi acemi 1.65, mahalleli 2.65, usta 4.6). Ekran görüntüleri 390x844 ve 360x640 (menü, bot penceresi, lobi bot satırı, oyun içi BOT rozeti, taç banner'ı, sonuç + RÖVANŞ, ölüm paneli + Aynı Parkur, hayalet). Headless Botlarla Oyna: 2 maç + rövanş + reddedip menüye dönüş. Ayrılmış oda + 1 istemci: 15 sn bot tamamlama, rövanş turu, kimse kabul etmeyince lobiye dönüş ve yeniden bot tamamlama. LAN host + istemci: bot ekle/çıkar/seviye, istemcinin bot ekleme denemesi reddedildi, rövanş, zaman aşımında "Kabul edenlerle başlat".
- **Yapılmadı / not:** Bot beceri olasılıkları gerçek oyunla kalibre edilmedi. İnternetsiz bot maçında sıralama Kırıntı bonusu verilmiyor (bilinçli). Rövanşı kabul etmeyen oyuncu odadan çıkarılıyor (lobide bekletilmiyor).

## #33 — Faz 11B: Ölüm Karesi, Günlük Görevler ve Seri
- **Tarih:** 2026-11-17
- **Dosyalar:** `core/DeathFrameRecorder.gd` (yeni), `scenes/ui/DeathComicCard.gd` (yeni), `autoload/Monetization.gd`, `autoload/AudioManager.gd`, `data/GameConfig.gd` ("Faz 11.3" / "Faz 11.4" sabitleri, `DAILY_TASKS`), `scenes/game/GameWorld.gd`, `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/entities/Player.gd`, `tools/ci_check.gd`
- **Eklenenler:**
  - **Ölüm Karesi:** Yerel oyuncu hayattayken her 0.25 sn'de ekran 9:16 kırpılıp 360x640'a küçültülür, son 8 kare yalnızca bellekte tutulur (diske yazılmaz). Yakalama art arda 1 kareden (16.7 ms) uzun sürerse aralık 0.5 sn'ye çıkar. Ölüm anında siyah-beyaz efektten önce son kare alınır. Headless/görüntüsüz ortamda yakalama atlanır, kart mekan + böcek yedek karesiyle kurulur.
  - 1080x1350 çizgi roman (`SubViewport`): 1. kare ~0.75 sn önce + sarı anlatı kutusu (saate göre "Gece 03:12. Mutfak sessiz…", rekora yakınsa "Rekor kapıdaydı…", kısa maçta "Her şey yolunda gidiyordu…"); 2. kare ölüm anı, böceğin üstünde yakınlaştırılmış ve eğik, patlama yıldızında ses efekti (terlik/üst/alt engel ŞAPP!, füze BUMM!, zemin PIRT!, tavan DONK!, sürpriz FIŞŞŞ!, hayalet terlik İNTİKAM!); 3. kare Faz 10 `CharacterPortrait` sinirli yüz + sinir repliği balonu. Kalın, köşeleri birkaç piksel oynayan el çizimi çerçeveler, beyaz boşluk, pastel nokta deseni, altta logo + "{n} kişiyi korkuttu" + bağlantı. Kareler böceğin konumuna göre ortalanır.
  - Ölüm panelinde (Paylaş ile yan yana) ve çok oyunculu sıralama ekranında "Ölüm Karesi" butonu → büyük önizleme, Paylaş (GodotShare görsel + "Böyle öldüm. Sen daha iyisini yapabilir misin? {link}", yoksa panoya) ve Kapat. Kart `user://olum_karesi.png` (yalnızca sonuncusu). Ayarlar'da "Ölüm Karesi" aç/kapat (kapalıysa yakalama yok, buton yok).
  - **Günlük görevler:** Tarihten üretilen seed ile 3 görev (herkes aynı gün aynı görevler), 28 parametreli görev havuzu (`GameConfig.DAILY_TASKS`; {n}, {karakter}; sum / tek maç / ulaşılan değer kipleri; günde en fazla 1 çok oyunculu ve 1 sosyal görev), ödül 30–80 Kırıntı. Olaylar yalnızca yerel insan oyuncudan gelir (botlar görev ilerletmez; Botlarla Oyna'da oyuncunun sataşması sayılır). Maç içi ilerleme HUD bildirim yığınında küçük hap ("Görev: 7/10 kişi korkutuldu"), sık güncellemeler 2 sn'de bir.
  - Günde 1 kez ödüllü reklamla görev değiştirme (yalnızca `is_rewarded_ad_available()` ise buton görünür). 3 görev bitince **Günün Sürprizi** (tarih seed'li; 100/150/200 Kırıntı veya 1 kostüm parçası; olası içerik ekranda yazılı, satın alınamaz).
  - **Kostüm parçası:** Ayrı kostüm sistemi kurulmadı; 3 parça = Pazar'daki sıradaki kilitli kostüm (`unlocked_skins`) açılır, hepsi açıksa parça başına 200 Kırıntı.
  - **Seri:** O gün ilk maç bitince seri 1 artar, gün kaçarsa 1'den başlar; 7 günlük takvim 20 → 30 → 40 → 50 → 60 → 80 Kırıntı → 7. gün kostüm parçası (döngü, sayı artmaya devam eder). Tam 1 gün kaçırıldıysa haftada 1 "Seriyi Kurtar" (ödüllü reklam). Saat geri alınırsa görev listesi sıfırlanmaz, seri artmaz.
  - Ana menü üst çubuğunda kanat çırpan böcek ikonu + seri sayısı (dokununca Görevler). Seri 7 / 30 / 100 olunca konfetili kutlama penceresi. Görevler ekranı: seri başlığı, takvim + günlük ödül, Seriyi Kurtar, 3 görev kartı (ilerleme, ödül, Al, Değiştir), Günün Sürprizi kutusu. Görevler rozeti: alınabilir ödül sayısı, yoksa bitmemiş görev için nokta.
  - Eski kayıt uyumu: v1 `[quests]` (pass/scare/play) aynı gün açılırsa yeni biçime (version 2) taşınır; `max_seen_date` / günlük bonus mantığı aynen korundu.
  - **İsim etiketleri (11A'dan):** 3+ botta etiketler üst üste biniyordu. Etiketler dikeyde sıralanıp çakışanlar yukarı kaydırılıyor, gövdeyle birlikte dönmüyor ve tüm böceklerin üstünde çiziliyor.
- **Testler:** İçe aktarma, load_all (`CHECKED 51 BAD 0`), CI (0 hata; yeni: aynı tarih = aynı 3 görev, 28 günde ≥10 farklı liste, havuz ≥25 / ödül 30–80 / bilinen olaylar, sürpriz determinizmi, ay-yıl geçişinde gün farkı, ses efekti eşlemesi, headless'ta yakalama atlanıyor ve kart yedek kareyle kuruluyor, HUD görev bildirimi). Görev/seri mantık betiği (v1 kayıt taşıma, olaylar, ödül bir kez, sürpriz, reklamla değiştirme, seri artışı / aynı gün / saat geri alma / Seriyi Kurtar haftada 1 / sıfırlanma / 7 kutlaması, kostüm parçası) hatasız. Pencereli çalıştırmada gerçek yakalamalı kart PNG'si üretildi ve incelendi. Ekran görüntüleri 360x640 ve 390x844: ölüm paneli, kart önizlemesi, sıralama + Ölüm Karesi, menü seri hapı, Görevler ekranı, tehlikedeki seri, 7 gün kutlaması, maç içi görev bildirimi, 4 botlu isim etiketleri. Headless Botlarla Oyna: 2 maç + rövanş hatasız.
- **Yapılmadı / not:** "Annem Geldi olayında yakalanma" görevi 11.6 ani olaylar gelince (11C) havuza eklenecek. Orta seviye telefonda FPS ölçümü yapılamadı (yavaş yakalama koruması var; masaüstünde yakalama ~1 kare altında). Kostüm parçasıyla açılan kostümler mevcut Pazar kostüm kayıtlarıdır; kostümlerin oyunda görünümü bu fazın konusu değil.

## #34 — Faz 11C: Mahalle Albümü ve Ani Olaylar
- **Tarih:** 2026-11-17
- **Dosyalar:** `core/PeopleArt.gd` (yeni), `scenes/entities/FogWall.gd` (yeni), `scenes/game/EventDirector.gd` (yeni), `scenes/ui/AlbumModal.gd` (yeni), `data/GameConfig.gd` ("Faz 11.5" / "Faz 11.6" sabitleri, `PEOPLE`, `EVENTS`, `DAILY_TASKS`, `NET_VERSION` 4), `scenes/game/ObstacleTimeline.gd`, `core/BotPlanner.gd`, `scenes/entities/SlipperObstacle.gd`, `scenes/entities/Player.gd`, `scenes/game/GameWorld.gd`, `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/GuideModal.gd`, `autoload/Monetization.gd`, `autoload/NetworkManager.gd`, `autoload/AudioManager.gd`, `tools/ci_check.gd`
- **Eklenenler:**
  - **İnsan tipleri (11.5):** 12 tip (`GameConfig.PEOPLE`: ad, açılış seviyesi, açıklama, 3 çığlık lafı, renk, aksesuar, ses perdesi). Her engelin üst/alt tipi zaman çizelgesinde seed'den seçilir (ayrı RNG akışı; terlik/füze dizisi değişmedi), yeni tipler seviyeyle havuza girer. `insanlar/<id>_alt|ust.png` varsa o görsel, yoksa mevcut alt/üst görselin üstüne tipe özel yedek çizim (başörtüsü, bigudi, kasket, kask, kulaklık, gözlük, önlük, maske, kuşak; üst kolda yen rengi/deseni + bilek aksesuarı). Kafa hizası, kaide ve kafadan zemine çarpışma kutusu aynen kaldı (`--debug-collisions` görüntüsüyle bakıldı). Korkutma balonunda tipin çığlık lafı; üst engel korkutması da sayılır.
  - **Mahalle Albümü:** Bir tipin yanından ilk kıl payı geçişte kart açılır ("Yeni komşu: X!" şeridi + çığlık). 1 / 10 / 50 korkutmada Bronz / Gümüş / Altın. Yalnızca yerel insan oyuncu ilerletir (botlar ilerletmez; Botlarla Oyna ve çok oyunculuda ilerler). Kayıt şifreli `save.cfg` `[album]`; maç içinde kademe değişince, maç sonunda/yarıda kalınca yazılır. Ödüller: hepsi Bronz → 500 Kırıntı, hepsi Gümüş → `unlocked_skins`'e sıradaki kilitli kostüm (kalmadıysa 1000 Kırıntı), hepsi Altın → "Mahallenin Kâbusu" unvanı. Unvan isim etiketinin altında görünür; çok oyunculuda yeni `report_title` RPC'si (`_rpc_guard` + beyaz liste) ile yayılır.
  - Ana menü üst çubuğunda Ayarlar'ın yanında "Albüm" düğmesi (alt gezinme değişmedi). `ModalAlbum`: 3 sütun 12 kart (kademe renginde çerçeve, kilitliyse silüet + "Seviye N'de ortaya çıkar"), tamamlama ödülleri satırları. Karta dokununca `ModalAlbumCard`: büyük görsel, ad, açıklama, korkutma sayısı, sonraki kademeye kalan, çığlık sesi (tipin perdesiyle).
  - **Ani olaylar (11.6):** `GameConfig.EVENTS`; zamanlama `ObstacleTimeline` içinde seed'den (ağ mesajı yok; çok oyunculu, LAN ve Botlarla Oyna'da herkes aynı anda görür). Aynı anda tek olay, füze evresine ±2 sn yaklaşmaz, bir olayın bitişiyle sonrakinin başlangıcı arasında en az 45 sn. Her olayın ilk görülüşünde tanıtım şeridi.
    - **Annem Geldi (Sv 3+):** anahtar sesi, "ANAHTAR SESİ! KÜÇÜL!", soldan sarı ışık şeridi; Aktif-2 bekleme süresi dolar ve düğme parlar. 1.2 sn sonra ışık (beyaz parlama + sıcak ton): küçülmemiş / kalkan / hayalet fazında olmayan böcek 1 sn donar ("Yakalandım!"), diğerleri +1 kombo ve "Sıvıştın!" (görev olayı `annem_escape`). Botlar seed'li görsel küçülme + balon.
    - **Belediye İlaçlıyor (Sv 5'e girişte, sonra her 3 seviyede):** siren, ilaçlama kamyoneti, 6+ sn normal engel yok, deliği seed'li 5 sis duvarı; her duvar ekrana girmeden 0.9 sn önce sağ kenarda delik hizasında yanıp sönen ok. Sis öldürür (ölüm sebebi `belediye`); Diva kalkanı, Halay hayalet fazı ve Yurt pasifi korur. Hayatta kalana +40 Kırıntı ve akışta "{isim} belediyeyi atlattı!". `BotPlanner` sis duvarlarını da engel listesine katar (sunucu ve istemci aynı planı kurar).
    - **Elektrik Kesildi (Sv 4+):** 6 sn neredeyse tam karanlık (dünya üstü katman); yalnızca böcek gözleri ve engellerin soluk konturu görünür, o sırada gelen engellerde aralık +40 px. Bitince "Elektrik geldi!" + buzdolabı sesi.
    - **Misafir Var (Sv 2+):** 8 sn Ödü Kopan puanı x2, kutu sıklığı x1.5, engellerde misafir kılığı (şapka, papyon, çay tepsisi), ölüm satırına "…hem de misafirin önünde!". Sunucunun skor sınırı misafir engellerinde iki katı.
    - Olay sesleri dosya yoksa sentezlenir (anahtar, siren, klik, buzdolabı, kapı zili, çığlık).
  - Günlük görev havuzuna "Annem Geldi olayında {n} kez yakalanma" (`annem_kac`). Rehber'e "Ani Olaylar" sayfası (her olay için çizim ikon + tek cümle). `NET_VERSION` 3 → 4.
- **Testler:** İçe aktarma, load_all (`CHECKED 55 BAD 0`), CI (0 hata; yeni: 40 seed'de aynı seed = aynı olaylar/sis duvarları, olaylar arası ≥45 sn, füze evresiyle çakışma yok, seviye alt sınırları, her seed'de Sv 5'te Belediye, sis deliği sınırları ve art arda erişilebilirlik, sis bölgesinde normal engel yok, Elektrik aralık bonusu, insan tipi seviye kuralı ve determinizmi, sis duvarlı bot planı determinizmi, albüm eşikleri/metinleri, zorla tetikleme, 4 olayın çalışan dünyada başlat/ilerlet/bitir akışı, albüm penceresi 12 kart). Zorla tetiklenen olay ekran görüntüleri 360x640 ve 390x844 (Annem Geldi, Belediye ok uyarısı + duvarlar, Elektrik Kesildi, Misafir Var), `--debug-collisions` görüntüsü, menü, albüm, büyük kart ve Rehber sayfası görüntüleri. Headless Botlarla Oyna: 2 maç + rövanş hatasız; zorla Belediye ile botlar sis duvarında `belediye` sebebiyle elendi.
- **Yapılmadı / not:** İnsan tipleri için gerçek görsel yok; hepsi aynı temel figür + tipe özel aksesuar/renk yedek çizimi (`assets/sprites/insanlar/<id>_alt.png` / `_ust.png` eklenince otomatik kullanılır). Olay ses dosyaları yok (sentez). Belediye her 3 seviyede ve 45 sn kuralı birlikte uygulanınca Sv 5'ten sonra araya başka olay nadiren sığıyor (40 seed'de Annem 7, Elektrik 7 kez); sıklık istenirse kural "başlangıçlar arası 45 sn" yapılabilir. Annem Geldi'de botların küçülmesi yalnızca görsel (bot ölüm planı değişmez). Elektrik karanlığı PointLight yerine çizim katmanı (gözler + kontur). Betikten `draw_texture` ile çizilen doku bu sürücüde beyaz çıktığı için albüm görselleri `TextureRect` + aksesuar katmanıyla gösteriliyor.

## #35 — Faz 11D: Kendi Lafını Kaydet (Benim Lafım)
- **Tarih:** 2026-11-18
- **Dosyalar:** `core/VoiceClip.gd` (yeni), `scenes/ui/VoiceRecorderModal.gd` (yeni), `scenes/ui/PlayerSafetyUi.gd` (yeni), `web/gizlilik.html` (yeni), `autoload/NetworkManager.gd`, `autoload/AudioManager.gd`, `data/GameConfig.gd` ("Faz 11.7" sabitleri, `NET_VERSION` 5), `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `scenes/game/GameWorld.gd`, `project.godot` (`audio/driver/enable_input`), `export_presets.cfg`, `.gitignore`, `tools/ci_check.gd`
- **Eklenenler:**
  - **Kayıt ekranı:** Ayarlar → "Benim Lafım" → "Aç" (`ModalBenimLafim`). 3 yuva sekmesi (Laf atma / Sataşma / Zafer), büyük mikrofon butonu: basılı tut = kaydet (en fazla 2.0 sn, süre dolunca kendisi durur), kayıtta kırmızı canlı dalga formu (`AudioEffectCapture`) ve ilerleme çizgisi. `AudioStreamMicrophone` yalnızca buton basılıyken oluşturulur; `Mic` bus'ı (sessiz, Capture + `AudioEffectRecord`) ilk kayıtta kurulur, pencere kapanınca akış kapatılır.
  - Kayıttan sonra otomatik: mono → 2.0 sn sınırı → 16 kHz (pencere ortalamalı indirme) → baş/son sessizlik kırpma (eşik 0.04, 40 ms pay) → normalize (tepe 0.89). Çok kısa/sessiz kayıt reddedilir ("Ses duyulmadı..."). Taslak önce dinlenir: "Dinle" (ham, SFX bus) ve "Böcek Sesiyle Dinle" (Voice bus, seçili karakterin `voice_pitch` x 1.2 + mevcut kompresör/EQ). "Kaydet" → `user://benim_lafim_<yuva>.wav` (`save_to_wav`), "Sil" dosyayı ve taslağı siler. WAV okuma için küçük RIFF okuyucu (yalnızca 16 bit PCM, boyut sınırlı).
  - **Android izni:** `permissions/record_audio=true` (Android ve Android Release AAB). İzin yalnızca mikrofon butonuna ilk basışta `OS.request_permission("android.permission.RECORD_AUDIO")` ile istenir, sonuç `on_request_permissions_result` ile gelir; reddedilirse açıklayıcı mesaj, mikrofon butonu "Mikrofon kapalı" olur, oyunun geri kalanı etkilenmez. **iOS:** `privacy/microphone_usage_description` Türkçe metin.
  - **Kullanım:** Laf menüsünde 8. seçenek "Benim Lafım (sesli)" (yalnızca kayıt varsa ve oda izin veriyorsa; yeni hızlı sohbet indeksi 98, balon "(sesli laf)"; sunucu yalnızca gönderenin sesi kendisine ulaşmışsa yayınlar). Sataşma eşyasında "Özür dilerim pıttığım" sesinin yerine gönderenin "Sataşma" sesi, sıralama ekranında kazananın "Zafer" sesi (yoksa eski sesler). Çalma her zaman gönderenin karakter perdesiyle Voice bus'tan.
  - **Ağ paylaşımı:** Yalnızca Özel Oda ve LAN. İstemci kendini oyuncu listesinde ilk gördüğünde (kayıt tamamlanınca, lobide) yuva başına bir kez `upload_custom_voice` (ayrı güvenilir kanal 2): 11025 Hz 16 bit PCM + ZSTD, yuva başına ≤ 48 KB sıkıştırılmış ve ≤ 44200 bayt açılmış (2 sn). Sunucu: `_rpc_guard` + üyelik, Hızlı Oyun'da ve maç sırasında ret, yuva başına oturumda tek kabul, boyut ve açılma doğrulaması (açılınca büyüyen paket reddi); sesi yalnızca bellekte tutup diğer üyelere `relay_custom_voice` ile aktarır, yeni gelene odadaki sesleri bir kez gönderir, oyuncu çıkınca siler; diske yazmaz, loglamaz. LAN host da oyuncu olduğundan kendi seslerini önbelleğe koyar, gelenleri doğrudan belleğe alır. Alıcı da doğrular ve yalnızca bellekte tutar. **Hızlı Oyun'da** istemci kod seviyesinde göndermez, sunucu reddeder, alıcı kabul etmez, hiçbir yerde çalınmaz.
  - **Kontrol ve güvenlik:** Ayarlar'da "Arkadaşların özel seslerini çal" (settings.cfg `[audio] friend_voices`). Lobide oda sahibine "Özel sesler: Açık/Kapalı" (yalnızca Özel Oda/LAN; kapalıyken sunucu aktarmaz, kimse çalmaz, lobide "· Özel sesler kapalı"). Lobide her diğer gerçek oyuncunun kartı altında "Bu oyuncuyu sustur" / "Bildir"; maç içinde "Hayatta" hapına dokununca "OYUNCULAR" penceresi (aynı düğmeler). Susturma oturum boyu: o kişinin özel sesleri, hızlı sohbet balonları ve sataşma lafı çalmaz/görünmez.
  - **Bildir:** Sebep seçimi (Rahatsız edici ses / Küfür-hakaret / Uygunsuz isim / Diğer); ayrılmış sunucuya oyuncu, oda kodu ve sebep gider, sunucu `server/reports.log`'a tek satır yazar (dışa aktarılmış sunucuda çalıştırılabilir dosyanın yanında `reports.log`). Ses verisi gönderilmez. Kişi başına aynı hedefe 1, oturumda en fazla 5 bildirim; sunucuda eş başına üst sınır. **LAN'da** sunucu olmadığı için (host da oyuncu, bildirilen kişi olabilir) bildirim cihazda `user://bildirim_kuyrugu.cfg` kuyruğuna yazılır (en fazla 10) ve bir sonraki çevrimiçi odaya katılınca `submit_queued_report` ile iletilip silinir (log satırında `oda=LAN`).
  - `web/gizlilik.html`: oda.html üslubunda gizlilik taslağı; mikrofon bölümü (yalnızca basılı tutarken açılır, ilk basışta izin, cihazda saklanır, yalnızca davetli oda üyelerine iletilir, Hızlı Oyun'da asla, sunucuda saklanmaz/loglanmaz, alıcıda yalnızca bellekte), susturma ve bildirim maddeleri.
  - `NET_VERSION` 4 → 5. `server/reports.log` .gitignore'da.
- **Testler:** İçe aktarma, load_all (`CHECKED 58 BAD 0`), CI (0 hata; yeni 11D: sentetik PCM ile sessizlik kırpma süresi, normalize tepe, 16 kHz'e indirmede 440 Hz korunuyor (~880 geçiş/sn), 2.6 sn kaydın 2.0 sn'ye kesilmesi, sessiz kaydın reddi, WAV yaz/oku, geçersiz yuva reddi, ağ paketi (1.4 sn: 23808 → 4452 bayt; en kötü durum 2 sn gürültü: 44100 → 44110 bayt ≤ 48 KB), yanlış boyut / 48 KB üstü / açılınca büyüyen paket reddi, hızlı sohbet indeksi 98, Hızlı Oyun kapısı, kayıt penceresinin sentetik kayıtla taslak oluşturması ve mikrofon akışı/`Mic` bus'ının kayıt başlamadan açılmaması, oyuncular penceresi). Ayrılmış oda (Özel) + 2 istemci: iki taraf da karşı tarafın 3 yuvasını aldı (11025 Hz; yeni gelene önbellekten, sonra gelenin yüklemesi aktarımla), tekrar / 48 KB üstü / geçersiz yuva yüklemeleri reddedildi (alıcıda yeni olay yok), sesli laf iletildi, susturunca çalmıyor, bildirim `reports.log`'a yazıldı (ikinci bildirim engellendi), LAN kuyruğu çevrimiçi odada iletildi, oda sahibi sesleri kapatınca sesli laf iletilmedi, sahip olmayanın açma isteği yok sayıldı. Hızlı Oyun odası + 2 istemci: otomatik gönderim yok, zorla gönderilen ses ve sesli laf sunucuda reddedildi, alıcıda hiç ses yok. LAN host + istemci: karşılıklı 3'er yuva, host'un sesli lafı istemcide, LAN bildirimi yerel kuyrukta. Ekran görüntüleri 360x640 ve 390x844: Benim Lafım (taslak dalga formu, canlı kayıt görünümü), Ayarlar bölümü, lobi Sustur/Bildir + Özel sesler düğmesi, Bildir penceresi, maç içi Oyuncular penceresi, 8 seçenekli laf menüsü. Headless Botlarla Oyna hatasız.
- **Yapılmadı / not:** Gerçek mikrofon kaydı headless ortamda denenemedi (kayıt yolu sentetik PCM ile birim testli; `AudioEffectRecord` / `AudioStreamMicrophone` bağlantısı gerçek cihazda denenmeli). Android izin akışı cihazda denenmedi. Ayrılmış sunucu bildirim günlüğü UTC zaman damgalı; Eşleştirici'ye ayrı bildirim kanalı eklenmedi (kuyruk oda sunucusu üzerinden gider). Maç içinde oyuncu kartı olarak "Hayatta" hapı kullanıldı (dokunmak uçuşu tetiklemez); sıralama satırları dokunulabilir yapılmadı.


## #36 — Faz 12A-B: Böcek Kimliği, Mahalle bağlantısı ve arkadaşlık
- **Tarih:** 2026-11-18
- **Dosyalar:** `autoload/Mahalle.gd` (yeni autoload), `server/UserStore.gd` (yeni), `server/MahalleHub.gd` (yeni), `scenes/ui/FriendsUi.gd` (yeni), `web/arkadas.html` (yeni), `server/Matchmaker.gd`, `server/RoomServer.gd`, `autoload/NetworkManager.gd`, `data/GameConfig.gd` ("Faz 12.1–12.3" sabitleri, `NET_VERSION` 6, `MM_MAX_CONNECTIONS` 128), `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `project.godot`, `server/SUNUCU_KURULUM.md`, `web/README.md`, `.gitignore` (`server/data/`), `tools/ci_check.gd`
- **Eklenenler:**
  - **Böcek Kimliği (12.1):** İlk çevrimiçi girişte (Çevrimiçi / Arkadaşlar ekranı) `hello` kimliksiz gider, sunucu `#XXXX-XXXX` kimlik (karışmayan 32 karakter, `Crypto` rastgele, benzersiz) + 32 baytlık gizli anahtar verir. Cihazda `user://hesap.cfg` şifreli (`save_encrypted_pass`); sunucu yalnızca SHA-256 özetini tutar, karşılaştırma sabit zamanlı. Anahtar ve kurtarma kodu hiçbir yerde loglanmaz. Ad değişebilir, kimlik değişmez.
  - **Kurtarma Kodu:** Ayarlar → Hesabım → "Kurtarma Kodu" (16 karakter, sunucuda özeti; yenisi eskisini geçersiz kılar; kimlik başına saatte 5). "Kimliğimi Geri Yükle": kimlik + kod; doğruysa yeni anahtar üretilir, eski cihazın açık oturumu "Kimliğin başka bir cihazda geri yüklendi" ile kapanır ve eski anahtar artık geçmez ("Bu cihaza yeni kimlik al" seçeneği). Kaba kuvvete karşı: geri yükleme IP başına saatte 10, kimlik başına saatte 5 (sınır dolunca doğru kod da reddedilir), hatalı kimlik doğrulama IP başına saatte 30, yeni kimlik IP başına saatte 10.
  - **users.json:** `{id: {name, char, title, token_hash, recovery_hash, created, last_seen, friends, requests_in, requests_out, blocked, rejected_by, req_day, req_count, stats{matches, wins, muhtar, album}}}`; bellekte, değişiklik en geç 5 sn içinde diske (`.tmp` + yeniden adlandırma), açılışta bozuksa `.tmp` / en yeni yedek. Günlük `users_YYYYMMDD.json`, son 7 tutulur. Veri klasörü `--data-dir=` ile değiştirilebilir (dışa aktarılmış sunucuda çalıştırılabilir dosyanın yanındaki `data/`). `blocked` alanı 12D için hazır.
  - **Kalıcı Mahalle bağlantısı (12.2):** Aynı TCP 7700; `hello` sonrası bağlantı kalıcı oturuma yükselir, kısa bağlantı kuralları (5 sn boşta, IP başına 4, yanıt sonrası kapanma) aynen kaldı. Oturum kuralları: boşta 60 sn (istemci 20 sn'de ping), kimlik başına 2 bağlantı (yenisi gelince en eskisi kapanır), kimlik başına dakikada 60 mesaj (aşınca bağlantılar kapanır, 5 dk bekletilir), IP başına 16, toplam 2000 oturum. İstek/yanıt `rid` ile, sunucu itmeleri ayrı `op` (`presence`, `friend_request`, `friend_added`, `friend_removed`, `request_gone`, `kicked`); 12C davetleri aynı kanala yeni `op` olarak eklenecek.
  - İstemci (`Mahalle.gd`): kopunca 2, 4, 8 … 60 sn geri çekilme; arka planda 30 sn sonra kapanır, öne gelince açılır; bağlanamazsa "Arkadaşlar" girişi ve "Çevrimiçi Oyna" gri (tek oyunculu, LAN, Botlarla Oyna etkilenmez). Oda kodu, ad/karakter/unvan ve istatistikler (toplam maç, Muhtar sayısı, albüm) değişince sunucuya gider.
  - **Durum:** Oda sunucusu 2 sn'lik `room_status` mesajına odadaki kimlikleri (`uids`) ekler, maç sonunda `room_result` (kazananın kimliği) gönderir; galibiyet yalnızca buradan sayılır. Oyuncu kimliği odaya yeni `report_user_id` RPC'siyle bildirilir (`_rpc_guard`, biçim kontrolü, odada tekrar yok; `register_player` imzası değişmedi). 12C'deki giriş biletine kadar doğrulanmadığı için eşleştirici, kullanıcının kendi oturumunun bildirdiği oda koduyla oda listesini karşılaştırır (uyuşmazsa durum/galibiyet sayılmaz). Durum değişince çevrimiçi arkadaşlara anında `presence`: Çevrimiçi (yeşil) / Odada (3/5) (sarı) / Maçta (turuncu) / Son görülme (gri).
  - **Arkadaşlık (12.3):** Kimlikle (# ve tire isteğe bağlı, küçük harf, bağlantı yapıştırma), paylaşım bağlantısıyla (`ucanbocek://arkadas/<ID>` → "İstek gönderilsin mi?"), Son Oynadıkların sekmesinden (çevrimiçi/LAN maç sonucundan son 20 gerçek oyuncu, botlar hariç) ve lobi/sıralama kartından profil kartı → "Arkadaş Ekle". Karşılıklı istek otomatik arkadaşlık. Sınırlar: 100 arkadaş, günde 30 istek, reddedilene 24 saat. Bağlantı yokken gönderilen istek sıraya alınır (en fazla 10), bağlanınca gider.
  - **Arayüz:** Ana menüde isim kutusunun altında "Böcek Kimliğin: #XXXX-XXXX" + Kopyala / Paylaş (paylaşım metni + `arkadas.html?k=`). Alt gezinmeye "Arkadaşlar" (Görevler ile Yetenekler arası, gelen istek sayısı rozeti). Arkadaşlar ekranı: Arkadaşlar / İstekler / Son Oynadıkların sekmeleri, sıralama odada → maçta → çevrimiçi → çevrimdışı (son görülmeye göre); satırda ikon, ad, kimlik, durum noktası ve yazısı; maçtakinde "Maç bitince katılabilirsin"; dokun = profil, uzun bas = Profil / Arkadaşlıktan Çıkar. Profil kartı: `CharacterPortrait` (gururlu), ad, kimlik, unvan, durum, toplam maç / galibiyet / Mahalle Muhtarı / albüm. Gelen istek bildirim şeridi ([Kabul] [Reddet], maç sırasında bekletilir). Lobide ve sıralama ekranında gerçek oyuncu kartında kimlik (botlarda yok), dokununca profil kartı. Ayarlar → Hesabım.
  - `web/arkadas.html` (`oda.html` mantığı, kimlik alfabesiyle doğrulama), `SUNUCU_KURULUM.md`'ye yedekleme / SQLite notu ve oturum sınırları, `web/README.md`'ye Android intent-filter adımları.
- **Testler:** İçe aktarma, load_all (`CHECKED 62 BAD 0`), CI (0 hata; yeni 12A-B: kimlik/kod normalleştirme ve biçim, sabit zamanlı karşılaştırma, güvenli yazım ve `.tmp` kalmaması, dosyada düz anahtar olmaması, 9 eski yedekten 7'ye budama, yeniden yüklemede anahtar doğrulama, ret sonrası 24 saat ve süre dolunca izin, karşılıklı arkadaşlık, günde 30 istek, 100 arkadaş sınırı, kimlik başına 2 bağlantı, kurtarma deneme sınırı (sınırdan sonra doğru kod da ret), geri yüklemede eski anahtarın geçersizleşmesi, dakikada 60 mesaj ve 5 dk bekletme, pencerelerin kurulması). Yerel eşleştirici + 3 headless istemci: kimlik alındı; küçük harf/tireli kimlikle ve bağlantıyla istek; kendine / olmayan kimliğe ret; kabul iki tarafta görünür; ret sonrası 24 saat mesajı; karşı istek kabulü. A özel oda kurup maç oynadı, B ve C anında Odada (1/5) → Maçta → Odada → Çevrimiçi → Son görülme gördü; galibiyet `room_result` ile 1. Eşleştirici öldürülüp açıldı: 3 kullanıcı ve arkadaşlıklar yerinde, istemciler aynı kimlikle bağlandı; günlük yedek oluştu, eski yedekler 7'ye budandı. Kurtarma: yanlış kodla ret (yeni kimlik açılmadı), doğru kodla yeni cihaz aynı kimlik ve arkadaşları aldı, eski cihaz anında atıldı, yeniden açılınca "Kimlik doğrulanamadı". Arka planda 30 sn kapanma ve öne gelince yeniden bağlanma; sunucusuzken geri çekilme ve gri görünüm. Kısa bağlantı regresyonu (oda açma / hız sınırı / yerel kısıtı / 5 sn boşta / 4 KB tampon) değişmedi. Ekran görüntüleri 360x640 ve 390x844: ana menü (kimlik satırı, 5'li alt gezinme + rozet), Arkadaşlar 3 sekme, profil kartı, Hesabım, bildirim şeridi, lobi kimlikleri, çevrimdışı gri görünüm.
- **Yapılmadı / not:** Android'de `ucanbocek://` bağlantısının oyunu açması için Android derleme şablonu (`android/build/`) + intent-filter ve bağlantıyı ileten küçük eklenti gerekiyor (adımlar `web/README.md`'de; `Mahalle` `UcanBocekDeepLink` tekilini ve komut satırını okuyor). O zamana kadar bağlantı/kimlik "Arkadaş Ekle" kutusuna yapıştırılabiliyor. "Davet Et" / "Oda Kur ve Davet Et" / "Katıl" düğmeleri ve Engelle 12C/12D'ye bırakıldı (gizli). Oyuncu kimliği oda sunucusunda henüz doğrulanmıyor (12C giriş bileti). Arkadaşlar ekranı sekme değişince içerik kadar büyüyüp küçülüyor. Toplam maç ve Muhtar sayısı istemci beyanı; yalnızca galibiyet sunucu hesabı.


## #37 — Faz 12C-D: Davet, oda gizliliği, giriş bileti, engelle/bildir, hesap silme ve TLS
- **Tarih:** 2026-11-18
- **Dosyalar:** `net/RoomTicket.gd` (yeni), `net/NetStream.gd` (yeni), `server/DeleteHttp.gd` (yeni), `server/moderation.json` (yeni), `web/hesap-silme.html` (yeni), `server/MahalleHub.gd`, `server/Matchmaker.gd`, `server/RoomServer.gd`, `server/UserStore.gd`, `autoload/Mahalle.gd`, `autoload/NetworkManager.gd`, `data/GameConfig.gd` ("Faz 12.4–12.5" sabitleri, `NET_VERSION` 7, `USE_TLS`), `scenes/ui/FriendsUi.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/Lobby.gd`, `server/SUNUCU_KURULUM.md` (bölüm 8–10), `web/gizlilik.html`, `web/README.md`, `tools/ci_check.gd`
- **Eklenenler:**
  - **Giriş bileti:** Oda açma/katılma artık yalnızca kimliği doğrulanmış Mahalle oturumundan (`room_quick`, `room_create`, `room_join_code`, `join_friend`, `invite_accept`); eski kısa istekler "Önce Mahalle'ye bağlan (oyunu güncelle)" ile reddedilir. Eşleştirici `{kimlik, oda kodu, 60 sn, tek kullanımlık rastgele, gizli ad bayrağı}` + HMAC-SHA256 bilet verir; oda sunucusu `register_player(..., bilet)` ile imzayı, kodu, süreyi doğrular, aynı bileti ikinci kez kabul etmez, aynı kimliği iki kez almaz. `players[pid].uid` biletten gelir; `report_user_id` ayrılmış odada yok sayılır (yalnızca LAN), Mahalle oturumundaki oda kodu çapraz kontrolü kaldırıldı (durum oda sunucusunun doğrulanmış listesinden). Anahtar `UCAN_BOCEK_TICKET_KEY` ortam değişkeniyle oda süreçlerine geçer (komut satırında yok, oda okuyunca siler; verilmezse rastgele). Oda yerleri bilet verilince 60 sn ayrılır (dolu oda yarışı yok).
  - **Oda gizliliği:** Kodla açık / Sadece arkadaşlarım (varsayılan) / Sadece davetliler; Çevrimiçi Oyun penceresinde oda kurmadan önce ve lobide oda sahibi (maç dışında) değiştirebilir (`request_room_privacy`, oda durumu anında eşleştiriciye). Kodla girişte gizliliğe göre "Bu oda sadece oda sahibinin arkadaşlarına açık." / "Bu oda sadece davetlilere açık." Lobide sahip olmayanlara gizlilik adı.
  - **Davet:** Lobide "Arkadaş Davet Et" (sahibe; Kodla açık / Arkadaşlarım odalarında herkese) ve arkadaş satırı menüsünde "Odama Davet Et". Davet popup'ı (karakter portresi + balon "Ayşe seni mutfağa çağırıyor! (Oda: KTRB, 2/5)", [Katıl] [Sonra], 30 sn geri sayım); maçtaysa popup maç bitene kadar bekler. Arkadaşlar ekranında "Bekleyen davetler" (Katıl / Sil, kalan dakika); davet 10 dk geçerli, kişi başına 10 bekleyen, dakikada 10 davet; alt gezinme rozeti istek + davet. Çevrimdışı arkadaşa "Arkadaşın çevrimdışı. Bağlantıyı WhatsApp'tan gönder?" (oda bağlantısı paylaşımı). Arkadaş satırında Odada / Maçta için "Katıl"; oda maçtaysa "Maç bitince otomatik katıl" (15 dk tutulur, Vazgeç), maç bitince eşleştirici otomatik bilet iter ve istemci lobiye geçer.
  - **Engelle:** Profil kartında ve arkadaş menüsünde (onaylı); arkadaşlık, istekler ve davetler iki yönde silinir; engellenen istek/davet gönderemez, profili göremez, aynı odaya (kodla açık dahil, ayrılmış yerler sayılır) giremez, Hızlı Oyun'da aynı odaya düşmez. Hesabım → Güvenlik → Engellenenler (Engeli Kaldır), en fazla 200.
  - **Bildir (profil kartı):** Uygunsuz isim / Taciz / Hile / Diğer → `reports.log`'a `kaynak=profil` satırı, kimlik başına saatte 10. `moderation.json` `hide_names` listesindeki kimliklerin adı başkalarına ve oda sunucusunda "Böcek #XXXX" görünür; dosya 60 sn'de bir değişirse yeniden yüklenir. Dakikada 60 mesaj sınırı 12A-B'deki gibi.
  - **Hesabımı Sil:** Hesabım → Güvenlik → Hesabımı Sil; kimliği yazınca "Kalıcı Olarak Sil" açılır. Sunucu kaydı, diğerlerinin arkadaş/istek/engel/ret listelerindeki izleri, davetler ve bekleyen otomatik katılımlar silinir; günlük yedeklerdeki kopyalar da temizlenir; kimlik `deleted_ids.json`'a girer ve bir daha verilmez. Cihazda `hesap.cfg` silinir (Kırıntı, karakterler, satın alımlar kalır); arkadaşlara anında `friend_removed`.
  - **Web hesap silme:** `web/hesap-silme.html` (kimlik + kurtarma kodu formu, onay kutusu, kodu yoksa `{DESTEK_EPOSTA}`) → eşleştiricideki küçük HTTP ucu `POST /hesap-sil` (port 7701): yalnızca POST (diğerleri 405), başlık 4 KB, gövde 1 KB, 5 sn zaman aşımı, 16 bağlantı, IP başına dakikada 20 istek + saatte 10 silme denemesi, kimlik başına saatte 5; CORS yok, güvenlik başlıkları, yanıt kaçışlı HTML; logda kimlik/kod yok.
  - **TLS:** `GameConfig.USE_TLS` (yerelde `--tls`); eşleştirici 7700 ve HTTP ucu `StreamPeerTLS` + `TLSOptions.server()` (sertifika `--tls-cert=`/`--tls-key=` ya da `data/tls/`), istemci ve oda süreçleri TLS istemci. Sertifika yüklenemezse sunucu şifresiz açılmaz. Yayın derlemesinde TLS kapalıysa konsola büyük uyarı. Debug derlemede `--tls-trust=<pem> --tls-cn=` ile kendinden imzalı sertifikaya güvenme. `SUNUCU_KURULUM.md`: alan adı, certbot, yenileme kancası, sertifika yolları, bilet anahtarı (systemd `Environment=`), 7701 portu, moderasyon ve silme.
  - `web/gizlilik.html`: "Böcek Kimliği ve arkadaşlar" bölümü (ne tutulur, neden, kişisel bilgi toplanmaz, kim görür, nasıl silinir), profil bildirimi maddesi.
- **Testler:** İçe aktarma, CI (`CiCheck.tscn`, 0 hata; yeni 12C-D: bilet geçerli / başka oda / süresi geçmiş / sahte imza / gövde değiştirme / başka anahtar / boş, tek kullanım ve gizli ad, hub gizlilik-davet-kabul-otomatik katılım-engel-Hızlı Oyun-profil-moderasyon-bildirim-silme, silinen kimliklerin kalıcılığı, web silme, HTTP ayrıştırma/405/404/413/kaçış/CORS yok, pencereler). Yerel eşleştirici + 4 headless istemci uçtan uca: davetliler/arkadaşlarım odasına yabancının ve arkadaşın kodla girişi reddedildi, kodla açıkta kabul; arkadaşlarım odasına "Katıl" biletle (uid kayıtlı); davet popup'ı + Katıl; arkadaş olmayana davet reddi; biletsiz / süresi geçmiş / sahte / başka oda bileti bağlantıyı kesti; engel sonrası kodla açık odaya ve isteğe ret; maçtaki odaya Katıl → "Maç sürüyor" → otomatik katılım maç bitince (oda 2 kişi); maçtayken gelen davet popup'ı maç bitince açıldı; Hızlı Oyun'da engelli iki kişi farklı odalara düştü; Hesabımı Sil (yanlış onay reddi, hesap.cfg silindi, arkadaş listeleri güncellendi); web ucu GET 405, yanlış kod reddi, doğru kodla silme ("Hesabın silindi" ile oturum kapandı). TLS: kendinden imzalı sertifikayla eşleştirici, güvenen istemci bağlandı ve Hızlı Oyun bileti aldı (oda süreci de TLS ile bağlı), güvenmeyen istemci ve düz TCP istemci reddedildi, HTTPS silme ucu yanıt verdi. Ekran görüntüleri 360x640 ve 390x844: davet popup'ı, Çevrimiçi Oyun gizlilik seçici, lobi gizlilik + Arkadaş Davet Et, Bekleyen davetler, davet edilecek arkadaşlar, Hesabım, Hesabımı Sil onayı. Kullanıcı verisi testlerden önce yedeklendi, sonra geri yüklendi.
- **Yapılmadı / not:** Gerçek alan adı + Let's Encrypt sertifikası ve `USE_TLS = true` yayın öncesi yapılacak (adımlar `SUNUCU_KURULUM.md` bölüm 9); `{DESTEK_EPOSTA}` ve `hesap-silme.html` içindeki `SILME_UCU` yer tutucu. Oyun içi ENet trafiği şifresiz (kişisel veri yok). Bilet anahtarı ortamda verilmezse eşleştirici yeniden başladığında açık odalara yeni giriş olmaz. Bildirimler incelemesi elle (`reports.log` + `moderation.json`). 360x640'ta lobi kalabalık ama kesilme yok.

## #38 — Faz 13A: Sesli sohbet
- **Tarih:** 2026-11-18
- **Dosyalar:** `net/VoiceChat.gd` (yeni), `net/VoiceJitterBuffer.gd` (yeni), `scenes/ui/VoiceChatUi.gd` (yeni), `autoload/NetworkManager.gd`, `autoload/AudioManager.gd`, `autoload/Mahalle.gd`, `data/GameConfig.gd` ("Faz 13A" sabitleri, `NET_VERSION` 8), `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `scenes/game/GameWorld.gd`, `scenes/entities/Player.gd`, `scenes/ui/PlayerSafetyUi.gd`, `scenes/ui/MainMenu.gd`, `scenes/ui/GuideModal.gd`, `export_presets.cfg` (iOS mikrofon açıklaması), `web/gizlilik.html`, `web/README.md`, `tools/ci_check.gd`
- **Eklenenler:**
  - **Eklenti kapısı:** Opus kodlama/çözme TwoVoip GDExtension'ından (`TwovoipOpusEncoder`, `AudioStreamOpus`); sınıflar `ClassDB.class_exists` ile aranır, statik tip yok, çağrılar dinamik. Eklenti yoksa sesli sohbet seçenekleri (Ayarlar bölümü, lobi kutusu, HUD ikonu, "Ses" butonu, katılma penceresi) hiç görünmez; oyun hatasız çalışır.
  - **Ağ:** Paket = [bayrak (bit0 konuşma sonu)][16 bit sıra][Opus]. Kanal 3, `unreliable_ordered` (kanal 2 Faz 11D Benim Lafım güvenilir aktarımında, çakışmasın diye ayrı kanal). İstemci -> sunucu `send_voice_chat`, sunucu/LAN host -> dinleyenler `relay_voice_chat`; sunucu çözmez, saklamaz, loglamaz. Sunucu oyuncu başına saniyede 60 paket (fazlası atılır, 240 üstü odadan atılır), 3..400 bayt, oda izinli + açık + gönderen "Katıl" denetler. Hızlı Oyun'da (ve internetsiz botlarda) kod seviyesinde kapalı: kip 0'a zorlanır, paket reddedilir, alıcı da düşürür. Kip (`players[pid].vc`: 0 kapalı / 1 dinliyor / 2 konuşabilir) sunucuya bildirilir, oyuncu listesiyle eşlenir.
  - **Oda sahibi:** Lobide "Sesli Sohbet: Açık/Kapalı" ve "Herkes Böcek Sesiyle: Açık/Kapalı" (yalnızca sahip değiştirebilir; yeni gelenlere eşlenir). Böcek sesi zorunluyken lobi paneli sarı şeride döner ("Herkes böcek sesiyle!" + antenli dalga).
  - **Katılma:** Sesli sohbetli odaya ilk girişte "Katıl / Sadece Dinle / Hayır" penceresi (kulaklık önerisi, yankı uyarısı); seçim `settings.cfg [voice_chat]`. Mikrofon izni yalnızca Katıl'da istenir, reddedilirse Sadece Dinle.
  - **Konuşma:** Otomatik (eşik + 500 ms bekleme) ve Bas-Konuş; 20 ms kare, 10 kbps, RNNoise gürültü bastırma (eklentide varsa). Yankı önleme: başkası konuşurken yerel eşik yükselir (yarı çift yönlü kapı). Uygulama arka plana geçince mikrofon anında kapanır.
  - **Çalma:** Konuşan başına `VoiceChat_<peer>` alt bus (+ `PitchShift` böcek sesi için, perde = karakter sesi x 1.2) ve titreşim tamponu (~100 ms birikim, sıralama, geç gelen atılır, kayıp parça atlanır, kuyruk 300 ms'yi geçerse kırpılır). Biri konuşurken müzik -6 dB, efektler -3 dB (yumuşak geçiş).
  - **Arayüz:** HUD sol üstte "Laf At"ın yanında mikrofon ikonu (kapalı = üstü çizili, açık = gri, konuşuyor = yeşil dalga; dokununca sustur/aç); Bas-Konuş küçük buton yanında, ölüm paneli / izleyici / sıralamada büyük olarak sol altta. Konuşan böceğin ağzı oynar, isminin yanında dalga ikonu; lobide kartı parlar. Kişi menüsünde "Ses": sustur + kişiye özel ses seviyesi; "Herkesi sustur". Engellenen kişi (Faz 12D listesi, `Mahalle.blocked_ids`) otomatik susturulur.
  - **Ayarlar → Sesli Sohbet:** Katılım, Konuşma şekli, eşik çubuğu + "Dene", eşik ve ses seviyesi kaydırıcıları, Yankı önleme, "Arkadaşları böcek sesiyle duy", hoparlör uyarısı. Rehber'e "Sesli Sohbet" sayfası. `web/gizlilik.html` sesli sohbet bölümü, `web/README.md` Play Console notu ("aktarılan ama saklanmayan") ve TwoVoip kurulum adımları.
- **Testler:** İçe aktarma, `load_all` (68 betik, 0 hata), CI (0 hata; yeni 13A: paket kur/ayrıştır, titreşim tamponu sıralama/geç/kayıp/bitiş, kip hesabı, eşik + yankı, tepe ölçümü, ağsız kapılar, eklentisiz UI gizli, önizleme pencereleri, ducking, artık bus kalmaması). Eklentili (DLL engelli, bkz. not) ve eklentisiz iki durumda da load_all + CI temiz; eklenti kaldırılınca `extension_list.cfg` temizlendi. Headless sentetik bayt istemcileriyle (mikrofon yok): Özel Oda + 3 istemci (sahip konuşur, biri dinler, biri katılmadı): 50/50 paket sırayla dinleyene ulaştı, katılmayana 0; 150 paket selinde 57 aktarıldı (saniye sınırı), 401 baytlık paketler aktarılmadı; susturma ve engelde 0 çalındı (düşürüldü); dinleyicinin zorla gönderdiği 0 ulaştı; sahip olmayanın kapatma isteği yok sayıldı; sahip "Herkes Böcek Sesiyle"yi açtı ve sohbeti kapattı, kapalı odada 0. Hızlı Oyun odası: izinli=false, tüm kipler 0, normal gönderim 0/20, zorla 20 paket 0 ulaştı. LAN host + istemci: iki yönde 30/30 sıralı, istemcinin seli/büyük paketleri host'ta reddedildi. Maçta mikrofon ikonuna, Bas-Konuş'a ve Laf At'a dokunmak zıplatmadı (boş alana dokunmak zıplattı). Ekran görüntüleri 360x640 ve 390x844: katılma penceresi, lobi anahtarları + böcek sesi şeridi, HUD mikrofon ikonu (üst çubukla çakışmıyor), ölüm panelinde büyük Bas-Konuş, Ayarlar → Sesli Sohbet. Kullanıcı verisi testlerden önce yedeklendi, sonra geri yüklendi.
- **Yapılmadı / not:** TwoVoip v6.6.2 (MIT, Godot 4.6+) indirildi ve incelendi ama **projeye eklenmedi**: bu bilgisayarda Windows Akıllı Uygulama Denetimi imzasız `libtwovoip` DLL'ini engelledi ("Error 4551"), eklenti yüklenemedi. Bu yüzden gerçek Opus kodlama/çözme, mikrofon, eşik, yankı ve ducking'in kulakla doğruluğu denenmedi; eklenti API'si sürümün yardımcı betiğinden okundu. Kurulum adımları `web/README.md`'de. Gerçek iki telefonla test yapılamadı. ENet ses trafiği şifresiz (Opus, oda içi). Sunucu çıkışındaki "1 resources still in use" uyarısı önceden de vardı.

## #39 — Faz 13B: Profesyonel açılış ve ana menü
- **Tarih:** 2026-11-18
- **Dosyalar:** `scenes/ui/MainMenu.gd` (yeniden yazıldı), `scenes/ui/MainMenu.tscn`, `scenes/ui/KitchenScene.gd` (yeni), `scenes/ui/Intro.gd` + `Intro.tscn` (yeni, ana sahne), `scenes/ui/Logo.gd` + `Logo.tscn` (yeni), `scenes/ui/CreditsModal.gd` (yeni), `core/UiFeel.gd` (yeni), `ui/tema.tres` (yeni, `gui/theme/custom`), `core/ComicUiHelper.gd` (`build_modal` alttan kayan kart / gömülü sayfa / kaydırarak kapatma), `scenes/ui/ShopModal.gd` (gömülü kip), `scenes/ui/Hud.gd` ve `scenes/ui/DeathComicCard.gd` (paylaşım kartında ortak logo), `autoload/AudioManager.gd`, `autoload/Boot.gd`, `data/GameConfig.gd` ("Faz 13B" sabitleri), `project.godot` (açılış ekranı, ikon, tema, ana sahne), `export_presets.cfg` (Android uyarlanır ikonlar, lisans .txt dahil), `tools/IconMaker.tscn` + `icon_maker.gd`, `tools/StoreShots.tscn` + `store_shots.gd`, `assets/icon/*`, `.gitignore` (`store_output/`), `tools/ci_check.gd`
- **Eklenenler:**
  - **Tema:** Baloo 2 (600, başlık 800) varsayılan yazı; krem kâğıt, 3 px mürekkep kenar, düzensiz köşe, yumuşak gölge; tür varyasyonları BaslikLabel 64 / AltBaslikLabel 44 / GovdeLabel 24 / KucukLabel 21, BirincilButton, KartPanel, SayfaPanel, SheetPanel. Boyutlar mevcut `GameConfig.FS_*` ölçeğine eşlendi (720 px genişlikte 30 px gövde fazla büyük; 64/44/24/21 korundu).
  - **Yaşayan mutfak:** Katmanlı sahne, yavaş otomatik kaydırma (ön katman 1.45x), perde salınımı, gerçek saati gösteren duvar saati, buzdolabı motor titremesi, çaydanlık ve çay bardağı buharı, 20-40 sn'de bir şaka (duvarda böcek, terlik bakışı, buzdolabı aralanması), 22:00-06:00 gece (ay ışığı, dolap altı ve tezgâh lambası). Tezgâhta seçili böcek; dokununca tepki verir.
  - **Ana menü:** Üst çubuk (portre + ad + kimlik kartı, Kırıntı, seri), büyük OYNA → alttan kayan mod kartı (Tek Başına + ikinci satır Günün Mutfağı, Botlarla Oyna, Arkadaşlarla (Aynı Wi-Fi), Çevrimiçi); son mod işaretli, basılı tutunca son mod doğrudan başlar. 5 sekmeli alt menü (Pazar · Böcekler · Ana Sayfa · Görevler · Arkadaşlar) rozetlerle; sekme geçişi 0.2 sn yatay kayma. Profil kartı ve dişli: Ayarlar, Albüm, Nasıl Oynanır, Emeği Geçenler, Hesabım. Pencereler %35 karartma üstünde alttan kayar, aşağı kaydırınca kapanır. Her buton basınca 0.95'e iner, tık sesi + kısa titreşim (Ayarlar'dan kapatılabilir). Android Geri: pencere → sekme → Ana Sayfa → çıkış.
  - **Logo:** `Logo.tscn` `title_logo.png`'yi çizer, "Ç" üstünde antenleri oynayan böcek; menü, intro, açılış görseli ve paylaşım kartlarında aynı logo.
  - **Açılış:** Krem (#F6EFE4) önyükleme ekranı + logo (Godot yazısı yok). `Intro.tscn`: ilk açılışta ~3 sn (karanlık mutfak, buzdolabı aralığı, ışık, terlik, ŞAPP!, logo, böcek "kaçtım"), sonra 1 sn kısa sürüm, dokununca geçilir, Ayarlar'da kapatılabilir; arka planda `load_threaded_request` + ilerleme çizgisi, logo yerinde kalarak menüye kesintisiz geçiş. Sunucu kipinde (`--room`/`--matchmaker`) ve başsız çalışmada intro atlanır.
  - **Emeği Geçenler:** Baloo 2 (OFL) ve Noto Emoji (OFL) lisans metinleri, Godot (MIT), "ĞÜŞİÖÇ ğüşıöç" harf testi.
  - **Araçlar:** `IconMaker` → `assets/icon/` icon_192, adaptive_fg/bg_432, monochrome_432, splash.png (export ayarlarına bağlı). `StoreShots` → `store_output/` 1024x500 tanıtım + 6 adet 1080x1920 başlıklı görsel (gerçek sahneler SubViewport'ta 720x1280 tasarım boyutunda çizilir). `store_output/` üretilen çıktı olduğu için .gitignore'da.
- **Testler:** İçe aktarma, CI (derleme 0 hata; 11-13A kontrolleri temiz; yeni 13B: intro atlama kuralları, intro türü, ön yükleme yolları, ana sahne, gece saat sınırları, tema + Türkçe harfler, 3 boyutta menü yerleşimi, logo, tüm menü giriş noktaları/sekme içerikleri/mod kartı/profil ve dişli bağlantıları/yeni ayar anahtarları/Emeği Geçenler/Botlar ve Wi-Fi pencereleri). Başsız Botlarla Oyna duman testi: 2 maç + rövanş + menüye dönüş hatasız. Başsız açılışta Intro doğrudan MainMenu'ye geçti; pencereli tam intro ~3.1 sn'de menüye geçti. Ekran görüntüleri: 360x640, 405x900, 390x844, 360x800, 600x800 gündüz ve gece; mod kartı, profil, menü, dört sekme, intro kareleri; IconMaker ve StoreShots çıktıları Read ile incelendi. Kullanıcı verisi testlerden önce yedeklendi, sonra geri yüklendi.
- **Yapılmadı / not:** Faz 9.7 "etkinlik şeridi" projede bulunmadığı için menüye taşınacak bir şey yoktu. Menü arka planı her zaman mutfak; Ayarlar'daki Mekan teması yalnızca oyunu etkiler. Gerçek telefonda titreşim ve geri tuşu denenmedi. Ekran görüntüsü aracı intro yüklemesi sürerken kapanınca çıkışta yarım yükleme uyarıları basıyor (yalnızca araçta, oyunda değil). Mağaza görsellerindeki oyun kareleri test botlarıyla otomatik alındı; yayın öncesi elle seçilmiş karelerle değiştirilebilir.

## #40 — Çevrimiçi Mod Şimdilik Kapalı ("Yakında")
- **Tarih:** 2026-11-20
- **Dosyalar:** `data/GameConfig.gd`, `autoload/Mahalle.gd`, `scenes/ui/MainMenu.gd`, `tools/ci_check.gd`
- **Eklenenler:**
  - Sunucu alınana kadar çevrimiçi özellikler tek ayarla kapatıldı: `GameConfig.ONLINE_ENABLED = false`. Açmak için `true` yapmak, `DEFAULT_SERVER_HOST`'u sunucu adresine çevirmek ve TLS'yi kurmak (`server/SUNUCU_KURULUM.md`) yeterli; Faz 12–13 kodu olduğu gibi duruyor.
  - Kapalıyken `Mahalle` sunucuya hiç bağlanmaz (`activate()` ve arka plan dönüşü etkisiz, derin bağlantı işlenmez).
  - Mod kartında **"Çevrimiçi · Yakında"** soluk kart (dokununca kısa bildirim); Arkadaşlar sekmesinde "Çevrimiçi mod yakında!" sayfası + Botlarla Oyna / Aynı Wi-Fi'de Oyna kısayolları; profil kartında kimlik yerine "Çevrimiçi mod yakında"; profil penceresindeki kimlik satırı, menüdeki ve Ayarlar'daki **Hesabım** gizli.
  - Günlük görev havuzundan çevrimiçi gerektiren "Bir arkadaşını davet et" kapalıyken çıkmaz.
  - Tek Başına, Günün Mutfağı, Botlarla Oyna ve Aynı Wi-Fi (LAN) aynen çalışıyor.
  - Hesap oluşturulmadığı için bu sürümde Play Store'un hesap silme şartı geçerli değil.
- **Testler:** load_all `CHECKED 79 BAD 0`, CI 0 hata (tüm faz kontrolleri + yeni "çevrimiçi kapalı" kontrolleri: 60 günde davet görevi çıkmıyor, Mahalle bağlantı açmıyor). 360x640 ve 390x844 ekran görüntüleri: mod kartı, Arkadaşlar sekmesi, profil. Kullanıcı kaydı testten önce yedeklenip geri yüklendi.
- **Not:** Alan adısız kurulum için denenen "oyuna gömülü sertifika" (sabitleme) yöntemi bu makinede TLS el sıkışmasında hata verdi (mbedtls -0x6c00, istemci durum 4); geri alındı, sunucu alınınca yeniden ele alınacak.

## #41 — Ani Olay Aralığı: Başlangıçtan Başlangıca 45 sn
- **Tarih:** 2026-11-20
- **Dosyalar:** `data/GameConfig.gd` (`EVENT_MIN_END_GAP_SEC`, `NET_VERSION` 8 → 9), `scenes/game/ObstacleTimeline.gd`, `tools/ci_check.gd`
- **Eklenenler:**
  - İki olayın **başlangıçları** arası en az 45 sn; bir olay bittikten sonra en az 15 sn nefes payı. Eski kural (bitişten başlangıca 45 sn) Belediye'nin her 3 seviyedeki gelişiyle birleşince diğer olayları çok seyreltiyordu.
  - 40 seed'de olay sayıları: Annem 7 → 35, Elektrik 7 → 30, Misafir 27 → 95 (Belediye değişmedi).
  - Olay zamanlaması her cihazda seed'den hesaplandığı için `NET_VERSION` artırıldı (eski sürümle LAN'da karışmasın).
- **Testler:** CI 0 hata (başlangıç arası 45 sn ve bitiş sonrası 15 sn kontrolleri, füze evresiyle çakışmama, seviye alt sınırları).

## #42 — Kod ve Arayüz Taraması
- **Tarih:** 2026-11-20
- **Dosyalar:** `scenes/ui/Hud.gd`, `scenes/ui/MainMenu.gd`, `tools/ci_check.gd`
- **Tarama:** load_all (79 betik, 0 hata), tam CI, oyun içi (oyun, elenme, sonuçlar, duraklat) ve menü (ana sayfa, pazar, böcekler, görevler, ayarlar) ekranları 360x640 ve 768x1024'te; çalışma sırasında hata/uyarı yok. Eksik görsel/ses dosyalarının hepsinin kodla çizilen ya da sessiz yedeği var.
- **Düzeltilenler:**
  - Duraklatınca maç başı yetenek kartı duraklatma panelinin altından taşıyordu; artık kapanıyor.
  - Ayarlar'daki "arkadaşların özel sesleri" açıklaması çevrimiçi kapalıyken kapalı modlardan (Özel Oda, Hızlı Oyun) bahsetmiyor.
  - CI: elektrik aralık kontrolü yalnızca tek elektrik olayı varsayıyordu; #41'den sonra parkurda birden çok elektrik olayı olunca yanlış hata veriyordu (oyun kodu doğruydu). "Hesabım" bağlantısı beklentisi `ONLINE_ENABLED`'a bağlandı.
- **Not:** #40 ve #41 kayıtlarında "CI 0 hata" yazıyordu; bu iki CI kontrol hatası o sırada gözden kaçmıştı, burada giderildi.

## #43 — Eksik Görsel Listesi ve Portre Adlandırma Kuralı
- **Tarih:** 2026-11-20
- **Dosyalar:** `PROMPT_GORSELLER.md` (yeni), `scenes/ui/CharacterPortrait.gd`
- **Eklenenler:**
  - `PROMPT_GORSELLER.md`: Gemini / Antigravity için eksik görsellerin tam listesi (dosya adı, klasör, boyut, tarz, örnek istem, ajan talimatı). 19 önden portre (Klasik önden + 9 karakterin önden/sinirli hali), 12 mahalle insanı × üst/alt şerit, füze ve kopan bacak.
  - Portre: `CharacterData`'da `front_path`/`angry_path` boşsa `assets/sprites/char_<id>_front.png` / `_angry.png` aranır; görseller klasöre bırakılınca kod değişmeden kullanılır.
- **Testler:** load_all 79/0, CI 0 hata (portre ekranları dahil).


## #44 — Görseller
- **Tarih:** 2026-11-20
- **Dosyalar:** `assets/sprites/char_klasik_front.png`, `assets/sprites/char_plaza_front.png`, `assets/sprites/char_plaza_angry.png`, `assets/sprites/char_usta_front.png`, `assets/sprites/char_usta_angry.png`, `assets/sprites/char_emlakci_front.png`, `assets/sprites/char_emlakci_angry.png`, `assets/sprites/char_siber_front.png`, `assets/sprites/char_siber_angry.png`, `assets/sprites/char_yurt_front.png`, `assets/sprites/char_yurt_angry.png`, `assets/sprites/char_dayi_front.png`, `assets/sprites/char_dayi_angry.png`, `assets/sprites/char_taraftar_front.png` (ve `.import` dosyaları)
- **Eklenenler:**
  - `PROMPT_GORSELLER.md` Bölüm 1'den `256x256` şeffaf arka planlı 14 önden/sinirli karakter portresi üretilip içe aktarıldı (`Godot --headless --path . --import` hatasız).
- **Not:** Kalan 31 görsel (5 önden portre, 24 mahalle insanı şeridi, `fuze.png`, `bacak.png`) `gemini-3.1-flash-image` kota sınırı (429 RESOURCE_EXHAUSTED) nedeniyle kota yenilenince üretilmek üzere bırakıldı.

## #45 — Görseller
- **Tarih:** 2026-11-20
- **Dosyalar:** `assets/sprites/char_taraftar_angry.png`, `assets/sprites/char_saftirik_front.png`, `assets/sprites/char_saftirik_angry.png`, `assets/sprites/char_deli_front.png`, `assets/sprites/char_deli_angry.png`, `assets/sprites/fuze.png`, `assets/sprites/bacak.png`, `assets/sprites/insanlar/anne_ust.png`, `assets/sprites/insanlar/anne_alt.png`, `assets/sprites/insanlar/amca_ust.png`, `assets/sprites/insanlar/teyze_alt.png`, `assets/sprites/insanlar/kapici_ust.png`, `assets/sprites/insanlar/misafir_ust.png` (ve `.import` dosyaları)
- **Eklenenler:**
  - `PROMPT_GORSELLER.md` Bölüm 1'in kalan 5 önden/sinirli karakter portresi (`256x256`, şeffaf arka planlı PNG) tamamlandı.
  - Bölüm 3'teki `fuze.png` (`96x48`) ve `bacak.png` (`28x28`) üretilip içe aktarıldı.
  - Bölüm 2'deki mahalle insanlarından 6 şerit (`anne_ust`, `anne_alt`, `amca_ust`, `teyze_alt`, `kapici_ust`, `misafir_ust`, `120x600`) üretilip içe aktarıldı (`Godot --headless --path . --import` hatasız).
- **Not:** Kalan 18 mahalle insanı şeridi (`amca_alt`, `teyze_ust`, `kapici_alt`, `misafir_alt`, `ev_arkadasi`, `kurye`, `yonetici`, `bakkal`, `kayinvalide`, `belediye`, `muhtar`) `gemini-3.1-flash-image` kota sınırı (429 RESOURCE_EXHAUSTED, sıfırlanma ~21:29 TRT) nedeniyle bir sonraki kota penceresine bırakıldı.

## #46 — Antigravity görsellerinin kontrolü, üst şerit hizası
- **Tarih:** 2026-11-20
- **Dosyalar:** `scenes/entities/SlipperObstacle.gd`, `PROMPT_GORSELLER.md`
- **Kontrol:** #44–#45'teki 19 portre, `fuze.png`, `bacak.png` ve 6 insan şeridi incelendi: boyutlar doğru (256x256 / 96x48 / 28x28 / 120x600), arka planlar şeffaf, tarz mevcut portrelerle uyumlu.
- **Bulunan hata:** Yeni üst şeritlerde (`*_ust.png`) terlik görselin y≈350–398'inde bitiyor, altı boş; çarpışma kutusu ise görselin tamamını kaplıyordu → oyuncu terliğin ~200 px altında, boşlukta ölüyordu (eski `terlik_ust.png` alta kadar dolu olduğu için daha önce görünmüyordu; tarifteki "alt kısım boş" maddesi yanlıştı).
- **Düzeltme:** `_measure_top_blank()` üst görselin altındaki boşluğu ölçer (önbellekli), özel üst görsel o kadar aşağı kaydırılır; üstte açılan yer kolun en üst piksel satırı tavana kadar uzatılarak doldurulur. Varsayılan terlik ve yedek çizim değişmedi. `PROMPT_GORSELLER.md` üst şerit tarifi düzeltildi.
- **Test:** 5 farklı üst/alt tip çifti çarpışma kutularıyla render edildi (terlikler kutunun alt kenarına oturuyor, alt şeritlerde kafa aralığın alt kenarında); `CiCheck` derleme hatası 0, GameWorld duman testi hatasız.
- **Kalan görseller:** 18 insan şeridi (`amca_alt`, `teyze_ust`, `kapici_alt`, `misafir_alt` ve 7 tipin ikisi de). Görseli olmayan yarılar kodla çizilmiş yedeği kullanıyor (aynı engelde iki tarz yan yana görünebilir).

## #47 — Görseller
- **Tarih:** 2026-11-20
- **Dosyalar:** `assets/sprites/insanlar/amca_alt.png`, `assets/sprites/insanlar/teyze_ust.png`, `assets/sprites/insanlar/kapici_alt.png`, `assets/sprites/insanlar/kurye_ust.png`, `assets/sprites/insanlar/kurye_alt.png`, `assets/sprites/insanlar/yonetici_ust.png`, `assets/sprites/insanlar/kayinvalide_ust.png`, `assets/sprites/insanlar/kayinvalide_alt.png`, `assets/sprites/insanlar/belediye_ust.png`, `assets/sprites/insanlar/belediye_alt.png`, `assets/sprites/insanlar/muhtar_ust.png` (ve `.import` dosyaları)
- **Eklenenler:**
  - `PROMPT_GORSELLER.md` Bölüm 2'deki mahalle insanlarından 11 şerit (`120x600`, şeffaf arka planlı PNG) üretilip Godot ile içe aktarıldı (`Godot --headless --path . --import` hatasız).
- **Not:** Kalan 7 mahalle insanı şeridi (`misafir_alt`, `ev_arkadasi_ust`, `ev_arkadasi_alt`, `yonetici_alt`, `bakkal_ust`, `bakkal_alt`, `muhtar_alt`) `gemini-3.1-flash-image` kota sınırı (`429 RESOURCE_EXHAUSTED`) nedeniyle bir sonraki kota penceresine bırakıldı.

## #48 — Saftirik ikonu, kart üstünden kaydırma, devam geri sayımı, ses listesi
- **Tarih:** 2026-11-20
- **Dosyalar:** `tools/icon_maker.gd`, `assets/icon/*`, `assets/sprites/app_icon.png`, `core/ComicUiHelper.gd`, `scenes/ui/ShopModal.gd`, `scenes/ui/SkillsModal.gd`, `scenes/ui/Lobby.gd`, `scenes/ui/Hud.gd`, `data/GameConfig.gd`, `PROMPT_SESLER.md` (yeni)
- **Eklenenler:**
  - **İkon:** Uygulama ikonu Saftirik Böcek'in önden portresi (`char_saftirik_front.png`, baş + el sallayan kol kırpılır). Eski ikon (192), adaptif ön plan (şeftali daire içinde, güvenli bölgeye kırpılmış), tema ikonu (konturlar saydam, yüz okunuyor) ve `app_icon.png` (512, Windows/iOS) IconMaker ile yeniden üretildi. 48 px'te yüz seçiliyor. Açılış görseli (logo) değişmedi.
  - **Kaydırma:** `ComicUiHelper.enable_touch_scroll()`: kaydırma içeriğindeki STOP Control'ler PASS yapılır (kaydırıcı/yazı kutusu hariç), içerik değişince yeniden uygulanır, `TOUCH_SCROLL_DEADZONE_PX` = 12. `build_modal` (ayarlar, görevler, böcekler, albüm, rehber, arkadaşlar), Pazar listesi, Yetenekler, Lobi karakter/oyuncu listeleri. Parmak deadzone'u aşınca motor buton basışını iptal ediyor.
  - **Devam geri sayımı:** Duraklatmada "Devam Et" → panel kapanır, ağaç duraklı kalır, 3-2-1 (`RESUME_COUNTDOWN_FROM` / `RESUME_COUNTDOWN_STEP_SEC` 0.6), sonra oyun sürer. Sayım sırasında duraklat butonu / Geri tuşu / arka plana alınma sayımı iptal edip menüyü yeniden açar; maç başı sayımının ortasında duraklatıldıysa onun yazısı geri konur. Çok oyunculuda duraklatma yok (değişmedi).
  - `PROMPT_SESLER.md`: Antigravity / AI Studio / Flow için eksik ses listesi — 13 karakter × 3 dokunma repliği (`assets/sounds/chars/<id>/dokun_N.ogg`), 3 sesli replik, 19 efekt, 3 müzik; teslim biçimi, araç önerisi (Gemini TTS, Veo/Flow sesi, Lyria), hazır viral videolardan ses kesmeme kuralı.
- **Testler:** load_all 79/0, CI hata 0 (duman testi dahil). Oyunda duraklat → devam: sayım boyunca `paused=true`, oyuncu kıpırdamıyor, 1.8 sn sonra oyun sürüyor; sayım sırasında yeniden duraklatma sayımı iptal ediyor. Dokunmatik öykünmesiyle (720x1280): modal ve Pazar listesi butonun üstünden sürüklenince 238 px kaydı, buton basılmadı; 4 px titremeli dokunuş butonu bastı. Debug APK alındı.

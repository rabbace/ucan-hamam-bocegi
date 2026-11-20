# Oda Davet Sayfasını GitHub Pages'te Yayınlama

1. GitHub'da yeni bir depo oluşturun (ör. `hamam-bocegi-web`).
2. `web/oda.html` dosyasını deponun köküne yükleyin.
3. `oda.html` içindeki `DOWNLOAD_URL` sabitini APK / Play Store bağlantınızla güncelleyin.
4. **Settings → Pages → Branch: main** seçeneğini açıp kaydedin.
5. Oluşan adresi (`https://kullanici.github.io/hamam-bocegi-web`) `data/GameConfig.gd` içindeki `SHARE_SITE_URL` sabitine yazın.

# Arkadaş Bağlantısı (`arkadas.html`, Faz 12.3)

1. `web/arkadas.html` dosyasını da aynı deponun köküne yükleyin; `DOWNLOAD_URL` ve `PACKAGE_NAME` değerlerini güncelleyin.
2. Oyundaki paylaş butonu `SHARE_SITE_URL/arkadas.html?k=<KİMLİK>` bağlantısını gönderir. Sayfa
   `intent://arkadas/<KİMLİK>#Intent;scheme=ucanbocek;...` ile oyunu açmayı dener.

## Android'de `ucanbocek://` bağlantısının oyunu açması
Godot'nun hazır Android dışa aktarımı özel URI şeması (intent-filter) eklemeye ve gelen bağlantıyı oyuna
iletmeye izin vermez. Gereken iki adım:
1. **Proje → Android Derleme Şablonunu Yükle** ile `android/build/` oluşturun (AAB ön ayarında
   `gradle_build/use_gradle_build=true` zaten açık) ve `android/build/AndroidManifest.xml` içindeki ana
   aktiviteye şunu ekleyin:
   ```xml
   <intent-filter>
       <action android:name="android.intent.action.VIEW" />
       <category android:name="android.intent.category.DEFAULT" />
       <category android:name="android.intent.category.BROWSABLE" />
       <data android:scheme="ucanbocek" android:host="arkadas" />
   </intent-filter>
   ```
2. Gelen `intent.getData()` değerini oyuna veren küçük bir Android eklentisi (singleton adı `UcanBocekDeepLink`,
   yöntem `getPendingLink() -> String`). `autoload/Mahalle.gd` açılışta ve uygulama öne gelince bu tekili
   arar; bağlantı `ucanbocek://arkadas/<KİMLİK>` ise ana menüde "İstek gönderilsin mi?" penceresi açılır.
   Masaüstünde aynı bağlantı komut satırı argümanı olarak verilirse de çalışır.

Eklenti kurulana kadar: oyuncu bağlantıyı ya da kimliği Arkadaşlar → **Arkadaş Ekle** kutusuna yapıştırabilir
(kutu bağlantının içindeki kimliği kendisi ayıklar).

# Hesap Silme Sayfası (`hesap-silme.html`, Faz 12.5)

1. `web/hesap-silme.html` ve güncel `web/gizlilik.html` dosyalarını aynı depoya yükleyin.
2. `hesap-silme.html` içindeki `SILME_UCU` sabitini sunucunuzun alan adıyla (`https://oyun.ornek.com:7701/hesap-sil`) ve
   `{DESTEK_EPOSTA}` yer tutucularını (bu iki dosyada ve `data/GameConfig.gd` → `SUPPORT_EMAIL`) gerçek adresle değiştirin.
3. Play Console → Uygulama içeriği → Veri güvenliği → "Hesap silme" bölümüne `.../hesap-silme.html` bağlantısını yazın.
4. Form düz HTML gönderimidir (JavaScript gerekmez, CORS gerekmez); sunucu yanıtı küçük bir sonuç sayfasıdır.
   Sayfa HTTPS'te olduğu için sunucu ucu da TLS ile çalışmalıdır (bkz. `server/SUNUCU_KURULUM.md`, bölüm 9).

# Sesli Sohbet (Faz 13A)

## Play Console → Veri güvenliği

- **Ses kayıtları / Sesli veya ses kayıtları:** "Toplanan" değil, **"Aktarılan ama saklanmayan"** (geçici işleme)
  olarak işaretleyin. Sesli sohbet sesi cihazda Opus ile sıkıştırılır, sunucu (ya da LAN host) yalnızca odadaki
  oyunculara canlı aktarır; çözmez, diske yazmaz, günlüğe almaz. "Benim Lafım" ses yuvaları da aynı şekilde
  yalnızca odaya aktarılır, sunucuda saklanmaz.
- Amaç: "Uygulama işlevselliği". Paylaşım: yok (üçüncü tarafa gitmez). Veri aktarımda şifreli: yayın sürümünde TLS.
- Kullanıcı isteğe bağlı: evet (Katıl / Sadece Dinle / Hayır; Hızlı Oyun'da hiç yok).
- `web/gizlilik.html` → "Sesli sohbet" bölümü bu bilgiyi oyuncuya anlatır.

## TwoVoip eklentisi (Opus kodlayıcı)

Sesli sohbet, MIT lisanslı [TwoVoip](https://github.com/goatchurchprime/two-voip-godot-4) GDExtension eklentisiyle çalışır
(denenen sürüm: **v6.6.2**, `compatibility_minimum = 4.6`). Eklenti **projeye eklenmedi**: geliştirme
bilgisayarında Windows "Akıllı Uygulama Denetimi" imzasız `libtwovoip.windows.*.dll` dosyasını engelledi
("Error 4551"), bu yüzden gerçek sesle doğrulanamadı. Eklenti yokken oyun hatasız açılır, sesli sohbet
seçenekleri gizlenir (`ClassDB.class_exists("TwovoipOpusEncoder")`).

Kurulum (yayın derlemesini hazırlayan makinede):
1. Sürüm sayfasından `twovoip` zip'ini indirin, `addons/twovoip/` klasörünü projeye kopyalayın. Yalnızca
   `twovoip.gdextension`, `LICENSE` ve `libs/` altındaki Windows, Linux ve Android (arm64, arm32) ikilileri gerekir.
   v6.6.2 zip'inde iOS ikilileri de var ama bu depoya alınmadı; iOS derlemesi yapılacaksa `libs/` altındaki
   iOS dosyalarını ve `twovoip.gdextension` içindeki `ios.*` satırlarını da ekleyin.
2. Godot'u bir kez açıp (`--import`) eklentinin yüklendiğini görün; Ayarlar'da "Sesli Sohbet" bölümü belirir.
3. Windows'ta DLL engelleniyorsa: Akıllı Uygulama Denetimi açık makinede imzasız DLL yüklenemez; derlemeyi
   başka bir makinede yapın ya da kendi imzanızla imzalayın. Güvenlik ayarını kapatmanız gerekmez.
4. İki gerçek telefonla (biri kulaklıksız) Özel Oda'da deneyin: konuşma, Bas-Konuş, susturma, yankı.


# GitHub Pages
`docs/` klasörü GitHub Pages ile yayınlanır (main dalı, /docs). `docs/gizlilik.html`, `web/gizlilik.html` ile aynı tutulmalı; birini değiştirince diğerine kopyala.

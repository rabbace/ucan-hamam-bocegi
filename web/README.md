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

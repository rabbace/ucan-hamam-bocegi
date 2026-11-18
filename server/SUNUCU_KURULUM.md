# Uçan Hamam Böceği — Çevrimiçi Sunucu Kurulum Rehberi

Bu rehber, oyunun çevrimiçi sunucusunu (Eşleştirici + Oda Sunucuları) kendi Linux VPS'inizde çalıştırmak için hazırlanmıştır.

## 1. Linux VPS Kiralama
- Ubuntu 22.04 veya 24.04 çalıştıran en küçük paket (1 vCPU, 1 GB RAM) yeterlidir.

## 2. Sunucu Dosyasını Export Etme ve Yükleme
1. Godot editöründe **Proje → Dışa Aktar → Server** (Linux/X11) ön ayarını kullanarak `hamam_server.x86_64` olarak dışa aktarın.
2. Dosyayı sunucuya yükleyin:
```bash
scp hamam_server.x86_64 root@SUNUCU_IP:/opt/hamam_bocegi/
ssh root@SUNUCU_IP "chmod +x /opt/hamam_bocegi/hamam_server.x86_64"
```

## 3. Güvenlik Duvarını Açma (`ufw`)
```bash
ufw allow 7700/tcp
ufw allow 7801:7850/udp
ufw reload
```

## 4. `systemd` Servisi Olarak Çalıştırma
`/etc/systemd/system/hamam-matchmaker.service` dosyasını oluşturun:
```ini
[Unit]
Description=Ucan Hamam Bocegi Matchmaker
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/hamam_bocegi
ExecStart=/opt/hamam_bocegi/hamam_server.x86_64 --headless -- --matchmaker
Restart=always
RestartSec=3
# Eşleştirici yeniden başlarken açık oda süreçleri ölmesin (varsayılan control-group hepsini öldürür)
KillMode=process

[Install]
WantedBy=multi-user.target
```
Servisi başlatın:
```bash
systemctl daemon-reload
systemctl enable --now hamam-matchmaker
```

> **KillMode=process neden gerekli?** Oda sunucuları eşleştiricinin alt süreçleridir. systemd varsayılanı
> (`KillMode=control-group`) servis yeniden başlatılınca tüm alt süreçleri, yani oynanan maçları da öldürür.
> `KillMode=process` ile yalnızca eşleştirici yeniden başlar; açık odalar 1-16 sn geri çekilmeli olarak
> yeniden bağlanır ve `room_ready` / `room_status` ile kendilerini yeni eşleştiriciye tekrar kaydeder.
> Odalar 60 sn boş kalınca kendini kapatır; 10 sn'den uzun süre durum göndermeyen oda eşleştirici
> tarafından listeden silinir ve süreci sonlandırılır.

## 4.1 Güvenlik Sınırları (GameConfig.gd → "# Ağ güvenliği")
- `room_ready` / `room_status` yalnızca `127.0.0.1`'den kabul edilir; oda portu 7801-7850 aralığında olmalı.
- IP başına dakikada en fazla 2 oda açma (`MM_ROOM_SPAWN_PER_MIN_PER_IP`), 10 oda kodu denemesi
  (`MM_JOIN_CODE_PER_MIN_PER_IP`); toplam en fazla 10 eşzamanlı oda (`MM_MAX_ROOMS`).
- En fazla 64 eşzamanlı TCP bağlantısı, IP başına 4; istemci bağlantısı yanıttan hemen sonra
  ya da 5 sn boşta kalınca kapanır; satır tamponu 4 KB ile sınırlı.
- Oda sunucusu: kayıt (register_player) için 5 sn, ENet zaman aşımı 5-8 sn, eş başına saniyede
  30 RPC (120 üstü atılır). Ağ protokolü değişince `NET_VERSION` artırılır; istemci ve sunucu aynı
  sürümde olmalıdır (eski istemci "Sürüm eski" yanıtı alır).

## 5. Logları İzleme
```bash
journalctl -u hamam-matchmaker -f
```

## 6. Oyunda `SERVER_HOST` Adresini Değiştirme
- `data/GameConfig.gd` içindeki `DEFAULT_SERVER_HOST` sabitini VPS IP'nizle değiştirin **veya** oyunda **Çevrimiçi → Sunucu Adresi Değiştir** butonundan girin.

## 7. Böcek Kimliği ve Mahalle (Faz 12)
Eşleştirici artık kullanıcı kimliklerini ve arkadaş listelerini de tutar.

### Veri dosyası ve yedekler
- Kayıtlar `data/users.json` dosyasındadır (dışa aktarılmış sunucuda çalıştırılabilir dosyanın yanındaki
  `data/` klasörü; editörden çalışırken `server/data/`; istenirse `-- --matchmaker --data-dir=/yol` ile değiştirilir).
- Bellekte tutulur, değişiklik en geç 5 sn içinde diske yazılır (`MM_USERS_FLUSH_SEC`). Yazım güvenlidir:
  önce `users.json.tmp`, sonra asıl dosyanın yerine taşınır. Ana dosya bozulursa açılışta sırasıyla `.tmp`
  ve en yeni günlük yedek denenir.
- Her gün ilk fırsatta `data/users_YYYYMMDD.json` yedeği alınır; son 7 yedek tutulur (`MM_USERS_BACKUP_KEEP`).
  Sunucu diski bozulmasına karşı bu klasörü haftada bir başka yere kopyalamanız önerilir:
  ```bash
  # /etc/cron.weekly/hamam-yedek
  tar czf /root/hamam_users_$(date +%Y%m%d).tgz -C /opt/hamam_bocegi data
  ```
- `data/` klasörü depoya girmez (`.gitignore`). Gizli anahtar ve kurtarma kodu dosyada yalnızca SHA-256 özeti
  olarak durur; sunucu bunları hiçbir zaman loglamaz.
- Kullanıcı sayısı on binleri geçerse JSON dosyası yerine SQLite gibi bir veritabanına geçmek gerekir
  (`server/UserStore.gd` tek giriş noktasıdır; yalnızca o dosya değişir).

### Kalıcı Mahalle bağlantıları (TCP 7700, aynı port)
- İstemci `{"op":"hello", ...}` gönderip kimliği doğrulanınca bağlantı kalıcı oturuma yükselir. Kurallar
  kısa bağlantılardan ayrıdır (`server/MahalleHub.gd`, `GameConfig` → "Faz 12.1–12.3"):
  - boşta kalma 60 sn (istemci 20 sn'de bir ping atar), kimlik başına en fazla 2 bağlantı (yenisi gelince en eskisi kapanır),
  - kimlik başına dakikada 60 mesaj; aşan kimliğin bağlantıları kapanır ve 5 dk bekletilir,
  - IP başına 16, toplam 2000 oturum (`MM_MAX_SESSIONS`),
  - yeni kimlik IP başına saatte 10; kurtarma kodu denemesi IP başına saatte 10, kimlik başına saatte 5;
    kurtarma kodu üretme kimlik başına saatte 5; hatalı kimlik doğrulama IP başına saatte 30.
- Kimliksiz kısa bağlantı sınırı 64'ten 128'e çıkarıldı (`MM_MAX_CONNECTIONS`); IP başına 4 ve 5 sn boşta
  kapanma kuralları kısa bağlantılarda aynen geçerlidir. Satır tamponu her iki türde de 4 KB.
- Oda sunucuları 2 sn'lik `room_status` mesajında odadaki kullanıcı kimliklerini (`uids`), gizliliği ve oda
  sahibinin kimliğini, maç sonunda da `room_result` (kazananın kimliği) gönderir. Galibiyet sayısı yalnızca buradan
  artar. Kimlikler giriş biletinden geldiği için (Faz 12C) doğrulanmıştır.
- Çok sayıda kalıcı bağlantı için Linux'ta dosya tanıtıcı sınırını artırın (systemd servisine `LimitNOFILE=8192`).

## 8. Davet, oda gizliliği ve giriş bileti (Faz 12C)
- Oda açma / katılma artık yalnızca kimliği doğrulanmış Mahalle oturumundan yapılır (`room_quick`, `room_create`,
  `room_join_code`, `join_friend`, `invite_accept`). Eski kısa bağlantı istekleri (`quick_play`, `create_private`,
  `join_code`) reddedilir. `NET_VERSION` 7.
- Eşleştirici izin verince **giriş bileti** üretir: `{kimlik, oda kodu, 60 sn, tek kullanımlık rastgele}` + HMAC-SHA256.
  Oda sunucusu ilk mesajda (`register_player`) imzayı, oda kodunu, süreyi doğrular ve aynı bileti ikinci kez kabul
  etmez; biletsiz / geçersiz bağlantı "Giriş bileti geçersiz" ile kesilir. LAN odalarında bilet yoktur.
- İmza anahtarı oda süreçlerine **ortam değişkeniyle** (`UCAN_BOCEK_TICKET_KEY`, 64 hex karakter) geçer; komut
  satırında görünmez, oda okuduktan sonra ortamdan siler. Verilmezse eşleştirici her açılışta rastgele üretir; bu durumda
  eşleştirici yeniden başlarsa açık odalara yeni bilet geçmez (odalar boşalıp kapanır). Kalıcı anahtar önerilir:
  ```bash
  openssl rand -hex 32   # çıktıyı aşağıya yaz
  # /etc/systemd/system/hamam-matchmaker.service → [Service] altına:
  Environment=UCAN_BOCEK_TICKET_KEY=<64_hex>
  ```
  (Dosyayı `chmod 600` yapın; anahtar loglanmaz.)
- Oda gizliliği: Kodla açık / Sadece arkadaşlarım (varsayılan) / Sadece davetliler. Yetki oda sahibinin arkadaş
  listesine ve davetlere bağlıdır. Davet 10 dk geçerli, kişi başına en fazla 10 bekleyen davet, dakikada 10 davet.
  "Maç bitince otomatik katıl" kaydı 15 dk tutulur.

## 9. TLS (yayın için zorunlu, Faz 12D)
Yayın sürümünde `data/GameConfig.gd` → `USE_TLS = true` olmalıdır (false ise yayın derlemesi açılışta konsola büyük
uyarı yazar). Eşleştirici (7700) ve hesap silme ucu (7701) aynı sertifikayla şifrelenir; oda süreçleri eşleştiriciye
yerelden TLS ile bağlanır. Oyun içi oda trafiği (ENet/UDP) şifresizdir; içinde kişisel bilgi yoktur.
1. **Alan adını VPS'e yönlendirin:** alan adı sağlayıcınızda `A` kaydı → `oyun.ornek.com` = VPS IP (IPv6 varsa `AAAA`).
   `dig +short oyun.ornek.com` VPS IP'sini göstermeli. Oyunda `DEFAULT_SERVER_HOST` (ya da Sunucu adresi) bu **alan adı**
   olmalı; sertifika ada göre doğrulanır, IP ile bağlanılırsa TLS reddeder.
2. **Sertifika alın (Let's Encrypt, certbot):**
   ```bash
   apt install certbot
   ufw allow 80/tcp          # yalnızca doğrulama için
   certbot certonly --standalone -d oyun.ornek.com --agree-tos -m {DESTEK_EPOSTA} --non-interactive
   ```
   Dosyalar: `/etc/letsencrypt/live/oyun.ornek.com/fullchain.pem` ve `privkey.pem`.
3. **Godot sunucusuna yolları verin** (servis satırı):
   ```ini
   ExecStart=/opt/hamam_bocegi/hamam_server.x86_64 --headless -- --matchmaker --tls-cert=/etc/letsencrypt/live/oyun.ornek.com/fullchain.pem --tls-key=/etc/letsencrypt/live/oyun.ornek.com/privkey.pem
   ```
   Yol verilmezse `data/tls/fullchain.pem` ve `data/tls/privkey.pem` aranır. Servis root değilse okuma izni verin
   (`setfacl -m u:hamam:rx /etc/letsencrypt/{live,archive}` ve `privkey` dosyalarına `r`). TLS açıkken sertifika
   yüklenemezse eşleştirici açılmaz (şifresiz çalışmaz).
4. **Otomatik yenileme:** certbot zamanlayıcısı (`systemctl list-timers | grep certbot`) 60 günde bir yeniler. Yeni
   sertifikanın yüklenmesi için yeniden başlatma kancası ekleyin (odalar `KillMode=process` sayesinde ölmez):
   ```bash
   cat > /etc/letsencrypt/renewal-hooks/deploy/hamam.sh <<'EOF'
   #!/bin/sh
   systemctl restart hamam-matchmaker
   EOF
   chmod +x /etc/letsencrypt/renewal-hooks/deploy/hamam.sh
   certbot renew --dry-run
   ```
5. `ufw allow 7701/tcp` (web hesap silme ucu).
- **Yerel test:** `Crypto.generate_self_signed_certificate` ile `CN=localhost` sertifika üretip eşleştiriciyi
  `-- --matchmaker --tls --tls-cert=... --tls-key=...`, istemciyi `-- --tls --tls-trust=<fullchain.pem> --tls-cn=localhost`
  ile çalıştırın. `--tls` argümanı `USE_TLS`'i yerelde açar; `--tls-trust` yalnızca debug derlemede dikkate alınır.

## 10. Engelleme, bildirim, moderasyon, hesap silme (Faz 12D)
- **Engelle:** arkadaşlık ve istekler iki yönde silinir; engellenen kişi istek/davet gönderemez, profilini göremez,
  aynı odaya (kodla açık dahil) giremez, Hızlı Oyun'da aynı odaya düşmez.
- **Bildir (profil kartı):** `reports.log`'a `kaynak=profil` satırı (kimlikler, ad, sebep: uygunsuz isim / taciz / hile /
  diğer); kimlik başına saatte 10.
- **moderation.json:** `{"hide_names": ["7K3MQX9P"]}` — bu kimliklerin adı başkalarına ve oda sunucusunda
  "Böcek #7K3M" görünür. Önce `data/moderation.json`, yoksa `server/moderation.json` okunur; dosya değişince
  60 sn içinde yeniden yüklenir (yeniden başlatma gerekmez).
- **Hız sınırı:** kimlik başına dakikada 60 Mahalle mesajı; aşan kimliğin bağlantıları kapanır, 5 dk bekletilir.
- **Hesap silme:** oyunda Ayarlar → Hesabım → Hesabımı Sil (kimliği yazarak onay) ya da web formu
  (`web/hesap-silme.html` → `POST https://oyun.ornek.com:7701/hesap-sil`, alanlar `id`, `recovery`). Kullanıcı kaydı,
  karşı tarafların arkadaş/istek/engel/ret listeleri, davetler silinir; **günlük yedeklerdeki kopyalar da temizlenir**.
  Kimlik `data/deleted_ids.json` listesine girer ve bir daha verilmez. Web ucu: yalnızca POST, başlık 4 KB, gövde 1 KB,
  5 sn zaman aşımı, 16 eşzamanlı bağlantı, IP başına dakikada 20 istek ve saatte 10 silme denemesi, kimlik başına
  saatte 5; CORS başlığı yok. `hesap-silme.html` içindeki `SILME_UCU` adresini alan adınızla güncelleyin.

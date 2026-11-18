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
- Oda sunucuları 2 sn'lik `room_status` mesajında odadaki kullanıcı kimliklerini (`uids`), maç sonunda da
  `room_result` (kazananın kimliği) gönderir. Galibiyet sayısı yalnızca buradan artar. Kimlik oda sunucusunda
  Faz 12C'deki giriş biletine kadar doğrulanmadığından eşleştirici, kullanıcının kendi Mahalle oturumunun
  bildirdiği oda koduyla oda sunucusunun listesini karşılaştırır; ikisi uyuşmazsa durum/galibiyet sayılmaz.
- Çok sayıda kalıcı bağlantı için Linux'ta dosya tanıtıcı sınırını artırın (systemd servisine `LimitNOFILE=8192`).

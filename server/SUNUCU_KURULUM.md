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

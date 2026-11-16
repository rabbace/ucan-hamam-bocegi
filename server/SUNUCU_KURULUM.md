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

[Install]
WantedBy=multi-user.target
```
Servisi başlatın:
```bash
systemctl daemon-reload
systemctl enable --now hamam-matchmaker
```

## 5. Logları İzleme
```bash
journalctl -u hamam-matchmaker -f
```

## 6. Oyunda `SERVER_HOST` Adresini Değiştirme
- `data/GameConfig.gd` içindeki `DEFAULT_SERVER_HOST` sabitini VPS IP'nizle değiştirin **veya** oyunda **Çevrimiçi → Sunucu Adresi Değiştir** butonundan girin.

# Karakter Parça (Cutout) Hazırlama Rehberi

Her karakter `res://assets/sprites/chars/<char_id>/` klasöründe aşağıdaki PNG parçalarıyla özelleştirilebilir. Dosyalardan biri veya tümü eksikse oyun otomatik olarak tek parça `char_<id>.png` görselini veya pastel yedek şekilleri kullanır.

## Beklenen Dosyalar ve Önerilen Boyutlar

| Dosya | Boyut (px) | Pivot Noktası | Açıklama |
|---|---|---|---|
| `govde.png` | `128x96` | Merkez `(64, 48)` | Böceğin ana gövdesi (uçarken dönmez) |
| `kafa.png` | `64x64` | Boyun bağlantısı `(16, 36)` | Kafa parçası |
| `anten.png` | `48x32` | Kök `(4, 28)` | Sol ve sağ anten (sönümlü yay fiziği ile sallanır) |
| `kanat_on.png` | `84x48` | Omuz `(12, 24)` | Sert dış kanat |
| `kanat_arka.png` | `84x44` | Omuz `(12, 22)` | Yarı saydam zar kanat (hızlı titreşim + motion blur) |
| `kol.png` | `48x32` | Omuz `(8, 12)` | Ön ve arka kol |
| `bacak.png` | `40x40` | Kalça `(20, 6)` | 3 adet görünen bacak |
| `goz.png` | `24x24` | Merkez `(12, 12)` | Göz akı |
| `goz_bebek.png` | `12x12` | Merkez `(6, 6)` | Tehlikeye bakan göz bebeği (±4 px kayar) |
| `agiz_kapali.png` | `28x16` | Merkez `(14, 8)` | Kapalı ağız |
| `agiz_acik.png` | `28x24` | Merkez `(14, 12)` | Konuşma / panik açık ağız |
| `kafa_aksesuar.png` | `64x64` | Merkez `(32, 32)` | Gözlük, kasket vb. |
| `govde_aksesuar.png` | `96x96` | Merkez `(48, 48)` | Önlük, mendil, kravat vb. |

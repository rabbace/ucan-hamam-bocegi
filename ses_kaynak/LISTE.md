# Ses kaynak klasörü

Videoları buraya koy. **Dosya adı = aşağıdaki tablodaki ad** (uzantı fark etmez: .mp4, .webm, .mov, .m4a, .mp3).
Videolar git'e girmez; yalnızca bu dosya ve `kaynaklar.csv` girer.

`kaynaklar.csv` dosyasına her video için bir satır yaz:
- `baslangic` / `bitis`: repliğin videodaki yeri (ör. `0:03.2` ve `0:05.8`). Boş bırakırsan tüm ses alınır, baştaki/sondaki sessizlik kırpılır.
- `link`: videonun adresi (şikâyet gelirse hangi sesi değiştireceğimizi bilmek için).

Arka planda müzik varsa söyle; konuşmayı müzikten ayırmayı ayrıca deneriz (her zaman temiz olmaz).

## Adlar ve oyunda nerede çalacağı

| Dosya adı | Replik / ses | Oyunda |
|---|---|---|
| `duktur_yok_mu` | "Duktur yok mu duktur?" | Elenince |
| `bos_gectik` | "Bu sene de boş geçtik karı." | Elenince |
| `babanin_soyu` | "O babanın soyu oğlum, bizi ilgilendirmez!" | Rakibe sataşma atınca |
| `makara_reels` | "Sabaha kadar Reels kaydırıyoruz…" | Kazanınca |
| `makara_piciz` | "Makarayız ya, piçiz ya!" | Kazanınca |
| `abi_uyuyor_musun` | "Abi uyuyor musun?" | Elektrik Kesildi olayı |
| `lululu` | "Lülülülü…" | Terliği kıl payı atlatınca |
| `kiz_isteme` | "Allah'ın emriyle kızını istiyoruz!…" | Misafir Var olayı |
| `kiz_isteme_cevap` | "Hepsi var, bi' tek karı eksik…" | Misafir olayının sonu |
| `ayran_ictik` | "Ayran içtik ayrı mı düştük?" | Botlu/çok oyunculu maçta yanındaki elenince |
| `aydinlat` | "Kurban olduğum şuraları aydınlat hele." | Karanlık bitip ışık yanınca |
| `soz_alacagim` | "Söz bir gün alacağım…" | Rekoru kıl payı kaçırınca |
| `elimi_tut` | "Elimi tut." | Dirilme penceresi açılınca |
| `kis_kisligini` | "Kış kışlığını yapacak anlaşılan…" | Buz kalıbı / dondurma gelince |
| `teyze_ayyy` | Teyze çığlığı "Ayyy!" | Komşu teyze olayı |
| `kahve_hupletme` | Kahve höpürdetme | Türk kahvesi sataşması |
| `ozur_dilerim` | "Özür dilerim pıttığım" | Sataşma eşyası atınca |

Listede olmayan bir ses eklemek istersen istediğin adı ver ve `kaynaklar.csv`'de `not` sütununa nerede çalmasını istediğini yaz; ben bağlarım.

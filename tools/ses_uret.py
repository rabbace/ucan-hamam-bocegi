#!/usr/bin/env python3
"""
PROMPT_SESLER.md Bölüm 1 ve 2'deki replikleri Gemini TTS API ile üretir,
ffmpeg ile baştaki/sondaki sessizliği kırpar, -16 LUFS / -1 dBFS seviyesine
eşitler ve .ogg (44.1 kHz, mono) olarak hedef klasörlere yazar.

Kullanım:
  set GEMINI_API_KEY=...
  python tools/ses_uret.py
  python tools/ses_uret.py --dry-run
  python tools/ses_uret.py --only diva --overwrite
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
import wave
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOUNDS_DIR = ROOT / "assets" / "sounds"
DEFAULT_MODEL = "gemini-2.5-flash-preview-tts"


@dataclass(frozen=True)
class VoiceItem:
    rel_path: str
    voice: str
    style: str
    text: str


# Bölüm 1: 13 karakter x 3 dokunma repliği = 39 dosya
# Diva kadın sesi (Aoede), diğer 12 karakter birbirinden farklı erkek sesleri.
CHARACTER_ITEMS: list[VoiceItem] = [
    # klasik
    VoiceItem("chars/klasik/dokun_1.ogg", "Puck", "sıradan mahalle delikanlısı, rahat, hafif alaycı", "Efendim?"),
    VoiceItem("chars/klasik/dokun_2.ogg", "Puck", "sıradan mahalle delikanlısı, rahat, hafif alaycı", "Ben buranın eskisiyim."),
    VoiceItem("chars/klasik/dokun_3.ogg", "Puck", "sıradan mahalle delikanlısı, rahat, hafif alaycı", "Işığı kapat, utanıyorum."),
    # diva (kadın)
    VoiceItem("chars/diva/dokun_1.ogg", "Aoede", "kadın, şımarık, ayollu, abartılı", "Ayy dokunma, ojem yeni!"),
    VoiceItem("chars/diva/dokun_2.ogg", "Aoede", "kadın, şımarık, ayollu, abartılı", "Fotoğrafım çekilecekse önce haber verin."),
    VoiceItem("chars/diva/dokun_3.ogg", "Aoede", "kadın, şımarık, ayollu, abartılı", "Bu mutfak bana küçük."),
    # duktur
    VoiceItem("chars/duktur/dokun_1.ogg", "Charon", "kendini doktor sanan, ağır, duktur gibi ciddi ama komik", "Ağzını aç, aaa de."),
    VoiceItem("chars/duktur/dokun_2.ogg", "Charon", "kendini doktor sanan, ağır, duktur gibi ciddi ama komik", "Bu kırıntı çok yağlı."),
    VoiceItem("chars/duktur/dokun_3.ogg", "Charon", "kendini doktor sanan, ağır, duktur gibi ciddi ama komik", "Randevun var mıydı?"),
    # halaybasi
    VoiceItem("chars/halaybasi/dokun_1.ogg", "Fenrir", "coşkulu, düğün havasında, bağırarak", "Hadi kalk, halaya!"),
    VoiceItem("chars/halaybasi/dokun_2.ogg", "Fenrir", "coşkulu, düğün havasında, bağırarak", "Mendil nerde mendil?"),
    VoiceItem("chars/halaybasi/dokun_3.ogg", "Fenrir", "coşkulu, düğün havasında, bağırarak", "Davulcu nerde kaldı?"),
    # plaza
    VoiceItem("chars/plaza/dokun_1.ogg", "Orus", "aceleci beyaz yaka, telefonla konuşur gibi", "Toplantıdayım, sonra dönerim."),
    VoiceItem("chars/plaza/dokun_2.ogg", "Orus", "aceleci beyaz yaka, telefonla konuşur gibi", "Bunu mail atar mısın?"),
    VoiceItem("chars/plaza/dokun_3.ogg", "Orus", "aceleci beyaz yaka, telefonla konuşur gibi", "Cuma'ya yetiştiririz."),
    # usta
    VoiceItem("chars/usta/dokun_1.ogg", "Algenib", "kalın sesli, işini bilen sanayi ustası, ağır", "Abi motor inecek."),
    VoiceItem("chars/usta/dokun_2.ogg", "Algenib", "kalın sesli, işini bilen sanayi ustası, ağır", "Bir kahve koy, bakarız."),
    VoiceItem("chars/usta/dokun_3.ogg", "Algenib", "kalın sesli, işini bilen sanayi ustası, ağır", "Bu orijinal parça değil."),
    # emlakci
    VoiceItem("chars/emlakci/dokun_1.ogg", "Zubenelgenubi", "tatlı dilli satıcı, hızlı konuşan", "Depozito iki kira."),
    VoiceItem("chars/emlakci/dokun_2.ogg", "Zubenelgenubi", "tatlı dilli satıcı, hızlı konuşan", "Metroya yürüme mesafesi."),
    VoiceItem("chars/emlakci/dokun_3.ogg", "Zubenelgenubi", "tatlı dilli satıcı, hızlı konuşan", "Lavabo altı, ferah daire."),
    # siber
    VoiceItem("chars/siber/dokun_1.ogg", "Rasalgethi", "robotik, düz tonlu, hafif dijital", "Sistem başlatıldı."),
    VoiceItem("chars/siber/dokun_2.ogg", "Rasalgethi", "robotik, düz tonlu, hafif dijital", "Şarjım yüzde on beş."),
    VoiceItem("chars/siber/dokun_3.ogg", "Rasalgethi", "robotik, düz tonlu, hafif dijital", "Güncelleme var, yükleyeyim mi?"),
    # yurt
    VoiceItem("chars/yurt/dokun_1.ogg", "Achird", "uykulu öğrenci, esneyerek", "Yemekhane açık mı?"),
    VoiceItem("chars/yurt/dokun_2.ogg", "Achird", "uykulu öğrenci, esneyerek", "Oda arkadaşım yine yok."),
    VoiceItem("chars/yurt/dokun_3.ogg", "Achird", "uykulu öğrenci, esneyerek", "Yoklamaya beni de yaz."),
    # dayi
    VoiceItem("chars/dayi/dokun_1.ogg", "Alnilam", "yaşlı, tok sesli, nasihat eden kahvehane dayısı", "Bir çay söyle evladım."),
    VoiceItem("chars/dayi/dokun_2.ogg", "Alnilam", "yaşlı, tok sesli, nasihat eden kahvehane dayısı", "Bizim zamanımızda terlik yoktu."),
    VoiceItem("chars/dayi/dokun_3.ogg", "Alnilam", "yaşlı, tok sesli, nasihat eden kahvehane dayısı", "Okey dördüncüsü lazım."),
    # taraftar
    VoiceItem("chars/taraftar/dokun_1.ogg", "Schedar", "maç tribününde, bağıran, kısık sesli", "Bu sene bizim sene!"),
    VoiceItem("chars/taraftar/dokun_2.ogg", "Schedar", "maç tribününde, bağıran, kısık sesli", "Hakem kör mü?"),
    VoiceItem("chars/taraftar/dokun_3.ogg", "Schedar", "maç tribününde, bağıran, kısık sesli", "Doksana takarım!"),
    # saftirik
    VoiceItem("chars/saftirik/dokun_1.ogg", "Umbriel", "şaşkın, saf, ağzı açık konuşan", "Abi bu otobüs Taksim'e gider mi?"),
    VoiceItem("chars/saftirik/dokun_2.ogg", "Umbriel", "şaşkın, saf, ağzı açık konuşan", "Akbilim bitmiş ya."),
    VoiceItem("chars/saftirik/dokun_3.ogg", "Umbriel", "şaşkın, saf, ağzı açık konuşan", "Bana mı baktın abi?"),
    # deli
    VoiceItem("chars/deli/dokun_1.ogg", "Sadachbia", "çılgın, kahkahalı, hızlı", "Benim raporum var!"),
    VoiceItem("chars/deli/dokun_2.ogg", "Sadachbia", "çılgın, kahkahalı, hızlı", "Terlikler uçuyor mu?"),
    VoiceItem("chars/deli/dokun_3.ogg", "Sadachbia", "çılgın, kahkahalı, hızlı", "Doktor bey kapıyı aç!"),
]

# Bölüm 2: Oyun içi sesli replikler (3 dosya)
INGAME_ITEMS: list[VoiceItem] = [
    VoiceItem("ozur_dilerim.ogg", "Puck", "alaycı, sırıtarak", "Özür dilerim pıttığım!"),
    VoiceItem("teyze_ayyy.ogg", "Leda", "yaşlı kadın, şaşkın tiz çığlık", "Ayyyy! Böcek!"),
    VoiceItem("kahve_hupletme.ogg", "Alnilam", "sadece yüksek sesle Türk kahvesi höpürdetme sesi ve ardından keyifli bir 'aaah', konuşma yok", "Hüüüp! Aaah!"),
]

ALL_ITEMS: list[VoiceItem] = CHARACTER_ITEMS + INGAME_ITEMS


def build_prompt(item: VoiceItem) -> str:
    return (
        "Bir çizgi film hamam böceği karakterisin. Sıcak, komik, Türk mahalle mizahı. "
        f"Tarz: {item.style}. Doğal perdede (aşırı inceltmeden), abartılı tonlamayla söyle: "
        f"\"{item.text}\""
    )


def call_gemini_tts(api_key: str, model: str, item: VoiceItem) -> bytes:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={api_key}"
    payload = {
        "contents": [{"parts": [{"text": build_prompt(item)}]}],
        "generationConfig": {
            "responseModalities": ["AUDIO"],
            "speechConfig": {
                "voiceConfig": {
                    "prebuiltVoiceConfig": {
                        "voiceName": item.voice,
                    }
                }
            },
        },
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=60) as resp:
        data = json.loads(resp.read().decode("utf-8"))

    for cand in data.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            inline = part.get("inlineData")
            if inline and inline.get("data"):
                return base64.b64decode(inline["data"])
    raise RuntimeError(f"TTS yanıtında ses verisi yok: {data}")


def pcm_to_ogg(pcm_bytes: bytes, out_ogg: Path) -> None:
    out_ogg.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmpdir:
        wav_path = Path(tmpdir) / "raw.wav"
        with wave.open(str(wav_path), "wb") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(24000)
            wf.writeframes(pcm_bytes)

        # Baştaki ve sondaki sessizliği kırp (ortadaki duraklamalara dokunmadan),
        # ardından -16 LUFS / -1 dBFS tepeye normalize edip 44.1 kHz mono .ogg yaz.
        af = (
            "silenceremove=start_periods=1:start_duration=0:start_threshold=-40dB,"
            "areverse,"
            "silenceremove=start_periods=1:start_duration=0:start_threshold=-40dB,"
            "areverse,"
            "loudnorm=I=-16:TP=-1.0:LRA=11"
        )
        cmd = [
            "ffmpeg",
            "-y",
            "-hide_banner",
            "-loglevel",
            "error",
            "-i",
            str(wav_path),
            "-af",
            af,
            "-ac",
            "1",
            "-ar",
            "44100",
            "-c:a",
            "libvorbis",
            "-q:a",
            "5",
            str(out_ogg),
        ]
        subprocess.run(cmd, check=True)


def main() -> int:
    parser = argparse.ArgumentParser(description="Gemini TTS ile oyun repliklerini üretir.")
    parser.add_argument("--dry-run", action="store_true", help="API çağırmadan listeyi yazdır.")
    parser.add_argument("--only", default="", help="Yalnızca yolu bu metni içerenleri üret.")
    parser.add_argument("--overwrite", action="store_true", help="Var olan .ogg dosyalarının üzerine yaz.")
    parser.add_argument("--model", default=DEFAULT_MODEL, help=f"Gemini TTS modeli (varsayılan: {DEFAULT_MODEL})")
    args = parser.parse_args()

    items = [it for it in ALL_ITEMS if not args.only or args.only in it.rel_path]
    if not items:
        print("Eşleşen öğe bulunamadı.", file=sys.stderr)
        return 1

    if args.dry_run:
        for it in items:
            print(f"[DRY] {it.rel_path:32s} voice={it.voice:14s} text={it.text}")
        print(f"Toplam: {len(items)} dosya")
        return 0

    api_key = os.environ.get("GEMINI_API_KEY", "").strip()
    if not api_key:
        print("HATA: GEMINI_API_KEY ortam değişkeni tanımlı değil.", file=sys.stderr)
        return 2

    done = 0
    skipped = 0
    for it in items:
        out_path = SOUNDS_DIR / it.rel_path
        if out_path.exists() and not args.overwrite:
            skipped += 1
            continue
        print(f"[{done + skipped + 1}/{len(items)}] {it.rel_path} ({it.voice})...", flush=True)
        for attempt in range(3):
            try:
                pcm = call_gemini_tts(api_key, args.model, it)
                pcm_to_ogg(pcm, out_path)
                done += 1
                time.sleep(1.5)
                break
            except urllib.error.HTTPError as e:
                body = e.read().decode("utf-8", errors="replace")
                if e.code == 429 and attempt < 2:
                    wait_s = _parse_retry_delay(body)
                    if wait_s is not None and wait_s <= 75 and "PerDay" not in body:
                        print(f"  429 (RPM), {wait_s:.0f}s bekleniyor...", flush=True)
                        time.sleep(wait_s + 2.0)
                        continue
                print(f"HTTP {e.code} ({it.rel_path}): {body}", file=sys.stderr)
                if e.code == 429:
                    print("Kota sınırı (429) nedeniyle durduruldu.", file=sys.stderr)
                    return 3
                return 1
            except Exception as e:
                print(f"HATA ({it.rel_path}): {e}", file=sys.stderr)
                return 1

    print(f"Tamamlandı: {done} üretildi, {skipped} atlandı.")
    return 0


def _parse_retry_delay(body: str) -> float | None:
    try:
        err = json.loads(body).get("error", {})
        for detail in err.get("details", []):
            delay = detail.get("retryDelay")
            if isinstance(delay, str) and delay.endswith("s"):
                return float(delay[:-1])
    except Exception:
        pass
    return None


if __name__ == "__main__":
    raise SystemExit(main())

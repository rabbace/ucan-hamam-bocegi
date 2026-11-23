"""ses_kaynak/ içindeki videolardan oyun seslerini çıkarır.

Her video: kaynaklar.csv'deki aralık (varsa) kesilir, baş/son sessizlik kırpılır, seviye eşitlenir
(loudnorm -16 LUFS, tepe -1 dB), 44.1 kHz mono Ogg Vorbis olarak assets/sounds/<ad>.ogg'ye yazılır.
Kullanım: python tools/ses_ayikla.py            (hepsi)
          python tools/ses_ayikla.py lululu     (yalnızca verilen adlar)
"""
import csv
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "ses_kaynak"
DST = ROOT / "assets" / "sounds"
EXTS = (".mp4", ".webm", ".mov", ".mkv", ".m4a", ".mp3", ".wav", ".ogg", ".aac", ".opus")


def ts(v: str) -> str:
    """'1:03.5' / '63.5' -> ffmpeg süre biçimi."""
    v = v.strip()
    if not v:
        return ""
    parts = v.split(":")
    sec = 0.0
    for p in parts:
        sec = sec * 60 + float(p)
    return f"{sec:.3f}"


def find_video(name: str) -> Path | None:
    for ext in EXTS:
        p = SRC / (name + ext)
        if p.exists():
            return p
    return None


def extract(name: str, start: str, end: str) -> None:
    vid = find_video(name)
    if vid is None:
        print(f"YOK   {name}: ses_kaynak/ içinde dosya bulunamadı")
        return
    out = DST / f"{name}.ogg"
    cmd = ["ffmpeg", "-v", "error", "-y"]
    if ts(start):
        cmd += ["-ss", ts(start)]
    if ts(end):
        cmd += ["-to", ts(end)]
    cmd += ["-i", str(vid), "-vn", "-ac", "1", "-ar", "44100",
            "-af", "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,"
                   "areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.08,areverse,"
                   "loudnorm=I=-16:TP=-1.0:LRA=11",
            "-c:a", "libvorbis", "-q:a", "5", str(out)]
    r = subprocess.run(cmd, capture_output=True, text=True)
    if r.returncode != 0:
        print(f"HATA  {name}: {r.stderr.strip()[:300]}")
        return
    dur = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(out)],
                         capture_output=True, text=True).stdout.strip()
    print(f"OK    {name}.ogg  {float(dur or 0):.2f} sn  <- {vid.name}")


def main() -> None:
    only = set(sys.argv[1:])
    rows: dict[str, tuple[str, str]] = {}
    csv_path = SRC / "kaynaklar.csv"
    if csv_path.exists():
        with open(csv_path, encoding="utf-8-sig", newline="") as f:
            for row in csv.DictReader(f):
                n = (row.get("dosya") or "").strip()
                if n:
                    rows[n] = (row.get("baslangic") or "", row.get("bitis") or "")
    # CSV'de olmasa da klasördeki her video işlenir (tüm ses)
    for p in SRC.iterdir():
        if p.suffix.lower() in EXTS and p.stem not in rows:
            rows[p.stem] = ("", "")
    for name, (s, e) in sorted(rows.items()):
        if only and name not in only:
            continue
        extract(name, s, e)


if __name__ == "__main__":
    main()

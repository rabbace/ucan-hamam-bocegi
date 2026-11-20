"""Play mağaza görselleri: iki oyun ekranı yan yana, başlık + açıklama, öne çıkan böcek ve repliği.

Girdi: store_output/raw_*.png (Godot --path . --resolution 540x960 res://tools/StoreShots.tscn -- raw)
Çıktı: play_teslim/ekran_1..6.png (1080x1920)
Kullanım: python tools/magaza_kompozit.py
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "store_output"
OUT = ROOT / "play_teslim"
SPRITES = ROOT / "assets" / "sprites"
FONT = str(ROOT / "assets" / "fonts" / "Baloo2.ttf")

W, H = 1080, 1920
INK = (36, 22, 14)
CREAM = (246, 239, 228)
BROWN = (107, 90, 78)
WHITE = (255, 253, 248)

SLIDES = [
    {
        "title": "Terliklerden kaç!",
        "sub": "Dokun, kanat çırp, son böcek sen ol!",
        "shots": ["raw_oyun_dayi.png", "raw_botlar_usta.png"],
        "char": "char_dayi_front.png", "name": "Kahvehane Dayısı",
        "line": "Bizim zamanımızda terlik yoktu.",
        "accent": (242, 201, 169),
    },
    {
        "title": "Ani olaylar patlıyor",
        "sub": "Annem geldi, elektrik kesildi, misafir var!",
        "shots": ["raw_annem_usta.png", "raw_elektrik_dayi.png"],
        "char": "char_usta_front.png", "name": "Sanayi Ustası",
        "line": "Abi motor inecek.",
        "accent": (240, 205, 120),
    },
    {
        "title": "13 komik böcek",
        "sub": "Her birinin kendi yeteneği, kendi lafı var.",
        "shots": ["raw_bocekler.png", "raw_yetenek_halaybasi.png"],
        "char": "char_halaybasi_front.png", "name": "Halay Başı Böcek",
        "line": "Hadi kalk, halaya!",
        "accent": (143, 209, 124),
    },
    {
        "title": "Elendin mi? Sinirlen!",
        "sub": "Paylaş, rövanş iste ya da yerinden diril.",
        "shots": ["raw_elenme_duktur.png", "raw_dirilme_deli.png"],
        "char": "char_duktur_angry.png", "name": "Duktur Böcek",
        "line": "Aaaa duktur yok mu duktur!",
        "accent": (232, 170, 170),
    },
    {
        "title": "Arkadaşlarla sataş",
        "sub": "Aynı Wi-Fi'de oda kur ya da botlarla yarış.",
        "shots": ["raw_oda_taraftar.png", "raw_modlar_saftirik.png"],
        "char": "char_taraftar_front.png", "name": "Taraftar Böcek",
        "line": "Bu sene bizim sene!",
        "accent": (160, 190, 220),
    },
    {
        "title": "Her gün yeni görevler",
        "sub": "Seri ödülleri, böcek pazarı ve kostümler.",
        "shots": ["raw_gorevler.png", "raw_pazar.png"],
        "char": "char_diva_front.png", "name": "Diva Böcek",
        "line": "Ayy dokunma, ojem yeni!",
        "accent": (226, 180, 205),
    },
]


def font(size: int, weight: str = "ExtraBold") -> ImageFont.FreeTypeFont:
    f = ImageFont.truetype(FONT, size)
    f.set_variation_by_name(weight)
    return f


def wrap(draw: ImageDraw.ImageDraw, text: str, f: ImageFont.FreeTypeFont, max_w: int) -> list[str]:
    lines: list[str] = []
    cur = ""
    for word in text.split():
        test = (cur + " " + word).strip()
        if draw.textlength(test, font=f) <= max_w:
            cur = test
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def phone(shot: Path, width: int) -> Image.Image:
    """Ekran görüntüsünü yuvarlak köşeli, kalın konturlu telefon çerçevesine koyar."""
    img = Image.open(shot).convert("RGB")
    h = int(width * img.height / img.width)
    img = img.resize((width, h), Image.LANCZOS)
    bez = 14
    radius = 46
    frame = Image.new("RGBA", (width + bez * 2, h + bez * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(frame)
    d.rounded_rectangle([0, 0, frame.width - 1, frame.height - 1], radius=radius + bez, fill=INK)
    mask = Image.new("L", (width, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, width - 1, h - 1], radius=radius, fill=255)
    frame.paste(img, (bez, bez), mask)
    return frame


def shadowed(layer: Image.Image, angle: float) -> tuple[Image.Image, Image.Image]:
    rot = layer.rotate(angle, resample=Image.BICUBIC, expand=True)
    sh = Image.new("RGBA", rot.size, (0, 0, 0, 0))
    sh.putalpha(rot.getchannel("A").point(lambda a: int(a * 0.28)))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    return rot, sh


def bubble(canvas: Image.Image, box: tuple[int, int, int, int], text: str, tail_to: tuple[int, int]) -> None:
    d = ImageDraw.Draw(canvas)
    x0, y0, x1, y1 = box
    # kuyruk (portreye doğru)
    tx, ty = tail_to
    base_y = (y0 + y1) // 2
    d.polygon([(x0 + 30, base_y - 34), (x0 + 30, base_y + 34), (tx, ty)], fill=INK)
    d.rounded_rectangle(box, radius=48, fill=INK)
    d.rounded_rectangle((x0 + 7, y0 + 7, x1 - 7, y1 - 7), radius=42, fill=WHITE)
    d.polygon([(x0 + 38, base_y - 24), (x0 + 38, base_y + 24), (tx + 16, ty - 4)], fill=WHITE)
    f = font(52)
    lines = wrap(d, "“" + text + "”", f, x1 - x0 - 80)
    lh = 60
    ty0 = (y0 + y1) // 2 - len(lines) * lh // 2 - 6
    for i, ln in enumerate(lines):
        lw = d.textlength(ln, font=f)
        d.text(((x0 + x1) / 2 - lw / 2, ty0 + i * lh), ln, font=f, fill=INK)


def make(slide: dict, idx: int) -> None:
    acc = slide["accent"]
    cv = Image.new("RGBA", (W, H), CREAM + (255,))
    d = ImageDraw.Draw(cv)
    # renkli yumuşak bant (telefonların arkası)
    d.rounded_rectangle((-60, 470, W + 60, 1330), radius=120, fill=acc + (255,))
    # nokta deseni
    for yy in range(500, 1310, 54):
        for xx in range(20 + (yy // 54 % 2) * 27, W, 54):
            d.ellipse((xx - 4, yy - 4, xx + 4, yy + 4), fill=tuple(max(c - 22, 0) for c in acc) + (255,))

    # başlık + açıklama
    ft = font(96)
    tw = d.textlength(slide["title"], font=ft)
    d.text((W / 2 - tw / 2, 92), slide["title"], font=ft, fill=INK)
    fs = font(46, "SemiBold")
    for i, ln in enumerate(wrap(d, slide["sub"], fs, W - 160)):
        lw = d.textlength(ln, font=fs)
        d.text((W / 2 - lw / 2, 238 + i * 58), ln, font=fs, fill=BROWN)

    # iki telefon, hafif eğik, biri öne
    pw = 452
    left = phone(RAW / slide["shots"][0], pw)
    right = phone(RAW / slide["shots"][1], pw)
    for img, ang, x, y in [(left, 4.5, 40, 430), (right, -4.5, W - 40 - pw - 60, 470)]:
        rot, sh = shadowed(img, ang)
        cv.alpha_composite(sh, (x + 16, y + 26))
        cv.alpha_composite(rot, (x, y))

    # öne çıkan böcek + konuşma balonu + ad şeridi
    por = Image.open(SPRITES / slide["char"]).convert("RGBA")
    ps = 470
    por = por.resize((ps, ps), Image.LANCZOS)
    px, py = 10, H - ps - 20
    sh = Image.new("RGBA", por.size, (0, 0, 0, 0))
    sh.putalpha(por.getchannel("A").point(lambda a: int(a * 0.25)))
    sh = sh.filter(ImageFilter.GaussianBlur(10))
    cv.alpha_composite(sh, (px + 10, py + 14))
    cv.alpha_composite(por, (px, py))
    bubble(cv, (470, 1430, 1040, 1700), slide["line"], (400, 1600))
    fn = font(40, "Bold")
    nw = int(d.textlength(slide["name"], font=fn))
    nx0 = 1040 - nw - 56
    d.rounded_rectangle((nx0, 1730, 1040, 1806), radius=38, fill=INK)
    d.rounded_rectangle((nx0 + 5, 1735, 1035, 1801), radius=33, fill=acc)
    d.text((nx0 + 28, 1741), slide["name"], font=fn, fill=INK)

    out = OUT / f"ekran_{idx}.png"
    cv.convert("RGB").save(out, optimize=True)
    print("OK", out.name)


def feature() -> None:
    """1024x500 tanıtım: Godot'nun çizdiği mutfak + logo, önüne beş böcek dizilir (saydamlıksız)."""
    bg = Image.open(RAW / "feature_1024x500.png").convert("RGBA")
    grad = Image.new("L", bg.size, 0)
    gd = ImageDraw.Draw(grad)
    for y in range(250, 500):
        gd.line([(0, y), (1024, y)], fill=int((y - 250) / 250 * 110))
    dark = Image.new("RGBA", bg.size, INK + (255,))
    dark.putalpha(grad)
    bg.alpha_composite(dark)
    for cid, sz, x in [("diva", 200, 40), ("dayi", 215, 215), ("saftirik", 265, 392), ("duktur", 215, 600), ("taraftar", 200, 790)]:
        p = Image.open(SPRITES / f"char_{cid}_front.png").convert("RGBA").resize((sz, sz), Image.LANCZOS)
        y = 500 - sz + 18
        sh = Image.new("RGBA", p.size, (0, 0, 0, 0))
        sh.putalpha(p.getchannel("A").point(lambda a: int(a * 0.35)))
        sh = sh.filter(ImageFilter.GaussianBlur(8))
        bg.alpha_composite(sh, (x + 8, y + 6))
        bg.alpha_composite(p, (x, y))
    bg.convert("RGB").save(OUT / "tanitim_1024x500.png")
    print("OK tanitim_1024x500.png")


def main() -> None:
    OUT.mkdir(exist_ok=True)
    for i, s in enumerate(SLIDES, 1):
        make(s, i)
    feature()


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build App Store marketing screenshots from raw captures in store/play/.

Sizes (App Store Connect):
  - 6.9\" iPhone: 1320 × 2868  (primary — iPhone 16 Pro Max)
  - 6.7\" iPhone: 1290 × 2796  (iPhone 15 Pro Max / 14 Pro Max)

Run:
  .venv-store/bin/python store/appstore/generate_framed.py
"""

from __future__ import annotations

from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
RAW = ROOT.parent / "play"
OUT = ROOT / "framed"
FONTS = ROOT.parents[1] / "google_fonts"

# Brand colors (from app_theme.dart)
CREAM = (255, 248, 240)
ORANGE = (232, 93, 4)
ORANGE_SOFT = (244, 140, 6)
ACCENT = (220, 47, 2)
TEXT = (26, 26, 26)
TEXT_MUTED = (107, 107, 107)
BEZEL = (28, 28, 32)

# Apple display sizes → (W, H)
SIZES: dict[str, tuple[int, int]] = {
    "6.9": (1320, 2868),
    "6.7": (1290, 2796),
}

# Journey order → raw file, EN title/sub, AR title/sub
SHOTS: list[tuple[str, str, str, str, str]] = [
    (
        "starter screen.png",
        "Gather your crew",
        "Create a room. Friends join in seconds.",
        "اجمع أصحابك",
        "أنشئ غرفة. أصحابك ينضمون في ثوانٍ.",
    ),
    (
        "type of room.png",
        "Decide your way",
        "Vote, race, or both — you choose.",
        "اختاروا طريقة القرار",
        "تصويت أو سباق أو الاثنين.",
    ),
    (
        "lobby.png",
        "One code. Everyone in.",
        "Share a link or room code instantly.",
        "كود واحد للجميع",
        "شارك الرابط أو كود الغرفة فورًا.",
    ),
    (
        "add resutrants.png",
        "Suggest restaurants",
        "Everyone adds what they’re craving.",
        "اقترحوا مطاعم",
        "كل واحد يضيف اللي نفسه فيه.",
    ),
    (
        "voting.png",
        "Vote as a group",
        "One vote each. Fair and fast.",
        "صوّتوا كمجموعة",
        "صوت واحد لكل شخص. عادل وسريع.",
    ),
    (
        "race1.png",
        "Tied? Race it out",
        "Restaurants race. Winner wins dinner.",
        "تعادل؟ خلّوها سباق",
        "المطاعم تتسابق. الفائز يحل العشاء.",
    ),
    (
        "order.png",
        "Order together",
        "Each person adds items. Host locks in.",
        "اطلبوا مع بعض",
        "كل واحد يضيف طلبه. المضيف يقفل الطلبات.",
    ),
    (
        "total paying.png",
        "Split it fairly",
        "Receipt + fees. Exact share for everyone.",
        "قسّموا بعدل",
        "الإيصال والرسوم. كل واحد يشوف نصيبه.",
    ),
]


def load_font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


def prepare_text(text: str, *, rtl: bool) -> str:
    if not rtl:
        return text
    return get_display(arabic_reshaper.reshape(text))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def draw_background(base: Image.Image, w: int, h: int) -> None:
    px = base.load()
    for y in range(h):
        t = y / (h - 1)
        r = 255
        g = int(248 + (236 - 248) * t)
        b = int(240 + (220 - 240) * t)
        r = min(255, int(r + 12 * t))
        g = max(0, int(g - 8 * t))
        b = max(0, int(b - 18 * t))
        for x in range(w):
            px[x, y] = (r, g, b, 255)

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    for cx, cy, rad, color, alpha in (
        (-80, int(h * 0.08), int(w * 0.30), ORANGE, 38),
        (w + 40, int(h * 0.17), int(w * 0.26), ORANGE_SOFT, 32),
        (int(w * 0.17), h - 120, int(w * 0.24), ACCENT, 22),
        (w - 100, h - int(h * 0.14), int(w * 0.19), ORANGE, 18),
    ):
        blob = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        bd = ImageDraw.Draw(blob)
        bd.ellipse(
            (cx - rad, cy - rad, cx + rad, cy + rad),
            fill=(*color, alpha),
        )
        blob = blob.filter(ImageFilter.GaussianBlur(80))
        overlay = Image.alpha_composite(overlay, blob)

    check = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cd = ImageDraw.Draw(check)
    cell = max(16, w // 60)
    y0, y1 = int(h * 0.017), int(h * 0.025)
    for i, x in enumerate(range(0, w, cell)):
        if i % 2 == 0:
            cd.rectangle((x, y0, x + cell, y1), fill=(26, 26, 26, 28))
        else:
            cd.rectangle((x, y0, x + cell, y1), fill=(255, 255, 255, 40))
    overlay = Image.alpha_composite(overlay, check)
    base.alpha_composite(overlay)


def wrap_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    max_width: int,
) -> list[str]:
    words = text.split()
    lines: list[str] = []
    cur = ""
    for word in words:
        trial = f"{cur} {word}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines or [text]


def compose(
    src_name: str,
    title: str,
    subtitle: str,
    index: int,
    *,
    out_dir: Path,
    brand_line: str,
    canvas_size: tuple[int, int],
    rtl: bool = False,
) -> Path:
    w, h = canvas_size
    # Scale typography from Play Store baseline 1080×1920
    s = w / 1080

    src_path = RAW / src_name
    if not src_path.exists():
        raise FileNotFoundError(src_path)

    canvas = Image.new("RGBA", (w, h), (*CREAM, 255))
    draw_background(canvas, w, h)
    draw = ImageDraw.Draw(canvas)

    if rtl:
        ar_path = Path("/System/Library/Fonts/SFArabicRounded.ttf")
        title_font = ImageFont.truetype(str(ar_path), int(54 * s))
        sub_font = ImageFont.truetype(str(ar_path), int(28 * s))
        brand_font = ImageFont.truetype(str(ar_path), int(22 * s))
    else:
        title_font = load_font("Sora-ExtraBold.ttf", int(54 * s))
        sub_font = load_font("Sora-Regular.ttf", int(28 * s))
        brand_font = load_font("Sora-SemiBold.ttf", int(22 * s))

    max_text_w = w - int(96 * s)
    title_lines_src = wrap_text(draw, title, title_font, max_text_w)
    sub_lines_src = wrap_text(draw, subtitle, sub_font, max_text_w)
    title_lines = [prepare_text(line, rtl=rtl) for line in title_lines_src]
    sub_lines = [prepare_text(line, rtl=rtl) for line in sub_lines_src]
    brand_draw = prepare_text(brand_line, rtl=rtl)

    y = int(110 * (h / 1920))
    line_gap_title = int((70 if rtl else 64) * s)
    line_gap_sub = int((40 if rtl else 36) * s)
    for line in title_lines:
        tw = draw.textlength(line, font=title_font)
        draw.text(((w - tw) / 2, y), line, font=title_font, fill=TEXT)
        y += line_gap_title
    y += int(8 * s)
    for line in sub_lines:
        tw = draw.textlength(line, font=sub_font)
        draw.text(((w - tw) / 2, y), line, font=sub_font, fill=TEXT_MUTED)
        y += line_gap_sub

    caption_bottom = y + int(28 * s)
    brand_space = int(70 * s)
    avail_h = h - caption_bottom - brand_space - int(24 * s)
    avail_w = w - int(120 * s)

    shot = Image.open(src_path).convert("RGBA")
    sw, sh = shot.size
    scale = min(avail_w / sw, avail_h / sh)
    phone_w = int(sw * scale)
    phone_h = int(sh * scale)

    bezel = max(12, int(14 * s))
    radius = max(40, int(52 * s))
    frame_w = phone_w + bezel * 2
    frame_h = phone_h + bezel * 2

    frame_x = (w - frame_w) // 2
    frame_y = caption_bottom + max(0, (avail_h - frame_h) // 2)

    shadow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (
            frame_x + 10,
            frame_y + 18,
            frame_x + frame_w + 10,
            frame_y + frame_h + 18,
        ),
        radius=radius + 4,
        fill=(0, 0, 0, 55),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(22))
    canvas.alpha_composite(shadow)

    bezel_img = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bezel_img)
    bd.rounded_rectangle(
        (0, 0, frame_w - 1, frame_h - 1),
        radius=radius,
        fill=(*BEZEL, 255),
    )
    bd.rounded_rectangle(
        (2, 2, frame_w - 3, frame_h - 3),
        radius=radius - 2,
        outline=(*ORANGE, 90),
        width=2,
    )
    canvas.alpha_composite(bezel_img, (frame_x, frame_y))

    screen = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    screen_mask = rounded_mask((phone_w, phone_h), radius - bezel + 4)
    screen.putalpha(screen_mask)
    canvas.alpha_composite(screen, (frame_x + bezel, frame_y + bezel))

    bw = draw.textlength(brand_draw, font=brand_font)
    draw.text(
        ((w - bw) / 2, h - int(52 * s)),
        brand_draw,
        font=brand_font,
        fill=(*ORANGE, 255),
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    stem = Path(src_name).stem.replace(" ", "_")
    out_path = out_dir / f"{index:02d}_{stem}.png"
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


def sync_deliver(size_key: str, locale: str, paths: list[Path]) -> None:
    """Copy into Fastlane deliver layout if ios/fastlane exists (or create)."""
    # Apple device folder names used by deliver / snapshot
    device_dir = {
        "6.9": "APP_IPHONE_69",
        "6.7": "APP_IPHONE_67",
    }[size_key]

    dest = (
        ROOT.parents[1]
        / "ios"
        / "fastlane"
        / "screenshots"
        / locale
        / device_dir
    )
    dest.mkdir(parents=True, exist_ok=True)
    for old in dest.glob("*.png"):
        old.unlink()
    for path in paths:
        Image.open(path).save(dest / path.name, "PNG", optimize=True)
    print(f"  → synced {len(paths)} → {dest.relative_to(ROOT.parents[1])}")


def main() -> None:
    print(f"Writing App Store screenshots → {OUT}")
    print(f"Raw sources ← {RAW}")

    for size_key, canvas_size in SIZES.items():
        print(f"\n=== iPhone {size_key}\"  {canvas_size[0]}×{canvas_size[1]} ===")
        out_en = OUT / size_key / "en"
        out_ar = OUT / size_key / "ar"
        en_paths: list[Path] = []
        ar_paths: list[Path] = []

        for i, (src, title_en, sub_en, title_ar, sub_ar) in enumerate(SHOTS, start=1):
            en = compose(
                src,
                title_en,
                sub_en,
                i,
                out_dir=out_en,
                brand_line="FoodRush  ·  Decide. Race. Order. Split.",
                canvas_size=canvas_size,
            )
            ar = compose(
                src,
                title_ar,
                sub_ar,
                i,
                out_dir=out_ar,
                brand_line="فودراش  ·  قرّروا. تسابقوا. اطلبوا. قسّموا.",
                canvas_size=canvas_size,
                rtl=True,
            )
            en_paths.append(en)
            ar_paths.append(ar)
            print(f"  ✓ EN {en.name}")
            print(f"  ✓ AR {ar.name}")

        sync_deliver(size_key, "en-US", en_paths)
        sync_deliver(size_key, "ar-SA", ar_paths)

    print("\nDone.")
    print("Upload folders:")
    print(f"  {OUT}/6.9/en/   ← primary App Store Connect (1320×2868)")
    print(f"  {OUT}/6.7/en/   ← alternate (1290×2796)")


if __name__ == "__main__":
    main()

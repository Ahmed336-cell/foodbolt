#!/usr/bin/env python3
"""Build Play Store marketing screenshots from raw captures in store/play/."""

from __future__ import annotations

from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "framed"
FONTS = ROOT.parents[1] / "google_fonts"

# Play Store phone screenshot — 9:16, within 320–3840px
W, H = 1080, 1920

# Brand colors (from app_theme.dart)
CREAM = (255, 248, 240)
ORANGE = (232, 93, 4)
ORANGE_SOFT = (244, 140, 6)
ACCENT = (220, 47, 2)
TEXT = (26, 26, 26)
TEXT_MUTED = (107, 107, 107)
WHITE = (255, 255, 255)
BEZEL = (28, 28, 32)

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
        "المطاعم تتسابق. الفائز هو العشاء.",
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
    path = FONTS / name
    return ImageFont.truetype(str(path), size)


def prepare_text(text: str, *, rtl: bool) -> str:
    """Shape Arabic + apply bidi so Pillow draws glyphs correctly."""
    if not rtl:
        return text
    return get_display(arabic_reshaper.reshape(text))


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius=radius, fill=255)
    return mask


def draw_background(base: Image.Image) -> None:
    """Warm cream → soft peach gradient with soft brand orbs."""
    px = base.load()
    for y in range(H):
        t = y / (H - 1)
        # cream → light peach
        r = int(255 + (255 - 255) * t)
        g = int(248 + (236 - 248) * t)
        b = int(240 + (220 - 240) * t)
        # slight orange wash toward bottom
        r = min(255, int(r + 12 * t))
        g = max(0, int(g - 8 * t))
        b = max(0, int(b - 18 * t))
        for x in range(W):
            px[x, y] = (r, g, b, 255)

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)

    # Soft orbs
    for cx, cy, rad, color, alpha in (
        (-80, 220, 320, ORANGE, 38),
        (W + 40, 480, 280, ORANGE_SOFT, 32),
        (180, H - 120, 260, ACCENT, 22),
        (W - 100, H - 400, 200, ORANGE, 18),
    ):
        blob = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        bd = ImageDraw.Draw(blob)
        bd.ellipse(
            (cx - rad, cy - rad, cx + rad, cy + rad),
            fill=(*color, alpha),
        )
        blob = blob.filter(ImageFilter.GaussianBlur(80))
        overlay = Image.alpha_composite(overlay, blob)

    # Subtle checkered accent strip (race vibe) near top caption area
    check = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(check)
    cell = 18
    y0, y1 = 48, 72
    for i, x in enumerate(range(0, W, cell)):
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
    for w in words:
        trial = f"{cur} {w}".strip()
        if draw.textlength(trial, font=font) <= max_width:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
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
    rtl: bool = False,
) -> Path:
    src_path = ROOT / src_name
    if not src_path.exists():
        raise FileNotFoundError(src_path)

    canvas = Image.new("RGBA", (W, H), (*CREAM, 255))
    draw_background(canvas)
    draw = ImageDraw.Draw(canvas)

    # Arabic: system SF Arabic; EN: app Sora
    if rtl:
        ar_path = Path("/System/Library/Fonts/SFArabicRounded.ttf")
        title_font = ImageFont.truetype(str(ar_path), 54)
        sub_font = ImageFont.truetype(str(ar_path), 28)
        brand_font = ImageFont.truetype(str(ar_path), 22)
    else:
        title_font = load_font("Sora-ExtraBold.ttf", 54)
        sub_font = load_font("Sora-Regular.ttf", 28)
        brand_font = load_font("Sora-SemiBold.ttf", 22)

    # Caption block — wrap logical text first, then reshape each line for RTL.
    max_text_w = W - 96
    # Measure with shaped text approx: use original for wrap of short EN;
    # for AR, wrap on unshaped then shape lines (titles are short).
    title_lines_src = wrap_text(draw, title, title_font, max_text_w)
    sub_lines_src = wrap_text(draw, subtitle, sub_font, max_text_w)
    title_lines = [prepare_text(line, rtl=rtl) for line in title_lines_src]
    sub_lines = [prepare_text(line, rtl=rtl) for line in sub_lines_src]
    brand_draw = prepare_text(brand_line, rtl=rtl)

    y = 110
    line_gap_title = 70 if rtl else 64
    line_gap_sub = 40 if rtl else 36
    for line in title_lines:
        tw = draw.textlength(line, font=title_font)
        draw.text(((W - tw) / 2, y), line, font=title_font, fill=TEXT)
        y += line_gap_title
    y += 8
    for line in sub_lines:
        tw = draw.textlength(line, font=sub_font)
        draw.text(((W - tw) / 2, y), line, font=sub_font, fill=TEXT_MUTED)
        y += line_gap_sub

    # Phone frame geometry
    caption_bottom = y + 28
    brand_space = 70
    avail_h = H - caption_bottom - brand_space - 24
    avail_w = W - 120

    # Source aspect ~1170x2532
    shot = Image.open(src_path).convert("RGBA")
    sw, sh = shot.size
    scale = min(avail_w / sw, avail_h / sh)
    phone_w = int(sw * scale)
    phone_h = int(sh * scale)

    bezel = 14
    radius = 52
    frame_w = phone_w + bezel * 2
    frame_h = phone_h + bezel * 2

    frame_x = (W - frame_w) // 2
    frame_y = caption_bottom + max(0, (avail_h - frame_h) // 2)

    # Drop shadow
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
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

    # Bezel
    bezel_img = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(bezel_img)
    bd.rounded_rectangle(
        (0, 0, frame_w - 1, frame_h - 1),
        radius=radius,
        fill=(*BEZEL, 255),
    )
    # subtle orange rim
    bd.rounded_rectangle(
        (2, 2, frame_w - 3, frame_h - 3),
        radius=radius - 2,
        outline=(*ORANGE, 90),
        width=2,
    )
    canvas.alpha_composite(bezel_img, (frame_x, frame_y))

    # Screen content
    screen = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    screen_mask = rounded_mask((phone_w, phone_h), radius - bezel + 4)
    screen.putalpha(screen_mask)
    canvas.alpha_composite(screen, (frame_x + bezel, frame_y + bezel))

    # Brand footer
    bw = draw.textlength(brand_draw, font=brand_font)
    draw.text(
        ((W - bw) / 2, H - 52),
        brand_draw,
        font=brand_font,
        fill=(*ORANGE, 255),
    )

    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f"{index:02d}_{Path(src_name).stem.replace(' ', '_')}.png"
    # Play Store wants RGB PNG (no alpha required)
    canvas.convert("RGB").save(out_path, "PNG", optimize=True)
    return out_path


def sync_to_fastlane(locale: str, paths: list[Path]) -> None:
    dest = (
        ROOT.parents[1]
        / "android"
        / "fastlane"
        / "metadata"
        / "android"
        / locale
        / "images"
        / "phoneScreenshots"
    )
    dest.mkdir(parents=True, exist_ok=True)
    for old in dest.glob("*.png"):
        old.unlink()
    for path in paths:
        Image.open(path).save(dest / path.name, "PNG", optimize=True)
    print(f"  → synced {len(paths)} → {dest.relative_to(ROOT.parents[1])}")


def main() -> None:
    out_en = OUT / "en"
    out_ar = OUT / "ar"
    print(f"Writing framed screenshots → {OUT}")

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
        )
        ar = compose(
            src,
            title_ar,
            sub_ar,
            i,
            out_dir=out_ar,
            brand_line="فودراش  ·  قرّروا. تسابقوا. اطلبوا. قسّموا.",
            rtl=True,
        )
        en_paths.append(en)
        ar_paths.append(ar)
        print(f"  ✓ EN {en.name}")
        print(f"  ✓ AR {ar.name}")

    sync_to_fastlane("en-US", en_paths)
    sync_to_fastlane("ar", ar_paths)
    print("Done.")


if __name__ == "__main__":
    main()

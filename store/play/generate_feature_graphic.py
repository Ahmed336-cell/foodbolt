#!/usr/bin/env python3
"""Generate Play Store feature graphic (1024×500)."""

from __future__ import annotations

from pathlib import Path

import arabic_reshaper
from bidi.algorithm import get_display
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent
ASSETS = ROOT.parents[1] / "assets" / "images"
FONTS = ROOT.parents[1] / "google_fonts"
W, H = 1024, 500

ORANGE = (232, 93, 4)
ORANGE_SOFT = (244, 140, 6)
CREAM = (255, 248, 240)
ACCENT = (220, 47, 2)
NAVY = (20, 24, 48)
WHITE = (255, 255, 255)


def font(name: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(FONTS / name), size)


def ar(text: str) -> str:
    return get_display(arabic_reshaper.reshape(text))


def gradient_bg() -> Image.Image:
    img = Image.new("RGBA", (W, H), (*CREAM, 255))
    px = img.load()
    for y in range(H):
        ty = y / (H - 1)
        for x in range(W):
            tx = x / (W - 1)
            # Warm orange left → soft cream right (hero side)
            r = int(230 + (255 - 230) * tx)
            g = int(88 + (242 - 88) * tx)
            b = int(10 + (228 - 10) * tx)
            # slight vertical darken at bottom
            r = max(0, min(255, int(r - 18 * ty * (1 - tx))))
            g = max(0, min(255, int(g - 12 * ty * (1 - tx))))
            b = max(0, min(255, int(b - 6 * ty * (1 - tx))))
            px[x, y] = (r, g, b, 255)

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for cx, cy, rad, color, a in (
        (80, 60, 160, WHITE, 50),
        (420, 480, 200, ACCENT, 30),
        (980, 40, 180, ORANGE_SOFT, 40),
        (200, 400, 140, NAVY, 25),
    ):
        blob = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(blob).ellipse(
            (cx - rad, cy - rad, cx + rad, cy + rad),
            fill=(*color, a),
        )
        overlay = Image.alpha_composite(
            overlay, blob.filter(ImageFilter.GaussianBlur(48))
        )
    img = Image.alpha_composite(img, overlay)

    # Checkered strip
    check = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cd = ImageDraw.Draw(check)
    cell = 14
    y0 = H - 24
    for i, x in enumerate(range(0, W, cell)):
        fill = (255, 255, 255, 220) if i % 2 == 0 else (26, 26, 32, 220)
        cd.rectangle((x, y0, x + cell, H), fill=fill)
    cd.rectangle((0, y0 - 3, W, y0), fill=(*ORANGE, 220))
    return Image.alpha_composite(img, check)


def rounded(im: Image.Image, radius: int) -> Image.Image:
    im = im.convert("RGBA")
    mask = Image.new("L", im.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, im.size[0] - 1, im.size[1] - 1), radius=radius, fill=255
    )
    out = im.copy()
    out.putalpha(mask)
    return out


def place_shadow(
    canvas: Image.Image,
    box: tuple[int, int, int, int],
    radius: int,
    blur: int = 16,
    offset: tuple[int, int] = (0, 6),
) -> None:
    x0, y0, x1, y1 = box
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        (x0 + offset[0], y0 + offset[1], x1 + offset[0], y1 + offset[1]),
        radius=radius,
        fill=(0, 0, 0, 65),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(blur)))


def compose(*, rtl: bool = False) -> Image.Image:
    canvas = gradient_bg()
    draw = ImageDraw.Draw(canvas)

    # Mini checkered flag top-left
    cell = 11
    for i in range(6):
        for j in range(2):
            fill = WHITE if (i + j) % 2 == 0 else NAVY
            draw.rectangle(
                (
                    40 + i * cell,
                    36 + j * cell,
                    40 + (i + 1) * cell,
                    36 + (j + 1) * cell,
                ),
                fill=(*fill, 230),
            )

    # --- Left copy block ---
    if rtl:
        ar_path = Path("/System/Library/Fonts/SFArabicRounded.ttf")
        title_f = ImageFont.truetype(str(ar_path), 52)
        sub_f = ImageFont.truetype(str(ar_path), 26)
        chip_f = ImageFont.truetype(str(ar_path), 18)
        title = ar("فودراش")
        sub = ar("قرّروا. تسابقوا. اطلبوا. قسّموا.")
        chips = [ar("غرفة"), ar("تصويت"), ar("سباق"), ar("تقسيم")]
    else:
        title_f = font("Sora-ExtraBold.ttf", 52)
        sub_f = font("Sora-SemiBold.ttf", 24)
        chip_f = font("Sora-SemiBold.ttf", 17)
        title = "FoodRush"
        sub = "Decide. Race. Order. Split."
        chips = ["Room", "Vote", "Race", "Split"]

    # Logo badge
    logo = Image.open(ASSETS / "logo.png").convert("RGBA")
    logo_size = 168
    logo = rounded(logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS), 36)
    lx, ly = 48, 90
    place_shadow(canvas, (lx, ly, lx + logo_size, ly + logo_size), radius=36)
    ring = Image.new("RGBA", (logo_size + 10, logo_size + 10), (0, 0, 0, 0))
    ImageDraw.Draw(ring).rounded_rectangle(
        (0, 0, logo_size + 9, logo_size + 9),
        radius=40,
        fill=(*CREAM, 255),
    )
    canvas.alpha_composite(ring, (lx - 5, ly - 5))
    canvas.alpha_composite(logo, (lx, ly))

    # Title + tagline to the right of logo
    tx = lx + logo_size + 28
    ty = ly + 18
    # Soft plate behind text for contrast
    tw = max(draw.textlength(title, font=title_f), draw.textlength(sub, font=sub_f))
    plate_w = int(tw + 40)
    plate_h = 118
    plate = Image.new("RGBA", (plate_w, plate_h), (0, 0, 0, 0))
    ImageDraw.Draw(plate).rounded_rectangle(
        (0, 0, plate_w - 1, plate_h - 1),
        radius=18,
        fill=(255, 248, 240, 210),
    )
    canvas.alpha_composite(plate, (tx - 14, ty - 10))
    draw = ImageDraw.Draw(canvas)
    draw.text((tx, ty), title, font=title_f, fill=NAVY)
    draw.text((tx, ty + 62), sub, font=sub_f, fill=ORANGE)

    # Chips under logo+title row
    cx = lx
    cy = ly + logo_size + 28
    for label in chips:
        lw = int(draw.textlength(label, font=chip_f))
        cw, ch = lw + 26, 32
        chip = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        ImageDraw.Draw(chip).rounded_rectangle(
            (0, 0, cw - 1, ch - 1),
            radius=16,
            fill=(26, 26, 32, 205),
        )
        canvas.alpha_composite(chip, (cx, cy))
        ImageDraw.Draw(canvas).text((cx + 13, cy + 5), label, font=chip_f, fill=WHITE)
        cx += cw + 8

    # --- Right hero: friends dinner ---
    hero = Image.open(ASSETS / "welcome_friends.jpg").convert("RGBA")
    hero_h = 360
    scale = hero_h / hero.size[1]
    hero_w = int(hero.size[0] * scale)
    hero = rounded(hero.resize((hero_w, hero_h), Image.Resampling.LANCZOS), 26)
    pad = 8
    card_w, card_h = hero_w + pad * 2, hero_h + pad * 2
    hx = W - card_w - 40
    hy = (H - card_h) // 2 - 8
    place_shadow(canvas, (hx, hy, hx + card_w, hy + card_h), radius=30, blur=18)
    card = Image.new("RGBA", (card_w, card_h), (0, 0, 0, 0))
    ImageDraw.Draw(card).rounded_rectangle(
        (0, 0, card_w - 1, card_h - 1),
        radius=30,
        fill=(*CREAM, 255),
    )
    canvas.alpha_composite(card, (hx, hy))
    canvas.alpha_composite(hero, (hx + pad, hy + pad))

    return canvas.convert("RGB")


def main() -> None:
    out_en = ROOT / "feature-graphic.png"
    out_ar = ROOT / "feature-graphic-ar.png"
    compose(rtl=False).save(out_en, "PNG", optimize=True)
    compose(rtl=True).save(out_ar, "PNG", optimize=True)
    print(f"✓ {out_en.name} ({W}×{H})")
    print(f"✓ {out_ar.name} ({W}×{H})")

    for locale, src in (("en-US", out_en), ("ar", out_ar)):
        dest = (
            ROOT.parents[1]
            / "android"
            / "fastlane"
            / "metadata"
            / "android"
            / locale
            / "images"
            / "featureGraphic.png"
        )
        dest.parent.mkdir(parents=True, exist_ok=True)
        Image.open(src).save(dest, "PNG", optimize=True)
        print(f"  → {dest.relative_to(ROOT.parents[1])}")


if __name__ == "__main__":
    main()

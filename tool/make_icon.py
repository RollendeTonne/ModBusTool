"""Generates the app icon sources in assets/icon/ (1024 px): a register
table with one highlighted row on the app's seed colour.

Run: uvx --with pillow python tool/make_icon.py
then: dart run flutter_launcher_icons
"""
import math

from PIL import Image, ImageDraw

S = 1024
SEED = (11, 110, 153)       # 0xFF0B6E99, theme seed colour
DARK = (6, 64, 92)          # 0xFF06405C, adaptive icon background
ROW = (236, 244, 248)
HIGHLIGHT = (255, 205, 80)  # "changed" highlight
ADDRESS = (150, 200, 222)


def draw_rows(d, left, top, scale):
    """Four register rows (address cell + value bar), second highlighted."""
    def r(x0, y0, x1, y1, radius, fill):
        d.rounded_rectangle(
            (left + x0 * scale, top + y0 * scale, left + x1 * scale, top + y1 * scale),
            radius=radius * scale, fill=fill)
    height, gap = 100, 46
    for i in range(4):
        y = i * (height + gap)
        r(0, y, 130, y + height, 26, ADDRESS)
        r(160, y, 624, y + height, 26, HIGHLIGHT if i == 1 else ROW)
        for k in range(4):
            x = 200 + k * 104
            r(x, y + 34, x + 70, y + height - 34, 12,
              (120, 80, 0) if i == 1 else SEED)

ROWS_W, ROWS_H = 624, 4 * 100 + 3 * 46

# Full icon: rounded square with a subtle vertical gradient.
img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
mask = Image.new("L", (S, S), 0)
ImageDraw.Draw(mask).rounded_rectangle((40, 40, S - 40, S - 40), radius=210, fill=255)
grad = Image.new("RGBA", (S, S))
gd = ImageDraw.Draw(grad)
for y in range(S):
    t = y / S
    gd.line([(0, y), (S, y)],
            fill=tuple(int(SEED[i] * (1 - t) + DARK[i] * t) for i in range(3)) + (255,))
img.paste(grad, (0, 0), mask)
draw_rows(ImageDraw.Draw(img), (S - ROWS_W) // 2, (S - ROWS_H) // 2, 1)
img.save("assets/icon/app_icon.png")

# Opaque variant for iOS (no transparency allowed).
flat = Image.new("RGB", (S, S), DARK)
flat.paste(img, (0, 0), img)
flat.save("assets/icon/app_icon_opaque.png")

# Android adaptive foreground: rows only. The safe zone is a circle of 66 %
# diameter, so the table's diagonal must fit inside it.
fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
scale = 0.64 * S / math.hypot(ROWS_W, ROWS_H)
draw_rows(ImageDraw.Draw(fg), (S - ROWS_W * scale) / 2, (S - ROWS_H * scale) / 2, scale)
fg.save("assets/icon/app_icon_foreground.png")
print("ok")

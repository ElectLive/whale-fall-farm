#!/usr/bin/env python3
"""Procedural pixel-art generator for Whale Fall Farm.

Everything in assets/generated/ is produced by this script: tiles, characters,
crops, UI icons and the title illustration. No external art is used.

    python tools/gen_art.py

Requires Pillow. All sprites are tiny (16x16 / 16x24) and upscaled by the game
with nearest-neighbour filtering.
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "generated"
PREVIEW = ROOT / "docs" / "art_preview.png"

# ---------------------------------------------------------------- palette
C = {
    "ink": (26, 20, 32, 255),
    "ink2": (44, 36, 54, 255),
    "grass0": (61, 110, 55, 255),
    "grass1": (77, 133, 63, 255),
    "grass2": (95, 156, 72, 255),
    "grass3": (48, 92, 48, 255),
    "sand0": (198, 176, 122, 255),
    "sand1": (176, 152, 102, 255),
    "sand2": (216, 198, 148, 255),
    "soil0": (92, 62, 43, 255),
    "soil1": (114, 79, 54, 255),
    "soil2": (73, 47, 34, 255),
    "wet0": (66, 44, 34, 255),
    "wet1": (82, 57, 43, 255),
    "wood0": (94, 60, 38, 255),
    "wood1": (139, 95, 58, 255),
    "wood2": (176, 128, 80, 255),
    "skin": (242, 194, 150, 255),
    "skin2": (211, 154, 116, 255),
    "hair": (58, 108, 160, 255),
    "hair2": (40, 78, 124, 255),
    "straw": (233, 197, 106, 255),
    "straw2": (196, 154, 76, 255),
    "shirt": (226, 212, 178, 255),
    "overall": (64, 124, 128, 255),
    "overall2": (45, 92, 100, 255),
    "boot": (69, 48, 40, 255),
    "red": (214, 76, 84, 255),
    "red2": (168, 48, 62, 255),
    "orange": (232, 137, 58, 255),
    "orange2": (190, 96, 38, 255),
    "green": (95, 174, 78, 255),
    "green2": (58, 122, 58, 255),
    "cyan": (126, 227, 212, 255),
    "cyan2": (72, 176, 172, 255),
    "gold": (242, 201, 76, 255),
    "gold2": (196, 148, 44, 255),
    "purple": (127, 91, 214, 255),
    "purple2": (86, 58, 156, 255),
    "purple3": (167, 134, 238, 255),
    "crow": (43, 42, 58, 255),
    "crow2": (26, 26, 38, 255),
    "vine": (106, 143, 58, 255),
    "vine2": (70, 102, 42, 255),
    "white": (245, 243, 232, 255),
    "panel": (18, 27, 46, 238),
    "panel2": (28, 42, 66, 250),
    "border": (76, 112, 146, 255),
    "border2": (128, 172, 200, 255),
}


def rgba(name: str) -> tuple[int, int, int, int]:
    return C[name]


def new(w: int, h: int) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    return im, ImageDraw.Draw(im)


def save(im: Image.Image, *parts: str) -> None:
    path = OUT.joinpath(*parts)
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path)


def px(d: ImageDraw.ImageDraw, x: int, y: int, col) -> None:
    if isinstance(col, str):
        col = rgba(col)
    d.point((x, y), fill=col)


def box(d: ImageDraw.ImageDraw, x0: int, y0: int, x1: int, y1: int, col) -> None:
    if isinstance(col, str):
        col = rgba(col)
    d.rectangle((x0, y0, x1, y1), fill=col)


def disc(d: ImageDraw.ImageDraw, cx: float, cy: float, rx: float, ry: float, col) -> None:
    if isinstance(col, str):
        col = rgba(col)
    d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=col)


# ---------------------------------------------------------------- tiles
def grass_tile(variant: int) -> Image.Image:
    rnd = random.Random(1000 + variant)
    im, d = new(16, 16)
    for y in range(16):
        for x in range(16):
            r = rnd.random()
            col = C["grass1"]
            if r < 0.10:
                col = C["grass0"]
            elif r < 0.16:
                col = C["grass2"]
            elif r < 0.20:
                col = C["grass3"]
            px(d, x, y, col)
    # grass blades
    for _ in range(7):
        x = rnd.randrange(1, 15)
        y = rnd.randrange(2, 15)
        px(d, x, y, C["grass2"])
        px(d, x, y - 1, C["grass2"])
        px(d, x + (1 if rnd.random() < 0.5 else -1), y - 1, C["grass0"])
    # tiny flowers on some variants
    if variant >= 2:
        for _ in range(variant - 1):
            x = rnd.randrange(2, 14)
            y = rnd.randrange(2, 14)
            for ox, oy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                px(d, x + ox, y + oy, C["white"])
            px(d, x, y, C["gold"])
    return im


def soil_tile(wet: bool = False, tilled: bool = True) -> Image.Image:
    rnd = random.Random(3000 + (1 if wet else 0))
    im, d = new(16, 16)
    base = C["wet0"] if wet else C["soil0"]
    alt = C["wet1"] if wet else C["soil1"]
    dark = C["soil2"]
    for y in range(16):
        for x in range(16):
            r = rnd.random()
            col = base
            if r < 0.18:
                col = alt
            elif r < 0.30:
                col = dark
            px(d, x, y, col)
    if tilled:
        for y in (3, 8, 13):
            for x in range(1, 15):
                if rnd.random() < 0.85:
                    px(d, x, y, alt if not wet else (52, 36, 29, 255))
            for x in range(1, 15):
                if rnd.random() < 0.4:
                    px(d, x, y + 1, dark)
    if wet:
        for _ in range(6):
            x = rnd.randrange(1, 15)
            y = rnd.randrange(1, 15)
            px(d, x, y, (122, 150, 160, 220))
    # darker border so plots read as separate
    for x in range(16):
        px(d, x, 15, (52, 36, 28, 255))
    for y in range(16):
        px(d, 15, y, (52, 36, 28, 255))
    return im


def sand_tile() -> Image.Image:
    rnd = random.Random(4000)
    im, d = new(16, 16)
    for y in range(16):
        for x in range(16):
            r = rnd.random()
            col = C["sand1"] if r < 0.25 else C["sand0"]
            if r > 0.93:
                col = C["sand2"]
            px(d, x, y, col)
    for _ in range(3):
        px(d, rnd.randrange(16), rnd.randrange(16), (140, 118, 78, 255))
    return im


def path_tile(variant: int) -> Image.Image:
    rnd = random.Random(5000 + variant)
    im, d = new(16, 16)
    box(d, 0, 0, 15, 15, (150, 132, 96, 255))
    for _ in range(9):
        x = rnd.randrange(0, 13)
        y = rnd.randrange(0, 13)
        w = rnd.randrange(3, 5)
        h = rnd.randrange(2, 4)
        box(d, x, y, x + w, y + h, (176, 158, 118, 255))
        box(d, x, y + h, x + w, y + h, (118, 102, 74, 255))
    return im


def fence_h() -> Image.Image:
    im, d = new(16, 16)
    box(d, 0, 6, 15, 8, C["wood1"])
    box(d, 0, 6, 15, 6, C["wood2"])
    box(d, 0, 8, 15, 8, C["wood0"])
    box(d, 11, 2, 14, 14, C["wood1"])
    box(d, 11, 2, 13, 3, C["wood2"])
    box(d, 13, 2, 14, 14, C["wood0"])
    px(d, 12, 4, C["wood2"])
    return im


def fence_v() -> Image.Image:
    im, d = new(16, 16)
    box(d, 6, 0, 8, 15, C["wood1"])
    box(d, 6, 0, 6, 15, C["wood2"])
    box(d, 8, 0, 8, 15, C["wood0"])
    box(d, 2, 11, 14, 14, C["wood1"])
    box(d, 2, 11, 14, 12, C["wood2"])
    box(d, 2, 13, 14, 14, C["wood0"])
    return im


def tuft() -> Image.Image:
    im, d = new(16, 16)
    rnd = random.Random(77)
    for i in range(6):
        x = 3 + i * 2 + rnd.randrange(0, 2)
        y = 12 - rnd.randrange(0, 4)
        px(d, x, y, C["grass3"])
        px(d, x, y + 1, C["grass0"])
        px(d, x + 1, y + 1, C["grass2"])
        px(d, x, y - 1, C["grass2"])
    return im


def flower(col: str = "white") -> Image.Image:
    im, d = new(16, 16)
    box(d, 7, 9, 7, 13, C["green2"])
    px(d, 6, 11, C["green"])
    px(d, 8, 12, C["green"])
    for ox, oy in ((7, 6), (8, 6), (7, 7), (8, 7)):
        px(d, ox, oy, C[col])
    px(d, 7, 7, C["gold"])
    px(d, 9, 8, C[col])
    px(d, 6, 8, C[col])
    return im


def stone() -> Image.Image:
    im, d = new(16, 16)
    disc(d, 8, 12, 5, 3, C["ink2"])
    disc(d, 8, 11, 4, 3, (120, 120, 130, 255))
    disc(d, 7, 10, 2, 1, (160, 160, 168, 255))
    px(d, 10, 12, (90, 90, 100, 255))
    return im


# ---------------------------------------------------------------- player
def player_frame(direction: int, step: int) -> Image.Image:
    """direction: 0 down, 1 left, 2 right, 3 up. step: 0..3."""
    im, d = new(16, 24)
    walk = step in (1, 3)
    swing = 1 if step == 1 else (-1 if step == 3 else 0)
    bob = 1 if walk else 0
    # ground shadow is a separate sprite
    # legs
    if direction in (0, 3):
        left_dy = 1 if step == 1 else 0
        right_dy = 1 if step == 3 else 0
        box(d, 5, 19, 6, 22 - left_dy, C["overall2"])
        box(d, 9, 19, 10, 22 - right_dy, C["overall2"])
        box(d, 4, 22 - left_dy, 6, 23 - left_dy, C["boot"])
        box(d, 9, 22 - right_dy, 11, 23 - right_dy, C["boot"])
    else:
        lead = 1 if step in (1, 2) else 0
        box(d, 6 + lead, 19, 7 + lead, 22, C["overall2"])
        box(d, 9 - lead, 19, 10 - lead, 22, C["overall2"])
        box(d, 5 + lead, 22, 7 + lead, 23, C["boot"])
        box(d, 9 - lead, 22, 11 - lead, 23, C["boot"])
    # body
    box(d, 5, 12 + bob, 10, 19 + bob, C["overall"])
    box(d, 4, 13 + bob, 4, 17 + bob, C["shirt"])
    box(d, 11, 13 + bob, 11, 17 + bob, C["shirt"])
    # straps
    if direction != 3:
        px(d, 6, 12 + bob, C["overall2"])
        px(d, 9, 12 + bob, C["overall2"])
        px(d, 7, 15 + bob, C["gold2"])
    # arms
    if direction == 0:
        box(d, 3, 14 + bob, 4, 17 + bob, C["skin"])
        box(d, 11, 14 + bob + swing, 12, 17 + bob + swing, C["skin"])
    elif direction == 1:
        box(d, 2, 15 + bob, 4, 17 + bob + swing, C["skin"])
    elif direction == 2:
        box(d, 11, 15 + bob, 13, 17 + bob + swing, C["skin"])
    else:
        box(d, 3, 14 + bob, 4, 16 + bob, C["skin"])
        box(d, 11, 14 + bob, 12, 16 + bob, C["skin"])
    # head
    head_y = 4 + bob
    if direction == 0:
        box(d, 4, head_y + 2, 11, head_y + 8, C["skin"])
        box(d, 4, head_y + 7, 11, head_y + 8, C["skin2"])
        # hair fringe + side locks
        box(d, 3, head_y + 1, 4, head_y + 7, C["hair"])
        box(d, 11, head_y + 1, 12, head_y + 7, C["hair"])
        box(d, 4, head_y + 2, 7, head_y + 3, C["hair"])
        px(d, 6, head_y + 4, C["ink"])
        px(d, 9, head_y + 4, C["ink"])
        px(d, 5, head_y + 5, (233, 156, 150, 255))
        px(d, 10, head_y + 5, (233, 156, 150, 255))
    elif direction == 3:
        box(d, 4, head_y + 2, 11, head_y + 8, C["hair"])
        box(d, 3, head_y + 3, 4, head_y + 8, C["hair2"])
        box(d, 11, head_y + 3, 12, head_y + 8, C["hair2"])
        box(d, 5, head_y + 2, 10, head_y + 4, C["hair2"])
    elif direction == 1:
        box(d, 3, head_y + 2, 10, head_y + 8, C["skin"])
        box(d, 9, head_y + 1, 11, head_y + 8, C["hair"])
        box(d, 3, head_y + 1, 4, head_y + 6, C["hair"])
        px(d, 5, head_y + 4, C["ink"])
        px(d, 3, head_y + 5, (233, 156, 150, 255))
    else:
        box(d, 5, head_y + 2, 12, head_y + 8, C["skin"])
        box(d, 4, head_y + 1, 6, head_y + 8, C["hair"])
        box(d, 11, head_y + 1, 12, head_y + 6, C["hair"])
        px(d, 10, head_y + 4, C["ink"])
        px(d, 12, head_y + 5, (233, 156, 150, 255))
    # straw hat
    hy = head_y - 2
    box(d, 3, hy + 2, 12, hy + 2, C["straw2"])
    box(d, 4, hy + 1, 11, hy + 1, C["straw"])
    box(d, 5, hy - 1, 10, hy + 1, C["straw"])
    box(d, 5, hy, 10, hy, C["straw2"])
    px(d, 7, hy + 1, C["red"])
    px(d, 8, hy + 1, C["red"])
    return im


def player_sheet() -> Image.Image:
    sheet, _ = new(64, 96)
    for direction in range(4):
        for step in range(4):
            sheet.paste(player_frame(direction, step), (step * 16, direction * 24))
    return sheet


def shadow() -> Image.Image:
    im, d = new(16, 8)
    disc(d, 8, 4, 6, 2.5, (20, 26, 36, 90))
    disc(d, 8, 4, 4, 1.5, (20, 26, 36, 70))
    return im


# ---------------------------------------------------------------- enemies
def slime_frame(step: int) -> Image.Image:
    im, d = new(16, 16)
    squash = (1.5, 0.0, 1.0)[step] if step < 3 else 0.5
    top = 7 + int(squash)
    w = 6 + (1 if step == 1 else 0)
    disc(d, 8, 14, w, 4, C["ink"])
    disc(d, 8, 14, w - 1, 3, C["purple2"])
    disc(d, 8, top + 3, w - 2, 4 + squash, C["purple"])
    disc(d, 6, top + 1, 3, 2, C["purple3"])
    px(d, 6, top + 4, C["ink"])
    px(d, 10, top + 4, C["ink"])
    px(d, 5, top + 6, (198, 170, 255, 255))
    px(d, 10, top + 6, (198, 170, 255, 255))
    return im


def slime_sheet() -> Image.Image:
    sheet, _ = new(64, 16)
    for i in range(4):
        sheet.paste(slime_frame(i % 3), (i * 16, 0))
    return sheet


def crow_frame(step: int) -> Image.Image:
    im, d = new(16, 16)
    up = 0 if step == 0 else 3
    disc(d, 8, 9, 5, 3.5, C["ink"])
    disc(d, 8, 9, 4, 3, C["crow"])
    # wings
    if step == 0:
        d.polygon([(3, 7), (1, 2), (7, 6)], fill=C["crow2"])
        d.polygon([(13, 7), (15, 2), (9, 6)], fill=C["crow2"])
    else:
        d.polygon([(3, 8), (0, 11), (6, 10)], fill=C["crow2"])
        d.polygon([(13, 8), (16, 11), (10, 10)], fill=C["crow2"])
    disc(d, 9, 6, 3, 2.5, C["crow"])
    # beak
    box(d, 12, 7, 14, 8, C["orange"])
    px(d, 14, 8, C["orange2"])
    # eye
    px(d, 10, 6, C["white"])
    px(d, 11, 6, C["ink"])
    # feet
    px(d, 7, 13, C["orange2"])
    px(d, 9, 13, C["orange2"])
    return im


def crow_sheet() -> Image.Image:
    sheet, _ = new(32, 16)
    for i in range(2):
        sheet.paste(crow_frame(i), (i * 16, 0))
    return sheet


def vine_frame(step: int) -> Image.Image:
    im, d = new(16, 16)
    sway = 1 if step else 0
    # root mass
    disc(d, 8, 12, 5, 3.5, C["ink"])
    disc(d, 8, 12, 4, 2.5, C["vine2"])
    # tendrils
    for i, (x, y, h) in enumerate(((3, 8, 4), (6, 5, 6), (9, 6, 5), (12, 8, 4))):
        x += sway if i % 2 else -sway
        box(d, x, y, x, y + h, C["vine"])
        px(d, x - 1, y + h - 1, C["vine2"])
        px(d, x + (1 if i % 2 else -1), y + 2, C["vine"])
    # face
    px(d, 6, 11, C["gold"])
    px(d, 9, 11, C["gold"])
    px(d, 6, 12, C["orange2"])
    px(d, 9, 12, C["orange2"])
    px(d, 5, 13, C["ink2"])
    px(d, 10, 13, C["ink2"])
    # thorns
    px(d, 2, 10, C["white"])
    px(d, 13, 7, C["white"])
    return im


def vine_sheet() -> Image.Image:
    sheet, _ = new(32, 16)
    for i in range(2):
        sheet.paste(vine_frame(i), (i * 16, 0))
    return sheet


def boss_frame(step: int) -> Image.Image:
    im, d = new(32, 32)
    bob = 1 if step else 0
    # vine arms
    for side in (-1, 1):
        x = 16 + side * 14
        for k in range(4):
            px(d, x + side * k // 2, 20 - k * 2 - bob, C["vine2"])
            px(d, x + side * k // 2, 19 - k * 2 - bob, C["vine"])
    # body
    disc(d, 16, 20 - bob, 13, 10, C["ink"])
    disc(d, 16, 19 - bob, 12, 9, C["orange2"])
    disc(d, 16, 18 - bob, 11, 8, C["orange"])
    # ribs
    for dx in (-7, -3, 3, 7):
        box(d, 16 + dx, 11 - bob, 16 + dx, 26 - bob, C["orange2"])
        box(d, 16 + dx + 1, 13 - bob, 16 + dx + 1, 24 - bob, (244, 170, 90, 255))
    # highlight
    disc(d, 11, 14 - bob, 3, 2, (250, 186, 112, 255))
    # stem + crown vines
    box(d, 15, 6 - bob, 18, 10 - bob, C["green2"])
    for dx, dy in ((-6, 5), (-3, 3), (0, 2), (3, 3), (6, 5)):
        px(d, 16 + dx, 9 - bob - dy, C["green"])
        px(d, 16 + dx, 10 - bob - dy, C["green2"])
    # face
    d.polygon([(9, 15 - bob), (13, 15 - bob), (11, 19 - bob)], fill=C["ink"])
    d.polygon([(19, 15 - bob), (23, 15 - bob), (21, 19 - bob)], fill=C["ink"])
    px(d, 11, 18 - bob, C["gold"])
    px(d, 21, 18 - bob, C["gold"])
    # jagged mouth
    d.polygon([(9, 23 - bob), (23, 23 - bob), (21, 27 - bob), (18, 25 - bob), (16, 28 - bob),
               (14, 25 - bob), (11, 27 - bob)], fill=C["ink"])
    for tx in range(10, 22, 4):
        px(d, tx, 24 - bob, C["white"])
        px(d, tx + 1, 24 - bob, C["white"])
    # glow eyes
    if step:
        px(d, 10, 17 - bob, (255, 240, 160, 255))
        px(d, 20, 17 - bob, (255, 240, 160, 255))
    return im


def boss_sheet() -> Image.Image:
    sheet, _ = new(64, 32)
    for i in range(2):
        sheet.paste(boss_frame(i), (i * 32, 0))
    return sheet


def seed_shot() -> Image.Image:
    im, d = new(8, 8)
    disc(d, 4, 5, 3, 2, C["orange"])
    disc(d, 3, 5, 1, 1, (255, 220, 150, 255))
    px(d, 4, 2, C["green2"])
    px(d, 5, 1, C["green"])
    return im


# ---------------------------------------------------------------- crops
def crop_radish(stage: int) -> Image.Image:
    im, d = new(16, 16)
    if stage == 0:
        px(d, 7, 12, C["green2"])
        px(d, 8, 11, C["green"])
        px(d, 6, 11, C["green"])
        px(d, 9, 12, C["green2"])
    elif stage == 1:
        box(d, 7, 10, 7, 13, C["green2"])
        for ox, oy in ((5, 9), (6, 8), (9, 9), (10, 10)):
            px(d, ox, oy, C["green"])
        px(d, 6, 10, C["green2"])
        px(d, 9, 11, C["green2"])
    elif stage == 2:
        box(d, 7, 8, 7, 12, C["green2"])
        for ox, oy in ((4, 8), (5, 7), (6, 6), (9, 8), (10, 7), (11, 8)):
            px(d, ox, oy, C["green"])
        disc(d, 8, 12, 3, 2, C["red"])
        disc(d, 8, 12, 2, 1.5, C["red2"])
        px(d, 8, 14, C["white"])
    else:
        box(d, 7, 5, 7, 9, C["green2"])
        for ox, oy in ((3, 5), (4, 4), (5, 3), (6, 4), (9, 5), (10, 4), (11, 3), (12, 4)):
            px(d, ox, oy, C["green"])
            px(d, ox, oy + 1, C["green2"] if oy % 2 else C["green"])
        disc(d, 8, 11, 4, 3.5, C["red"])
        disc(d, 7, 10, 2, 1.5, (240, 120, 120, 255))
        px(d, 8, 14, C["white"])
        px(d, 8, 15, (220, 200, 190, 255))
    return im


def crop_pumpkin(stage: int) -> Image.Image:
    im, d = new(16, 16)
    if stage == 0:
        px(d, 6, 13, C["green2"])
        px(d, 7, 12, C["green"])
        px(d, 8, 13, C["green"])
        px(d, 9, 13, C["green2"])
    elif stage == 1:
        box(d, 7, 11, 7, 14, C["green2"])
        disc(d, 9, 11, 2.5, 2, C["green"])
        disc(d, 9, 10, 1.5, 1, C["green2"])
        px(d, 7, 9, C["green"])
        px(d, 6, 10, C["green"])
    elif stage == 2:
        box(d, 7, 10, 7, 14, C["green2"])
        disc(d, 9, 12, 3.5, 3, C["orange2"])
        disc(d, 9, 11, 3, 2.5, C["orange"])
        px(d, 9, 7, C["green2"])
        px(d, 8, 8, C["green"])
        px(d, 10, 8, C["green"])
        px(d, 7, 12, C["orange2"])
        px(d, 11, 12, C["orange2"])
    else:
        box(d, 7, 9, 7, 14, C["green2"])
        disc(d, 8, 12, 5, 4, C["orange2"])
        disc(d, 8, 11, 4.5, 3.5, C["orange"])
        box(d, 7, 8, 8, 10, C["green2"])
        px(d, 6, 8, C["green"])
        px(d, 9, 8, C["green"])
        box(d, 6, 11, 6, 13, C["orange2"])
        box(d, 10, 11, 10, 13, C["orange2"])
        px(d, 8, 14, C["orange2"])
        px(d, 6, 9, (250, 180, 110, 255))
    return im


def crop_star(stage: int) -> Image.Image:
    im, d = new(16, 16)
    if stage == 0:
        px(d, 7, 13, C["green2"])
        px(d, 8, 12, C["green"])
        px(d, 7, 11, C["green"])
    elif stage == 1:
        box(d, 7, 9, 7, 14, C["green2"])
        px(d, 6, 9, C["green"])
        px(d, 8, 8, C["green"])
        px(d, 9, 9, C["green"])
        px(d, 7, 7, C["cyan2"])
    elif stage == 2:
        box(d, 7, 8, 7, 14, C["green2"])
        px(d, 5, 9, C["green"])
        px(d, 9, 8, C["green"])
        disc(d, 8, 7, 2.5, 2.5, C["cyan2"])
        disc(d, 8, 7, 1.5, 1.5, C["cyan"])
        px(d, 8, 7, C["gold"])
    else:
        box(d, 7, 9, 7, 14, C["green2"])
        px(d, 5, 10, C["green"])
        px(d, 10, 9, C["green"])
        # star bloom
        for dx, dy in ((0, -5), (4, -2), (3, 3), (-3, 3), (-4, -2)):
            px(d, 8 + dx, 7 + dy, C["cyan"])
            px(d, 8 + dx, 7 + dy + 1, C["cyan2"])
        disc(d, 8, 7, 3, 3, C["cyan2"])
        disc(d, 8, 7, 2, 2, C["cyan"])
        px(d, 8, 7, C["gold"])
        px(d, 7, 6, C["white"])
        px(d, 5, 4, C["cyan2"])
        px(d, 11, 3, C["cyan2"])
    return im


def crop_dead() -> Image.Image:
    im, d = new(16, 16)
    box(d, 7, 10, 7, 14, (120, 100, 60, 255))
    px(d, 6, 10, (150, 130, 80, 255))
    px(d, 8, 11, (100, 82, 52, 255))
    px(d, 5, 9, (120, 100, 60, 255))
    px(d, 9, 9, (120, 100, 60, 255))
    return im


# ---------------------------------------------------------------- ui
def panel(selected: bool = False) -> Image.Image:
    im, d = new(24, 24)
    fill = C["panel2"] if selected else C["panel"]
    border = C["border2"] if selected else C["border"]
    d.rectangle((0, 0, 23, 23), fill=fill)
    d.rectangle((0, 0, 23, 23), outline=border)
    d.rectangle((1, 1, 22, 22), outline=(10, 14, 24, 160))
    d.line((2, 2, 21, 2), fill=(255, 255, 255, 24))
    # corner studs
    for x, y in ((2, 2), (21, 2), (2, 21), (21, 21)):
        px(d, x, y, C["border2"] if selected else C["border"])
    return im


def button() -> Image.Image:
    im, d = new(24, 24)
    d.rectangle((0, 0, 23, 23), fill=(38, 58, 88, 255))
    d.rectangle((0, 0, 23, 23), outline=C["border2"])
    d.rectangle((1, 1, 22, 22), outline=(120, 168, 196, 160))
    d.line((2, 2, 21, 2), fill=(200, 230, 255, 90))
    d.line((2, 21, 21, 21), fill=(10, 14, 24, 160))
    return im


def heart(full: bool) -> Image.Image:
    im, d = new(16, 16)
    col = C["red"] if full else (72, 52, 64, 255)
    hi = (255, 140, 140, 255) if full else (96, 72, 82, 255)
    box(d, 3, 4, 6, 7, col)
    box(d, 9, 4, 12, 7, col)
    box(d, 2, 5, 13, 8, col)
    box(d, 3, 9, 12, 9, col)
    box(d, 5, 10, 10, 10, col)
    box(d, 6, 11, 9, 11, col)
    box(d, 7, 12, 8, 12, col)
    px(d, 5, 5, hi)
    px(d, 4, 6, hi)
    return im


def coin() -> Image.Image:
    im, d = new(16, 16)
    disc(d, 8, 8, 6, 6, C["ink"])
    disc(d, 8, 8, 5, 5, C["gold2"])
    disc(d, 8, 8, 4, 4, C["gold"])
    px(d, 6, 5, (255, 240, 170, 255))
    px(d, 7, 5, (255, 240, 170, 255))
    box(d, 7, 6, 9, 10, C["gold2"])
    px(d, 7, 6, C["gold2"])
    return im


def sun_icon() -> Image.Image:
    im, d = new(16, 16)
    disc(d, 8, 8, 4, 4, C["gold"])
    disc(d, 8, 8, 3, 3, (255, 226, 120, 255))
    for ang in range(0, 360, 45):
        x = 8 + int(round(math.cos(math.radians(ang)) * 7))
        y = 8 + int(round(math.sin(math.radians(ang)) * 7))
        px(d, x, y, C["gold2"])
        px(d, 8 + int(round(math.cos(math.radians(ang)) * 6)), 8 + int(round(math.sin(math.radians(ang)) * 6)), C["gold"])
    return im


def moon_icon() -> Image.Image:
    im, d = new(16, 16)
    disc(d, 9, 8, 5.5, 5.5, C["white"])
    disc(d, 6, 6, 5.5, 5.5, (0, 0, 0, 0))
    px(d, 11, 6, (206, 220, 240, 255))
    px(d, 12, 9, (206, 220, 240, 255))
    px(d, 10, 11, (206, 220, 240, 255))
    return im


def seed_icon(kind: str) -> Image.Image:
    im, d = new(16, 16)
    paper = (226, 208, 168, 255)
    d.polygon([(4, 4), (12, 4), (12, 12), (8, 14), (4, 12)], fill=paper)
    d.line([(4, 4), (12, 4)], fill=(168, 142, 100, 255))
    col = {"radish": C["red"], "pumpkin": C["orange"], "star": C["cyan"]}[kind]
    if kind == "radish":
        disc(d, 8, 8, 2.5, 2, col)
        px(d, 8, 5, C["green"])
        px(d, 7, 6, C["green"])
    elif kind == "pumpkin":
        disc(d, 8, 8, 3, 2.5, col)
        px(d, 8, 5, C["green2"])
        px(d, 7, 8, C["orange2"])
        px(d, 9, 8, C["orange2"])
    else:
        disc(d, 8, 8, 2, 2, C["gold"])
        for dx, dy in ((0, -3), (3, 0), (0, 3), (-3, 0)):
            px(d, 8 + dx, 8 + dy, col)
    return im


def tool_icon(kind: str) -> Image.Image:
    im, d = new(16, 16)
    if kind == "hoe":
        box(d, 4, 3, 5, 13, C["wood1"])
        box(d, 4, 11, 12, 12, C["wood1"])
        box(d, 11, 10, 13, 12, (150, 156, 168, 255))
        box(d, 12, 11, 14, 13, (96, 102, 116, 255))
    elif kind == "can":
        box(d, 3, 6, 11, 12, (120, 160, 180, 255))
        box(d, 4, 6, 10, 7, (168, 208, 220, 255))
        box(d, 11, 8, 13, 9, (120, 160, 180, 255))
        box(d, 13, 7, 14, 9, (168, 208, 220, 255))
        box(d, 5, 4, 7, 6, (96, 130, 150, 255))
    elif kind == "scythe":
        box(d, 3, 4, 4, 14, C["wood1"])
        d.arc((3, 1, 14, 10), 200, 350, fill=(200, 206, 220, 255), width=2)
        px(d, 13, 3, (240, 246, 255, 255))
        px(d, 3, 3, C["wood2"])
    elif kind == "clock":
        disc(d, 8, 8, 6, 6, C["border"])
        disc(d, 8, 8, 5, 5, (240, 238, 220, 255))
        box(d, 8, 4, 8, 8, C["ink2"])
        box(d, 8, 8, 11, 8, C["ink2"])
    return im


def spark() -> Image.Image:
    im, d = new(8, 8)
    disc(d, 4, 4, 2, 2, (255, 255, 255, 255))
    px(d, 1, 4, (255, 240, 180, 220))
    px(d, 7, 4, (255, 240, 180, 220))
    px(d, 4, 1, (255, 240, 180, 220))
    px(d, 4, 7, (255, 240, 180, 220))
    return im


def glow() -> Image.Image:
    im, d = new(64, 64)
    for r in range(30, 0, -2):
        a = int(90 * (1 - r / 32) ** 2)
        disc(d, 32, 32, r, r, (255, 236, 170, a))
    return im


def slash() -> Image.Image:
    im, d = new(32, 32)
    d.arc((4, 4, 28, 28), 300, 60, fill=(235, 250, 255, 235), width=2)
    d.arc((6, 6, 26, 26), 300, 60, fill=(150, 220, 235, 170), width=2)
    return im


def relic_icon(kind: str) -> Image.Image:
    im, d = new(24, 24)
    ink = C["ink"]
    if kind == "boots":
        box(d, 6, 5, 12, 15, C["green2"])
        box(d, 6, 5, 12, 7, C["green"])
        box(d, 4, 15, 16, 19, C["green"])
        box(d, 4, 18, 16, 19, C["ink"])
        box(d, 8, 8, 10, 10, C["gold"])
    elif kind == "whetstone":
        disc(d, 12, 13, 8, 5, C["ink"])
        disc(d, 12, 12, 7, 4, (120, 126, 140, 255))
        disc(d, 10, 10, 3, 2, (170, 176, 190, 255))
        for x, y in ((18, 4), (20, 7), (16, 6)):
            px(d, x, y, C["gold"])
    elif kind == "blubber":
        disc(d, 12, 13, 7, 7, C["ink"])
        disc(d, 12, 12, 6, 6, (86, 140, 200, 255))
        disc(d, 10, 10, 3, 2, (150, 200, 240, 255))
        box(d, 11, 4, 13, 6, C["gold2"])
    elif kind == "metronome":
        d.polygon([(12, 4), (19, 19), (5, 19)], fill=C["ink"])
        d.polygon([(12, 6), (17, 18), (7, 18)], fill=C["wood1"])
        box(d, 11, 9, 12, 16, C["wood2"])
        box(d, 8, 17, 16, 18, C["gold2"])
        px(d, 12, 5, C["gold"])
    elif kind == "rainbell":
        disc(d, 12, 12, 6, 6, C["gold"])
        disc(d, 12, 12, 4, 4, C["gold2"])
        box(d, 11, 4, 13, 8, C["gold2"])
        for x, y in ((5, 7), (18, 6), (4, 15), (19, 15), (8, 20)):
            px(d, x, y, C["cyan"])
            px(d, x + 1, y + 1, C["cyan2"])
    elif kind == "goldseed":
        disc(d, 12, 14, 6, 5, C["gold2"])
        disc(d, 11, 12, 4, 3, C["gold"])
        box(d, 12, 5, 13, 10, C["green2"])
        px(d, 10, 6, C["green"])
        px(d, 14, 7, C["green"])
        px(d, 9, 9, C["green2"])
    elif kind == "fang":
        d.polygon([(8, 4), (15, 4), (13, 14), (11, 20), (9, 14)], fill=C["white"])
        d.polygon([(9, 5), (14, 5), (12, 13), (11, 17), (10, 13)], fill=(226, 210, 190, 255))
        px(d, 11, 5, C["red"])
    elif kind == "thorns":
        d.line((5, 19, 18, 6), fill=C["green2"], width=3)
        d.line((5, 19, 18, 6), fill=C["green"], width=1)
        for x, y in ((8, 15), (11, 12), (14, 9), (12, 15), (9, 11)):
            px(d, x, y, C["white"])
            px(d, x + 1, y - 1, C["white"])
        px(d, 5, 19, C["wood0"])
    elif kind == "clover":
        for ox, oy in ((0, -5), (0, 4), (-5, 0), (5, 0)):
            disc(d, 11 + ox, 12 + oy, 4, 4, C["green2"])
            disc(d, 11 + ox, 12 + oy, 3, 3, C["green"])
        box(d, 11, 15, 12, 21, C["green2"])
        px(d, 10, 17, C["green"])
    elif kind == "tideheart":
        box(d, 6, 8, 10, 13, C["red"])
        box(d, 13, 8, 17, 13, C["red"])
        box(d, 5, 11, 18, 15, C["red"])
        box(d, 7, 16, 16, 17, C["red"])
        box(d, 9, 18, 14, 19, C["red"])
        box(d, 11, 20, 12, 21, C["red"])
        for x in range(5, 19, 3):
            px(d, x, 12, C["cyan"])
        px(d, 9, 10, (255, 170, 170, 255))
    elif kind == "longhandle":
        box(d, 4, 4, 5, 21, C["wood1"])
        d.arc((2, 1, 20, 13), 190, 350, fill=(210, 218, 230, 255), width=2)
        px(d, 19, 4, C["white"])
        px(d, 4, 3, C["wood2"])
    elif kind == "nightglass":
        disc(d, 12, 12, 8, 8, C["ink"])
        disc(d, 12, 12, 7, 7, (70, 74, 110, 255))
        disc(d, 14, 10, 5, 5, (235, 230, 190, 255))
        disc(d, 12, 9, 4, 4, (70, 74, 110, 255))
        for x, y in ((6, 6), (18, 7), (7, 18), (17, 17)):
            px(d, x, y, C["cyan"])
    else:
        disc(d, 12, 12, 8, 8, C["border"])
    return im


def leaf() -> Image.Image:
    im, d = new(8, 8)
    disc(d, 4, 4, 3, 2, (110, 180, 84, 255))
    px(d, 3, 3, (160, 220, 130, 255))
    return im


def app_icon() -> Image.Image:
    """64x64 pixel icon: a whale carrying a tiny lit farm under the moon."""
    im, d = new(64, 64)
    # night sky
    for y in range(64):
        t = y / 63.0
        d.line((0, y, 64, y), fill=lerp((14, 20, 46), (38, 62, 88), t))
    rnd = random.Random(7)
    for _ in range(28):
        x = rnd.randrange(1, 63)
        y = rnd.randrange(1, 38)
        px(d, x, y, (235, 240, 255, rnd.randrange(120, 255)))
    # moon
    disc(d, 48, 15, 9, 9, (246, 238, 202, 255))
    disc(d, 45, 13, 7, 7, (232, 224, 186, 255))
    px(d, 50, 18, (214, 206, 168, 255))
    px(d, 47, 11, (214, 206, 168, 255))
    # sea
    for y in range(44, 64):
        t = (y - 44) / 20.0
        d.line((0, y, 64, y), fill=lerp((26, 58, 84), (8, 18, 34), t))
    for _ in range(20):
        x = rnd.randrange(0, 64)
        y = rnd.randrange(46, 64)
        d.line((x, y, x + rnd.randrange(2, 7), y), fill=(70, 116, 140, 120))
    # whale silhouette
    body = [(6, 50), (10, 44), (22, 41), (40, 40), (55, 42), (60, 47), (56, 52), (38, 55), (16, 55)]
    d.polygon(body, fill=(30, 42, 60, 255))
    d.polygon([(6, 50), (2, 42), (4, 50), (10, 54)], fill=(30, 42, 60, 255))
    d.polygon([(10, 48), (14, 55), (20, 52)], fill=(24, 34, 50, 255))
    # grass on the back
    d.polygon([(18, 42), (40, 40), (57, 45), (54, 48), (30, 48), (18, 46)], fill=(52, 88, 62, 255))
    # house
    d.rectangle((30, 33, 42, 44), fill=(148, 106, 74, 255))
    d.polygon([(27, 34), (36, 27), (45, 34)], fill=(122, 72, 58, 255))
    d.rectangle((33, 37, 37, 41), fill=(250, 206, 110, 255))
    d.rectangle((39, 37, 41, 41), fill=(70, 96, 118, 255))
    # crops
    for i in range(5):
        x = 18 + i * 4
        d.line((x, 44, x, 41), fill=(96, 158, 84, 255))
        px(d, x - 1, 40, (120, 186, 96, 255))
    # bubble / sparkle
    px(d, 52, 30, (126, 227, 212, 255))
    px(d, 54, 27, (126, 227, 212, 200))
    return im.resize((256, 256), Image.NEAREST)


def leaf_preview() -> None:
    pass


# ---------------------------------------------------------------- title art
def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def title_art() -> Image.Image:
    w, h = 320, 180
    im = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    d = ImageDraw.Draw(im)
    # sky gradient: deep indigo to teal
    top = (12, 16, 42)
    bottom = (58, 102, 120)
    for y in range(110):
        d.line((0, y, w, y), fill=lerp(top, bottom, (y / 110) ** 0.85))
    # stars
    rnd = random.Random(20261029)
    for _ in range(120):
        x = rnd.randrange(0, w)
        y = rnd.randrange(0, 105)
        a = rnd.randrange(90, 255)
        s = 1 if rnd.random() < 0.85 else 2
        d.rectangle((x, y, x + s - 1, y + s - 1), fill=(235, 240, 255, a))
    # moon
    d.ellipse((232, 14, 288, 70), fill=(246, 238, 202, 255))
    d.ellipse((244, 24, 280, 60), fill=(232, 224, 186, 255))
    for cx, cy, r in ((252, 32, 5), (266, 46, 7), (256, 52, 3)):
        d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(214, 206, 168, 255))
    # distant clouds (opaque, pre-blended with the sky so no alpha holes)
    for cx, cy, cw in ((60, 40, 46), (120, 28, 32), (20, 70, 40)):
        sky = lerp(top, bottom, (cy / 110) ** 0.85)
        cloud = lerp(sky, (120, 134, 168), 0.42)
        d.ellipse((cx - cw // 2, cy - 6, cx + cw // 2, cy + 6), fill=cloud)
        d.ellipse((cx - cw // 3, cy - 10, cx + cw // 3, cy + 4), fill=lerp(cloud, (150, 164, 196), 0.25))
    # sea
    for y in range(105, h):
        t = (y - 105) / (h - 105)
        d.line((0, y, w, y), fill=lerp((26, 58, 84), (8, 18, 34), t))
    for _ in range(200):
        x = rnd.randrange(0, w)
        y = rnd.randrange(105, h)
        length = rnd.randrange(2, 10)
        col = (70, 116, 140, rnd.randrange(30, 90))
        d.line((x, y, x + length, y), fill=col)
    # whale island silhouette
    body = [(28, 132), (52, 122), (98, 118), (150, 116), (206, 118), (248, 124),
            (276, 132), (282, 140), (262, 148), (170, 152), (80, 150), (38, 144)]
    d.polygon(body, fill=(32, 44, 62, 255))
    d.polygon([(p[0], p[1] + 4) for p in body], fill=(22, 30, 46, 255))
    # grass back on whale
    d.polygon([(60, 124), (92, 118), (150, 116), (206, 118), (252, 126), (248, 132),
               (170, 137), (96, 136), (62, 131)], fill=(52, 88, 62, 255))
    d.line([(60, 124), (150, 116), (252, 126)], fill=(86, 134, 84, 255))
    # whale tail
    d.polygon([(20, 130), (6, 118), (2, 128), (12, 136)], fill=(30, 42, 60, 255))
    # farmhouse
    hx, hy = 176, 96
    d.rectangle((hx, hy + 12, hx + 34, hy + 32), fill=(148, 106, 74, 255))
    d.polygon([(hx - 4, hy + 12), (hx + 17, hy - 4), (hx + 38, hy + 12)], fill=(122, 72, 58, 255))
    d.rectangle((hx + 4, hy + 18, hx + 12, hy + 26), fill=(250, 206, 110, 255))
    d.rectangle((hx + 20, hy + 18, hx + 26, hy + 26), fill=(70, 96, 118, 255))
    d.rectangle((hx + 18, hy + 30, hx + 30, hy + 32), fill=(96, 66, 46, 255))
    # chimney + smoke
    d.rectangle((hx + 28, hy - 2, hx + 33, hy + 6), fill=(110, 76, 64, 255))
    for i, (sx, sy, r) in enumerate(((hx + 33, hy - 8, 3), (hx + 37, hy - 14, 4), (hx + 43, hy - 21, 5))):
        smoke = lerp((120, 134, 168), (150, 160, 190), 0.3)
        d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=smoke)
    # crops rows on whale back
    for row in range(2):
        for i in range(9):
            x = 96 + i * 10 + row * 3
            y = 126 + row * 5
            d.line((x, y, x, y - 3), fill=(96, 158, 84, 255))
            d.ellipse((x - 2, y - 5, x + 2, y - 2), fill=(120, 186, 96, 255))
    # fence
    for i in range(18):
        x = 58 + i * 11
        d.rectangle((x, 128, x + 1, 133), fill=(118, 82, 52, 255))
    d.line((58, 129, 250, 129), fill=(90, 62, 42, 255))
    # lighthouse on right
    lx = 292
    d.rectangle((lx, 102, lx + 8, 134), fill=(188, 190, 198, 255))
    d.rectangle((lx + 2, 100, lx + 6, 104), fill=(250, 214, 120, 255))
    d.polygon([(lx - 1, 102), (lx + 4, 96), (lx + 9, 102)], fill=(150, 70, 62, 255))
    for yy in range(106, 130, 10):
        d.rectangle((lx, yy, lx + 8, yy + 4), fill=(196, 86, 74, 255))
    # glow from lighthouse (soft radial, composited properly over the sky)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for r in range(26, 0, -1):
        a = int(2 + 20 * (1 - r / 27) ** 2)
        gd.ellipse((lx + 4 - r, 100 - r, lx + 4 + r, 100 + r), fill=(250, 220, 140, a))
    im = Image.alpha_composite(im, glow)
    d = ImageDraw.Draw(im)
    # foreground water highlights
    for _ in range(60):
        x = rnd.randrange(0, w)
        y = rnd.randrange(135, h)
        d.line((x, y, x + rnd.randrange(3, 9), y), fill=(96, 150, 168, 70))
    return im


# ---------------------------------------------------------------- preview
def build_preview() -> None:
    tile_paths = sorted((OUT / "tiles").glob("*.png"))
    char_paths = sorted((OUT / "chars").glob("*.png"))
    crop_paths = sorted((OUT / "crops").glob("*.png"))
    ui_paths = sorted((OUT / "ui").glob("*.png"))
    scale = 6
    cols = 10
    all_paths = tile_paths + char_paths + crop_paths + ui_paths
    cell_w, cell_h = 24 * scale + 12, 30 * scale + 12
    rows = math.ceil(len(all_paths) / cols)
    sheet = Image.new("RGBA", (cols * cell_w, rows * cell_h), (26, 32, 44, 255))
    ds = ImageDraw.Draw(sheet)
    for i, p in enumerate(all_paths):
        im = Image.open(p).convert("RGBA")
        im = im.resize((im.width * scale, im.height * scale), Image.NEAREST)
        cx = (i % cols) * cell_w + 6
        cy = (i // cols) * cell_h + 6
        sheet.paste(im, (cx, cy), im)
        ds.text((cx, cy + 24 * scale + 2), p.stem, fill=(220, 228, 240, 255))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(PREVIEW)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    # tiles
    for i in range(4):
        save(grass_tile(i), "tiles", f"grass_{i}.png")
    save(soil_tile(False), "tiles", "soil.png")
    save(soil_tile(True), "tiles", "soil_wet.png")
    save(sand_tile(), "tiles", "sand.png")
    for i in range(2):
        save(path_tile(i), "tiles", f"path_{i}.png")
    save(fence_h(), "tiles", "fence_h.png")
    save(fence_v(), "tiles", "fence_v.png")
    save(tuft(), "tiles", "tuft.png")
    save(flower(), "tiles", "flower.png")
    save(stone(), "tiles", "stone.png")
    # characters
    save(player_sheet(), "chars", "player.png")
    save(slime_sheet(), "chars", "slime.png")
    save(crow_sheet(), "chars", "crow.png")
    save(vine_sheet(), "chars", "vine.png")
    save(boss_sheet(), "chars", "boss_pumpkin.png")
    save(shadow(), "chars", "shadow.png")
    # crops
    for i in range(4):
        save(crop_radish(i), "crops", f"radish_{i}.png")
        save(crop_pumpkin(i), "crops", f"pumpkin_{i}.png")
        save(crop_star(i), "crops", f"star_{i}.png")
    save(crop_dead(), "crops", "dead.png")
    # ui
    save(panel(False), "ui", "panel.png")
    save(panel(True), "ui", "panel_sel.png")
    save(button(), "ui", "button.png")
    save(heart(True), "ui", "heart_full.png")
    save(heart(False), "ui", "heart_empty.png")
    save(coin(), "ui", "coin.png")
    save(sun_icon(), "ui", "sun.png")
    save(moon_icon(), "ui", "moon.png")
    for k in ("radish", "pumpkin", "star"):
        save(seed_icon(k), "ui", f"seed_{k}.png")
    for k in ("hoe", "can", "scythe", "clock"):
        save(tool_icon(k), "ui", f"icon_{k}.png")
    for rid in ("boots", "whetstone", "blubber", "metronome", "rainbell", "goldseed",
                "fang", "thorns", "clover", "tideheart", "longhandle", "nightglass"):
        save(relic_icon(rid), "ui", f"relic_{rid}.png")
    save(spark(), "fx", "spark.png")
    save(glow(), "fx", "glow.png")
    save(slash(), "fx", "slash.png")
    save(leaf(), "fx", "leaf.png")
    save(seed_shot(), "fx", "seed_shot.png")
    save(title_art(), "bg", "title.png")
    icon = app_icon()
    save(icon, "icon.png")
    icon.save(OUT / "icon.ico", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    build_preview()
    n = len(list(OUT.rglob("*.png")))
    print(f"generated {n} sprites -> {OUT}")
    print(f"preview -> {PREVIEW}")


if __name__ == "__main__":
    main()

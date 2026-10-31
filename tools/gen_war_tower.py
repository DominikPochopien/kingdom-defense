#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - Wieza wroga (poziom 8): ciemna kamienna wieza z czerwonymi proporcami i koszem ognia.

Widok jak wieze graczy (lekko z przodu), swiatlo z lewej-gory, paleta Resurrect 64.

Plik (assets/objects/):
  war_tower.png   3 klatki 24x44 w poziomym pasku: 0 - spokojna (kosz wygaszony),
                  1-2 - plonie (ogien migocze, proporce sie swieca). Podstawa wiezy = dol klatki.

Uruchamia go gen_art.py, mozna tez osobno:  python tools/gen_war_tower.py [--out X]
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_art import C, new, px, h01, check_palette, outline, shadow_ellipse, stack  # noqa: E402

FRAME_W, FRAME_H = 24, 44
DARK_STONE = ["2e222f", "3e3546", "625565", "7f708a"]   # od cienia do swiatla
BANNER = ["6e2727", "b33831", "ea4f36"]
BANNER_LIT = ["b33831", "ea4f36", "f57d4a"]
FIRE = [["ae2334", "fb6b1d", "f9c22b", "fbff86"], ["b33831", "f79617", "fbb954", "fbff86"]]


def stone_col(x, y, x0, x1, seed):
    """Cegly: spoina co 4 wiersze, przesuniecie co drugi rzad; lewa strona jasniejsza."""
    row = y // 4
    if y % 4 == 3 or (x + (row % 2) * 2) % 5 == 4:
        return DARK_STONE[0]
    t = (x - x0) / max(1, x1 - x0)
    shade = 3 if t < 0.25 else (2 if t < 0.7 else 1)
    if h01(x // 5, row, seed) < 0.2:
        shade = max(1, shade - 1)
    return DARK_STONE[shade]


def body():
    img = new(FRAME_W, FRAME_H)
    # trzon wiezy i szersza podstawa
    for y in range(14, 41):
        x0, x1 = (4, 19) if y < 35 else (3, 20)
        for x in range(x0, x1 + 1):
            px(img, x, y, C(stone_col(x, y, x0, x1, 3)))
    # gzyms i blanki
    for x in range(3, 21):
        px(img, x, 13, C(DARK_STONE[3] if x < 9 else DARK_STONE[2]))
        px(img, x, 12, C(DARK_STONE[2] if x < 12 else DARK_STONE[1]))
    for mx in (3, 8, 13, 18):
        for x in range(mx, mx + 3):
            for y in range(8, 12):
                px(img, x, y, C(DARK_STONE[3] if x == mx else DARK_STONE[2] if x == mx + 1 else DARK_STONE[1]))
    # brama i strzelnica
    for y in range(34, 41):
        for x in range(10, 14):
            if y > 34 or x in (11, 12):
                px(img, x, y, C("2e222f"))
    for y in range(18, 22):
        px(img, 11, y, C("2e222f"))
        px(img, 12, y, C("2e222f"))
    return img


def banners(lit):
    img = new(FRAME_W, FRAME_H)
    ramp = BANNER_LIT if lit else BANNER
    for bx in (5, 16):
        for y in range(15, 26):
            for x in range(bx, bx + 3):
                if y >= 24 and x == bx + 1:
                    continue                       # wciecie na dole proporca
                px(img, x, y, C(ramp[2] if x == bx else ramp[1] if x == bx + 1 else ramp[0]))
        px(img, bx + 1, 18, C("2e222f"))           # czarny znak
        px(img, bx + 1, 19, C("2e222f"))
    return img


def brazier(frame):
    img = new(FRAME_W, FRAME_H)
    # kosz na srodku blankow
    for x in range(9, 15):
        px(img, x, 7, C("3e3546"))
    for x in range(10, 14):
        px(img, x, 6, C("625565"))
    if frame == 0:
        px(img, 11, 5, C("3e3546"))                # zgaszony zar
        px(img, 12, 5, C("6e2727"))
        return img
    fire = FIRE[frame - 1]
    shape = [(5, 8, 15), (4, 8, 15), (3, 9, 14), (2, 9, 14), (1, 10, 13), (0, 10 + frame, 11 + frame)]
    for y, x0, x1 in shape:
        for x in range(x0, x1 + 1):
            mid = (x0 + x1) / 2.0
            k = 3 - min(3, int(abs(x + 0.5 - mid - 0.5) + (5 - y) * 0.5))
            k = max(0, min(3, k))
            px(img, x, y, C(fire[k]))
    return img


def frame(i):
    base = new(FRAME_W, FRAME_H)
    shadow_ellipse(base, 12, 41.5, 10, 2.5)
    tower = stack(body(), banners(i > 0))
    tower = outline(tower, C("2e222f"))
    return stack(base, tower, brazier(i))


def run(out="."):
    folder = os.path.join(out, "assets", "objects")
    os.makedirs(folder, exist_ok=True)
    strip = new(FRAME_W * 3, FRAME_H)
    for i in range(3):
        strip.alpha_composite(frame(i), (i * FRAME_W, 0))
    check_palette(strip, "war_tower")
    p = os.path.join(folder, "war_tower.png")
    strip.save(p)
    print("Wieza wroga: %s %dx%d (3 klatki 24x44)" % (os.path.relpath(p, out), strip.width, strip.height))


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    run(ap.parse_args().out)

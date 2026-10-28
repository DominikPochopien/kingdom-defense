#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - generator grafik pixel art, ETAP 4:
sojusznicy (zolnierz, rycerz z dzida, bohater, lesny lucznik), pustynny ptak z jajkiem,
pociski, efekty (wybuch, ognisty deszcz, ogien smoka, dymek smierci) i ikony interfejsu.

Uruchamia go tools/gen_art.py na koncu, mozna tez osobno:
    python tools/gen_fx.py [--out X]
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as G  # noqa: E402
import gen_units as U  # noqa: E402
from gen_art import C, new, px, alpha, h01, bayer, outline, shadow_ellipse, stack, blob, hstrip, check_palette  # noqa: E402
from gen_units import rect, ell, poly, line, finish, flash, humanoid, walk_poses, make_blade, wdir, OUT  # noqa: E402
from PIL import Image  # noqa: E402

SKIN = ["cd683d", "e6904e", "fca790"]
STEEL = ["3e3546", "625565", "7f708a", "9babb2"]
GOLD = ["cd683d", "f79617", "f9c22b", "fbff86"]


# ================================================================ SOJUSZNICY
# ---------------------------------------------------------------- zolnierz 12x16
def soldier_head(img, hx, hy, pose):
    for y in range(hy - 3, hy):
        for x in range(hx - 3, hx + 3):
            if alpha(img, x, y):
                px(img, x, y, C("9babb2" if x < hx else "7f708a"))
    rect(img, hx - 2, hy - 1, hx + 2, hy - 1, C("625565"))
    px(img, hx + 1, hy, C("625565"))   # nosal
    px(img, hx + 2, hy, C("2e222f"))   # oko


def small_shield(img, hand, pose):
    x, y = int(round(hand[0])), int(round(hand[1]))
    rect(img, x - 1, y - 2, x + 1, y + 1, C("9e4539"))
    px(img, x - 1, y - 2, C("cd683d"))
    px(img, x, y - 1, C("c7dcd0"))
    px(img, x, y + 2, C("6e2727"))


SOLDIER = {"size": (12, 16), "cx": 5, "leg": 4, "torso": 4, "head": 2.4, "head_dx": 1, "leg_w": 1.3,
           "arm": 3, "arm_w": 1.2, "torso_w": 4.5, "torso_ramp": ["6e2727", "9e4539", "cd683d"],
           "head_ramp": SKIN, "head_fn": soldier_head, "limb": "9babb2", "limb_dark": "625565",
           "leg_col": "966c6c", "leg_dark": "4c3e24", "boot": ("45293f", "4c3e24"), "hand": "fca790",
           "belt": "4c3e24", "shadow_r": 4, "offhand": small_shield,
           "weapon": make_blade(4, "c7dcd0", "ffffff", guard="cd683d", grip="4c3e24")}


def soldier_anims():
    walk = [humanoid(SOLDIER, dict(p, arm_back=70)) for p in walk_poses(amp=2, weapon=60)]
    att = [humanoid(SOLDIER, dict(p, arm_back=70)) for p in U.ATTACK]
    return {"walk": walk, "attack": att, "hit": [flash(humanoid(SOLDIER, {"weapon": 60, "arm_back": 70}))]}


# ---------------------------------------------------------------- rycerz z dzida 14x18
TABARD = ["323353", "484a77", "4d65b4"]


def spear_knight_head(img, hx, hy, pose):
    for y in range(hy - 3, hy + 3):
        for x in range(hx - 3, hx + 3):
            if alpha(img, x, y):
                px(img, x, y, C("9babb2" if x < hx - 0.5 else "7f708a"))
    rect(img, hx, hy, hx + 2, hy, C("2e222f"))      # szczelina przylbicy
    px(img, hx - 1, hy - 3, C("4d9be6"))            # pioropusz
    px(img, hx - 2, hy - 3, C("4d65b4"))
    px(img, hx - 3, hy - 2, C("484a77"))


def spear(img, hand, deg, pose):
    dx, dy = wdir(deg)
    hx, hy = hand
    fwd = pose.get("reach", 5)
    line(img, hx - dx * 6, hy - dy * 6, hx + dx * fwd, hy + dy * fwd, C("ab947a"), 1)
    tx, ty = hx + dx * (fwd + 1), hy + dy * (fwd + 1)
    px(img, int(round(tx)), int(round(ty)), C("c7dcd0"))
    px(img, int(round(tx + dx)), int(round(ty + dy)), C("ffffff"))
    px(img, int(round(hx + dx * fwd - dy)), int(round(hy + dy * fwd + dx)), C("4d65b4"))  # proporczyk


SPEAR_KNIGHT = {"size": (14, 18), "cx": 6, "leg": 5, "torso": 5, "head": 2.7, "head_dx": 1, "leg_w": 1.5,
                "arm": 3.5, "arm_w": 1.4, "torso_w": 5, "torso_ramp": TABARD, "head_ramp": STEEL,
                "head_fn": spear_knight_head, "limb": "9babb2", "limb_dark": "625565",
                "leg_col": "7f708a", "leg_dark": "3e3546", "boot": ("2e222f", "3e3546"), "hand": "9babb2",
                "belt": "f9c22b", "shadow_r": 5, "weapon": spear,
                "shoulder": lambda img, sx, sy: blob(img, sx, sy, 1.6, 1.3, STEEL, seed=3, dither=0.2)}
SPEAR_ATTACK = [
    {"arm_front": 40, "weapon": 92, "lean": -1, "legs": (1, -1), "reach": 3, "arm_back": 60},
    {"arm_front": 95, "weapon": 90, "lean": 1, "legs": (3, -2), "reach": 5, "arm_back": 80},
    {"arm_front": 70, "weapon": 95, "lean": 0, "legs": (2, -1), "reach": 4, "arm_back": 70},
]


def spear_knight_anims():
    walk = [humanoid(SPEAR_KNIGHT, dict(p, reach=4)) for p in walk_poses(amp=2, weapon=40)]
    att = [humanoid(SPEAR_KNIGHT, p) for p in SPEAR_ATTACK]
    return {"walk": walk, "attack": att, "hit": [flash(humanoid(SPEAR_KNIGHT, {"weapon": 15, "reach": 4}))]}


# ---------------------------------------------------------------- bohater 16x22
def hero_head(img, hx, hy, pose):
    for y in range(hy - 3, hy + 3):
        for x in range(hx - 3, hx + 4):
            if alpha(img, x, y):
                px(img, x, y, C("f9c22b" if x < hx - 0.5 else "f79617"))
    rect(img, hx, hy, hx + 2, hy, C("2e222f"))
    px(img, hx - 1, hy - 2, C("fbff86"))
    px(img, hx - 2, hy - 1, C("fbff86"))
    line(img, hx - 1, hy - 3, hx - 4, hy - 4, C("b33831"), 1.4)   # pioropusz
    px(img, hx - 5, hy - 3, C("6e2727"))


def hero_cape(img, sh_x, sh_y, hip_y, foot_y, pose):
    fl = pose.get("legs", (0, 0))[1] * 0.5
    poly(img, [(sh_x - 2, sh_y - 1), (sh_x + 1, sh_y - 1), (sh_x, foot_y - 2), (sh_x - 6 + fl, foot_y - 1)],
         C("9e4539"))
    line(img, sh_x - 2, sh_y, sh_x - 5 + fl, foot_y - 2, C("b33831"), 1)


HERO = {"size": (16, 22), "cx": 7, "leg": 6, "torso": 6, "head": 3.0, "head_dx": 1.5, "neck": 0,
        "leg_w": 1.8, "arm": 4.2, "arm_w": 1.7, "torso_w": 6, "torso_ramp": GOLD, "head_ramp": GOLD,
        "head_fn": hero_head, "limb": "f9c22b", "limb_dark": "f79617", "leg_col": "f9c22b",
        "leg_dark": "cd683d", "boot": ("6e2727", "9e4539"), "hand": "fbff86", "belt": "6e2727",
        "shadow_r": 6, "cape": hero_cape,
        "shoulder": lambda img, sx, sy: blob(img, sx, sy, 2.0, 1.6, GOLD, seed=5, dither=0.2),
        "weapon": make_blade(8, "f9c22b", "fbff86", guard="cd683d", grip="6e2727", width=2)}


def swoosh(img, cx, cy, rx, ry, a0, a1, col="fbff86"):
    """Smuga po zamachu mieczem: luk elipsy tylko na pustych pikselach."""
    out = img.copy()
    steps = 40
    for i in range(steps + 1):
        a = math.radians(a0 + (a1 - a0) * i / steps)
        for k, (dr, al) in enumerate(((0, 230), (-1, 140))):
            x = int(round(cx + math.cos(a) * (rx + dr)))
            y = int(round(cy + math.sin(a) * (ry + dr * 0.5)))
            if 0 <= x < img.width and 0 <= y < img.height and img.getpixel((x, y))[3] == 0:
                out.putpixel((x, y), C(col if k == 0 else "f9c22b", al))
    return out


def hero_front(back, sword_dir):
    img = new(16, 22)
    cx = 8
    line(img, cx - 2, 15, cx - 2, 20, C("f9c22b" if not back else "cd683d"), 2)
    line(img, cx + 2, 15, cx + 2, 20, C("cd683d"), 2)
    rect(img, cx - 3, 20, cx - 1, 20, C("6e2727"))
    rect(img, cx + 1, 20, cx + 3, 20, C("6e2727"))
    blob(img, cx, 11.5, 3.8, 4.2, GOLD, seed=2, dither=0.3)
    hy = 5
    blob(img, cx, hy, 3.0, 3.0, GOLD, seed=4, dither=0.3)
    if back:
        poly(img, [(cx - 4, 8), (cx + 4, 8), (cx + 5, 18), (cx - 5, 18)], C("9e4539"))
        line(img, cx - 4, 9, cx - 5, 17, C("b33831"), 1)
        line(img, cx, hy - 3, cx, hy - 5, C("b33831"), 1.4)
    else:
        rect(img, cx - 2, hy, cx + 1, hy, C("2e222f"))
        px(img, cx, hy + 1, C("2e222f"))
        line(img, cx, hy - 3, cx, hy - 5, C("b33831"), 1.4)
        px(img, cx - 1, hy - 2, C("fbff86"))
    sx = cx + sword_dir * 4
    line(img, cx + sword_dir * 2, 10, sx, 12, C("f9c22b"), 1.6)              # reka
    line(img, cx - sword_dir * 3, 10, cx - sword_dir * 4, 14, C("cd683d"), 1.6)
    line(img, sx, 12, sx + sword_dir * 8, 12, C("f9c22b"), 2)               # miecz poziomo
    line(img, sx + sword_dir * 1, 11, sx + sword_dir * 8, 11, C("fbff86"), 1)
    rect(img, sx, 10, sx, 14, C("cd683d"))                                   # jelec
    return finish(img, shadow=(8, 21, 6, 1.2))


def hero_anims():
    walk = [humanoid(HERO, p) for p in walk_poses(amp=2.5, weapon=35)]
    att = [humanoid(HERO, p) for p in U.ATTACK]
    hit = [flash(humanoid(HERO, {"weapon": 35}))]
    side = humanoid(HERO, {"arm_front": 92, "weapon": 90, "legs": (2, -2)})
    spin = [
        swoosh(side, 8, 13, 7.5, 3.5, 180, 360),
        swoosh(hero_front(False, -1), 8, 13, 7.5, 3.5, -90, 90),
        swoosh(side.transpose(Image.FLIP_LEFT_RIGHT), 8, 13, 7.5, 3.5, 0, 180),
        swoosh(hero_front(True, 1), 8, 13, 7.5, 3.5, 90, 270),
    ]
    return {"walk": walk, "attack": att, "spin": spin, "hit": hit}


# ---------------------------------------------------------------- lesny lucznik z dmuchawka 12x16
CLOAK = ["165a4c", "239063", "1ebc73"]


def ranger_head(img, hx, hy, pose):
    for y in range(hy - 3, hy + 3):                   # kaptur
        for x in range(hx - 3, hx + 1):
            if alpha(img, x, y):
                px(img, x, y, C("239063" if x < hx - 1 else "165a4c"))
    px(img, hx - 1, hy - 3, C("1ebc73"))
    px(img, hx - 3, hy - 2, C("165a4c"))
    px(img, hx + 1, hy - 1, C("2e222f"))              # oko


def blowgun_carry(img, hand, deg, pose):
    if pose.get("aim"):
        return
    dx, dy = wdir(deg)
    hx, hy = hand
    line(img, hx - dx * 2, hy - dy * 2, hx + dx * 3, hy + dy * 3, C("966c6c"), 1)


RANGER = {"size": (12, 16), "cx": 5, "leg": 4, "torso": 4, "head": 2.4, "head_dx": 1, "leg_w": 1.2,
          "arm": 3, "arm_w": 1.2, "torso_w": 4.5, "torso_ramp": CLOAK, "head_ramp": SKIN,
          "head_fn": ranger_head, "limb": "239063", "limb_dark": "165a4c", "leg_col": "966c6c",
          "leg_dark": "4c3e24", "boot": ("4c3e24", "4c3e24"), "hand": "fca790", "belt": "966c6c",
          "shadow_r": 4, "weapon": blowgun_carry,
          "glow_fn": lambda img, pose: ranger_aim(img, pose)}
def ranger_aim(img, pose):
    """Dmuchawka przy ustach, rysowana na wierzchu (po rekach)."""
    res = img.copy()
    y = 6
    for x in range(6, 11):
        res.putpixel((x, y), C("966c6c"))
        if res.getpixel((x, y - 1))[3] == 0:
            res.putpixel((x, y - 1), OUT)
        res.putpixel((x, y + 1), OUT)
    res.putpixel((11, y), C("4c3e24"))
    res.putpixel((11, y - 1), OUT)
    res.putpixel((11, y + 1), OUT)
    if pose.get("puff"):
        res.putpixel((7, 7), C("fca790"))
        res.putpixel((7, 4), C("c7dcd0", 200))
    if pose.get("dart") is not None:
        res.putpixel((min(11, 9 + pose["dart"]), y), C("ffffff"))
    return res


RANGER_ATTACK = [
    {"aim": True, "glow": True, "arm_front": 110, "arm_back": 95, "legs": (1, -1)},
    {"aim": True, "glow": True, "puff": True, "dart": 1, "arm_front": 110, "arm_back": 95, "legs": (1, -1)},
    {"aim": True, "glow": True, "dart": 2, "arm_front": 105, "arm_back": 90, "legs": (1, -1)},
]


def ranger_anims():
    walk = [humanoid(RANGER, p) for p in walk_poses(amp=2, weapon=50)]
    att = [humanoid(RANGER, p) for p in RANGER_ATTACK]
    return {"walk": walk, "attack": att, "hit": [flash(humanoid(RANGER, {"weapon": 50}))]}


# ---------------------------------------------------------------- pustynny ptak z jajkiem 16x12
BIRD = ["45293f", "4c3e24", "966c6c"]


def bird(f):
    img = new(16, 12)
    tip = [0, 2, 10, 3][f]        # wysokosc koncow skrzydel: gora, srodek, dol, srodek
    by = [1, 0, -1, 0][f]
    # dalsze skrzydlo (ciemniejsze, przesuniete)
    poly(img, [(9, 5 + by), (8, tip - 1 if tip > 1 else 0), (5, tip - 1 if tip > 1 else 0), (7, 6 + by)],
         C("966c6c"))
    # ogon (wachlarz)
    poly(img, [(5, 5 + by), (1, 4 + by), (0, 6 + by), (1, 8 + by), (5, 7 + by)], C("966c6c"))
    px(img, 0, 6 + by, C("4c3e24"))
    blob(img, 8, 6 + by, 4.2, 2.1, BIRD, seed=1, dither=0.3)               # tulow
    rect(img, 7, 7 + by, 10, 7 + by, C("fdcbb0"))                          # jasny brzuch
    blob(img, 12.5, 4.5 + by, 1.9, 1.7, ["ab947a", "fdcbb0", "ffffff"], seed=2, dither=0.2)
    px(img, 14, 5 + by, C("f79617"))                                       # dziob
    px(img, 15, 5 + by, C("cd683d"))
    px(img, 14, 6 + by, C("cd683d"))
    px(img, 13, 4 + by, C("2e222f"))                                       # oko
    # jajko w szponach
    ell(img, 9, 9.6 + by, 1.3, 1.7, C("fdcbb0"))
    px(img, 8, 9 + by, C("ffffff"))
    px(img, 10, 10 + by, C("ab947a"))
    px(img, 8, 8 + by, C("e6904e"))
    px(img, 10, 8 + by, C("e6904e"))
    # blizsze skrzydlo: szerokie, z ciemnymi lotkami
    pts = [(11, 5 + by), (8, tip), (4, tip), (2, tip + 1), (5, 7 + by), (10, 7 + by)]
    poly(img, pts, C("ab947a"))
    line(img, 11, 5 + by, 8, tip, C("fdcbb0"), 1)
    lo, hi = (tip, 7 + by) if tip < 7 + by else (7 + by, tip)
    for k, x in enumerate(range(2, 8)):
        yy = tip + 1 if tip < 6 else tip
        if 0 <= yy < 12 and alpha(img, x, yy):
            px(img, x, yy, C("4c3e24" if k % 2 == 0 else "45293f"))
    return finish(img)


def bird_anims():
    return {"fly": [bird(f) for f in range(4)], "hit": [flash(bird(1))]}


# ================================================================ POCISKI
def arrow():
    img = new(8, 2)
    for x, c0, c1 in ((0, "cd683d", "9e4539"), (1, "cd683d", "9e4539")):
        px(img, x, 0, C(c0))
        px(img, x, 1, C(c1))
    for x in range(2, 6):
        px(img, x, 0, C("ab947a"))
        px(img, x, 1, C("966c6c"))
    px(img, 6, 0, C("c7dcd0"))
    px(img, 6, 1, C("7f708a"))
    px(img, 7, 0, C("ffffff"))
    px(img, 7, 1, C("9babb2"))
    return img


def magic_ball(f):
    img = new(6, 6)
    r = [2.2, 2.6][f]
    for y in range(6):
        for x in range(6):
            d = math.hypot(x + 0.5 - 3, y + 0.5 - 3)
            if d < r * 0.5:
                px(img, x, y, C("eaaded"))
            elif d < r * 0.85:
                px(img, x, y, C("a884f3"))
            elif d < r + 0.6 and bayer(x + f, y) < 0.6:
                px(img, x, y, C("905ea9", 200))
    if f == 1:
        px(img, 1, 1, C("eaaded"))
        px(img, 4, 4, C("a884f3"))
    else:
        px(img, 4, 1, C("eaaded"))
        px(img, 1, 4, C("a884f3"))
    return img


def sphere(ramp, size=6, seed=0):
    img = new(size, size)
    blob(img, size / 2, size / 2, size / 2 - 0.6, size / 2 - 0.6, ramp, seed=seed, dither=0.3)
    return finish(img)


def cannonball():
    img = sphere(["3e3546", "625565", "7f708a"])
    px(img, 2, 2, C("c7dcd0"))
    return img


def coconut_ball():
    img = sphere(["45293f", "4c3e24", "966c6c"], seed=2)
    for x, y in ((2, 2), (3, 2), (2, 3)):
        px(img, x, y, C("2e222f") if (x, y) != (2, 2) else C("ab947a"))
    return img


def egg():
    img = new(4, 5)
    rows = [".xx.", "xyxx", "xxxz", "xxzz", ".zz."]
    cm = {"x": "fdcbb0", "y": "ffffff", "z": "ab947a"}
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in cm:
                px(img, x, y, C(cm[ch]))
    return img


def quill():
    img = new(4, 4)
    px(img, 0, 3, C("4c3e24"))
    px(img, 1, 2, C("966c6c"))
    px(img, 2, 1, C("ab947a"))
    px(img, 3, 0, C("ffffff"))
    px(img, 1, 3, C("45293f"))
    return img


# ================================================================ EFEKTY
FIRE = ["fbff86", "f9c22b", "f79617", "fb6b1d", "ea4f36"]


def explosion(f):
    img = new(32, 32)
    R = [5, 9, 12, 13.5, 14.5][f]
    for y in range(32):
        for x in range(32):
            dx, dy = x + 0.5 - 16, y + 0.5 - 17
            a = math.atan2(dy, dx)
            rr = R * (0.78 + 0.35 * h01(int((a + math.pi) * 3), f, 9))
            d = math.hypot(dx, dy * 1.1) / rr
            if d > 1:
                continue
            n = h01(x // 2, y // 2, 20 + f)
            if f == 0:
                c = "ffffff" if d < 0.5 else "fbff86" if d < 0.8 else "f9c22b"
            elif f == 1:
                c = FIRE[min(4, int(d * 4 + n * 0.8))]
            elif f == 2:
                c = (FIRE[1 + min(3, int(d * 3 + n))] if d < 0.75 else ("625565" if n < 0.5 else "fb6b1d"))
            elif f == 3:
                if n < 0.25 and d < 0.6:
                    c = "f79617"
                else:
                    c = "7f708a" if (dx + dy) < 0 else "625565"
                    if d > 0.85 and bayer(x, y) < 0.4:
                        continue
            else:
                if h01(x, y, 99) < 0.45 + d * 0.4 or n < 0.3:
                    continue
                c = "9babb2" if (dx + dy) < 0 else "7f708a"
            px(img, x, y, C(c))
    if 1 <= f <= 3:  # odlamki
        for i in range(8):
            a = i * math.pi / 4 + 0.3
            r = R + 2 + f
            px(img, int(16 + math.cos(a) * r), int(17 + math.sin(a) * r), C("f9c22b" if f < 3 else "625565"))
    return img


def meteor(img, cx, cy, trail):
    for i in range(trail):  # ogon ognia do gory w lewo
        t = i / max(1, trail)
        x, y = cx - i * 0.6, cy - i
        w = 2.8 * (1 - t) + 0.5
        for yy in range(int(y - w), int(y + w) + 1):
            for xx in range(int(x - w), int(x + w) + 1):
                if (xx + 0.5 - x) ** 2 + (yy + 0.5 - y) ** 2 <= w * w:
                    c = FIRE[min(4, int(t * 5 + h01(xx, yy, i) * 0.8))]
                    px(img, xx, yy, C(c))
    blob(img, cx, cy, 2.8, 2.8, ["45293f", "6e2727", "9e4539", "cd683d"], seed=3, dither=0.3)
    px(img, int(cx) + 1, int(cy) + 1, C("f9c22b"))


def burning_ground(img, f, base_y=30):
    ell(img, 12, base_y - 1, 10, 2.4, C("45293f"))
    for x in range(3, 22):
        h = int(3 + 6 * h01(x // 2, f, 5) * (1 - abs(x - 12) / 11))
        for k in range(h):
            y = base_y - 2 - k
            c = FIRE[min(4, int((h - k) / max(1, h) * 0 + k / max(1, h) * 3 + h01(x, k, f) * 1.2))]
            if k > h - 2 and h01(x, f, 8) < 0.5:
                c = "625565"
            px(img, x, y, C(c))


def fire_rain(f):
    img = new(24, 32)
    if f == 0:
        meteor(img, 14, 8, 8)
    elif f == 1:
        meteor(img, 12, 21, 14)
    elif f == 2:
        ex = explosion(1).resize((16, 16), Image.NEAREST)
        img.alpha_composite(ex, (4, 15))
        for i in range(6):
            a = math.pi + i * math.pi / 5
            px(img, int(12 + math.cos(a) * 10), int(27 + math.sin(a) * 6), C("cd683d"))
    else:
        burning_ground(img, f)
    return img


def dragon_fire12(f):
    img = new(32, 12)
    reach = [18, 28, 32][f]
    for x in range(reach):
        half = 1 + x * 0.16
        for y in range(12):
            dy = y + 0.5 - 6
            wob = (h01(x // 2, f, 5) - 0.5) * 1.6
            if abs(dy - wob * x / 24) > half:
                continue
            k = abs(dy) / half
            r = h01(x, y, 10 + f)
            if x > reach - 4 and r < 0.5:
                continue
            if k < 0.35 and x < reach * 0.7:
                c = "fbff86"
            elif k < 0.65:
                c = "f9c22b"
            elif k < 0.9:
                c = "f79617" if r < 0.6 else "fb6b1d"
            else:
                c = "ea4f36" if r < 0.7 else "625565"
            px(img, x, y, C(c))
    return img


def death_puff(f):
    img = new(16, 16)
    puffs = [(8, 10, 3.0), (5, 9, 2.2), (11, 9, 2.2), (8, 7, 2.4), (6, 12, 1.8), (10, 12, 1.8)]
    grow = [0.6, 1.0, 1.3, 1.45][f]
    rise = [0, 1, 2, 4][f]
    for i, (cx, cy, r) in enumerate(puffs):
        cx2 = 8 + (cx - 8) * grow
        cy2 = 10 + (cy - 10) * grow - rise
        rr = r * grow
        for y in range(16):
            for x in range(16):
                dx, dy = x + 0.5 - cx2, y + 0.5 - cy2
                d = math.hypot(dx, dy) / rr
                if d > 1:
                    continue
                if f == 3 and h01(x, y, 98) < 0.55:
                    continue
                if f == 2 and h01(x, y, 97) < 0.15:
                    continue
                c = "ffffff" if dx + dy < -rr * 0.5 else "c7dcd0" if dx + dy < rr * 0.4 else "9babb2"
                if f == 0 and d < 0.4:
                    c = "ffffff"
                px(img, x, y, C(c))
    return img


# ================================================================ IKONY
def icon_frame(size=24, border=("3e3546", "625565", "9babb2"), bg=("313638", "3e3546")):
    img = new(size, size)
    s = size - 1
    for y in range(size):
        for x in range(size):
            corner = (x in (0, s) and y in (0, s))
            if corner:
                continue
            edge = min(x, y, s - x, s - y)
            if edge == 0:
                c = "2e222f"
            elif edge <= 2:
                c = border[2] if (x < y and edge == 1) or (y <= 2 and x < s - 2 and edge == 1) else (
                    border[1] if edge == 1 else border[0])
                if edge == 1 and (x == s - 1 or y == s - 1):
                    c = border[0]
            else:
                c = bg[0] if (x + y) > s else bg[1]
            px(img, x, y, C(c))
    for x, y in ((1, 1), (s - 1, 1), (1, s - 1), (s - 1, s - 1)):
        px(img, x, y, C("2e222f"))
    return img


def sym_bow(img):
    for i in range(30):  # luk
        a = math.radians(120 + i * 4)
        x, y = 17 + math.cos(a) * 9, 12 + math.sin(a) * 8
        px(img, int(x), int(y), C("cd683d"))
        px(img, int(x) + 1, int(y), C("9e4539"))
    line(img, 13, 5, 13, 19, C("c7dcd0"), 1)
    line(img, 6, 18, 18, 6, C("c7dcd0"), 1)
    px(img, 18, 6, C("ffffff"))
    px(img, 19, 5, C("ffffff"))
    px(img, 17, 5, C("9babb2"))
    px(img, 19, 7, C("9babb2"))
    for d in range(3):
        px(img, 6 + d, 18 - d + 1, C("b33831"))
        px(img, 5 + d, 18 - d, C("b33831"))


def sym_crystal(img, ramp=U.CR_PURPLE):
    U.crystal(img, 12, 12, 7, ramp)


def sym_cannon(img):
    U.cannon_barrel(img, 7, 15, 18, 8, 4)
    ell(img, 9, 17, 3, 3, C("4c3e24"))
    ell(img, 9, 17, 1.4, 1.4, C("966c6c"))
    px(img, 9, 17, C("2e222f"))
    for x, y in ((16, 18), (18, 18), (17, 17)):
        px(img, x, y, C("625565"))


def sym_shield_swords(img):
    line(img, 5, 5, 18, 18, C("c7dcd0"), 1)
    line(img, 18, 5, 5, 18, C("c7dcd0"), 1)
    px(img, 6, 17, C("cd683d"))
    px(img, 17, 17, C("cd683d"))
    rows = ["xxxxxxx", "xxxcxxx", "xxcccxx", "xxxcxxx", "xxxcxxx", ".xxxxx.", "..xxx..", "...x..."]
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch == "x":
                px(img, 9 + i, 8 + j, C("cd683d" if i < 3 else "9e4539"))
            elif ch == "c":
                px(img, 9 + i, 8 + j, C("f9c22b"))


def sym_helmet(img):
    blob(img, 12, 12, 5.5, 6, STEEL, seed=2, dither=0.2)
    rect(img, 8, 11, 15, 11, C("2e222f"))
    rect(img, 11, 13, 12, 16, C("3e3546"))
    line(img, 12, 6, 15, 3, C("4d9be6"), 2)
    px(img, 16, 3, C("4d65b4"))


def sym_leaf(img):
    pts = [(6, 18), (9, 9), (16, 5), (19, 6), (17, 13), (9, 18)]
    poly(img, pts, C("239063"))
    poly(img, [(6, 18), (9, 9), (16, 5), (12, 12)], C("1ebc73"))
    line(img, 6, 18, 17, 7, C("165a4c"), 1)
    line(img, 4, 20, 7, 17, C("966c6c"), 1)
    line(img, 13, 16, 20, 16, C("966c6c"), 1)  # dmuchawka
    px(img, 21, 16, C("c7dcd0"))


def sym_meteor(img):
    meteor(img, 14, 14, 9)


def sym_reinforce(img):
    for ox, c in ((-4, "9e4539"), (4, "cd683d")):
        cx = 12 + ox
        blob(img, cx, 9, 3.2, 3, STEEL, seed=ox + 9, dither=0.2)
        rect(img, cx - 2, 9, cx + 2, 9, C("2e222f"))
        rect(img, cx - 3, 13, cx + 3, 18, C(c))
        px(img, cx, 15, C("f9c22b"))
    line(img, 12, 2, 12, 6, C("fbff86"), 1)
    line(img, 10, 4, 14, 4, C("fbff86"), 1)


def sym_spin(img):
    for i in range(36):
        a = math.radians(i * 10)
        x, y = 12 + math.cos(a) * 8, 12 + math.sin(a) * 6
        if i % 9 < 6:
            px(img, int(x), int(y), C("fbff86" if i % 9 < 3 else "f9c22b"))
    line(img, 12, 4, 12, 16, C("f9c22b"), 2)
    line(img, 11, 4, 11, 15, C("fbff86"), 1)
    rect(img, 9, 16, 14, 16, C("cd683d"))
    line(img, 12, 17, 12, 20, C("6e2727"), 1)


def coin():
    img = new(12, 12)
    blob(img, 6, 6, 4.8, 4.8, GOLD, seed=1, dither=0.2)
    for i in range(16):
        a = i * math.pi / 8
        px(img, int(6 + math.cos(a) * 3.2), int(6 + math.sin(a) * 3.2), C("cd683d"))
    rect(img, 5, 4, 6, 7, C("fbff86"))
    return finish(img)


def heart():
    img = new(12, 12)
    rows = ["..xx..xx..", ".xxxxxxxx.", "xxxxxxxxxx", "xxxxxxxxxx", ".xxxxxxxx.", "..xxxxxx..",
            "...xxxx...", "....xx...."]
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch == "x":
                c = "e83b3b" if i < 5 else "b33831"
                if j > 4:
                    c = "ae2334"
                px(img, 1 + i, 2 + j, C(c))
    px(img, 3, 3, C("f68181"))
    px(img, 4, 3, C("fca790"))
    px(img, 3, 4, C("f68181"))
    return finish(img)


def skull_icon():
    img = new(12, 12)
    blob(img, 6, 5, 4.2, 3.8, ["9babb2", "c7dcd0", "ffffff"], seed=2, dither=0.2)
    rect(img, 4, 8, 8, 9, C("c7dcd0"))
    rect(img, 3, 4, 4, 5, C("2e222f"))
    rect(img, 7, 4, 8, 5, C("2e222f"))
    px(img, 6, 6, C("625565"))
    px(img, 5, 9, C("625565"))
    px(img, 7, 9, C("625565"))
    return finish(img)


TOWER_ICONS = [("archer", sym_bow), ("mage", sym_crystal), ("artillery", sym_cannon),
               ("barracks", sym_shield_swords), ("knight", sym_helmet), ("forest", sym_leaf)]
SKILL_ICONS = [("fire_rain", sym_meteor), ("reinforcements", sym_reinforce), ("hero_spin", sym_spin)]


def make_icon(sym, gold=False):
    img = icon_frame(border=("9e4539", "cd683d", "f9c22b") if gold else ("3e3546", "625565", "9babb2"))
    layer = new(24, 24)
    sym(layer)
    for y in range(24):  # polprzezroczyste piksele -> dithering, zeby ikona zostala w palecie
        for x in range(24):
            r, g, b, a = layer.getpixel((x, y))
            if 0 < a < 255:
                layer.putpixel((x, y), (r, g, b, 255) if bayer(x, y) < a / 400 else (0, 0, 0, 0))
    outline(layer, OUT)
    img.alpha_composite(layer)
    return img


# ================================================================ MAIN


def run(out="."):
    al = os.path.join(out, "assets", "allies")
    en = os.path.join(out, "assets", "enemies")
    pr = os.path.join(out, "assets", "projectiles")
    fx = os.path.join(out, "assets", "effects")
    ui = os.path.join(out, "assets", "ui")
    for d in (al, en, pr, fx, ui):
        os.makedirs(d, exist_ok=True)
    files = []

    def save(folder, name, img, frames, desc):
        check_palette(img, name)
        p = os.path.join(folder, name + ".png")
        img.save(p)
        files.append((os.path.relpath(p, out), img.size, frames, desc))
        return img

    groups = []
    for name, anims, folder in (("soldier", soldier_anims(), al), ("spear_knight", spear_knight_anims(), al),
                                ("hero", hero_anims(), al), ("forest_ranger", ranger_anims(), al),
                                ("desert_bird", bird_anims(), en)):
        row = []
        for an, frames in anims.items():
            sheet = hstrip(frames)
            w, h = frames[0].size
            save(folder, "%s_%s" % (name, an), sheet, len(frames), "%dx%d" % (w, h))
            row.append((an, sheet))
        groups.append((name, row))

    proj = [("arrow", arrow(), 1), ("magic_ball", hstrip([magic_ball(0), magic_ball(1)]), 2),
            ("cannonball", cannonball(), 1), ("coconut", coconut_ball(), 1), ("egg", egg(), 1),
            ("hedgehog_spike", quill(), 1)]
    for n, im, k in proj:
        save(pr, n, im, k, "pocisk")
    groups.append(("pociski", [(n, im) for n, im, _ in proj]))

    eff = [("explosion", hstrip([explosion(f) for f in range(5)]), 5, "32x32"),
           ("fire_rain", hstrip([fire_rain(f) for f in range(4)]), 4, "24x32: meteor, meteor, uderzenie, plonaca ziemia"),
           ("death_puff", hstrip([death_puff(f) for f in range(4)]), 4, "16x16")]
    for n, im, k, d in eff:
        save(fx, n, im, k, d)
    dfire = hstrip([dragon_fire12(f) for f in range(3)])
    save(en, "dragon_fire", dfire, 3, "32x12, lewa krawedz przy pysku")
    groups.append(("efekty", [(n, im) for n, im, _, _ in eff] + [("dragon_fire", dfire)]))

    icons = []
    for n, sym in TOWER_ICONS:
        icons.append(save(ui, "icon_tower_" + n, make_icon(sym), 1, "24x24"))
    for n, sym in SKILL_ICONS:
        icons.append(save(ui, "icon_skill_" + n, make_icon(sym, gold=True), 1, "24x24"))
    small = [save(ui, "icon_gold", coin(), 1, "12x12"), save(ui, "icon_life", heart(), 1, "12x12"),
             save(ui, "icon_wave", skull_icon(), 1, "12x12")]
    groups.append(("ikony", [("i", im) for im in icons]))
    groups.append(("pasek", [("i", im) for im in small]))

    G.overview(groups, scale=4).save(os.path.join(out, "overview_allies_fx.png"))
    print("Etap 4, zapisane pliki:")
    for p, size, n, desc in files:
        print("  %-44s %3dx%-3d  %d kl.  %s" % (p, size[0], size[1], n, desc))
    return files


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".")
    run(ap.parse_args().out)

#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - generator grafik pixel art, ETAP 2 i 3:
wrogowie (wszyscy patrza W PRAWO), 25 wiez, statek.

Uruchamia go tools/gen_art.py na koncu, ale mozna tez osobno:
    python tools/gen_units.py            # zapis do ./assets i ./preview_*.png
    python tools/gen_units.py --out X
Wymaga gen_art.py w tym samym katalogu (wspolne narzedzia i paleta).
"""
import argparse
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as G  # noqa: E402
from gen_art import (C, new, px, alpha, h01, bayer, outline, shadow_ellipse, stack,  # noqa: E402
                     blob, thick_line, hstrip, check_palette, SHADOW, T)
from PIL import Image  # noqa: E402

OUT = C("2e222f")

# ================================================================ narzedzia


def rect(img, x0, y0, x1, y1, col):
    for y in range(int(y0), int(y1) + 1):
        for x in range(int(x0), int(x1) + 1):
            px(img, x, y, col)


def ell(img, cx, cy, rx, ry, col):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1:
                px(img, x, y, col)


def _inside(pts, x, y):
    c = False
    n = len(pts)
    for i in range(n):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % n]
        if (y1 > y) != (y2 > y) and x < (x2 - x1) * (y - y1) / (y2 - y1) + x1:
            c = not c
    return c


def poly(img, pts, col):
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)) - 1, int(max(ys)) + 2):
        for x in range(int(min(xs)) - 1, int(max(xs)) + 2):
            if _inside(pts, x + 0.5, y + 0.5):
                px(img, x, y, col)


def line(img, x0, y0, x1, y1, col, w=1.0):
    thick_line(img, x0, y0, x1, y1, w, col)


def finish(img, shadow=None, out=OUT):
    outline(img, out)
    if shadow:
        sh = new(*img.size)
        shadow_ellipse(sh, *shadow)
        return stack(sh, img)
    return img


def flash(img, dx=-1):
    """Klatka trafienia: biala sylwetka, odrzut o 1 px."""
    res = new(*img.size)
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                continue
            if a < 255 or (r, g, b, a) == OUT:
                col = (r, g, b, a)
            else:
                lum = 0.299 * r + 0.587 * g + 0.114 * b
                col = C("ffffff") if lum > 85 else C("c7dcd0")
            px(res, x + (dx if a == 255 else 0), y, col)
    return res


def leg_off(f, ph, amp=2.0, n=4):
    return int(round(amp * math.sin(2 * math.pi * f / n + ph)))


def leg_lift(f, ph, n=4):
    return 1 if math.cos(2 * math.pi * f / n + ph) > 0.5 else 0


# ================================================================ WROGOWIE
# ---------------------------------------------------------------- wilk 20x14
WOLF = ["3e3546", "625565", "7f708a", "9babb2"]


def wolf(pose):
    img = new(20, 14)
    bx, by = pose.get("x", 0), pose.get("bob", 0)
    hd, mouth = pose.get("head", 0), pose.get("mouth", 0)
    legs, lifts = pose.get("legs", (0, 0, 0, 0)), pose.get("lift", (0, 0, 0, 0))

    def leg(hx, dx, lift, col):
        line(img, hx + bx, 9 + by, hx + bx + dx, 12 - lift, C(col), 1.3)
        px(img, hx + bx + dx + 1, 12 - lift, C(col))

    leg(7, legs[1], lifts[1], "3e3546")
    leg(13, legs[3], lifts[3], "3e3546")
    line(img, 4 + bx, 7 + by, 1 + bx, 4 + by, C("625565"), 2.2)   # ogon
    px(img, 0 + bx, 3 + by, C("9babb2"))
    blob(img, 8.5 + bx, 7.5 + by, 5.8, 3.0, WOLF, seed=1, dither=0.3)
    blob(img, 12.5 + bx, 6.5 + by, 2.8, 3.2, WOLF, seed=2, dither=0.3)
    for x in range(6, 12):
        px(img, x + bx, 10 + by, C("9babb2"))
    leg(6, legs[0], lifts[0], "625565")
    leg(12, legs[2], lifts[2], "625565")
    hx, hy = 14 + bx, 4 + by + hd
    blob(img, hx, hy + 0.5, 2.6, 2.3, WOLF, seed=3, dither=0.3)
    rect(img, hx + 1, hy, hx + 3, hy + 1, C("7f708a"))
    px(img, hx + 1, hy, C("9babb2"))
    px(img, hx + 2, hy, C("9babb2"))
    px(img, hx + 4, hy, C("2e222f"))
    if mouth:
        rect(img, hx + 1, hy + 2, hx + 3, hy + 2, C("6e2727"))
        px(img, hx + 3, hy + 2, C("ffffff"))
        rect(img, hx + 1, hy + 3, hx + 3, hy + 3, C("625565"))
    px(img, hx - 1, hy - 2, C("625565"))
    px(img, hx - 1, hy - 3, C("3e3546"))
    px(img, hx, hy - 2, C("7f708a"))
    px(img, hx, hy, C("f9c22b"))
    return finish(img, shadow=(10, 13, 7, 1.2))


def wolf_anims():
    ph = (0, math.pi / 2, math.pi, 3 * math.pi / 2)
    walk = [wolf({"legs": tuple(leg_off(f, p) for p in ph), "lift": tuple(leg_lift(f, p) for p in ph),
                  "bob": [0, -1, 0, -1][f]}) for f in range(4)]
    attack = [wolf({"bob": 1, "head": 1, "legs": (-1, -1, 1, 1)}),
              wolf({"x": 2, "mouth": 1, "legs": (-2, -1, 2, 2), "lift": (0, 0, 1, 1)}),
              wolf({"x": 1, "head": 1, "legs": (-1, 0, 1, 1)})]
    return {"walk": walk, "attack": attack, "hit": [flash(wolf({}))]}


# ---------------------------------------------------------------- nietoperz 16x12
BAT = ["45293f", "6b3e75", "905ea9"]


def bat(f):
    img = new(16, 12)
    tip = [0, 3, 9, 5][f]       # wysokosc koncow skrzydel
    by = [1, 0, -1, 0][f]       # cialo idzie w przeciwna strone niz skrzydla
    for side in (-1, 1):
        sx = 8 + side * 1.2
        ex = 8 + side * 7.4
        pts = [(sx, 4.5 + by), (ex, tip), (ex - side * 0.6, tip + 2.5),
               (8 + side * 5.2, 7.2 + by), (8 + side * 4.4, 6.5 + by), (8 + side * 3.0, 8.5 + by), (sx, 7.5 + by)]
        poly(img, pts, C("6b3e75"))
        line(img, sx, 4.5 + by, ex, tip, C("905ea9"), 1)                     # kosc ramienia
        line(img, (sx + ex) / 2, (4.5 + by + tip) / 2, 8 + side * 4.6, 7 + by, C("45293f"), 1)
    blob(img, 8, 6.5 + by, 2.2, 2.8, BAT, seed=1, dither=0.3)
    px(img, 7, 3 + by, C("6b3e75"))
    px(img, 6, 2 + by, C("45293f"))
    px(img, 9, 3 + by, C("6b3e75"))
    px(img, 10, 2 + by, C("45293f"))
    px(img, 8, 5 + by, C("e83b3b"))
    px(img, 9, 5 + by, C("e83b3b"))
    px(img, 9, 7 + by, C("c7dcd0"))
    px(img, 7, 9 + by, C("45293f"))
    px(img, 9, 9 + by, C("45293f"))
    return finish(img)


def bat_anims():
    fly = [bat(f) for f in range(4)]
    return {"fly": fly, "hit": [flash(bat(1))]}


# ---------------------------------------------------------------- smok 48x32
DRAGON = ["45293f", "6e2727", "9e4539", "cd683d"]
BELLY = ["cd683d", "e6904e", "fbb954"]


def dragon(f, head=0, mouth=0, flame=0):
    img = new(48, 32)
    tips = [(16, 0), (5, 7), (10, 30), (6, 15)]
    by = [1, 0, -1, 0][f]
    sx, sy = 24, 13 + by

    def wing(dx, dy, mem, bone, scale):
        tx, ty = tips[f]
        tx = sx + (tx - sx) * scale + dx
        ty = sy + (ty - sy) * scale + dy
        b1 = (13 + dx, 17 + by + dy)
        b2 = (29 + dx, 15 + by + dy)
        m1 = (tx * 0.55 + b1[0] * 0.45, ty * 0.55 + b1[1] * 0.45)
        m2 = (tx * 0.25 + b1[0] * 0.75, ty * 0.25 + b1[1] * 0.75)
        pts = [(sx + dx, sy + dy), (tx, ty), (m1[0] + 1, m1[1] + 1.5), m1, (m2[0] + 1, m2[1] + 1.5), m2,
               b1, b2]
        poly(img, pts, C(mem))
        line(img, sx + dx, sy + dy, tx, ty, C(bone), 1.5)
        line(img, (sx + dx + tx) / 2, (sy + dy + ty) / 2, m1[0], m1[1], C(bone), 1)
        line(img, sx + dx + (tx - sx) * 0.3, sy + dy + (ty - sy) * 0.3, m2[0], m2[1], C(bone), 1)

    wing(3, -2, "45293f", "6e2727", 0.85)                           # dalsze skrzydlo
    pts = [(14, 18), (9, 20), (5, 22), (2, 22)]                     # ogon
    for i, ((x0, y0), (x1, y1)) in enumerate(zip(pts, pts[1:])):
        line(img, x0, y0 + by, x1, y1 + by, C("9e4539"), 4 - i * 1.2)
    poly(img, [(0, 20 + by), (3, 21 + by), (0, 24 + by)], C("6e2727"))  # kolec ogona
    line(img, 18, 21 + by, 17, 26 + by, C("6e2727"), 2)              # tylna lapa
    px(img, 18, 26 + by, C("c7dcd0"))
    blob(img, 22, 17.5 + by, 10, 4.6, DRAGON, seed=1, dither=0.3)
    for x in range(15, 30):                                          # brzuch
        if alpha(img, x, 20 + by):
            px(img, x, 20 + by, C(BELLY[1] if x % 2 else BELLY[0]))
            px(img, x, 21 + by, C(BELLY[0]))
    line(img, 28, 21 + by, 29, 24 + by, C("9e4539"), 2)              # przednia lapa
    px(img, 30, 24 + by, C("c7dcd0"))
    hx, hy = 38 + head, 10 + by - head
    line(img, 29, 16 + by, hx - 2, hy + 1, C("9e4539"), 4)           # szyja
    line(img, 30, 18 + by, hx - 1, hy + 3, C("e6904e"), 1.2)
    blob(img, hx, hy, 4.0, 3.1, DRAGON, seed=3, dither=0.3)
    rect(img, hx + 2, hy, hx + 6, hy + 1, C("cd683d"))                # pysk
    rect(img, hx + 2, hy - 1, hx + 5, hy - 1, C("e6904e"))
    if mouth:
        rect(img, hx + 2, hy + 2, hx + 6, hy + 2, C("45293f"))
        rect(img, hx + 2, hy + 3, hx + 5, hy + 3, C("9e4539"))
        px(img, hx + 5, hy + 2, C("ffffff"))
    else:
        rect(img, hx + 2, hy + 2, hx + 5, hy + 2, C("9e4539"))
    px(img, hx + 6, hy, C("45293f"))
    px(img, hx + 1, hy - 1, C("f9c22b"))                              # oko
    line(img, hx - 1, hy - 2, hx - 5, hy - 5, C("c7dcd0"), 1)        # rogi
    line(img, hx - 2, hy - 1, hx - 6, hy - 2, C("9babb2"), 1)
    for x in range(14, 32, 3):                                       # grzebien
        px(img, x, int(13 + by + (abs(x - 22) / 4)), C("6e2727"))
    if flame:
        fx, fy = hx + 7, hy + 2
        for i in range(flame * 3):
            for dy in range(-i // 3 - 1, i // 3 + 2):
                xx, yy = fx + i, fy + dy
                if xx < 48:
                    c = "fbff86" if abs(dy) < i / 5 else ("f9c22b" if abs(dy) <= i / 4 else "fb6b1d")
                    px(img, xx, yy, C(c))
    wing(0, 0, "7a3045", "e6904e", 1.0)                              # blizsze skrzydlo
    if head < 0:
        px(img, hx - 2, hy + 3, C("f79617"))                         # zar w gardle
        px(img, hx - 3, hy + 4, C("f9c22b"))
    return finish(img)


def dragon_fire(f):
    """Strumien ognia 32x16 - efekt doklejany do pyska (poczatek po lewej, srodek wysokosci)."""
    img = new(32, 16)
    reach = [18, 28, 32][f]
    for x in range(reach):
        half = 1 + x * 0.22
        for y in range(16):
            dy = y + 0.5 - 8
            wob = (h01(x // 2, f, 5) - 0.5) * 2
            if abs(dy - wob * x / 20) > half:
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


def dragon_anims():
    fly = [dragon(f) for f in range(4)]
    breathe = [dragon(1, head=-1), dragon(1, head=1, mouth=1, flame=1), dragon(2, head=1, mouth=1, flame=2)]
    return {"fly": fly, "breathe": breathe, "hit": [flash(dragon(1))]}


# ---------------------------------------------------------------- jezowiec 20x16
SPIKE = ["45293f", "4c3e24", "966c6c"]
SNOUT = ["966c6c", "ab947a", "fca790"]


def hedgehog(f):
    img = new(20, 16)
    by = [0, -1, 0, -1][f]
    cx, cy = 8, 10 + by
    for i in range(13):  # kolce na luku
        a = math.pi + i * math.pi / 12
        jig = 0.6 if (i + f) % 2 else 0
        r0x, r0y = 6.5, 5.5
        x0, y0 = cx + math.cos(a) * r0x, cy + math.sin(a) * r0y
        x1, y1 = cx + math.cos(a) * (r0x + 2.6 + jig), cy + math.sin(a) * (r0y + 2.6 + jig)
        line(img, x0, y0, x1, y1, C("4c3e24"), 1.2)
        px(img, int(x1), int(y1), C("c7dcd0"))
    blob(img, cx, cy, 7, 5.5, SPIKE, seed=2, dither=0.3, clump=0.3)
    for y in range(int(cy), 16):  # plaski spod
        for x in range(0, 20):
            if y > cy + 1.5:
                img.putpixel((x, y), (0, 0, 0, 0))
    blob(img, 14, 11.5 + by, 3.2, 2.2, SNOUT, seed=3, dither=0.3)
    px(img, 17, 11 + by, C("2e222f"))
    px(img, 14, 10 + by, C("2e222f"))
    fo = [(1, 0), (0, 1), (-1, 0), (0, 1)][f]
    for x0, d in ((4, fo[0]), (11, fo[1]), (6, -fo[0]), (13, -fo[1])):
        px(img, x0 + d, 12 + by, C("966c6c"))
        px(img, x0 + d, 13, C("4c3e24"))
    return finish(img, shadow=(10, 15, 7, 1.0))


def hedgehog_ball(f):
    img = new(20, 16)
    cx, cy, r = 10, 8.5, 5.5
    for i in range(14):
        a = i * 2 * math.pi / 14 + f * math.pi / 7
        x0, y0 = cx + math.cos(a) * (r - 0.5), cy + math.sin(a) * (r - 0.5)
        x1, y1 = cx + math.cos(a) * (r + 2.3), cy + math.sin(a) * (r + 2.3)
        if y1 > 14:
            continue
        line(img, x0, y0, x1, y1, C("4c3e24"), 1.2)
        px(img, int(x1), int(y1), C("c7dcd0"))
    blob(img, cx, cy, r, r, SPIKE, seed=5 + f, dither=0.3, clump=0.4)
    a = f * math.pi / 2  # brzuch/pysk przesuwajacy sie po obwodzie
    blob(img, cx + math.cos(a) * 2.5, cy + math.sin(a) * 2.5, 1.8, 1.8, SNOUT, seed=6, dither=0.2)
    for i in range(2):  # kurz za kula
        px(img, 2 - i * 2 + (f % 2), 13 - i, C("ab947a"))
    return finish(img, shadow=(10, 15, 6, 1.0))


def hedgehog_anims():
    return {"walk": [hedgehog(f) for f in range(4)], "roll": [hedgehog_ball(f) for f in range(4)],
            "hit": [flash(hedgehog(0))]}


# ---------------------------------------------------------------- humanoidy


def humanoid(spec, pose):
    W, H = spec["size"]
    img = new(W, H)
    cx = spec["cx"]
    foot_y = H - 2
    bob, lean = pose.get("bob", 0), pose.get("lean", 0)
    hip_y = foot_y - spec["leg"] + bob
    sh_y = hip_y - spec["torso"]
    sh_x = cx + lean
    fl, bl = pose.get("legs", (0, 0))
    lf, lb = pose.get("lift", (0, 0))
    lw = spec["leg_w"]

    if spec.get("cape"):
        spec["cape"](img, sh_x, sh_y, hip_y, foot_y, pose)
    ab = math.radians(pose.get("arm_back", 0))
    hb = (sh_x - 1 + math.sin(ab) * spec["arm"], sh_y + 1 + math.cos(ab) * spec["arm"])
    line(img, sh_x - 1, sh_y + 1, hb[0], hb[1], C(spec["limb_dark"]), spec["arm_w"])
    if spec.get("offhand"):
        spec["offhand"](img, hb, pose)
    line(img, cx - 1, hip_y, cx + bl - 1, foot_y - lb, C(spec["leg_dark"]), lw)
    rect(img, cx + bl - 1, foot_y - lb, cx + bl + 1, foot_y - lb, C(spec["boot"][0]))
    if spec.get("robe"):
        spec["robe"](img, sh_x, sh_y, cx, foot_y, pose)
    else:
        line(img, cx + 1, hip_y, cx + fl + 1, foot_y - lf, C(spec["leg_col"]), lw)
        rect(img, cx + fl + 1, foot_y - lf, cx + fl + 2, foot_y - lf, C(spec["boot"][1]))
        tx, ty = (sh_x + cx) / 2, (sh_y + hip_y) / 2
        blob(img, tx, ty, spec["torso_w"] / 2, (hip_y - sh_y) / 2 + 1, spec["torso_ramp"], seed=2, dither=0.3)
        if spec.get("belt"):
            rect(img, int(tx - spec["torso_w"] / 2) + 1, hip_y - 1, int(tx + spec["torso_w"] / 2) - 1, hip_y - 1,
                 C(spec["belt"]))
        if spec.get("torso_fn"):
            spec["torso_fn"](img, sh_x, sh_y, cx, hip_y, pose)
    hr = spec["head"]
    hx, hy = sh_x + spec.get("head_dx", 1), sh_y - hr + spec.get("neck", 1) + pose.get("head_dy", 0)
    blob(img, hx, hy, hr, hr, spec["head_ramp"], seed=4, dither=0.3)
    spec["head_fn"](img, int(round(hx)), int(round(hy)), pose)
    af = math.radians(pose.get("arm_front", 0))
    sx, sy = sh_x + 1, sh_y + 1
    hand = (sx + math.sin(af) * spec["arm"], sy + math.cos(af) * spec["arm"])
    if spec.get("weapon"):
        spec["weapon"](img, hand, pose.get("weapon", 45), pose)
    line(img, sx, sy, hand[0], hand[1], C(spec["limb"]), spec["arm_w"])
    if spec.get("shoulder"):
        spec["shoulder"](img, sx, sy)
    px(img, int(round(hand[0])), int(round(hand[1])), C(spec["hand"]))
    res = finish(img, shadow=(cx + 1, H - 1, spec["shadow_r"], 1.2))
    if pose.get("glow"):
        res = spec["glow_fn"](res, pose)
    return res


def wdir(deg):
    a = math.radians(deg)
    return math.sin(a), -math.cos(a)


def make_blade(length, blade, edge, guard="9babb2", grip="4c3e24", width=1.0):
    def fn(img, hand, deg, pose):
        dx, dy = wdir(deg)
        hx, hy = hand
        line(img, hx - dx * 1.5, hy - dy * 1.5, hx, hy, C(grip), 1)
        gx, gy = hx + dx, hy + dy
        line(img, gx - dy * 1.5, gy + dx * 1.5, gx + dy * 1.5, gy - dx * 1.5, C(guard), 1)
        line(img, gx + dx, gy + dy, hx + dx * length, hy + dy * length, C(blade), width)
        px(img, int(round(hx + dx * (length - 1))), int(round(hy + dy * (length - 1))), C(edge))
    return fn


def make_axe(length, head_r, steel=("9babb2", "c7dcd0"), haft="966c6c"):
    def fn(img, hand, deg, pose):
        dx, dy = wdir(deg)
        hx, hy = hand
        line(img, hx - dx * 2, hy - dy * 2, hx + dx * length, hy + dy * length, C(haft), 1.2)
        ex, ey = hx + dx * (length - 1), hy + dy * (length - 1)
        nx, ny = dy, -dx  # ostrze po stronie "przodu" kierunku
        pts = [(ex - dx * head_r, ey - dy * head_r), (ex + nx * head_r * 1.4 - dx * head_r * 1.2,
                                                       ey + ny * head_r * 1.4 - dy * head_r * 1.2),
               (ex + nx * head_r * 1.6 + dx * head_r * 0.6, ey + ny * head_r * 1.6 + dy * head_r * 0.6),
               (ex + dx * head_r * 0.8, ey + dy * head_r * 0.8)]
        poly(img, pts, C(steel[0]))
        line(img, pts[1][0], pts[1][1], pts[2][0], pts[2][1], C(steel[1]), 1)
    return fn


def walk_poses(n=4, amp=2.5, arm=25, weapon=40):
    poses = []
    for f in range(n):
        s = math.sin(2 * math.pi * f / n)
        poses.append({"legs": (int(round(amp * s)), int(round(-amp * s))),
                      "lift": (1 if f == 3 else 0, 1 if f == 1 else 0),
                      "bob": [0, -1, 0, -1][f], "arm_front": -arm * s, "arm_back": arm * s,
                      "weapon": weapon})
    return poses


ATTACK = [
    {"arm_front": 200, "weapon": -40, "lean": -1, "legs": (1, -1), "arm_back": 20},
    {"arm_front": 100, "weapon": 100, "lean": 1, "legs": (3, -2), "arm_back": -30},
    {"arm_front": 45, "weapon": 160, "lean": 1, "legs": (2, -2), "arm_back": -20, "bob": 1},
]


def humanoid_anims(spec, attack=ATTACK, walk_weapon=40, extra=None):
    walk = [humanoid(spec, p) for p in walk_poses(weapon=walk_weapon)]
    att = [humanoid(spec, dict(p, **(extra or {}))) for p in attack]
    hit = [flash(humanoid(spec, {"weapon": walk_weapon}))]
    return {"walk": walk, "attack": att, "hit": hit}


# goblin 16x16 ---------------------------------------------------
GOB = ["374e4a", "676633", "a2a947"]
RAGS = ["45293f", "4c3e24", "966c6c"]


def goblin_head(img, hx, hy, pose):
    line(img, hx - 2, hy - 1, hx - 5, hy - 3, C("676633"), 1.2)
    px(img, hx - 5, hy - 3, C("a2a947"))
    px(img, hx + 1, hy - 1, C("f9c22b"))
    px(img, hx + 3, hy, C("a2a947"))
    px(img, hx + 2, hy + 1, C("ffffff"))


GOBLIN = {"size": (16, 16), "cx": 7, "leg": 4, "torso": 4, "head": 3.2, "head_dx": 1.5, "leg_w": 1.4, "arm": 3.5,
          "arm_w": 1.3, "torso_w": 5, "torso_ramp": RAGS, "head_ramp": GOB, "head_fn": goblin_head,
          "limb": "a2a947", "limb_dark": "374e4a", "leg_col": "a2a947", "leg_dark": "374e4a",
          "boot": ("45293f", "4c3e24"), "hand": "a2a947", "belt": "966c6c", "shadow_r": 5,
          "weapon": make_blade(4, "9babb2", "c7dcd0", grip="4c3e24")}

# ork 20x24 ------------------------------------------------------
ORC = ["374e4a", "547e64", "92a984"]
STEEL = ["3e3546", "625565", "7f708a", "9babb2"]


def orc_head(img, hx, hy, pose):
    for y in range(hy - 4, hy):
        for x in range(hx - 4, hx + 4):
            if alpha(img, x, y) and (x + 0.5 - hx) ** 2 / 14 + (y + 0.5 - hy) ** 2 / 12 <= 1:
                px(img, x, y, C("7f708a" if x < hx else "625565"))
    rect(img, hx - 3, hy - 1, hx + 3, hy - 1, C("3e3546"))
    px(img, hx - 1, hy - 3, C("c7dcd0"))
    px(img, hx + 1, hy, C("3e3546"))
    px(img, hx + 1, hy + 1, C("3e3546"))
    px(img, hx + 2, hy, C("e83b3b"))
    px(img, hx + 3, hy + 2, C("c7dcd0"))
    px(img, hx + 3, hy + 1, C("c7dcd0"))


def orc_shoulder(img, sx, sy):
    blob(img, sx, sy, 2.6, 2.0, STEEL, seed=8, dither=0.2)


ORCSPEC = {"size": (20, 24), "cx": 9, "leg": 7, "torso": 7, "head": 3.4, "head_dx": 2, "neck": 0, "leg_w": 2.4, "arm": 5.5,
           "arm_w": 2.2, "torso_w": 8, "torso_ramp": STEEL, "head_ramp": ORC, "head_fn": orc_head,
           "limb": "547e64", "limb_dark": "374e4a", "leg_col": "966c6c", "leg_dark": "4c3e24",
           "boot": ("3e3546", "45293f"), "hand": "547e64", "belt": "4c3e24", "shadow_r": 7,
           "shoulder": orc_shoulder, "weapon": make_axe(7, 2.2)}

# szaman 18x24 ---------------------------------------------------
ROBE = ["45293f", "6b3e75", "905ea9"]


def shaman_head(img, hx, hy, pose):
    for y in range(hy - 3, hy + 2):  # kaptur z tylu
        for x in range(hx - 4, hx):
            if alpha(img, x, y):
                px(img, x, y, C("45293f"))
    rect(img, hx, hy - 2, hx + 2, hy + 2, C("c7dcd0"))
    px(img, hx + 2, hy - 2, C("ffffff"))
    px(img, hx + 1, hy - 1, C("e83b3b"))
    px(img, hx + 1, hy + 1, C("625565"))
    px(img, hx + 3, hy, C("9babb2"))
    line(img, hx - 1, hy - 3, hx - 3, hy - 7, C("ea4f36"), 1)
    line(img, hx, hy - 3, hx, hy - 7, C("f9c22b"), 1)
    line(img, hx - 2, hy - 2, hx - 5, hy - 5, C("30e1b9"), 1)


def shaman_robe(img, sh_x, sh_y, cx, foot_y, pose):
    sway = pose.get("legs", (0, 0))[0] * 0.5
    pts = [(sh_x - 2.5, sh_y), (sh_x + 2.5, sh_y), (cx + 4 + sway, foot_y), (cx - 4 + sway, foot_y)]
    poly(img, pts, C("6b3e75"))
    for y in range(int(sh_y), foot_y + 1):
        for x in range(0, img.width):
            if img.getpixel((x, y)) == C("6b3e75"):
                if alpha(img, x - 1, y) == 0 or img.getpixel((x - 1, y)) not in (C("6b3e75"), C("905ea9")):
                    px(img, x, y, C("905ea9"))
                elif alpha(img, x + 1, y) == 0:
                    px(img, x, y, C("45293f"))
    rect(img, cx - 3 + sway, foot_y - 3, cx + 3 + sway, foot_y - 3, C("cd683d"))  # lamowka
    px(img, int(cx + 2 + sway), foot_y + 1, C("4c3e24"))
    px(img, int(cx + 3 + sway), foot_y + 1, C("4c3e24"))


def staff(img, hand, deg, pose):
    dx, dy = wdir(deg)
    hx, hy = hand
    line(img, hx - dx * 5, hy - dy * 5, hx + dx * 7, hy + dy * 7, C("ab947a"), 1.3)
    tx, ty = hx + dx * 8, hy + dy * 8
    rect(img, tx - 1, ty - 1, tx + 1, ty, C("c7dcd0"))
    px(img, int(tx), int(ty), C("2e222f"))
    px(img, int(tx) - 1, int(ty) - 2, C("30e1b9"))
    px(img, int(tx), int(ty) - 2, C("8ff8e2"))
    g = max(1, pose.get("orb", 1))
    for i in range(g * 3):
        a = i * 2.1 + g
        px(img, int(tx + math.cos(a) * g), int(ty - 2 + math.sin(a) * g), C("30e1b9" if i % 2 else "8ff8e2"))


SHAMAN = {"size": (18, 24), "cx": 8, "leg": 6, "torso": 7, "head": 3.0, "leg_w": 1.2, "arm": 5,
          "arm_w": 1.6, "torso_w": 6, "torso_ramp": ROBE, "head_ramp": ORC, "head_fn": shaman_head,
          "limb": "6b3e75", "limb_dark": "45293f", "leg_col": "45293f", "leg_dark": "45293f",
          "boot": ("4c3e24", "4c3e24"), "hand": "547e64", "shadow_r": 6, "robe": shaman_robe,
          "weapon": staff}
SHAMAN_ATTACK = [
    {"arm_front": 160, "weapon": -5, "orb": 1, "arm_back": 30, "lean": -1},
    {"arm_front": 120, "weapon": 30, "orb": 3, "arm_back": 60, "lean": 0},
    {"arm_front": 95, "weapon": 70, "orb": 2, "arm_back": 40, "lean": 1},
]

# boss-wodz 32x32 ------------------------------------------------
BRONZE = ["45293f", "9e4539", "cd683d", "e6904e"]
FUR = ["4c3e24", "966c6c", "ab947a"]


def boss_head(img, hx, hy, pose):
    for y in range(hy - 5, hy):
        for x in range(hx - 5, hx + 5):
            if alpha(img, x, y) and (x + 0.5 - hx) ** 2 / 22 + (y + 0.5 - hy) ** 2 / 20 <= 1:
                px(img, x, y, C("cd683d" if x < hx else "9e4539"))
    rect(img, hx - 4, hy - 1, hx + 4, hy - 1, C("45293f"))
    for pts, c in (([(hx - 3, hy - 3), (hx - 6, hy - 6), (hx - 5, hy - 9)], "9babb2"),
                   ([(hx + 2, hy - 4), (hx + 5, hy - 6), (hx + 4, hy - 8)], "c7dcd0")):
        line(img, *pts[0], *pts[1], C(c), 2)
        line(img, *pts[1], *pts[2], C(c), 1.4)
    px(img, hx + 2, hy, C("e83b3b"))
    px(img, hx + 3, hy, C("e83b3b"))
    px(img, hx + 4, hy + 2, C("c7dcd0"))
    px(img, hx + 4, hy + 1, C("c7dcd0"))
    rect(img, hx + 1, hy + 3, hx + 3, hy + 3, C("313638"))


def boss_cape(img, sh_x, sh_y, hip_y, foot_y, pose):
    fl = pose.get("legs", (0, 0))[1] * 0.5
    poly(img, [(sh_x - 4, sh_y - 1), (sh_x + 3, sh_y - 1), (sh_x - 1, foot_y - 2), (sh_x - 8 + fl, foot_y - 1)],
         C("966c6c"))
    for y in range(sh_y - 1, foot_y):
        for x in range(img.width):
            if img.getpixel((x, y)) == C("966c6c") and (x + y) % 4 == 0:
                px(img, x, y, C("4c3e24"))
    rect(img, sh_x - 5, sh_y - 1, sh_x + 3, sh_y, C("ab947a"))


def boss_shoulder(img, sx, sy):
    blob(img, sx, sy, 3.6, 2.8, BRONZE, seed=9, dither=0.2)
    px(img, int(sx), int(sy - 3), C("c7dcd0"))


BOSS = {"size": (32, 32), "cx": 14, "leg": 8, "torso": 9, "head": 4.2, "head_dx": 2.5, "neck": 0, "leg_w": 3.4, "arm": 7.5,
        "arm_w": 3.2, "torso_w": 12, "torso_ramp": BRONZE, "head_ramp": ORC, "head_fn": boss_head,
        "limb": "547e64", "limb_dark": "374e4a", "leg_col": "966c6c", "leg_dark": "4c3e24",
        "boot": ("45293f", "4c3e24"), "hand": "547e64", "belt": "4c3e24", "shadow_r": 10,
        "cape": boss_cape, "shoulder": boss_shoulder,
        "weapon": make_axe(11, 3.4, steel=("9babb2", "c7dcd0"), haft="4c3e24")}

# magiczny rycerz 20x28 --------------------------------------------
KNIGHT = ["3e3546", "625565", "7f708a", "9babb2"]
AURAS = {"purple": ("a884f3", "905ea9", "eaaded"), "blue": ("8fd3ff", "4d9be6", "ffffff")}


def knight_head_fn(glow):
    def fn(img, hx, hy, pose):
        rect(img, hx, hy - 1, hx + 3, hy, C("2e222f"))     # przylbica
        px(img, hx + 1, hy - 1, C(glow))
        px(img, hx + 2, hy - 1, C(glow))
        px(img, hx + 3, hy - 1, C("eaaded" if glow == "a884f3" else "ffffff"))
        px(img, hx + 2, hy + 1, C("2e222f"))
        px(img, hx - 1, hy - 2, C("c7dcd0"))
        px(img, hx, hy - 3, C("c7dcd0"))
        line(img, hx - 1, hy - 4, hx - 5, hy - 2, C("905ea9"), 1.6)  # pioropusz
        px(img, hx - 6, hy - 1, C("6b3e75"))
        px(img, hx - 5, hy, C("6b3e75"))
    return fn


def knight_cape(img, sh_x, sh_y, hip_y, foot_y, pose):
    fl = pose.get("legs", (0, 0))[1] * 0.6
    poly(img, [(sh_x - 3, sh_y - 1), (sh_x + 1, sh_y - 1), (sh_x, foot_y - 2), (sh_x - 8 + fl, foot_y - 1)],
         C("6b3e75"))
    line(img, sh_x - 3, sh_y, sh_x - 7 + fl, foot_y - 2, C("905ea9"), 1)
    line(img, sh_x - 1, sh_y + 2, sh_x - 3 + fl, foot_y - 2, C("45293f"), 1)


def knight_chest(img, sh_x, sh_y, cx, hip_y, pose):
    tx = int(round((sh_x + cx) / 2))
    px(img, tx - 1, sh_y + 2, C("c7dcd0"))
    px(img, tx - 2, sh_y + 3, C("c7dcd0"))
    px(img, tx + 1, sh_y + 3, C("905ea9"))
    px(img, tx + 1, sh_y + 4, C("6b3e75"))


def knight_shoulder(img, sx, sy):
    blob(img, sx, sy, 2.4, 1.8, KNIGHT, seed=7, dither=0.2)


def aura_fn(name):
    inner, outer, spark = AURAS[name]

    def fn(img, pose):
        w, h = img.size
        f = pose.get("frame", 0)
        solid = [[img.getpixel((x, y))[3] == 255 for x in range(w)] for y in range(h)]
        glow = new(w, h)
        for y in range(h):
            for x in range(w):
                if solid[y][x]:
                    continue
                d = 9.0
                for yy in range(max(0, y - 2), min(h, y + 3)):
                    for xx in range(max(0, x - 2), min(w, x + 3)):
                        if solid[yy][xx]:
                            d = min(d, math.hypot(xx - x, yy - y))
                if d <= 1.0 and bayer(x + f, y) < 0.8:
                    px(glow, x, y, C(inner, 190))
                elif d <= 2.3 and bayer(x, y + f * 2) < 0.35:
                    px(glow, x, y, C(outer, 120))
        for i in range(6):  # iskry unoszace sie w gore
            sx = int(h01(i, 0, 77) * w)
            sy = (int(h01(i, 1, 77) * h) - f * 3) % h
            if not solid[sy][sx]:
                px(glow, sx, sy, C(spark, 230))
        res = img.copy()  # poswiata tylko tam, gdzie nie ma postaci ani cienia (bez mieszania kolorow)
        for y in range(h):
            for x in range(w):
                g = glow.getpixel((x, y))
                if g[3] and img.getpixel((x, y))[3] == 0:
                    res.putpixel((x, y), g)
        return res
    return fn


def knight_spec(aura=None):
    glow = AURAS[aura][0] if aura else "a884f3"
    s = {"size": (20, 28), "cx": 10, "leg": 8, "torso": 8, "head": 3.3, "head_dx": 1.5, "neck": 0, "leg_w": 2.2, "arm": 5.5,
         "arm_w": 2.0, "torso_w": 7, "torso_ramp": KNIGHT, "head_ramp": KNIGHT,
         "head_fn": knight_head_fn(glow), "limb": "7f708a", "limb_dark": "3e3546",
         "leg_col": "625565", "leg_dark": "3e3546", "boot": ("2e222f", "3e3546"), "hand": "9babb2",
         "belt": "6b3e75", "shadow_r": 7, "cape": knight_cape, "shoulder": knight_shoulder,
         "weapon": make_blade(9, glow, "ffffff", guard="9babb2", grip="45293f", width=1.5),
         "torso_fn": knight_chest}
    if aura:
        s["glow_fn"] = aura_fn(aura)
    return s


def knight_anims(aura=None):
    spec = knight_spec(aura)
    walk = []
    for f, p in enumerate(walk_poses(weapon=30)):
        walk.append(humanoid(spec, dict(p, glow=bool(aura), frame=f)))
    att = [humanoid(spec, dict(p, glow=bool(aura), frame=i)) for i, p in enumerate(ATTACK)]
    hit = [flash(humanoid(spec, {"weapon": 30}))]
    return {"walk": walk, "attack": att, "hit": hit}


# ================================================================ WIEZE (32x40)
ST = ["3e3546", "625565", "7f708a", "9babb2", "c7dcd0"]
ST_LIGHT = ["625565", "7f708a", "9babb2", "c7dcd0", "ffffff"]
ST_DARK = ["2e222f", "3e3546", "45293f", "625565", "7f708a"]
WOODR = ["45293f", "4c3e24", "966c6c", "ab947a"]
STRAW = ["4c3e24", "966c6c", "ab947a", "fbb954"]
R_RED = ["6e2727", "9e4539", "cd683d", "e6904e"]
R_GREEN = ["165a4c", "239063", "1ebc73", "91db69"]
R_PURPLE = ["45293f", "6b3e75", "905ea9", "a884f3"]
R_BLUE = ["323353", "484a77", "4d65b4", "4d9be6"]
R_GOLD = ["9e4539", "cd683d", "f79617", "f9c22b"]
R_DARKP = ["2e222f", "45293f", "6b3e75", "905ea9"]
CR_PURPLE = ["45293f", "6b3e75", "a884f3", "eaaded"]
CR_BLUE = ["323353", "4d65b4", "4d9be6", "8fd3ff"]
CR_GREEN = ["165a4c", "0eaf9b", "30e1b9", "8ff8e2"]


def wall(img, x0, x1, y0, y1, ramp=ST, round_=True, bricks=True, seed=0):
    w = max(1, x1 - x0)
    for y in range(y0, y1 + 1):
        row = (y1 - y) // 3
        for x in range(x0, x1 + 1):
            t = (x - x0) / w
            if round_:
                idx = 4 if t < 0.15 else 3 if t < 0.5 else 2 if t < 0.82 else 1
            else:
                idx = 3 if t < 0.08 else 2 if t < 0.92 else 1
            if bricks:
                if (y1 - y) % 3 == 2 or (x - x0 + (2 if row % 2 else 0)) % 5 == 4:
                    idx -= 1
                elif h01(x, y, seed) < 0.06:
                    idx = max(1, idx - 1)
            px(img, x, y, C(ramp[max(0, min(len(ramp) - 1, idx))]))


def wood_wall(img, x0, x1, y0, y1, ramp=WOODR, horizontal=False):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            k = (y - y0) if horizontal else (x - x0)
            idx = 2
            if k % 3 == 2:
                idx = 1
            if x == x0:
                idx = 3
            elif x == x1:
                idx = 1
            if y in (y0, y1):
                idx = 1
            px(img, x, y, C(ramp[idx]))


def battlements(img, x0, x1, y, ramp=ST):
    for x in range(x0, x1 + 1):
        t = (x - x0) / max(1, x1 - x0)
        c = ramp[3] if t < 0.5 else ramp[2]
        px(img, x, y, C(c))
        px(img, x, y + 1, C(ramp[1]))
        if ((x - x0) // 3) % 2 == 0:
            px(img, x, y - 1, C(ramp[4] if (x - x0) % 3 == 0 else c))
            px(img, x, y - 2, C(ramp[4] if (x - x0) % 3 == 0 else c))


def top_cap(img, cx, cy, rx, ry, ramp=ST):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d > 1:
                continue
            c = ramp[3] if dx < 0 else ramp[2]
            if d > 0.6 and dy > 0:
                c = ramp[1]
            px(img, x, y, C(c))


def cone(img, cx, ytop, ybase, half, ramp):
    for y in range(ytop, ybase + 1):
        t = (y - ytop) / max(1, ybase - ytop)
        hw = half * t + 0.5
        for x in range(int(cx - hw) - 1, int(cx + hw) + 2):
            xo = x + 0.5 - cx
            if abs(xo) > hw:
                continue
            idx = 2 if xo < -hw * 0.25 else 1 if xo < hw * 0.45 else 0
            if xo < 0 and xo > -1.2:
                idx = 3
            if (ybase - y) % 3 == 0 and t > 0.15:
                idx = max(0, idx - 1)
            px(img, x, y, C(ramp[idx]))
    for x in range(int(cx - half) - 1, int(cx + half) + 2):
        px(img, x, ybase + 1, C(ramp[0]))


def hip_roof(img, x0, x1, ytop, ybase, ramp, inset=5):
    for y in range(ytop, ybase + 1):
        t = (y - ytop) / max(1, ybase - ytop)
        left = x0 + inset - (inset + 1) * t
        right = x1 - inset + (inset + 1) * t
        for x in range(int(left), int(right) + 1):
            if x < left + 1.5 + t:
                idx = 3
            elif x > right - 1.5 - t:
                idx = 0
            else:
                idx = 2 if (ybase - y) % 3 else 1
            px(img, x, y, C(ramp[idx]))
    for x in range(x0 - 1, x1 + 2):
        px(img, x, ybase + 1, C(ramp[0]))


def window(img, x, y, glow=None, h=3):
    rect(img, x, y, x + 1, y + h - 1, C("2e222f"))
    if glow:
        px(img, x, y + 1, C(glow))
        px(img, x, y + 2, C(glow))
        px(img, x + 1, y + 2, C(glow))


def door(img, cx, ybot, w=4, h=6, wood=("4c3e24", "966c6c")):
    x0 = int(cx - w / 2)
    for y in range(ybot - h, ybot + 1):
        for x in range(x0, x0 + w):
            if y == ybot - h and (x == x0 or x == x0 + w - 1):
                continue
            c = wood[1] if (x - x0) % 2 == 0 else wood[0]
            px(img, x, y, C(c))
    px(img, x0 + w - 2, ybot - h // 2, C("f9c22b"))


def flag(img, x, ytop, ramp, h=7, wave=0):
    line(img, x, ytop, x, ytop + h, C("4c3e24"), 1)
    px(img, x, ytop - 1, C("f9c22b"))
    for i in range(4):
        dy = (1 if (i + wave) % 3 == 2 else 0)
        px(img, x + 1 + i, ytop + dy, C(ramp[2]))
        px(img, x + 1 + i, ytop + 1 + dy, C(ramp[1]))
        if i < 3:
            px(img, x + 1 + i, ytop + 2 + dy, C(ramp[0]))


def banner(img, x0, y0, w, h, ramp, emblem=None):
    line(img, x0 - 1, y0, x0 + w, y0, C("4c3e24"), 1)
    for y in range(y0 + 1, y0 + h + 1):
        for x in range(x0, x0 + w):
            if y >= y0 + h - 1 and x == x0 + w // 2 - (w % 2 == 0) * 0 and y == y0 + h:
                continue
            c = ramp[2] if x == x0 else ramp[1] if x < x0 + w - 1 else ramp[0]
            px(img, x, y, C(c))
    mid = x0 + w // 2
    px(img, mid, y0 + h, (0, 0, 0, 0))
    if emblem:
        px(img, mid, y0 + h // 2, C(emblem))
        px(img, mid, y0 + h // 2 - 1, C(emblem))
        if w > 3:
            px(img, mid - 1, y0 + h // 2 - 1, C(emblem))
            px(img, mid + 1, y0 + h // 2 - 1, C(emblem))


def crystal(img, cx, cy, hh, ramp, glow=True):
    if glow:
        for y in range(int(cy - hh - 3), int(cy + hh + 4)):
            for x in range(int(cx - hh - 3), int(cx + hh + 4)):
                d = math.hypot((x + 0.5 - cx) / 0.7, y + 0.5 - cy)
                if hh + 0.5 < d < hh + 2.5 and bayer(x, y) < 0.3:
                    px(img, x, y, C(ramp[2], 150))
    for dy in range(-hh, hh + 1):
        half = (hh - abs(dy)) * 0.55 + 0.4
        for x in range(int(cx - half) - 1, int(cx + half) + 2):
            xo = x + 0.5 - cx
            if abs(xo) > half:
                continue
            c = ramp[2] if xo < -0.4 else ramp[1] if xo > 0.6 else ramp[3]
            if dy > hh * 0.4 and xo > 0:
                c = ramp[0]
            px(img, x, int(cy + dy), C(c))


def shield(img, cx, y, field, charge):
    rows = ["xxxxx", "xxcxx", "xcccx", "xxcxx", ".xxx.", "..x.."]
    for j, r in enumerate(rows):
        for i, ch in enumerate(r):
            if ch == "x":
                px(img, cx - 2 + i, y + j, C(field[1] if i < 2 else field[0]))
            elif ch == "c":
                px(img, cx - 2 + i, y + j, C(charge))


def cannon_barrel(img, x0, y0, x1, y1, w, ring="cd683d"):
    line(img, x0, y0, x1, y1, C("3e3546"), w)
    line(img, x0, y0 - w * 0.3, x1, y1 - w * 0.3, C("625565"), max(1, w - 2))
    for t in (0.35, 0.7):
        x, y = x0 + (x1 - x0) * t, y0 + (y1 - y0) * t
        line(img, x - (y1 - y0) / 12, y + (x1 - x0) / 12 * 0 - w / 2, x + (y1 - y0) / 12, y + w / 2, C(ring), 1)
    ell(img, x1, y1, w / 2 + 0.3, w / 2 + 0.3, C("7f708a"))
    px(img, int(x1), int(y1), C("2e222f"))


def balls(img, x, y):
    for dx, dy in ((0, 0), (2, 0), (1, -1)):
        px(img, x + dx, y + dy, C("3e3546"))
        px(img, x + dx, y + dy - 1, C("7f708a")) if dy == -1 else None


def tower_canvas():
    return new(32, 40), new(32, 40)


def tower_done(img, sh, rx=13):
    shadow_ellipse(sh, 18, 38.5, rx, 1.8)
    return stack(sh, finish(img))


# ---------------------------------------------------------------- lucznicza
def archer_tower(lvl):
    img, sh = tower_canvas()
    if lvl == 1:
        for x in (7, 16, 24):
            line(img, x, 22, x, 38, C("4c3e24"), 2)
        line(img, 8, 24, 15, 36, C("966c6c"), 1)
        line(img, 17, 24, 23, 36, C("966c6c"), 1)
        wood_wall(img, 5, 26, 17, 22, horizontal=True)
        rect(img, 5, 16, 26, 17, C("ab947a"))
        for x in (5, 11, 16, 21, 26):
            line(img, x, 12, x, 16, C("966c6c"), 1)
        line(img, 5, 12, 26, 12, C("ab947a"), 1)
        flag(img, 25, 4, R_GREEN, h=8)
        return tower_done(img, sh, 11)
    if lvl == 2:
        wall(img, 8, 23, 26, 38)
        door(img, 15.5, 38)
        wood_wall(img, 5, 26, 16, 25)
        window(img, 9, 19)
        window(img, 21, 19)
        cone(img, 15.5, 4, 15, 13, STRAW)
        return tower_done(img, sh)
    if lvl == 3:
        wall(img, 8, 23, 20, 38)
        window(img, 12, 25)
        window(img, 18, 29)
        door(img, 15.5, 38)
        banner(img, 19, 22, 3, 5, R_GREEN, "fbff86")
        wood_wall(img, 5, 26, 12, 20)
        window(img, 9, 14)
        window(img, 21, 14)
        cone(img, 15.5, 1, 11, 13, R_GREEN)
        return tower_done(img, sh)
    if lvl == "4a":  # strazniczka lasu
        wall(img, 8, 23, 20, 38)
        door(img, 15.5, 38)
        for y in range(20, 38, 2):  # pnacza
            px(img, 9 + (y // 2) % 3, y, C("239063"))
            px(img, 22 - (y // 3) % 2, y + 1, C("1ebc73"))
        wood_wall(img, 5, 26, 13, 20)
        window(img, 9, 15, "fbff86")
        window(img, 21, 15, "fbff86")
        for i, (cx, cy, rx, ry) in enumerate([(15.5, 9, 12, 5.5), (8, 7, 6, 4.5), (23, 7, 6, 4.5), (15.5, 3.5, 7, 3.5)]):
            blob(img, cx, cy, rx, ry, G.LEAF, seed=60 + i, rough=0.35, clump=0.35)
        banner(img, 3, 20, 3, 7, R_GREEN, "fbff86")
        banner(img, 26, 20, 3, 7, R_GREEN, "fbff86")
        return tower_done(img, sh)
    # 4b - kusznicy z balista
    wall(img, 6, 25, 16, 38)
    battlements(img, 6, 25, 16)
    window(img, 10, 22)
    window(img, 20, 22)
    window(img, 15, 28)
    door(img, 15.5, 38)
    banner(img, 7, 26, 3, 6, R_RED, "f9c22b")
    banner(img, 22, 26, 3, 6, R_RED, "f9c22b")
    line(img, 9, 12, 23, 10, C("966c6c"), 2)       # loze balisty
    line(img, 21, 4, 22, 16, C("4c3e24"), 2)       # luk
    line(img, 21, 4, 17, 10, C("c7dcd0"), 1)       # cieciwa
    line(img, 22, 16, 17, 10, C("c7dcd0"), 1)
    line(img, 12, 10, 28, 9, C("c7dcd0"), 1)       # belt
    px(img, 29, 9, C("9babb2"))
    return tower_done(img, sh)


# ---------------------------------------------------------------- magiczna
def mage_tower(lvl):
    img, sh = tower_canvas()
    if lvl == 1:
        wall(img, 10, 21, 26, 38)
        top_cap(img, 15.5, 26, 6.5, 2)
        window(img, 15, 30, "a884f3")
        crystal(img, 15.5, 18, 4, CR_PURPLE)
        return tower_done(img, sh, 9)
    if lvl == 2:
        wall(img, 9, 22, 18, 38)
        window(img, 13, 22, "a884f3")
        window(img, 17, 27, "a884f3")
        door(img, 15.5, 38)
        cone(img, 15.5, 8, 17, 9, R_PURPLE)
        crystal(img, 15.5, 4, 3, CR_PURPLE)
        return tower_done(img, sh, 10)
    if lvl == 3:
        wall(img, 7, 24, 32, 38)
        wall(img, 10, 21, 14, 31)
        rect(img, 8, 22, 23, 23, C("9babb2"))
        rect(img, 8, 24, 23, 24, C("625565"))
        window(img, 15, 17, "a884f3")
        window(img, 12, 26, "a884f3")
        window(img, 18, 27, "a884f3")
        door(img, 15.5, 38)
        cone(img, 15.5, 1, 13, 8, R_PURPLE)
        for cx, cy in ((4, 12), (27, 17)):
            blob(img, cx, cy, 1.6, 1.6, CR_PURPLE[1:], seed=3, dither=0.2)
        return tower_done(img, sh)
    cr = CR_PURPLE if lvl == "4a" else CR_BLUE
    glow = "a884f3" if lvl == "4a" else "8fd3ff"
    wall(img, 7, 24, 32, 38)
    wall(img, 10, 21, 18, 31)
    battlements(img, 9, 22, 18)
    window(img, 12, 22, glow)
    window(img, 18, 24, glow)
    door(img, 15.5, 38)
    crystal(img, 15.5, 8, 7, cr)
    if lvl == "4a":  # kamienie z runami krazace wokol krysztalu
        for cx, cy in ((5, 9), (26, 5), (27, 15)):
            blob(img, cx, cy, 2.2, 1.8, ST, seed=4, facets=5, dither=0.2)
            px(img, int(cx), int(cy), C("a884f3"))
    else:  # blyskawice
        for (x0, y0), (x1, y1) in (((8, 2), (5, 7)), ((5, 7), (7, 9)), ((7, 9), (3, 14)),
                                   ((24, 3), (27, 8)), ((27, 8), (25, 10)), ((25, 10), (29, 15))):
            line(img, x0, y0, x1, y1, C("fbff86"), 1)
    return tower_done(img, sh)


# ---------------------------------------------------------------- artyleria
def artillery_tower(lvl):
    img, sh = tower_canvas()
    if lvl == 1:
        wood_wall(img, 5, 26, 30, 38, horizontal=True)
        rect(img, 5, 27, 26, 29, C("ab947a"))
        for x in range(6, 26, 4):
            blob(img, x + 1.5, 29.5, 2.2, 1.5, ["966c6c", "ab947a", "c7dcd0"], seed=x, dither=0.2)
        blob(img, 16, 24, 4, 3, STEEL, seed=1, dither=0.2)
        cannon_barrel(img, 16, 24, 20, 18, 4)
        balls(img, 8, 26)
        return tower_done(img, sh, 12)
    if lvl == 2:
        wall(img, 4, 27, 26, 38, round_=False)
        battlements(img, 4, 27, 26)
        door(img, 15.5, 38)
        rect(img, 11, 21, 20, 24, C("966c6c"))
        rect(img, 11, 21, 20, 21, C("ab947a"))
        cannon_barrel(img, 13, 21, 25, 16, 3)
        ell(img, 13, 24, 2.2, 2.2, C("4c3e24"))
        px(img, 13, 24, C("966c6c"))
        balls(img, 6, 23)
        return tower_done(img, sh)
    if lvl == 3:
        wall(img, 3, 28, 22, 38)
        battlements(img, 3, 28, 22)
        window(img, 9, 28)
        window(img, 21, 28)
        door(img, 15.5, 38)
        rect(img, 9, 17, 19, 20, C("4c3e24"))
        cannon_barrel(img, 11, 18, 25, 8, 5)
        balls(img, 5, 19)
        balls(img, 23, 19)
        return tower_done(img, sh)
    if lvl == "4a":  # ciezki mozdzierz
        wall(img, 4, 27, 26, 38)
        battlements(img, 4, 27, 26)
        door(img, 15.5, 38)
        blob(img, 16, 19, 8.5, 6.5, STEEL, seed=2, dither=0.2)
        for y in (16, 21):
            for x in range(8, 25):
                if alpha(img, x, y):
                    px(img, x, y, C("cd683d" if x < 16 else "9e4539"))
        ell(img, 18, 12, 6, 2.6, C("9babb2"))
        ell(img, 18, 12, 4.4, 1.6, C("2e222f"))
        balls(img, 5, 23)
        balls(img, 25, 23)
        return tower_done(img, sh)
    # 4b - katapulta z ognistym pociskiem
    wall(img, 5, 26, 28, 38, round_=False)
    battlements(img, 5, 26, 28)
    line(img, 9, 27, 15, 15, C("4c3e24"), 2)
    line(img, 22, 27, 15, 15, C("4c3e24"), 2)
    line(img, 10, 22, 21, 22, C("966c6c"), 1)
    line(img, 9, 24, 25, 6, C("966c6c"), 2)
    rect(img, 7, 23, 11, 26, C("625565"))
    ell(img, 25, 5, 2.6, 2.2, C("4c3e24"))
    blob(img, 25, 3, 3, 3, ["ea4f36", "fb6b1d", "f79617", "f9c22b"], seed=3, dither=0.4)
    px(img, 26, 0, C("625565"))
    px(img, 24, 0, C("7f708a"))
    return tower_done(img, sh)


# ---------------------------------------------------------------- koszary
def barracks_tower(lvl):
    img, sh = tower_canvas()
    if lvl == 1:
        wood_wall(img, 6, 25, 27, 38)
        door(img, 15.5, 38)
        window(img, 9, 30)
        window(img, 21, 30)
        hip_roof(img, 6, 25, 17, 26, STRAW)
        return tower_done(img, sh, 12)
    if lvl == 2:
        wall(img, 4, 27, 25, 38, round_=False)
        door(img, 15.5, 38)
        window(img, 8, 29, "f9c22b")
        window(img, 22, 29, "f9c22b")
        hip_roof(img, 4, 27, 13, 24, R_RED)
        rect(img, 22, 10, 24, 15, C("625565"))
        px(img, 23, 9, C("9babb2"))
        banner(img, 11, 26, 2, 5, R_RED)
        return tower_done(img, sh)
    st = ST_LIGHT if lvl == "4a" else ST
    if lvl in (3, "4a"):
        roof = R_BLUE if lvl == "4a" else R_RED
        cloth = ["9babb2", "c7dcd0", "ffffff"] if lvl == "4a" else R_RED
        emb = "f9c22b" if lvl == "4a" else None
        wall(img, 8, 23, 20, 38, st, round_=False)
        battlements(img, 8, 23, 20, st)
        door(img, 15.5, 38, w=6, h=8)
        for x0 in (2, 22):
            wall(img, x0, x0 + 7, 16, 38, st)
            window(img, x0 + 3, 24, "f9c22b" if lvl == "4a" else None)
            cone(img, x0 + 3.5, 7, 15, 4.5, roof)
        banner(img, 11, 22, 3, 6, cloth, emb)
        banner(img, 18, 22, 3, 6, cloth, emb)
        flag(img, 15, 10, cloth if lvl == "4a" else R_RED, h=9)
        return tower_done(img, sh, 14)
    # 4b - barbarzyncy: dlugi dom
    wood_wall(img, 3, 28, 24, 38)
    door(img, 15.5, 38, w=5, h=7)
    rect(img, 14, 28, 17, 29, C("c7dcd0"))  # czaszka nad drzwiami
    px(img, 15, 29, C("2e222f"))
    px(img, 16, 29, C("2e222f"))
    for cx in (7, 24):  # okragle tarcze
        ell(img, cx, 31, 2.4, 2.4, C("b33831"))
        px(img, cx, 31, C("c7dcd0"))
    hip_roof(img, 3, 28, 10, 23, STRAW, inset=6)
    for x, d in ((9, -1), (22, 1)):  # rogi na kalenicy
        line(img, x, 10, x + 3 * d, 6, C("c7dcd0"), 1)
        px(img, x + 3 * d, 5, C("ffffff"))
    line(img, 28, 22, 29, 12, C("4c3e24"), 1)  # totem z czaszka
    rect(img, 28, 10, 30, 12, C("c7dcd0"))
    return tower_done(img, sh, 14)


# ---------------------------------------------------------------- rycerska
def knight_tower(lvl):
    img, sh = tower_canvas()
    if lvl == 1:
        wall(img, 8, 23, 22, 38, round_=False)
        battlements(img, 8, 23, 22)
        shield(img, 15, 26, R_BLUE[1:], "f9c22b")
        door(img, 15.5, 38, h=5)
        return tower_done(img, sh, 10)
    if lvl == 2:
        wall(img, 7, 24, 14, 38, round_=False)
        battlements(img, 7, 24, 14)
        window(img, 15, 18)
        banner(img, 9, 20, 3, 8, R_BLUE, "f9c22b")
        banner(img, 20, 20, 3, 8, R_BLUE, "f9c22b")
        shield(img, 15, 24, R_BLUE[1:], "f9c22b")
        door(img, 15.5, 38)
        return tower_done(img, sh, 11)
    if lvl == 3:
        st, roof, cloth, emb, glow = ST, R_BLUE, R_BLUE, "f9c22b", None
    elif lvl == "4a":
        st, roof, cloth, emb, glow = ST_LIGHT, R_GOLD, ["9babb2", "c7dcd0", "ffffff"], "f9c22b", "fbff86"
    else:
        st, roof, cloth, emb, glow = ST_DARK, R_DARKP, R_DARKP, "e83b3b", "e83b3b"
    wall(img, 9, 22, 12, 38, st, round_=False)
    battlements(img, 9, 22, 12, st)
    window(img, 15, 16, glow)
    door(img, 15.5, 38)
    shield(img, 15, 26, cloth[1:] if len(cloth) > 3 else cloth, emb)
    for x0 in (3, 22):
        wall(img, x0, x0 + 6, 19, 38, st)
        window(img, x0 + 3, 26, glow)
        cone(img, x0 + 3, 10, 18, 4.5, roof)
    banner(img, 10, 18, 2, 6, cloth, None)
    banner(img, 20, 18, 2, 6, cloth, None)
    flag(img, 15, 2, cloth if len(cloth) > 3 else R_BLUE, h=8)
    if lvl == "4a":  # poswiata
        for i in range(8):
            a = i * math.pi / 4
            px(img, int(15.5 + math.cos(a) * 6), int(4 + math.sin(a) * 3), C("fbff86", 200))
    return tower_done(img, sh, 14)


TOWERS = {
    "archer": (archer_tower, {"4a": "ranger", "4b": "crossbow"}),
    "mage": (mage_tower, {"4a": "arcane", "4b": "storm"}),
    "artillery": (artillery_tower, {"4a": "mortar", "4b": "firecatapult"}),
    "barracks": (barracks_tower, {"4a": "templar", "4b": "barbarian"}),
    "knight": (knight_tower, {"4a": "paladin", "4b": "darkknight"}),
}


# ================================================================ STATEK 64x32
def ship(frame):
    img = new(64, 32)
    s = frame  # 0/1: przechyl masztow i lekkie zanurzenie
    bob = frame
    deck = 19 + bob

    def lean(y):
        return int(round(s * (deck - y) / 14)) if y < deck else 0

    hull = []
    for x in range(4, 61):
        t = (x - 4) / 56
        top = deck - (3 if x < 16 else 0) - (int((x - 52) * 0.6) if x > 52 else 0)
        bottom = 28 + bob - int(3 * abs(t - 0.45) ** 1.6 * 4)
        hull.append((x, top, bottom))
        for y in range(top, bottom + 1):
            c = "966c6c" if y < deck + 2 else "4c3e24"
            if y == deck + 3 or y == deck + 4:
                c = "6e2727"
            if y == top:
                c = "ab947a"
            if y >= bottom - 1:
                c = "45293f"
            px(img, x, y, C(c))
    for x in range(22, 50, 6):
        px(img, x, deck + 2, C("2e222f"))
    for x in range(5, 16):  # nadbudowka rufowa
        for y in range(deck - 7, deck - 3):
            px(img, x, y, C("966c6c" if (x - 5) % 3 else "4c3e24"))
    rect(img, 5, deck - 8, 15, deck - 8, C("ab947a"))
    window(img, 9, deck - 6, "f9c22b", h=2)
    for mx, top, sail in ((27, 2, (19, 34, 7, 16)), (43, 5, (37, 49, 9, 16))):
        for y in range(top, deck):
            px(img, mx + lean(y), y, C("4c3e24"))
        x0, x1, y0, y1 = sail
        for y in range(y0, y1 + 1):
            bow = int(2 * math.sin(math.pi * (y - y0) / (y1 - y0)))
            for x in range(x0 + bow, x1 + bow + 1):
                c = "ffffff" if x < x0 + bow + 2 else "c7dcd0"
                if x > x1 + bow - 2:
                    c = "9babb2"
                px(img, x + lean(y), y, C(c))
        rect(img, x0 - 1 + lean(y0), y0 - 1, x1 + 1 + lean(y0), y0 - 1, C("966c6c"))
        flag(img, mx + lean(top), top, R_RED, h=2, wave=frame)
    cx = 27 + lean(11)  # herb na grotzaglu
    for dx, dy in ((0, 0), (-1, 0), (1, 0), (0, -1), (0, 1), (0, 2)):
        px(img, cx + dx, 11 + dy, C("b33831"))
    line(img, 43 + lean(5), 5, 61, deck - 4, C("ab947a"), 1)  # sztag
    poly(img, [(44 + lean(7), 7), (58, deck - 5), (45 + lean(17), 17)], C("c7dcd0"))
    line(img, 56, deck - 4, 63, deck - 7, C("4c3e24"), 1)  # bukszpryt
    out = finish(img)
    for x in range(2, 63):  # piana przy linii wody
        y = 30 + bob // 1
        if y < 32 and (x + frame * 2) % 5 != 0:
            px(out, x, min(31, y), C("ffffff" if (x + frame) % 3 else "8fd3ff"))
    return out


# ================================================================ PODGLADY


def strip_sheet(groups, scale=4):
    return G.overview(groups, scale=scale)


def towers_sheet(imgs, spot):
    cols = ["1", "2", "3", "4a", "4b"]
    cw, chh = 40, 50
    tiles = [G.grass_tiles().crop((i * T, 0, (i + 1) * T, T)) for i in range(4)]
    W, H = cw * len(cols), chh * len(TOWERS)
    bg = new(W, H)
    for ty in range(H // T + 1):
        for tx in range(W // T + 1):
            bg.paste(tiles[int(h01(tx, ty, 4) * 4) % 4], (tx * T, ty * T))
    for r, name in enumerate(TOWERS):
        for c, lv in enumerate(cols):
            im = imgs["%s_%s" % (name, lv)]
            x0, y0 = c * cw, r * chh
            bg.alpha_composite(spot, (x0 + 4, y0 + chh - 22 - 2))
            bg.alpha_composite(im, (x0 + 4, y0 + chh - 40 - 6))
    return bg.resize((W * 3, H * 3), Image.NEAREST)


def preview_battle(E, TW_, ship_img):
    MW, MH = 640, 360
    road = G.render_path([(-40, 104), (200, 104), (312, 216), (700, 216)], MW, MH)
    grass = G.render_base(G.grass_tiles(), 3).crop((0, 0, MW, MH))
    sea = G.Grid()
    beach = G.Grid()
    for x in range(G.TW + 1):
        for y in range(G.TH + 1):
            d = ((x - 40) / 12) ** 2 + ((y - 24) / 6.5) ** 2
            if d <= 1:
                sea.set(x, y)
            if ((x - 40) / 16) ** 2 + ((y - 24) / 9) ** 2 <= 1:
                beach.set(x, y)
    beach_l = G.render_layer(beach, *G.atlas_tiles(G.wang_atlas(G.beach_style())), seed=2).crop((0, 0, MW, MH))
    sea_l = G.render_layer(sea, G.water_tiles(G.water_atlas(G.SEA))).crop((0, 0, MW, MH))
    foam_l = G.render_layer(sea, G.water_tiles(G.water_atlas(G.foam_style()), 1)).crop((0, 0, MW, MH))
    canvas = stack(grass, beach_l, road, sea_l, foam_l)
    spot = G.build_spot()
    items = []
    for (x, y), t in zip([(150, 150), (250, 128), (226, 262), (392, 180), (470, 268)],
                         ["archer_3", "mage_4a", "artillery_2", "knight_3", "barracks_4b"]):
        canvas.alpha_composite(spot, (x - 16, y - 18))
        items.append((x, y - 2, TW_[t]))
    trees = [G.tree_deciduous(0), G.tree_deciduous(1), G.tree_conifer(0)]
    rng = random.Random(3)
    for i in range(16):
        x, y = rng.randint(330, 620), rng.randint(20, 90)
        items.append((x, y, trees[i % 3]))
    for i in range(6):
        x, y = rng.randint(10, 120), rng.randint(180, 340)
        items.append((x, y, trees[i % 3]))
    for name, x, y in [("goblin", 40, 110), ("wolf", 84, 112), ("orc", 128, 112), ("hedgehog", 236, 136),
                       ("shaman", 280, 186), ("magic_knight_purple", 360, 222), ("boss", 420, 226),
                       ("hedgehog_roll", 500, 222), ("magic_knight_blue", 560, 222)]:
        im = E[name]
        items.append((x, y, im))
    items.append((560, 352, ship_img))
    for x, y, im in sorted(items, key=lambda it: it[1]):
        canvas.alpha_composite(im, (int(x - im.width // 2), int(y - im.height)))
    for name, x, y in [("bat", 180, 60), ("bat", 205, 48), ("dragon", 330, 120)]:  # w powietrzu
        im = E[name]
        sh = new(im.width, 4)
        shadow_ellipse(sh, im.width / 2, 2, im.width * 0.3, 1.3)
        canvas.alpha_composite(sh, (x - im.width // 2, y + 26))
        canvas.alpha_composite(im, (x - im.width // 2, y - im.height))
    return canvas.resize((MW * 3, MH * 3), Image.NEAREST)


# ================================================================ MAIN


def run(out="."):
    en = os.path.join(out, "assets", "enemies")
    tw = os.path.join(out, "assets", "towers")
    ob = os.path.join(out, "assets", "objects")
    for d in (en, tw, ob):
        os.makedirs(d, exist_ok=True)
    files = []

    def save(folder, name, img, frames, desc):
        check_palette(img, name)
        p = os.path.join(folder, name + ".png")
        img.save(p)
        files.append((os.path.relpath(p, out), img.size, frames, desc))
        return img

    enemies = {
        "goblin": humanoid_anims(GOBLIN, walk_weapon=120),
        "wolf": wolf_anims(),
        "orc": humanoid_anims(ORCSPEC, walk_weapon=145),
        "bat": bat_anims(),
        "shaman": humanoid_anims(SHAMAN, attack=SHAMAN_ATTACK, walk_weapon=10),
        "boss": humanoid_anims(BOSS, walk_weapon=145),
        "magic_knight": knight_anims(None),
        "magic_knight_purple": knight_anims("purple"),
        "magic_knight_blue": knight_anims("blue"),
        "dragon": dragon_anims(),
        "hedgehog": hedgehog_anims(),
    }
    E = {}
    groups = []
    for name, anims in enemies.items():
        row = []
        for an, frames in anims.items():
            sheet = hstrip(frames)
            w, h = frames[0].size
            save(en, "%s_%s" % (name, an), sheet, len(frames), "%dx%d" % (w, h))
            row.append((an, sheet))
        groups.append((name, row))
        E[name] = anims.get("walk", anims.get("fly"))[0]
    E["hedgehog_roll"] = enemies["hedgehog"]["roll"][1]
    # ogien smoka (32x12) zapisuje gen_fx.py

    TWI = {}
    for name, (fn, names4) in TOWERS.items():
        for lv in (1, 2, 3, "4a", "4b"):
            im = fn(lv)
            key = "%s_%s" % (name, lv)
            TWI[key] = im
            fname = key if lv in (1, 2, 3) else "%s_%s_%s" % (name, lv, names4[lv])
            save(tw, fname, im, 1, "poziom %s" % lv)

    ship_frames = [ship(0), ship(1)]
    save(ob, "ship_sway", hstrip(ship_frames), 2, "64x32")

    strip_sheet(groups[:6]).save(os.path.join(out, "overview_enemies.png"))
    strip_sheet(groups[6:] + [("statek", [("ship", hstrip(ship_frames))])]).save(
        os.path.join(out, "overview_enemies_2.png"))
    towers_sheet(TWI, G.build_spot()).save(os.path.join(out, "overview_towers.png"))
    preview_battle(E, TWI, ship_frames[0]).save(os.path.join(out, "preview_battle.png"))

    print("Etap 2-3, zapisane pliki:")
    for p, size, n, desc in files:
        print("  %-48s %3dx%-3d  %d kl.  %s" % (p, size[0], size[1], n, desc))
    return files


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".")
    run(ap.parse_args().out)

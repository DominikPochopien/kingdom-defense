#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - poziom 9 (Piramida): nieumarli, piramida i portale. Paleta Resurrect 64.

Pliki:
  assets/enemies/skeleton_{walk,attack,hit}.png          klatki 16x20 (Szkielet z mieczem)
  assets/enemies/skeleton_archer_{walk,attack,hit}.png   klatki 16x20 (Szkielet z łukiem; attack = strzał)
  assets/enemies/skeleton_armored_{walk,attack,hit}.png  klatki 18x22 (Szkielet pancerny: hełm, napierśnik, tarcza, miecz)
  assets/enemies/mummy_{walk,attack,cast,hit}.png        klatki 28x32 (Mumia - boss; cast = przywołanie)
  assets/objects/pyramid.png    80x64, drzwi na dole przedniej ściany w pikselu (31, 62)
  assets/objects/portal.png     4 klatki 28x18 - fioletowy wir na ziemi (środek klatki = punkt trasy)

Postacie patrzą w prawo, stopy w dolnym środku klatki (jak w gen_units.py).
Uruchamia go gen_art.py, można też osobno:  python tools/gen_undead.py [--out X]
"""
import argparse
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_art import C, new, px, alpha, h01, outline, hstrip, check_palette, blob  # noqa: E402
from gen_units import humanoid, walk_poses, flash, rect, line, poly, make_blade, ATTACK  # noqa: E402

OUT = C("2e222f")

# ================================================================ szkielety 16x20
BONE = ["7f708a", "9babb2", "c7dcd0"]
SKULL = ["9babb2", "c7dcd0", "ffffff"]


def skull_head(img, hx, hy, pose):
    px(img, hx + 1, hy - 1, C("2e222f"))       # oczodoły
    px(img, hx + 2, hy - 1, C("e83b3b"))
    px(img, hx + 2, hy + 1, C("625565"))       # zęby
    px(img, hx + 1, hy + 1, C("9babb2"))


def ribs(img, sh_x, sh_y, cx, hip_y, pose):
    tx = int(round((sh_x + cx) / 2))
    for y in range(sh_y + 1, hip_y, 2):
        for x in range(tx - 3, tx + 4):
            if alpha(img, x, y) and x != tx:
                px(img, x, y, C("2e222f"))
    for y in range(sh_y, hip_y + 1):
        px(img, tx, y, C("c7dcd0"))               # kręgosłup


SKELETON = {"size": (16, 20), "cx": 7, "leg": 6, "torso": 5, "head": 3.0, "head_dx": 1.5, "leg_w": 1.0, "arm": 4,
            "arm_w": 1.0, "torso_w": 4, "torso_ramp": BONE, "head_ramp": SKULL, "head_fn": skull_head,
            "limb": "c7dcd0", "limb_dark": "9babb2", "leg_col": "c7dcd0", "leg_dark": "9babb2",
            "boot": ("9babb2", "c7dcd0"), "hand": "ffffff", "shadow_r": 5, "torso_fn": ribs,
            "weapon": make_blade(5, "9babb2", "c7dcd0", guard="966c6c", grip="4c3e24")}


def hooded_skull(img, hx, hy, pose):
    skull_head(img, hx, hy, pose)
    for y in range(hy - 4, hy + 1):          # postrzępiony kaptur z tyłu głowy
        for x in range(hx - 4, hx):
            if (x - hx) * 2 + (y - hy) < -1 and alpha(img, x, y):
                px(img, x, y, C("45293f" if (x + y) % 3 else "6b3e75"))
    px(img, hx - 1, hy - 4, C("6b3e75"))


def quiver(img, sh_x, sh_y, cx, hip_y, pose):
    ribs(img, sh_x, sh_y, cx, hip_y, pose)
    rect(img, sh_x - 4, sh_y - 1, sh_x - 3, sh_y + 4, C("4c3e24"))
    px(img, sh_x - 4, sh_y - 2, C("c7dcd0"))
    px(img, sh_x - 3, sh_y - 3, C("ea4f36"))


def bow(img, hand, deg, pose):
    """Łuk pionowo przed dłonią; pose["draw"] = napięta cięciwa ze strzałą."""
    hx, hy = int(round(hand[0])), int(round(hand[1]))
    pull = pose.get("draw", 0)
    for dy in range(-5, 6):
        bx = hx + 1 + int(round(2.0 * (1 - (dy / 5.0) ** 2)))
        px(img, bx, hy + dy, C("966c6c" if abs(dy) < 4 else "4c3e24"))
    sx = hx - pull
    line(img, hx + 1, hy - 5, sx, hy, C("c7dcd0"), 1)
    line(img, sx, hy, hx + 1, hy + 5, C("c7dcd0"), 1)
    if pull:
        line(img, sx, hy, hx + 5, hy, C("ab947a"), 1)
        px(img, hx + 5, hy, C("ffffff"))


ARCHER = dict(SKELETON, head_fn=hooded_skull, torso_fn=quiver, weapon=bow)

# szkielet pancerny 18x22 ----------------------------------------
ARMOR = ["3e3546", "625565", "7f708a", "9babb2"]


def helmet_skull(img, hx, hy, pose):
    for y in range(hy - 4, hy - 1):            # stalowy hełm na górnej połowie czaszki
        for x in range(hx - 4, hx + 4):
            if alpha(img, x, y):
                px(img, x, y, C("9babb2" if x < hx - 1 else "7f708a" if x < hx + 2 else "625565"))
    rect(img, hx - 3, hy - 2, hx + 3, hy - 2, C("3e3546"))
    line(img, hx - 2, hy - 5, hx + 1, hy - 5, C("b33831"), 1)   # czerwony grzebień
    px(img, hx - 3, hy - 4, C("b33831"))
    px(img, hx + 1, hy - 1, C("2e222f"))
    px(img, hx + 2, hy - 1, C("e83b3b"))
    px(img, hx + 2, hy + 1, C("625565"))


def armor_belt(img, sh_x, sh_y, cx, hip_y, pose):
    rect(img, sh_x - 1, sh_y + 2, sh_x + 1, sh_y + 2, C("9babb2"))   # blask na napierśniku


def round_shield(img, hand, pose):
    hx, hy = int(round(hand[0])), int(round(hand[1]))
    rect(img, hx - 2, hy - 3, hx + 1, hy + 2, C("6e2727"))
    rect(img, hx - 1, hy - 2, hx, hy + 1, C("b33831"))
    px(img, hx - 1, hy - 1, C("f9c22b"))


def steel_pad(img, sx, sy):
    blob(img, sx, sy, 2.2, 1.8, ARMOR, seed=8, dither=0.2)


ARMORED = dict(SKELETON, size=(18, 22), cx=8, leg=7, torso=6, head=3.2, leg_w=1.4, arm_w=1.4, torso_w=6,
               torso_ramp=ARMOR, head_fn=helmet_skull, torso_fn=armor_belt, offhand=round_shield,
               shoulder=steel_pad, belt="4c3e24", shadow_r=6,
               weapon=make_blade(6, "c7dcd0", "ffffff", guard="f9c22b", grip="4c3e24"))
# łucznik celuje: ręka z łukiem do przodu, druga naciąga cięciwę
ARCHER_ATTACK = [
    {"arm_front": 95, "arm_back": 60, "draw": 1, "lean": 0},
    {"arm_front": 92, "arm_back": 80, "draw": 3, "lean": -1},
    {"arm_front": 98, "arm_back": 40, "draw": 0, "lean": 1},
]


def skeleton_anims(spec, attack, walk_weapon):
    walk = [humanoid(spec, p) for p in walk_poses(weapon=walk_weapon)]
    return {"walk": walk, "attack": [humanoid(spec, p) for p in attack],
            "hit": [flash(humanoid(spec, {"weapon": walk_weapon}))]}


# ================================================================ mumia 28x32
BANDAGE = ["966c6c", "ab947a", "b2ba90", "c7dcd0"]
WRAP_DARK = {"c7dcd0": "b2ba90", "b2ba90": "ab947a", "ab947a": "966c6c", "966c6c": "694f62"}


def mummy_head(img, hx, hy, pose):
    # złote nakrycie głowy faraona w niebieskie pasy, opadające za uszy
    for y in range(hy - 5, hy + 4):
        for x in range(hx - 6, hx - 1):
            if y < hy - 2 or x < hx - 3:
                if alpha(img, x, y) or y > hy - 2:
                    px(img, x, y, C("f9c22b" if (y + 10) % 3 else "4d65b4"))
    rect(img, hx - 3, hy - 5, hx + 2, hy - 5, C("f9c22b"))
    px(img, hx, hy - 6, C("e6904e"))
    glow = "30e1b9" if pose.get("cast") else "8ff8e2"
    px(img, hx + 1, hy - 1, C(glow))           # świecące oczy
    px(img, hx + 3, hy - 1, C(glow))


def mummy_chest(img, sh_x, sh_y, cx, hip_y, pose):
    rect(img, sh_x - 3, sh_y, sh_x + 3, sh_y, C("f9c22b"))   # złoty kołnierz
    rect(img, sh_x - 2, sh_y + 1, sh_x + 2, sh_y + 1, C("4d65b4"))
    px(img, sh_x, sh_y + 2, C("e83b3b"))


MUMMY = {"size": (28, 32), "cx": 13, "leg": 8, "torso": 9, "head": 4.0, "head_dx": 2, "neck": 0, "leg_w": 3.0,
         "arm": 7.5, "arm_w": 2.6, "torso_w": 10, "torso_ramp": BANDAGE, "head_ramp": BANDAGE, "head_fn": mummy_head,
         "limb": "c7dcd0", "limb_dark": "ab947a", "leg_col": "b2ba90", "leg_dark": "ab947a",
         "boot": ("966c6c", "ab947a"), "hand": "b2ba90", "shadow_r": 10, "torso_fn": mummy_chest}


def wrap(img):
    """Ukośne pasy bandaży i zwisające strzępy."""
    res = img.copy()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = img.getpixel((x, y))
            hx = "%02x%02x%02x" % (r, g, b)
            if a == 255 and hx in WRAP_DARK and (x + 2 * y) % 5 == 0:
                px(res, x, y, C(WRAP_DARK[hx]))
    return res


def mummy(pose):
    return wrap(humanoid(MUMMY, pose))


def mummy_anims():
    # ręce wyciągnięte przed siebie, ciężki, kołyszący się krok
    walk = []
    for f, p in enumerate(walk_poses(amp=2.0)):
        s = math.sin(2 * math.pi * f / 4)
        walk.append(dict(p, arm_front=80 + 8 * s, arm_back=70 - 8 * s, lean=1 if f % 2 else 0))
    attack = [{"arm_front": 150, "arm_back": 120, "lean": -1, "legs": (1, -1)},
              {"arm_front": 95, "arm_back": 80, "lean": 1, "legs": (3, -2)},
              {"arm_front": 60, "arm_back": 50, "lean": 2, "legs": (2, -2), "bob": 1}]
    cast = [{"arm_front": 140 + 8 * k, "arm_back": 130 - 8 * k, "cast": 1, "lean": -1, "bob": -(k % 2)}
            for k in range(4)]
    return {"walk": [mummy(p) for p in walk], "attack": [mummy(p) for p in attack],
            "cast": [mummy(p) for p in cast], "hit": [flash(mummy(walk[0]))]}


# ================================================================ piramida 80x64
PYR_LIT = ["e6904e", "fbb954"]
PYR_DARK = ["9e4539", "cd683d"]
APEX = (38, 2)
FRONT_L, FRONT_R, BACK_R = (2, 62), (60, 62), (78, 54)
DOOR_X = 31


def pyramid():
    img = new(80, 64)
    poly(img, [APEX, FRONT_R, BACK_R], C(PYR_DARK[0]))
    poly(img, [APEX, FRONT_L, FRONT_R], C(PYR_LIT[0]))
    for y in range(64):
        for x in range(80):
            if not alpha(img, x, y):
                continue
            lit = img.getpixel((x, y))[:3] == C(PYR_LIT[0])[:3]
            ramp = PYR_LIT if lit else PYR_DARK
            row = y // 4
            joint = y % 4 == 3 or (x + (row % 2) * 3) % 6 == 5
            col = ramp[0] if joint else ramp[1]
            # krawędź od strony światła jaśniejsza, piasek nawiany przy podstawie
            if lit and joint and h01(x // 6, row, 9) < 0.25:
                col = ramp[1]
            if y > 57 and h01(x // 2, y, 4) < 0.35:
                col = "fbb954" if lit else "e6904e"
            px(img, x, y, C(col))
    # grzbiet między ścianami
    line(img, APEX[0], APEX[1], FRONT_R[0], FRONT_R[1], C("f9c22b"), 1)
    # złoty szczyt
    poly(img, [(APEX[0], APEX[1] - 1), (APEX[0] - 4, APEX[1] + 6), (APEX[0] + 4, APEX[1] + 6)], C("f9c22b"))
    px(img, APEX[0] - 1, APEX[1] + 3, C("fbff86"))
    # wejście: ciemny otwór z nadprożem i świecącymi oczami w środku
    rect(img, DOOR_X - 6, 46, DOOR_X + 6, 47, C("7a3045"))
    rect(img, DOOR_X - 5, 48, DOOR_X + 5, 62, C("2e222f"))
    rect(img, DOOR_X - 4, 49, DOOR_X + 4, 62, C("323353"))
    for x in (DOOR_X - 2, DOOR_X + 1):
        px(img, x, 53, C("30e1b9"))
    for y in range(48, 63):
        px(img, DOOR_X - 6, y, C("7a3045"))
        px(img, DOOR_X + 6, y, C("9e4539"))
    # hieroglify obok wejścia
    for gx, gy in ((DOOR_X - 13, 40), (DOOR_X + 10, 40), (DOOR_X - 15, 50), (DOOR_X + 12, 50)):
        rect(img, gx, gy, gx + 1, gy + 2, C("9e4539"))
        px(img, gx + 2, gy, C("9e4539"))
    outline(img, OUT)
    return img


# ================================================================ portal 4x 28x18
PORTAL_RING = ["6b3e75", "905ea9", "a884f3", "eaaded"]


def portal(f):
    img = new(28, 18)
    cx, cy, rx, ry = 13.5, 9.0, 13.0, 8.0
    for y in range(18):
        for x in range(28):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            d = math.sqrt(dx * dx + dy * dy)
            if d > 1.0:
                continue
            ang = math.atan2(dy, dx)
            # spirala obracająca się z klatkami
            swirl = math.sin(ang * 2 + d * 7 - f * math.pi / 2)
            if d > 0.78:
                k = 1 + (1 if swirl > 0.3 else 0) + (1 if math.sin(ang + f * math.pi / 2) > 0.85 else 0)
                col = PORTAL_RING[k]
            elif d > 0.3:
                col = "6b3e75" if swirl > 0.2 else ("484a77" if swirl > -0.4 else "323353")
            else:
                col = "a884f3" if f % 2 == 0 else "905ea9"
            px(img, x, y, C(col))
    # iskry nad wirem
    for k in range(3):
        a = f * math.pi / 2 + k * 2 * math.pi / 3
        px(img, int(cx + math.cos(a) * 10), int(cy + math.sin(a) * 5) - 1, C("eaaded"))
    outline(img, C("45293f"))
    return img


# ================================================================ MAIN


def run(out="."):
    en = os.path.join(out, "assets", "enemies")
    ob = os.path.join(out, "assets", "objects")
    for d in (en, ob):
        os.makedirs(d, exist_ok=True)
    files = []

    def save(folder, name, img, desc):
        check_palette(img, name)
        p = os.path.join(folder, name + ".png")
        img.save(p)
        files.append((os.path.relpath(p, out), img.size, desc))

    enemies = {
        "skeleton": skeleton_anims(SKELETON, ATTACK, 120),
        "skeleton_archer": skeleton_anims(ARCHER, ARCHER_ATTACK, 0),
        "skeleton_armored": skeleton_anims(ARMORED, ATTACK, 120),
        "mummy": mummy_anims(),
    }
    for name, anims in enemies.items():
        for an, frames in anims.items():
            w, h = frames[0].size
            save(en, "%s_%s" % (name, an), hstrip(frames), "%d kl. %dx%d" % (len(frames), w, h))
    save(ob, "pyramid", pyramid(), "80x64, drzwi (31, 62)")
    save(ob, "portal", hstrip([portal(f) for f in range(4)]), "4 kl. 28x18")
    print("Poziom 9 (nieumarli, piramida, portal):")
    for p, size, desc in files:
        print("  %-44s %3dx%-3d  %s" % (p, size[0], size[1], desc))
    return files


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
    run(ap.parse_args().out)

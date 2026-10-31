#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - generator grafik pixel art, ETAP 1 (teren + natura)
oraz ETAP 1b (plaza, droga na piasku, skosna droga, gory, tunel, morze z piana,
lilie, muszelki, gniazdo lucznika, palma, wciagarka mostu).

Biomy: laka/las (meadow) oraz pustynia (desert).
Paleta: wylacznie Resurrect 64 (kazdy kolor jest sprawdzany).
Skala: 1 px grafiki = 2 jednostki gry, kafelek 16x16, mapa 640x360.

Uruchomienie z katalogu glownego projektu:
    pip install pillow
    python tools/gen_art.py              # zapis do ./assets i ./preview_*.png
    python tools/gen_art.py --out inny/  # inny katalog docelowy
"""
import argparse
import json
import math
import os
import random

from PIL import Image

# ---------------------------------------------------------------- paleta
PAL_HEX = """
2e222f 3e3546 625565 966c6c ab947a 694f62 7f708a 9babb2 c7dcd0 ffffff
6e2727 b33831 ea4f36 f57d4a ae2334 e83b3b fb6b1d f79617 f9c22b 7a3045
9e4539 cd683d e6904e fbb954 4c3e24 676633 a2a947 d5e04b fbff86 165a4c
239063 1ebc73 91db69 cddf6c 313638 374e4a 547e64 92a984 b2ba90 0b5e65
0b8a8f 0eaf9b 30e1b9 8ff8e2 323353 484a77 4d65b4 4d9be6 8fd3ff 45293f
6b3e75 905ea9 a884f3 eaaded 753c54 a24b6f cf657f ed8099 831c5d c32454
f04f78 f68181 fca790 fdcbb0
""".split()
assert len(PAL_HEX) == 64
PAL_SET = set(PAL_HEX)


def C(h, a=255):
    """Kolor z palety Resurrect 64 (hex bez #)."""
    assert h in PAL_SET, "kolor spoza palety: " + h
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


SHADOW = C("2e222f", 80)  # polprzezroczysty cien pod obiektami

T = 16  # rozmiar kafelka

# ---------------------------------------------------------------- narzedzia


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def px(img, x, y, col):
    if col is not None and 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), col)


def alpha(img, x, y):
    if 0 <= x < img.width and 0 <= y < img.height:
        return img.getpixel((x, y))[3]
    return 0


def h01(x, y, seed=0):
    """Deterministyczny szum 0..1 dla pary liczb calkowitych."""
    n = (x * 374761393 + y * 668265263 + seed * 2246822519 + 12345) & 0xFFFFFFFF
    n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
    n ^= n >> 16
    return n / 0xFFFFFFFF


BAYER = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def bayer(x, y):
    return (BAYER[y & 3][x & 3] + 0.5) / 16.0


def outline(img, col, diagonal=False):
    """Kontur 1 px wokol nieprzezroczystych pikseli."""
    src = img.copy()
    w, h = img.size
    nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diagonal:
        nb += [(1, 1), (-1, -1), (1, -1), (-1, 1)]
    for y in range(h):
        for x in range(w):
            if alpha(src, x, y) == 0 and any(alpha(src, x + dx, y + dy) > 128 for dx, dy in nb):
                img.putpixel((x, y), col)
    return img


def shadow_ellipse(img, cx, cy, rx, ry, col=SHADOW):
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1:
                px(img, x, y, col)


def stack(*layers):
    out = layers[0].copy()
    for l in layers[1:]:
        out.alpha_composite(l)
    return out


LIGHT = (-0.55, -0.75, 0.55)
_l = math.sqrt(sum(c * c for c in LIGHT))
LIGHT = tuple(c / _l for c in LIGHT)


def blob(img, cx, cy, rx, ry, ramp, seed=0, rough=0.0, clump=0.0,
         facets=0, dither=0.55, bias=0.0):
    """Cieniowana 'kula' (korona drzewa, krzak, kamien).
    ramp: kolory od najciemniejszego do najjasniejszego."""
    n = len(ramp)
    for y in range(int(cy - ry) - 2, int(cy + ry) + 3):
        for x in range(int(cx - rx) - 2, int(cx + rx) + 3):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            lim = 1.0 + rough * (h01(x // 2, y // 2, seed + 3) - 0.5)
            if d > lim:
                continue
            dd = min(d, 0.999)
            nx, ny, nz = dx, dy, math.sqrt(1 - dd)
            if facets:
                ang = math.atan2(ny, nx) + seed * 0.7
                step = 2 * math.pi / facets
                ang = round(ang / step) * step - seed * 0.7
                ring = 0.45 if dd < 0.25 else (0.8 if dd < 0.7 else 0.97)
                r = math.sqrt(ring)
                nx, ny, nz = math.cos(ang) * r, math.sin(ang) * r, math.sqrt(1 - ring)
            lum = nx * LIGHT[0] + ny * LIGHT[1] + nz * LIGHT[2]
            lum = (lum + 0.25) / 1.25 + bias
            lum += clump * (h01(x // 2 + (y // 2) % 2, y // 2, seed) - 0.5)
            t = lum * n + (bayer(x, y) - 0.5) * dither
            idx = max(0, min(n - 1, int(t)))
            px(img, x, y, C(ramp[idx]))


def edge_shade(img, mid, light, dark):
    """Prosty 'walec': piksel koloru mid przy lewej/gornej krawedzi -> jasny,
    przy prawej/dolnej -> ciemny."""
    src = img.copy()
    m = C(mid)
    for y in range(img.height):
        for x in range(img.width):
            if src.getpixel((x, y)) != m:
                continue
            if alpha(src, x - 1, y) == 0:
                img.putpixel((x, y), C(light))
            elif alpha(src, x + 1, y) == 0 or alpha(src, x, y + 1) == 0:
                img.putpixel((x, y), C(dark))


def thick_line(img, x0, y0, x1, y1, w, col):
    steps = int(max(abs(x1 - x0), abs(y1 - y0)) * 2) + 1
    r = w / 2.0
    for i in range(steps + 1):
        t = i / steps
        x = x0 + (x1 - x0) * t
        y = y0 + (y1 - y0) * t
        for yy in range(int(y - r) - 1, int(y + r) + 2):
            for xx in range(int(x - r) - 1, int(x + r) + 2):
                if (xx + 0.5 - x) ** 2 + (yy + 0.5 - y) ** 2 <= r * r + 0.15:
                    px(img, xx, yy, col)


# ================================================================ TEREN
# Kafelki przejsc dzialaja jak "Match Corners" w Godot 4:
# kazdy rog kafelka ma teren (1) albo nie (0). Bity: NW=1, NE=2, SW=4, SE=8.
# Kafelek z maska m lezy w atlasie 4x5 na pozycji (m % 4, m // 4).
# Wiersz 4 to 4 dodatkowe warianty pelnego kafelka (maska 15).
# Kafelki przejsc sa NAKLADKAMI: poza ksztaltem sa przezroczyste
# i kladzie sie je na osobnej warstwie nad trawa / piaskiem.

EDGE_TERMS = [(1, 0, 0.3, 0.5), (0, 1, 1.7, 0.5), (2, 1, 2.1, 0.35),
              (1, -2, 0.9, 0.35), (3, 0, 4.0, 0.2), (0, 3, 5.2, 0.2)]


def edge_noise(x, y):
    s = 0.0
    for kx, ky, ph, amp in EDGE_TERMS:
        s += amp * math.sin(2 * math.pi * (kx * (x + 0.5) + ky * (y + 0.5)) / T + ph)
    return s / 2.1  # ~ -1..1, okresowy co 16 px -> brak szwow


def tile_field(mask, x, y, amp):
    nw, ne, sw, se = mask & 1, (mask >> 1) & 1, (mask >> 2) & 1, (mask >> 3) & 1
    u = (x + 0.5) / T
    v = (y + 0.5) / T
    # polowa drogi miedzy liniowym a smoothstep: rogi lekko zaokraglone
    u = 0.5 * u + 0.5 * u * u * (3 - 2 * u)
    v = 0.5 * v + 0.5 * v * v * (3 - 2 * v)
    f = nw * (1 - u) * (1 - v) + ne * u * (1 - v) + sw * (1 - u) * v + se * u * v
    gx = -nw * (1 - v) + ne * (1 - v) - sw * v + se * v
    gy = -nw * (1 - u) - ne * u + sw * (1 - u) + se * u
    return f + amp * edge_noise(x, y), gx, gy


def side(gx, gy):
    """>0: krawedz od lewej-gory (w cieniu), <0: od prawej-dolu (oswietlona)."""
    g = math.hypot(gx, gy)
    return (gx + gy) / (g * 1.4142) if g > 1e-6 else 0.0


def ground_texture(x, y, seed, base, specks):
    r = h01(x, y, seed)
    acc = 0.0
    for p, col in specks:
        acc += p
        if r < acc:
            return C(col)
    # drobne kamyczki 2 px
    if h01(x // 3, y // 3, seed + 9) < 0.06 and (x % 3, y % 3) == (1, 1):
        return C(specks[0][1])
    return C(base)


def ground_overlay_style(rim, base, shadow, lit, specks, amp=0.055, rim_lit=None):
    def fn(f, gx, gy, x, y, frame, var):
        if f < 0.435:
            return None
        s = side(gx, gy)
        if f < 0.5:
            return C(rim_lit) if (rim_lit and s < -0.3) else C(rim)
        if s > 0.2 and f < 0.62:
            return C(shadow) if f < 0.56 or (x + y) % 2 == 0 else ground_texture(x, y, 40 + var, base, specks)
        if lit and s < -0.2 and f < 0.56:
            return C(lit)
        return ground_texture(x, y, 40 + var * 17, base, specks)
    return {"fn": fn, "amp": amp}


WAVES = [(2, 3, 3), (10, 6, 2), (5, 11, 3), (13, 13, 2)]
WAVE_OFF = [0, 1, 2, 1]


def water_style(bank, bank_dark, edge_dark, foam, body, deep, wave):
    def fn(f, gx, gy, x, y, frame, var):
        if f < 0.40:
            return None
        s = side(gx, gy)
        if f < 0.5:
            # brzeg: ciemniejszy tuz przy wodzie po stronie cienia
            return C(bank_dark) if (f > 0.465 and s > 0.2) else C(bank)
        if f < 0.56:
            if s > 0.2:
                return C(edge_dark)
            o = WAVE_OFF[frame]
            return C(foam) if (x + o) % 4 != 3 else C(body)
        for wx, wy, ln in WAVES:
            if y == wy and (x - wx - WAVE_OFF[frame]) % T < ln and f > 0.62:
                return C(wave)
        if f > 0.88:
            t = (f - 0.88) / 0.08 + (bayer(x, y) - 0.5) * 0.6
            return C(deep) if t > 0.5 else C(body)
        return C(body)
    return {"fn": fn, "amp": 0.05}


def wang_tile(mask, style, frame=0, var=0):
    img = new(T, T)
    if mask == 0:
        return img
    for y in range(T):
        for x in range(T):
            f, gx, gy = tile_field(mask, x, y, style["amp"])
            px(img, x, y, style["fn"](f, gx, gy, x, y, frame, var))
    return img


def wang_atlas(style):
    """Atlas 64x80: 16 masek (4x4) + wiersz 4 wariantow pelnego kafelka."""
    atl = new(4 * T, 5 * T)
    for m in range(16):
        atl.paste(wang_tile(m, style), ((m % 4) * T, (m // 4) * T))
    for v in range(4):
        atl.paste(wang_tile(15, style, var=v + 1), (v * T, 4 * T))
    return atl


def water_atlas(style):
    """Atlas 64x256: wiersz = maska 0..15, kolumny = 4 klatki animacji."""
    atl = new(4 * T, 16 * T)
    for m in range(16):
        for fr in range(4):
            atl.paste(wang_tile(m, style, frame=fr), (fr * T, m * T))
    return atl


def base_tile(var, base, specks, detail, seed):
    img = Image.new("RGBA", (T, T), C(base))
    for y in range(T):
        for x in range(T):
            r = h01(x, y, seed + var * 101)
            acc = 0
            for p, col in specks:
                acc += p
                if r < acc:
                    img.putpixel((x, y), C(col))
                    break
    rng = random.Random(seed * 7 + var)
    detail(img, rng, var)
    return img


def grass_detail(img, rng, var):
    for _ in range(rng.randint(3, 5)):
        x, y = rng.randint(2, 13), rng.randint(3, 13)
        img.putpixel((x, y), C("676633"))
        img.putpixel((x - 1, y - 1), C("cddf6c"))
        img.putpixel((x + 1, y - 1), C("a2a947") if rng.random() < 0.5 else C("cddf6c"))
        img.putpixel((x, y - 2), C("cddf6c")) if rng.random() < 0.4 else None
    if var == 3:  # wariant z mala koniczyna
        x, y = rng.randint(3, 11), rng.randint(4, 11)
        for dx, dy in [(0, 0), (1, 0), (0, 1), (1, 1)]:
            img.putpixel((x + dx, y + dy), C("547e64"))
        img.putpixel((x, y), C("92a984"))


def sand_detail(img, rng, var):
    for _ in range(rng.randint(0, 2)):
        x, y = rng.randint(2, 10), rng.randint(3, 13)
        ln = rng.randint(3, 5)
        for i in range(ln):
            img.putpixel((x + i, y), C("fbb954"))
            img.putpixel((x + i, y + 1), C("cd683d"))
    if var == 2:
        x, y = rng.randint(3, 12), rng.randint(3, 12)
        img.putpixel((x, y), C("9e4539"))
        img.putpixel((x - 1, y), C("ab947a"))


def grass_tiles():
    sp = [(0.045, "676633"), (0.02, "cddf6c")]
    row = new(4 * T, T)
    for v in range(4):
        row.paste(base_tile(v, "a2a947", sp, grass_detail, 11), (v * T, 0))
    return row


def sand_tiles():
    sp = [(0.05, "cd683d"), (0.03, "fbb954")]
    row = new(4 * T, T)
    for v in range(4):
        row.paste(base_tile(v, "e6904e", sp, sand_detail, 23), (v * T, 0))
    return row


# Style nakladek
ROAD = ground_overlay_style(rim="676633", rim_lit="cddf6c", base="ab947a", shadow="966c6c", lit=None,
                            specks=[(0.06, "966c6c"), (0.03, "c7dcd0")])
SAND_ON_GRASS = ground_overlay_style(rim="676633", rim_lit="cddf6c", base="fbb954", shadow="e6904e", lit=None,
                                     specks=[(0.07, "e6904e"), (0.02, "fbff86")])
DESERT_PATH = ground_overlay_style(rim="9e4539", rim_lit="fbb954", base="fbb954", shadow="cd683d", lit=None,
                                   specks=[(0.06, "e6904e"), (0.02, "fbff86")])
WATER = water_style(bank="ab947a", bank_dark="966c6c", edge_dark="484a77", foam="8fd3ff",
                    body="4d9be6", deep="4d65b4", wave="8fd3ff")
OASIS = water_style(bank="cd683d", bank_dark="9e4539", edge_dark="484a77", foam="8fd3ff",
                    body="4d9be6", deep="4d65b4", wave="8fd3ff")
# Woda na trawie i na piasku ma ten sam ksztalt; rozni sie tylko kolorem brzegu.


# ---------------------------------------------------------------- most, miejsce budowy
WOOD = ["45293f", "4c3e24", "966c6c", "ab947a", "c7dcd0"]


def bridge_h():
    """Most nad pionowa rzeka (droga biegnie poziomo). 48x32."""
    img = new(48, 32)
    sh = new(48, 32)
    for x in range(3, 48):
        for y in range(27, 30):
            px(sh, x, y, SHADOW)
    # belka nosna (grubosc mostu)
    for x in range(1, 47):
        for y in range(24, 28):
            px(img, x, y, C("4c3e24") if y > 25 else C("966c6c"))
    # deski (prostopadle do kierunku drogi)
    for x in range(1, 47):
        plank = x // 4
        gap = x % 4 == 3
        for y in range(5, 25):
            if gap:
                c = C("966c6c")
            else:
                c = C("ab947a")
                if x % 4 == 0 and plank % 3 == 0:
                    c = C("c7dcd0")
                if h01(x, y, 77) < 0.06:
                    c = C("966c6c")
                if (y + plank * 3) % 9 == 0 and x % 4 == 1:
                    c = C("4c3e24")  # gwozdz / sek
            px(img, x, y, c)
    # porecze: gorne i dolne, ze slupkami
    for rail_y in (3, 22):
        for x in range(1, 47):
            px(img, x, rail_y, C("ab947a"))
            px(img, x, rail_y + 1, C("4c3e24"))
        for x in (2, 13, 24, 35, 45):
            for y in range(rail_y - 2, rail_y + 3):
                px(img, x, y, C("966c6c"))
                px(img, x + 1, y, C("4c3e24"))
            px(img, x, rail_y - 2, C("c7dcd0"))
    outline(img, C("2e222f"))
    return stack(sh, img)


def bridge_v():
    """Most nad pozioma rzeka (droga biegnie pionowo). 32x48."""
    img = new(32, 48)
    sh = new(32, 48)
    for y in range(4, 47):
        for x in range(27, 30):
            px(sh, x, y, SHADOW)
    for y in range(1, 47):
        plank = y // 4
        gap = y % 4 == 3
        for x in range(5, 27):
            if gap:
                c = C("966c6c")
            else:
                c = C("ab947a")
                if y % 4 == 0 and plank % 3 == 0:
                    c = C("c7dcd0")
                if h01(x, y, 78) < 0.06:
                    c = C("966c6c")
            px(img, x, y, c)
    # bok mostu widoczny na dole (grubosc)
    for x in range(5, 27):
        for y in (45, 46):
            px(img, x, y, C("4c3e24"))
    for rail_x in (3, 27):
        for y in range(0, 46):
            px(img, rail_x, y, C("ab947a"))
            px(img, rail_x + 1, y, C("4c3e24"))
        for y in (1, 12, 23, 34, 44):
            for x in range(rail_x - 1, rail_x + 3):
                px(img, x, y, C("966c6c"))
            px(img, rail_x - 1, y, C("c7dcd0"))
    outline(img, C("2e222f"))
    return stack(sh, img)


STONE = ["3e3546", "625565", "7f708a", "9babb2", "c7dcd0"]


def build_spot(fill="966c6c", fill_light="ab947a", seed=5):
    """Miejsce budowy wiezy: kamienny okrag, 32x22."""
    w, h = 32, 22
    img = new(w, h)
    cx, cy, rx, ry = 16, 11, 13.5, 8.5
    # ubita ziemia w srodku, cien przy lewej-gornej krawedzi (wglebienie)
    for y in range(h):
        for x in range(w):
            dx = (x + 0.5 - cx) / rx
            dy = (y + 0.5 - cy) / ry
            d = dx * dx + dy * dy
            if d <= 1:
                c = C(fill_light)
                if d > 0.55 and (dx + dy) < -0.3:
                    c = C(fill)
                if h01(x, y, seed) < 0.08:
                    c = C(fill)
                px(img, x, y, c)
    # kamienie na obwodzie
    n = 16
    for i in range(n):
        a = 2 * math.pi * i / n
        sx = cx + math.cos(a) * (rx - 0.5)
        sy = cy + math.sin(a) * (ry - 0.5)
        blob(img, sx, sy, 2.4 + 0.5 * h01(i, 0, seed), 1.9, STONE[1:], seed=i, facets=5, dither=0.3)
    outline(img, C("2e222f"))
    return img


# ================================================================ NATURA
LEAF = ["165a4c", "239063", "1ebc73", "91db69"]
LEAF_OLIVE = ["374e4a", "676633", "a2a947", "cddf6c"]
PINE = ["313638", "374e4a", "547e64", "92a984"]
BARK = ["45293f", "4c3e24", "966c6c"]


def trunk(img, cx, top, bottom, w=4):
    x0 = cx - w // 2
    for y in range(top, bottom + 1):
        for x in range(x0, x0 + w):
            c = "4c3e24"
            if x == x0:
                c = "966c6c"
            elif x == x0 + w - 1:
                c = "45293f"
            if y == bottom and (x == x0 or x == x0 + w - 1):
                continue
            px(img, x, y, C(c))
    # korzenie
    px(img, x0 - 1, bottom, C("4c3e24"))
    px(img, x0 + w, bottom, C("45293f"))


def tree_deciduous(variant):
    w, h = 24, 32
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 14, 29.5, 9, 2.3)
    trunk(img, 12, 20, h - 2)
    if variant == 0:      # okragly
        parts = [(12, 11, 9.5, 9), (7, 15, 5, 4.5), (17, 15, 5, 4.5), (12, 6, 6, 5)]
        ramp, seed = LEAF, 3
    elif variant == 1:    # wyzszy, owalny
        parts = [(12, 13, 8, 10), (12, 6, 6, 5.5), (8, 17, 4.5, 4), (16, 18, 4.5, 4)]
        ramp, seed = LEAF, 7
    else:                 # szeroki, oliwkowy (stare drzewo)
        parts = [(12, 13, 10.5, 8), (6, 14, 5, 5), (18, 13, 5, 5), (11, 7, 6, 5)]
        ramp, seed = LEAF_OLIVE, 11
    parts.sort(key=lambda p: p[1])
    for i, (cx, cy, rx, ry) in enumerate(parts):
        blob(img, cx, cy, rx, ry, ramp, seed=seed + i, rough=0.35, clump=0.35)
    outline(img, C("313638"))
    return stack(sh, img)


def tree_conifer(variant):
    w, h = 24, 32
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 14, 29.5, 8, 2.2)
    trunk(img, 12, 24, h - 2, w=3 if variant else 4)
    tiers = [(14, 27, 10.5), (7, 20, 8.5), (1, 12, 6)] if variant == 0 else \
            [(16, 27, 9), (10, 22, 7.5), (5, 16, 6), (1, 10, 4)]
    cx = 12
    for ti, (top, bot, hw) in enumerate(tiers):  # od dolu: wyzsze pietra przykrywaja nizsze
        for y in range(top, bot + 1):
            t = (y - top) / max(1, bot - top)
            half = hw * t + 0.6
            for x in range(int(cx - half) - 1, int(cx + half) + 2):
                xo = x + 0.5 - cx
                if abs(xo) > half:
                    continue
                # postrzepiony dol pietra
                if y >= bot - 1 and h01(x, ti, 31) < 0.45 and abs(xo) > 1:
                    continue
                lum = 0.55 - 0.55 * (xo / (hw + 0.1)) - 0.25 * t
                lum += 0.25 * (h01(x // 2, y, ti + 50) - 0.5)
                tt = lum * 4 + (bayer(x, y) - 0.5) * 0.6
                px(img, x, y, C(PINE[max(0, min(3, int(tt)))]))
    outline(img, C("313638"))
    return stack(sh, img)


def bush(variant):
    w, h = 16, 12
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 9, 10, 7, 1.8)
    if variant == 0:
        parts = [(5, 7, 4, 3.5), (11, 7, 4, 3.5), (8, 5, 4.5, 4)]
    else:
        parts = [(6, 6, 5, 4.5), (11, 7.5, 4, 3.2)]
    for i, (cx, cy, rx, ry) in enumerate(sorted(parts, key=lambda p: p[1])):
        blob(img, cx, cy, rx, ry, LEAF, seed=20 + i + variant * 5, rough=0.3, clump=0.3)
    if variant == 1:  # krzak z jagodami
        for x, y in [(4, 5), (8, 3), (7, 7), (11, 6), (12, 9)]:
            px(img, x, y, C("b33831"))
            px(img, x - 1, y - 1, C("f68181")) if (x + y) % 2 else None
    outline(img, C("313638"))
    return stack(sh, img)


def rock(variant, ramp=STONE, outline_col="2e222f", moss=True):
    sizes = [(12, 9, 5, 3.6), (16, 11, 7, 4.6), (9, 7, 3.6, 2.8)]
    w, h, rx, ry = sizes[variant]
    img, sh = new(w, h), new(w, h)
    cx, cy = w / 2 - 0.5, h - ry - 1.5
    shadow_ellipse(sh, cx + 1.5, h - 1.6, rx, 1.6)
    blob(img, cx, cy, rx, ry, ramp, seed=40 + variant, facets=6, rough=0.2, dither=0.2)
    if moss and variant == 1:
        for x in range(int(cx - 3), int(cx + 1)):
            if alpha(img, x, int(cy - ry + 1)):
                px(img, x, int(cy - ry + 1), C("547e64"))
                if h01(x, 1, 3) < 0.5:
                    px(img, x, int(cy - ry + 2), C("374e4a"))
    outline(img, C(outline_col))
    return stack(sh, img)


def big_rock(ramp=STONE, outline_col="2e222f", strata=False, seed=60, grass=True):
    """Duza skala / gora 48x48."""
    w, h = 48, 48
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 27, 44.5, 21, 3.2)
    parts = [(24, 29, 17, 14), (24, 16, 10, 11), (11, 36, 9, 8), (37, 36, 9.5, 8),
             (16, 22, 7, 8), (32, 23, 7, 8), (24, 39, 12, 6.5)]
    for i, (cx, cy, rx, ry) in enumerate(sorted(parts, key=lambda p: p[1])):
        blob(img, cx, cy, rx, ry, ramp, seed=seed + i, facets=6, rough=0.15, dither=0.2)
    if strata:
        for y in range(h):
            if y % 6 == 2:
                for x in range(w):
                    if alpha(img, x, y) and alpha(img, x - 1, y) and alpha(img, x + 1, y):
                        if h01(x, y, 9) < 0.75:
                            px(img, x, y, C(ramp[0]))
    else:
        # pekniecia
        for (x0, y0, x1, y1) in [(22, 14, 25, 24), (30, 30, 34, 38), (13, 33, 16, 39)]:
            steps = 12
            for i in range(steps):
                t = i / steps
                x = int(x0 + (x1 - x0) * t + (h01(i, 0, x0) - 0.5) * 1.5)
                y = int(y0 + (y1 - y0) * t)
                if alpha(img, x, y):
                    px(img, x, y, C(ramp[0]))
    outline(img, C(outline_col))
    if grass:  # kepki trawy u podnoza
        for gx in (5, 10, 40, 43, 20):
            gy = h - 3 if gx not in (5, 43) else h - 6
            for dx, dy, c in [(0, 0, "676633"), (-1, -1, "a2a947"), (1, -1, "cddf6c"), (0, -2, "a2a947")]:
                px(img, gx + dx, gy + dy, C(c))
    return stack(sh, img)


def flowers(variant):
    img = new(8, 8)
    cols = [("ed8099", "fca790"), ("fbff86", "f9c22b"), ("eaaded", "ffffff")][variant]
    spots = [[(2, 3), (5, 5), (4, 1)], [(1, 4), (4, 2), (6, 6)], [(2, 2), (5, 3), (3, 6)]][variant]
    for x, y in spots:
        px(img, x, y + 1, C("547e64"))
        px(img, x, y, C(cols[0]))
        px(img, x - 1, y, C(cols[1]))
        px(img, x + 1, y, C(cols[1]))
        px(img, x, y - 1, C(cols[1]))
    return img


def grass_tuft(variant):
    img = new(8, 8)
    blades = [[(1, 6, 0, 3), (3, 7, 1, 5), (5, 7, 2, 4), (6, 6, 3, 2)],
              [(2, 7, 1, 4), (4, 7, 3, 6), (5, 7, 6, 3)],
              [(1, 7, 0, 4), (3, 7, 2, 2), (4, 7, 5, 3), (6, 7, 7, 5)]][variant]
    for x0, y0, x1, y1 in blades:
        steps = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(steps + 1):
            t = i / steps
            x = round(x0 + (x1 - x0) * t)
            y = round(y0 + (y1 - y0) * t)
            c = "cddf6c" if t > 0.66 else ("a2a947" if t > 0.3 else "676633")
            px(img, x, y, C(c))
    return img


# ---------------------------------------------------------------- pustynia
CACTUS = ["313638", "374e4a", "547e64", "92a984"]
SANDSTONE = ["7a3045", "9e4539", "cd683d", "e6904e", "fbb954"]
BONE = ["966c6c", "ab947a", "c7dcd0", "ffffff"]


def capsule(img, x0, y0, x1, y1, r, ramp, seed=0):
    """Pionowy/poziomy walec z zaokraglonymi koncami, cieniowany w poziomie."""
    for y in range(int(min(y0, y1) - r) - 1, int(max(y0, y1) + r) + 2):
        for x in range(int(min(x0, x1) - r) - 1, int(max(x0, x1) + r) + 2):
            cx = min(max(x + 0.5, min(x0, x1)), max(x0, x1))
            cy = min(max(y + 0.5, min(y0, y1)), max(y0, y1))
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            d = (dx * dx + dy * dy) / (r * r)
            if d > 1:
                continue
            nx = dx / r
            ny = dy / r if x0 == x1 else dy / r
            nz = math.sqrt(max(0, 1 - nx * nx - ny * ny))
            lum = nx * LIGHT[0] + ny * LIGHT[1] * 0.5 + nz * LIGHT[2]
            lum = (lum + 0.25) / 1.25
            t = lum * len(ramp) + (bayer(x, y) - 0.5) * 0.4
            px(img, x, y, C(ramp[max(0, min(len(ramp) - 1, int(t)))]))


def cactus(variant):
    if variant == 0:  # saguaro z ramionami, 16x24
        w, h = 16, 24
        img, sh = new(w, h), new(w, h)
        shadow_ellipse(sh, 10, 22, 6, 1.6)
        capsule(img, 3.5, 8, 3.5, 12, 1.7, CACTUS)
        capsule(img, 4, 13.5, 6.5, 13.5, 1.6, CACTUS)
        capsule(img, 12, 6, 12, 10, 1.7, CACTUS)
        capsule(img, 9.5, 11.5, 12, 11.5, 1.6, CACTUS)
        capsule(img, 8, 4, 8, 21, 2.8, CACTUS)
        for y in range(4, 21, 3):  # kolce
            px(img, 6, y, C("c7dcd0"))
            px(img, 10, y + 1, C("c7dcd0"))
        px(img, 8, 1, C("ed8099"))
        px(img, 7, 2, C("cf657f"))
    else:  # okragly "beczkowy" 12x12
        w, h = 12, 12
        img, sh = new(w, h), new(w, h)
        shadow_ellipse(sh, 7, 10, 5, 1.5)
        blob(img, 6, 6.5, 4.5, 4.5, CACTUS, seed=3, dither=0.3, bias=0.15)
        for x in (4, 6, 8):
            for y in range(3, 10):
                if alpha(img, x, y) and h01(x, y, 1) < 0.7:
                    px(img, x, y, C("374e4a"))
        px(img, 6, 2, C("f9c22b"))
        px(img, 5, 2, C("ed8099"))
        px(img, 7, 2, C("ed8099"))
    outline(img, C("2e222f"))
    return stack(sh, img)


def dead_tree(variant):
    w, h = 24, 32
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 14, 29.5, 8, 2)
    rng = random.Random(90 + variant)
    mid = C("966c6c")

    def branch(x, y, ang, ln, wd, depth):
        x2, y2 = x + math.cos(ang) * ln, y + math.sin(ang) * ln
        thick_line(img, x, y, x2, y2, wd, mid)
        if depth > 0:
            for s in (-1, 1):
                branch(x2, y2, ang + s * rng.uniform(0.35, 0.8), ln * rng.uniform(0.55, 0.75),
                       max(1.0, wd - 1.1), depth - 1)
            if depth == 2 and rng.random() < 0.6:
                branch(x2, y2, ang + rng.uniform(-0.2, 0.2), ln * 0.6, max(1.0, wd - 1.4), depth - 2)

    if variant == 0:
        branch(12, 30.5, -math.pi / 2, 12, 3.6, 3)
    else:
        branch(11, 30.5, -math.pi / 2 + 0.25, 9, 3.6, 2)
        branch(11, 26, -math.pi / 2 - 0.6, 7, 2.2, 2)
    edge_shade(img, "966c6c", "ab947a", "4c3e24")
    outline(img, C("45293f"))
    return stack(sh, img)


def desert_rock(variant):
    return rock(variant, ramp=SANDSTONE, outline_col="45293f", moss=False)


def skull():
    w, h = 16, 10
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 9, 8.5, 6, 1.5)
    blob(img, 8, 5, 3.6, 3, BONE[1:], seed=2, dither=0.2)          # czaszka
    blob(img, 8, 7.5, 2, 1.8, BONE[1:], seed=3, dither=0.2)        # pysk
    for x0, d in ((5, -1), (11, 1)):                                # rogi
        for i in range(4):
            px(img, x0 + d * i, 4 - (i // 2), C("c7dcd0") if i < 3 else C("ab947a"))
            px(img, x0 + d * i, 5 - (i // 2), C("ab947a"))
    px(img, 7, 5, C("45293f"))
    px(img, 9, 5, C("45293f"))
    px(img, 8, 8, C("966c6c"))
    outline(img, C("45293f"))
    return stack(sh, img)


def ribs():
    w, h = 16, 12
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 9, 10.5, 7, 1.4)
    for x in range(2, 14):  # kregoslup
        px(img, x, 9, C("ab947a"))
        px(img, x, 8, C("c7dcd0") if x % 2 else C("ab947a"))
    for i, x in enumerate((3, 6, 9, 12)):
        hgt = [4, 6, 6, 4][i]
        for k in range(hgt):
            px(img, x + (1 if k > hgt - 2 else 0), 8 - k - 1, C("c7dcd0") if k < hgt - 1 else C("ffffff"))
            px(img, x + 1 + (1 if k > hgt - 2 else 0), 8 - k - 1, C("ab947a"))
    outline(img, C("45293f"))
    return stack(sh, img)


def dry_bush():
    w, h = 14, 10
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 8, 8.5, 5.5, 1.4)
    rng = random.Random(5)
    for _ in range(9):
        a = -math.pi / 2 + rng.uniform(-1.3, 1.3)
        ln = rng.uniform(4, 7)
        x2, y2 = 7 + math.cos(a) * ln, 8.5 + math.sin(a) * ln
        thick_line(img, 7, 8.5, x2, y2, 1, C("9e4539"))
        px(img, int(x2), int(y2), C("e6904e"))
    outline(img, C("45293f"))
    return stack(sh, img)


# ================================================================ PODGLADY MAP
MAP_W, MAP_H = 640, 360
TW, TH = MAP_W // T, MAP_H // T + 1  # 40 x 23 kafelki (ostatni wiersz przycinany)


class Grid:
    def __init__(self):
        self.c = [[0] * (TW + 1) for _ in range(TH + 1)]

    def set(self, x, y, v=1):
        if 0 <= x <= TW and 0 <= y <= TH:
            self.c[y][x] = v

    def get(self, x, y):
        if 0 <= x <= TW and 0 <= y <= TH:
            return self.c[y][x]
        return 0

    def path(self, pts, width=2):
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            steps = max(abs(x1 - x0), abs(y1 - y0))
            for i in range(steps + 1):
                x = round(x0 + (x1 - x0) * i / steps)
                y = round(y0 + (y1 - y0) * i / steps)
                for dy in range(width):
                    for dx in range(width):
                        self.set(x + dx, y + dy)

    def ellipse(self, cx, cy, rx, ry):
        for y in range(TH + 1):
            for x in range(TW + 1):
                if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1:
                    self.set(x, y)

    def mask(self, tx, ty):
        return (self.get(tx, ty) | self.get(tx + 1, ty) << 1 |
                self.get(tx, ty + 1) << 2 | self.get(tx + 1, ty + 1) << 3)


def render_layer(grid, tiles_by_mask, full_variants=None, seed=0):
    layer = new(TW * T, TH * T)
    for ty in range(TH):
        for tx in range(TW):
            m = grid.mask(tx, ty)
            if m == 0:
                continue
            tile = tiles_by_mask[m]
            if m == 15 and full_variants and h01(tx, ty, seed) < 0.5:
                tile = full_variants[int(h01(tx, ty, seed + 1) * len(full_variants))]
            layer.alpha_composite(tile, (tx * T, ty * T))
    return layer


def render_base(row_img, seed):
    tiles = [row_img.crop((i * T, 0, (i + 1) * T, T)) for i in range(4)]
    layer = new(TW * T, TH * T)
    for ty in range(TH):
        for tx in range(TW):
            r = h01(tx, ty, seed)
            i = 0 if r < 0.45 else 1 if r < 0.75 else 2 if r < 0.92 else 3
            layer.paste(tiles[i], (tx * T, ty * T))
    return layer


def atlas_tiles(atlas):
    by_mask = [atlas.crop(((m % 4) * T, (m // 4) * T, (m % 4 + 1) * T, (m // 4 + 1) * T)) for m in range(16)]
    full = [atlas.crop((v * T, 4 * T, (v + 1) * T, 5 * T)) for v in range(4)]
    return by_mask, full


def water_tiles(atlas, frame=0):
    return [atlas.crop((frame * T, m * T, (frame + 1) * T, (m + 1) * T)) for m in range(16)]


class Placer:
    def __init__(self, blocked_alpha, rng):
        self.block = blocked_alpha.load()
        self.w, self.h = blocked_alpha.size
        self.items = []  # (x_bottom_center, y_bottom, img)
        self.rng = rng

    def free(self, x, y, fw, gap):
        if x - fw < 2 or x + fw > MAP_W - 2 or y - 4 < 0 or y > MAP_H + 6:
            return False
        for yy in range(int(y - 5), int(y + 2)):
            for xx in range(int(x - fw), int(x + fw) + 1):
                if 0 <= xx < self.w and 0 <= yy < self.h and self.block[xx, yy] > 0:
                    return False
        for ix, iy, _, g in self.items:
            if abs(ix - x) < max(g, gap) and abs(iy - y) < max(g, gap) * 0.7:
                return False
        return True

    def put(self, img, x, y, gap=0, force=False):
        if force or self.free(x, y, img.width * 0.35, gap):
            self.items.append((x, y, img, gap))
            return True
        return False

    def scatter(self, imgs, count, region, gap, tries=400):
        x0, y0, x1, y1 = region
        n = 0
        for _ in range(tries):
            if n >= count:
                break
            img = self.rng.choice(imgs)
            x = self.rng.randint(x0, x1)
            y = self.rng.randint(y0, y1)
            if self.put(img, x, y, gap):
                n += 1

    def draw(self, canvas):
        for x, y, img, _ in sorted(self.items, key=lambda it: it[1]):
            canvas.alpha_composite(img, (int(x - img.width // 2), int(y - img.height)))


def blocked_mask(*layers):
    m = Image.new("L", (TW * T, TH * T), 0)
    for l in layers:
        a = l.getchannel("A").point(lambda v: 255 if v > 0 else 0)
        m = Image.composite(Image.new("L", m.size, 255), m, a)
    # margines 3 px wokol drog/wody
    from PIL import ImageFilter
    return m.filter(ImageFilter.MaxFilter(7))


def preview_meadow(A):
    road, water, sand = Grid(), Grid(), Grid()
    # droga: wejscie z lewej, serpentyna, wyjscie z prawej
    road.path([(0, 6), (14, 6), (14, 15), (25, 15), (25, 7), (33, 7), (33, 12), (41, 12)])
    # rzeka z gory na dol, przecina droge pod mostem
    water.path([(7, 0), (7, 3), (6, 4), (6, 10), (7, 11), (7, 16), (5, 18), (5, 24)])
    # staw z plaza
    sand.ellipse(32.5, 18.5, 5.0, 3.4)
    water.ellipse(32.5, 18.6, 3.6, 2.2)

    grass = render_base(A["grass"], 5)
    sand_l = render_layer(sand, *atlas_tiles(A["sand_overlay"]), seed=8)
    road_l = render_layer(road, *atlas_tiles(A["road"]), seed=3)
    water_l = render_layer(water, water_tiles(A["water"]))
    canvas = stack(grass, sand_l, road_l, water_l)

    rng = random.Random(42)
    pl = Placer(blocked_mask(sand_l, road_l, water_l), rng)
    # most: rzeka kolumny 6-7 (srodek x=112), droga wiersze 6-7 (srodek y=112)
    pl.put(A["bridge_h"], 112, 128, gap=30, force=True)
    for bx, by in [(178, 140), (300, 196), (360, 160), (448, 96), (500, 230)]:
        pl.put(A["build_spot"], bx, by, gap=20)
    pl.put(A["big_rock"], 600, 56, gap=30)
    trees_d = [A["tree_round"], A["tree_oval"], A["tree_wide"]]
    trees_c = [A["pine_tall"], A["pine_slim"]]
    pl.scatter(trees_c, 14, (430, 20, 640, 120), 11)
    pl.scatter(trees_d, 16, (0, 230, 110, 370), 11)
    pl.scatter(trees_d + trees_c, 14, (150, 0, 400, 80), 13)
    pl.scatter(trees_d, 6, (560, 230, 640, 370), 12)
    pl.scatter([A["bush_round"], A["bush_berry"]], 12, (0, 0, 640, 370), 14)
    pl.scatter([A["rock_small"], A["rock_medium"], A["rock_tiny"]], 9, (0, 0, 640, 370), 12)
    pl.scatter([A["flowers_pink"], A["flowers_yellow"], A["flowers_white"]], 30, (0, 0, 640, 370), 8)
    pl.scatter([A["grass_tuft_a"], A["grass_tuft_b"], A["grass_tuft_c"]], 40, (0, 0, 640, 370), 6)
    pl.draw(canvas)
    return canvas.crop((0, 0, MAP_W, MAP_H))


def preview_desert(A):
    path, water = Grid(), Grid()
    path.path([(0, 15), (10, 15), (10, 5), (22, 5), (22, 17), (31, 17), (31, 8), (41, 8)])
    water.ellipse(15.5, 12, 2.6, 1.8)

    sand = render_base(A["sand"], 9)
    path_l = render_layer(path, *atlas_tiles(A["desert_path"]), seed=4)
    water_l = render_layer(water, water_tiles(A["oasis_water"]))
    canvas = stack(sand, path_l, water_l)

    rng = random.Random(7)
    pl = Placer(blocked_mask(path_l, water_l), rng)
    for bx, by in [(132, 200), (240, 150), (300, 230), (410, 220), (560, 180)]:
        pl.put(A["build_spot_desert"], bx, by, gap=20)
    pl.put(A["mesa"], 56, 64, gap=30)
    pl.put(A["mesa"], 590, 330, gap=30)
    pl.scatter([A["dead_tree_a"], A["dead_tree_b"]], 7, (0, 0, 640, 370), 22)
    pl.scatter([A["cactus_tall"], A["cactus_round"]], 16, (0, 0, 640, 370), 14)
    pl.scatter([A["desert_rock_small"], A["desert_rock_medium"], A["desert_rock_tiny"]], 14, (0, 0, 640, 370), 12)
    pl.scatter([A["skull"], A["ribs"]], 4, (0, 0, 640, 370), 30)
    pl.scatter([A["dry_bush"]], 16, (0, 0, 640, 370), 10)
    pl.draw(canvas)
    return canvas.crop((0, 0, MAP_W, MAP_H))


def overview(groups, scale=4):
    """Arkusz z wszystkimi grafikami na ciemnym tle (do oceny stylu)."""
    pad = 6
    rows = []
    for title, items in groups:
        w = sum(im.width for _, im in items) + pad * (len(items) + 1)
        h = max(im.height for _, im in items) + pad * 2
        row = Image.new("RGBA", (w, h), C("313638"))
        x = pad
        for _, im in items:
            row.alpha_composite(im, (x, h - pad - im.height))
            x += im.width + pad
        rows.append(row)
    W = max(r.width for r in rows)
    H = sum(r.height for r in rows) + 2 * (len(rows) - 1)
    sheet = Image.new("RGBA", (W, H), C("2e222f"))
    y = 0
    for r in rows:
        sheet.alpha_composite(r, (0, y))
        y += r.height + 2
    return sheet.resize((W * scale, H * scale), Image.NEAREST)


# ================================================================ ETAP 1b
# Dodatki: plaza, droga na piasku, skosna droga, gory, tunel, morze z piana,
# lilie, muszelki, gniazdo lucznika, palma, wciagarka mostu.

# ---------------------------------------------------------------- 1. plaza
BEACH_TUFTS = {0: [(4, 6), (12, 12)], 1: [(9, 5)], 2: [(3, 12), (12, 4)], 3: [], 4: [(7, 9), (13, 13)]}
TUFT_PAT = {(0, 0): "676633", (-1, -1): "a2a947", (1, -1): "cddf6c", (0, -2): "a2a947"}
BEACH_BASE = "fdcbb0"


def beach_style():
    """Trawa -> piasek: miekka, postrzepiona krawedz i kepki trawy na piasku."""
    specks = [(0.38, "fbb954"), (0.03, "e6904e"), (0.02, "ab947a")]

    def fn(f, gx, gy, x, y, frame, var):
        ff = f + (bayer(x, y) - 0.5) * 0.09 + (h01(x, y, 77) - 0.5) * 0.07
        if ff < 0.47:
            return None
        if ff < 0.57 and h01(x, y, 91) < 0.38:  # zdzbla trawy na skraju piasku
            return C("a2a947") if h01(x, y, 92) < 0.6 else C("676633")
        if f > 0.62:
            for cx, cy in BEACH_TUFTS[var]:
                c = TUFT_PAT.get((x - cx, y - cy))
                if c:
                    return C(c)
        if side(gx, gy) > 0.2 and ff < 0.6:
            return C("e6904e")
        return ground_texture(x, y, 140 + var * 17, BEACH_BASE, specks)
    return {"fn": fn, "amp": 0.075}


# ---------------------------------------------------------------- 2. droga na piasku


def stone_road_style():
    """Ubita ziemia z plaskimi kamieniami, ciemniejsza od piasku."""
    earth_specks = [(0.08, "694f62"), (0.05, "ab947a")]

    def fn(f, gx, gy, x, y, frame, var):
        if f < 0.435:
            return None
        s = side(gx, gy)
        if f < 0.5:
            return C("fdcbb0") if s < -0.3 else C("cd683d")
        if s > 0.2 and f < 0.58:
            return C("694f62")
        # plaskie kamienie: najwyzej jeden w kazdej komorce 4x4, nie wychodzi poza kafelek
        cx_, cy_ = x // 4, y // 4
        sd = 510 + var * 7
        if f > 0.56 and h01(cx_, cy_, sd) < 0.38:
            sw = 2 + (h01(cx_, cy_, sd + 1) < 0.5)
            ox = int(h01(cx_, cy_, sd + 2) * (4 - sw))
            oy = int(h01(cx_, cy_, sd + 3) * 2)
            lx, ly = x % 4 - ox, y % 4 - oy
            if 0 <= lx < sw and 0 <= ly < 2:
                if ly == 0:
                    return C("c7dcd0") if lx == 0 else C("9babb2")
                return C("7f708a")
        return ground_texture(x, y, 160 + var * 13, "966c6c", earth_specks)
    return {"fn": fn, "amp": 0.055}


# ---------------------------------------------------------------- 3. skosna droga


def blend(u):
    u = min(1.0, max(0.0, u))
    return 0.5 * u + 0.5 * u * u * (3 - 2 * u)


def path_field(pts, hw=16, amp=0.055):
    """Pole drogi z linii srodkowej. Dla odcinkow prostych daje dokladnie
    te same piksele co kafelki road.png, wiec obie czesci sie lacza."""
    segs = list(zip(pts, pts[1:]))

    def field(x, y):
        pxc, pyc = x + 0.5, y + 0.5
        best = None
        for (ax, ay), (bx, by) in segs:
            vx, vy = bx - ax, by - ay
            t = max(0.0, min(1.0, ((pxc - ax) * vx + (pyc - ay) * vy) / (vx * vx + vy * vy)))
            cx, cy = ax + vx * t, ay + vy * t
            d = math.hypot(pxc - cx, pyc - cy)
            if best is None or d < best[0]:
                best = (d, cx, cy)
        d, cx, cy = best
        f = blend(0.5 + (hw - d) / T) + amp * edge_noise(x % T, y % T)
        if d > 1e-6:
            return f, (cx - pxc) / d, (cy - pyc) / d
        return f, 0.0, 0.0
    return field


def render_path(pts, w, h, style=None):
    style = style or ROAD
    field = path_field(pts, amp=style["amp"])
    img = new(w, h)
    for y in range(h):
        for x in range(w):
            f, gx, gy = field(x, y)
            if f < 0.4:
                continue
            px(img, x, y, style["fn"](f, gx, gy, x % T, y % T, 0, 0))
    return img


# Przyklady ukladow (punkty = srodek drogi). Droga wchodzi z gory, skreca o 45 stopni.
DIAG_EXAMPLES = [
    ("gora_skos_prawo_poziomo", [(24, -40), (24, 40), (104, 120), (216, 120)]),
    ("gora_skos_lewo_poziomo", [(152, -40), (152, 40), (72, 120), (-40, 120)]),
    ("gora_skos_prawo_dol", [(24, -40), (24, 40), (104, 120), (104, 216)]),
    ("gora_skos_lewo_dol", [(152, -40), (152, 40), (72, 120), (72, 216)]),
]
DIAG_SIZE = 176  # 11 x 11 kafelkow


def diagonal_road_set():
    uniq, keys = [], {}
    layouts, canvases = {}, []
    n = DIAG_SIZE // T
    for name, pts in DIAG_EXAMPLES:
        canv = render_path(pts, DIAG_SIZE, DIAG_SIZE)
        canvases.append(canv)
        grid = []
        for ty in range(n):
            row = []
            for tx in range(n):
                tile = canv.crop((tx * T, ty * T, (tx + 1) * T, (ty + 1) * T))
                if tile.getbbox() is None:
                    row.append(-1)
                    continue
                k = tile.tobytes()
                if k not in keys:
                    keys[k] = len(uniq)
                    uniq.append(tile)
                row.append(keys[k])
            grid.append(row)
        layouts[name] = grid
    cols = 8
    rows = (len(uniq) + cols - 1) // cols
    atlas = new(cols * T, rows * T)
    for i, t in enumerate(uniq):
        atlas.paste(t, ((i % cols) * T, (i // cols) * T))
    return atlas, layouts, canvases, cols


# ---------------------------------------------------------------- 4. gory


def mountain_style():
    """Skalny plaskowyz: jasna gorna krawedz, sciana klifu od poludnia."""
    def fn(f, gx, gy, x, y, frame, var):
        g = math.hypot(gx, gy)
        south = g > 1e-6 and gy / g < -0.45  # skala jest powyzej -> pod krawedzia sciana
        if f < 0.5:
            if south:
                bottom = 0.19 + 0.05 * (h01(x, 0, 611) - 0.5)
                if f < bottom - 0.04:
                    return None
                if f < bottom:
                    return C("2e222f")
                if f > 0.47:
                    return C("7f708a")
                stripe = (x + (1 if h01(x // 3, y, 7) < 0.3 else 0)) % 3 == 0
                return C("3e3546") if stripe else C("625565")
            if f > 0.455:
                return C("2e222f")
            return None
        s = side(gx, gy)
        if s > 0.25 and f < 0.56:
            return C("c7dcd0")
        if s < -0.25 and not south and f < 0.57:
            return C("625565")
        r = h01(x // 3, y // 3, 620 + var)
        if r < 0.10 and (x + y) % 3:
            return C("625565")
        if r > 0.90 and (x + y) % 2:
            return C("9babb2")
        if h01(x, y, 630 + var) < 0.03:
            return C("3e3546")
        return C("7f708a")
    return {"fn": fn, "amp": 0.05}


PEAKS = [
    ([(24, 2, 22)], 0.42),                              # pojedynczy, osniezony
    ([(31, 2, 16), (15, 9, 15)], 0.40),                 # podwojny, osniezony
    ([(24, 5, 22)], 0.0),                               # pojedynczy, skalny
    ([(33, 7, 14), (14, 11, 14), (25, 20, 11)], 0.0),   # grzbiet, skalny
]


def peak(variant):
    w, h = 48, 48
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 27, 45.5, 21, 2.4)
    peaks, snow = PEAKS[variant]
    base = 46
    for k, (cx, top, hw) in enumerate(peaks):
        H = base - top
        for y in range(top, base + 1):
            t = (y - top) / H
            half = hw * t ** 0.85 + 0.5 + (h01(y, k, 300 + variant) - 0.5) * 1.4 * t
            ridge = cx + 3 * t * (1 if k % 2 == 0 else -0.6) + (h01(y // 2, k, 9) - 0.5)
            for x in range(int(cx - half) - 1, int(cx + half) + 2):
                if abs(x + 0.5 - cx) > half:
                    continue
                lit = x + 0.5 < ridge
                band = (int((y * 0.7 + (x if lit else -x)) / 4 + 2.2 * h01(y // 3, (x if lit else -x) // 4, 70 + k)) % 3 == 0
                        and h01(x // 2, y // 2, 80 + k) < 0.75)
                if lit:
                    col = "7f708a" if band else "9babb2"
                    if ridge - (x + 0.5) < 1.2:
                        col = "c7dcd0"
                else:
                    col = "3e3546" if band else "625565"
                if snow:
                    sy = top + H * snow + 3 * (h01(x // 2, k, 33) - 0.5) + (2 if band else 0)
                    if y < sy:
                        col = "ffffff" if lit else ("9babb2" if band else "c7dcd0")
                px(img, x, y, C(col))
    if not snow:  # glazy u podnoza
        blob(img, 7, 43.5, 4, 2.6, STONE, seed=variant + 3, facets=5, dither=0.2)
        blob(img, 41, 44, 3.5, 2.2, STONE, seed=variant + 5, facets=5, dither=0.2)
    outline(img, C("2e222f"))
    return stack(sh, img)


# ---------------------------------------------------------------- 5. tunel


def tunnel():
    w = h = 32
    img = new(w, h)
    blob(img, 16, 13, 15.5, 12.5, STONE, seed=81, facets=6, rough=0.15, dither=0.2)
    for y in range(13, h):  # sciana skalna do samego dolu
        for x in range(1, 31):
            stripe = (x + (1 if h01(x // 3, y, 8) < 0.3 else 0)) % 3 == 0
            px(img, x, y, C("3e3546") if stripe else C("625565"))
    acx, acy = 16, 21.5  # srodek luku
    for y in range(4, h):
        for x in range(w):
            dx, dy = x + 0.5 - acx, y + 0.5 - acy
            inside = (abs(dx) <= 7 and dy >= 0) or (dx * dx + dy * dy <= 49)
            ring = (abs(dx) <= 10.5 and dy >= 0) or (dx * dx + dy * dy <= 110)
            if inside:
                col = "2e222f"
                if dy > 6 and h01(x, y, 3) < 0.12:
                    col = "3e3546"
                px(img, x, y, C(col))
            elif ring:
                if dy < 0:
                    ang = math.atan2(dy, dx)
                    blk = int((ang + math.pi) / (math.pi / 7))
                    edge = abs(((ang + math.pi) / (math.pi / 7)) - round((ang + math.pi) / (math.pi / 7))) < 0.12
                    key = abs(ang + math.pi / 2) < 0.24
                else:
                    blk = int(dy // 3)
                    edge = int(dy) % 3 == 2
                    key = False
                if edge:
                    col = "3e3546"
                elif key:
                    col = "c7dcd0"
                else:
                    col = "9babb2" if (blk + (dx < 0)) % 2 == 0 else "7f708a"
                    if dx > 0 and col == "9babb2":
                        col = "7f708a"
                px(img, x, y, C(col))
    # pochodnia z lewej
    for y in (17, 18, 19):
        px(img, 3, y, C("4c3e24"))
    px(img, 3, 16, C("fb6b1d"))
    px(img, 3, 15, C("f9c22b"))
    px(img, 2, 16, C("f79617"))
    outline(img, C("2e222f"))
    return img


# ---------------------------------------------------------------- 6. morze i piana
SEA = water_style(bank="e6904e", bank_dark="cd683d", edge_dark="484a77", foam="8fd3ff",
                  body="4d9be6", deep="4d65b4", wave="8fd3ff")
FOAM_PULSE = [0, 1, 2, 1]


def foam_style():
    """Piana na granicy morza: linia przyplywa i odplywa, babelki migocza."""
    def fn(f, gx, gy, x, y, frame, var):
        ph = FOAM_PULSE[frame]
        lim = 0.535 + 0.035 * ph
        if 0.47 < f < lim and h01(x, y, 200 + frame) < 0.88:
            return C("ffffff") if (x + frame) % 3 else C("c7dcd0")
        if lim <= f < lim + 0.09 and h01(x, y, 300 + frame) < 0.22:
            return C("ffffff") if h01(x, y, 310) < 0.5 else C("8fd3ff")
        if 0.42 < f <= 0.47 and ph == 2 and h01(x, y, 400) < 0.35:
            return C("c7dcd0")  # mokry slad na piasku po fali
        return None
    return {"fn": fn, "amp": 0.05}


# ---------------------------------------------------------------- 7. lilie, muszelki


def lily_pad(flower):
    img = new(8, 8)
    for y in range(8):
        for x in range(8):
            dx, dy = x + 0.5 - 4, y + 0.5 - 4.3
            if dx * dx / 12.5 + dy * dy / 9 > 1:
                continue
            if dx > 0 and abs(dy) < 0.6 * dx:  # wciecie
                continue
            col = "239063"
            if dx + dy < -1.5:
                col = "1ebc73"
            elif dx + dy > 2:
                col = "165a4c"
            px(img, x, y, C(col))
    px(img, 3, 4, C("165a4c"))
    if flower:
        for x, y, c in [(3, 2, "fdcbb0"), (2, 3, "ed8099"), (4, 3, "ed8099"), (3, 3, "f9c22b"), (3, 1, "ed8099")]:
            px(img, x, y, C(c))
    outline(img, C("165a4c"))
    return img


def shell(variant):
    img = new(6, 6)
    if variant == 0:  # przegrzebek
        rows = ["..xx..", ".xyxy.", "xyxyxy", "xyxyxy", ".zzzz.", "..zz.."]
        cmap = {"x": "fdcbb0", "y": "fca790", "z": "cf657f"}
    elif variant == 1:  # slimak spiralny
        rows = [".xxx..", "xyyzx.", "xyxzx.", "xzzzx.", ".xxxyz", "....zz"]
        cmap = {"x": "eaaded", "y": "ffffff", "z": "a24b6f"}
    else:  # mala malza
        rows = ["......", ".xxx..", "xyyyx.", "xyyzx.", ".zzz..", "......"]
        cmap = {"x": "c7dcd0", "y": "ffffff", "z": "9babb2"}
    for y, r in enumerate(rows):
        for x, ch in enumerate(r):
            if ch in cmap:
                px(img, x, y, C(cmap[ch]))
    return img


# ---------------------------------------------------------------- 8. gniazdo lucznika


def archer_nest():
    w = h = 24
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 14, 22.5, 9, 1.6)
    for i, (cx, cy, rx, ry) in enumerate([(12, 15, 10, 6.5), (5, 13, 4.5, 4), (19, 13, 4.5, 4), (12, 19.5, 7, 3.5)]):
        blob(img, cx, cy, rx, ry, LEAF, seed=140 + i, rough=0.35, clump=0.35)
    # maszt z zielonym proporcem (za platforma)
    for y in range(1, 9):
        px(img, 16, y, C("4c3e24"))
    for x, y, c in [(17, 1, "1ebc73"), (18, 1, "1ebc73"), (19, 1, "239063"), (17, 2, "239063"),
                    (18, 2, "239063"), (19, 2, "165a4c"), (17, 3, "165a4c"), (20, 1, "239063")]:
        px(img, x, y, C(c))
    # platforma z desek
    cx, cy, rx, ry = 12, 10, 7.5, 4.5
    for y in range(int(cy - ry) - 1, int(cy + ry) + 4):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            dx, dy = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if dx * dx + dy * dy <= 1:
                col = "ab947a" if (x // 2) % 2 == 0 else "966c6c"
                if dx + dy < -0.9:
                    col = "c7dcd0" if (x // 2) % 2 == 0 else "ab947a"
                px(img, x, y, C(col))
            else:
                dy2 = (y - 1.5 + 0.5 - cy) / ry  # grubosc platformy (2 px pod spodem)
                if dx * dx + dy2 * dy2 <= 1 and dy > 0:
                    px(img, x, y, C("4c3e24"))
    # balustrada: slupki i porecz
    for i in range(10):
        a = 2 * math.pi * i / 10
        bx = int(round(cx + math.cos(a) * (rx - 0.6) - 0.5))
        by = int(round(cy + math.sin(a) * (ry - 0.6) - 0.5))
        px(img, bx, by, C("4c3e24"))
        px(img, bx, by - 1, C("966c6c"))
    # drabinka sznurowa
    for y in range(15, 23):
        px(img, 10, y, C("ab947a"))
        px(img, 13, y, C("966c6c"))
        if y % 2 == 0:
            px(img, 11, y, C("ab947a"))
            px(img, 12, y, C("966c6c"))
    outline(img, C("313638"))
    return stack(sh, img)


# ---------------------------------------------------------------- 9. palma
FROND_ANGLES = [(168, 10, 0.55), (205, 10, 0.4), (245, 9, 0.25), (290, 9, 0.25),
                (330, 10, 0.4), (12, 10, 0.55), (110, 6, 0.3)]


def _stamp(img, x, y, r, col):
    for yy in range(int(y - r) - 1, int(y + r) + 2):
        for xx in range(int(x - r) - 1, int(x + r) + 2):
            if (xx + 0.5 - x) ** 2 + (yy + 0.5 - y) ** 2 <= r * r + 0.1:
                px(img, xx, yy, col)


def coconut(img, x, y, ground=False):
    for dx, dy, c in [(0, 0, "966c6c"), (1, 0, "4c3e24"), (0, 1, "4c3e24"), (1, 1, "45293f")]:
        px(img, x + dx, y + dy, C(c))
    if ground:
        px(img, x - 2, y + 1, C("ab947a"))
        px(img, x + 3, y + 1, C("ab947a"))


def palm(sway=0, nuts=3, loose=False, fall=None, ground=False):
    w, h = 24, 40
    img, sh = new(w, h), new(w, h)
    shadow_ellipse(sh, 15, 38, 7, 1.5)
    shadow_ellipse(sh, 17, 37, 6, 1.2)
    bx, by = 9.5, 38.0
    tx, ty = 14.0 + sway, 13.0
    cxp, cyp = 9.0, 26.0
    steps = 60
    for i in range(steps + 1):  # pien: krzywa Beziera, cieniowany, z pierscieniami
        t = i / steps
        x = (1 - t) ** 2 * bx + 2 * (1 - t) * t * cxp + t * t * tx
        y = (1 - t) ** 2 * by + 2 * (1 - t) * t * cyp + t * t * ty
        r = 1.9 - 0.6 * t
        ring = int(t * 14) % 2 == 0
        for yy in range(int(y - r) - 1, int(y + r) + 2):
            for xx in range(int(x - r) - 1, int(x + r) + 2):
                dx = xx + 0.5 - x
                if dx * dx + (yy + 0.5 - y) ** 2 > r * r + 0.1:
                    continue
                if dx < -0.4 * r:
                    c = "c7dcd0" if not ring else "ab947a"
                elif dx > 0.4 * r:
                    c = "4c3e24"
                else:
                    c = "ab947a" if not ring else "966c6c"
                px(img, xx, yy, C(c))
    # liscie
    for k, (deg, ln, droop) in enumerate(FROND_ANGLES):
        a = math.radians(deg + sway * (5 if math.cos(math.radians(deg)) > 0 else 3))
        ln = ln + (sway if k in (0, 5) else 0) * 0.5
        pts = []
        for i in range(21):
            t = i / 20
            x = tx + math.cos(a) * ln * t
            y = ty + math.sin(a) * ln * t + droop * ln * t * t + sway * 0.6 * t * t
            pts.append((x, y, t))
        for x, y, t in pts:  # cien pod lisciem
            _stamp(img, x, y + 0.7, max(0.5, 1.3 * (1 - t) + 0.35), C("165a4c"))
        for x, y, t in pts:
            _stamp(img, x, y, max(0.5, 1.2 * (1 - t) + 0.3), C("239063"))
        for j, (x, y, t) in enumerate(pts):
            if t < 0.85:
                px(img, int(x), int(y), C("1ebc73"))
            if j % 3 == 1 and 0.2 < t < 0.95:  # listki opadajace w dol
                px(img, int(x), int(y) + 2, C("239063"))
                px(img, int(x), int(y) + 3, C("165a4c"))
    # kokosy
    nut_pos = [(int(tx) - 2, int(ty) + 1), (int(tx), int(ty) + 2), (int(tx) - 1, int(ty) + 3)]
    for i, (x, y) in enumerate(nut_pos[:nuts]):
        coconut(img, x, y + (1 if loose and i == nuts - 1 else 0))
    if fall:
        coconut(img, fall[0], fall[1], ground)
    outline(img, C("313638"))
    return stack(sh, img)


def hstrip(frames):
    w, h = frames[0].size
    out = new(w * len(frames), h)
    for i, f in enumerate(frames):
        out.paste(f, (i * w, 0))
    return out


# ---------------------------------------------------------------- 10. wciagarka mostu


def winch():
    img = new(8, 8)
    for y in range(1, 6):  # slupki
        px(img, 0, y, C("ab947a"))
        px(img, 1, y, C("966c6c"))
        px(img, 6, y, C("966c6c"))
        px(img, 7, y, C("4c3e24"))
    px(img, 0, 0, C("4c3e24"))
    px(img, 1, 0, C("4c3e24"))
    px(img, 6, 0, C("4c3e24"))
    for x in range(2, 6):  # beben z nawinieta lina
        px(img, x, 2, C("c7dcd0"))
        px(img, x, 3, C("ab947a"))
        px(img, x, 4, C("c7dcd0") if x % 2 else C("ab947a"))
        px(img, x, 5, C("966c6c"))
    px(img, 7, 1, C("9babb2"))  # korba
    px(img, 7, 0, C("625565"))
    for x in range(8):  # podstawa
        px(img, x, 6, C("966c6c"))
        px(img, x, 7, C("4c3e24"))
    return img


# ---------------------------------------------------------------- podglady etapu 1b


def preview_coast(A):
    beach, sea, water, road, pond = Grid(), Grid(), Grid(), Grid(), Grid()
    for x in range(TW + 1):
        bt = (9 if x < 14 else 10 if x < 27 else 11) + int(round(math.sin(x / 3.5)))
        st = bt + 8 + int(round(math.sin(x / 4.5 + 1)))
        for y in range(bt, TH + 1):
            beach.set(x, y)
        for y in range(st, TH + 1):
            sea.set(x, y)
            water.set(x, y)
    road.path([(0, 12), (14, 12), (14, 13), (27, 13), (27, 14), (41, 14)])
    water.path([(20, 0), (20, 7), (19, 9), (20, 11), (20, 19)])  # rzeka do morza
    pond.ellipse(8, 4, 2.6, 1.8)

    grass = render_base(A["grass"], 6)
    beach_l = render_layer(beach, *atlas_tiles(A["beach"]), seed=12)
    road_l = render_layer(road, *atlas_tiles(A["sand_road"]), seed=13)
    water_l = render_layer(water, water_tiles(A["sea"]))
    foam_l = render_layer(sea, water_tiles(A["sea_foam"], 0))
    pond_l = render_layer(pond, water_tiles(A["water"]))
    canvas = stack(grass, beach_l, road_l, water_l, foam_l, pond_l)

    rng = random.Random(11)
    on_grass = blocked_mask(beach_l, water_l, pond_l)
    inv_beach = beach_l.getchannel("A").point(lambda v: 0 if v > 0 else 255)
    on_beach = Image.composite(Image.new("L", inv_beach.size, 255), inv_beach,
                               blocked_mask(road_l, water_l, foam_l))
    pl = Placer(on_grass, rng)
    pl.put(A["bridge_h"], 328, 232, gap=30, force=True)
    pl.put(A["drawbridge_winch"], 358, 199, gap=6, force=True)
    for lx, ly in [(118, 64), (138, 72), (132, 58)]:
        pl.put(A["lily_pad_flower"] if lx == 138 else A["lily_pad"], lx, ly, force=True)
    for nx, ny in [(470, 46), (560, 92)]:
        pl.put(A["archer_nest"], nx, ny, gap=18, force=True)
    trees = [A["tree_round"], A["tree_oval"], A["tree_wide"], A["pine_tall"]]
    pl.scatter(trees, 22, (400, 10, 640, 130), 12)
    pl.scatter(trees, 8, (0, 90, 200, 150), 12)
    pl.scatter([A["bush_round"], A["bush_berry"]], 8, (0, 0, 640, 200), 14)
    pl.scatter([A["flowers_pink"], A["flowers_yellow"], A["grass_tuft_a"], A["grass_tuft_b"]], 30, (0, 0, 640, 200), 7)
    pl.block = on_beach.load()
    palm0 = A["palm_sway"].crop((0, 0, 24, 40))
    for x, y in [(60, 268), (150, 262), (236, 280), (420, 286), (520, 292), (600, 300), (60, 170)]:
        pl.put(palm0, x, y, gap=14)
    pl.scatter([A["shell_scallop"], A["shell_spiral"], A["shell_clam"]], 16, (0, 140, 640, 340), 10)
    pl.scatter([A["rock_tiny"]], 4, (0, 140, 640, 340), 14)
    pl.draw(canvas)
    return canvas.crop((0, 0, MAP_W, MAP_H))


def preview_mountain(A):
    mnt = Grid()
    for x in range(24, TW + 1):  # masyw w prawym gornym rogu
        b = 8 if 26 <= x <= 31 else 8 + int(round(1.4 * math.sin(x / 2.3)))
        for y in range(0, b + 1):
            mnt.set(x, y)
    for x in range(0, 7):        # masyw w lewym gornym rogu
        for y in range(0, 5 + (x % 3 == 0)):
            mnt.set(x, y)
    for x in range(33, TW + 1):  # skaly w prawym dolnym rogu
        for y in range(17 + (x % 2), TH + 1):
            mnt.set(x, y)

    grass = render_base(A["grass"], 8)
    mnt_l = render_layer(mnt, *atlas_tiles(A["mountain"]), seed=21)
    road_pts = [(136, -40), (136, 72), (264, 200), (456, 200), (456, 140)]
    road_l = new(TW * T, TH * T)
    road_l.alpha_composite(render_path(road_pts, MAP_W, MAP_H), (0, 0))
    canvas = stack(grass, mnt_l, road_l)

    rng = random.Random(5)
    pl = Placer(blocked_mask(mnt_l, road_l), rng)
    pl.put(A["tunnel_entrance"], 456, 147, gap=30, force=True)
    for name, x, y in [("peak_snow_a", 560, 92), ("peak_snow_b", 420, 70), ("peak_rock_b", 616, 48),
                       ("peak_rock_a", 48, 62), ("peak_rock_a", 600, 352)]:
        pl.put(A[name], x, y, force=True)
    for bx, by in [(220, 110), (200, 250), (330, 170), (360, 250), (560, 220)]:
        pl.put(A["build_spot"], bx, by, gap=20)
    pl.scatter([A["pine_tall"], A["pine_slim"]], 26, (0, 0, 640, 370), 12)
    pl.scatter([A["rock_small"], A["rock_medium"], A["rock_tiny"]], 14, (0, 0, 640, 370), 12)
    pl.scatter([A["grass_tuft_a"], A["grass_tuft_c"], A["flowers_white"]], 30, (0, 0, 640, 370), 7)
    pl.draw(canvas)
    return canvas.crop((0, 0, MAP_W, MAP_H))


def preview_diagonal(A, canvases):
    gap = 8
    W = len(canvases) * DIAG_SIZE + (len(canvases) + 1) * gap
    H = DIAG_SIZE + 2 * gap
    out = Image.new("RGBA", (W, H), C("313638"))
    tiles = [A["grass"].crop((i * T, 0, (i + 1) * T, T)) for i in range(4)]
    for k, canv in enumerate(canvases):
        x0 = gap + k * (DIAG_SIZE + gap)
        base = new(DIAG_SIZE, DIAG_SIZE)
        for ty in range(DIAG_SIZE // T):
            for tx in range(DIAG_SIZE // T):
                base.paste(tiles[int(h01(tx, ty, 2) * 4) % 4], (tx * T, ty * T))
        base.alpha_composite(canv)
        out.alpha_composite(base, (x0, gap))
    return out.resize((W * 3, H * 3), Image.NEAREST)


def stage_1b(A, save, terr, nat, obj, out):
    """Etap 1b: zapisuje nowe grafiki, metadane i podglady."""
    save(terr, "beach", wang_atlas(beach_style()), "plaza: trawa -> piasek, miekka krawedz, 16 masek + 4 pelne")
    save(terr, "sand_road", wang_atlas(stone_road_style()), "droga na piasku: ubita ziemia i kamienie, 16 masek + 4 pelne")
    diag_atlas, layouts, diag_canv, diag_cols = diagonal_road_set()
    save(terr, "road_diagonal", diag_atlas, "skosna droga 45 st. (atlas, uklady w road_diagonal_layout.json)")
    save(terr, "mountain", wang_atlas(mountain_style()), "skaly/plaskowyz z klifem, 16 masek + 4 pelne")
    save(terr, "tunnel_entrance", tunnel(), "wejscie do tunelu")
    save(terr, "sea", water_atlas(SEA), "morze z brzegiem pod plaze, 16 masek x 4 klatki")
    save(terr, "sea_foam", water_atlas(foam_style()), "piana przy brzegu (nakladka), 16 masek x 4 klatki")
    for i, name in enumerate(("peak_snow_a", "peak_snow_b", "peak_rock_a", "peak_rock_b")):
        save(nat, name, peak(i), "szczyt gorski" + (" ze sniegiem" if i < 2 else ""))
    save(nat, "lily_pad", lily_pad(False), "lilia wodna")
    save(nat, "lily_pad_flower", lily_pad(True), "lilia wodna z kwiatem")
    for i, name in enumerate(("shell_scallop", "shell_spiral", "shell_clam")):
        save(nat, name, shell(i), "muszelka")
    save(obj, "archer_nest", archer_nest(), "gniazdo Lesnego Lucznika")
    save(obj, "palm_sway", hstrip([palm(0), palm(1)]), "palma, kolysanie: 2 klatki 24x40")
    save(obj, "palm_coconut_fall", hstrip([
        palm(0, 3, loose=True),
        palm(0, 2, fall=(15, 21)),
        palm(0, 2, fall=(16, 30)),
        palm(0, 2, fall=(17, 36), ground=True),
    ]), "palma, spadajacy kokos: 4 klatki 24x40")
    save(obj, "drawbridge_winch", winch(), "wciagarka mostu zwodzonego")

    with open(os.path.join(terr, "road_diagonal_layout.json"), "w", encoding="utf-8") as fh:
        json.dump({
            "opis": "Indeksy kafelkow z road_diagonal.png (kolumna = i %% %d, wiersz = i // %d), -1 = pusto. "
                    "Kazdy uklad to 11x11 kafelkow; droga wchodzi z gory. Proste odcinki pasuja do road.png."
                    % (diag_cols, diag_cols),
            "columns": diag_cols,
            "layouts": layouts,
        }, fh, indent=1, ensure_ascii=False)

    pc = preview_coast(A)
    pmnt = preview_mountain(A)
    pc.resize((MAP_W * 3, MAP_H * 3), Image.NEAREST).save(os.path.join(out, "preview_coast.png"))
    pmnt.resize((MAP_W * 3, MAP_H * 3), Image.NEAREST).save(os.path.join(out, "preview_mountain.png"))
    preview_diagonal(A, diag_canv).save(os.path.join(out, "preview_road_diagonal.png"))

    ov = overview([
        ("teren", [(n, A[n]) for n in ("beach", "sand_road", "mountain", "road_diagonal")]),
        ("woda", [(n, A[n]) for n in ("sea", "sea_foam", "tunnel_entrance", "lily_pad", "lily_pad_flower",
                                      "shell_scallop", "shell_spiral", "shell_clam", "drawbridge_winch")]),
        ("gory", [(n, A[n]) for n in ("peak_snow_a", "peak_snow_b", "peak_rock_a", "peak_rock_b", "archer_nest")]),
        ("palma", [(n, A[n]) for n in ("palm_sway", "palm_coconut_fall")]),
    ])
    ov.save(os.path.join(out, "overview_extra.png"))
    return ["beach", "sand_road", "mountain"], ["sea", "sea_foam"]


# ================================================================ MAIN


def check_palette(img, name):
    for (r, g, b, a) in set(img.convert('RGBA').get_flattened_data() if hasattr(img, 'get_flattened_data') else img.getdata()):
        if a == 0:
            continue
        hx = "%02x%02x%02x" % (r, g, b)
        assert hx in PAL_SET, "%s: kolor spoza palety %s" % (name, hx)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".")
    args = ap.parse_args()
    out = args.out
    terr = os.path.join(out, "assets", "terrain")
    nat = os.path.join(out, "assets", "nature")
    os.makedirs(terr, exist_ok=True)
    os.makedirs(nat, exist_ok=True)
    obj = os.path.join(out, "assets", "objects")
    os.makedirs(obj, exist_ok=True)

    A = {}
    files = {}  # sciezka -> (obraz, opis)

    def save(folder, name, img, desc):
        A[name] = img
        check_palette(img, name)
        p = os.path.join(folder, name + ".png")
        img.save(p)
        files[os.path.relpath(p, out)] = (img.size, desc)

    # --- teren
    save(terr, "grass", grass_tiles(), "trawa, 4 warianty 16x16 w rzedzie")
    save(terr, "sand", sand_tiles(), "piasek, 4 warianty 16x16 w rzedzie")
    save(terr, "road", wang_atlas(ROAD), "droga ziemna (nakladka na trawe), 16 masek + 4 pelne")
    save(terr, "sand_overlay", wang_atlas(SAND_ON_GRASS), "plaza/piasek na trawie, 16 masek + 4 pelne")
    save(terr, "desert_path", wang_atlas(DESERT_PATH), "sciezka na pustyni, 16 masek + 4 pelne")
    save(terr, "water", water_atlas(WATER), "woda z brzegiem (na trawe), 16 masek x 4 klatki")
    save(terr, "oasis_water", water_atlas(OASIS), "woda z brzegiem (na piasek), 16 masek x 4 klatki")
    save(terr, "bridge_h", bridge_h(), "most, droga poziomo nad pionowa rzeka")
    save(terr, "bridge_v", bridge_v(), "most, droga pionowo nad pozioma rzeka")
    save(terr, "build_spot", build_spot(), "miejsce budowy wiezy (laka)")
    save(terr, "build_spot_desert", build_spot("cd683d", "e6904e", seed=6), "miejsce budowy wiezy (pustynia)")

    # --- natura laka
    for n, v in (("tree_round", 0), ("tree_oval", 1), ("tree_wide", 2)):
        save(nat, n, tree_deciduous(v), "drzewo lisciaste")
    save(nat, "pine_tall", tree_conifer(0), "drzewo iglaste")
    save(nat, "pine_slim", tree_conifer(1), "drzewo iglaste")
    save(nat, "bush_round", bush(0), "krzak")
    save(nat, "bush_berry", bush(1), "krzak z jagodami")
    for n, v in (("rock_small", 0), ("rock_medium", 1), ("rock_tiny", 2)):
        save(nat, n, rock(v), "kamien")
    save(nat, "big_rock", big_rock(), "duza skala / gora")
    for n, v in (("flowers_pink", 0), ("flowers_yellow", 1), ("flowers_white", 2)):
        save(nat, n, flowers(v), "kwiatki")
    for n, v in (("grass_tuft_a", 0), ("grass_tuft_b", 1), ("grass_tuft_c", 2)):
        save(nat, n, grass_tuft(v), "kepka trawy")
    # --- natura pustynia
    save(nat, "cactus_tall", cactus(0), "kaktus")
    save(nat, "cactus_round", cactus(1), "kaktus okragly")
    save(nat, "dead_tree_a", dead_tree(0), "suche drzewo")
    save(nat, "dead_tree_b", dead_tree(1), "suche drzewo")
    for n, v in (("desert_rock_small", 0), ("desert_rock_medium", 1), ("desert_rock_tiny", 2)):
        save(nat, n, desert_rock(v), "kamien z piaskowca")
    save(nat, "mesa", big_rock(SANDSTONE, "45293f", strata=True, seed=70, grass=False), "duza skala z piaskowca")
    save(nat, "skull", skull(), "czaszka bydleca")
    save(nat, "ribs", ribs(), "zebra")
    save(nat, "dry_bush", dry_bush(), "suchy krzak")

    # --- etap 1b (plaza, gory, morze, obiekty)
    extra_overlays, extra_water = stage_1b(A, save, terr, nat, obj, out)

    # --- metadane dla Godota (Match Corners)
    meta = {"tile_size": T, "corner_bits": {"nw": 1, "ne": 2, "sw": 4, "se": 8},
            "overlay_atlases": {}, "water_atlases": {}}
    for name in ("road", "sand_overlay", "desert_path") + tuple(extra_overlays):
        tiles = []
        for m in range(16):
            tiles.append({"atlas": [m % 4, m // 4], "mask": m,
                          "corners": {k: (m >> b) & 1 for k, b in (("nw", 0), ("ne", 1), ("sw", 2), ("se", 3))}})
        for v in range(4):
            tiles.append({"atlas": [v, 4], "mask": 15, "variant": v + 1})
        meta["overlay_atlases"]["assets/terrain/%s.png" % name] = tiles
    for name in ("water", "oasis_water") + tuple(extra_water):
        meta["water_atlases"]["assets/terrain/%s.png" % name] = {
            "layout": "wiersz = maska 0..15 (atlas [0, maska]), kolumny 0..3 = klatki animacji",
            "frames": 4, "suggested_fps": 4}
    with open(os.path.join(terr, "terrain_meta.json"), "w", encoding="utf-8") as fh:
        json.dump(meta, fh, indent=1, ensure_ascii=False)

    # --- podglady
    pm = preview_meadow(A)
    pd = preview_desert(A)
    pm.resize((MAP_W * 3, MAP_H * 3), Image.NEAREST).save(os.path.join(out, "preview_meadow.png"))
    pd.resize((MAP_W * 3, MAP_H * 3), Image.NEAREST).save(os.path.join(out, "preview_desert.png"))

    ov = overview([
        ("teren", [(n, A[n]) for n in ("grass", "sand", "road", "sand_overlay", "desert_path")]),
        ("woda", [(n, A[n]) for n in ("water", "oasis_water", "bridge_h", "bridge_v", "build_spot", "build_spot_desert")]),
        ("laka", [(n, A[n]) for n in ("tree_round", "tree_oval", "tree_wide", "pine_tall", "pine_slim",
                                      "bush_round", "bush_berry", "rock_small", "rock_medium", "rock_tiny",
                                      "big_rock", "flowers_pink", "flowers_yellow", "flowers_white",
                                      "grass_tuft_a", "grass_tuft_b", "grass_tuft_c")]),
        ("pustynia", [(n, A[n]) for n in ("cactus_tall", "cactus_round", "dead_tree_a", "dead_tree_b",
                                          "desert_rock_small", "desert_rock_medium", "desert_rock_tiny",
                                          "mesa", "skull", "ribs", "dry_bush")]),
    ])
    ov.save(os.path.join(out, "overview.png"))

    print("Zapisane pliki:")
    for p, (size, desc) in files.items():
        print("  %-42s %3dx%-3d  %s" % (p, size[0], size[1], desc))

    # --- etap 2 i 3: wrogowie, wieze, statek (osobny plik tools/gen_units.py)
    import gen_units
    gen_units.run(out)

    # --- etap 4: sojusznicy, pociski, efekty, ikony (tools/gen_fx.py)
    import gen_fx
    gen_fx.run(out)

    # --- droga malowana wzdluz trasy (tools/gen_road_paint.py)
    import gen_road_paint
    gen_road_paint.run(out)

    # --- mosty stale 48-112 px i most zwodzony (tools/gen_bridges.py)
    import gen_bridges
    gen_bridges.run(out)

    # --- Wieza wroga (tools/gen_war_tower.py)
    import gen_war_tower
    gen_war_tower.run(out)

    # --- poziom 9: szkielety, mumia, piramida, portal (tools/gen_undead.py)
    import gen_undead
    gen_undead.run(out)


if __name__ == "__main__":
    main()

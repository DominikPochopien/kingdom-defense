#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - tekstury do drogi "malowanej" wzdluz trasy (dowolne luki, bez kafelkow).

Pliki (assets/terrain/):
  road_fill.png        32x32  nawierzchnia, powtarza sie bez szwow w obu osiach, bez kierunku
  road_edge.png        8x1    gradient brzegu: piksel 0 = sam skraj, piksel 7 = kolor wnetrza
  road_edge_lit.png    8x1    opcjonalnie: brzeg po stronie oswietlonej (prawy-dolny)
  road_bits.png        64x16  drobiazgi 8x8 (2 rzedy po 8) do rozrzucenia przy brzegach
  sand_road_fill.png, sand_road_edge.png, sand_road_edge_lit.png, sand_road_bits.png - wersja na plaze

Kolory sa te same co w road.png i sand_road.png (paleta Resurrect 64).
Uruchamia go gen_art.py, mozna tez osobno:  python tools/gen_road_paint.py [--out X]
"""
import argparse
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as G  # noqa: E402
from gen_art import C, new, px, h01, check_palette, outline, stack  # noqa: E402
from PIL import Image  # noqa: E402

S = 32  # rozmiar tekstury wypelnienia

ROAD = {
    "base": "ab947a", "dark": "966c6c", "light": "c7dcd0", "deep": "694f62",
    "edge": ["676633", "966c6c", "966c6c", "966c6c", "ab947a", "ab947a", "ab947a", "ab947a"],
    "edge_lit": ["cddf6c", "ab947a", "ab947a", "ab947a", "ab947a", "ab947a", "ab947a", "ab947a"],
    "stones": False,
}
SAND = {
    "base": "966c6c", "dark": "694f62", "light": "ab947a", "deep": "45293f",
    "edge": ["cd683d", "694f62", "694f62", "694f62", "966c6c", "966c6c", "966c6c", "966c6c"],
    "edge_lit": ["fdcbb0", "966c6c", "966c6c", "966c6c", "966c6c", "966c6c", "966c6c", "966c6c"],
    "stones": True,
}


def wrap_noise(x, y, period, seed):
    """Gladki szum okresowy (powtarza sie co `period` px) - do duzych, lagodnych plam."""
    s = 0.0
    for kx, ky, ph, a in ((2, 1, 0.4, 0.5), (-1, 3, 1.9, 0.5), (3, -2, 3.1, 0.4), (4, 1, 5.0, 0.3), (1, 4, 2.2, 0.3)):
        s += a * math.sin(2 * math.pi * (kx * x + ky * y) / period + ph + seed)
    return s / 1.8


def fill_texture(st, seed=0):
    img = Image.new("RGBA", (S, S), C(st["base"]))
    # lagodne plamy ciemniejszej ziemi (okresowe, wiec bez szwow)
    for y in range(S):
        for x in range(S):
            n = wrap_noise(x, y, S, seed)
            if n > 0.62 and h01(x, y, seed + 3) < 0.4:
                img.putpixel((x, y), C(st["dark"]))
    # pojedyncze plamki
    for y in range(S):
        for x in range(S):
            r = h01(x, y, seed + 11)
            if r < 0.055:
                img.putpixel((x, y), C(st["dark"]))
            elif r > 0.982:
                img.putpixel((x, y), C(st["light"]))
    # kamyki 2-3 px z oswietleniem z lewej-gory; wspolrzedne zawijane modulo S
    rng = random.Random(seed * 13 + 5)
    n_peb = 8 if not st["stones"] else 5
    for _ in range(n_peb):
        x, y = rng.randrange(S), rng.randrange(S)
        big = rng.random() < 0.35
        cells = [(0, 0), (1, 0)] + ([(0, 1), (1, 1)] if big else [])
        for dx, dy in cells:
            c = st["light"] if (dx, dy) == (0, 0) else st["dark"]
            img.putpixel(((x + dx) % S, (y + dy) % S), C(c))
        img.putpixel(((x + 1) % S, (y + (2 if big else 1)) % S), C(st["deep"]))  # cien pod kamykiem
    if st["stones"]:  # plaskie kamienie jak w sand_road.png, tez zawijane
        for _ in range(6):
            x, y = rng.randrange(S), rng.randrange(S)
            w = rng.choice((3, 3, 4))
            for dx in range(w):
                img.putpixel(((x + dx) % S, y % S), C("c7dcd0" if dx == 0 else "9babb2"))
                img.putpixel(((x + dx) % S, (y + 1) % S), C("7f708a"))
            img.putpixel(((x + w) % S, (y + 1) % S), C(st["deep"]))
    return img


def edge_strip(cols):
    img = new(8, 1)
    for i, c in enumerate(cols):
        img.putpixel((i, 0), C(c))
    return img


def bits_sheet(st, grass):
    """2 rzedy po 8 drobiazgow 8x8. Rzad 0: kamyki i koleiny, rzad 1: kepki trawy/suche zdzbla."""
    img = new(64, 16)
    rng = random.Random(7 if grass else 9)

    def cell(i):
        return (i % 8) * 8, (i // 8) * 8

    # 0-2: kamyki roznej wielkosci
    for i, (rx, ry) in enumerate(((1.6, 1.2), (2.4, 1.7), (3.0, 2.2))):
        ox, oy = cell(i)
        layer = new(8, 8)
        G.shadow_ellipse(layer, 4.6, 6.0, rx + 0.5, 1.0)
        rock = new(8, 8)
        G.blob(rock, 4, 5 - ry * 0.4, rx, ry, G.STONE[1:], seed=i + 3, facets=5, dither=0.2)
        outline(rock, C("2e222f"))
        img.alpha_composite(stack(layer, rock), (ox, oy))
    # 3: grupka drobnych kamykow
    ox, oy = cell(3)
    for x, y in ((1, 5), (2, 5), (4, 3), (5, 6), (6, 6)):
        px(img, ox + x, oy + y, C("9babb2" if (x + y) % 2 else "7f708a"))
    # 4-5: koleiny / slady kol (krotkie, ciemne; gra moze je obracac tylko o 90 st. albo zostawic)
    for i, ln in ((4, 6), (5, 4)):
        ox, oy = cell(i)
        for x in range(1, 1 + ln):
            px(img, ox + x, oy + 3, C(st["deep"]))
            px(img, ox + x, oy + 4, C(st["dark"]))
            if x % 2 == 0:
                px(img, ox + x, oy + 2, C(st["light"]))
    # 6: kaluza / ciemniejsza plama
    ox, oy = cell(6)
    for y in range(8):
        for x in range(8):
            if ((x + 0.5 - 4) / 3.4) ** 2 + ((y + 0.5 - 4.5) / 2.2) ** 2 <= 1:
                c = st["dark"] if (x + y) % 3 else st["deep"]
                if grass and y < 4 and 2 < x < 6:
                    c = "4d65b4"  # odrobina wody w kaluzy
                px(img, ox + x, oy + y, C(c))
    # 7: patyk / suchy kawalek drewna
    ox, oy = cell(7)
    for x in range(1, 7):
        px(img, ox + x, oy + 4 + (x > 4), C("966c6c" if grass else "4c3e24"))
    px(img, ox + 3, oy + 3, C("966c6c" if grass else "4c3e24"))
    # rzad 1: kepki trawy wchodzace na droge (laka) albo suche zdzbla i muszelki (plaza)
    for k in range(8):
        ox, oy = cell(8 + k)
        if grass:
            if k < 3:
                img.alpha_composite(G.grass_tuft(k), (ox, oy))
            elif k < 5:
                img.alpha_composite(G.flowers(k - 3), (ox, oy))
            else:
                for j in range(3 + k - 5):
                    x, y = rng.randint(1, 6), rng.randint(3, 7)
                    px(img, ox + x, oy + y, C("a2a947"))
                    px(img, ox + x, oy + y - 1, C("cddf6c"))
        else:
            if k < 3:
                tuft = G.grass_tuft(k)
                for y in range(8):  # suche zdzbla: przekolorowanie kepki
                    for x in range(8):
                        a = tuft.getpixel((x, y))
                        if a[3]:
                            col = {(103, 102, 51): "9e4539", (162, 169, 71): "cd683d", (205, 223, 108): "fbb954"}
                            hx = col.get(a[:3])
                            if hx:
                                px(img, ox + x, oy + y, C(hx))
            elif k < 6:
                img.alpha_composite(G.shell(k - 3), (ox + 1, oy + 1))
            else:
                for j in range(4):
                    x, y = rng.randint(1, 6), rng.randint(1, 6)
                    px(img, ox + x, oy + y, C("fdcbb0" if j % 2 else "fbb954"))
    return img


# ================================================================ podglad (wzorcowe "malowanie")


def catmull(pts, steps=24):
    out = []
    p = [pts[0]] + pts + [pts[-1]]
    for i in range(1, len(p) - 2):
        p0, p1, p2, p3 = p[i - 1], p[i], p[i + 1], p[i + 2]
        for s in range(steps):
            t = s / steps
            t2, t3 = t * t, t * t * t
            out.append(tuple(0.5 * ((2 * p1[k]) + (-p0[k] + p2[k]) * t + (2 * p0[k] - 5 * p1[k] + 4 * p2[k] - p3[k]) * t2
                                    + (-p0[k] + 3 * p1[k] - 3 * p2[k] + p3[k]) * t3) for k in (0, 1)))
    out.append(pts[-1])
    return out


def paint_road(canvas, paths, fill, edge, edge_lit, half=16):
    """Wzorcowe uzycie tekstur (to samo zrobi gra):
    d = odleglosc piksela od najblizszej linii trasy;
    i = floor(half - d) (+ male drganie, zeby brzeg nie byl idealnie gladki);
    i < 0 -> trawa, 0..7 -> kolor z road_edge (strona swiatla z road_edge_lit),
    gdy kolor z paska == kolor wnetrza albo i >= 8 -> piksel z road_fill (x mod 32, y mod 32)."""
    W, H = canvas.size
    segs = []
    for pts in paths:
        segs += list(zip(pts, pts[1:]))
    inner = edge.getpixel((7, 0))
    best = [[(1e9, 0.0, 0.0)] * W for _ in range(H)]
    for (ax, ay), (bx, by) in segs:  # odleglosc liczona tylko w otoczeniu odcinka
        x0, x1 = int(min(ax, bx) - half - 2), int(max(ax, bx) + half + 2)
        y0, y1 = int(min(ay, by) - half - 2), int(max(ay, by) + half + 2)
        vx, vy = bx - ax, by - ay
        L = vx * vx + vy * vy or 1e-9
        for y in range(max(0, y0), min(H, y1 + 1)):
            row = best[y]
            for x in range(max(0, x0), min(W, x1 + 1)):
                pxc, pyc = x + 0.5, y + 0.5
                t = max(0.0, min(1.0, ((pxc - ax) * vx + (pyc - ay) * vy) / L))
                dx, dy = pxc - (ax + vx * t), pyc - (ay + vy * t)
                d = math.hypot(dx, dy)
                if d < row[x][0]:
                    row[x] = (d, dx, dy)
    for y in range(H):
        for x in range(W):
            d, dx, dy = best[y][x]
            jitter = 0.9 * G.edge_noise(x % 16, y % 16)
            i = int(math.floor(half - d + jitter))
            if i < 0:
                continue
            if i >= 8:
                col = fill.getpixel((x % S, y % S))
            else:
                lit = d > 1e-6 and (dx + dy) / d > 0.35  # normalna w strone prawego-dolu = strona swiatla
                col = (edge_lit if lit else edge).getpixel((i, 0))
                if col == inner:
                    col = fill.getpixel((x % S, y % S))
            canvas.putpixel((x, y), col)


def scatter_bits(canvas, paths, bits, half, seed, count=60):
    rng = random.Random(seed)
    pts = [p for path in paths for p in path]
    tiles = [bits.crop(((i % 8) * 8, (i // 8) * 8, (i % 8) * 8 + 8, (i // 8) * 8 + 8)) for i in range(16)]
    for _ in range(count):
        x, y = rng.choice(pts)
        a = rng.uniform(0, 2 * math.pi)
        r = rng.uniform(half - 7, half + 1)
        i = rng.choice([0, 1, 3, 3, 4, 6, 8, 9, 10, 8, 9, 13, 14, 15])
        cx, cy = int(x + math.cos(a) * r) - 4, int(y + math.sin(a) * r) - 4
        canvas.alpha_composite(tiles[i], (max(0, cx), max(0, cy)))


def preview(A):
    W, H = 640, 360
    grass = G.render_base(G.grass_tiles(), 7).crop((0, 0, W, H))
    sand = G.render_base(G.sand_tiles(), 7).crop((0, 0, W, H))
    beach_col = C(G.BEACH_BASE)
    canvas = grass.copy()
    for y in range(200, H):  # pas plazy na dole (uproszczony, tylko do podgladu)
        edge_y = 200 + 10 * math.sin(y * 0.0) + 0
        for x in range(W):
            if y > 214 + 8 * math.sin(x / 37.0) + 4 * math.sin(x / 13.0):
                c = beach_col if h01(x, y, 3) > 0.38 else C("fbb954")
                canvas.putpixel((x, y), c)
    main = catmull([(-30, 60), (90, 60), (170, 110), (200, 175), (290, 190), (360, 120), (450, 80),
                    (530, 120), (560, 175)])
    branch = catmull([(330, 152), (360, 40), (420, -30)])
    beachp = catmull([(555, 175), (590, 250), (500, 300), (380, 285), (250, 320), (120, 300), (-30, 330)])
    paint_road(canvas, [main, branch], A["road_fill"], A["road_edge"], A["road_edge_lit"])
    scatter_bits(canvas, [main, branch], A["road_bits"], 16, seed=4, count=70)
    sand_layer = canvas.copy()
    paint_road(sand_layer, [beachp], A["sand_road_fill"], A["sand_road_edge"], A["sand_road_edge_lit"])
    # odcinek plazowy tylko ponizej linii plazy, droga laczy sie przez wspolny punkt (560,175)
    canvas = sand_layer
    scatter_bits(canvas, [beachp], A["sand_road_bits"], 16, seed=6, count=50)
    trees = [G.tree_deciduous(0), G.tree_deciduous(1), G.tree_conifer(0), G.bush(0)]
    rng = random.Random(2)
    spots = [(40, 160), (80, 190), (120, 170), (250, 70), (290, 50), (470, 20), (600, 60), (620, 140),
             (24, 120), (440, 180)]
    for i, (x, y) in enumerate(spots):
        t = trees[i % 4]
        canvas.alpha_composite(t, (x - t.width // 2, y - t.height))
    for x, y in ((470, 330), (620, 300)):
        p = A.get("palm")
        if p:
            canvas.alpha_composite(p, (x - 12, y - 40))
    return canvas.resize((W * 3, H * 3), Image.NEAREST)


def tiled_check(fill, n=3):
    out = new(S * n, S * n)
    for y in range(n):
        for x in range(n):
            out.paste(fill, (x * S, y * S))
    return out


def run(out="."):
    terr = os.path.join(out, "assets", "terrain")
    os.makedirs(terr, exist_ok=True)
    A, files = {}, []

    def save(name, img, desc):
        check_palette(img, name)
        A[name] = img
        p = os.path.join(terr, name + ".png")
        img.save(p)
        files.append((os.path.relpath(p, out), img.size, desc))

    save("road_fill", fill_texture(ROAD, seed=1), "nawierzchnia, bez szwow")
    save("road_edge", edge_strip(ROAD["edge"]), "brzeg: 0 = skraj, 7 = wnetrze")
    save("road_edge_lit", edge_strip(ROAD["edge_lit"]), "brzeg po stronie swiatla (opcjonalny)")
    save("road_bits", bits_sheet(ROAD, grass=True), "16 drobiazgow 8x8")
    save("sand_road_fill", fill_texture(SAND, seed=2), "nawierzchnia na plazy, bez szwow")
    save("sand_road_edge", edge_strip(SAND["edge"]), "brzeg na plazy")
    save("sand_road_edge_lit", edge_strip(SAND["edge_lit"]), "brzeg na plazy, strona swiatla (opcjonalny)")
    save("sand_road_bits", bits_sheet(SAND, grass=False), "16 drobiazgow 8x8 na plaze")

    try:
        A["palm"] = Image.open(os.path.join(out, "assets", "objects", "palm_sway.png")).crop((0, 0, 24, 40))
    except OSError:
        pass
    preview(A).save(os.path.join(out, "preview_road_paint.png"))
    sheet = new(S * 3 * 2 + 8, S * 3)
    sheet.paste(tiled_check(A["road_fill"]), (0, 0))
    sheet.paste(tiled_check(A["sand_road_fill"]), (S * 3 + 8, 0))
    sheet.resize((sheet.width * 4, sheet.height * 4), Image.NEAREST).save(os.path.join(out, "preview_road_fill_tiling.png"))

    print("Droga malowana, zapisane pliki:")
    for p, size, desc in files:
        print("  %-40s %3dx%-3d  %s" % (p, size[0], size[1], desc))
    return files


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".")
    run(ap.parse_args().out)

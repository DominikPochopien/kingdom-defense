#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Kingdom Defense - mosty: 5 stalych (poziome i pionowe) + animowany most zwodzony.

Widok prosto z gory (bez pochylenia), swiatlo z lewej-gory, paleta Resurrect 64.
Szerokosc kazdego mostu: 46 px = 3 px porecz + 40 px pokladu + 3 px porecz.

Pliki (assets/terrain/):
  bridge_h_48.png ... bridge_h_112.png   L x 50  (wiersze 0-45 most, 46-49 cien na wodzie)
  bridge_v_48.png ... bridge_v_112.png   50 x L  (kolumny 0-45 most, 46-49 cien na wodzie)
  bridges.png                            arkusz: rzad 1 poziome, rzad 2 pionowe, 16 px odstepu
  drawbridge.png                         6 klatek 96x64 w poziomym pasku

Uruchamia go gen_art.py, mozna tez osobno:  python tools/gen_bridges.py [--out X]
"""
import argparse
import math
import os
import random
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import gen_art as G  # noqa: E402
from gen_art import C, new, px, h01, check_palette, stack  # noqa: E402
from PIL import Image  # noqa: E402

WIDTH = 46          # pelna szerokosc mostu
RAIL = 3            # grubosc poreczy
DECK = 40           # szerokosc pokladu
ABUT = 6            # przyczolek na kazdym koncu
PLANK = 4           # deska 3 px + 1 px szczeliny
POST_STEP = 8
SHADOW_ROWS = (110, 80, 50, 25)   # alfa cienia pod krawedzia mostu (4 px)
LENGTHS = (48, 64, 80, 96, 112)

LIGHTER = {"966c6c": "ab947a", "694f62": "966c6c", "4c3e24": "694f62"}
DARKER = {"45293f": "45293f", "c7dcd0": "ab947a", "ab947a": "966c6c", "966c6c": "694f62", "4c3e24": "45293f",
          "694f62": "45293f", "9babb2": "7f708a", "7f708a": "625565"}


def hexof(col):
    return "%02x%02x%02x" % col[:3]


# ================================================================ poklad i porecze (wspolrzedne a, c)
# a = wzdluz drogi (0..L-1), c = w poprzek (0..45). Poziomo: (x, y) = (a, c); pionowo: (x, y) = (c, a).
# Swiatlo z lewej-gory oswietla w obu ukladach strone "a niskie" i "c niskie", wiec cieniowanie
# liczone w (a, c) jest poprawne w obu orientacjach (to odbicie wzgledem przekatnej, nie obrot).


def deck_pixel(a, c, plank_cols, seed, a0):
    """Kolor piksela pokladu (bez poreczy). a liczone od poczatku pokladu."""
    k, r = divmod(a - a0, PLANK)
    base = plank_cols[k % len(plank_cols)]
    if r == PLANK - 1:
        col = "4c3e24"                                   # szczelina miedzy deskami
    else:
        col = base
        if r == 0 and (base == "966c6c" or h01(k, 0, seed + 1) < 0.3):
            col = "ab947a" if base == "966c6c" else "c7dcd0"   # oswietlona krawedz deski
        n = h01(a, c, seed)
        if n < 0.07 and r != 0:
            col = "966c6c" if base == "ab947a" else "694f62"   # slój / sęki
        if c in (RAIL + 2, WIDTH - RAIL - 3) and r == 1:
            col = "45293f"                               # gwozdzie przy poreczach
    if c in (RAIL, RAIL + 1):                            # cien poreczy na pokladzie
        col = DARKER.get(col, col)
        if c == RAIL:
            col = DARKER.get(col, col)
    elif c == RAIL + 2 and (a + c) % 2 == 0:
        col = DARKER.get(col, col)
    return col


POST_SHADE = ["c7dcd0", "ab947a", "966c6c", "4c3e24", "45293f"]


def post_positions(a_start, a_end):
    """Poczatki slupkow (kazdy 3 px), co 8 px, ostatni dosuniety do konca poreczy."""
    pos = list(range(a_start, a_end - 2, POST_STEP))
    if a_end - 2 - pos[-1] >= 5:
        pos.append(a_end - 2)
    elif pos[-1] != a_end - 2:
        pos[-1] = a_end - 2
    return pos


def rail_pixel(a, c, a_start, a_end, posts=None):
    """Porecz (c w 0..2 albo 43..45): ciemna belka + jasne kolpaki slupkow 3x3 co 8 px."""
    cc = c if c < RAIL else c - (WIDTH - RAIL)
    posts = posts if posts is not None else post_positions(a_start, a_end)
    for p0 in posts:
        if p0 <= a <= p0 + 2:
            return POST_SHADE[(a - p0) + cc]
    return ("966c6c", "694f62", "45293f")[cc]


def abutment_pixel(a, c, at_start, L, seed):
    """Przyczolek 6 px: 3 px ubitej ziemi jak droga + 3 px kamiennego progu; kamienne narozniki."""
    d = a if at_start else L - 1 - a           # odleglosc od konca mostu (0 = styk z droga)
    corner = c <= RAIL or c >= WIDTH - RAIL - 1
    if corner:
        # kamienny blok narozny 6 x 4 (konczy porecz)
        cc = c if c <= RAIL else c - (WIDTH - RAIL - 1)
        idx = 3
        if cc == 0 or d == ABUT - 1 and at_start is False:
            idx = 4
        if cc == 3 or d == 0:
            idx = 1
        if (d == 2 and cc in (1, 2)) or h01(a, c, seed + 5) < 0.12:
            idx = max(1, idx - 1)
        if cc == 0 and d == ABUT - 1:
            idx = 4
        return G.STONE[idx]
    if d >= 3:                                  # kamienny prog pod koncem desek
        row = (c // 5) % 2
        joint = (c % 5 == 4) or (d == 3)
        if joint:
            return "625565"
        return "9babb2" if (d == 5 and row == 0) or (c % 5 == 0) else "7f708a"
    # ubita ziemia jak road_fill, zeby droga wchodzila prosto na most
    n = h01(a, c, seed + 9)
    if n < 0.07:
        return "966c6c"
    if n > 0.975:
        return "c7dcd0"
    return "ab947a"


def bridge_ac(L, seed):
    """Zwraca slownik {(a, c): hex} dla mostu dlugosci L (bez cienia)."""
    rng = random.Random(seed)
    n_planks = (L - 2 * ABUT) // PLANK + 2
    plank_cols = [rng.choice(("ab947a", "ab947a", "966c6c")) for _ in range(n_planks)]
    out = {}
    a0, a1 = ABUT, L - ABUT - 1
    posts = post_positions(a0, a1)
    for a in range(L):
        for c in range(WIDTH):
            if a < ABUT:
                col = abutment_pixel(a, c, True, L, seed)
            elif a > a1:
                col = abutment_pixel(a, c, False, L, seed)
            elif c < RAIL or c >= WIDTH - RAIL:
                col = rail_pixel(a, c, a0, a1, posts)
            else:
                col = deck_pixel(a, c, plank_cols, seed, a0)
            out[(a, c)] = col
    return out


def fixed_bridge(L, vertical, seed=0):
    ac = bridge_ac(L, seed + L * 7 + (3 if vertical else 0))
    W, H = (WIDTH + 4, L) if vertical else (L, WIDTH + 4)
    img = new(W, H)
    for (a, c), col in ac.items():
        x, y = (c, a) if vertical else (a, c)
        img.putpixel((x, y), C(col))
    for a in range(ABUT, L - ABUT):             # cien pod mostem, tylko nad woda
        for k, al in enumerate(SHADOW_ROWS):
            c = WIDTH + k
            if k >= 2 and (a + k) % 2 == 0:
                continue
            x, y = (c, a) if vertical else (a, c)
            img.putpixel((x, y), C("2e222f", al))
    return img


def bridges_sheet(hs, vs, gap=16):
    W = sum(b.width for b in hs) + gap * (len(hs) + 1)
    H = hs[0].height + max(v.height for v in vs) + gap * 3
    sheet = new(W, H)
    x = gap
    for b in hs:
        sheet.alpha_composite(b, (x, gap))
        x += b.width + gap
    x = gap
    y = hs[0].height + 2 * gap
    for v in vs:
        sheet.alpha_composite(v, (x, y))
        x += v.width + gap
    return sheet


# ================================================================ most zwodzony
FW, FH = 96, 64
DY0 = 9                     # gorny wiersz pokladu w klatce (poklad: 9..54)
GATE = 14                   # dlugosc bramy/przyczolka
MOVE = 80 - GATE            # dlugosc ruchomego pokladu = 66
THICK = 4                   # grubosc pokladu (widoczna, gdy jest podniesiony)
ANGLES = (0, 22, 42, 60, 76, 90)
SH_K, SH_V = 0.45, 0.25     # przesuniecie cienia na jednostke wysokosci (w prawo, w dol)


def flat_deck():
    """Ruchomy poklad 66x46 w tym samym stylu (bez przyczolkow), porecze ze slupkami."""
    rng = random.Random(41)
    plank_cols = [rng.choice(("ab947a", "ab947a", "966c6c")) for _ in range(MOVE // PLANK + 2)]
    img = new(MOVE, WIDTH)
    for a in range(MOVE):
        for c in range(WIDTH):
            if c < RAIL or c >= WIDTH - RAIL:
                col = rail_pixel(a, c, 1, MOVE - 1)
            else:
                col = deck_pixel(a, c, plank_cols, 41, 0)
            if a == MOVE - 1 and RAIL <= c < WIDTH - RAIL:
                col = "4c3e24"          # okuta krawedz konca pokladu
            img.putpixel((a, c), C(col))
    for c in (RAIL + 3, WIDTH - RAIL - 4):  # okucia, do ktorych przypiete sa lancuchy
        img.putpixel((MOVE - 2, c), C("9babb2"))
        img.putpixel((MOVE - 3, c), C("625565"))
    return img


def gatehouse(img):
    """Kamienny przyczolek 14 px: bruk pod droga + dwa filary z kolowrotami."""
    for y in range(DY0, DY0 + WIDTH):              # bruk na drodze
        for x in range(GATE):
            row = (y - DY0) // 4
            jx = (x + (2 if row % 2 else 0)) % 5 == 4
            jy = (y - DY0) % 4 == 3
            col = "625565" if (jx or jy) else ("9babb2" if (x + y) % 7 == 0 else "7f708a")
            if x == GATE - 1:
                col = "3e3546"                      # zawias / krawedz przy pokladzie
            px(img, x, y, C(col))
    for x in range(GATE):                           # pas ziemi po lewej, gdzie wchodzi droga
        for y in range(DY0 + RAIL, DY0 + WIDTH - RAIL):
            if x < 2:
                px(img, x, y, C("ab947a" if h01(x, y, 3) > 0.1 else "966c6c"))
    for y0, y1 in ((2, DY0 + 2), (DY0 + WIDTH - 3, 61)):   # filary nad i pod pokladem
        for y in range(y0, y1 + 1):
            for x in range(GATE):
                col = "7f708a"
                if x == 0 or y == y0:
                    col = "9babb2"
                if x == GATE - 1 or y == y1:
                    col = "3e3546"
                elif (x % 5 == 4) or ((y - y0) % 4 == 3):
                    col = "625565"
                px(img, x, y, C(col))
        # kolowrot: drewniany slupek z bebnem i nawinietym lancuchem
        cy = (y0 + y1) // 2
        for y in range(cy - 2, cy + 3):
            for x in range(3, 11):
                col = "966c6c"
                if x in (3, 10):
                    col = "4c3e24"
                elif y == cy - 2:
                    col = "ab947a"
                elif y == cy + 2:
                    col = "4c3e24"
                elif x % 2 == 0:
                    col = "625565"            # zwoje lancucha na bebnie
                px(img, x, y, C(col))
        px(img, 3, cy - 2, C("c7dcd0"))
        px(img, 11, cy, C("9babb2"))          # korba
        px(img, 12, cy, C("625565"))
    return img


def chain(img, x0, y0, x1, y1, sag):
    """Lancuch: krzywa z ugieciem `sag` (w strone srodka pokladu), ogniwa na przemian."""
    mx, my = (x0 + x1) / 2, (y0 + y1) / 2 + sag
    steps = int(abs(x1 - x0) + abs(y1 - y0)) * 2 + 4
    last = None
    i_link = 0
    for s in range(steps + 1):
        t = s / steps
        x = (1 - t) ** 2 * x0 + 2 * (1 - t) * t * mx + t * t * x1
        y = (1 - t) ** 2 * y0 + 2 * (1 - t) * t * my + t * t * y1
        p = (int(round(x)), int(round(y)))
        if p != last:
            px(img, p[0], p[1], C("9babb2" if i_link % 2 == 0 else "3e3546"))
            i_link += 1
            last = p


def drawbridge_frame(theta_deg, deck):
    th = math.radians(theta_deg)
    ct, st = math.cos(th), math.sin(th)
    img = new(FW, FH)
    # cien ruchomego pokladu na wodzie (rosnie i przesuwa sie w prawo-dol z wysokoscia)
    shadow = new(FW, FH)
    for s10 in range(0, MOVE * 4 + 1):
        s = s10 / 4
        h = s * st
        x = GATE + s * ct + SH_K * h
        dy = SH_V * h
        for c in range(WIDTH):
            y = DY0 + c + dy + 3
            px(shadow, int(x), int(y), C("2e222f", 95))
    for x in range(2, GATE + 1):                 # cien filarow na wodzie (w prawo-dol)
        for y in (62, 63):
            px(shadow, x, y, C("2e222f", 80))
    for y in list(range(3, DY0)) + list(range(DY0 + WIDTH, 62)):
        px(shadow, GATE, y, C("2e222f", 80))
    img.alpha_composite(shadow)
    # ruchomy poklad: rzut z gory skraca go do MOVE*cos(theta)
    w = int(round(MOVE * ct))
    lit = theta_deg >= 40
    ppp = PLANK * w / MOVE if w else 0          # ile pikseli zostaje z jednej deski po skroceniu
    for i in range(w):
        af0, af1 = i / w * MOVE, (i + 1) / w * MOVE
        k = int(((af0 + af1) / 2) // PLANK)
        gap = ppp >= 2 and int(af1 // PLANK) > int(af0 // PLANK) and i < w - 1
        a_true = min(MOVE - 1, int((af0 + af1) / 2))
        a_wood = a_true - 1 if a_true % PLANK == PLANK - 1 else a_true   # omijaj szczeline
        if i == w - 1:
            a_true = a_wood = MOVE - 1              # okuta krawedz konca zawsze widoczna
        for c in range(WIDTH):
            on_deck = RAIL <= c < WIDTH - RAIL
            if gap and on_deck:
                col = "4c3e24"
            else:
                col = hexof(deck.getpixel((a_wood if on_deck else a_true, c)))
            if lit:
                col = LIGHTER.get(col, col)
            px(img, GATE + i, DY0 + c, C(col))
    # czolo konca pokladu (grubosc) widoczne, gdy poklad sie unosi; odwrocone od swiatla -> ciemne
    e = int(round(THICK * st))
    for j in range(e):
        for c in range(WIDTH):
            col = "4c3e24" if (c % 6 != 5) else "45293f"
            if j == 0:
                col = "694f62" if c % 6 != 5 else "45293f"
            if c < RAIL or c >= WIDTH - RAIL:
                col = "45293f"
            px(img, GATE + w + j, DY0 + c, C(col))
    gatehouse(img)
    # lancuchy z kolowrotow do konca pokladu (rzut konca: x = GATE + w + e - 1)
    end_x = GATE + max(w + e - 2, 1)
    sag = {0: 4, 22: 1}.get(theta_deg, 0)
    top_anchor, bot_anchor = (12, 5), (12, 58)
    chain(img, *top_anchor, end_x, DY0 + RAIL + 3, sag)
    chain(img, *bot_anchor, end_x, DY0 + WIDTH - RAIL - 4, -sag)
    return img


def drawbridge():
    deck = flat_deck()
    frames = [drawbridge_frame(t, deck) for t in ANGLES]
    return G.hstrip(frames), frames


# ================================================================ podglady


def river_scene(vertical_river=True, open_gap=None):
    """Trawa + rzeka z brzegami (kafelki water.png) + droga malowana o polowie szerokosci 20 px."""
    import gen_road_paint as R
    W, H = 320, 208
    grid = G.Grid()
    if vertical_river:
        for ty in range(G.TH + 1):
            for tx in (9, 10, 11, 12):
                grid.set(tx, ty)
    else:
        for tx in range(G.TW + 1):
            for ty in (6, 7, 8):
                grid.set(tx, ty)
    grass = G.render_base(G.grass_tiles(), 11)
    water = G.render_layer(grid, G.water_tiles(G.water_atlas(G.WATER)))
    canvas = stack(grass, water).crop((0, 0, W, H))
    fill = Image.open(os.path.join(OUT_DIR, "assets", "terrain", "road_fill.png"))
    edge = Image.open(os.path.join(OUT_DIR, "assets", "terrain", "road_edge.png"))
    edge_lit = Image.open(os.path.join(OUT_DIR, "assets", "terrain", "road_edge_lit.png"))
    base = canvas.copy()
    path = [(-30, 104), (350, 104)] if vertical_river else [(176, -30), (176, 240)]
    R.paint_road(canvas, [path], fill, edge, edge_lit, half=20)
    if open_gap:  # droga ucieta prosto na brzegach, rzeka pod mostem zwodzonym zostaje odkryta
        x0, x1 = open_gap
        canvas.paste(base.crop((x0, 0, x1, H)), (x0, 0))
    return canvas


OUT_DIR = "."


def preview(out, hs, vs, frames):
    a = river_scene(True)
    b = hs[3]                                       # 96 px nad rzeka szeroka na ~56 px
    a.alpha_composite(b, (176 - b.width // 2, 104 - WIDTH // 2))
    bv = river_scene(False)
    v = vs[2]                                       # 80 px nad pozioma rzeka
    bv.alpha_composite(v, (176 - WIDTH // 2, 112 - v.height // 2))
    sheet = new(a.width * 2 + 8, a.height)
    sheet.alpha_composite(a, (0, 0))
    sheet.alpha_composite(bv, (a.width + 8, 0))
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(out, "preview_bridges.png"))

    # GIF mostu zwodzonego nad rzeka: podnoszenie i opuszczanie (klatki w przod i wstecz)
    scene = river_scene(True, open_gap=(136, 202))
    gif = []
    order = list(range(6)) + [5, 5] + list(range(5, -1, -1)) + [0, 0]
    for i in order:
        f = scene.copy()
        f.alpha_composite(frames[i], (176 - 32 - 8 - GATE, 104 - DY0 - WIDTH // 2))
        gif.append(f.crop((80, 40, 280, 176)).resize((600, 408), Image.NEAREST).convert("P", palette=Image.ADAPTIVE))
    gif[0].save(os.path.join(out, "preview_drawbridge.gif"), save_all=True, append_images=gif[1:],
                duration=180, loop=0, disposal=2)
    strip = new(FW * 6 + 5 * 4, FH)
    for i, f in enumerate(frames):
        bg = scene.crop((176 - 32 - 8 - GATE, 104 - DY0 - WIDTH // 2,
                         176 - 32 - 8 - GATE + FW, 104 - DY0 - WIDTH // 2 + FH)).copy()
        bg.alpha_composite(f)
        strip.alpha_composite(bg, (i * (FW + 4), 0))
    strip.resize((strip.width * 3, strip.height * 3), Image.NEAREST).save(os.path.join(out, "preview_drawbridge.png"))


def run(out="."):
    global OUT_DIR
    OUT_DIR = out
    terr = os.path.join(out, "assets", "terrain")
    os.makedirs(terr, exist_ok=True)
    files = []

    def save(name, img, desc):
        check_palette(img, name)
        p = os.path.join(terr, name + ".png")
        img.save(p)
        files.append((os.path.relpath(p, out), img.size, desc))

    hs = [fixed_bridge(L, False) for L in LENGTHS]
    vs = [fixed_bridge(L, True) for L in LENGTHS]
    for L, h, v in zip(LENGTHS, hs, vs):
        save("bridge_h_%d" % L, h, "most poziomy, wiersze 46-49 = cien")
        save("bridge_v_%d" % L, v, "most pionowy, kolumny 46-49 = cien")
    save("bridges", bridges_sheet(hs, vs), "arkusz: rzad 1 poziome, rzad 2 pionowe, odstep 16 px")
    strip, frames = drawbridge()
    save("drawbridge", strip, "most zwodzony, 6 klatek 96x64")
    preview(out, hs, vs, frames)
    print("Mosty, zapisane pliki:")
    for p, size, desc in files:
        print("  %-38s %3dx%-3d  %s" % (p, size[0], size[1], desc))
    return files


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default=".")
    run(ap.parse_args().out)

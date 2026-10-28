"""Tworzy assets/terrain/sand_road_diagonal.png - skośną drogę w kolorach drogi na piasku.

Środek drogi (kolory pełnego kafelka road.png) dostaje fakturę pełnego kafelka sand_road.png
w tym samym miejscu kafelka. Krawędzie przekolorowuje mapa kolorów zbudowana z par pikseli
na tych samych pozycjach w road.png i sand_road.png (mają ten sam kształt); kolor spoza mapy
dostaje kolor najbliższego znanego.
Uruchomienie z katalogu projektu: python tools/recolor_diagonal.py (wymaga Pillow).
"""
from collections import Counter, defaultdict
from PIL import Image

TERRAIN = "assets/terrain/"


TILE = 16
FULL = (3 * TILE, 3 * TILE)   # pełny kafelek (maska 15)


def full_tile(atlas):
    return atlas.crop((FULL[0], FULL[1], FULL[0] + TILE, FULL[1] + TILE))


def color_map(src, dst, skip):
    votes = defaultdict(Counter)
    for xy in ((x, y) for y in range(src.height) for x in range(src.width)):
        a, b = src.getpixel(xy), dst.getpixel(xy)
        if a[3] and b[3] and a not in skip:
            votes[a][b] += 1
    return {a: c.most_common(1)[0][0] for a, c in votes.items()}


def nearest(color, mapping):
    key = min(mapping, key=lambda k: sum((p - q) ** 2 for p, q in zip(k[:3], color[:3])))
    return mapping[key]


def main():
    road = Image.open(TERRAIN + "road.png").convert("RGBA")
    sand_road = Image.open(TERRAIN + "sand_road.png").convert("RGBA")
    diagonal = Image.open(TERRAIN + "road_diagonal.png").convert("RGBA")
    road_full = full_tile(road)
    inner = {road_full.getpixel((x, y)) for y in range(TILE) for x in range(TILE)}
    sand_inner = full_tile(sand_road)
    mapping = color_map(road, sand_road, inner)
    out = diagonal.copy()
    for y in range(out.height):
        for x in range(out.width):
            c = out.getpixel((x, y))
            if not c[3]:
                continue
            if c in inner:
                out.putpixel((x, y), sand_inner.getpixel((x % TILE, y % TILE)))
            else:
                out.putpixel((x, y), mapping.get(c) or nearest(c, mapping))
    out.save(TERRAIN + "sand_road_diagonal.png")


if __name__ == "__main__":
    main()

"""Landing art: halftone dot masks made from our own sprites and game frames (no outside photos).

    uv run --with pillow python3 scripts/gen_landing_art.py

Each output in landing/art/ is white with the dots in alpha; landing.css tints it with --band-art.
"""
import math
import os

from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(HERE, "web", "sprites")
OUT = os.path.join(HERE, "landing", "art")


def sprite(name, scale):
    im = Image.open(os.path.join(SPR, f"{name}.png")).convert("RGBA")
    return im.resize((im.width * scale // 2, im.height * scale // 2), Image.NEAREST)


def scene(size, items, ground=None):
    """Sprites on black; items are (name, scale, x-fraction, baseline-fraction)."""
    c = Image.new("RGBA", size, (0, 0, 0, 255))
    if ground:
        c.paste(Image.new("RGBA", (size[0], int(size[1] * (1 - ground))), (70, 80, 110, 255)), (0, int(size[1] * ground)))
    for name, s, fx, fy in items:
        im = sprite(name, s)
        c.alpha_composite(im, (int(size[0] * fx - im.width / 2), int(size[1] * fy - im.height)))
    return c


def halftone(src, size, cell=7, gain=1.15):
    """Round dots on a 45-degree-free square grid, radius by brightness."""
    g = src.convert("L").resize(size, Image.LANCZOS).filter(ImageFilter.GaussianBlur(cell / 3))
    out = Image.new("LA", size, (255, 0))
    px = out.load()
    gp = g.load()
    for cy in range(0, size[1], cell):
        for cx in range(0, size[0], cell):
            v = gp[min(cx + cell // 2, size[0] - 1), min(cy + cell // 2, size[1] - 1)] / 255
            r = min(cell * 0.62, cell * 0.62 * math.sqrt(v) * gain)
            if r < 0.6:
                continue
            for y in range(cy, min(cy + cell, size[1])):
                for x in range(cx, min(cx + cell, size[0])):
                    d = math.hypot(x - cx - cell / 2 + .5, y - cy - cell / 2 + .5)
                    if d <= r:
                        px[x, y] = (255, 255 if d <= r - 1 else int(255 * (r - d)))
    return out


def main():
    os.makedirs(OUT, exist_ok=True)
    frame = lambda f: Image.open(os.path.join(HERE, "landing", f)).convert("RGB")
    jobs = {
        "stage": (frame("hero-poster.jpg"), (1600, 900)),
        "band": (scene((1800, 950), [("tile_subway", 14, .78, .62), ("beacon", 13, .36, .9), ("shelter", 6, .62, .9), ("colonist_walk1", 6, .86, .9)], ground=.9), (1800, 950)),
        "crew": (scene((900, 600), [("colonist_idle", 9, .3, .9), ("colonist_walk1", 9, .52, .88), ("colonist_walk2", 9, .74, .9)], ground=.9), (900, 600)),
        "machines": (scene((900, 600), [("generator", 7, .34, .9), ("drill", 12, .74, .9)], ground=.9), (900, 600)),
        "clock": (scene((900, 600), [("beacon", 9, .5, .95)], ground=.95), (900, 600)),
        "film": (frame("hero-poster.jpg").transpose(Image.FLIP_LEFT_RIGHT), (1600, 900)),
    }
    for name, (src, size) in jobs.items():
        halftone(src, size).save(os.path.join(OUT, f"{name}.png"), optimize=True)
        print("art", name, size)


if __name__ == "__main__":
    main()

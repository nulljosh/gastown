"""NYC Survive sprites, drawn pixel by pixel from one palette, so the whole city reads as one place.

Look: Deadbolt's noir night (ink outlines, navy dark, one hot accent, light that pools) with Fez's chunky,
clean shapes and bevelled edges (light top-left, shade bottom-right). Every sprite is original and
generated here; nothing is traced or downloaded. Same bytes every run (seeded noise).

    uv run --with pillow python3 scripts/gen_sprites.py            # writes Resources/Assets.xcassets/*.imageset at 1x 2x 3x, and web/sprites/*.png at 2x
    uv run --with pillow python3 scripts/gen_sprites.py --sheet x.png   # also a contact sheet for review
"""
import json
import os
import random
import sys

from PIL import Image

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS = os.path.join(HERE, "Resources", "Assets.xcassets")
WEB = os.path.join(HERE, "web", "sprites")  # the browser game draws the same sprites, 2x

P = {  # the palette; nothing outside it
    "ink": (11, 13, 22), "night": (20, 26, 46), "asph": (24, 29, 46), "asph2": (31, 37, 56), "asph0": (18, 22, 38),
    "roof": (54, 62, 94), "roof2": (64, 73, 108), "roof3": (74, 84, 122), "conc": (88, 99, 136), "conc2": (104, 115, 152),
    "seam": (66, 75, 108), "steel": (74, 85, 120), "fog": (139, 148, 179), "paper": (246, 240, 228),
    "clay": (217, 119, 87), "clay2": (181, 80, 44), "clayL": (241, 166, 132), "glow": (255, 196, 140),
    "blue": (61, 123, 255), "blue2": (42, 95, 214), "deep": (11, 47, 138), "yellow": (255, 204, 61),
    "amber": (255, 159, 28), "red": (255, 59, 78), "green": (61, 220, 132), "skin": (242, 201, 160),
    "skin2": (201, 142, 95), "hair": (27, 31, 48), "pants": (27, 35, 64),
}


class C:
    """A tiny pixel canvas."""

    def __init__(self, w, h, fill=None):
        self.im = Image.new("RGBA", (w, h), (0, 0, 0, 0) if fill is None else P[fill] + (255,))
        self.w, self.h = w, h
        self.rounded = True
        self.under = self.im.copy()   # what the corners fall back to

    def px(self, x, y, c, a=255):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.im.putpixel((x, y), (P[c] if isinstance(c, str) else c) + (a,))

    def rect(self, x, y, w, h, c, a=255):
        for i in range(x, x + w):
            for j in range(y, y + h):
                self.px(i, j, c, a)

    def shadow(self, cx, cy, rx, ry, a=70):
        """Soft ground shadow: an oval that fades to its edge."""
        for i in range(-rx, rx + 1):
            for j in range(-ry, ry + 1):
                d = (i / rx) ** 2 + (j / ry) ** 2
                if d <= 1:
                    self.px(cx + i, cy + j, "ink", int(a * (1 - d * 0.6)))

    def glow(self, cx, cy, r, c, a=60):
        """Light that pools: concentric alpha rings."""
        for i in range(-r, r + 1):
            for j in range(-r, r + 1):
                d = (i * i + j * j) ** 0.5
                if d <= r:
                    self.px(cx + i, cy + j, c, int(a * (1 - d / r) ** 1.5))

    def box(self, x, y, w, h, fill, light=None, shade=None, outline="ink"):
        """Fez bevel: outline, fill, light on the top-left inner edge, shade on the bottom-right.
        Boxes 6px and up get chamfered corners."""
        self.rect(x, y, w, h, outline)
        self.rect(x + 1, y + 1, w - 2, h - 2, fill)
        if light:
            self.rect(x + 1, y + 1, w - 2, 1, light)
            self.rect(x + 1, y + 1, 1, h - 2, light)
        if shade:
            self.rect(x + 1, y + h - 2, w - 2, 1, shade)
            self.rect(x + w - 2, y + 1, 1, h - 2, shade)
        if min(w, h) >= 6 and self.rounded:
            for cx, cy in ((x, y), (x + w - 1, y), (x, y + h - 1), (x + w - 1, y + h - 1)):
                self.im.putpixel((cx, cy), self.under.getpixel((cx, cy)) if self.under else (0, 0, 0, 0))

    def disc(self, cx, cy, r, c):
        for i in range(-r, r + 1):
            for j in range(-r, r + 1):
                if i * i + j * j <= r * r + r * 0.6:
                    self.px(cx + i, cy + j, c)

    def speckle(self, colors, density, seed, x=0, y=0, w=None, h=None):
        rnd = random.Random(seed)
        for i in range(x, x + (w or self.w)):
            for j in range(y, y + (h or self.h)):
                if rnd.random() < density:
                    self.px(i, j, rnd.choice(colors))


# ---- tiles (32x32) -------------------------------------------------------------------------

def tile_road():
    c = C(32, 32, "asph")
    c.speckle(["asph2", "asph0"], 0.09, 1)
    for x, y in [(6, 21), (7, 21), (8, 22), (9, 22), (10, 23)]:   # one hairline crack
        c.px(x, y, "asph0")
    return c


def tile_sidewalk():
    c = C(32, 32, "conc")
    c.speckle(["conc2", "seam"], 0.05, 2)
    for k in (0, 16):
        c.rect(k, 0, 1, 32, "seam"); c.rect(0, k, 32, 1, "seam")
        c.rect(k + 1, 1, 1, 31, "conc2"); c.rect(1, k + 1, 31, 1, "conc2")
    return c


def roof_base(seed):
    c = C(32, 32, "roof")
    c.speckle(["roof2", "asph"], 0.07, seed)
    return c


def tile_building():
    # Plain gravel: this one texture repeats over every rooftop, so any detail turns into wallpaper.
    return roof_base(3)


def tile_billboard():
    c = roof_base(4)
    c.rect(1, 5, 30, 22, "blue", 70)                             # glow pooling on the roof
    c.box(3, 7, 26, 18, "deep", light="blue", shade="ink")
    c.rect(6, 10, 12, 3, "yellow"); c.rect(6, 15, 18, 2, "paper"); c.rect(6, 19, 8, 2, "blue")
    c.disc(23, 11, 2, "clay")
    for x in range(4, 28, 3):                                     # marquee bulbs
        c.px(x, 7, "yellow"); c.px(x, 24, "yellow")
    return c


def tile_subway():
    c = tile_sidewalk()
    c.box(9, 8, 14, 22, "night", outline="ink")
    for y in range(11, 29, 3):
        c.rect(10, y, 12, 1, "roof2")                             # steps going down
    c.rect(9, 8, 1, 22, "steel"); c.rect(22, 8, 1, 22, "steel")  # rails
    for x in (5, 26):                                             # the green globes
        c.rect(x, 6, 1, 6, "steel")
        c.disc(x, 4, 2, "green"); c.px(x - 1, 3, "paper")
    return c


def tile_sewer():
    c = tile_road()
    c.disc(16, 16, 10, "ink"); c.disc(16, 16, 9, "steel"); c.disc(16, 16, 7, "seam")
    for k in (-4, 0, 4):
        c.rect(10, 16 + k, 13, 1, "steel"); c.rect(16 + k, 10, 1, 13, "steel")
    c.px(12, 11, "fog"); c.px(13, 10, "fog")
    return c


def tile_empty():
    c = C(32, 32, "night")
    c.speckle(["asph0", "roof"], 0.08, 7)
    rnd = random.Random(8)
    for _ in range(5):                                            # rubble
        x, y = rnd.randrange(3, 26), rnd.randrange(3, 26)
        c.box(x, y, rnd.choice([4, 5, 6]), rnd.choice([3, 4]), "roof2", light="steel", shade="roof")
    return c


# ---- colonists (32x32) ---------------------------------------------------------------------

def person(stride=0):
    """A chunky survivor in a clay-coloured jacket. stride -1/0/1 swings the legs for the walk cycle."""
    c = C(32, 32)
    c.shadow(16, 30, 9, 2, 80)                                    # ground shadow
    l, r = (12 - stride, 17 + stride) if stride else (12, 17)
    for x, lift in ((l, stride < 0), (r, stride > 0)):           # legs, shoes
        c.rect(x, 22, 4, 7 - lift, "ink"); c.rect(x + 1, 22, 2, 6 - lift, "pants")
        c.rect(x, 28 - lift, 5, 2, "ink")
    c.box(9, 13, 14, 10, "clay", light="clayL", shade="clay2")            # jacket
    c.rect(15, 14, 2, 8, "clay2"); c.rect(14, 13, 4, 2, "paper")          # zip, collar
    c.rect(7, 14 + max(stride, 0), 3, 7, "ink"); c.rect(8, 15 + max(stride, 0), 1, 5, "clay2")  # arms
    c.rect(22, 14 - min(stride, 0), 3, 7, "ink"); c.rect(23, 15 - min(stride, 0), 1, 5, "clay2")
    c.box(10, 3, 12, 11, "skin", shade="skin2")                    # head
    c.rect(10, 3, 12, 4, "ink"); c.rect(11, 4, 10, 2, "hair"); c.rect(11, 6, 2, 3, "hair")  # hair
    c.px(14, 9, "ink"); c.px(18, 9, "ink")                          # eyes
    return c


# ---- buildings -----------------------------------------------------------------------------

def shelter():  # 64x64, 2x2 tiles
    c = C(64, 64)
    c.shadow(32, 59, 28, 3, 95)
    for i in range(24):                                            # canvas roof, Fez-flat with a lit side
        c.rect(32 - i, 12 + i, 1, 1, "ink"); c.rect(32 + i, 12 + i, 1, 1, "ink")
        c.rect(33 - i, 13 + i, i, 1, "clayL"); c.rect(32, 13 + i, i, 1, "clay2")
    c.box(10, 36, 44, 22, "roof3", light="fog", shade="roof2")     # walls
    c.box(26, 42, 12, 16, "night")                                  # door, warm light spilling out
    c.rect(27, 43, 10, 14, "glow", 190); c.rect(28, 56, 8, 3, "glow", 100)
    for x in range(12, 54, 5):                                      # string lights
        c.px(x, 34 + (x // 5) % 2, "yellow")
    c.box(14, 46, 8, 6, "deep", light="blue")                       # window
    c.box(42, 46, 8, 6, "deep", light="blue")
    for x in range(6, 58, 7):                                       # sandbags
        c.box(x, 55, 7, 4, "steel", light="fog", shade="seam")
    return c


def generator():  # 64x64
    c = C(64, 64)
    c.shadow(32, 59, 28, 3, 95)
    c.box(6, 22, 52, 36, "steel", light="fog", shade="seam")
    for x in range(10, 36, 4):
        c.rect(x, 28, 2, 18, "roof")                                # vents
    for x in range(6, 58, 6):                                       # hazard band
        c.rect(x, 50, 3, 4, "yellow"); c.rect(x + 3, 50, 3, 4, "ink")
    c.box(40, 28, 14, 14, "night"); c.rect(42, 30, 10, 4, "amber"); c.disc(44, 38, 1, "clay"); c.disc(50, 38, 1, "green")
    c.box(14, 6, 6, 18, "roof3", light="fog")                       # exhaust and its puff
    for (x, y, r) in ((17, 4, 3), (22, 2, 2), (26, 1, 1)):
        c.disc(x, y, r, "fog")
    return c


def drill():  # 32x32: a pump-jack drill rig on a steel plate, amber work light
    c = C(32, 32)
    c.shadow(16, 30, 13, 2, 95)
    c.box(3, 23, 26, 6, "steel", light="fog", shade="seam")                 # base plate
    for x in (6, 22):
        c.rect(x, 25, 3, 2, "yellow"); c.rect(x + 3, 25, 3, 2, "ink")        # hazard marks
    c.rect(14, 4, 4, 19, "ink"); c.rect(15, 5, 2, 17, "fog")                  # mast
    for y in range(7, 21, 4):
        c.rect(12, y, 8, 1, "ink"); c.px(13, y, "steel"); c.px(18, y, "steel")  # cross braces
    c.box(10, 2, 12, 5, "roof3", light="fog", shade="roof2")                  # motor head
    c.disc(16, 4, 1, "clay")
    c.rect(15, 21, 2, 3, "ink"); c.px(16, 23, "clay")                        # bit
    return c


def beacon():  # 64x64: a stepped tower to a lit spire, brand blue
    c = C(64, 64)
    c.glow(32, 52, 31, "glow", 70)                                             # light pooling on the street
    c.shadow(32, 60, 26, 3, 95)
    c.box(8, 44, 48, 15, "roof3", light="fog", shade="roof2")                 # podium
    c.box(15, 31, 34, 14, "steel", light="fog", shade="seam")                 # second tier
    c.box(22, 20, 20, 12, "roof3", light="fog", shade="roof2")                # third tier
    c.box(27, 12, 10, 9, "steel", light="fog", shade="seam")                  # crown
    for (x0, y0, x1, y1) in ((11, 48, 52, 56), (18, 35, 45, 42), (25, 23, 38, 29)):
        for x in range(x0, x1, 4):
            c.rect(x, y0, 2, y1 - y0, "amber")                                 # lit windows
            c.rect(x, y0, 2, 2, "glow")
    c.rect(31, 2, 2, 11, "ink"); c.rect(31, 3, 1, 9, "fog")                    # mast
    c.disc(32, 3, 3, "ink"); c.disc(32, 3, 2, "clay")                          # the lamp
    for r, a in ((9, 40), (6, 70)):
        for i in range(-r, r + 1):
            for j in range(-r, r + 1):
                if i * i + j * j <= r * r and (i * i + j * j) > (r - 2) ** 2:
                    c.px(32 + i, 3 + j, "clay", a)                             # glow ring
    c.box(28, 50, 8, 9, "night"); c.rect(29, 51, 6, 8, "glow", 200)            # door
    return c


# ---- resources (16x16) ---------------------------------------------------------------------

def res_food():
    c = C(16, 16)
    for x in (2, 8):
        c.box(x, 5, 6, 9, "fog", light="paper", shade="steel"); c.rect(x + 1, 8, 4, 3, "clay")
    c.box(5, 1, 6, 6, "fog", light="paper", shade="steel"); c.rect(6, 3, 4, 2, "clay")
    return c


def res_materials():
    c = C(16, 16)
    c.box(1, 9, 14, 4, "steel", light="fog", shade="seam")
    c.box(3, 5, 11, 4, "roof3", light="fog", shade="roof2")
    c.box(5, 1, 7, 4, "steel", light="fog", shade="seam")
    c.px(4, 11, "ink"); c.px(12, 11, "ink"); c.px(7, 7, "ink")
    return c


def res_power():
    c = C(16, 16)
    c.box(3, 3, 10, 12, "steel", light="fog", shade="seam"); c.rect(6, 1, 4, 2, "ink")
    for (x, y) in ((8, 5), (7, 6), (6, 7), (7, 8), (8, 8), (9, 9), (8, 10), (7, 11)):
        c.px(x, y, "yellow"); c.px(x + 1, y, "yellow")
    return c


SPRITES = {
    "tile_road": tile_road, "tile_sidewalk": tile_sidewalk, "tile_building": tile_building,
    "tile_billboard": tile_billboard, "tile_subway": tile_subway, "tile_sewer": tile_sewer, "tile_empty": tile_empty,
    "colonist_idle": lambda: person(0), "colonist_walk1": lambda: person(-1), "colonist_walk2": lambda: person(1),
    "shelter": shelter, "generator": generator, "drill": drill, "beacon": beacon,
    "res_food": res_food, "res_materials": res_materials, "res_power": res_power,
}


def write(name, im):
    d = os.path.join(ASSETS, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    images = []
    for scale in (1, 2, 3):
        fn = f"{name}.png" if scale == 1 else f"{name}@{scale}x.png"
        im.resize((im.width * scale, im.height * scale), Image.NEAREST).save(os.path.join(d, fn), optimize=True)
        images.append({"filename": fn, "idiom": "universal", "scale": f"{scale}x"})
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump({"images": images, "info": {"author": "xcode", "version": 1}}, f, indent=2)


def main():
    drawn = {name: fn().im for name, fn in SPRITES.items()}
    os.makedirs(WEB, exist_ok=True)
    for f in os.listdir(WEB):
        if f.endswith(".png") and f[:-4] not in drawn:
            os.remove(os.path.join(WEB, f))
    for name, im in drawn.items():
        write(name, im)
        im.resize((im.width * 2, im.height * 2), Image.NEAREST).save(os.path.join(WEB, f"{name}.png"), optimize=True)
    if "--sheet" in sys.argv:
        out = sys.argv[sys.argv.index("--sheet") + 1]
        cell = 112
        names = list(drawn)
        sheet = Image.new("RGBA", (cell * 7, cell * ((len(names) + 6) // 7)), P["night"] + (255,))
        for i, n in enumerate(names):
            im = drawn[n]
            k = max(1, min(cell // im.width, cell // im.height) - 0)
            big = im.resize((im.width * k, im.height * k), Image.NEAREST)
            sheet.alpha_composite(big, ((i % 7) * cell + (cell - big.width) // 2, (i // 7) * cell + (cell - big.height) // 2))
        sheet.save(out)
    print(f"{len(drawn)} sprites written")


if __name__ == "__main__":
    main()

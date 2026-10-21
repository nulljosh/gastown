"""NYC Sans: Inter (rsms/inter, SIL Open Font License 1.1, no reserved name), renamed, figures made proportional.

Inter was drawn for screens in the same grotesk family as San Francisco and Helvetica, which is the brief
(Joshua, 2026-10-21: "more like Helvetica or San Francisco, just sans serif, proportionally spaced"). Same method
as Coda's Quip Sans: pinned release, renamed, OFL shipped beside the fonts, original copyright kept in the name
table. Four weights, Latin only, every build the same bytes.

    uv run --with fonttools --with brotli python3 scripts/gen_font.py           # Resources/Fonts/*.ttf, landing/fonts/*.woff2, OFL.txt in both
    uv run --with fonttools --with brotli python3 scripts/gen_font.py --check   # named NYC Sans, OFL present, proportional, I l 1 O 0 distinct
"""
import io
import os
import sys
import urllib.request

from fontTools.ttLib import TTFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TTF_DIR = os.path.join(HERE, "Resources", "Fonts")
WOFF_DIR = os.path.join(HERE, "landing", "fonts")
SOURCE = "https://cdn.jsdelivr.net/npm/@fontsource/inter@5.1.0/"
WEIGHTS = {"Regular": 400, "Medium": 500, "Semibold": 600, "Bold": 700}


def fetch(path):
    """Bytes of one file from the pinned Inter release."""
    with urllib.request.urlopen(SOURCE + path, timeout=60) as r:
        return r.read()


def proportional_figures(font):
    """Respace the digits so each keeps the 0's side bearings around its own ink: a 1 is narrower than a 0."""
    glyf, hmtx, cmap = font["glyf"], font["hmtx"], font.getBestCmap()
    zero = glyf[cmap[ord("0")]]
    left, right = zero.xMin, hmtx[cmap[ord("0")]][0] - zero.xMax
    for d in "0123456789":
        name = cmap[ord(d)]
        g = glyf[name]
        g.coordinates.translate((left - g.xMin, 0))
        g.recalcBounds(glyf)
        hmtx[name] = (round(g.xMax - g.xMin + left + right), g.xMin)


def rename(font, style):
    """Give the outlines the NYC Sans name; copyright (0) and license (13, 14) stay as the authors wrote them."""
    names = {1: "NYC Sans", 2: style, 3: f"NYCSans-{style}", 4: f"NYC Sans {style}", 5: "Version 1.000",
             6: f"NYCSans-{style}", 16: "NYC Sans", 17: style}
    table = font["name"]
    table.names = [n for n in table.names if n.nameID in (0, 13, 14)]
    for nid, text in names.items():
        table.setName(text, nid, 3, 1, 0x409)
        table.setName(text, nid, 1, 0, 0)
    font["head"].created = font["head"].modified = 3_700_000_000   # fixed, so every build is the same bytes
    font["OS/2"].achVendID = "NYCS"


def to_bytes(font, flavor):
    """The font as TTF (flavor None) or WOFF2 bytes."""
    font.flavor = flavor
    buf = io.BytesIO()
    font.save(buf, reorderTables=False)
    return buf.getvalue()


def check():
    """Self-check of the shipped files."""
    for d in (TTF_DIR, WOFF_DIR):
        assert os.path.exists(os.path.join(d, "OFL.txt")), "the OFL must ship with the fonts"
    for style in WEIGHTS:
        for path in (os.path.join(TTF_DIR, f"NYCSans-{style}.ttf"), os.path.join(WOFF_DIR, f"NYCSans-{style}.woff2")):
            f = TTFont(path)
            assert f["name"].getDebugName(1) == "NYC Sans" and f["name"].getDebugName(6) == f"NYCSans-{style}"
            assert "Inter" in (f["name"].getDebugName(0) or ""), "the original copyright must stay in the name table"
            cmap, hmtx, glyf = f.getBestCmap(), f["hmtx"], f["glyf"]
            assert hmtx[cmap[ord("i")]][0] < hmtx[cmap[ord("m")]][0], "letters are not proportional"
            assert hmtx[cmap[ord("1")]][0] < hmtx[cmap[ord("0")]][0], "figures are not proportional"
            shapes = {glyf[cmap[ord(c)]].coordinates.array.tobytes() for c in "Il1O0"}
            assert len(shapes) == 5, "two of I l 1 O 0 are drawn the same"
    print(f"font ok: NYC Sans (Inter, OFL), {len(WEIGHTS)} weights, proportional figures")


def main():
    """Fetch Inter, rename it, respace the figures, write every weight and the license; or run the check."""
    if "--check" in sys.argv:
        return check()
    lic = fetch("LICENSE")
    for d in (TTF_DIR, WOFF_DIR):
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, "OFL.txt"), "wb") as f:
            f.write(lic)
    for style, weight in WEIGHTS.items():
        font = TTFont(io.BytesIO(fetch(f"files/inter-latin-{weight}-normal.woff2")))
        proportional_figures(font)
        rename(font, style)
        with open(os.path.join(TTF_DIR, f"NYCSans-{style}.ttf"), "wb") as f:
            f.write(to_bytes(font, None))
        with open(os.path.join(WOFF_DIR, f"NYCSans-{style}.woff2"), "wb") as f:
            f.write(to_bytes(font, "woff2"))
        print(f"NYCSans-{style}: Inter {weight}")


if __name__ == "__main__":
    main()

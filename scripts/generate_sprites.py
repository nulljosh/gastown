#!/usr/bin/env python3
"""Generate Fez-style pixel art sprites for NYC Survive."""

from PIL import Image, ImageDraw
import os
import json

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPRITES_DIR = os.path.join(BASE, "Resources", "Assets.xcassets")


def save_imageset(name, img, subdir=""):
    """Save image as an Xcode imageset with 1x/2x/3x scales (nearest upscale, crisp on Retina)."""
    path = os.path.join(SPRITES_DIR, subdir, f"{name}.imageset")
    os.makedirs(path, exist_ok=True)
    images = []
    for scale in (1, 2, 3):
        suffix = "" if scale == 1 else f"@{scale}x"
        fname = f"{name}{suffix}.png"
        scaled = img if scale == 1 else img.resize((img.width * scale, img.height * scale), Image.NEAREST)
        scaled.save(os.path.join(path, fname))
        images.append({"filename": fname, "idiom": "universal", "scale": f"{scale}x"})
    contents = {
        "images": images,
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(path, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)


def pixel_scale(pixels, src_size, dst_size):
    """Scale pixel art from src to dst size using nearest neighbor."""
    img = Image.new("RGBA", (src_size, src_size), (0, 0, 0, 0))
    for y, row in enumerate(pixels):
        for x, color in enumerate(row):
            if color:
                img.putpixel((x, y), color)
    return img.resize((dst_size, dst_size), Image.NEAREST)


def pixel_scale_rect(pixels, src_w, src_h, dst_w, dst_h):
    """Scale pixel art from src to dst size for non-square sprites."""
    img = Image.new("RGBA", (src_w, src_h), (0, 0, 0, 0))
    for y, row in enumerate(pixels):
        for x, color in enumerate(row):
            if color:
                img.putpixel((x, y), color)
    return img.resize((dst_w, dst_h), Image.NEAREST)


# -- Colonist sprites (12x12 pixel grid -> 32x32, Fez-style with outlines) --

SKIN = (232, 190, 152, 255)
SKIN_SHADE = (198, 156, 118, 255)
HAIR = (56, 40, 34, 255)
PANTS = (52, 58, 78, 255)
PANTS_D = (36, 40, 56, 255)
EYE = (30, 30, 40, 255)


def make_colonist(body_color, eye_color=EYE):
    """12x12 humanoid with 1px dark outline. Chunky Fez style.
    Skin-tone face with hair; body_color is the shirt (state tint), dark pants."""
    N = None
    B = body_color
    E = eye_color
    D = tuple(max(0, c - 60) if i < 3 else c for i, c in enumerate(body_color))  # shirt shade
    L = tuple(min(255, c + 40) if i < 3 else c for i, c in enumerate(body_color))  # shirt highlight
    O = (20, 20, 30, 255)  # dark outline
    H = HAIR
    S = SKIN
    F = SKIN_SHADE
    P = PANTS
    Q = PANTS_D
    pixels = [
        [N, N, N, N, O, O, O, O, N, N, N, N],  # head outline top
        [N, N, N, O, H, H, H, H, O, N, N, N],  # hair
        [N, N, N, O, E, S, S, E, O, N, N, N],  # eyes on skin
        [N, N, N, O, S, S, F, F, O, N, N, N],  # face with shading
        [N, N, O, B, L, B, B, B, B, O, N, N],  # shoulders + highlight
        [N, N, O, B, D, D, D, D, B, O, N, N],  # torso
        [N, N, O, B, D, D, D, D, B, O, N, N],  # torso 2
        [N, N, O, B, B, B, B, B, B, O, N, N],  # belt
        [N, N, N, O, P, P, P, P, O, N, N, N],  # hips (pants)
        [N, N, N, O, P, N, N, P, O, N, N, N],  # legs
        [N, N, O, P, P, N, N, P, P, O, N, N],  # calves
        [N, N, O, Q, Q, N, N, Q, Q, O, N, N],  # feet
    ]
    return pixel_scale(pixels, 12, 32)


def make_colonist_walk(body_color, frame=1):
    N = None
    B = body_color
    E = EYE
    D = tuple(max(0, c - 60) if i < 3 else c for i, c in enumerate(body_color))
    L = tuple(min(255, c + 40) if i < 3 else c for i, c in enumerate(body_color))
    O = (20, 20, 30, 255)
    H = HAIR
    S = SKIN
    F = SKIN_SHADE
    P = PANTS
    Q = PANTS_D
    if frame == 1:
        pixels = [
            [N, N, N, N, O, O, O, O, N, N, N, N],
            [N, N, N, O, H, H, H, H, O, N, N, N],
            [N, N, N, O, E, S, S, E, O, N, N, N],
            [N, N, N, O, S, S, F, F, O, N, N, N],
            [N, N, O, B, L, B, B, B, B, O, N, N],
            [N, N, O, B, D, D, D, D, B, O, N, N],
            [N, N, O, B, D, D, D, D, B, O, N, N],
            [N, N, O, B, B, B, B, B, B, O, N, N],
            [N, N, N, O, P, P, P, P, O, N, N, N],
            [N, O, P, N, N, N, N, N, P, O, N, N],  # legs apart
            [O, P, P, N, N, N, N, N, N, P, P, O],
            [O, Q, Q, N, N, N, N, N, N, Q, Q, O],
        ]
    else:
        pixels = [
            [N, N, N, N, O, O, O, O, N, N, N, N],
            [N, N, N, O, H, H, H, H, O, N, N, N],
            [N, N, N, O, E, S, S, E, O, N, N, N],
            [N, N, N, O, S, S, F, F, O, N, N, N],
            [N, N, O, B, L, B, B, B, B, O, N, N],
            [N, N, O, B, D, D, D, D, B, O, N, N],
            [N, N, O, B, D, D, D, D, B, O, N, N],
            [N, N, O, B, B, B, B, B, B, O, N, N],
            [N, N, N, O, P, P, P, P, O, N, N, N],
            [N, N, N, O, P, P, P, P, O, N, N, N],  # legs together
            [N, N, N, O, P, N, N, P, O, N, N, N],
            [N, N, N, O, Q, N, N, Q, O, N, N, N],
        ]
    return pixel_scale(pixels, 12, 32)


def make_colonist_dead():
    N = None
    G = (102, 102, 102, 255)
    D = (70, 70, 70, 255)
    X = (200, 50, 50, 255)
    O = (20, 20, 30, 255)
    pixels = [
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, O, O, O, O, O, O, O, O, N, N],
        [N, O, G, G, G, G, G, G, G, G, O, N],
        [N, O, D, X, D, D, D, D, X, D, O, N],
        [N, O, G, G, G, G, G, G, G, G, O, N],
        [N, N, O, O, O, O, O, O, O, O, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
        [N, N, N, N, N, N, N, N, N, N, N, N],
    ]
    return pixel_scale(pixels, 12, 32)


# Colors matching colonist states
COLONIST_COLORS = {
    "idle": (122, 242, 120, 255),      # green - healthy
    "hungry": (255, 230, 110, 255),     # yellow
    "suffocating": (0, 245, 212, 255),  # cyan
    "exhausted": (255, 107, 54, 255),   # orange
    "dead": (102, 102, 102, 255),       # gray
}


# -- Building sprites --

def make_shelter():
    """16x16 pixel grid -> 64x64. Small house with door and cyan roof. Dark outline."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    outline = (20, 20, 30, 255)
    # Outline first
    draw.polygon([(0, 8), (8, 0), (15, 8)], fill=outline)
    draw.rectangle([2, 7, 13, 15], fill=outline)
    # Roof (cyan) with highlight edge and shaded underside
    roof = (0, 200, 180, 255)
    draw.polygon([(1, 7), (8, 1), (14, 7)], fill=roof)
    draw.line([(2, 6), (8, 1)], fill=(120, 240, 225, 255))
    draw.line([(2, 7), (13, 7)], fill=(0, 150, 135, 255))
    # Walls with subtle brick courses
    wall = (60, 70, 90, 255)
    draw.rectangle([3, 7, 12, 14], fill=wall)
    brick = (52, 61, 79, 255)
    draw.line([(3, 10), (12, 10)], fill=brick)
    draw.line([(3, 13), (12, 13)], fill=brick)
    # Door
    door = (40, 45, 60, 255)
    draw.rectangle([6, 10, 9, 14], fill=door)
    # Windows
    window = (150, 220, 255, 200)
    draw.rectangle([4, 8, 5, 9], fill=window)
    draw.rectangle([10, 8, 11, 9], fill=window)
    return img.resize((64, 64), Image.NEAREST)


def make_food_stall():
    """8x8 -> 32x32. Counter with yellow awning. Dark outline."""
    N = None
    O = (20, 20, 30, 255)     # outline
    Y = (255, 230, 110, 255)  # yellow awning
    W = (80, 70, 60, 255)     # wood
    D = (60, 50, 40, 255)     # dark wood
    G = (120, 200, 100, 255)  # green food
    pixels = [
        [O, Y, Y, Y, Y, Y, Y, O],
        [O, Y, Y, Y, Y, Y, Y, O],
        [O, W, W, W, W, W, W, O],
        [O, W, G, G, G, G, W, O],
        [O, W, G, G, G, G, W, O],
        [O, W, W, W, W, W, W, O],
        [O, D, O, N, N, O, D, O],
        [O, D, O, N, N, O, D, O],
    ]
    return pixel_scale(pixels, 8, 32)


def make_generator():
    """16x16 -> 64x64. Industrial box with lightning bolt. Dark outline."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    outline = (20, 20, 30, 255)
    # Outline
    draw.rectangle([1, 3, 14, 15], fill=outline)
    # Box
    box = (80, 60, 50, 255)
    draw.rectangle([2, 4, 13, 14], fill=box)
    # Darker border
    border = (50, 35, 30, 255)
    draw.rectangle([2, 4, 13, 4], fill=border)
    draw.rectangle([2, 14, 13, 14], fill=border)
    draw.rectangle([2, 4, 2, 14], fill=border)
    draw.rectangle([13, 4, 13, 14], fill=border)
    # Vent slats + top highlight
    vent = (60, 44, 38, 255)
    draw.line([(3, 12), (5, 12)], fill=vent)
    draw.line([(10, 12), (12, 12)], fill=vent)
    draw.line([(3, 5), (12, 5)], fill=(100, 78, 66, 255))
    # Lightning bolt (orange, thicker)
    bolt = (255, 140, 50, 255)
    for px, py in [(8, 5), (9, 5), (7, 6), (8, 6), (6, 7), (7, 7),
                   (6, 8), (7, 8), (8, 8), (9, 8), (10, 8),
                   (8, 9), (9, 9), (7, 10), (8, 10), (6, 11), (7, 11)]:
        draw.point((px, py), fill=bolt)
    return img.resize((64, 64), Image.NEAREST)


def make_filter_station():
    """16x16 -> 64x64. Dome/tank, cyan tinted. Dark outline."""
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    outline = (20, 20, 30, 255)
    # Outline
    draw.ellipse([2, 1, 13, 9], fill=outline)
    draw.rectangle([3, 6, 12, 15], fill=outline)
    # Dome top
    dome = (0, 180, 160, 255)
    draw.ellipse([3, 2, 12, 8], fill=dome)
    # Tank body
    tank = (0, 150, 135, 255)
    draw.rectangle([4, 7, 11, 14], fill=tank)
    # Highlight
    highlight = (100, 230, 220, 200)
    draw.rectangle([5, 3, 6, 5], fill=highlight)
    # Bubbles
    bubble = (200, 255, 250, 230)
    draw.point((6, 9), fill=bubble)
    draw.point((9, 11), fill=bubble)
    draw.point((7, 12), fill=bubble)
    return img.resize((64, 64), Image.NEAREST)


def make_subway_access():
    """8x8 -> 32x32. Stairs going down with magenta sign."""
    N = None
    S = (60, 60, 70, 255)     # stairs
    D = (40, 40, 50, 255)     # dark
    M = (247, 38, 133, 255)   # magenta sign
    W = (200, 200, 200, 255)  # white text
    pixels = [
        [N, M, M, M, M, M, M, N],
        [N, M, W, N, W, N, M, N],
        [N, N, N, N, N, N, N, N],
        [S, S, N, N, N, N, N, N],
        [D, S, S, N, N, N, N, N],
        [D, D, S, S, N, N, N, N],
        [D, D, D, S, S, N, N, N],
        [D, D, D, D, S, S, S, S],
    ]
    return pixel_scale(pixels, 8, 32)


def make_billboard():
    """16x8 -> 64x32. Rectangular sign with neon ad."""
    N = None
    F = (50, 50, 60, 255)      # frame
    P = (247, 38, 133, 255)    # pink neon
    B = (30, 30, 40, 255)      # background
    W = (255, 255, 255, 255)   # white
    C = (0, 245, 212, 255)     # cyan
    pixels = [
        [F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F],
        [F, B, B, B, B, B, B, B, B, B, B, B, B, B, B, F],
        [F, B, P, P, B, C, C, B, P, P, B, C, C, B, B, F],
        [F, B, P, B, B, C, B, B, P, B, B, C, B, B, B, F],
        [F, B, P, P, B, C, C, B, P, P, B, C, C, B, B, F],
        [F, B, B, B, B, B, B, B, B, B, B, B, B, B, B, F],
        [F, B, W, W, W, B, W, B, W, W, B, W, W, W, B, F],
        [F, F, F, F, F, F, F, F, F, F, F, F, F, F, F, F],
    ]
    return pixel_scale_rect(pixels, 16, 8, 64, 32)


# -- Resource sprites (8x8 -> 16x16, diamond-shaped) --

def make_res_food():
    """Green apple/leaf."""
    N = None
    G = (120, 200, 100, 255)
    D = (80, 160, 60, 255)
    S = (60, 120, 40, 255)    # stem
    pixels = [
        [N, N, N, S, N, N, N, N],
        [N, N, N, G, G, N, N, N],
        [N, N, G, G, G, G, N, N],
        [N, G, G, D, G, G, G, N],
        [N, G, G, G, G, G, G, N],
        [N, N, G, G, G, G, N, N],
        [N, N, N, G, G, N, N, N],
        [N, N, N, N, N, N, N, N],
    ]
    return pixel_scale(pixels, 8, 16)


def make_res_power():
    """Yellow lightning bolt."""
    N = None
    Y = (255, 230, 110, 255)
    B = (255, 200, 50, 255)
    pixels = [
        [N, N, N, N, Y, N, N, N],
        [N, N, N, Y, Y, N, N, N],
        [N, N, Y, Y, N, N, N, N],
        [N, Y, Y, Y, Y, Y, N, N],
        [N, N, N, N, B, B, N, N],
        [N, N, N, B, B, N, N, N],
        [N, N, B, B, N, N, N, N],
        [N, N, N, N, N, N, N, N],
    ]
    return pixel_scale(pixels, 8, 16)


def make_res_materials():
    """Orange gear/brick."""
    N = None
    O = (255, 140, 50, 255)
    D = (200, 100, 30, 255)
    pixels = [
        [N, N, N, O, O, N, N, N],
        [N, N, O, D, D, O, N, N],
        [N, O, D, O, O, D, O, N],
        [O, D, O, N, N, O, D, O],
        [O, D, O, N, N, O, D, O],
        [N, O, D, O, O, D, O, N],
        [N, N, O, D, D, O, N, N],
        [N, N, N, O, O, N, N, N],
    ]
    return pixel_scale(pixels, 8, 16)


def make_res_oxygen():
    """Cyan bubble."""
    N = None
    C = (0, 220, 200, 200)
    L = (150, 250, 245, 220)  # highlight
    D = (0, 160, 145, 180)
    pixels = [
        [N, N, N, C, C, N, N, N],
        [N, N, C, C, C, C, N, N],
        [N, C, L, L, C, C, C, N],
        [C, C, L, C, C, C, C, C],
        [C, C, C, C, C, D, C, C],
        [N, C, C, C, C, C, C, N],
        [N, N, C, C, C, C, N, N],
        [N, N, N, C, C, N, N, N],
    ]
    return pixel_scale(pixels, 8, 16)


def make_res_cash():
    """Pink/magenta coin."""
    N = None
    P = (247, 80, 160, 255)
    D = (200, 40, 120, 255)
    W = (255, 200, 230, 255)
    pixels = [
        [N, N, N, P, P, N, N, N],
        [N, N, P, P, P, P, N, N],
        [N, P, P, W, W, P, P, N],
        [P, P, W, P, P, W, P, P],
        [P, P, W, P, P, W, P, P],
        [N, P, P, W, W, P, P, N],
        [N, N, P, P, P, P, N, N],
        [N, N, N, P, P, N, N, N],
    ]
    return pixel_scale(pixels, 8, 16)


# -- Tile sprites (16x16 -> 32x32) --

def speckle(img, colors, count, seed):
    """Deterministic noise speckle for tile texture."""
    import random
    rng = random.Random(seed)
    for _ in range(count):
        img.putpixel((rng.randrange(16), rng.randrange(16)), rng.choice(colors))


def make_tile_road():
    img = Image.new("RGBA", (16, 16), (38, 38, 51, 255))
    speckle(img, [(45, 45, 58, 255), (32, 32, 44, 255)], 30, seed=1)
    draw = ImageDraw.Draw(img)
    # Lane markings
    lane = (80, 80, 90, 200)
    draw.rectangle([7, 0, 8, 3], fill=lane)
    draw.rectangle([7, 6, 8, 9], fill=lane)
    draw.rectangle([7, 12, 8, 15], fill=lane)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_sidewalk():
    img = Image.new("RGBA", (16, 16), (89, 89, 102, 255))
    speckle(img, [(96, 96, 110, 255), (82, 82, 95, 255)], 35, seed=2)
    draw = ImageDraw.Draw(img)
    # Concrete texture (subtle grid lines)
    line = (80, 80, 92, 255)
    draw.line([(0, 8), (15, 8)], fill=line)
    draw.line([(8, 0), (8, 15)], fill=line)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_subway():
    img = Image.new("RGBA", (16, 16), (60, 55, 30, 255))
    draw = ImageDraw.Draw(img)
    # Yellow platform edge
    edge = (255, 230, 110, 255)
    draw.rectangle([0, 14, 15, 15], fill=edge)
    draw.rectangle([0, 0, 15, 1], fill=edge)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_building():
    img = Image.new("RGBA", (16, 16), (13, 28, 41, 255))
    draw = ImageDraw.Draw(img)
    # Window grid
    win = (30, 60, 80, 200)
    for y in [2, 6, 10, 14]:
        for x in [2, 6, 10, 14]:
            draw.rectangle([x, y, x + 1, y + 1], fill=win)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_billboard():
    img = Image.new("RGBA", (16, 16), (80, 20, 50, 255))
    draw = ImageDraw.Draw(img)
    # Neon glow
    glow = (247, 38, 133, 120)
    draw.rectangle([0, 0, 15, 15], fill=glow)
    # Bright center
    bright = (247, 80, 160, 200)
    draw.rectangle([4, 4, 11, 11], fill=bright)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_sewer():
    img = Image.new("RGBA", (16, 16), (35, 50, 35, 255))
    draw = ImageDraw.Draw(img)
    # Grate pattern
    grate = (25, 35, 25, 255)
    for y in [3, 7, 11]:
        draw.line([(2, y), (13, y)], fill=grate)
    for x in [4, 8, 12]:
        draw.line([(x, 2), (x, 13)], fill=grate)
    return img.resize((32, 32), Image.NEAREST)


def make_tile_empty():
    img = Image.new("RGBA", (16, 16), (13, 13, 26, 255))
    speckle(img, [(18, 18, 33, 255), (10, 10, 21, 255)], 20, seed=3)
    return img.resize((32, 32), Image.NEAREST)


# -- Contents.json for Sprites root --

def write_folder_contents(path):
    os.makedirs(path, exist_ok=True)
    contents = {"info": {"author": "xcode", "version": 1}, "properties": {"provides-namespace": True}}
    with open(os.path.join(path, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)


def main():
    # Colonists
    idle_color = COLONIST_COLORS["idle"]
    save_imageset("colonist_idle", make_colonist(idle_color))
    save_imageset("colonist_walk1", make_colonist_walk(idle_color, 1))
    save_imageset("colonist_walk2", make_colonist_walk(idle_color, 2))
    save_imageset("colonist_dead", make_colonist_dead())

    # State variants
    for state_name, color in COLONIST_COLORS.items():
        if state_name != "dead":
            save_imageset(f"colonist_{state_name}", make_colonist(color))

    # Buildings
    save_imageset("shelter", make_shelter())
    save_imageset("foodStall", make_food_stall())
    save_imageset("generator", make_generator())
    save_imageset("filterStation", make_filter_station())
    save_imageset("subwayAccess", make_subway_access())
    save_imageset("billboard", make_billboard())

    # Resources
    save_imageset("res_food", make_res_food())
    save_imageset("res_power", make_res_power())
    save_imageset("res_materials", make_res_materials())
    save_imageset("res_oxygen", make_res_oxygen())
    save_imageset("res_cash", make_res_cash())

    # Tiles
    save_imageset("tile_road", make_tile_road())
    save_imageset("tile_sidewalk", make_tile_sidewalk())
    save_imageset("tile_subway", make_tile_subway())
    save_imageset("tile_building", make_tile_building())
    save_imageset("tile_billboard", make_tile_billboard())
    save_imageset("tile_sewer", make_tile_sewer())
    save_imageset("tile_empty", make_tile_empty())

    print(f"Sprites generated in {SPRITES_DIR}")


if __name__ == "__main__":
    main()

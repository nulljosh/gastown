# Gastown brand kit and design system

Gastown is a Vancouver colony game: a crew you send to work, machines that run themselves, and the Gastown Steam Clock to raise. The mark is that clock.

## The mark
One bold flat white glyph on an accent gradient tile. No text, no outline, no emblem.

- `../Gastown.icon` is the source of truth (Icon Composer). Light and dark fills are set in it.
- `../icon.svg` is the flat copy for READMEs (shown at 80 px). `icon-1024.png` is the App Store icon, no alpha.
- `mark.svg` is the glyph alone in `currentColor` for your own background.
- Clear space equal to the width of the glyph's thickest stroke. Smallest size 16 px.

## Colour
| Role | Value |
|---|---|
| Accent | `#0b2f8a` |
| Gradient top | `#3d7bff` |
| Text | `#1d1d1f` light, `#f5f5f7` dark |
| Night (game, bands) | `#141a2e` |
| Clay (sprites only) | `#b5502c` |
| Cream (highlights) | `#f6f0e4` |
| Background | `#ffffff` light, `#000000` dark |
| Surface | `#f5f5f7` light, `#1c1c1e` dark |

The accent is for actions, links and the icon. Never brown, beige, purple or teal.

## Type
Gastown Sans everywhere (Inter, renamed, built by `scripts/gen_font.py`), falling back to the system font. Scale 34/41 bold, 22/28, 17/24, 15/20, 13/18.

## Sprites
Pixel art from `scripts/gen_sprites.py`: one palette, noir night with clay and cream, ink outlines, chamfered corners, soft shadows. Clay lives in the sprites; the brand colour is blue. The landing halftones come from the same sprites (`scripts/gen_landing_art.py`).

## Space and shape
- Space on the 8 point grid: 4, 8, 12, 16, 24, 32, 48. Side margin 20. Reading column 680.
- Radii: cards 28, grouped lists 20, controls fully round, icon 22 percent.
- Controls are 48 points tall capsules, one height in a row. Focus is a 4 point ring at 30 percent accent.
- Motion is 0.2 s ease and honours reduced motion.

`tokens.css` holds the app's accent. Everything else comes from the shared token file.

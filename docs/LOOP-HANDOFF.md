# Gastown loop handoff (2026-10-21, early afternoon)

Gastown is the new name for NYC Survive. Joshua locked it on 2026-10-21. It is free on the App Store: it was probed on the real record, and the listing was then restored to "NYC Survive".

## What the loop is

Ship Gastown 2.0.0 to the App Store, then keep polishing. Stop at 96% weekly usage (the usage hook prints it every prompt). The headless bots are the win check: `node web/sim.mjs` and `scripts/playthrough.sh`. Both must keep winning after any rule change, with the same rules on web and native.

## Where things stand

- **The game.** It's a Pikmin crew with Factorio machines, set in Vancouver. You send a crew to a resource and they keep working it. Generators make power. A drill beside a resource mines it and burns power, one per patch. Shelters add beds, and a bed plus 10 food brings a survivor each day. Raise the Steam Clock to win (internal id `beacon`, 8,000 materials and 1,000 power).
- **The map.** It has Burrard Inlet and False Creek (water is `TileType.empty`), seawall paths, one bridge and SkyTrain stations. It rains on both platforms.
- **Bots and tests.** The web bot wins in about 12 minutes and the native bot on day 12 or 13. 6 web tests and 19 Swift tests pass. CI goes yellow when pushes land close together (cancel-in-progress), so batch pushes.
- **Rename sweep.** Gastown.xcodeproj, the Gastown and Gastown-iOS schemes, GastownWatch, Gastown.icon, Gastown Sans (rebuilt by `scripts/gen_font.py`), docs and landing.
- **Still on old names on purpose.** These are the bundle IDs `com.heyitsmejosh.nyc*`, the Worker name `nyc`, web save key `nyc2_save_`, native save folder `NYCSurvive`, the `nyc-theme` keys, and `nyc-controls-hint-seen`.
- **Art.** `scripts/gen_sprites.py` draws clay and cream on noir into the xcassets and `web/sprites/`, including water, SkyTrain and the Steam Clock. `scripts/gen_landing_art.py` makes the landing halftones from our own sprites and frames, with no outside photos. The hero film is `landing/hero.mp4`, recorded through `window._ff` (`?bg` only).
- **QA hooks.** `-colony` builds a small working colony on both platforms. `-colony -beacon` also raises the clock and shows the win banner. Use them for store screenshots.
- **Store.** iOS and Mac 1.1.0 are live as NYC Survive. An iOS 2.0.0 version exists in PREPARE_FOR_SUBMISSION (727699a1), with no build or new metadata yet.

## Next, in order

1. **Repo and domain.**
   - `gh repo rename gastown`, then `git remote set-url`, plus homepage and description.
   - Move `~/Documents/Code/nyc` to `gastown` and fix the paths in labs CLAUDE.md and .gitignore.
   - Add the `gastown.jaybulb.com` route in `wrangler.toml` and keep `nyc.jaybulb.com`.
   - Deploy and curl both hosts.
2. **Brand kit.** The icon is still the Empire State Building.
   - Make a Steam Clock glyph on clay `#b5502c` (Gastown.icon, `icon.svg`, favicons).
   - Rewrite `brand/BRAND.md` and `brand/tokens.css` (clay accent, noir, cream).
   - Move the landing accent from blue to clay.
3. **Store metadata for 2.0.0.**
   - Name Gastown, plus subtitle, description and keywords.
   - whatsNew covering the new name, the new game, and that 1.x saves don't carry over.
   - Review notes.
   - Screenshots from `-colony` (6.5" iPhone, iPad 13", Mac).
4. **Ship.** Bump `MARKETING_VERSION` to 2.0.0 with a new build. Run `asc workflow run ship-ios` and `ship-mac`, `asc validate`, `review items add`, and submit once CI is green.
5. **Landing leftovers.** "See it played" still plays the 1.x `playthrough.mp4`, so re-record a 2.0 run. Remake `og.png`.
6. **Docs.** `docs/API.md`, `ARCHITECTURE.md`, `CONTROLS.md` and `WHITEPAPER.md` still use 1.x terms. Autosave is every 60 ticks (15 s).
7. **Embedded game.** The web game embedded on the landing runs in light theme. Force dark in `?embed`.

## Restart prompt

```
/loop Gastown 2.0. Work ~/Documents/Code/gastown/docs/LOOP-HANDOFF.md "Next, in order" top to bottom. Both bots must keep winning (same rules on web and native). Commit and push in nulljosh/gastown, batching pushes. Send screenshots of every visible change. Never submit to App Review until CI is green, native QA is done and store metadata is updated. Stop at 96% weekly usage.
```

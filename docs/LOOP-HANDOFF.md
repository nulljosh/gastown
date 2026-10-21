# NYC Survive loop handoff (2026-10-21, midday)

## What the loop is

Ship NYC Survive 2.0.0, then keep polishing. Stop at 96% weekly usage (the usage hook prints it every prompt). The headless bots are the win check: `node web/sim.mjs` and `scripts/playthrough.sh`. Both must keep winning after any rule change, with the same rules on web and native.

## Where things stand

2.0 is the simplification Joshua asked for ("radical simplicity, more like Pikmin and Factorio"). You send a crew to a resource and they keep working it. Generators make power. A drill beside a resource mines it and burns power, one drill per patch. Shelters add beds, and a bed plus 10 food brings a survivor each day. The Beacon (8,000 materials, 1,000 power) is the win. Needs, stats, traits, XP, weapons, raids, quests, oxygen and cash are gone.

- Web and native rules match. The web bot wins in about 12 minutes, and the native playthrough wins on day 13.
- Tests: 6 web tests and 19 Swift tests, all green. CI was broken before 2.0 because the scheme had no test action and the test host used the old app name. That's fixed in `project.yml`.
- Sprites are clay and cream on noir, with chamfered corners and soft shadows. They come from `scripts/gen_sprites.py`, which writes both the xcassets and `web/sprites/`.
- The landing is live at nyc.jaybulb.com. It has a dark hero over `landing/hero.mp4`, a film of the attract city recorded with headless Chrome frame capture through `window._ff` (`?bg` only), plus parallax and the 2.0 copy.
- Saves moved to `nyc2_save_` (web) and `save2_N.json` (native). 1.x saves are ignored, never decoded.
- Store: iOS and Mac 1.1.0 are live. 2.0.0 is not created or submitted yet.

## Next, in order

1. Confirm CI on main is green across all three jobs (`gh run list -R nulljosh/nyc -L 1`).
2. Native visual QA on a Release build, Mac and iOS sim. Cover the 3 tutorial steps, squad select and gather, all 4 buildings (a drill beside a node), and the Beacon banner, then Keep playing (it must not re-pause).
3. Store metadata for 2.0.0:
   - new gameplay screenshots (6.5" iPhone, iPad 12.9", Mac; Release build, not the menu)
   - rewritten description and promo text
   - whatsNew that says 1.x saves don't carry over
   - App Review notes on the redesign
4. Bump `MARKETING_VERSION` to 2.0.0 with a new build number. Then `asc workflow run ship-ios VERSION:2.0.0` and `ship-mac VERSION:2.0.0 BUILD:$(date +%Y%m%d%H%M)`, `asc validate`, `review items add`, submit.
5. Landing: "See it played" still plays the 1.x `playthrough.mp4`. Re-record a 2.0 run, and check `og.png`.
6. README screenshots and alt text, plus `docs/API.md`, `ARCHITECTURE.md` and `CONTROLS.md`: replace old terms. Autosave is every 60 ticks (15 s).
7. Embedded web game on the landing runs in light theme on the blue stage. Consider forcing dark in `?embed`.

## Restart prompt

```
/loop NYC Survive 2.0. Work nyc/docs/LOOP-HANDOFF.md "Next, in order" top to bottom. Both bots must keep winning (same rules on web and native). Commit and push in nulljosh/nyc. Send screenshots of every visible change. Stop at 96% weekly usage.
```

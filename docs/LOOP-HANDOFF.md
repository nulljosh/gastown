# Gastown loop handoff (2026-10-21, late morning)

Gastown is the new name for NYC Survive. Joshua locked it on 2026-10-21. The App Store listing still says NYC Survive until 2.0.0 ships.

## What the loop is

Get Gastown 2.0.0 through CI and into App Review, then keep polishing. Stop at 96% weekly usage (the usage hook prints it every prompt). The headless bots are the win check: `node web/sim.mjs` and `scripts/playthrough.sh`. Both must keep winning after any rule change, with the same rules on web and native.

## Where things stand

- **The game.** A Vancouver colony game in the spirit of Pikmin and Factorio. You command a crew, and drills and generators run on their own. A drill beside a resource mines it and burns power, one per patch. Needs, raids, weapons, quests and cash are cut. Shelters add beds, and a bed plus 10 food brings a survivor each day. Raise the Steam Clock to win (internal id `beacon`, 8,000 materials and 1,000 power).
- **Rules.** Web and native share the same rules. Both bots win in about 12 days.
- **The map.** Burrard Inlet and False Creek (water is `TileType.empty`), seawall paths, one bridge and SkyTrain stations. It rains on both platforms.
- **Tests and CI.** 6 web tests and 19 Swift tests pass locally. The test workflow runs the scheme test target, which is fixed. CI goes yellow when pushes land close together (cancel-in-progress), so batch pushes. Latest run: `5795fdf` (landing), still in progress at 10:53.
- **Repo and domain.** Repo is `nulljosh/gastown` (public), folder `~/Documents/Code/gastown`. Labs CLAUDE.md and .gitignore are updated for the rename. The landing is at gastown.jaybulb.com with no embedded game, and nyc.jaybulb.com still serves.
- **Brand and art.** New sprite set, Gastown Sans (rebuilt by `scripts/gen_font.py`), a blue Steam Clock icon and brand kit in `brand/` (BRAND.md, brand-board.png). The README has new screenshots. `scripts/gen_sprites.py` draws the sprites, and `scripts/gen_landing_art.py` makes the landing art from our own sprites.
- **Still on old names on purpose.** Bundle IDs `com.heyitsmejosh.nyc*`, the Worker name `nyc`, web save key `nyc2_save_`, native save folder `NYCSurvive`, the `nyc-theme` keys and `nyc-controls-hint-seen`.
- **QA hooks.** `-colony` builds a small working colony on both platforms. `-colony -beacon` also raises the clock and shows the win banner. Use them for store screenshots.
- **Store.** iOS and Mac 1.1.0 are live as NYC Survive. The iOS 2.0.0 version exists in App Store Connect (727699a1, PREPARE_FOR_SUBMISSION) with the app name set to Gastown. It has no build and no new metadata beyond the name. There is no Mac 2.0.0 yet. Nothing is submitted.

## Next, in order

1. **CI.** Confirm the Tests run on `5795fdf` goes green on main. If it goes red, fix the cause and do not mute it.
2. **2.0.0 store metadata.** The name is Gastown. Still to write: subtitle, description, keywords, what's new (new name, new game, and that 1.x saves don't carry over) and review notes.
3. **Screenshots.** From `-colony` and `-colony -beacon` for 6.5" iPhone, iPad 13" and Mac. Check that the landing's "See it played" section shows 2.0 footage.
4. **Mac 2.0.0.** Create the Mac version beside iOS 2.0.0 in App Store Connect.
5. **Version bump and build.** Set `MARKETING_VERSION` to 2.0.0 with a new build on both platforms. Run `asc workflow run ship-ios` and `ship-mac`, then `asc validate` and `review items add`. Submit only on Joshua's yes.
6. **Docs.** Rewrite `docs/API.md`, `docs/ARCHITECTURE.md`, `docs/CONTROLS.md` and `WHITEPAPER.md`, which still use 1.x terms, for the 2.0 rules. Autosave is every 60 ticks (15 s).

## Restart prompt

```
/loop Gastown 2.0. Work ~/Documents/Code/gastown/docs/LOOP-HANDOFF.md "Next, in order" top to bottom. Both bots must keep winning (same rules on web and native). Commit and push in nulljosh/gastown, batching pushes. Send screenshots of every visible change. Never submit to App Review until CI is green, native QA is done and store metadata is updated. Stop at 96% weekly usage.
```

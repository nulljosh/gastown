# Gastown loop handoff (2026-10-21, midday)

Gastown is the new name for NYC Survive. Joshua locked it on 2026-10-21. The App Store listing still says NYC Survive until 2.0.0 ships.

## What the loop is

Get Gastown 2.0.0 through CI and into App Review, then keep polishing. Stop at 96% weekly usage (the usage hook prints it every prompt). The headless bots are the win check: `node web/sim.mjs` and `scripts/playthrough.sh`. Both must keep winning after any rule change, with the same rules on web and native.

## Where things stand

- **The game.** A Vancouver colony game in the spirit of Pikmin and Factorio. You command a crew, and drills and generators run on their own. A drill beside a resource mines it and burns power, one per patch. Needs, raids, weapons, quests and cash are cut. Shelters add beds, and a bed plus 10 food brings a survivor each day. Raise the Steam Clock to win (internal id `beacon`, 8,000 materials and 1,000 power).
- **Rules.** Web and native share the same rules. Both bots win in about 12 days.
- **The map.** Burrard Inlet and False Creek (water is `TileType.empty`), seawall paths, one bridge and SkyTrain stations. It rains on both platforms.
- **Tests and CI.** 6 web tests and 19 Swift tests pass locally. The test workflow runs the scheme test target, which is fixed. The last full green run on main was `d57633f`; `66db5bd` was still queued at 11:52 PT. CI goes yellow when pushes land close together (cancel-in-progress), so batch pushes.
- **Repo and domain.** Repo is `nulljosh/gastown` (public), folder `~/Documents/Code/gastown`. Labs CLAUDE.md and .gitignore are updated for the rename. The landing is at gastown.jaybulb.com with no embedded game, and nyc.jaybulb.com still serves.
- **Brand and art.** New sprite set, Gastown Sans (rebuilt by `scripts/gen_font.py`), a blue Steam Clock icon and brand kit in `brand/` (BRAND.md, brand-board.png). The README has new screenshots. `scripts/gen_sprites.py` draws the sprites, and `scripts/gen_landing_art.py` makes the landing art from our own sprites.
- **Still on old names on purpose.** Bundle IDs `com.heyitsmejosh.nyc*`, the Worker name `nyc`, web save key `nyc2_save_`, native save folder `NYCSurvive`, the `nyc-theme` keys and `nyc-controls-hint-seen`.
- **QA hooks.** `-colony` builds a small working colony on both platforms. `-colony -beacon` also raises the clock and shows the win banner. Use them for store screenshots.
- **Player-facing copy.** The menu, HUD, win banner ("THE STEAM CLOCK STANDS") and landing say Steam Clock and colonists, not Beacon and survivors. The menu tagline no longer clips on iPhone. The Mac entitlements file and the iOS export profile carry the Gastown name, which fixed two shipping breaks.
- **Landing on phones.** No embedded game. On phones only Safari's App Store banner shows; the black store bar is desktop only.
- **Store.** iOS and Mac 1.1.0 are live as NYC Survive. iOS and Mac 2.0.0 exist in App Store Connect with the Gastown name and listing text (subtitle "Raise the Steam Clock", description, keywords, what's new). Both builds are uploaded, processed and attached. Nothing is submitted.
- **Screenshots, the blocker.** Apple fails every new screenshot upload with ASSET_FAILED, on every set. A one-pixel edit of a screenshot Apple had already accepted fails too, on Gastown and on Epiphany, so the fault is on Apple's side and account-wide. Tested with PNG and JPEG, two encoders, native and resized sizes, through asc and the raw API. The new frames are ready in `.asc/screenshots/2.0/`.

## Next, in order

1. **Screenshots.** Retry the upload with `python3 .asc/upload-shot.py SET_ID FILE` from `.asc/screenshots/2.0/`, one set at a time, and again later. If it still fails after a day or two, ask Apple developer support, with the one-pixel test as evidence.
2. **Submit, on Joshua's yes only.** Once every set has its frames, submit iOS and Mac 2.0.0. Never run `asc workflow run ship-ios` as is: `.asc/workflow.json` sets `SUBMIT` to true by default, so it would send the build to review on its own.
3. **CI.** Keep main green. If a run goes red, fix the cause and do not mute it.
4. **Listing check.** Read the Gastown listing on both 2.0.0 versions before any submit, including What's New and the App Review notes.
5. **Docs.** Rewrite `docs/API.md`, `docs/ARCHITECTURE.md`, `docs/CONTROLS.md` and `WHITEPAPER.md`, which still use 1.x terms, for the 2.0 rules.

## Restart prompt

```
/loop Gastown 2.0. Work ~/Documents/Code/gastown/docs/LOOP-HANDOFF.md "Next, in order" top to bottom. Both bots must keep winning (same rules on web and native). Commit and push in nulljosh/gastown, batching pushes. Send screenshots of every visible change. Never submit to App Review until CI is green, native QA is done and store metadata is updated. Stop at 96% weekly usage.
```

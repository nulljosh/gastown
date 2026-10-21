# Changelog

## Unreleased (2026-10-21)

Still version 1.1.0. No version bump yet.

- **The game can be won.** Native had the wrong XP curve: level N cost N × 100 XP, so level 8 took 2,800 XP instead of 650. It now uses the web game's curve. Native has no quests, so gathering pays XP on every harvest. The headless playthrough wins on days 21 to 23, about 1.5 hours at normal speed.
- **New Game starts in 0.05 s** instead of 7.7 s. The pathfinder is a bitmap with a breadth-first search now.
- **Clicks land.** A drag has to move 6 pt before it becomes a box-select, so hand jitter no longer clears the selection.
- **Tutorial fixes.** Card clicks work. The scrim on step 7 no longer hides colonists. Steps that wait for you no longer advance after 30 seconds. Step 10 no longer names a SAVE button that does not exist. The Mac copy says Click, not Tap. A one-time controls card shows after the tutorial.
- **HUD.** The log and clock are readable in light mode. The minimap draws the city instead of an empty box. The victory card sits in the middle instead of the top-left corner.
- **Menu.** The live city runs behind the menu. Buttons are capsules with a hover state. Menu type is NYC Sans.
- **NYC Sans.** The game's own typeface, built from Inter (SIL Open Font License 1.1) by `scripts/gen_font.py`.
- **New icon.** The Empire State Building, in `NYC.icon`.
- **Mac.** The app is called NYC Survive in the Dock. The window resizes, and Settings has a Full screen switch.
- **Headless play.** `scripts/playthrough.sh 200` plays the game to a win with no window. The `-demo 200` flag runs the tutorial and then the bot, for a recording.
- **License** is now Apache 2.0.
- **Privacy policy** is updated and says plainly that the game collects nothing and makes no network calls.
- **Domain** is `nyc.jaybulb.com`.

## 1.1.0 (2026-10-05)

The game can be won. Survivors join when there is a free bed and food; victory is 15 alive at average level 8. Click a survivor or drag a box, click the ground to move, click a resource to gather. Buildings burn materials and break when the pile is empty. Scavengers raid every third night unless someone is on patrol. New title screen with Settings and how-to-play, bigger sprites, 10-step tutorial. Web: the HUD had been swallowing every mouse click; fixed. Submitted to App Review on iOS and macOS the same night.

## Earlier notes

These builds were numbered before the store versions. They are kept for the record.

### v1.3.1

- Fix tutorial/HUD unclickable on macOS and iOS (HUD subtree had hit-testing disabled; taps fell through to the game scene)
- Harden SaveManager: corrupt saves log instead of failing silently, guard against invalid grid size
- Test suite expanded to 19 tests: no-autoplay regression, move orders, save round-trip, legacy save decode, tutorial flow

### v1.3.0

- Sprite refresh: colonists get hair, skin-tone faces, two-tone outfits; textured road/sidewalk/empty tiles; all sprites now export @1x/@2x/@3x (crisp on Retina)
- Controls reference in Settings now covers select-then-tap move orders and macOS keyboard shortcuts (WASD, B, 1-6, Space, Cmd+S, Esc)

### v1.2.0

- Removed autoplay completely: deleted colony directive engine (`autoAssignIdle`, `ColonyDirective`, directive HUD pills, `jobOverride`)
- Game is fully player-controlled: select colonist + tap to move, assign jobs via colonist panel
- Tutorial step 6 now teaches manual command instead of directives
- Applies to both macOS and iOS targets (shared `Sources/`)

### v1.1.0 (earlier numbering)

- Transformed from colony sim → Factorio-style factory game
- Unified iOS + macOS codebase (single Sources-Shared/)
- Added portrait + landscape support (iOS only)
- Replaced colonist AI with production building system
- 4 building types with auto-pull logistics
- ItemType-based inventory (replaced ResourceType)
- Progress bar visualization for production recipes
- Simplified GameState (no colonists, no complex resources)
- Updated SaveManager for new model schema

### v1.0.0

- Stable colony sim release
- Colonist AI, weapons, building placement
- 3-slot save system, interactive tutorial
- Camera controls, mini-map

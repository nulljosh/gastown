# Gastown Technical Whitepaper

**v2.0.0** | October 2026

Send a crew to work, build machines that run themselves, and raise the Steam Clock over Vancouver.

Gastown is a small colony game. The colonists do only what the player tells them. Nobody auto-assigns a job, and nobody wanders off to work on their own. Machines run without anyone nearby, but every trip out to gather is an order. The rules are small on purpose: three resources, four buildings, one goal. SpriteKit and Swift 6, one codebase for iPhone, iPad and Mac. The same game runs in a browser at gastown.jaybulb.com/app.

## The Loop

A day is 240 ticks. A tick is a quarter of a second, so a day takes one minute. You start with 30 food, 40 materials and no power.

1. **Resources.** Food, materials and power. Colonists gather food and materials from nodes on the map, one unit every four ticks per colonist. Nodes respawn when they run dry.
2. **Orders.** Select a colonist, or drag a box around several, then tap the ground to move them or tap a resource to gather it. A gathering colonist keeps working until told otherwise.
3. **Machines.** A generator makes 1 power every 2 ticks. A drill placed beside a node mines 1 unit every 4 ticks and burns 1 power each time, and the patch never runs dry under it. Neither needs a colonist nearby.
4. **Recruits.** Once a day a new colonist arrives if there is a free bed and 10 food. The colony starts with 4 beds, each shelter adds 4, and it tops out at 20 people. Recruits arrive idle.
5. **The goal.** The Steam Clock costs 8000 materials and 1000 power. Build it and you win.

Costs: shelter 10 materials, generator 15 materials, drill 12 materials and 2 power. There are no needs, no raids, no levels and no timers that punish you for stepping away.

The map is Vancouver: Burrard Inlet across the top, False Creek with a single bridge, the seawall, SkyTrain stations, and rain that never quite stops. A headless playthrough (`scripts/playthrough.sh`) and the web bot (`web/sim.mjs`) both win in about 12 game days, and they have to keep winning after every rules change.

## Commands

Colonists act only on explicit orders:

- Click or tap a colonist, or drag a box around several (Mac).
- Click the ground to move them. `JobSystem.commandMove()` handles it.
- Click a resource to gather it. `JobSystem.commandGather()` handles it.

Auto-assignment was removed on 2026-07-02 and again on 2026-08-02, when two other systems were found to bring it back. It must not return. Recruits arrive idle for the same reason.

## Architecture

- **Rendering.** The world renders in SpriteKit. The HUD, menus and settings are SwiftUI views over the scene.
- **Layout.** One `Sources/` tree, with a thin entry point per platform in `Sources/App` (Mac) and `Sources/AppiOS` (iPhone and iPad). The game logic is shared.
- **State.** `GameState.swift` is the single source of truth. `SaveManager.swift` writes JSON to three save slots, and the game autosaves every 60 ticks.
- **Systems.** `TimeSystem` advances the clock. `JobSystem` carries out orders. `ResourceSystem` handles gathering and respawn. `ColonySystem` runs generators, drills, recruits and the win check. `BuildSystem` places and removes buildings.
- **Pathfinding.** `Pathfinder.swift` keeps a bitmap of walkable tiles and runs a breadth-first search over it. New Game went from 7.7 seconds to 0.05 seconds when the old grid-graph wall removal was replaced.
- **World.** A 128 by 128 tile grid from `WorldGenerator.swift`: streets, the inlet, the creek and its bridge, and resource nodes.
- **Type.** The Gastown Sans face is Inter, renamed and with proportional figures. `scripts/gen_font.py` builds it.
- **Headless.** `scripts/playthrough/DemoBot.swift` plays the game for `scripts/playthrough.sh`. Tests in `Tests/SimTests.swift` and `web/*.test.mjs` cover the same rules, and the web and native numbers must match.

## Platforms

| Platform | Status |
|---|---|
| iPhone and iPad | 1.1.0 live on the App Store. 2.0.0 is built, uploaded and attached, with screenshots in App Store Connect, and has not been submitted |
| Mac | Same: 1.1.0 live, 2.0.0 built and attached, not submitted |
| Web | Live at gastown.jaybulb.com/app. Static ES modules, saves in local storage |
| Apple Watch | Quick reference for building costs. No pairing, no network |

Saves from 1.x do not carry over to 2.0.

## Open Work

The open list lives in [ROADMAP.md](ROADMAP.md).

## License

Apache License 2.0. See [LICENSE](../LICENSE).

# NYC Survive Technical Whitepaper

**v1.1.0** | October 2026

Reclaim Times Square with a few survivors and a stockpile that never quite covers everything.

NYC Survive is a survival game about choices. The colonists do only what the player tells them. Nobody auto-assigns a job, and nobody wanders off to work on their own. Buildings run on their own, but every trip out to gather is an order. The player watches the stockpile, plans for the next raid, and decides who goes where. The rules are small on purpose. SpriteKit and Swift 6, one codebase for iPhone, iPad and Mac. The same game runs in a browser at nyc.jaybulb.com/app.

## The Loop

A day is 240 ticks. At normal speed a tick is one real second, so a day takes four minutes.

1. **Stockpile.** Five resources: food, power, materials, oxygen and cash. Generators make power. Billboards make cash. Food stalls turn food into meals, and filter stations use power to make air.
2. **Survivors.** Each one has hunger, oxygen, sleep and stress. Hunger and oxygen drain over time. An idle survivor recovers sleep and stress. Survivors eat from the stockpile when they are hungry and breathe from it when they are short of air. Traits (insomniac, iron lung, anxious) change those rates.
3. **Buildings.** Six types: shelter, food stall, generator, filter station, subway access and billboard. Each costs materials plus cash or power. Each one uses a material every ten ticks. With no materials left, it breaks until the stockpile can pay again.
4. **Recruits.** Once a day, a survivor arrives if the colony has a free bed and at least 10 food. Beds come from a base of six, plus four per working shelter. The colony tops out at 20.
5. **Raids.** Every third night at 22:00, scavengers take a fifth of the food, materials and cash. A survivor on patrol within eight tiles of a building turns them back. The game warns at 06:00 so the player has time to set a guard.

**Victory** is 15 survivors alive, an average level of 8, and at least one survivor at level 10. The native and web games use the same rule. The XP curve matches the web game, and gathering pays XP on every harvest, since native has no quests. A headless playthrough (`scripts/playthrough.sh`) wins in about 1.5 hours of play.

## Commands

Colonists act only on explicit orders:

- Click a survivor, or drag a box around several (Mac).
- Click the ground to move them. `JobSystem.commandMove()` handles it.
- Click a resource to gather it. `JobSystem.commandGather()` handles it.

Auto-assignment was removed on 2026-07-02 and again on 2026-08-02, when two other systems were found to bring it back. It must not return.

## Architecture

- **Rendering.** The world renders in SpriteKit. The HUD, menus and settings are SwiftUI views over the scene.
- **Layout.** One `Sources/` tree, with a thin entry point per platform in `Sources/App` (Mac) and `Sources/AppiOS` (iPhone and iPad). The game logic is shared.
- **State.** `GameState.swift` is the single source of truth. `SaveManager.swift` writes JSON to three save slots and autosaves about once a minute.
- **Systems.** `TimeSystem` advances the clock. `NeedsSystem` runs upkeep, needs, recruits, raids and victory. `ResourceSystem` handles gathering. `JobSystem` carries out orders. `BuildSystem` places and removes buildings.
- **Pathfinding.** `Pathfinder.swift` keeps a bitmap of blocked tiles and runs a breadth-first search over it. New Game went from 7.7 seconds to 0.05 seconds when the old grid-graph wall removal was replaced.
- **World.** A 128 by 128 tile grid with avenues and streets, from `WorldGenerator.swift`.
- **Type.** The NYC Sans face is Inter, renamed and with proportional figures. `scripts/gen_font.py` builds it.
- **Headless.** `DemoBot.swift` plays the game for the `-demo` run and for `scripts/playthrough.sh`. Tests in `Tests/SimTests.swift` and `web/*.test.mjs` cover the same rules.

## Platforms

| Platform | Status |
|---|---|
| iPhone and iPad | iOS 1.1.0, live on the App Store since 2026-10-06 |
| Mac | macOS 1.1.0, submitted 2026-10-05. Review status lives in App Store Connect |
| Web | Live at nyc.jaybulb.com/app. Static ES modules, saves in local storage |
| Apple Watch | Quick reference for costs, traits and weapon stats. No pairing, no network |

## Open Work

The open list lives in [ROADMAP.md](ROADMAP.md).

## License

Apache License 2.0. See [LICENSE](LICENSE).

# nyc

v1.1.0, macOS + iOS colony survival game, fully player-controlled (no autoplay). Live at `https://nyc.jaybulb.com`, web app at `/app`. License Apache 2.0.

## The loop

Live /loop on nyc: fix the game, QA until it works. See `docs/LOOP-HANDOFF.md` for resume state and next steps.

## Rules

- SpriteKit for all rendering, no UIKit/AppKit views in game scene
- Colonists act only on orders. Never reintroduce auto-assignment (removed 2026-07-02 and 2026-08-02).
- Rules that exist twice (victory, XP curve, raids, needs) must match between `Sources/` and `web/js/`. Change both or neither.
- The NYC Sans typeface is built by `scripts/gen_font.py`. Don't hand-edit the .ttf files.
- No emojis. No em dashes in docs.

## Structure

- **Sources/**: the only game source tree and the build target (see `project.yml`). Game logic, models, HUD.
- **web/**: the browser game, plain ES modules, no bundler. `scripts/build-site.sh` copies it to `dist/app/`.
- **watchos/**: quick-reference companion app, its own XcodeGen project.
- `Sources-Shared/`, `Sources-macOS/`, `Sources-iOS/`, `nyc-ios/` are gone. Don't recreate them.

## Run

```bash
xcodegen generate && open NYCSurvive.xcodeproj
```

## Key Files

- Sources/Game/Scenes/GameScene.swift: Main gameplay loop, input → command wiring
- Sources/Game/Systems/JobSystem.swift: Colonist orders (commandMove, commandGather)
- Sources/Game/Systems/NeedsSystem.swift: Upkeep, needs, recruits, raids, victory (`isVictory`)
- Sources/Game/Systems/Pathfinder.swift: Bitmap plus breadth-first search
- scripts/playthrough/DemoBot.swift: the bot for the headless playthrough. Outside Sources/ on purpose, the app never plays itself
- Sources/Game/Systems/BuildSystem.swift: Building placement and demolition
- Sources/Models/ColonistModel.swift: XP curve (matches `web/js/state.js`)
- Sources/Models/GameState.swift: Central state
- Sources/Models/SaveManager.swift: JSON save/load (3 slots, autosave every 60 ticks)
- scripts/playthrough.sh: headless win check. `scripts/gen_font.py`: NYC Sans
- Tests/SimTests.swift and web/*.test.mjs: `node --test` runs the web tests

## Imported from Nyc.pdf (2026-06-21)
- [x] iOS target added 2026-06-30 (`NYCSurvive-iOS` scheme, touch controls), builds clean for simulator.
- [x] iOS build 2 uploaded to ASC 2026-07-03, generated new IOS_DISTRIBUTION cert (`38S6CX4DJ5`, key kept in login keychain), provisioning profile `HZKYCVUVRH`, exported + uploaded via `asc xcode export` / `asc builds upload`. Support URL set to `https://nyc.jaybulb.com`.
- [x] Build 3 rejected 2026-07-04 (ITMS-90474 missing iPad orientation key, ITMS-90055 bundle ID mismatch). Root cause: `INFOPLIST_KEY_UISupportedInterfaceOrientations~ipad` build-setting syntax does NOT generate the device-qualified plist key, Xcode silently drops it. Fixed by adding a real `Resources/Info-iOS.plist` with both orientation keys. Also fixed iOS target bundle ID from `com.heyitsmejosh.nyc.ios` to `com.heyitsmejosh.nyc` to match the registered ASC app record (created new bundle ID reg + provisioning profile `39Y8RMMQMU`, ExportOptions updated). Build 5 uploaded and processed clean 2026-07-04.
- [x] Build 5 uploaded 2026-07-04, description/keywords set, 6.5" screenshot uploaded, review contact + encryption declaration filled in. Submission was blocked on 3 things once believed "ASC web UI only", **2 of the 3 turned out to be CLI-fixable and were done 2026-08-03**: (1) App Privacy answers → `asc web privacy apply --file` then `publish --confirm`; (2) privacy policy URL → real page written at `web/privacy.html`, deployed, then `asc localizations update --app 6782618198 --type app-info --locale en-US --privacy-policy-url ...`. Only (3) the iPad Pro 12.9" screenshot remains. See `ROADMAP.md` for the exact finish sequence.
- [x] macOS 1.0 SUBMITTED 2026-08-03 (WAITING_FOR_REVIEW, submission `55ebe4b1`) after setting the build encryption declaration via `asc builds update --uses-non-exempt-encryption=false`.
- [x] iOS 1.0.0 SUBMITTED 2026-08-04 (WAITING_FOR_REVIEW, submission `9338674e`, build 6). iPad gameplay screenshot captured from a Release sim build and uploaded. Capturing it exposed that `showsFPS`/`showsNodeCount` were unconditional, the debug counter was shipping to users, now `#if DEBUG` gated in both `Sources/App/` and `Sources/AppiOS/`, which is why build 6 exists.
- [x] Watch app added 2026-09-02 (`watchos/`, standalone watchOS target, XcodeGen). Not a live-save mirror: it's a quick-reference (building costs, colonist traits, weapon stats) ported from `Sources/Models/`. No pairing, no network, no App Group.
- [ ] Define concrete next steps to ship the game
- [x] Manual colonist control fixed 2026-07-01, `assignJob()` was dead code, colonists were 100% directive-driven. Added `JobSystem.commandMove()` wired to select-then-tap-destination in GameScene.
- [x] Autoplay fully resolved 2026-08-02, 2026-07-02 only removed the directive engine; two other systems were perpetuating autoplay: (1) GameScene.swift hardcoded startup job assignments, (2) JobSystem.swift's tick() self-renewed targets forever. Removed both. Also cleaned web/js/systems.js dead autopilot block (survivalActions, infrastructureActions, autoplayTick, assignIdleColonist, autoGenerateQuests). Colonists act only on player commands (select + tap to move, job pills in ColonistPanel). Do NOT reintroduce auto-assignment.
- [ ] Improve the tutorial/onboarding polish
- [ ] Vibe-clone the portfolio UI into the project
- [x] iOS 1.0.0 rejected 2026-08-26 (Guideline 2.3.3): the 6.5" set was the title/menu screen, which Apple counts as a splash, not the app in use. Replaced with three captured gameplay shots (colony map, colonist stats panel, build menu) from a Release sim build on iPhone 11 Pro Max. The stale `iPhone_14_Plus_01.png` in the same folder was also the old "TIMES SQUARE" title screen and got swept into the 6.5" set by the fan-out upload, deleted from ASC and moved to `.asc/screenshots/_unused/`. Resubmitting needed cancelling the UNRESOLVED_ISSUES submission first, same as Sparkjar.

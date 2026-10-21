# nyc loop log (goal: more Factorio + Pikmin)

## Round 1, 2026-10-05: analysis

Read JobSystem, ResourceSystem, NeedsSystem, BuildingModel, TimeSystem.

Findings
- BUG: generator and billboard output lives inside the per-colonist loop in NeedsSystem.tick. They only produce when a colonist stands within 3 tiles, and produce once per colonist in range. Empty colony = zero power and zero cash. Food stall also drains food per colonist.
- Gather is instant adjacency harvest, 1 unit per tick, straight into the global pool. Nothing is carried, nothing is hauled.
- Buildings are pure proximity auras. No inputs, outputs, chains, or throughput. Nothing to optimise, so no Factorio feel.
- Every colonist needs a manual select-then-tap. No squad commands, so no Pikmin feel.
- Only 6 buildings and 5 resources. Tests: Tests/SimTests.swift only.

Plan (small slices, one per round)
1. Fix building production out of the colonist loop (BuildingSystem tick, once per building per tick). Test.
2. Carry and haul: gatherers carry a load to the nearest depot/shelter, Pikmin-style trips.
3. Squad: select group, one tap sends all, followers trail the leader.
4. Production chain: generator burns materials into power at a visible rate, throughput shown.
5. Day timer pressure (Pikmin day end) tied to night.

## Log
- R1: analysis done. Fixed: generator and billboard now produce once per building per tick, no colonist needed (NeedsSystem.tickBuildings). Test added, SimTests all green.
- Rule: colonists stay player-commanded (CLAUDE.md). Automation = machines the player builds + squad orders the player gives. No auto-assign.
- Next R2: player-ordered haul trips.
- R2: no serif was found. Removed all monospaced faces (Swift HUD + web --font-mono) so UI is sans only. Controls: selection persists after orders, drag-box selects squads, orders go to the whole squad, click a resource = gather, Esc deselects, selection ring drawn, tutorial copy rewritten. Tests added, green.
- R3: WEB BUG: #hud had pointer-events:auto set inline and covered the canvas, so no mouse click ever reached the game (fixed, hud.js). Web had no move/gather orders at all; added same squad controls + touch taps. Tutorial still taught removed DIRECTIVES; rewritten. Splash on web+native now New Game / Load Game / Settings (how to play), rounded font. Landing has a real scripted playthrough video.
- FOUND: VICTORY needs 15 alive and avg level 8, but nothing ever adds colonists past the starting 8. The web game cannot be won. Next: survivors arrive as the colony grows, then a real win condition + progression pacing for a few hours of play.
- FOUND: sprites are ~12px and resource nodes are tiny dots; unclear what is what. Next: bigger sprites + labels.
- R4: web is now winnable: a recruit arrives each day if there is a free bed (8 + 4 per shelter, cap 20) and 10 food; gathering gives 1 XP per 20 working ticks so avg lvl 8 takes roughly an hour of steady work. Tests in web/recruit.test.mjs. NOT yet mirrored in the Swift app (no recruits or victory there). Next: mirror to Swift, bigger sprites, real playtest to tune pacing.
- R5: wrote web/sim.mjs, a headless bot that plays the web game start to finish (node web/sim.mjs). First run exposed that the game was a death trap: sleep/hunger only restored near buildings, so gatherers died by the dozen (394 deaths in one run). Fixes: idle colonists rest anywhere, the stockpile feeds the hungry and supplies air on its own, food stall and filter only spend when needed, generator and billboard now run per building (same bug as the Swift app), starting food 60. XP 1 per 5 working ticks. Bot results over ~15 worlds: wins in 0.4 to 3.9 hours, median about 1.9h, 1 world never (food-starved). Open: no resource sinks (stockpiles hit 70k, no tension), no threats, Swift app still lacks recruits/victory/rest. Sprites still tiny.
- R6: sprites 1.8x, resource nodes bigger with name + count labels. CI now runs the Swift SimTests on macOS and web/winnable.test.mjs, which plays the game to victory with the bot (2 of 3 worlds, under 5h).
- R7: Mac/iOS app now matches the web: idle colonists rest, stockpile feeds and supplies air, gather XP, daily recruits (6 beds + 4 per shelter, cap 20, 10 food), victory banner with Keep playing. Starting food 60 / O2 60. Three Swift tests added; two old tests updated (they assumed idle colonists starve with a full stockpile). CI Swift job moved to the Xcode 26 runner.
- R8: tension added on both platforms: every building burns 1 materials per 10 ticks and breaks (dimmed, BROKEN) when the pile hits zero; filter stations now actually spend power. Bot still wins in 1.5-2.1h across 5 worlds.
- R9: live QA on nyc.jaybulb.com: controls, bigger sprites and labels all work. Bug: a gather click on a node that sits on a blocked tile did nothing (no path). Added findPathNear (tile or a neighbour) on both platforms, used by click-gather and the gather retarget.
- R10: mid-game bot QA with invariants (NaN/negative resources, needs out of range, colonists on blocked tiles, stuck gatherers, all buildings broken). Real bug: placing a building on a tile someone was walking through, or standing on, walled them in (33 trapped per game). Fixed on both platforms: cannot build on a survivor, and paths through a new footprint are cleared. Tests added. Remaining anomaly is "all buildings broken" stretches when the bot lets materials hit zero; a human sees BROKEN labels and the log. Bot still wins in ~2h.
- R11: iOS target builds clean with the new controls. Save slots and the HUD on Mac showed the wrong day (divided ticks by 24, a day is 240); fixed, HUD now says Day N like the web. CI: one red run was a single slow bot world (5.1h); the winnable test now gates on the median of 3 worlds.
- R12: raids on both platforms. Every third night scavengers take 20% of food, materials and cash unless a survivor is on PATROL within 8 tiles of a building; the log warns at dawn. Patrol used to flip straight back to idle (useless); now it holds position and earns slow XP. Tests on both platforms. Bot still wins in 1.4-2.1h; it loses most raids because it posts its guard wherever it stands, a human reads the warning.
- R13: tutorial and the Settings how-to on both platforms now teach upkeep, raids/patrol and the win condition (10 steps). Step counts derived from the list on web.
- R14: SHIPPED 1.1.0 to App Review on both platforms (iOS submission 1ab8dcd4, Mac 8ead5591, build 202610052145). Added a ship-mac workflow (raw xcodebuild archive + exportArchive, since asc xcode export only writes ipa). Gotcha: publish --submit preflight needs whatsNew on the version first; set it with asc localizations update, then asc review submit --build-id. Review notes updated to describe 1.1.0 truthfully.
- R15: live mid-game check on nyc.jaybulb.com: dawn raid warning, BROKEN generator and the raid loss all show. Night had no visual, added a dusk tint on the web canvas (deeper 22:00-04:00). Mac scene had none either; added a camera-mounted tint node.
- R16 (2026-10-06 03:30): iOS 1.1.0 APPROVED, READY_FOR_SALE. Mac 1.1.0 still WAITING_FOR_REVIEW.

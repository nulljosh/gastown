// Headless playthrough (main.swift so the two lines at the bottom may run at top level): the real world generator, the real systems in GameScene.update's order, and
// DemoBot issuing player commands. No window, no rendering. Exit 0 on victory, 1 if the colony fails
// or the day cap passes. Built and run by scripts/playthrough.sh.
import Foundation

@MainActor func play(maxDays: Int) -> Int32 {
    let gs = GameState()
    gs.autoSaveEnabled = false
    let world = WorldGenerator.generate()
    gs.resourceNodes = world.resources
    let tileMap = TileMap(grid: world.grid)
    let pathfinder = Pathfinder(columns: WorldGenerator.gridSize, rows: WorldGenerator.gridSize)
    pathfinder.buildGraph(grid: world.grid)
    let jobs = JobSystem(); jobs.pathfinder = pathfinder
    let (time, needs, res, builds) = (TimeSystem(), NeedsSystem(), ResourceSystem(), BuildSystem())

    // Same five starters and spawn rule as a fresh GameScene.
    let center = WorldGenerator.gridSize / 2
    for (i, name) in ["Alex", "Jordan", "Casey", "Riley", "Morgan"].enumerated() {
        var spot = (center + i, center)
        search: for dc in 0..<10 { for dr in 0..<10 where tileMap.tileAt(col: center + dc + i, row: center + dr)?.isWalkable == true {
            spot = (center + dc + i, center + dr); break search
        } }
        gs.colonists.append(ColonistModel(id: UUID(), name: name, col: spot.0, row: spot.1))
    }

    var bot = DemoBot()
    while gs.currentTick < maxDays * NeedsSystem.ticksPerDay {
        time.advance(gs)
        needs.tick(gameState: gs)
        jobs.tick(gameState: gs)
        res.tick(gameState: gs, tileMap: tileMap)
        needs.recruitTick(gameState: gs)
        needs.raidTick(gameState: gs)
        bot.tick(gs, jobs: jobs, pathfinder: pathfinder,
                 canPlace: { builds.canPlace(type: $0, col: $1, row: $2, tileMap: tileMap, gameState: gs) },
                 place: { builds.place(type: $0, col: $1, row: $2, tileMap: tileMap, gameState: gs, pathfinder: pathfinder) != nil })
        let alive = gs.colonists.filter { !$0.isDead }
        let day = gs.currentTick / NeedsSystem.ticksPerDay
        if gs.currentTick % (NeedsSystem.ticksPerDay * 5) == 0 || NeedsSystem.isVictory(gs) || alive.isEmpty {
            let avg = alive.isEmpty ? 0 : Double(alive.map(\.level).reduce(0, +)) / Double(alive.count)
            print(String(format: "day %3d  alive %2d  avg lvl %.1f  top %2d  food %4d  o2 %4d  mat %4d  shelters %d",
                         day, alive.count, avg, alive.map(\.level).max() ?? 0, gs.resources[.food] ?? 0,
                         gs.resources[.oxygen] ?? 0, gs.resources[.materials] ?? 0,
                         gs.buildings.filter { $0.type == .shelter }.count))
        }
        if NeedsSystem.isVictory(gs) { print("VICTORY on day \(day)"); return 0 }
        if alive.isEmpty { print("FAILED: everyone died on day \(day)"); return 1 }
    }
    print("FAILED: no win by day \(maxDays)")
    return 1
}

let days = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 200 : 200
exit(MainActor.assumeIsolated { play(maxDays: days) })

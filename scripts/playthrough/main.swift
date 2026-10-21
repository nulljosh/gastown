// Headless playthrough (main.swift so the two lines at the bottom may run at top level): the real world generator, the real systems in GameScene.update's order, and
// DemoBot issuing player commands. No window, no rendering. Exit 0 on victory, 1 if the day cap passes. Built and run by scripts/playthrough.sh.
import Foundation

@MainActor func play(maxDays: Int) -> Int32 {
    let gs = GameState()
    gs.autoSaveEnabled = false
    let world = WorldGenerator.generate()
    gs.resourceNodes = world.resources
    let tileMap = TileMap(grid: world.grid)
    let pathfinder = Pathfinder(columns: WorldGenerator.gridSize, rows: WorldGenerator.gridSize)
    pathfinder.buildGraph(grid: world.grid)
    let jobs = JobSystem()
    let (time, colony, res, builds) = (TimeSystem(), ColonySystem(), ResourceSystem(), BuildSystem())

    // Same four starters and spawn rule as a fresh GameScene.
    let center = WorldGenerator.gridSize / 2
    for (i, name) in ["Alex", "Jordan", "Casey", "Riley"].enumerated() {
        var spot = (center + i, center)
        search: for dc in 0..<10 { for dr in 0..<10 where tileMap.tileAt(col: center + dc + i, row: center + dr)?.isWalkable == true {
            spot = (center + dc + i, center + dr); break search
        } }
        gs.colonists.append(ColonistModel(id: UUID(), name: name, col: spot.0, row: spot.1))
    }

    var bot = DemoBot()
    while gs.currentTick < maxDays * ColonySystem.ticksPerDay {
        time.advance(gs)
        colony.machineTick(gameState: gs)
        jobs.tick(gameState: gs)
        res.tick(gameState: gs, tileMap: tileMap)
        colony.recruitTick(gameState: gs)
        bot.tick(gs, jobs: jobs, pathfinder: pathfinder,
                 canPlace: { builds.canPlace(type: $0, col: $1, row: $2, tileMap: tileMap, gameState: gs) },
                 place: { builds.place(type: $0, col: $1, row: $2, tileMap: tileMap, gameState: gs, pathfinder: pathfinder) != nil })
        let day = gs.currentTick / ColonySystem.ticksPerDay
        if gs.currentTick % (ColonySystem.ticksPerDay * 5) == 0 || ColonySystem.isVictory(gs) {
            print(String(format: "day %3d  crew %2d  food %5d  mat %5d  pwr %5d  shelters %d  drills %d  gens %d",
                         day, gs.colonists.count, gs.resources[.food] ?? 0, gs.resources[.materials] ?? 0, gs.resources[.power] ?? 0,
                         gs.buildings.filter { $0.type == .shelter }.count, gs.buildings.filter { $0.type == .drill }.count,
                         gs.buildings.filter { $0.type == .generator }.count))
        }
        if ColonySystem.isVictory(gs) { print("VICTORY on day \(day)"); return 0 }
    }
    print("FAILED: no win by day \(maxDays)")
    return 1
}

let days = CommandLine.arguments.count > 1 ? Int(CommandLine.arguments[1]) ?? 200 : 200
exit(MainActor.assumeIsolated { play(maxDays: days) })

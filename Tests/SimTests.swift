import XCTest
@testable import NYCSurvive

@MainActor
final class SimTests: XCTestCase {

    func testWorldGeneratorProducesValidGrid() {
        let result = WorldGenerator.generate()
        XCTAssertEqual(result.grid.count, 128)
        XCTAssertEqual(result.grid[0].count, 128)

        var hasRoad = false
        var hasBuilding = false
        var hasSidewalk = false
        for row in result.grid {
            for tile in row {
                if tile == .road { hasRoad = true }
                if tile == .building { hasBuilding = true }
                if tile == .sidewalk { hasSidewalk = true }
            }
        }
        XCTAssertTrue(hasRoad)
        XCTAssertTrue(hasBuilding)
        XCTAssertTrue(hasSidewalk)
        XCTAssertFalse(result.resources.isEmpty)
    }

    func testPathfinderFindsPath() {
        let result = WorldGenerator.generate()
        let pf = Pathfinder(columns: 128, rows: 128)
        pf.buildGraph(grid: result.grid)

        var startCol = 0, startRow = 0
        var endCol = 0, endRow = 0
        var foundStart = false, foundEnd = false

        for row in 0..<128 {
            for col in 0..<128 {
                if result.grid[row][col].isWalkable {
                    if !foundStart {
                        startCol = col; startRow = row; foundStart = true
                    } else if abs(col - startCol) + abs(row - startRow) > 10 {
                        endCol = col; endRow = row; foundEnd = true
                        break
                    }
                }
            }
            if foundEnd { break }
        }

        let path = pf.findPath(fromCol: startCol, fromRow: startRow, toCol: endCol, toRow: endRow)
        XCTAssertFalse(path.isEmpty)
    }

    func testNeedsSystemDecay() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Test", col: 0, row: 0)]
        gs.currentTick = 200  // past the 120-tick grace period
        gs.colonists[0].job = .gather  // working: idle colonists rest and recover instead
        let needs = NeedsSystem()

        let initialHunger = gs.colonists[0].hunger
        let initialOxygen = gs.colonists[0].oxygen

        for _ in 0..<10 {
            needs.tick(gameState: gs)
        }

        XCTAssertLessThan(gs.colonists[0].hunger, initialHunger)
        XCTAssertLessThan(gs.colonists[0].oxygen, initialOxygen)
        XCTAssertGreaterThan(gs.colonists[0].stress, 0)
    }

    func testNeedsSystemDeath() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Doomed", col: 0, row: 0)]
        gs.colonists[0].hunger = 1
        gs.resources[.food] = 0  // an empty stockpile cannot feed them
        gs.currentTick = 200  // past the 120-tick grace period
        let needs = NeedsSystem()
        for _ in 0..<500 where !gs.colonists[0].isDead {
            needs.tick(gameState: gs)
        }
        XCTAssertEqual(gs.colonists[0].state, .dead)
    }

    func testBuildSystemRejectsNonWalkable() {
        let grid = Array(repeating: Array(repeating: TileType.building, count: 10), count: 10)
        let tm = TileMap(grid: grid)
        let gs = GameState()
        gs.resources = [.materials: 100, .cash: 100, .power: 100]
        let bs = BuildSystem()

        XCTAssertFalse(bs.canPlace(type: .shelter, col: 0, row: 0, tileMap: tm, gameState: gs))
    }

    func testBuildSystemAcceptsWalkable() {
        var grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 10), count: 10)
        let tm = TileMap(grid: grid)
        let gs = GameState()
        gs.resources = [.materials: 100, .cash: 100, .power: 100]
        let bs = BuildSystem()

        XCTAssertTrue(bs.canPlace(type: .foodStall, col: 2, row: 2, tileMap: tm, gameState: gs))
    }

    func testResourceSystemConsumeFailsWhenEmpty() {
        let gs = GameState()
        gs.resources = [.food: 0]
        let rs = ResourceSystem()
        XCTAssertFalse(rs.consume(gameState: gs, type: .food, amount: 1))
    }

    func testResourceSystemConsumeSucceeds() {
        let gs = GameState()
        gs.resources = [.food: 10]
        let rs = ResourceSystem()
        XCTAssertTrue(rs.consume(gameState: gs, type: .food, amount: 5))
        XCTAssertEqual(gs.resources[.food], 5)
    }

    func testJobSystemAssignAndClear() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Worker", col: 0, row: 0)]
        let result = WorldGenerator.generate()
        let pf = Pathfinder(columns: 128, rows: 128)
        pf.buildGraph(grid: result.grid)

        let js = JobSystem()
        js.assignJob(colonistIndex: 0, job: .gather, destCol: 5, destRow: 5, gameState: gs, pathfinder: pf)
        XCTAssertEqual(gs.colonists[0].job, .gather)

        js.clearJob(colonistIndex: 0, gameState: gs)
        XCTAssertEqual(gs.colonists[0].job, .idle)
        XCTAssertTrue(gs.colonists[0].pathCols.isEmpty)
    }

    // MARK: - No autoplay (regression: colonists must never self-assign)

    func testIdleColonistsStayIdle() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Idler", col: 5, row: 5)]
        gs.resourceNodes = [ResourceModel(id: UUID(), type: .food, col: 6, row: 6, remaining: 100, maxAmount: 100, respawnTicks: 10)]
        let result = WorldGenerator.generate()
        let pf = Pathfinder(columns: 128, rows: 128)
        pf.buildGraph(grid: result.grid)
        let js = JobSystem()
        js.pathfinder = pf

        for _ in 0..<50 {
            js.tick(gameState: gs)
        }
        XCTAssertEqual(gs.colonists[0].job, .idle)
        XCTAssertFalse(gs.colonists[0].hasPath)
        XCTAssertEqual(gs.colonists[0].col, 5)
        XCTAssertEqual(gs.colonists[0].row, 5)
    }

    func testCommandMoveSetsPath() {
        let result = WorldGenerator.generate()
        let pf = Pathfinder(columns: 128, rows: 128)
        pf.buildGraph(grid: result.grid)

        var startCol = 0, startRow = 0, endCol = 0, endRow = 0
        var foundStart = false, foundEnd = false
        for row in 0..<128 {
            for col in 0..<128 where result.grid[row][col].isWalkable {
                if !foundStart {
                    startCol = col; startRow = row; foundStart = true
                } else if abs(col - startCol) + abs(row - startRow) > 5 {
                    endCol = col; endRow = row; foundEnd = true; break
                }
            }
            if foundEnd { break }
        }

        let gs = GameState()
        let id = UUID()
        gs.colonists = [ColonistModel(id: id, name: "Mover", col: startCol, row: startRow)]
        let js = JobSystem()
        js.commandMove(colonistId: id, destCol: endCol, destRow: endRow, gameState: gs, pathfinder: pf)

        XCTAssertTrue(gs.colonists[0].hasPath)
        XCTAssertEqual(gs.colonists[0].job, .idle)

        js.pathfinder = pf
        for _ in 0..<500 where gs.colonists[0].hasPath {
            js.tick(gameState: gs)
        }
        XCTAssertEqual(gs.colonists[0].col, endCol)
        XCTAssertEqual(gs.colonists[0].row, endRow)
    }

    func testCommandMoveIgnoresDeadColonist() {
        let gs = GameState()
        let id = UUID()
        var c = ColonistModel(id: id, name: "Ghost", col: 0, row: 0)
        c.state = .dead
        gs.colonists = [c]
        let pf = Pathfinder(columns: 10, rows: 10)
        pf.buildGraph(grid: Array(repeating: Array(repeating: TileType.sidewalk, count: 10), count: 10))
        let js = JobSystem()
        js.commandMove(colonistId: id, destCol: 5, destRow: 5, gameState: gs, pathfinder: pf)
        XCTAssertFalse(gs.colonists[0].hasPath)
    }

    // MARK: - Gather (regression: the GATH pill sets job=.gather with no path; JobSystem must
    // path the colonist to a node itself, not just cancel back to idle before ResourceSystem
    // ever gets a chance to harvest)

    func testGatherJobPathsToNodeAndHarvests() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Miner", col: 5, row: 5)]
        gs.resourceNodes = [ResourceModel(id: UUID(), type: .materials, col: 5, row: 8, remaining: 5, maxAmount: 5, respawnTicks: 60)]
        gs.resources = [.materials: 0]

        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 15), count: 15)
        let tileMap = TileMap(grid: grid)
        let pathfinder = Pathfinder(columns: 15, rows: 15)
        pathfinder.buildGraph(grid: grid)

        let jobSystem = JobSystem()
        jobSystem.pathfinder = pathfinder
        let resourceSystem = ResourceSystem()

        // Same as tapping the GATH pill: job set directly, no path.
        gs.colonists[0].job = .gather

        for _ in 0..<40 {
            jobSystem.tick(gameState: gs)
            resourceSystem.tick(gameState: gs, tileMap: tileMap)
        }

        XCTAssertEqual(gs.colonists[0].col, 5)
        XCTAssertEqual(gs.colonists[0].row, 8)
        XCTAssertGreaterThan(gs.resources[.materials] ?? 0, 0, "gather should walk to the node and harvest")
        XCTAssertTrue(gs.resourceNodes[0].isDepleted, "5 remaining at ~1/tick over 40 ticks should fully deplete")
    }

    func testGatherRetargetsAfterNodeDepletes() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Miner", col: 0, row: 0)]
        gs.resourceNodes = [
            ResourceModel(id: UUID(), type: .materials, col: 0, row: 2, remaining: 1, maxAmount: 1, respawnTicks: 999),
            ResourceModel(id: UUID(), type: .materials, col: 0, row: 6, remaining: 3, maxAmount: 3, respawnTicks: 999)
        ]
        gs.resources = [.materials: 0]

        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 10), count: 10)
        let tileMap = TileMap(grid: grid)
        let pathfinder = Pathfinder(columns: 10, rows: 10)
        pathfinder.buildGraph(grid: grid)

        let jobSystem = JobSystem()
        jobSystem.pathfinder = pathfinder
        let resourceSystem = ResourceSystem()

        gs.colonists[0].job = .gather

        for _ in 0..<60 {
            jobSystem.tick(gameState: gs)
            resourceSystem.tick(gameState: gs, tileMap: tileMap)
        }

        XCTAssertTrue(gs.resourceNodes[0].isDepleted)
        XCTAssertTrue(gs.resourceNodes[1].isDepleted, "colonist should retarget the second node once the first is empty")
        XCTAssertEqual(gs.resources[.materials], 4)
    }

    // MARK: - Save/load

    func testSaveLoadRoundTrip() throws {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "Saved", col: 3, row: 4)]
        gs.resources = [.food: 42]
        gs.currentTick = 99
        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 8), count: 8)

        try SaveManager.shared.save(slot: 3, gameState: gs, grid: grid)
        defer { SaveManager.shared.delete(slot: 3) }

        let loaded = SaveManager.shared.load(slot: 3)
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.colonists.first?.name, "Saved")
        XCTAssertEqual(loaded?.resources[.food], 42)
        XCTAssertEqual(loaded?.currentTick, 99)
        let rebuilt = SaveManager.shared.rebuildGrid(from: loaded!)
        XCTAssertEqual(rebuilt.count, 8)
        XCTAssertEqual(rebuilt[0][0], .sidewalk)
    }

    func testLoadMissingSlotReturnsNil() {
        SaveManager.shared.delete(slot: 3)
        XCTAssertNil(SaveManager.shared.load(slot: 3))
    }

    func testLegacySaveWithRemovedFieldsDecodes() throws {
        // Saves written before v1.2.0 contain jobOverride/currentDirective keys.
        let json = """
        {"id":"\(UUID().uuidString)","name":"Legacy","col":1,"row":2,"jobOverride":true}
        """
        var dict = try JSONSerialization.jsonObject(with: JSONEncoder().encode(
            ColonistModel(id: UUID(), name: "T", col: 0, row: 0))) as! [String: Any]
        dict["jobOverride"] = true
        let data = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(ColonistModel.self, from: data)
        XCTAssertEqual(decoded.name, "T")
        _ = json
    }

    func testRebuildGridHandlesCorruptSize() {
        let sd = SaveData(colonists: [], buildings: [], resourceNodes: [], resources: [:],
                          currentTick: 0, flatGrid: [], gridSize: 0,
                          slot: SaveSlot(slot: 1, saveName: "x", timestamp: Date(), dayCount: 0, colonistCount: 0))
        XCTAssertTrue(SaveManager.shared.rebuildGrid(from: sd).isEmpty)
    }

    // MARK: - Tutorial

    func testTutorialAdvancesOnEvents() {
        let gs = GameState()
        gs.tutorialStep = 2
        TutorialView.checkAdvance(gameState: gs, event: .colonistSelected)
        XCTAssertEqual(gs.tutorialStep, 3)
        TutorialView.checkAdvance(gameState: gs, event: .cameraPanned)
        XCTAssertEqual(gs.tutorialStep, 4)
        TutorialView.checkAdvance(gameState: gs, event: .buildMenuOpened)
        XCTAssertEqual(gs.tutorialStep, 5)
        TutorialView.checkAdvance(gameState: gs, event: .shelterPlaced)
        XCTAssertEqual(gs.tutorialStep, 6)
    }

    func testTutorialIgnoresWrongEvent() {
        let gs = GameState()
        gs.tutorialStep = 2
        TutorialView.checkAdvance(gameState: gs, event: .shelterPlaced)
        XCTAssertEqual(gs.tutorialStep, 2)
    }

    func testTutorialInactiveWhenDismissed() {
        let gs = GameState()
        gs.tutorialStep = nil
        TutorialView.checkAdvance(gameState: gs, event: .colonistSelected)
        XCTAssertNil(gs.tutorialStep)
    }

    // MARK: - Full playthrough (regression net for the whole game loop, not just one system)

    func testFullPlaythroughSmokeTest() throws {
        let gs = GameState()
        gs.resources = [.food: 300, .power: 10, .materials: 40, .oxygen: 50, .cash: 25]
        gs.colonists = [ColonistModel(id: UUID(), name: "Player", col: 10, row: 10)]

        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 20), count: 20)
        let tileMap = TileMap(grid: grid)
        let pathfinder = Pathfinder(columns: 20, rows: 20)
        pathfinder.buildGraph(grid: grid)

        let buildSystem = BuildSystem()
        let jobSystem = JobSystem()
        jobSystem.pathfinder = pathfinder
        let needsSystem = NeedsSystem()

        // All three origins land within NeedsSystem's dist<=3 proximity check from the
        // colonist at (10,10), and none of their footprints overlap.
        XCTAssertNotNil(buildSystem.place(type: .shelter, col: 10, row: 7, tileMap: tileMap, gameState: gs, pathfinder: pathfinder))
        XCTAssertNotNil(buildSystem.place(type: .foodStall, col: 12, row: 10, tileMap: tileMap, gameState: gs, pathfinder: pathfinder))
        XCTAssertNotNil(buildSystem.place(type: .generator, col: 8, row: 10, tileMap: tileMap, gameState: gs, pathfinder: pathfinder))
        XCTAssertEqual(gs.buildings.count, 3)
        XCTAssertLessThan(gs.resources[.materials] ?? 0, 40, "building should spend materials")

        jobSystem.assignJob(colonistIndex: 0, job: .gather, destCol: 10, destRow: 10, gameState: gs, pathfinder: pathfinder)

        gs.currentTick = 200 // past NeedsSystem's grace period, so decay/production are live
        for _ in 0..<400 {
            jobSystem.tick(gameState: gs)
            needsSystem.tick(gameState: gs)
            gs.currentTick += 1
        }

        XCTAssertFalse(gs.colonists[0].isDead, "colonist should survive 400 ticks near shelter+foodStall+generator")
        XCTAssertGreaterThan(gs.resources[.power] ?? 0, 10, "generator should raise power over 400 ticks")
        XCTAssertLessThan(gs.colonists[0].stress, 50, "shelter should hold stress down")

        // Mid-game save/load, buildings included (the existing round-trip test only covers colonists)
        try SaveManager.shared.save(slot: 4, gameState: gs, grid: tileMap.grid)
        defer { SaveManager.shared.delete(slot: 4) }
        let loaded = SaveManager.shared.load(slot: 4)
        XCTAssertEqual(loaded?.buildings.count, 3)
        XCTAssertEqual(loaded?.colonists.first?.isDead, false)
    }

    // MARK: - Startup performance (regression guard for the known "NEW GAME hangs 10-15s, no spinner" issue)

    func testWorldGenAndTileMapConstructionStaysUnderBudget() {
        // WorldGenerator.generate() + TileMap(grid:) building 128x128 = 16,384 SKSpriteNodes
        // synchronously on @MainActor is the mechanism behind the roadmap's flagged startup hang.
        // This doesn't fix it, it just fails loudly if it gets worse.
        let start = Date()
        let result = WorldGenerator.generate()
        let tileMap = TileMap(grid: result.grid)
        let elapsed = Date().timeIntervalSince(start)

        XCTAssertEqual(tileMap.node.children.count, 128 * 128)
        XCTAssertLessThan(elapsed, 5.0, "world gen + tile map construction took \(elapsed)s; the shipped hang is already ~10-15s on device with no loading indicator, this must not get worse")
    }

    func testGeneratorProducesWithNoColonistsNearby() {
        let gs = GameState()
        gs.colonists = []
        gs.buildings = [BuildingModel(id: UUID(), type: .generator, col: 5, row: 5)]
        let before = gs.resources[.power] ?? 0
        NeedsSystem().tick(gameState: gs)
        XCTAssertEqual(gs.resources[.power] ?? 0, before + 1)
    }

    func testCommandGatherSendsWholeSquadAndKeepsThemWorking() {
        let gs = GameState()
        let a = ColonistModel(id: UUID(), name: "A", col: 2, row: 2)
        let b = ColonistModel(id: UUID(), name: "B", col: 3, row: 2)
        gs.colonists = [a, b]
        let node = ResourceModel(id: UUID(), type: .materials, col: 8, row: 8, remaining: 10, maxAmount: 10, respawnTicks: 60)
        gs.resourceNodes = [node]
        gs.resources = [.materials: 0]
        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 15), count: 15)
        let pf = Pathfinder(columns: 15, rows: 15)
        pf.buildGraph(grid: grid)
        let js = JobSystem()
        js.pathfinder = pf
        for c in gs.colonists { js.commandGather(colonistId: c.id, node: node, gameState: gs, pathfinder: pf) }
        XCTAssertTrue(gs.colonists.allSatisfy { $0.job == .gather && $0.hasPath })
        let rs = ResourceSystem()
        let tm = TileMap(grid: grid)
        for _ in 0..<40 { js.tick(gameState: gs); rs.tick(gameState: gs, tileMap: tm) }
        XCTAssertGreaterThan(gs.resources[.materials] ?? 0, 4, "two gatherers should out-harvest one")
    }

    func testRecruitNeedsBedAndFood() {
        let gs = GameState()
        gs.colonists = (0..<6).map { ColonistModel(id: UUID(), name: "C\($0)", col: 5, row: 5) }
        gs.resources[.food] = 100
        gs.currentTick = 240
        let ns = NeedsSystem()
        XCTAssertNil(ns.recruitTick(gameState: gs), "no free bed")
        gs.buildings = [BuildingModel(id: UUID(), type: .shelter, col: 1, row: 1)]
        XCTAssertNotNil(ns.recruitTick(gameState: gs))
        XCTAssertEqual(gs.colonists.count, 7)
        XCTAssertEqual(gs.resources[.food], 90)
        gs.resources[.food] = 5
        XCTAssertNil(ns.recruitTick(gameState: gs), "no food")
    }

    func testIdleColonistRestsAndStockpileFeeds() {
        let gs = GameState()
        var c = ColonistModel(id: UUID(), name: "Tired", col: 5, row: 5)
        c.sleep = 10; c.hunger = 10
        gs.colonists = [c]
        gs.currentTick = 500
        gs.resources[.food] = 30
        NeedsSystem().tick(gameState: gs)
        XCTAssertGreaterThan(gs.colonists[0].sleep, 10)
        XCTAssertGreaterThan(gs.colonists[0].hunger, 10)
        XCTAssertEqual(gs.resources[.food], 27)
    }

    func testVictoryRule() {
        let gs = GameState()
        gs.colonists = (0..<15).map { i -> ColonistModel in
            var c = ColonistModel(id: UUID(), name: "V\(i)", col: 1, row: 1); c.level = i == 0 ? 10 : 8; return c
        }
        XCTAssertTrue(NeedsSystem.isVictory(gs))
        gs.colonists[0].level = 8
        XCTAssertFalse(NeedsSystem.isVictory(gs))
    }

    func testBuildingNeverTrapsAColonist() {
        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 20), count: 20)
        let tileMap = TileMap(grid: grid)
        let pf = Pathfinder(columns: 20, rows: 20); pf.buildGraph(grid: grid)
        let gs = GameState()
        gs.resources[.materials] = 100
        var c = ColonistModel(id: UUID(), name: "Walker", col: 5, row: 5)
        c.pathCols = [6, 7, 8]; c.pathRows = [5, 5, 5]; c.pathIndex = 0
        gs.colonists = [c]
        let bs = BuildSystem()
        XCTAssertFalse(bs.canPlace(type: .shelter, col: 5, row: 5, tileMap: tileMap, gameState: gs))
        XCTAssertNotNil(bs.place(type: .shelter, col: 7, row: 4, tileMap: tileMap, gameState: gs, pathfinder: pf))
        XCTAssertFalse(gs.colonists[0].hasPath)
    }

    func testRaidTakesUnlessPatrolled() {
        let gs = GameState()
        gs.colonists = (0..<4).map { ColonistModel(id: UUID(), name: "G\($0)", col: 5, row: 5) }
        gs.resources = [.food: 100, .materials: 50, .cash: 10]
        gs.currentTick = 3 * 240 + 220
        let ns = NeedsSystem()
        XCTAssertEqual(ns.raidTick(gameState: gs), false)
        XCTAssertEqual(gs.resources[.food], 80)
        gs.colonists[0].job = .patrol
        XCTAssertEqual(ns.raidTick(gameState: gs), true)
        XCTAssertEqual(gs.resources[.food], 80)
        gs.currentTick = 4 * 240 + 220
        XCTAssertNil(ns.raidTick(gameState: gs))
    }
}

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

    func testBuildSystemRejectsNonWalkable() {
        let grid = Array(repeating: Array(repeating: TileType.building, count: 10), count: 10)
        let tm = TileMap(grid: grid)
        let gs = GameState()
        gs.resources = [.materials: 100, .power: 100]
        let bs = BuildSystem()

        XCTAssertFalse(bs.canPlace(type: .shelter, col: 0, row: 0, tileMap: tm, gameState: gs))
    }

    func testBuildSystemAcceptsWalkable() {
        var grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 10), count: 10)
        let tm = TileMap(grid: grid)
        let gs = GameState()
        gs.resources = [.materials: 100, .power: 100]
        let bs = BuildSystem()

        XCTAssertTrue(bs.canPlace(type: .shelter, col: 2, row: 2, tileMap: tm, gameState: gs))
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

                for _ in 0..<500 where gs.colonists[0].hasPath {
            js.tick(gameState: gs)
        }
        XCTAssertEqual(gs.colonists[0].col, endCol)
        XCTAssertEqual(gs.colonists[0].row, endRow)
    }

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

    func testRebuildGridHandlesCorruptSize() {
        let sd = SaveData(colonists: [], buildings: [], resourceNodes: [], resources: [:],
                          currentTick: 0, flatGrid: [], gridSize: 0,
                          slot: SaveSlot(slot: 1, saveName: "x", timestamp: Date(), dayCount: 0, colonistCount: 0))
        XCTAssertTrue(SaveManager.shared.rebuildGrid(from: sd).isEmpty)
    }

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

    func testGatheringColonistHarvestsAndIdleDoesNot() {
        let gs = GameState()
        var a = ColonistModel(id: UUID(), name: "A", col: 5, row: 6); a.job = .gather
        let b = ColonistModel(id: UUID(), name: "B", col: 5, row: 4)
        gs.colonists = [a, b]
        gs.resourceNodes = [ResourceModel(id: UUID(), type: .materials, col: 5, row: 5, remaining: 50, maxAmount: 50, respawnTicks: 60)]
        gs.resources = [.materials: 0]
        let rs = ResourceSystem()
        let tm = TileMap(grid: Array(repeating: Array(repeating: TileType.sidewalk, count: 10), count: 10))
        for t in 1...40 { gs.currentTick = t; rs.tick(gameState: gs, tileMap: tm) }
        XCTAssertEqual(gs.resources[.materials], 10)
    }

    func testCommandGatherSendsWholeSquad() {
        let gs = GameState()
        gs.colonists = [ColonistModel(id: UUID(), name: "A", col: 2, row: 2), ColonistModel(id: UUID(), name: "B", col: 3, row: 2)]
        let node = ResourceModel(id: UUID(), type: .materials, col: 8, row: 8, remaining: 10, maxAmount: 10, respawnTicks: 60)
        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 15), count: 15)
        let pf = Pathfinder(columns: 15, rows: 15); pf.buildGraph(grid: grid)
        let js = JobSystem()
        for c in gs.colonists { js.commandGather(colonistId: c.id, node: node, gameState: gs, pathfinder: pf) }
        XCTAssertTrue(gs.colonists.allSatisfy { $0.job == .gather && $0.hasPath })
    }

    func testDrillNeedsNodeAndPowerAndOnePerPatch() {
        let grid = Array(repeating: Array(repeating: TileType.sidewalk, count: 20), count: 20)
        let tm = TileMap(grid: grid)
        let pf = Pathfinder(columns: 20, rows: 20); pf.buildGraph(grid: grid)
        let gs = GameState()
        gs.resources = [.materials: 100, .power: 2]
        gs.resourceNodes = [ResourceModel(id: UUID(), type: .materials, col: 10, row: 10, remaining: 50, maxAmount: 50, respawnTicks: 60)]
        let bs = BuildSystem()
        XCTAssertFalse(bs.canPlace(type: .drill, col: 3, row: 3, tileMap: tm, gameState: gs), "no node nearby")
        XCTAssertNotNil(bs.place(type: .drill, col: 10, row: 11, tileMap: tm, gameState: gs, pathfinder: pf))
        gs.resources = [.materials: 100, .power: 2]
        XCTAssertFalse(bs.canPlace(type: .drill, col: 10, row: 9, tileMap: tm, gameState: gs), "one drill per patch")
        gs.resources = [.materials: 0, .power: 0]
        let cs = ColonySystem()
        for t in 1...40 { gs.currentTick = t; cs.machineTick(gameState: gs) }
        XCTAssertEqual(gs.resources[.materials], 0, "a dry drill stalls")
        gs.buildings.append(BuildingModel(id: UUID(), type: .generator, col: 0, row: 0))
        for t in 41...80 { gs.currentTick = t; cs.machineTick(gameState: gs) }
        XCTAssertGreaterThan(gs.resources[.materials] ?? 0, 0, "a powered drill mines")
    }

    func testGeneratorProducesWithNoColonistsNearby() {
        let gs = GameState()
        gs.buildings = [BuildingModel(id: UUID(), type: .generator, col: 5, row: 5)]
        gs.currentTick = 2
        ColonySystem().machineTick(gameState: gs)
        XCTAssertEqual(gs.resources[.power], 1)
    }

    func testRecruitNeedsBedAndFood() {
        let gs = GameState()
        gs.colonists = (0..<4).map { ColonistModel(id: UUID(), name: "C\($0)", col: 5, row: 5) }
        gs.resources[.food] = 100
        gs.currentTick = 240
        let cs = ColonySystem()
        XCTAssertNil(cs.recruitTick(gameState: gs), "no free bed")
        gs.buildings = [BuildingModel(id: UUID(), type: .shelter, col: 1, row: 1)]
        XCTAssertNotNil(cs.recruitTick(gameState: gs))
        XCTAssertEqual(gs.colonists.count, 5)
        XCTAssertEqual(gs.resources[.food], 90)
        gs.resources[.food] = 5
        XCTAssertNil(cs.recruitTick(gameState: gs), "no food")
    }

    func testVictoryIsTheBeacon() {
        let gs = GameState()
        XCTAssertFalse(ColonySystem.isVictory(gs))
        gs.buildings = [BuildingModel(id: UUID(), type: .beacon, col: 0, row: 0)]
        XCTAssertTrue(ColonySystem.isVictory(gs))
    }

    // MARK: - Tutorial

    func testTutorialAdvancesOnEvents() {
        let gs = GameState()
        gs.tutorialStep = 0
        TutorialView.checkAdvance(gameState: gs, event: .colonistSelected)
        XCTAssertEqual(gs.tutorialStep, 1)
        TutorialView.checkAdvance(gameState: gs, event: .buildMenuOpened)
        XCTAssertEqual(gs.tutorialStep, 2)
    }

    func testTutorialIgnoresWrongEvent() {
        let gs = GameState()
        gs.tutorialStep = 0
        TutorialView.checkAdvance(gameState: gs, event: .buildMenuOpened)
        XCTAssertEqual(gs.tutorialStep, 0)
    }

    func testTutorialInactiveWhenDismissed() {
        let gs = GameState()
        gs.tutorialStep = nil
        TutorialView.checkAdvance(gameState: gs, event: .colonistSelected)
        XCTAssertNil(gs.tutorialStep)
    }
}

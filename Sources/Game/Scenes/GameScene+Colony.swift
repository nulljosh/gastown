import SpriteKit

extension GameScene {
    /// ponytail: store screenshots and QA only (`-colony`, `-beacon`). Builds a small working colony with the
    /// same placement and orders a player uses, so a capture shows the game in use. Never runs in a normal launch.
    func stageColony(beacon: Bool) {
        gameState.tutorialStep = nil
        gameState.resources = [.food: 40, .materials: beacon ? 9000 : 160, .power: beacon ? 1100 : 30]
        let home = gameState.colonists.first.map { ($0.col, $0.row) } ?? (WorldGenerator.gridSize / 2, WorldGenerator.gridSize / 2)
        func near(_ type: BuildingType) {
            for r in 2..<24 { for dc in -r...r { for dr in [-r, r] where buildSystem.canPlace(type: type, col: home.0 + dc, row: home.1 + dr, tileMap: tileMap, gameState: gameState) {
                gameState.selectedBuildingType = type; placeBuilding(col: home.0 + dc, row: home.1 + dr); return
            } } }
        }
        for t: BuildingType in [.shelter, .generator, .generator] { near(t) }
        let ores = gameState.resourceNodes.filter { $0.type == .materials }.sorted { abs($0.col - home.0) + abs($0.row - home.1) < abs($1.col - home.0) + abs($1.row - home.1) }
        for n in ores.prefix(2) {
            for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] where buildSystem.canPlace(type: .drill, col: n.col + dc, row: n.row + dr, tileMap: tileMap, gameState: gameState) {
                gameState.selectedBuildingType = .drill; placeBuilding(col: n.col + dc, row: n.row + dr); break
            }
        }
        if beacon { near(.beacon) }
        gameState.selectedBuildingType = nil
        if let ore = ores.first { for c in gameState.colonists { jobSystem.commandGather(colonistId: c.id, node: ore, gameState: gameState, pathfinder: pathfinder) } }
    }
}

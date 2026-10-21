import SpriteKit

@MainActor
final class BuildSystem {
    var ghostNode: SKSpriteNode?

    func canPlace(type: BuildingType, col: Int, row: Int, tileMap: TileMap, gameState: GameState) -> Bool {
        let ts = type.tileSize
        for r in row..<(row + ts.h) {
            for c in col..<(col + ts.w) {
                guard let tile = tileMap.tileAt(col: c, row: r), tile.isWalkable else { return false }
                // never wall a survivor in
                if gameState.colonists.contains(where: { !$0.isDead && $0.col == c && $0.row == r }) { return false }
            }
        }
        for (resource, amount) in type.cost {
            if (gameState.resources[resource] ?? 0) < amount { return false }
        }
        return true
    }

    func place(type: BuildingType, col: Int, row: Int, tileMap: TileMap, gameState: GameState, pathfinder: Pathfinder) -> BuildingModel? {
        guard canPlace(type: type, col: col, row: row, tileMap: tileMap, gameState: gameState) else { return nil }

        for (resource, amount) in type.cost {
            gameState.resources[resource, default: 0] -= amount
        }

        let ts = type.tileSize
        for r in row..<(row + ts.h) {
            for c in col..<(col + ts.w) {
                tileMap.setTile(.building, col: c, row: r)
                pathfinder.removeNode(col: c, row: r)
            }
        }

        // Anyone routed through the new footprint re-plans; a stale path would walk them into the wall.
        for i in gameState.colonists.indices {
            let c = gameState.colonists[i]
            guard c.hasPath else { continue }
            let crosses = (c.pathIndex..<c.pathCols.count).contains { k in
                c.pathCols[k] >= col && c.pathCols[k] < col + ts.w && c.pathRows[k] >= row && c.pathRows[k] < row + ts.h
            }
            if crosses { gameState.colonists[i].pathCols = []; gameState.colonists[i].pathRows = []; gameState.colonists[i].pathIndex = 0 }
        }

        let model = BuildingModel(id: UUID(), type: type, col: col, row: row)
        gameState.buildings.append(model)
        gameState.log("Built \(type.displayName)")
        return model
    }

    func demolish(id: UUID, tileMap: TileMap, gameState: GameState, pathfinder: Pathfinder) {
        guard let idx = gameState.buildings.firstIndex(where: { $0.id == id }) else { return }
        let building = gameState.buildings[idx]
        let ts = building.type.tileSize
        for r in building.row..<(building.row + ts.h) {
            for c in building.col..<(building.col + ts.w) {
                tileMap.setTile(.sidewalk, col: c, row: r)
                pathfinder.addNode(col: c, row: r)
            }
        }
        gameState.buildings.remove(at: idx)
        gameState.log("Demolished \(building.type.displayName)")
    }

    func updateGhost(col: Int, row: Int, type: BuildingType, parent: SKNode) {
        ghostNode?.removeFromParent()
        let ts = type.tileSize
        let size = CGSize(width: CGFloat(ts.w) * TileMap.tileSize, height: CGFloat(ts.h) * TileMap.tileSize)
        let ghost = SKSpriteNode(color: SKColor.white.withAlphaComponent(0.3), size: size)
        ghost.anchorPoint = CGPoint(x: 0, y: 0)
        ghost.position = CGPoint(x: CGFloat(col) * TileMap.tileSize, y: CGFloat(row) * TileMap.tileSize)
        ghost.zPosition = 15
        ghost.name = "ghost"
        parent.addChild(ghost)
        ghostNode = ghost
    }

    func removeGhost() {
        ghostNode?.removeFromParent()
        ghostNode = nil
    }
}

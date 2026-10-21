import Foundation

/// Colonists only walk. The player's orders set the path and job; ResourceSystem does the work.
@MainActor
final class JobSystem {
    /// Player-issued move order.
    func commandMove(colonistId: UUID, destCol: Int, destRow: Int, gameState: GameState, pathfinder: Pathfinder) {
        guard let i = gameState.colonists.firstIndex(where: { $0.id == colonistId }) else { return }
        let path = pathfinder.findPath(
            fromCol: gameState.colonists[i].col,
            fromRow: gameState.colonists[i].row,
            toCol: destCol,
            toRow: destRow
        )
        guard !path.isEmpty else { return }
        gameState.colonists[i].job = .idle
        gameState.colonists[i].pathCols = path.map(\.col)
        gameState.colonists[i].pathRows = path.map(\.row)
        gameState.colonists[i].pathIndex = 0
    }

    /// Player-issued gather order: walk to the node and work it until told otherwise (nodes respawn).
    func commandGather(colonistId: UUID, node: ResourceModel, gameState: GameState, pathfinder: Pathfinder) {
        guard let i = gameState.colonists.firstIndex(where: { $0.id == colonistId }) else { return }
        let path = pathfinder.findPathNear(fromCol: gameState.colonists[i].col, fromRow: gameState.colonists[i].row, toCol: node.col, toRow: node.row)
        gameState.colonists[i].job = .gather
        gameState.colonists[i].pathCols = path.map(\.col)
        gameState.colonists[i].pathRows = path.map(\.row)
        gameState.colonists[i].pathIndex = 0
    }

    func tick(gameState: GameState) {
        for i in gameState.colonists.indices where gameState.colonists[i].hasPath {
            gameState.colonists[i].advancePath()
            if let pos = gameState.colonists[i].currentPathPosition {
                gameState.colonists[i].col = pos.col
                gameState.colonists[i].row = pos.row
            }
        }
    }
}

import Foundation

@MainActor
final class ResourceSystem {
    /// Nodes respawn; a gathering colonist standing at a node harvests it, one unit per gatherEvery ticks.
    func tick(gameState: GameState, tileMap: TileMap) {
        for i in gameState.resourceNodes.indices {
            gameState.resourceNodes[i].tickRespawn()
        }
        guard gameState.currentTick % ColonySystem.gatherEvery == 0 else { return }
        for c in gameState.colonists where c.job == .gather {
            guard let ri = gameState.resourceNodes.firstIndex(where: { !$0.isDepleted && abs($0.col - c.col) + abs($0.row - c.row) <= 1 }) else { continue }
            let amount = gameState.resourceNodes[ri].harvest()
            gameState.resources[gameState.resourceNodes[ri].type, default: 0] += amount
        }
    }
}

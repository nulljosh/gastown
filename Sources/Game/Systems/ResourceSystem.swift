import Foundation

@MainActor
final class ResourceSystem {
    func tick(gameState: GameState, tileMap: TileMap) {
        for i in gameState.resourceNodes.indices {
            gameState.resourceNodes[i].tickRespawn()
        }

        for ci in gameState.colonists.indices {
            guard gameState.colonists[ci].job == .gather && !gameState.colonists[ci].isDead else { continue }
            let cc = gameState.colonists[ci].col
            let cr = gameState.colonists[ci].row

            for ri in gameState.resourceNodes.indices {
                guard !gameState.resourceNodes[ri].isDepleted else { continue }
                let dist = abs(gameState.resourceNodes[ri].col - cc) + abs(gameState.resourceNodes[ri].row - cr)
                if dist <= 1 {
                    let amount = gameState.resourceNodes[ri].harvest()
                    if amount > 0 {
                        gameState.resources[gameState.resourceNodes[ri].type, default: 0] += amount
                        gameState.colonists[ci].grantXP(1) // every harvest: native has no quests, so this stands in for web's quest XP (scripts/playthrough.sh wins day 21-23, ~1.5 h)
                    }
                    break
                }
            }
        }
    }

    func consume(gameState: GameState, type: ResourceType, amount: Int) -> Bool {
        let current = gameState.resources[type, default: 0]
        guard current >= amount else { return false }
        gameState.resources[type] = current - amount
        return true
    }
}

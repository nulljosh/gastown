import Foundation

@MainActor
final class JobSystem {
    weak var pathfinder: Pathfinder?

    func assignJob(colonistIndex: Int, job: ColonistJob, destCol: Int, destRow: Int, gameState: GameState, pathfinder: Pathfinder) {
        guard colonistIndex < gameState.colonists.count else { return }
        gameState.colonists[colonistIndex].job = job
        let path = pathfinder.findPath(
            fromCol: gameState.colonists[colonistIndex].col,
            fromRow: gameState.colonists[colonistIndex].row,
            toCol: destCol,
            toRow: destRow
        )
        gameState.colonists[colonistIndex].pathCols = path.map(\.col)
        gameState.colonists[colonistIndex].pathRows = path.map(\.row)
        gameState.colonists[colonistIndex].pathIndex = 0
    }

    /// Player-issued move order.
    func commandMove(colonistId: UUID, destCol: Int, destRow: Int, gameState: GameState, pathfinder: Pathfinder) {
        guard let i = gameState.colonists.firstIndex(where: { $0.id == colonistId }),
              !gameState.colonists[i].isDead else { return }
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
        gameState.log("\(gameState.colonists[i].name) moving to (\(destCol), \(destRow))")
    }

    /// Player-issued gather order: walk to the node, then ResourceSystem harvests on arrival.
    func commandGather(colonistId: UUID, node: ResourceModel, gameState: GameState, pathfinder: Pathfinder) {
        guard let i = gameState.colonists.firstIndex(where: { $0.id == colonistId }),
              !gameState.colonists[i].isDead else { return }
        let path = pathfinder.findPathNear(fromCol: gameState.colonists[i].col, fromRow: gameState.colonists[i].row, toCol: node.col, toRow: node.row)
        gameState.colonists[i].job = .gather
        gameState.colonists[i].pathCols = path.map(\.col)
        gameState.colonists[i].pathRows = path.map(\.row)
        gameState.colonists[i].pathIndex = 0
        gameState.log("\(gameState.colonists[i].name) gathering \(node.type.rawValue)")
    }

    func clearJob(colonistIndex: Int, gameState: GameState) {
        guard colonistIndex < gameState.colonists.count else { return }
        gameState.colonists[colonistIndex].job = .idle
        gameState.colonists[colonistIndex].pathCols = []
        gameState.colonists[colonistIndex].pathRows = []
        gameState.colonists[colonistIndex].pathIndex = 0
    }

    func tick(gameState: GameState) {
        for i in gameState.colonists.indices {
            guard !gameState.colonists[i].isDead else { continue }

            // Combat tick
            if gameState.colonists[i].job == .attack {
                tickCombat(colonistIndex: i, gameState: gameState)
            }

            guard gameState.colonists[i].hasPath else {
                if gameState.colonists[i].job == .gather {
                    tickGather(colonistIndex: i, gameState: gameState)
                } else if gameState.colonists[i].job == .patrol {
                    // On guard: stays put, earns a little XP, keeps raiders off the stockpile (NeedsSystem.raidTick).
                    if gameState.currentTick % 20 == 0 { gameState.colonists[i].grantXP(1) }
                }
                continue
            }

            let speed = gameState.colonists[i].movementSpeed
            let steps = max(1, Int(speed))
            for _ in 0..<steps {
                guard gameState.colonists[i].hasPath else { break }
                gameState.colonists[i].advancePath()
                if let pos = gameState.colonists[i].currentPathPosition {
                    gameState.colonists[i].col = pos.col
                    gameState.colonists[i].row = pos.row
                }
            }
        }
    }

    func grantJobXP(colonistIndex: Int, job: ColonistJob, gameState: GameState) {
        guard colonistIndex < gameState.colonists.count else { return }
        let xp: Int
        switch job {
        case .gather: xp = 5
        case .build: xp = 10
        case .patrol: xp = 3
        case .attack: xp = 8
        case .idle: xp = 0
        }
        if xp > 0 {
            gameState.colonists[colonistIndex].grantXP(xp)
        }
    }

    // MARK: - Gather

    /// A `.gather` colonist with no path either just arrived at a node (stay put, ResourceSystem
    /// harvests this same frame) or has none assigned yet / their node depleted (find the nearest
    /// reachable one and walk there). Only goes idle when nothing is left to gather.
    private func tickGather(colonistIndex: Int, gameState: GameState) {
        let cc = gameState.colonists[colonistIndex].col
        let cr = gameState.colonists[colonistIndex].row

        let alreadyAdjacent = gameState.resourceNodes.contains {
            !$0.isDepleted && abs($0.col - cc) + abs($0.row - cr) <= 1
        }
        if alreadyAdjacent { return }

        guard let pathfinder else {
            gameState.colonists[colonistIndex].grantXP(5)
            gameState.colonists[colonistIndex].job = .idle
            return
        }

        let nearest = gameState.resourceNodes
            .filter { !$0.isDepleted }
            .sorted { (abs($0.col - cc) + abs($0.row - cr)) < (abs($1.col - cc) + abs($1.row - cr)) }

        for node in nearest {
            let path = pathfinder.findPathNear(fromCol: cc, fromRow: cr, toCol: node.col, toRow: node.row)
            guard !path.isEmpty else { continue }
            gameState.colonists[colonistIndex].pathCols = path.map(\.col)
            gameState.colonists[colonistIndex].pathRows = path.map(\.row)
            gameState.colonists[colonistIndex].pathIndex = 0
            return
        }

        // Nothing reachable left to gather.
        gameState.colonists[colonistIndex].grantXP(5)
        gameState.colonists[colonistIndex].job = .idle
    }

    // MARK: - Combat

    private func tickCombat(colonistIndex: Int, gameState: GameState) {
        let attacker = gameState.colonists[colonistIndex]
        guard let targetId = attacker.attackTargetId,
              let targetIdx = gameState.colonists.firstIndex(where: { $0.id == targetId }) else {
            // No valid target, go idle
            gameState.colonists[colonistIndex].job = .idle
            gameState.colonists[colonistIndex].attackTargetId = nil
            return
        }

        let target = gameState.colonists[targetIdx]
        guard !target.isDead else {
            gameState.colonists[colonistIndex].job = .idle
            gameState.colonists[colonistIndex].attackTargetId = nil
            gameState.colonists[colonistIndex].grantXP(15)
            AudioManager.shared.colonistDied()
            gameState.log("\(attacker.name) killed \(target.name)")
            return
        }

        let dist = abs(attacker.col - target.col) + abs(attacker.row - target.row)
        if dist <= attacker.weapon.range {
            // In range -- deal damage
            let dmg = attacker.weapon.damage * (1.0 + Double(attacker.stats.str) * 0.1)
            gameState.colonists[targetIdx].takeDamage(dmg)
            AudioManager.shared.combatHit()
            gameState.colonists[colonistIndex].grantXP(2)
        } else if !attacker.hasPath {
            // Move toward target
            if let pathfinder {
                let path = pathfinder.findPath(fromCol: attacker.col, fromRow: attacker.row, toCol: target.col, toRow: target.row)
                if !path.isEmpty {
                    gameState.colonists[colonistIndex].pathCols = path.map(\.col)
                    gameState.colonists[colonistIndex].pathRows = path.map(\.row)
                    gameState.colonists[colonistIndex].pathIndex = 0
                }
            }
        }
    }
}

import Foundation

@MainActor
final class NeedsSystem {
    private let gracePeriodTicks = 120

    /// Machines run on their own, once per building per tick, whether or not anyone is standing nearby.
    func tickBuildings(gameState: GameState) {
        // Upkeep: 1 materials per building per 10 ticks. Unpaid, it breaks until materials return.
        if gameState.currentTick % 10 == 0 {
            for i in gameState.buildings.indices {
                if (gameState.resources[.materials] ?? 0) >= 1 {
                    gameState.resources[.materials, default: 0] -= 1
                    if !gameState.buildings[i].isActive { gameState.buildings[i].isActive = true; gameState.log("\(gameState.buildings[i].type.displayName) repaired") }
                } else if gameState.buildings[i].isActive {
                    gameState.buildings[i].isActive = false
                    gameState.log("\(gameState.buildings[i].type.displayName) broke down: no materials")
                }
            }
        }
        for building in gameState.buildings where building.isActive {
            switch building.type {
            case .generator: gameState.resources[.power, default: 0] += 1
            case .billboard: gameState.resources[.cash, default: 0] += 1
            default: break
            }
        }
    }

    func tick(gameState: GameState) {
        tickBuildings(gameState: gameState)
        let inGracePeriod = gameState.currentTick < gracePeriodTicks

        for i in gameState.colonists.indices {
            guard !gameState.colonists[i].isDead else { continue }

            if !inGracePeriod {
                let endMult = gameState.colonists[i].hungerDecayMultiplier
                let traitSleepMult: Double = gameState.colonists[i].trait == .insomniac ? 0.7 : 1.0
                let traitO2Mult: Double = gameState.colonists[i].trait == .ironlung ? 0.7 : 1.0
                let traitStressMult: Double = gameState.colonists[i].trait == .anxious ? 2.0 : 1.0

                gameState.colonists[i].hunger = max(0, gameState.colonists[i].hunger - 0.25 * endMult)
                gameState.colonists[i].oxygen = max(0, gameState.colonists[i].oxygen - 0.1 * traitO2Mult)
                gameState.colonists[i].stress = min(100, gameState.colonists[i].stress + 0.15 * traitStressMult)
                gameState.colonists[i].sleep = max(0, gameState.colonists[i].sleep - 0.15 * traitSleepMult)
            }

            // Resting: an idle colonist recovers anywhere. The stockpile feeds the hungry and
            // supplies air on its own, so food and O2 are production problems, not babysitting.
            if gameState.colonists[i].job == .idle && !gameState.colonists[i].hasPath {
                gameState.colonists[i].sleep = min(100, gameState.colonists[i].sleep + 0.5)
                gameState.colonists[i].stress = max(0, gameState.colonists[i].stress - 0.25)
                gameState.colonists[i].oxygen = min(100, gameState.colonists[i].oxygen + 0.2)
            }
            if gameState.colonists[i].hunger < 30, (gameState.resources[.food] ?? 0) >= 3 {
                gameState.colonists[i].hunger = min(100, gameState.colonists[i].hunger + 25)
                gameState.resources[.food, default: 0] -= 3
            }
            if gameState.colonists[i].oxygen < 30, (gameState.resources[.oxygen] ?? 0) >= 5 {
                gameState.colonists[i].oxygen = min(100, gameState.colonists[i].oxygen + 20)
                gameState.resources[.oxygen, default: 0] -= 5
            }

            let col = gameState.colonists[i].col
            let row = gameState.colonists[i].row

            // CHA-based stress reduction from nearby colonists
            let cha = gameState.colonists[i].stats.cha
            for j in gameState.colonists.indices where j != i && !gameState.colonists[j].isDead {
                let dist = abs(gameState.colonists[j].col - col) + abs(gameState.colonists[j].row - row)
                if dist <= 3 {
                    gameState.colonists[i].stress = max(0, gameState.colonists[i].stress - Double(cha) * 0.02)
                }
            }

            for building in gameState.buildings where building.isActive {
                let dist = abs(building.col - col) + abs(building.row - row)
                guard dist <= 3 else { continue }

                switch building.type {
                case .shelter:
                    gameState.colonists[i].stress = max(0, gameState.colonists[i].stress - 0.5)
                    gameState.colonists[i].sleep = min(100, gameState.colonists[i].sleep + 0.4)
                case .foodStall:
                    if (gameState.resources[.food] ?? 0) > 0, gameState.colonists[i].hunger <= 98 {
                        gameState.colonists[i].hunger = min(100, gameState.colonists[i].hunger + 2.0)
                        gameState.resources[.food, default: 0] -= 1
                    }
                case .filterStation:
                    if (gameState.resources[.power] ?? 0) > 0, gameState.colonists[i].oxygen <= 98 {
                        gameState.colonists[i].oxygen = min(100, gameState.colonists[i].oxygen + 1.0)
                        gameState.resources[.power, default: 0] -= 1
                    }
                default:
                    break
                }
            }

            gameState.colonists[i].updateState()

            if gameState.colonists[i].isDead {
                AudioManager.shared.colonistDied()
                gameState.log("\(gameState.colonists[i].name) has died")
            }
        }
    }

    // MARK: - Recruits and victory

    static let bedsBase = 6, bedsPerShelter = 4, maxColonists = 20, ticksPerDay = 240

    /// Once a day a survivor walks in if there is a free bed and 10 food. Arrives idle; no auto-assign.
    @discardableResult
    func recruitTick(gameState: GameState) -> ColonistModel? {
        guard gameState.currentTick > 0, gameState.currentTick % Self.ticksPerDay == 0 else { return nil }
        let alive = gameState.colonists.filter { !$0.isDead }
        guard let host = alive.first else { return nil }
        let beds = Self.bedsBase + Self.bedsPerShelter * gameState.buildings.filter { $0.type == .shelter && $0.isActive }.count
        guard alive.count < min(beds, Self.maxColonists), (gameState.resources[.food] ?? 0) >= 10 else { return nil }
        gameState.resources[.food, default: 0] -= 10
        let names = ["Sam", "Drew", "Quinn", "Reese", "Blake", "Harper", "Rowan", "Sage", "Emery", "Kai", "River", "Skyler", "Remy", "Marley", "Avery"]
        let name = names.first { n in !gameState.colonists.contains { $0.name == n } } ?? "Survivor \(gameState.colonists.count + 1)"
        let c = ColonistModel(id: UUID(), name: name, col: host.col, row: host.row)
        gameState.colonists.append(c)
        gameState.log("\(name) arrives, looking for work")
        return c
    }

    static let raidEveryDays = 3, raidHour = 22, raidGuardRange = 8, raidTake = 0.2

    /// Every third night scavengers hit the stockpile unless someone is on patrol within
    /// raidGuardRange of the colony centre. The log warns at dawn. Player-set, never automatic.
    @discardableResult
    func raidTick(gameState: GameState) -> Bool? {
        let day = gameState.currentTick / Self.ticksPerDay, hourTick = gameState.currentTick % Self.ticksPerDay
        guard day > 0, day % Self.raidEveryDays == 0 else { return nil }
        if hourTick == 60 { gameState.log("Scavengers spotted nearby. Put someone on PATROL before 22:00."); return nil }
        guard hourTick == Self.raidHour * 10 else { return nil }
        let alive = gameState.colonists.filter { !$0.isDead }
        guard !alive.isEmpty else { return nil }
        // The stockpile lives in the buildings: a patrol near any building guards it. No buildings yet, any patrol will do.
        let guarded = alive.contains { c in c.job == .patrol && (gameState.buildings.isEmpty ||
            gameState.buildings.contains { abs(c.col - $0.col) + abs(c.row - $0.row) <= Self.raidGuardRange }) }
        if guarded { gameState.log("Scavengers turned back by the patrol."); return true }
        var lost: [ResourceType: Int] = [:]
        for k in [ResourceType.food, .materials, .cash] {
            lost[k] = Int(Double(gameState.resources[k] ?? 0) * Self.raidTake)
            gameState.resources[k, default: 0] -= lost[k]!
        }
        gameState.log("Scavengers raided the stockpile: -\(lost[.food]!) food, -\(lost[.materials]!) materials, -\(lost[.cash]!) cash.")
        return false
    }

    /// Victory: 15 alive, average level 8, one at level 10. Same rule as the web game.
    static func isVictory(_ gameState: GameState) -> Bool {
        let alive = gameState.colonists.filter { !$0.isDead }
        guard alive.count >= 15 else { return false }
        let avg = Double(alive.map(\.level).reduce(0, +)) / Double(alive.count)
        return avg >= 8 && alive.contains { $0.level >= 10 }
    }
}

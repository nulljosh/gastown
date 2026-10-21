import Foundation

/// Machines, recruits and the win. Same numbers as web/js/systems.js.
@MainActor
final class ColonySystem {
    static let ticksPerDay = 240
    static let gatherEvery = 4, drillEvery = 4, genEvery = 2, drillReach = 1, drillYield = 1
    static let baseBeds = 4, bedsPerShelter = 4, maxColonists = 20

    /// Machines run on their own, once per building per tick, whether or not anyone is nearby.
    func machineTick(gameState gs: GameState) {
        let t = gs.currentTick
        for b in gs.buildings {
            switch b.type {
            case .generator where t % Self.genEvery == 0:
                gs.resources[.power, default: 0] += 1
            case .drill where t % Self.drillEvery == 0 && (gs.resources[.power] ?? 0) >= 1:
                guard let rn = Self.nodeNear(gs, col: b.col, row: b.row) else { continue }
                gs.resources[.power, default: 0] -= 1
                gs.resources[rn.type, default: 0] += Self.drillYield // ore patches never run dry under a drill
            default: break
            }
        }
    }

    static func nodeNear(_ gs: GameState, col: Int, row: Int) -> ResourceModel? {
        gs.resourceNodes.first { abs($0.col - col) + abs($0.row - row) <= drillReach }
    }

    /// Once a day a survivor walks in if there is a free bed and 10 food. Arrives idle; no auto-assign.
    @discardableResult
    func recruitTick(gameState gs: GameState) -> ColonistModel? {
        guard gs.currentTick > 0, gs.currentTick % Self.ticksPerDay == 0, let host = gs.colonists.first else { return nil }
        let beds = Self.baseBeds + Self.bedsPerShelter * gs.buildings.filter { $0.type == .shelter }.count
        guard gs.colonists.count < min(beds, Self.maxColonists), (gs.resources[.food] ?? 0) >= 10 else { return nil }
        gs.resources[.food, default: 0] -= 10
        let names = ["Alex", "Jordan", "Casey", "Riley", "Morgan", "Sam", "Taylor", "Avery", "Quinn", "Blake", "Drew", "Emery", "Harper", "Sage", "Rowan", "Kai", "Reese", "Skyler", "Remy", "Kit"]
        let name = names.first { n in !gs.colonists.contains { $0.name == n } } ?? "Survivor \(gs.colonists.count + 1)"
        let c = ColonistModel(id: UUID(), name: name, col: host.col, row: host.row)
        gs.colonists.append(c)
        gs.log("\(name) arrives, looking for work")
        return c
    }

    /// Victory: the Beacon stands. Same rule as the web game.
    static func isVictory(_ gs: GameState) -> Bool {
        gs.buildings.contains { $0.type == .beacon }
    }
}

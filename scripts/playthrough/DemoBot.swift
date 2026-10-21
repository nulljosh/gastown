import Foundation

/// Plays NYC Survive with the same commands a player's clicks issue: send survivors to a resource,
/// build shelters for beds, generators for power, drills on ore, then raise the Beacon. Mirrors web/sim.mjs.
/// It drives the headless playthrough check (scripts/playthrough.sh) and lives outside Sources/ on
/// purpose: the app never plays itself (ROADMAP no-autoplay rule).
@MainActor
struct DemoBot {
    private var home: (col: Int, row: Int)?

    mutating func tick(_ gs: GameState, jobs: JobSystem, pathfinder: Pathfinder,
                       canPlace: (BuildingType, Int, Int) -> Bool, place: (BuildingType, Int, Int) -> Bool) {
        guard gs.currentTick % 60 == 0, let first = gs.colonists.first else { return }
        if home == nil { home = (first.col, first.row) }
        let mats = gs.resources[.materials] ?? 0, power = gs.resources[.power] ?? 0, food = gs.resources[.food] ?? 0
        func count(_ t: BuildingType) -> Int { gs.buildings.filter { $0.type == t }.count }
        let beacon = BuildingType.beacon.cost

        if mats >= beacon[.materials]! && power >= beacon[.power]! { _ = buildNearHome(.beacon, canPlace, place) }
        else if gs.colonists.count >= ColonySystem.baseBeds + ColonySystem.bedsPerShelter * count(.shelter) && mats >= 10 { _ = buildNearHome(.shelter, canPlace, place) }
        else if count(.generator) <= count(.drill) && mats >= 15 { _ = buildNearHome(.generator, canPlace, place) }
        else if mats >= 12 && power >= 2 { _ = buildDrill(gs, canPlace, place) }

        // Idle hands go to the resource we are short of.
        let want: ResourceType = food < 20 ? .food : (count(.generator) == 0 ? .power : .materials)
        for c in gs.colonists where c.job == .idle && !c.hasPath {
            if let node = gs.resourceNodes.filter({ $0.type == want }).min(by: { dist($0, c) < dist($1, c) }) {
                jobs.commandGather(colonistId: c.id, node: node, gameState: gs, pathfinder: pathfinder)
            }
        }
    }

    private func dist(_ n: ResourceModel, _ c: ColonistModel) -> Int { abs(n.col - c.col) + abs(n.row - c.row) }

    private func buildDrill(_ gs: GameState, _ canPlace: (BuildingType, Int, Int) -> Bool, _ place: (BuildingType, Int, Int) -> Bool) -> Bool {
        guard let home else { return false }
        let nodes = gs.resourceNodes.filter { $0.type == .materials }
            .sorted { abs($0.col - home.col) + abs($0.row - home.row) < abs($1.col - home.col) + abs($1.row - home.row) }
        for n in nodes {
            for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] where canPlace(.drill, n.col + dc, n.row + dr) {
                return place(.drill, n.col + dc, n.row + dr)
            }
        }
        return false
    }

    /// Nearest free spot to home, widening ring by ring.
    private func buildNearHome(_ type: BuildingType, _ canPlace: (BuildingType, Int, Int) -> Bool, _ place: (BuildingType, Int, Int) -> Bool) -> Bool {
        guard let home else { return false }
        for r in 2..<40 {
            for dc in -r...r {
                for dr in [-r, r] where canPlace(type, home.col + dc, home.row + dr) {
                    return place(type, home.col + dc, home.row + dr)
                }
            }
        }
        return false
    }
}

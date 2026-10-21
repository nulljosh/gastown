import Foundation

/// Plays NYC Survive with the same commands a player's clicks issue: send survivors to gather, rest
/// them when they tire, put one on patrol on raid nights, and build shelters so recruits have beds.
/// It drives the headless playthrough check (scripts/playthrough.sh) and lives outside Sources/ on
/// purpose: the app never plays itself (ROADMAP no-autoplay rule).
@MainActor
struct DemoBot {
    private var resting: Set<UUID> = []
    private var home: (col: Int, row: Int)?

    /// Shelters for 18 beds (6 + 4 each): room for the 15 survivors the win needs.
    static let shelterGoal = 3

    mutating func tick(_ gs: GameState, jobs: JobSystem, pathfinder: Pathfinder,
                       canPlace: (BuildingType, Int, Int) -> Bool, place: (BuildingType, Int, Int) -> Bool) {
        guard gs.currentTick % 5 == 0 else { return }
        let alive = gs.colonists.indices.filter { !gs.colonists[$0].isDead }
        guard let first = alive.first else { return }
        if home == nil { home = (gs.colonists[first].col, gs.colonists[first].row) }
        build(gs, canPlace: canPlace, place: place)

        let day = gs.currentTick / NeedsSystem.ticksPerDay
        let raidDay = day > 0 && day % NeedsSystem.raidEveryDays == 0
        // The guard rotates by raid, so nobody falls behind on gathering XP.
        let guardIndex = alive[(day / NeedsSystem.raidEveryDays) % alive.count]

        for i in alive {
            let c = gs.colonists[i]
            if raidDay && i == guardIndex && gs.currentHour >= 6 {
                standGuard(gs, i, jobs: jobs, pathfinder: pathfinder)
                continue
            }
            if c.job == .patrol { jobs.clearJob(colonistIndex: i, gameState: gs) }
            if resting.contains(c.id) {
                if c.sleep > 90 && c.stress < 30 { resting.remove(c.id) } else { continue }
            } else if c.sleep < 25 || c.stress > 75 {
                resting.insert(c.id)
                jobs.clearJob(colonistIndex: i, gameState: gs)
                continue
            }
            if c.job != .gather || (!c.hasPath && !besideNode(gs, c)) {
                if let node = nearestNode(gs, c, of: scarcest(gs)) ?? nearestNode(gs, c, of: nil) {
                    jobs.commandGather(colonistId: c.id, node: node, gameState: gs, pathfinder: pathfinder)
                }
            }
        }
    }

    /// What the stockpile is shortest of, against what 15 people burn.
    private func scarcest(_ gs: GameState) -> ResourceType {
        let want: [(ResourceType, Double)] = [(.food, 120), (.oxygen, 80), (.materials, 90)]
        return want.min { Double(gs.resources[$0.0] ?? 0) / $0.1 < Double(gs.resources[$1.0] ?? 0) / $1.1 }!.0
    }

    private func nearestNode(_ gs: GameState, _ c: ColonistModel, of type: ResourceType?) -> ResourceModel? {
        gs.resourceNodes
            .filter { !$0.isDepleted && (type == nil || $0.type == type) }
            .min { abs($0.col - c.col) + abs($0.row - c.row) < abs($1.col - c.col) + abs($1.row - c.row) }
    }

    private func besideNode(_ gs: GameState, _ c: ColonistModel) -> Bool {
        gs.resourceNodes.contains { !$0.isDepleted && abs($0.col - c.col) + abs($0.row - c.row) <= 1 }
    }

    /// Walk next to the first building (or home), then hold position on PATROL.
    private func standGuard(_ gs: GameState, _ i: Int, jobs: JobSystem, pathfinder: Pathfinder) {
        let c = gs.colonists[i]
        guard c.job != .patrol else { return }
        let post = gs.buildings.first.map { ($0.col, $0.row) } ?? (home ?? (c.col, c.row))
        if abs(c.col - post.0) + abs(c.row - post.1) <= NeedsSystem.raidGuardRange - 2 {
            jobs.clearJob(colonistIndex: i, gameState: gs)
            gs.colonists[i].job = .patrol
        } else if !c.hasPath {
            jobs.commandMove(colonistId: c.id, destCol: post.0, destRow: post.1, gameState: gs, pathfinder: pathfinder)
        }
    }

    /// One shelter at a time, on the nearest free tile to home, while materials allow upkeep too.
    private func build(_ gs: GameState, canPlace: (BuildingType, Int, Int) -> Bool, place: (BuildingType, Int, Int) -> Bool) {
        guard let home, gs.buildings.filter({ $0.type == .shelter }).count < Self.shelterGoal,
              (gs.resources[.materials] ?? 0) >= 30 else { return }
        for r in 2...12 {
            for dc in -r...r {
                for dr in [-r, r] where canPlace(.shelter, home.col + dc, home.row + dr) {
                    if place(.shelter, home.col + dc, home.row + dr) { return }
                }
            }
        }
    }
}

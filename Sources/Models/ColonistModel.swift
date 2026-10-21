import Foundation

enum ColonistJob: String, Codable, Sendable, CaseIterable {
    case idle, gather, build, patrol, attack
}

enum WeaponType: String, Codable, Sendable, CaseIterable {
    case fists
    case pipe
    case bat
    case pistol
    case shotgun
    case rifle

    var damage: Double {
        switch self {
        case .fists: 5
        case .pipe: 10
        case .bat: 12
        case .pistol: 20
        case .shotgun: 30
        case .rifle: 25
        }
    }

    var range: Int {
        switch self {
        case .fists: 1
        case .pipe: 1
        case .bat: 1
        case .pistol: 5
        case .shotgun: 3
        case .rifle: 8
        }
    }

    var displayName: String {
        rawValue.uppercased()
    }
}

enum ColonistState: String, Codable, Sendable {
    case healthy, hungry, suffocating, exhausted, dead
}

enum ColonistTrait: String, Codable, Sendable, CaseIterable {
    case hustler      // +20% XP gain
    case scavenger    // +1 resource per harvest
    case insomniac    // 30% slower sleep decay
    case ironlung     // 30% slower oxygen decay
    case anxious      // 2x stress gain

    var displayName: String {
        rawValue.capitalized
    }

    var description: String {
        switch self {
        case .hustler: "+20% XP gain"
        case .scavenger: "+1 resource per harvest"
        case .insomniac: "30% slower sleep decay"
        case .ironlung: "30% slower oxygen decay"
        case .anxious: "2x stress gain"
        }
    }
}

struct ColonistStats: Codable, Sendable {
    var str: Int  // carry capacity, build speed
    var int: Int  // research efficiency, job task speed
    var agi: Int  // movement speed, pathfinding priority
    var end: Int  // slower need decay
    var cha: Int  // stress reduction near others, trade prices

    static func random() -> ColonistStats {
        ColonistStats(
            str: Int.random(in: 1...10),
            int: Int.random(in: 1...10),
            agi: Int.random(in: 1...10),
            end: Int.random(in: 1...10),
            cha: Int.random(in: 1...10)
        )
    }

    mutating func boostRandom() {
        let stat = Int.random(in: 0..<5)
        switch stat {
        case 0: str = min(10, str + 1)
        case 1: int = min(10, int + 1)
        case 2: agi = min(10, agi + 1)
        case 3: end = min(10, end + 1)
        default: cha = min(10, cha + 1)
        }
    }
}

struct ColonistModel: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var hunger: Double = 100
    var oxygen: Double = 100
    var stress: Double = 0
    var sleep: Double = 100
    var health: Double = 100
    var job: ColonistJob = .idle
    var state: ColonistState = .healthy
    var weapon: WeaponType = .fists
    var attackTargetId: UUID? = nil
    var col: Int
    var row: Int
    var inventory: [ResourceType: Int] = [:]
    var pathCols: [Int] = []
    var pathRows: [Int] = []
    var pathIndex: Int = 0

    var stats: ColonistStats = .random()
    var xp: Int = 0
    var level: Int = 1
    var trait: ColonistTrait = ColonistTrait.allCases.randomElement()!

    var isDead: Bool { state == .dead }

    var lowestNeed: Double {
        min(hunger, oxygen, sleep)
    }

    /// Same steps as the web game (web/js/state.js colonistXpForNext), so both win around day 35 to 40.
    /// It was level * 100 here, which put level 8 at 2,800 XP instead of 650 and made the game unwinnable.
    var xpForNextLevel: Int {
        switch level {
        case ...3: 50
        case ...6: 100
        case ...9: 200
        default: 300
        }
    }

    var xpProgress: Double {
        Double(xp) / Double(xpForNextLevel)
    }

    mutating func grantXP(_ amount: Int) {
        let adjusted = trait == .hustler ? Int(Double(amount) * 1.2) : amount
        xp += adjusted
        while xp >= xpForNextLevel {
            xp -= xpForNextLevel
            level += 1
            stats.boostRandom()
        }
    }

    /// Movement speed multiplier based on AGI
    var movementSpeed: Double {
        1.0 + Double(stats.agi) * 0.1
    }

    /// Hunger decay multiplier based on END
    var hungerDecayMultiplier: Double {
        1.0 - Double(stats.end) * 0.05
    }

    /// Build cost discount from INT (fraction)
    var buildDiscount: Double {
        Double(stats.int) * 0.02
    }

    mutating func takeDamage(_ amount: Double) {
        health = max(0, health - amount)
        if health <= 0 {
            state = .dead
        }
    }

    mutating func updateState() {
        guard state != .dead else { return }
        if health <= 0 || hunger <= 0 || oxygen <= 0 || sleep <= 0 {
            state = .dead
            return
        }
        if hunger < 20 {
            state = .hungry
        } else if oxygen < 20 {
            state = .suffocating
        } else if sleep < 20 {
            state = .exhausted
        } else {
            state = .healthy
        }
    }

    var currentPathPosition: (col: Int, row: Int)? {
        guard pathIndex < pathCols.count else { return nil }
        return (pathCols[pathIndex], pathRows[pathIndex])
    }

    mutating func advancePath() {
        if pathIndex < pathCols.count {
            pathIndex += 1
        }
    }

    var hasPath: Bool { pathIndex < pathCols.count }
}

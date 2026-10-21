import Foundation

// Ported directly from Sources/Models/{BuildingModel,ResourceModel,ColonistModel}.swift.
// NYC Survive is a fully local colony-survival builder (no backend, JSON save-slots on
// device), so there is no live game state to sync here -- this is a standalone quick-reference
// for the same static building costs, resource types, and colonist traits the main app ships
// with, not a mirror of an in-progress save.

enum ResourceType: String, CaseIterable {
    case food, power, materials, oxygen, cash

    var symbol: String {
        switch self {
        case .food: "F"
        case .power: "P"
        case .materials: "M"
        case .oxygen: "O"
        case .cash: "$"
        }
    }
}

enum BuildingType: String, CaseIterable {
    case shelter
    case foodStall
    case generator
    case filterStation
    case subwayAccess
    case billboard

    var displayName: String {
        switch self {
        case .shelter: "Shelter"
        case .foodStall: "Food Stall"
        case .generator: "Generator"
        case .filterStation: "Filter Station"
        case .subwayAccess: "Subway Access"
        case .billboard: "Billboard"
        }
    }

    var cost: [ResourceType: Int] {
        switch self {
        case .shelter: [.materials: 10]
        case .foodStall: [.materials: 8, .cash: 5]
        case .generator: [.materials: 15, .cash: 10]
        case .filterStation: [.materials: 12, .power: 5]
        case .subwayAccess: [.materials: 20, .cash: 15]
        case .billboard: [.materials: 5, .cash: 20]
        }
    }

    var costText: String {
        cost
            .sorted { $0.key.rawValue < $1.key.rawValue }
            .map { "\($1)\($0.symbol)" }
            .joined(separator: " ")
    }

    var description: String {
        switch self {
        case .shelter: "Reduces stress for nearby colonists"
        case .foodStall: "Converts food resources into meals"
        case .generator: "Produces power from materials"
        case .filterStation: "Filters oxygen using power"
        case .subwayAccess: "Fast travel between subway stations"
        case .billboard: "Generates cash over time"
        }
    }
}

enum ColonistTrait: String, CaseIterable {
    case hustler
    case scavenger
    case insomniac
    case ironlung
    case anxious

    var displayName: String { rawValue.capitalized }

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

enum WeaponType: String, CaseIterable {
    case fists
    case pipe
    case bat
    case pistol
    case shotgun
    case rifle

    var displayName: String { rawValue.uppercased() }

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
}

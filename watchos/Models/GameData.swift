import Foundation

// Ported directly from Sources/Models/{BuildingModel,ResourceModel}.swift.
// NYC Survive is a fully local colony builder (no backend, JSON save-slots on device), so
// there is no live game state to sync here. This is a standalone quick-reference for the
// same static building costs and resource types the main app ships with.

enum ResourceType: String, CaseIterable {
    case food, materials, power

    var symbol: String {
        switch self {
        case .food: "F"
        case .materials: "M"
        case .power: "P"
        }
    }
}

enum BuildingType: String, CaseIterable {
    case shelter
    case generator
    case drill
    case beacon

    var displayName: String {
        switch self {
        case .shelter: "Shelter"
        case .generator: "Generator"
        case .drill: "Drill"
        case .beacon: "Beacon"
        }
    }

    var cost: [ResourceType: Int] {
        switch self {
        case .shelter: [.materials: 10]
        case .generator: [.materials: 15]
        case .drill: [.materials: 12, .power: 2]
        case .beacon: [.materials: 8000, .power: 1000]
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
        case .shelter: "+4 beds"
        case .generator: "+1 power every 2 ticks"
        case .drill: "Next to a resource: mines it, burns power"
        case .beacon: "Raise it to win"
        }
    }
}

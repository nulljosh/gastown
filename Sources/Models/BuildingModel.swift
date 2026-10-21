import Foundation

/// Machines run on their own (ColonySystem.machineTick). The Beacon is the win. Same list as web/js/state.js.
enum BuildingType: String, Codable, Sendable, CaseIterable {
    case shelter
    case generator
    case drill
    case beacon

    var displayName: String {
        switch self {
        case .shelter: "Shelter"
        case .generator: "Generator"
        case .drill: "Drill"
        case .beacon: "Steam Clock"
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

    var description: String {
        switch self {
        case .shelter: "+4 beds"
        case .generator: "+1 power every 2 ticks"
        case .drill: "Next to a resource: +1 every 4 ticks, burns power"
        case .beacon: "Raise it to win"
        }
    }

    var tileSize: (w: Int, h: Int) {
        switch self {
        case .shelter, .generator, .beacon: (2, 2)
        case .drill: (1, 1)
        }
    }
}

struct BuildingModel: Identifiable, Codable, Sendable {
    var id: UUID
    var type: BuildingType
    var col: Int
    var row: Int
}

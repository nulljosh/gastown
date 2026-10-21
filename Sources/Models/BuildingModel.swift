import Foundation

enum BuildingType: String, Codable, Sendable, CaseIterable {
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

    var tileSize: (w: Int, h: Int) {
        switch self {
        case .shelter, .generator, .filterStation: (2, 2)
        case .foodStall, .subwayAccess: (1, 1)
        case .billboard: (2, 1)
        }
    }
}

struct BuildingModel: Identifiable, Codable, Sendable {
    var id: UUID
    var type: BuildingType
    var col: Int
    var row: Int
    var isActive: Bool = true
}

import SpriteKit

enum TileType: Int, Codable, Sendable {
    case road
    case sidewalk
    case building
    case billboard
    case subway
    case sewer
    case empty

    var rawString: String {
        switch self {
        case .road: "road"
        case .sidewalk: "sidewalk"
        case .building: "building"
        case .billboard: "billboard"
        case .subway: "subway"
        case .sewer: "sewer"
        case .empty: "empty"
        }
    }

    var isWalkable: Bool {
        switch self {
        case .road, .sidewalk, .subway: true
        case .building, .billboard, .sewer, .empty: false
        }
    }

    var baseColor: SKColor {
        switch self {
        case .road: SKColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
        case .sidewalk: SKColor(red: 0.35, green: 0.35, blue: 0.4, alpha: 1)
        case .building: SKColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
        case .billboard: SKColor(red: 1.0, green: 0.22, blue: 0.37, alpha: 1)
        case .subway: SKColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1)
        case .sewer: SKColor(red: 0.2, green: 0.25, blue: 0.2, alpha: 1)
        case .empty: SKColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1)
        }
    }

    var resourceYield: ResourceType? {
        switch self {
        case .subway: .cash
        case .sewer: .materials
        default: nil
        }
    }
}

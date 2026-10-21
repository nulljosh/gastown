import Foundation

@MainActor
struct WorldGenerator {
    static let gridSize = 128
    static let avenueSpacing = 16
    static let streetSpacing = 12
    static let avenueWidth = 4
    static let streetWidth = 3
    static let sidewalkWidth = 1

    static func generate() -> (grid: [[TileType]], resources: [ResourceModel]) {
        var grid = Array(repeating: Array(repeating: TileType.building, count: gridSize), count: gridSize)
        var resources: [ResourceModel] = []

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let isAvenue = isAvenueColumn(col)
                let isStreet = isStreetRow(row)
                let isAvenueSidewalk = isAvenueSidewalkColumn(col)
                let isStreetSidewalk = isStreetSidewalkRow(row)

                if isAvenue || isStreet {
                    grid[row][col] = .road
                } else if isAvenueSidewalk || isStreetSidewalk {
                    grid[row][col] = .sidewalk
                }
            }
        }

        for row in stride(from: streetSpacing, to: gridSize, by: streetSpacing) {
            for col in stride(from: avenueSpacing, to: gridSize, by: avenueSpacing) {
                if row < gridSize && col < gridSize {
                    grid[row][col] = .subway
                }
            }
        }

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col] == .building {
                    let adjAvenue = isAvenueSidewalkColumn(col - 1) || isAvenueSidewalkColumn(col + 1)
                    if adjAvenue && Int.random(in: 0..<5) == 0 {
                        grid[row][col] = .billboard
                    }
                }
            }
        }

        let resourceTypes: [ResourceType] = [.food, .food, .food, .materials, .materials, .power, .oxygen, .cash]
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col] == .sidewalk && Int.random(in: 0..<40) == 0 {
                    let rtype = resourceTypes[Int.random(in: 0..<resourceTypes.count)]
                    let maxAmt: Int
                    switch rtype {
                    case .food: maxAmt = 10
                    case .materials: maxAmt = 15
                    case .power: maxAmt = 8
                    case .oxygen: maxAmt = 12
                    case .cash: maxAmt = 20
                    }
                    resources.append(ResourceModel(
                        id: UUID(),
                        type: rtype,
                        col: col,
                        row: row,
                        remaining: maxAmt,
                        maxAmount: maxAmt,
                        respawnTicks: 60
                    ))
                }
            }
        }

        return (grid, resources)
    }

    private static func isAvenueColumn(_ col: Int) -> Bool {
        let offset = col % avenueSpacing
        return offset >= 0 && offset < avenueWidth
    }

    private static func isStreetRow(_ row: Int) -> Bool {
        let offset = row % streetSpacing
        return offset >= 0 && offset < streetWidth
    }

    private static func isAvenueSidewalkColumn(_ col: Int) -> Bool {
        let offset = col % avenueSpacing
        return offset == avenueWidth || (offset == avenueSpacing - 1 && col > 0)
    }

    private static func isStreetSidewalkRow(_ row: Int) -> Bool {
        let offset = row % streetSpacing
        return offset == streetWidth || (offset == streetSpacing - 1 && row > 0)
    }
}

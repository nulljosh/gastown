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

        addWater(&grid)

        let resourceTypes: [ResourceType] = [.food, .food, .materials, .materials, .materials, .power]
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                if grid[row][col] == .sidewalk && Int.random(in: 0..<40) == 0 {
                    let rtype = resourceTypes[Int.random(in: 0..<resourceTypes.count)]
                    let maxAmt: Int
                    switch rtype {
                    case .food: maxAmt = 10
                    case .materials: maxAmt = 15
                    case .power: maxAmt = 8
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

    /// Vancouver: Burrard Inlet along the north edge and False Creek across the south, each with a
    /// seawall path, and one bridge over the creek. Water is `.empty`. Same shape as web/js/world.js addWater.
    static let inletRows = 0..<9, creekRows = 106..<112, creekCols = 0..<88, bridgeCols = 32..<36
    private static func addWater(_ grid: inout [[TileType]]) {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let creek = creekRows.contains(row) && creekCols.contains(col)
                if inletRows.contains(row) || (creek && !bridgeCols.contains(col)) { grid[row][col] = .empty }
                else if row == inletRows.upperBound || ((row == creekRows.lowerBound - 1 || row == creekRows.upperBound) && creekCols.contains(col) && !bridgeCols.contains(col)) { grid[row][col] = .sidewalk }
                else if creek { grid[row][col] = .road }
            }
        }
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

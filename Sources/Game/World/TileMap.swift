import SpriteKit

@MainActor
final class TileMap {
    static let tileSize: CGFloat = 32
    let columns: Int
    let rows: Int
    var grid: [[TileType]]
    let node: SKNode

    init(grid: [[TileType]]) {
        self.grid = grid
        self.rows = grid.count
        self.columns = grid.isEmpty ? 0 : grid[0].count
        self.node = SKNode()
        node.name = "tileMap"
        buildTiles()
    }

    private static var tileTextureCache: [TileType: SKTexture] = {
        var cache = [TileType: SKTexture]()
        for tile in [TileType.road, .sidewalk, .building, .billboard, .subway, .sewer, .empty] {
            let tex = SKTexture(imageNamed: "tile_\(tile.rawString)")
            tex.filteringMode = .nearest
            cache[tile] = tex
        }
        return cache
    }()

    private func buildTiles() {
        for row in 0..<rows {
            for col in 0..<columns {
                let tile = grid[row][col]
                let rect: SKSpriteNode
                if let tex = TileMap.tileTextureCache[tile] {
                    rect = SKSpriteNode(texture: tex, size: CGSize(width: TileMap.tileSize, height: TileMap.tileSize))
                } else {
                    rect = SKSpriteNode(color: tile.baseColor, size: CGSize(width: TileMap.tileSize, height: TileMap.tileSize))
                }
                rect.anchorPoint = CGPoint(x: 0, y: 0)
                rect.position = CGPoint(
                    x: CGFloat(col) * TileMap.tileSize,
                    y: CGFloat(row) * TileMap.tileSize
                )
                rect.name = "tile_\(col)_\(row)"
                node.addChild(rect)
            }
        }
    }

    func tileAt(col: Int, row: Int) -> TileType? {
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        return grid[row][col]
    }

    func setTile(_ type: TileType, col: Int, row: Int) {
        guard col >= 0, col < columns, row >= 0, row < rows else { return }
        grid[row][col] = type
        if let existing = node.childNode(withName: "tile_\(col)_\(row)") as? SKSpriteNode {
            if let tex = TileMap.tileTextureCache[type] {
                existing.texture = tex
            } else {
                existing.color = type.baseColor
            }
        }
    }

    func worldPosition(col: Int, row: Int) -> CGPoint {
        CGPoint(
            x: CGFloat(col) * TileMap.tileSize + TileMap.tileSize / 2,
            y: CGFloat(row) * TileMap.tileSize + TileMap.tileSize / 2
        )
    }

    func tilePosition(worldX: CGFloat, worldY: CGFloat) -> (col: Int, row: Int) {
        let col = Int(worldX / TileMap.tileSize)
        let row = Int(worldY / TileMap.tileSize)
        return (max(0, min(col, columns - 1)), max(0, min(row, rows - 1)))
    }
}

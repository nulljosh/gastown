import Foundation

/// Shortest walking route on the tile grid (4-way, every step costs the same), so a breadth-first
/// search is exact. Replaced GKGridGraph on 2026-10-21: removing the ~10k wall nodes from a full grid
/// graph is quadratic and froze New Game for about 7 seconds. A walkable bitmap builds in microseconds.
@MainActor
final class Pathfinder {
    private var walkable: [Bool] = []
    private let columns: Int
    private let rows: Int

    init(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }

    private func index(_ col: Int, _ row: Int) -> Int? {
        guard col >= 0, col < columns, row >= 0, row < rows else { return nil }
        return row * columns + col
    }

    func buildGraph(grid: [[TileType]]) {
        walkable = Array(repeating: false, count: columns * rows)
        for row in 0..<min(rows, grid.count) {
            for col in 0..<min(columns, grid[row].count) where grid[row][col].isWalkable {
                walkable[row * columns + col] = true
            }
        }
    }

    func removeNode(col: Int, row: Int) {
        if let i = index(col, row), i < walkable.count { walkable[i] = false }
    }

    func addNode(col: Int, row: Int) {
        if let i = index(col, row), i < walkable.count { walkable[i] = true }
    }

    /// Start to end inclusive, or empty when either end is blocked or unreachable.
    func findPath(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> [(col: Int, row: Int)] {
        guard let start = index(fromCol, fromRow), let end = index(toCol, toRow),
              start < walkable.count, walkable[start], walkable[end] else { return [] }
        if start == end { return [(fromCol, fromRow)] }
        var cameFrom = Array(repeating: -1, count: walkable.count)
        cameFrom[start] = start
        var queue = [start]
        var head = 0
        search: while head < queue.count {
            let cur = queue[head]; head += 1
            let col = cur % columns, row = cur / columns
            for (dc, dr) in [(1, 0), (-1, 0), (0, 1), (0, -1)] {
                guard let next = index(col + dc, row + dr), walkable[next], cameFrom[next] == -1 else { continue }
                cameFrom[next] = cur
                if next == end { break search }
                queue.append(next)
            }
        }
        guard cameFrom[end] != -1 else { return [] }
        var path: [(col: Int, row: Int)] = []
        var cur = end
        while cur != start {
            path.append((cur % columns, cur / columns))
            cur = cameFrom[cur]
        }
        path.append((fromCol, fromRow))
        return path.reversed()
    }

    /// Path to the tile, or to a neighbour when the tile itself is blocked (nodes can sit on
    /// building tiles; harvesting works from one tile away).
    func findPathNear(fromCol: Int, fromRow: Int, toCol: Int, toRow: Int) -> [(col: Int, row: Int)] {
        for (dc, dr) in [(0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)] {
            let p = findPath(fromCol: fromCol, fromRow: fromRow, toCol: toCol + dc, toRow: toRow + dr)
            if !p.isEmpty { return p }
        }
        return []
    }
}

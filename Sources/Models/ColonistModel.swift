import Foundation

enum ColonistJob: String, Codable, Sendable, CaseIterable {
    case idle, gather
}

struct ColonistModel: Identifiable, Codable, Sendable {
    var id: UUID
    var name: String
    var col: Int
    var row: Int
    var job: ColonistJob = .idle
    var pathCols: [Int] = []
    var pathRows: [Int] = []
    var pathIndex: Int = 0

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

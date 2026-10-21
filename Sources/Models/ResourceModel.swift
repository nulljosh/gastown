import Foundation

enum ResourceType: String, Codable, Sendable, CaseIterable, Hashable {
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

struct ResourceModel: Identifiable, Codable, Sendable {
    var id: UUID
    var type: ResourceType
    var col: Int
    var row: Int
    var remaining: Int
    var maxAmount: Int
    var respawnTicks: Int
    var ticksSinceDepleted: Int = 0

    var isDepleted: Bool { remaining <= 0 }

    mutating func harvest(amount: Int = 1) -> Int {
        let taken = min(amount, remaining)
        remaining -= taken
        return taken
    }

    mutating func tickRespawn() {
        guard isDepleted else { return }
        ticksSinceDepleted += 1
        if ticksSinceDepleted >= respawnTicks {
            remaining = maxAmount
            ticksSinceDepleted = 0
        }
    }
}

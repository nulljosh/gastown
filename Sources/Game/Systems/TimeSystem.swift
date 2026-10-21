import Foundation

@MainActor
final class TimeSystem {
    private var accumulated: TimeInterval = 0
    private let tickInterval: TimeInterval = 1.0
    let ticksPerDay = 240

    /// How many ticks are due this frame (capped, so a slow frame never runs away). Call `advance` for each.
    func update(deltaTime: TimeInterval, gameState: GameState) -> Int {
        guard !gameState.isPaused else { return 0 }
        accumulated += deltaTime
        var due = 0
        while accumulated >= tickInterval && due < 16 {
            accumulated -= tickInterval
            due += 1
        }
        if due == 16 { accumulated = 0 }
        return due
    }

    func advance(_ gameState: GameState) {
        gameState.currentTick += 1
        gameState.currentHour = (gameState.currentTick % ticksPerDay) / 10
        gameState.isNight = gameState.currentHour >= 20 || gameState.currentHour < 6
    }
}

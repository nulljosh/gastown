import SpriteKit

/// Timers for the city that runs behind the title menu.
struct MenuBackdropClock {
    var clock: TimeInterval = 0
    var wander: TimeInterval = 0
    var center: CGPoint?
}

extension GameScene {
    /// Title menu only: the camera circles slowly and colonists stroll, so the menu sits on a live city.
    /// Real games never move colonists on their own (see CLAUDE.md); this never runs outside the menu.
    func animateBackdrop(_ dt: TimeInterval) {
        let center = backdrop.center ?? cameraController.cameraNode.position
        backdrop.center = center
        backdrop.clock += dt
        cameraController.centerOn(position: CGPoint(
            x: center.x + CGFloat(sin(backdrop.clock * 0.06)) * 320,
            y: center.y + CGFloat(cos(backdrop.clock * 0.045)) * 200))

        backdrop.wander += dt
        guard backdrop.wander >= 0.8 else { return }
        backdrop.wander = 0
        guard let c = gameState.colonists.filter({ !$0.isDead }).randomElement() else { return }
        let last = WorldGenerator.gridSize - 1
        jobSystem.commandMove(
            colonistId: c.id,
            destCol: min(max(c.col + Int.random(in: -10...10), 0), last),
            destRow: min(max(c.row + Int.random(in: -10...10), 0), last),
            gameState: gameState, pathfinder: pathfinder)
    }
}

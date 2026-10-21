import SwiftUI

/// The whole 128x128 city at a glance: buildings as squares, resources as small marks,
/// survivors as dots (the selected ones ringed). Row 0 is the bottom of the world, as in SpriteKit.
struct MiniMap: View {
    @Bindable var gameState: GameState
    private let side: CGFloat = 150

    var body: some View {
        Canvas { ctx, size in
            let cell = size.width / CGFloat(WorldGenerator.gridSize)
            func point(_ col: Int, _ row: Int) -> CGPoint {
                CGPoint(x: (CGFloat(col) + 0.5) * cell, y: size.height - (CGFloat(row) + 0.5) * cell)
            }
            for r in gameState.resourceNodes where !r.isDepleted {
                let p = point(r.col, r.row)
                ctx.fill(Path(CGRect(x: p.x - 1, y: p.y - 1, width: 2, height: 2)), with: .color(Theme.green.opacity(0.7)))
            }
            for b in gameState.buildings {
                let p = point(b.col, b.row)
                ctx.fill(Path(CGRect(x: p.x - 2, y: p.y - 2, width: 4, height: 4)), with: .color(Theme.yellow))
            }
            let picked = gameState.selectedColonistIds.union([gameState.selectedColonistId].compactMap { $0 })
            for c in gameState.colonists where !c.isDead {
                let p = point(c.col, c.row)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(Theme.accent))
                if picked.contains(c.id) {
                    ctx.stroke(Path(ellipseIn: CGRect(x: p.x - 4.5, y: p.y - 4.5, width: 9, height: 9)), with: .color(Theme.text1), lineWidth: 1)
                }
            }
        }
        .frame(width: side, height: side)
        .background(RoundedRectangle(cornerRadius: Theme.radius).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 1))
        .allowsHitTesting(false)
    }
}

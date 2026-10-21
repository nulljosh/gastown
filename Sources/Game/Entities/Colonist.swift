import SpriteKit

@MainActor
final class ColonistNode: SKSpriteNode {
    let colonistId: UUID
    private var isMoving = false
    private let indicator: SKShapeNode

    init(id: UUID) {
        self.colonistId = id
        let size = CGSize(width: 32, height: 32)

        // Green circle indicator underneath so colonists are visible
        indicator = SKShapeNode(circleOfRadius: 10)
        indicator.fillColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.4)
        indicator.strokeColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.8)
        indicator.lineWidth = 1
        indicator.zPosition = -1


        let tex = SKTexture(imageNamed: "colonist_idle")
        tex.filteringMode = .nearest
        super.init(texture: tex, color: .green, size: size)
        self.name = "colonist_\(id.uuidString)"
        self.zPosition = 10

        addChild(indicator)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Green while working a resource, grey when idle. The one thing you need to see at a glance.
    func update(model: ColonistModel) {
        let c = model.job == .gather ? SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1) : SKColor(white: 0.55, alpha: 1)
        indicator.fillColor = c.withAlphaComponent(0.35)
        indicator.strokeColor = c.withAlphaComponent(0.8)
    }

    func moveToward(target: CGPoint, speed: CGFloat) {
        let dx = target.x - position.x
        let dy = target.y - position.y
        let dist = sqrt(dx * dx + dy * dy)
        if dist < 2 {
            position = target
            if isMoving {
                isMoving = false
                removeAction(forKey: "walk")
            }
            return
        }
        if !isMoving {
            isMoving = true
            let t1 = SKTexture(imageNamed: "colonist_walk1")
            let t2 = SKTexture(imageNamed: "colonist_walk2")
            t1.filteringMode = .nearest
            t2.filteringMode = .nearest
            let walkAction = SKAction.animate(with: [t1, t2], timePerFrame: 0.3)
            run(SKAction.repeatForever(walkAction), withKey: "walk")
        }
        let step = min(speed, dist)
        position.x += (dx / dist) * step
        position.y += (dy / dist) * step
    }

    var isAtTarget: Bool {
        false
    }

    func isNear(_ target: CGPoint, threshold: CGFloat = 4) -> Bool {
        let dx = target.x - position.x
        let dy = target.y - position.y
        return sqrt(dx * dx + dy * dy) < threshold
    }
}

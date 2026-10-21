import SpriteKit

@MainActor
final class ColonistNode: SKSpriteNode {
    let colonistId: UUID
    private var isMoving = false
    private let indicator: SKShapeNode
    private let healthBarBg: SKShapeNode
    private let healthBarFill: SKShapeNode

    init(id: UUID) {
        self.colonistId = id
        let size = CGSize(width: 32, height: 32)

        // Green circle indicator underneath so colonists are visible
        indicator = SKShapeNode(circleOfRadius: 10)
        indicator.fillColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.4)
        indicator.strokeColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 0.8)
        indicator.lineWidth = 1
        indicator.zPosition = -1

        healthBarBg = SKShapeNode(rect: CGRect(x: -12, y: 0, width: 24, height: 3), cornerRadius: 1)
        healthBarBg.fillColor = SKColor(white: 0.2, alpha: 0.8)
        healthBarBg.strokeColor = .clear
        healthBarBg.position = CGPoint(x: 0, y: 20)
        healthBarBg.zPosition = 20

        healthBarFill = SKShapeNode(rect: CGRect(x: -12, y: 0, width: 24, height: 3), cornerRadius: 1)
        healthBarFill.fillColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        healthBarFill.strokeColor = .clear
        healthBarFill.position = CGPoint(x: 0, y: 20)
        healthBarFill.zPosition = 21

        let tex = SKTexture(imageNamed: "colonist_idle")
        tex.filteringMode = .nearest
        super.init(texture: tex, color: .green, size: size)
        self.name = "colonist_\(id.uuidString)"
        self.zPosition = 10

        addChild(indicator)
        addChild(healthBarBg)
        addChild(healthBarFill)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func update(model: ColonistModel) {
        let texName: String
        switch model.state {
        case .healthy: texName = "colonist_idle"
        case .hungry: texName = "colonist_hungry"
        case .suffocating: texName = "colonist_suffocating"
        case .exhausted: texName = "colonist_exhausted"
        case .dead: texName = "colonist_dead"
        }
        let tex = SKTexture(imageNamed: texName)
        tex.filteringMode = .nearest
        self.texture = tex

        // Update indicator color to match state
        let indicatorColor: SKColor
        switch model.state {
        case .healthy: indicatorColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        case .hungry: indicatorColor = SKColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1)
        case .suffocating: indicatorColor = SKColor(red: 0.39, green: 0.82, blue: 1.0, alpha: 1)
        case .exhausted: indicatorColor = SKColor(red: 1.0, green: 0.62, blue: 0.04, alpha: 1)
        case .dead: indicatorColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        }
        indicator.fillColor = indicatorColor.withAlphaComponent(0.35)
        indicator.strokeColor = indicatorColor.withAlphaComponent(0.8)

        let hpFrac = max(0, min(1, model.health / 100.0))
        healthBarFill.xScale = CGFloat(hpFrac)
        let hpColor: SKColor
        if model.health > 60 {
            hpColor = SKColor(red: 0.19, green: 0.82, blue: 0.35, alpha: 1)
        } else if model.health > 30 {
            hpColor = SKColor(red: 1.0, green: 0.84, blue: 0.04, alpha: 1)
        } else {
            hpColor = SKColor(red: 1.0, green: 0.27, blue: 0.23, alpha: 1)
        }
        healthBarFill.fillColor = hpColor
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

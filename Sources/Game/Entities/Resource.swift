import SpriteKit

@MainActor
final class ResourceNode: SKSpriteNode {
    let resourceId: UUID
    let resourceType: ResourceType

    init(model: ResourceModel, tileSize: CGFloat) {
        self.resourceId = model.id
        self.resourceType = model.type
        let tex = SKTexture(imageNamed: "res_\(model.type.rawValue)")
        tex.filteringMode = .nearest
        let size = CGSize(width: 16, height: 16)
        super.init(texture: tex, color: .clear, size: size)
        self.zPosition = 3
        self.name = "resource_\(model.id.uuidString)"

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.5),
            SKAction.scale(to: 0.8, duration: 0.5)
        ])
        run(SKAction.repeatForever(pulse))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func update(model: ResourceModel) {
        let fraction = CGFloat(model.remaining) / CGFloat(max(model.maxAmount, 1))
        alpha = max(0.3, fraction)
        if model.isDepleted {
            alpha = 0.15
        }
    }
}

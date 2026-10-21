import SpriteKit

@MainActor
final class BuildingNode: SKSpriteNode {
    let buildingId: UUID
    let buildingType: BuildingType

    init(model: BuildingModel, tileSize: CGFloat) {
        self.buildingId = model.id
        self.buildingType = model.type
        let ts = model.type.tileSize
        let size = CGSize(width: CGFloat(ts.w) * tileSize, height: CGFloat(ts.h) * tileSize)
        let tex = SKTexture(imageNamed: model.type.rawValue)
        tex.filteringMode = .nearest
        super.init(texture: tex, color: .clear, size: size)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.zPosition = 5
        self.name = "building_\(model.id.uuidString)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func playPlaceAnimation() {
        setScale(0.1)
        run(SKAction.scale(to: 1.0, duration: 0.2))
        run(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ]))
    }
}

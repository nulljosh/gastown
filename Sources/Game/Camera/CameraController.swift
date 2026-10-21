import SpriteKit

@MainActor
final class CameraController {
    let cameraNode: SKCameraNode
    var panDirection: CGPoint = .zero
    private let panSpeed: CGFloat = 400
    private var currentZoom: CGFloat = 1.0
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 3.0

    init() {
        cameraNode = SKCameraNode()
        cameraNode.name = "camera"
    }

    func update(deltaTime: TimeInterval) {
        let dt = CGFloat(deltaTime)
        cameraNode.position.x += panDirection.x * panSpeed * dt * currentZoom
        cameraNode.position.y += panDirection.y * panSpeed * dt * currentZoom
    }

    func panBy(delta: CGPoint) {
        cameraNode.position.x -= delta.x * currentZoom
        cameraNode.position.y -= delta.y * currentZoom
    }

    func zoom(by amount: CGFloat) {
        currentZoom = max(minZoom, min(maxZoom, currentZoom - amount))
        cameraNode.setScale(currentZoom)
    }

    func centerOn(position: CGPoint) {
        cameraNode.position = position
    }
}

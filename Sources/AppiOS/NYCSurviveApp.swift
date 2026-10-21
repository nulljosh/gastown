import SwiftUI
import SpriteKit

@main
struct NYCSurviveApp: App {
    @State private var themeChoice = Theme.choice
    @State private var gameState = GameState()
    @State private var showMenu = true
    @State private var loadSlot: Int? = nil
    @State private var menuBackdrop = GameState.menuBackdrop()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showMenu {
                    GameSceneView(gameState: menuBackdrop, loadSlot: nil)
                    MenuSceneView(
                        onNewGame: {
                            gameState = GameState()
                            gameState.tutorialStep = 0
                            loadSlot = nil
                            showMenu = false
                        },
                        onLoadGame: { slot in
                            loadSlot = slot
                            gameState = GameState()
                            gameState.tutorialStep = nil
                            if SaveManager.shared.load(slot: slot) != nil {
                                gameState.lastSaveSlot = slot
                            }
                            showMenu = false
                        }
                    )
                } else {
                    GameView(gameState: gameState, loadSlot: loadSlot)
                }
            }
            .preferredColorScheme(themeChoice.colorScheme)
            .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
                themeChoice = Theme.choice
            }
            .statusBarHidden()
        }
    }
}

struct MenuSceneView: UIViewRepresentable {
    var onNewGame: () -> Void
    var onLoadGame: (Int) -> Void

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        let scene = MenuScene(size: CGSize(width: 1280, height: 800))
        scene.scaleMode = .aspectFill
        scene.onNewGame = onNewGame
        scene.onLoadGame = onLoadGame
        view.presentScene(scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}
}

struct GameView: View {
    @Bindable var gameState: GameState
    var loadSlot: Int?

    var body: some View {
        ZStack {
            GameSceneView(gameState: gameState, loadSlot: loadSlot)
            HUDView(gameState: gameState)
        }
    }
}

struct GameSceneView: UIViewRepresentable {
    let gameState: GameState
    var loadSlot: Int?

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
        #endif
        view.ignoresSiblingOrder = true
        let scene = GameScene(gameState: gameState)
        if let slot = loadSlot {
            scene.savedData = SaveManager.shared.load(slot: slot)
        }
        view.presentScene(scene)

        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        context.coordinator.scene = scene
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    @MainActor
    final class Coordinator: NSObject {
        weak var scene: GameScene?

        @objc func handlePinch(_ recognizer: UIPinchGestureRecognizer) {
            let scale = recognizer.scale
            recognizer.scale = 1.0
            Task { @MainActor in
                scene?.applyPinch(scale: scale)
            }
        }
    }
}

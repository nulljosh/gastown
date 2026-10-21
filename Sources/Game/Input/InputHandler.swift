import SpriteKit

@MainActor
final class InputHandler {
    weak var gameState: GameState?
    weak var cameraController: CameraController?

    var onPlaceBuilding: ((Int, Int) -> Void)?
    var onDemolish: ((CGPoint) -> Void)?
    var onSelectEntity: ((CGPoint) -> Void)?
    var onSave: (() -> Void)?

    #if os(macOS)
    func handleKeyDown(event: NSEvent) {
        guard let gameState else { return }
        let chars = event.charactersIgnoringModifiers ?? ""
        let modifiers = event.modifierFlags

        // Cmd+S -> save
        if modifiers.contains(.command) && chars == "s" {
            onSave?()
            return
        }

        switch chars {
        case "w", "W":
            cameraController?.panDirection.y = 1
            TutorialView.checkAdvance(gameState: gameState, event: .wasdPressed)
        case "s", "S":
            cameraController?.panDirection.y = -1
            TutorialView.checkAdvance(gameState: gameState, event: .wasdPressed)
        case "a", "A":
            cameraController?.panDirection.x = -1
            TutorialView.checkAdvance(gameState: gameState, event: .wasdPressed)
        case "d", "D":
            cameraController?.panDirection.x = 1
            TutorialView.checkAdvance(gameState: gameState, event: .wasdPressed)
        case "b", "B":
            gameState.showBuildMenu.toggle()
            if !gameState.showBuildMenu { gameState.inputMode = .normal }
            TutorialView.checkAdvance(gameState: gameState, event: .buildMenuOpened)
        case " ": gameState.isPaused.toggle()
        case "1": selectBuilding(.shelter, gameState: gameState)
        case "2": selectBuilding(.foodStall, gameState: gameState)
        case "3": selectBuilding(.generator, gameState: gameState)
        case "4": selectBuilding(.filterStation, gameState: gameState)
        case "5": selectBuilding(.subwayAccess, gameState: gameState)
        case "6": selectBuilding(.billboard, gameState: gameState)
        case "x", "X":
            if gameState.inputMode == .demolish {
                gameState.inputMode = .normal
            } else {
                gameState.inputMode = .demolish
            }
        default: break
        }

        if event.keyCode == 53 {
            if !gameState.selectedColonistIds.isEmpty || gameState.selectedColonistId != nil {
                gameState.selectedColonistIds = []
                gameState.selectedColonistId = nil
            } else if gameState.inputMode != .normal || gameState.showBuildMenu {
                gameState.inputMode = .normal
                gameState.selectedBuildingType = nil
                gameState.showBuildMenu = false
            } else {
                gameState.showSettings.toggle()
                gameState.isPaused = gameState.showSettings
            }
        }

        if let key = event.specialKey {
            switch key {
            case .upArrow: cameraController?.panDirection.y = 1
            case .downArrow: cameraController?.panDirection.y = -1
            case .leftArrow: cameraController?.panDirection.x = -1
            case .rightArrow: cameraController?.panDirection.x = 1
            default: break
            }
        }
    }

    func handleKeyUp(event: NSEvent) {
        let chars = event.charactersIgnoringModifiers ?? ""
        switch chars {
        case "w", "W", "s", "S": cameraController?.panDirection.y = 0
        case "a", "A", "d", "D": cameraController?.panDirection.x = 0
        default: break
        }
        if let key = event.specialKey {
            switch key {
            case .upArrow, .downArrow: cameraController?.panDirection.y = 0
            case .leftArrow, .rightArrow: cameraController?.panDirection.x = 0
            default: break
            }
        }
    }
    #endif

    func handleMouseDown(location: CGPoint, tileMap: TileMap) {
        guard let gameState else { return }
        let tilePos = tileMap.tilePosition(worldX: location.x, worldY: location.y)

        switch gameState.inputMode {
        case .normal:
            onSelectEntity?(location)
        case .build:
            onPlaceBuilding?(tilePos.col, tilePos.row)
        case .demolish:
            onDemolish?(location)
        }
    }

    func handleScrollWheel(deltaY: CGFloat) {
        cameraController?.zoom(by: deltaY * 0.01)
    }

    func handleTap(location: CGPoint, tileMap: TileMap) {
        handleMouseDown(location: location, tileMap: tileMap)
    }

    func handlePan(delta: CGPoint) {
        cameraController?.panBy(delta: delta)
    }

    func handlePinch(scale: CGFloat) {
        cameraController?.zoom(by: (1 - scale) * 2)
    }

    private func selectBuilding(_ type: BuildingType, gameState: GameState) {
        gameState.selectedBuildingType = type
        gameState.inputMode = .build
        gameState.showBuildMenu = true
    }
}

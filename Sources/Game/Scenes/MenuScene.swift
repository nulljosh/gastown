import SpriteKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
final class MenuScene: SKScene {
    var onNewGame: (() -> Void)?
    var onLoadGame: ((Int) -> Void)?

    /// NYC Sans, the same face as the HUD (see NYCFont in Theme.swift).
    private func chill(_ weight: ChillWeight = .semibold) -> String {
        NYCFont.name(weight == .bold ? .bold : weight == .regular ? .regular : .semibold)
    }
    private enum ChillWeight { case regular, semibold, bold }

    private var showingSettings = false
    private var showingLoadMenu = false
    private var loadMenuNodes: [SKNode] = []

    /// Menu sits over the live city (GameState.menuBackdrop), so it is always styled dark:
    /// a flat scrim, white type and the brand blue (brand/tokens.css) on the primary button.
    private static let accent = SKColor(red: 0.24, green: 0.48, blue: 1.00, alpha: 1)

    override func didMove(to view: SKView) {
        backgroundColor = .clear

        let scrim = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        scrim.fillColor = SKColor(white: 0, alpha: 0.55)
        scrim.strokeColor = .clear
        scrim.zPosition = -1
        addChild(scrim)

        let title = SKLabelNode(fontNamed: chill(.bold))
        // Must match the App Store name — a title screen that says something else
        // reads as the wrong app to a reviewer (see wiki: app-renaming).
        title.text = "NYC Survive"
        title.fontSize = 64
        title.fontColor = .white
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
        title.horizontalAlignmentMode = .center
        addChild(title)

        let subtitle = SKLabelNode(fontNamed: chill(.regular))
        subtitle.text = "Hold Times Square. Keep everyone alive."
        subtitle.fontSize = 20
        subtitle.fontColor = SKColor(white: 1, alpha: 0.7)
        subtitle.position = CGPoint(x: size.width / 2, y: size.height * 0.59)
        subtitle.horizontalAlignmentMode = .center
        addChild(subtitle)

        addButton("New Game", name: "newGame", y: size.height * 0.44, primary: true)
        addButton("Load Game", name: "loadGame", y: size.height * 0.36)
        addButton("Settings", name: "settings", y: size.height * 0.28)
        #if os(macOS)
        addButton("Quit", name: "quit", y: size.height * 0.20)
        #endif
    }

    /// 48 point capsule; the name sits on the capsule only, so one click fires once.
    private func addButton(_ text: String, name: String, y: CGFloat, primary: Bool = false) {
        let w: CGFloat = 280, h: CGFloat = 48
        let pill = SKShapeNode(rect: CGRect(x: -w / 2, y: -h / 2, width: w, height: h), cornerRadius: h / 2)
        pill.fillColor = primary ? Self.accent : SKColor(white: 1, alpha: 0.12)
        pill.strokeColor = primary ? .clear : SKColor(white: 1, alpha: 0.2)
        pill.lineWidth = 1
        pill.position = CGPoint(x: size.width / 2, y: y)
        pill.name = name
        pill.userData = ["fill": pill.fillColor]
        addChild(pill)

        let label = SKLabelNode(fontNamed: chill(.semibold))
        label.text = text
        label.fontSize = 20
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        pill.addChild(label)
    }

    private func showLoadMenu() {
        guard !showingLoadMenu else { return }
        showingLoadMenu = true

        // Dim overlay
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = ScenePalette.overlayScrim
        overlay.strokeColor = .clear
        overlay.name = "loadOverlay"
        overlay.zPosition = 10
        addChild(overlay)
        loadMenuNodes.append(overlay)

        let header = SKLabelNode(fontNamed: chill(.bold))
        header.text = "LOAD GAME"
        header.fontSize = 28
        header.fontColor = ScenePalette.title
        header.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        header.horizontalAlignmentMode = .center
        header.zPosition = 11
        addChild(header)
        loadMenuNodes.append(header)

        let slots = SaveManager.shared.listSlots()

        for i in 0..<3 {
            let slotY = size.height * (0.58 - CGFloat(i) * 0.14)
            let slotData = slots[i]

            let bg = SKShapeNode(rect: CGRect(x: size.width / 2 - 200, y: slotY - 20, width: 400, height: 50), cornerRadius: 0)
            bg.fillColor = ScenePalette.panelFill
            bg.strokeColor = ScenePalette.title.withAlphaComponent(0.3)
            bg.lineWidth = 1
            bg.name = "loadSlot\(i + 1)"
            bg.zPosition = 11
            addChild(bg)
            loadMenuNodes.append(bg)

            let label = SKLabelNode(fontNamed: chill(.bold))
            label.fontSize = 16
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(x: size.width / 2, y: slotY + 5)
            label.zPosition = 12
            label.name = "loadSlot\(i + 1)"

            if let slot = slotData {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d, HH:mm"
                let dateStr = formatter.string(from: slot.timestamp)
                label.text = "Slot \(i + 1): Day \(slot.dayCount), \(slot.colonistCount) alive, \(dateStr)"
                label.fontColor = ScenePalette.accentWarm
            } else {
                label.text = "Slot \(i + 1): empty"
                label.fontColor = ScenePalette.disabled
            }

            addChild(label)
            loadMenuNodes.append(label)
        }

        let back = SKLabelNode(fontNamed: chill(.bold))
        back.text = "[ ESC TO GO BACK ]"
        back.fontSize = 14
        back.fontColor = ScenePalette.muted
        back.position = CGPoint(x: size.width / 2, y: size.height * 0.18)
        back.horizontalAlignmentMode = .center
        back.zPosition = 11
        addChild(back)
        loadMenuNodes.append(back)
    }

    private func showSettings() {
        guard !showingSettings else { return }
        showingSettings = true
        let overlay = SKShapeNode(rect: CGRect(origin: .zero, size: size))
        overlay.fillColor = ScenePalette.overlayScrim
        overlay.strokeColor = .clear
        overlay.name = "settingsOverlay"
        overlay.zPosition = 10
        addChild(overlay)
        loadMenuNodes.append(overlay)
        let lines = [
            ("How to play", true),
            ("Click a survivor, or drag a box around a few", false),
            ("Click the ground to send them there", false),
            ("Click a resource to gather it", false),
            ("B opens build, 1-6 picks a building", false),
            ("WASD pans, scroll zooms, Esc deselects", false),
            ("Buildings burn materials. Empty pile, they break.", false),
            ("Every third night: scavengers. PATROL near a building stops them.", false),
            ("Win: 15 survivors, average level 8.", false),
            ("Tap anywhere to go back", false),
        ]
        for (i, line) in lines.enumerated() {
            let l = SKLabelNode(fontNamed: chill(line.1 ? .bold : .regular))
            l.text = line.0
            l.fontSize = line.1 ? 28 : 18
            l.fontColor = line.1 ? ScenePalette.title : ScenePalette.muted
            l.position = CGPoint(x: size.width / 2, y: size.height * 0.74 - CGFloat(i) * 34)
            l.horizontalAlignmentMode = .center
            l.zPosition = 11
            addChild(l)
            loadMenuNodes.append(l)
        }
    }

    private func hideLoadMenu() {
        for node in loadMenuNodes {
            node.removeFromParent()
        }
        loadMenuNodes.removeAll()
        showingLoadMenu = false
        showingSettings = false
    }

    private func handleTap(at location: CGPoint) {
        let nodes = self.nodes(at: location)

        if showingSettings {
            hideLoadMenu()
            return
        }
        if showingLoadMenu {
            let slots = SaveManager.shared.listSlots()
            for node in nodes {
                guard let name = node.name else { continue }
                for i in 1...3 {
                    if name == "loadSlot\(i)" && slots[i - 1] != nil {
                        onLoadGame?(i)
                        return
                    }
                }
            }
            return
        }

        for node in nodes {
            if node.name == "newGame" {
                onNewGame?()
            } else if node.name == "loadGame" {
                showLoadMenu()
            } else if node.name == "settings" {
                showSettings()
            } else if node.name == "quit" {
                #if os(macOS)
                NSApplication.shared.terminate(nil)
                #endif
            }
        }
    }

    #if os(macOS)
    override func mouseDown(with event: NSEvent) {
        handleTap(at: event.location(in: self))
    }
    #else
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        handleTap(at: touch.location(in: self))
    }
    #endif

    #if os(macOS)
    private weak var hovered: SKShapeNode?

    /// Hover: the capsule under the pointer grows a little, lightens, and the cursor turns to a hand.
    override func mouseMoved(with event: NSEvent) {
        let hit = showingLoadMenu || showingSettings ? nil :
            nodes(at: event.location(in: self)).compactMap { $0 as? SKShapeNode }.first { $0.parent === self && $0.name != nil }
        guard hit !== hovered else { return }
        if let old = hovered {
            old.run(.scale(to: 1.0, duration: 0.12))
            old.fillColor = old.userData?["fill"] as? SKColor ?? old.fillColor
        }
        hovered = hit
        if let new = hit {
            new.run(.scale(to: 1.05, duration: 0.12))
            let base = new.userData?["fill"] as? SKColor ?? new.fillColor
            new.fillColor = base.blended(withFraction: 0.18, of: .white) ?? base
            NSCursor.pointingHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 && (showingLoadMenu || showingSettings) {
            hideLoadMenu()
        }
    }
    #endif
}

extension GameState {
    /// A throwaway city that runs behind the menu. It never autosaves and skips the tutorial.
    static func menuBackdrop() -> GameState {
        let state = GameState()
        state.autoSaveEnabled = false
        state.tutorialStep = nil
        state.isMenuBackdrop = true
        return state
    }
}

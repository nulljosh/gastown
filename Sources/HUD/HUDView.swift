import SwiftUI

struct HUDView: View {
    @Bindable var gameState: GameState

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear.allowsHitTesting(false)

            // Resource bar
            VStack(spacing: 0) {
                ResourceBar(gameState: gameState)
                    .padding(8)
                Spacer()
            }

            // Build menu
            if gameState.showBuildMenu {
                HStack {
                    BuildMenu(gameState: gameState)
                        .padding(8)
                        .allowsHitTesting(true)
                    Spacer()
                }
                .padding(.top, 50)
            }

            // Colonist panel
            if gameState.selectedColonist != nil {
                HStack {
                    Spacer()
                    ColonistPanel(gameState: gameState)
                        .padding(8)
                        .allowsHitTesting(true)
                }
                .padding(.top, 50)
            }

            // Game log + minimap row
            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    gameLogView
                        .padding(8)
                    Spacer()
                    MiniMap(gameState: gameState)
                        .padding(8)
                }
                .padding(.bottom, 110)
            }

            // Pause overlay
            if gameState.isPaused && !gameState.showSettings {
                Color.black.opacity(0.45)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                VStack(spacing: 12) {
                    Text("PAUSED")
                        .font(.nyc(size: 36, weight: .bold))
                        .foregroundStyle(Theme.text1)
                    GlassButton(label: "RESUME", isPrimary: true) { gameState.isPaused = false }
                    GlassButton(label: "SETTINGS") {
                        gameState.showSettings = true
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .allowsHitTesting(true)
            }

            // Time display
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("Day \(gameState.currentTick / NeedsSystem.ticksPerDay + 1) | \(gameState.currentHour):00 | \(gameState.isNight ? "NIGHT" : "DAY")")
                        .font(.nyc(size: 10))
                        .foregroundStyle(Theme.text3)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(.ultraThinMaterial))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 0.5))
                        .padding(8)
                }
                .padding(.bottom, 110)
            }

            if gameState.victoryShown {
                VStack(spacing: 8) {
                    Text("TIMES SQUARE RECLAIMED")
                        .font(.nyc(size: 28, weight: .bold))
                        .foregroundStyle(Theme.accent)
                    Text("Day \(gameState.currentTick / NeedsSystem.ticksPerDay). \(gameState.colonists.filter { !$0.isDead }.count) survivors. Keep playing or start a new game.")
                        .font(.nyc(size: 13))
                        .foregroundStyle(Theme.text1)
                    Button("Keep playing") { gameState.victoryShown = false; gameState.isPaused = false }
                        .buttonStyle(.borderedProminent)
                }
                .padding(24)
                .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Save indicator
            if gameState.showSaveIndicator {
                VStack {
                    HStack {
                        Spacer()
                        Text("SAVED")
                            .font(.nyc(size: 12, weight: .bold))
                            .foregroundStyle(Theme.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.glass))
                            .overlay(Capsule().stroke(Theme.green.opacity(0.4), lineWidth: 1))
                            .padding(8)
                    }
                    Spacer()
                }
            }

            // Auto-save dot
            if gameState.autoSaveEnabled && gameState.lastSaveSlot != nil {
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Theme.green)
                            .frame(width: 6, height: 6)
                            .padding(.trailing, 12)
                            .padding(.top, gameState.showSaveIndicator ? 44 : 12)
                    }
                    Spacer()
                }
            }

            // Bottom toolbar
            VStack {
                Spacer()

                // Main toolbar
                HStack(spacing: 8) {
                    toolbarPill(label: gameState.isPaused ? "PLAY" : "PAUSE") {
                        gameState.isPaused.toggle()
                    }
                    toolbarPill(label: "BUILD", isActive: gameState.showBuildMenu) {
                        gameState.showBuildMenu.toggle()
                        if !gameState.showBuildMenu {
                            gameState.inputMode = .normal
                            gameState.selectedBuildingType = nil
                        }
                        TutorialView.checkAdvance(gameState: gameState, event: .buildMenuOpened)
                    }
                    toolbarPill(label: "SETTINGS", isActive: gameState.showSettings) {
                        gameState.showSettings.toggle()
                        if gameState.showSettings { gameState.isPaused = true }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .liquidGlass(in: Rectangle(), fallback: .ultraThinMaterial)
                .overlay(alignment: .top) { Theme.border.frame(height: 1) }
                .allowsHitTesting(true)
            }

            // Settings overlay
            if gameState.showSettings {
                SettingsView(gameState: gameState).allowsHitTesting(true)
            }

            // First-launch controls card (once per device, after the tutorial)
            ControlsHintView(gameState: gameState)

            // Tutorial overlay
            if gameState.tutorialStep != nil {
                TutorialView(gameState: gameState).allowsHitTesting(true)
            }
        }
    }

    private var gameLogView: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(gameState.gameLog.suffix(3).enumerated()), id: \.offset) { _, msg in
                Text(msg)
                    .font(.nyc(size: 11))
                    .foregroundStyle(Theme.text1)
            }
        }
        .padding(8)
        .frame(maxWidth: 280, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.radius).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.border, lineWidth: 0.5))
    }

    private func toolbarPill(label: String, isActive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.nyc(size: 11, weight: .bold))
                .foregroundStyle(isActive ? .white : Theme.text2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(minHeight: 36)
                .background(
                    Capsule()
                        .fill(isActive ? Theme.accent.opacity(0.35) : Theme.glass)
                        .overlay(Capsule().stroke(isActive ? Theme.accent : Theme.border, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }
}


/// One-time card that lists the controls after the tutorial ends (or is skipped).
/// Shown once per device; "GOT IT" sets the flag. Matches docs/CONTROLS.md and the
/// Settings list. Never shown during App Store screenshot runs (`-shot`).
struct ControlsHintView: View {
    @Bindable var gameState: GameState
    @AppStorage("nyc-controls-hint-seen") private var seen = false

    private static let isScreenshotRun = ProcessInfo.processInfo.arguments.contains("-shot")

    private struct Row: Identifiable {
        let key: String
        let action: String
        var id: String { key }
    }

    #if os(macOS)
    private static let rows: [Row] = [
        Row(key: "WASD / Arrows", action: "Pan camera"),
        Row(key: "Scroll",        action: "Zoom in and out"),
        Row(key: "Click",         action: "Select, place or demolish"),
        Row(key: "B",             action: "Build menu"),
        Row(key: "1-6",           action: "Pick a building"),
        Row(key: "X",             action: "Demolish mode"),
        Row(key: "Space",         action: "Pause or resume"),
        Row(key: "Esc",           action: "Cancel, or open Settings"),
    ]
    #else
    private static let rows: [Row] = [
        Row(key: "Drag",          action: "Pan camera"),
        Row(key: "Pinch",         action: "Zoom in and out"),
        Row(key: "Tap",           action: "Select or place"),
        Row(key: "Tap, then tile", action: "Move selected colonist"),
    ]
    #endif

    private var visible: Bool {
        !seen && gameState.tutorialStep == nil && !gameState.showSettings && !Self.isScreenshotRun
    }

    var body: some View {
        if visible {
            VStack(alignment: .leading, spacing: 10) {
                Text("CONTROLS")
                    .font(.nyc(size: 11, weight: .bold))
                    .foregroundStyle(Theme.yellow)

                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Self.rows) { row in
                        HStack(spacing: 0) {
                            Text(row.key)
                                .font(.nyc(size: 11, weight: .bold))
                                .foregroundStyle(Theme.accent)
                                .frame(width: 150, alignment: .leading)
                            Text(row.action)
                                .font(.nyc(size: 11))
                                .foregroundStyle(Theme.text2)
                        }
                    }
                }

                HStack {
                    Text("Full list in SETTINGS")
                        .font(.nyc(size: 10))
                        .foregroundStyle(Theme.text3)
                    Spacer()
                    GlassButton(label: "GOT IT", isPrimary: true) { seen = true }
                }
                .padding(.top, 4)
            }
            .padding(16)
            .frame(width: 360)
            .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
            .padding(.bottom, 110)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
    }
}

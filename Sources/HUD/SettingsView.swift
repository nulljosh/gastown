import SwiftUI
#if os(macOS)
import AppKit
#endif

struct SettingsView: View {
    @Bindable var gameState: GameState
    @State private var themeChoice = Theme.choice
    #if os(macOS)
    @State private var isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
    #endif

    var body: some View {
        ZStack(alignment: .trailing) {
            Theme.scrim
                .ignoresSafeArea()
                .onTapGesture { close() }

            VStack(alignment: .leading, spacing: 16) {
                Text("SETTINGS")
                    .font(.nyc(size: 24, weight: .bold))
                    .foregroundStyle(Theme.cyan)

                Divider().background(Theme.border)

                Text("CONTROLS")
                    .font(.nyc(size: 11, weight: .bold))
                    .foregroundStyle(Theme.yellow)

                VStack(alignment: .leading, spacing: 8) {
                    controlRow(key: "Drag",       action: "Pan camera")
                    controlRow(key: "Pinch",      action: "Zoom in/out")
                    controlRow(key: "Tap",        action: "Select / place")
                    controlRow(key: "Tap, then tile", action: "Move selected colonist")
                    #if os(macOS)
                    controlRow(key: "WASD",       action: "Pan camera")
                    controlRow(key: "B",          action: "Build menu")
                    controlRow(key: "1-6",        action: "Select building")
                    controlRow(key: "Space",      action: "Pause")
                    controlRow(key: "Cmd+S",      action: "Save")
                    controlRow(key: "Esc",        action: "Cancel / deselect")
                    #endif
                }

                Divider().background(Theme.border)

                Text("OPTIONS")
                    .font(.nyc(size: 11, weight: .bold))
                    .foregroundStyle(Theme.yellow)

                Toggle(isOn: Binding(
                    get: { gameState.autoSaveEnabled },
                    set: { gameState.autoSaveEnabled = $0 }
                )) {
                    Text("Auto-save")
                        .font(.nyc(size: 13))
                        .foregroundStyle(Theme.text1)
                }
                .toggleStyle(.switch)
                .tint(Theme.accent)

                #if os(macOS)
                Toggle(isOn: Binding(
                    get: { isFullScreen },
                    set: { on in
                        isFullScreen = on
                        if NSApp.keyWindow?.styleMask.contains(.fullScreen) != on {
                            NSApp.keyWindow?.toggleFullScreen(nil)
                        }
                    }
                )) {
                    Text("Full screen")
                        .font(.nyc(size: 13))
                        .foregroundStyle(Theme.text1)
                }
                .toggleStyle(.switch)
                .tint(Theme.accent)
                #endif

                Toggle(isOn: Binding(
                    get: { gameState.soundEnabled },
                    set: { gameState.soundEnabled = $0 }
                )) {
                    Text("Sound effects")
                        .font(.nyc(size: 13))
                        .foregroundStyle(Theme.text1)
                }
                .toggleStyle(.switch)
                .tint(Theme.accent)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Appearance")
                        .font(.nyc(size: 13))
                        .foregroundStyle(Theme.text1)
                    Picker("Appearance", selection: $themeChoice) {
                        ForEach(ThemeChoice.allCases, id: \.self) { choice in
                            Text(choice.label).tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: themeChoice) { _, new in
                        Theme.choice = new
                    }
                }

                Divider().background(Theme.border)

                Text("SAVE / LOAD")
                    .font(.nyc(size: 11, weight: .bold))
                    .foregroundStyle(Theme.yellow)

                let slots = SaveManager.shared.listSlots()
                ForEach(0..<3, id: \.self) { i in
                    HStack {
                        if let slot = slots[i] {
                            Text("Slot \(i + 1), Day \(slot.dayCount)")
                                .font(.nyc(size: 12))
                                .foregroundStyle(Theme.text1)
                        } else {
                            Text("Slot \(i + 1), empty")
                                .font(.nyc(size: 12))
                                .foregroundStyle(Theme.text3)
                        }
                        Spacer()
                        Button("SAVE") {
                            NotificationCenter.default.post(
                                name: .performSaveToSlot,
                                object: nil,
                                userInfo: ["slot": i + 1]
                            )
                        }
                        .font(.nyc(size: 10, weight: .bold))
                        .foregroundStyle(Theme.accent)
                        .buttonStyle(.plain)
                    }
                }

                Spacer()

                Text("Tap outside to close")
                    .font(.nyc(size: 11))
                    .foregroundStyle(Theme.text3)
            }
            .padding(24)
            .frame(width: 300)
            .frame(maxHeight: .infinity)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .fill(.clear)
                    .border(Theme.border, width: 0)
            )
            .overlay(alignment: .leading) {
                Theme.border
                    .frame(width: 1)
            }
        }
    }

    private func controlRow(key: String, action: String) -> some View {
        HStack(spacing: 0) {
            Text(key)
                .font(.nyc(size: 11, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 110, alignment: .leading)
            Text(action)
                .font(.nyc(size: 11))
                .foregroundStyle(Theme.text2)
        }
    }

    private func close() {
        gameState.showSettings = false
        gameState.isPaused = false
    }
}

extension Notification.Name {
    static let performSaveToSlot = Notification.Name("performSaveToSlot")
}

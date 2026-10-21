import SwiftUI

struct TutorialView: View {
    @Bindable var gameState: GameState

    private var step: Int { gameState.tutorialStep ?? 0 }

    /// Mac players click; the copy is written for touch.
    private var stepData: (title: String, body: String, hint: String) {
        let d = touchCopy
        #if os(macOS)
        return (d.title, d.body.replacingOccurrences(of: "Tap", with: "Click"), d.hint.replacingOccurrences(of: "Tap", with: "Click"))
        #else
        return d
        #endif
    }

    private var touchCopy: (title: String, body: String, hint: String) {
        switch step {
        case 0: ("WELCOME",    "Welcome to NYC Survive. You control a group of survivors.",                           "Tap to continue")
        case 1: ("NEEDS",      "Colonists have NEEDS: hunger, oxygen, stress, sleep, health. Keep them alive.",      "Tap to continue")
        case 2: ("STATS",      "Each colonist has RPG STATS: STR, INT, AGI, END, CHA. Tap a figure.",               "Tap a colonist")
        case 3: ("CAMERA",     "WASD or arrows to pan, scroll to zoom. On touch, drag to pan, pinch to zoom.",                                               "Tap to continue")
        case 4: ("BUILD",      "Tap BUILD to open the build menu. Buildings keep your colony running.",               "Tap BUILD")
        case 5: ("SHELTER",    "Place a SHELTER to reduce stress and let colonists sleep.",                            "Place a shelter")
        case 6: ("COMMAND",    "Click a colonist (or drag a box around several). Click the ground to move them. Click a resource to gather it. Esc to deselect.", "Tap a colonist")
        case 7: ("UPKEEP",     "Every building burns materials. Let the pile hit zero and they break until you gather more.", "Tap to continue")
        case 8: ("RAIDS",      "Every third night scavengers rob the stockpile. Put a survivor on PATROL near your buildings and they turn back.", "Tap to continue")
        case 9: ("GOOD LUCK",  "Tap PAUSE to pause. Save from SETTINGS. Good luck.",                                   "Tap to dismiss")
        default: ("", "", "")
        }
    }

    private var isInteractiveStep: Bool { [2, 4, 5, 6].contains(step) }

    var body: some View {
        ZStack {
            Color.black.opacity(isInteractiveStep ? 0.3 : 0.55)
                .ignoresSafeArea()
                .allowsHitTesting(!isInteractiveStep)
                .onTapGesture { advance() }

            VStack(spacing: 14) {
                HStack {
                    Text("TUTORIAL \(step + 1)/10")
                        .font(.nyc(size: 10))
                        .foregroundStyle(Theme.text3)
                    Spacer()
                    Button(action: skip) {
                        Text("SKIP")
                            .font(.nyc(size: 11, weight: .bold))
                            .foregroundStyle(Theme.red)
                    }
                    .buttonStyle(.plain)
                }

                Text(stepData.title)
                    .font(.nyc(size: 22, weight: .bold))
                    .foregroundStyle(Theme.cyan)

                Text(stepData.body)
                    .font(.nyc(size: 13))
                    .foregroundStyle(Theme.text1)
                    .multilineTextAlignment(.center)

                Text(stepData.hint)
                    .font(.nyc(size: 11))
                    .foregroundStyle(Theme.yellow)
                    .opacity(hintPulse ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: hintPulse)
                    .onAppear { hintPulse = true; startTimer() }
                    .onChange(of: step) { startTimer() }

                HStack(spacing: 6) {
                    ForEach(0..<10, id: \.self) { i in
                        Circle()
                            .fill(i <= step ? Theme.accent : Theme.glass)
                            .frame(width: 7, height: 7)
                    }
                }
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
            // "Tap to continue" means the card too, not only the dimmed area around it.
            .contentShape(RoundedRectangle(cornerRadius: Theme.radiusLg))
            .onTapGesture { if !isInteractiveStep { advance() } }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: isInteractiveStep ? .top : .center)
            .padding(.top, isInteractiveStep ? 60 : 0)
        }
    }

    @State private var hintPulse = false
    @State private var timerTask: Task<Void, Never>?

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            // Reading steps move on by themselves; steps that wait for the player (pick a colonist,
            // open BUILD, place a shelter) never skip ahead of them.
            guard !Task.isCancelled, gameState.tutorialStep != nil, !isInteractiveStep else { return }
            advance()
        }
    }

    private func advance() {
        gameState.tutorialStep = step >= 9 ? nil : step + 1
    }

    private func skip() {
        gameState.tutorialStep = nil
    }

    static func checkAdvance(gameState: GameState, event: TutorialEvent) {
        guard let step = gameState.tutorialStep else { return }
        switch (step, event) {
        case (2, .colonistSelected): gameState.tutorialStep = 3
        case (3, .cameraPanned):     gameState.tutorialStep = 4
        case (4, .buildMenuOpened):  gameState.tutorialStep = 5
        case (5, .shelterPlaced):    gameState.tutorialStep = 6
        case (6, .colonistSelected): gameState.tutorialStep = 7
        default: break
        }
    }
}

enum TutorialEvent {
    case colonistSelected
    case cameraPanned
    case buildMenuOpened
    case shelterPlaced
    case wasdPressed
}

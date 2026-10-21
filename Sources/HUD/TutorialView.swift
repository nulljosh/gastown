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
        case 0: ("COMMAND",    "Tap a survivor, or drag a box around several. Tap the ground to move them. Tap a resource and they work it until you say otherwise.", "Tap a colonist")
        case 1: ("BUILD",      "Open BUILD. A Generator makes power. A Drill next to a resource mines it for you, burning power. Shelters add beds, and a bed plus 10 food brings a new survivor each day.", "Tap BUILD")
        case 2: ("THE BEACON", "Gather materials and power, then raise the Beacon. That is the whole game.", "Tap to dismiss")
        default: ("", "", "")
        }
    }

    private var isInteractiveStep: Bool { [0, 1].contains(step) }

    var body: some View {
        ZStack {
            Color.black.opacity(isInteractiveStep ? 0.3 : 0.55)
                .ignoresSafeArea()
                .allowsHitTesting(!isInteractiveStep)
                .onTapGesture { advance() }

            VStack(spacing: 14) {
                HStack {
                    Text("TUTORIAL \(step + 1)/3")
                        .font(.gastown(size: 10))
                        .foregroundStyle(Theme.text3)
                    Spacer()
                    Button(action: skip) {
                        Text("SKIP")
                            .font(.gastown(size: 11, weight: .bold))
                            .foregroundStyle(Theme.red)
                    }
                    .buttonStyle(.plain)
                }

                Text(stepData.title)
                    .font(.gastown(size: 22, weight: .bold))
                    .foregroundStyle(Theme.cyan)

                Text(stepData.body)
                    .font(.gastown(size: 13))
                    .foregroundStyle(Theme.text1)
                    .multilineTextAlignment(.center)

                Text(stepData.hint)
                    .font(.gastown(size: 11))
                    .foregroundStyle(Theme.yellow)
                    .opacity(hintPulse ? 1.0 : 0.4)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: hintPulse)
                    .onAppear { hintPulse = true; startTimer() }
                    .onChange(of: step) { startTimer() }

                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
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
        gameState.tutorialStep = step >= 2 ? nil : step + 1
    }

    private func skip() {
        gameState.tutorialStep = nil
    }

    static func checkAdvance(gameState: GameState, event: TutorialEvent) {
        guard let step = gameState.tutorialStep else { return }
        switch (step, event) {
        case (0, .colonistSelected): gameState.tutorialStep = 1
        case (1, .buildMenuOpened):  gameState.tutorialStep = 2
        default: break
        }
    }
}

enum TutorialEvent {
    case colonistSelected
    case buildMenuOpened
    case wasdPressed
}

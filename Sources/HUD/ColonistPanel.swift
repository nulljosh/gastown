import SwiftUI

struct ColonistPanel: View {
    let gameState: GameState

    var body: some View {
        if let colonist = gameState.selectedColonist {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(colonist.name)
                        .font(.nyc(size: 15, weight: .bold))
                        .foregroundStyle(Theme.yellow)
                    Spacer()
                    Text("Lv.\(colonist.level)")
                        .font(.nyc(size: 11, weight: .bold))
                        .foregroundStyle(Theme.cyan)
                }

                Text(colonist.state.rawValue.uppercased())
                    .font(.nyc(size: 10, weight: .semibold))
                    .foregroundStyle(stateColor(colonist.state))

                Divider().background(Theme.border)

                vitalBar(label: "HP",  value: colonist.health)
                vitalBar(label: "HNG", value: colonist.hunger)
                vitalBar(label: "O2",  value: colonist.oxygen)
                vitalBar(label: "STS", value: 100 - colonist.stress)
                vitalBar(label: "SLP", value: colonist.sleep)

                Divider().background(Theme.border)

                Text("JOB: \(colonist.job.rawValue.uppercased())")
                    .font(.nyc(size: 9, weight: .bold))
                    .foregroundStyle(Theme.text2)

                HStack(spacing: 4) {
                    ForEach(ColonistJob.allCases, id: \.self) { job in
                        jobPill(job: job, isActive: colonist.job == job)
                    }
                }
            }
            .padding(10)
            .frame(width: 220)
            .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
        }
    }

    private func vitalBar(label: String, value: Double) -> some View {
        let v = max(0, min(100, value))
        return HStack(spacing: 6) {
            Text(label)
                .font(.nyc(size: 9))
                .foregroundStyle(Theme.text2)
                .frame(width: 28, alignment: .leading)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Theme.glass).frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Theme.vitalColor(v))
                        .frame(width: max(0, geo.size.width * v / 100), height: 4)
                }
            }
            .frame(height: 4)
            Text("\(Int(value))")
                .font(.nyc(size: 9))
                .foregroundStyle(Theme.text3)
                .frame(width: 22, alignment: .trailing)
        }
    }

    private func jobPill(job: ColonistJob, isActive: Bool) -> some View {
        Button(action: {
            guard let id = gameState.selectedColonistId,
                  let idx = gameState.colonists.firstIndex(where: { $0.id == id }) else { return }
            gameState.colonists[idx].job = job
        }) {
            Text(job.rawValue.prefix(4).uppercased())
                .font(.nyc(size: 9, weight: .bold))
                .foregroundStyle(isActive ? .white : Theme.text2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(isActive ? Theme.accent.opacity(0.35) : Theme.glass)
                        .overlay(Capsule().stroke(isActive ? Theme.accent : Theme.border, lineWidth: 1))
                )
        }
        .buttonStyle(.plain)
    }

    private func stateColor(_ state: ColonistState) -> Color {
        switch state {
        case .healthy: Theme.green
        case .hungry: Theme.yellow
        case .suffocating: Theme.cyan
        case .exhausted: Theme.orange
        case .dead: .gray
        }
    }
}

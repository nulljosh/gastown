import SwiftUI

struct BuildMenu: View {
    @Bindable var gameState: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("BUILD")
                .font(.nyc(size: 11, weight: .bold))
                .foregroundStyle(Theme.yellow)
                .padding(.bottom, 4)

            ForEach(Array(BuildingType.allCases.enumerated()), id: \.offset) { i, type in
                Button {
                    gameState.selectedBuildingType = type
                    gameState.inputMode = .build
                } label: {
                    let isSelected = gameState.selectedBuildingType == type
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(i + 1). \(type.displayName)")
                            .font(.nyc(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.text1)
                        HStack(spacing: 4) {
                            ForEach(Array(type.cost.sorted(by: { $0.key.rawValue < $1.key.rawValue })), id: \.key) { resource, amount in
                                Text("\(resource.symbol)\(amount)")
                                    .font(.nyc(size: 9))
                                    .foregroundStyle(Theme.text3)
                            }
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 40)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radius)
                            .fill(isSelected ? Theme.accent.opacity(0.25) : Theme.glass)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.radius)
                                    .stroke(isSelected ? Theme.accent.opacity(0.6) : Color.clear, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().background(Theme.border)

            Button {
                gameState.inputMode = .demolish
            } label: {
                Text("DEMOLISH")
                    .font(.nyc(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 40)
                    .background(
                        RoundedRectangle(cornerRadius: Theme.radius)
                            .fill(gameState.inputMode == .demolish ? Theme.red.opacity(0.2) : Theme.glass)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .frame(width: 200)
        .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
    }
}

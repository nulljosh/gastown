import SwiftUI

struct ResourceBar: View {
    let gameState: GameState

    // Five pills plus the colonist count overflow a compact iPhone width, and the
    // Texts were wrapping mid-word ("FOO / D", "CAS / H"). The icon and colour already
    // identify the resource, so the word is what gives way when space is tight.
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    private var showsWordLabels: Bool { sizeClass != .compact }
    #else
    private var showsWordLabels: Bool { true }
    #endif

    var body: some View {
        HStack(spacing: 4) {
            ForEach([ResourceType.food, .power, .materials, .oxygen, .cash], id: \.self) { type in
                resourcePill(type: type)
            }
            Spacer()
            Text("\(gameState.colonists.filter { !$0.isDead }.count) alive")
                .font(.nyc(size: 11, weight: .bold))
                .foregroundStyle(Theme.text2)
                .fixedSize()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
    }

    private func resourcePill(type: ResourceType) -> some View {
        let meta = resourceMeta[type]
        let color = meta?.color ?? Theme.text2
        let label = meta?.label ?? type.rawValue.uppercased()
        let iconName = meta?.icon ?? "circle"

        return HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.nyc(size: 10, weight: .semibold))
                .foregroundStyle(color)
                .accessibilityLabel(label)
            Text("\(gameState.resources[type, default: 0])")
                .font(.nyc(size: 12, weight: .semibold))
                .foregroundStyle(Theme.text1)
                .fixedSize()
            if showsWordLabels {
                Text(label)
                    .font(.nyc(size: 9, weight: .medium))
                    .foregroundStyle(Theme.text3)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(Theme.glass).overlay(Capsule().stroke(Theme.border, lineWidth: 0.5)))
    }
}

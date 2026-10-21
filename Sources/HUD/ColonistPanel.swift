import SwiftUI

struct ColonistPanel: View {
    let gameState: GameState

    private var picked: Int {
        var ids = gameState.selectedColonistIds
        if let id = gameState.selectedColonistId { ids.insert(id) }
        return ids.count
    }

    var body: some View {
        if picked > 0 {
            VStack(alignment: .leading, spacing: 6) {
                Text(picked > 1 ? "\(picked) SELECTED" : (gameState.selectedColonist?.name ?? ""))
                    .font(.gastown(size: 15, weight: .bold))
                    .foregroundStyle(Theme.yellow)
                Text(picked == 1 && gameState.selectedColonist != nil
                     ? gameState.selectedColonist!.job.rawValue.uppercased()
                     : "Click ground to move, a resource to gather")
                    .font(.gastown(size: 10, weight: .semibold))
                    .foregroundStyle(Theme.text2)
            }
            .padding(10)
            .frame(width: 220, alignment: .leading)
            .liquidGlass(in: RoundedRectangle(cornerRadius: Theme.radiusLg), fallback: .ultraThinMaterial)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
        }
    }
}

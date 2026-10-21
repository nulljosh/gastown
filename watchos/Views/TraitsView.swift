import SwiftUI

/// Colonist traits, ported from `ColonistTrait` so a player can look up what a trait
/// they just rolled actually does without pausing the main game.
struct TraitsView: View {
    var body: some View {
        NavigationStack {
            List(ColonistTrait.allCases, id: \.self) { trait in
                VStack(alignment: .leading, spacing: 2) {
                    Text(trait.displayName)
                        .font(.headline)
                    Text(trait.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Traits")
        }
    }
}

import SwiftUI

/// Build costs and effects, the same reference a player checks mid-game before placing
/// a building. Static data ported from `BuildingType` -- no live save state on the watch.
struct BuildingsView: View {
    var body: some View {
        NavigationStack {
            List(BuildingType.allCases, id: \.self) { building in
                VStack(alignment: .leading, spacing: 2) {
                    Text(building.displayName)
                        .font(.headline)
                    Text(building.costText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(building.description)
                        .font(.caption2)
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Buildings")
        }
    }
}

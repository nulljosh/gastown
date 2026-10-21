import Foundation
import SwiftTUI

// ponytail: quick-reference, not a live game — same scope as watchos/ (see its
// CLAUDE.md: "not a live-save mirror, a quick reference ported from Sources/Models/").
// The real sim runs on GameScene's SpriteKit tick loop, not worth porting for a pilot.
// `nyc-tui` lists building costs/effects from BuildingType, same data the build menu shows.

struct BuildingRow: Identifiable {
    var id: String { type.rawValue }
    let type: BuildingType
}

struct ReferenceCard: View {
    let rows = BuildingType.allCases.map(BuildingRow.init)

    var body: some View {
        VStack(alignment: .leading) {
            Text("NYC Survive — buildings").bold()
            ForEach(rows) { row in
                let cost = row.type.cost.map { "\($0.value)\($0.key.symbol)" }.joined(separator: " ")
                Text("\(row.type.displayName): \(cost) — \(row.type.description)")
            }
        }
        .padding()
        .border()
    }
}

Application(rootView: ReferenceCard()).start()

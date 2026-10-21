import SwiftUI

/// Weapon stats, ported from `WeaponType`, for checking damage/range without leaving
/// the fight to dig through the phone or Mac app.
struct WeaponsView: View {
    var body: some View {
        NavigationStack {
            List(WeaponType.allCases, id: \.self) { weapon in
                HStack {
                    Text(weapon.displayName)
                        .font(.headline)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("DMG \(Int(weapon.damage))")
                            .font(.caption2)
                        Text("RNG \(weapon.range)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 2)
            }
            .navigationTitle("Weapons")
        }
    }
}

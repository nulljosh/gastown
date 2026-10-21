import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BuildingsView()
            TraitsView()
            WeaponsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

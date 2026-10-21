import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            BuildingsView()
        }
        .tabViewStyle(.verticalPage)
    }
}

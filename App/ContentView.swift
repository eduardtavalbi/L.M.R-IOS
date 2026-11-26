import SwiftUI

enum AppTab: Hashable {
    case library
    case learning
    case sets
    case ai
    case profile
}

struct ContentView: View {
    @ObservedObject var store: LibraryStore
    @State private var selectedTab: AppTab = .library

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(store: store)
                .tabItem { Label("Главная", systemImage: "books.vertical") }
                .tag(AppTab.library)

            PlaceholderView(title: "Обучение", symbol: "brain.head.profile")
                .tabItem { Label("Обучение", systemImage: "brain.head.profile") }
                .tag(AppTab.learning)

            PlaceholderView(title: "Наборы", symbol: "square.grid.2x2")
                .tabItem { Label("Наборы", systemImage: "square.grid.2x2") }
                .tag(AppTab.sets)

            PlaceholderView(title: "AI", symbol: "sparkles")
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(AppTab.ai)

            PlaceholderView(title: "Профиль", systemImage: "person.crop.circle")
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
    }
}

struct PlaceholderView: View {
    let title: String
    let symbol: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(title, systemImage: symbol, description: Text("Этот раздел скоро появится."))
                .navigationTitle(title)
        }
    }
}

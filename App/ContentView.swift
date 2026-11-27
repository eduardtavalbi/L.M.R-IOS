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
    @State private var showingOnboarding = false
    @AppStorage("lmr.onboarding.completed") private var onboardingCompleted = false

    var body: some View {
        TabView(selection: $selectedTab) {
            LibraryView(store: store)
                .tabItem { Label("Главная", systemImage: "books.vertical") }
                .tag(AppTab.library)

            LearningView(store: store)
                .tabItem { Label("Обучение", systemImage: "brain.head.profile") }
                .tag(AppTab.learning)

            SetsView(store: store)
                .tabItem { Label("Наборы", systemImage: "square.grid.2x2") }
                .tag(AppTab.sets)

            AIGenerationView(store: store)
                .tabItem { Label("AI", systemImage: "sparkles") }
                .tag(AppTab.ai)

            ProfileView(store: store)
                .tabItem { Label("Профиль", systemImage: "person.crop.circle") }
                .tag(AppTab.profile)
        }
        .fullScreenCover(isPresented: $showingOnboarding) {
            FirstRunOnboardingView(store: store) {
                onboardingCompleted = true
                showingOnboarding = false
            }
        }
        .onAppear {
            if !store.languages.isEmpty {
                onboardingCompleted = true
            }
            showingOnboarding = !onboardingCompleted
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

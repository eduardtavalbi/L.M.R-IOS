import SwiftUI

@main
struct LMRApp: App {
    @StateObject private var store = LibraryStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
    }
}

import SwiftUI

@main
struct RosolekApp: App {
    @StateObject private var batchStore = BatchStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(batchStore)
        }
    }
}

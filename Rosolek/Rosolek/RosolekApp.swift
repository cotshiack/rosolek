import SwiftUI

@main
struct RosolekApp: App {
    @StateObject private var batchStore = BatchStore()
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(batchStore)
                .environmentObject(router)
                .onOpenURL { url in
                    if url.scheme == "rosolek", url.host == "cooking" {
                        router.routeToActiveCooking()
                    }
                }
        }
    }
}

import SwiftUI
import Foundation

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
                        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                        let batchID = components?.queryItems?
                            .first(where: { $0.name == "batchID" })?
                            .value
                            .flatMap(UUID.init(uuidString:))
                        router.routeToActiveCooking(batchID: batchID)
                    }
                }
        }
    }
}

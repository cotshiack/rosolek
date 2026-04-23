import SwiftUI

@main
struct RosolekApp: App {
    @StateObject private var batchStore = BatchStore()
    @AppStorage("returnToHomeTrigger") private var returnToHomeTrigger = 0
    @AppStorage("openActiveCookingTrigger") private var openActiveCookingTrigger = 0

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(batchStore)
                .onOpenURL { url in
                    if url.scheme == "rosolek", url.host == "cooking" {
                        returnToHomeTrigger += 1
                        openActiveCookingTrigger += 1
                    }
                }
        }
    }
}

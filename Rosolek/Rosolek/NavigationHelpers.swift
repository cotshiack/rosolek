import SwiftUI
import Combine
import Foundation

enum HomeRouteIntent: Equatable {
    case openActiveCooking(batchID: UUID?)
}

final class AppRouter: ObservableObject {
    @Published var pendingHomeRoute: HomeRouteIntent?
    @Published var returnToHomeTrigger = 0

    func routeToActiveCooking(batchID: UUID? = nil) {
        pendingHomeRoute = .openActiveCooking(batchID: batchID)
    }

    func consumeHomeRoute() {
        pendingHomeRoute = nil
    }

    func triggerReturnToHome() {
        returnToHomeTrigger += 1
    }
}

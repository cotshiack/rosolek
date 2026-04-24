import SwiftUI
import Combine
import Foundation

enum HomeRouteIntent: Equatable {
    case openActiveCooking(batchID: UUID?)
}

final class AppRouter: ObservableObject {
    @Published var pendingHomeRoute: HomeRouteIntent?

    func routeToActiveCooking(batchID: UUID? = nil) {
        pendingHomeRoute = .openActiveCooking(batchID: batchID)
    }

    func consumeHomeRoute() {
        pendingHomeRoute = nil
    }
}

extension View {
    func cascadesReturnHome() -> some View {
        self
    }
}

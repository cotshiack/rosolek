import SwiftUI
import Combine

enum HomeRouteIntent: Equatable {
    case openActiveCooking
}

final class AppRouter: ObservableObject {
    @Published var pendingHomeRoute: HomeRouteIntent?

    func routeToActiveCooking() {
        pendingHomeRoute = .openActiveCooking
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

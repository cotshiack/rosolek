import Foundation
import ActivityKit

struct CookingSession: Codable {
    let batchID: UUID
    var phaseIndex: Int
    var phaseElapsedSeconds: Int
    var processElapsedSeconds: Int
    var isStageRunning: Bool
    var prepMeatReady: Bool
    var prepWaterReady: Bool
    var prepPotReady: Bool
    var prepThermometerReady: Bool
    var prepVinegarReady: Bool
    var backgroundedAt: Date?
    var currentPhaseTitle: String?
    var currentPhaseTotalSeconds: Int?
    var overallRemainingSeconds: Int?

    private static let storageKey = "cooking_session_active_v1"

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    static func load() -> CookingSession? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let session = try? JSONDecoder().decode(CookingSession.self, from: data)
        else { return nil }
        return session
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
}

struct ActiveCookingConflict {
    let batchID: UUID
    let title: String
}

enum CookingSessionCoordinator {
    static func activeConflict(in batchStore: BatchStore) -> ActiveCookingConflict? {
        guard let session = CookingSession.load(),
              let batch = batchStore.batch(for: session.batchID)
        else {
            return nil
        }

        return ActiveCookingConflict(batchID: batch.id, title: batch.displayTitle)
    }

    static func clearOrphanedSessionIfNeeded(in batchStore: BatchStore) {
        guard let session = CookingSession.load() else { return }
        guard batchStore.batch(for: session.batchID) == nil else { return }
        CookingSession.clear()
        CookingNotificationService.shared.cancelAll()
    }

    static func interruptActiveCookingAndCleanup(in batchStore: BatchStore) {
        if let conflict = activeConflict(in: batchStore) {
            batchStore.markBatchInterruptedByNewCooking(batchID: conflict.batchID)
        }
        CookingSession.clear()
        CookingNotificationService.shared.cancelAll()
        endAllLiveActivities()
    }

    static func activeBatch(in batchStore: BatchStore) -> BatchRecord? {
        guard let session = CookingSession.load() else { return nil }
        return batchStore.batch(for: session.batchID)
    }

    private static func endAllLiveActivities() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let finalState = CookingActivityAttributes.ContentState(
            stepName: "Gotowanie przerwane",
            stepNumber: 0,
            totalSteps: 1,
            stepEndDate: nil,
            totalEndDate: nil,
            totalProgress: 0,
            isRunning: false
        )

        Task {
            for activity in Activity<CookingActivityAttributes>.activities {
                await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
            }
        }
    }
}

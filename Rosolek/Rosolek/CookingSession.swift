import Foundation

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

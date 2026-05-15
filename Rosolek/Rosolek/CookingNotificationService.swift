import Foundation
import UserNotifications

final class CookingNotificationService {
    static let shared = CookingNotificationService()
    private init() {}

    private let phaseEndID = "rosolek.phase.end"

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func schedulePhaseEnd(stepTitle: String, inSeconds seconds: Int, brothKindTitle: String) {
        guard seconds > 0 else { return }

        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = "\(brothKindTitle): Etap zakończony"
        content.body = "\(stepTitle) — czas na następny krok"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: phaseEndID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [phaseEndID])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [phaseEndID])
    }
}

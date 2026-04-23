import Foundation
import UserNotifications

final class CookingNotificationService {
    static let shared = CookingNotificationService()
    private init() {}

    private let phaseEndID = "rosolek.phase.end"

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func schedulePhaseEnd(stepTitle: String, inSeconds seconds: Int) {
        guard seconds > 0 else { return }

        cancelAll()

        let content = UNMutableNotificationContent()
        content.title = "Rosół: Etap zakończony"
        content.body = "\(stepTitle) — czas na następny krok"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        let request = UNNotificationRequest(identifier: phaseEndID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func notifyActionRequired(stepTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Rosół: Twoja akcja"
        content.body = "\(stepTitle) — sprawdź garnek"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [phaseEndID])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [phaseEndID])
    }
}

import Foundation
import ActivityKit

struct CookingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var stepName: String
        var stepNumber: Int
        var totalSteps: Int
        var stepEndDate: Date?
        var totalEndDate: Date?
        var isRunning: Bool
    }

    let batchTitle: String
}

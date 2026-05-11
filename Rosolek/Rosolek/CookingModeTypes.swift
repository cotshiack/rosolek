import Foundation

enum TimelineStepState {
    case done
    case active
    case next
    case upcoming
}

enum LivePhaseKind {
    case prep
    case heatUp
    case stabilization
    case addVegetables
    case simmerToPoultryOut
    case removePoultry
    case simmerToVegetablesOut
    case removeVegetables
    case finishBase
    case addLiver
    case finishWithLiver
    case beginRest
    case rest
    case strainAndSeason
    case optionalClarityTip
}

struct LivePhase: Identifiable {
    let id = UUID()
    var stepID: String? = nil
    let kind: LivePhaseKind
    let title: String
    let shortText: String
    let detailText: String
    let durationSeconds: Int?
    let timelineLabel: String
    let bottomActionTitle: String?

    func withStepID(_ stepID: String) -> LivePhase {
        var copy = self
        copy.stepID = stepID
        return copy
    }
}

enum LiveIngredientIconKind: Hashable {
    case carrot
    case celery
    case parsleyRoot
    case leek
    case onion
    case salt
    case pepper
    case bayLeaf
    case allspice
    case vinegar
    case generic
}

struct LiveIngredientReminderRowData: Hashable {
    let icon: LiveIngredientIconKind
    let title: String
    let subtitle: String?
    let value: String
}

func normalizeCookingID(_ value: String) -> String {
    value.normalizedForMatching()
}

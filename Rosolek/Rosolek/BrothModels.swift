import Foundation

struct VegetableAmount: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let amount: String
    let note: String?
}

struct MeatAmount: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let grams: Int
    let note: String?
}

struct CookingTimelineItem: Identifiable, Hashable {
    let id = UUID()
    let minuteOffset: Int
    let timeLabel: String
    let title: String
    let subtitle: String?
}

enum BrothClarityMode: String, CaseIterable, Hashable {
    case normal
    case paperFilter

    var title: String {
        switch self {
        case .normal:
            return "Standard"
        case .paperFilter:
            return "Filtr papierowy"
        }
    }

    var subtitle: String {
        switch self {
        case .normal:
            return "Większy uzysk i pełniejszy smak."
        case .paperFilter:
            return "Czystszy rosół, ale mniejszy uzysk i lżejszy efekt."
        }
    }
}

enum BrothWarningSeverity: String, Hashable {
    case info
    case warn
    case error
}

enum BrothWarningCode: String, Hashable {
    case hardPotTooSmall
    case hardPotTooBig
    case hardTooMuchMeat
    case hardItemTooBig
    case hardNoMeat
    case hardNotFit
    case premiumBlocked

    case undermeatLight
    case overmeatLight
    case undermeatIntense
    case overmeatIntense

    case overfatLight
    case wingsTooHighLight
    case lowGelatinIntense
    case heavyBeefProfile
    case marrowTooHigh

    case singleIngredientRisk
    case offalDominantRisk
    case liverTimingRequired

    case paperFilterLowerIntensity
    case paperFilterHighLoss
    case waterReducedToFit
    case baseTooLowForWater
    case baseTooHighForWater
}

struct BrothWarningParameter: Hashable {
    let key: String
    let value: Double
}

struct BrothWarning: Hashable {
    let code: BrothWarningCode
    let severity: BrothWarningSeverity
    let params: [BrothWarningParameter]
}

struct BrothValidationFailure: Hashable {
    let code: BrothWarningCode
    let messageFallback: String
}

struct BrothRecommendedMeatRange: Hashable {
    let minGrams: Int
    let maxGrams: Int?
}

struct BrothVegetableBreakdown: Hashable {
    let totalGrams: Int
    let carrotGrams: Int
    let celeriacGrams: Int
    let parsleyRootGrams: Int
    let leekGrams: Int
    let onionCount: Int
}

struct BrothSpiceBreakdown: Hashable {
    let peppercornCount: Int
    let allspiceCount: Int
    let bayLeafCount: Int
}

struct BrothScoring: Hashable {
    let fatIndex: Double
    let collagenIndex: Double
    let boneShare: Double
    let meatDensityGL: Double
    let oneIngredientShare: Double
    let wingsShare: Double
    let beefShare: Double
    let offalShare: Double
    let marrowHeavyBeefShare: Double
}

struct BrothCalculationResult: Hashable {
    let waterLiters: Double
    let temperatureMin: Int
    let temperatureMax: Int
    let totalMinutes: Int
    let estimatedYieldLiters: Double
    let startSaltGrams: Double
    let finalSaltGrams: Double
    let appleCiderVinegarMl: Int
    let peppercornCount: Int
    let allspiceCount: Int
    let bayLeafCount: Int
    let vegetables: [VegetableAmount]
    let meatParts: [MeatAmount]
    let timeline: [CookingTimelineItem]
    let warnings: [String]

    let structuredWarnings: [BrothWarning]
    let validationFailure: BrothValidationFailure?
    let scoring: BrothScoring?
    let recommendedMeatRange: BrothRecommendedMeatRange?
    let clarityMode: BrothClarityMode
    let useVinegar: Bool
    let targetYieldLiters: Double?
    let vegetableBreakdown: BrothVegetableBreakdown?
    let spiceBreakdown: BrothSpiceBreakdown?
    let microMode: Bool
    let waterWasReducedToFit: Bool
}

enum BrothPreset: String, CaseIterable, Identifiable, Hashable {
    case poultryReady
    case poultryBeefReady
    case grandmaReady
    case fishReady
    case collagenPoultryReady

    var id: String { rawValue }

    var title: String {
        switch self {
        case .poultryReady:
            return "Gotowy drobiowy"
        case .poultryBeefReady:
            return "Gotowy drobiowo-wołowy"
        case .grandmaReady:
            return "Szybki domowy rosół"
        case .fishReady:
            return "Bulion rybny"
        case .collagenPoultryReady:
            return "Bulion kolagenowy drobiowy"
        }
    }

    var subtitle: String {
        switch self {
        case .poultryReady:
            return "Szybka, gotowa receptura oparta na drobiu."
        case .poultryBeefReady:
            return "Gotowa receptura z drobiem i wołowiną dla pełniejszego smaku."
        case .grandmaReady:
            return "Szybki „babciny” rosół domowy z drobiu."
        case .fishReady:
            return "Lekki bulion rybny bez owoców morza."
        case .collagenPoultryReady:
            return "Drobiowy bulion kolagenowy o wysokim body."
        }
    }

    var profile: BrothProfile {
        switch self {
        case .poultryReady:
            return .cleaner
        case .poultryBeefReady:
            return .richer
        case .grandmaReady:
            return .cleaner
        case .fishReady:
            return .cleaner
        case .collagenPoultryReady:
            return .richer
        }
    }

    var defaultSelectedIDs: [String] {
        switch self {
        case .poultryReady:
            return ["kura"]
        case .poultryBeefReady:
            return ["kura", "szponder"]
        case .grandmaReady:
            return ["kura", "skrzydla_kurczaka"]
        case .fishReady:
            return ["kregoslup_rybny", "glowy_rybne"]
        case .collagenPoultryReady:
            return ["szyje_kurczaka", "korpus_kurczaka", "lapki", "skrzydla_kurczaka", "udka_kurczaka"]
        }
    }

    var legacyStyle: BrothStyle {
        profile.legacyStyle
    }
}

enum BrothProfile: String, CaseIterable, Identifiable, Hashable {
    case cleaner
    case richer

    var id: String { rawValue }

    var title: String {
        switch self {
        case .cleaner:
            return "Czystszy"
        case .richer:
            return "Głębszy"
        }
    }

    var subtitle: String {
        switch self {
        case .cleaner:
            return "Więcej wody względem mięsa, czystszy smak i lżejszy finisz."
        case .richer:
            return "Mniej wody względem mięsa, głębszy smak i mocniejszy wywar."
        }
    }

    var legacyStyle: BrothStyle {
        switch self {
        case .cleaner:
            return .light
        case .richer:
            return .intense
        }
    }
}

enum BrothMode: Hashable {
    case preset(BrothPreset)
    case custom(BrothProfile)
}

struct BrothCalculationRequest: Hashable {
    let mode: BrothMode
    let potSizeLiters: Double
    let meatItems: [BrothIngredientSelection]
    let clarityMode: BrothClarityMode
    let useVinegar: Bool
    let targetYieldLiters: Double?
    let premiumEnabled: Bool

    init(
        mode: BrothMode,
        potSizeLiters: Double,
        meatItems: [BrothIngredientSelection] = [],
        clarityMode: BrothClarityMode = .normal,
        useVinegar: Bool = false,
        targetYieldLiters: Double? = nil,
        premiumEnabled: Bool = true
    ) {
        self.mode = mode
        self.potSizeLiters = potSizeLiters
        self.meatItems = meatItems
        self.clarityMode = clarityMode
        self.useVinegar = useVinegar
        self.targetYieldLiters = targetYieldLiters
        self.premiumEnabled = premiumEnabled
    }
}


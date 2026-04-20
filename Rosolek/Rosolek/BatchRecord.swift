import Foundation

struct BatchIngredientSnapshot: Identifiable, Codable, Hashable {
    let ingredientID: String
    let ingredientName: String
    let categoryRawValue: String
    let grams: Int

    var id: String { ingredientID }

    init(
        ingredientID: String,
        ingredientName: String,
        categoryRawValue: String,
        grams: Int
    ) {
        self.ingredientID = ingredientID
        self.ingredientName = ingredientName
        self.categoryRawValue = categoryRawValue
        self.grams = grams
    }
}

struct BatchRecord: Identifiable, Codable, Hashable {
    let id: UUID
    let createdAt: Date

    // Legacy / compatibility
    let styleRawValue: String

    // New flow metadata
    let modeRawValue: String
    let profileRawValue: String
    let clarityModeRawValue: String
    let useVinegar: Bool

    // Batch values
    let totalWeightGrams: Int
    let selectedIngredientCount: Int
    let waterLiters: Double
    let estimatedYieldLiters: Double

    // Legacy field kept for compatibility/history UI
    let totalMinutes: Int

    // Preferred semantic field for the new flow
    let activeCookingMinutes: Int

    let warningCount: Int
    let hasThermometer: Bool

    var selectedIngredientIDs: [String]?
    var selectedIngredientsSnapshot: [BatchIngredientSnapshot]?
    var customTitle: String?

    var overallRating: Int?
    var strengthFeedbackRawValue: String?
    var fatFeedbackRawValue: String?
    var clarityFeedbackRawValue: String?
    var notes: String

    init(
        id: UUID = UUID(),
        createdAt: Date,
        styleRawValue: String,
        modeRawValue: String = "legacy",
        profileRawValue: String? = nil,
        clarityModeRawValue: String = BrothClarityMode.normal.rawValue,
        useVinegar: Bool = false,
        totalWeightGrams: Int,
        selectedIngredientCount: Int,
        waterLiters: Double,
        estimatedYieldLiters: Double,
        totalMinutes: Int,
        activeCookingMinutes: Int? = nil,
        warningCount: Int,
        hasThermometer: Bool,
        selectedIngredientIDs: [String]? = nil,
        selectedIngredientsSnapshot: [BatchIngredientSnapshot]? = nil,
        customTitle: String? = nil,
        overallRating: Int? = nil,
        strengthFeedbackRawValue: String? = nil,
        fatFeedbackRawValue: String? = nil,
        clarityFeedbackRawValue: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.createdAt = createdAt
        self.styleRawValue = styleRawValue
        self.modeRawValue = modeRawValue
        self.profileRawValue = profileRawValue ?? Self.legacyProfileRawValue(from: styleRawValue)
        self.clarityModeRawValue = clarityModeRawValue
        self.useVinegar = useVinegar
        self.totalWeightGrams = totalWeightGrams
        self.selectedIngredientCount = selectedIngredientCount
        self.waterLiters = waterLiters
        self.estimatedYieldLiters = estimatedYieldLiters
        self.totalMinutes = totalMinutes
        self.activeCookingMinutes = activeCookingMinutes ?? totalMinutes
        self.warningCount = warningCount
        self.hasThermometer = hasThermometer
        self.selectedIngredientIDs = selectedIngredientIDs
        self.selectedIngredientsSnapshot = selectedIngredientsSnapshot
        self.customTitle = customTitle
        self.overallRating = overallRating
        self.strengthFeedbackRawValue = strengthFeedbackRawValue
        self.fatFeedbackRawValue = fatFeedbackRawValue
        self.clarityFeedbackRawValue = clarityFeedbackRawValue
        self.notes = notes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case styleRawValue
        case modeRawValue
        case profileRawValue
        case clarityModeRawValue
        case useVinegar
        case totalWeightGrams
        case selectedIngredientCount
        case waterLiters
        case estimatedYieldLiters
        case totalMinutes
        case activeCookingMinutes
        case warningCount
        case hasThermometer
        case selectedIngredientIDs
        case selectedIngredientsSnapshot
        case customTitle
        case overallRating
        case strengthFeedbackRawValue
        case fatFeedbackRawValue
        case clarityFeedbackRawValue
        case notes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedID = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        let decodedCreatedAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        let decodedStyleRawValue = try container.decodeIfPresent(String.self, forKey: .styleRawValue) ?? BrothStyle.light.rawValue

        let decodedSelectedIngredientIDs = try container.decodeIfPresent([String].self, forKey: .selectedIngredientIDs)
        let decodedSelectedIngredientCount = try container.decodeIfPresent(Int.self, forKey: .selectedIngredientCount) ?? 0

        let fallbackProfileRawValue = Self.legacyProfileRawValue(from: decodedStyleRawValue)
        let fallbackModeRawValue = Self.legacyModeRawValue(
            styleRawValue: decodedStyleRawValue,
            selectedIngredientIDs: decodedSelectedIngredientIDs,
            selectedIngredientCount: decodedSelectedIngredientCount
        )

        let decodedTotalMinutes = try container.decodeIfPresent(Int.self, forKey: .totalMinutes) ?? 0

        self.id = decodedID
        self.createdAt = decodedCreatedAt
        self.styleRawValue = decodedStyleRawValue
        self.modeRawValue = try container.decodeIfPresent(String.self, forKey: .modeRawValue) ?? fallbackModeRawValue
        self.profileRawValue = try container.decodeIfPresent(String.self, forKey: .profileRawValue) ?? fallbackProfileRawValue
        self.clarityModeRawValue = try container.decodeIfPresent(String.self, forKey: .clarityModeRawValue) ?? BrothClarityMode.normal.rawValue
        self.useVinegar = try container.decodeIfPresent(Bool.self, forKey: .useVinegar) ?? false
        self.totalWeightGrams = try container.decodeIfPresent(Int.self, forKey: .totalWeightGrams) ?? 0
        self.selectedIngredientCount = decodedSelectedIngredientCount
        self.waterLiters = try container.decodeIfPresent(Double.self, forKey: .waterLiters) ?? 0
        self.estimatedYieldLiters = try container.decodeIfPresent(Double.self, forKey: .estimatedYieldLiters) ?? 0
        self.totalMinutes = decodedTotalMinutes
        self.activeCookingMinutes = try container.decodeIfPresent(Int.self, forKey: .activeCookingMinutes) ?? decodedTotalMinutes
        self.warningCount = try container.decodeIfPresent(Int.self, forKey: .warningCount) ?? 0
        self.hasThermometer = try container.decodeIfPresent(Bool.self, forKey: .hasThermometer) ?? false
        self.selectedIngredientIDs = decodedSelectedIngredientIDs
        self.selectedIngredientsSnapshot = try container.decodeIfPresent([BatchIngredientSnapshot].self, forKey: .selectedIngredientsSnapshot)
        self.customTitle = try container.decodeIfPresent(String.self, forKey: .customTitle)
        self.overallRating = try container.decodeIfPresent(Int.self, forKey: .overallRating)
        self.strengthFeedbackRawValue = try container.decodeIfPresent(String.self, forKey: .strengthFeedbackRawValue)
        self.fatFeedbackRawValue = try container.decodeIfPresent(String.self, forKey: .fatFeedbackRawValue)
        self.clarityFeedbackRawValue = try container.decodeIfPresent(String.self, forKey: .clarityFeedbackRawValue)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(styleRawValue, forKey: .styleRawValue)
        try container.encode(modeRawValue, forKey: .modeRawValue)
        try container.encode(profileRawValue, forKey: .profileRawValue)
        try container.encode(clarityModeRawValue, forKey: .clarityModeRawValue)
        try container.encode(useVinegar, forKey: .useVinegar)
        try container.encode(totalWeightGrams, forKey: .totalWeightGrams)
        try container.encode(selectedIngredientCount, forKey: .selectedIngredientCount)
        try container.encode(waterLiters, forKey: .waterLiters)
        try container.encode(estimatedYieldLiters, forKey: .estimatedYieldLiters)
        try container.encode(totalMinutes, forKey: .totalMinutes)
        try container.encode(activeCookingMinutes, forKey: .activeCookingMinutes)
        try container.encode(warningCount, forKey: .warningCount)
        try container.encode(hasThermometer, forKey: .hasThermometer)
        try container.encodeIfPresent(selectedIngredientIDs, forKey: .selectedIngredientIDs)
        try container.encodeIfPresent(selectedIngredientsSnapshot, forKey: .selectedIngredientsSnapshot)
        try container.encodeIfPresent(customTitle, forKey: .customTitle)
        try container.encodeIfPresent(overallRating, forKey: .overallRating)
        try container.encodeIfPresent(strengthFeedbackRawValue, forKey: .strengthFeedbackRawValue)
        try container.encodeIfPresent(fatFeedbackRawValue, forKey: .fatFeedbackRawValue)
        try container.encodeIfPresent(clarityFeedbackRawValue, forKey: .clarityFeedbackRawValue)
        try container.encode(notes, forKey: .notes)
    }
}

extension BatchRecord {
    var brothMode: BrothMode? {
        switch modeRawValue {
        case "preset":
            if let preset = Self.legacyPresetFromStyle(styleRawValue) {
                return .preset(preset)
            }
            return nil

        case "custom":
            if let profile = BrothProfile(rawValue: profileRawValue) {
                return .custom(profile)
            }
            return nil

        default:
            if let profile = BrothProfile(rawValue: profileRawValue) {
                return .custom(profile)
            }
            return nil
        }
    }

    var brothProfile: BrothProfile {
        BrothProfile(rawValue: profileRawValue) ?? Self.legacyProfileFromStyle(styleRawValue)
    }

    var clarityMode: BrothClarityMode {
        BrothClarityMode(rawValue: clarityModeRawValue) ?? .normal
    }

    var defaultTitle: String {
        switch brothProfile {
        case .cleaner:
            return "Rosół czystszy"
        case .richer:
            return "Rosół głębszy"
        }
    }

    var displayTitle: String {
        let trimmed = customTitle?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? defaultTitle : trimmed
    }

    var profileTitle: String {
        brothProfile.title
    }

    var modeTitle: String {
        switch modeRawValue {
        case "preset":
            return "Preset"
        case "custom":
            return "Własny"
        default:
            return "Batch"
        }
    }

    var ratingBadgeText: String {
        if let overallRating {
            return "\(overallRating)/10"
        }
        return "—"
    }

    var createdAtDisplayText: String {
        Self.historyDateFormatter.string(from: createdAt)
    }

    var timeDisplayText: String {
        let hours = activeCookingMinutes / 60
        let minutes = activeCookingMinutes % 60

        if minutes == 0 {
            return "\(hours) h"
        }

        return "\(hours) h \(minutes) min"
    }

    var weightDisplayText: String {
        Self.weightString(totalWeightGrams)
    }

    var waterDisplayText: String {
        Self.litersString(waterLiters)
    }

    var yieldDisplayText: String {
        Self.litersString(estimatedYieldLiters)
    }

    var ingredientCountDisplayText: String {
        "\(selectedIngredientCount)"
    }

    var thermometerDisplayText: String {
        hasThermometer ? "tak" : "nie"
    }

    private static let historyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()

    private static func litersString(_ value: Double) -> String {
        if value == floor(value) {
            return "\(Int(value)) l"
        }

        let twoDecimals = String(format: "%.2f", value)
        if twoDecimals.hasSuffix("0") {
            return String(format: "%.1f l", value).replacingOccurrences(of: ".", with: ",")
        }

        return "\(twoDecimals.replacingOccurrences(of: ".", with: ",")) l"
    }

    private static func weightString(_ grams: Int) -> String {
        if grams < 1000 {
            return "\(grams) g"
        }

        let kilos = Double(grams) / 1000.0
        if kilos == floor(kilos) {
            return "\(Int(kilos)) kg"
        }

        return String(format: "%.1f kg", kilos).replacingOccurrences(of: ".", with: ",")
    }

    private static func legacyProfileRawValue(from styleRawValue: String) -> String {
        legacyProfileFromStyle(styleRawValue).rawValue
    }

    private static func legacyProfileFromStyle(_ styleRawValue: String) -> BrothProfile {
        styleRawValue == BrothStyle.intense.rawValue ? .richer : .cleaner
    }

    private static func legacyPresetFromStyle(_ styleRawValue: String) -> BrothPreset? {
        switch styleRawValue {
        case BrothStyle.light.rawValue:
            return .poultryReady
        case BrothStyle.intense.rawValue:
            return .poultryBeefReady
        default:
            return nil
        }
    }

    private static func legacyModeRawValue(
        styleRawValue: String,
        selectedIngredientIDs: [String]?,
        selectedIngredientCount: Int
    ) -> String {
        guard let ids = selectedIngredientIDs, !ids.isEmpty else {
            return "preset"
        }

        let normalizedIDs = Set(
            ids.map {
                $0.folding(options: .diacriticInsensitive, locale: nil).lowercased()
            }
        )

        let looksLikeLightPreset =
            styleRawValue == BrothStyle.light.rawValue &&
            normalizedIDs == ["kura"] &&
            selectedIngredientCount == 1

        let looksLikeIntensePreset =
            styleRawValue == BrothStyle.intense.rawValue &&
            normalizedIDs == ["kura", "szponder"] &&
            selectedIngredientCount == 2

        if looksLikeLightPreset || looksLikeIntensePreset {
            return "preset"
        }

        return "custom"
    }
}

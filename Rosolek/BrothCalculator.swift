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

    var id: String { rawValue }

    var title: String {
        switch self {
        case .poultryReady:
            return "Gotowy drobiowy"
        case .poultryBeefReady:
            return "Gotowy drobiowo-wołowy"
        }
    }

    var subtitle: String {
        switch self {
        case .poultryReady:
            return "Szybka, gotowa receptura oparta na drobiu."
        case .poultryBeefReady:
            return "Gotowa receptura z drobiem i wołowiną dla pełniejszego smaku."
        }
    }

    var profile: BrothProfile {
        switch self {
        case .poultryReady:
            return .cleaner
        case .poultryBeefReady:
            return .richer
        }
    }

    var defaultSelectedIDs: [String] {
        switch self {
        case .poultryReady:
            return ["kura"]
        case .poultryBeefReady:
            return ["kura", "szponder"]
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

enum BrothCalculator {
    static func calculate(request: BrothCalculationRequest) -> BrothCalculationResult {
        if let validationFailure = validateRequest(request) {
            return hardFailureResult(
                request: request,
                failure: validationFailure
            )
        }

        switch request.mode {
        case .preset(let preset):
            return presetCalculation(
                preset: preset,
                request: request
            )

        case .custom(let profile):
            return customCalculation(
                request: request,
                profile: profile
            )
        }
    }

    static func calculate(
        preset: BrothPreset,
        potSizeLiters: Double,
        clarityMode: BrothClarityMode = .normal,
        useVinegar: Bool = false,
        targetYieldLiters: Double? = nil,
        premiumEnabled: Bool = true
    ) -> BrothCalculationResult {
        calculate(
            request: BrothCalculationRequest(
                mode: .preset(preset),
                potSizeLiters: potSizeLiters,
                clarityMode: clarityMode,
                useVinegar: useVinegar,
                targetYieldLiters: targetYieldLiters,
                premiumEnabled: premiumEnabled
            )
        )
    }

    static func calculate(
        profile: BrothProfile,
        meatItems: [BrothIngredientSelection],
        potSizeLiters: Double,
        clarityMode: BrothClarityMode = .normal,
        useVinegar: Bool = false,
        targetYieldLiters: Double? = nil,
        premiumEnabled: Bool = true
    ) -> BrothCalculationResult {
        calculate(
            request: BrothCalculationRequest(
                mode: .custom(profile),
                potSizeLiters: potSizeLiters,
                meatItems: meatItems,
                clarityMode: clarityMode,
                useVinegar: useVinegar,
                targetYieldLiters: targetYieldLiters,
                premiumEnabled: premiumEnabled
            )
        )
    }

    static func calculate(
        style: BrothStyle,
        totalWeightGrams: Int,
        selectedIDs: [String],
        potSizeLiters: Int
    ) -> BrothCalculationResult {
        if let legacyPreset = legacyPreset(
            style: style,
            selectedIDs: selectedIDs
        ) {
            return calculate(
                preset: legacyPreset,
                potSizeLiters: Double(potSizeLiters)
            )
        }

        let syntheticItems = syntheticSelections(
            totalWeightGrams: totalWeightGrams,
            selectedIDs: selectedIDs
        )

        return calculate(
            profile: legacyProfile(from: style),
            meatItems: syntheticItems,
            potSizeLiters: Double(potSizeLiters)
        )
    }

    private static func presetCalculation(
        preset: BrothPreset,
        request: BrothCalculationRequest
    ) -> BrothCalculationResult {
        let pot = normalizedPotCapacity(request.potSizeLiters)

        switch preset {
        case .poultryReady:
            return poultryPresetCalculation(
                pot: pot,
                request: request
            )

        case .poultryBeefReady:
            return poultryBeefPresetCalculation(
                pot: pot,
                request: request
            )
        }
    }

    private static func poultryPresetCalculation(
        pot: Double,
        request: BrothCalculationRequest
    ) -> BrothCalculationResult {
        let waterLiters = interpolate(pot, table: [
            (5, 3.2), (7, 4.5), (10, 6.4), (12, 7.7)
        ])

        let mainChicken = roundedToTen(interpolate(pot, table: [
            (5, 430), (7, 610), (10, 860), (12, 1040)
        ]))

        let supportChicken = roundedToTen(interpolate(pot, table: [
            (5, 146), (7, 200), (10, 292), (12, 346)
        ]))

        let totalVegetableGrams = roundedToFive(interpolate(pot, table: [
            (5, 400), (7, 562), (10, 800), (12, 962)
        ]))

        let vegetableBreakdown = buildVegetableBreakdown(
            totalVegetableGrams: totalVegetableGrams
        )

        let vegetables = splitVegetables(
            breakdown: vegetableBreakdown,
            microMode: false
        )

        let baseEstimatedYieldLiters = roundedToOneDecimal(interpolate(pot, table: [
            (5, 2.7), (7, 3.8), (10, 5.4), (12, 6.5)
        ]))

        let clarityAdjustedYield = adjustedYield(
            baseYieldLiters: baseEstimatedYieldLiters,
            waterStartLiters: waterLiters,
            fatIndex: 1.0,
            clarityMode: request.clarityMode
        )

        let config = styleConfig(for: .cleaner)
        let finalSaltBase = request.targetYieldLiters ?? clarityAdjustedYield.yieldLiters

        let startSaltGrams = roundedToOneDecimal(interpolate(pot, table: [
            (5, 4), (7, 6), (10, 9), (12, 11)
        ]))

        let finalSaltGrams = roundedToOneDecimal(
            request.targetYieldLiters == nil
                ? interpolate(pot, table: [
                    (5, 19), (7, 27), (10, 38), (12, 46)
                ])
                : (finalSaltBase * config.saltTargetCoef)
        )

        let peppercornCount = max(8, roundedToInt(interpolate(pot, table: [
            (5, 10), (7, 14), (10, 19), (12, 23)
        ])))

        let allspiceCount = max(3, roundedToInt(interpolate(pot, table: [
            (5, 4), (7, 5), (10, 7), (12, 8)
        ])))

        let bayLeafCount = max(2, roundedToInt(interpolate(pot, table: [
            (5, 2), (7, 2), (10, 3), (12, 4)
        ])))

        let spiceBreakdown = BrothSpiceBreakdown(
            peppercornCount: peppercornCount,
            allspiceCount: allspiceCount,
            bayLeafCount: bayLeafCount
        )

        let structuredWarnings = deduplicatedStructuredWarnings(
            presetStructuredWarnings(
                waterLiters: waterLiters,
                potSizeLiters: request.potSizeLiters,
                clarityMode: request.clarityMode,
                yieldLossLiters: clarityAdjustedYield.lossLiters
            )
        )

        return BrothCalculationResult(
            waterLiters: roundedToOneDecimal(waterLiters),
            temperatureMin: 88,
            temperatureMax: 90,
            totalMinutes: 315,
            estimatedYieldLiters: clarityAdjustedYield.yieldLiters,
            startSaltGrams: startSaltGrams,
            finalSaltGrams: roundedToOneDecimal(finalSaltGrams),
            appleCiderVinegarMl: vinegarAmountForPreset(
                profile: .cleaner,
                useVinegar: request.useVinegar
            ),
            peppercornCount: peppercornCount,
            allspiceCount: allspiceCount,
            bayLeafCount: bayLeafCount,
            vegetables: vegetables,
            meatParts: [
                MeatAmount(
                    name: "Kura / korpus",
                    grams: mainChicken,
                    note: "Główna baza gotowego drobiowego."
                ),
                MeatAmount(
                    name: "Szyje / skrzydła",
                    grams: supportChicken,
                    note: "Dla pełniejszego aromatu i body."
                )
            ],
            timeline: buildBasicSummaryTimeline(profile: .cleaner, hasLiver: false),
            warnings: structuredWarnings.map(warningText(for:)),
            structuredWarnings: structuredWarnings,
            validationFailure: nil,
            scoring: nil,
            recommendedMeatRange: nil,
            clarityMode: request.clarityMode,
            useVinegar: request.useVinegar,
            targetYieldLiters: request.targetYieldLiters,
            vegetableBreakdown: vegetableBreakdown,
            spiceBreakdown: spiceBreakdown,
            microMode: false,
            waterWasReducedToFit: false
        )
    }

    private static func poultryBeefPresetCalculation(
        pot: Double,
        request: BrothCalculationRequest
    ) -> BrothCalculationResult {
        let waterLiters = interpolate(pot, table: [
            (5, 3.0), (7, 4.1), (10, 5.9), (12, 7.1)
        ])

        let chickenTotal = roundedToTen(interpolate(pot, table: [
            (5, 470), (7, 640), (10, 920), (12, 1110)
        ]))

        let beefTotal = roundedToTen(interpolate(pot, table: [
            (5, 250), (7, 344), (10, 496), (12, 594)
        ]))

        let beefBones = roundedToTen(Double(beefTotal) * 0.55)
        let beefCollagen = max(0, beefTotal - beefBones)

        let totalVegetableGrams = roundedToFive(interpolate(pot, table: [
            (5, 420), (7, 574), (10, 826), (12, 994)
        ]))

        let vegetableBreakdown = buildVegetableBreakdown(
            totalVegetableGrams: totalVegetableGrams
        )

        let vegetables = splitVegetables(
            breakdown: vegetableBreakdown,
            microMode: false
        )

        let baseEstimatedYieldLiters = roundedToOneDecimal(interpolate(pot, table: [
            (5, 2.4), (7, 3.3), (10, 4.7), (12, 5.7)
        ]))

        let clarityAdjustedYield = adjustedYield(
            baseYieldLiters: baseEstimatedYieldLiters,
            waterStartLiters: waterLiters,
            fatIndex: 1.4,
            clarityMode: request.clarityMode
        )

        let config = styleConfig(for: .richer)
        let finalSaltBase = request.targetYieldLiters ?? clarityAdjustedYield.yieldLiters

        let startSaltGrams = roundedToOneDecimal(interpolate(pot, table: [
            (5, 5), (7, 7), (10, 10), (12, 12)
        ]))

        let finalSaltGrams = roundedToOneDecimal(
            request.targetYieldLiters == nil
                ? interpolate(pot, table: [
                    (5, 18), (7, 25), (10, 36), (12, 44)
                ])
                : (finalSaltBase * config.saltTargetCoef)
        )

        let peppercornCount = max(8, roundedToInt(interpolate(pot, table: [
            (5, 10), (7, 14), (10, 21), (12, 25)
        ])))

        let allspiceCount = max(3, roundedToInt(interpolate(pot, table: [
            (5, 4), (7, 5), (10, 8), (12, 9)
        ])))

        let bayLeafCount = max(2, roundedToInt(interpolate(pot, table: [
            (5, 2), (7, 2), (10, 4), (12, 4)
        ])))

        let spiceBreakdown = BrothSpiceBreakdown(
            peppercornCount: peppercornCount,
            allspiceCount: allspiceCount,
            bayLeafCount: bayLeafCount
        )

        let structuredWarnings = deduplicatedStructuredWarnings(
            presetStructuredWarnings(
                waterLiters: waterLiters,
                potSizeLiters: request.potSizeLiters,
                clarityMode: request.clarityMode,
                yieldLossLiters: clarityAdjustedYield.lossLiters
            )
        )

        return BrothCalculationResult(
            waterLiters: roundedToOneDecimal(waterLiters),
            temperatureMin: 88,
            temperatureMax: 90,
            totalMinutes: 345,
            estimatedYieldLiters: clarityAdjustedYield.yieldLiters,
            startSaltGrams: startSaltGrams,
            finalSaltGrams: roundedToOneDecimal(finalSaltGrams),
            appleCiderVinegarMl: vinegarAmountForPreset(
                profile: .richer,
                useVinegar: request.useVinegar
            ),
            peppercornCount: peppercornCount,
            allspiceCount: allspiceCount,
            bayLeafCount: bayLeafCount,
            vegetables: vegetables,
            meatParts: [
                MeatAmount(
                    name: "Kura / korpus",
                    grams: chickenTotal,
                    note: "Część drobiowa dla czystości i aromatu."
                ),
                MeatAmount(
                    name: "Wołowina: kości",
                    grams: beefBones,
                    note: "Stawowe / szpikowe / ogon."
                ),
                MeatAmount(
                    name: "Wołowina: mięso z kolagenem",
                    grams: beefCollagen,
                    note: "Goleń / pręga / szponder."
                )
            ],
            timeline: buildBasicSummaryTimeline(profile: .richer, hasLiver: false),
            warnings: structuredWarnings.map(warningText(for:)),
            structuredWarnings: structuredWarnings,
            validationFailure: nil,
            scoring: nil,
            recommendedMeatRange: nil,
            clarityMode: request.clarityMode,
            useVinegar: request.useVinegar,
            targetYieldLiters: request.targetYieldLiters,
            vegetableBreakdown: vegetableBreakdown,
            spiceBreakdown: spiceBreakdown,
            microMode: false,
            waterWasReducedToFit: false
        )
    }

    private static func customCalculation(
        request: BrothCalculationRequest,
        profile: BrothProfile
    ) -> BrothCalculationResult {
        let pot = normalizedPotCapacity(request.potSizeLiters)
        let normalizedItems = normalizedItems(from: request.meatItems)
        let totalWeight = normalizedItems.reduce(0) { $0 + $1.grams }
        let config = styleConfig(for: profile)
        let hasLiver = normalizedItems.contains(where: { $0.profile.whenToAdd == .endOnly })
        let recommendedRange = recommendedMeatRange(
            for: profile,
            potCapacityL: pot
        )

        let meatKg = Double(totalWeight) / 1000.0
        let recipeWaterL = roundedToTwoDecimals(meatKg * config.waterFactor)

        let provisionalVegG = roundedToInt(recipeWaterL * 1000.0 * config.vegPercent)
        let provisionalSafeWaterL = safeWaterUpperBoundV2(
            potCapacityL: pot,
            totalMeatG: totalWeight,
            vegTotalG: provisionalVegG
        )

        if provisionalSafeWaterL <= 0 {
            return hardFailureResult(
                request: request,
                failure: BrothValidationFailure(
                    code: .hardNotFit,
                    messageFallback: warningText(
                        for: BrothWarning(
                            code: .hardNotFit,
                            severity: .error,
                            params: []
                        )
                    )
                )
            )
        }

        var waterStartL = min(recipeWaterL, provisionalSafeWaterL)
        var vegTotalG = roundedToInt(waterStartL * 1000.0 * config.vegPercent)

        let finalSafeWaterL = safeWaterUpperBoundV2(
            potCapacityL: pot,
            totalMeatG: totalWeight,
            vegTotalG: vegTotalG
        )

        if finalSafeWaterL <= 0 {
            return hardFailureResult(
                request: request,
                failure: BrothValidationFailure(
                    code: .hardNotFit,
                    messageFallback: warningText(
                        for: BrothWarning(
                            code: .hardNotFit,
                            severity: .error,
                            params: []
                        )
                    )
                )
            )
        }

        if waterStartL > finalSafeWaterL {
            waterStartL = finalSafeWaterL
            vegTotalG = roundedToInt(waterStartL * 1000.0 * config.vegPercent)
        }

        waterStartL = roundedToTwoDecimals(max(0.1, waterStartL))
        let waterWasReducedToFit = recipeWaterL - waterStartL > 0.009
        let microMode = pot < 1.0 || waterStartL < 0.7

        let vegetableBreakdown = buildVegetableBreakdown(
            totalVegetableGrams: vegTotalG
        )

        let vegetables = splitVegetables(
            breakdown: vegetableBreakdown,
            microMode: microMode
        )

        let spiceBreakdown = buildSpiceBreakdown(
            profile: profile,
            waterStartL: waterStartL
        )

        let scoring = calculateScoring(
            items: normalizedItems,
            waterStartLiters: waterStartL
        )

        let clarityAdjustedYield = adjustedYield(
            baseYieldLiters: roundedToTwoDecimals(waterStartL * config.yieldFactor),
            waterStartLiters: waterStartL,
            fatIndex: scoring.fatIndex,
            clarityMode: request.clarityMode
        )

        let effectiveSaltTargetCoef = microMode
            ? max(0, config.saltTargetCoef - 0.5)
            : config.saltTargetCoef

        let saltTargetBase = request.targetYieldLiters ?? clarityAdjustedYield.yieldLiters

        let startSaltG = roundedToInt(waterStartL * config.saltStartCoef)
        let finalSaltG = roundedToInt(max(0.1, saltTargetBase) * effectiveSaltTargetCoef)

        let boneWeight = normalizedItems
            .filter { $0.profile.bonesFlag }
            .reduce(0) { $0 + $1.grams }

        let vinegarMl = vinegarAmountForCustom(
            useVinegar: request.useVinegar,
            bonesKg: Double(boneWeight) / 1000.0
        )

        let structuredWarnings = deduplicatedStructuredWarnings(
            buildStructuredWarnings(
                profile: profile,
                scoring: scoring,
                totalWeight: totalWeight,
                recommendedRange: recommendedRange,
                waterWasReducedToFit: waterWasReducedToFit,
                hasLiver: hasLiver,
                clarityMode: request.clarityMode,
                paperFilterLossLiters: clarityAdjustedYield.lossLiters
            )
        )

        return BrothCalculationResult(
            waterLiters: waterStartL,
            temperatureMin: 88,
            temperatureMax: 90,
            totalMinutes: profile == .cleaner ? 315 : 345,
            estimatedYieldLiters: clarityAdjustedYield.yieldLiters,
            startSaltGrams: Double(startSaltG),
            finalSaltGrams: Double(finalSaltG),
            appleCiderVinegarMl: vinegarMl,
            peppercornCount: spiceBreakdown.peppercornCount,
            allspiceCount: spiceBreakdown.allspiceCount,
            bayLeafCount: spiceBreakdown.bayLeafCount,
            vegetables: vegetables,
            meatParts: meatParts(from: normalizedItems),
            timeline: buildBasicSummaryTimeline(profile: profile, hasLiver: hasLiver),
            warnings: structuredWarnings.map(warningText(for:)),
            structuredWarnings: structuredWarnings,
            validationFailure: nil,
            scoring: scoring,
            recommendedMeatRange: recommendedRange,
            clarityMode: request.clarityMode,
            useVinegar: request.useVinegar,
            targetYieldLiters: request.targetYieldLiters,
            vegetableBreakdown: vegetableBreakdown,
            spiceBreakdown: spiceBreakdown,
            microMode: microMode,
            waterWasReducedToFit: waterWasReducedToFit
        )
    }

    private static func validateRequest(
        _ request: BrothCalculationRequest
    ) -> BrothValidationFailure? {
        if request.potSizeLiters < 0.25 {
            return BrothValidationFailure(
                code: .hardPotTooSmall,
                messageFallback: warningText(
                    for: BrothWarning(
                        code: .hardPotTooSmall,
                        severity: .error,
                        params: []
                    )
                )
            )
        }

        if request.potSizeLiters > 30 {
            return BrothValidationFailure(
                code: .hardPotTooBig,
                messageFallback: warningText(
                    for: BrothWarning(
                        code: .hardPotTooBig,
                        severity: .error,
                        params: []
                    )
                )
            )
        }

        switch request.mode {
        case .preset:
            return nil

        case .custom:
            let positiveItems = request.meatItems.filter { $0.grams > 0 }
            let totalWeight = positiveItems.reduce(0) { $0 + $1.grams }

            if totalWeight <= 0 {
                return BrothValidationFailure(
                    code: .hardNoMeat,
                    messageFallback: warningText(
                        for: BrothWarning(
                            code: .hardNoMeat,
                            severity: .error,
                            params: []
                        )
                    )
                )
            }

            if totalWeight > 10_000 {
                return BrothValidationFailure(
                    code: .hardTooMuchMeat,
                    messageFallback: warningText(
                        for: BrothWarning(
                            code: .hardTooMuchMeat,
                            severity: .error,
                            params: []
                        )
                    )
                )
            }

            if positiveItems.contains(where: { $0.grams > 6_000 }) {
                return BrothValidationFailure(
                    code: .hardItemTooBig,
                    messageFallback: warningText(
                        for: BrothWarning(
                            code: .hardItemTooBig,
                            severity: .error,
                            params: []
                        )
                    )
                )
            }

            if request.premiumEnabled == false {
                let normalized = normalizedItems(from: positiveItems)
                if normalized.contains(where: { $0.profile.isPremium }) {
                    return BrothValidationFailure(
                        code: .premiumBlocked,
                        messageFallback: warningText(
                            for: BrothWarning(
                                code: .premiumBlocked,
                                severity: .error,
                                params: []
                            )
                        )
                    )
                }
            }

            return nil
        }
    }

    private static func hardFailureResult(
        request: BrothCalculationRequest,
        failure: BrothValidationFailure
    ) -> BrothCalculationResult {
        let fallbackProfile = profile(for: request.mode)
        let normalized = normalizedItems(from: request.meatItems)
        let hasLiver = normalized.contains(where: { $0.profile.whenToAdd == .endOnly })
        let warning = BrothWarning(
            code: failure.code,
            severity: .error,
            params: []
        )

        return BrothCalculationResult(
            waterLiters: 0,
            temperatureMin: 88,
            temperatureMax: 90,
            totalMinutes: fallbackProfile == .cleaner ? 315 : 345,
            estimatedYieldLiters: 0,
            startSaltGrams: 0,
            finalSaltGrams: 0,
            appleCiderVinegarMl: 0,
            peppercornCount: 0,
            allspiceCount: 0,
            bayLeafCount: 0,
            vegetables: [],
            meatParts: meatParts(from: normalized),
            timeline: buildBasicSummaryTimeline(profile: fallbackProfile, hasLiver: hasLiver),
            warnings: [failure.messageFallback],
            structuredWarnings: [warning],
            validationFailure: failure,
            scoring: nil,
            recommendedMeatRange: recommendedMeatRange(
                for: fallbackProfile,
                potCapacityL: normalizedPotCapacity(request.potSizeLiters)
            ),
            clarityMode: request.clarityMode,
            useVinegar: request.useVinegar,
            targetYieldLiters: request.targetYieldLiters,
            vegetableBreakdown: nil,
            spiceBreakdown: nil,
            microMode: false,
            waterWasReducedToFit: false
        )
    }
}

// MARK: - Supporting domain and helpers

private struct BrothStyleConfig {
    let waterFactor: Double
    let vegPercent: Double
    let yieldFactor: Double
    let saltStartCoef: Double
    let saltTargetCoef: Double
    let pepperCoef: Double
    let allspiceCoef: Double
    let bayCoef: Double
}

private func styleConfig(for profile: BrothProfile) -> BrothStyleConfig {
    switch profile {
    case .cleaner:
        return BrothStyleConfig(
            waterFactor: 4.5,
            vegPercent: 0.125,
            yieldFactor: 0.84,
            saltStartCoef: 1.4,
            saltTargetCoef: 7.0,
            pepperCoef: 3.0,
            allspiceCoef: 1.1,
            bayCoef: 0.5
        )

    case .richer:
        return BrothStyleConfig(
            waterFactor: 2.6,
            vegPercent: 0.14,
            yieldFactor: 0.80,
            saltStartCoef: 1.7,
            saltTargetCoef: 7.7,
            pepperCoef: 3.5,
            allspiceCoef: 1.3,
            bayCoef: 0.6
        )
    }
}

private enum IngredientFamily: Hashable {
    case poultry
    case beef
    case offal
    case other
}

private enum WhenToAdd: Hashable {
    case start
    case endOnly
}

private struct IngredientProfile: Hashable {
    let id: String
    let family: IngredientFamily
    let bonesFlag: Bool
    let collagenScore: Int
    let fatScore: Int
    let aromaScore: Int
    let whenToAdd: WhenToAdd
    let isWingLike: Bool
    let isHeavyBeef: Bool
    let isPremium: Bool
    let isMarrowHeavyBeef: Bool
}

private struct NormalizedMeatItem: Hashable {
    let id: String
    let name: String
    let grams: Int
    let profile: IngredientProfile
}

private func profile(for mode: BrothMode) -> BrothProfile {
    switch mode {
    case .preset(let preset):
        return preset.profile
    case .custom(let profile):
        return profile
    }
}

private func profileForID(_ rawID: String) -> IngredientProfile {
    let id = normalizeID(rawID)

    if containsAny(id, ["watrob"]) {
        return IngredientProfile(
            id: id,
            family: .offal,
            bonesFlag: false,
            collagenScore: 0,
            fatScore: 1,
            aromaScore: 3,
            whenToAdd: .endOnly,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["serca"]) {
        return IngredientProfile(
            id: id,
            family: .offal,
            bonesFlag: false,
            collagenScore: 0,
            fatScore: 1,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["zoladki"]) {
        return IngredientProfile(
            id: id,
            family: .offal,
            bonesFlag: false,
            collagenScore: 1,
            fatScore: 0,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["szpik", "kosci_szpikowe"]) {
        return IngredientProfile(
            id: id,
            family: .beef,
            bonesFlag: true,
            collagenScore: 3,
            fatScore: 3,
            aromaScore: 3,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: true,
            isPremium: false,
            isMarrowHeavyBeef: true
        )
    }

    if containsAny(id, ["ogon", "kosci_rosolowe", "kosci_stawowe"]) {
        return IngredientProfile(
            id: id,
            family: .beef,
            bonesFlag: true,
            collagenScore: 3,
            fatScore: 2,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["mostek"]) {
        return IngredientProfile(
            id: id,
            family: .beef,
            bonesFlag: false,
            collagenScore: 1,
            fatScore: 3,
            aromaScore: 3,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: true,
            isPremium: false,
            isMarrowHeavyBeef: true
        )
    }

    if containsAny(id, ["szponder", "prega", "pręga", "golen"]) {
        return IngredientProfile(
            id: id,
            family: .beef,
            bonesFlag: false,
            collagenScore: 2,
            fatScore: 2,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["lapki", "stopy", "feet"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 3,
            fatScore: 0,
            aromaScore: 1,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["skrzyd"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 2,
            fatScore: containsAny(id, ["kacz", "ges"]) ? 3 : 2,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: true,
            isHeavyBeef: false,
            isPremium: containsAny(id, ["kacz", "ges"]),
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["szyj"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 3,
            fatScore: containsAny(id, ["kacz", "ges"]) ? 2 : 1,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: containsAny(id, ["kacz", "ges"]),
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["korpus"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 2,
            fatScore: containsAny(id, ["kacz", "ges"]) ? 3 : 1,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: containsAny(id, ["kacz", "ges"]),
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["kura", "porcja_rosolowa", "porcja"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 2,
            fatScore: 2,
            aromaScore: 3,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: false,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["udka"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: true,
            collagenScore: 1,
            fatScore: 3,
            aromaScore: 2,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: true,
            isMarrowHeavyBeef: false
        )
    }

    if containsAny(id, ["piers", "pierś"]) {
        return IngredientProfile(
            id: id,
            family: .poultry,
            bonesFlag: false,
            collagenScore: 0,
            fatScore: 0,
            aromaScore: 1,
            whenToAdd: .start,
            isWingLike: false,
            isHeavyBeef: false,
            isPremium: true,
            isMarrowHeavyBeef: false
        )
    }

    return IngredientProfile(
        id: id,
        family: .other,
        bonesFlag: false,
        collagenScore: 1,
        fatScore: 1,
        aromaScore: 1,
        whenToAdd: .start,
        isWingLike: false,
        isHeavyBeef: false,
        isPremium: true,
        isMarrowHeavyBeef: false
    )
}

// MARK: - Normalization / mapping

private func normalizedItems(from selections: [BrothIngredientSelection]) -> [NormalizedMeatItem] {
    selections
        .filter { $0.grams > 0 }
        .map { selection in
            let normalizedID = normalizeID(selection.ingredientID)
            return NormalizedMeatItem(
                id: normalizedID,
                name: selection.ingredientName,
                grams: selection.grams,
                profile: profileForID(normalizedID)
            )
        }
}

private func syntheticSelections(
    totalWeightGrams: Int,
    selectedIDs: [String]
) -> [BrothIngredientSelection] {
    let filtered = selectedIDs
        .map(normalizeID)
        .filter { !$0.isEmpty }

    guard !filtered.isEmpty, totalWeightGrams > 0 else { return [] }

    let count = filtered.count
    let base = totalWeightGrams / count
    let remainder = totalWeightGrams % count

    return filtered.enumerated().map { index, id in
        let grams = base + (index < remainder ? 1 : 0)

        return BrothIngredientSelection(
            ingredientID: id,
            ingredientName: displayName(forID: id),
            category: categoryForID(id),
            grams: grams
        )
    }
}

private func displayName(forID rawID: String) -> String {
    let id = normalizeID(rawID)

    switch true {
    case containsAny(id, ["kura", "porcja_rosolowa", "porcja"]):
        return "Kura rosołowa / porcja rosołowa"
    case containsAny(id, ["korpus_kurczaka"]):
        return "Korpus z kurczaka"
    case containsAny(id, ["skrzydla_kurczaka"]):
        return "Skrzydła z kurczaka"
    case containsAny(id, ["szyje_kurczaka"]):
        return "Szyje z kurczaka"
    case containsAny(id, ["lapki"]):
        return "Łapki z kurczaka"
    case containsAny(id, ["szyja_indyka"]):
        return "Szyja z indyka"
    case containsAny(id, ["skrzydlo_indyka"]):
        return "Skrzydło z indyka"
    case containsAny(id, ["korpus_indyka"]):
        return "Korpus z indyka"
    case containsAny(id, ["korpus_kaczki"]):
        return "Korpus z kaczki"
    case containsAny(id, ["szyja_kaczki"]):
        return "Szyja z kaczki"
    case containsAny(id, ["skrzydla_kaczki"]):
        return "Skrzydła z kaczki"
    case containsAny(id, ["szponder"]):
        return "Szponder"
    case containsAny(id, ["prega", "pręga"]):
        return "Pręga"
    case containsAny(id, ["mostek"]):
        return "Mostek"
    case containsAny(id, ["golen"]):
        return "Goleń wołowa"
    case containsAny(id, ["kosci_szpikowe"]):
        return "Kości szpikowe"
    case containsAny(id, ["kosci_rosolowe", "kosci_stawowe"]):
        return "Kości rosołowe / stawowe"
    case containsAny(id, ["ogon"]):
        return "Ogon wołowy"
    case containsAny(id, ["serca"]):
        return "Serca drobiowe"
    case containsAny(id, ["zoladki"]):
        return "Żołądki drobiowe"
    case containsAny(id, ["watrob"]):
        return "Wątróbka drobiowa"
    default:
        return rawID
    }
}

private func categoryForID(_ rawID: String) -> IngredientCategory {
    let family = profileForID(rawID).family

    switch family {
    case .poultry:
        return .poultry
    case .beef:
        return .beef
    case .offal, .other:
        return .offal
    }
}

private func legacyPreset(
    style: BrothStyle,
    selectedIDs: [String]
) -> BrothPreset? {
    let normalizedIDs = Set(selectedIDs.map(normalizeID))

    let isLegacyLightPreset = style == .light && normalizedIDs == ["kura"]
    let isLegacyIntensePreset = style == .intense && normalizedIDs == ["kura", "szponder"]

    if isLegacyLightPreset {
        return .poultryReady
    }

    if isLegacyIntensePreset {
        return .poultryBeefReady
    }

    return nil
}

private func legacyProfile(from style: BrothStyle) -> BrothProfile {
    switch style {
    case .light:
        return .cleaner
    case .intense:
        return .richer
    }
}

// MARK: - Vegetables / spices / timeline / meat breakdown

private func buildVegetableBreakdown(totalVegetableGrams: Int) -> BrothVegetableBreakdown {
    let total = Double(max(0, totalVegetableGrams))

    let carrot = roundedToFive(total * 0.34)
    let celeriac = roundedToFive(total * 0.29)
    let parsleyRoot = roundedToFive(total * 0.20)
    let leek = roundedToFive(total * 0.17)

    return BrothVegetableBreakdown(
        totalGrams: max(0, totalVegetableGrams),
        carrotGrams: carrot,
        celeriacGrams: celeriac,
        parsleyRootGrams: parsleyRoot,
        leekGrams: leek,
        onionCount: totalVegetableGrams > 0 ? 1 : 0
    )
}

private func splitVegetables(
    breakdown: BrothVegetableBreakdown,
    microMode: Bool
) -> [VegetableAmount] {
    if breakdown.totalGrams <= 0 {
        return []
    }

    if microMode {
        return [
            VegetableAmount(name: "Marchew", amount: "2–3 plasterki", note: nil),
            VegetableAmount(name: "Seler", amount: "1 mały kawałek", note: nil),
            VegetableAmount(name: "Pietruszka", amount: "1–2 plasterki", note: nil),
            VegetableAmount(name: "Por", amount: "krótki kawałek", note: nil),
            VegetableAmount(name: "Cebula", amount: "mały kawałek", note: "Opcjonalnie, opalona.")
        ]
    }

    return [
        VegetableAmount(name: "Marchew", amount: "\(breakdown.carrotGrams) g", note: nil),
        VegetableAmount(name: "Seler korzeniowy", amount: "\(breakdown.celeriacGrams) g", note: nil),
        VegetableAmount(name: "Pietruszka korzeń", amount: "\(breakdown.parsleyRootGrams) g", note: nil),
        VegetableAmount(name: "Por", amount: "\(breakdown.leekGrams) g", note: nil),
        VegetableAmount(name: "Cebula", amount: breakdown.onionCount == 1 ? "1 szt." : "\(breakdown.onionCount) szt.", note: "Opalana.")
    ]
}

private func buildSpiceBreakdown(
    profile: BrothProfile,
    waterStartL: Double
) -> BrothSpiceBreakdown {
    let config = styleConfig(for: profile)
    let microMode = waterStartL < 0.7

    let pepperCount = microMode
        ? max(1, roundedToInt(max(1.0, waterStartL * (profile == .cleaner ? 2.6 : 3.0))))
        : max(1, roundedToInt(waterStartL * config.pepperCoef))

    let allspiceCount = microMode
        ? max(1, roundedToInt(max(1.0, waterStartL * (profile == .cleaner ? 0.8 : 1.0))))
        : max(1, roundedToInt(waterStartL * config.allspiceCoef))

    let bayLeafCount = microMode
        ? 1
        : max(profile == .cleaner ? 1 : 2, roundedToInt(waterStartL * config.bayCoef))

    return BrothSpiceBreakdown(
        peppercornCount: pepperCount,
        allspiceCount: allspiceCount,
        bayLeafCount: bayLeafCount
    )
}

private func meatParts(from items: [NormalizedMeatItem]) -> [MeatAmount] {
    guard !items.isEmpty else { return [] }

    let sorted = items.sorted {
        if familySortIndex($0.profile.family) != familySortIndex($1.profile.family) {
            return familySortIndex($0.profile.family) < familySortIndex($1.profile.family)
        }

        if $0.grams != $1.grams {
            return $0.grams > $1.grams
        }

        return $0.name < $1.name
    }

    return sorted.map { item in
        MeatAmount(
            name: item.name,
            grams: item.grams,
            note: note(for: item)
        )
    }
}

private func familySortIndex(_ family: IngredientFamily) -> Int {
    switch family {
    case .poultry: return 0
    case .beef: return 1
    case .offal: return 2
    case .other: return 3
    }
}

private func note(for item: NormalizedMeatItem) -> String? {
    if item.profile.whenToAdd == .endOnly {
        return "Dodaj dopiero na końcu, na 20–30 minut."
    }

    if item.profile.family == .beef && item.profile.bonesFlag {
        return "Kości i dłuższy finisz."
    }

    if item.profile.family == .beef {
        return "Mocniejsza, bardziej mięsna baza."
    }

    if item.profile.family == .poultry && item.profile.isWingLike {
        return "Więcej smaku i trochę tłustości."
    }

    if item.profile.family == .poultry && item.profile.collagenScore >= 3 {
        return "Kolagen i lepsze body."
    }

    if item.profile.family == .offal {
        return "Dodatek pogłębiający smak."
    }

    return "Część wybrana przez użytkownika."
}

private func buildBasicSummaryTimeline(profile: BrothProfile, hasLiver: Bool) -> [CookingTimelineItem] {
    let heatUp = 45
    let stabilizeEnd = heatUp + 60

    let poultryOut = stabilizeEnd + 105
    let vegetablesOut = stabilizeEnd + (profile == .cleaner ? 135 : 165)
    let finishEnd = vegetablesOut + (profile == .cleaner ? 35 : 75)
    let restEnd = finishEnd + 20
    let seasonEnd = restEnd + 10

    var items: [CookingTimelineItem] = [
        CookingTimelineItem(
            minuteOffset: 0,
            timeLabel: "START",
            title: "Przygotuj mięso i zalej wodą",
            subtitle: "Dopiero po tym uruchom gotowanie."
        ),
        CookingTimelineItem(
            minuteOffset: heatUp,
            timeLabel: minutesLabel(heatUp),
            title: "Osiągnij 88–90°C",
            subtitle: "Grzej powoli i zbieraj szumowiny bez mieszania."
        ),
        CookingTimelineItem(
            minuteOffset: stabilizeEnd,
            timeLabel: minutesLabel(stabilizeEnd),
            title: "Dodaj warzywa i przyprawy",
            subtitle: "Timer liczymy od momentu ustabilizowania temperatury."
        ),
        CookingTimelineItem(
            minuteOffset: poultryOut,
            timeLabel: minutesLabel(poultryOut),
            title: "Wyjmij drób",
            subtitle: "Po 90–120 minutach od dodania warzyw."
        )
    ]

    if hasLiver {
        let liverIn = max(vegetablesOut, finishEnd - 30)
        items.append(
            CookingTimelineItem(
                minuteOffset: liverIn,
                timeLabel: minutesLabel(liverIn),
                title: "Dodaj wątróbkę",
                subtitle: "Tylko na końcu, na 20–30 minut."
            )
        )
    }

    items.append(contentsOf: [
        CookingTimelineItem(
            minuteOffset: vegetablesOut,
            timeLabel: minutesLabel(vegetablesOut),
            title: "Wyjmij warzywa",
            subtitle: profile == .cleaner
                ? "Zwykle po 120–150 minutach od dodania."
                : "Zwykle po 150–180 minutach od dodania."
        ),
        CookingTimelineItem(
            minuteOffset: finishEnd,
            timeLabel: minutesLabel(finishEnd),
            title: "Wyłącz i odstaw",
            subtitle: "Pozwól osadom opaść przez 15–20 minut."
        ),
        CookingTimelineItem(
            minuteOffset: restEnd,
            timeLabel: minutesLabel(restEnd),
            title: "Cedź bez wyciskania",
            subtitle: "Przygotuj sito i naczynie na gotowy rosół."
        ),
        CookingTimelineItem(
            minuteOffset: seasonEnd,
            timeLabel: minutesLabel(seasonEnd),
            title: "Dopraw po cedzeniu",
            subtitle: "Sól koryguj dopiero na końcu."
        )
    ])

    return items.sorted { $0.minuteOffset < $1.minuteOffset }
}

// MARK: - Warning builders and math

private func buildStructuredWarnings(
    profile: BrothProfile,
    scoring: BrothScoring,
    totalWeight: Int,
    recommendedRange: BrothRecommendedMeatRange,
    waterWasReducedToFit: Bool,
    hasLiver: Bool,
    clarityMode: BrothClarityMode,
    paperFilterLossLiters: Double
) -> [BrothWarning] {
    var warnings: [BrothWarning] = []

    if waterWasReducedToFit {
        warnings.append(
            BrothWarning(
                code: .waterReducedToFit,
                severity: .warn,
                params: []
            )
        )
    } else {
        if totalWeight < recommendedRange.minGrams {
            warnings.append(
                BrothWarning(
                    code: profile == .cleaner ? .undermeatLight : .undermeatIntense,
                    severity: .info,
                    params: [
                        BrothWarningParameter(key: "totalWeight", value: Double(totalWeight)),
                        BrothWarningParameter(key: "recommendedMin", value: Double(recommendedRange.minGrams))
                    ]
                )
            )
        } else if let maxGrams = recommendedRange.maxGrams, totalWeight > maxGrams {
            warnings.append(
                BrothWarning(
                    code: profile == .cleaner ? .overmeatLight : .overmeatIntense,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "totalWeight", value: Double(totalWeight)),
                        BrothWarningParameter(key: "recommendedMax", value: Double(maxGrams))
                    ]
                )
            )
        }
    }

    switch profile {
    case .cleaner:
        if scoring.fatIndex > 1.6 {
            warnings.append(
                BrothWarning(
                    code: .overfatLight,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "fatIndex", value: scoring.fatIndex)
                    ]
                )
            )
        }

        if scoring.wingsShare > 0.25 {
            warnings.append(
                BrothWarning(
                    code: .wingsTooHighLight,
                    severity: .info,
                    params: [
                        BrothWarningParameter(key: "wingsShare", value: scoring.wingsShare)
                    ]
                )
            )
        }

    case .richer:
        if scoring.boneShare < 0.35 && scoring.collagenIndex < 1.2 {
            warnings.append(
                BrothWarning(
                    code: .lowGelatinIntense,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "boneShare", value: scoring.boneShare),
                        BrothWarningParameter(key: "collagenIndex", value: scoring.collagenIndex)
                    ]
                )
            )
        }

        if scoring.beefShare > 0.55 {
            warnings.append(
                BrothWarning(
                    code: .heavyBeefProfile,
                    severity: .info,
                    params: [
                        BrothWarningParameter(key: "beefShare", value: scoring.beefShare)
                    ]
                )
            )
        }

        if scoring.marrowHeavyBeefShare > 0.40 {
            warnings.append(
                BrothWarning(
                    code: .marrowTooHigh,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "marrowHeavyBeefShare", value: scoring.marrowHeavyBeefShare)
                    ]
                )
            )
        }
    }

    if scoring.oneIngredientShare > 0.80 {
        warnings.append(
            BrothWarning(
                code: .singleIngredientRisk,
                severity: .info,
                params: [
                    BrothWarningParameter(key: "oneIngredientShare", value: scoring.oneIngredientShare)
                ]
            )
        )
    }

    if scoring.offalShare > 0.35 {
        warnings.append(
            BrothWarning(
                code: .offalDominantRisk,
                severity: .warn,
                params: [
                    BrothWarningParameter(key: "offalShare", value: scoring.offalShare)
                ]
            )
        )
    }

    if hasLiver {
        warnings.append(
            BrothWarning(
                code: .liverTimingRequired,
                severity: .warn,
                params: []
            )
        )
    }

    if clarityMode == .paperFilter {
        warnings.append(
            BrothWarning(
                code: .paperFilterLowerIntensity,
                severity: .info,
                params: []
            )
        )

        if paperFilterLossLiters > 0.6 {
            warnings.append(
                BrothWarning(
                    code: .paperFilterHighLoss,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "yieldLossL", value: paperFilterLossLiters)
                    ]
                )
            )
        }
    }

    return warnings
}

private func presetStructuredWarnings(
    waterLiters: Double,
    potSizeLiters: Double,
    clarityMode: BrothClarityMode,
    yieldLossLiters: Double
) -> [BrothWarning] {
    var warnings: [BrothWarning] = []

    let maxLiquid = potSizeLiters * 0.82
    if waterLiters > maxLiquid {
        warnings.append(
            BrothWarning(
                code: .waterReducedToFit,
                severity: .warn,
                params: []
            )
        )
    }

    if clarityMode == .paperFilter {
        warnings.append(
            BrothWarning(
                code: .paperFilterLowerIntensity,
                severity: .info,
                params: []
            )
        )

        if yieldLossLiters > 0.6 {
            warnings.append(
                BrothWarning(
                    code: .paperFilterHighLoss,
                    severity: .warn,
                    params: [
                        BrothWarningParameter(key: "yieldLossL", value: yieldLossLiters)
                    ]
                )
            )
        }
    }

    return warnings
}

private func deduplicatedStructuredWarnings(_ warnings: [BrothWarning]) -> [BrothWarning] {
    var seen = Set<BrothWarningCode>()
    return warnings.filter { seen.insert($0.code).inserted }
}

private func warningText(for warning: BrothWarning) -> String {
    switch warning.code {
    case .hardPotTooSmall:
        return "To jest mniej niż 0,25 l. Ustaw realną pojemność garnka."
    case .hardPotTooBig:
        return "To wygląda na literówkę. Maksymalna pojemność w aplikacji to 30 l."
    case .hardTooMuchMeat:
        return "To ilość przemysłowa. Wprowadź wagę mięsa dla jednego garnka."
    case .hardItemTooBig:
        return "Jedna z wag wygląda podejrzanie wysoko. Sprawdź, czy na pewno wpisujesz gramy."
    case .hardNoMeat:
        return "Dodaj mięso. Bez mięsa nie ugotujesz rosołu."
    case .hardNotFit:
        return "Ten zestaw fizycznie nie mieści się w tym garnku. Zmniejsz ilość mięsa albo użyj większego naczynia."
    case .premiumBlocked:
        return "Ten składnik jest dostępny dopiero w rozszerzonej wersji kalkulatora."

    case .undermeatLight:
        return "Wybrałeś mniej mięsa niż zwykle mieści ten garnek. Aplikacja przeliczy rosół do tej ilości, ale jeśli chcesz ugotować większą porcję, możesz dodać jeszcze trochę mięsa."
    case .overmeatLight:
        return "Jak na czystszy profil mięsa jest już sporo. Rosół może wyjść cięższy niż zwykle."
    case .undermeatIntense:
        return "To raczej mniejsza partia jak na tak głęboki profil. Aplikacja przeliczy całość do tej ilości, ale jeśli chcesz mocniejszy efekt i większy uzysk, możesz dodać jeszcze trochę mięsa."
    case .overmeatIntense:
        return "Mięsa jest bardzo dużo. Rosół może wyjść ciężki i trudniejszy do zbalansowania."

    case .overfatLight:
        return "Ten zestaw może wyjść tłusty. Do czystszego profilu lepiej sprawdza się więcej korpusu lub szyi i mniej cięższych elementów."
    case .wingsTooHighLight:
        return "Skrzydełka w większej ilości podbijają tłuszcz. W czystszym rosole warto trzymać je z umiarem."
    case .lowGelatinIntense:
        return "Smak może być głęboki, ale wywar będzie mniej sprężysty, bo jest tu mało kości i kolagenu."
    case .heavyBeefProfile:
        return "Ten zestaw idzie w cięższą, bardziej wołową stronę."
    case .marrowTooHigh:
        return "Jest tu sporo szpiku albo mostka. Rosół może wyjść za ciężki i tłusty."

    case .singleIngredientRisk:
        return "Jeden składnik mocno dominuje w zestawie. Warto lekko go zrównoważyć."
    case .offalDominantRisk:
        return "Podroby są tu już bardzo wyraźne. Lepiej, żeby wspierały bazę, a nie ją przejmowały."
    case .liverTimingRequired:
        return "Wątróbkę dodaj tylko na końcu, na 20–30 minut. Dłuższe gotowanie daje metaliczny posmak i mętność."

    case .paperFilterLowerIntensity:
        return "Filtr papierowy da czystszy rosół, ale finalnie zostanie go mniej i będzie odrobinę lżejszy."
    case .paperFilterHighLoss:
        return "Przy filtrze papierowym strata może być tu wyraźna. Finalnego rosołu zostanie zauważalnie mniej."
    case .waterReducedToFit:
        return "Dla tego zestawu i tego garnka klasyczna ilość wody byłaby za duża, więc policzyliśmy jej mniej. Rosół wyjdzie trochę mocniejszy i będzie go mniej."
    }
}

private func calculateScoring(
    items: [NormalizedMeatItem],
    waterStartLiters: Double
) -> BrothScoring {
    let totalWeight = items.reduce(0) { $0 + $1.grams }

    guard totalWeight > 0, waterStartLiters > 0 else {
        return BrothScoring(
            fatIndex: 0,
            collagenIndex: 0,
            boneShare: 0,
            meatDensityGL: 0,
            oneIngredientShare: 0,
            wingsShare: 0,
            beefShare: 0,
            offalShare: 0,
            marrowHeavyBeefShare: 0
        )
    }

    let totalWeightDouble = Double(totalWeight)

    let fatLoad = items.reduce(0.0) { partial, item in
        partial + (Double(item.grams) * Double(item.profile.fatScore))
    }

    let collagenLoad = items.reduce(0.0) { partial, item in
        partial + (Double(item.grams) * Double(item.profile.collagenScore))
    }

    let boneWeight = items
        .filter { $0.profile.bonesFlag }
        .reduce(0) { $0 + $1.grams }

    let poultryItems = items.filter { $0.profile.family == .poultry }
    let poultryWeight = poultryItems.reduce(0) { $0 + $1.grams }

    let wingsWeight = poultryItems
        .filter { $0.profile.isWingLike }
        .reduce(0) { $0 + $1.grams }

    let beefWeight = items
        .filter { $0.profile.family == .beef }
        .reduce(0) { $0 + $1.grams }

    let offalWeight = items
        .filter { $0.profile.family == .offal }
        .reduce(0) { $0 + $1.grams }

    let marrowHeavyBeefWeight = items
        .filter { $0.profile.family == .beef && $0.profile.isMarrowHeavyBeef }
        .reduce(0) { $0 + $1.grams }

    let maxItemWeight = items.map(\.grams).max() ?? 0

    return BrothScoring(
        fatIndex: fatLoad / totalWeightDouble,
        collagenIndex: collagenLoad / totalWeightDouble,
        boneShare: Double(boneWeight) / totalWeightDouble,
        meatDensityGL: totalWeightDouble / max(0.001, waterStartLiters),
        oneIngredientShare: Double(maxItemWeight) / totalWeightDouble,
        wingsShare: poultryWeight > 0 ? Double(wingsWeight) / Double(poultryWeight) : 0,
        beefShare: Double(beefWeight) / totalWeightDouble,
        offalShare: Double(offalWeight) / totalWeightDouble,
        marrowHeavyBeefShare: beefWeight > 0 ? Double(marrowHeavyBeefWeight) / Double(beefWeight) : 0
    )
}

private func adjustedYield(
    baseYieldLiters: Double,
    waterStartLiters: Double,
    fatIndex: Double,
    clarityMode: BrothClarityMode
) -> (yieldLiters: Double, lossLiters: Double) {
    guard clarityMode == .paperFilter else {
        return (roundedToTwoDecimals(baseYieldLiters), 0)
    }

    let yieldLossL = clamp(
        0.12 * waterStartLiters + 0.10 * fatIndex,
        min: 0.20,
        max: 0.80
    )

    let adjusted = max(0.1, baseYieldLiters - yieldLossL)
    return (roundedToTwoDecimals(adjusted), roundedToTwoDecimals(yieldLossL))
}

private func safeWaterUpperBoundV2(
    potCapacityL: Double,
    totalMeatG: Int,
    vegTotalG: Int
) -> Double {
    let maxLiquidLHeat = potCapacityL * 0.84
    let maxLiquidLMild = potCapacityL * 0.88

    let foamBufferHeat = foamBufferHeatLiters(potCapacityL: potCapacityL)
    let foamBufferMild = foamBufferMildLiters(potCapacityL: potCapacityL)

    let totalSolidsKg = Double(totalMeatG + vegTotalG) / 1000.0
    let displacementL = totalSolidsKg * 0.85

    let waterSafeHeat = maxLiquidLHeat - displacementL - foamBufferHeat
    let waterSafeMild = maxLiquidLMild - displacementL - foamBufferMild

    return roundedToTwoDecimals(min(waterSafeHeat, waterSafeMild))
}

private func foamBufferHeatLiters(potCapacityL: Double) -> Double {
    switch potCapacityL {
    case ..<5.1:
        return 0.20
    case ..<8.1:
        return 0.28
    default:
        return 0.40
    }
}

private func foamBufferMildLiters(potCapacityL: Double) -> Double {
    switch potCapacityL {
    case ..<5.1:
        return 0.10
    case ..<8.1:
        return 0.15
    default:
        return 0.20
    }
}

private func recommendedMeatRange(
    for profile: BrothProfile,
    potCapacityL: Double
) -> BrothRecommendedMeatRange {
    let config = styleConfig(for: profile)

    var maxComfortGrams = 0

    for grams in stride(from: 100, through: 10_000, by: 10) {
        let meatKg = Double(grams) / 1000.0
        let recipeWaterL = meatKg * config.waterFactor
        let vegTotalG = roundedToInt(recipeWaterL * 1000.0 * config.vegPercent)
        let safeWaterL = safeWaterUpperBoundV2(
            potCapacityL: potCapacityL,
            totalMeatG: grams,
            vegTotalG: vegTotalG
        )

        if recipeWaterL <= safeWaterL + 0.0001 {
            maxComfortGrams = grams
        } else {
            break
        }
    }

    if maxComfortGrams <= 0 {
        return BrothRecommendedMeatRange(
            minGrams: 0,
            maxGrams: nil
        )
    }

    let minMultiplier = profile == .cleaner ? 0.72 : 0.78
    let minGrams = max(100, roundedToInt(Double(maxComfortGrams) * minMultiplier))

    return BrothRecommendedMeatRange(
        minGrams: roundedToTen(Double(minGrams)),
        maxGrams: roundedToTen(Double(maxComfortGrams))
    )
}

private func vinegarAmountForPreset(
    profile: BrothProfile,
    useVinegar: Bool
) -> Int {
    guard useVinegar else { return 0 }
    return profile == .cleaner ? 3 : 5
}

private func vinegarAmountForCustom(
    useVinegar: Bool,
    bonesKg: Double
) -> Int {
    guard useVinegar else { return 0 }
    return Int(clamp(2 + Double(roundedToInt(bonesKg * 1.0)), min: 2, max: 6).rounded())
}

private func normalizedPotCapacity(_ raw: Double) -> Double {
    min(max(raw, 0.25), 30.0)
}

private func normalizeID(_ value: String) -> String {
    value
        .folding(options: .diacriticInsensitive, locale: nil)
        .lowercased()
}

private func containsAny(_ value: String, _ phrases: [String]) -> Bool {
    phrases.contains { value.contains($0) }
}

private func interpolate(_ pot: Double, table: [(Double, Double)]) -> Double {
    let sorted = table.sorted { $0.0 < $1.0 }

    guard let first = sorted.first, let last = sorted.last else { return 0 }

    if pot <= first.0 { return first.1 }
    if pot >= last.0 { return last.1 }

    for index in 0..<(sorted.count - 1) {
        let lower = sorted[index]
        let upper = sorted[index + 1]

        if pot >= lower.0 && pot <= upper.0 {
            let progress = (pot - lower.0) / (upper.0 - lower.0)
            return lower.1 + (upper.1 - lower.1) * progress
        }
    }

    return last.1
}

private func minutesLabel(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    return String(format: "%d:%02d", hours, mins)
}

private func roundedToFive(_ value: Double) -> Int {
    Int((value / 5.0).rounded() * 5.0)
}

private func roundedToTen(_ value: Double) -> Int {
    Int((value / 10.0).rounded() * 10.0)
}

private func roundedToInt(_ value: Double) -> Int {
    Int(value.rounded())
}

private func roundedToOneDecimal(_ value: Double) -> Double {
    (value * 10).rounded() / 10
}

private func roundedToTwoDecimals(_ value: Double) -> Double {
    (value * 100).rounded() / 100
}

private func clamp(_ value: Double, min minValue: Double, max maxValue: Double) -> Double {
    Swift.max(minValue, Swift.min(maxValue, value))
}

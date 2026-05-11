import Foundation

enum UltraSpecBridge {

    static func calculateFromCurrentFlow(
        kind: BrothKind,
        styleName: String?,
        potCapacityL: Double,
        selections: [BrothIngredientSelection],
        clarityMode: BrothClarityMode
    ) throws -> UltraSpecCalculationResult {
        let key = UltraSpecStyleKeyResolver.resolve(kind: kind, styleName: styleName)
        return try calculateFromCurrentFlow(
            kind: kind,
            styleKey: key,
            potCapacityL: potCapacityL,
            selections: selections,
            clarityMode: clarityMode
        )
    }

    static func calculateFromCurrentFlow(
        kind: BrothKind,
        styleKey: String,
        potCapacityL: Double,
        selections: [BrothIngredientSelection],
        clarityMode: BrothClarityMode
    ) throws -> UltraSpecCalculationResult {
        let request = UltraSpecRequestBuilder.build(
            kind: kind,
            styleKey: styleKey,
            potCapacityL: potCapacityL,
            selections: selections,
            clarityMode: clarityMode
        )
        return try UltraSpecEngine.calculate(request: request)
    }

    // Converts UltraSpec result to BrothCalculationResult for use in CookingModeView.
    // Used by BatchRecord.calculationResult() so that the cooking banner and deep-link
    // path always receive values from the correct engine.
    static func makeBrothResult(
        from ultra: UltraSpecCalculationResult,
        variant: UltraSpecVariantID,
        selections: [BrothIngredientSelection],
        clarityMode: BrothClarityMode,
        useVinegar: Bool
    ) -> BrothCalculationResult {
        let config = UltraSpecCatalog.variants.first(where: { $0.id == variant })
        let tempMin = config?.temperature.minC ?? 88
        let tempMax = config?.temperature.maxC ?? 92
        let totalMinutes = config?.totalMinutes ?? 180

        return BrothCalculationResult(
            waterLiters: ultra.waterStartL,
            temperatureMin: tempMin,
            temperatureMax: tempMax,
            totalMinutes: totalMinutes,
            estimatedYieldLiters: ultra.estimatedYieldL,
            startSaltGrams: ultra.startSaltG,
            finalSaltGrams: ultra.targetSaltG,
            appleCiderVinegarMl: useVinegar ? max(5, Int((ultra.waterStartL * 2).rounded())) : 0,
            peppercornCount: ultra.spices.peppercornCount,
            allspiceCount: ultra.spices.allspiceCount,
            bayLeafCount: ultra.spices.bayLeafCount,
            vegetables: ultra.vegetables.map {
                VegetableAmount(name: $0.ingredientID, amount: "\($0.grams) g", note: nil)
            },
            meatParts: selections.map { MeatAmount(name: $0.name, grams: $0.grams, note: nil) },
            timeline: UltraSpecTimelineCatalog.steps(for: variant).map {
                .init(minuteOffset: $0.minuteOffset, timeLabel: $0.timeLabel, title: $0.title, subtitle: $0.subtitle)
            },
            warnings: ultra.warningMessages.map { "\($0.title): \($0.message)" },
            structuredWarnings: [],
            validationFailure: nil,
            scoring: nil,
            recommendedMeatRange: nil,
            clarityMode: clarityMode,
            useVinegar: useVinegar,
            targetYieldLiters: nil,
            vegetableBreakdown: nil,
            spiceBreakdown: nil,
            microMode: ultra.waterStartL < 0.7,
            waterWasReducedToFit: ultra.waterStartL < ultra.waterRecipeL
        )
    }
}

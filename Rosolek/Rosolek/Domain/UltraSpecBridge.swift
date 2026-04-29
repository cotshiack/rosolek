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
}

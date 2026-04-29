import Foundation

enum UltraSpecBridge {
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

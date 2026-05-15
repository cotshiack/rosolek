import XCTest
@testable import Rosolek

/// Tests that BatchRecord.calculationResult() routes to the correct engine.
/// Regression for S-3: UltraSpec batches must not use BrothCalculator.
final class BatchRecordEngineRoutingTests: XCTestCase {

    // An UltraSpec batch (brothKindRawValue set) must return values produced
    // by UltraSpecEngine, not by BrothCalculator.
    // Discriminant: tonkotsu config has totalMinutes = 480; legacy BrothCalculator
    // would never return that for an identical weight/style combination.
    func testUltraSpecBatchUsesUltraSpecEngine() throws {
        let snapshot: [BatchIngredientSnapshot] = [
            .init(ingredientID: "kosci_wieprzowe", ingredientName: "Kości wieprzowe", categoryRawValue: IngredientCategory.pork.rawValue, grams: 2000),
            .init(ingredientID: "lapki_wieprzowe", ingredientName: "Łapki wieprzowe", categoryRawValue: IngredientCategory.pork.rawValue, grams: 800)
        ]

        let batch = BatchRecord(
            createdAt: Date(),
            styleRawValue: "custom",
            modeRawValue: "custom",
            brothKindRawValue: BrothKind.ramen.rawValue,
            selectedStyleName: "Tonkotsu",
            clarityModeRawValue: BrothClarityMode.normal.rawValue,
            useVinegar: false,
            totalWeightGrams: 2800,
            selectedIngredientCount: 2,
            waterLiters: 5.0,
            estimatedYieldLiters: 3.5,
            totalMinutes: 480,
            warningCount: 0,
            hasThermometer: true,
            potSizeLitersAtCooking: 7,
            selectedIngredientsSnapshot: snapshot
        )

        let result = batch.calculationResult()

        // Tonkotsu UltraSpec config: totalMinutes = 480, temp min = 95.
        // BrothCalculator would never produce temp 95 for this combination.
        XCTAssertEqual(result.totalMinutes, 480, "UltraSpec tonkotsu totalMinutes should be 480")
        XCTAssertEqual(result.temperatureMin, 95, "UltraSpec tonkotsu temperatureMin should be 95")
    }

    // A legacy batch (no brothKindRawValue) must still use BrothCalculator.
    func testLegacyBatchUsesBrothCalculator() {
        let batch = BatchRecord(
            createdAt: Date(),
            styleRawValue: "light",
            modeRawValue: "legacy",
            brothKindRawValue: nil,
            totalWeightGrams: 1500,
            selectedIngredientCount: 1,
            waterLiters: 3.5,
            estimatedYieldLiters: 2.8,
            totalMinutes: 300,
            warningCount: 0,
            hasThermometer: true,
            potSizeLitersAtCooking: 7,
            selectedIngredientIDs: ["kura"]
        )

        let result = batch.calculationResult()

        // BrothCalculator produces finite, positive values for a simple poultry batch.
        XCTAssertGreaterThan(result.waterLiters, 0)
        XCTAssertGreaterThan(result.totalMinutes, 0)
    }

    // An UltraSpec batch with snapshot but no brothKindRawValue falls back to BrothCalculator.
    func testBatchWithSnapshotButNoKindFallsBackToLegacy() {
        let snapshot: [BatchIngredientSnapshot] = [
            .init(ingredientID: "kura", ingredientName: "Kura", categoryRawValue: IngredientCategory.poultry.rawValue, grams: 1500)
        ]

        let batch = BatchRecord(
            createdAt: Date(),
            styleRawValue: "light",
            modeRawValue: "custom",
            brothKindRawValue: nil,
            totalWeightGrams: 1500,
            selectedIngredientCount: 1,
            waterLiters: 3.5,
            estimatedYieldLiters: 2.8,
            totalMinutes: 315,
            warningCount: 0,
            hasThermometer: true,
            potSizeLitersAtCooking: 7,
            selectedIngredientsSnapshot: snapshot
        )

        let result = batch.calculationResult()

        XCTAssertGreaterThan(result.waterLiters, 0)
        XCTAssertGreaterThan(result.totalMinutes, 0)
    }
}

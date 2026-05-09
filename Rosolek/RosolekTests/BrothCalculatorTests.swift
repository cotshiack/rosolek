import XCTest
@testable import Rosolek

/// Smoke tests for BrothCalculator — the legacy engine with zero previous coverage.
/// These verify basic physical invariants and guard against silent regressions.
final class BrothCalculatorTests: XCTestCase {

    // Every preset should produce finite, positive water and time values.
    func testAllPresetsProducePositiveWaterAndTime() {
        let presets: [BrothPreset] = [.poultryReady, .poultryBeefReady, .grandmaReady, .fishReady, .collagenPoultryReady]
        for preset in presets {
            let result = BrothCalculator.calculate(preset: preset, potSizeLiters: 7)
            XCTAssertGreaterThan(result.waterLiters, 0, "Preset \(preset) waterLiters should be > 0")
            XCTAssertGreaterThan(result.totalMinutes, 0, "Preset \(preset) totalMinutes should be > 0")
            XCTAssertTrue(result.waterLiters.isFinite, "Preset \(preset) waterLiters should be finite")
        }
    }

    // Increasing pot size should produce proportionally more water.
    func testLargerPotProducesMoreWater() {
        let small = BrothCalculator.calculate(preset: .poultryReady, potSizeLiters: 5)
        let large = BrothCalculator.calculate(preset: .poultryReady, potSizeLiters: 9)
        XCTAssertGreaterThan(large.waterLiters, small.waterLiters)
    }

    // Profile+selections path: positive weight should yield positive water.
    func testProfileCalculationProducesPositiveResults() {
        let selections = [
            BrothIngredientSelection(ingredientID: "kura", ingredientName: "Kura", category: .poultry, grams: 1500)
        ]
        let result = BrothCalculator.calculate(
            profile: .cleaner,
            meatItems: selections,
            potSizeLiters: 7.0,
            clarityMode: .normal,
            useVinegar: false
        )
        XCTAssertGreaterThan(result.waterLiters, 0)
        XCTAssertGreaterThan(result.totalMinutes, 0)
        XCTAssertTrue(result.waterLiters.isFinite)
    }

    // Vinegar flag should produce non-zero vinegar amount.
    func testVinegarFlagProducesVinegarAmount() {
        let selections = [
            BrothIngredientSelection(ingredientID: "kura", ingredientName: "Kura", category: .poultry, grams: 1500)
        ]
        let withVinegar = BrothCalculator.calculate(
            profile: .cleaner,
            meatItems: selections,
            potSizeLiters: 7.0,
            clarityMode: .normal,
            useVinegar: true
        )
        let withoutVinegar = BrothCalculator.calculate(
            profile: .cleaner,
            meatItems: selections,
            potSizeLiters: 7.0,
            clarityMode: .normal,
            useVinegar: false
        )
        XCTAssertGreaterThan(withVinegar.appleCiderVinegarMl, 0)
        XCTAssertEqual(withoutVinegar.appleCiderVinegarMl, 0)
    }

    // Zero-weight input should not crash and should return sane fallback.
    func testZeroWeightDoesNotCrash() {
        let result = BrothCalculator.calculate(
            style: .light,
            totalWeightGrams: 0,
            selectedIDs: [],
            potSizeLiters: 7
        )
        XCTAssertTrue(result.waterLiters.isFinite)
        XCTAssertGreaterThanOrEqual(result.waterLiters, 0)
    }
}

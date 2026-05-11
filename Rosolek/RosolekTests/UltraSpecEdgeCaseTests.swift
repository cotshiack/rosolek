import XCTest
@testable import Rosolek

final class UltraSpecEdgeCaseTests: XCTestCase {

    // MARK: - Pot size guards

    func testPotExactlyAtMinimumThresholdSucceeds() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 0.25,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 50)],
            clarityMode: .normal
        )
        XCTAssertNoThrow(try UltraSpecEngine.calculate(request: request))
    }

    func testPotBelowMinimumThrows() {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 0.24,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 50)],
            clarityMode: .normal
        )
        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardPotTooSmall)
        }
    }

    func testPotExactlyAtMaximumThresholdSucceeds() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 30,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1000)],
            clarityMode: .normal
        )
        XCTAssertNoThrow(try UltraSpecEngine.calculate(request: request))
    }

    func testPotAboveMaximumThrows() {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 30.1,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1000)],
            clarityMode: .normal
        )
        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardPotTooBig)
        }
    }

    // MARK: - Meat overload (hardNotFit)

    func testExcessiveMeatOverflowsSmallPot() {
        // 30 kg meat in a 1L pot — displacement alone exceeds pot capacity
        let request = UltraSpecCalculationRequest(
            variant: .rosolBogaty,
            potCapacityL: 1,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 30_000)],
            clarityMode: .normal
        )
        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardNotFit)
        }
    }

    // MARK: - Vegetable-only variants require no animal protein

    func testWarzywnyJasnyWithNoAnimalProteinSucceeds() throws {
        let request = UltraSpecCalculationRequest(
            variant: .warzywnyJasny,
            potCapacityL: 4,
            items: [],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)
        XCTAssertEqual(result.totalAnimalG, 0)
        XCTAssertGreaterThan(result.waterStartL, 0)
    }

    func testWarzywnyUmamiWithNoAnimalProteinSucceeds() throws {
        let request = UltraSpecCalculationRequest(
            variant: .warzywnyUmami,
            potCapacityL: 4,
            items: [],
            clarityMode: .normal
        )
        XCTAssertNoThrow(try UltraSpecEngine.calculate(request: request))
    }

    func testNonVeggieVariantWithNoAnimalProteinThrows() {
        let request = UltraSpecCalculationRequest(
            variant: .rosolBogaty,
            potCapacityL: 4,
            items: [],
            clarityMode: .normal
        )
        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardNoBase)
        }
    }

    // MARK: - Result value sanity

    func testResultValuesAreFiniteAndPositive() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1200)],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)

        XCTAssertTrue(result.waterStartL.isFinite && result.waterStartL > 0)
        XCTAssertTrue(result.estimatedYieldL.isFinite && result.estimatedYieldL > 0)
        XCTAssertTrue(result.densityGL.isFinite && result.densityGL > 0)
        XCTAssertTrue(result.startSaltG.isFinite && result.startSaltG >= 0)
        XCTAssertTrue(result.targetSaltG.isFinite && result.targetSaltG >= 0)
    }

    func testYieldNeverExceedsWaterStart() throws {
        let variants: [UltraSpecVariantID] = [
            .rosolLekki, .rosolBogaty, .ramenShio, .ramenTonkotsu,
            .wolowyMocny, .wolowyCzysty, .warzywnyJasny, .warzywnyUmami
        ]
        for variant in variants {
            let isVeg = (variant == .warzywnyJasny || variant == .warzywnyUmami)
            let items: [UltraSpecInputItem] = isVeg ? [] : [.init(ingredientID: "POULTRY_OLD_HEN", grams: 800)]
            let request = UltraSpecCalculationRequest(
                variant: variant,
                potCapacityL: 6,
                items: items,
                clarityMode: .normal
            )
            let result = try UltraSpecEngine.calculate(request: request)
            XCTAssertLessThanOrEqual(result.estimatedYieldL, result.waterStartL,
                "Variant \(variant): yieldL(\(result.estimatedYieldL)) > waterStartL(\(result.waterStartL))")
        }
    }

    // MARK: - Paper filter reduces yield by ~4 %

    func testPaperFilterReducesYieldByApprox4Percent() throws {
        let base = UltraSpecCalculationRequest(
            variant: .rosolBogaty,
            potCapacityL: 8,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1800)],
            clarityMode: .normal
        )
        let filtered = UltraSpecCalculationRequest(
            variant: .rosolBogaty,
            potCapacityL: 8,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1800)],
            clarityMode: .paperFilter
        )

        let baseResult = try UltraSpecEngine.calculate(request: base)
        let filteredResult = try UltraSpecEngine.calculate(request: filtered)

        let ratio = filteredResult.estimatedYieldL / baseResult.estimatedYieldL
        XCTAssertEqual(ratio, 0.96, accuracy: 0.001)
    }

    // MARK: - Warning deltas are non-negative

    func testWarningDeltasAreNonNegative() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 200)],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)

        for msg in result.warningMessages {
            if let delta = msg.suggestion?.deltaMeatG {
                XCTAssertGreaterThan(delta, 0, "deltaMeatG should be positive for \(msg.code)")
            }
            if let delta = msg.suggestion?.deltaWaterL {
                XCTAssertGreaterThan(delta, 0, "deltaWaterL should be positive for \(msg.code)")
            }
        }
    }

    // MARK: - Pot capacity zero

    func testPotZeroLitersThrowsHardPotTooSmall() {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 0.0,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 500)],
            clarityMode: .normal
        )
        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardPotTooSmall)
        }
    }

    // MARK: - New catalog entries (H-2 fix) are accepted by the engine

    func testOffalHeartIsAcceptedByEngine() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [
                .init(ingredientID: "POULTRY_OLD_HEN", grams: 1000),
                .init(ingredientID: "OFFAL_HEART", grams: 200)
            ],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)
        XCTAssertEqual(result.totalAnimalG, 1200)
    }

    func testOffalGizzardIsAcceptedByEngine() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [
                .init(ingredientID: "POULTRY_OLD_HEN", grams: 1000),
                .init(ingredientID: "OFFAL_GIZZARD", grams: 200)
            ],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)
        XCTAssertEqual(result.totalAnimalG, 1200)
    }

    func testPoultryFeetIsAcceptedByEngine() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [
                .init(ingredientID: "POULTRY_OLD_HEN", grams: 800),
                .init(ingredientID: "POULTRY_FEET", grams: 400)
            ],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)
        XCTAssertEqual(result.totalAnimalG, 1200)
    }

    // MARK: - Unknown ingredient ID is silently ignored

    func testUnknownIngredientIDIsIgnored() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [
                .init(ingredientID: "POULTRY_OLD_HEN", grams: 1000),
                .init(ingredientID: "totally_unknown_ingredient_xyz", grams: 999)
            ],
            clarityMode: .normal
        )
        let result = try UltraSpecEngine.calculate(request: request)
        // Only known ingredient should count
        XCTAssertEqual(result.totalAnimalG, 1000)
    }
}

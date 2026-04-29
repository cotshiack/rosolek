import XCTest
@testable import Rosolek

final class UltraSpecEngineTests: XCTestCase {
    func testRosolLekkiUnderpowerSuggestsAddingBase() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 7,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 400)],
            clarityMode: .normal
        )

        let result = try UltraSpecEngine.calculate(request: request)

        XCTAssertTrue(result.warnings.contains("UNDERPOWER"))
        let underpower = try XCTUnwrap(result.warningMessages.first(where: { $0.code == .underpower }))
        XCTAssertEqual(underpower.severity, .warn)
        XCTAssertNotNil(underpower.suggestion?.deltaMeatG)
    }

    func testOverpowerSuggestsAddingWater() throws {
        let request = UltraSpecCalculationRequest(
            variant: .ramenTonkotsu,
            potCapacityL: 5,
            items: [.init(ingredientID: "PORK_JOINT_BONES", grams: 7000)],
            clarityMode: .normal
        )

        let result = try UltraSpecEngine.calculate(request: request)

        XCTAssertTrue(result.warnings.contains("OVERPOWER"))
        let overpower = try XCTUnwrap(result.warningMessages.first(where: { $0.code == .overpower }))
        XCTAssertGreaterThan(overpower.suggestion?.deltaWaterL ?? 0, 0)
    }

    func testPaperFilterAddsInfoWarning() throws {
        let request = UltraSpecCalculationRequest(
            variant: .rosolBogaty,
            potCapacityL: 8,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 1800)],
            clarityMode: .paperFilter
        )

        let result = try UltraSpecEngine.calculate(request: request)

        XCTAssertTrue(result.warnings.contains("PAPER_FILTER_LOWER_INTENSITY"))
        let info = try XCTUnwrap(result.warningMessages.first(where: { $0.code == .paperFilterLowerIntensity }))
        XCTAssertEqual(info.severity, .info)
    }

    func testHardPotTooSmallThrowsError() {
        let request = UltraSpecCalculationRequest(
            variant: .rosolLekki,
            potCapacityL: 0.2,
            items: [.init(ingredientID: "POULTRY_OLD_HEN", grams: 500)],
            clarityMode: .normal
        )

        XCTAssertThrowsError(try UltraSpecEngine.calculate(request: request)) { error in
            XCTAssertEqual(error as? UltraSpecEngineError, .hardPotTooSmall)
        }
    }
}

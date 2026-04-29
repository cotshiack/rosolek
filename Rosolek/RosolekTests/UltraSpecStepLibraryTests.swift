import XCTest
@testable import Rosolek

final class UltraSpecStepLibraryTests: XCTestCase {
    func testStepLibraryContainsCoreSteps() {
        XCTAssertNotNil(UltraSpecStepLibrary.all["prep"])
        XCTAssertNotNil(UltraSpecStepLibrary.all["heat_up_clear"])
        XCTAssertNotNil(UltraSpecStepLibrary.all["strain_season"])
    }

    func testLibraryContainsRestAndAddVegSteps() {
        XCTAssertNotNil(UltraSpecStepLibrary.all["rest_settle"])
        XCTAssertNotNil(UltraSpecStepLibrary.all["add_veg_spices"])
    }

    func testTonkotsuStepMentionsWaterLevel() {
        let step = UltraSpecStepLibrary.tonkotsuBoil
        XCTAssertTrue(step.extendedHint.lowercased().contains("przykryte"))
    }
}

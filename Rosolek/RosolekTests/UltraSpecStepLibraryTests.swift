import XCTest
@testable import Rosolek

final class UltraSpecStepLibraryTests: XCTestCase {
    func testStepLibraryContainsCoreSteps() {
        XCTAssertNotNil(UltraSpecStepLibrary.all["prep"])
        XCTAssertNotNil(UltraSpecStepLibrary.all["heat_up_clear"])
        XCTAssertNotNil(UltraSpecStepLibrary.all["strain_season"])
    }

    func testTonkotsuStepMentionsWaterLevel() {
        let step = UltraSpecStepLibrary.tonkotsuBoil
        XCTAssertTrue(step.extendedHint.lowercased().contains("przykryte"))
    }
}

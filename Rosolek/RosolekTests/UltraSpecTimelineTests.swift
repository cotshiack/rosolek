import XCTest
@testable import Rosolek

final class UltraSpecTimelineTests: XCTestCase {
    func testTonkotsuTimelineHasBoilStage() {
        let steps = UltraSpecTimelineCatalog.steps(for: .ramenTonkotsu)
        XCTAssertFalse(steps.isEmpty)
        XCTAssertTrue(steps.contains(where: { $0.title.lowercased().contains("tonkotsu") || $0.subtitle.lowercased().contains("wrzenie") }))
    }

    func testEveryTimelineStepHasDrawerDefinition() {
        for variant in UltraSpecVariantID.allCases {
            let steps = UltraSpecTimelineCatalog.steps(for: variant)
            for step in steps {
                XCTAssertNotNil(UltraSpecStepLibrary.all[step.stepID], "Missing drawer definition for stepID: \(step.stepID)")
            }
        }
    }

    func testFishDelicateTimelineDurationEndsAt45() {
        let steps = UltraSpecTimelineCatalog.steps(for: .rybnyDelikatny)
        XCTAssertEqual(steps.last?.minuteOffset, 45)
    }
}

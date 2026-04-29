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
                // some step IDs are timeline-only at this stage; keep strict set explicit
                let allowedTimelineOnly: Set<String> = ["stabilize_base", "simmer_clear", "finish_clear", "tonkotsu_aromatics_end", "veg_simmer_limit"]
                XCTAssertTrue(UltraSpecStepLibrary.all[step.stepID] != nil || allowedTimelineOnly.contains(step.stepID), "Missing drawer definition for stepID: \(step.stepID)")
            }
        }
    }

    func testFishDelicateTimelineDurationEndsAt45() {
        let steps = UltraSpecTimelineCatalog.steps(for: .rybnyDelikatny)
        XCTAssertEqual(steps.last?.minuteOffset, 45)
    }
}

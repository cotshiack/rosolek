import XCTest
@testable import Rosolek

final class UltraSpecTimelineTests: XCTestCase {
    func testTonkotsuTimelineHasBoilStage() {
        let steps = UltraSpecTimelineCatalog.steps(for: .ramenTonkotsu)
        XCTAssertFalse(steps.isEmpty)
        XCTAssertTrue(steps.contains(where: { $0.title.lowercased().contains("tonkotsu") || $0.subtitle.lowercased().contains("wrzenie") }))
    }

    func testFishDelicateTimelineDurationEndsAt45() {
        let steps = UltraSpecTimelineCatalog.steps(for: .rybnyDelikatny)
        XCTAssertEqual(steps.last?.minuteOffset, 45)
    }
}

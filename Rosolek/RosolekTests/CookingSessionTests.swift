import XCTest
@testable import Rosolek

final class CookingSessionTests: XCTestCase {

    private let storageKey = "cooking_session_active_v1"

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - Save / load round-trip

    func testSaveAndLoadRoundTrip() {
        let id = UUID()
        var session = CookingSession(
            batchID: id,
            phaseIndex: 2,
            phaseElapsedSeconds: 345,
            processElapsedSeconds: 1200,
            isStageRunning: true,
            prepMeatReady: true,
            prepWaterReady: false,
            prepPotReady: true,
            prepThermometerReady: false,
            prepVinegarReady: true
        )
        session.currentPhaseTitle = "Gotowanie właściwe"
        session.currentPhaseTotalSeconds = 7200
        session.overallRemainingSeconds = 5400

        session.save()

        let loaded = CookingSession.load()
        XCTAssertNotNil(loaded)
        XCTAssertEqual(loaded?.batchID, id)
        XCTAssertEqual(loaded?.phaseIndex, 2)
        XCTAssertEqual(loaded?.phaseElapsedSeconds, 345)
        XCTAssertEqual(loaded?.processElapsedSeconds, 1200)
        XCTAssertTrue(loaded?.isStageRunning ?? false)
        XCTAssertTrue(loaded?.prepMeatReady ?? false)
        XCTAssertFalse(loaded?.prepWaterReady ?? true)
        XCTAssertEqual(loaded?.currentPhaseTitle, "Gotowanie właściwe")
        XCTAssertEqual(loaded?.currentPhaseTotalSeconds, 7200)
        XCTAssertEqual(loaded?.overallRemainingSeconds, 5400)
    }

    func testLoadReturnsNilWhenNoDataStored() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        XCTAssertNil(CookingSession.load())
    }

    func testClearRemovesSession() {
        let session = CookingSession(
            batchID: UUID(),
            phaseIndex: 0,
            phaseElapsedSeconds: 0,
            processElapsedSeconds: 0,
            isStageRunning: false,
            prepMeatReady: false,
            prepWaterReady: false,
            prepPotReady: false,
            prepThermometerReady: false,
            prepVinegarReady: false
        )
        session.save()
        XCTAssertNotNil(CookingSession.load())

        CookingSession.clear()
        XCTAssertNil(CookingSession.load())
    }

    // MARK: - Overwrite

    func testSavingNewSessionOverwritesPrevious() {
        let id1 = UUID()
        let id2 = UUID()

        CookingSession(batchID: id1, phaseIndex: 1, phaseElapsedSeconds: 0,
                       processElapsedSeconds: 0, isStageRunning: false,
                       prepMeatReady: false, prepWaterReady: false, prepPotReady: false,
                       prepThermometerReady: false, prepVinegarReady: false).save()

        CookingSession(batchID: id2, phaseIndex: 3, phaseElapsedSeconds: 999,
                       processElapsedSeconds: 2000, isStageRunning: true,
                       prepMeatReady: true, prepWaterReady: true, prepPotReady: true,
                       prepThermometerReady: false, prepVinegarReady: false).save()

        let loaded = CookingSession.load()
        XCTAssertEqual(loaded?.batchID, id2)
        XCTAssertEqual(loaded?.phaseIndex, 3)
        XCTAssertEqual(loaded?.phaseElapsedSeconds, 999)
    }

    // MARK: - Garbled data

    func testLoadReturnsNilForGarbledData() {
        let garbage = Data("corrupt session data".utf8)
        UserDefaults.standard.set(garbage, forKey: storageKey)
        XCTAssertNil(CookingSession.load())
    }

    // MARK: - Optional fields

    func testBackgroundedAtIsPreserved() {
        let backgroundDate = Date(timeIntervalSince1970: 1_713_500_000)
        var session = CookingSession(
            batchID: UUID(),
            phaseIndex: 0,
            phaseElapsedSeconds: 0,
            processElapsedSeconds: 0,
            isStageRunning: false,
            prepMeatReady: false,
            prepWaterReady: false,
            prepPotReady: false,
            prepThermometerReady: false,
            prepVinegarReady: false
        )
        session.backgroundedAt = backgroundDate
        session.save()

        let loaded = CookingSession.load()
        XCTAssertEqual(loaded?.backgroundedAt?.timeIntervalSince1970,
                       backgroundDate.timeIntervalSince1970,
                       accuracy: 0.001)
    }
}

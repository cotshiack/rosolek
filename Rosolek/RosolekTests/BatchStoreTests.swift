import XCTest
@testable import Rosolek

final class BatchStoreTests: XCTestCase {

    private let testKey = "rosolek_batches_v1"

    override func tearDown() {
        super.tearDown()
        UserDefaults.standard.removeObject(forKey: testKey)
    }

    // MARK: - Basic CRUD

    func testCreateBatchAppearsInStore() {
        let store = BatchStore()
        let before = store.batches.count

        store.createBatch(
            styleRawValue: "light",
            totalWeightGrams: 1200,
            selectedIngredientCount: 2,
            waterLiters: 4.0,
            estimatedYieldLiters: 3.2,
            totalMinutes: 240,
            warningCount: 0,
            hasThermometer: false
        )

        XCTAssertEqual(store.batches.count, before + 1)
    }

    func testDeleteBatchRemovesFromStore() {
        let store = BatchStore()
        let batch = store.createBatch(
            styleRawValue: "light",
            totalWeightGrams: 1000,
            selectedIngredientCount: 1,
            waterLiters: 3.5,
            estimatedYieldLiters: 2.8,
            totalMinutes: 200,
            warningCount: 0,
            hasThermometer: false
        )

        store.deleteBatch(id: batch.id)
        XCTAssertNil(store.batch(for: batch.id))
    }

    func testUpdateFeedbackPersists() {
        let store = BatchStore()
        let batch = store.createBatch(
            styleRawValue: "intense",
            totalWeightGrams: 1500,
            selectedIngredientCount: 3,
            waterLiters: 4.5,
            estimatedYieldLiters: 3.6,
            totalMinutes: 300,
            warningCount: 1,
            hasThermometer: true
        )

        store.updateFeedback(
            batchID: batch.id,
            overallRating: 8,
            strengthFeedbackRawValue: "good",
            fatFeedbackRawValue: nil,
            clarityFeedbackRawValue: nil,
            actualYieldLiters: 3.4,
            notes: "Dobry wynik"
        )

        let updated = store.batch(for: batch.id)
        XCTAssertEqual(updated?.overallRating, 8)
        XCTAssertEqual(updated?.actualYieldLiters, 3.4)
        XCTAssertEqual(updated?.notes, "Dobry wynik")
    }

    func testUpdateTitleNormalizesWhitespace() {
        let store = BatchStore()
        let batch = store.createBatch(
            styleRawValue: "light",
            totalWeightGrams: 1000,
            selectedIngredientCount: 1,
            waterLiters: 3.0,
            estimatedYieldLiters: 2.4,
            totalMinutes: 180,
            warningCount: 0,
            hasThermometer: false
        )

        store.updateTitle(batchID: batch.id, customTitle: "  Rosół niedzielny  ")
        XCTAssertEqual(store.batch(for: batch.id)?.customTitle, "Rosół niedzielny")
    }

    func testUpdateTitleWithBlankStringSetsNil() {
        let store = BatchStore()
        let batch = store.createBatch(
            styleRawValue: "light",
            totalWeightGrams: 1000,
            selectedIngredientCount: 1,
            waterLiters: 3.0,
            estimatedYieldLiters: 2.4,
            totalMinutes: 180,
            warningCount: 0,
            hasThermometer: false,
            customTitle: "Stary tytuł"
        )

        store.updateTitle(batchID: batch.id, customTitle: "   ")
        XCTAssertNil(store.batch(for: batch.id)?.customTitle)
    }

    func testBatchesAreSortedByCreatedAtDescending() {
        let store = BatchStore()
        store.createBatch(styleRawValue: "a", totalWeightGrams: 1000, selectedIngredientCount: 1,
                          waterLiters: 3, estimatedYieldLiters: 2, totalMinutes: 100, warningCount: 0, hasThermometer: false)
        store.createBatch(styleRawValue: "b", totalWeightGrams: 1000, selectedIngredientCount: 1,
                          waterLiters: 3, estimatedYieldLiters: 2, totalMinutes: 100, warningCount: 0, hasThermometer: false)

        let dates = store.batches.map(\.createdAt)
        let sorted = dates.sorted(by: >)
        XCTAssertEqual(dates, sorted)
    }

    // MARK: - Persistence round-trip

    func testStoreReloadsFromUserDefaults() {
        let store1 = BatchStore()
        let batch = store1.createBatch(
            styleRawValue: "custom_roundtrip",
            totalWeightGrams: 2000,
            selectedIngredientCount: 5,
            waterLiters: 5.0,
            estimatedYieldLiters: 4.0,
            totalMinutes: 360,
            warningCount: 0,
            hasThermometer: true,
            customTitle: "Roundtrip test"
        )

        let store2 = BatchStore()
        let reloaded = store2.batch(for: batch.id)
        XCTAssertNotNil(reloaded)
        XCTAssertEqual(reloaded?.customTitle, "Roundtrip test")
        XCTAssertEqual(reloaded?.totalWeightGrams, 2000)
    }

    // MARK: - C-1 fix: per-element recovery from corrupted data

    func testRecoveryFromPartiallyCorruptedArray() throws {
        // Build two valid records and inject one corrupt element between them.
        let goodRecord1 = BatchRecord(
            createdAt: Date(timeIntervalSince1970: 1_713_000_000),
            styleRawValue: "light",
            totalWeightGrams: 1100,
            selectedIngredientCount: 2,
            waterLiters: 3.5,
            estimatedYieldLiters: 2.8,
            totalMinutes: 200,
            warningCount: 0,
            hasThermometer: false
        )
        let goodRecord2 = BatchRecord(
            createdAt: Date(timeIntervalSince1970: 1_713_001_000),
            styleRawValue: "rich",
            totalWeightGrams: 1800,
            selectedIngredientCount: 4,
            waterLiters: 5.0,
            estimatedYieldLiters: 4.0,
            totalMinutes: 300,
            warningCount: 1,
            hasThermometer: true
        )

        let encoder = JSONEncoder()
        let dict1 = try JSONSerialization.jsonObject(with: encoder.encode(goodRecord1))
        let dict2 = try JSONSerialization.jsonObject(with: encoder.encode(goodRecord2))
        let corrupt: [String: Any] = ["id": "not-a-uuid", "totalWeightGrams": "wrong_type"]

        let mixedArray = [dict1, corrupt, dict2]
        let mixedData = try JSONSerialization.data(withJSONObject: mixedArray)
        UserDefaults.standard.set(mixedData, forKey: testKey)

        let store = BatchStore()
        // Both good records should be recovered; the corrupt element is skipped.
        XCTAssertEqual(store.batches.count, 2)
        let ids = store.batches.map(\.id)
        XCTAssertTrue(ids.contains(goodRecord1.id))
        XCTAssertTrue(ids.contains(goodRecord2.id))
    }

    func testRecoveryFromCompletelyGarbledData() {
        let garbage = Data("not json at all ¡@#$%".utf8)
        UserDefaults.standard.set(garbage, forKey: testKey)

        let store = BatchStore()
        XCTAssertEqual(store.batches.count, 0)
    }

    func testRecoveryFromAllCorruptElements() throws {
        let corrupt1: [String: Any] = ["id": "bad", "createdAt": "not-a-date"]
        let corrupt2: [String: Any] = ["foo": 42]
        let allCorrupt = [corrupt1, corrupt2]
        let data = try JSONSerialization.data(withJSONObject: allCorrupt)
        UserDefaults.standard.set(data, forKey: testKey)

        let store = BatchStore()
        XCTAssertEqual(store.batches.count, 0)
    }

    func testEmptyUserDefaultsProducesEmptyStore() {
        UserDefaults.standard.removeObject(forKey: testKey)
        let store = BatchStore()
        XCTAssertEqual(store.batches.count, 0)
    }
}

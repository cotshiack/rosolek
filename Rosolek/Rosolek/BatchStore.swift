import Foundation
import Combine

final class BatchStore: ObservableObject {
    @Published private(set) var batches: [BatchRecord] = []

    private let storageKey = "rosolek_batches_v1"

    init() {
        load()
    }

    @discardableResult
    func createBatch(
        styleRawValue: String,
        totalWeightGrams: Int,
        selectedIngredientCount: Int,
        waterLiters: Double,
        estimatedYieldLiters: Double,
        totalMinutes: Int,
        warningCount: Int,
        hasThermometer: Bool,
        selectedIngredientIDs: [String]? = nil,
        customTitle: String? = nil,
        modeRawValue: String = "legacy",
        presetRawValue: String? = nil,
        profileRawValue: String? = nil,
        brothKindRawValue: String? = nil,
        selectedStyleName: String? = nil,
        clarityModeRawValue: String = BrothClarityMode.normal.rawValue,
        useVinegar: Bool = false,
        activeCookingMinutes: Int? = nil,
        selectedIngredientsSnapshot: [BatchIngredientSnapshot]? = nil,
        meatOverrides: [String: Int]? = nil,
        vegetableOverrides: [String: Int]? = nil,
        spiceOverrides: [String: Int]? = nil
    ) -> BatchRecord {
        let batch = BatchRecord(
            createdAt: Date(),
            styleRawValue: styleRawValue,
            modeRawValue: modeRawValue,
            presetRawValue: presetRawValue,
            profileRawValue: profileRawValue,
            brothKindRawValue: brothKindRawValue,
            selectedStyleName: selectedStyleName,
            clarityModeRawValue: clarityModeRawValue,
            useVinegar: useVinegar,
            totalWeightGrams: totalWeightGrams,
            selectedIngredientCount: selectedIngredientCount,
            waterLiters: waterLiters,
            estimatedYieldLiters: estimatedYieldLiters,
            totalMinutes: totalMinutes,
            activeCookingMinutes: activeCookingMinutes,
            warningCount: warningCount,
            hasThermometer: hasThermometer,
            selectedIngredientIDs: selectedIngredientIDs,
            selectedIngredientsSnapshot: selectedIngredientsSnapshot,
            meatOverrides: meatOverrides,
            vegetableOverrides: vegetableOverrides,
            spiceOverrides: spiceOverrides,
            customTitle: normalizedTitle(customTitle)
        )

        batches.insert(batch, at: 0)
        sortBatches()
        save()
        return batch
    }

    @discardableResult
    func createBatch(
        styleRawValue: String,
        modeRawValue: String,
        presetRawValue: String?,
        profileRawValue: String?,
        brothKindRawValue: String? = nil,
        selectedStyleName: String? = nil,
        clarityModeRawValue: String,
        useVinegar: Bool,
        totalWeightGrams: Int,
        selectedIngredientCount: Int,
        waterLiters: Double,
        estimatedYieldLiters: Double,
        totalMinutes: Int,
        activeCookingMinutes: Int,
        warningCount: Int,
        hasThermometer: Bool,
        selectedIngredientIDs: [String]? = nil,
        selectedIngredientsSnapshot: [BatchIngredientSnapshot]? = nil,
        meatOverrides: [String: Int]? = nil,
        vegetableOverrides: [String: Int]? = nil,
        spiceOverrides: [String: Int]? = nil,
        customTitle: String? = nil
    ) -> BatchRecord {
        createBatch(
            styleRawValue: styleRawValue,
            totalWeightGrams: totalWeightGrams,
            selectedIngredientCount: selectedIngredientCount,
            waterLiters: waterLiters,
            estimatedYieldLiters: estimatedYieldLiters,
            totalMinutes: totalMinutes,
            warningCount: warningCount,
            hasThermometer: hasThermometer,
            selectedIngredientIDs: selectedIngredientIDs,
            customTitle: customTitle,
            modeRawValue: modeRawValue,
            presetRawValue: presetRawValue,
            profileRawValue: profileRawValue,
            brothKindRawValue: brothKindRawValue,
            selectedStyleName: selectedStyleName,
            clarityModeRawValue: clarityModeRawValue,
            useVinegar: useVinegar,
            activeCookingMinutes: activeCookingMinutes,
            selectedIngredientsSnapshot: selectedIngredientsSnapshot,
            meatOverrides: meatOverrides,
            vegetableOverrides: vegetableOverrides,
            spiceOverrides: spiceOverrides
        )
    }

    func updateFeedback(
        batchID: UUID,
        overallRating: Int,
        strengthFeedbackRawValue: String?,
        fatFeedbackRawValue: String?,
        clarityFeedbackRawValue: String?,
        actualYieldLiters: Double?,
        notes: String
    ) {
        guard let index = batches.firstIndex(where: { $0.id == batchID }) else { return }

        batches[index].overallRating = min(10, max(1, overallRating))
        batches[index].strengthFeedbackRawValue = strengthFeedbackRawValue
        batches[index].fatFeedbackRawValue = fatFeedbackRawValue
        batches[index].clarityFeedbackRawValue = clarityFeedbackRawValue
        batches[index].actualYieldLiters = actualYieldLiters
        batches[index].notes = notes

        save()
    }

    func updateTitle(
        batchID: UUID,
        customTitle: String
    ) {
        guard let index = batches.firstIndex(where: { $0.id == batchID }) else { return }

        batches[index].customTitle = normalizedTitle(customTitle)
        save()
    }

    func markBatchInterruptedByNewCooking(batchID: UUID, at date: Date = Date()) {
        guard let index = batches.firstIndex(where: { $0.id == batchID }) else { return }

        batches[index].cookingOutcomeRawValue = CookingOutcome.interruptedByNewCooking.rawValue
        batches[index].interruptedAt = date

        let interruptionNote = "Gotowanie przerwane po uruchomieniu nowego przepisu."
        let currentNotes = batches[index].notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if currentNotes.isEmpty {
            batches[index].notes = interruptionNote
        } else if !currentNotes.localizedCaseInsensitiveContains("przerwane") {
            batches[index].notes = currentNotes + "\n\n" + interruptionNote
        }

        save()
    }

    func deleteBatch(id: UUID) {
        batches.removeAll { $0.id == id }
        save()
    }

    func batch(for id: UUID) -> BatchRecord? {
        batches.first(where: { $0.id == id })
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(batches)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Nie udało się zapisać batchy: \(error.localizedDescription)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            batches = []
            return
        }

        do {
            batches = try JSONDecoder().decode([BatchRecord].self, from: data)
            sortBatches()
        } catch {
            print("BatchStore: decode całej tablicy nie powiódł się (\(error.localizedDescription)), próba per-element.")
            batches = recoverBatchesFromCorruptedData(data)
            sortBatches()
        }
    }

    private func recoverBatchesFromCorruptedData(_ data: Data) -> [BatchRecord] {
        guard let rawArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            print("BatchStore: dane nie są tablicą JSON — historia niedostępna.")
            return []
        }
        let decoder = JSONDecoder()
        let recovered = rawArray.compactMap { dict -> BatchRecord? in
            guard let elementData = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return try? decoder.decode(BatchRecord.self, from: elementData)
        }
        print("BatchStore: odzyskano \(recovered.count)/\(rawArray.count) rekordów.")
        return recovered
    }

    private func sortBatches() {
        batches.sort { $0.createdAt > $1.createdAt }
    }

    private func normalizedTitle(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

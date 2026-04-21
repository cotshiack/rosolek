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
        profileRawValue: String? = nil,
        clarityModeRawValue: String = BrothClarityMode.normal.rawValue,
        useVinegar: Bool = false,
        activeCookingMinutes: Int? = nil,
        selectedIngredientsSnapshot: [BatchIngredientSnapshot]? = nil
    ) -> BatchRecord {
        let batch = BatchRecord(
            createdAt: Date(),
            styleRawValue: styleRawValue,
            modeRawValue: modeRawValue,
            profileRawValue: profileRawValue,
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
        profileRawValue: String?,
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
            profileRawValue: profileRawValue,
            clarityModeRawValue: clarityModeRawValue,
            useVinegar: useVinegar,
            activeCookingMinutes: activeCookingMinutes,
            selectedIngredientsSnapshot: selectedIngredientsSnapshot
        )
    }

    func updateFeedback(
        batchID: UUID,
        overallRating: Int,
        strengthFeedbackRawValue: String?,
        fatFeedbackRawValue: String?,
        clarityFeedbackRawValue: String?,
        notes: String
    ) {
        guard let index = batches.firstIndex(where: { $0.id == batchID }) else { return }

        batches[index].overallRating = overallRating
        batches[index].strengthFeedbackRawValue = strengthFeedbackRawValue
        batches[index].fatFeedbackRawValue = fatFeedbackRawValue
        batches[index].clarityFeedbackRawValue = clarityFeedbackRawValue
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
            print("Nie udało się wczytać batchy: \(error.localizedDescription)")
            batches = []
        }
    }

    private func sortBatches() {
        batches.sort { $0.createdAt > $1.createdAt }
    }

    private func normalizedTitle(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }
}

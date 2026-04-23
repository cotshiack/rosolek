import SwiftUI

struct LastBatchDetailView: View {
    @EnvironmentObject private var batchStore: BatchStore
    @Environment(\.dismiss) private var dismiss

    let batchID: UUID

    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteAlert = false

    private var batch: BatchRecord? {
        batchStore.batch(for: batchID)
    }

    var body: some View {
        Group {
            if let batch {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        summaryCard(batch)
                        cookingSection(batch)
                        qualitySection(batch)
                        notesSection(batch)
                        replaySection(batch)
                    }
                    .padding(AppSpacing.screen)
                    .padding(.bottom, 40)
                }
                .background(AppTheme.background)
                .navigationTitle("Szczegóły")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                renameText = batch.customTitle ?? ""
                                showRenameAlert = true
                            } label: {
                                Label("Zmień nazwę", systemImage: "pencil")
                            }

                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("Usuń z historii", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 19, weight: .semibold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }
                .sheet(isPresented: $showRenameAlert) {
                    BatchRenameSheet(
                        defaultTitle: batch.defaultTitle,
                        renameText: $renameText
                    ) {
                        batchStore.updateTitle(batchID: batch.id, customTitle: renameText)
                    }
                }
                .alert("Usunąć wpis z historii?", isPresented: $showDeleteAlert) {
                    Button("Usuń", role: .destructive) {
                        batchStore.deleteBatch(id: batch.id)
                        dismiss()
                    }

                    Button("Anuluj", role: .cancel) {}
                } message: {
                    Text("Usuniesz \(batch.displayTitle). Tej operacji nie da się cofnąć.")
                }
            } else {
                missingBatchState
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Szczegóły gotowania")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Tu widzisz parametry gotowania, ocenę partii i możesz łatwo wrócić do tego samego przepisu.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func summaryCard(_ batch: BatchRecord) -> some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(batch.displayTitle)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)

                        Text(batch.createdAtDisplayText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer(minLength: 8)

                    DetailRatingBadge(
                        text: batch.ratingBadgeText,
                        hasRating: batch.overallRating != nil
                    )
                }

                HStack(spacing: 8) {
                    DetailMetaChip(kind: .time, title: batch.timeDisplayText)
                    DetailMetaChip(kind: .yield, title: batch.yieldDisplayText)
                    DetailMetaChip(kind: .profile, title: batch.profileTitle)
                }
            }
        }
        .appSoftShadow()
    }

    private func cookingSection(_ batch: BatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionLabel(text: "Parametry gotowania")

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    AppInfoRow(title: "Styl", value: batch.profileTitle.lowercased())
                    AppInfoRow(title: "Masa mięsa", value: batch.weightDisplayText)
                    AppInfoRow(title: "Woda start", value: batch.waterDisplayText)
                    AppInfoRow(title: "Szacowany uzysk", value: batch.yieldDisplayText)
                    AppInfoRow(title: "Czas gotowania", value: batch.timeDisplayText)
                    AppInfoRow(title: "Liczba składników", value: batch.ingredientCountDisplayText)
                    AppInfoRow(title: "Termometr", value: batch.thermometerDisplayText)

                    if let interruption = batch.interruptionDisplayText {
                        AppInfoRow(title: "Status", value: interruption)
                    }

                    if batch.warningCount > 0 {
                        AppInfoRow(title: "Uwagi kalkulatora", value: "\(batch.warningCount)")
                    }
                }
            }
            .appSoftShadow()
        }
    }

    private func qualitySection(_ batch: BatchRecord) -> some View {
        let strength = strengthValue(for: batch)
        let fat = fatValue(for: batch)
        let clarity = clarityValue(for: batch)

        return Group {
            if batch.overallRating != nil || strength != nil || fat != nil || clarity != nil {
                VStack(alignment: .leading, spacing: 10) {
                    AppSectionLabel(text: "Ocena partii")

                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            if let rating = batch.overallRating {
                                AppInfoRow(title: "Ocena ogólna", value: "\(rating)/10")
                            }

                            if let strength {
                                AppInfoRow(title: "Moc", value: strength)
                            }

                            if let fat {
                                AppInfoRow(title: "Tłustość", value: fat)
                            }

                            if let clarity {
                                AppInfoRow(title: "Klarowność", value: clarity)
                            }

                            if strength == nil && fat == nil && clarity == nil {
                                Text("Brak szczegółowej oceny")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                        }
                    }
                    .appSoftShadow()
                }
            }
        }
    }

    private func notesSection(_ batch: BatchRecord) -> some View {
        Group {
            if !batch.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    AppSectionLabel(text: "Notatka")

                    AppCard {
                        Text(batch.notes)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .appSoftShadow()
                }
            }
        }
    }

    private func replaySection(_ batch: BatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let replayIngredientIDs = batch.selectedIngredientIDs, !replayIngredientIDs.isEmpty {
                NavigationLink {
                    BrothResultView(
                        mode: .custom(batch.brothProfile),
                        totalWeight: batch.totalWeightGrams,
                        selectedIngredientCount: replayIngredientIDs.count,
                        selectedIDs: replayIngredientIDs,
                        initialSelections: batch.selectedIngredientsSnapshot?.map {
                            BrothIngredientSelection(
                                ingredientID: $0.ingredientID,
                                ingredientName: $0.ingredientName,
                                category: IngredientCategory(rawValue: $0.categoryRawValue) ?? .poultry,
                                grams: $0.grams
                            )
                        } ?? []
                    )
                } label: {
                    AppPrimaryButtonLabel(title: "Ugotuj ponownie")
                }
            } else {
                AppCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Brak pełnego zapisu składników")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Ten batch był zapisany w starszej wersji aplikacji, która nie przechowywała listy składników. Możesz jednak zacząć nowe gotowanie z tym samym profilem (\(batch.profileTitle)).")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)

                        NavigationLink {
                            BrothStyleSelectionView()
                        } label: {
                            AppSecondaryButtonLabel(title: "Zacznij nowe gotowanie")
                        }
                        .padding(.top, 4)
                    }
                }
                .appSoftShadow()
            }
        }
    }

    private var missingBatchState: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ten wpis nie jest już dostępny")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Prawdopodobnie został usunięty z historii.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                AppCard {
                    Text("Wróć do historii i wybierz inny zapisany batch.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .appSoftShadow()
            }
            .padding(AppSpacing.screen)
        }
        .background(AppTheme.background)
        .navigationTitle("Szczegóły")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func strengthValue(for batch: BatchRecord) -> String? {
        guard let raw = batch.strengthFeedbackRawValue else { return nil }
        return BatchStrengthFeedback(rawValue: raw)?.title
    }

    private func fatValue(for batch: BatchRecord) -> String? {
        guard let raw = batch.fatFeedbackRawValue else { return nil }
        return BatchFatFeedback(rawValue: raw)?.title
    }

    private func clarityValue(for batch: BatchRecord) -> String? {
        guard let raw = batch.clarityFeedbackRawValue else { return nil }
        return BatchClarityFeedback(rawValue: raw)?.title
    }
}

private struct DetailRatingBadge: View {
    let text: String
    let hasRating: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(hasRating ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 10)
            .frame(height: 30)
            .background(hasRating ? AppTheme.accent : AppTheme.surfaceMuted)
            .overlay(
                Capsule()
                    .stroke(hasRating ? AppTheme.accent : AppTheme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private enum DetailMetaKind {
    case time
    case yield
    case profile
}

private struct DetailMetaChip: View {
    let kind: DetailMetaKind
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            DetailMetaGlyph(kind: kind)

            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .foregroundStyle(AppTheme.textPrimary.opacity(0.86))
        .padding(.horizontal, 10)
        .frame(height: 28)
        .background(
            Capsule()
                .fill(AppTheme.surfaceMuted)
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}

private struct DetailMetaGlyph: View {
    let kind: DetailMetaKind

    var body: some View {
        Group {
            switch kind {
            case .time:
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .semibold))
            case .yield:
                AppYieldGlyph()
            case .profile:
                AppProfileGlyph()
            }
        }
        .frame(width: 12, height: 12)
    }
}

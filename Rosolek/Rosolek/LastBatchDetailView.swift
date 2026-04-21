import SwiftUI

struct LastBatchDetailView: View {
    @EnvironmentObject private var batchStore: BatchStore
    @Environment(\.dismiss) private var dismiss

    let batchID: UUID

    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var showDeleteAlert = false
    @State private var showFeedback = false

    private var batch: BatchRecord? {
        batchStore.batch(for: batchID)
    }

    var body: some View {
        Group {
            if let batch {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        header(for: batch)
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
                .navigationDestination(isPresented: $showFeedback) {
                    BatchFeedbackView(batch: batch, standaloneMode: true)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button {
                                showFeedback = true
                            } label: {
                                Label(
                                    batch.overallRating != nil ? "Edytuj ocenę" : "Oceń tę partię",
                                    systemImage: "star"
                                )
                            }

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

    private func header(for batch: BatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(batch.displayTitle)
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
                    Text(batch.createdAtDisplayText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    Spacer(minLength: 8)

                    SharedRatingBadge(
                        text: batch.ratingBadgeText,
                        hasRating: batch.overallRating != nil
                    )
                }

                HStack(spacing: 8) {
                    AppMetaChip(metric: AppMetaMetric(kind: .time, title: batch.timeDisplayText))
                    AppMetaChip(metric: AppMetaMetric(kind: .yield, title: batch.yieldDisplayText))
                    AppMetaChip(metric: AppMetaMetric(kind: .profile, title: batch.profileTitle))
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

                    if batch.warningCount > 0 {
                        AppInfoRow(title: "Uwagi kalkulatora", value: "\(batch.warningCount)")
                    }
                }
            }
            .appSoftShadow()
        }
    }

    private func qualitySection(_ batch: BatchRecord) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            AppSectionLabel(text: "Ocena partii")

            if batch.overallRating != nil {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        if let rating = batch.overallRating {
                            AppInfoRow(title: "Ocena ogólna", value: "\(rating)/10")
                        }

                        if let raw = batch.strengthFeedbackRawValue,
                           let value = BatchStrengthFeedback(rawValue: raw) {
                            AppInfoRow(title: "Moc", value: value.title)
                        }

                        if let raw = batch.fatFeedbackRawValue,
                           let value = BatchFatFeedback(rawValue: raw) {
                            AppInfoRow(title: "Tłustość", value: value.title)
                        }

                        if let raw = batch.clarityFeedbackRawValue,
                           let value = BatchClarityFeedback(rawValue: raw) {
                            AppInfoRow(title: "Klarowność", value: value.title)
                        }
                    }
                }
                .appSoftShadow()
            } else {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ta partia nie ma jeszcze oceny.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                        Button {
                            showFeedback = true
                        } label: {
                            AppPrimaryButtonLabel(title: "Oceń tę partię")
                        }
                    }
                }
                .appSoftShadow()
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
}

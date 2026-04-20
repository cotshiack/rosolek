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
                .alert("Zmień nazwę rosołu", isPresented: $showRenameAlert) {
                    TextField(batch.defaultTitle, text: $renameText)

                    Button("Zapisz") {
                        batchStore.updateTitle(batchID: batch.id, customTitle: renameText)
                    }

                    Button("Anuluj", role: .cancel) {}
                } message: {
                    Text("Zostaw puste pole, aby wrócić do nazwy domyślnej: „\(batch.defaultTitle)”.")
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
                        selectedStyle: batch.styleRawValue == BrothStyle.intense.rawValue ? .intense : .light,
                        totalWeight: batch.totalWeightGrams,
                        selectedIngredientCount: replayIngredientIDs.count,
                        selectedIDs: replayIngredientIDs
                    )
                } label: {
                    AppPrimaryButtonLabel(title: "Ugotuj ponownie")
                }
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ten starszy batch nie ma pełnego zapisu składników.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    NavigationLink {
                        BrothStyleSelectionView()
                    } label: {
                        AppSecondaryButtonLabel(title: "Przejdź do kalkulatora")
                    }
                }
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
            .foregroundStyle(AppTheme.textPrimary)
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
                DetailYieldGlyph()
            case .profile:
                DetailProfileGlyph()
            }
        }
        .frame(width: 12, height: 12)
    }
}

private struct DetailYieldGlyph: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .stroke(AppTheme.textPrimary.opacity(0.82), lineWidth: 1.35)
                .frame(width: 10, height: 10)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(AppTheme.accent.opacity(0.95))
                .frame(width: 8, height: 4)
                .offset(y: -1)
        }
    }
}

private struct DetailProfileGlyph: View {
    var body: some View {
        VStack(spacing: 2) {
            Capsule()
                .fill(AppTheme.textPrimary.opacity(0.82))
                .frame(width: 10, height: 3)

            Capsule()
                .fill(AppTheme.accent.opacity(0.95))
                .frame(width: 7, height: 3)
        }
    }
}

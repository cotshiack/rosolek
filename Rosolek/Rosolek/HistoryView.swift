import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var batchStore: BatchStore

    @State private var selectedBatch: BatchRecord?
    @State private var batchToDelete: BatchRecord?
    @State private var batchToRename: BatchRecord?
    @State private var renameText = ""

    var body: some View {
        Group {
            if batchStore.batches.isEmpty {
                emptyState
            } else {
                historyList
            }
        }
        .background(AppTheme.background)
        .navigationTitle("Historia")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedBatch) { batch in
            LastBatchDetailView(batchID: batch.id)
        }
        .alert("Usuń wpis z historii?", isPresented: deleteBinding, presenting: batchToDelete) { batch in
            Button("Usuń", role: .destructive) {
                batchStore.deleteBatch(id: batch.id)
            }
            Button("Anuluj", role: .cancel) {}
        } message: { batch in
            Text("Usuniesz \(batch.displayTitle). Tej operacji nie da się cofnąć.")
        }
        .sheet(item: $batchToRename) { batch in
            BatchRenameSheet(
                defaultTitle: batch.defaultTitle,
                renameText: $renameText
            ) {
                batchStore.updateTitle(batchID: batch.id, customTitle: renameText)
            }
        }
    }

    private var historyList: some View {
        List {
            headerSection

            Section {
                ForEach(batchStore.batches) { batch in
                    Button {
                        selectedBatch = batch
                    } label: {
                        BatchHistoryCompactCard(batch: batch)
                            .padding(.horizontal, AppSpacing.screen)
                            .padding(.vertical, 4)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .listRowBackground(AppTheme.background)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            batchToDelete = batch
                        } label: {
                            Label("Usuń", systemImage: "trash")
                        }

                        Button {
                            renameText = batch.customTitle ?? ""
                            batchToRename = batch
                        } label: {
                            Label("Zmień nazwę", systemImage: "pencil")
                        }
                        .tint(AppTheme.accentPressed)
                    }
                }
            } footer: {
                Text("Przesuń kartę w lewo, aby zmienić nazwę albo usunąć wpis.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .textCase(nil)
                    .padding(.top, 8)
                    .padding(.horizontal, AppSpacing.screen)
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: batchStore.batches.count)
    }

    private var totalCookingHours: Int {
        batchStore.batches.reduce(0) { $0 + $1.activeCookingMinutes } / 60
    }

    private var totalYieldLiters: Double {
        batchStore.batches.reduce(0.0) { $0 + ($1.actualYieldLiters ?? $1.estimatedYieldLiters) }
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Text("Wszystkie zapisane\ngotowania")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Tu zapisują się Twoje ostatnie partie rosołu wraz z oceną i notatkami. Dotknij karty, aby zobaczyć szczegóły.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                statsCard
                    .padding(.top, 2)
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, 10)
            .padding(.bottom, 10)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(AppTheme.background)
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statTile(
                icon: "fork.knife",
                value: "\(batchStore.batches.count)",
                label: batchStore.batches.count == 1 ? "partia" : "partii"
            )

            statDivider

            statTile(
                icon: "clock.fill",
                value: totalCookingHours > 0 ? "\(totalCookingHours)" : "—",
                label: "godz. gotowania"
            )

            statDivider

            statTile(
                icon: "drop.fill",
                value: totalYieldLiters > 0
                    ? String(format: totalYieldLiters >= 100 ? "%.0f l" : "%.1f l", totalYieldLiters)
                    : "—",
                label: "bulionu"
            )
        }
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppTheme.accent.opacity(0.5), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }

    private func statTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.accent)

            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(AppTheme.accent.opacity(0.18))
            .frame(width: 1)
            .padding(.vertical, 10)
    }

    private var emptyState: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Historia")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Tu zapisują się ostatnie partie rosołu wraz z oceną i notatkami.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Brak zapisanych batchy")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text("Gdy uruchomisz gotowanie z ekranu wyniku, partia pojawi się tutaj automatycznie.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .appSoftShadow()
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, 24)
        }
    }

    private var deleteBinding: Binding<Bool> {
        Binding(
            get: { batchToDelete != nil },
            set: { newValue in
                if !newValue { batchToDelete = nil }
            }
        )
    }

}

private struct BatchHistoryCompactCard: View {
    let batch: BatchRecord

    var body: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(batch.displayTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .lineLimit(2)

                        Text(batch.createdAtDisplayText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)

                        if let outcomeBadge = batch.cookingOutcome.badgeTitle {
                            Text(outcomeBadge)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .padding(.horizontal, 8)
                                .frame(height: 22)
                                .background(AppTheme.warning)
                                .clipShape(Capsule())
                        }
                    }

                    Spacer(minLength: 8)

                    HistoryRatingBadge(
                        text: batch.ratingBadgeText,
                        hasRating: batch.overallRating != nil
                    )
                }

                HStack(spacing: 8) {
                    HistoryMetaChip(kind: .time, title: batch.timeDisplayText)
                    HistoryMetaChip(kind: .yield, title: batch.yieldDisplayText)
                    HistoryMetaChip(kind: .profile, title: batch.profileTitle)
                    if batch.hasManualOverrides {
                        HistoryMetaChip(kind: .adjusted, title: "Modyfikacje")
                    }
                }

                if !batch.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .overlay(AppTheme.border)

                    Text(batch.notes)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let interruption = batch.interruptionDisplayText {
                    Divider()
                        .overlay(AppTheme.border)

                    Text(interruption)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.warning)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appSoftShadow()
    }
}

private struct HistoryRatingBadge: View {
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

private enum HistoryMetaKind {
    case time
    case yield
    case profile
    case adjusted
}

private struct HistoryMetaChip: View {
    let kind: HistoryMetaKind
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            HistoryMetaGlyph(kind: kind)

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

private struct HistoryMetaGlyph: View {
    let kind: HistoryMetaKind

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
            case .adjusted:
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 10, weight: .semibold))
            }
        }
        .frame(width: 12, height: 12)
    }
}

struct BatchRenameSheet: View {
    let defaultTitle: String
    @Binding var renameText: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var renameFieldFocused: Bool

    private var previewName: String {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? defaultTitle : trimmed
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Podgląd")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                    Text(previewName)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .animation(.easeInOut(duration: 0.12), value: previewName)
                }
                .padding(AppSpacing.card)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.accentSoft)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                )

                TextField(defaultTitle, text: $renameText)
                    .focused($renameFieldFocused)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.done)
                    .onSubmit {
                        renameFieldFocused = false
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 54)
                    .background(AppTheme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))

                Text("Zostaw puste, aby wrócić do nazwy domyślnej.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer()
            }
            .padding(AppSpacing.screen)
            .background(AppTheme.background)
            .navigationTitle("Zmień nazwę")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Anuluj") { dismiss() }
                        .foregroundStyle(AppTheme.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zapisz") {
                        onSave()
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    renameFieldFocused = true
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

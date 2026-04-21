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
            }
            .listSectionSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
    }

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text("Wszystkie zapisane\ngotowania")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("Tu zapisują się Twoje ostatnie partie rosołu wraz z oceną i notatkami. Dotknij karty, aby zobaczyć szczegóły.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Przesuń kartę w lewo, aby zmienić nazwę lub usunąć.")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(AppTheme.textSecondary)
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
                        Text("Brak zapisanych partii")
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
                    }

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

                if !batch.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Divider()
                        .overlay(AppTheme.border)

                    Text(batch.notes)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appSoftShadow()
    }
}

struct BatchRenameSheet: View {
    let defaultTitle: String
    @Binding var renameText: String
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var fieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                TextField(defaultTitle, text: $renameText)
                    .focused($fieldFocused)
                    .font(.system(size: 19, weight: .bold))
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
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear { fieldFocused = true }
    }
}

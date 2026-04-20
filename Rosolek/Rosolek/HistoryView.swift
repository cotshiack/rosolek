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
            Text("Usuniesz „\(batch.displayTitle)". Tej operacji nie da się cofnąć.")
        }
        .alert("Zmień nazwę rosołu", isPresented: renameBinding, presenting: batchToRename) { batch in
            TextField(batch.defaultTitle, text: $renameText)

            Button("Zapisz") {
                batchStore.updateTitle(batchID: batch.id, customTitle: renameText)
            }

            Button("Anuluj", role: .cancel) {}
        } message: { batch in
            Text("Zostaw puste pole, aby wrócić do nazwy domyślnej: „\(batch.defaultTitle)”.")
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

    private var renameBinding: Binding<Bool> {
        Binding(
            get: { batchToRename != nil },
            set: { newValue in
                if !newValue { batchToRename = nil }
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

                    HistoryRatingBadge(
                        text: batch.ratingBadgeText,
                        hasRating: batch.overallRating != nil
                    )
                }

                HStack(spacing: 8) {
                    HistoryMetaChip(kind: .time, title: batch.timeDisplayText)
                    HistoryMetaChip(kind: .yield, title: batch.yieldDisplayText)
                    HistoryMetaChip(kind: .profile, title: batch.profileTitle)
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

private struct HistoryRatingBadge: View {
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

private enum HistoryMetaKind {
    case time
    case yield
    case profile
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
                HistoryYieldGlyph()
            case .profile:
                HistoryProfileGlyph()
            }
        }
        .frame(width: 12, height: 12)
    }
}

private struct HistoryYieldGlyph: View {
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

private struct HistoryProfileGlyph: View {
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

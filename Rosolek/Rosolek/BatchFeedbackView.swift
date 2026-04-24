import SwiftUI

private protocol BrothFeedbackOption: CaseIterable, Hashable, RawRepresentable where RawValue == String {
    var title: String { get }
    var iconName: String { get }
}

enum BatchStrengthFeedback: String, CaseIterable, BrothFeedbackOption {
    case tooWeak
    case ideal
    case tooStrong

    var title: String {
        switch self {
        case .tooWeak: return "Za lekki"
        case .ideal: return "Idealny"
        case .tooStrong: return "Za mocny"
        }
    }

    var iconName: String {
        switch self {
        case .tooWeak: return "drop"
        case .ideal: return "sparkles"
        case .tooStrong: return "flame"
        }
    }
}

enum BatchFatFeedback: String, CaseIterable, BrothFeedbackOption {
    case tooLean
    case ideal
    case tooFat

    var title: String {
        switch self {
        case .tooLean: return "Za chudy"
        case .ideal: return "Idealny"
        case .tooFat: return "Za tłusty"
        }
    }

    var iconName: String {
        switch self {
        case .tooLean: return "leaf"
        case .ideal: return "circle.lefthalf.filled"
        case .tooFat: return "drop.fill"
        }
    }
}

enum BatchClarityFeedback: String, CaseIterable, BrothFeedbackOption {
    case cloudy
    case medium
    case clear

    var title: String {
        switch self {
        case .cloudy: return "Mętny"
        case .medium: return "Średni"
        case .clear: return "Klarowny"
        }
    }

    var iconName: String {
        switch self {
        case .cloudy: return "cloud.fog"
        case .medium: return "sun.haze"
        case .clear: return "sun.max"
        }
    }
}

struct BatchFeedbackView: View {
    @EnvironmentObject private var batchStore: BatchStore
    @AppStorage("returnToHomeTrigger") private var returnToHomeTrigger = 0
    @Environment(\.dismiss) private var dismiss
    @FocusState private var notesFieldFocused: Bool
    @FocusState private var focusedField: FeedbackInputField?

    let batch: BatchRecord
    var standaloneMode: Bool = false

    @State private var batchName: String
    @State private var overallRating: Double
    @State private var strengthFeedback: BatchStrengthFeedback?
    @State private var fatFeedback: BatchFatFeedback?
    @State private var clarityFeedback: BatchClarityFeedback?
    @State private var notes: String

    private enum FeedbackInputField {
        case batchName
    }

    init(batch: BatchRecord, standaloneMode: Bool = false) {
        self.batch = batch
        self.standaloneMode = standaloneMode
        _batchName = State(initialValue: batch.customTitle ?? batch.defaultTitle)
        _overallRating = State(initialValue: Double(batch.overallRating ?? 8))
        _strengthFeedback = State(initialValue: batch.strengthFeedbackRawValue.flatMap { BatchStrengthFeedback(rawValue: $0) })
        _fatFeedback = State(initialValue: batch.fatFeedbackRawValue.flatMap { BatchFatFeedback(rawValue: $0) })
        _clarityFeedback = State(initialValue: batch.clarityFeedbackRawValue.flatMap { BatchClarityFeedback(rawValue: $0) })
        _notes = State(initialValue: batch.notes)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                nameSection
                overallRatingSection
                criteriaSection
                notesSection
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("Ocena rosołu")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomActionBar
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if notesFieldFocused {
                    Spacer()
                    Button("Gotowe") {
                        notesFieldFocused = false
                    }
                    .font(.system(size: 15, weight: .semibold))
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Jak wyszedł ten rosół?")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Szybka ocena pomoże lepiej dobrać proporcje i powtarzać najlepsze efekty przy kolejnym gotowaniu.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var nameSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Nazwa partii")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text("Opcjonalnie")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                TextField(batch.defaultTitle, text: $batchName)
                    .focused($focusedField, equals: .batchName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .submitLabel(.done)
                    .onSubmit {
                        focusedField = nil
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(AppTheme.surfaceMuted)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    )
            }
        }
        .appSoftShadow()
    }

    private var overallRatingSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Ocena ogólna")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text("\(Int(overallRating.rounded()))/10")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                }

                Text(ratingDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2, reservesSpace: true)

                Slider(value: $overallRating, in: 1...10, step: 1)
                    .tint(AppTheme.accent)
            }
        }
        .appSoftShadow()
    }

    private var criteriaSection: some View {
        VStack(spacing: 16) {
            feedbackCard(
                title: "Moc smaku",
                subtitle: "Czy wywar ma odpowiednią intensywność?",
                selection: $strengthFeedback,
                options: BatchStrengthFeedback.allCases
            )

            feedbackCard(
                title: "Tłustość",
                subtitle: "Czy ilość tłuszczu daje dobre wrażenie w ustach?",
                selection: $fatFeedback,
                options: BatchFatFeedback.allCases
            )

            feedbackCard(
                title: "Klarowność",
                subtitle: "Jak wygląda finalny rosół w misce lub talerzu?",
                selection: $clarityFeedback,
                options: BatchClarityFeedback.allCases
            )
        }
    }

    private var notesSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Notatka")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text("Opcjonalnie")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                        .fill(AppTheme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                                .stroke(AppTheme.border, lineWidth: 1)
                        )

                    if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text("Np. za mało warzyw, świetna klarowność, następnym razem mniej soli…")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }

                    TextEditor(text: $notes)
                        .focused($notesFieldFocused)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 110)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                }
            }
        }
        .appSoftShadow()
    }

    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.border.opacity(0.6))
                .frame(height: 1)

            Button {
                saveFeedback()
            } label: {
                AppPrimaryButtonLabel(title: "Zapisz ocenę")
            }
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func feedbackCard<T: BrothFeedbackOption>(
        title: String,
        subtitle: String,
        selection: Binding<T?>,
        options: T.AllCases
    ) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                HStack(spacing: 8) {
                    ForEach(Array(options), id: \.rawValue) { option in
                        brothChoiceButton(
                            option: option,
                            isSelected: selection.wrappedValue == option
                        ) {
                            selection.wrappedValue = option
                        }
                    }
                }
            }
        }
        .appSoftShadow()
    }

    private func brothChoiceButton<T: BrothFeedbackOption>(
        option: T,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: option.iconName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isSelected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .frame(width: 32, height: 32)

                Text(option.title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .frame(maxWidth: .infinity, minHeight: 88)
            .padding(.horizontal, 8)
            .background(isSelected ? AppTheme.accent : AppTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous)
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.button, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var ratingDescription: String {
        let value = Int(overallRating.rounded())

        switch value {
        case 1...4:
            return "Rosół do poprawki — czas i proporcje wymagają korekty."
        case 5...6:
            return "Solidna baza — jest z czego budować przy następnej próbie."
        case 7...8:
            return "Bardzo dobry wynik, bliski powtarzalnego przepisu."
        case 9...10:
            return "Perfekcyjny rosół — warto zapamiętać te proporcje."
        default:
            return "Oceń ogólne wrażenie po spróbowaniu."
        }
    }

    private func saveFeedback() {
        notesFieldFocused = false

        batchStore.updateTitle(batchID: batch.id, customTitle: batchName.trimmingCharacters(in: .whitespacesAndNewlines))

        batchStore.updateFeedback(
            batchID: batch.id,
            overallRating: Int(overallRating.rounded()),
            strengthFeedbackRawValue: strengthFeedback?.rawValue,
            fatFeedbackRawValue: fatFeedback?.rawValue,
            clarityFeedbackRawValue: clarityFeedback?.rawValue,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        if standaloneMode {
            dismiss()
        } else {
            returnToHomeTrigger += 1
        }
    }
}

import SwiftUI

enum IngredientCategory: String, CaseIterable, Identifiable, Hashable {
    case poultry = "Drób"
    case beef = "Wołowina"
    case offal = "Podroby"

    var id: String { rawValue }
}

enum IngredientIllustrationKind: Hashable {
    case chicken
    case chickenBones
    case chickenWings
    case turkey
    case duck
    case beef
    case bones
    case hearts
    case gizzards
    case liver
}

struct IngredientOption: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let category: IngredientCategory
    let illustration: IngredientIllustrationKind
    let fatScore: Double
    let gelatinScore: Double
    let clarityPenalty: Double
    let isPoultry: Bool
    let isBeef: Bool
    let isOffal: Bool
    let isLiver: Bool
    let isBoneHeavy: Bool
}

struct BrothIngredientSelection: Identifiable, Hashable {
    let ingredientID: String
    let ingredientName: String
    let category: IngredientCategory
    let grams: Int

    var id: String { ingredientID }
    var name: String { ingredientName }
    var selectedID: String { ingredientID }
    var optionID: String { ingredientID }
    var amountGrams: Int { grams }
}

enum FloatingStatusTone {
    case neutral
    case good
    case warning
    case danger
}

struct QuickInsight {
    let systemImage: String
    let shortText: String
    let detailText: String
    let tone: FloatingStatusTone
}

struct IngredientSelectionView: View {
    let selectedProfile: BrothProfile

    @AppStorage("potSizeLiters") private var potSizeLiters = 7

    @State private var amounts: [String: String] = [:]
    @State private var expandedCategory: IngredientCategory? = nil
    @State private var navigateToSummary = false

    @FocusState private var focusedFieldID: String?

    init(selectedProfile: BrothProfile) {
        self.selectedProfile = selectedProfile
    }

    private let ingredients: [IngredientOption] = [
        .init(id: "kura", name: "Kura rosołowa / porcja rosołowa", subtitle: "Mocna baza i pełny smak.", category: .poultry, illustration: .chicken, fatScore: 1.2, gelatinScore: 1.0, clarityPenalty: 0.4, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "korpus_kurczaka", name: "Korpus z kurczaka", subtitle: "Lekka baza i czystszy profil.", category: .poultry, illustration: .chickenBones, fatScore: 0.9, gelatinScore: 1.2, clarityPenalty: 0.4, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "skrzydla_kurczaka", name: "Skrzydła z kurczaka", subtitle: "Smak i trochę tłustości.", category: .poultry, illustration: .chickenWings, fatScore: 1.3, gelatinScore: 0.8, clarityPenalty: 0.7, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "szyje_kurczaka", name: "Szyje z kurczaka", subtitle: "Kolagen i głębia.", category: .poultry, illustration: .chickenBones, fatScore: 1.0, gelatinScore: 1.5, clarityPenalty: 0.6, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "lapki", name: "Łapki z kurczaka", subtitle: "Dużo żelatyny i body.", category: .poultry, illustration: .chickenBones, fatScore: 0.7, gelatinScore: 2.0, clarityPenalty: 0.5, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "szyja_indyka", name: "Szyja z indyka", subtitle: "Kolagen i struktura.", category: .poultry, illustration: .turkey, fatScore: 1.0, gelatinScore: 1.5, clarityPenalty: 0.6, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "skrzydlo_indyka", name: "Skrzydło z indyka", subtitle: "Pełniejszy smak i trochę tłustości.", category: .poultry, illustration: .turkey, fatScore: 1.4, gelatinScore: 1.0, clarityPenalty: 0.8, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "korpus_indyka", name: "Korpus z indyka", subtitle: "Pełniejsza baza i więcej kolagenu.", category: .poultry, illustration: .turkey, fatScore: 1.1, gelatinScore: 1.4, clarityPenalty: 0.7, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "korpus_kaczki", name: "Korpus z kaczki", subtitle: "Bogaty smak i wyższa tłustość.", category: .poultry, illustration: .duck, fatScore: 2.0, gelatinScore: 1.1, clarityPenalty: 1.4, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "szyja_kaczki", name: "Szyja z kaczki", subtitle: "Głębia, tłustość i więcej body.", category: .poultry, illustration: .duck, fatScore: 1.8, gelatinScore: 1.4, clarityPenalty: 1.2, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "skrzydla_kaczki", name: "Skrzydła z kaczki", subtitle: "Wyraźniejszy charakter i tłustość.", category: .poultry, illustration: .duck, fatScore: 1.9, gelatinScore: 0.9, clarityPenalty: 1.3, isPoultry: true, isBeef: false, isOffal: false, isLiver: false, isBoneHeavy: false),

        .init(id: "szponder", name: "Szponder", subtitle: "Klasyczna baza wołowa.", category: .beef, illustration: .beef, fatScore: 1.7, gelatinScore: 1.1, clarityPenalty: 1.0, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "prega", name: "Pręga", subtitle: "Smak, włókno i kolagen.", category: .beef, illustration: .beef, fatScore: 1.2, gelatinScore: 1.6, clarityPenalty: 0.8, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "mostek", name: "Mostek", subtitle: "Głębia i wyższa tłustość.", category: .beef, illustration: .beef, fatScore: 1.9, gelatinScore: 1.0, clarityPenalty: 1.2, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: false),
        .init(id: "golen", name: "Goleń wołowa", subtitle: "Struktura i żelatyna.", category: .beef, illustration: .bones, fatScore: 1.1, gelatinScore: 1.8, clarityPenalty: 0.8, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "ogon", name: "Ogon wołowy", subtitle: "Mocna żelatyna i długi finisz.", category: .beef, illustration: .bones, fatScore: 1.6, gelatinScore: 2.0, clarityPenalty: 1.0, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "kosci_szpikowe", name: "Kości szpikowe", subtitle: "Ciało, tłustość i cięższy profil.", category: .beef, illustration: .bones, fatScore: 2.2, gelatinScore: 1.4, clarityPenalty: 1.6, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: true),
        .init(id: "kosci_rosolowe", name: "Kości rosołowe / stawowe", subtitle: "Baza kolagenowa i głębia.", category: .beef, illustration: .bones, fatScore: 1.0, gelatinScore: 1.9, clarityPenalty: 0.9, isPoultry: false, isBeef: true, isOffal: false, isLiver: false, isBoneHeavy: true),

        .init(id: "serca", name: "Serca drobiowe", subtitle: "Głębia i lekko mineralny smak.", category: .offal, illustration: .hearts, fatScore: 1.1, gelatinScore: 0.4, clarityPenalty: 1.0, isPoultry: false, isBeef: false, isOffal: true, isLiver: false, isBoneHeavy: false),
        .init(id: "zoladki", name: "Żołądki drobiowe", subtitle: "Wytrawny smak i więcej charakteru.", category: .offal, illustration: .gizzards, fatScore: 0.8, gelatinScore: 0.8, clarityPenalty: 0.9, isPoultry: false, isBeef: false, isOffal: true, isLiver: false, isBoneHeavy: false),
        .init(id: "watrobka", name: "Wątróbka drobiowa", subtitle: "Bardzo intensywna. Używaj ostrożnie.", category: .offal, illustration: .liver, fatScore: 1.0, gelatinScore: 0.3, clarityPenalty: 1.9, isPoultry: false, isBeef: false, isOffal: true, isLiver: true, isBoneHeavy: false)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                header
                categorySections
                diagnosticsSection
            }
            .padding(AppSpacing.screen)
            .padding(.bottom, 8)
        }
        .background(AppTheme.background)
        .navigationTitle("Składniki")
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Gotowe") {
                    focusedFieldID = nil
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            floatingBottomBar
        }
        .navigationDestination(isPresented: $navigateToSummary) {
            BrothResultView(
                profile: selectedProfile,
                selections: selectedIngredients
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dodaj mięso\ndo własnego rosołu")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text("Profil „\(selectedProfile.title)” ustawia kierunek wywaru. Teraz wybierz części i wagę.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var categorySections: some View {
        VStack(spacing: 14) {
            ForEach(IngredientCategory.allCases) { category in
                IngredientCategorySection(
                    category: category,
                    items: ingredients.filter { $0.category == category },
                    isExpanded: expandedCategory == category,
                    amounts: $amounts,
                    focusedFieldID: $focusedFieldID,
                    onToggle: {
                        withAnimation(.spring(response: 0.26, dampingFraction: 0.9)) {
                            expandedCategory = expandedCategory == category ? nil : category
                        }
                    }
                )
            }
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ocena zestawu")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            AppCard {
                VStack(alignment: .leading, spacing: 14) {
                    IngredientDiagnosticRow(title: "Baza", value: baseLabel)
                    IngredientDiagnosticRow(title: "Tłustość", value: fatLabel)
                    IngredientDiagnosticRow(title: "Kolagen", value: gelatinLabel)
                    IngredientDiagnosticRow(title: "Kości", value: boneShareLabel)
                    IngredientDiagnosticRow(title: "Zakres", value: recommendedRangeText)
                    IngredientDiagnosticRow(title: "Woda", value: waterPreviewText)
                    IngredientDiagnosticRow(title: "Uzysk", value: yieldPreviewText)
                }
            }
            .appSoftShadow()
        }
    }

    private var floatingBottomBar: some View {
        VStack(spacing: 10) {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        FloatingSummaryChip(
                            title: selectedIngredientCount == 0 ? "0 skład." : "\(selectedIngredientCount) skład."
                        )

                        FloatingSummaryChip(
                            title: totalWeight == 0 ? "0 g" : gramsString(totalWeight)
                        )
                    }

                    FloatingStatusPanel(insight: quickInsight)
                }
            }
            .appSoftShadow()

            Button {
                guard canProceed else { return }
                focusedFieldID = nil
                navigateToSummary = true
            } label: {
                AppPrimaryButtonLabel(
                    title: "Przejdź do obliczeń",
                    disabled: !canProceed
                )
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, AppSpacing.screen)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .background(
            AppTheme.background
                .opacity(0.98)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var selectedEntries: [(IngredientOption, Int)] {
        ingredients.compactMap { option in
            let value = Int(amounts[option.id] ?? "") ?? 0
            return value > 0 ? (option, value) : nil
        }
    }

    var selectedIngredients: [BrothIngredientSelection] {
        selectedEntries.map {
            BrothIngredientSelection(
                ingredientID: $0.0.id,
                ingredientName: $0.0.name,
                category: $0.0.category,
                grams: $0.1
            )
        }
    }

    private var totalWeight: Int {
        selectedEntries.reduce(0) { $0 + $1.1 }
    }

    private var selectedIngredientCount: Int {
        selectedEntries.count
    }

    private var previewResult: BrothCalculationResult {
        BrothCalculator.calculate(
            profile: selectedProfile,
            meatItems: selectedIngredients,
            potSizeLiters: Double(potSizeLiters),
            clarityMode: .normal,
            useVinegar: false
        )
    }

    private var scoring: BrothScoring? {
        previewResult.scoring
    }

    private var canProceed: Bool {
        previewResult.validationFailure == nil
    }

    private var recommendedRangeText: String {
        guard let range = previewResult.recommendedMeatRange else {
            return "Brak danych"
        }

        if let maxGrams = range.maxGrams {
            return "\(kilogramsText(range.minGrams))–\(kilogramsText(maxGrams))"
        }

        return "od \(kilogramsText(range.minGrams))"
    }

    private var fatLabel: String {
        guard let fatIndex = scoring?.fatIndex, totalWeight > 0 else { return "Brak danych" }

        switch fatIndex {
        case ..<1.0:
            return "Niska"
        case ..<1.6:
            return "Średnia"
        default:
            return "Wysoka"
        }
    }

    private var gelatinLabel: String {
        guard let collagenIndex = scoring?.collagenIndex, totalWeight > 0 else { return "Brak danych" }

        switch collagenIndex {
        case ..<0.9:
            return "Niski"
        case ..<1.5:
            return "Średni"
        default:
            return "Wysoki"
        }
    }

    private var boneShareLabel: String {
        guard let boneShare = scoring?.boneShare, totalWeight > 0 else { return "Brak danych" }
        return percentString(boneShare)
    }

    private var baseLabel: String {
        guard let scoring, totalWeight > 0 else { return "Brak danych" }

        let beefShare = scoring.beefShare
        let boneShare = scoring.boneShare

        if selectedProfile == .cleaner {
            if beefShare < 0.15 && boneShare < 0.35 { return "Czystsza" }
            if beefShare < 0.35 { return "Zbalansowana" }
            return "Pełniejsza"
        } else {
            if beefShare < 0.20 && boneShare < 0.20 { return "Łagodna" }
            if beefShare < 0.40 || boneShare < 0.35 { return "Zbalansowana" }
            return "Mocna"
        }
    }

    private var quickInsight: QuickInsight {
        if let failure = previewResult.validationFailure {
            switch failure.code {
            case .hardNoMeat:
                return QuickInsight(
                    systemImage: "tray",
                    shortText: "Dodaj mięso",
                    detailText: "Wybierz przynajmniej jeden składnik, żeby aplikacja mogła policzyć rosół.",
                    tone: .danger
                )
            default:
                return QuickInsight(
                    systemImage: "exclamationmark.triangle",
                    shortText: "Popraw zestaw",
                    detailText: failure.messageFallback,
                    tone: .danger
                )
            }
        }

        guard totalWeight > 0 else {
            return QuickInsight(
                systemImage: "questionmark.circle",
                shortText: "Wybierz mięso",
                detailText: "Dodaj przynajmniej jeden składnik, żeby zobaczyć proporcje i przewidywany uzysk.",
                tone: .neutral
            )
        }

        if hasWarning(.waterReducedToFit) {
            return QuickInsight(
                systemImage: "drop.triangle",
                shortText: "Policzyliśmy mniej wody",
                detailText: messageForWarningCode(.waterReducedToFit),
                tone: .warning
            )
        }

        if hasWarning(.undermeatLight) || hasWarning(.undermeatIntense) {
            return QuickInsight(
                systemImage: "plus.circle",
                shortText: "Możesz dodać więcej",
                detailText: hasWarning(.undermeatLight)
                    ? messageForWarningCode(.undermeatLight)
                    : messageForWarningCode(.undermeatIntense),
                tone: .neutral
            )
        }

        if hasWarning(.overmeatLight) || hasWarning(.overmeatIntense) {
            return QuickInsight(
                systemImage: "arrow.up.circle",
                shortText: "Cięższy wsad",
                detailText: hasWarning(.overmeatLight)
                    ? messageForWarningCode(.overmeatLight)
                    : messageForWarningCode(.overmeatIntense),
                tone: .warning
            )
        }

        if hasWarning(.overfatLight) || hasWarning(.heavyBeefProfile) || hasWarning(.marrowTooHigh) {
            let detail: String
            if hasWarning(.overfatLight) {
                detail = messageForWarningCode(.overfatLight)
            } else if hasWarning(.marrowTooHigh) {
                detail = messageForWarningCode(.marrowTooHigh)
            } else {
                detail = messageForWarningCode(.heavyBeefProfile)
            }

            return QuickInsight(
                systemImage: "drop.fill",
                shortText: "Cięższy profil",
                detailText: detail,
                tone: .warning
            )
        }

        if hasWarning(.lowGelatinIntense) {
            return QuickInsight(
                systemImage: "bolt.slash",
                shortText: "Mało kolagenu",
                detailText: messageForWarningCode(.lowGelatinIntense),
                tone: .neutral
            )
        }

        if hasWarning(.liverTimingRequired) {
            return QuickInsight(
                systemImage: "clock.badge.exclamationmark",
                shortText: "Wątróbka na końcu",
                detailText: messageForWarningCode(.liverTimingRequired),
                tone: .warning
            )
        }

        return QuickInsight(
            systemImage: "checkmark.circle",
            shortText: "Dobry balans",
            detailText: "Zestaw wygląda sensownie i dobrze pasuje do wybranego profilu.",
            tone: .good
        )
    }

    private var waterPreviewText: String {
        guard totalWeight > 0, previewResult.validationFailure == nil else { return "Brak danych" }
        return litersString(previewResult.waterLiters)
    }

    private var yieldPreviewText: String {
        guard totalWeight > 0, previewResult.validationFailure == nil else { return "Brak danych" }
        return litersString(previewResult.estimatedYieldLiters)
    }

    private func hasWarning(_ code: BrothWarningCode) -> Bool {
        previewResult.structuredWarnings.contains(where: { $0.code == code })
    }

    private func messageForWarningCode(_ code: BrothWarningCode) -> String {
        switch code {
        case .hardPotTooSmall:
            return "To jest mniej niż 0,25 l. Ustaw realną pojemność garnka."
        case .hardPotTooBig:
            return "To wygląda na literówkę. Maksymalna pojemność w aplikacji to 30 l."
        case .hardTooMuchMeat:
            return "To ilość przemysłowa. Wprowadź wagę mięsa dla jednego garnka."
        case .hardItemTooBig:
            return "Jedna z wag wygląda podejrzanie wysoko. Sprawdź, czy na pewno wpisujesz gramy."
        case .hardNoMeat:
            return "Dodaj mięso. Bez mięsa nie ugotujesz rosołu."
        case .hardNotFit:
            return "Ten zestaw fizycznie nie mieści się w tym garnku. Zmniejsz ilość mięsa albo użyj większego naczynia."
        case .premiumBlocked:
            return "Ten składnik jest dostępny dopiero w rozszerzonej wersji kalkulatora."
        case .undermeatLight:
            return "Wybrałeś mniej mięsa niż zwykle mieści ten garnek. Aplikacja przeliczy rosół do tej ilości, ale jeśli chcesz ugotować większą porcję, możesz dodać jeszcze trochę mięsa."
        case .overmeatLight:
            return "Jak na czystszy profil mięsa jest już sporo. Rosół może wyjść cięższy niż zwykle."
        case .undermeatIntense:
            return "To raczej mniejsza partia jak na tak głęboki profil. Aplikacja przeliczy całość do tej ilości, ale jeśli chcesz mocniejszy efekt i większy uzysk, możesz dodać jeszcze trochę mięsa."
        case .overmeatIntense:
            return "Mięsa jest bardzo dużo. Rosół może wyjść ciężki i trudniejszy do zbalansowania."
        case .overfatLight:
            return "Ten zestaw może wyjść tłusty. Do czystszego profilu lepiej sprawdza się więcej korpusu lub szyi i mniej cięższych elementów."
        case .wingsTooHighLight:
            return "Skrzydełka w większej ilości podbijają tłuszcz. W czystszym rosole warto trzymać je z umiarem."
        case .lowGelatinIntense:
            return "Smak może być głęboki, ale wywar będzie mniej sprężysty, bo jest tu mało kości i kolagenu."
        case .heavyBeefProfile:
            return "Ten zestaw idzie w cięższą, bardziej wołową stronę."
        case .marrowTooHigh:
            return "Jest tu sporo szpiku albo mostka. Rosół może wyjść za ciężki i tłusty."
        case .singleIngredientRisk:
            return "Jeden składnik mocno dominuje w zestawie. Warto lekko go zrównoważyć."
        case .offalDominantRisk:
            return "Podroby są tu już bardzo wyraźne. Lepiej, żeby wspierały bazę, a nie ją przejmowały."
        case .liverTimingRequired:
            return "Wątróbkę dodaj dopiero na ostatnie 20–30 minut."
        case .paperFilterLowerIntensity:
            return "Filtr papierowy da czystszy rosół, ale finalnie zostanie go mniej i będzie odrobinę lżejszy."
        case .paperFilterHighLoss:
            return "Przy filtrze papierowym strata może być tu wyraźna. Finalnego rosołu zostanie zauważalnie mniej."
        case .waterReducedToFit:
            return "Dla tego zestawu klasyczna ilość wody nie zmieściłaby się w garnku, więc wywar będzie trochę mocniejszy i będzie go mniej."
        }
    }

    private func gramsString(_ grams: Int) -> String {
        if grams >= 1000 {
            let value = Double(grams) / 1000.0
            let text = value.formatted(.number.precision(.fractionLength(1)))
                .replacingOccurrences(of: ".", with: ",")
            return "\(text) kg"
        }
        return "\(grams) g"
    }

    private func kilogramsText(_ grams: Int) -> String {
        let value = Double(grams) / 1000.0
        let text = value.formatted(.number.precision(.fractionLength(1)))
            .replacingOccurrences(of: ".", with: ",")
        return "\(text) kg"
    }

    private func litersString(_ liters: Double) -> String {
        let text = liters.formatted(.number.precision(.fractionLength(2)))
            .replacingOccurrences(of: ".", with: ",")
        if text.hasSuffix(",00") {
            return text.replacingOccurrences(of: ",00", with: "") + " l"
        }
        if text.hasSuffix("0") {
            return String(text.dropLast()) + " l"
        }
        return text + " l"
    }

    private func percentString(_ value: Double) -> String {
        let percent = (value * 100).rounded()
        return "\(Int(percent))%"
    }
}

struct IngredientCategorySection: View {
    let category: IngredientCategory
    let items: [IngredientOption]
    let isExpanded: Bool
    @Binding var amounts: [String: String]
    let focusedFieldID: FocusState<String?>.Binding
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Button(action: onToggle) {
                AppCard(
                    background: isExpanded ? AppTheme.accentSoft : AppTheme.surface,
                    border: isExpanded ? AppTheme.accent : AppTheme.border,
                    lineWidth: isExpanded ? 1.5 : 1
                ) {
                    HStack(alignment: .center, spacing: 14) {
                        CategoryIllustrationBadge(category: category, selected: isExpanded)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.rawValue)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            Text(sectionSubtitle)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                        }

                        Spacer(minLength: 8)

                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                }
                .appSoftShadow()
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        IngredientRow(
                            item: item,
                            text: binding(for: item.id),
                            focusedFieldID: focusedFieldID
                        )
                    }
                }
            }
        }
    }

    private var selectedItems: [(IngredientOption, Int)] {
        items.compactMap { item in
            let value = Int(amounts[item.id] ?? "") ?? 0
            return value > 0 ? (item, value) : nil
        }
    }

    private var sectionSubtitle: String {
        let totalWeight = selectedItems.reduce(0) { $0 + $1.1 }
        let count = selectedItems.count

        if count == 0 {
            return "Nic jeszcze nie wybrano"
        }

        return "\(count) skład. • \(gramsString(totalWeight))"
    }

    private func binding(for id: String) -> Binding<String> {
        Binding(
            get: { amounts[id] ?? "" },
            set: { newValue in
                let filtered = newValue.filter { $0.isNumber }
                amounts[id] = filtered
            }
        )
    }

    private func gramsString(_ grams: Int) -> String {
        if grams >= 1000 {
            let value = Double(grams) / 1000.0
            let text = value.formatted(.number.precision(.fractionLength(1)))
                .replacingOccurrences(of: ".", with: ",")
            return "\(text) kg"
        }
        return "\(grams) g"
    }
}

struct IngredientRow: View {
    let item: IngredientOption
    @Binding var text: String
    let focusedFieldID: FocusState<String?>.Binding

    var body: some View {
        AppCard(
            background: isSelected ? AppTheme.accentSoft.opacity(0.45) : AppTheme.surface,
            border: isSelected ? AppTheme.accent.opacity(0.6) : AppTheme.border,
            lineWidth: isSelected ? 1.2 : 1
        ) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    IngredientIllustrationBadge(kind: item.illustration)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(item.subtitle)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)
                }

                HStack(spacing: 10) {
                    StepperCircle(symbol: "minus") {
                        let newValue = max(0, currentValue - 50)
                        text = newValue == 0 ? "" : "\(newValue)"
                        focusedFieldID.wrappedValue = nil
                    }

                    Button {
                        focusedFieldID.wrappedValue = item.id
                    } label: {
                        HStack(spacing: 8) {
                            Text(currentValue == 0 ? "0" : "\(currentValue)")
                                .multilineTextAlignment(.leading)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text("g")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(AppTheme.surfaceMuted)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(focusedFieldID.wrappedValue == item.id ? AppTheme.accent : AppTheme.border, lineWidth: 1)
                        )
                        .overlay(alignment: .leading) {
                            TextField("", text: $text)
                                .keyboardType(.numberPad)
                                .textContentType(.none)
                                .focused(focusedFieldID, equals: item.id)
                                .opacity(0.015)
                                .frame(width: 1, height: 1)
                        }
                    }
                    .buttonStyle(.plain)

                    StepperCircle(symbol: "plus") {
                        let newValue = currentValue + 50
                        text = "\(newValue)"
                        focusedFieldID.wrappedValue = nil
                    }
                }
            }
        }
        .appSoftShadow()
    }

    private var currentValue: Int {
        Int(text) ?? 0
    }

    private var isSelected: Bool {
        currentValue > 0
    }
}

private struct FloatingStatusPanel: View {
    let insight: QuickInsight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.systemImage)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.shortText)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(titleColor)

                Text(insight.detailText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(detailColor)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var backgroundColor: Color {
        switch insight.tone {
        case .neutral:
            return AppTheme.surfaceMuted
        case .good:
            return Color(red: 0.95, green: 0.99, blue: 0.94)
        case .warning:
            return Color(red: 1.0, green: 0.96, blue: 0.91)
        case .danger:
            return Color(red: 1.0, green: 0.94, blue: 0.93)
        }
    }

    private var borderColor: Color {
        switch insight.tone {
        case .neutral:
            return AppTheme.border
        case .good:
            return Color(red: 0.63, green: 0.84, blue: 0.58)
        case .warning:
            return Color(red: 0.96, green: 0.80, blue: 0.46)
        case .danger:
            return Color(red: 0.95, green: 0.67, blue: 0.62)
        }
    }

    private var iconColor: Color {
        switch insight.tone {
        case .neutral:
            return AppTheme.textSecondary
        case .good:
            return Color(red: 0.24, green: 0.55, blue: 0.22)
        case .warning:
            return Color(red: 0.55, green: 0.36, blue: 0.10)
        case .danger:
            return Color(red: 0.74, green: 0.24, blue: 0.20)
        }
    }

    private var titleColor: Color {
        switch insight.tone {
        case .neutral, .good, .warning, .danger:
            return AppTheme.textPrimary
        }
    }

    private var detailColor: Color {
        switch insight.tone {
        case .neutral:
            return AppTheme.textSecondary
        case .good:
            return Color(red: 0.16, green: 0.36, blue: 0.15)
        case .warning:
            return Color(red: 0.40, green: 0.28, blue: 0.10)
        case .danger:
            return Color(red: 0.45, green: 0.16, blue: 0.14)
        }
    }
}

private struct AssessmentChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: 34)
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

struct FloatingSummaryChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: 32)
            .background(
                Capsule()
                    .fill(AppTheme.surface)
            )
            .overlay(
                Capsule()
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }
}

struct StepperCircle: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: 42, height: 42)
                .background(AppTheme.surface)
                .overlay(
                    Circle()
                        .stroke(AppTheme.borderStrong, lineWidth: 1)
                )
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

struct IngredientDiagnosticRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct CategoryIllustrationBadge: View {
    let category: IngredientCategory
    let selected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(selected ? AppTheme.accent : AppTheme.surfaceMuted)
                .frame(width: 56, height: 56)

            illustration
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch category {
        case .poultry:
            ChickenCategoryIllustration(selected: selected)
        case .beef:
            BeefCategoryIllustration(selected: selected)
        case .offal:
            OffalCategoryIllustration(selected: selected)
        }
    }
}

struct IngredientIllustrationBadge: View {
    let kind: IngredientIllustrationKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surfaceMuted)
                .frame(width: 52, height: 52)

            illustration
        }
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var illustration: some View {
        switch kind {
        case .chicken:
            ChickenWholeIllustration()
        case .chickenBones:
            ChickenFrameIllustration()
        case .chickenWings:
            WingIllustration()
        case .turkey:
            TurkeyIllustration()
        case .duck:
            DuckIllustration()
        case .beef:
            BeefMeatIllustration()
        case .bones:
            BonesIllustration()
        case .hearts:
            HeartsIllustration()
        case .gizzards:
            GizzardsIllustration()
        case .liver:
            LiverIllustration()
        }
    }
}

// MARK: - Ilustracje

struct ChickenCategoryIllustration: View {
    let selected: Bool

    var body: some View {
        ZStack {
            ChickenWholeIllustration()
                .scaleEffect(0.95)

            if selected {
                Circle()
                    .fill(AppTheme.surface.opacity(0.95))
                    .frame(width: 10, height: 10)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

struct BeefCategoryIllustration: View {
    let selected: Bool

    var body: some View {
        ZStack {
            BeefMeatIllustration()
                .scaleEffect(1.0)

            if selected {
                Circle()
                    .fill(AppTheme.surface.opacity(0.95))
                    .frame(width: 10, height: 10)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

struct OffalCategoryIllustration: View {
    let selected: Bool

    var body: some View {
        ZStack {
            HeartsIllustration()
                .scaleEffect(0.85)
                .offset(x: -4)

            LiverIllustration()
                .scaleEffect(0.78)
                .offset(x: 8, y: 6)

            if selected {
                Circle()
                    .fill(AppTheme.surface.opacity(0.95))
                    .frame(width: 10, height: 10)
                    .offset(x: 12, y: -12)
            }
        }
    }
}

struct ChickenWholeIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.87))
                .frame(width: 22, height: 14)
                .offset(x: 2, y: 6)

            Circle()
                .fill(Color(red: 0.95, green: 0.92, blue: 0.87))
                .frame(width: 11, height: 11)
                .offset(x: 9, y: 1)

            Capsule()
                .fill(Color(red: 0.96, green: 0.62, blue: 0.18))
                .frame(width: 10, height: 4)
                .rotationEffect(.degrees(-28))
                .offset(x: -10, y: -1)

            Circle()
                .fill(Color(red: 0.96, green: 0.62, blue: 0.18))
                .frame(width: 4, height: 4)
                .offset(x: -14, y: -2)

            Circle()
                .fill(Color(red: 0.94, green: 0.34, blue: 0.28))
                .frame(width: 3.5, height: 3.5)
                .offset(x: 9, y: -7)
        }
        .overlay(
            Ellipse()
                .stroke(Color.black.opacity(0.06), lineWidth: 0.7)
                .frame(width: 22, height: 14)
                .offset(x: 2, y: 6)
        )
    }
}

struct ChickenFrameIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 18, height: 5)
                .rotationEffect(.degrees(-24))

            Circle()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 5, height: 5)
                .offset(x: -8, y: -1)

            Circle()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 5, height: 5)
                .offset(x: 8, y: 1)

            Capsule()
                .fill(Color(red: 0.93, green: 0.58, blue: 0.18))
                .frame(width: 14, height: 4)
                .rotationEffect(.degrees(32))
                .offset(x: 4, y: -6)
        }
    }
}

struct WingIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.98, green: 0.73, blue: 0.34))
                .frame(width: 14, height: 18)
                .rotationEffect(.degrees(-28))
                .offset(x: -4)

            Ellipse()
                .fill(Color(red: 0.96, green: 0.65, blue: 0.24))
                .frame(width: 12, height: 15)
                .rotationEffect(.degrees(28))
                .offset(x: 5)
        }
    }
}

struct TurkeyIllustration: View {
    var body: some View {
        ZStack {
            ChickenWholeIllustration()
                .scaleEffect(0.92)

            HerbAccentMini()
                .offset(x: 10, y: -8)
        }
    }
}

struct DuckIllustration: View {
    var body: some View {
        ZStack {
            BeefMeatIllustration()
                .scaleEffect(0.9)
                .offset(x: -1, y: -1)

            WingIllustration()
                .scaleEffect(0.6)
                .offset(x: 8, y: -8)
        }
    }
}

struct BeefMeatIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.73, green: 0.38, blue: 0.30))
                .frame(width: 20, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
                )

            Circle()
                .fill(Color(red: 0.99, green: 0.86, blue: 0.78))
                .frame(width: 4.5, height: 4.5)
                .offset(x: -4, y: -2)

            Circle()
                .fill(Color(red: 0.99, green: 0.86, blue: 0.78))
                .frame(width: 4, height: 4)
                .offset(x: 4, y: 2)
        }
    }
}

struct BonesIllustration: View {
    var body: some View {
        ZStack {
            ChickenFrameIllustration()

            BeefMeatIllustration()
                .scaleEffect(0.7)
                .offset(x: -8, y: -8)
        }
    }
}

struct HeartsIllustration: View {
    var body: some View {
        ZStack {
            HeartShape()
                .fill(Color(red: 0.71, green: 0.31, blue: 0.34))
                .frame(width: 12, height: 12)
                .offset(x: -4, y: 1)

            HeartShape()
                .fill(Color(red: 0.62, green: 0.24, blue: 0.28))
                .frame(width: 11, height: 11)
                .offset(x: 4, y: -1)
        }
    }
}

struct GizzardsIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.79, green: 0.58, blue: 0.45))
                .frame(width: 14, height: 10)
                .rotationEffect(.degrees(-16))
                .offset(x: -4, y: 1)

            Ellipse()
                .fill(Color(red: 0.70, green: 0.50, blue: 0.40))
                .frame(width: 13, height: 9)
                .rotationEffect(.degrees(20))
                .offset(x: 5, y: -1)
        }
    }
}

struct LiverIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 0.60, green: 0.22, blue: 0.20))
                .frame(width: 18, height: 12)
                .rotationEffect(.degrees(-12))

            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(red: 0.72, green: 0.28, blue: 0.24))
                .frame(width: 11, height: 8)
                .offset(x: -3, y: 1)
                .rotationEffect(.degrees(10))
        }
    }
}

struct HerbAccentMini: View {
    var body: some View {
        HStack(spacing: 2) {
            Capsule()
                .fill(Color(red: 0.32, green: 0.77, blue: 0.42))
                .frame(width: 4, height: 10)
                .rotationEffect(.degrees(-22))

            Capsule()
                .fill(Color(red: 0.25, green: 0.67, blue: 0.34))
                .frame(width: 4, height: 9)
                .rotationEffect(.degrees(18))
        }
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        path.move(to: CGPoint(x: width / 2, y: height))
        path.addCurve(
            to: CGPoint(x: 0, y: height * 0.35),
            control1: CGPoint(x: width * 0.15, y: height * 0.75),
            control2: CGPoint(x: 0, y: height * 0.58)
        )
        path.addArc(
            center: CGPoint(x: width * 0.25, y: height * 0.30),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addArc(
            center: CGPoint(x: width * 0.75, y: height * 0.30),
            radius: width * 0.25,
            startAngle: .degrees(180),
            endAngle: .degrees(0),
            clockwise: false
        )
        path.addCurve(
            to: CGPoint(x: width / 2, y: height),
            control1: CGPoint(x: width, y: height * 0.58),
            control2: CGPoint(x: width * 0.85, y: height * 0.75)
        )

        return path
    }
}

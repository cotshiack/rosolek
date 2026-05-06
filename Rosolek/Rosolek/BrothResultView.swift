import SwiftUI

struct BrothResultView: View {
    let mode: BrothMode
    let totalWeight: Int
    let selectedIngredientCount: Int
    let selectedIDs: [String]
    let initialSelections: [BrothIngredientSelection]
    let selectedKind: BrothKind?
    let selectedStyleName: String?

    @EnvironmentObject private var batchStore: BatchStore

    @AppStorage("potSizeLiters") private var potSizeLiters = 7
    @AppStorage("hasThermometer") private var hasThermometer = true

    @State private var savedBatch: BatchRecord?
    @State private var navigateToCooking = false
    @State private var isStartingCooking = false
    @State private var showActiveCookingConflictAlert = false
    @State private var activeCookingTitleForConflict = ""
    @State private var clarityMode: BrothClarityMode = .normal
    @State private var useVinegar = false
    @State private var activeMetricTooltip: ResultMetricTooltipKey?
    @State private var isSummaryGridInteracting = false
    @State private var showVegetableEditor = false
    @State private var vegetableOverrides: [String: Int] = [:]
    @State private var showSpiceEditor = false
    @State private var spiceOverrides: [String: Int] = [:]
    @State private var showMeatEditor = false
    @State private var meatOverrides: [String: Int] = [:]

    init(
        mode: BrothMode,
        totalWeight: Int,
        selectedIngredientCount: Int,
        selectedIDs: [String],
        initialSelections: [BrothIngredientSelection] = [],
        meatOverrides: [String: Int]? = nil,
        vegetableOverrides: [String: Int]? = nil,
        spiceOverrides: [String: Int]? = nil,
        selectedKind: BrothKind? = nil,
        selectedStyleName: String? = nil
    ) {
        self.mode = mode
        self.totalWeight = totalWeight
        self.selectedIngredientCount = selectedIngredientCount
        self.selectedIDs = selectedIDs
        self.initialSelections = initialSelections
        self.selectedKind = selectedKind
        self.selectedStyleName = selectedStyleName
        _meatOverrides = State(initialValue: meatOverrides ?? [:])
        _vegetableOverrides = State(initialValue: vegetableOverrides ?? [:])
        _spiceOverrides = State(initialValue: spiceOverrides ?? [:])
    }

    init(
        preset: BrothPreset,
        potSizeLiters: Int
    ) {
        let result = BrothCalculator.calculate(
            preset: preset,
            potSizeLiters: Double(potSizeLiters)
        )

        self.init(
            mode: .preset(preset),
            totalWeight: result.meatParts.reduce(0) { $0 + $1.grams },
            selectedIngredientCount: preset.defaultSelectedIDs.count,
            selectedIDs: preset.defaultSelectedIDs,
            initialSelections: [],
            selectedKind: nil,
            selectedStyleName: nil
        )
    }

    init(
        profile: BrothProfile,
        selections: [BrothIngredientSelection],
        selectedKind: BrothKind? = nil,
        selectedStyleName: String? = nil
    ) {
        self.init(
            mode: .custom(profile),
            totalWeight: selections.reduce(0) { $0 + $1.grams },
            selectedIngredientCount: selections.count,
            selectedIDs: selections.map(\.ingredientID),
            initialSelections: selections,
            meatOverrides: nil,
            vegetableOverrides: nil,
            spiceOverrides: nil,
            selectedKind: selectedKind,
            selectedStyleName: selectedStyleName
        )
    }

    private var result: BrothCalculationResult {
        switch mode {
        case .preset(let preset):
            return BrothCalculator.calculate(
                preset: preset,
                potSizeLiters: Double(potSizeLiters),
                clarityMode: clarityMode,
                useVinegar: useVinegar
            )

        case .custom(let profile):
            if let kind = selectedKind {
                do {
                    let styleKey = UltraSpecStyleKeyResolver.resolve(kind: kind, styleName: selectedStyleName)
                    let variant = UltraSpecVariantResolver.resolve(kind: kind, styleKey: styleKey)
                    let ultra = try UltraSpecBridge.calculateFromCurrentFlow(
                        kind: kind,
                        styleName: selectedStyleName,
                        potCapacityL: Double(potSizeLiters),
                        selections: resolvedSelections,
                        clarityMode: clarityMode
                    )
                    return makeBrothResultFromUltraSpec(ultra, variant: variant, profile: profile)
                } catch let error as UltraSpecEngineError {
                    return makeUltraSpecFailureResult(error: error)
                } catch {
                    return makeUltraSpecFailureResult(error: .variantNotConfigured)
                }
            }

            return BrothCalculator.calculate(
                profile: profile,
                meatItems: resolvedSelections,
                potSizeLiters: Double(potSizeLiters),
                clarityMode: clarityMode,
                useVinegar: useVinegar
            )
        }
    }


    private func makeBrothResultFromUltraSpec(_ ultra: UltraSpecCalculationResult, variant: UltraSpecVariantID, profile: BrothProfile) -> BrothCalculationResult {
        guard let config = variantConfig(for: variant) else {
            return makeUltraSpecFailureResult(error: .variantNotConfigured)
        }

        let vegRows = ultra.vegetables.map {
            VegetableAmount(name: prettyIngredientName($0.ingredientID), amount: "\($0.grams) g", note: nil)
        }

        let spice = BrothSpiceBreakdown(
            peppercornCount: ultra.spices.peppercornCount,
            allspiceCount: ultra.spices.allspiceCount,
            bayLeafCount: ultra.spices.bayLeafCount
        )

        let filteredWarnings = ultra.warningMessages.filter { warning in
            if variant == .warzywnyJasny || variant == .warzywnyUmami {
                return warning.code != .underpower && warning.code != .overpower
            }
            return true
        }

        var warningTexts = filteredWarnings.map {
            if let suggestion = $0.suggestion?.text, !suggestion.isEmpty {
                return "\($0.title): \($0.message) \(suggestion)"
            }
            return "\($0.title): \($0.message)"
        }
        let structured: [BrothWarning] = filteredWarnings.map {
            BrothWarning(code: mapWarningCode($0.code), severity: mapSeverity($0.severity), params: [])
        }

        let timeline = UltraSpecTimelineCatalog.steps(for: variant).map {
            let drawerSubtitle = UltraSpecStepLibrary.all[$0.stepID]?.subtitle
            return CookingTimelineItem(
                minuteOffset: $0.minuteOffset,
                timeLabel: $0.timeLabel,
                title: $0.title,
                subtitle: drawerSubtitle ?? $0.subtitle
            )
        }

        return BrothCalculationResult(
            waterLiters: ultra.waterStartL,
            temperatureMin: config.temperature.minC,
            temperatureMax: config.temperature.maxC,
            totalMinutes: config.totalMinutes,
            estimatedYieldLiters: ultra.estimatedYieldL,
            startSaltGrams: ultra.startSaltG,
            finalSaltGrams: ultra.targetSaltG,
            appleCiderVinegarMl: useVinegar ? max(5, Int((ultra.waterStartL * 2).rounded())) : 0,
            peppercornCount: ultra.spices.peppercornCount,
            allspiceCount: ultra.spices.allspiceCount,
            bayLeafCount: ultra.spices.bayLeafCount,
            vegetables: vegRows,
            meatParts: resolvedSelections.map { MeatAmount(name: $0.name, grams: $0.grams, note: nil) },
            timeline: timeline,
            warnings: warningTexts,
            structuredWarnings: structured,
            validationFailure: nil,
            scoring: nil,
            recommendedMeatRange: nil,
            clarityMode: clarityMode,
            useVinegar: useVinegar,
            targetYieldLiters: nil,
            vegetableBreakdown: nil,
            spiceBreakdown: spice,
            microMode: ultra.waterStartL < 0.7,
            waterWasReducedToFit: ultra.waterStartL < ultra.waterRecipeL
        )
    }


    private func makeUltraSpecFailureResult(error: UltraSpecEngineError) -> BrothCalculationResult {
        let failureCode: BrothWarningCode
        let message: String
        switch error {
        case .hardPotTooSmall:
            failureCode = .hardPotTooSmall
            message = "Garnek jest za mały (min. 0,25 L)."
        case .hardPotTooBig:
            failureCode = .hardPotTooBig
            message = "Pojemność garnka wygląda na literówkę (max. 30 L)."
        case .hardNotFit:
            failureCode = .hardNotFit
            message = "Składniki nie mieszczą się w garnku z bezpiecznym marginesem."
        case .variantNotConfigured:
            failureCode = .premiumBlocked
            message = "Nie udało się dopasować konfiguracji wariantu ULTRA-SPEC."
        case .hardNoBase:
            failureCode = .hardNoMeat
            message = "Brak bazy dla tego bulionu. Dodaj składniki bazowe."
        }

        return BrothCalculationResult(
            waterLiters: 0,
            temperatureMin: 0,
            temperatureMax: 0,
            totalMinutes: 0,
            estimatedYieldLiters: 0,
            startSaltGrams: 0,
            finalSaltGrams: 0,
            appleCiderVinegarMl: 0,
            peppercornCount: 0,
            allspiceCount: 0,
            bayLeafCount: 0,
            vegetables: [],
            meatParts: resolvedSelections.map { MeatAmount(name: $0.name, grams: $0.grams, note: nil) },
            timeline: [],
            warnings: [message],
            structuredWarnings: [.init(code: failureCode, severity: .error, params: [])],
            validationFailure: .init(code: failureCode, messageFallback: message),
            scoring: nil,
            recommendedMeatRange: nil,
            clarityMode: clarityMode,
            useVinegar: useVinegar,
            targetYieldLiters: nil,
            vegetableBreakdown: nil,
            spiceBreakdown: nil,
            microMode: false,
            waterWasReducedToFit: false
        )
    }

    private func variantConfig(for variant: UltraSpecVariantID) -> UltraSpecVariantConfig? {
        UltraSpecCatalog.variants.first(where: { $0.id == variant })
    }

    private func mapSeverity(_ severity: UltraSpecSeverity) -> BrothWarningSeverity {
        switch severity {
        case .info: return .info
        case .warn: return .warn
        case .error: return .error
        }
    }

    private func mapWarningCode(_ code: UltraSpecWarningCode) -> BrothWarningCode {
        switch code {
        case .underpower: return .baseTooLowForWater
        case .overpower: return .baseTooHighForWater
        case .vegTooMuch: return .singleIngredientRisk
        case .paperFilterLowerIntensity: return .paperFilterLowerIntensity
        case .hardPotTooSmall: return .hardPotTooSmall
        case .hardPotTooBig: return .hardPotTooBig
        case .hardNotFit: return .hardNotFit
        case .wingsTooHigh: return .wingsTooHighLight
        case .beefTooHigh: return .heavyBeefProfile
        case .offalTooHigh: return .offalDominantRisk
        case .vegSweetRisk: return .singleIngredientRisk
        }
    }

    private func prettyIngredientName(_ id: String) -> String {
        UltraSpecCatalog.ingredients.first(where: { $0.id == id })?.name ?? id
    }

    private var resolvedSelections: [BrothIngredientSelection] {
        if !initialSelections.isEmpty {
            return sortedSelections(initialSelections)
        }

        return sortedSelections(syntheticSelections())
    }

    private var activeUltraVariant: UltraSpecVariantID? {
        guard case .custom = mode, let kind = selectedKind else { return nil }
        let styleKey = UltraSpecStyleKeyResolver.resolve(kind: kind, styleName: selectedStyleName)
        return UltraSpecVariantResolver.resolve(kind: kind, styleKey: styleKey)
    }

    private var usesUserSelections: Bool {
        if case .custom = mode {
            return !resolvedSelections.isEmpty
        }
        return false
    }

    private var vegetableRows: [ResultListRowData] {
        result.vegetables.compactMap { item in
            let baseValue = parseGrams(from: item.amount)
            let grams = vegetableOverrides[item.name] ?? baseValue
            guard grams > 0 else { return nil }
            return ResultListRowData(
                icon: iconKind(for: item.name),
                title: item.name,
                subtitle: vegetableSubtitle(for: item),
                value: "\(grams) g"
            )
        }
    }

    private var spiceRows: [ResultListRowData] {
        let startSaltG = spiceOverrides["salt_start"] ?? Int(result.startSaltGrams.rounded())
        let finalSaltG = spiceOverrides["salt_final"] ?? Int(result.finalSaltGrams.rounded())
        let pepperCount = spiceOverrides["pepper"] ?? result.peppercornCount
        let allspiceCount = spiceOverrides["allspice"] ?? result.allspiceCount
        let bayLeafCount = spiceOverrides["bay"] ?? result.bayLeafCount
        let vinegarMl = spiceOverrides["vinegar"] ?? result.appleCiderVinegarMl

        var rows: [ResultListRowData] = [
            ]

        if startSaltG > 0 || finalSaltG > 0 {
            rows.append(
                ResultListRowData(
                    icon: .salt,
                    title: "Sól",
                    subtitle: "Start i korekta końcowa",
                    value: "\(startSaltG) g / \(finalSaltG) g"
                )
            )
        }
        if supportsPepper, pepperCount > 0 {
            rows.append(
                ResultListRowData(
                    icon: .pepper,
                    title: "Pieprz czarny ziarnisty",
                    subtitle: "Czysty aromat",
                    value: "\(pepperCount) \(pepperCount == 1 ? "ziarno" : "ziaren")"
                )
            )
        }

        if supportsAllspice, allspiceCount > 0 { rows.append(ResultListRowData(icon: .allspice, title: "Ziele angielskie", subtitle: "Głębia smaku", value: "\(allspiceCount) \(allspiceCount == 1 ? "ziarno" : "ziaren")")) }
        if supportsBayLeaf, bayLeafCount > 0 { rows.append(ResultListRowData(icon: .bayLeaf, title: "Liść laurowy", subtitle: "Tło aromatu", value: bayLeafCount == 1 ? "1 liść" : "\(bayLeafCount) liście")) }

        if supportsVinegar && vinegarMl > 0 {
            rows.append(ResultListRowData(icon: .vinegar, title: "Ocet jabłkowy", subtitle: useVinegar ? "dodatek startowy" : "wyłączony", value: "\(vinegarMl) ml"))
        }

        return rows
    }

    private var effectiveResult: BrothCalculationResult {
        let baseResult = recalculatedResultFromEditedBase ?? result

        let updatedVegetables = baseResult.vegetables.map { veg in
            let baseValue = parseGrams(from: veg.amount)
            let grams = vegetableOverrides[veg.name] ?? baseValue
            return VegetableAmount(name: veg.name, amount: "\(grams) g", note: veg.note)
        }

        let startSaltG = Double(spiceOverrides["salt_start"] ?? Int(baseResult.startSaltGrams.rounded()))
        let finalSaltG = Double(spiceOverrides["salt_final"] ?? Int(baseResult.finalSaltGrams.rounded()))
        let pepperCount = spiceOverrides["pepper"] ?? baseResult.peppercornCount
        let allspiceCount = spiceOverrides["allspice"] ?? baseResult.allspiceCount
        let bayLeafCount = spiceOverrides["bay"] ?? baseResult.bayLeafCount
        let vinegarMl = supportsVinegar ? (spiceOverrides["vinegar"] ?? baseResult.appleCiderVinegarMl) : 0

        return BrothCalculationResult(
            waterLiters: baseResult.waterLiters,
            temperatureMin: baseResult.temperatureMin,
            temperatureMax: baseResult.temperatureMax,
            totalMinutes: baseResult.totalMinutes,
            estimatedYieldLiters: baseResult.estimatedYieldLiters,
            startSaltGrams: startSaltG,
            finalSaltGrams: finalSaltG,
            appleCiderVinegarMl: vinegarMl,
            peppercornCount: pepperCount,
            allspiceCount: allspiceCount,
            bayLeafCount: bayLeafCount,
            vegetables: updatedVegetables,
            meatParts: effectiveSelections.map { MeatAmount(name: $0.name, grams: $0.grams, note: nil) },
            timeline: baseResult.timeline,
            warnings: baseResult.warnings,
            structuredWarnings: baseResult.structuredWarnings,
            validationFailure: baseResult.validationFailure,
            scoring: baseResult.scoring,
            recommendedMeatRange: baseResult.recommendedMeatRange,
            clarityMode: baseResult.clarityMode,
            useVinegar: baseResult.useVinegar,
            targetYieldLiters: baseResult.targetYieldLiters,
            vegetableBreakdown: baseResult.vegetableBreakdown,
            spiceBreakdown: baseResult.spiceBreakdown,
            microMode: baseResult.microMode,
            waterWasReducedToFit: baseResult.waterWasReducedToFit
        )
    }

    private var recalculatedResultFromEditedBase: BrothCalculationResult? {
        guard !meatOverrides.isEmpty else { return nil }
        guard case .custom(let profile) = mode, let kind = selectedKind else { return nil }

        do {
            let styleKey = UltraSpecStyleKeyResolver.resolve(kind: kind, styleName: selectedStyleName)
            let variant = UltraSpecVariantResolver.resolve(kind: kind, styleKey: styleKey)
            let ultra = try UltraSpecBridge.calculateFromCurrentFlow(
                kind: kind,
                styleName: selectedStyleName,
                potCapacityL: Double(potSizeLiters),
                selections: effectiveSelections,
                clarityMode: clarityMode
            )
            return makeBrothResultFromUltraSpec(ultra, variant: variant, profile: profile)
        } catch let error as UltraSpecEngineError {
            return makeUltraSpecFailureResult(error: error)
        } catch {
            return makeUltraSpecFailureResult(error: .variantNotConfigured)
        }
    }

    private var meatRows: [MeatShoppingRowData] {
        if usesUserSelections {
            return effectiveSelections.map { selection in
                MeatShoppingRowData(
                    icon: iconKind(for: selection.name),
                    title: selection.name,
                    subtitle: subtitleForSelection(selection),
                    value: gramsString(selection.grams)
                )
            }
        }

        return result.meatParts.map { part in
            MeatShoppingRowData(
                icon: iconKind(for: part.name),
                title: part.name,
                subtitle: part.note ?? "Część przepisu.",
                value: gramsString(part.grams)
            )
        }
    }

    private var effectiveSelections: [BrothIngredientSelection] {
        resolvedSelections.map { selection in
            let overriddenGrams = meatOverrides[selection.ingredientID] ?? selection.grams
            return BrothIngredientSelection(
                ingredientID: selection.ingredientID,
                ingredientName: selection.ingredientName,
                category: selection.category,
                grams: max(0, overriddenGrams)
            )
        }
    }

    private var effectiveTotalWeight: Int {
        effectiveSelections.reduce(0) { $0 + $1.grams }
    }

    private var totalVegetableGrams: Int {
        effectiveResult.vegetables.reduce(0) { partial, item in
            partial + parseGrams(from: item.amount)
        }
    }

    private var additivesApproxGrams: Int {
        totalVegetableGrams + Int(effectiveResult.startSaltGrams.rounded()) + effectiveResult.appleCiderVinegarMl
    }

    private var loadDisplay: String {
        let load = effectiveTotalWeight + additivesApproxGrams
        return gramsString(load)
    }

    private var hasBlockingFailure: Bool {
        result.validationFailure != nil
    }

    private var warningCards: [WarningCardModel] {
        let structured = result.structuredWarnings

        if !structured.isEmpty {
            let hasWaterReduction = structured.contains(where: { $0.code == .waterReducedToFit })

            let filtered: [BrothWarning]
            if hasWaterReduction {
                filtered = structured.filter { warning in
                    warning.code != .undermeatLight && warning.code != .undermeatIntense
                }
            } else {
                filtered = structured
            }

            var seenCodes = Set<BrothWarningCode>()
            var uniqueWarnings: [BrothWarning] = []
            for warning in filtered {
                if seenCodes.insert(warning.code).inserted {
                    uniqueWarnings.append(warning)
                }
            }

            return uniqueWarnings.map {
                WarningCardModel(
                    text: warningText(for: $0),
                    severity: $0.severity
                )
            }
        }

        return result.warnings.map {
            WarningCardModel(text: $0, severity: .warn)
        }
    }

    private func tooltipText(for key: ResultMetricTooltipKey) -> String {
        switch key {
        case .pot:
            return "Pojemność garnka podałeś w ustawieniach aplikacji. Możesz ją tam w każdej chwili zmienić."
        case .yield:
            return "To ilość czystego bulionu, która zostanie na końcu gotowania i będzie do wykorzystania."
        case .load:
            return "To cały wsad do garnka: mięso, podroby, warzywa i przyprawy, z których wydobędziesz smak."
        case .temperature:
            if hasThermometer {
                return "Masz ustawiony tryb z termometrem. Jeśli chcesz, możesz to zmienić w ustawieniach."
            }
            return "Masz ustawiony tryb bez termometru. Jeśli chcesz, możesz to zmienić w ustawieniach."
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    summaryGrid
                    if hasRefinementOptions {
                        refinementSection
                    }
                    ingredientsSection
                    if !spiceRows.isEmpty {
                        spicesSection
                    }
                    timelineSection

                    if !warningCards.isEmpty {
                        warningsSection
                    }
                }
                .padding(AppSpacing.screen)
                .padding(.bottom, 8)
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 8)
                    .onChanged { _ in
                        isSummaryGridInteracting = true
                        if activeMetricTooltip != nil {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                activeMetricTooltip = nil
                            }
                        }
                    }
                    .onEnded { _ in
                        isSummaryGridInteracting = false
                    }
            )

            if activeMetricTooltip != nil {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            activeMetricTooltip = nil
                        }
                    }
                    .zIndex(8)
            }

        }
        .overlayPreferenceValue(ResultMetricInfoAnchorPreferenceKey.self) { anchors in
            GeometryReader { proxy in
                if let activeMetricTooltip, let anchor = anchors[activeMetricTooltip], !isSummaryGridInteracting {
                    let iconRect = proxy[anchor]
                    let tooltipWidth = min(220, max(160, proxy.size.width - 28))
                    let horizontalPadding: CGFloat = 12
                    let estimatedTooltipHeight: CGFloat = 132

                    let preferredLeading = iconRect.maxX - tooltipWidth
                    let clampedLeading = min(
                        max(preferredLeading, horizontalPadding),
                        max(horizontalPadding, proxy.size.width - tooltipWidth - horizontalPadding)
                    )

                    let preferredTop = iconRect.maxY + 8
                    let fallbackTop = iconRect.minY - estimatedTooltipHeight - 8
                    let resolvedTop = preferredTop + estimatedTooltipHeight > proxy.size.height - horizontalPadding
                        ? max(horizontalPadding, fallbackTop)
                        : preferredTop

                    Text(tooltipText(for: activeMetricTooltip))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(width: tooltipWidth, alignment: .leading)
                        .background(Color.black.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.16), lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.black.opacity(0.24), radius: 8, x: 0, y: 3)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .offset(x: clampedLeading, y: resolvedTop)
                        .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .topTrailing)))
                        .animation(.easeInOut(duration: 0.18), value: activeMetricTooltip)
                        .allowsHitTesting(false)
                }
            }
        }
        .background(AppTheme.background)
        .navigationTitle(screenNavigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                attemptStartCooking()
            } label: {
                AppPrimaryButtonLabel(
                    title: "Przejdź do gotowania",
                    disabled: hasBlockingFailure || isStartingCooking
                )
            }
            .disabled(hasBlockingFailure || isStartingCooking)
            .padding(.horizontal, AppSpacing.screen)
            .padding(.top, 8)
            .padding(.bottom, 8)
            .background(
                AppTheme.background
                    .opacity(0.97)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .navigationDestination(isPresented: $navigateToCooking) {
            if let savedBatch {
                CookingModeView(
                    batch: savedBatch,
                    result: effectiveResult,
                    totalWeightGrams: totalWeight,
                    selectedIngredientCount: selectedIngredientCount,
                    hasThermometer: hasThermometer
                )
            }
        }
        .alert("Trwa już gotowanie", isPresented: $showActiveCookingConflictAlert) {
            Button("Zachowaj obecne", role: .cancel) { }
            Button("Rozpocznij nowe", role: .destructive) {
                startCooking(replacingExistingSession: true)
            }
        } message: {
            Text("Aktywne gotowanie „\(activeCookingTitleForConflict)” zostanie przerwane i zapisane w historii jako przerwane.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(screenTitle)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            Text(screenSubtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var screenNavigationTitle: String {
        if selectedKind == .ramen || activeUltraVariant == .ramenShio || activeUltraVariant == .ramenTonkotsu || screenTitle.lowercased().contains("ramen") {
            return "Twój ramen"
        }
        if selectedKind == .veggie || activeUltraVariant == .warzywnyJasny || activeUltraVariant == .warzywnyUmami {
            return "Twój bulion warzywny"
        }
        if selectedKind == .fish || activeUltraVariant == .rybnyDelikatny || activeUltraVariant == .rybnyIntensywny {
            return "Twój bulion rybny"
        }
        return "Twój rosół"
    }

    private var summaryGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ResultMetricCard(
                title: "Garnek",
                value: "\(potSizeLiters) l",
                subtitle: "pojemność",
                tooltipKey: .pot,
                onInfoTap: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeMetricTooltip = activeMetricTooltip == .pot ? nil : .pot
                    }
                }
            )

            ResultMetricCard(
                title: "Uzysk",
                value: litersString(result.estimatedYieldLiters),
                subtitle: "po cedzeniu",
                tooltipKey: .yield,
                onInfoTap: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeMetricTooltip = activeMetricTooltip == .yield ? nil : .yield
                    }
                }
            )

            ResultMetricCard(
                title: "Wsad",
                value: loadDisplay,
                subtitle: selectedKind == .veggie ? "warzywa + woda" : "mięso + warzywa",
                tooltipKey: .load,
                onInfoTap: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeMetricTooltip = activeMetricTooltip == .load ? nil : .load
                    }
                }
            )

            ResultMetricCard(
                title: "Temperatura",
                value: hasThermometer ? "\(result.temperatureMin)–\(result.temperatureMax)°C" : "bez term.",
                subtitle: hasThermometer ? "zakres" : "tryb",
                tooltipKey: .temperature,
                onInfoTap: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        activeMetricTooltip = activeMetricTooltip == .temperature ? nil : .temperature
                    }
                }
            )
        }
    }

    private var refinementSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Doprecyzuj wywar")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(selectedKind == .veggie ? "Te opcje zmieniają finalny efekt po ugotowaniu, ale nie zmieniają wyliczonego koszyka." : "Te opcje zmieniają finalny efekt po ugotowaniu, ale nie zmieniają doboru mięsa.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AppCard {
                VStack(alignment: .leading, spacing: 18) {
                    if supportsFiltering {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Filtrowanie")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            BinaryChoiceControl(
                                falseTitle: "Nie",
                                trueTitle: "Tak",
                                isOn: isFiltered,
                                onFalse: {
                                    clarityMode = .normal
                                },
                                onTrue: {
                                    clarityMode = filteredClarityMode
                                }
                            )

                            Text(filteringDescription)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }

                    if supportsVinegar {
                        if supportsFiltering {
                            Divider()
                                .overlay(AppTheme.border)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Ocet jabłkowy")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            BinaryChoiceControl(
                                falseTitle: "Nie",
                                trueTitle: "Tak",
                                isOn: useVinegar,
                                onFalse: {
                                    useVinegar = false
                                },
                                onTrue: {
                                    useVinegar = true
                                }
                            )

                            Text(vinegarDescription)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .appSoftShadow()
        }
    }

    private var hasRefinementOptions: Bool {
        supportsFiltering || supportsVinegar
    }

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Składniki")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(ingredientsSectionDescription)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MeatShoppingCard(
                title: selectedKind == .veggie ? "Baza" : (selectedKind == .fish ? "Baza rybna" : "Mięso"),
                totalWeight: gramsString(effectiveTotalWeight),
                rows: meatRows,
                description: usesUserSelections
                    ? "To jest dokładnie Twój zestaw."
                    : "To jest gotowy zestaw z przepisu.",
                onEdit: usesUserSelections ? { showMeatEditor = true } : nil
            )

            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Text("Warzywa")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Spacer()

                        ResultMetaChip(title: "\(vegetableRows.count) pozycji")
                        editHeaderButton { showVegetableEditor = true }
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(vegetableRows.enumerated()), id: \.offset) { index, item in
                            ResultListRow(item: item)

                            if index < vegetableRows.count - 1 {
                                Divider()
                                    .overlay(AppTheme.border)
                                    .padding(.leading, 52)
                            }
                        }
                    }
                }
            }
            .appSoftShadow()
        }
        .sheet(isPresented: $showVegetableEditor) {
            editorSheet(
                title: "Edytuj warzywa",
                onReset: { vegetableOverrides.removeAll() },
                onDone: { showVegetableEditor = false }
            ) {
                ForEach(result.vegetables, id: \.name) { item in
                    let baseValue = parseGrams(from: item.amount)
                    editorRow(
                        title: item.name,
                        subtitle: vegetableSubtitle(for: item),
                        value: vegetableOverrides[item.name] ?? baseValue,
                        suffix: "g",
                        step: 5,
                        range: 0...2500
                    ) { vegetableOverrides[item.name] = $0 }
                }
            }
        }
        .sheet(isPresented: $showMeatEditor) {
            editorSheet(
                title: "Edytuj bazę",
                onReset: { meatOverrides.removeAll() },
                onDone: { showMeatEditor = false }
            ) {
                ForEach(resolvedSelections, id: \.ingredientID) { selection in
                    editorRow(
                        title: selection.ingredientName,
                        subtitle: subtitleForSelection(selection),
                        value: meatOverrides[selection.ingredientID] ?? selection.grams,
                        suffix: "g",
                        step: 50,
                        range: 0...6000
                    ) { meatOverrides[selection.ingredientID] = $0 }
                }
            }
        }
    }

    private var spicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Przyprawy")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                        Spacer()
                        editHeaderButton { showSpiceEditor = true }
                    }
                    Text("Przygotuj wcześniej.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)

                    VStack(spacing: 0) {
                    ForEach(Array(spiceRows.enumerated()), id: \.offset) { index, item in
                        ResultListRow(item: item)

                        if index < spiceRows.count - 1 {
                            Divider()
                                .overlay(AppTheme.border)
                                .padding(.leading, 52)
                        }
                    }
                }
                }
            }
            .appSoftShadow()
        }
        .sheet(isPresented: $showSpiceEditor) {
            editorSheet(
                title: "Edytuj przyprawy",
                onReset: { spiceOverrides.removeAll() },
                onDone: { showSpiceEditor = false }
            ) {
                spiceStepperRow(title: "Sól start", key: "salt_start", defaultValue: Int(result.startSaltGrams.rounded()), suffix: "g", range: 0...200, step: 1)
                spiceStepperRow(title: "Sól końcowa", key: "salt_final", defaultValue: Int(result.finalSaltGrams.rounded()), suffix: "g", range: 0...250, step: 1)
                if supportsPepper {
                    spiceStepperRow(title: "Pieprz", key: "pepper", defaultValue: result.peppercornCount, suffix: "ziaren", range: 0...200, step: 1)
                }
                if supportsAllspice {
                    spiceStepperRow(title: "Ziele angielskie", key: "allspice", defaultValue: result.allspiceCount, suffix: "ziaren", range: 0...100, step: 1)
                }
                if supportsBayLeaf {
                    spiceStepperRow(title: "Liść laurowy", key: "bay", defaultValue: result.bayLeafCount, suffix: "liści", range: 0...50, step: 1)
                }
                if supportsVinegar {
                    spiceStepperRow(title: "Ocet jabłkowy", key: "vinegar", defaultValue: result.appleCiderVinegarMl, suffix: "ml", range: 0...200, step: 5)
                }
            }
        }
    }

    private var supportsVinegar: Bool {
        switch activeUltraVariant {
        case .some(.ramenTonkotsu), .some(.warzywnyJasny), .some(.warzywnyUmami), .some(.rybnyDelikatny), .some(.rybnyIntensywny):
            return false
        default:
            return true
        }
    }

    private var supportsFiltering: Bool {
        activeUltraVariant != .ramenTonkotsu
    }

    private var supportsPepper: Bool {
        activeUltraVariant != .ramenTonkotsu
    }

    private var supportsAllspice: Bool {
        switch activeUltraVariant {
        case .some(.ramenShio), .some(.ramenTonkotsu), .some(.warzywnyJasny), .some(.warzywnyUmami), .some(.rybnyDelikatny), .some(.rybnyIntensywny):
            return false
        default:
            return true
        }
    }

    private var supportsBayLeaf: Bool {
        supportsAllspice
    }

    private func editHeaderButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 30, height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.surfaceMuted)
                )
        }
        .buttonStyle(.plain)
    }

    private func editorSheet<Content: View>(
        title: String,
        onReset: @escaping () -> Void,
        onDone: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) -> some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                AppCard {
                    VStack(spacing: 0) {
                        content()
                    }
                }
                .appSoftShadow()
                .padding(AppSpacing.screen)
            }
            .background(AppTheme.background)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Reset", action: onReset) }
                ToolbarItem(placement: .confirmationAction) { Button("Gotowe", action: onDone) }
            }
        }
    }

    private func editorRow(
        title: String,
        subtitle: String?,
        value: Int,
        suffix: String,
        step: Int,
        range: ClosedRange<Int>,
        onChange: @escaping (Int) -> Void
    ) -> some View {
        let displayTitle = shortenedEditorTitle(for: title)
        let displaySubtitle = subtitle?.trimmingCharacters(in: .whitespacesAndNewlines)

        return HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayTitle)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                if let displaySubtitle, !displaySubtitle.isEmpty {
                    Text(displaySubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()
            Text("\(value) \(suffix)")
                .font(.system(size: 15, weight: .bold))
                .frame(minWidth: 78, alignment: .trailing)

            HStack(spacing: 0) {
                Button {
                    onChange(max(range.lowerBound, value - step))
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                    .disabled(value <= range.lowerBound)
                Divider().frame(height: 26)
                Button {
                    onChange(min(range.upperBound, value + step))
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                    .disabled(value >= range.upperBound)
            }
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 116, height: 50)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(AppTheme.surfaceSoft)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) { Divider().overlay(AppTheme.border) }
    }

    private func shortenedEditorTitle(for title: String) -> String {
        let normalized = title.lowercased()
        if normalized.contains("kura rosołowa / porcja rosołowa") { return "Kura rosołowa" }
        if normalized.contains("kości wieprzowe stawowe") { return "Kości wieprzowe" }
        if normalized.contains("kręgosłup / ości rybne") { return "Kręgosłup / ości" }
        if normalized.contains("pietruszka korzeń") { return "Pietruszka korzeń" }
        return title
    }

    private func spiceStepperRow(
        title: String,
        key: String,
        defaultValue: Int,
        suffix: String,
        range: ClosedRange<Int>,
        step: Int
    ) -> some View {
        return editorRow(
            title: title,
            subtitle: nil,
            value: spiceOverrides[key] ?? defaultValue,
            suffix: suffix,
            step: step,
            range: range
        ) { spiceOverrides[key] = $0 }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Harmonogram")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Kolejność i orientacyjne czasy.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                ResultMetaChip(title: timeString(result.totalMinutes), accent: true)
            }

            AppCard {
                VStack(spacing: 0) {
                    ForEach(Array(result.timeline.enumerated()), id: \.element.id) { index, item in
                        TimelineDetailRow(
                            timeLabel: item.timeLabel,
                            title: item.title,
                            subtitle: item.subtitle ?? ""
                        )

                        if index < result.timeline.count - 1 {
                            Divider()
                                .overlay(AppTheme.border)
                                .padding(.leading, 84)
                        }
                    }
                }
            }
            .appSoftShadow()
        }
    }
}
extension BrothResultView {
    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uwagi")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)

            VStack(spacing: 10) {
                ForEach(Array(warningCards.enumerated()), id: \.offset) { _, warning in
                    WarningCard(
                        text: warning.text,
                        severity: warning.severity
                    )
                }
            }
        }
    }

    private var isFiltered: Bool {
        clarityMode != .normal
    }

    private var filteredClarityMode: BrothClarityMode {
        BrothClarityMode.allCases.first(where: { $0 != .normal }) ?? .normal
    }

    private var filteringDescription: String {
        if isFiltered {
            return "Po przecedzeniu użyj filtra papierowego albo bardzo drobnego filtra. Rosół wyjdzie czystszy, ale finalnie zostanie go trochę mniej."
        } else {
            return selectedKind == .veggie ? "Bez dodatkowego filtrowania bulion będzie pełniejszy i zostanie go trochę więcej. Wystarczy zwykłe cedzenie przez sito." : "Bez dodatkowego filtrowania rosół będzie pełniejszy i zostanie go trochę więcej. Wystarczy zwykłe cedzenie przez sito."
        }
    }

    private var vinegarDescription: String {
        if useVinegar {
            return "Mały dodatek na start. Najbardziej pomaga przy kościach i elementach kolagenowych, ale nie powinien być wyczuwalny w smaku."
        } else {
            return "Bez dodatku octu smak będzie bardziej klasyczny. Ekstrakcja z kości będzie trochę słabsza, ale nadal poprawna."
        }
    }

    private var compatibilityStyle: BrothStyle {
        switch mode {
        case .preset(let preset):
            return preset.legacyStyle
        case .custom(let profile):
            return profile.legacyStyle
        }
    }

    private var screenTitle: String {
        switch mode {
        case .preset(let preset):
            return preset.title
        case .custom:
            return selectedKind.map { "Własny \($0.rawValue.lowercased())" } ?? "Własny bulion"
        }
    }

    private var screenSubtitle: String {
        switch mode {
        case .preset:
            return "To podsumowanie kalkulatora dla wybranego przepisu i składników."
        case .custom:
            if let selectedStyleName {
                if selectedKind == .veggie {
                    return "Podsumowanie dla stylu \(selectedStyleName.lowercased()) i wyliczonego koszyka warzyw. Pominęliśmy krok wyboru bazy, bo w warzywnym koszyk liczymy automatycznie z wielkości garnka."
                }
                return "Podsumowanie dla stylu \(selectedStyleName.lowercased()) i wybranej bazy."
            }
            return "Podsumowanie kalkulatora na bazie wybranych składników."
        }
    }

    private var ingredientsSectionDescription: String {
        switch mode {
        case .preset:
            return "Mięso, warzywa i przyprawy policzyła aplikacja."
        case .custom:
            return selectedKind == .veggie ? "Koszyk warzyw policzyła aplikacja na podstawie garnka i wybranego stylu." : "Bazę dodałeś Ty, resztę policzyła aplikacja."
        }
    }

    private var meatProfileShortLabel: String {
        let selections = resolvedSelections

        let hasPoultry = !selections.isEmpty
            ? selections.contains(where: { $0.category == .poultry })
            : containsPoultry
        let hasBeef = !selections.isEmpty
            ? selections.contains(where: { $0.category == .beef })
            : containsBeef
        let hasOffal = !selections.isEmpty
            ? selections.contains(where: { $0.category == .offal })
            : containsOffal

        if hasPoultry && hasBeef {
            return hasOffal ? "drób + woł. + podroby" : "drób + wołowina"
        }

        if hasPoultry {
            return hasOffal ? "drób + podroby" : "drób"
        }

        if hasBeef {
            return hasOffal ? "woł. + podroby" : "wołowina"
        }

        if hasOffal {
            return "podroby"
        }

        return "mieszanka"
    }

    private var containsPoultry: Bool {
        selectedIDs.contains(where: { id in
            let normalized = normalize(id)
            return normalized.contains("kura")
                || normalized.contains("kurcz")
                || normalized.contains("indyk")
                || normalized.contains("kacz")
                || normalized.contains("ges")
                || normalized.contains("skrzyd")
                || normalized.contains("szyj")
                || normalized.contains("lapk")
                || normalized.contains("korpus")
        })
    }

    private var containsBeef: Bool {
        selectedIDs.contains(where: { id in
            let normalized = normalize(id)
            return normalized.contains("wol")
                || normalized.contains("woł")
                || normalized.contains("szponder")
                || normalized.contains("prega")
                || normalized.contains("pręga")
                || normalized.contains("golen")
                || normalized.contains("mostek")
                || normalized.contains("ogon")
                || normalized.contains("kosc")
                || normalized.contains("szpik")
        })
    }

    private var containsOffal: Bool {
        selectedIDs.contains(where: { id in
            let normalized = normalize(id)
            return normalized.contains("serca")
                || normalized.contains("zoladki")
                || normalized.contains("watrob")
        })
    }

    private func vegetableSubtitle(for item: VegetableAmount) -> String? {
        let normalized = normalize(item.name)

        if normalized.contains("marchew") { return "słodycz" }
        if normalized.contains("seler") { return "głębia" }
        if normalized.contains("pietruszka") { return "świeższy finisz" }
        if normalized.contains("por") { return "łagodna cebulowość" }
        if normalized.contains("cebula") { return "słodycz i aromat" }

        return item.note
    }

    private func subtitleForSelection(_ selection: BrothIngredientSelection) -> String {
        let normalizedID = normalize(selection.id)

        switch selection.category {
        case .poultry:
            if normalizedID.contains("kacz") {
                return "Bardziej tłusty i cięższy profil."
            }
            if normalizedID.contains("lapk") || normalizedID.contains("szyj") {
                return "Kolagen i lepsze body."
            }
            if normalizedID.contains("skrzyd") {
                return "Więcej smaku i trochę tłustości."
            }
            return "Część wybrana przez użytkownika."
        case .pork:
            return "Baza wieprzowa pod gęstszy, kremowy profil."

        case .beef:
            if normalizedID.contains("kosc") || normalizedID.contains("ogon") {
                return "Kości i dłuższy finisz."
            }
            return "Mocniejsza, bardziej mięsna baza."

        case .offal:
            if normalizedID.contains("watrob") {
                return "Dodawaj ostrożnie — trafia pod koniec gotowania."
            }
            return "Dodatek pogłębiający smak."
        case .fish:
            return "Delikatna baza rybna, gotuj krócej i łagodniej."
        case .seafood:
            return "Morski akcent umami — używaj ostrożnie, by nie zdominować profilu."
        case .veggies:
            return "Warzywna baza budująca czysty profil bulionu."
        }
    }

    private func sortedSelections(_ selections: [BrothIngredientSelection]) -> [BrothIngredientSelection] {
        selections.sorted {
            if categorySortIndex($0.category) != categorySortIndex($1.category) {
                return categorySortIndex($0.category) < categorySortIndex($1.category)
            }
            if $0.grams != $1.grams {
                return $0.grams > $1.grams
            }
            return $0.name < $1.name
        }
    }

    private func syntheticSelections() -> [BrothIngredientSelection] {
        guard !selectedIDs.isEmpty, totalWeight > 0 else { return [] }

        let base = totalWeight / selectedIDs.count
        let remainder = totalWeight % selectedIDs.count

        return selectedIDs.enumerated().map { index, id in
            let grams = base + (index < remainder ? 1 : 0)
            let normalizedID = normalize(id)

            return BrothIngredientSelection(
                ingredientID: id,
                ingredientName: displayName(for: normalizedID),
                category: categoryFor(normalizedID),
                grams: grams
            )
        }
    }

    private func displayName(for normalizedID: String) -> String {
        switch true {
        case normalizedID.contains("kura"), normalizedID.contains("porcja"):
            return "Kura rosołowa / porcja rosołowa"
        case normalizedID.contains("korpus_kurczaka"):
            return "Korpus z kurczaka"
        case normalizedID.contains("skrzydla_kurczaka"):
            return "Skrzydła z kurczaka"
        case normalizedID.contains("szyje_kurczaka"):
            return "Szyje z kurczaka"
        case normalizedID.contains("lapki"):
            return "Łapki z kurczaka"
        case normalizedID.contains("szyja_indyka"):
            return "Szyja z indyka"
        case normalizedID.contains("skrzydlo_indyka"):
            return "Skrzydło z indyka"
        case normalizedID.contains("korpus_indyka"):
            return "Korpus z indyka"
        case normalizedID.contains("korpus_kaczki"):
            return "Korpus z kaczki"
        case normalizedID.contains("szyja_kaczki"):
            return "Szyja z kaczki"
        case normalizedID.contains("skrzydla_kaczki"):
            return "Skrzydła z kaczki"
        case normalizedID.contains("szponder"):
            return "Szponder"
        case normalizedID.contains("prega"), normalizedID.contains("pręga"):
            return "Pręga"
        case normalizedID.contains("mostek"):
            return "Mostek"
        case normalizedID.contains("golen"):
            return "Goleń wołowa"
        case normalizedID.contains("ogon"):
            return "Ogon wołowy"
        case normalizedID.contains("kosci_szpikowe"):
            return "Kości szpikowe"
        case normalizedID.contains("kosci_rosolowe"), normalizedID.contains("kosci_stawowe"):
            return "Kości rosołowe / stawowe"
        case normalizedID.contains("serca"):
            return "Serca drobiowe"
        case normalizedID.contains("zoladki"):
            return "Żołądki drobiowe"
        case normalizedID.contains("watrob"):
            return "Wątróbka drobiowa"
        default:
            return normalizedID
        }
    }

    private func categoryFor(_ normalizedID: String) -> IngredientCategory {
        if normalizedID.contains("szponder")
            || normalizedID.contains("prega")
            || normalizedID.contains("pręga")
            || normalizedID.contains("mostek")
            || normalizedID.contains("golen")
            || normalizedID.contains("ogon")
            || normalizedID.contains("kosc")
            || normalizedID.contains("szpik")
            || normalizedID.contains("wol")
            || normalizedID.contains("woł") {
            return .beef
        }

        if normalizedID.contains("serca")
            || normalizedID.contains("zoladki")
            || normalizedID.contains("watrob") {
            return .offal
        }

        if normalizedID.contains("ryb")
            || normalizedID.contains("kregoslup")
            || normalizedID.contains("osci")
            || normalizedID.contains("glow") {
            return .fish
        }

        if normalizedID.contains("krewet")
            || normalizedID.contains("malz")
            || normalizedID.contains("skorupiak")
            || normalizedID.contains("shell") {
            return .seafood
        }

        return .poultry
    }

    private func normalize(_ value: String) -> String {
        value
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }

    private func categorySortIndex(_ category: IngredientCategory) -> Int {
        switch category {
        case .poultry: return 0
        case .pork: return 1
        case .beef: return 2
        case .offal: return 3
        case .fish: return 4
        case .seafood: return 5
        case .veggies: return 6
        }
    }

    private func iconKind(for name: String) -> ResultIconKind {
        let normalized = normalize(name)

        if normalized.contains("serca") { return .hearts }
        if normalized.contains("zoladki") { return .gizzards }
        if normalized.contains("watrob") { return .liver }

        if normalized.contains("wol") || normalized.contains("woł") || normalized.contains("szponder") || normalized.contains("prega") || normalized.contains("mostek") || normalized.contains("ogon") {
            return .beef
        }

        if normalized.contains("skrzyd") { return .wings }
        if normalized.contains("lapk") || normalized.contains("szyj") || normalized.contains("kosc") { return .bones }
        if normalized.contains("kura") || normalized.contains("korpus") || normalized.contains("indyk") || normalized.contains("kacz") || normalized.contains("porcja") {
            return .chicken
        }

        if normalized.contains("marchew") { return .carrot }
        if normalized.contains("seler") { return .celery }
        if normalized.contains("pietruszka") { return .parsleyRoot }
        if normalized.contains("por") { return .leek }
        if normalized.contains("cebula") { return .onion }
        if normalized.contains("pieprz") { return .pepper }
        if normalized.contains("laurow") { return .bayLeaf }
        if normalized.contains("ziele") { return .allspice }
        if normalized.contains("ocet") { return .vinegar }
        if normalized.contains("sól") || normalized.contains("sol") { return .salt }

        return .generic
    }

    private func warningText(for warning: BrothWarning) -> String {
        switch warning.code {
        case .hardPotTooSmall:
            return "To jest mniej niż 0,25 l. Ustaw realną pojemność garnka."
        case .hardPotTooBig:
            return "To wygląda na literówkę. Maksymalna pojemność w aplikacji to 30 l."
        case .hardTooMuchMeat:
            return "To ilość przemysłowa. Wprowadź wagę mięsa dla jednego garnka."
        case .hardItemTooBig:
            return "Jedna z wag wygląda podejrzanie wysoko. Sprawdź, czy na pewno wpisujesz gramy."
        case .hardNoMeat:
            return selectedKind == .fish ? "Dodaj bazę rybną. Bez ryb/owoców morza nie policzymy bulionu rybnego." : "Dodaj mięso. Bez mięsa nie ugotujesz rosołu."
        case .hardNotFit:
            return "Ten zestaw fizycznie nie mieści się w tym garnku. Zmniejsz ilość mięsa albo użyj większego naczynia."
        case .premiumBlocked:
            return "Ten składnik jest dostępny dopiero w rozszerzonej wersji kalkulatora."
        case .undermeatLight:
            return selectedKind == .veggie
                ? "Ten garnek pozwala na większy wsad warzywny. Aplikacja dopasowała wodę i dodatki do aktualnej ilości, ale jeśli chcesz mocniejszy profil, możesz zwiększyć gramaturę warzyw."
                : (selectedKind == .fish ? "Wybrałeś mało bazy rybnej jak na ten garnek. Aplikacja dopasuje wodę i dodatki, ale dla mocniejszego profilu możesz dodać trochę ryb lub owoców morza." : "Wybrałeś mniej mięsa, niż spokojnie pomieści ten garnek. Aplikacja dopasuje wodę i dodatki do tej ilości, ale jeśli chcesz mocniejszy rosół, możesz dodać jeszcze trochę mięsa.")
        case .baseTooLowForWater:
            return selectedKind == .veggie ? "Baza jest dość lekka względem ilości wody. Jeśli chcesz pełniejszy efekt, zwiększ koszyk warzyw lub zmniejsz wodę." : (selectedKind == .fish ? "Baza rybna jest lekka względem ilości wody. Dla pełniejszego bulionu zwiększ ryby/owoce morza albo zmniejsz wodę." : "Baza jest lekka względem ilości wody. Dla pełniejszego efektu dodaj więcej bazy lub zmniejsz wodę.")
        case .overmeatLight:
            return "Jak na czystszy profil mięsa jest bardzo dużo. Wywar może wyjść zbyt ciężki."
        case .undermeatIntense:
            return selectedKind == .fish ? "Jak na intensywniejszy bulion rybny baza jest raczej mała. Aplikacja dopasuje proporcje, ale pełniejszy efekt da większa ilość ryb/owoców morza." : "Jak na głębszy profil mięsa jest tu raczej mało. Aplikacja dopasuje proporcje do tej ilości, ale jeśli chcesz pełniejszy efekt, możesz dodać jeszcze trochę mięsa."
        case .overmeatIntense:
            return selectedKind == .fish ? "Bazy rybnej jest bardzo dużo jak na ten litraż. Bulion może wyjść ciężki i gorzkawy." : "Mięsa jest bardzo dużo. Wywar może wyjść zbyt ciężki i trudniejszy do zbalansowania."
        case .baseTooHighForWater:
            return selectedKind == .veggie ? "Koszyk warzyw jest bardzo gęsty względem ilości wody. Bulion może wyjść zbyt ciężki." : (selectedKind == .fish ? "Baza rybna jest bardzo gęsta względem ilości wody. Bulion może wyjść ciężki lub gorzkawy." : "Baza jest bardzo gęsta względem ilości wody. Bulion może wyjść zbyt ciężki.")
        case .overfatLight:
            return "Ten zestaw może wyjść tłusty. Do czystszego profilu lepiej sprawdza się więcej korpusu lub szyi i mniej cięższych elementów."
        case .wingsTooHighLight:
            return "Skrzydełka w większej ilości podbijają tłuszcz. W czystszym rosole warto trzymać je z umiarem."
        case .lowGelatinIntense:
            return "Smak może być głęboki, ale wywar będzie mniej sprężysty, bo jest tu mało kości i kolagenu."
        case .heavyBeefProfile:
            return "Ten zestaw może wyjść ciężki. Warto zmniejszyć udział cięższej wołowiny."
        case .marrowTooHigh:
            return "Jest tu sporo szpiku albo mostka. Rosół może wyjść za ciężki i tłusty."
        case .singleIngredientRisk:
            return "Jeden składnik mocno dominuje w zestawie. Warto lekko go zrównoważyć."
        case .offalDominantRisk:
            return "Podroby są tu już bardzo wyraźne. Lepiej, żeby wspierały bazę, a nie ją przejmowały."
        case .liverTimingRequired:
            return "Wątróbkę dodaj tylko na końcu, na 20–30 minut. Dłuższe gotowanie daje metaliczny posmak i mętność."
        case .paperFilterLowerIntensity:
            return "Filtr papierowy da czystszy rosół, ale finalnie zostanie go mniej i będzie odrobinę lżejszy."
        case .paperFilterHighLoss:
            return "Przy filtrze papierowym strata może być tu wyraźna. Finalnego rosołu zostanie zauważalnie mniej."
        case .waterReducedToFit:
            return "Ten zestaw jest już gęsty jak na ten garnek, więc aplikacja obniżyła ilość wody. Rosół wyjdzie mocniejszy i będzie go trochę mniej."
        }
    }

    private func gramsString(_ grams: Int) -> String {
        if grams % 1000 == 0 {
            return "\(grams / 1000) kg"
        }

        if grams >= 1000 {
            return String(format: "%.1f kg", Double(grams) / 1000.0)
                .replacingOccurrences(of: ".", with: ",")
        }

        return "\(grams) g"
    }

    private func attemptStartCooking() {
        guard !hasBlockingFailure, !isStartingCooking else { return }

        if let conflict = CookingSessionCoordinator.activeConflict(in: batchStore) {
            activeCookingTitleForConflict = conflict.title
            showActiveCookingConflictAlert = true
            return
        }

        startCooking(replacingExistingSession: false)
    }

    private func startCooking(replacingExistingSession: Bool) {
        guard !hasBlockingFailure, !isStartingCooking else { return }
        isStartingCooking = true

        if replacingExistingSession {
            CookingSessionCoordinator.interruptActiveCookingAndCleanup(in: batchStore)
        }

        let ingredientSnapshots = effectiveSelections.map { selection in
            BatchIngredientSnapshot(
                ingredientID: selection.ingredientID,
                ingredientName: selection.ingredientName,
                categoryRawValue: selection.category.rawValue,
                grams: selection.grams
            )
        }

        let ingredientIDs = ingredientSnapshots.map(\.ingredientID)

        let modeRawValue: String
        let presetRawValue: String?
        let profileRawValue: String

        switch mode {
        case .preset(let preset):
            modeRawValue = "preset"
            presetRawValue = preset.rawValue
            profileRawValue = preset.profile.rawValue

        case .custom(let profile):
            modeRawValue = "custom"
            presetRawValue = nil
            profileRawValue = profile.rawValue
        }

        let batch = batchStore.createBatch(
            styleRawValue: compatibilityStyle.rawValue,
            modeRawValue: modeRawValue,
            presetRawValue: presetRawValue,
            profileRawValue: profileRawValue,
            brothKindRawValue: selectedKind?.rawValue,
            selectedStyleName: selectedStyleName,
            clarityModeRawValue: clarityMode.rawValue,
            useVinegar: useVinegar,
            totalWeightGrams: effectiveTotalWeight,
            selectedIngredientCount: ingredientSnapshots.isEmpty ? selectedIngredientCount : ingredientSnapshots.count,
            waterLiters: effectiveResult.waterLiters,
            estimatedYieldLiters: effectiveResult.estimatedYieldLiters,
            totalMinutes: effectiveResult.totalMinutes,
            activeCookingMinutes: effectiveResult.totalMinutes,
            warningCount: warningCards.count,
            hasThermometer: hasThermometer,
            selectedIngredientIDs: ingredientIDs,
            selectedIngredientsSnapshot: ingredientSnapshots,
            meatOverrides: meatOverrides.isEmpty ? nil : meatOverrides,
            vegetableOverrides: vegetableOverrides.isEmpty ? nil : vegetableOverrides,
            spiceOverrides: spiceOverrides.isEmpty ? nil : spiceOverrides,
            customTitle: nil
        )

        savedBatch = batch
        navigateToCooking = true
    }

    private var formattedWeight: String {
        if totalWeight % 1000 == 0 {
            return "\(totalWeight / 1000) kg"
        }

        if totalWeight >= 1000 {
            return String(format: "%.1f kg", Double(totalWeight) / 1000.0)
                .replacingOccurrences(of: ".", with: ",")
        }

        return "\(totalWeight) g"
    }

    private func litersString(_ value: Double) -> String {
        numberString(value) + " l"
    }

    private func parseGrams(from text: String) -> Int {
        let digits = text.filter { $0.isNumber }
        return Int(digits) ?? 0
    }

    private func numberString(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }

        let twoDecimals = String(format: "%.2f", value)
        if twoDecimals.hasSuffix("0") {
            return String(format: "%.1f", value)
                .replacingOccurrences(of: ".", with: ",")
        }

        return twoDecimals.replacingOccurrences(of: ".", with: ",")
    }

    private func timeString(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if mins == 0 {
            return "\(hours) h"
        }

        return "\(hours) h \(mins) min"
    }
}

private struct WarningCardModel: Hashable {
    let text: String
    let severity: BrothWarningSeverity
}

private struct BinaryChoiceControl: View {
    let falseTitle: String
    let trueTitle: String
    let isOn: Bool
    let onFalse: () -> Void
    let onTrue: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            BinaryChoiceOptionButton(
                title: falseTitle,
                isSelected: !isOn,
                action: onFalse
            )

            BinaryChoiceOptionButton(
                title: trueTitle,
                isSelected: isOn,
                action: onTrue
            )
        }
    }
}

private struct BinaryChoiceOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(isSelected ? AppTheme.accentSoft : AppTheme.surfaceMuted)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct RefinementChoiceChip: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 36)
            .background(isSelected ? AppTheme.accentSoft : AppTheme.surfaceMuted)
            .overlay(
                Capsule()
                    .stroke(isSelected ? AppTheme.accent : AppTheme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private enum ResultMetricTooltipKey: Hashable {
    case pot
    case yield
    case load
    case temperature
}

private struct ResultMetricInfoAnchorPreferenceKey: PreferenceKey {
    static var defaultValue: [ResultMetricTooltipKey: Anchor<CGRect>] = [:]

    static func reduce(value: inout [ResultMetricTooltipKey: Anchor<CGRect>], nextValue: () -> [ResultMetricTooltipKey: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private struct ResultMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let tooltipKey: ResultMetricTooltipKey
    let onInfoTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.2)
                    .foregroundStyle(AppTheme.textSecondary)

                Spacer(minLength: 0)

                Button(action: onInfoTap) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .buttonStyle(.plain)
                .anchorPreference(key: ResultMetricInfoAnchorPreferenceKey.self, value: .bounds) { anchor in
                    [tooltipKey: anchor]
                }
            }

            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.82)

            Text(subtitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 82, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .appSoftShadow()
    }
}

private enum ResultIconKind {
    case carrot
    case celery
    case parsleyRoot
    case leek
    case onion
    case salt
    case pepper
    case bayLeaf
    case allspice
    case vinegar
    case chicken
    case wings
    case beef
    case bones
    case hearts
    case gizzards
    case liver
    case generic
}

private struct ResultListRowData {
    let icon: ResultIconKind
    let title: String
    let subtitle: String?
    let value: String
}

private struct ResultListRow: View {
    let item: ResultListRowData

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ResultIllustrationBadge(kind: item.icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 12)

            Text(item.value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
    }
}

private struct MeatShoppingRowData {
    let icon: ResultIconKind
    let title: String
    let subtitle: String
    let value: String
}

private struct MeatShoppingCard: View {
    let title: String
    let totalWeight: String
    let rows: [MeatShoppingRowData]
    let description: String
    let onEdit: (() -> Void)?

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)

                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    ResultMetaChip(title: totalWeight, accent: true)
                    if let onEdit {
                        Button(action: onEdit) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 30, height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(AppTheme.surfaceMuted)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }

                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                        HStack(alignment: .center, spacing: 12) {
                            ResultIllustrationBadge(kind: row.icon)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.title)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(AppTheme.textPrimary)

                                Text(row.subtitle)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 12)

                            Text(row.value)
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .multilineTextAlignment(.trailing)
                        }
                        .padding(.vertical, 12)

                        if index < rows.count - 1 {
                            Divider()
                                .overlay(AppTheme.border)
                                .padding(.leading, 52)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appSoftShadow()
    }
}
private struct ResultIllustrationBadge: View {
    let kind: ResultIconKind

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.surfaceMuted)
                .frame(width: 40, height: 40)

            illustration
                .frame(width: 24, height: 24)
        }
    }

    @ViewBuilder
    private var illustration: some View {
        switch kind {
        case .carrot:
            CarrotIllustration()
        case .celery:
            CeleryIllustration()
        case .parsleyRoot:
            ParsleyRootIllustration()
        case .leek:
            LeekIllustration()
        case .onion:
            OnionIllustration()
        case .salt:
            SaltIllustration()
        case .pepper:
            PepperIllustration()
        case .bayLeaf:
            BayLeafIllustration()
        case .allspice:
            AllspiceIllustration()
        case .vinegar:
            VinegarIllustration()
        case .chicken:
            ChickenIllustration()
        case .wings:
            WingsIllustration()
        case .beef:
            BeefIllustration()
        case .bones:
            BonesMiniIllustration()
        case .hearts:
            HeartsMiniIllustration()
        case .gizzards:
            GizzardsMiniIllustration()
        case .liver:
            LiverMiniIllustration()
        case .generic:
            GenericIllustration()
        }
    }
}

private struct ResultMetaChip: View {
    let title: String
    var accent: Bool = false

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(accent ? AppTheme.accentSoft : AppTheme.surfaceMuted)
            .overlay(
                Capsule()
                    .stroke(accent ? AppTheme.accent : AppTheme.border, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct TimelineDetailRow: View {
    let timeLabel: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(timeLabel)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary)
                .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 12)
    }
}

private struct WarningCard: View {
    let text: String
    let severity: BrothWarningSeverity

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 28, height: 28)

                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(iconColor)
            }
            .padding(.top, 2)

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .appSoftShadow()
    }

    private var iconName: String {
        switch severity {
        case .error:
            return "xmark.octagon.fill"
        case .warn:
            return "exclamationmark.triangle.fill"
        case .info:
            return "info.circle.fill"
        }
    }

    private var iconBackground: Color {
        switch severity {
        case .error:
            return Color(red: 1.0, green: 0.92, blue: 0.92)
        case .warn:
            return Color(red: 1.0, green: 0.95, blue: 0.89)
        case .info:
            return Color(red: 0.93, green: 0.96, blue: 1.0)
        }
    }

    private var iconColor: Color {
        switch severity {
        case .error:
            return Color(red: 0.67, green: 0.17, blue: 0.17)
        case .warn:
            return Color(red: 0.55, green: 0.34, blue: 0.08)
        case .info:
            return Color(red: 0.16, green: 0.36, blue: 0.67)
        }
    }

    private var borderColor: Color {
        switch severity {
        case .error:
            return Color(red: 0.92, green: 0.48, blue: 0.45)
        case .warn:
            return Color(red: 0.96, green: 0.80, blue: 0.46)
        case .info:
            return Color(red: 0.67, green: 0.80, blue: 0.95)
        }
    }
}

// MARK: - Mini ilustracje

private struct CarrotIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 1.0, green: 0.61, blue: 0.18), Color(red: 0.96, green: 0.45, blue: 0.08)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 18)
                .rotationEffect(.degrees(22))
                .offset(x: 1, y: 4)

            Capsule()
                .fill(Color.green.opacity(0.95))
                .frame(width: 4, height: 10)
                .rotationEffect(.degrees(-26))
                .offset(x: -4, y: -7)

            Capsule()
                .fill(Color.green.opacity(0.85))
                .frame(width: 4, height: 10)
                .rotationEffect(.degrees(22))
                .offset(x: 2, y: -8)
        }
    }
}

private struct CeleryIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.72, green: 0.87, blue: 0.58))
                .frame(width: 5, height: 15)
                .offset(x: -4, y: 4)

            Capsule()
                .fill(Color(red: 0.77, green: 0.90, blue: 0.62))
                .frame(width: 5, height: 16)
                .offset(y: 3)

            Capsule()
                .fill(Color(red: 0.69, green: 0.84, blue: 0.54))
                .frame(width: 5, height: 15)
                .offset(x: 4, y: 4)

            Ellipse()
                .fill(Color.green.opacity(0.92))
                .frame(width: 8, height: 5)
                .offset(x: -5, y: -6)

            Ellipse()
                .fill(Color.green.opacity(0.86))
                .frame(width: 8, height: 5)
                .offset(x: 0, y: -8)

            Ellipse()
                .fill(Color.green.opacity(0.9))
                .frame(width: 8, height: 5)
                .offset(x: 5, y: -6)
        }
    }
}

private struct ParsleyRootIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.96, green: 0.92, blue: 0.77), Color(red: 0.90, green: 0.84, blue: 0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 18)
                .rotationEffect(.degrees(12))
                .offset(x: 1, y: 4)

            Capsule()
                .fill(Color.green.opacity(0.92))
                .frame(width: 4, height: 10)
                .rotationEffect(.degrees(-24))
                .offset(x: -4, y: -7)

            Capsule()
                .fill(Color.green.opacity(0.82))
                .frame(width: 4, height: 10)
                .rotationEffect(.degrees(20))
                .offset(x: 3, y: -7)
        }
    }
}

private struct LeekIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.45, green: 0.78, blue: 0.44)],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .frame(width: 10, height: 20)
                .rotationEffect(.degrees(16))

            Capsule()
                .fill(Color.green.opacity(0.95))
                .frame(width: 3.5, height: 10)
                .rotationEffect(.degrees(-22))
                .offset(x: -4, y: -6)

            Capsule()
                .fill(Color.green.opacity(0.88))
                .frame(width: 3.5, height: 11)
                .rotationEffect(.degrees(22))
                .offset(x: 4, y: -6)
        }
    }
}

private struct OnionIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.98, green: 0.86, blue: 0.47), Color(red: 0.92, green: 0.72, blue: 0.22)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 17, height: 17)
                .offset(y: 4)

            Capsule()
                .fill(Color(red: 0.77, green: 0.56, blue: 0.17))
                .frame(width: 5, height: 8)
                .offset(y: -5)
        }
    }
}

private struct SaltIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color.white)
                .frame(width: 14, height: 16)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.gray.opacity(0.22), lineWidth: 1)
                )

            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(Color.gray.opacity(0.35))
                .frame(width: 10, height: 4)
                .offset(y: -5)
        }
    }
}

private struct PepperIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.88))
                .frame(width: 6, height: 6)
                .offset(x: -5, y: 3)

            Circle()
                .fill(Color.black.opacity(0.80))
                .frame(width: 6, height: 6)
                .offset(x: 3, y: -1)

            Circle()
                .fill(Color.black.opacity(0.72))
                .frame(width: 6, height: 6)
                .offset(x: 5, y: 5)
        }
    }
}

private struct BayLeafIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.47, green: 0.79, blue: 0.36), Color(red: 0.22, green: 0.56, blue: 0.20)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14, height: 20)
                .rotationEffect(.degrees(24))

            Capsule()
                .fill(Color.white.opacity(0.45))
                .frame(width: 1.3, height: 13)
                .rotationEffect(.degrees(24))
        }
    }
}

private struct AllspiceIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.50, green: 0.34, blue: 0.20))
                .frame(width: 6, height: 6)
                .offset(x: -5, y: 3)

            Circle()
                .fill(Color(red: 0.56, green: 0.38, blue: 0.22))
                .frame(width: 6, height: 6)
                .offset(x: 3, y: -1)

            Circle()
                .fill(Color(red: 0.46, green: 0.30, blue: 0.18))
                .frame(width: 6, height: 6)
                .offset(x: 5, y: 5)
        }
    }
}

private struct VinegarIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(Color(red: 0.90, green: 0.31, blue: 0.25))
                .frame(width: 12, height: 16)
                .offset(y: 2)

            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color(red: 0.76, green: 0.22, blue: 0.18))
                .frame(width: 5, height: 6)
                .offset(y: -8)
        }
    }
}

private struct ChickenIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.white)
                .frame(width: 14, height: 12)
                .offset(x: 2, y: 4)

            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
                .offset(x: -4, y: -1)

            Ellipse()
                .fill(Color.white)
                .frame(width: 7, height: 5)
                .rotationEffect(.degrees(-28))
                .offset(x: 7, y: 6)

            Triangle()
                .fill(Color.orange)
                .frame(width: 4, height: 4)
                .rotationEffect(.degrees(90))
                .offset(x: -9, y: -1)

            Circle()
                .fill(Color.red.opacity(0.86))
                .frame(width: 2.6, height: 2.6)
                .offset(x: -4, y: -7)
        }
    }
}

private struct WingsIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.96, green: 0.69, blue: 0.29), Color(red: 0.86, green: 0.48, blue: 0.16)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 11, height: 16)
                .rotationEffect(.degrees(-28))
                .offset(x: -4)

            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.97, green: 0.76, blue: 0.33), Color(red: 0.88, green: 0.55, blue: 0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 10, height: 14)
                .rotationEffect(.degrees(28))
                .offset(x: 4)
        }
    }
}

private struct BeefIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.84, green: 0.21, blue: 0.28), Color(red: 0.66, green: 0.10, blue: 0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 18, height: 14)
                .rotationEffect(.degrees(-16))

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(red: 0.98, green: 0.89, blue: 0.88))
                .frame(width: 6, height: 5)
                .offset(x: 3, y: 1)
                .rotationEffect(.degrees(-16))
        }
    }
}

private struct BonesMiniIllustration: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 14, height: 4)
                .rotationEffect(.degrees(-24))

            Circle()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 4, height: 4)
                .offset(x: -6, y: -1)

            Circle()
                .fill(Color(red: 0.95, green: 0.64, blue: 0.22))
                .frame(width: 4, height: 4)
                .offset(x: 6, y: 1)
        }
    }
}

private struct HeartsMiniIllustration: View {
    var body: some View {
        ZStack {
            ResultHeartShape()
                .fill(Color(red: 0.71, green: 0.31, blue: 0.34))
                .frame(width: 10, height: 10)
                .offset(x: -3, y: 1)

            ResultHeartShape()
                .fill(Color(red: 0.62, green: 0.24, blue: 0.28))
                .frame(width: 9, height: 9)
                .offset(x: 3, y: -1)
        }
    }
}

private struct GizzardsMiniIllustration: View {
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(red: 0.79, green: 0.58, blue: 0.45))
                .frame(width: 12, height: 8)
                .rotationEffect(.degrees(-16))
                .offset(x: -3, y: 1)

            Ellipse()
                .fill(Color(red: 0.70, green: 0.50, blue: 0.40))
                .frame(width: 11, height: 7)
                .rotationEffect(.degrees(20))
                .offset(x: 4, y: -1)
        }
    }
}

private struct LiverMiniIllustration: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color(red: 0.60, green: 0.22, blue: 0.20))
                .frame(width: 16, height: 10)
                .rotationEffect(.degrees(-12))

            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(red: 0.72, green: 0.28, blue: 0.24))
                .frame(width: 9, height: 6)
                .offset(x: -2, y: 1)
                .rotationEffect(.degrees(10))
        }
    }
}

private struct GenericIllustration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accentSoft)
                .frame(width: 16, height: 16)

            Circle()
                .fill(AppTheme.accent)
                .frame(width: 7, height: 7)
        }
    }
}

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct ResultHeartShape: Shape {
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

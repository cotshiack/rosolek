import SwiftUI
import Combine
import AudioToolbox
import UIKit
import UserNotifications
import ActivityKit

private enum TimelineStepState {
    case done
    case active
    case next
    case upcoming
}

private enum LivePhaseKind {
    case prep
    case heatUp
    case stabilization
    case addVegetables
    case simmerToPoultryOut
    case removePoultry
    case simmerToVegetablesOut
    case removeVegetables
    case finishBase
    case addLiver
    case finishWithLiver
    case beginRest
    case rest
    case strainAndSeason
}

private struct LivePhase: Identifiable {
    let id = UUID()
    let kind: LivePhaseKind
    let title: String
    let shortText: String
    let detailText: String
    let durationSeconds: Int?
    let timelineLabel: String
    let bottomActionTitle: String?
}

private struct InstructionSheetContent: Identifiable {
    let id = UUID()
    let title: String
    let phaseKind: LivePhaseKind
    let hasThermometer: Bool
    let clarityMode: BrothClarityMode
    let useVinegar: Bool
    let hasPoultry: Bool
    let hasLiver: Bool
}

private struct TemperatureSheetContent: Identifiable {
    let id = UUID()
    let hasThermometer: Bool
    let targetLabel: String
}

private struct IngredientsReminderSheetContent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let vegetableRows: [LiveIngredientReminderRowData]
    let spiceRows: [LiveIngredientReminderRowData]
}

private enum LiveSheet: Identifiable {
    case phase(InstructionSheetContent)
    case temperature(TemperatureSheetContent)
    case ingredients(IngredientsReminderSheetContent)

    var id: UUID {
        switch self {
        case .phase(let content):
            return content.id
        case .temperature(let content):
            return content.id
        case .ingredients(let content):
            return content.id
        }
    }
}

private struct OverheatMessage: Identifiable {
    let id = UUID()
    let title: String
    let text: String
    let isCritical: Bool
}

private struct PhaseSheetSection: Identifiable {
    let id: UUID
    let title: String
    let systemImage: String
    let text: String
    let bullets: [String]

    init(title: String, systemImage: String = "square.text.square", text: String, bullets: [String] = []) {
        self.id = UUID()
        self.title = title
        self.systemImage = systemImage
        self.text = text
        self.bullets = bullets
    }
}

private struct PhaseSheetModel {
    let eyebrow: String
    let intro: String
    let sections: [PhaseSheetSection]
    let footer: String?
    let footerLabel: String
}


private enum LiveIngredientIconKind: Hashable {
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
    case generic
}

private struct LiveIngredientReminderRowData: Hashable {
    let icon: LiveIngredientIconKind
    let title: String
    let subtitle: String?
    let value: String
}

struct CookingModeView: View {
    let batch: BatchRecord
    let result: BrothCalculationResult
    let totalWeightGrams: Int
    let selectedIngredientCount: Int
    let hasThermometer: Bool

    @EnvironmentObject private var batchStore: BatchStore
    @Environment(\.scenePhase) private var scenePhase

    @State private var processElapsedSeconds = 0
    @State private var phaseIndex = 0
    @State private var phaseElapsedSeconds = 0
    @State private var sessionStarted = false
    @State private var isStageRunning = false
    @State private var finalStepCompleted = false
    @State private var showFinishAlert = false
    @State private var activeSheet: LiveSheet?
    @State private var overheatMessage: OverheatMessage?
    @State private var isTimelineExpanded = false

    @State private var prepMeatReady = false
    @State private var prepWaterReady = false
    @State private var prepPotReady = false
    @State private var prepThermometerReady = false
    @State private var prepVinegarReady = false

    @State private var liveActivity: Activity<CookingActivityAttributes>?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var liveControlsOverlayHeight: CGFloat { 238 }
    private var finishButtonOverlayHeight: CGFloat { 92 }

    private var currentBatch: BatchRecord {
        batchStore.batch(for: batch.id) ?? batch
    }

    private var ingredientSnapshots: [BatchIngredientSnapshot] {
        currentBatch.selectedIngredientsSnapshot ?? []
    }

    private var ingredientIDs: [String] {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.map(\.ingredientID)
        }
        return currentBatch.selectedIngredientIDs ?? []
    }

    private var brothProfile: BrothProfile {
        currentBatch.brothProfile
    }

    private var clarityMode: BrothClarityMode {
        currentBatch.clarityMode
    }

    private var batchUsesVinegar: Bool {
        currentBatch.useVinegar
    }

    private var hasPoultry: Bool {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.contains {
                normalizeCookingID($0.categoryRawValue) == normalizeCookingID(IngredientCategory.poultry.rawValue)
            }
        }

        return ingredientIDs.contains { id in
            let normalized = normalizeCookingID(id)
            return normalized.contains("kura")
                || normalized.contains("kurcz")
                || normalized.contains("indyk")
                || normalized.contains("kacz")
                || normalized.contains("ges")
                || normalized.contains("gęś")
                || normalized.contains("skrzyd")
                || normalized.contains("szyj")
                || normalized.contains("lapk")
                || normalized.contains("korpus")
        }
    }

    private var hasLiver: Bool {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.contains {
                normalizeCookingID($0.ingredientID).contains("watrob")
            }
        }

        return ingredientIDs.contains { normalizeCookingID($0).contains("watrob") }
    }

    private var vegetableReminderRows: [LiveIngredientReminderRowData] {
        result.vegetables.map { item in
            LiveIngredientReminderRowData(
                icon: ingredientIconKind(for: item.name),
                title: item.name,
                subtitle: vegetableSubtitle(for: item),
                value: item.amount
            )
        }
    }

    private var spiceReminderRows: [LiveIngredientReminderRowData] {
        [
            LiveIngredientReminderRowData(
                icon: .salt,
                title: "Sól",
                subtitle: "Dodaj porcję startową na tym etapie.",
                value: "\(numberString(result.startSaltGrams)) g"
            ),
            LiveIngredientReminderRowData(
                icon: .pepper,
                title: "Pieprz czarny ziarnisty",
                subtitle: "Czysty aromat.",
                value: "\(result.peppercornCount) \(result.peppercornCount == 1 ? "ziarno" : "ziaren")"
            ),
            LiveIngredientReminderRowData(
                icon: .allspice,
                title: "Ziele angielskie",
                subtitle: "Głębia smaku.",
                value: "\(result.allspiceCount) \(result.allspiceCount == 1 ? "ziarno" : "ziaren")"
            ),
            LiveIngredientReminderRowData(
                icon: .bayLeaf,
                title: "Liść laurowy",
                subtitle: "Tło aromatu.",
                value: result.bayLeafCount == 1 ? "1 liść" : "\(result.bayLeafCount) liście"
            )
        ]
    }

    private var poultrySimmerSeconds: Int {
        hasPoultry ? 105 * 60 : 0
    }

    private var vegetablesTotalSeconds: Int {
        brothProfile == .cleaner ? 135 * 60 : 165 * 60
    }

    private var finishTotalSeconds: Int {
        brothProfile == .cleaner ? 35 * 60 : 75 * 60
    }

    private var simmerAfterPoultrySeconds: Int {
        hasPoultry ? max(0, vegetablesTotalSeconds - poultrySimmerSeconds) : vegetablesTotalSeconds
    }

    private var liverFinishSeconds: Int {
        hasLiver ? min(25 * 60, finishTotalSeconds) : 0
    }

    private var baseFinishBeforeLiverSeconds: Int {
        hasLiver ? max(0, finishTotalSeconds - liverFinishSeconds) : finishTotalSeconds
    }

    private var phases: [LivePhase] {
        var items: [LivePhase] = [
            LivePhase(
                kind: .prep,
                title: "Przygotuj garnek i składniki",
                shortText: batchUsesVinegar
                    ? "Przygotuj mięso, wodę, garnek, termometr i odmierzoną porcję octu."
                    : "Przygotuj mięso, wodę, garnek i termometr.",
                detailText: batchUsesVinegar
                    ? "Na tym etapie przygotuj mięso, wodę, garnek, termometr oraz odmierzoną porcję octu jabłkowego. Zegar uruchamiasz dopiero wtedy, gdy wszystko jest już gotowe."
                    : "Na tym etapie przygotuj mięso, wodę, garnek i termometr. Zegar uruchamiasz dopiero wtedy, gdy wszystko jest już gotowe.",
                durationSeconds: nil,
                timelineLabel: "Przygotuj",
                bottomActionTitle: nil
            ),
            LivePhase(
                kind: .heatUp,
                title: "Podgrzewaj do spokojnej pracy",
                shortText: hasThermometer
                    ? "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero po stabilnym wejściu w zakres 88–90°C."
                    : "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero wtedy, gdy wywar pracuje spokojnie, bez wrzenia.",
                detailText: hasThermometer
                    ? "To etap spokojnego dochodzenia wywaru do temperatury 88–90°C. Najwięcej szumowin zwykle pojawia się właśnie wtedy, gdy wywar przechodzi od zimnej wody do około 75–90°C."
                    : "To etap spokojnego dochodzenia wywaru do delikatnej pracy. Szukaj lekkiego drżenia powierzchni i pojedynczych bąbli przy brzegu. Nie dopuszczaj do pełnego wrzenia.",
                durationSeconds: nil,
                timelineLabel: "Podgrzewaj",
                bottomActionTitle: "Gotowe"
            ),
            LivePhase(
                kind: .stabilization,
                title: "Stabilizuj samo mięso",
                shortText: "Przez pełne 60 minut utrzymuj spokojną temperaturę. Warzywa dodasz dopiero po tym etapie.",
                detailText: "To najważniejszy etap budowania czystej bazy mięsnej. Nie mieszaj wywaru. Zbieraj tylko to, co samo wypływa na powierzchnię.",
                durationSeconds: 60 * 60,
                timelineLabel: "1 h",
                bottomActionTitle: nil
            ),
            LivePhase(
                kind: .addVegetables,
                title: "Dodaj warzywa i przyprawy",
                shortText: "Dodaj teraz wszystkie warzywa i przyprawy wyliczone dla tego wywaru.",
                detailText: "Po zakończeniu stabilizacji dodajesz warzywa, opaloną cebulę oraz przyprawy. Temperatura może na chwilę spaść o 1–3°C. To normalne.",
                durationSeconds: nil,
                timelineLabel: "Dodaj",
                bottomActionTitle: "Dodałem"
            )
        ]

        if hasPoultry {
            items.append(
                LivePhase(
                    kind: .simmerToPoultryOut,
                    title: "Prowadź wywar z warzywami",
                    shortText: "Utrzymuj spokojną temperaturę i przygotuj naczynie na wyjęty drób.",
                    detailText: "Od tej chwili wywar ma pracować spokojnie. Nie mieszaj go i nie dopuszczaj do wrzenia.",
                    durationSeconds: poultrySimmerSeconds,
                    timelineLabel: "Prowadź",
                    bottomActionTitle: nil
                )
            )

            items.append(
                LivePhase(
                    kind: .removePoultry,
                    title: "Wyjmij drób",
                    shortText: "Powinieneś teraz delikatnie wyciągnąć drób z wywaru.",
                    detailText: "Wyjmij drób szczypcami albo łyżką cedzakową. Nie wyciskaj mięsa nad wywarem i nie wzburzaj garnka bardziej niż to konieczne.",
                    durationSeconds: nil,
                    timelineLabel: "Wyjmij drób",
                    bottomActionTitle: "Wyjąłem"
                )
            )
        }

        items.append(
            LivePhase(
                kind: .simmerToVegetablesOut,
                title: "Prowadź wywar dalej",
                shortText: "Warzywa powinny jeszcze przez chwilę oddawać smak, ale nie trzymaj ich zbyt długo.",
                detailText: "Na tym etapie wywar nadal pracuje spokojnie. Zbyt długie trzymanie warzyw daje słodszy, mniej precyzyjny profil.",
                durationSeconds: simmerAfterPoultrySeconds,
                timelineLabel: "Dalej",
                bottomActionTitle: nil
            )
        )

        items.append(
            LivePhase(
                kind: .removeVegetables,
                title: "Wyciągnij warzywa",
                shortText: "Powinieneś teraz delikatnie wyciągnąć warzywa z wywaru.",
                detailText: "Wyciągnij warzywa bez wyciskania i bez mieszania. Po tym etapie zostaje już sama baza mięsna.",
                durationSeconds: nil,
                timelineLabel: "Wyjmij warzywa",
                bottomActionTitle: "Wyjąłem"
            )
        )

        if baseFinishBeforeLiverSeconds > 0 {
            items.append(
                LivePhase(
                    kind: .finishBase,
                    title: "Dokończ bazę",
                    shortText: "Pozwól bazie mięsnej spokojnie pracować jeszcze przez wyliczony czas.",
                    detailText: "To etap domknięcia smaku bez warzyw. Nie podkręcaj ognia i nie mieszaj wywaru.",
                    durationSeconds: baseFinishBeforeLiverSeconds,
                    timelineLabel: "Finisz",
                    bottomActionTitle: nil
                )
            )
        }

        if hasLiver {
            items.append(
                LivePhase(
                    kind: .addLiver,
                    title: "Dodaj wątróbkę",
                    shortText: "Dodaj ją dopiero teraz. To krótki etap na sam koniec gotowania.",
                    detailText: "Wątróbka gotowana zbyt długo daje metaliczny posmak i pogarsza klarowność wywaru. Dlatego dodajesz ją dopiero teraz.",
                    durationSeconds: nil,
                    timelineLabel: "Dodaj wątróbkę",
                    bottomActionTitle: "Dodałem"
                )
            )

            items.append(
                LivePhase(
                    kind: .finishWithLiver,
                    title: "Dokończ wywar z wątróbką",
                    shortText: "Utrzymuj spokojną temperaturę i nie dopuszczaj do wrzenia.",
                    detailText: "To końcowy, krótki etap z wątróbką. Wywar ma pracować spokojnie do samego końca.",
                    durationSeconds: liverFinishSeconds,
                    timelineLabel: "Finisz",
                    bottomActionTitle: nil
                )
            )
        }

        items.append(contentsOf: [
            LivePhase(
                kind: .beginRest,
                title: "Wyłącz i odstaw",
                shortText: "Kończy się gotowanie aktywne. Odstaw garnek i nie ruszaj wywaru.",
                detailText: "Po wyłączeniu ognia osady powinny spokojnie opaść. Nie mieszaj i nie potrząsaj garnkiem.",
                durationSeconds: nil,
                timelineLabel: "Wyłącz",
                bottomActionTitle: "Gotowe"
            ),
            LivePhase(
                kind: .rest,
                title: "Pozwól wywarowi odstać",
                shortText: "Odstawienie przez około 20 minut poprawia klarowność.",
                detailText: "To etap porządkowania klarowności. Po odstawieniu przecedzisz wywar spokojnie, bez pośpiechu.",
                durationSeconds: 20 * 60,
                timelineLabel: "20 min",
                bottomActionTitle: nil
            ),
            LivePhase(
                kind: .strainAndSeason,
                title: clarityMode == .paperFilter ? "Przefiltruj, przecedź i dopraw" : "Przecedź i dopraw",
                shortText: clarityMode == .paperFilter
                    ? "Najpierw przefiltruj wywar, a dopiero potem skoryguj sól."
                    : "Przecedź wywar i dopiero potem skoryguj sól.",
                detailText: clarityMode == .paperFilter
                    ? "Najpierw przecedź wywar wstępnie, a potem dokładnie przefiltruj go przez filtr papierowy albo bardzo gęsty filtr. Dopiero po tym spróbuj i skoryguj sól."
                    : "Przecedź wywar bez wyciskania składników. Dopiero po przecedzeniu sprawdź smak i skoryguj sól.",
                durationSeconds: nil,
                timelineLabel: "Cedzenie",
                bottomActionTitle: "Zakończ"
            )
        ])

        return items
    }

    private var currentPhase: LivePhase {
        phases[min(phaseIndex, phases.count - 1)]
    }

    private var collapsedTimelineIndices: [Int] {
        if phases.isEmpty { return [] }
        let nextIndex = min(phaseIndex + 1, phases.count - 1)
        if nextIndex == phaseIndex {
            return [phaseIndex]
        }
        return [phaseIndex, nextIndex]
    }

    private var totalPlannedSeconds: Int {
        phases.reduce(0) { $0 + ($1.durationSeconds ?? 0) }
    }

    private var progress: Double {
        guard totalPlannedSeconds > 0 else { return 0 }
        if isFinished { return 1.0 }

        let completed = phases.prefix(phaseIndex).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        let currentContribution = min(phaseElapsedSeconds, currentPhase.durationSeconds ?? 0)

        return min(Double(completed + currentContribution) / Double(totalPlannedSeconds), 1.0)
    }

    private var overallRemainingSeconds: Int {
        let remainingCurrent = currentPhaseHasTimer ? currentPhaseRemainingSeconds : 0
        let remainingFuture = phases.suffix(from: min(phaseIndex + 1, phases.count)).reduce(0) { $0 + ($1.durationSeconds ?? 0) }
        return max(0, remainingCurrent + remainingFuture)
    }

    private var canStartCooking: Bool {
        if batchUsesVinegar {
            return prepMeatReady && prepWaterReady && prepPotReady && prepThermometerReady && prepVinegarReady
        }
        return prepMeatReady && prepWaterReady && prepPotReady && prepThermometerReady
    }

    private var canGoBackward: Bool {
        sessionStarted && phaseIndex > 0 && !isFinished
    }

    private var canUseNextButton: Bool {
        guard sessionStarted, !isFinished else { return false }
        if currentPhaseHasTimer { return true }
        return currentPhase.bottomActionTitle != nil
    }

    private var isFinished: Bool {
        finalStepCompleted
    }

    private var currentPhaseHasTimer: Bool {
        currentPhase.durationSeconds != nil
    }

    private var currentPhaseTotalSeconds: Int {
        currentPhase.durationSeconds ?? 0
    }

    private var currentPhaseRemainingSeconds: Int {
        max(0, currentPhaseTotalSeconds - phaseElapsedSeconds)
    }

    private var currentPhaseProgress: Double {
        guard currentPhaseTotalSeconds > 0 else { return 0 }
        return min(Double(phaseElapsedSeconds) / Double(currentPhaseTotalSeconds), 1.0)
    }

    private var targetTemperaturePillText: String {
        hasThermometer ? "\(result.temperatureMin)–\(result.temperatureMax)°C" : "Bez wrzenia"
    }

    private var nextButtonTitle: String {
        guard sessionStarted else { return "Dalej" }
        if currentPhaseHasTimer { return "Pomiń" }
        return currentPhase.bottomActionTitle ?? "Dalej"
    }

    private var shouldShowIngredientReminderButton: Bool {
        currentPhase.kind == .addVegetables && (!vegetableReminderRows.isEmpty || !spiceReminderRows.isEmpty)
    }

    private var shouldShowFoamCard: Bool {
        currentPhase.kind == .heatUp || currentPhase.kind == .stabilization
    }

    private var phaseSupportNote: String? {
        switch currentPhase.kind {
        case .addVegetables:
            return "Po dodaniu warzyw wróć do spokojnej pracy wywaru. Nie zwiększaj gwałtownie ognia."
        case .simmerToPoultryOut, .simmerToVegetablesOut:
            return "Po dodaniu warzyw utrzymuj spokojną pracę wywaru. Nie mieszaj go i nie dopuszczaj do wrzenia."
        case .removePoultry:
            return "Wyjmij drób delikatnie i nie wyciskaj go nad wywarem."
        case .removeVegetables:
            return "Warzywa wyciągnij bez wyciskania. Chodzi o czysty wywar, nie o maksymalny odzysk."
        default:
            return nil
        }
    }

    private var manualCompletionNote: String? {
        guard !currentPhaseHasTimer, let actionTitle = currentPhase.bottomActionTitle, sessionStarted else { return nil }

        if currentPhase.kind == .strainAndSeason {
            return "Gdy skończysz, naciśnij „\(actionTitle)” w dolnym panelu."
        }

        return "Po wykonaniu tego kroku naciśnij „\(actionTitle)” w dolnym panelu."
    }

    var body: some View {
        GeometryReader { _ in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    if !sessionStarted {
                        prepStepCard
                    } else {
                        activeStepCard
                    }

                    timelineSection
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 2)
                .padding(.bottom, isFinished ? (finishButtonOverlayHeight + 20) : (liveControlsOverlayHeight + 20))
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .background(AppTheme.background)
            .clipped()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("Gotowanie na żywo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if isFinished {
                NavigationLink {
                    BatchFeedbackView(batch: currentBatch)
                } label: {
                    AppPrimaryButtonLabel(title: "Oceń rosół")
                }
                .padding(.horizontal, AppSpacing.screen)
                .padding(.bottom, 8)
                .background(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            AppTheme.background.opacity(0.16),
                            AppTheme.background.opacity(0.78)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                )
            } else {
                ZStack(alignment: .bottom) {
                    LiveControlsBackdrop()
                        .allowsHitTesting(false)

                    liveControlsPanel
                        .padding(.horizontal, AppSpacing.screen)
                        .padding(.top, 10)
                        .padding(.bottom, 8)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .phase(let content):
                PhaseDetailsSheet(content: content)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)

            case .temperature(let content):
                TemperatureDetailsSheet(content: content)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)

            case .ingredients(let content):
                IngredientsReminderSheet(content: content)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .alert("Zakończyć gotowanie?", isPresented: $showFinishAlert) {
            Button("Anuluj", role: .cancel) { }
            Button("Zakończ gotowanie", role: .destructive) {
                finalStepCompleted = true
                isStageRunning = false
                CookingSession.clear()
                CookingNotificationService.shared.cancelAll()
                endLiveActivity()
                playFinishSignal()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } message: {
            Text("Po zakończeniu przejdziesz do oceny swojego rosołu.")
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            prepThermometerReady = !hasThermometer
            prepVinegarReady = !batchUsesVinegar
            restoreSessionIfNeeded()
            attachToExistingLiveActivityIfNeeded()
            updateLiveActivity()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
            saveSession(backgrounded: isStageRunning)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                saveSession(backgrounded: true)
                updateLiveActivity()
            } else if newPhase == .active {
                resumeFromBackground()
                attachToExistingLiveActivityIfNeeded()
                updateLiveActivity()
            }
        }
        .onReceive(timer) { _ in
            handleTick()
        }
    }
    
    private var prepStepCard: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border,
            lineWidth: 1
        ) {
            VStack(alignment: .leading, spacing: 18) {
                cardTopRow(
                    openTemperature: openTemperatureSheet,
                    openDetails: { openPhaseSheet(for: phaseIndex) }
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentPhase.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(currentPhase.shortText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                StartChecklistCard(
                    hasThermometer: hasThermometer,
                    waterLiters: result.waterLiters,
                    useVinegar: batchUsesVinegar,
                    vinegarMl: result.appleCiderVinegarMl,
                    prepMeatReady: $prepMeatReady,
                    prepWaterReady: $prepWaterReady,
                    prepPotReady: $prepPotReady,
                    prepThermometerReady: $prepThermometerReady,
                    prepVinegarReady: $prepVinegarReady
                )

                if canStartCooking {
                    ReadyToStartBanner()
                }
            }
            .animation(.easeInOut(duration: 0.2), value: canStartCooking)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSoftShadow()
    }

    private var activeStepCard: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.border,
            lineWidth: 1
        ) {
            VStack(alignment: .leading, spacing: 14) {
                cardTopRow(
                    openTemperature: openTemperatureSheet,
                    openDetails: { openPhaseSheet(for: phaseIndex) }
                )

                VStack(alignment: .leading, spacing: 10) {
                    Text(currentPhase.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(currentPhase.shortText)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if shouldShowIngredientReminderButton {
                    IngredientReminderTriggerCard {
                        openIngredientsReminderSheet()
                    }
                }

                CurrentMiniStepsCard(
                    title: "Teraz zrób",
                    steps: miniSteps(for: currentPhase.kind)
                )

                if let manualCompletionNote {
                    SupportNoteCard(text: manualCompletionNote)
                }

                if shouldShowFoamCard {
                    FoamInfoCard(
                        title: "Szumowiny",
                        text: "Najwięcej szumowin pojawia się zwykle podczas dochodzenia wywaru od zimnej wody do około 75–90°C. Zbieraj je delikatnie tylko wtedy, gdy same wypływają na powierzchnię."
                    )
                }

                if let phaseSupportNote {
                    SupportNoteCard(text: phaseSupportNote)
                }

                if let overheatMessage {
                    OverheatBanner(message: overheatMessage) {
                        self.overheatMessage = nil
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSoftShadow()
    }

    @ViewBuilder
    private func cardTopRow(
        openTemperature: @escaping () -> Void,
        openDetails: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 12) {
            TemperatureMiniPill(title: targetTemperaturePillText)

            Spacer(minLength: 12)

            StepTopIconButton(
                systemName: "thermometer.medium",
                action: openTemperature
            )

            StepTopIconButton(
                systemName: "doc.text",
                action: openDetails
            )
        }
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Harmonogram")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text("Dotknij kroku, aby przeczytać jego pełny opis.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .topLeading)
                }

                Spacer(minLength: 12)

                Button {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.92)) {
                        isTimelineExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text(isTimelineExpanded ? "Mniej" : "Więcej")
                            .font(.system(size: 15, weight: .bold))

                        Image(systemName: isTimelineExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 46)
                    .background(AppTheme.surface)
                    .overlay(
                        Capsule()
                            .stroke(AppTheme.accent, lineWidth: 1)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            AppCard {
                VStack(spacing: 12) {
                    if isTimelineExpanded {
                        ForEach(Array(phases.enumerated()), id: \.element.id) { index, phase in
                            TimelineStepButton(
                                state: state(for: index),
                                metaText: timelineMetaText(for: phase, index: index),
                                title: phase.title,
                                subtitle: phase.shortText,
                                action: { openPhaseSheet(for: index) }
                            )
                        }
                    } else {
                        ForEach(collapsedTimelineIndices, id: \.self) { index in
                            let phase = phases[index]
                            TimelineStepButton(
                                state: state(for: index),
                                metaText: timelineMetaText(for: phase, index: index),
                                title: phase.title,
                                subtitle: phase.shortText,
                                action: { openPhaseSheet(for: index) }
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .appSoftShadow()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var liveControlsPanel: some View {
        AppCard(
            background: AppTheme.surface,
            border: AppTheme.borderStrong.opacity(0.88),
            lineWidth: 1
        ) {
            VStack(spacing: 14) {
                timerTopRow

                ProgressView(value: currentPhaseHasTimer ? currentPhaseProgress : 0)
                    .tint(currentPhaseHasTimer ? AppTheme.accent : AppTheme.borderStrong.opacity(0.7))
                    .opacity(currentPhaseHasTimer ? 1.0 : 0.5)
                    .scaleEffect(y: 1.35, anchor: .center)

                HStack(spacing: 10) {
                    TimerMetricTile(
                        title: "Od początku",
                        value: timerString(processElapsedSeconds)
                    )

                    TimerMetricTile(
                        title: "Do końca",
                        value: countdownString(overallRemainingSeconds)
                    )
                }

                HStack(spacing: 10) {
                    StageIconControlButton(
                        systemImage: "arrow.left",
                        isDisabled: !canGoBackward,
                        action: goToPreviousStep
                    )

                    StageTextControlButton(
                        title: centerButtonTitle,
                        systemImage: centerButtonSystemImage,
                        isDisabled: !sessionStarted && !canStartCooking,
                        filled: true,
                        action: handleCenterAction
                    )

                    StageTextControlButton(
                        title: nextButtonTitle,
                        systemImage: nil,
                        isDisabled: !canUseNextButton,
                        filled: false,
                        action: handleNextAction
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(AppTheme.accent.opacity(0.08))
                .blur(radius: 16)
                .offset(y: 8)
        )
        .appSoftShadow()
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
    }

    private var timerTopRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Etap \(phaseIndex + 1)/\(phases.count)")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Spacer(minLength: 8)

            if currentPhaseHasTimer {
                StageTimerCapsule(
                    label: "czas etapu",
                    value: countdownString(currentPhaseRemainingSeconds)
                )
                .layoutPriority(1)
            } else {
                StageStatusCapsule(text: "Potwierdź krok")
                    .layoutPriority(1)
            }
        }
    }

    private var centerButtonTitle: String {
        if !sessionStarted {
            return "Start"
        }
        return isStageRunning ? "Pauza" : "Wznów"
    }

    private var centerButtonSystemImage: String {
        if !sessionStarted {
            return "play.fill"
        }
        return isStageRunning ? "pause.fill" : "play.fill"
    }

    private func timelineMetaText(for phase: LivePhase, index: Int) -> String {
        if state(for: index) == .done || state(for: index) == .upcoming {
            if let duration = phase.durationSeconds {
                return durationCompactString(duration)
            }
            return phase.timelineLabel
        }
        return "Etap \(index + 1)/\(phases.count)"
    }

    private func state(for index: Int) -> TimelineStepState {
        if isFinished {
            return .done
        }
        if index < phaseIndex {
            return .done
        }
        if index == phaseIndex {
            return .active
        }
        if index == phaseIndex + 1 {
            return .next
        }
        return .upcoming
    }

    private func openPhaseSheet(for index: Int) {
        guard phases.indices.contains(index) else { return }

        activeSheet = .phase(
            InstructionSheetContent(
                title: phases[index].title,
                phaseKind: phases[index].kind,
                hasThermometer: hasThermometer,
                clarityMode: clarityMode,
                useVinegar: batchUsesVinegar,
                hasPoultry: hasPoultry,
                hasLiver: hasLiver
            )
        )
    }

    private func openTemperatureSheet() {
        activeSheet = .temperature(
            TemperatureSheetContent(
                hasThermometer: hasThermometer,
                targetLabel: targetTemperaturePillText
            )
        )
    }

    private func openIngredientsReminderSheet() {
        activeSheet = .ingredients(
            IngredientsReminderSheetContent(
                title: "Lista składników do dodania",
                subtitle: "Sprawdź dokładnie, co i ile powinieneś teraz dodać.",
                vegetableRows: vegetableReminderRows,
                spiceRows: spiceReminderRows
            )
        )
    }

    private func miniSteps(for kind: LivePhaseKind) -> [String] {
        switch kind {
        case .prep:
            var steps = [
                "Włóż mięso do garnka.",
                "Dolej wodę do poziomu z wyliczeń.",
                "Przygotuj garnek i termometr."
            ]

            if batchUsesVinegar && result.appleCiderVinegarMl > 0 {
                steps.insert("Odmierz \(result.appleCiderVinegarMl) ml octu jabłkowego.", at: 2)
            }

            return steps

        case .heatUp:
            return [
                "Grzej powoli i zbieraj szumowiny.",
                "Nie mieszaj wywaru i nie dopuszczaj do wrzenia.",
                hasThermometer
                    ? "Przejdź dalej dopiero po stabilnym wejściu w zakres 88–90°C."
                    : "Przejdź dalej dopiero wtedy, gdy wywar pracuje spokojnie, bez wrzenia."
            ]

        case .stabilization:
            return [
                "Przez pełne 60 minut utrzymuj spokojną temperaturę.",
                "Nie dodawaj jeszcze warzyw.",
                "Zbieraj tylko to, co samo wypływa na powierzchnię."
            ]

        case .addVegetables:
            return [
                "Dodaj warzywa z obliczonej listy.",
                "Dodaj przyprawy w podanych ilościach.",
                "Po dodaniu wróć do spokojnej pracy wywaru."
            ]

        case .simmerToPoultryOut:
            return [
                "Nie mieszaj wywaru.",
                "Utrzymuj spokojną temperaturę.",
                "Przygotuj naczynie na wyjęty drób."
            ]

        case .removePoultry:
            return [
                "Delikatnie wyciągnij drób.",
                "Nie wyciskaj go nad wywarem.",
                "Po wyjęciu wróć do spokojnej pracy wywaru."
            ]

        case .simmerToVegetablesOut:
            return [
                "Pozwól warzywom jeszcze przez chwilę oddawać smak.",
                "Nie trzymaj ich zbyt długo.",
                "Przygotuj sito do późniejszego przecedzania."
            ]

        case .removeVegetables:
            return [
                "Delikatnie wyciągnij warzywa.",
                "Nie wyciskaj ich nad wywarem.",
                "Zostaw samą bazę na końcowy etap."
            ]

        case .finishBase:
            return [
                "Pozwól bazie spokojnie pracować.",
                "Nie podkręcaj ognia.",
                "Przygotuj się do końcowych etapów."
            ]

        case .addLiver:
            return [
                "Dodaj wątróbkę dopiero teraz.",
                "Nie gotuj jej długo.",
                "Po dodaniu przejdź dalej."
            ]

        case .finishWithLiver:
            return [
                "Utrzymuj spokojną temperaturę.",
                "Nie dopuszczaj do wrzenia.",
                "Po upływie czasu wyłącz ogień."
            ]

        case .beginRest:
            return [
                "Wyłącz ogień.",
                "Odstaw garnek i nie ruszaj wywaru.",
                "Pozwól osadom spokojnie opaść."
            ]

        case .rest:
            return [
                "Nie mieszaj wywaru.",
                "Przygotuj sito i naczynie.",
                "Po odstawieniu przecedź wywar."
            ]

        case .strainAndSeason:
            if clarityMode == .paperFilter {
                return [
                    "Najpierw przecedź wywar wstępnie.",
                    "Potem dokładnie go przefiltruj.",
                    "Dopraw sól dopiero po filtracji."
                ]
            }

            return [
                "Przecedź wywar bez wyciskania składników.",
                "Spróbuj go po przecedzeniu.",
                "Dopraw sól dopiero na końcu."
            ]
        }
    }

    private func handleTick() {
        guard sessionStarted, !isFinished, isStageRunning else { return }

        processElapsedSeconds += 1

        if currentPhaseHasTimer {
            phaseElapsedSeconds += 1

            if phaseElapsedSeconds >= currentPhaseTotalSeconds {
                phaseElapsedSeconds = 0
                playTimedStageFinishedSignal()
                advanceToNextPhase()
            }
        }
    }

    private func schedulePhaseNotification() {
        guard currentPhaseHasTimer, isStageRunning else {
            CookingNotificationService.shared.cancelAll()
            return
        }
        CookingNotificationService.shared.schedulePhaseEnd(
            stepTitle: currentPhase.title,
            inSeconds: currentPhaseRemainingSeconds
        )
    }

    private func handleCenterAction() {
        guard !isFinished else { return }

        if !sessionStarted {
            startCookingFromPrep()
            return
        }

        isStageRunning.toggle()
        if isStageRunning {
            schedulePhaseNotification()
        } else {
            CookingNotificationService.shared.cancelAll()
        }
        updateLiveActivity()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        playTapSignal()
    }

    private func startCookingFromPrep() {
        guard canStartCooking else { return }

        CookingNotificationService.shared.requestPermission()

        withAnimation(.easeInOut(duration: 0.3)) {
            sessionStarted = true
            phaseIndex = 1
            phaseElapsedSeconds = 0
            isStageRunning = true
        }
        schedulePhaseNotification()
        startLiveActivity()
        playStartSignal()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func handleNextAction() {
        guard canUseNextButton else { return }

        if currentPhase.kind == .strainAndSeason {
            showFinishAlert = true
            return
        }

        playManualAdvanceSignal()
        advanceToNextPhase()
    }

    private func advanceToNextPhase() {
        guard phaseIndex < phases.count - 1 else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            phaseIndex += 1
            phaseElapsedSeconds = 0
            overheatMessage = nil
        }
        schedulePhaseNotification()
        updateLiveActivity()
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    private func goToPreviousStep() {
        guard canGoBackward else { return }

        withAnimation(.easeInOut(duration: 0.25)) {
            phaseIndex -= 1
            phaseElapsedSeconds = 0
            overheatMessage = nil
        }
        schedulePhaseNotification()
        updateLiveActivity()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        playTapSignal()
    }

    private func playStartSignal() {
        AudioServicesPlaySystemSound(1005)
    }

    private func playTapSignal() {
        AudioServicesPlaySystemSound(1104)
    }

    private func playManualAdvanceSignal() {
        AudioServicesPlaySystemSound(1111)
    }

    private func playTimedStageFinishedSignal() {
        AudioServicesPlaySystemSound(1016)
    }

    private func playFinishSignal() {
        AudioServicesPlaySystemSound(1005)
    }

    private func countdownString(_ seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        let remainingSeconds = max(0, seconds) % 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }

    private func timerString(_ seconds: Int) -> String {
        let totalMinutes = max(0, seconds) / 60
        let remainingSeconds = max(0, seconds) % 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    }

    private func durationCompactString(_ seconds: Int) -> String {
        let minutes = max(0, Int(ceil(Double(seconds) / 60.0)))
        if minutes >= 60 {
            let hours = minutes / 60
            let rest = minutes % 60
            return rest == 0 ? "\(hours) h" : "\(hours) h \(rest)"
        }
        return "\(minutes) min"
    }

    private func numberString(_ value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }

        let twoDecimals = String(format: "%.2f", value)
        if twoDecimals.hasSuffix("0") {
            return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
        }

        return twoDecimals.replacingOccurrences(of: ".", with: ",")
    }

    private func vegetableSubtitle(for item: VegetableAmount) -> String? {
        let normalized = normalizeCookingID(item.name)

        if normalized.contains("marchew") { return "Słodycz." }
        if normalized.contains("seler") { return "Głębia smaku." }
        if normalized.contains("pietruszka") { return "Świeższy finisz." }
        if normalized.contains("por") { return "Łagodna cebulowość." }
        if normalized.contains("cebula") { return item.note ?? "Opalana." }

        return item.note
    }

    private func ingredientIconKind(for name: String) -> LiveIngredientIconKind {
        let normalized = normalizeCookingID(name)

        if normalized.contains("marchew") { return .carrot }
        if normalized.contains("seler") { return .celery }
        if normalized.contains("pietruszka") { return .parsleyRoot }
        if normalized.contains("por") { return .leek }
        if normalized.contains("cebula") { return .onion }
        if normalized.contains("pieprz") { return .pepper }
        if normalized.contains("laurow") { return .bayLeaf }
        if normalized.contains("ziele") { return .allspice }
        if normalized.contains("sól") || normalized.contains("sol") { return .salt }
        if normalized.contains("ocet") { return .vinegar }

        return .generic
    }

    private func liveActivityState() -> CookingActivityAttributes.ContentState {
        let stepEnd: Date? = currentPhaseHasTimer && isStageRunning
            ? Date().addingTimeInterval(TimeInterval(currentPhaseRemainingSeconds))
            : nil
        let totalEnd: Date? = isStageRunning && overallRemainingSeconds > 0
            ? Date().addingTimeInterval(TimeInterval(overallRemainingSeconds))
            : nil
        return CookingActivityAttributes.ContentState(
            stepName: currentPhase.title,
            stepNumber: max(0, phaseIndex),
            totalSteps: max(1, phases.count - 1),
            stepEndDate: stepEnd,
            totalEndDate: totalEnd,
            totalProgress: progress,
            isRunning: isStageRunning
        )
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let existingActivity = existingLiveActivity() {
            liveActivity = existingActivity
            updateLiveActivity()
            return
        }
        let attributes = CookingActivityAttributes(batchID: currentBatch.id, batchTitle: currentBatch.displayTitle)
        let state = liveActivityState()
        liveActivity = try? Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: nil)
        )
    }

    private func updateLiveActivity() {
        if liveActivity == nil {
            liveActivity = existingLiveActivity()
        }
        guard let activity = liveActivity else { return }
        let state = liveActivityState()
        Task {
            await activity.update(.init(state: state, staleDate: nil))
        }
    }

    private func endLiveActivity() {
        guard let activity = liveActivity else { return }
        let state = liveActivityState()
        Task {
            await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .immediate)
        }
        liveActivity = nil
    }

    private func attachToExistingLiveActivityIfNeeded() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if liveActivity == nil {
            liveActivity = existingLiveActivity()
        }
        if !sessionStarted, phaseIndex == 0 {
            restoreFromLiveActivityIfNeeded()
        }
    }

    private func existingLiveActivity() -> Activity<CookingActivityAttributes>? {
        Activity<CookingActivityAttributes>.activities.first { activity in
            activity.attributes.batchID == currentBatch.id
        }
    }

    private func restoreFromLiveActivityIfNeeded() {
        guard let activity = existingLiveActivity() else { return }
        let state = activity.content.state
        guard state.stepNumber > 0 else { return }

        phaseIndex = min(max(0, state.stepNumber), phases.count - 1)
        sessionStarted = true
        isStageRunning = state.isRunning
        phaseElapsedSeconds = 0

        if let currentDuration = phases[phaseIndex].durationSeconds,
           let stepEndDate = state.stepEndDate,
           state.isRunning {
            let remaining = max(0, Int(stepEndDate.timeIntervalSinceNow))
            phaseElapsedSeconds = max(0, currentDuration - remaining)
        }
    }

    private func saveSession(backgrounded: Bool) {
        guard sessionStarted, !isFinished else {
            CookingSession.clear()
            return
        }
        var session = CookingSession(
            batchID: batch.id,
            phaseIndex: phaseIndex,
            phaseElapsedSeconds: phaseElapsedSeconds,
            processElapsedSeconds: processElapsedSeconds,
            isStageRunning: isStageRunning,
            prepMeatReady: prepMeatReady,
            prepWaterReady: prepWaterReady,
            prepPotReady: prepPotReady,
            prepThermometerReady: prepThermometerReady,
            prepVinegarReady: prepVinegarReady,
            backgroundedAt: backgrounded ? Date() : nil,
            currentPhaseTitle: currentPhase.timelineLabel,
            currentPhaseTotalSeconds: currentPhase.durationSeconds,
            overallRemainingSeconds: overallRemainingSeconds
        )
        session.save()
    }

    private func advanceElapsedThroughPhases(_ elapsed: Int) {
        var remaining = elapsed
        processElapsedSeconds += elapsed
        while remaining > 0 && phaseIndex < phases.count - 1 {
            guard currentPhaseHasTimer else { break }
            let timeLeft = currentPhaseTotalSeconds - phaseElapsedSeconds
            if remaining >= timeLeft {
                remaining -= timeLeft
                phaseIndex += 1
                phaseElapsedSeconds = 0
            } else {
                phaseElapsedSeconds += remaining
                remaining = 0
            }
        }
    }

    private func restoreSessionIfNeeded() {
        guard let session = CookingSession.load(),
              session.batchID == batch.id,
              !isFinished
        else {
            restoreFromLiveActivityIfNeeded()
            return
        }

        phaseIndex = session.phaseIndex
        phaseElapsedSeconds = session.phaseElapsedSeconds
        processElapsedSeconds = session.processElapsedSeconds
        isStageRunning = session.isStageRunning
        sessionStarted = session.phaseIndex > 0
        prepMeatReady = session.prepMeatReady
        prepWaterReady = session.prepWaterReady
        prepPotReady = session.prepPotReady
        prepThermometerReady = session.prepThermometerReady
        prepVinegarReady = session.prepVinegarReady

        if !sessionStarted, phaseIndex == 0 {
            restoreFromLiveActivityIfNeeded()
        }

        if let backgroundedAt = session.backgroundedAt, session.isStageRunning {
            let elapsed = Int(Date().timeIntervalSince(backgroundedAt))
            if elapsed > 0 {
                advanceElapsedThroughPhases(elapsed)
            }
        }
    }

    private func resumeFromBackground() {
        guard sessionStarted, !isFinished else { return }
        guard let session = CookingSession.load(),
              session.batchID == batch.id,
              let backgroundedAt = session.backgroundedAt,
              session.isStageRunning
        else { return }

        let elapsed = Int(Date().timeIntervalSince(backgroundedAt))
        guard elapsed > 0 else { return }

        advanceElapsedThroughPhases(elapsed)
        saveSession(backgrounded: false)
    }
}

private func normalizeCookingID(_ value: String) -> String {
    value
        .folding(options: .diacriticInsensitive, locale: nil)
        .lowercased()
}

private struct TemperatureMiniPill: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(AppTheme.accentSoft)
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent, lineWidth: 1)
            )
            .clipShape(Capsule())
    }
}

private struct StepTopIconButton: View {
    let systemName: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.surfaceSoft)
                    .frame(width: 52, height: 52)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
                    .frame(width: 52, height: 52)

                Image(systemName: systemName)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct ReadyToStartBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(red: 0.21, green: 0.75, blue: 0.36))
                .padding(.top, 2)

            Text("Checklista jest gotowa. Naciśnij Start w dolnym panelu.")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(Color(red: 0.91, green: 0.97, blue: 0.93))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color(red: 0.67, green: 0.88, blue: 0.71), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct FoamInfoCard: View {
    let title: String
    let text: String

    var body: some View {
        AppCard(
            background: AppTheme.surfaceSoft,
            border: AppTheme.border
        ) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(text)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

private struct SupportNoteCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .padding(.top, 2)

            Text(text)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(16)
        .background(AppTheme.surfaceSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct IngredientReminderTriggerCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text("Lista składników")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: 8)

                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(AppTheme.surface)
                        .frame(width: 36, height: 36)

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                        .frame(width: 36, height: 36)

                    Image(systemName: "doc.text")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 58)
            .background(AppTheme.surfaceSoft)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct StartChecklistCard: View {
    let hasThermometer: Bool
    let waterLiters: Double
    let useVinegar: Bool
    let vinegarMl: Int

    @Binding var prepMeatReady: Bool
    @Binding var prepWaterReady: Bool
    @Binding var prepPotReady: Bool
    @Binding var prepThermometerReady: Bool
    @Binding var prepVinegarReady: Bool

    var body: some View {
        AppCard(
            background: AppTheme.surfaceSoft,
            border: AppTheme.border
        ) {
            VStack(spacing: 0) {
                ChecklistRow(
                    title: "Mięso włóż do garnka",
                    isOn: $prepMeatReady
                )

                Divider()
                    .overlay(AppTheme.border)

                ChecklistRow(
                    title: "Dolej \(waterLabel) wody",
                    isOn: $prepWaterReady
                )

                if useVinegar {
                    Divider()
                        .overlay(AppTheme.border)

                    ChecklistRow(
                        title: "Dodaj \(vinegarMl) ml octu jabłkowego",
                        isOn: $prepVinegarReady
                    )
                }

                Divider()
                    .overlay(AppTheme.border)

                ChecklistRow(
                    title: "Garnek ustaw na kuchence",
                    isOn: $prepPotReady
                )

                if hasThermometer {
                    Divider()
                        .overlay(AppTheme.border)

                    ChecklistRow(
                        title: "Termometr włóż do wody",
                        isOn: $prepThermometerReady
                    )
                }
            }
        }
    }

    private var waterLabel: String {
        if waterLiters == floor(waterLiters) {
            return "\(Int(waterLiters)) l"
        }

        let twoDecimals = String(format: "%.2f", waterLiters).replacingOccurrences(of: ".", with: ",")
        if twoDecimals.hasSuffix("0") {
            return String(twoDecimals.dropLast()) + " l"
        }

        return "\(twoDecimals) l"
    }
}

private struct ChecklistRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isOn.toggle()
            }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isOn ? AppTheme.accent : AppTheme.surface)
                        .frame(width: 32, height: 32)

                    Circle()
                        .stroke(isOn ? AppTheme.accent : AppTheme.borderStrong, lineWidth: 1)
                        .frame(width: 32, height: 32)

                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .transition(.scale(scale: 0.4).combined(with: .opacity))
                    }
                }

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

private struct CurrentMiniStepsCard: View {
    let title: String
    let steps: [String]

    var body: some View {
        AppCard(
            background: AppTheme.surfaceSoft,
            border: AppTheme.border
        ) {
            VStack(alignment: .leading, spacing: 14) {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(3)
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .center, spacing: 12) {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.accent)
                            .clipShape(Circle())

                        Text(step)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        }
    }
}

private struct TimelineStepButton: View {
    let state: TimelineStepState
    let metaText: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Text(metaText)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(state == .done ? AppTheme.textTertiary : AppTheme.textSecondary)

                    Spacer()

                    stateBadge
                }

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(titleColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(subtitleColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(rowBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(rowBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .opacity(state == .done ? 0.58 : 1.0)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var stateBadge: some View {
        switch state {
        case .active:
            HStack(spacing: 8) {
                PulsingTimelineDot()
                Text("teraz")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
            }
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(AppTheme.accentSoft)
            .overlay(
                Capsule()
                    .stroke(AppTheme.accent, lineWidth: 1)
            )
            .clipShape(Capsule())

        case .next:
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
                Text("za chwilę")
                    .font(.system(size: 13, weight: .bold))
            }
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(AppTheme.surfaceSoft)
            .overlay(
                Capsule()
                    .stroke(AppTheme.borderStrong, lineWidth: 1)
            )
            .clipShape(Capsule())

        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textTertiary)

        case .upcoming:
            Circle()
                .fill(AppTheme.borderStrong)
                .frame(width: 12, height: 12)
        }
    }

    private var rowBackground: Color {
        switch state {
        case .active:
            return AppTheme.accentSoft.opacity(0.58)
        case .next:
            return AppTheme.surfaceSoft
        case .done, .upcoming:
            return AppTheme.surface
        }
    }

    private var rowBorder: Color {
        switch state {
        case .active:
            return AppTheme.accent
        case .next:
            return AppTheme.borderStrong
        case .done, .upcoming:
            return AppTheme.border
        }
    }

    private var titleColor: Color {
        state == .done ? AppTheme.textSecondary : AppTheme.textPrimary
    }

    private var subtitleColor: Color {
        state == .done ? AppTheme.textTertiary : AppTheme.textSecondary
    }
}

private struct PulsingTimelineDot: View {
    @State private var animate = false

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.accent.opacity(0.18))
                .frame(width: 18, height: 18)
                .scaleEffect(animate ? 1.12 : 0.86)
                .opacity(animate ? 1.0 : 0.55)

            Circle()
                .fill(AppTheme.accent)
                .frame(width: 9, height: 9)
        }
        .onAppear {
            animate = true
        }
        .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: animate)
    }
}

private struct StageTimerCapsule: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textSecondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)

            Circle()
                .fill(AppTheme.accent)
                .frame(width: 5, height: 5)

            Text(value)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.9)
        }
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(AppTheme.accentSoft)
        .overlay(
            Capsule()
                .stroke(AppTheme.accent, lineWidth: 1)
        )
        .clipShape(Capsule())
        .fixedSize(horizontal: true, vertical: false)
    }
}

private struct StageStatusCapsule: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(AppTheme.surface)
            .overlay(
                Capsule()
                    .stroke(AppTheme.borderStrong, lineWidth: 1)
            )
            .clipShape(Capsule())
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct TimerMetricTile: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.4)
                .foregroundStyle(AppTheme.textSecondary)

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceSoft)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct StageIconControlButton: View {
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isDisabled ? AppTheme.surfaceMuted : AppTheme.surface)
                    .frame(width: 72, height: 58)

                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isDisabled ? AppTheme.border : AppTheme.borderStrong, lineWidth: 1)
                    .frame(width: 72, height: 58)

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isDisabled ? AppTheme.textTertiary : AppTheme.textPrimary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct StageTextControlButton: View {
    let title: String
    let systemImage: String?
    let isDisabled: Bool
    let filled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: systemImage == nil ? 0 : 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .bold))
                }

                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
            }
            .foregroundStyle(filled ? AppTheme.textPrimary : (isDisabled ? AppTheme.textTertiary : AppTheme.textPrimary))
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background(
                filled
                    ? (isDisabled ? AppTheme.accent.opacity(0.45) : AppTheme.accent)
                    : AppTheme.surface
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        filled
                            ? (isDisabled ? AppTheme.accent.opacity(0.45) : AppTheme.accent)
                            : (isDisabled ? AppTheme.border : AppTheme.borderStrong),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

private struct OverheatBanner: View {
    let message: OverheatMessage
    let dismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: message.isCritical ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(message.isCritical ? Color(red: 0.71, green: 0.17, blue: 0.16) : Color(red: 0.74, green: 0.41, blue: 0.08))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(message.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Button(action: dismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .background(AppTheme.surface.opacity(0.7))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(message.isCritical ? Color(red: 1.0, green: 0.93, blue: 0.93) : Color(red: 1.0, green: 0.96, blue: 0.90))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    message.isCritical
                        ? Color(red: 0.95, green: 0.67, blue: 0.62)
                        : Color(red: 0.96, green: 0.76, blue: 0.47),
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct IngredientsReminderSheet: View {
    let content: IngredientsReminderSheetContent

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text(content.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Text(content.subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    IngredientsSectionCard(
                        title: "Warzywa",
                        rows: content.vegetableRows
                    )

                    IngredientsSectionCard(
                        title: "Przyprawy",
                        rows: content.spiceRows
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .background(AppTheme.background)
        }
    }
}

private struct IngredientsSectionCard: View {
    let title: String
    let rows: [LiveIngredientReminderRowData]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)

                ForEach(Array(rows.enumerated()), id: \.offset) { index, row in
                    HStack(alignment: .center, spacing: 12) {
                        LiveIngredientIllustrationBadge(kind: row.icon)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(row.title)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)

                            if let subtitle = row.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer(minLength: 8)

                        Text(row.value)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 10)

                    if index < rows.count - 1 {
                        Divider()
                            .overlay(AppTheme.border)
                            .padding(.leading, 52)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .appSoftShadow()
    }
}

private struct LiveIngredientIllustrationBadge: View {
    let kind: LiveIngredientIconKind

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
        case .generic:
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 10, height: 10)
        }
    }
}

private struct TemperatureDetailsSheet: View {
    let content: TemperatureSheetContent

    private var heroText: String {
        content.hasThermometer
            ? "Zakres 88–90°C pomaga budować smak równomiernie, utrzymać klarowność i nie rozbijać osadu."
            : "Szukasz spokojnej pracy bez pełnego wrzenia. Liczy się stabilność powierzchni, nie szybkie bulgotanie."
    }

    private var foamSupportText: String {
        "Najwięcej szumowin pojawia się zwykle podczas dochodzenia wywaru od zimnej wody do około 75–90°C. Zbieraj je delikatnie tylko wtedy, gdy same wypływają na powierzchnię."
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Temperatura")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)

                    SheetHeroCard(
                        eyebrow: "Zakres docelowy",
                        emphasis: content.targetLabel,
                        text: heroText
                    )

                    TemperatureMechanicsPanel(
                        hasThermometer: content.hasThermometer
                    )

                    SheetSupportStrip(
                        title: "Szumowiny i klarowność",
                        systemImage: "sparkles",
                        text: foamSupportText
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .background(AppTheme.background)
        }
    }
}

private struct TemperatureMechanicsPanel: View {
    let hasThermometer: Bool

    private var lowRange: String {
        hasThermometer ? "Poniżej 88°C" : "Za słaba praca"
    }

    private var goodRange: String {
        hasThermometer ? "88–90°C" : "Spokojna praca"
    }

    private var highRange: String {
        hasThermometer ? "Powyżej 92°C lub wrzenie" : "Za mocno lub wrzenie"
    }

    private var introText: String {
        "Temperatura steruje nie tylko tempem gotowania, ale też klarownością, ciężarem smaku i zachowaniem osadu. Najlepszy efekt daje spokojna, stabilna praca."
    }

    private var lowExplanation: String {
        hasThermometer
            ? "Ekstrakcja zwalnia, mięso oddaje smak wolniej, a etap zaczyna się rozmywać."
            : "Powierzchnia jest zbyt spokojna, więc wywar buduje się wolniej i trudniej utrzymać rytm etapu."
    }

    private var goodExplanation: String {
        hasThermometer
            ? "To zakres, w którym smak przechodzi do wywaru równomiernie, a osad ma szansę spokojnie opaść."
            : "Powierzchnia delikatnie drży, przy brzegu pojawiają się pojedyncze bąble, ale środek nie bulgocze."
    }

    private var highExplanation: String {
        hasThermometer
            ? "Białka i tłuszcz są mocniej rozbijane, rośnie ryzyko mętności, a profil robi się cięższy."
            : "Pełne bulgotanie rozbija szumowiny i miesza je w płynie, przez co rosół łatwo traci klarowność."
    }

    private var lowAction: String {
        "Lekko zwiększ ogień i obserwuj zmiany spokojnie, bez gwałtownego skoku."
    }

    private var goodAction: String {
        "Nie zmieniaj ustawień. Utrzymuj równą pracę i nie mieszaj garnka."
    }

    private var highAction: String {
        "Zmniejsz ogień albo zdejmij garnek na 60–120 sekund, aż powierzchnia wróci do spokojnej pracy."
    }

    private var sensoryNote: String {
        hasThermometer
            ? "Termometr daje punkt odniesienia, ale nadal obserwuj powierzchnię: stabilna praca jest ważniejsza niż pojedynczy odczyt."
            : "Bez termometru patrz na powierzchnię. Szukasz delikatnego drżenia i pojedynczych bąbli przy brzegu — nie pełnego wrzenia."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Temperatura w praktyce")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(introText)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AppCard(background: AppTheme.surface, border: AppTheme.border) {
                VStack(spacing: 0) {
                    TemperatureMeaningRow(
                        title: "Za niska",
                        rangeText: lowRange,
                        explanation: lowExplanation,
                        actionText: lowAction,
                        tone: .neutral
                    )

                    Divider().overlay(AppTheme.border)

                    TemperatureMeaningRow(
                        title: "Prawidłowa",
                        rangeText: goodRange,
                        explanation: goodExplanation,
                        actionText: goodAction,
                        tone: .positive
                    )

                    Divider().overlay(AppTheme.border)

                    TemperatureMeaningRow(
                        title: "Za wysoka lub wrzenie",
                        rangeText: highRange,
                        explanation: highExplanation,
                        actionText: highAction,
                        tone: .warning
                    )

                    Divider().overlay(AppTheme.border)

                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: hasThermometer ? "thermometer.medium" : "eye")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(AppTheme.textTertiary)
                            .frame(width: 18, height: 18)
                            .padding(.top, 1)

                        Text(sensoryNote)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TemperatureMeaningRow: View {
    let title: String
    let rangeText: String
    let explanation: String
    let actionText: String
    let tone: SheetIconTone

    private var dotColor: Color {
        switch tone {
        case .neutral: return AppTheme.textTertiary
        case .positive: return AppTheme.success
        case .warning: return AppTheme.warning
        }
    }

    private var pillBackground: Color {
        switch tone {
        case .neutral: return AppTheme.surfaceSoft
        case .positive: return AppTheme.accentSoft
        case .warning: return AppTheme.warning.opacity(0.12)
        }
    }

    private var pillStroke: Color {
        switch tone {
        case .neutral: return AppTheme.border
        case .positive: return AppTheme.accent.opacity(0.4)
        case .warning: return AppTheme.warning.opacity(0.4)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle()
                    .fill(dotColor)
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text(rangeText)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .frame(height: 22)
                    .background(pillBackground)
                    .overlay(Capsule().stroke(pillStroke, lineWidth: 1))
                    .clipShape(Capsule())
                    .fixedSize(horizontal: true, vertical: false)
            }

            Text(explanation)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(actionText)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PhaseDetailsSheet: View {
    let content: InstructionSheetContent

    private var model: PhaseSheetModel {
        switch content.phaseKind {
        case .prep:
            return PhaseSheetModel(
                eyebrow: "Zanim zaczniesz",
                intro: "Rosół jest wywarem ekstrakcyjnym: jakość zależy od czasu i temperatury. Najczęstsze błędy wynikają z pośpiechu, mieszania i przekraczania temperatury pracy.",
                sections: [
                    PhaseSheetSection(
                        title: "Przygotuj stanowisko",
                        systemImage: "checklist",
                        text: "Zanim uruchomisz gotowanie, ustaw wszystko tak, żeby w trakcie pracy nie szukać narzędzi ani nie wykonywać nerwowych ruchów.",
                        bullets: [
                            "Mięso włóż do garnka i wlej wodę z kalkulatora.",
                            content.hasThermometer ? "Sondę umieść w wodzie tak, aby nie dotykała dna ani ścian garnka." : "Obserwuj powierzchnię spokojnie i nie mieszaj garnka.",
                            "Przygotuj sitko lub łyżkę do szumowin, szczypce albo łyżkę cedzakową oraz sito lub gazę do cedzenia."
                        ]
                    ),
                    PhaseSheetSection(
                        title: "Dodatkowe uwagi",
                        systemImage: "text.badge.star",
                        text: "Ten etap porządkuje start. Dzięki temu później łatwiej utrzymać klarowność i właściwe tempo pracy.",
                        bullets: content.useVinegar ? ["Mięso możesz krótko opłukać tylko z luźnych resztek z pakowania. Nie blanszuj.", "Ocet działa tu funkcjonalnie i w małej ilości nie powinien być wyczuwalny w smaku."] : ["Mięso możesz krótko opłukać tylko z luźnych resztek z pakowania. Nie blanszuj."]
                    )
                ],
                footer: "Gdy wszystko będzie gotowe, uruchom Start i dalej prowadź rosół już bez pośpiechu.",
                footerLabel: "Pamiętaj"
            )

        case .heatUp:
            return PhaseSheetModel(
                eyebrow: "Kluczowy moment",
                intro: "Celem jest osiągnięcie temperatury pracy bez wrzenia. Najwięcej problemów z klarownością powstaje właśnie w tej fazie.",
                sections: [
                    PhaseSheetSection(
                        title: "Co dzieje się w garnku",
                        systemImage: "drop",
                        text: "Wraz ze wzrostem temperatury białka ścinają się i wypływają jako piana. Wrzenie rozbija pianę na drobne cząstki i miesza je w płynie, przez co rosół łatwo mętnieje."
                    ),
                    PhaseSheetSection(
                        title: "Jak ma wyglądać dobra praca",
                        systemImage: "thermometer.medium",
                        text: content.hasThermometer ? "Dąż do zakresu 88–90°C i utrzymaj go stabilnie." : "Szukaj spokojnej powierzchni, pojedynczych bąbli przy brzegu i braku intensywnego bulgotania na środku.",
                        bullets: ["Szumowiny zbieraj tylko wtedy, gdy same wypływają.", "Nie mieszaj wywaru.", "Jeśli doszło do wrzenia, zmniejsz ogień albo zdejmij garnek na 60–120 s."]
                    )
                ],
                footer: "W tym etapie liczy się cierpliwość — spokojna praca jest ważniejsza niż szybkie dojście do temperatury.",
                footerLabel: "Cierpliwość"
            )

        case .stabilization:
            return PhaseSheetModel(
                eyebrow: "60 minut bez warzyw",
                intro: "Przez 60 minut gotujesz wyłącznie mięso. To etap budowania czystej bazy.",
                sections: [
                    PhaseSheetSection(
                        title: "Co dzieje się w garnku",
                        systemImage: "drop",
                        text: "Aromaty rozpuszczalne w wodzie przechodzą do wywaru, elementy łącznotkankowe stopniowo oddają kolagen, a osad ma czas opaść na dno, jeśli nie mieszasz."
                    ),
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "To najbardziej techniczny moment budowania bazy.",
                        bullets: ["88–90°C, bez wrzenia.", "Brak mieszania.", "Zbieraj tylko to, co samo wypływa.", "Warzywa zostają poza garnkiem do końca stabilizacji."]
                    ),
                    PhaseSheetSection(
                        title: "Dlaczego bez warzyw",
                        systemImage: "questionmark.circle",
                        text: "Warzywa oddają aromat szybko. Dodane zbyt wcześnie mogą zdominować profil i podnieść słodycz."
                    )
                ],
                footer: "Dopiero po pełnej stabilizacji dodajesz warzywa, cebulę i przyprawy.",
                footerLabel: "Nie spiesz się"
            )

        case .addVegetables:
            return PhaseSheetModel(
                eyebrow: "Zmiana w garnku",
                intro: "Po stabilizacji dodaj warzywa, opaloną cebulę i przyprawy zgodnie z kalkulatorem.",
                sections: [
                    PhaseSheetSection(
                        title: "Po dodaniu składników",
                        systemImage: "arrow.right.circle",
                        text: "Temperatura zwykle spada o 1–3°C. Ustaw moc tak, aby wrócić do spokojnej pracy i nie przestrzelić w stronę wrzenia."
                    ),
                    PhaseSheetSection(
                        title: "Na co uważać",
                        systemImage: "exclamationmark.triangle",
                        text: "Tu łatwo zepsuć balans przez zbyt mocny ogień albo za ciężką rękę do przypraw.",
                        bullets: ["Cebula opalana wnosi kolor i aromat, ale nie powinna być spalona na popiół.", "Przyprawy mają być tłem. Nadmiar pieprzu albo ziela łatwo dominuje smak."]
                    )
                ],
                footer: "Po dodaniu wszystkiego wróć do spokojnej pracy wywaru i nie mieszaj garnka.",
                footerLabel: "Po dodaniu"
            )

        case .simmerToPoultryOut:
            return PhaseSheetModel(
                eyebrow: "Klarowność zależy od temperatury",
                intro: "W tym etapie klarowność zależy głównie od temperatury i braku mieszania.",
                sections: [
                    PhaseSheetSection(
                        title: "Co dzieje się w garnku",
                        systemImage: "drop",
                        text: "Warzywa oddają aromaty i cukry, a tłuszcz unosi się jako oczka. Wrzenie sprzyja emulsji tłuszczu i rozbiciu białek, co daje cięższe odczucie i gorszą klarowność."
                    ),
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "Prowadź rosół spokojnie aż do momentu wyjęcia drobiu.",
                        bullets: ["88–90°C.", "Nie mieszaj.", "Nie dopuszczaj do bulgotania."]
                    )
                ],
                footer: "Przygotuj naczynie na drób, ale nie wykonuj żadnych gwałtownych ruchów w garnku.",
                footerLabel: "Przed wyjęciem"
            )

        case .removePoultry:
            return PhaseSheetModel(
                eyebrow: "Drób wychodzi pierwszy",
                intro: "Drób wyjmuje się wcześniej niż wołowinę. Zbyt długie gotowanie może wnieść przegotowaną nutę i podnieść tłustość.",
                sections: [
                    PhaseSheetSection(
                        title: "Jak wyjmować",
                        systemImage: "hand.raised",
                        text: "Rób to spokojnie, najlepiej przy brzegu garnka.",
                        bullets: ["Użyj szczypiec albo łyżki cedzakowej.", "Ruszaj składnikami możliwie delikatnie.", "Nie wyciskaj drobiu nad wywarem."]
                    ),
                    PhaseSheetSection(
                        title: "Dlaczego to ważne",
                        systemImage: "questionmark.circle",
                        text: "Wyciskanie wprowadza drobiny białek i tłuszczu do płynu, przez co klarowność spada."
                    )
                ],
                footer: "Po wyjęciu drobiu wywar dalej pracuje spokojnie — bez mieszania i bez wrzenia.",
                footerLabel: "Po wyjęciu"
            )

        case .simmerToVegetablesOut:
            return PhaseSheetModel(
                eyebrow: "Nie przeciągaj",
                intro: "To etap, w którym łatwo przesadzić z warzywami.",
                sections: [
                    PhaseSheetSection(
                        title: "Co się stanie, jeśli potrwa za długo",
                        systemImage: "exclamationmark.triangle",
                        text: "Rośnie słodycz, szczególnie od marchwi, aromat robi się bardziej płaski, a profil przesuwa się w stronę cięższej zupy."
                    ),
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "Domknij pracę warzyw, ale nie przeciągaj tego etapu.",
                        bullets: ["88–90°C.", "Nie mieszaj.", "Nie dopuszczaj do wrzenia."]
                    )
                ],
                footer: "Gdy etap się skończy, wyjmij warzywa delikatnie i bez wyciskania.",
                footerLabel: "Przed wyjęciem"
            )

        case .removeVegetables:
            return PhaseSheetModel(
                eyebrow: "Delikatnie i bez wyciskania",
                intro: "Wyjmij warzywa delikatnie i bez wyciskania. W rosole priorytetem jest czysty płyn.",
                sections: [
                    PhaseSheetSection(
                        title: "Jak to zrobić",
                        systemImage: "hand.raised",
                        text: "Pracuj spokojnie przy brzegu garnka i nie wyciskaj warzyw nad wywarem."
                    ),
                    PhaseSheetSection(
                        title: "Dlaczego to ważne",
                        systemImage: "questionmark.circle",
                        text: "Wyciskanie zwiększa mętność i wnosi dodatkową słodycz oraz drobiny."
                    )
                ],
                footer: "Po tym etapie zostaje już sama baza mięsna i końcowe domknięcie smaku.",
                footerLabel: "Po wyjęciu"
            )

        case .finishBase:
            return PhaseSheetModel(
                eyebrow: "Ostatnie wyrównanie smaku",
                intro: "To etap wyrównania smaku na samej bazie mięsnej.",
                sections: [
                    PhaseSheetSection(
                        title: "Co dzieje się w garnku",
                        systemImage: "drop",
                        text: "Aromat stabilizuje się, a drobne cząstki mają czas opaść. Trzymaj spokojną temperaturę do końca etapu."
                    ),
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "To ostatni spokojny finisz samej bazy.",
                        bullets: ["88–90°C.", "Bez wrzenia.", "Bez mieszania."]
                    )
                ],
                footer: "Nie przyspieszaj końcówki. W tym etapie liczy się równa praca i czysty smak.",
                footerLabel: "Nie przyspieszaj"
            )

        case .addLiver:
            return PhaseSheetModel(
                eyebrow: "Tylko na końcu",
                intro: "Wątróbkę dodaje się tylko na końcu.",
                sections: [
                    PhaseSheetSection(
                        title: "Dlaczego tak późno",
                        systemImage: "questionmark.circle",
                        text: "Długo gotowana wątróbka może dać metaliczny posmak i pogorszyć klarowność."
                    ),
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "To tylko krótki krok przed finałem.",
                        bullets: ["Dodaj na końcu.", "Prowadź dalej w 88–90°C.", "Nie dopuszczaj do wrzenia."]
                    )
                ],
                footer: "Po dodaniu przejdź od razu do krótkiego etapu końcowego z wątróbką.",
                footerLabel: "Zaraz po tym"
            )

        case .finishWithLiver:
            return PhaseSheetModel(
                eyebrow: "Finał aktywnego gotowania",
                intro: "To krótki etap końcowy. Zbyt wysoka temperatura pogarsza klarowność.",
                sections: [
                    PhaseSheetSection(
                        title: "Zasady etapu",
                        systemImage: "checkmark.shield",
                        text: "Utrzymaj pełną kontrolę do samego końca.",
                        bullets: ["88–90°C.", "Bez wrzenia.", "Po czasie wyłącz grzanie."]
                    )
                ],
                footer: "Nie przeciągaj tego etapu. Tutaj kończy się aktywne gotowanie.",
                footerLabel: "Koniec gotowania"
            )

        case .beginRest:
            return PhaseSheetModel(
                eyebrow: "Garnek stoi, nie ruszaj",
                intro: "Po zakończeniu gotowania aktywnego nie wykonuj żadnych ruchów w garnku.",
                sections: [
                    PhaseSheetSection(
                        title: "Co dzieje się w tym etapie",
                        systemImage: "drop",
                        text: "Osad i drobne cząstki opadają na dno. Poruszenie garnka podrywa osad i pogarsza klarowność."
                    )
                ],
                footer: "Wyłącz grzanie, odstaw garnek i pozwól mu spokojnie się wyciszyć.",
                footerLabel: "Wyłącz grzanie"
            )

        case .rest:
            return PhaseSheetModel(
                eyebrow: "Czas na klarowność",
                intro: "Odstawienie na 15–20 minut poprawia klarowność i ułatwia czyste cedzenie.",
                sections: [
                    PhaseSheetSection(
                        title: "Dlaczego warto poczekać",
                        systemImage: "questionmark.circle",
                        text: "W tym czasie drobiny stabilizują się i opadają na dno, więc później łatwiej oddzielić czysty płyn od osadu."
                    )
                ],
                footer: "Nie mieszaj i nie przenoś garnka bez potrzeby. Cierpliwość daje lepszy efekt niż pośpiech.",
                footerLabel: "Bez mieszania"
            )

        case .strainAndSeason:
            return PhaseSheetModel(
                eyebrow: "Najpierw cedzenie, potem sól",
                intro: "Zasada główna: najpierw cedzenie, dopiero potem doprawianie.",
                sections: [
                    PhaseSheetSection(
                        title: content.clarityMode == .paperFilter ? "Cedzenie i filtracja" : "Cedzenie",
                        systemImage: "line.3.horizontal.decrease.circle",
                        text: content.clarityMode == .paperFilter ? "Najpierw przecedź wywar wstępnie, potem przefiltruj go papierem. Filtr usuwa część tłuszczu i drobin, więc uzysk bywa mniejszy, a smak delikatniejszy." : "Przelewaj powoli przez sito lub gazę i nie wyciskaj składników. Nie przelewaj do końca — ostatnie 200–300 ml z dna zawiera zwykle najwięcej osadu."
                    ),
                    PhaseSheetSection(
                        title: "Doprawianie",
                        systemImage: "fork.knife",
                        text: "Sól dodawaj dopiero po cedzeniu i rób to stopniowo."
                    )
                ],
                footer: "Po cedzeniu pracuj spokojnie. To ostatni moment, w którym łatwo zepsuć klarowność pośpiechem.",
                footerLabel: "Ostatni krok"
            )
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(model.eyebrow)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textTertiary)
                        .padding(.bottom, 6)

                    Text(content.title)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(AppTheme.textPrimary)
                        .padding(.bottom, 14)

                    Text(model.intro)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 20)

                    if !model.sections.isEmpty {
                        AppCard(background: AppTheme.surface, border: AppTheme.border) {
                            SheetGroupedSectionsPanel(sections: model.sections)
                        }
                        .padding(.bottom, 4)
                    }

                    if let footer = model.footer {
                        SheetSupportStrip(
                            title: model.footerLabel,
                            systemImage: "info.circle",
                            text: footer
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.screen)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            .background(AppTheme.background)
        }
    }
}

private struct LiveControlsBackdrop: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.clear,
                AppTheme.background.opacity(0.02),
                AppTheme.background.opacity(0.06),
                AppTheme.background.opacity(0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 220)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
    }
}

private enum SheetIconTone {
    case neutral
    case positive
    case warning
}

private struct SheetHeroCard: View {
    let eyebrow: String
    let emphasis: String?
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(AppTheme.accent)
                    .frame(width: 10, height: 10)

                Text(eyebrow)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            if let emphasis, !emphasis.isEmpty {
                Text(emphasis)
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(text)
                .font(.system(size: emphasis == nil ? 17 : 15.5, weight: emphasis == nil ? .semibold : .medium))
                .foregroundStyle(emphasis == nil ? AppTheme.textPrimary : AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SheetGroupedSectionsPanel: View {
    let sections: [PhaseSheetSection]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                if index > 0 {
                    Divider()
                        .overlay(AppTheme.border)
                }
                SheetGroupedSectionRow(
                    title: section.title,
                    systemImage: section.systemImage,
                    text: section.text,
                    bullets: section.bullets
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SheetGroupedSectionRow: View {
    let title: String
    let systemImage: String
    let text: String
    let bullets: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                SheetSectionIconBadge(systemImage: systemImage)

                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            Text(text)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !bullets.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Circle()
                                .fill(AppTheme.textTertiary)
                                .frame(width: 4, height: 4)
                                .padding(.top, 7)

                            Text(bullet)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}

private struct SheetSupportStrip: View {
    let title: String
    let systemImage: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .overlay(AppTheme.border)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.textTertiary)

                Text(text)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SheetSectionIconBadge: View {
    let systemImage: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(AppTheme.surfaceSoft)
                .frame(width: 32, height: 32)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
                .frame(width: 32, height: 32)

            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

private struct SheetTinyIcon: View {
    let systemImage: String

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppTheme.textPrimary)
            .frame(width: 18, height: 18)
    }
}

private struct SheetInlineMarker: View {
    let systemImage: String
    let tone: SheetIconTone

    private var strokeColor: Color {
        switch tone {
        case .neutral:
            return AppTheme.borderStrong
        case .positive:
            return Color(red: 0.63, green: 0.86, blue: 0.69)
        case .warning:
            return Color(red: 0.95, green: 0.75, blue: 0.46)
        }
    }

    private var fillColor: Color {
        switch tone {
        case .neutral:
            return AppTheme.surface
        case .positive:
            return Color(red: 0.92, green: 0.98, blue: 0.94)
        case .warning:
            return Color(red: 1.0, green: 0.96, blue: 0.90)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(fillColor)
                .frame(width: 56, height: 56)

            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(strokeColor, lineWidth: 1)
                .frame(width: 56, height: 56)

            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.textPrimary)
        }
    }
}

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

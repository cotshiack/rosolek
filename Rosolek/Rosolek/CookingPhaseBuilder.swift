import Foundation
import os

struct CookingPhaseBuilder {
    let batch: BatchRecord
    let result: BrothCalculationResult
    let hasThermometer: Bool

    // MARK: - Ingredient context

    private var ingredientSnapshots: [BatchIngredientSnapshot] {
        batch.selectedIngredientsSnapshot ?? []
    }

    private var ingredientIDs: [String] {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.map(\.ingredientID)
        }
        return batch.selectedIngredientIDs ?? []
    }

    var hasPoultry: Bool {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.contains {
                normalizeCookingID($0.categoryRawValue) == normalizeCookingID(IngredientCategory.poultry.rawValue)
            }
        }
        // Legacy path: substring detection on raw IDs, used when selectedIngredientsSnapshot is nil.
        // New batches always provide a snapshot; this path exists only for pre-snapshot history records.
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

    var hasLiver: Bool {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.contains {
                normalizeCookingID($0.ingredientID).contains("watrob")
            }
        }
        return ingredientIDs.contains { normalizeCookingID($0).contains("watrob") }
    }

    var hasBeef: Bool {
        if !ingredientSnapshots.isEmpty {
            return ingredientSnapshots.contains { snap in
                // IngredientCategory.beef.rawValue = "Wołowina" — ł is not a Unicode diacritic,
                // so folding(diacriticInsensitive) leaves it intact; compare via enum to be safe.
                if IngredientCategory(rawValue: snap.categoryRawValue) == .beef { return true }
                let cat = normalizeCookingID(snap.categoryRawValue)
                let name = snap.ingredientName.lowercased()
                return cat == "wolowina" || cat == "beef"
                    || snap.ingredientID.lowercased().hasPrefix("beef_")
                    || name.contains("wołowin") || name.contains("wolowin")
            }
        }
        return ingredientIDs.contains { id in
            let n = normalizeCookingID(id)
            return n.contains("prega") || n.contains("szponder") || n.contains("ogon")
                || n.contains("wolowy") || n.contains("szpik") || n.contains("mostek")
                || n.contains("golen") || n.hasPrefix("beef_")
        }
    }

    // MARK: - Batch context

    var activeUltraVariant: UltraSpecVariantID? {
        if let presetVariant = activePreset?.ultraVariant { return presetVariant }
        guard batch.modeRawValue == "custom" else { return nil }
        if let rawKind = batch.brothKindRawValue,
           let kind = BrothKind(rawValue: rawKind) {
            let styleName = batch.selectedStyleName ?? batch.styleRawValue
            let styleKey = UltraSpecStyleKeyResolver.resolve(kind: kind, styleName: styleName)
            return UltraSpecVariantResolver.resolve(kind: kind, styleKey: styleKey)
        }
        let legacyStyle = batch.styleRawValue.lowercased()
        if legacyStyle.contains("ramen_tonkotsu") || legacyStyle.contains("tonkotsu") {
            return .ramenTonkotsu
        }
        if legacyStyle.contains("ramen") || legacyStyle.contains("shio") {
            return .ramenShio
        }
        return nil
    }

    var activePreset: BrothPreset? {
        guard batch.modeRawValue == "preset",
              let raw = batch.presetRawValue else { return nil }
        return BrothPreset(rawValue: raw)
    }

    var isGrandmaPreset: Bool { activePreset == .grandmaReady }
    var isCollagenPoultryPreset: Bool { activePreset == .collagenPoultryReady }
    var brothProfile: BrothProfile { batch.brothProfile }
    var clarityMode: BrothClarityMode { batch.clarityMode }
    var batchUsesVinegar: Bool { result.appleCiderVinegarMl > 0 }

    // MARK: - Timing

    var poultrySimmerSeconds: Int {
        if isCollagenPoultryPreset { return hasPoultry ? 120 * 60 : 0 }
        if !hasPoultry { return 0 }
        // spec: Lekki simmer z drobiem = 135 min, Bogaty = 165 min
        return brothProfile == .cleaner ? 135 * 60 : 165 * 60
    }

    var vegetablesTotalSeconds: Int {
        if isCollagenPoultryPreset { return 120 * 60 }
        // spec: Lekki = 135 + 20 = 155 min, Bogaty = 165 + 30 = 195 min
        return brothProfile == .cleaner ? 155 * 60 : 195 * 60
    }

    var finishTotalSeconds: Int {
        if isCollagenPoultryPreset { return 90 * 60 }
        return brothProfile == .cleaner ? 35 * 60 : 75 * 60
    }

    var simmerAfterPoultrySeconds: Int {
        hasPoultry ? max(0, vegetablesTotalSeconds - poultrySimmerSeconds) : vegetablesTotalSeconds
    }

    var liverFinishSeconds: Int {
        hasLiver ? min(25 * 60, finishTotalSeconds) : 0
    }

    var baseFinishBeforeLiverSeconds: Int {
        hasLiver ? max(0, finishTotalSeconds - liverFinishSeconds) : finishTotalSeconds
    }

    // MARK: - Reminder rows

    var vegetableReminderRows: [LiveIngredientReminderRowData] {
        result.vegetables.compactMap { item in
            let grams = item.amount.extractGrams()
            if grams <= 0 { return nil }
            return LiveIngredientReminderRowData(
                icon: ingredientIconKind(for: item.name),
                title: item.name,
                subtitle: vegetableSubtitle(for: item),
                value: item.amount
            )
        }
    }

    var spiceReminderRows: [LiveIngredientReminderRowData] {
        var rows: [LiveIngredientReminderRowData] = []

        if !isGrandmaPreset, result.startSaltGrams > 0 {
            rows.append(LiveIngredientReminderRowData(
                icon: .salt,
                title: "Sól",
                subtitle: "Dodaj porcję startową na tym etapie.",
                value: "\(numberString(result.startSaltGrams)) g"
            ))
        }

        if result.peppercornCount > 0 {
            rows.append(LiveIngredientReminderRowData(
                icon: .pepper,
                title: "Pieprz czarny ziarnisty",
                subtitle: "Czysty aromat.",
                value: "\(result.peppercornCount) \(result.peppercornCount == 1 ? "ziarno" : "ziaren")"
            ))
        }
        if result.allspiceCount > 0 {
            rows.append(LiveIngredientReminderRowData(
                icon: .allspice,
                title: "Ziele angielskie",
                subtitle: "Głębia smaku.",
                value: "\(result.allspiceCount) \(result.allspiceCount == 1 ? "ziarno" : "ziaren")"
            ))
        }
        if result.bayLeafCount > 0 {
            rows.append(LiveIngredientReminderRowData(
                icon: .bayLeaf,
                title: "Liść laurowy",
                subtitle: "Tło aromatu.",
                value: result.bayLeafCount == 1 ? "1 liść" : "\(result.bayLeafCount) liście"
            ))
        }

        return rows
    }

    // MARK: - Phase building

    func buildPhases() -> [LivePhase] {
        if activeUltraVariant != nil { return buildUltraSpecPhases() }
        if isGrandmaPreset { return buildGrandmaPhases() }
        if isCollagenPoultryPreset { return buildCollagenPhases() }
        return buildStandardPhases()
    }

    // MARK: - Private helpers

    private func numberString(_ value: Double) -> String {
        if value == floor(value) { return String(Int(value)) }
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

    func livePhaseKind(forUltraStepID stepID: String) -> LivePhaseKind {
        switch stepID {
        case "prep":                return .prep
        case "heat_up_clear":       return .heatUp
        case "strain_season":       return .strainAndSeason
        case "add_veg_spices", "tonkotsu_aromatics_end": return .addVegetables
        case "simmer_clear":        return .simmerToVegetablesOut
        case "stabilize_base", "tonkotsu_boil_emulsify", "veg_simmer_limit", "fish_poach_limit":
                                    return .stabilization
        case "finish_clear", "rest_settle": return .rest
        case "remove_poultry":      return .removePoultry
        case "remove_veg":          return .removeVegetables
        default:
            os_log(.error, "CookingPhaseBuilder: unhandled ultra timeline stepID: %{public}@ — fallback .stabilization", stepID)
            return .stabilization
        }
    }

    // MARK: - Bogaty step selection
    //
    // Path A  hasBeef + hasPoultry   → full Bogaty (drobiowo-wołowy) timeline
    // Path B  hasBeef + !hasPoultry  → Bogaty without remove_poultry / closing simmer
    // Path C  !hasBeef               → Lekki (poultry-only) schedule

    private func stepsForBogaty() -> [UltraSpecTimelineStep] {
        UltraSpecTimelineCatalog.steps(for: .rosolBogaty, hasBeef: hasBeef, hasPoultry: hasPoultry)
    }

    // MARK: - Ultra spec phases

    private func buildUltraSpecPhases() -> [LivePhase] {
        guard let variant = activeUltraVariant else { return [] }

        let steps = (variant == .rosolBogaty)
            ? stepsForBogaty()
            : UltraSpecTimelineCatalog.steps(for: variant)

        guard !steps.isEmpty else { return [] }

        let beefOnlyBogaty = (variant == .rosolBogaty && hasBeef && !hasPoultry)
        let fullBogaty     = (variant == .rosolBogaty && hasBeef && hasPoultry)

        return steps.enumerated().map { index, step in
            let durationSeconds: Int? = {
                if index == 0 || step.isManual { return nil }
                let previousOffset = steps[index - 1].minuteOffset
                return max(0, (step.minuteOffset - previousOffset) * 60)
            }()

            var subtitle = step.subtitle
            if fullBogaty {
                switch step.stepID {
                case "simmer_clear" where step.minuteOffset == 225:
                    subtitle = "Drób i wołowina gotują się razem. Bez mieszania, bez wrzenia."
                case "simmer_clear" where step.minuteOffset == 255:
                    subtitle = "Wołowina dochodzi po wyjęciu drobiu."
                case "finish_clear":
                    subtitle = "Wołowina kończy gotowanie. Wyrównaj smak, bez wrzenia."
                default: break
                }
            } else if beefOnlyBogaty {
                switch step.stepID {
                case "stabilize_base":
                    subtitle = "Wołowina od zimnej wody. Zbieraj tylko to, co samo wypływa."
                case "simmer_clear":
                    subtitle = "Wołowina gotuje się spokojnie. Bez mieszania, bez wrzenia."
                case "finish_clear":
                    subtitle = "Wołowina kończy gotowanie. Wyrównaj smak, bez wrzenia."
                default: break
                }
            }

            return LivePhase(
                kind: livePhaseKind(forUltraStepID: step.stepID),
                title: step.title,
                shortText: subtitle,
                detailText: UltraSpecStepLibrary.all[step.stepID]?.extendedHint ?? step.subtitle,
                durationSeconds: durationSeconds,
                timelineLabel: step.timeLabel,
                bottomActionTitle: durationSeconds == nil ? "Dalej" : nil
            ).withStepID(step.stepID)
        }
    }

    // MARK: - Grandma phases

    private func buildGrandmaPhases() -> [LivePhase] {
        [
            LivePhase(kind: .prep,
                title: "Start od zimnej wody",
                shortText: "Włóż mięso, zalej zimną wodą i grzej prawie do wrzenia.",
                detailText: "Zbieraj szumowiny tylko z powierzchni i nie mieszaj wywaru.",
                durationSeconds: nil, timelineLabel: "Start", bottomActionTitle: nil),
            LivePhase(kind: .heatUp,
                title: "Zmniejsz ogień",
                shortText: "Gdy wywar zaczyna pracować, ustaw minimalny ogień.",
                detailText: "Rosół ma lekko pyrkać przy brzegu, nie bulgotać.",
                durationSeconds: nil, timelineLabel: "Uspokój", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .stabilization,
                title: "Gotuj samą bazę mięsną",
                shortText: "Utrzymuj spokojną pracę przez 30 minut.",
                detailText: "To etap budowania mięsnej bazy przed dodaniem warzyw.",
                durationSeconds: 30 * 60, timelineLabel: "30 min", bottomActionTitle: nil),
            LivePhase(kind: .addVegetables,
                title: "Dodaj warzywa i przyprawy",
                shortText: "Dodaj warzywa, cebulę opalaną i przyprawy (bez soli).",
                detailText: "Po dodaniu wróć do spokojnego pyrkania i kontynuuj 60–75 minut.",
                durationSeconds: nil, timelineLabel: "Dodaj", bottomActionTitle: "Dodałem"),
            LivePhase(kind: .simmerToVegetablesOut,
                title: "Prowadź rosół dalej",
                shortText: "Gotuj spokojnie przez 60–75 minut po dodaniu warzyw.",
                detailText: "Nie mieszaj i nie dopuszczaj do wrzenia.",
                durationSeconds: 70 * 60, timelineLabel: "70 min", bottomActionTitle: nil),
            LivePhase(kind: .beginRest,
                title: "Wyłącz i odstaw",
                shortText: "Wyłącz ogień i odstaw rosół na 10 minut.",
                detailText: "Dzięki temu osad opadnie i łatwiej przecedzisz klarowny płyn.",
                durationSeconds: nil, timelineLabel: "Wyłącz", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .rest,
                title: "Odstawienie",
                shortText: "Pozwól wywarowi odstać przez 10 minut bez poruszania garnka.",
                detailText: "Nie mieszaj i nie przenoś garnka bez potrzeby.",
                durationSeconds: 10 * 60, timelineLabel: "10 min", bottomActionTitle: nil),
            LivePhase(kind: .strainAndSeason,
                title: "Cedzenie i doprawianie",
                shortText: "Przecedź rosół i dopraw sól dopiero po cedzeniu.",
                detailText: "Przelewaj powoli przez sito i nie wyciskaj składników.",
                durationSeconds: nil, timelineLabel: "Cedzenie", bottomActionTitle: "Dalej"),
            LivePhase(kind: .optionalClarityTip,
                title: "Opcjonalnie: klarowniejszy finisz",
                shortText: "Zostaw w garnku ostatnie 200–300 ml z osadem.",
                detailText: "To prosty sposób na klarowniejszy efekt bez dodatkowych działań.",
                durationSeconds: nil, timelineLabel: "Opcjonalnie", bottomActionTitle: "Zakończ")
        ]
    }

    // MARK: - Collagen phases

    private func buildCollagenPhases() -> [LivePhase] {
        var items: [LivePhase] = [
            LivePhase(kind: .prep,
                title: "Przygotuj garnek i składniki",
                shortText: "Przygotuj bazę kolagenową, wodę i garnek.",
                detailText: "Na tym etapie przygotuj bazę kolagenową, wodę i garnek. Zegar uruchamiasz dopiero wtedy, gdy wszystko jest już gotowe.",
                durationSeconds: nil, timelineLabel: "Przygotuj", bottomActionTitle: nil),
            LivePhase(kind: .heatUp,
                title: "Podgrzewaj do spokojnej pracy",
                shortText: hasThermometer
                    ? "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero po stabilnym wejściu w zakres 88–90°C."
                    : "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero gdy wywar pracuje spokojnie, bez wrzenia.",
                detailText: hasThermometer
                    ? "To etap spokojnego dochodzenia wywaru do temperatury 88–90°C. Szumowiny pojawiają się głównie podczas przejścia od zimnej wody do ~90°C."
                    : "Szukaj lekkiego drżenia powierzchni i pojedynczych bąbli przy brzegu. Nie dopuszczaj do pełnego wrzenia.",
                durationSeconds: nil, timelineLabel: "Podgrzewaj", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .stabilization,
                title: "Gotuj samą bazę kolagenową",
                shortText: "Przez 75 minut gotuj samą bazę kolagenową spokojnie. Warzywa dodasz w następnym kroku.",
                detailText: "To najważniejszy etap budowania bazy kolagenowej. Nie mieszaj wywaru. Zbieraj tylko to, co samo wypływa na powierzchnię.",
                durationSeconds: 75 * 60,
                timelineLabel: "75 min",
                bottomActionTitle: nil),
            LivePhase(kind: .addVegetables,
                title: "Dodaj warzywa i przyprawy",
                shortText: "Dodaj teraz wszystkie warzywa i przyprawy wyliczone dla tego wywaru.",
                detailText: "Po zakończeniu stabilizacji dodajesz warzywa, opaloną cebulę oraz przyprawy. Temperatura może na chwilę spaść o 1–3°C. To normalne.",
                durationSeconds: nil, timelineLabel: "Dodaj", bottomActionTitle: "Dodałem"),
            LivePhase(kind: .simmerToVegetablesOut,
                title: "Gotuj wywar z warzywami",
                shortText: "Baza kolagenowa i warzywa gotują się razem. Warzywa wyjdzą po tym etapie.",
                detailText: "Wywar pracuje spokojnie na bazie kolagenowej i warzywach. Nie mieszaj i nie dopuszczaj do wrzenia. Po 120 minutach warzywa wychodzą — baza zostaje.",
                durationSeconds: 120 * 60, timelineLabel: "120 min", bottomActionTitle: nil),
            LivePhase(kind: .removeVegetables,
                title: "Wyciągnij warzywa",
                shortText: "Wyjmij warzywa — baza kolagenowa zostaje w garnku i gotuje się dalej.",
                detailText: "Wyciągnij warzywa bez wyciskania i bez mieszania. Po tym etapie baza kolagenowa dochodzi spokojnie do końca bez warzyw.",
                durationSeconds: nil, timelineLabel: "Wyjmij warzywa", bottomActionTitle: "Wyjąłem"),
            LivePhase(kind: .finishBase,
                title: "Dokończ bazę kolagenową",
                shortText: "Ostatni etap — baza kolagenowa wykańcza się spokojnie bez warzyw.",
                detailText: "Wywar gotuje się na samej bazie kolagenowej. Utrzymuj spokojną temperaturę — bez wrzenia, bez mieszania.",
                durationSeconds: 90 * 60, timelineLabel: "90 min", bottomActionTitle: nil)
        ]

        items.append(contentsOf: [
            LivePhase(kind: .beginRest,
                title: "Wyłącz i odstaw",
                shortText: "Gotowanie skończone. Odstaw garnek i nie ruszaj wywaru.",
                detailText: "Po wyłączeniu ognia osady powinny spokojnie opaść. Nie mieszaj i nie potrząsaj garnkiem.",
                durationSeconds: nil, timelineLabel: "Wyłącz", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .rest,
                title: "Pozwól wywarowi odstać",
                shortText: "Odstawienie przez około 20 minut poprawia klarowność.",
                detailText: "Osad powoli opada na dno. Nie ruszaj garnka — po 20 minutach przecedzenie będzie znacznie łatwiejsze.",
                durationSeconds: 20 * 60, timelineLabel: "20 min", bottomActionTitle: nil),
            LivePhase(kind: .strainAndSeason,
                title: clarityMode == .paperFilter ? "Przefiltruj, przecedź i dopraw" : "Przecedź i dopraw",
                shortText: clarityMode == .paperFilter
                    ? "Najpierw przefiltruj wywar, a dopiero potem skoryguj sól."
                    : "Przecedź wywar i dopiero potem skoryguj sól.",
                detailText: clarityMode == .paperFilter
                    ? "Najpierw przecedź wywar wstępnie, a potem dokładnie przefiltruj przez filtr papierowy. Dopiero po tym spróbuj i skoryguj sól."
                    : "Przecedź wywar bez wyciskania składników. Dopiero po przecedzeniu sprawdź smak i skoryguj sól.",
                durationSeconds: nil, timelineLabel: "Cedzenie", bottomActionTitle: "Zakończ")
        ])

        return items
    }

    // MARK: - Standard phases

    private func buildStandardPhases() -> [LivePhase] {
        var items: [LivePhase] = [
            LivePhase(kind: .prep,
                title: "Przygotuj garnek i składniki",
                shortText: batchUsesVinegar
                    ? "Przygotuj mięso, wodę, garnek, termometr i odmierzoną porcję octu."
                    : "Przygotuj mięso, wodę, garnek i termometr.",
                detailText: batchUsesVinegar
                    ? "Na tym etapie przygotuj mięso, wodę, garnek, termometr oraz odmierzoną porcję octu jabłkowego. Zegar uruchamiasz dopiero wtedy, gdy wszystko jest już gotowe."
                    : "Na tym etapie przygotuj mięso, wodę, garnek i termometr. Zegar uruchamiasz dopiero wtedy, gdy wszystko jest już gotowe.",
                durationSeconds: nil, timelineLabel: "Przygotuj", bottomActionTitle: nil),
            LivePhase(kind: .heatUp,
                title: "Podgrzewaj do spokojnej pracy",
                shortText: hasThermometer
                    ? "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero po stabilnym wejściu w zakres 88–90°C."
                    : "Grzej powoli, zbieraj szumowiny i przejdź dalej dopiero wtedy, gdy wywar pracuje spokojnie, bez wrzenia.",
                detailText: hasThermometer
                    ? "To etap spokojnego dochodzenia wywaru do temperatury 88–90°C. Najwięcej szumowin zwykle pojawia się właśnie wtedy, gdy wywar przechodzi od zimnej wody do około 75–90°C."
                    : "To etap spokojnego dochodzenia wywaru do delikatnej pracy. Szukaj lekkiego drżenia powierzchni i pojedynczych bąbli przy brzegu. Nie dopuszczaj do pełnego wrzenia.",
                durationSeconds: nil, timelineLabel: "Podgrzewaj", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .stabilization,
                title: "Gotuj samą bazę mięsną",
                shortText: "Przez 60 minut gotuj samo mięso spokojnie. Warzywa dodasz w następnym kroku.",
                detailText: "To najważniejszy etap budowania czystej bazy mięsnej. Nie mieszaj wywaru. Zbieraj tylko to, co samo wypływa na powierzchnię.",
                durationSeconds: 60 * 60,
                timelineLabel: "1 h",
                bottomActionTitle: nil),
            LivePhase(kind: .addVegetables,
                title: "Dodaj warzywa i przyprawy",
                shortText: "Dodaj teraz wszystkie warzywa i przyprawy wyliczone dla tego wywaru.",
                detailText: "Po zakończeniu stabilizacji dodajesz warzywa, opaloną cebulę oraz przyprawy. Temperatura może na chwilę spaść o 1–3°C. To normalne.",
                durationSeconds: nil, timelineLabel: "Dodaj", bottomActionTitle: "Dodałem")
        ]

        if hasPoultry {
            items.append(LivePhase(kind: .simmerToPoultryOut,
                title: "Gotuj wywar z warzywami",
                shortText: hasBeef
                    ? "Drób i wołowina gotują się razem — utrzymuj spokojną temperaturę. Przygotuj naczynie na wyjęty drób."
                    : "Utrzymuj spokojną temperaturę i przygotuj naczynie na wyjęty drób.",
                detailText: hasBeef
                    ? "Wywar pracuje na drobiu i wołowinie jednocześnie. Nie mieszaj i nie dopuszczaj do wrzenia. Drób wyjdzie w następnym kroku — wołowina zostaje."
                    : "Od tej chwili wywar ma pracować spokojnie. Nie mieszaj go i nie dopuszczaj do wrzenia.",
                durationSeconds: poultrySimmerSeconds, timelineLabel: "Gotuj", bottomActionTitle: nil))
            items.append(LivePhase(kind: .removePoultry,
                title: "Wyjmij drób",
                shortText: hasBeef
                    ? "Drób wyjmuje się wcześniej niż wołowinę. Zbyt długie gotowanie może wnieść przegotowaną nutę i podnieść tłustość."
                    : "Wyjmij teraz drób delikatnie, bez wzburzania garnka.",
                detailText: "Wyjmij drób szczypcami albo łyżką cedzakową. Nie wyciskaj mięsa nad wywarem i nie wzburzaj garnka bardziej niż to konieczne.",
                durationSeconds: nil, timelineLabel: "Wyjmij drób", bottomActionTitle: "Wyjąłem"))
        }

        items.append(LivePhase(kind: .simmerToVegetablesOut,
            title: hasBeef ? "Gotuj dalej — zostaje wołowina" : "Gotuj dalej bez drobiu",
            shortText: hasBeef
                ? "Drób już wyjęty — wołowina i warzywa gotują się dalej. Pilnuj czasu warzyw."
                : "Warzywa oddają jeszcze smak — ale nie trzymaj ich zbyt długo.",
            detailText: hasBeef
                ? "Wywar pracuje teraz na wołowinie i warzywach. Nie mieszaj i nie dopuszczaj do wrzenia."
                : "Na tym etapie wywar nadal pracuje spokojnie. Zbyt długie trzymanie warzyw daje słodszy, mniej precyzyjny profil.",
            durationSeconds: simmerAfterPoultrySeconds > 0 ? simmerAfterPoultrySeconds : nil,
            timelineLabel: simmerAfterPoultrySeconds > 0 ? "Dalej" : "Wyjmij",
            bottomActionTitle: simmerAfterPoultrySeconds > 0 ? nil : "Gotowe"))

        items.append(LivePhase(kind: .removeVegetables,
            title: "Wyciągnij warzywa",
            shortText: hasBeef
                ? "Wyjmij warzywa — w garnku zostaje wołowina, która potrzebuje jeszcze czasu."
                : "Wyjmij warzywa delikatnie, bez mieszania i wyciskania.",
            detailText: hasBeef
                ? "Wyciągnij warzywa bez wyciskania i bez mieszania. Po tym etapie zostaje wołowina — ona dochodzi powoli do końca."
                : "Wyciągnij warzywa bez wyciskania i bez mieszania. Po tym etapie zostaje już sama baza mięsna.",
            durationSeconds: nil, timelineLabel: "Wyjmij warzywa", bottomActionTitle: "Wyjąłem"))

        if baseFinishBeforeLiverSeconds > 0 && (hasBeef || hasLiver) {
            items.append(LivePhase(kind: .finishBase,
                title: "Dokończ bazę",
                shortText: hasBeef
                    ? "To etap budowania dłuższego finiszu. Nie doprowadzaj do wrzenia."
                    : "Domknij smak na samej bazie, bez wrzenia.",
                detailText: hasBeef
                    ? "Wywar gotuje się na samej wołowinie. To etap wyrównania smaku — utrzymuj spokojną temperaturę, bez wrzenia i bez mieszania."
                    : "To etap wyrównania smaku i uspokojenia wywaru. Utrzymuj temperaturę pracy i nie mieszaj. Drobne cząstki mają czas opaść, a aromat staje się bardziej spójny.",
                durationSeconds: baseFinishBeforeLiverSeconds, timelineLabel: "Finisz", bottomActionTitle: nil))
        }

        if hasLiver {
            items.append(LivePhase(kind: .addLiver,
                title: "Dodaj wątróbkę",
                shortText: "Dodaj ją dopiero teraz. To krótki etap na sam koniec gotowania.",
                detailText: "Wątróbka gotowana zbyt długo daje metaliczny posmak i pogarsza klarowność wywaru. Dlatego dodajesz ją dopiero teraz.",
                durationSeconds: nil, timelineLabel: "Dodaj wątróbkę", bottomActionTitle: "Dodałem"))
            items.append(LivePhase(kind: .finishWithLiver,
                title: "Dokończ wywar z wątróbką",
                shortText: "Utrzymuj spokojną temperaturę i nie dopuszczaj do wrzenia.",
                detailText: "To końcowy, krótki etap z wątróbką. Wywar ma pracować spokojnie do samego końca.",
                durationSeconds: liverFinishSeconds, timelineLabel: "Finisz", bottomActionTitle: nil))
        }

        items.append(contentsOf: [
            LivePhase(kind: .beginRest,
                title: "Wyłącz i odstaw",
                shortText: "Gotowanie skończone. Odstaw garnek i nie ruszaj wywaru.",
                detailText: "Po wyłączeniu ognia osady powinny spokojnie opaść. Nie mieszaj i nie potrząsaj garnkiem.",
                durationSeconds: nil, timelineLabel: "Wyłącz", bottomActionTitle: "Gotowe"),
            LivePhase(kind: .rest,
                title: "Pozwól wywarowi odstać",
                shortText: "Odstawienie przez około 20 minut poprawia klarowność.",
                detailText: "Osad powoli opada na dno. Nie ruszaj garnka — po 20 minutach przecedzenie będzie znacznie łatwiejsze.",
                durationSeconds: 20 * 60, timelineLabel: "20 min", bottomActionTitle: nil),
            LivePhase(kind: .strainAndSeason,
                title: clarityMode == .paperFilter ? "Przefiltruj, przecedź i dopraw" : "Przecedź i dopraw",
                shortText: clarityMode == .paperFilter
                    ? "Najpierw przefiltruj wywar, a dopiero potem skoryguj sól."
                    : "Przecedź wywar i dopiero potem skoryguj sól.",
                detailText: clarityMode == .paperFilter
                    ? "Najpierw przecedź wywar wstępnie, a potem dokładnie przefiltruj go przez filtr papierowy albo bardzo gęsty filtr. Dopiero po tym spróbuj i skoryguj sól."
                    : "Przecedź wywar bez wyciskania składników. Dopiero po przecedzeniu sprawdź smak i skoryguj sól.",
                durationSeconds: nil, timelineLabel: "Cedzenie", bottomActionTitle: "Zakończ")
        ])

        return items
    }
}

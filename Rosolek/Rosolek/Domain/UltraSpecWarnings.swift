import Foundation

enum UltraSpecWarningCode: String, Hashable {
    case hardPotTooSmall = "HARD_POT_TOO_SMALL"
    case hardPotTooBig = "HARD_POT_TOO_BIG"
    case hardNotFit = "HARD_NOT_FIT"
    case underpower = "UNDERPOWER"
    case underpowerForPot = "UNDERPOWER_FOR_POT"
    case overpower = "OVERPOWER"
    case vegTooMuch = "VEG_TOO_MUCH"
    case paperFilterLowerIntensity = "PAPER_FILTER_LOWER_INTENSITY"
    case wingsTooHigh = "WINGS_TOO_HIGH"
    case beefTooHigh = "BEEF_TOO_HIGH"
    case offalTooHigh = "OFFAL_TOO_HIGH"
    case vegSweetRisk = "VEG_SWEET_RISK"
}

struct UltraSpecWarningSuggestion: Hashable {
    let text: String
    let deltaMeatG: Int?
    let deltaWaterL: Double?
    let deltaVegetablesG: Int?
}

struct UltraSpecWarningMessage: Hashable {
    let code: UltraSpecWarningCode
    let severity: UltraSpecSeverity
    let title: String
    let message: String
    let fixNow: String
    let suggestion: UltraSpecWarningSuggestion?
}

enum UltraSpecWarnings {
    static func buildWarnings(
        request: UltraSpecCalculationRequest,
        densityGL: Double,
        waterStartL: Double,
        totalAnimalG: Int,
        vegetableTotalG: Int,
        thresholds: UltraSpecWarningThresholds?,
        wingsShare: Double,
        beefShare: Double,
        offalShare: Double,
        carrotShare: Double
    ) -> [UltraSpecWarningMessage] {
        var warnings: [UltraSpecWarningMessage] = []

        if let thresholds {
            if densityGL < thresholds.density.minGL {
                let deltaMeat = Int((thresholds.density.minGL * waterStartL - Double(totalAnimalG)).rounded(.up))
                warnings.append(.init(code: .underpower, severity: .warn, title: "Bulion może wyjść zbyt delikatny", message: "Baza jest zbyt mała względem ilości wody dla wybranego wariantu.", fixNow: "Dodaj więcej bazy.", suggestion: .init(text: "Dodaj około \(max(0, deltaMeat)) g bazy.", deltaMeatG: max(0, deltaMeat), deltaWaterL: nil, deltaVegetablesG: nil)))
            } else if let minPerPot = thresholds.minMeatPerPotGL,
                      Double(totalAnimalG) / request.potCapacityL < minPerPot {
                let minGrams = Int((minPerPot * request.potCapacityL).rounded(.up))
                let deltaMeat = max(0, minGrams - totalAnimalG)
                warnings.append(.init(code: .underpowerForPot, severity: .warn, title: "Za mało bazy na ten garnek", message: "Przy garnku \(Int(request.potCapacityL)) L potrzebujesz więcej składników, żeby bulion miał dobry smak i właściwą intensywność.", fixNow: "Dodaj więcej bazy — minimum to około \(minGrams) g dla garnka \(Int(request.potCapacityL)) L.", suggestion: .init(text: "Dodaj około \(deltaMeat) g bazy.", deltaMeatG: deltaMeat, deltaWaterL: nil, deltaVegetablesG: nil)))
            }

            if densityGL > thresholds.density.maxGL {
                let targetMeatG = Int((thresholds.density.maxGL * waterStartL).rounded(.down))
                let deltaMeat = max(0, totalAnimalG - targetMeatG)
                warnings.append(.init(code: .overpower, severity: .warn, title: "Bulion może wyjść zbyt ciężki", message: "Baza jest bardzo gęsta względem ilości wody.", fixNow: "Zmniejsz bazę.", suggestion: .init(text: "Usuń około \(deltaMeat) g bazy.", deltaMeatG: -deltaMeat, deltaWaterL: nil, deltaVegetablesG: nil)))
            }

            let vegGL = waterStartL > 0 ? Double(vegetableTotalG) / waterStartL : 0
            if vegGL > thresholds.vegetableCapGL {
                let targetVegG = Int((thresholds.vegetableCapGL * waterStartL).rounded(.down))
                let deltaVeg = max(0, vegetableTotalG - targetVegG)
                warnings.append(.init(code: .vegTooMuch, severity: .warn, title: "Za dużo warzyw na litr", message: "Bulion może wyjść zbyt słodki i mniej klarowny.", fixNow: "Zmniejsz warzywa do wskazanej ilości.", suggestion: .init(text: "Usuń około \(deltaVeg) g warzyw, aby wrócić do limitu.", deltaMeatG: nil, deltaWaterL: nil, deltaVegetablesG: deltaVeg)))
            }

            // Show at most one composition warning from this group — the highest-priority hit.
            // Showing multiple simultaneously is redundant noise (they share the same root cause).
            var compositionWarning: UltraSpecWarningMessage? = nil
            if compositionWarning == nil, let maxOffal = thresholds.offalMaxShare, offalShare > maxOffal {
                compositionWarning = .init(code: .offalTooHigh, severity: .warn, title: "Za dużo podrobów", message: "Podroby mogą zdominować smak i pogorszyć klarowność.", fixNow: "Zmniejsz podroby — mają wspierać bazę, nie dominować smaku.", suggestion: nil)
            }
            if compositionWarning == nil, let maxBeef = thresholds.beefMaxShare, beefShare > maxBeef {
                compositionWarning = .init(code: .beefTooHigh, severity: .warn, title: "Wołowina dominuje profil", message: "Zbyt wysoki udział wołowiny może zrobić bulion ciężkim.", fixNow: "Zmniejsz wołowinę lub zwiększ udział drobiu.", suggestion: nil)
            }
            if compositionWarning == nil, let maxWings = thresholds.wingsMaxShare, wingsShare > maxWings {
                compositionWarning = .init(code: .wingsTooHigh, severity: .warn, title: "Za duży udział skrzydeł", message: "Skrzydła mogą podnieść tłustość i obniżyć klarowność.", fixNow: "Zamień część skrzydeł na korpus lub szyje.", suggestion: nil)
            }
            if let compositionWarning { warnings.append(compositionWarning) }
            if let carrotMax = thresholds.carrotMaxShare, carrotShare > carrotMax {
                warnings.append(.init(code: .vegSweetRisk, severity: .warn, title: "Ryzyko przesłodzenia", message: "Udział marchewki jest za wysoki dla tego wariantu.", fixNow: "Zmniejsz marchew i zwiększ seler/pietruszkę.", suggestion: nil))
            }
        }

        if request.clarityMode == .paperFilter {
            warnings.append(.init(code: .paperFilterLowerIntensity, severity: .info, title: "Filtr papierowy zmniejsza uzysk", message: "Filtr poprawia klarowność, ale zwykle obniża uzysk i intensywność.", fixNow: "Finalnego bulionu zostanie odrobinę mniej — to normalne.", suggestion: nil))
        }

        return warnings
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

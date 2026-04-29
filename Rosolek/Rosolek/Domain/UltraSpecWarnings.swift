import Foundation

enum UltraSpecWarningCode: String, Hashable {
    case hardPotTooSmall = "HARD_POT_TOO_SMALL"
    case hardPotTooBig = "HARD_POT_TOO_BIG"
    case hardNotFit = "HARD_NOT_FIT"

    case underpower = "UNDERPOWER"
    case overpower = "OVERPOWER"
    case vegTooMuch = "VEG_TOO_MUCH"
    case paperFilterLowerIntensity = "PAPER_FILTER_LOWER_INTENSITY"
    case wingsTooHigh = "WINGS_TOO_HIGH"
    case beefTooHigh = "BEEF_TOO_HIGH"
    case offalTooHigh = "OFFAL_TOO_HIGH"
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
        offalShare: Double
    ) -> [UltraSpecWarningMessage] {
        var warnings: [UltraSpecWarningMessage] = []

        if let thresholds {
            if densityGL < thresholds.density.minGL {
                let deltaMeat = Int((thresholds.density.minGL * waterStartL - Double(totalAnimalG)).rounded(.up))
                let deltaWater = max(0, waterStartL - (Double(totalAnimalG) / thresholds.density.minGL))
                warnings.append(
                    .init(
                        code: .underpower,
                        severity: .warn,
                        title: "Bulion może wyjść zbyt delikatny",
                        message: "Baza jest zbyt mała względem ilości wody dla wybranego wariantu.",
                        fixNow: "Dodaj więcej bazy albo zmniejsz ilość wody.",
                        suggestion: .init(
                            text: "Dodaj około \(max(0, deltaMeat)) g bazy albo zmniejsz wodę o \(format(deltaWater)) L.",
                            deltaMeatG: max(0, deltaMeat),
                            deltaWaterL: deltaWater,
                            deltaVegetablesG: nil
                        )
                    )
                )
            }

            if densityGL > thresholds.density.maxGL {
                let deltaWater = max(0, (Double(totalAnimalG) / thresholds.density.maxGL) - waterStartL)
                warnings.append(
                    .init(
                        code: .overpower,
                        severity: .warn,
                        title: "Bulion może wyjść zbyt ciężki",
                        message: "Baza jest bardzo gęsta względem ilości wody.",
                        fixNow: "Dodaj wody lub zmniejsz ilość bazy.",
                        suggestion: .init(
                            text: "Dodaj około \(format(deltaWater)) L wody.",
                            deltaMeatG: nil,
                            deltaWaterL: deltaWater,
                            deltaVegetablesG: nil
                        )
                    )
                )
            }

            let vegGL = waterStartL > 0 ? Double(vegetableTotalG) / waterStartL : 0
            if vegGL > thresholds.vegetableCapGL {
                let targetVegG = Int((thresholds.vegetableCapGL * waterStartL).rounded(.down))
                let deltaVeg = max(0, vegetableTotalG - targetVegG)
                warnings.append(
                    .init(
                        code: .vegTooMuch,
                        severity: .warn,
                        title: "Za dużo warzyw na litr",
                        message: "Bulion może wyjść zbyt słodki i mniej klarowny.",
                        fixNow: "Zmniejsz warzywa lub zwiększ wodę, jeśli garnek pozwala.",
                        suggestion: .init(
                            text: "Usuń około \(deltaVeg) g warzyw, aby wrócić do limitu.",
                            deltaMeatG: nil,
                            deltaWaterL: nil,
                            deltaVegetablesG: deltaVeg
                        )
                    )
                )
            }
        }



            if let maxWings = thresholds.wingsMaxShare, wingsShare > maxWings {
                warnings.append(
                    .init(
                        code: .wingsTooHigh,
                        severity: .warn,
                        title: "Za duży udział skrzydeł",
                        message: "Skrzydła mogą podnieść tłustość i obniżyć klarowność.",
                        fixNow: "Zamień część skrzydeł na korpus lub szyje.",
                        suggestion: nil
                    )
                )
            }

            if let maxBeef = thresholds.beefMaxShare, beefShare > maxBeef {
                warnings.append(
                    .init(
                        code: .beefTooHigh,
                        severity: .warn,
                        title: "Wołowina dominuje profil",
                        message: "Zbyt wysoki udział wołowiny może zrobić bulion ciężkim.",
                        fixNow: "Zmniejsz wołowinę lub zwiększ udział drobiu.",
                        suggestion: nil
                    )
                )
            }

            if let maxOffal = thresholds.offalMaxShare, offalShare > maxOffal {
                warnings.append(
                    .init(
                        code: .offalTooHigh,
                        severity: .warn,
                        title: "Za dużo podrobów",
                        message: "Podroby mogą zdominować smak i pogorszyć klarowność.",
                        fixNow: "Zmniejsz podroby lub zwiększ bazę neutralną.",
                        suggestion: nil
                    )
                )
            }

                if request.clarityMode == .paperFilter {
            warnings.append(
                .init(
                    code: .paperFilterLowerIntensity,
                    severity: .info,
                    title: "Filtr papierowy zmniejsza uzysk",
                    message: "Filtr poprawia klarowność, ale zwykle obniża uzysk i intensywność.",
                    fixNow: "To normalne — jeśli chcesz mocniej, rozważ delikatną redukcję.",
                    suggestion: nil
                )
            )
        }

        return warnings
    }

    private static func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

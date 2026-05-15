import Foundation

enum UltraSpecVariantID: String, CaseIterable, Hashable {
    case rosolLekki
    case rosolBogaty
    case ramenShio
    case ramenTonkotsu
    case wolowyCzysty
    case wolowyMocny
    case warzywnyJasny
    case warzywnyUmami
    case rybnyDelikatny
    case rybnyIntensywny
}

enum UltraSpecSeverity: String, Hashable {
    case info, warn, error
}

struct UltraSpecTemperatureRange: Hashable {
    let minC: Int
    let maxC: Int
    let allowsBoiling: Bool
}

struct UltraSpecVariantConfig: Hashable {
    let id: UltraSpecVariantID
    let displayName: String
    let waterFactor: Double?
    let vegPercent: Double
    let yieldFactor: Double
    let saltStartCoef: Double
    let saltTargetCoef: Double
    let pepperPerL: Double
    let allspicePerL: Double
    let bayPerL: Double
    let temperature: UltraSpecTemperatureRange
    let totalMinutes: Int
}

struct UltraSpecDensityThreshold: Hashable {
    let minGL: Double
    let maxGL: Double
}

struct UltraSpecWarningThresholds: Hashable {
    let density: UltraSpecDensityThreshold
    let wingsMaxShare: Double?
    let beefMaxShare: Double?
    let offalMaxShare: Double?
    let fatWarn: Double?
    let boneMin: Double?
    let collagenMin: Double?
    let vegetableCapGL: Double
    let carrotMaxShare: Double?
    // Minimum grams of animal base per liter of pot capacity.
    // Density check alone cannot detect "too little" when waterFactor is fixed,
    // because density stays constant regardless of total meat amount.
    let minMeatPerPotGL: Double?
}

struct UltraSpecVegetableBasketItem: Hashable {
    let ingredientID: String
    let share: Double
    let optional: Bool
}

struct UltraSpecVegetableBasket: Hashable {
    let variant: UltraSpecVariantID
    let items: [UltraSpecVegetableBasketItem]
}

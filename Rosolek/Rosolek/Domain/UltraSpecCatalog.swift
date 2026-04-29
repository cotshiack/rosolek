import Foundation

enum UltraSpecIngredientCategory: String, Hashable {
    case poultry
    case pork
    case beef
    case offal
    case fish
    case veg
    case umami
}

struct UltraSpecIngredient: Hashable, Identifiable {
    let id: String
    let name: String
    let category: UltraSpecIngredientCategory
    let allowedVariants: Set<UltraSpecVariantID>
    let bonesFlag: Bool
    let fatScore: Double
    let collagenScore: Double
    let tags: Set<String>
    let premiumOnly: Bool
}

enum UltraSpecCatalog {
    static let variants: [UltraSpecVariantConfig] = [
        .init(id: .rosolLekki, displayName: "Rosół Lekki", waterFactor: 4.5, vegPercent: 0.125, yieldFactor: 0.84, saltStartCoef: 1.4, saltTargetCoef: 7.0, pepperPerL: 3.0, allspicePerL: 1.1, bayPerL: 0.5, temperature: .init(minC: 88, maxC: 90, allowsBoiling: false), totalMinutes: 315),
        .init(id: .rosolBogaty, displayName: "Rosół Bogaty", waterFactor: 2.6, vegPercent: 0.140, yieldFactor: 0.80, saltStartCoef: 1.7, saltTargetCoef: 7.7, pepperPerL: 3.5, allspicePerL: 1.3, bayPerL: 0.6, temperature: .init(minC: 88, maxC: 90, allowsBoiling: false), totalMinutes: 345),
        .init(id: .ramenShio, displayName: "Ramen Shio", waterFactor: 3.0, vegPercent: 0.080, yieldFactor: 0.82, saltStartCoef: 0.6, saltTargetCoef: 6.0, pepperPerL: 1.2, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 88, maxC: 92, allowsBoiling: false), totalMinutes: 240),
        .init(id: .ramenTonkotsu, displayName: "Ramen Tonkotsu", waterFactor: 1.8, vegPercent: 0.040, yieldFactor: 0.70, saltStartCoef: 0.0, saltTargetCoef: 5.0, pepperPerL: 0.0, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 95, maxC: 100, allowsBoiling: true), totalMinutes: 480)
    ]

    static let ingredients: [UltraSpecIngredient] = [
        .init(id: "POULTRY_OLD_HEN", name: "Kura stara", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 1.2, collagenScore: 2.4, tags: ["collagen", "classic"], premiumOnly: false),
        .init(id: "POULTRY_CARCASS", name: "Korpus kurczaka", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 1.0, collagenScore: 2.0, tags: ["bones"], premiumOnly: false),
        .init(id: "POULTRY_NECK", name: "Szyje kurczaka", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 0.8, collagenScore: 2.3, tags: ["collagen"], premiumOnly: false),
        .init(id: "POULTRY_WINGS", name: "Skrzydła", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: false, fatScore: 2.2, collagenScore: 1.1, tags: ["wingLike", "fat"], premiumOnly: false),
        .init(id: "BEEF_SHANK", name: "Pręga", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny, .ramenShio], bonesFlag: false, fatScore: 1.2, collagenScore: 1.6, tags: ["classic"], premiumOnly: false),
        .init(id: "BEEF_SHORT_RIB", name: "Szponder", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny, .ramenShio], bonesFlag: false, fatScore: 1.7, collagenScore: 1.4, tags: ["classic"], premiumOnly: false),
        .init(id: "PORK_JOINT_BONES", name: "Kości wieprzowe stawowe", category: .pork, allowedVariants: [.ramenTonkotsu], bonesFlag: true, fatScore: 1.6, collagenScore: 2.2, tags: ["tonkotsu", "bones"], premiumOnly: false),
        .init(id: "PORK_TROTTERS", name: "Łapki wieprzowe", category: .pork, allowedVariants: [.ramenTonkotsu], bonesFlag: true, fatScore: 1.2, collagenScore: 2.4, tags: ["tonkotsu", "collagen"], premiumOnly: false),
        .init(id: "FISH_WHITE_BONES", name: "Ości białych ryb", category: .fish, allowedVariants: [.rybnyDelikatny, .rybnyIntensywny], bonesFlag: true, fatScore: 0.5, collagenScore: 0.6, tags: ["fishBase"], premiumOnly: false),
        .init(id: "VEG_ONION", name: "Cebula", category: .veg, allowedVariants: [.warzywnyJasny, .warzywnyUmami, .rybnyDelikatny, .rybnyIntensywny], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["onion"], premiumOnly: false)
    ]
}

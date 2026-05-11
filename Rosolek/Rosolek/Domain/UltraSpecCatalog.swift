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
        .init(id: .ramenTonkotsu, displayName: "Ramen Tonkotsu", waterFactor: 1.8, vegPercent: 0.040, yieldFactor: 0.70, saltStartCoef: 0.0, saltTargetCoef: 5.0, pepperPerL: 0.0, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 95, maxC: 100, allowsBoiling: true), totalMinutes: 480),
        .init(id: .wolowyCzysty, displayName: "Wołowy Czysty", waterFactor: 2.8, vegPercent: 0.060, yieldFactor: 0.80, saltStartCoef: 0.8, saltTargetCoef: 6.2, pepperPerL: 2.0, allspicePerL: 0.5, bayPerL: 0.4, temperature: .init(minC: 88, maxC: 92, allowsBoiling: false), totalMinutes: 360),
        .init(id: .wolowyMocny, displayName: "Wołowy Mocny", waterFactor: 2.0, vegPercent: 0.070, yieldFactor: 0.76, saltStartCoef: 0.9, saltTargetCoef: 6.6, pepperPerL: 2.2, allspicePerL: 0.6, bayPerL: 0.4, temperature: .init(minC: 90, maxC: 94, allowsBoiling: false), totalMinutes: 420),
        .init(id: .warzywnyJasny, displayName: "Warzywny Jasny", waterFactor: nil, vegPercent: 0.200, yieldFactor: 0.86, saltStartCoef: 0.8, saltTargetCoef: 5.8, pepperPerL: 1.2, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 85, maxC: 88, allowsBoiling: false), totalMinutes: 90),
        .init(id: .warzywnyUmami, displayName: "Warzywny Umami", waterFactor: nil, vegPercent: 0.220, yieldFactor: 0.84, saltStartCoef: 0.9, saltTargetCoef: 6.2, pepperPerL: 1.4, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 88, maxC: 92, allowsBoiling: false), totalMinutes: 120),
        .init(id: .rybnyDelikatny, displayName: "Rybny Delikatny", waterFactor: nil, vegPercent: 0.100, yieldFactor: 0.85, saltStartCoef: 0.6, saltTargetCoef: 5.6, pepperPerL: 0.6, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 80, maxC: 85, allowsBoiling: false), totalMinutes: 45),
        .init(id: .rybnyIntensywny, displayName: "Rybny Intensywny", waterFactor: nil, vegPercent: 0.120, yieldFactor: 0.82, saltStartCoef: 0.7, saltTargetCoef: 5.9, pepperPerL: 0.8, allspicePerL: 0.0, bayPerL: 0.0, temperature: .init(minC: 85, maxC: 90, allowsBoiling: false), totalMinutes: 60)
    ]

    static let ingredients: [UltraSpecIngredient] = [
        .init(id: "POULTRY_OLD_HEN", name: "Kura stara", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 1.2, collagenScore: 2.4, tags: ["collagen", "classic"], premiumOnly: false),
        .init(id: "POULTRY_CARCASS", name: "Korpus kurczaka", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 1.0, collagenScore: 2.0, tags: ["bones"], premiumOnly: false),
        .init(id: "POULTRY_NECK", name: "Szyje kurczaka", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 0.8, collagenScore: 2.3, tags: ["collagen"], premiumOnly: false),
        .init(id: "POULTRY_WINGS", name: "Skrzydła", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: false, fatScore: 2.2, collagenScore: 1.1, tags: ["wingLike", "fat"], premiumOnly: false),
        .init(id: "POULTRY_THIGHS", name: "Udka", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: false, fatScore: 2.4, collagenScore: 1.0, tags: ["fat"], premiumOnly: false),
        .init(id: "POULTRY_SOUP_MIX", name: "Porcja rosołowa drobiowa", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty], bonesFlag: true, fatScore: 1.6, collagenScore: 1.8, tags: ["mixed"], premiumOnly: false),
        .init(id: "BEEF_SHANK", name: "Pręga", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny, .ramenShio], bonesFlag: false, fatScore: 1.2, collagenScore: 1.6, tags: ["classic"], premiumOnly: false),
        .init(id: "BEEF_SHORT_RIB", name: "Szponder", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny, .ramenShio], bonesFlag: false, fatScore: 1.7, collagenScore: 1.4, tags: ["classic"], premiumOnly: false),
        .init(id: "BEEF_OXTAIL", name: "Ogon wołowy", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny], bonesFlag: true, fatScore: 1.3, collagenScore: 2.6, tags: ["collagen"], premiumOnly: false),
        .init(id: "BEEF_JOINT_BONES", name: "Kości stawowe wołowe", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny], bonesFlag: true, fatScore: 0.9, collagenScore: 2.2, tags: ["bones"], premiumOnly: false),
        .init(id: "BEEF_MARROW_BONES", name: "Kości szpikowe", category: .beef, allowedVariants: [.rosolBogaty, .wolowyCzysty, .wolowyMocny], bonesFlag: true, fatScore: 2.1, collagenScore: 1.4, tags: ["fat"], premiumOnly: false),
        .init(id: "BEEF_BRISKET", name: "Mostek", category: .beef, allowedVariants: [.rosolBogaty, .wolowyMocny], bonesFlag: false, fatScore: 2.0, collagenScore: 1.1, tags: ["fat"], premiumOnly: false),
        .init(id: "PORK_JOINT_BONES", name: "Kości wieprzowe stawowe", category: .pork, allowedVariants: [.ramenTonkotsu], bonesFlag: true, fatScore: 1.6, collagenScore: 2.2, tags: ["tonkotsu", "bones"], premiumOnly: false),
        .init(id: "PORK_TROTTERS", name: "Łapki wieprzowe", category: .pork, allowedVariants: [.ramenTonkotsu], bonesFlag: true, fatScore: 1.2, collagenScore: 2.4, tags: ["tonkotsu", "collagen"], premiumOnly: false),
        .init(id: "PORK_SPINE", name: "Kręgi wieprzowe", category: .pork, allowedVariants: [.ramenTonkotsu], bonesFlag: true, fatScore: 1.5, collagenScore: 2.1, tags: ["tonkotsu", "bones"], premiumOnly: false),
        
        .init(id: "OFFAL_CHICKEN_LIVER", name: "Wątróbka drobiowa", category: .offal, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio, .wolowyCzysty, .wolowyMocny], bonesFlag: false, fatScore: 1.8, collagenScore: 0.5, tags: ["offal", "endOnly"], premiumOnly: true),
        .init(id: "OFFAL_HEART", name: "Serca drobiowe", category: .offal, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio, .wolowyCzysty, .wolowyMocny], bonesFlag: false, fatScore: 1.0, collagenScore: 0.4, tags: ["offal", "endOnly"], premiumOnly: false),
        .init(id: "OFFAL_GIZZARD", name: "Żołądki drobiowe", category: .offal, allowedVariants: [.rosolLekki, .rosolBogaty], bonesFlag: false, fatScore: 0.6, collagenScore: 0.3, tags: ["offal", "endOnly"], premiumOnly: false),
        .init(id: "POULTRY_FEET", name: "Łapki drobiowe", category: .poultry, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio], bonesFlag: true, fatScore: 0.6, collagenScore: 3.2, tags: ["collagen"], premiumOnly: false),
        .init(id: "FISH_WHITE_BONES", name: "Ości białych ryb", category: .fish, allowedVariants: [.rybnyDelikatny, .rybnyIntensywny], bonesFlag: true, fatScore: 0.5, collagenScore: 0.6, tags: ["fishBase"], premiumOnly: false),
        .init(id: "FISH_HEADS", name: "Głowy białych ryb", category: .fish, allowedVariants: [.rybnyDelikatny, .rybnyIntensywny], bonesFlag: true, fatScore: 0.7, collagenScore: 0.9, tags: ["fishBase"], premiumOnly: false),
        .init(id: "SEAFOOD_SHRIMP_SHELLS", name: "Pancerze krewetek", category: .fish, allowedVariants: [.rybnyIntensywny], bonesFlag: false, fatScore: 0.4, collagenScore: 0.4, tags: ["umami"], premiumOnly: true),
        .init(id: "SEAFOOD_SHELLS", name: "Skorupiaki / małże", category: .fish, allowedVariants: [.rybnyIntensywny], bonesFlag: false, fatScore: 0.5, collagenScore: 0.4, tags: ["umami"], premiumOnly: true),
        .init(id: "VEG_ONION", name: "Cebula", category: .veg, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenShio, .ramenTonkotsu, .wolowyCzysty, .wolowyMocny, .warzywnyJasny, .warzywnyUmami, .rybnyDelikatny, .rybnyIntensywny], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["onion"], premiumOnly: false),
        .init(id: "VEG_CARROT", name: "Marchew", category: .veg, allowedVariants: [.rosolLekki, .rosolBogaty, .wolowyCzysty, .wolowyMocny, .warzywnyJasny, .warzywnyUmami, .rybnyDelikatny, .rybnyIntensywny], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["sweetRisk"], premiumOnly: false),
        .init(id: "VEG_CELERIAC", name: "Seler korzeniowy", category: .veg, allowedVariants: [.rosolLekki, .rosolBogaty, .wolowyCzysty, .wolowyMocny, .warzywnyJasny, .warzywnyUmami], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["base"], premiumOnly: false),
        .init(id: "VEG_PARSNIP_PL", name: "Pietruszka korzeń", category: .veg, allowedVariants: [.rosolLekki, .rosolBogaty, .wolowyCzysty, .wolowyMocny, .warzywnyJasny, .warzywnyUmami], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["base"], premiumOnly: false),
        .init(id: "VEG_LEEK", name: "Por", category: .veg, allowedVariants: [.rosolLekki, .rosolBogaty, .ramenTonkotsu, .warzywnyJasny, .warzywnyUmami, .rybnyDelikatny, .rybnyIntensywny], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["leek"], premiumOnly: false),
        .init(id: "VEG_CELERY_STALK", name: "Seler naciowy", category: .veg, allowedVariants: [.rybnyDelikatny, .rybnyIntensywny], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["stalk"], premiumOnly: false),
        .init(id: "AROMA_GINGER", name: "Imbir", category: .veg, allowedVariants: [.ramenShio, .ramenTonkotsu], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["aroma"], premiumOnly: false),
        .init(id: "AROMA_GARLIC", name: "Czosnek", category: .veg, allowedVariants: [.ramenShio, .ramenTonkotsu], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["aroma"], premiumOnly: false),
        .init(id: "AROMA_SCALLION", name: "Dymka", category: .veg, allowedVariants: [.ramenShio], bonesFlag: false, fatScore: 0, collagenScore: 0, tags: ["aroma"], premiumOnly: false)
    ]
}


extension UltraSpecCatalog {
    static let warningThresholds: [UltraSpecVariantID: UltraSpecWarningThresholds] = [
        .rosolLekki: .init(density: .init(minGL: 140, maxGL: 230), wingsMaxShare: 0.25, beefMaxShare: nil, offalMaxShare: 0.12, fatWarn: 1.6, boneMin: 0.60, collagenMin: nil, vegetableCapGL: 350, carrotMaxShare: nil),
        .rosolBogaty: .init(density: .init(minGL: 240, maxGL: 420), wingsMaxShare: nil, beefMaxShare: 0.55, offalMaxShare: 0.12, fatWarn: 2.0, boneMin: 0.35, collagenMin: 1.2, vegetableCapGL: 350, carrotMaxShare: nil),
        .ramenShio: .init(density: .init(minGL: 180, maxGL: 350), wingsMaxShare: nil, beefMaxShare: 0.55, offalMaxShare: 0.12, fatWarn: 2.0, boneMin: nil, collagenMin: nil, vegetableCapGL: 350, carrotMaxShare: nil),
        .ramenTonkotsu: .init(density: .init(minGL: 600, maxGL: 1200), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: nil, fatWarn: nil, boneMin: nil, collagenMin: nil, vegetableCapGL: 350, carrotMaxShare: nil),
        .wolowyCzysty: .init(density: .init(minGL: 260, maxGL: 520), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: 0.12, fatWarn: 2.0, boneMin: nil, collagenMin: nil, vegetableCapGL: 350, carrotMaxShare: nil),
        .wolowyMocny: .init(density: .init(minGL: 380, maxGL: 700), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: 0.12, fatWarn: 2.2, boneMin: nil, collagenMin: nil, vegetableCapGL: 350, carrotMaxShare: nil),
        .warzywnyJasny: .init(density: .init(minGL: 220, maxGL: 320), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: nil, fatWarn: nil, boneMin: nil, collagenMin: nil, vegetableCapGL: 420, carrotMaxShare: 0.25),
        .warzywnyUmami: .init(density: .init(minGL: 260, maxGL: 380), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: nil, fatWarn: nil, boneMin: nil, collagenMin: nil, vegetableCapGL: 420, carrotMaxShare: 0.30),
        .rybnyDelikatny: .init(density: .init(minGL: 250, maxGL: 380), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: nil, fatWarn: nil, boneMin: nil, collagenMin: nil, vegetableCapGL: 120, carrotMaxShare: 0.15),
        .rybnyIntensywny: .init(density: .init(minGL: 320, maxGL: 480), wingsMaxShare: nil, beefMaxShare: nil, offalMaxShare: nil, fatWarn: nil, boneMin: nil, collagenMin: nil, vegetableCapGL: 120, carrotMaxShare: 0.15)
    ]

    static let vegetableBaskets: [UltraSpecVariantID: [UltraSpecVegetableBasketItem]] = [
        .rosolLekki: [.init(ingredientID: "VEG_CARROT", share: 0.34, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.29, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.17, optional: true)],
        .rosolBogaty: [.init(ingredientID: "VEG_CARROT", share: 0.34, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.29, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.17, optional: true)],
        .ramenShio: [.init(ingredientID: "VEG_ONION", share: 0.45, optional: false), .init(ingredientID: "AROMA_GINGER", share: 0.25, optional: false), .init(ingredientID: "AROMA_GARLIC", share: 0.15, optional: false), .init(ingredientID: "AROMA_SCALLION", share: 0.15, optional: true)],
        .ramenTonkotsu: [.init(ingredientID: "VEG_ONION", share: 0.40, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.25, optional: false), .init(ingredientID: "AROMA_GINGER", share: 0.20, optional: false), .init(ingredientID: "AROMA_GARLIC", share: 0.15, optional: false)],
        .wolowyCzysty: [.init(ingredientID: "VEG_ONION", share: 0.35, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.25, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.20, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false)],
        .wolowyMocny: [.init(ingredientID: "VEG_ONION", share: 0.35, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.25, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.20, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false)],
        .warzywnyJasny: [.init(ingredientID: "VEG_ONION", share: 0.30, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.30, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.15, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.05, optional: false)],
        .warzywnyUmami: [.init(ingredientID: "VEG_ONION", share: 0.30, optional: false), .init(ingredientID: "VEG_CELERIAC", share: 0.30, optional: false), .init(ingredientID: "VEG_PARSNIP_PL", share: 0.20, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.15, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.05, optional: false)],
        .rybnyDelikatny: [.init(ingredientID: "VEG_ONION", share: 0.40, optional: false), .init(ingredientID: "VEG_CELERY_STALK", share: 0.25, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.20, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.15, optional: false)],
        .rybnyIntensywny: [.init(ingredientID: "VEG_ONION", share: 0.40, optional: false), .init(ingredientID: "VEG_CELERY_STALK", share: 0.25, optional: false), .init(ingredientID: "VEG_LEEK", share: 0.20, optional: false), .init(ingredientID: "VEG_CARROT", share: 0.15, optional: false)]
    ]
}

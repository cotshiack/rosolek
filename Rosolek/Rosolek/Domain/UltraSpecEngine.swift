import Foundation

struct UltraSpecInputItem: Hashable {
    let ingredientID: String
    let grams: Int
}

struct UltraSpecCalculationRequest: Hashable {
    let variant: UltraSpecVariantID
    let potCapacityL: Double
    let items: [UltraSpecInputItem]
    let clarityMode: BrothClarityMode
}

struct UltraSpecComputedVegetable: Hashable {
    let ingredientID: String
    let grams: Int
}

struct UltraSpecComputedSpices: Hashable {
    let peppercornCount: Int
    let allspiceCount: Int
    let bayLeafCount: Int
}

struct UltraSpecCalculationResult: Hashable {
    let waterRecipeL: Double
    let waterStartL: Double
    let estimatedYieldL: Double
    let startSaltG: Double
    let targetSaltG: Double
    let vegetableTotalG: Int
    let vegetables: [UltraSpecComputedVegetable]
    let spices: UltraSpecComputedSpices
    let totalAnimalG: Int
    let densityGL: Double
    let warnings: [String]
    let warningMessages: [UltraSpecWarningMessage]
}

enum UltraSpecEngine {
    static func calculate(request: UltraSpecCalculationRequest) throws -> UltraSpecCalculationResult {
        let config = try configForVariant(request.variant)

        let ingredientMap = Dictionary(uniqueKeysWithValues: UltraSpecCatalog.ingredients.map { ($0.id, $0) })
        let resolvedItems: [(UltraSpecIngredient, Int)] = request.items.compactMap { item in
            guard let ingredient = ingredientMap[item.ingredientID] else { return nil }
            guard ingredient.allowedVariants.contains(request.variant) else { return nil }
            return (ingredient, item.grams)
        }

        let totalAnimalG = resolvedItems
            .filter { $0.0.category != .veg && $0.0.category != .umami }
            .reduce(0) { $0 + max(0, $1.1) }

        let poultryG = resolvedItems.filter { $0.0.category == .poultry }.reduce(0) { $0 + max(0, $1.1) }
        let beefG = resolvedItems.filter { $0.0.category == .beef }.reduce(0) { $0 + max(0, $1.1) }
        let offalG = resolvedItems.filter { $0.0.category == .offal }.reduce(0) { $0 + max(0, $1.1) }
        let wingsG = resolvedItems.filter { $0.0.id == "POULTRY_WINGS" }.reduce(0) { $0 + max(0, $1.1) }


        guard request.potCapacityL >= 0.25 else { throw UltraSpecEngineError.hardPotTooSmall }
        guard request.potCapacityL <= 30 else { throw UltraSpecEngineError.hardPotTooBig }
        guard totalAnimalG <= 10_000 else { throw UltraSpecEngineError.hardTooMuchMeat }

        let animalRequired: Bool = {
            switch request.variant {
            case .warzywnyJasny, .warzywnyUmami:
                return false
            default:
                return true
            }
        }()
        if animalRequired && totalAnimalG == 0 {
            throw UltraSpecEngineError.hardNoBase
        }

        let displacementL = Double(totalAnimalG) / 1000.0 * 0.55
        let foamReserveL = request.potCapacityL * 0.12
        let safetyReserveL = max(0.25, request.potCapacityL * 0.08)
        let waterSafeL = request.potCapacityL - displacementL - foamReserveL - safetyReserveL

        guard waterSafeL > 0 else { throw UltraSpecEngineError.hardNotFit }

        let waterRecipeL: Double = {
            if let waterFactor = config.waterFactor {
                return (Double(totalAnimalG) / 1000.0) * waterFactor
            }
            return min(waterSafeL, request.potCapacityL * 0.72)
        }()

        let waterStartL = max(0.1, min(waterRecipeL, waterSafeL))
        let vegetableTotalG = Int((waterStartL * 1000 * config.vegPercent).rounded())
        let basket = UltraSpecCatalog.vegetableBaskets[request.variant] ?? []
        let vegetables = basket.map {
            UltraSpecComputedVegetable(ingredientID: $0.ingredientID, grams: Int((Double(vegetableTotalG) * $0.share).rounded()))
        }

        let carrotGrams = vegetables.first(where: { $0.ingredientID == "VEG_CARROT" })?.grams ?? 0
        let carrotShare = vegetableTotalG > 0 ? (Double(carrotGrams) / Double(vegetableTotalG)) : 0

        var estimatedYieldL = waterStartL * config.yieldFactor
        if request.clarityMode == .paperFilter {
            estimatedYieldL *= 0.96
        }

        let startSaltG = config.saltStartCoef * waterStartL
        let targetSaltG = config.saltTargetCoef * estimatedYieldL

        let spices = UltraSpecComputedSpices(
            peppercornCount: max(0, Int((config.pepperPerL * waterStartL).rounded())),
            allspiceCount: max(0, Int((config.allspicePerL * waterStartL).rounded())),
            bayLeafCount: max(0, Int((config.bayPerL * waterStartL).rounded()))
        )

        let densityGL = waterStartL > 0 ? Double(totalAnimalG) / waterStartL : 0
        let thresholds = UltraSpecCatalog.warningThresholds[request.variant]
        var warnings: [String] = []

        if let thresholds {
            if densityGL < thresholds.density.minGL {
                warnings.append("UNDERPOWER")
            }
            if densityGL > thresholds.density.maxGL {
                warnings.append("OVERPOWER")
            }
            let vegGL = waterStartL > 0 ? Double(vegetableTotalG) / waterStartL : 0
            if vegGL > thresholds.vegetableCapGL {
                warnings.append("VEG_TOO_MUCH")
            }
            if let limit = thresholds.wingsMaxShare, totalAnimalG > 0, (Double(wingsG) / Double(totalAnimalG)) > limit {
                warnings.append("WINGS_TOO_HIGH")
            }
            if let limit = thresholds.beefMaxShare, totalAnimalG > 0, (Double(beefG) / Double(totalAnimalG)) > limit {
                warnings.append("BEEF_TOO_HIGH")
            }
            if let limit = thresholds.offalMaxShare, totalAnimalG > 0, (Double(offalG) / Double(totalAnimalG)) > limit {
                warnings.append("OFFAL_TOO_HIGH")
            }
            if let carrotMax = thresholds.carrotMaxShare, carrotShare > carrotMax {
                warnings.append("VEG_SWEET_RISK")
            }
        }

        if request.clarityMode == .paperFilter {
            warnings.append("PAPER_FILTER_LOWER_INTENSITY")
        }

        let warningMessages = UltraSpecWarnings.buildWarnings(
            request: request,
            densityGL: densityGL,
            waterStartL: waterStartL,
            totalAnimalG: totalAnimalG,
            vegetableTotalG: vegetableTotalG,
            thresholds: thresholds,
            wingsShare: poultryG > 0 ? (Double(wingsG) / Double(poultryG)) : 0,
            beefShare: totalAnimalG > 0 ? (Double(beefG) / Double(totalAnimalG)) : 0,
            offalShare: totalAnimalG > 0 ? (Double(offalG) / Double(totalAnimalG)) : 0,
            carrotShare: carrotShare
        )

        return UltraSpecCalculationResult(
            waterRecipeL: waterRecipeL,
            waterStartL: waterStartL,
            estimatedYieldL: estimatedYieldL,
            startSaltG: startSaltG,
            targetSaltG: targetSaltG,
            vegetableTotalG: vegetableTotalG,
            vegetables: vegetables,
            spices: spices,
            totalAnimalG: totalAnimalG,
            densityGL: densityGL,
            warnings: warnings,
            warningMessages: warningMessages
        )
    }

    private static func configForVariant(_ variant: UltraSpecVariantID) throws -> UltraSpecVariantConfig {
        guard let config = UltraSpecCatalog.variants.first(where: { $0.id == variant }) else {
            throw UltraSpecEngineError.variantNotConfigured
        }
        return config
    }
}

enum UltraSpecEngineError: Error, Equatable {
    case variantNotConfigured
    case hardPotTooSmall
    case hardPotTooBig
    case hardNotFit
    case hardNoBase
    case hardTooMuchMeat
}

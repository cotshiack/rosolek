import Foundation

struct UltraSpecVariantResolver {
    static func resolve(kind: BrothKind, styleKey: String) -> UltraSpecVariantID {
        switch (kind, styleKey) {
        case (.rosol, "rosol_rich"):
            return .rosolBogaty
        case (.rosol, _):
            return .rosolLekki

        case (.ramen, "ramen_tonkotsu"):
            return .ramenTonkotsu
        case (.ramen, _):
            return .ramenShio

        case (.beef, "beef_strong"):
            return .wolowyMocny
        case (.beef, _):
            return .wolowyCzysty

        case (.veggie, "veggie_umami"):
            return .warzywnyUmami
        case (.veggie, _):
            return .warzywnyJasny

        case (.fish, "fish_intense"):
            return .rybnyIntensywny
        case (.fish, _):
            return .rybnyDelikatny
        }
    }
}

struct UltraSpecRequestBuilder {
    static func build(
        kind: BrothKind,
        styleKey: String,
        potCapacityL: Double,
        selections: [BrothIngredientSelection],
        clarityMode: BrothClarityMode
    ) -> UltraSpecCalculationRequest {
        let variant = UltraSpecVariantResolver.resolve(kind: kind, styleKey: styleKey)
        let items = selections.map { UltraSpecInputItem(ingredientID: mapIngredientID($0.ingredientID), grams: $0.grams) }

        return UltraSpecCalculationRequest(
            variant: variant,
            potCapacityL: potCapacityL,
            items: items,
            clarityMode: clarityMode
        )
    }

    static func mapIngredientID(_ id: String) -> String {
        switch id {
        case "kura": return "POULTRY_OLD_HEN"
        case "korpus_kurczaka": return "POULTRY_CARCASS"
        case "szyje_kurczaka": return "POULTRY_NECK"
        case "skrzydla_kurczaka": return "POULTRY_WINGS"
        case "lapki", "szyja_indyka", "skrzydlo_indyka", "korpus_indyka": return "POULTRY_NECK"
        case "korpus_kaczki", "szyja_kaczki", "skrzydla_kaczki": return "POULTRY_WINGS"
        case "szponder": return "BEEF_SHORT_RIB"
        case "prega": return "BEEF_SHANK"
        case "mostek", "golen", "ogon", "kosci_szpikowe", "kosci_rosolowe": return "BEEF_SHANK"
        case "kosci_wieprzowe": return "PORK_JOINT_BONES"
        case "lapki_wieprzowe", "gicz_wieprzowa": return "PORK_TROTTERS"
        case "serca", "zoladki", "watrobka": return "OFFAL_CHICKEN_LIVER"
        case "kregoslup_rybny": return "FISH_WHITE_BONES"
        case "glowy_rybne", "filet_rybny": return "FISH_WHITE_BONES"
        case "cebula_baza": return "VEG_ONION"
        case "seler_baza": return "VEG_CELERIAC"
        case "por_baza": return "VEG_LEEK"
        default: return id
        }
    }
}


struct UltraSpecStyleKeyResolver {
    static func resolve(kind: BrothKind, styleName: String?) -> String {
        let normalized = (styleName ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch kind {
        case .rosol:
            return normalized.contains("bogat") ? "rosol_rich" : "rosol_light"
        case .ramen:
            return normalized.contains("tonkotsu") ? "ramen_tonkotsu" : "ramen_shio"
        case .beef:
            return normalized.contains("moc") ? "beef_strong" : "beef_clean"
        case .veggie:
            return normalized.contains("umami") ? "veggie_umami" : "veggie_bright"
        case .fish:
            return normalized.contains("intens") ? "fish_intense" : "fish_delicate"
        }
    }
}

import Foundation

enum UltraSpecLiveBanners {
    static func hints(for variant: UltraSpecVariantID) -> [String] {
        switch variant {
        case .ramenTonkotsu:
            return [
                "Wrzenie jest celowe. Pilnuj poziomu wody — kości muszą być przykryte.",
                "Jeśli poziom spada, dolewaj gorącą wodę."
            ]
        case .rybnyDelikatny, .rybnyIntensywny:
            return [
                "Pilnuj limitu czasu. Po przekroczeniu rośnie ryzyko goryczy.",
                "Jeśli masz wątpliwości, zakończ wcześniej i przecedź."
            ]
        case .warzywnyJasny, .warzywnyUmami:
            return [
                "Nie przedłużaj czasu. Dłuższe gotowanie daje słodycz i płaskość."
            ]
        default:
            return [
                "Nie mieszaj. Mieszanie pogarsza klarowność.",
                "Temperatura rośnie za wysoko? Zmniejsz ogień lub zdejmij garnek na 60–120 s."
            ]
        }
    }
}

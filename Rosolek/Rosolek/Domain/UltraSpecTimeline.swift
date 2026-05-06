import Foundation

struct UltraSpecTimelineStep: Hashable {
    let stepID: String
    let timeLabel: String
    let title: String
    let subtitle: String
    let minuteOffset: Int
    let isManual: Bool

    init(stepID: String, timeLabel: String, title: String, subtitle: String, minuteOffset: Int, isManual: Bool = false) {
        self.stepID = stepID
        self.timeLabel = timeLabel
        self.title = title
        self.subtitle = subtitle
        self.minuteOffset = minuteOffset
        self.isManual = isManual
    }
}

enum UltraSpecTimelineCatalog {
    static func steps(for variant: UltraSpecVariantID) -> [UltraSpecTimelineStep] {
        switch variant {
        case .rosolLekki:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Garnek, sito i składniki.", minuteOffset: 0),
                .init(stepID: "stabilize_base", timeLabel: "60 min", title: "Ustabilizuj bazę", subtitle: "Poniżej wrzenia.", minuteOffset: 60),
                .init(stepID: "simmer_clear", timeLabel: "195 min", title: "Gotuj klarownie", subtitle: "Bez mieszania.", minuteOffset: 195),
                .init(stepID: "strain_season", timeLabel: "315 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 315)
            ]
        case .rosolBogaty:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Garnek, sito i składniki.", minuteOffset: 0),
                .init(stepID: "stabilize_base", timeLabel: "60 min", title: "Ustabilizuj bazę", subtitle: "Poniżej wrzenia.", minuteOffset: 60),
                .init(stepID: "finish_clear", timeLabel: "240 min", title: "Domknij smak", subtitle: "Dłuższy finisz bez wrzenia.", minuteOffset: 240),
                .init(stepID: "strain_season", timeLabel: "345 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 345)
            ]
        case .ramenShio:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Utrzymaj klarowną bazę.", minuteOffset: 0),
                .init(stepID: "heat_up_clear", timeLabel: "do temp.", title: "Podgrzewaj do temperatury pracy", subtitle: "Pracuj poniżej wrzenia.", minuteOffset: 0, isManual: true),
                .init(stepID: "stabilize_base", timeLabel: "180 min", title: "Główne gotowanie", subtitle: "Pracuj w 88-92°C.", minuteOffset: 180),
                .init(stepID: "add_veg_spices", timeLabel: "210 min", title: "Dodaj aromaty", subtitle: "Imbir, czosnek i cebula.", minuteOffset: 210, isManual: true),
                .init(stepID: "simmer_clear", timeLabel: "240 min", title: "Krótki finisz aromatów", subtitle: "Bez wrzenia.", minuteOffset: 240),
                .init(stepID: "strain_season", timeLabel: "240+ min", title: "Przecedź", subtitle: "Sól finalnie ustawiaj tare.", minuteOffset: 240, isManual: true)
            ]
        case .ramenTonkotsu:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kości i narzędzia gotowe.", minuteOffset: 0),
                .init(stepID: "tonkotsu_boil_emulsify", timeLabel: "360 min", title: "Emulsyfikacja", subtitle: "Wrzenie jest celem.", minuteOffset: 360),
                .init(stepID: "tonkotsu_aromatics_end", timeLabel: "420 min", title: "Aromaty końcowe", subtitle: "Krótko przed cedzeniem.", minuteOffset: 420, isManual: true),
                .init(stepID: "strain_season", timeLabel: "480+ min", title: "Przecedź i dopraw", subtitle: "Słoność ustawiaj przez tare.", minuteOffset: 480, isManual: true)
            ]
        case .wolowyCzysty:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury.", minuteOffset: 0),
                .init(stepID: "stabilize_base", timeLabel: "300 min", title: "Główne gotowanie", subtitle: "Czysty profil wołowy.", minuteOffset: 300),
                .init(stepID: "strain_season", timeLabel: "360 min", title: "Przecedź i dopraw", subtitle: "Bez wrzenia na końcu.", minuteOffset: 360)
            ]
        case .wolowyMocny:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury.", minuteOffset: 0),
                .init(stepID: "stabilize_base", timeLabel: "330 min", title: "Główne gotowanie", subtitle: "Mocny profil wołowy.", minuteOffset: 330),
                .init(stepID: "strain_season", timeLabel: "420 min", title: "Przecedź i dopraw", subtitle: "Opcjonalnie delikatna redukcja.", minuteOffset: 420)
            ]
        case .warzywnyJasny:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Pracuj w niższej temperaturze.", minuteOffset: 0),
                .init(stepID: "veg_simmer_limit", timeLabel: "60 min", title: "Kontrolowane gotowanie", subtitle: "Nie przeciągaj czasu.", minuteOffset: 60),
                .init(stepID: "strain_season", timeLabel: "90+ min", title: "Przecedź i dopraw", subtitle: "Sprawdź słodycz profilu.", minuteOffset: 90, isManual: true)
            ]
        case .warzywnyUmami:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Umami bez przesady czasu.", minuteOffset: 0),
                .init(stepID: "veg_simmer_limit", timeLabel: "75 min", title: "Kontrolowane gotowanie", subtitle: "Pilnuj czasu — zbyt długie gotowanie spłaszcza umami.", minuteOffset: 75),
                .init(stepID: "strain_season", timeLabel: "120+ min", title: "Przecedź i dopraw", subtitle: "Korekta soli po cedzeniu.", minuteOffset: 120, isManual: true)
            ]
        case .rybnyDelikatny:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Niska temperatura, krótki czas.", minuteOffset: 0),
                .init(stepID: "fish_poach_limit", timeLabel: "25 min", title: "Poach limit", subtitle: "Nie przekraczaj 30 minut.", minuteOffset: 25),
                .init(stepID: "strain_season", timeLabel: "45 min", title: "Przecedź", subtitle: "Nie redukuj rybnego.", minuteOffset: 45)
            ]
        case .rybnyIntensywny:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury i czasu.", minuteOffset: 0),
                .init(stepID: "fish_poach_limit", timeLabel: "35 min", title: "Poach limit", subtitle: "Nie przekraczaj 40 minut.", minuteOffset: 35),
                .init(stepID: "strain_season", timeLabel: "60 min", title: "Przecedź", subtitle: "Bez redukcji po gotowaniu.", minuteOffset: 60)
            ]
        }
    }
}

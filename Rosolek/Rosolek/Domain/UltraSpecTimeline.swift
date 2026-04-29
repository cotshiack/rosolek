import Foundation

struct UltraSpecTimelineStep: Hashable {
    let timeLabel: String
    let title: String
    let subtitle: String
    let minuteOffset: Int
}

enum UltraSpecTimelineCatalog {
    static func steps(for variant: UltraSpecVariantID) -> [UltraSpecTimelineStep] {
        switch variant {
        case .rosolLekki:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Garnek, sito i składniki.", minuteOffset: 0),
                .init(timeLabel: "60 min", title: "Ustabilizuj bazę", subtitle: "Poniżej wrzenia.", minuteOffset: 60),
                .init(timeLabel: "195 min", title: "Gotuj klarownie", subtitle: "Bez mieszania.", minuteOffset: 195),
                .init(timeLabel: "315 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 315)
            ]
        case .rosolBogaty:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Garnek, sito i składniki.", minuteOffset: 0),
                .init(timeLabel: "60 min", title: "Ustabilizuj bazę", subtitle: "Poniżej wrzenia.", minuteOffset: 60),
                .init(timeLabel: "240 min", title: "Domknij smak", subtitle: "Dłuższy finisz bez wrzenia.", minuteOffset: 240),
                .init(timeLabel: "345 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 345)
            ]
        case .ramenShio:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Utrzymaj klarowną bazę.", minuteOffset: 0),
                .init(timeLabel: "180 min", title: "Główne gotowanie", subtitle: "Pracuj w 88-92°C.", minuteOffset: 180),
                .init(timeLabel: "240 min", title: "Przecedź", subtitle: "Sól finalnie ustawiaj tare.", minuteOffset: 240)
            ]
        case .ramenTonkotsu:
            return [
                .init(timeLabel: "0 min", title: "Start tonkotsu", subtitle: "Wrzenie jest celem.", minuteOffset: 0),
                .init(timeLabel: "360 min", title: "Emulsyfikacja", subtitle: "Kości stale przykryte wodą.", minuteOffset: 360),
                .init(timeLabel: "480 min", title: "Aromaty końcowe", subtitle: "Krótko przed cedzeniem.", minuteOffset: 480)
            ]
        case .wolowyCzysty:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury.", minuteOffset: 0),
                .init(timeLabel: "300 min", title: "Główne gotowanie", subtitle: "Czysty profil wołowy.", minuteOffset: 300),
                .init(timeLabel: "360 min", title: "Przecedź i dopraw", subtitle: "Bez wrzenia na końcu.", minuteOffset: 360)
            ]
        case .wolowyMocny:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury.", minuteOffset: 0),
                .init(timeLabel: "330 min", title: "Główne gotowanie", subtitle: "Mocny profil wołowy.", minuteOffset: 330),
                .init(timeLabel: "420 min", title: "Przecedź i dopraw", subtitle: "Opcjonalnie delikatna redukcja.", minuteOffset: 420)
            ]
        case .warzywnyJasny:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Pracuj w niższej temperaturze.", minuteOffset: 0),
                .init(timeLabel: "60 min", title: "Kontrolowane gotowanie", subtitle: "Nie przeciągaj czasu.", minuteOffset: 60),
                .init(timeLabel: "90 min", title: "Przecedź i dopraw", subtitle: "Sprawdź słodycz profilu.", minuteOffset: 90)
            ]
        case .warzywnyUmami:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Umami bez przesady czasu.", minuteOffset: 0),
                .init(timeLabel: "75 min", title: "Kontrolowane gotowanie", subtitle: "Pilnuj czasu dodatków umami.", minuteOffset: 75),
                .init(timeLabel: "120 min", title: "Przecedź i dopraw", subtitle: "Korekta soli po cedzeniu.", minuteOffset: 120)
            ]
        case .rybnyDelikatny:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Niska temperatura, krótki czas.", minuteOffset: 0),
                .init(timeLabel: "25 min", title: "Poach limit", subtitle: "Nie przekraczaj 30 minut.", minuteOffset: 25),
                .init(timeLabel: "45 min", title: "Przecedź", subtitle: "Nie redukuj rybnego.", minuteOffset: 45)
            ]
        case .rybnyIntensywny:
            return [
                .init(timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury i czasu.", minuteOffset: 0),
                .init(timeLabel: "35 min", title: "Poach limit", subtitle: "Nie przekraczaj 40 minut.", minuteOffset: 35),
                .init(timeLabel: "60 min", title: "Przecedź", subtitle: "Bez redukcji po gotowaniu.", minuteOffset: 60)
            ]
        }
    }
}

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
                .init(stepID: "prep",           timeLabel: "—",        title: "Przygotuj stanowisko",        subtitle: "Garnek, składniki, narzędzia i sito.",              minuteOffset: 0),
                .init(stepID: "heat_up_clear",  timeLabel: "do temp.", title: "Podgrzewaj do temperatury",   subtitle: "Dąż do 88–90°C poniżej wrzenia.",                  minuteOffset: 0,   isManual: true),
                .init(stepID: "stabilize_base", timeLabel: "60 min",   title: "Ustabilizuj bazę",            subtitle: "Gotuj bazę równo, bez nowych dodatków.",           minuteOffset: 60),
                .init(stepID: "add_veg_spices", timeLabel: "2–3 min",  title: "Dodaj warzywa i przyprawy",   subtitle: "Dodaj z listy. Spadek temp. 1–3°C jest normalny.", minuteOffset: 60,  isManual: true),
                .init(stepID: "simmer_clear",   timeLabel: "135 min",  title: "Prowadź spokojną pracę",      subtitle: "Bez mieszania, bez wrzenia.",                      minuteOffset: 195),
                .init(stepID: "remove_poultry", timeLabel: "—",        title: "Wyjmij drób",                 subtitle: "Delikatnie, bez wyciskania nad płynem.",            minuteOffset: 195, isManual: true),
                .init(stepID: "simmer_clear",   timeLabel: "20 min",   title: "Domknij po wyjęciu drobiu",   subtitle: "Krótki finisz na samej bazie.",                    minuteOffset: 215),
                .init(stepID: "remove_veg",     timeLabel: "—",        title: "Wyjmij warzywa",              subtitle: "Bez wyciskania. Zostaw osad w garnku.",             minuteOffset: 215, isManual: true),
                .init(stepID: "finish_clear",   timeLabel: "35 min",   title: "Dokończ bazę",                subtitle: "Wyrównaj smak na samej bazie, bez wrzenia.",       minuteOffset: 250),
                .init(stepID: "rest_settle",    timeLabel: "20 min",   title: "Odstaw",                      subtitle: "Nie ruszaj garnka. Osad ma opaść.",                minuteOffset: 270),
                .init(stepID: "strain_season",  timeLabel: "10–20 min",title: "Przecedź i dopraw",           subtitle: "Najpierw cedzenie, potem sól.",                    minuteOffset: 270, isManual: true)
            ]
        case .rosolBogaty:
            return [
                .init(stepID: "prep",           timeLabel: "—",        title: "Przygotuj stanowisko",        subtitle: "Garnek, składniki, narzędzia i sito.",              minuteOffset: 0),
                .init(stepID: "heat_up_clear",  timeLabel: "do temp.", title: "Podgrzewaj do temperatury",   subtitle: "Dąż do 88–90°C poniżej wrzenia.",                  minuteOffset: 0,   isManual: true),
                .init(stepID: "stabilize_base", timeLabel: "60 min",   title: "Ustabilizuj bazę",            subtitle: "Drób i wołowina od zimnej wody. Zbieraj tylko to, co samo wypływa.", minuteOffset: 60),
                .init(stepID: "add_veg_spices", timeLabel: "2–3 min",  title: "Dodaj warzywa i przyprawy",   subtitle: "Dodaj z listy. Spadek temp. 1–3°C jest normalny.", minuteOffset: 60,  isManual: true),
                .init(stepID: "simmer_clear",   timeLabel: "165 min",  title: "Drób i wołowina — wspólna baza", subtitle: "Drób i wołowina gotują się razem. Bez mieszania, bez wrzenia.", minuteOffset: 225),
                .init(stepID: "remove_poultry", timeLabel: "—",        title: "Wyjmij drób",                 subtitle: "Drób jest gotowy. Wołowina gotuje się dalej.",     minuteOffset: 225, isManual: true),
                .init(stepID: "simmer_clear",   timeLabel: "30 min",   title: "Wołowina dochodzi",           subtitle: "Wołowina gotuje się bez drobiu. Spokojnie i bez wrzenia.", minuteOffset: 255),
                .init(stepID: "remove_veg",     timeLabel: "—",        title: "Wyjmij warzywa",              subtitle: "Bez wyciskania. Zostaw osad w garnku.",             minuteOffset: 255, isManual: true),
                .init(stepID: "finish_clear",   timeLabel: "75 min",   title: "Wołowina kończy gotowanie",   subtitle: "Wołowina daje finisz. Bez wrzenia.",               minuteOffset: 330),
                .init(stepID: "rest_settle",    timeLabel: "20 min",   title: "Odstaw",                      subtitle: "Nie ruszaj garnka. Osad ma opaść.",                minuteOffset: 350),
                .init(stepID: "strain_season",  timeLabel: "10–20 min",title: "Przecedź i dopraw",           subtitle: "Najpierw cedzenie, potem sól.",                    minuteOffset: 350, isManual: true)
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
                .init(stepID: "heat_up_clear", timeLabel: "do temp.", title: "Podgrzewaj delikatnie", subtitle: "Wejdź w zakres 80–85°C bez wrzenia.", minuteOffset: 0, isManual: true),
                .init(stepID: "fish_poach_limit", timeLabel: "25 min", title: "Krótka ekstrakcja rybna", subtitle: "Maks. 30 min (cel: ~25 min).", minuteOffset: 25),
                .init(stepID: "rest_settle", timeLabel: "5–10 min", title: "Daj bulionowi odpocząć", subtitle: "Nie mieszaj, osad opadnie na dno.", minuteOffset: 35, isManual: true),
                .init(stepID: "strain_season", timeLabel: "10–20 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 45, isManual: true)
            ]
        case .rybnyIntensywny:
            return [
                .init(stepID: "prep", timeLabel: "0 min", title: "Przygotuj stanowisko", subtitle: "Kontrola temperatury i czasu.", minuteOffset: 0),
                .init(stepID: "heat_up_clear", timeLabel: "do temp.", title: "Podgrzewaj delikatnie", subtitle: "Wejdź w zakres 85–90°C bez wrzenia.", minuteOffset: 0, isManual: true),
                .init(stepID: "fish_poach_limit", timeLabel: "35 min", title: "Krótka ekstrakcja rybna", subtitle: "Maks. 40 min (cel: ~35 min).", minuteOffset: 35),
                .init(stepID: "rest_settle", timeLabel: "5–10 min", title: "Daj bulionowi odpocząć", subtitle: "Nie mieszaj, osad opadnie na dno.", minuteOffset: 45, isManual: true),
                .init(stepID: "strain_season", timeLabel: "10–20 min", title: "Przecedź i dopraw", subtitle: "Najpierw cedzenie, potem sól.", minuteOffset: 60, isManual: true)
            ]
        }
    }

    static func steps(
        for variant: UltraSpecVariantID,
        hasBeef: Bool,
        hasPoultry: Bool
    ) -> [UltraSpecTimelineStep] {
        guard variant == .rosolBogaty else { return steps(for: variant) }
        guard hasBeef else { return steps(for: .rosolLekki) }

        var s = steps(for: .rosolBogaty)
        if !hasPoultry {
            if let i = s.firstIndex(where: { $0.stepID == "remove_poultry" }) {
                var toRemove = IndexSet([i])
                if i + 1 < s.count && s[i + 1].stepID == "simmer_clear" {
                    toRemove.insert(i + 1)
                }
                s = s.enumerated().filter { !toRemove.contains($0.offset) }.map { $0.element }
            }
        }
        return s
    }
}

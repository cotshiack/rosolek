import Foundation

struct UltraSpecStepDetail: Hashable {
    let stepID: String
    let title: String
    let subtitle: String
    let extendedHint: String
    let commonMistakes: String
    let recoveryAction: String
}

enum UltraSpecStepLibrary {
    static let prep = UltraSpecStepDetail(
        stepID: "prep",
        title: "Przygotuj stanowisko",
        subtitle: "Garnek, składniki i narzędzia.",
        extendedHint: "Przygotuj sito/gazę, łyżkę cedzakową i miskę na wyjmowane składniki. Nie mieszaj od startu.",
        commonMistakes: "Start bez narzędzi, mieszanie od początku, sonda dotyka dna.",
        recoveryAction: "Przerwij na minutę, przygotuj narzędzia i ustaw poprawnie sondę."
    )

    static let heatUpClear = UltraSpecStepDetail(
        stepID: "heat_up_clear",
        title: "Podgrzewaj do temperatury pracy",
        subtitle: "Dąż do pracy poniżej wrzenia.",
        extendedHint: "Zbieraj pianę tylko z powierzchni. Wrzenie w klarownych bulionach pogarsza klarowność.",
        commonMistakes: "Doprowadzenie do wrzenia, mieszanie, agresywne zbieranie osadu.",
        recoveryAction: "Zmniejsz ogień i pozwól osadowi opaść, potem przecedź przez gazę."
    )

    static let fishPoachLimit = UltraSpecStepDetail(
        stepID: "fish_poach_limit",
        title: "Rybny: gotuj krótko",
        subtitle: "Nie przekraczaj limitu czasu.",
        extendedHint: "Rybny jest wrażliwy na czas i temperaturę. Lepiej skończyć wcześniej niż przeciągnąć.",
        commonMistakes: "Zbyt długie gotowanie, wrzenie, za dużo warzyw.",
        recoveryAction: "Po przekroczeniu limitu: zakończ natychmiast i przecedź, nie redukuj."
    )

    static let tonkotsuBoil = UltraSpecStepDetail(
        stepID: "tonkotsu_boil_emulsify",
        title: "Tonkotsu: mocne wrzenie",
        subtitle: "Wrzenie jest celem, budujesz emulsję.",
        extendedHint: "Kości muszą być stale przykryte. Dolewaj gorącą wodę małymi porcjami.",
        commonMistakes: "Za mało wody, zbyt słabe grzanie, odkryte kości.",
        recoveryAction: "Dolej gorącą wodę i zmniejsz ryzyko przywierania przez korektę mocy."
    )

    static let strainSeason = UltraSpecStepDetail(
        stepID: "strain_season",
        title: "Przecedź i dopraw",
        subtitle: "Najpierw cedzenie, potem sól.",
        extendedHint: "Nie wyciskaj składników i zostaw osad na dnie. Doprawiaj po cedzeniu stopniowo.",
        commonMistakes: "Wyciskanie, przelewanie osadu, dosalanie przed cedzeniem.",
        recoveryAction: "Jeśli przesolone: rozcieńcz porcję lub połącz z niesolonym wywarem."
    )

    static let all: [String: UltraSpecStepDetail] = [
        prep.stepID: prep,
        heatUpClear.stepID: heatUpClear,
        fishPoachLimit.stepID: fishPoachLimit,
        tonkotsuBoil.stepID: tonkotsuBoil,
        strainSeason.stepID: strainSeason
    ]
}

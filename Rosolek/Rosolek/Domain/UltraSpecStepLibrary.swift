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



    static let stabilizeBase = UltraSpecStepDetail(
        stepID: "stabilize_base",
        title: "Ustabilizuj bazę",
        subtitle: "Utrzymuj temperaturę pracy.",
        extendedHint: "To etap budowania podstawy smaku i klarowności. Nie dopuszczaj do intensywnego wrzenia.",
        commonMistakes: "Skoki temperatury, mieszanie, zbyt mocny ogień.",
        recoveryAction: "Zmniejsz ogień i wróć do zakresu temperatury wariantu."
    )

    static let simmerClear = UltraSpecStepDetail(
        stepID: "simmer_clear",
        title: "Gotuj klarownie",
        subtitle: "Delikatna praca bez mieszania.",
        extendedHint: "Pozwól osadom opaść i utrzymuj spokojny ruch powierzchni.",
        commonMistakes: "Wrzenie, mieszanie, przegrzewanie końcówki etapu.",
        recoveryAction: "Uspokój temperaturę i odstaw na chwilę przed dalszym etapem."
    )

    static let finishClear = UltraSpecStepDetail(
        stepID: "finish_clear",
        title: "Domknij smak",
        subtitle: "Końcowe wyrównanie profilu.",
        extendedHint: "Pracuj bez wrzenia. To etap porządkowania smaku i klarowności.",
        commonMistakes: "Podkręcanie mocy na końcu, mieszanie po wyjęciu składników.",
        recoveryAction: "Wróć do spokojnej temperatury i przecedź przez gazę, jeśli trzeba."
    )

    static let tonkotsuAromaticsEnd = UltraSpecStepDetail(
        stepID: "tonkotsu_aromatics_end",
        title: "Tonkotsu: aromaty na końcu",
        subtitle: "Krótki etap przed cedzeniem.",
        extendedHint: "Dodaj aromaty pod koniec, aby uniknąć goryczy od długiej obróbki.",
        commonMistakes: "Aromaty od początku gotowania, zbyt długi czas kontaktu.",
        recoveryAction: "Jeśli aromaty dominują, rozcieńcz porcję i dopraw tare oddzielnie."
    )

    static let vegSimmerLimit = UltraSpecStepDetail(
        stepID: "veg_simmer_limit",
        title: "Warzywny: limit czasu",
        subtitle: "Kontrolowana temperatura i czas.",
        extendedHint: "Długie gotowanie warzyw zwiększa słodycz i spłaszcza aromat.",
        commonMistakes: "Przeciąganie czasu, zbyt wysoka temperatura.",
        recoveryAction: "Zakończ wcześniej i dopraw finalnie już po cedzeniu."
    )



    static let restSettle = UltraSpecStepDetail(
        stepID: "rest_settle",
        title: "Odstaw i pozwól opaść osadowi",
        subtitle: "Nie ruszaj garnka po wyłączeniu.",
        extendedHint: "Po wyłączeniu grzania osad powinien opaść na dno. Ruch garnka pogarsza klarowność.",
        commonMistakes: "Przelewanie od razu, mieszanie, potrząsanie garnkiem.",
        recoveryAction: "Jeśli poruszyłeś garnek, odstaw ponownie na 10 minut."
    )

    static let addVegSpices = UltraSpecStepDetail(
        stepID: "add_veg_spices",
        title: "Dodaj warzywa i przyprawy",
        subtitle: "W odpowiednim momencie i bez mieszania dna.",
        extendedHint: "Warzywa i przyprawy dodaj etapowo zgodnie z wariantem. Nie wyciskaj składników po etapie.",
        commonMistakes: "Za wczesne dodanie warzyw, zbyt długi kontakt z wysoką temperaturą.",
        recoveryAction: "Jeśli smak idzie w gorycz/słodycz, skróć etap i przecedź wcześniej."
    )

    static let fishPoachLimit = UltraSpecStepDetail(
        stepID: "fish_poach_limit",
        title: "Rybny: gotuj krótko",
        subtitle: "Nie przekraczaj 30–40 min (zależnie od wariantu).",
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
        strainSeason.stepID: strainSeason,
        stabilizeBase.stepID: stabilizeBase,
        simmerClear.stepID: simmerClear,
        finishClear.stepID: finishClear,
        tonkotsuAromaticsEnd.stepID: tonkotsuAromaticsEnd,
        vegSimmerLimit.stepID: vegSimmerLimit,
        restSettle.stepID: restSettle,
        addVegSpices.stepID: addVegSpices
    ]
}

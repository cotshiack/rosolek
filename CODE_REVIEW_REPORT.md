# Raport code review — Rosolek

**Data:** 2026-05-08  
**Reviewer:** Claude Code (claude-sonnet-4-6)  
**Pliki przejrzane:** 30 plików Swift (źródłowych) + 8 plików testowych  
**Poprzedni raport:** AUDIT_REPORT.md — Etap 1 zakończony

---

## Podsumowanie wykonawcze

Aplikacja Rosolek jest jakościowo powyżej średniej dla projektu jednej osoby: architektura dwuwarstwowa (legacy BrothCalculator + nowy UltraSpecEngine) jest sensownie zaprojektowana, persistence opiera się na Codable z obsługą błędów, a testy pokrywają krytyczne ścieżki kalkulatora. Etap 1 naprawił dwa CRITICAL bugi (utrata historii przy decode error i crash w release przez assertionFailure). Jednak pozostało kilka poważnych problemów, których nie wykrył poprzedni audyt: dwa niezależne handlowery `returnToHomeTrigger` powodują podwójny reset nawigacji, `parseGrams()` obcina dziesiętne produkując błędne wagi w UI, `BrothCalculator` jest wywoływany dla UltraSpec batchy przy deep linkach i banner aktywnego gotowania, oraz `previewResult` w IngredientSelectionView uruchamia pełny kalkulator na każdym renderze. Poza tym codebase zawiera kilka drobnych pominiętych napraw: deprecated `onChange` w SettingsView, martwy kod `cascadesReturnHome()`, oraz semantycznie błędne mapowanie `"finish_clear"` do `.stabilization`. Nie ma krytycznych bugów blokujących release, ale cztery spośród niżej opisanych problemów mają bezpośredni wpływ na użytkownika.

---

## Co działa dobrze

**Architektura domenowa UltraSpec:**  
`UltraSpecEngine.calculate()` (`/Domain/UltraSpecEngine.swift:42`) jest czyste, testowalne, bez side-effectów. Wszystkie guard-throw na wejściu są precyzyjne. Testy pokrywają wszystkie gałęzie błędów.

**Persistence z fallback recovery:**  
`BatchStore.recoverBatchesFromCorruptedData()` (`BatchStore.swift:203`) poprawnie obsługuje częściowo zepsute dane. Trzy testy to weryfikują (`BatchStoreTests.swift:151–210`).

**CookingSession roundtrip:**  
Persist/restore sesji gotowania jest poprawnie zaimplementowany z obsługą backgroundedAt (`CookingModeView.swift:1924`). Test suite (`CookingSessionTests.swift`) obejmuje 5 scenariuszy łącznie z garbled data.

**BrothResultView.frozenResult — memoizacja H-1:**  
`frozenResult` ustawiony w `onAppear` i odświeżany tylko przy zmianie `clarityMode`/`useVinegar` (`BrothResultView.swift:100–102`) efektywnie rozwiązuje problem zbędnych przeliczań w widoku wynikowym.

**BatchRecord.init(from:) z decodeIfPresent:**  
Dekodowanie batchów jest odporne na nowe pola — wszystkie opcjonalne pola używają `decodeIfPresent`, co zapewnia forward compatibility.

**UltraSpecVariantMapping — H-2 fix:**  
`mapIngredientID()` (`UltraSpecVariantMapping.swift:53`) pokrywa komplet aliasów łącznie z podrobami (serca/żołądki → OFFAL), kaczką, indykiem, rybami. Testy (`UltraSpecVariantMappingTests.swift:63–86`) weryfikują kluczowe przypadki.

**CookingModeView.livePhaseKind() — C-2 fix:**  
`assertionFailure()` zastąpione `print()` + safe fallback (`CookingModeView.swift:777`). Brak możliwości crasha przy nieobsługiwanym stepID.

**Walidacja w BatchFeedbackView:**  
`overallRating` jest `Double` z `Slider(…in: 1...10, step: 1)` — zakres jest narzucony przez slider. `updateFeedback()` dodatkowo clampuje `min(10, max(1, overallRating))` (`BatchStore.swift:132`).

**SettingsView.potInputAlert — UX blokada zapisu:**  
Wpisanie wartości > 30 l blokuje przycisk "Zapisz" (`blocksSave: true`) i pokazuje czytelny alert, co chroni przed przekroczeniem limitu UltraSpecEngine.

---

## Krytyczne problemy

Brak. Etap 1 usunął oba CRITICAL bugi (utrata historii, crash przez assertionFailure). Żaden z pozostałych problemów nie powoduje trwałej utraty danych ani crasha produkcyjnego.

---

## Poważne problemy

### S-1: Podwójny handler `returnToHomeTrigger` — podwójny reset nawigacji

**Pliki:** `ContentView.swift:30` i `ContentView.swift:218`

```swift
// ContentView (zewnętrzny NavigationStack)
.onChange(of: returnToHomeTrigger) { _, _ in
    navigationResetID = UUID()   // resetuje cały stack
}

// HomeView (wewnętrzny widok)
.onChange(of: returnToHomeTrigger) { _, _ in
    selectedMenuTab = .home      // drugi handler tego samego triggera
}
```

Oba handlery odpalają się dla tej samej zmiany `@AppStorage`. Kiedy użytkownik tapnie tab `.home` będąc już na `.home` (`handleMenuTabTap` w ContentView.swift:249 robi `returnToHomeTrigger += 1`), lub kiedy onboarding się kończy (`relaunchOnboarding()` w SettingsView.swift:659), NavigationStack jest jednocześnie niszczony przez `navigationResetID = UUID()` I ustawiany na `.home` przez drugi handler. Praktyczny efekt: animacja resetu NavigationStacka pojawia się dwa razy jeśli SwiftUI przetworzy zmiany w dwóch cyklach renderowania, lub widok "migocze" przy powrocie do home. Nie jest to crash, ale powoduje wizualny artefakt.

**Naprawa:** Usunąć handler w ContentView (który jest bardziej agresywny — niszczy cały stack) lub skoordynować oba handlery w jednym miejscu. Jeśli intent `returnToHomeTrigger` to "wróć do ekranu home i zresetuj stos", wystarczy jeden handler w ContentView.

---

### S-2: `parseGrams(from:)` obcina część dziesiętną — błędne wagi w UI

**Plik:** `BrothResultView.swift:1832`

```swift
private func parseGrams(from text: String) -> Int {
    let digits = text.filter { $0.isNumber }
    return Int(digits) ?? 0
}
```

`.filter { $0.isNumber }` zatrzymuje tylko cyfry, usuwając `.` i `,`. Waga wyświetlana jako `"12.5 g"` zostanie sparsowana jako `125` zamiast `12`. Identyczny pattern istnieje w `CookingModeView.vegetableReminderRows` (`CookingModeView.swift:291`): `Int((item.amount.filter { $0.isNumber }))`.

Choć wyniki kalkulatora są całkowitoliczbowe (grams: Int), string "12.5 g" może pojawić się w overridach edytowanych przez użytkownika lub w wartościach wyliczanych przez BrothCalculator (który używa formatu `"%.1f g"`). Skutek: użytkownik wprowadza 12 g, parser widzi 120 lub 125, wariant "dodaj sól" dostaje 10× wartość.

**Naprawa:**
```swift
private func parseGrams(from text: String) -> Int {
    let cleaned = text.trimmingCharacters(in: .whitespaces)
    // usuń jednostkę, weź pierwszą liczbę
    let numericPart = cleaned.components(separatedBy: CharacterSet.decimalDigits.inverted)
                              .joined()
    return Int(numericPart) ?? 0
}
// Lub prościej: Double(text.filter { $0.isNumber || $0 == "." || $0 == "," }.replacingOccurrences(of: ",", with: ".")).map(Int.init) ?? 0
```

---

### S-3: `BatchRecord.calculationResult()` zawsze używa BrothCalculator dla UltraSpec batchy

**Plik:** `BatchRecord.swift:542`

```swift
func calculationResult(potSizeLiters: Int) -> BrothCalculationResult {
    if let snapshot = selectedIngredientsSnapshot, !snapshot.isEmpty {
        // ...
        return BrothCalculator.calculate(profile: brothProfile, meatItems: selections, ...)
    }
    return BrothCalculator.calculate(style: ..., totalWeightGrams: totalWeightGrams, ...)
}
```

Ta metoda jest wywoływana w dwóch krytycznych miejscach:

1. `HomeView.activeCookingBanner` (`ContentView.swift:264`): `let result = batch.calculationResult(potSizeLiters: potSizeLiters)` — baner aktywnego gotowania dla UltraSpec rosołu (np. ramenShio) dostaje legacy wyniki BrothCalculator.

2. `HomeView.body.navigationDestination` przy deep linku (`ContentView.swift:211`): `result: deepLinkBatch.calculationResult(potSizeLiters: potSizeLiters)` — CookingModeView otwarte z deep linku (np. `rosolek://cooking?batchID=…`) dostaje błędne `result` dla wszystkich UltraSpec batchy.

Konsekwencja: czas gotowania, ilość wody, warzywa, przyprawy wyświetlane w CookingModeView otwartym przez baner lub deep link są obliczone przez stary kalkulator, nie przez UltraSpec. Różnice mogą być znaczne (np. tonkotsu ma 4h 30min vs rosół lekki 3h).

**Naprawa:** Dodać do `BatchRecord` metodę `ultraSpecCalculationResult()` która rozpoznaje `modeRawValue == "custom"` + `brothKindRawValue != nil` i wywołuje `UltraSpecBridge.calculateFromCurrentFlow()`. Fallback na BrothCalculator dla legacy batchy.

---

### S-4: `previewResult` w IngredientSelectionView — kalkulator na każdym renderze

**Plik:** `IngredientSelectionView.swift:366`

```swift
private var previewResult: BrothCalculationResult {
    guard let variant = activeUltraVariant else {
        return BrothCalculator.calculate(...)
    }
    // throws UltraSpecEngine.calculate() inside
    let ultra = try UltraSpecBridge.calculateFromCurrentFlow(...)
    ...
}
```

`previewResult` to computed property (nie cached), wywoływana przez widok podglądu ilekroć SwiftUI re-renderuje widok (np. przy każdym naciśnięciu klawisza w polu wagi). Dla UltraSpec wariantów uruchamia pełny silnik. Analogicznie, pięć computed properties `HomeView.poultryPresetRecipe` etc. (`ContentView.swift:61–94`) wywołuje `BrothCalculator.calculate()` przy każdym renderze HomeView.

To nie jest crash, ale wpływa na płynność UI na starszych urządzeniach. Problem o niższym priorytecie niż S-1..S-3, ale znany z poprzedniego audytu jako H-1 — w IngredientSelectionView nie został naprawiony.

---

## Ścieżki użytkownika — analiza

### Flow A: Nowy rosół (preset) od HomeView do CookingModeView

1. `HomeView.readyRecipesSection` renderuje `filteredPresetItems` (`ContentView.swift:305`)
2. Każdy item to `NavigationLink` → `BrothResultView(preset:potSizeLiters:)` (`ContentView.swift:310`)
3. `BrothResultView.init(preset:)` wywołuje `BrothCalculator.calculate()` **w init** (`BrothResultView.swift:64`) — kalkulator odpala się zanim widok się pojawi
4. W `onAppear` ustawiany jest `frozenResult` (`BrothResultView.swift:~149`) — poprawne zabezpieczenie przed późniejszymi przeliczeniami
5. Użytkownik klika "Start gotowania" → `BatchStore.createBatch()` → `CookingModeView`
6. `CookingModeView.startCookingFromPrep()` ustawia `phaseIndex = 1` (`CookingModeView.swift:1623`) — phase 0 (prep) jest pominięta

**Problem:** Wyliczenie w `init` jest redudantne (jest ponawiane w `onAppear` przez `computeCurrentResult()`). Nieszkodliwe, ale nieelegancie.

---

### Flow B: Custom rosół przez IngredientSelectionView → BrothResultView

1. `BrothStyleSelectionView` → wybór kind + style → `IngredientSelectionView`
2. `IngredientSelectionView.previewResult` liczy wynik **na każdym renderze** (S-4)
3. "Dalej" → `BrothResultView(profile:selections:selectedKind:selectedStyleName:)`
4. `computeCurrentResult()` w BrothResultView rozpoznaje `selectedKind != nil` → wywołuje UltraSpecBridge → prawidłowy wynik
5. Zapis batcha → `CookingModeView`
6. **Problem:** Przy powrocie do home przez deep link lub baner aktywnego gotowania, CookingModeView dostaje wynik z BrothCalculator (S-3)

---

### Flow C: Powrót do aktywnego gotowania (baner / deep link)

**Baner:** `HomeView.activeCookingBanner` (`ContentView.swift:260`):
```swift
let result = batch.calculationResult(potSizeLiters: potSizeLiters)  // zawsze legacy
NavigationLink { CookingModeView(batch: batch, result: result, ...) }
```

**Deep link** `rosolek://cooking?batchID=UUID` → `RosolekApp.onOpenURL` → `router.routeToActiveCooking(batchID:)` → `HomeView.handlePendingHomeRoute()` → `navigateToDeepLinkedCooking = true` → `navigationDestination`:
```swift
CookingModeView(
    batch: deepLinkBatch,
    result: deepLinkBatch.calculationResult(potSizeLiters: potSizeLiters),  // zawsze legacy
    ...
)
```

Oba ścieżki dotknięte S-3. CookingModeView wewnętrznie używa `activeUltraVariant` do renderowania UltraSpec timeline i kroków, ale `result` przekazany jako parametr pochodzi z BrothCalculator — niezgodność.

---

### Flow D: Ocena (feedback) po gotowaniu

1. `CookingModeView` → "Zakończ gotowanie" → `BatchFeedbackView`
2. Slider `1...10` + opcjonalne pola → "Zapisz"
3. `batchStore.updateFeedback()` (`BatchStore.swift:121`) — poprawnie clampuje rating
4. Po zapisie → powrót do HomeView

Ten flow jest poprawny. Brak bugów.

---

### Flow E: Ustawienia → zmiana rozmiaru garnka

1. `SettingsView` → edycja garnka → `savePot()` zapisuje do `@AppStorage("potSizeLiters")`
2. Wszystkie widoki z `@AppStorage("potSizeLiters")` odświeżają się automatycznie
3. `BrothResultView` otwarte *przed* zmianą: `potSizeLiters` to `@AppStorage` bezpośrednio używany w `computeCurrentResult()`. `frozenResult` ustawiony w `onAppear` nie reaguje na zmianę `potSizeLiters` — użytkownik musi wyjść i wrócić. **To jest zamierzone** (per komentarz z poprzedniego audytu H-1).
4. **Deprecated API:** `onChange(of: customPotSize) { newValue in` (`SettingsView.swift:76`) używa jednoparametrowego closure — deprecated od iOS 17. Kompiluje się z ostrzeżeniem, ale należy zaktualizować do `{ _, newValue in }`.

---

## Edge cases i bugi

### E-1: `parseGrams` — corruptuje wagi dziesiętne

**Plik:** `BrothResultView.swift:1832`, `CookingModeView.swift:291`  
Opisane w S-2.

### E-2: `finish_clear` mapuje do `.stabilization` — semantycznie błędne

**Plik:** `CookingModeView.swift:772`

```swift
case "stabilize_base", "tonkotsu_boil_emulsify", "finish_clear", "veg_simmer_limit", "fish_poach_limit":
    return .stabilization
```

`finish_clear` to krok klarowania (np. papierowy filtr lub egg raft) po gotowaniu właściwym — nie jest etapem stabilizacji. Powoduje że Live Activity i UI w fazie klarowania wyświetlają ikonę/kolor "stabilizacji" zamiast "klarowania". Wizualny błąd, nie crash.

### E-3: `"porcja_rosolowa_drobiowa"` — mapowanie *jest* poprawne, poprzedni raport miał błąd

**Plik:** `UltraSpecVariantMapping.swift:60`

```swift
case "porcja_rosolowa_drobiowa": return "POULTRY_SOUP_MIX"
```

Poprzednia analiza (etap kompaktowania) błędnie sygnalizowała brak tego case. Mapping istnieje. `POULTRY_SOUP_MIX` jest w katalogu (`UltraSpecCatalog.swift`). Brak buga.

### E-4: `cascadesReturnHome()` — martwy kod

**Plik:** `NavigationHelpers.swift:22`

```swift
extension View {
    func cascadesReturnHome() -> some View { self }
}
```

Funkcja jest no-opem. Nie jest wywołana w żadnym miejscu produkcyjnym (poza ewentualnymi komentarzami). Może być placeholderem po refaktorze. Należy usunąć lub zaimplementować.

### E-5: `syntheticSelections()` — błędne wagi przy odtwarzaniu legacy batchy

**Plik:** `BrothResultView.swift:~1468`

Gdy batch nie ma `selectedIngredientsSnapshot` (starsze batche przed tą funkcją), `syntheticSelections()` rozkłada `totalWeightGrams` równo między `selectedIngredientIDs`. Jeśli użytkownik dodał 1000 g kury + 300 g szpondra, synthetyczne odtworzenie przypisze 650 g każdemu — inne wyniki kalkulatora niż oryginalne. Nie jest to nowy bug (istniał przed audytem), ale warto odnotować.

### E-6: Timer w CookingModeView nigdy nie jest explicite anulowany

**Plik:** `CookingModeView.swift:183`

```swift
private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
```

Timer jako stored property startuje przy inicjalizacji widoku i tyka przez cały czas życia widoku (w tym gdy `isStageRunning == false` lub `isFinished == true`). `onReceive(timer)` ma guard na te warunki, więc ticki są no-opami — brak side-effectu, ale timer zużywa zasoby. SwiftUI powinien anulować timer przy `onDisappear` przez dealokację widoku, ale przy NavigationStack (który preloads destinacje) czas życia widoku jest nieoczywisty. Niski priorytet, ale warto użyć `timer.upstream.connect()` z `@State` i kontrolować manualnie.

### E-7: Deprecated `onChange` w SettingsView

**Plik:** `SettingsView.swift:76`

```swift
.onChange(of: customPotSize) { newValue in
```

iOS 17 wymaga dwuparametrowego closure: `{ oldValue, newValue in }`. Jednoparametrowa forma jest deprecated. Kompiluje się z ostrzeżeniem, w przyszłej wersji Xcode/iOS może zostać usunięta.

### E-8: `HomeView.activeCookingBanner` — licznik czasu się nie aktualizuje

**Plik:** `ContentView.swift:260`

`ActiveCookingBannerLabel(session: session)` renderuje countdown bazując na `session.overallRemainingSeconds` z momentu załadowania. Baner jest wrappowany w `TimelineView(.periodic(from:by:))` (w `FloatingHomeMenuBar` lub w `ActiveCookingBannerLabel` — zależy od implementacji), ale `activeCookingSession` jest ładowane tylko w `onAppear` i `didBecomeActiveNotification`. Jeśli app jest na foreground i użytkownik patrzyna home screen, baner może pokazywać stały czas bez odliczania. Zależy od implementacji `ActiveCookingBannerLabel` (nie czytany bezpośrednio).

### E-9: `startCookingFromPrep()` ustawia `phaseIndex = 1` — pomija phase 0

**Plik:** `CookingModeView.swift:1623`

```swift
phaseIndex = 1
```

Phase 0 to checklist przygotowawczy. Przeskok do phase 1 jest zamierzony (użytkownik zatwierdził checklistę). Nie jest to bug funkcjonalny, ale warto by `phases[0]` był jawnie oznaczony jako `.prep` i nigdy nie był "aktywny" jako krok gotowania.

---

## Jakość kodu

### Duplikacja kodu

**normalize() vs normalizeCookingID():**  
`BrothResultView.swift` zawiera lokalną funkcję `normalize()` (diacriticsInsensitive + lowercased). Identyczna funkcja `normalizeCookingID()` istnieje w `CookingModeView.swift:1948`. Żadna z nich nie jest częścią shared utility — duplikacja.

**parseGrams() pojawia się dwa razy:**  
W `BrothResultView.swift:1832` i jako inline `Int((item.amount.filter { $0.isNumber }))` w `CookingModeView.swift:291`. Należy wyciągnąć do extension `String.extractGrams() -> Int`.

### Magiczne stałe bez nazw

`CookingModeView.swift:76`: displacement factor `0.55`, foamReserve `0.12`, safetyReserve `0.08`, yieldFactor — wszystkie są zdefiniowane jako literały inline w UltraSpecEngine. W UltraSpecCatalog są per-variant skonfigurowane, ale ogólne stałe fizyczne (displacement) są hardkodowane.

### Zbyt duże pliki

- `CookingModeView.swift`: 4193 linie — trudny w nawigacji. Można wydzielić `CookingModeViewPrep`, `CookingModeViewPhaseControls`, `CookingModeViewBackground`.
- `BrothResultView.swift`: 1862 linie.
- `ContentView.swift`: 2517 linie.

### AppStorage semantics

`returnToHomeTrigger` jest `@AppStorage`, co oznacza że persystuje między sesjami app. Przy restarcie aplikacji, jeśli wartość była > 0, oba handlery odpalą się przy pierwszym renderze. Dla mechanizmu "jednorazowego triggera" powinien być `@State` przekazywany przez EnvironmentObject, nie UserDefaults.

### `HomePresetRecipe.init` w computed properties

Pięć computed properties w HomeView (`poultryPresetRecipe`, `poultryBeefPresetRecipe`, etc.) tworzy `HomePresetRecipe` za każdym razem (który wywołuje `BrothCalculator.calculate()`). Powinny być `let` w `init` lub `lazy var`, albo wyliczane raz przez `@StateObject`.

---

## Testy — ocena

### Co istnieje

| Plik testowy | Testy | Ocena |
|---|---|---|
| `UltraSpecEngineTests.swift` | 7 | Dobre: pokrywa UNDERPOWER, OVERPOWER, WINGS/BEEF/OFFAL, hardNoBase, hardPotTooSmall |
| `UltraSpecEdgeCaseTests.swift` | 10 | Bardzo dobre: granice pot (0.25, 30), hardNotFit, veggie variants, yield sanity, paper filter, delta non-negative, unknown ID |
| `BatchStoreTests.swift` | 11 | Dobre: CRUD, feedback, title normalizacja, sort, roundtrip, recovery — pełne pokrycie C-1 |
| `CookingSessionTests.swift` | 5 | Dobre: save/load, clear, overwrite, garbled, backgroundedAt |
| `UltraSpecVariantMappingTests.swift` | 8 | Dobre: resolver, bridge, ID mapping łącznie z kaczką/indykiem |
| `UltraSpecTimelineTests.swift` | 3 | Minimalny: tonkotsu stage, every step has drawer, fish duration |
| `UltraSpecStepLibraryTests.swift` | 3 | Minimalny: klucze biblioteki |
| `RosolekTests.swift` | 2 | Podstawowy: Codable roundtrip BatchRecord + pusty performance test |

### Czego brakuje

1. **Brak testów `UltraSpecRequestBuilder.mapIngredientID` dla porcja_rosolowa_drobiowa:** Mapping jest poprawny, ale nie ma testu dla tego konkretnego case.

2. **Brak testów `BrothCalculator`:** Legacy kalkulator (2568 linii) nie ma żadnego testu. Zmiany regressionowe są niewidoczne.

3. **Brak testów `BatchRecord.calculationResult()`:** Bug S-3 (błędny kalkulator dla UltraSpec batchy) mógłby być wykryty przez test który sprawdza że UltraSpec batch używa UltraSpecEngine.

4. **Brak testów UI/Integration:** Nie ma żadnych `XCTestCase` dla widoków. `IngredientSelectionView.previewResult` i `BrothResultView.computeCurrentResult()` nie są testowane.

5. **Brak testu dla `parseGrams()`:** Bug S-2 mógłby być wykryty przez prosty unit test `XCTAssertEqual(parseGrams("12.5 g"), 12)`.

6. **`UltraSpecTimelineTests.testFishDelicateTimelineDurationEndsAt45`:** Test sprawdza ostatni minuteOffset == 45. Zmiana timeline złamie test, ale test nie weryfikuje kompletności kroków — jest kruchy.

7. **Wydajność `previewResult`:** Brak testów `measure {}` dla IngredientSelectionView.

### Jakość istniejących testów

Pozytywne: testy są deterministyczne, nie zależą od sieci, właściwie czyszczą UserDefaults w tearDown. UltraSpecEdgeCaseTests jest wzorcowo napisany (graniczne wartości, fizyczne niezmienniki). Negatywne: `RosolekTests.swift` zawiera pusty `testPerformanceExample()` z boilerplate który nie testuje niczego produkcyjnego.

---

## Priorytetowa lista napraw

### CRITICAL (blokuje poprawność funkcji)

Brak — wszystkie CRITICAL z Etapu 1 naprawione.

### HIGH (wpływa na użytkownika, do naprawy w Etapie 2)

**H-1: S-3 — BatchRecord.calculationResult() używa BrothCalculator dla UltraSpec batchy**  
Plik: `BatchRecord.swift:542`  
Dodać ścieżkę rozpoznającą `modeRawValue == "custom"` + `brothKindRawValue != nil` i wywołującą UltraSpecBridge. Fallback na legacy BrothCalculator.

**H-2: S-2 — parseGrams() obcina wartości dziesiętne**  
Pliki: `BrothResultView.swift:1832`, `CookingModeView.swift:291`  
Poprawić parser: zamiast `filter { $0.isNumber }` użyć `Double(cleaned).map(Int.init)` z uwzględnieniem separatora.

**H-3: S-1 — Podwójny handler returnToHomeTrigger**  
Plik: `ContentView.swift:30,218`  
Skoordynować handlery — jeden powinien obsługiwać pełny reset. Rozważyć zmianę `returnToHomeTrigger` z `@AppStorage` na przekazywany `@State`/EnvironmentObject.

### MEDIUM (do naprawy przed Etap 3)

**M-1: S-4 — previewResult w IngredientSelectionView liczy na każdym renderze**  
Plik: `IngredientSelectionView.swift:366`  
Memoizować przez `@State var cachedPreviewResult` i obliczać tylko przy zmianie selections/potSize.

**M-2: E-7 — Deprecated onChange w SettingsView**  
Plik: `SettingsView.swift:76`  
Zmienić na `{ _, newValue in }`.

**M-3: E-2 — finish_clear mapuje do .stabilization**  
Plik: `CookingModeView.swift:772`  
Dodać case `.clarifying` do `LivePhaseKind` lub zmapować `finish_clear` na `.rest` (semantycznie bliższe).

**M-4: returnToHomeTrigger jako @AppStorage**  
Plik: `SettingsView.swift:8`, `ContentView.swift:9`  
Zmienić na EnvironmentObject event lub `@State` na poziomie root — trigger nie powinien persistować.

**M-5: HomeView preset computed properties**  
Plik: `ContentView.swift:61–94`  
Zmienić na `let` obliczone raz, lub użyć `@State var presets` inicjalizowanego w `onAppear`.

### LOW (cleanup)

**L-1: E-4 — cascadesReturnHome() martwy kod**  
Plik: `NavigationHelpers.swift:22`  
Usunąć lub zaimplementować.

**L-2: E-6 — Timer nigdy nie anulowany explicite**  
Plik: `CookingModeView.swift:183`  
Rozważyć użycie `Cancellable` z `@State` i manualną kontrolę.

**L-3: Duplikacja normalize()/normalizeCookingID()**  
Pliki: `BrothResultView.swift`, `CookingModeView.swift:1948`  
Wyciągnąć do `String+Rosolek.swift` extension.

**L-4: Dodać testy jednostkowe BrothCalculator**  
Plik: nowy `BrothCalculatorTests.swift`  
Minimum: test granicznych wartości, test że wynik jest finite dla wszystkich presetów.

**L-5: Dodać test parseGrams()**  
Plik: nowy lub rozszerzony `RosolekTests.swift`  
`XCTAssertEqual(parseGrams("12.5 g"), 12)`  
`XCTAssertEqual(parseGrams("1 000 g"), 1000)` (spacja)

---

*Raport obejmuje wszystkie 30 plików źródłowych i 8 plików testowych. Każdy problem ma referencję plik:linia. Analiza statyczna — build nie był możliwy w środowisku Linux.*

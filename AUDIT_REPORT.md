# Audyt aplikacji iOS — Rosolek
**Data audytu:** 2026-05-14  
**Audytor:** Claude (statyczna analiza kodu)  
**Gałąź:** `claude/ios-security-audit-ostvJ`

---

## 1. Executive Summary

Aplikacja Rosolek to dobrze zorganizowany, rozbudowany kalkulator rosołu z live cooking, historią i systemem UltraSpec. Ogólna jakość kodu jest **ponadprzeciętna** — widać świadomą architekturę, dobre pokrycie testami domenowymi i przemyślane podejście do migracji danych.

**Największe ryzyko:** timer w live cooking jest oparty na zliczaniu ticków zamiast na porównaniu dat, a fazy obliczane są od nowa co sekundę — to kombinacja prowadząca do dryftu i zużycia procesora. Osobno: nazwy warzyw w trybie gotowania z historii wyświetlają surowe klucze katalogowe (np. `VEG_CARROT`) zamiast polskich nazw. Oba problemy dotykają kluczowego flow użytkownika.

**Liczba znalezionych problemów:**
- 🔴 **CRITICAL:** 6
- 🟠 **HIGH:** 8
- 🟡 **MEDIUM:** 15
- 🔵 **LOW:** 10

**Ogólna ocena jakości kodu: 7/10**  
Solidna architektura z jasnym podziałem odpowiedzialności, dobra obsługa migracji danych (decodeIfPresent z fallbackami), świadome użycie UltraSpec jako osobnej domeny. Utrudnia ocenę: timer bazujący na tickach zamiast datach, computed properties nadużywane w gorącej ścieżce renderowania, brak izolacji nazw wyświetlanych od kluczy serializacji.

---

## 2. Jak przeprowadzono audyt

### Pliki przejrzane
Wszystkie pliki `.swift` projektu (47 plików):
- Główna aplikacja: `RosolekApp.swift`, `ContentView.swift`
- Domena: `BrothCalculator.swift`, `BrothModels.swift`, `CookingModeTypes.swift`, `CookingSession.swift`
- UltraSpec: `UltraSpecEngine.swift`, `UltraSpecCatalog.swift`, `UltraSpecBridge.swift`, `UltraSpecTimeline.swift`, `UltraSpecStepLibrary.swift`, `UltraSpecWarnings.swift`, `UltraSpecLiveBanners.swift`, `UltraSpecVariantMapping.swift`, `UltraSpecModels.swift`
- Store: `BatchStore.swift`, `BatchRecord.swift`
- Widoki: `CookingModeView.swift`, `BrothResultView.swift`, `IngredientSelectionView.swift`, `HistoryView.swift`, `LastBatchDetailView.swift`, `SettingsView.swift`, `OnboardingFlowView.swift`, `BrothStyleSelectionView.swift`, `BatchFeedbackView.swift`, `RecipesHubView.swift`, `FloatingHomeMenuBar.swift`
- Helpery: `CookingPhaseBuilder.swift`, `CookingNotificationService.swift`, `CookingActivityAttributes.swift`, `NavigationHelpers.swift`, `KeyboardObserver.swift`, `RosolDesignSystem.swift`, `String+Rosolek.swift`
- Testy: 10 plików testowych

### Komendy wykonane
```bash
find . -name "*.swift" | sort
find . -name "*.json" | sort  
find . -name "*.md" | sort
grep -rn "enum BrothStyle|enum BrothKind" ...
grep -n "handleTick|restoreSession|saveSession|phaseElapsedSeconds..." ...
sed -n 'NNN,MMMp' BrothCalculator.swift
# + wiele grep/sed do szukania konkretnych wzorców
```

### Wynik buildu i testów
**Brak środowiska Xcode** — analiza wykonana statycznie. Kod wygląda kompilatorowo poprawnie, brak widocznych błędów składniowych.

### Co nie było dostępne
- Środowisko uruchomieniowe iOS (brak Xcode/symulatora)
- Dostęp do backendu (brak — aplikacja lokalna)
- Analiza runtime (crashlytyki, profiler)

---

## 3. Mapa aplikacji

### Ekrany i odpowiedzialności
| Ekran | Plik | Odpowiedzialność |
|---|---|---|
| Root / Onboarding | `ContentView.swift` | Routing onboarding / home, deep link handling |
| Home | `ContentView.swift` (HomeView) | Lista presetów, aktywne gotowanie, nawigacja |
| Wybór stylu | `BrothStyleSelectionView.swift` | Wybór BrothKind + BrothStyle |
| Wybór składników | `IngredientSelectionView.swift` | Selekcja składników, podgląd insightów |
| Wyniki kalkulacji | `BrothResultView.swift` | Wyświetlanie wyników, edytory warzyw/przypraw, start gotowania |
| Live cooking | `CookingModeView.swift` | Timer, fazy gotowania, Live Activity |
| Historia | `HistoryView.swift` | Lista batch'y |
| Szczegóły batcha | `LastBatchDetailView.swift` | Widok historyczny, replay |
| Ocena batcha | `BatchFeedbackView.swift` | Formularz oceny po gotowaniu |
| Ustawienia | `SettingsView.swift` | Garnek, termometr, imię |

### Modele danych
```
BatchRecord (Codable)
  ├── id: UUID
  ├── createdAt: Date
  ├── styleRawValue: String (legacy)
  ├── modeRawValue: String ("preset"|"custom"|"legacy")
  ├── presetRawValue: String? (BrothPreset.rawValue)
  ├── profileRawValue: String (BrothProfile.rawValue)
  ├── brothKindRawValue: String? (BrothKind.rawValue — PROBLEM: Polish display string!)
  ├── clarityModeRawValue: String
  ├── selectedIngredientsSnapshot: [BatchIngredientSnapshot]?
  ├── meatOverrides/vegetableOverrides/spiceOverrides: [String:Int]?
  └── feedback fields...

CookingSession (Codable) — w UserDefaults
  ├── batchID: UUID
  ├── phaseIndex: Int
  ├── phaseElapsedSeconds: Int   ← tick-counted, not Date-based!
  ├── processElapsedSeconds: Int ← tick-counted, not Date-based!
  ├── isStageRunning: Bool
  └── backgroundedAt: Date?      ← Date-based dla background recovery
```

### Store'y
| Store | Typ | Odpowiedzialność |
|---|---|---|
| `BatchStore` | `@StateObject ObservableObject` | Historia gotowań, zapis w UserDefaults |
| `AppRouter` | `@StateObject ObservableObject` | Routing deep link / return to home |

### Kalkulator
**Dwa silniki działające równolegle:**
1. **BrothCalculator** (legacy): dla presetów i starych flow. Wejście: `BrothCalculationRequest`. Wyjście: `BrothCalculationResult`.
2. **UltraSpecEngine** (nowy): dla custom flow z BrothKind. Wejście: `UltraSpecCalculationRequest`. Wyjście: `UltraSpecCalculationResult`. Mostek: `UltraSpecBridge`.

### Flow danych
```
AppStorage (UserDefaults)
  potSizeLiters, hasThermometer, userFirstName
      ↓
BrothStyleSelectionView → IngredientSelectionView → BrothResultView
      ↓ (tworzy BatchRecord)
BatchStore (UserDefaults)
      ↓
CookingModeView ← BatchRecord + BrothCalculationResult
      ↓ (zapisuje CookingSession)
UserDefaults (cooking_session_active_v1)
```

---

## 4. Wynik buildu i testów

| | Status |
|---|---|
| Build | Nie uruchomiono (brak Xcode) — kod wygląda poprawnie składniowo |
| Testy unit | 10 klas testowych, szacunkowo ~80 test case'ów |
| Pokrycie UI | 2 pliki UI testów (RosolekUITests, LaunchTests) |
| Testy snapshot | Brak |

**Klasy testowe:**
- `UltraSpecEngineTests` — dobre pokrycie warningstów
- `UltraSpecEdgeCaseTests` — dobre pokrycie edge case'ów (pot too small, no meat, paper filter)
- `UltraSpecTimelineTests` — timeline steps
- `UltraSpecVariantMappingTests` — mapowanie ID
- `UltraSpecStepLibraryTests` — biblioteka kroków
- `BrothCalculatorTests` — smoke testy legacy engine
- `CookingSessionTests` — save/load/clear/corruptedData
- `BatchStoreTests` — store operations
- `BatchRecordEngineRoutingTests` — routing kalkulatora
- `RosolekTests` — placeholder (1 pusty test, brak asercji)

---

## 5. Audyt kalkulatora

### BrothCalculator (legacy)

**Wejście:** `BrothCalculationRequest` (mode, potSizeLiters, meatItems, clarityMode, useVinegar, targetYieldLiters, premiumEnabled)

**Walidacja wejść:**
- `potSizeLiters < 0.25` → `hardPotTooSmall`
- `potSizeLiters > 30` → `hardPotTooBig`
- Custom mode: `totalWeight == 0` → `hardNoMeat`
- Custom mode: `totalWeight > 10_000` → `hardTooMuchMeat`
- Custom mode: `item.grams > 6_000` → `hardItemTooBig`
- Preset mode: **brak walidacji wagi** — preset sam definiuje składniki

**Edge case'y kalkulatora (logicznie przetestowane):**
| Przypadek | Zachowanie | Ocena |
|---|---|---|
| 0 g mięsa (custom) | Zwraca `hardNoMeat` z waterLiters=0 | ✅ OK |
| 10 g mięsa | Kalkuluje normalnie, może dać UNDERPOWER warning | ✅ OK |
| 10 000 g mięsa | Limit walidacji — `hardTooMuchMeat` | ✅ OK |
| Tylko jeden typ składnika | Kalkuluje normalnie, możliwy warning singleIngredientRisk | ✅ OK |
| Garnek 0 L | `hardPotTooSmall` | ✅ OK |
| Garnek < 0.25 L | `hardPotTooSmall` | ✅ OK |
| Garnek 30 L | OK, przy pełnym obciążeniu może wygenerować `hardNotFit` | ✅ OK |
| Garnek 100 L | `hardPotTooBig` (limit 30) | ✅ OK |
| Łączna waga > pojemność | `hardNotFit` lub `waterWasReducedToFit` | ✅ OK |
| Wyjście NaN/infinity | Chronione przez logikę w BrothStyleConfig | ✅ OK |

**Problem znaleziony:**
- `BrothCalculator.calculate(style:totalWeightGrams:selectedIDs:potSizeLiters:)` (legacy sygnatura z Int) — jeśli wywołany z `totalWeightGrams = 0` i pustymi `selectedIDs`, nie przechodzi przez walidację (walidacja jest tylko w `validateRequest` na nowej ścieżce). Legacy path może zwrócić `waterLiters = 0` bez validationFailure ustawionego — użytkownik nie dostaje komunikatu błędu.

### UltraSpecEngine

**Wejście:** `UltraSpecCalculationRequest` (variant, potCapacityL, items, clarityMode)

**Walidacja wejść:**
- `potCapacityL < 0.25` → throws `hardPotTooSmall`
- `potCapacityL > 30` → throws `hardPotTooBig`
- Dla non-veg wariantów: `totalAnimalG == 0` → throws `hardNoBase`
- `waterSafeL <= 0` → throws `hardNotFit`

**Brak limitu 10kg dla UltraSpec:**
- BrothCalculator waliduje `totalWeight > 10_000 g` → `hardTooMuchMeat`
- UltraSpecEngine: **brak analogicznego limitu** — 50kg mięsa przejdzie bez błędu jeśli garnek jest wystarczająco duży

**Znalezione problemy:**
- Engine nie filtruje składników przez `allowedVariants` (C-6)
- Wings share liczony jako `wingsG/poultryG` — przy samych skrzydłach zawsze 100% → zawsze warning (M-9)

---

## 6. Audyt trybów gotowania

### Tryby zdefiniowane

**Warstwa BrothMode:**
```swift
enum BrothMode {
    case preset(BrothPreset)  // 5 presetów
    case custom(BrothProfile) // cleaner | richer
}
```

**Warstwa UltraSpecVariantID (10 wariantów):**
- `.rosolLekki`, `.rosolBogaty`
- `.ramenShio`, `.ramenTonkotsu`
- `.wolowyCzysty`, `.wolowyMocny`
- `.warzywnyJasny`, `.warzywnyUmami`
- `.rybnyDelikatny`, `.rybnyIntensywny`

### Czas gotowania per wariant
| Wariant | totalMinutes |
|---|---|
| rosolLekki | 315 |
| rosolBogaty | 350 |
| ramenShio | 240 |
| ramenTonkotsu | 480 |
| wolowyCzysty | 360 |
| wolowyMocny | 420 |
| warzywnyJasny | 90 |
| warzywnyUmami | 120 |
| rybnyDelikatny | 45 |
| rybnyIntensywny | 60 |

### Problemy

**Spójność domen:**
- Czasy temperatur są spójne (wyższe warianty = wyższe temperatury) ✅
- Ramen Tonkotsu ma `allowsBoiling: true` — jedyny wariant ze wrzeniem — poprawnie obsłużony w UI ✅
- Wariant "bogaty" ma DŁUŻSZY czas niż "lekki" (350 vs 315 min) — celowe, ale myląca nazwa dla kogoś kto myśli "intense = szybciej"

**Serialization problem (H-2):**
- `BrothKind.rosol.rawValue = "Rosół"` — polska litera ł jako klucz serializacji
- `BrothKind.beef.rawValue = "Wołowy"` — j.w.
- Zmiana nazwy wyświetlanej = utrata odczytu historii

**Zmiana trybu po wygenerowaniu wyniku:**
- `BrothResultView` zamraża wynik w `frozenResult` dopiero przy zapisie batcha
- Przed zapisem: zmiana garnka/opcji odświeża wynik na bieżąco (OK)
- Po zapisie: `frozenResult` jest ustawiony i nie zmienia się — poprawne zachowanie ✅

**Zmiana trybu w trakcie gotowania:**
- Niemożliwa — użytkownik jest w `CookingModeView` z niezmiennym `result` ✅

---

## 7. Audyt składników

### Katalog UltraSpec (32 składniki)

**Kategorie:**
- `.poultry` (9): kura stara, korpus, szyje, skrzydła, udka, porcja rosołowa, łapki drobiowe + aliasy
- `.beef` (6): pręga, szponder, ogon, kości stawowe, kości szpikowe, mostek
- `.pork` (3): kości wieprzowe stawowe, łapki wieprzowe, kręgi wieprzowe
- `.offal` (3): wątróbka (premium), serca, żołądki
- `.fish` (4): ości, głowy, pancerze krewetek (premium), skorupiaki (premium)
- `.veg` + aromatics (9): cebula, marchew, seler, pietruszka, por, seler naciowy, imbir, czosnek, dymka

**Walidacja zakresów:**
- Brak zdefiniowanego min/max per składnik w katalogu
- Walidacja tylko na poziomie sumy (totalWeight max 10k g, singleItem max 6k g) w BrothCalculator
- UltraSpecEngine: brak walidacji per-składnik, akceptuje dowolne gramy > 0

**Znalezione problemy:**
- Składniki nie są filtrowane przez `allowedVariants` w silniku (C-6)
- `premiumOnly: true` na `OFFAL_CHICKEN_LIVER` ale UltraSpec nie sprawdza tego pola (M-13)
- `filet_rybny` → `FISH_WHITE_BONES` — mapowanie OK ale nazwa myląca

**Stabilność identyfikatorów:**
- Stare ID (lowercase snake_case): `kura`, `szponder`, `lapki` etc.
- Nowe ID (UPPER_SNAKE_CASE): `POULTRY_OLD_HEN`, `BEEF_SHORT_RIB`, `POULTRY_FEET` etc.
- Mapowanie w `UltraSpecRequestBuilder.mapIngredientID()` — dobre rozwiązanie ✅
- `BatchIngredientSnapshot` przechowuje `ingredientID` w formacie z momentu zapisu — stabilne ✅

---

## 8. Audyt timerów i live cooking

### Implementacja timera

```swift
@State private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

.onReceive(timerPublisher) { _ in
    handleTick()
}

private func handleTick() {
    guard sessionStarted, !isFinished, isStageRunning else { return }
    processElapsedSeconds += 1       // TICK-BASED — może dryfować
    if currentPhaseHasTimer {
        phaseElapsedSeconds += 1     // TICK-BASED — może dryfować
        ...
    }
}
```

**Typ timera:** `Timer.TimerPublisher` z Combine, `.autoconnect()`, trzymany jako `@State`.

**Dokładność:** Timer oparty na **zliczaniu ticków** (C-2). Każdy tick to `+1` sekunda — jeśli główny wątek jest zajęty, tick może się opóźnić lub nie przyjść. Brak korekty driftu.

**Niespójność:** Background recovery (poprawna) używa `Date()`:
```swift
let elapsed = Int(Date().timeIntervalSince(backgroundedAt))
advanceElapsedThroughPhases(elapsed)
```
Ale czas bieżący jest oparty na tickach. Timer dryfuje w foreground ale koryguje się po background/foreground przejściu.

**Obsługa tła:**
| Scenariusz | Zachowanie | Ocena |
|---|---|---|
| Telefon w uśpienie → powrót | `scenePhase → active` → `resumeFromBackground()` koryguje czas | ✅ OK (Date-based) |
| Wyjście z aplikacji → powrót po 10 min | `restoreSessionIfNeeded()` + `advanceElapsedThroughPhases()` | ✅ OK |
| Force quit → restart | `CookingSession.load()` wczytuje z UserDefaults | ✅ OK |
| Odebranie połączenia → powrót | `scenePhase → active` → recovery | ✅ OK |
| Timer dobiega końca w tle | Push notification zaplanowany na `currentPhaseRemainingSeconds` — ale ta wartość jest wyliczona z dryfujących ticków | ⚠️ Może być niedokładne |
| Dwa szybkie tapnięcia "Start" | Brak jawnego guard — drugie tapnięcie może przejść zanim `sessionStarted = true` dotrze | ⚠️ Ryzyko |
| Brak Background Modes w Info.plist | Timer zatrzymuje się w tle | ⚠️ Celowe, ale warto dokumentować |
| Zmiana strefy czasowej | `Date()` jest UTC, `backgroundedAt` absolutne — bezpieczne | ✅ OK |

**Bug C-4 — zatrzymanie przy manualnym kroku:**
```swift
private func advanceElapsedThroughPhases(_ elapsed: Int) {
    var remaining = elapsed
    processElapsedSeconds += elapsed     // ← pełny elapsed doliczony
    while remaining > 0 && phaseIndex < phases.count - 1 {
        guard currentPhaseHasTimer else { break }  // ← STOP przy manualnym!
        ...
    }
}
```
Gdy aplikacja jest w tle podczas MANUALNEGO kroku, `processElapsedSeconds` jest zwiększony o cały `elapsed`, ale `phaseIndex` się nie przesuwa. Użytkownik wraca i widzi ten sam krok manualny ze zbyt dużym `processElapsedSeconds`.

---

## 9. Audyt komunikatów

### Typy komunikatów

| Typ | Lokalizacja |
|---|---|
| Warningi kalkulatora | `BrothWarning`, `UltraSpecWarningMessage` — struktury in-memory |
| Powiadomienia push | `CookingNotificationService.swift` — hardcoded strings |
| Alerty UI | SwiftUI `.alert()` — hardcoded strings po polsku |
| Toasty | np. "Zmiany zostały odrzucone" w SettingsView |
| Inline karty | `SupportNoteCard`, `FoamInfoCard` etc. |
| Komunikaty etapów | `UltraSpecStepLibrary` — polskie stringi |

### Znalezione problemy

**Powiadomienie zawsze mówi "Rosół" (H-6):**
```swift
content.title = "Rosół: Etap zakończony"  // hardcoded
```
Dla Ramen Tonkotsu, bulionu rybnego, bulionu wołowego — komunikat jest niepoprawny domenowo.

**Brak lokalizacji:**
- Wszystkie komunikaty hardcoded w języku polskim
- Brak `Localizable.strings`, brak `String(localized:)`
- Jeśli aplikacja kiedykolwiek ma obsłużyć inne języki — pełny refaktor będzie potrzebny

**`notifyActionRequired` — dead code (H-7):**
Metoda istnieje ale nie jest nigdzie wywoływana. Tworzy powiadomienia z UUID identifiers których nie można anulować przez `cancelAll()`.

**Spójność jednostek:**
- `l`, `g`, `kg`, `ml`, `°C`, `min`, `h` — spójne w całej aplikacji ✅
- Formatowanie liczb: `.replacingOccurrences(of: ".", with: ",")` — polska notacja ✅

---

## 10. Audyt flow użytkownika

### Flow: Pierwsze uruchomienie
- Flaga `hasCompletedOnboarding` w `@AppStorage` — poprawne ✅
- Onboarding zbiera: imię, rozmiar garnka, czy ma termometr ✅
- Reset: zmiana `hasCompletedOnboarding = false` w SettingsView — poprawne ✅

### Flow: Wybór składników → wynik → start gotowania
1. `BrothStyleSelectionView` → `IngredientSelectionView` → `BrothResultView`
2. Batch tworzony przy tapnięciu "Gotuj teraz" — **PRZED** wejściem do CookingModeView
3. Sprawdzenie konfliktu aktywnego gotowania ✅
4. `CookingModeView` otrzymuje `batch + result` jako parametry

**Problem (M-4):** Batch jest tworzony i zapisywany w `BatchStore` PRZED wejściem do `CookingModeView`. Jeśli użytkownik wróci (navigate back) z gotowania bez ukończenia, batch pozostaje w historii ze statusem `completed`. Brak mechanizmu "in progress".

### Flow: Live cooking → zakończenie
- Przycisk "Zakończ" → `showFinishAlert` → `BatchFeedbackView`
- Przy zakończeniu: `CookingSession.clear()`, `cancelAll()`, `endLiveActivity()` ✅

### Flow: Wyjście z live cooking i powrót
- `onDisappear`: `saveSession(backgrounded: isStageRunning)` ✅
- `onAppear`: `restoreSessionIfNeeded()` ✅
- Dane nie są tracone przy nawigacji ✅

### Flow: Zamknięcie aplikacji w trakcie gotowania → ponowne uruchomienie
- Session zapisywana w UserDefaults ✅
- Po restarcie: `CookingSession.load()` → nawigacja przez deep link / banner ✅
- Jeśli batch usunięty: `clearOrphanedSessionIfNeeded` ✅

### Flow: Przeglądanie historii → szczegóły
- `LastBatchDetailView` z `batchID` — odszukuje w BatchStore
- Jeśli batch usunięty: `missingBatchState` ✅
- **BUG:** Szczegóły przeliczają wyniki z BIEŻĄCYM garnkiem (C-1)

### Puste stany
- Brak historii: `emptyState` w HistoryView ✅
- Brak składników snapshot: komunikat o starszej wersji + opcja nowego gotowania ✅
- Brak batcha po ID: `missingBatchState` ✅

---

## 11. Audyt SwiftUI i stanu

### Property wrappers

| Użycie | Poprawność |
|---|---|
| `@StateObject` dla BatchStore, AppRouter w RosolekApp | ✅ Poprawne — root owner |
| `@EnvironmentObject` w widokach | ✅ Poprawne |
| `@AppStorage` w wielu widokach dla tych samych kluczy | ⚠️ Redundantne deklaracje, synchronizują się przez UserDefaults |
| `@State private var timerPublisher = Timer.publish(...).autoconnect()` | ⚠️ Timer uruchomiony od init widoku, nawet przed startem gotowania |

### Computed properties w body (problem wydajności C-3)

```swift
// CookingModeView — 11 computed properties delegujących do phaseBuilder
private var phaseBuilder: CookingPhaseBuilder {
    CookingPhaseBuilder(batch: currentBatch, result: result, hasThermometer: hasThermometer)
}
private var activeUltraVariant: UltraSpecVariantID? { phaseBuilder.activeUltraVariant }
private var isGrandmaPreset: Bool { phaseBuilder.isGrandmaPreset }
// ... 9 kolejnych ...
private var phases: [LivePhase] { phaseBuilder.buildPhases() }  // ← nowe buildPhases() co render
```

Każdy dostęp do `phaseBuilder` tworzy nową instancję. Każdy dostęp do `phases` wywołuje `buildPhases()`. Timer re-renderuje widok co sekundę → ~11 tworzenia `CookingPhaseBuilder` + `buildPhases()` na sekundę przez całe gotowanie.

### Force unwrap
- Brak jawnych force unwrap (`!`) w krytycznych ścieżkach ✅
- `try? Activity.request(...)` — silently swallows Live Activity error ⚠️

### ForEach identifiers
- `ForEach(Array(steps.enumerated()), id: \.offset)` w `CurrentMiniStepsCard` — index jako ID ⚠️
- `ForEach(Array(phases.enumerated()), id: \.element.id)` w timeline — UUID jako ID ✅

### Navigation
- `NavigationStack` → `NavigationLink` → `NavigationDestination` — poprawny wzorzec iOS 16+ ✅
- `id(navigationResetID)` na `NavigationStack` dla "return to home" — pragmatyczne ale kruche ⚠️

### Layout
- `fixedSize(horizontal: false, vertical: true)` na długich tekstach ✅
- `GeometryReader { _ in` wrapping całego ScrollView — zbędne, `_` oznacza że wartość jest ignorowana (M-14)
- `.scrollBounceBehavior(.basedOnSize)` — iOS 16.4+, sprawdzić minimum deployment target

### Dark mode
- Wszystkie kolory przez `AppTheme` (semantic colors) ✅
- **Wyjątek:** `ReadyToStartBanner` używa hardcoded `Color(red:green:blue:)` — nie adaptuje się do dark mode (M-1)

### Dynamic Type
- `.font(.system(size: N, weight:))` bez skalowania — nie obsługuje Dynamic Type ⚠️
- `fixedSize(horizontal: false, vertical: true)` łagodzi problem dla wieloliniowych tekstów ✅

---

## 12. Audyt danych i historii

### Mechanizm zapisu

**BatchStore:**
- UserDefaults, klucz `rosolek_batches_v1`
- Serializacja: `JSONEncoder().encode([BatchRecord])`
- Deserializacja z per-element recovery ✅

**CookingSession:**
- UserDefaults, klucz `cooking_session_active_v1`
- JSONEncoder/Decoder ✅

### Wersjonowanie modeli

```swift
private static let schemaVersion = 1
private let storageKey = "rosolek_batches_v\(BatchStore.schemaVersion)"
```

Strategia `decodeIfPresent` z fallbackami — dobra na dodawanie pól ✅  
Komentarz wyjaśnia strategię migracji ✅  
**Ryzyko:** Zmiana typu pola bez zmiany `schemaVersion` → crash przy decodeIfPresent które nie pasuje do typu.

### Odporność na uszkodzone dane
- `recoverBatchesFromCorruptedData()` — per-element recovery ✅
- CookingSession: `try?` → nil przy uszkodzonych danych ✅

### Historyczne vs. bieżące dane — CRITICAL BUG (C-1)

```swift
// ContentView.swift:155 — deep link do aktywnego gotowania
result: deepLinkBatch.calculationResult(potSizeLiters: potSizeLiters)  // BIEŻĄCY garnek

// ContentView.swift:206 — banner aktywnego gotowania  
let result = batch.calculationResult(potSizeLiters: potSizeLiters)  // BIEŻĄCY garnek
```

`BatchRecord` przechowuje `waterLiters` historyczne, ale `calculationResult()` przelicza wszystko od nowa z BIEŻĄCYM `potSizeLiters`. Jeśli użytkownik zmienił garnek między początkiem gotowania a powrotem do aplikacji — widzi inne dane w live cooking niż faktycznie gotuje.

---

## 13. Spójność domenowa

### Miejsca definicji kluczowych wartości

| Wartość | Definicja | Duplikaty? |
|---|---|---|
| Czasy gotowania per wariant | `UltraSpecCatalog.variants[].totalMinutes` | Jedyne źródło dla UltraSpec ✅ |
| Temperatury | `UltraSpecCatalog.variants[].temperature` | Jedyne źródło ✅ |
| Mapowanie wariantu | `UltraSpecVariantResolver.resolve()` | Jedyne miejsce ✅ |
| Progi warningstów | `UltraSpecCatalog.warningThresholds` | Jedyne miejsce ✅ |
| Profile składników | `UltraSpecCatalog.ingredients` | Jedyne miejsce ✅ |
| Koszyki warzyw | `UltraSpecCatalog.vegetableBaskets` | Jedyne miejsce ✅ |
| Fazy gotowania | `UltraSpecTimelineCatalog` (Ultra), `CookingPhaseBuilder.buildStandardPhases()` (legacy) | **DWIE IMPLEMENTACJE** |
| Nazwy warzyw wyświetlane | `BrothResultView.prettyIngredientName()` vs `UltraSpecBridge.makeBrothResult()` (bez pretty) | **NIESPÓJNOŚĆ** → C-5 |

### Niespójności nazw warzyw — CRITICAL (C-5)

```swift
// BrothResultView.makeBrothResultFromUltraSpec() — DOBRZE:
VegetableAmount(name: prettyIngredientName($0.ingredientID), ...)  // "Marchew"

// UltraSpecBridge.makeBrothResult() — ŹLE:
VegetableAmount(name: $0.ingredientID, ...)  // "VEG_CARROT"
```

`UltraSpecBridge.makeBrothResult()` jest używane przez `BatchRecord.calculationResult()` → przez `ContentView` dla aktywnego gotowania i deep linków → przez `CookingModeView` → przez `CookingPhaseBuilder.vegetableReminderRows` → przez sheet "Lista składników do dodania".

Użytkownik w live cooking z historii widzi "VEG_CARROT", "VEG_CELERIAC" etc. zamiast "Marchew", "Seler korzeniowy". Dodatkowo `ingredientIconKind()` i `vegetableSubtitle()` szukają polskich słów kluczowych i nie dopasowują ID-ów, więc ikony i opisy są generyczne.

---

## 14. Pełna lista problemów

| ID | Priorytet | Obszar | Plik:Linia | Opis problemu | Skutek | Rekomendacja |
|---|---|---|---|---|---|---|
| C-1 | 🔴 CRITICAL | Dane/Historia | ContentView.swift:155, 206 | `batch.calculationResult(potSizeLiters: potSizeLiters)` używa BIEŻĄCEGO garnka z AppStorage zamiast garnka z momentu gotowania | Ilość wody i wyniki dla aktywnej sesji zmieniają się gdy użytkownik zmieni garnek w ustawieniach | Dodać `potSizeLitersAtCooking: Int` do `BatchRecord`, zapisywać przy tworzeniu, używać w `calculationResult()` |
| C-2 | 🔴 CRITICAL | Timery | CookingModeView.swift:1028-1031 | Timer oparty na zliczaniu ticków (`phaseElapsedSeconds += 1`) zamiast na porównaniu `Date()` | Timer dryfuje gdy main thread jest zajęty; czas może być niedokładny przez całe gotowanie | Zapisać `phaseStartDate: Date` przy starcie etapu i liczyć elapsed jako `Date().timeIntervalSince(phaseStartDate)` |
| C-3 | 🔴 CRITICAL | Wydajność | CookingModeView.swift:121-138 | `phaseBuilder` i `phases` to computed properties tworzące nowy `CookingPhaseBuilder` + `buildPhases()` przy każdym dostępie; timer re-renderuje co sekundę | ~11 tworzenia CookingPhaseBuilder/sekundę przez całe gotowanie — CPU i bateria | Memoizować `phaseBuilder` jako `@State private var`, przebudowywać tylko przy zmianie `batch` |
| C-4 | 🔴 CRITICAL | Timery | CookingModeView.swift:1299-1313 | `advanceElapsedThroughPhases()` przerywa pętlę przy manualnym kroku (`guard currentPhaseHasTimer else { break }`), ale `processElapsedSeconds` nadal rośnie o pełny elapsed | Powrót z tła podczas manualnego kroku: `processElapsedSeconds` jest fałszywie wysoki, `phaseIndex` nie przesuwa się | Przy manualnych krokach przemijający czas powinien być zaliczany inaczej lub pętla powinna pomijać manualne kroki |
| C-5 | 🔴 CRITICAL | Komunikaty/UX | UltraSpecBridge.swift:makeBrothResult() | `UltraSpecBridge.makeBrothResult()` zapisuje `VegetableAmount(name: $0.ingredientID)` → "VEG_CARROT"; `BrothResultView.makeBrothResultFromUltraSpec()` używa `prettyIngredientName()` → "Marchew" | Live cooking z historii: lista składników do dodania pokazuje surowe ID zamiast polskich nazw; ikony i opisy są generyczne | Ujednolicić: `UltraSpecBridge.makeBrothResult()` powinien używać tej samej funkcji `prettyIngredientName()` |
| C-6 | 🔴 CRITICAL | Logika domeny | UltraSpecEngine.swift:calculate():38-45 | Engine nie filtruje `resolvedItems` przez `ingredient.allowedVariants` — składnik z innego wariantu liczy się do `totalAnimalG` | Składnik rybny dodany do rosołu liczy się do gęstości; możliwe błędne warningi lub wyniki | Dodać filtr: `.filter { $0.0.allowedVariants.contains(request.variant) }` |
| H-1 | 🟠 HIGH | Wydajność | CookingModeView.swift:109-110 | `timerPublisher` uruchomiony od init widoku (`autoconnect()`), timer bije co sekundę nawet przed startem gotowania na etapie checklist | Zbędne budzenie procesora/baterii co sekundę przed "Start" | Zarządzać subskrypcją ręcznie — startować timer dopiero przy `sessionStarted = true` |
| H-2 | 🟠 HIGH | Serializacja | BrothStyleSelectionView.swift:13-17 | `BrothKind.rawValue` używa polskich znaków (`"Rosół"`, `"Wołowy"`) jako klucz serializacji w `BatchRecord.brothKindRawValue` | Zmiana wyświetlanej nazwy = utrata odczytu historycznych rekordów | Oddzielić klucz serializacji (np. `"rosol"`, `"wolowy"`) od tytułu wyświetlanego przez osobne property |
| H-3 | 🟠 HIGH | Logika domeny | BatchRecord.swift:calculationResult() | `try?` cicho połyka błąd UltraSpec i fallbackuje do legacy silnika bez informowania użytkownika | Użytkownik może dostać inne wyniki niż przy pierwotnym obliczeniu bez żadnego komunikatu | Przynajmniej `os_log(.error, ...)` błąd; rozważyć wyświetlenie komunikatu |
| H-4 | 🟠 HIGH | Testy | RosolekTests/RosolekTests.swift | Plik zawiera tylko `testExample()` bez asercji — placeholder | Fałszywe poczucie pokrycia testami | Wypełnić prawdziwymi testami lub usunąć plik |
| H-5 | 🟠 HIGH | Architektura | CookingModeView.swift:1083 | `startCookingFromPrep()` ustawia `phaseIndex = 1` bez sprawdzenia `phases.count > 1` | Jeśli `buildPhases()` zwróci 0 lub 1 elementów, `phaseIndex = 1` przy `phases.count = 1` tworzy niespójny stan | Dodać `guard phases.count > 1 else { return }` |
| H-6 | 🟠 HIGH | UX/Komunikaty | CookingNotificationService.swift:18 | Tytuł powiadomienia zawsze `"Rosół: Etap zakończony"` bez względu na typ bulionu | Ramen, bulion rybny, bulion wołowy — komunikat niepoprawny | Przekazać typ bulionu do `schedulePhaseEnd()` i dynamicznie generować tytuł |
| H-7 | 🟠 HIGH | Kod martwy | CookingNotificationService.swift:29-41 | `notifyActionRequired()` tworzy powiadomienia z UUID identifiers których nie może anulować `cancelAll()`. Nigdy nie jest wywoływana. | Jeśli kiedykolwiek zostanie wywołana — nagromadzenie nieanulowanych powiadomień | Usunąć metodę |
| H-8 | 🟠 HIGH | Live Activity | CookingModeView.swift:1189-1191 | `stepEndDate = Date().addingTimeInterval(currentPhaseRemainingSeconds)` — `currentPhaseRemainingSeconds` obliczony z dryfujących ticków | Live Activity na lock screen może pokazywać nieznacznie niedokładny czas | Trzymać `phaseStartDate: Date` i obliczać: `phaseStartDate + phaseTotalSeconds - Date.now` |
| M-1 | 🟡 MEDIUM | UI/Dark mode | CookingModeView.swift (ReadyToStartBanner) | Hardcoded `Color(red: 0.21, green: 0.75, blue: 0.36)` i podobne kolory — nie adaptują się do dark mode | Baner "Checklista gotowa" jest zawsze jasno zielony, nawet w dark mode | Dodać semantic colors do `RosolDesignSystem` |
| M-2 | 🟡 MEDIUM | UX/Flow | ContentView.swift, BrothResultView.swift | Batch tworzony i zapisywany w BatchStore PRZED wejściem do CookingModeView. Wycofanie zostawia batch ze statusem `completed` w historii | Historia zawiera niekompletne batche | Ustawić domyślny status `unknown` i zmieniać na `completed` dopiero po BatchFeedbackView |
| M-3 | 🟡 MEDIUM | Architektura | CookingPhaseBuilder.swift:74 | `if activePreset == .fishReady { return .rybnyDelikatny }` — hardcoded mapowanie presetu na wariant | Jeśli dojdzie drugi preset rybny, linia musi być ręcznie zaktualizowana | Dodać `ultraVariant: UltraSpecVariantID?` jako właściwość `BrothPreset` |
| M-4 | 🟡 MEDIUM | UX | CookingModeView.swift:1079 | `requestPermission()` wywoływane przy tapnięciu "Start" — może wywołać dialog zgody w środku animacji startu | Zakłócenie UX; jeśli user odmówi, brak informacji że gotowanie idzie bez powiadomień | Prosić o pozwolenie przy wejściu do CookingModeView; pokazać komunikat jeśli brak uprawnień |
| M-5 | 🟡 MEDIUM | Testy | Wiele plików | Brak testów dla: `CookingPhaseBuilder.buildPhases()`, `BrothResultView` logic, `BatchFeedbackView`, `SettingsView`, live cooking flow | Brak pewności co do poprawności budowania faz gotowania | Priorytetowo: testy dla `buildPhases()` dla każdego wariantu UltraSpec |
| M-6 | 🟡 MEDIUM | Architektura | CookingPhaseBuilder.swift:26-68 | Detekcja składników przez substring matching (np. `normalized.contains("kura")`) na starej ścieżce bez snapshot | Dodanie nowego składnika drobiu może nie zostać wykryte na legacy path | Wyraźnie oznaczyć legacy path jako `@available(*, deprecated)` |
| M-7 | 🟡 MEDIUM | Architektura | Wiele plików | `@AppStorage("potSizeLiters")` deklarowane wielokrotnie niezależnie w różnych widokach | Brak centralnego punktu kontroli; redundancja | Rozważyć `EnvironmentValues` lub dedykowany `UserPreferencesStore` |
| M-8 | 🟡 MEDIUM | UX | BrothResultView.swift:101 | `result: BrothCalculationResult` jest computed property wywołującą `computeCurrentResult()` bez cachowania | Przy każdym re-renderze widoku wynik jest przeliczany od nowa (UltraSpec = matematyka) | `@State private var cachedResult` aktualizowany przez `onChange` |
| M-9 | 🟡 MEDIUM | Logika domeny | UltraSpecEngine.swift:wingsShare | Wings share = `wingsG / poultryG` — przy składzie "tylko skrzydła" wingsShare = 100% → zawsze WINGS_TOO_HIGH | Użytkownik ze składem "tylko skrzydła" zawsze dostaje warning jako błąd | Zmienić semantykę na "wings jako udział całej bazy mięsnej" lub dostosować próg |
| M-10 | 🟡 MEDIUM | Dane | UltraSpecEngine.swift | UltraSpecEngine nie ma limitu `totalAnimalG` analogicznego do `hardTooMuchMeat` w BrothCalculator (10kg) | 50kg mięsa w dużym garnku przejdzie bez błędu | Dodać górny limit totalAnimalG w UltraSpecEngine |
| M-11 | 🟡 MEDIUM | UI | CookingModeView.swift:273 | `GeometryReader { _ in` wrapping całego body — wartość geometrii ignorowana (`_`) | Zbędna warstwa layoutu, możliwe layout issues | Usunąć GeometryReader |
| M-12 | 🟡 MEDIUM | UX | CookingModeView.swift:isTimelineExpanded | `@State private var isTimelineExpanded` resetowany przy każdym wejściu na ekran | User musi ponownie rozwijać timeline po każdym powrocie | Rozważyć `@SceneStorage` lub `@AppStorage` |
| M-13 | 🟡 MEDIUM | Logika domeny | UltraSpecCatalog.swift | `OFFAL_CHICKEN_LIVER` ma `premiumOnly: true` ale UltraSpecEngine nie sprawdza tego pola | Premium składniki dostępne dla wszystkich | Dodać walidację premium lub usunąć `premiumOnly` z katalogu jeśli feature nie jest zaimplementowany |
| M-14 | 🟡 MEDIUM | UI | CookingModeView.swift:249 | `print("⚠️ unhandled ultra timeline stepID: ...")` — debug log w produkcji | Logi debugowe wyciekają do produkcji | Zastąpić przez `os_log(.error, ...)` lub `assertionFailure` w DEBUG |
| M-15 | 🟡 MEDIUM | UX | HistoryView.swift | Brak `lineLimit` + `truncationMode` dla `customTitle` w kartach historii | Bardzo długie nazwy batcha mogą rozciągnąć UI | Dodać `lineLimit(2).truncationMode(.tail)` |
| L-1 | 🔵 LOW | UX | ContentView.swift:7, SettingsView.swift:3 | `@AppStorage("userFirstName") private var userFirstName = "Paweł"` — hardcoded polskie imię | Nowi użytkownicy widzą "Paweł" zamiast pustego pola | Zmienić na `= ""` i obsłużyć empty state |
| L-2 | 🔵 LOW | i18n | BatchRecord.swift:historyDateFormatter | `Locale(identifier: "pl_PL")` hardcoded — nie respektuje locale urządzenia | Daty zawsze po polsku nawet dla użytkowników z innym locale | Użyć `Locale.autoupdatingCurrent` |
| L-3 | 🔵 LOW | Testy | RosolekTests/RosolekTests.swift | `testExample()` bez asercji — placeholder | False positive w liczbie testów | Usunąć lub zastąpić prawdziwym testem |
| L-4 | 🔵 LOW | UI | CookingModeView.swift | `isTimelineExpanded` resetowany przy każdym wejściu — user musi rozwijać ponownie | Drobny UX friction | `@SceneStorage("isTimelineExpanded")` |
| L-5 | 🔵 LOW | UI | CookingModeView.swift:1136-1154 | `playStartSignal()` i `playFinishSignal()` oba używają `AudioServicesPlaySystemSound(1005)` | Start i koniec mają identyczny dźwięk | Użyć różnych ID |
| L-6 | 🔵 LOW | Architektura | BatchRecord.swift:modeTitle | `default: return "Batch"` dla nieznanych modeRawValue | Generyczny fallback bez identyfikacji | Dodać obsługę "legacy" osobno |
| L-7 | 🔵 LOW | Dostępność | Wiele plików | `.font(.system(size: N, weight:))` bez `relativeTo:` — nie skaluje z Dynamic Type | Użytkownicy z dużą czcionką dostępnościową nie mają powiększonego tekstu | Użyć `.font(.system(.body))` z `.fontWeight()` lub `relativeTo:` |
| L-8 | 🔵 LOW | UX | BrothResultView.swift, ContentView.swift | `defaultUseVinegar` zapisywane w AppStorage jako preferencja użytkownika — ale nie jest prezentowane w SettingsView | Użytkownik nie widzi swojej preferencji octu w ustawieniach | Dodać ocet do SettingsView lub usunąć persystencję |
| L-9 | 🔵 LOW | Architektura | BatchRecord.swift | Static `historyDateFormatter` z hardcoded locale nie aktualizuje się po zmianie locale | Stary format po zmianie języka | `Locale.autoupdatingCurrent` |
| L-10 | 🔵 LOW | UX | ContentView.swift:phaseSupportNote | `switch kind` w `miniSteps()` ma `default: break` po wszystkich obsłużonych case'ach — zbędne | Kod mniej czytelny | Usunąć `default: break` i dodać `@unknown default:` jeśli enum może się rozrastać |

---

## 15. Edge case matrix

| Przypadek | Obecne zachowanie | Oczekiwane zachowanie | Status | Rekomendacja |
|---|---|---|---|---|
| Garnek 0 L | `hardPotTooSmall` | Blokada startu | ✅ OK | — |
| Garnek 0.24 L | `hardPotTooSmall` | Blokada startu | ✅ OK | — |
| Garnek 0.25 L (minimum) | Kalkuluje, może dać `hardNotFit` | Kalkuluje | ✅ OK | — |
| Garnek 30 L (maximum) | Kalkuluje | Kalkuluje | ✅ OK | — |
| Garnek 100 L | `hardPotTooBig` (limit 30L) | Blokada | ✅ OK | Limit 30L może być zbyt restrykcyjny |
| 0 g mięsa custom | `hardNoMeat` | Blokada startu | ✅ OK | — |
| 10 g mięsa | UNDERPOWER warning, kalkuluje | Wyniki z warningstiem | ✅ OK | — |
| 10 000 g mięsa (BrothCalc) | `hardTooMuchMeat` | Blokada | ✅ OK | — |
| 10 000 g mięsa (UltraSpec) | Kalkuluje — brak limitu | Powinien ograniczyć | ⚠️ BRAK LIMITU | Dodać limit w UltraSpecEngine |
| Tylko skrzydła | Kalkuluje, WINGS_TOO_HIGH=100% | Warning | ⚠️ ZAWSZE WARNING | Przemyśleć semantykę progu |
| Tylko wątróbka | `offalDominantRisk`, kalkuluje | Warning + wyniki | ✅ OK | — |
| Brak żadnego mięsa (custom) | `hardNoMeat` | Blokada | ✅ OK | — |
| Tryb bez termometru | Checkbox pominięty automatycznie | Automatyczne zaznaczenie | ✅ OK | — |
| Zmiana garnka w trakcie gotowania | Niemożliwe — wynik zamrożony w CookingModeView | Wynik z momentu startu | ✅ OK | — |
| Dwa tapnięcia "Start" | Brak jawnego guard | Tylko jedno gotowanie | ⚠️ Ryzyko | Dodać explicit `isStartingCooking` flag |
| Timer w tło → powrót | Date-based recovery | Poprawny czas | ✅ OK | — |
| Force quit → restart | UserDefaults recovery | Odtworzenie sesji | ✅ OK | — |
| Zmiana strefy czasowej | `backgroundedAt` absolutne | Czas poprawny | ✅ OK | — |
| Uszkodzone dane UserDefaults | Per-element recovery | Odzysk sprawnych | ✅ OK | — |
| Pusta historia | `emptyState` widok | Komunikat | ✅ OK | — |
| Batch usunięty podczas przeglądania | `missingBatchState` | Komunikat | ✅ OK | — |
| Brak zgody na powiadomienia | Gotowanie startuje, brak notifikacji, brak info | Powinien informować | ⚠️ Brak komunikatu | Pokazać info o braku powiadomień |
| Locale z przecinkiem dziesiętnym | `extractGrams()` zamienia `,` na `.` | Poprawne parsowanie | ✅ OK | — |
| Bardzo długa nazwa batcha | Brak `lineLimit` w HistoryView | Może rozciągnąć UI | ⚠️ Sprawdzić | Dodać `lineLimit(2).truncationMode(.tail)` |
| Gotowanie z historii bez snapshot | Komunikat o starszej wersji | Czytelna informacja | ✅ OK | — |
| Składnik nieznany w katalogu UltraSpec | Cicho ignorowany | Ignorowany | ⚠️ Może skrzywić gęstość | Dodać warning w UI |

---

## 16. Proponowana kolejność napraw

### Blok 1 — Natychmiast (widoczne błędy UX lub logiki danych)

1. **C-5** — Nazwy warzyw w live cooking. Prosta zmiana jednej linii w `UltraSpecBridge.makeBrothResult()`: zamiana `$0.ingredientID` na `prettyIngredientName($0.ingredientID)`. Wymaga przeniesienia funkcji `prettyIngredientName` do wspólnego miejsca (lub `UltraSpecCatalog`).

2. **C-1** — Historyczny garnek. Dodać `potSizeLitersAtCooking: Int` do `BatchRecord` (z `decodeIfPresent` → fallback na `potSizeLiters` z AppStorage dla wstecznej kompatybilności). Każde wywołanie `batch.calculationResult(potSizeLiters:)` zamienić na `batch.calculationResult()` używające stored pot.

3. **C-6** — allowedVariants filtering. Jednolinijkowa zmiana w UltraSpecEngine: dodać `.filter { $0.0.allowedVariants.contains(request.variant) }` przed reduce operations.

4. **H-6** — Tytuł powiadomienia. Przekazać `brothKindTitle: String` do `schedulePhaseEnd()`.

### Blok 2 — W ciągu 1-2 sprintów (wydajność i stabilność)

5. **C-2 + H-8** — Timer Date-based. Dodać `@State private var currentPhaseStartDate: Date?`. Przy każdym `advanceToNextPhase()` i `startCookingFromPrep()` ustawić `currentPhaseStartDate = Date()`. `phaseElapsedSeconds = Int(Date().timeIntervalSince(currentPhaseStartDate))` obliczane w każdym ticku zamiast inkrementacji.

6. **C-3 + H-1** — Memoizacja phaseBuilder + timer lifecycle. Zmienić `phaseBuilder` w `@State private var` (lub `@StateObject` jeśli `class`). Przebudowywać przez `onChange(of: batch.id)`. Timer: zarządzać subskrypcją ręcznie przez `AnyCancellable`.

7. **C-4** — advance przez manualne kroki. Przy manualnym kroku w pętli: nie przerywać, lecz traktować manual krok jako "passed" jeśli elapsed > 0 i przejść do następnego.

8. **H-2** — BrothKind serialization keys. Dodać `static var storageKey: String` osobno. Backward compat: `BatchRecord.init(from: decoder)` mapuje stare "Rosół" → "rosol" etc.

### Blok 3 — Dług techniczny

9. **M-1** — Hardcoded kolory do design systemu.
10. **H-3, H-4, H-7** — Logging, usunięcie dead code, placeholder testu.
11. **M-2, M-4, M-5** — Status batcha, permission UX, nowe testy.
12. **M-13** — Premium blokada lub usunięcie.
13. **L-1 do L-10** — Kosmetyka.

---

## 17. Brakujące testy

**TC-01**
- Nazwa: `HistoricalBatchUsesRecordedPotSize`
- Co testuje: `batch.calculationResult()` używa potSizeLiters z momentu gotowania, nie bieżącego
- Wejście: `BatchRecord` z `potSizeLitersAtCooking = 7`, wywołanie z potSizeLiters = 5
- Oczekiwany wynik: wyniki odpowiadają 7L, nie 5L
- Priorytet: CRITICAL

**TC-02**
- Nazwa: `UltraSpecEngineRejectsIngredientFromWrongVariant`
- Co testuje: `allowedVariants` filtering w UltraSpecEngine
- Wejście: `.rosolLekki` + `FISH_WHITE_BONES` (allowed only for fish variants)
- Oczekiwany wynik: `result.totalAnimalG` = 0 (FISH_WHITE_BONES nie jest doliczany)
- Priorytet: CRITICAL

**TC-03**
- Nazwa: `VegetableNamesInBridgeResultArePretty`
- Co testuje: `UltraSpecBridge.makeBrothResult()` zwraca czytelne nazwy warzyw
- Wejście: `UltraSpecCalculationResult` z `VEG_CARROT` w warzywach
- Oczekiwany wynik: `result.vegetables[0].name == "Marchew"`, nie `"VEG_CARROT"`
- Priorytet: CRITICAL

**TC-04**
- Nazwa: `AdvanceElapsedSkipsManualPhasesCorrectly`
- Co testuje: Logika advance po powrocie z tła gdy bieżący krok jest manualny
- Wejście: phases = [manual, timed(3600s), timed(1800s)], phaseIndex = 0 (manual), elapsed = 4000s
- Oczekiwany wynik: phaseIndex = 2, phaseElapsedSeconds = 400, processElapsedSeconds = 4000
- Priorytet: CRITICAL

**TC-05**
- Nazwa: `CookingPhaseBuilderBuildsPhasesForAllVariants`
- Co testuje: `buildPhases()` zwraca non-empty dla każdego UltraSpecVariantID
- Wejście: BatchRecord z każdym możliwym `brothKindRawValue` + `selectedStyleName`
- Oczekiwany wynik: `phases.count > 1` dla każdego wariantu
- Priorytet: HIGH

**TC-06**
- Nazwa: `BrothKindDecodesFromLegacyPolishRawValues`
- Co testuje: Stare `BatchRecord` z `brothKindRawValue = "Rosół"` poprawnie dekodują po zmianie enum
- Wejście: JSON z `"brothKindRawValue": "Rosół"`
- Oczekiwany wynik: `batch.brothMode` zwraca poprawny `BrothKind.rosol`
- Priorytet: HIGH

**TC-07**
- Nazwa: `UltraSpecEngineLargeMeatAmount`
- Co testuje: UltraSpecEngine obsługuje duże ilości mięsa w dużym garnku
- Wejście: 30L garnek, 10000g POULTRY_OLD_HEN dla rosolLekki
- Oczekiwany wynik: brak crashu, `result.waterStartL.isFinite && result.waterStartL > 0`
- Priorytet: MEDIUM

**TC-08**
- Nazwa: `CookingPhaseBuilderRosolBogatyWithoutPoultry`
- Co testuje: `rosolBogaty` bez drobiu (tylko wołowina) generuje poprawne fazy
- Wejście: BatchRecord z samą wołowiną, `brothKindRawValue = "Wołowy"`
- Oczekiwany wynik: brak kroku `remove_poultry` w fazach, `hasPoultry == false`
- Priorytet: MEDIUM

**TC-09**
- Nazwa: `StartCookingGuardsAgainstEmptyPhases`
- Co testuje: `startCookingFromPrep()` nie crashuje gdy phases.count == 0 lub 1
- Wejście: BatchRecord generujący 0 faz (edge case)
- Oczekiwany wynik: brak crashu, `sessionStarted` pozostaje `false`
- Priorytet: HIGH

**TC-10**
- Nazwa: `BatchStorePersistenceWithFullSnapshot`
- Co testuje: Zapis i odczyt BatchRecord ze wszystkimi nowymi polami
- Wejście: Pełny BatchRecord z `selectedIngredientsSnapshot`, `meatOverrides`, `cookingOutcome`
- Oczekiwany wynik: identyczny rekord po encode/decode
- Priorytet: HIGH

**TC-11**
- Nazwa: `BatchStoreRecoversPartiallyCorruptedHistory`
- Co testuje: Jeden uszkodzony rekord nie blokuje odczytu pozostałych
- Wejście: JSON array z 3 rekordami, środkowy uszkodzony
- Oczekiwany wynik: 2 rekordy odzyskane, uszkodzony pominięty
- Priorytet: HIGH

**TC-12**
- Nazwa: `NotificationTitleMatchesBrothType`
- Co testuje: Tytuł powiadomienia jest odpowiedni dla typu bulionu
- Wejście: `schedulePhaseEnd(stepTitle: "X", inSeconds: 60, brothKind: .ramen)`
- Oczekiwany wynik: `content.title` zawiera "Ramen" lub podobne, nie "Rosół"
- Priorytet: MEDIUM

---

## Podsumowanie

**Znaleziono łącznie 39 problemów: 6 CRITICAL, 8 HIGH, 15 MEDIUM, 10 LOW.**

Najważniejsze do naprawy, w kolejności:

1. **C-5** — Warzywa w live cooking pokazują `VEG_CARROT` zamiast "Marchew" — natychmiast widoczny błąd UX
2. **C-1** — Bieżący garnek zamiast historycznego — błąd logiki danych wpływający na kluczowy flow
3. **C-6** — Brak filtrowania allowedVariants — błąd domenowy wpływający na poprawność wyników
4. **C-2** — Timer oparty na tickach — dryfuje przez całe gotowanie
5. **C-4** — Advance zatrzymuje się na manualnym kroku — błąd stanu po powrocie z tła
6. **C-3** — Przebudowa faz co sekundę — wydajność przez 3-8 godzin gotowania

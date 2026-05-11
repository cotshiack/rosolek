# Audit aplikacji iOS — Rosolek

**Data audytu:** 2026-05-08  
**Audytor:** Senior iOS Engineer / Swift Architect  
**Branch:** `claude/ios-audit-fixes-QMwxc`  
**Status:** Etap 1 zakończony — CRITICAL naprawione

---

## 1. Executive summary

Aplikacja Rosolek jest solidnie zaprojektowana i widać dbałość o szczegóły UI.
Architektura MVVM jest stosowana konsekwentnie, a nowy silnik UltraSpec jest
znacznie czystszy niż legacy `BrothCalculator`.

**Trzy obszary wymagające natychmiastowej uwagi:**

1. **[CRITICAL — NAPRAWIONY]** `BatchStore.load()` po błędzie decode ustawia
   `batches = []` — cała historia gotowania jest trwale tracona bez informacji
   dla użytkownika. Naprawione przez fallback per-element decode.

2. **[CRITICAL — NAPRAWIONY]** `assertionFailure()` w `CookingModeView.livePhaseKind()`
   crashuje debug buildy przy każdym nowym `stepID` dodanym do UltraSpec timeline.
   Naprawione przez zamianę na log + safe fallback.

3. **[HIGH]** `result` w `BrothResultView` to computed property bez memoizacji —
   pełen kalkulator UltraSpec uruchamia się 5+ razy na render. Do naprawy w Etapie 2.

Pozostałe problemy opisane w sekcji 9 są HIGH/MEDIUM/LOW i nie blokują
działania aplikacji w trybie release.

---

## 2. Jak analizowałem repo

**Pliki przejrzane (39 Swift + dokumentacja):**
- Wszystkie pliki Domain/ (UltraSpecEngine, Catalog, Warnings, Timeline, StepLibrary,
  VariantMapping, Models, Bridge, LiveBanners)
- BrothCalculator.swift (2568 L)
- BatchStore.swift, BatchRecord.swift, CookingSession.swift
- BrothResultView.swift, CookingModeView.swift, ContentView.swift (widoki główne)
- IngredientSelectionView.swift, BrothStyleSelectionView.swift
- HistoryView.swift, SettingsView.swift, LastBatchDetailView.swift
- BatchFeedbackView.swift, RecipesHubView.swift
- FloatingHomeMenuBar.swift, NavigationHelpers.swift
- RosolekApp.swift, Item.swift, KeyboardObserver.swift
- Wszystkie pliki testowe (4 pliki)
- ultra_spec_bulion_engine_v2_2_full.md (spec dokumentacja)
- docs/ultra-spec-implementation-plan.md
- docs/ultra-spec-xcode-validation-checklist.md

**Komendy wykonane:** Przeglądanie kodu statycznie (Linux — brak xcodebuild).  
**Build status:** Nie można uruchomić w środowisku Linux. Analiza oparta na
statycznym audycie kodu. Każda zmiana jest weryfikowana przez analizę Swift syntax
i sprawdzenie interfejsów.

---

## 3. Mapa aplikacji

### Ekrany i flow
```
RosolekApp
└── ContentView
    ├── OnboardingFlowView (pierwsze uruchomienie)
    │   └── kroki: welcome → pot → thermometer → name
    └── HomeView (po onboardingu)
        ├── FloatingHomeMenuBar (home / recipes / live / history / settings)
        ├── Tab: Home
        │   ├── ActiveCookingBanner (jeśli trwa gotowanie)
        │   ├── CalculatorEntryCard → BrothStyleSelectionView
        │   │   └── BrothKindCard → IngredientSelectionView / BrothResultView (veggie)
        │   │       └── BrothResultView
        │   │           └── CookingModeView
        │   │               └── BatchFeedbackView
        │   └── ReadyRecipesSection → BrothResultView (preset)
        ├── Tab: Recipes → RecipesHubView
        ├── Tab: Live → CookingModeView (aktywna sesja)
        ├── Tab: History → HistoryView → LastBatchDetailView
        └── Tab: Settings → SettingsView
```

### Modele
- `BatchRecord` — główny model historii gotowania (Codable, UserDefaults)
- `CookingSession` — aktywna sesja (Codable, UserDefaults)
- `UltraSpecVariantConfig` — konfiguracja wariantu bulionu (10 wariantów)
- `UltraSpecIngredient` — składnik z katalogiem (29 składników)
- `BrothCalculationResult` — wynik kalkulatora (legacy + UltraSpec)

### Store'y
- `BatchStore: ObservableObject` — CRUD historii, persystencja UserDefaults
- `AppRouter: ObservableObject` — kolejkowanie deep linków

### Kalkulator — dwa systemy
- **UltraSpec** (nowy): `UltraSpecEngine` → `UltraSpecBridge` → `BrothResultView`
  Używany dla wszystkich custom flows (10 wariantów)
- **BrothCalculator** (legacy): używany dla presetów (5 presetów) i jako fallback

### Flow danych
```
Użytkownik wybiera składniki
→ IngredientSelectionView (amounts: [String: String])
→ BrothResultView (initialSelections: [BrothIngredientSelection])
  → UltraSpecBridge.calculateFromCurrentFlow() → UltraSpecCalculationResult
  → BrothCalculationResult (bridge output)
→ startCooking() → batchStore.createBatch() → BatchRecord (UserDefaults)
→ CookingModeView (result: BrothCalculationResult jako `let`)
→ BatchFeedbackView → batchStore.updateFeedback()
```

---

## 4. Wynik build i testów

**Build:** Nie uruchomiono — brak `xcodebuild` w środowisku Linux.

**Testy (analiza statyczna):**

| Plik testowy | Liczba testów | Ocena |
|---|---|---|
| `UltraSpecEngineTests.swift` | 7 | Dobre — pokrycie ostrzeżeń, error throws |
| `UltraSpecTimelineTests.swift` | 3 | Podstawowe — brak edge case'ów |
| `UltraSpecVariantMappingTests.swift` | 4 | Dobre — resolvery i mapowania |
| `RosolekTests.swift` | 2 | Codable roundtrip — poprawne |

Łącznie: 16 testów. Brak testów dla: edge case'ów kalkulatora, persystencji
z uszkodzonymi danymi, locale, session restore, NaN/infinity guard.

---

## 5. Audyt kalkulatora

### UltraSpecEngine — analiza dokładna

**Wejścia:** `UltraSpecCalculationRequest` (variant, potCapacityL, items, clarityMode)  
**Wyjścia:** `UltraSpecCalculationResult` (waterRecipeL, waterStartL, estimatedYieldL,
startSaltG, targetSaltG, vegetables, spices, densityGL, warnings, warningMessages)

**Wzór obliczania wody:**
```
displacementL = totalAnimalG / 1000 * 0.55
foamReserveL  = potCapacityL * 0.12
safetyReserveL = max(0.25, potCapacityL * 0.08)
waterSafeL = potCapacityL - displacement - foam - safety

waterRecipeL:
  - jeśli waterFactor istnieje: (totalAnimalG / 1000) * waterFactor
  - jeśli nil (warzywny, rybny): min(waterSafeL, potCapacityL * 0.72)

waterStartL = max(0.1, min(waterRecipeL, waterSafeL))
```

**Walidacja:**
- `potCapacityL < 0.25` → `.hardPotTooSmall`
- `potCapacityL > 30` → `.hardPotTooBig`
- `waterSafeL <= 0` → `.hardNotFit`
- `totalAnimalG == 0` (non-warzywny) → `.hardNoBase`

⚠️ **Uwaga:** Guardy `potCapacityL` są sprawdzane PO obliczeniu `waterSafeL`
(choć logicznie poprawne — `potTooSmall` jest przed `waterSafeL > 0`). Semantycznie
guardy powinny być na początku (patrz L-1).

**Edge case'y — wyniki:**

| Przypadek | Zachowanie | Ocena |
|---|---|---|
| garnek 0 L | `hardPotTooSmall` ✓ | OK |
| garnek < 0.25 L | `hardPotTooSmall` ✓ | OK |
| garnek 0.3 L, mięso = 0, wariant non-warzywny | `hardNoBase` ✓ | OK |
| garnek 0.3 L, mięso = 0, wariant warzywny | wynik: ~3g warzyw ✓ | OK |
| mięso 10 000 g, garnek 5 L | duże displacement → `hardNotFit` lub duża gęstość | OK |
| mięso > pojemność garnka | displacement > waterSafeL → `hardNotFit` ✓ | OK |
| sama wątróbka 200 g, garnek 7 L | totalAnimalG=200, gęstość ~28 g/L → UNDERPOWER | OK |
| warzywny bez składników, garnek 5 L | waterRecipeL obliczone z waterSafeL, warzywa auto | OK |
| clarityMode = paperFilter | yieldL *= 0.96, warning `PAPER_FILTER_LOWER_INTENSITY` | OK |
| NaN/infinity | `max(0, ...)` i `min(...)` guards chronią przed > 0 | OK (praktycznie) |

**Ostrzeżenia — kompletność:**
- `UNDERPOWER` / `OVERPOWER` — z deltami (liczba gramów do dodania) ✓
- `VEG_TOO_MUCH` — z deltą (gramy warzyw do usunięcia) ✓
- `WINGS_TOO_HIGH`, `BEEF_TOO_HIGH`, `OFFAL_TOO_HIGH` — bez delty ✓
- `VEG_SWEET_RISK` — bez delty ✓
- `PAPER_FILTER_LOWER_INTENSITY` — info ✓

**Zaokrąglenia:**
- Warzywa: `.rounded()` → OK
- Sól: `saltStartCoef * waterStartL` — bez zaokrąglenia (wyświetlane po rounded() w View)
- Przyprawy: `max(0, Int((coef * waterStartL).rounded()))` — OK

### BrothCalculator (legacy) — analiza

Kalkulator legacy obsługuje 5 presetów plus custom flow. Kluczowe cechy:
- Interpolacja liniowa z tabel dla presetów (potSize → water/meat/veg)
- `safeWaterUpperBoundV2` z dwoma buforami piany (heat vs mild mode)
- Paper filter loss: `clamp(0.12 * waterL + 0.10 * fatIndex, 0.20, 0.80)` — może
  przeceniać uzysk dla bardzo tłustych wywarów
- `recommendedMeatRange()`: iteracja 0–10 000 g co 10 g = 1000 kroków → performance
- Formuła soli: `microMode` redukuje o 0.5 — spójne

---

## 6. Audyt flow użytkownika

### Onboarding
- **Stan pusty (pierwsze uruchomienie):** `@AppStorage("hasCompletedOnboarding") = false` →
  wyświetla `OnboardingFlowView` ✓
- **Walidacja garnka:** alert dla <3L (ostrzeżenie) i >30L (blokada zapisu) ✓
- **Restart aplikacji:** dane zachowane w AppStorage ✓
- **Reset onboardingu:** dostępny w Settings — ustawia `hasCompletedOnboarding = false`,
  `returnToHomeTrigger += 1` → reset NavigationStack ✓

### Wybór składników → kalkulator → wynik
- **Puste składniki:** IngredientSelectionView nie pozwala przejść dalej jeśli
  wszystkie pola = 0 (brak walidacji widocznej w kodzie — wymaga weryfikacji na urządzeniu)
- **Zmiana garnka w Settings podczas przeglądania wyniku:** możliwa przez
  FloatingMenuBar → `result` computed property rekalkuje natychmiast (patrz H-1)
- **Zmiana clarityMode/vinegar w ResultView:** rekalkuje wynik — ZAMIERZONE ✓
- **Batch save time:** `effectiveResult` uchwycony atomicznie w `startCooking()` ✓

### Live cooking
- **Timer pause/resume:** `isStageRunning` flag + `handleTick()` ✓
- **Tło aplikacji:** `onDisappear: saveSession(backgrounded: isStageRunning)`,
  `onChange(scenePhase) → resumeFromBackground()` ✓
- **Zamknięcie aplikacji podczas gotowania:** sesja zapisana w UserDefaults ✓
- **Powrót po czasie:** `resumeFromBackground()` powinien nadrobić czas, szczegóły
  zależą od implementacji (nie odczytałem w pełni)
- **Przerwanie przez nowe gotowanie:** `CookingSessionCoordinator.interruptActiveCookingAndCleanup()`
  oznacza stary batch jako `interruptedByNewCooking` ✓

### Historia
- **Brak historii:** pusty stan z CTA ✓
- **Z historią:** lista posortowana wg daty ✓
- **Szczegóły batcha:** pokazuje dane HISTORYCZNE (zapisane w BatchRecord) ✓
- **Replay:** `BatchRecord.calculationResult()` używa AKTUALNEGO potSizeLiters —
  to ZAMIERZONE (goto = gotuj z obecnym garnkiem), ale może mylić ✓

### Ustawienia
- **Zmiana garnka:** zmiana w AppStorage → natychmiastowy efekt w otwartych widokach
  (patrz H-1)
- **Zmiana termometru:** zmiana w AppStorage, widoki obserwują przez @AppStorage ✓

---

## 7. Audyt SwiftUI i stanu

### Property wrappers — poprawność
| Wrapper | Użycie | Ocena |
|---|---|---|
| `@AppStorage` | userFirstName, potSizeLiters, hasThermometer, hasCompletedOnboarding | ✓ poprawne |
| `@StateObject` | BatchStore, AppRouter w RosolekApp | ✓ — lifecycle root |
| `@EnvironmentObject` | batchStore, router w widokach | ✓ — injected z góry |
| `@State` | lokalne stany widoków | ✓ |
| `@Binding` | selectedPresetFilter, overrides | ✓ |
| `@FocusState` | focusedFieldID, focusedField | ✓ |

**Force unwraps:** Brak wykrytych w głównych widokach. Defensywne programowanie
konsekwentnie stosowane.

### Duże widoki
| Widok | LOC | Ocena |
|---|---|---|
| ContentView.swift | 2517 | Zawiera OnboardingFlowView + HomeView + wszystkie subcomponents |
| BrothResultView.swift | 2798 | Zawiera logikę kalkulatora + 3 arkusze edytora |
| CookingModeView.swift | 4193 | Największy — logika faz, timer, Live Activity, timeline |
| IngredientSelectionView.swift | 1600 | Duży, ale spójny |

CookingModeView jest kandydatem nr 1 do podziału na ViewModele.

### Navigation
- `NavigationStack` z `navigationDestination` — nowoczesny pattern ✓
- `id(navigationResetID)` do wymuszenia resetu navigation stack ✓
- Brak `NavigationLink` z deprecated `isActive` ✓
- Deep linking przez `onOpenURL` → `AppRouter` ✓

### ForEach / identyfikatory
- `ForEach(Array(phases.enumerated()), id: \.element.id)` — ✓ stabilne UUID
- `ForEach(batchStore.batches)` — `BatchRecord: Identifiable` przez UUID ✓
- `ForEach(Array(spiceRows.enumerated()), id: \.offset)` — indeks jako ID,
  akceptowalne dla statycznej listy ✓

### Safe area / layout
- `.safeAreaInset(edge: .bottom)` dla CTA buttons — nie zasłania treści ✓
- `.padding(.bottom, isFinished ? finishButtonOverlayHeight : liveControlsOverlayHeight + 20)`
  dla scrollView — ✓

---

## 8. Audyt danych i historii

### Persystencja
- **Mechanizm:** UserDefaults + JSONEncoder/Decoder
- **Klucz:** `"rosolek_batches_v1"` (wersjonowany klucz — dobry znak)
- **Model:** `BatchRecord` z custom `init(from:)` używającym `decodeIfPresent`
  dla WSZYSTKICH pól — bardzo dobra odporność na nowe pola ✓

### Stabilność modelu
- Wszystkie pola mają fallbacki w `init(from:)` ✓
- Legacy fields (styleRawValue, modeRawValue) mapowane przez helper functions ✓
- `activeCookingMinutes` fallback na `totalMinutes` ✓

### Ryzyko migracji — KRYTYCZNE (naprawione)
Jedyne realne ryzyko: `JSONDecoder().decode([BatchRecord].self, from: data)` rzuca
błąd dla CAŁEJ tablicy. Naprawione przez fallback per-element decode w BatchStore.

### Snapshot architecture
- `selectedIngredientsSnapshot: [BatchIngredientSnapshot]?` — pełny stan składników
  w czasie zapisu ✓
- `meatOverrides/vegetableOverrides/spiceOverrides` — zmiany użytkownika ✓
- Dane historyczne są NIEZMIENNE po zapisie (overallRating, notes są mutable) ✓

### CookingSession — aktywna sesja
- Zapisywana w UserDefaults na `onDisappear` i przy przejściu w tło
- `backgroundedAt: Date?` do nadrobienia czasu po powrocie ✓
- `clearOrphanedSessionIfNeeded()` — czyszczenie po usunięciu batcha ✓

---

## 9. Lista wszystkich problemów

| ID | Priorytet | Plik | Miejsce | Problem | Skutek | Status |
|---|---|---|---|---|---|---|
| C-1 | CRITICAL | BatchStore.swift:193-199 | `load()` catch | Milcząca utrata całej historii przy decode error | Trwała utrata danych użytkownika | **[FIXED]** |
| C-2 | CRITICAL | CookingModeView.swift:777 | `livePhaseKind()` | `assertionFailure()` crashuje debug build przy nowym stepID | Crash w DEBUG, wrong phase w RELEASE | **[FIXED]** |
| H-1 | HIGH | BrothResultView.swift:99 | `result` computed | Brak memoizacji — kalkulator uruchamia się 5+ razy na render | Lagowanie UI, potencjalna zmiana wyniku przy zmianie garnka | Otwarty |
| H-2 | HIGH | UltraSpecVariantMapping.swift | `mapIngredientID()` | `"serca", "zoladki"` → OFFAL_CHICKEN_LIVER (serca ≠ wątróbka) | Błędny profil smakowy/gęstość w kalkulatorze | Otwarty |
| H-3 | HIGH | BatchStore.swift | storage key | Brak formalnej strategii migracji danych | Ryzyko utraty danych przy zmianie schematu | Częściowo (C-1 naprawia) |
| M-1 | MEDIUM | Item.swift | cały plik | Unused SwiftData model (Xcode boilerplate) | Konfuzja architektury | Otwarty |
| M-2 | MEDIUM | BrothCalculator.swift | cały plik | 2568 linii — zbyt wiele odpowiedzialności | Trudna maintainability | Otwarty |
| M-3 | MEDIUM | RosolekTests.swift | brak | Brak testów edge case'ów kalkulatora | Nieznane zachowanie przy granicach | Otwarty |
| M-4 | MEDIUM | CookingModeView.swift | `phases`, `miniSteps()` | Ciężka logika domenowa w View body | Trudna testowalność i maintainability | Otwarty |
| M-5 | MEDIUM | BatchRecord.swift:89 | `overallRating` | Brak walidacji zakresu 1–10 | Możliwe nieprawidłowe dane w historii | Otwarty |
| L-1 | LOW | UltraSpecEngine.swift:73 | `calculate()` | Guards potCapacityL po obliczeniu waterSafeL | Semantycznie niepoprawna kolejność | Otwarty |
| L-2 | LOW | CookingModeView.swift:291 | `vegetableReminderRows` | `Int(item.amount.filter { $0.isNumber })` — kruche parsowanie | Błędna wartość przy dziesiętnych gramach | Otwarty |

---

## 10. Edge case matrix

| Przypadek | Obecne zachowanie | Oczekiwane | Status |
|---|---|---|---|
| garnek 0 L (UltraSpec) | `hardPotTooSmall` | Komunikat błędu | ✅ OK |
| garnek 0.24 L | `hardPotTooSmall` | Komunikat błędu | ✅ OK |
| mięso 0 g, wariant non-warzywny | `hardNoBase` | Komunikat błędu | ✅ OK |
| mięso 0 g, wariant warzywny | wynik z samymi warzywami | Wynik poprawny | ✅ OK |
| mięso > pojemność garnka (displacement > waterSafeL) | `hardNotFit` | Komunikat błędu | ✅ OK |
| tylko wątróbka 200 g, garnek 7 L | UNDERPOWER warning | Warning z deltą | ✅ OK |
| tylko kości, brak mięsa | UNDERPOWER lub OVERPOWER | Warning | ✅ OK |
| warzywa = 0 w koszyku | auto-kalkulator nie da 0 (vegPercent > 0) | Warzywa obliczone | ✅ OK |
| sól = 0 (saltStartCoef = 0, np. tonkotsu) | 0 g soli wyświetlane | Ukryte lub info | ⚠️ Do sprawdzenia |
| paper filter + brak mięsa | `hardNoBase` przed obliczeniem | Właściwy błąd | ✅ OK |
| zmiana garnka w Settings podczas ResultView | `result` przelicza się | Zamrożony wynik | ⚠️ H-1 |
| zmiana clarityMode w ResultView | `result` przelicza się | ZAMIERZONE | ✅ OK |
| powrót po zabiciuzabraniu aplikacji podczas gotowania | sesja odczytywana z UserDefaults | Wznowienie sesji | ✅ OK |
| uszkodzone dane UserDefaults (batches) | **PRZED FIX:** puste batches; **PO FIX:** próba per-element | Zachowanie max. danych | ✅ FIXED |
| locale z przecinkiem jako sep. dziesiętny | `Double(inputString)` może zwracać nil | Poprawna liczba | ⚠️ Do zbadania |
| rating > 10 w BatchFeedback | akceptowany bez walidacji | Odrzucony lub zaokrąglony | ⚠️ M-5 |

---

## 11. Brakujące testy

```swift
// KALKULATOR
func testCalculatorRejectsZeroLiterPot() throws
func testCalculatorRejectsPotAbove30L() throws
func testCalculatorMeatHeavierThanPotCapacityReturnsHardNotFit() throws
func testCalculatorNeverReturnsNaNOrNegativeWaterValues() throws
func testCalculatorNeverReturnsNaNOrNegativeYieldValues() throws
func testCalculatorWarzywnyVariantSucceedsWithZeroAnimalIngredients() throws
func testCalculatorWarzywnyVariantWithOnlyMeatThrowsHardNoBase() throws // oczekujemy: nie rzuca
func testLiverOnlyBatchProducesValidResultWithUnderpowerWarning() throws
func testRamenTonkotsuHighDensityDoesNotTriggerUnderpowerWarning() throws
func testPaperFilterReducesYieldBy4Percent() throws

// WALIDACJA
func testUnderpowerDeltaMeatIsAlwaysPositive() throws
func testOverpowerDeltaWaterIsAlwaysPositive() throws
func testVegTooMuchDeltaIsNeverNegative() throws

// PERSYSTENCJA
func testBatchStoreSilentlyRecoversSingleCorruptRecord() throws
func testBatchStoreReturnsEmptyArrayForCompletelyCorruptedData() throws
func testBatchStorePreservesGoodRecordsWhenOneRecordIsCorrupt() throws
func testHistoryPreservesOriginalBatchAfterSettingsChange() throws
func testBatchRecordAllFieldsSurviveEncodeDecodeRoundtrip() throws

// SESJA
func testSaveAndRestoreActiveCookingSessionPreservesPhaseIndex() throws
func testClearOrphanedSessionRemovesSessionWhenBatchDeleted() throws
func testInterruptActiveCookingMarksOldBatchAsInterrupted() throws

// ONBOARDING
func testOnboardingFlagResetsCorrectlyToFalse() throws
func testSettingsReturnsToOnboardingAfterReset() throws

// EDGE CASE'Y PLATFORMOWE
func testLocaleWithCommaDecimalSeparatorHandledCorrectly() throws
func testOverallRatingIsClampedToValidRange() throws
func testBatchRecordDisplayTitleFallsBackToDefaultTitle() throws

// TIMELINE
func testTimelineStagesMatchCalculatorTotalMinutes() throws
func testAllVariantTimelinesHaveAtLeastTwoSteps() throws
func testEveryTimelineStepHasNonEmptyTitle() throws

// VARIANT MAPPING
func testAllBrothKindStyleCombinationsResolveToKnownVariant() throws
func testIngredientIDMapperHandlesUnknownIDsByPassthrough() throws
```

---

## 12. Plan napraw

### Etap 1 — CRITICAL bugfixy ✅ ZROBIONE
- [x] **C-1:** BatchStore.swift — fallback per-element decode
- [x] **C-2:** CookingModeView.swift — usunięcie assertionFailure

### Etap 2 — HIGH — niespójności logiki i UX
- [ ] **H-1:** BrothResultView.swift — memoizacja `result` jako `@State`
- [ ] **H-2:** UltraSpecVariantMapping.swift — poprawne mapowania serca/żołądki

### Etap 3 — Testy jednostkowe kalkulatora i walidacji
- [ ] Testy z listy powyżej dla kalkulatora, persystencji, sesji

### Etap 4 — Refaktor architektury
- [ ] Podział CookingModeView (fazy → CookingPhaseBuilder)
- [ ] Podział BrothCalculator.swift
- [ ] Usunięcie Item.swift (M-1)
- [ ] Walidacja overallRating (M-5)

### Etap 5 — UX polish i drobne poprawki
- [ ] L-1: kolejność guardów w UltraSpecEngine
- [ ] L-2: parsowanie gramów w CookingModeView
- [ ] Sprawdzenie locale z przecinkami

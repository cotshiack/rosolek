# ULTRA-SPEC — Xcode validation checklist (final)

## 1) Smoke flow (custom)
1. Wejdź: Własny bulion -> wybierz rodzaj + styl.
2. Dodaj składniki i przejdź do wyników.
3. Sprawdź badge `ULTRA-SPEC aktywny`.
4. Zmień klarowność na filtr papierowy i sprawdź warning INFO.

## 2) Hard validation
- Garnek 0.2L -> oczekuj błędu `hardPotTooSmall`.
- Garnek 31L -> oczekuj błędu `hardPotTooBig`.
- Wariant zwierzęcy bez bazy -> oczekuj błędu `hardNoBase`.

## 3) Warning quality checks
- Rosół lekki + przewaga skrzydeł -> `WINGS_TOO_HIGH`.
- Rosół bogaty + wysoka wołowina -> `BEEF_TOO_HIGH`.
- Rosół bogaty + dużo podrobów -> `OFFAL_TOO_HIGH`.
- Skrajnie mało bazy -> `UNDERPOWER` + sugestia liczbowa.
- Skrajnie dużo bazy -> `OVERPOWER` + sugestia liczbowa.

## 4) Timeline checks
- Każdy wariant pokazuje kroki timeline.
- Tonkotsu zawiera etapy wrzenia.
- Rybny zawiera `Poach limit` i krótszy całkowity czas.

## 5) Regression checks
- Presety (nie-custom) dalej działają przez legacy kalkulator.
- Ekran wyników nie crashuje przy pustej selekcji.
- Ostrzeżenia renderują się z tekstem sugestii, jeśli dostępny.

## 6) Build/test commands (lokalnie)
- Product > Clean Build Folder
- Run tests: `RosolekTests`
- Uruchom aplikację na iPhone Simulator i przejdź checklistę 1-5.

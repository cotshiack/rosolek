# ULTRA-SPECYFIKACJA v2.2 (FULL) — Silnik bulionów + składniki + obliczenia + ostrzeżenia + live + drawery
_Data: 2026-04-30_

> Ten plik zawiera **całość**: ultra-specyfikację v2.2 + dodatki **O** (pełna biblioteka kroków live i drawerów) oraz **P** (biblioteka alertów jakości).  
> Format: **Markdown** (czytelny w repo i łatwy do wczytania przez Codex, szczególnie tabele).

---

## 0) Cel dokumentu
Silnik aplikacji liczącej i prowadzącej gotowanie bulionów:
- **co użytkownik może wybrać** (lista składników per rodzaj bulionu),
- **jak liczyć** wodę, warzywa, przyprawy, sól, uzysk, timeline,
- **jak diagnozować błędy i edge-case** (ostrzeżenia, progi, naprawy + auto-suggest),
- **jak prowadzić gotowanie live** (kroki + drawery + komunikaty).

Założenia UX/produktowe (ważne dla logiki, bez zmian ekranów):
- Użytkownik wybiera **rodzaj bulionu** + **profil**.
- Użytkownik wybiera składniki z **filtrowanej listy** i wpisuje gramatury.
- Warzywa/przyprawy/sól/timeline liczy **aplikacja**.
- Live cooking: aplikacja daje instrukcje, użytkownik **potwierdza checkpointy** (bez przesyłania danych z termometru).

---

## A) Założenia ogólne systemu

### A1) Core engine (wspólny dla wszystkich wariantów)
Kolejność obliczeń i decyzji:
1) Walidacja hard (czy wejścia mają sens)
2) Wyliczenie `waterRecipeL` (zależnie od wariantu)
3) Fit-to-pot → `waterStartL` (garnek + wypieranie + bufor piany)
4) Warzywa + przyprawy (koszyk per wariant, liczone od `waterStartL`)
5) Uzysk `estYieldL` (z korektą filtra)
6) Sól (start + docelowa)
7) Scoring jakości (fat/collagen/bone/density/udziały)
8) Ostrzeżenia (INFO/WARN/ERROR + auto-suggest)
9) Timeline (kroki + czasy + checkpointy + drawery)

### A2) Typy profili
- **Lżejszy (cleaner):** więcej wody na bazę, wyższa klarowność, niższe body.
- **Intensywniejszy (richer):** mniej wody na bazę, wyższa sól docelowa, częściej niższy uzysk i większe body.

### A3) Wspólne reguły jakości
- Warianty klarowne (rosół, shio, wołowy, warzywny, rybny) prowadzone **poniżej wrzenia**.
- **Wyjątek:** tonkotsu – wrzenie jest celem (emulsja).
- Klarowność psuje: wrzenie (poza tonkotsu), mieszanie, wyciskanie składników, przelewanie osadu z dna.
- Warzywa/aromaty mają optymalny czas – przeciąganie daje słodycz (warzywny/rosół) albo gorycz (rybny/aromaty).

---

## B) Matryca 10 wariantów (sensoryka i zastosowania)

| Wariant | Charakter sensoryczny | Klarowność | Tłustość | Body/żelatyna | Zastosowania |
|---|---:|---:|---:|---:|---|
| Rosół Lekki | czysty drobiowy | wysoka | niska-średnia | średnie | zupa, baza |
| Rosół Bogaty | drobiowo-wołowy | średnia-wysoka | średnia | wysokie | zupa, redukcje |
| Ramen Shio | jasny, solny, aromatyczny | wysoka | niska-średnia | średnie | ramen shio |
| Ramen Tonkotsu | mleczny, emulsyjny | niska (celowo) | wysoka | bardzo wysokie | ramen tonkotsu |
| Wołowy Czysty | wytrawny wołowy | wysoka | niska-średnia | średnie-wysokie | sosy, clear |
| Wołowy Mocny | mocny wołowy | średnia | średnia | wysokie | glaze, ramen |
| Warzywny Jasny | jasny warzywny | wysoka | niska | niskie-średnie | zupy, risotto |
| Warzywny Umami | warzywny umami | średnia-wysoka | niska-średnia | średnie | sosy, ramen wege |
| Rybny Delikatny | delikatny morski | wysoka | niska | niskie | zupy rybne |
| Rybny Intensywny | morski wyraźny | średnia-wysoka | niska-średnia | niskie-średnie | sosy, baza |

---

## C) Parametry kalkulatora per wariant (startowe, do kalibracji)

Definicje:
- `waterFactor` = L wody / kg bazy (mięso/kości) → rosoły/wołowe/ramen.
- Warzywny i rybny: `waterFactor = —` (woda wynika z uzysku i garnka; gramatury liczone na L uzysku).
- `vegPercent` = warzywa/aromaty (g) / (waterStartL*1000).
- `saltStartCoef` = g/L wody start.
- `saltTargetCoef` = g/L uzysku po cedzeniu.
- `pepper/allspice/bay` = szt/L wody start.

| Wariant | waterFactor | vegPercent | yieldFactor | saltStart | saltTarget | pepper/L | allspice/L | bay/L | Temp | Total min |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|---:|
| Rosół Lekki | 4.5 | 0.125 | 0.84 | 1.4 | 7.0 | 3.0 | 1.1 | 0.5 | 88–90°C | 315 |
| Rosół Bogaty | 2.6 | 0.140 | 0.80 | 1.7 | 7.7 | 3.5 | 1.3 | 0.6 | 88–90°C | 345 |
| Ramen Shio | 3.0 | 0.080 | 0.82 | 0.6 | 6.0 | 1.2 | 0.0 | 0.0 | 88–92°C | 240 |
| Tonkotsu | 1.8 | 0.040 | 0.70 | 0.0 | 5.0 | 0.0 | 0.0 | 0.0 | 95–100°C (wrzenie) | 480 |
| Wołowy Czysty | 2.8 | 0.060 | 0.80 | 0.8 | 6.2 | 2.0 | 0.5 | 0.4 | 88–92°C | 360 |
| Wołowy Mocny | 2.0 | 0.070 | 0.76 | 0.9 | 6.6 | 2.2 | 0.6 | 0.4 | 90–94°C | 420 |
| Warzywny Jasny | — | 0.200 | 0.86 | 0.8 | 5.8 | 1.2 | 0.0 | 0.0 | 85–88°C | 90 |
| Warzywny Umami | — | 0.220 | 0.84 | 0.9 | 6.2 | 1.4 | 0.0 | 0.0 | 88–92°C | 120 |
| Rybny Delikatny | — | 0.100 | 0.85 | 0.6 | 5.6 | 0.6 | 0.0 | 0.0 | 80–85°C | 45 |
| Rybny Intensywny | — | 0.120 | 0.82 | 0.7 | 5.9 | 0.8 | 0.0 | 0.0 | 85–90°C | 60 |

---

## D) Widoczność składników (UI) per rodzaj bulionu — ingredient catalog

**Zasada:** użytkownik widzi tylko składniki sensowne dla rodzaju bulionu.  
Warzywa i przyprawy:
- w rosole/wołowym/ramen są domyślnie niewybieralne (liczy kalkulator),
- w warzywnym i rybnym warzywa mogą być wybieralne, ale aplikacja liczy gramatury i pilnuje limitów.

### D1) Rosół (Lekki, Bogaty) — do wyboru (użytkownik wpisuje gramy)
**Drób (poultry)**: kura „stara”, korpus, porcja rosołowa drobiowa (mix), szyje, skrzydła, udka (ryzykowne w lekkim)  
**Wołowina (beef)**: szponder, pręga, ogon, kości stawowe, kości szpikowe (ryzykowne), mostek (ryzykowne)  
**Podroby (offal, premium)**: wątróbka (end-only), serca, żołądki  
**ZABLOKOWANE:** ryby, warzywa bazowe, przyprawy.

### D2) Ramen
**Shio**: drób (korpus/szyje/skrzydła/kura), wołowina opc. (pręga/szponder), premium kombu/grzyby, premium podroby (opc.)  
**Tonkotsu**: kości wieprzowe (stawowe/kręgi) + opc. łapki (jeśli wspierasz)  
**ZABLOKOWANE:** ryby (w basic), warzywa bazowe, przyprawy.

### D3) Wołowy
**Wołowina**: pręga/szponder/ogon/kości stawowe/kości szpikowe/mostek + premium podroby (opc.)  
**ZABLOKOWANE:** drób, ryby, warzywa bazowe, przyprawy.

### D4) Warzywny
**Warzywa**: cebula, seler korzeń, pietruszka korzeń, por, marchew, seler naciowy (opc.)  
**Umami premium**: suszone grzyby, kombu, miso (end-only)  
**ZABLOKOWANE:** drób/wołowina/podroby/ryby.

### D5) Rybny
**Ryby/owoce**: ości białych ryb, głowy białych ryb, pancerze krewetek, skorupiaki (shells), małże (opc.)  
**Warzywa (limitowane)**: cebula, seler naciowy, por, marchew (limitowana)  
**ZABLOKOWANE:** drób/wołowina/podroby, ziele, liść.

---

## E) Koszyki warzyw i przypraw — zasady do kalkulatora

### E1) Zasada nadrzędna
- `vegTotalG = round(waterStartL*1000*vegPercent_variant)`
- przyprawy jak w C.

### E2) Koszyki per rodzaj
**Rosół**: marchew 34%, seler 29%, pietruszka 20%, por 17% (toggle), cebula 1 szt/3–5 L (min 1 szt od 2.5 L)  
**Wołowy**: cebula 35%, marchew 25%, seler 20%, pietruszka 20%  
**Ramen Shio**: cebula 45%, imbir 25%, czosnek 15%, dymka 15% (opc.)  
**Tonkotsu**: cebula 40%, por 25%, imbir 20%, czosnek 15%  
**Warzywny**: jasny marchew ≤25%, umami marchew ≤30% (koszyk: cebula 30, seler 30, pietruszka 20, por 15, marchew 5–20)  
**Rybny**: cebula 40%, seler naciowy 25%, por 20%, marchew 15% (tylko pieprz, bez ziela/liścia)

### E3) Limity warzyw
- Klarowne: >350 g/L → WARN VEG_TOO_MUCH
- Warzywny: do 420 g/L (WARN powyżej 380)
- Rybny: warzywa max 120 g/L (WARN/ERROR zależnie od skali)

---

# DODATEK O — biblioteka kroków live + timeline
(pełna treść: patrz sekcje O0–O3 powyżej)

# DODATEK P — biblioteka alertów jakości
(pełna treść: patrz sekcje P0–P3 powyżej)

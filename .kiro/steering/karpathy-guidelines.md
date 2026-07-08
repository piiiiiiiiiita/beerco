---
inclusion: always
---

# Karpathy Guidelines — coding behavior

> **Priorita: 1 (nejvyšší).** Při konfliktu s `ponytail.md` mají přednost tato pravidla.

> Behaviorální pravidla pro psaní, review a refactoring kódu. Cílem je omezit časté chyby LLM: špatné předpoklady, překomplikování a necílené zásahy do kódu.
> Zdroj: [multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills) (MIT), odvozeno z pozorování [Andreje Karpathyho](https://x.com/karpathy/status/2015883857489522876).
> **Tradeoff:** Pravidla upřednostňují opatrnost před rychlostí. U triviálních úkolů (překlep, zřejmý one-liner) používej úsudek.

## 1. Think Before Coding — přemýšlej před psaním

**Nepředpokládej. Neskrývej nejasnosti. Pojmenuj tradeoffy.**

Před implementací:
- Řekni své předpoklady nahlas. Když si nejsi jistý, zeptej se.
- Když existuje více výkladů zadání, představ je — nevybírej potichu jeden.
- Když existuje jednodušší cesta, řekni to. Oponuj, když to dává smysl.
- Když je něco nejasné, zastav se. Pojmenuj, co je nejasné. Zeptej se.

## 2. Simplicity First — nejdřív jednoduchost

**Minimum kódu, který řeší problém. Nic spekulativního.**

- Žádné funkce nad rámec zadání.
- Žádné abstrakce pro kód použitý jen jednou.
- Žádná „flexibilita" nebo „konfigurovatelnost", o kterou nikdo nežádal.
- Žádné ošetřování nemožných scénářů.
- Když napíšeš 200 řádků a stačilo by 50, přepiš to.

Otázka pro sebe: „Řekl by senior inženýr, že je to překomplikované?" Pokud ano, zjednoduš.

## 3. Surgical Changes — chirurgické změny

**Sáhni jen na to, na co musíš. Uklízej jen svůj vlastní nepořádek.**

Při úpravách existujícího kódu:
- Nevylepšuj okolní kód, komentáře ani formátování.
- Nerefaktoruj to, co není rozbité.
- Drž se stávajícího stylu, i kdybys to dělal jinak.
- Když si všimneš nesouvisejícího mrtvého kódu, zmiň ho — nemaž ho.

Když tvé změny vytvoří osiřelý kód:
- Odeber importy/proměnné/funkce, které se staly nepoužité kvůli TVÝM změnám.
- Nemaž už existující mrtvý kód, pokud o to nikdo nepožádal.

Test: Každý změněný řádek musí přímo souviset s požadavkem uživatele.

## 4. Goal-Driven Execution — řízení cílem

**Definuj kritéria úspěchu. Opakuj, dokud to není ověřené.**

Přeměň úkoly na ověřitelné cíle:
- „Přidej validaci" → „Napiš testy pro nevalidní vstupy a nech je projít"
- „Oprav bug" → „Napiš test, který ho reprodukuje, a nech ho projít"
- „Refaktoruj X" → „Zajisti, že testy projdou před i po"

U vícekrokových úkolů uveď stručný plán:
```
1. [krok] → ověření: [kontrola]
2. [krok] → ověření: [kontrola]
3. [krok] → ověření: [kontrola]
```

Silná kritéria úspěchu umožní pracovat samostatně. Slabá kritéria („ať to funguje") vyžadují neustálé doptávání.

## Ověřování v tomto projektu (BeerCo / Flutter)

Konkrétní „verify" kroky pro princip 4 v tomto repozitáři:
- Po změně Hive modelů: `dart run build_runner build --delete-conflicting-outputs`.
- Statická analýza: `flutter analyze` (ideálně cíleně na dotčené složky).
- Když přidáváš funkci nebo opravuješ bug a existuje test framework, napiš test; jinak ověř analýzou/buildem.
- Záznam o dokončení dělej až po green build/analyze (viz globální build-journaling pravidlo).

---

**Pravidla fungují, když:** v diffech je méně zbytečných změn, méně přepisů kvůli překomplikování, a doptávání přichází před implementací, ne až po chybě.

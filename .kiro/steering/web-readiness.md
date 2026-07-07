---
inclusion: always
---

# Web-readiness — mobil teď, web v budoucnu

> Aplikace je primárně mobilní (iOS/Android), ale do budoucna přibude **web z téhož kódu**. Proto veškerý nový kód piš tak, aby web nerozbil. Neimplementujeme teď backend ani web UI — jen držíme kód připravený.

## Tvrdá pravidla (neporušovat)

1. **Žádné platformově vázané API bez ochrany.** Nepoužívej `dart:io`, `Platform.*`, `dart:ffi`, `path_provider` apod. přímo. Když je to nutné, izoluj to za abstrakci nebo conditional import (`if (dart.library.io)` / `if (dart.library.js)`).
2. **Před přidáním balíčku ověř WEB podporu** na pub.dev (štítek „WEB"). Bez ní web spadne. (Aktuální závislosti web zvládají: hive_ce, go_router, riverpod, flutter_slidable, intl, uuid, google_fonts.)
3. **UI nikdy nesahá přímo na úložiště.** Data jen přes repository + Riverpod providery. Až přijde cloud (Supabase/Firebase), měníme jen implementaci repository, ne UI. Počítej s tím, že cloud bude **async/stream** — nová repo API navrhuj tak, aby šla později zasynchronizovat (nevkládej synchronní Hive volání do UI).
4. **Navigace jen přes `go_router`** s URL cestami (stav ↔ URL). Žádné ad-hoc `Navigator.push` pro hlavní routy — na webu musí fungovat back tlačítko, přímé odkazy a refresh.
5. **Platform-specific efekty musí být na webu bezpečné** (no-op). Např. `HapticFeedback` na webu nic nedělá — OK, ale nikdy na jeho výsledku nezávisej.

## Responsivita (mysli dopředu)

- Nestav napevno na mobilní šířku. Nová obrazovka/komponenta má fungovat i na širokém displeji.
- Na širokých viewportech obsah **omez max šířkou** (centrovaný sloupec ~480–600 px) místo roztažení přes celou obrazovku.
- Kde má smysl rozdílný layout, použij `LayoutBuilder` / breakpointy (úzká = mobil, široká = web/tablet).
- Preferuj relativní/flex layouty před fixními rozměry, kde to jde.

## Průběžné ověřování

- Občas spusť na Chrome (`flutter run -d chrome`) a zkontroluj zobrazení + funkčnost, ať se chyby chytají brzy.
- `web/` platforma se doplní později (`flutter create --platforms web .`); do té doby aspoň drž pravidla výše.

## Aktuální stav (2026-07-07)

- Web-kompatibilní: žádné dart:io/Platform/ffi/path_provider; Hive (IndexedDB), go_router, Riverpod, ostatní balíčky OK; data oddělená od UI.
- K dořešení až u samotného webu: `web/` scaffold, responsivní layouty (teď mobile-first), případná abstrakce repository na async pro cloud sync.

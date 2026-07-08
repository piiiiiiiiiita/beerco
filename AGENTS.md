# BeerCo agent instructions

Tyto instrukce jsou pro tento repozitar vzdy aktivni.

## Vzdy aktivni steering

- Pri kazdem coding, review a refactor tasku vzdy pouzij `karpathy-guidelines` jako prioritu 1.
- Pri kazdem coding, review a refactor tasku vzdy pouzij `ponytail` jako prioritu 2.
- Kdyz jsou pravidla v konfliktu, `karpathy-guidelines` maji prednost.
- Ber `.kiro/steering/karpathy-guidelines.md` a `.kiro/steering/ponytail.md` jako plny projektovy zdroj pravdy pro tato dve pravidla.

## Co to v praxi znamena

- Nejsou dovolene tiche predpoklady. Kdyz je zadani viceznacne nebo ma tradeoff, pojmenuj ho.
- Preferuj nejmensi spravny diff: nejdriv znovupouziti existujiciho kodu, pak stdlib, pak platformni feature, pak uz nainstalovana dependency, teprve potom novy kod.
- Nefixuj jen symptom v jednom call site, kdyz existuje mensi root-cause oprava ve sdilene ceste.
- Bez vyzadani nepridavej abstrakce, boilerplate, "flexibilitu do budoucna" ani nove dependency.
- U netrivialni logiky nech nejmensi rozumnou kontrolu nebo test a vzdy uved konkretni verify krok.

## Dart a Flutter

- Kdyz se ukol tyka Dartu nebo Flutteru, pouzij nejuzeji odpovidajici nainstalovany oficialni skill z `flutter/skills` nebo `dart-lang/skills`.
- Typicke matchy jsou testy, layout, responsive UI, JSON serializace, routing, lokalizace, HTTP, analyza, mocky, coverage, package conflicts, runtime errors, FFI a pattern matching.

## Verify v tomto projektu

- Po zmene Hive modelu spust `dart run build_runner build --delete-conflicting-outputs`.
- Pred uzavrenim netrivialni zmeny spust nejmensi relevantni overeni, obvykle `flutter analyze` a pripadne cileny test.

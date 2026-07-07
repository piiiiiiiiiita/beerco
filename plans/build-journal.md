# Build journal — BeerCo

Záznamy chronologicky, nejnovější nahoře.

## 2026-07-07 — full-width stacked dialog actions

### Nové funkce
- `AppDialogActions` (`lib/core/theme/app_components.dart`) — sdílená komponenta: full-width, vertikálně skládaná dialogová tlačítka se spacingem (primary nahoře, secondary dole). `Column(stretch)` + 10px mezera.

### Změny
- Všechny dialogy převedeny na full-width stacked akce přes `AppDialogActions` (tlačítka přesunuta z `actions:` do `content`): ActiveTableScreen (rename, member name, paid, +1 all, end session, remove member, add member, random), HomeScreen (archive, delete), SummaryScreen (delete). Remove member dialog zrefaktorován z inline sloupce na `AppDialogActions`.

### Ověřeno
- `flutter analyze lib/features lib/core/theme` — No issues found.

## 2026-07-07 — dialogové Cancel/Close: TextButton → OutlinedButton

### Změny
- Všechny dialogové akce Cancel/Close (low emphasis `TextButton`) převedeny na medium emphasis `OutlinedButton` napříč: ActiveTableScreen (rename table, member name, paid „Close", +1 all, end session, add member, random orders), HomeScreen (archive, delete), SummaryScreen (delete).
- Záměrně ponecháno jako `TextButton`: UNDO v undo baru (na tmavém pozadí, amber — outlined by tam působil rozbitě) a inline „Change avatar" odkaz (`TextButton.icon`) v Add member dialogu.

### Ověřeno
- `flutter analyze lib/features/table lib/features/summary` — No issues found.

## 2026-07-07 — fix box-shadow karet (AppSurfaceCard)

### Bug & fix
- **Symptom:** Všechny row items (karty členů apod.) měly chybný/ořezaný box-shadow.
- **Root cause:** `AppSurfaceCard` měl `boxShadow` na vnitřním `Ink` uvnitř `Material`. Dekorace Inku se renderuje/ořezává v rámci Material vrstvy, takže měkký stín se nevykresloval korektně (nejvíc patrné u karet ve `Slidable`).
- **Fix:** Stín přesunut na vnější `Container` (nese color + borderRadius + boxShadow), `Material` je nyní `transparent` a drží jen `InkWell` ripple. Jedno místo → opraveno pro všechny karty v appce.
- **Ověřeno:** `flutter analyze lib/core/theme lib/features/table lib/features/summary` — No issues found.

## 2026-07-07 — menu bar peek (long-press/hover ukáže label)

### Změny
- `_MenuButton` (`active_table_menu_bar.dart`) přepsán na StatefulWidget s `_peeking`. Long-press (`onLongPressStart/End/Cancel`) i hover (`MouseRegion onEnter/onExit`) dočasně rozbalí položku a ukážou label, bez spuštění akce. Rychlý tap dál spouští akci. Rozbalení řízeno `expanded = selected || _peeking`.

### Ověřeno
- `flutter analyze .../active_table_menu_bar.dart` — No issues found.

## 2026-07-07 — dark pill menu bar (Active table)

### Nové funkce
- `ActiveTableMenuBar` + `MenuBarItemData` (`lib/features/table/presentation/widgets/active_table_menu_bar.dart`) — tmavá zaoblená spodní lišta; klepnutá položka se `AnimatedContainer`em rozbalí na ikonu + label (pill), ostatní zůstávají jako ikony. Interní `_selected` (nullable, default nic).

### Změny
- ActiveTableScreen: původní `bottomNavigationBar` (Row OutlinedButton/ElevatedButton +1 All/Random/Summary) nahrazen `ActiveTableMenuBar` s položkami Home / +1 All / Random / Summary. Home → `context.go('/')`.
- `docs/ui/mobile/design-system.md`: Active Table guidance aktualizováno o menu bar.

### Ověřeno
- `flutter analyze lib/features/table` — No issues found.

## 2026-07-07 — výběr avataru i v Add member dialogu

### Nové funkce
- `_AddMemberDialog` v ActiveTableScreen — dialog pro přidání člena s avatar preview (default `randomAvatarAsset`, tap/„Change avatar" → picker) + pole na jméno. Vrací `({String name, String avatar})`.

### Změny
- `_addMember` v ActiveTableScreen používá nový dialog a předává `avatarAsset` do `addMember`. (Dřív jen jméno, avatar zůstal deterministický.)

### Ověřeno
- `flutter analyze lib/features/table` — No issues found.

## 2026-07-07 — Member quick strip (scroll-x pod HERO)

### Nové funkce
- `MemberQuickStrip` (`lib/features/table/presentation/widgets/member_quick_strip.dart`) — horizontálně scrollovatelný pás pod HERO. První dlaždice = dashed „+" (vlastní `_DashedCirclePainter`, bez nové závislosti) → add member. Každý člen (avatar + jméno) → tap otevře edit (jméno / avatar).
- `_editMember` v ActiveTableScreen — bottom sheet s „Change name" / „Change avatar".

### Změny
- ActiveTableScreen: strip vložen mezi HERO a sekci členů. Odstraněna `person_add` ikona z app baru (add member je teď ve stripu).
- `docs/ui/mobile/design-system.md`: Active Table guidance doplněno o member quick strip.

### Ověřeno
- `flutter analyze lib/features/table` — No issues found (po zjednodušení nepoužitých parametrů painteru na konstanty).

## 2026-07-07 — avatar všude + výběr při zakládání člena

### Nové funkce
- `MemberAvatar` (`lib/features/table/presentation/widgets/member_avatar.dart`) — sdílený kruhový avatar člena: obrázek (`resolvedAvatarAsset`) s iniciálou jen jako fallback (`Image.asset errorBuilder`). Parametry diameter/ring/shadow.
- `addMember` (repo + `MembersNotifier`) přijímá `avatarAsset` → avatar lze nastavit už při zakládání člena.

### Změny
- Avatar nasazen všude místo iniciál: HERO řada, karta člena (ActiveTable), domácí `_MemberAvatarStrip`, summary `_MemberSummaryTile`. Odstraněny osiřelé `_AvatarCircle` (hero) a `_initials` (home).
- `NewTableScreen`: pending člen je nově `_PendingMember{name, avatar}` s defaultně náhodným avatarem; klepnutí na avatar v seznamu otevře picker; avatar se uloží při vytvoření stolu.

### Ověřeno
- `flutter analyze lib/features/table lib/features/summary lib/core/theme` — No issues found.

## 2026-07-07 — výběr avataru pro členy

### Nové funkce
- `MemberModel.avatarAsset` (`@HiveField(6)`, nullable) — uložený zvolený avatar člena. Adaptér regenerován (zpětně kompatibilní).
- `lib/features/table/data/member_avatars.dart` — přesunut seznam `memberAvatarAssets` + helpery `avatarAssetForMember`, `resolvedAvatarAsset`, `randomAvatarAsset` (sdílí HERO, picker, karta člena).
- `showAvatarPickerSheet(...)` (`lib/features/table/presentation/widgets/avatar_picker_sheet.dart`) — bottom sheet s gridem avatarů + tlačítkem Random; vrací zvolený asset.
- `MembersNotifier.setAvatar(member, asset)` — uloží avatar a refreshne.

### Změny
- ActiveTableScreen: v member options sheetu přibylo „Change avatar" → otevře picker → `setAvatar`. Karta člena i HERO řada zobrazují `resolvedAvatarAsset` (zvolený, jinak deterministický fallback). Iniciála na kartě člena nahrazena obrázkem avataru.
- `docs/ui/mobile/design-system.md`: sekce Avatars aktualizována (výběr Random/konkrétní + fallback).

### Ověřeno
- `dart run build_runner build` + `flutter analyze lib/features/table lib/core/theme` — No issues found.

## 2026-07-07 — Table Hero komponenta

### Nové funkce
- `TableHeroCard` (`lib/features/table/presentation/widgets/table_hero_card.dart`) — hero karta aktivního stolu: nerovnoměrný tvar (top 28 / bottom 44), jedna barva + top-left radial light (ne inner shadow), soft stín. Uvnitř: creator chip (top-left, offline = iniciál názvu stolu; připraveno na online přes `creatorName`/`creatorAvatarAsset`), pencil edit (top-right, existující `AppIconCircleButton` → rename), pill s názvem stolu, velké číslo = počet objednávek + „objednávek", řada překrývajících se avatarů členů.
- Character avatar set: složka `assets/images/avatars/` zaregistrována v `pubspec.yaml`. Konstanta `memberAvatarAssets` + `avatarAssetForMember(id)` mapují člena na avatar deterministicky přes `id.hashCode`.

### Změny
- ActiveTableScreen: starý horní `AppSurfaceCard` (název + tagline + 3 stat pills) nahrazen `TableHeroCard`. Edit ikona odstraněna z AppBaru (rename teď žije v HERO), aby nebyla duplicitní. Stat pills orders/active/paid z hlavičky odebrány (info zůstává v member sekcích níže).
- `docs/ui/mobile/design-system.md`: přidána komponenta „Table Hero", sekce „Avatars", aktualizováno Active Table guidance.

### Ověřeno
- `flutter pub get` (registrace assetů) + `flutter analyze lib/features/table lib/core/theme` — No issues found.

## 2026-07-07 — soft UI redesign (ActiveTable + design system)

### Změny
- `AppSurfaceCard` (`lib/core/theme/app_components.dart`): odstraněn 1px border, přechod na soft-UI dvouvrstvý jemný stín (ambient 5%/24/(0,12) + contact 3%/6/(0,2)). Platí pro všechny karty v appce.
- ActiveTableScreen (`lib/features/table/presentation/screens/active_table_screen.dart`): avatar člena je nově kruhový s 2px bílým prstencem a jemným stínem; spodní akční lišta bez tvrdé horní čáry, s jemným stínem nahoru. Tlačítka ponechána (AppPrimaryButton / AppIconCircleButton / OutlinedButton).
- `docs/ui/mobile/design-system.md`: sekce Shadows and Borders, Surface Card a Member Card upraveny na borderless soft-UI karty a kruhový avatar s prstencem.

### Ověřeno
- `flutter analyze lib/core/theme lib/features/table/presentation/screens` — No issues found.

## 2026-07-07 — glass header na detail screeny + fix overflow

### Nové funkce
- `glassAppBar(...)` (`lib/core/theme/app_components.dart`) — sdílený frosted-glass AppBar (`BackdropFilter` blur sigma 18 + bílá 0.7 + spodní border). Použít se `Scaffold(extendBodyBehindAppBar: true)`.

### Změny
- Glassmorphism header přesunut z HomeScreen na detail screeny: `ActiveTableScreen` a `SummaryScreen` teď používají `glassAppBar` + `extendBodyBehindAppBar: true` + horní padding obsahu `MediaQuery.padding.top + kToolbarHeight + 12`, takže obsah scrolluje pod blur.
- HomeScreen vrácen na normální (neglass) `_HomeHeader` v `Column`+`ListView`; tlačítko „Nové sezení" zůstává v `bottomNavigationBar`.

### Bug & fix
- **Symptom:** Na home „BOTTOM OVERFLOWED BY 11 PIXELS" (žlutočerný pruh pod hlavičkou po hot reloadu).
- **Root cause:** `_GlassHeaderDelegate` měl pevnou výšku obsahu 150 px, do níž se sloupec (emoji + název + podtitulek) nevešel.
- **Fix:** Odstraněn `SliverPersistentHeader` s fixní výškou z home; hlavička je zpět `Column`-sized (roste podle obsahu). Glass efekt nahrazen nativním `AppBar` s `flexibleSpace` na detail screenech (žádná pevná výška, používá `kToolbarHeight`).

### Ověřeno
- `flutter analyze lib/features/table/presentation/screens lib/features/summary lib/core/theme` — No issues found.

## 2026-07-07 — summary (dynamický počet piv + Per member)

### Nové funkce
- Per member tile (`lib/features/summary/presentation/screens/summary_screen.dart`) u zaplaceného člena zobrazuje zelený subtitle `paid - {počet} piv`.

### Změny
- Odebráno uložené pole `beerCount` z `TableEventModel` — počet piv u „paid" se už nezamrzává při zaplacení, ale počítá se dynamicky z aktuálních objednávek člena (`ordersNotifier.getCountForMember`). Platí pro Member log i Timeline. Důsledek: po opětovném označení člena jako aktivního a přidání dalších piv se počet u paid záznamu přepočítá.
- Adaptér `table_event_model.g.dart` regenerován (zpět na 6 polí, zpětně kompatibilní se staršími záznamy s polem 6).

### Ověřeno
- `dart run build_runner build --delete-conflicting-outputs` — OK.
- `flutter analyze lib/features/summary lib/features/table` — No issues found.

## 2026-07-07 — summary (Member log & Timeline)

### Nové funkce
- Počet piv u „paid" události (`lib/features/table/data/models/table_event_model.dart`) — přidáno nepovinné pole `beerCount` (`@HiveField(6)`), aby se u zaplacení uložilo, kolik piv měl člen v ten moment. Zpětně kompatibilní: staré události bez pole čtou `null` → zobrazí se `0 piv`.
- `TableRepository.markMemberPaid` (`lib/features/table/data/repositories/table_repository.dart`) nyní počítá piva člena přes nový helper `_beerCountForMember` a ukládá je do události.
- Member log v Summary (`lib/features/summary/presentation/screens/summary_screen.dart`) zobrazuje `{jméno} paid - {počet} piv` se zeleným zvýrazněním.
- Timeline v Summary nově obsahuje i „paid" události (sloučené s objednávkami chronologicky), se stejným zeleným vzhledem a ikonou `check_circle`. Přidána pomocná třída `_TimelineEntry`.

### Ověřeno
- `dart run build_runner build --delete-conflicting-outputs` — OK (adaptér regenerován, pole 6 přidáno).
- `flutter analyze lib/features/summary lib/features/table/data` — No issues found.

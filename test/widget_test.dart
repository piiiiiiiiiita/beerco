import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/screens/home_screen.dart';
import 'package:beerco/features/table/presentation/screens/new_table_screen.dart';

void main() {
  Widget buildNewTableScreen() {
    return const ProviderScope(child: MaterialApp(home: NewTableScreen()));
  }

  testWidgets('NewTableScreen adds and removes members', (tester) async {
    await tester.pumpWidget(buildNewTableScreen());

    expect(find.text('Add your friends to get started'), findsOneWidget);
    expect(find.text('Start (0 members)'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'Petr');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('Petr'), findsOneWidget);
    expect(find.text('Start (1 member)'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();

    expect(find.text('Petr'), findsNothing);
    expect(find.text('Start (0 members)'), findsOneWidget);
  });

  testWidgets('NewTableScreen requires at least one member', (tester) async {
    await tester.pumpWidget(buildNewTableScreen());

    await tester.tap(find.text('Start (0 members)'));
    await tester.pump();

    expect(find.text('Add at least one member'), findsOneWidget);
  });

  testWidgets('HomeScreen shows active and archived tables', (tester) async {
    final activeTable = TableModel(
      id: 'active-table',
      name: 'Friday beers',
      createdAt: DateTime(2026, 7, 6, 18),
    );
    final archivedTable = TableModel(
      id: 'archived-table',
      name: 'Saturday bill',
      createdAt: DateTime(2026, 7, 5, 22),
      isActive: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTablesProvider.overrideWithValue([activeTable]),
          archivedTablesProvider.overrideWithValue([archivedTable]),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('Active tables'), findsOneWidget);
    expect(find.text('Friday beers'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Saturday bill'), findsOneWidget);
  });
}

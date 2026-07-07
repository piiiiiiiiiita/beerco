import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/screens/home_screen.dart';
import 'package:beerco/features/table/presentation/screens/new_table_screen.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beerco_widget_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TableModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(MemberModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(OrderModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(TableEventModelAdapter());
    }
    await Hive.openBox<TableModel>('tables');
    await Hive.openBox<MemberModel>('members');
    await Hive.openBox<TableEventModel>('table_events');
    await Hive.openBox<OrderModel>('orders');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

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

    await tester.tap(find.byIcon(Icons.close_rounded));
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

  testWidgets('HomeScreen shows brand and main sections', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeTablesProvider.overrideWithValue(const []),
          archivedTablesProvider.overrideWithValue(const []),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    expect(find.text('BeerCo'), findsOneWidget);
    expect(find.text('Nové sezení'), findsOneWidget);
    expect(find.text('Aktivní stoly'), findsOneWidget);
    expect(find.text('Historie'), findsOneWidget);
    expect(find.text('Zatím nic neběží'), findsOneWidget);
    expect(find.text('Historie je prázdná'), findsOneWidget);
  });
}

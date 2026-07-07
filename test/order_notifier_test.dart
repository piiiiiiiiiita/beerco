import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/order/data/repositories/order_repository.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beerco_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(OrderModelAdapter());
    }
    await Hive.openBox<OrderModel>('orders');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('undoLastOrder removes the whole last group order action', () async {
    final notifier = OrdersNotifier(OrderRepository(), 'table-1');

    await notifier.addOrderForAll(['member-1', 'member-2'], ['Petr', 'Mai']);

    expect(notifier.state, hasLength(2));

    await notifier.undoLastOrder();

    expect(notifier.state, isEmpty);
  });

  test('undoLastOrder keeps previous actions', () async {
    final notifier = OrdersNotifier(OrderRepository(), 'table-1');

    await notifier.addOrder('member-1', 'Petr');
    await notifier.addOrderForAll(['member-1', 'member-2'], ['Petr', 'Mai']);

    expect(notifier.state, hasLength(3));

    await notifier.undoLastOrder();

    expect(notifier.state, hasLength(1));
    expect(notifier.state.single.memberName, 'Petr');
  });

  test(
    'removeLastOrderForMember removes only that member latest order',
    () async {
      final notifier = OrdersNotifier(OrderRepository(), 'table-1');

      await notifier.addOrder('member-1', 'Petr');
      await notifier.addOrder('member-2', 'Mai');
      await notifier.addOrder('member-1', 'Petr');

      await notifier.removeLastOrderForMember('member-1');

      expect(notifier.getCountForMember('member-1'), 1);
      expect(notifier.getCountForMember('member-2'), 1);
    },
  );

  test('addRandomOrders allows more orders than active members', () async {
    final notifier = OrdersNotifier(OrderRepository(), 'table-1');

    await notifier.addRandomOrders(
      ['member-1', 'member-2'],
      ['Petr', 'Mai'],
      5,
    );

    expect(notifier.state, hasLength(5));
  });
}

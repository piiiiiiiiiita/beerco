import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/data/repositories/table_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('beerco_table_test_');
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

  test('creates a table and stores members for it', () async {
    final repository = TableRepository();

    final table = await repository.createTable('Friday beers');
    await repository.addMember(table.id, 'Petr');
    await repository.addMember(table.id, 'Mai');

    expect(repository.getActiveTables(), hasLength(1));
    expect(repository.getTable(table.id)?.name, 'Friday beers');
    expect(repository.getMembersForTable(table.id).map((m) => m.name), [
      'Petr',
      'Mai',
    ]);
  });

  test('archiveTable moves a table out of active tables', () async {
    final repository = TableRepository();
    final table = await repository.createTable('');

    await repository.archiveTable(table.id);

    expect(repository.getActiveTables(), isEmpty);
    expect(repository.getArchivedTables().single.id, table.id);
  });

  test('reactivateTable moves a table back to active tables', () async {
    final repository = TableRepository();
    final table = await repository.createTable('Friday beers');

    await repository.archiveTable(table.id);
    await repository.reactivateTable(table.id);

    expect(repository.getArchivedTables(), isEmpty);
    expect(repository.getActiveTables().single.id, table.id);
  });

  test('updates an existing member name', () async {
    final repository = TableRepository();
    final table = await repository.createTable('Friday beers');
    final member = await repository.addMember(table.id, 'Petr');

    member.name = 'Petr M.';
    await repository.updateMember(member);

    expect(repository.getMembersForTable(table.id).single.name, 'Petr M.');
  });

  test('removes a member from the table', () async {
    final repository = TableRepository();
    final table = await repository.createTable('Friday beers');
    final member = await repository.addMember(table.id, 'Petr');

    await repository.removeMember(member);

    expect(repository.getMembersForTable(table.id), isEmpty);
  });

  test('renames an existing table', () async {
    final repository = TableRepository();
    final table = await repository.createTable('Friday beers');

    await repository.renameTable(table.id, 'Saturday beers');

    expect(repository.getTable(table.id)?.name, 'Saturday beers');
  });

  test('deletes an archived table and related members and orders', () async {
    final repository = TableRepository();
    final ordersBox = Hive.box<OrderModel>('orders');
    final eventsBox = Hive.box<TableEventModel>('table_events');
    final table = await repository.createTable('Friday beers');
    final member = await repository.addMember(table.id, 'Petr');

    await ordersBox.add(
      OrderModel(
        id: 'order-1',
        tableId: table.id,
        memberId: member.id,
        memberName: member.name,
        timestamp: DateTime.now(),
      ),
    );
    await eventsBox.add(
      TableEventModel(
        id: 'event-1',
        tableId: table.id,
        memberId: member.id,
        memberName: member.name,
        type: 'paid',
        timestamp: DateTime.now(),
      ),
    );
    await repository.archiveTable(table.id);

    await repository.deleteTable(table.id);

    expect(repository.getTable(table.id), isNull);
    expect(repository.getMembersForTable(table.id), isEmpty);
    expect(
      eventsBox.values.where((event) => event.tableId == table.id),
      isEmpty,
    );
    expect(
      ordersBox.values.where((order) => order.tableId == table.id),
      isEmpty,
    );
  });

  test('member paid and active again events are logged', () async {
    final repository = TableRepository();
    final ordersBox = Hive.box<OrderModel>('orders');
    final table = await repository.createTable('Friday beers');
    final member = await repository.addMember(table.id, 'Petr');

    await ordersBox.add(
      OrderModel(
        id: 'order-before-paid',
        tableId: table.id,
        memberId: member.id,
        memberName: member.name,
        timestamp: DateTime.now(),
      ),
    );

    await repository.markMemberPaid(member.id);
    await repository.markMemberUnpaid(member.id);

    final events = repository.getEventsForTable(table.id);
    expect(events.map((event) => event.type), ['paid', 'active_again']);
  });

  test(
    'marking paid again without new orders restores previous paid state and does not log 0 paid',
    () async {
      final repository = TableRepository();
      final ordersBox = Hive.box<OrderModel>('orders');
      final table = await repository.createTable('Friday beers');
      final member = await repository.addMember(table.id, 'Petr');

      await ordersBox.add(
        OrderModel(
          id: 'order-1',
          tableId: table.id,
          memberId: member.id,
          memberName: member.name,
          timestamp: DateTime.now(),
        ),
      );

      await repository.markMemberPaid(member.id);
      final firstPaidAt = repository.getMembersForTable(table.id).single.paidAt;

      await repository.markMemberUnpaid(member.id);
      await repository.markMemberPaid(member.id);

      final updatedMember = repository.getMembersForTable(table.id).single;
      final events = repository.getEventsForTable(table.id);

      expect(updatedMember.isPaid, isTrue);
      expect(updatedMember.paidAt, firstPaidAt);
      expect(events.map((event) => event.type), ['paid', 'active_again']);
    },
  );
}

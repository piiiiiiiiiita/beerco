import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:beerco/features/table/data/models/member_model.dart';
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
    await Hive.openBox<TableModel>('tables');
    await Hive.openBox<MemberModel>('members');
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
}

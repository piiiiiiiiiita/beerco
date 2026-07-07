import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';

class TableRepository {
  final Box<TableModel> _tableBox = Hive.box<TableModel>('tables');
  final Box<MemberModel> _memberBox = Hive.box<MemberModel>('members');
  final Box<TableEventModel> _tableEventBox = Hive.box<TableEventModel>(
    'table_events',
  );
  final Box<OrderModel> _orderBox = Hive.box<OrderModel>('orders');
  final _uuid = const Uuid();

  // Tables
  List<TableModel> getAllTables() => _tableBox.values.toList();

  List<TableModel> getActiveTables() =>
      _tableBox.values.where((t) => t.isActive).toList();

  List<TableModel> getArchivedTables() =>
      _tableBox.values.where((t) => !t.isActive).toList();

  TableModel? getTable(String id) =>
      _tableBox.values.where((t) => t.id == id).firstOrNull;

  Future<TableModel> createTable(String name) async {
    final table = TableModel(
      id: _uuid.v4(),
      name: name.isEmpty ? 'Table ${_tableBox.length + 1}' : name,
      createdAt: DateTime.now(),
    );
    await _tableBox.add(table);
    return table;
  }

  Future<void> archiveTable(String tableId) async {
    final table = getTable(tableId);
    if (table != null) {
      table.isActive = false;
      await table.save();
    }
  }

  Future<void> reactivateTable(String tableId) async {
    final table = getTable(tableId);
    if (table != null) {
      table.isActive = true;
      await table.save();
    }
  }

  Future<void> renameTable(String tableId, String newName) async {
    final table = getTable(tableId);
    if (table != null && newName.trim().isNotEmpty) {
      table.name = newName.trim();
      await table.save();
    }
  }

  Future<void> deleteTable(String tableId) async {
    final table = getTable(tableId);
    if (table == null) return;

    final members = _memberBox.values
        .where((m) => m.tableId == tableId)
        .toList();
    final events = _tableEventBox.values
        .where((event) => event.tableId == tableId)
        .toList();
    final orders = _orderBox.values.where((o) => o.tableId == tableId).toList();

    for (final order in orders) {
      await order.delete();
    }
    for (final event in events) {
      await event.delete();
    }
    for (final member in members) {
      await member.delete();
    }
    await table.delete();
  }

  List<TableEventModel> getEventsForTable(String tableId) =>
      _tableEventBox.values.where((event) => event.tableId == tableId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  Future<void> addEvent({
    required String tableId,
    required String memberId,
    required String memberName,
    required String type,
  }) async {
    await _tableEventBox.add(
      TableEventModel(
        id: _uuid.v4(),
        tableId: tableId,
        memberId: memberId,
        memberName: memberName,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  // Members
  List<MemberModel> getMembersForTable(String tableId) =>
      _memberBox.values.where((m) => m.tableId == tableId).toList();

  Future<MemberModel> addMember(
    String tableId,
    String name, {
    String? emoji,
    String? avatarAsset,
  }) async {
    final member = MemberModel(
      id: _uuid.v4(),
      tableId: tableId,
      name: name,
      emoji: emoji,
      avatarAsset: avatarAsset,
    );
    await _memberBox.add(member);
    return member;
  }

  Future<void> updateMember(MemberModel member) async {
    await member.save();
  }

  Future<void> removeMember(MemberModel member) async {
    await member.delete();
  }

  Future<void> markMemberPaid(String memberId) async {
    final member = _memberBox.values.where((m) => m.id == memberId).firstOrNull;
    if (member != null) {
      member.isPaid = true;
      member.paidAt = DateTime.now();
      await member.save();
      await addEvent(
        tableId: member.tableId,
        memberId: member.id,
        memberName: member.name,
        type: 'paid',
      );
    }
  }

  Future<void> markMemberUnpaid(String memberId) async {
    final member = _memberBox.values.where((m) => m.id == memberId).firstOrNull;
    if (member != null) {
      member.isPaid = false;
      member.paidAt = null;
      await member.save();
      await addEvent(
        tableId: member.tableId,
        memberId: member.id,
        memberName: member.name,
        type: 'active_again',
      );
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beerco/core/utils/notification_service.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/repositories/table_repository.dart';

final tableRepositoryProvider = Provider<TableRepository>(
  (ref) => TableRepository(),
);

// All active tables for continuing an open session
final activeTablesProvider = Provider<List<TableModel>>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.getActiveTables()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// All archived tables for history screen
final archivedTablesProvider = Provider<List<TableModel>>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.getArchivedTables()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

// Single table
final tableProvider = Provider.family<TableModel?, String>((ref, tableId) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.getTable(tableId);
});

final tableEventsProvider = Provider.family<List<TableEventModel>, String>((
  ref,
  tableId,
) {
  final repo = ref.watch(tableRepositoryProvider);
  return repo.getEventsForTable(tableId);
});

// Members for a table
final membersProvider =
    StateNotifierProvider.family<MembersNotifier, List<MemberModel>, String>((
      ref,
      tableId,
    ) {
      final repo = ref.watch(tableRepositoryProvider);
      return MembersNotifier(repo, tableId);
    });

class MembersNotifier extends StateNotifier<List<MemberModel>> {
  final TableRepository _repo;
  final String _tableId;

  MembersNotifier(this._repo, this._tableId)
    : super(_repo.getMembersForTable(_tableId));

  void refresh() {
    state = _repo.getMembersForTable(_tableId);
  }

  Future<void> addMember(
    String name, {
    String? emoji,
    String? avatarAsset,
  }) async {
    await _repo.addMember(
      _tableId,
      name,
      emoji: emoji,
      avatarAsset: avatarAsset,
    );
    refresh();
  }

  Future<void> removeMember(MemberModel member) async {
    await NotificationService.instance.cancelMemberTimerNotifications(
      member.id,
    );
    await _repo.removeMember(member);
    refresh();
  }

  Future<void> markPaid(String memberId) async {
    await NotificationService.instance.cancelMemberTimerNotifications(memberId);
    final createdPaidEvent = await _repo.markMemberPaid(memberId);
    refresh();
    if (!createdPaidEvent) return;

    final member = state.where((m) => m.id == memberId).firstOrNull;
    await NotificationService.instance.showMemberPaidNotification(
      memberName: member?.name ?? 'A member',
      tableName: _repo.getTable(_tableId)?.name,
    );
  }

  Future<void> markUnpaid(String memberId) async {
    await _repo.markMemberUnpaid(memberId);
    refresh();
  }

  Future<void> setTimerAt(String memberId, DateTime endsAt) async {
    final member = await _repo.setMemberTimer(memberId, endsAt);
    refresh();
    if (member == null) return;
    await NotificationService.instance.syncMemberTimerNotification(
      member.id,
      _repo,
    );
  }

  Future<void> clearTimer(String memberId) async {
    await NotificationService.instance.cancelMemberTimerNotifications(memberId);
    await _repo.clearMemberTimer(memberId);
    refresh();
  }

  Future<void> updateName(MemberModel member, String newName) async {
    final renamedMember = await _repo.renameMember(member.id, newName);
    refresh();
    if (renamedMember == null) return;
    await NotificationService.instance.syncMemberTimerNotification(
      renamedMember.id,
      _repo,
    );
  }

  Future<void> setAvatar(MemberModel member, String? avatarAsset) async {
    member.avatarAsset = avatarAsset;
    await _repo.updateMember(member);
    refresh();
  }
}

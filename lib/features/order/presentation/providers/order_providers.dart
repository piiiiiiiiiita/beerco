import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/order/data/repositories/order_repository.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/repositories/table_repository.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(),
);

final ordersProvider =
    StateNotifierProvider.family<OrdersNotifier, List<OrderModel>, String>((
      ref,
      tableId,
    ) {
      final orderRepo = ref.watch(orderRepositoryProvider);
      final tableRepo = ref.watch(tableRepositoryProvider);
      return OrdersNotifier(orderRepo, tableId, tableRepo);
    });

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final OrderRepository _orderRepo;
  final TableRepository? _tableRepo;
  final String _tableId;
  List<OrderModel> _lastOrders = [];

  OrdersNotifier(this._orderRepo, this._tableId, [this._tableRepo])
    : super(_orderRepo.getOrdersForTable(_tableId));

  void refresh() {
    state = _orderRepo.getOrdersForTable(_tableId);
  }

  Future<void> addOrder(String memberId, String memberName) async {
    _lastOrders = [await _orderRepo.addOrder(_tableId, memberId, memberName)];
    refresh();
  }

  Future<void> undoLastOrder() async {
    if (_lastOrders.isEmpty) return;
    for (final order in _lastOrders) {
      await _orderRepo.removeOrder(order.id);
    }
    _lastOrders = [];
    refresh();
  }

  Future<void> addOrderForAll(
    List<String> memberIds,
    List<String> memberNames,
  ) async {
    final created = <OrderModel>[];
    for (var i = 0; i < memberIds.length; i++) {
      created.add(
        await _orderRepo.addOrder(_tableId, memberIds[i], memberNames[i]),
      );
    }
    _lastOrders = created;
    refresh();
  }

  Future<void> addRandomOrders(
    List<String> memberIds,
    List<String> memberNames,
    int count,
  ) async {
    final created = <OrderModel>[];
    for (var i = 0; i < count; i++) {
      final idx = (List.generate(memberIds.length, (i) => i)..shuffle()).first;
      created.add(
        await _orderRepo.addOrder(_tableId, memberIds[idx], memberNames[idx]),
      );
    }
    _lastOrders = created;
    refresh();
  }

  Future<void> removeLastOrderForMember(String memberId) async {
    final memberOrders = getOrdersForMember(memberId);
    final lastOrder = memberOrders.lastOrNull;
    if (lastOrder == null) return;

    await _orderRepo.removeOrder(lastOrder.id);
    _lastOrders = [];
    refresh();
  }

  int getCountForMember(String memberId) {
    if (_tableRepo == null) {
      return getTotalCountForMember(memberId);
    }
    final member = _memberFor(memberId);
    final segmentOrders = _ordersForVisibleSegment(memberId, member);
    return segmentOrders.fold(0, (sum, o) => sum + o.quantity);
  }

  int getTotalCountForMember(String memberId) => state
      .where((o) => o.memberId == memberId)
      .fold(0, (sum, o) => sum + o.quantity);

  List<OrderModel> getOrdersForMember(String memberId) =>
      state.where((o) => o.memberId == memberId).toList();

  int getCountForPaidEvent(String memberId, DateTime paidAt) {
    final segmentStart = _latestActiveAgainBefore(memberId, paidAt);
    return state
        .where((o) => o.memberId == memberId)
        .where((o) => segmentStart == null || o.timestamp.isAfter(segmentStart))
        .where((o) => !o.timestamp.isAfter(paidAt))
        .fold(0, (sum, o) => sum + o.quantity);
  }

  OrderModel? get lastOrder => _lastOrders.lastOrNull;

  MemberModel? _memberFor(String memberId) => _tableRepo
      ?.getMembersForTable(_tableId)
      .where((member) => member.id == memberId)
      .firstOrNull;

  List<TableEventModel> _eventsForMember(String memberId) =>
      _tableRepo
          ?.getEventsForTable(_tableId)
          .where((event) => event.memberId == memberId)
          .toList() ??
      const [];

  DateTime? _latestActiveAgainBefore(String memberId, DateTime segmentEnd) {
    return _eventsForMember(memberId)
        .where((event) => event.type == 'active_again')
        .where((event) => !event.timestamp.isAfter(segmentEnd))
        .map((event) => event.timestamp)
        .lastOrNull;
  }

  List<OrderModel> _ordersForVisibleSegment(
    String memberId,
    MemberModel? member,
  ) {
    final segmentEnd = member?.isPaid == true ? member?.paidAt : null;
    final segmentStart = segmentEnd == null
        ? _eventsForMember(memberId)
              .where((event) => event.type == 'active_again')
              .map((event) => event.timestamp)
              .lastOrNull
        : _latestActiveAgainBefore(memberId, segmentEnd);

    return state
        .where((o) => o.memberId == memberId)
        .where((o) => segmentStart == null || o.timestamp.isAfter(segmentStart))
        .where((o) => segmentEnd == null || !o.timestamp.isAfter(segmentEnd))
        .toList();
  }
}

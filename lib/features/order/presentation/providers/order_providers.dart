import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/order/data/repositories/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => OrderRepository(),
);

final ordersProvider =
    StateNotifierProvider.family<OrdersNotifier, List<OrderModel>, String>((
      ref,
      tableId,
    ) {
      final repo = ref.watch(orderRepositoryProvider);
      return OrdersNotifier(repo, tableId);
    });

class OrdersNotifier extends StateNotifier<List<OrderModel>> {
  final OrderRepository _repo;
  final String _tableId;
  List<OrderModel> _lastOrders = [];

  OrdersNotifier(this._repo, this._tableId)
    : super(_repo.getOrdersForTable(_tableId));

  void refresh() {
    state = _repo.getOrdersForTable(_tableId);
  }

  Future<void> addOrder(String memberId, String memberName) async {
    _lastOrders = [await _repo.addOrder(_tableId, memberId, memberName)];
    refresh();
  }

  Future<void> undoLastOrder() async {
    if (_lastOrders.isEmpty) return;
    for (final order in _lastOrders) {
      await _repo.removeOrder(order.id);
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
      created.add(await _repo.addOrder(_tableId, memberIds[i], memberNames[i]));
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
        await _repo.addOrder(_tableId, memberIds[idx], memberNames[idx]),
      );
    }
    _lastOrders = created;
    refresh();
  }

  Future<void> removeLastOrderForMember(String memberId) async {
    final memberOrders = getOrdersForMember(memberId);
    final lastOrder = memberOrders.lastOrNull;
    if (lastOrder == null) return;

    await _repo.removeOrder(lastOrder.id);
    _lastOrders = [];
    refresh();
  }

  int getCountForMember(String memberId) => state
      .where((o) => o.memberId == memberId)
      .fold(0, (sum, o) => sum + o.quantity);

  List<OrderModel> getOrdersForMember(String memberId) =>
      state.where((o) => o.memberId == memberId).toList();

  OrderModel? get lastOrder => _lastOrders.lastOrNull;
}

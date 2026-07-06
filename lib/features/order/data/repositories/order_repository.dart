import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:beerco/features/order/data/models/order_model.dart';

class OrderRepository {
  final Box<OrderModel> _orderBox = Hive.box<OrderModel>('orders');
  final _uuid = const Uuid();

  List<OrderModel> getOrdersForTable(String tableId) =>
      _orderBox.values.where((o) => o.tableId == tableId).toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  List<OrderModel> getOrdersForMember(String tableId, String memberId) =>
      _orderBox.values
          .where((o) => o.tableId == tableId && o.memberId == memberId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

  int getOrderCountForMember(String tableId, String memberId) =>
      _orderBox.values
          .where((o) => o.tableId == tableId && o.memberId == memberId)
          .fold(0, (sum, o) => sum + o.quantity);

  Future<OrderModel> addOrder(String tableId, String memberId, String memberName) async {
    final order = OrderModel(
      id: _uuid.v4(),
      tableId: tableId,
      memberId: memberId,
      memberName: memberName,
      timestamp: DateTime.now(),
    );
    await _orderBox.add(order);
    return order;
  }

  Future<void> removeOrder(String orderId) async {
    final order = _orderBox.values.where((o) => o.id == orderId).firstOrNull;
    if (order != null) await order.delete();
  }

  Future<OrderModel?> getLastOrder(String tableId) async {
    final orders = getOrdersForTable(tableId);
    return orders.isEmpty ? null : orders.last;
  }
}

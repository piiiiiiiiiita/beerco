import 'package:hive_ce/hive.dart';

part 'order_model.g.dart';

@HiveType(typeId: 2)
class OrderModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tableId;

  @HiveField(2)
  final String memberId;

  @HiveField(3)
  final String memberName;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final int quantity;

  OrderModel({
    required this.id,
    required this.tableId,
    required this.memberId,
    required this.memberName,
    required this.timestamp,
    this.quantity = 1,
  });
}

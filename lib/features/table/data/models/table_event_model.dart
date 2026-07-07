import 'package:hive_ce/hive.dart';

part 'table_event_model.g.dart';

@HiveType(typeId: 3)
class TableEventModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tableId;

  @HiveField(2)
  final String memberId;

  @HiveField(3)
  final String memberName;

  @HiveField(4)
  final String type;

  @HiveField(5)
  final DateTime timestamp;

  TableEventModel({
    required this.id,
    required this.tableId,
    required this.memberId,
    required this.memberName,
    required this.type,
    required this.timestamp,
  });
}

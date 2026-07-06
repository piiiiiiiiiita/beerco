import 'package:hive_ce/hive.dart';

part 'table_model.g.dart';

@HiveType(typeId: 0)
class TableModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  bool isActive;

  TableModel({
    required this.id,
    required this.name,
    required this.createdAt,
    this.isActive = true,
  });
}

import 'package:hive_ce/hive.dart';

part 'member_model.g.dart';

@HiveType(typeId: 1)
class MemberModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String tableId;

  @HiveField(2)
  String name;

  @HiveField(3)
  String? emoji;

  @HiveField(4)
  bool isPaid;

  @HiveField(5)
  DateTime? paidAt;

  MemberModel({
    required this.id,
    required this.tableId,
    required this.name,
    this.emoji,
    this.isPaid = false,
    this.paidAt,
  });
}

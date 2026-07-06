import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/order/data/models/order_model.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(TableModelAdapter());
  Hive.registerAdapter(MemberModelAdapter());
  Hive.registerAdapter(OrderModelAdapter());
  await Hive.openBox<TableModel>('tables');
  await Hive.openBox<MemberModel>('members');
  await Hive.openBox<OrderModel>('orders');
}

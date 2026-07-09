import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/order/data/models/order_model.dart';

Future<void> initHive() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(TableModelAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(MemberModelAdapter());
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TableEventModelAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(OrderModelAdapter());
  if (!Hive.isBoxOpen('tables')) await Hive.openBox<TableModel>('tables');
  if (!Hive.isBoxOpen('members')) await Hive.openBox<MemberModel>('members');
  if (!Hive.isBoxOpen('table_events')) {
    await Hive.openBox<TableEventModel>('table_events');
  }
  if (!Hive.isBoxOpen('orders')) await Hive.openBox<OrderModel>('orders');
}

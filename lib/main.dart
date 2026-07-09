import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/core/router/app_router.dart';
import 'package:beerco/core/utils/hive_init.dart';
import 'package:beerco/core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();
  await NotificationService.instance.initialize();
  runApp(const ProviderScope(child: BeerCoApp()));
}

class BeerCoApp extends ConsumerWidget {
  const BeerCoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'BeerCo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}

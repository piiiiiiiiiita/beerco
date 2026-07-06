import 'package:go_router/go_router.dart';
import 'package:beerco/features/table/presentation/screens/home_screen.dart';
import 'package:beerco/features/table/presentation/screens/new_table_screen.dart';
import 'package:beerco/features/table/presentation/screens/active_table_screen.dart';
import 'package:beerco/features/summary/presentation/screens/summary_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/new-table',
      builder: (context, state) => const NewTableScreen(),
    ),
    GoRoute(
      path: '/table/:tableId',
      builder: (context, state) {
        final tableId = state.pathParameters['tableId']!;
        return ActiveTableScreen(tableId: tableId);
      },
    ),
    GoRoute(
      path: '/table/:tableId/summary',
      builder: (context, state) {
        final tableId = state.pathParameters['tableId']!;
        return SummaryScreen(tableId: tableId);
      },
    ),
  ],
);

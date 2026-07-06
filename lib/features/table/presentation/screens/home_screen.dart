import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/core/theme/app_theme.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTablesProvider);
    final archived = ref.watch(archivedTablesProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              const Text('🍺', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'BeerCo',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Track orders. Check the bill.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.push('/new-table'),
                child: const Text('New Table'),
              ),
              if (active.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Active tables',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...active
                    .take(5)
                    .map((t) => _TableTile(table: t, isActive: true)),
              ],
              if (archived.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...archived.take(5).map((t) => _TableTile(table: t)),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableTile extends StatelessWidget {
  final TableModel table;
  final bool isActive;
  const _TableTile({required this.table, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM, HH:mm');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.table_bar_outlined),
        title: Text(
          table.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          fmt.format(table.createdAt),
          style: TextStyle(color: AppColors.mutedLight, fontSize: 13),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(
          isActive ? '/table/${table.id}' : '/table/${table.id}/summary',
        ),
      ),
    );
  }
}

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
        trailing: isActive
            ? const Icon(Icons.chevron_right)
            : _ArchivedTableMenu(table: table),
        onTap: () => context.push(
          isActive ? '/table/${table.id}' : '/table/${table.id}/summary',
        ),
      ),
    );
  }
}

class _ArchivedTableMenu extends ConsumerWidget {
  final TableModel table;
  const _ArchivedTableMenu({required this.table});

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(tableRepositoryProvider).reactivateTable(table.id);
    ref.invalidate(activeTablesProvider);
    ref.invalidate(archivedTablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${table.name} restored to active tables')),
      );
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete table?'),
        content: Text('${table.name} and all related orders will be deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref.read(tableRepositoryProvider).deleteTable(table.id);
    ref.invalidate(activeTablesProvider);
    ref.invalidate(archivedTablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${table.name} deleted')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_ArchivedTableAction>(
      onSelected: (action) {
        switch (action) {
          case _ArchivedTableAction.restore:
            _restore(context, ref);
          case _ArchivedTableAction.delete:
            _delete(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: _ArchivedTableAction.restore,
          child: Text('Restore'),
        ),
        PopupMenuItem(
          value: _ArchivedTableAction.delete,
          child: Text('Delete'),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

enum _ArchivedTableAction { restore, delete }

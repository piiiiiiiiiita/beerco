import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTablesProvider);
    final archived = ref.watch(archivedTablesProvider);

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeGlowBackdrop()),
          SafeArea(
            child: Column(
              children: [
                const _HomeHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    children: [
                      AppSectionHeader(
                        title: 'Aktivní stoly',
                        trailing: AppPill(
                          label: '${active.length}',
                          backgroundColor: AppColors.primaryTint(context),
                          foregroundColor: AppColors.primaryTintForeground(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (active.isEmpty)
                        const _EmptyStateCard(
                          title: 'Zatím nic neběží',
                          subtitle:
                              'Začněte nové sezení a přidejte první stůl.',
                        )
                      else
                        ...active.map((table) => _HomeTableCard(table: table)),
                      const SizedBox(height: 28),
                      const AppSectionHeader(title: 'Historie'),
                      const SizedBox(height: 14),
                      if (archived.isEmpty)
                        const _EmptyStateCard(
                          title: 'Historie je prázdná',
                          subtitle: 'Uzavřené stoly se objeví tady.',
                        )
                      else
                        AppSurfaceCard(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              for (var i = 0; i < archived.length; i++) ...[
                                _HistoryRow(table: archived[i]),
                                if (i != archived.length - 1)
                                  Divider(
                                    height: 1,
                                    indent: 12,
                                    endIndent: 12,
                                    color: AppColors.border(context),
                                  ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: AppPrimaryButton(
            label: 'Nové sezení',
            icon: Icons.add,
            onPressed: () => context.push('/new-table'),
          ),
        ),
      ),
    );
  }
}

class _HomeGlowBackdrop extends StatelessWidget {
  const _HomeGlowBackdrop();

  @override
  Widget build(BuildContext context) {
    final opacity = AppColors.isDark(context) ? 1.0 : 0.7;

    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: MediaQuery.of(context).padding.top + kToolbarHeight + 400,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.24, 0.72, 1.0],
                      colors: [
                        Color(0xCCfd530c),
                        Color(0x88fc5c0c),
                        Color(0x18FF7A1A),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.18, -1.0),
                      radius: 1.02,
                      stops: const [0.0, 0.34, 0.78, 1.0],
                      colors: [
                        AppColors.glowYellow.withValues(alpha: 0.30),
                        AppColors.glowOrange.withValues(alpha: 0.24),
                        AppColors.glowOrange.withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BeerCo',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Track orders. Check the bill.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.glowYellow.withValues(alpha: 0.86)
                  : AppColors.surfaceDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTableCard extends ConsumerWidget {
  final TableModel table;

  const _HomeTableCard({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref
        .read(tableRepositoryProvider)
        .getMembersForTable(table.id);
    final orders = ref
        .read(orderRepositoryProvider)
        .getOrdersForTable(table.id);
    final orderCount = orders.fold<int>(
      0,
      (sum, order) => sum + order.quantity,
    );
    final isDark = AppColors.isDark(context);

    final card = AppSurfaceCard(
      onTap: () => context.push('/table/${table.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          // table name , název stolu
                          child: Text(
                            table.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AppColors.muted(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatRelativeTime(table.createdAt),
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppPill(
                label: '$orderCount piv',
                icon: Icons.local_bar_rounded,
                backgroundColor: AppColors.successTint(context),
                foregroundColor: isDark
                    ? AppColors.mutedDark
                    : AppColors.muted(context),
                gradient: isDark
                    ? const RadialGradient(
                        center: Alignment(-0.3, -0.8),
                        radius: 4.8,
                        colors: [Color(0x21FFFFFF), Color(0x4DF8A91F)],
                      )
                    : const RadialGradient(
                        center: Alignment(-0.3, -0.8),
                        radius: 4.8,
                        colors: [Color(0xFFF7F7F7), Color(0xFFF7F7F7)],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MemberAvatarStrip(members: members)),
              const SizedBox(width: 12),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey('table-${table.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => _TableActions.archive(context, table),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.archive_outlined,
              label: 'Archive',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _TableActions.delete(context, table),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  final TableModel table;

  const _HistoryRow({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref
        .read(orderRepositoryProvider)
        .getOrdersForTable(table.id);
    final orderCount = orders.fold<int>(
      0,
      (sum, order) => sum + order.quantity,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/table/${table.id}/summary'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 20,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d. M. HH:mm').format(table.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$orderCount piv',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                PopupMenuButton<_HistoryAction>(
                  onSelected: (action) {
                    if (action == _HistoryAction.restore) {
                      _TableActions.restore(context, table);
                    } else {
                      _TableActions.delete(context, table);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _HistoryAction.restore,
                      child: Text('Restore'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _HistoryAction { restore, delete }

class _MemberAvatarStrip extends StatelessWidget {
  final List<MemberModel> members;

  const _MemberAvatarStrip({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    final overflow = members.length - visible.length;

    return Row(
      children: [
        for (final member in visible)
          Align(
            widthFactor: 0.7,
            child: MemberAvatar(
              memberId: member.id,
              avatarAsset: member.avatarAsset,
              name: member.name,
              diameter: 32,
              shadow: false,
            ),
          ),
        if (overflow > 0)
          Align(
            widthFactor: 0.7,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.avatarRing(context),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflow',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted(context),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableActions {
  static Future<void> archive(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive table?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${table.name} will move to history. You can restore it later.',
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Archive'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await container.read(tableRepositoryProvider).archiveTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${table.name} moved to history')));
    }
  }

  static Future<void> restore(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(tableRepositoryProvider).reactivateTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${table.name} restored to active tables')),
      );
    }
  }

  static Future<void> delete(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete table?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${table.name} and all related orders will be deleted.'),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Delete'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await container.read(tableRepositoryProvider).deleteTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${table.name} deleted')));
    }
  }
}

String _formatRelativeTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return 'před ${difference.inMinutes} min';
  if (difference.inHours < 24) {
    final minutes = difference.inMinutes.remainder(60);
    if (minutes == 0) return 'před ${difference.inHours} h';
    return 'před ${difference.inHours}h ${minutes}m';
  }
  return DateFormat('d. M.').format(createdAt);
}

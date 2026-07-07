import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_event_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

class _TimelineEntry {
  final DateTime timestamp;
  final OrderModel? order;
  final TableEventModel? paidEvent;

  _TimelineEntry({required this.timestamp, this.order, this.paidEvent});
}

class SummaryScreen extends ConsumerWidget {
  final String tableId;
  const SummaryScreen({super.key, required this.tableId});

  Future<void> _restoreTable(
    BuildContext context,
    WidgetRef ref,
    String tableId,
  ) async {
    await ref.read(tableRepositoryProvider).reactivateTable(tableId);
    ref.invalidate(activeTablesProvider);
    ref.invalidate(archivedTablesProvider);
    if (context.mounted) {
      context.go('/table/$tableId');
    }
  }

  Future<void> _deleteArchivedTable(
    BuildContext context,
    WidgetRef ref,
    TableModel table,
  ) async {
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

    await ref.read(tableRepositoryProvider).deleteTable(table.id);
    ref.invalidate(activeTablesProvider);
    ref.invalidate(archivedTablesProvider);
    if (context.mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(tableId));
    final orders = ref.watch(ordersProvider(tableId));
    final table = ref.watch(tableProvider(tableId));
    final ordersNotifier = ref.read(ordersProvider(tableId).notifier);
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');

    final paidEvents = ref
        .watch(tableEventsProvider(tableId))
        .where((e) => e.type == 'paid');
    final timelineEntries = <_TimelineEntry>[
      ...orders.map((o) => _TimelineEntry(timestamp: o.timestamp, order: o)),
      ...paidEvents.map(
        (e) => _TimelineEntry(timestamp: e.timestamp, paidEvent: e),
      ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    String buildShareText() {
      final buf = StringBuffer();
      buf.writeln('BeerCo Summary - ${table?.name ?? 'Table'}');
      buf.writeln(dateFmt.format(table?.createdAt ?? DateTime.now()));
      buf.writeln('');
      for (final member in members) {
        final count = ordersNotifier.getCountForMember(member.id);
        buf.writeln('${member.name}: $count');
      }
      buf.writeln('');
      buf.writeln('Total: ${orders.length} orders');
      return buf.toString();
    }

    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: Text(table?.name ?? 'Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buildShareText()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Summary copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
        children: [
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurfaceLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Started ${dateFmt.format(table?.createdAt ?? DateTime.now())}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedLight,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AppPill(
                      label: '${orders.length} orders',
                      icon: Icons.local_bar_outlined,
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: const Color(0xFF92400E),
                    ),
                    AppPill(
                      label: '${members.length} members',
                      icon: Icons.group_outlined,
                      backgroundColor: AppColors.chipLight,
                      foregroundColor: AppColors.onSurfaceLight,
                    ),
                    if (table != null && !table.isActive)
                      AppPill(
                        label: 'Archived',
                        icon: Icons.history_rounded,
                        backgroundColor: AppColors.chipLight,
                        foregroundColor: AppColors.mutedLight,
                      ),
                  ],
                ),
                if (table != null && !table.isActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _restoreTable(context, ref, tableId),
                          icon: const Icon(Icons.restore_outlined),
                          label: const Text('Restore'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _deleteArchivedTable(context, ref, table),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Per member'),
          const SizedBox(height: 12),
          ...members.map((member) {
            final count = ordersNotifier.getCountForMember(member.id);
            final memberOrders = ordersNotifier.getOrdersForMember(member.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberSummaryTile(
                member: member,
                count: count,
                orders: memberOrders,
              ),
            );
          }),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Timeline'),
          const SizedBox(height: 12),
          AppSurfaceCard(
            padding: EdgeInsets.zero,
            child: timelineEntries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No orders yet',
                      style: TextStyle(color: AppColors.mutedLight),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: timelineEntries.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.borderLight),
                    itemBuilder: (_, index) {
                      final entry = timelineEntries[index];
                      final timeFmt = DateFormat('HH:mm:ss');
                      final isPaid = entry.paidEvent != null;
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 2,
                        ),
                        leading: Text(
                          timeFmt.format(entry.timestamp),
                          style: const TextStyle(
                            color: AppColors.mutedLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        title: Text(
                          isPaid
                              ? '${entry.paidEvent!.memberName} paid - ${ordersNotifier.getCountForMember(entry.paidEvent!.memberId)} piv'
                              : entry.order!.memberName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPaid ? AppColors.success : null,
                          ),
                        ),
                        trailing: isPaid
                            ? const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              )
                            : Text(
                                '+${entry.order!.quantity}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Member log'),
          const SizedBox(height: 12),
          _MemberEventTimeline(tableId: tableId),
        ],
      ),
    );
  }
}

class _MemberEventTimeline extends ConsumerWidget {
  final String tableId;
  const _MemberEventTimeline({required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(tableEventsProvider(tableId));
    ref.watch(ordersProvider(tableId));
    final ordersNotifier = ref.read(ordersProvider(tableId).notifier);
    final timeFmt = DateFormat('HH:mm:ss');

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: events.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No member status changes yet',
                style: TextStyle(color: AppColors.mutedLight),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.borderLight),
              itemBuilder: (_, index) {
                final event = events[index];
                final isPaid = event.type == 'paid';
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  leading: Icon(
                    isPaid ? Icons.check_circle : Icons.local_drink_outlined,
                    color: isPaid ? AppColors.success : AppColors.primary,
                    size: 18,
                  ),
                  title: Text(
                    isPaid
                        ? '${event.memberName} paid - ${ordersNotifier.getCountForMember(event.memberId)} piv'
                        : '${event.memberName} came back for more',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPaid ? AppColors.success : null,
                    ),
                  ),
                  trailing: Text(
                    timeFmt.format(event.timestamp),
                    style: const TextStyle(
                      color: AppColors.mutedLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _MemberSummaryTile extends StatefulWidget {
  final MemberModel member;
  final int count;
  final List<OrderModel> orders;

  const _MemberSummaryTile({
    required this.member,
    required this.count,
    required this.orders,
  });

  @override
  State<_MemberSummaryTile> createState() => _MemberSummaryTileState();
}

class _MemberSummaryTileState extends State<_MemberSummaryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm:ss');

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: MemberAvatar(
              memberId: widget.member.id,
              avatarAsset: widget.member.avatarAsset,
              name: widget.member.name,
              diameter: 42,
            ),
            title: Text(
              widget.member.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: widget.member.isPaid
                ? Text(
                    'paid - ${widget.count} piv',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.count}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.mutedLight,
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded && widget.orders.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: widget.orders
                    .map(
                      (order) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_bar_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeFmt.format(order.timestamp),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

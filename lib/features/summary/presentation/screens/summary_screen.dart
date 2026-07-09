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

class _MemberActivityEntry {
  final DateTime timestamp;
  final OrderModel? order;
  final TableEventModel? paidEvent;

  _MemberActivityEntry({required this.timestamp, this.order, this.paidEvent});
}

class SummaryScreen extends ConsumerStatefulWidget {
  final String tableId;
  const SummaryScreen({super.key, required this.tableId});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(widget.tableId));
    final orders = ref.watch(ordersProvider(widget.tableId));
    final table = ref.watch(tableProvider(widget.tableId));
    final ordersNotifier = ref.read(ordersProvider(widget.tableId).notifier);
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');

    final paidEvents = ref
        .watch(tableEventsProvider(widget.tableId))
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
        context: context,
        scrollController: _scrollController,
        title: Text(table?.name ?? 'Summary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: buildShareText()));
              showAppToast(context, 'Summary copied to clipboard');
            },
          ),
        ],
      ),
      body: ListView(
        controller: _scrollController,
        padding: EdgeInsets.fromLTRB(20, topPad, 20, 24),
        children: [
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Session overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Started ${dateFmt.format(table?.createdAt ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted(context),
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
                      backgroundColor: AppColors.primaryTint(context),
                      foregroundColor: AppColors.primaryTintForeground(context),
                    ),
                    AppPill(
                      label: '${members.length} members',
                      icon: Icons.group_outlined,
                      backgroundColor: AppColors.chip(context),
                      foregroundColor: AppColors.onSurface(context),
                    ),
                    if (table != null && !table.isActive)
                      AppPill(
                        label: 'Archived',
                        icon: Icons.history_rounded,
                        backgroundColor: AppColors.chip(context),
                        foregroundColor: AppColors.muted(context),
                      ),
                  ],
                ),
                if (table != null && !table.isActive) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _restoreTable(context, ref, widget.tableId),
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
            final totalCount = ordersNotifier.getTotalCountForMember(member.id);
            final memberOrders = ordersNotifier.getOrdersForMember(member.id);
            final allMemberPaidEvents = paidEvents
                .where((event) => event.memberId == member.id)
                .toList();
            final memberPaidEventCounts = {
              for (final event in allMemberPaidEvents)
                event.id: ordersNotifier.getCountForPaidEvent(
                  member.id,
                  event.timestamp,
                ),
            };
            final memberPaidEvents = allMemberPaidEvents
                .where((event) => (memberPaidEventCounts[event.id] ?? 0) > 0)
                .toList();
            final lastPaidEvent = memberPaidEvents.lastOrNull;
            final lastPaidCount = lastPaidEvent == null
                ? null
                : memberPaidEventCounts[lastPaidEvent.id];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MemberSummaryTile(
                member: member,
                count: totalCount,
                orders: memberOrders,
                paidEvents: memberPaidEvents,
                paidEventCounts: memberPaidEventCounts,
                lastPaidCount: lastPaidCount,
              ),
            );
          }),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Timeline'),
          const SizedBox(height: 12),
          AppSurfaceCard(
            padding: EdgeInsets.zero,
            child: timelineEntries.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No orders yet',
                      style: TextStyle(color: AppColors.muted(context)),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: timelineEntries.length,
                    separatorBuilder: (_, _) =>
                        Divider(height: 1, color: AppColors.border(context)),
                    itemBuilder: (_, index) {
                      final entry = timelineEntries[index];
                      final timeFmt = DateFormat('HH:mm');
                      final isPaid = entry.paidEvent != null;
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 58,
                              child: Text(
                                timeFmt.format(entry.timestamp),
                                style: TextStyle(
                                  color: AppColors.muted(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPaid
                                    ? '${entry.paidEvent!.memberName} paid - ${ordersNotifier.getCountForPaidEvent(entry.paidEvent!.memberId, entry.paidEvent!.timestamp)} piv'
                                    : entry.order!.memberName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isPaid ? AppColors.success : null,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (isPaid)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 18,
                              )
                            else
                              Text(
                                '+${entry.order!.quantity}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 24),
          const AppSectionHeader(title: 'Member log'),
          const SizedBox(height: 12),
          _MemberEventTimeline(tableId: widget.tableId),
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
    final timeFmt = DateFormat('HH:mm');

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: events.isEmpty
          ? Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No member status changes yet',
                style: TextStyle(color: AppColors.muted(context)),
              ),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8),
              itemCount: events.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: AppColors.border(context)),
              itemBuilder: (_, index) {
                final event = events[index];
                final isPaid = event.type == 'paid';
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isPaid
                              ? Icons.check_circle
                              : Icons.local_drink_outlined,
                          color: isPaid ? AppColors.success : AppColors.primary,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isPaid
                              ? '${event.memberName} paid - ${ordersNotifier.getCountForPaidEvent(event.memberId, event.timestamp)} piv'
                              : '${event.memberName} came back for more',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isPaid ? AppColors.success : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        timeFmt.format(event.timestamp),
                        style: TextStyle(
                          color: AppColors.muted(context),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
  final List<TableEventModel> paidEvents;
  final Map<String, int> paidEventCounts;
  final int? lastPaidCount;

  const _MemberSummaryTile({
    required this.member,
    required this.count,
    required this.orders,
    required this.paidEvents,
    required this.paidEventCounts,
    required this.lastPaidCount,
  });

  @override
  State<_MemberSummaryTile> createState() => _MemberSummaryTileState();
}

class _MemberSummaryTileState extends State<_MemberSummaryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final activityEntries = <_MemberActivityEntry>[
      ...widget.orders.map(
        (order) =>
            _MemberActivityEntry(timestamp: order.timestamp, order: order),
      ),
      ...widget.paidEvents.map(
        (event) =>
            _MemberActivityEntry(timestamp: event.timestamp, paidEvent: event),
      ),
    ]..sort((a, b) => a.timestamp.compareTo(b.timestamp));

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
            subtitle: widget.lastPaidCount != null && widget.lastPaidCount! > 0
                ? Text(
                    'Last paid ${widget.lastPaidCount} piv.',
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
                  color: AppColors.muted(context),
                ),
              ],
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded && activityEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  ...activityEntries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            entry.paidEvent != null
                                ? Icons.check_circle
                                : Icons.local_bar_outlined,
                            size: 14,
                            color: entry.paidEvent != null
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.paidEvent != null
                                  ? '${timeFmt.format(entry.timestamp)} - ${widget.member.name} paid - ${widget.paidEventCounts[entry.paidEvent!.id] ?? 0} piv'
                                  : timeFmt.format(entry.timestamp),
                              style: TextStyle(
                                fontSize: 13,
                                color: entry.paidEvent != null
                                    ? AppColors.success
                                    : AppColors.muted(context),
                                fontWeight: entry.paidEvent != null
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

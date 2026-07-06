import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/order/data/models/order_model.dart';
import 'package:beerco/core/theme/app_theme.dart';

class SummaryScreen extends ConsumerWidget {
  final String tableId;
  const SummaryScreen({super.key, required this.tableId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(tableId));
    final orders = ref.watch(ordersProvider(tableId));
    final table = ref.watch(tableProvider(tableId));
    final ordersNotifier = ref.read(ordersProvider(tableId).notifier);

    final dateFmt = DateFormat('d MMM yyyy, HH:mm');

    // Build summary text for sharing
    String buildShareText() {
      final buf = StringBuffer();
      buf.writeln('🍺 BeerCo Summary - ${table?.name ?? 'Table'}');
      buf.writeln(dateFmt.format(table?.createdAt ?? DateTime.now()));
      buf.writeln('');
      for (final m in members) {
        final count = ordersNotifier.getCountForMember(m.id);
        buf.writeln('${m.name}: $count order${count == 1 ? '' : 's'}');
      }
      buf.writeln('');
      buf.writeln('Total: ${orders.length} orders');
      return buf.toString();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          table?.name ?? 'Summary',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
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
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Session started',
                    style: TextStyle(color: AppColors.mutedLight, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFmt.format(table?.createdAt ?? DateTime.now()),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(
                        label: 'Total orders',
                        value: '${orders.length}',
                      ),
                      const SizedBox(width: 8),
                      _StatChip(label: 'Members', value: '${members.length}'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Per-member summary
          Text(
            'Per member',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...members.map((m) {
            final count = ordersNotifier.getCountForMember(m.id);
            final memberOrders = ordersNotifier.getOrdersForMember(m.id);
            return _MemberSummaryTile(
              member: m,
              count: count,
              orders: memberOrders,
            );
          }),
          const SizedBox(height: 16),
          // Timeline
          Text(
            'Timeline',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: orders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No orders yet'),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final timeFmt = DateFormat('HH:mm:ss');
                      return ListTile(
                        dense: true,
                        leading: Text(
                          timeFmt.format(o.timestamp),
                          style: TextStyle(
                            color: AppColors.mutedLight,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                        title: Text(
                          o.memberName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: Text(
                          '+${o.quantity}',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.mutedLight),
          ),
        ],
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.member.name.isNotEmpty
                      ? widget.member.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Text(
                  widget.member.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (widget.member.isPaid) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.check_circle, size: 14, color: AppColors.success),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.count}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 4),
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: widget.orders
                    .map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.local_drink_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              timeFmt.format(o.timestamp),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.mutedLight,
                                fontFamily: 'monospace',
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

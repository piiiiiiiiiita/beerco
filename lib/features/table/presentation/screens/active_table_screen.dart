import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/core/theme/app_theme.dart';

class ActiveTableScreen extends ConsumerStatefulWidget {
  final String tableId;
  const ActiveTableScreen({super.key, required this.tableId});

  @override
  ConsumerState<ActiveTableScreen> createState() => _ActiveTableScreenState();
}

class _ActiveTableScreenState extends ConsumerState<ActiveTableScreen> {
  bool _showUndo = false;
  String? _undoMessage;

  Future<String?> _showMemberNameDialog({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Member name'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  Future<void> _addMember() async {
    final name = await _showMemberNameDialog(
      title: 'Add member',
      actionLabel: 'Add',
    );
    if (name == null) return;

    await ref.read(membersProvider(widget.tableId).notifier).addMember(name);
  }

  Future<void> _renameMember(MemberModel member) async {
    final newName = await _showMemberNameDialog(
      title: 'Rename member',
      actionLabel: 'Save',
      initialValue: member.name,
    );
    if (newName == null || newName == member.name) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .updateName(member, newName);
  }

  Future<void> _removeMember(MemberModel member) async {
    final orderCount = ref
        .read(ordersProvider(widget.tableId).notifier)
        .getCountForMember(member.id);

    if (orderCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Members with existing orders cannot be removed'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.name} will be removed from this table.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .removeMember(member);
  }

  void _addOrder(MemberModel member) async {
    HapticFeedback.lightImpact();
    await ref
        .read(ordersProvider(widget.tableId).notifier)
        .addOrder(member.id, member.name);
    setState(() {
      _showUndo = true;
      _undoMessage = '+1 for ${member.name}';
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showUndo = false);
    });
  }

  void _undoLast() async {
    HapticFeedback.mediumImpact();
    await ref.read(ordersProvider(widget.tableId).notifier).undoLastOrder();
    setState(() => _showUndo = false);
  }

  void _addForAll() async {
    final members = ref
        .read(membersProvider(widget.tableId))
        .where((m) => !m.isPaid)
        .toList();
    if (members.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Order for everyone?'),
        content: Text('+1 for all ${members.length} active members'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      HapticFeedback.mediumImpact();
      await ref
          .read(ordersProvider(widget.tableId).notifier)
          .addOrderForAll(
            members.map((m) => m.id).toList(),
            members.map((m) => m.name).toList(),
          );
      setState(() {
        _showUndo = true;
        _undoMessage = '+1 for everyone (${members.length})';
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showUndo = false);
      });
    }
  }

  void _addRandom() async {
    final members = ref
        .read(membersProvider(widget.tableId))
        .where((m) => !m.isPaid)
        .toList();
    if (members.isEmpty) return;
    int count = 1;
    final confirmed = await showDialog<int>(
      context: context,
      builder: (_) =>
          _RandomOrderDialog(maxCount: members.length, initial: count),
    );
    if (confirmed != null && confirmed > 0) {
      HapticFeedback.mediumImpact();
      await ref
          .read(ordersProvider(widget.tableId).notifier)
          .addRandomOrders(
            members.map((m) => m.id).toList(),
            members.map((m) => m.name).toList(),
            confirmed,
          );
      setState(() {
        _showUndo = true;
        _undoMessage = 'Random +$confirmed orders added';
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showUndo = false);
      });
    }
  }

  void _showMemberOptions(MemberModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _MemberOptionsSheet(
        member: member,
        onRename: () async {
          Navigator.pop(context);
          await _renameMember(member);
        },
        onRemove: () async {
          Navigator.pop(context);
          await _removeMember(member);
        },
        onPaidToggle: () async {
          if (member.isPaid) {
            await ref
                .read(membersProvider(widget.tableId).notifier)
                .markUnpaid(member.id);
          } else {
            await ref
                .read(membersProvider(widget.tableId).notifier)
                .markPaid(member.id);
          }
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _endSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('End session?'),
        content: const Text(
          'The table will be archived. You can still view the summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(tableRepositoryProvider).archiveTable(widget.tableId);
      ref.invalidate(activeTablesProvider);
      ref.invalidate(archivedTablesProvider);
      ref.invalidate(tableProvider(widget.tableId));
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(widget.tableId));
    final orders = ref.watch(ordersProvider(widget.tableId));
    final table = ref.watch(tableProvider(widget.tableId));

    final activeMembers = members.where((m) => !m.isPaid).toList();
    final paidMembers = members.where((m) => m.isPaid).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          table?.name ?? 'Table',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: _addMember,
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () => context.push('/table/${widget.tableId}/summary'),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            color: AppColors.danger,
            onPressed: _endSession,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Stats bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Text(
                      '${orders.length} orders total',
                      style: TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${activeMembers.length} active',
                      style: TextStyle(
                        color: AppColors.mutedLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              // Members list
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    ...activeMembers.map(
                      (m) => _MemberCard(
                        member: m,
                        orderCount: ref
                            .watch(ordersProvider(widget.tableId).notifier)
                            .getCountForMember(m.id),
                        lastOrderTime: ref
                            .watch(ordersProvider(widget.tableId))
                            .where((o) => o.memberId == m.id)
                            .lastOrNull
                            ?.timestamp,
                        onTap: () => _addOrder(m),
                        onLongPress: () => _showMemberOptions(m),
                      ),
                    ),
                    if (paidMembers.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Paid & gone',
                          style: TextStyle(
                            color: AppColors.mutedLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...paidMembers.map(
                        (m) => _MemberCard(
                          member: m,
                          orderCount: ref
                              .watch(ordersProvider(widget.tableId).notifier)
                              .getCountForMember(m.id),
                          lastOrderTime: null,
                          onTap: null,
                          onLongPress: () => _showMemberOptions(m),
                          isPaid: true,
                        ),
                      ),
                    ],
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          // Undo banner
          if (_showUndo)
            Positioned(
              bottom: 90,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(14),
                color: Theme.of(context).colorScheme.onSurface,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _undoMessage ?? '',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.surface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _undoLast,
                        child: Text(
                          'UNDO',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      // Bottom action bar
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addForAll,
                  icon: const Icon(Icons.group, size: 18),
                  label: const Text('+1 All'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addRandom,
                  icon: const Icon(Icons.shuffle, size: 18),
                  label: const Text('Random'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/table/${widget.tableId}/summary'),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('Summary'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final int orderCount;
  final DateTime? lastOrderTime;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isPaid;

  const _MemberCard({
    required this.member,
    required this.orderCount,
    required this.lastOrderTime,
    required this.onTap,
    required this.onLongPress,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    return Opacity(
      opacity: isPaid ? 0.5 : 1.0,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Name + last order
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isPaid) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      if (lastOrderTime != null)
                        Text(
                          'Last: ${timeFmt.format(lastOrderTime!)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedLight,
                          ),
                        ),
                    ],
                  ),
                ),
                // Order count
                Text(
                  '$orderCount',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (!isPaid) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberOptionsSheet extends StatelessWidget {
  final MemberModel member;
  final VoidCallback onRename;
  final VoidCallback onRemove;
  final VoidCallback onPaidToggle;

  const _MemberOptionsSheet({
    required this.member,
    required this.onRename,
    required this.onRemove,
    required this.onPaidToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            member.name,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename'),
            onTap: onRename,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.danger),
            title: const Text('Remove'),
            textColor: AppColors.danger,
            iconColor: AppColors.danger,
            onTap: onRemove,
          ),
          ListTile(
            leading: Icon(
              member.isPaid ? Icons.undo : Icons.check_circle_outline,
              color: member.isPaid ? AppColors.mutedLight : AppColors.success,
            ),
            title: Text(
              member.isPaid ? 'Mark as active' : 'Mark as paid & gone',
            ),
            onTap: onPaidToggle,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _RandomOrderDialog extends StatefulWidget {
  final int maxCount;
  final int initial;
  const _RandomOrderDialog({required this.maxCount, required this.initial});

  @override
  State<_RandomOrderDialog> createState() => _RandomOrderDialogState();
}

class _RandomOrderDialogState extends State<_RandomOrderDialog> {
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Random orders'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How many beers were ordered?',
            style: TextStyle(color: AppColors.mutedLight),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _count > 1 ? () => setState(() => _count--) : null,
                icon: const Icon(Icons.remove_circle_outline, size: 32),
              ),
              const SizedBox(width: 16),
              Text(
                '$_count',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: _count < widget.maxCount
                    ? () => setState(() => _count++)
                    : null,
                icon: const Icon(Icons.add_circle_outline, size: 32),
              ),
            ],
          ),
          Text(
            'of ${widget.maxCount} active members',
            style: TextStyle(color: AppColors.mutedLight, fontSize: 13),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _count),
          child: const Text('Add randomly'),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/widgets/table_hero_card.dart';
import 'package:beerco/features/table/presentation/widgets/member_quick_strip.dart';
import 'package:beerco/features/table/presentation/widgets/active_table_menu_bar.dart';
import 'package:beerco/features/table/presentation/widgets/avatar_picker_sheet.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/member_avatars.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';
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

  Future<String?> _showTableNameDialog(String initialValue) async {
    var draftValue = initialValue;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rename table'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: initialValue,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Table name'),
              onChanged: (value) => draftValue = value,
              onFieldSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, draftValue.trim()),
                child: const Text('Save'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  Future<String?> _showMemberNameDialog({
    required String title,
    required String actionLabel,
    String initialValue = '',
  }) async {
    var draftValue = initialValue;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              initialValue: initialValue,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Member name'),
              onChanged: (value) => draftValue = value,
              onFieldSubmitted: (value) =>
                  Navigator.pop(dialogContext, value.trim()),
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, draftValue.trim()),
                child: Text(actionLabel),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.trim().isEmpty) {
      return null;
    }
    return result.trim();
  }

  Future<void> _addMember() async {
    final result = await showDialog<({String name, String avatar})>(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
    if (result == null) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .addMember(result.name, avatarAsset: result.avatar);
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

  Future<void> _changeAvatar(MemberModel member) async {
    final chosen = await showAvatarPickerSheet(
      context,
      current: member.avatarAsset,
    );
    if (chosen == null) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .setAvatar(member, chosen);
  }

  void _editMember(MemberModel member) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Change name'),
              onTap: () async {
                Navigator.pop(context);
                await _renameMember(member);
              },
            ),
            ListTile(
              leading: const Icon(Icons.face_outlined),
              title: const Text('Change avatar'),
              onTap: () async {
                Navigator.pop(context);
                await _changeAvatar(member);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${member.name} will be removed from this table.'),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Remove'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .removeMember(member);
  }

  Future<void> _showPaidMemberDialog(MemberModel member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('This fella has already paid.'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Are you sure this fella is not going home yet?'),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Yes, he/she is thirsty'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(membersProvider(widget.tableId).notifier)
        .markUnpaid(member.id);
    ref.invalidate(tableEventsProvider(widget.tableId));
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

  void _removeLastOrder(MemberModel member) async {
    final notifier = ref.read(ordersProvider(widget.tableId).notifier);
    if (notifier.getCountForMember(member.id) == 0) return;

    HapticFeedback.selectionClick();
    await notifier.removeLastOrderForMember(member.id);
    if (!mounted) return;

    setState(() {
      _showUndo = false;
      _undoMessage = null;
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('+1 for all ${members.length} active members'),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
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
          _RandomOrderDialog(activeMemberCount: members.length, initial: count),
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
        onChangeAvatar: () async {
          Navigator.pop(context);
          await _changeAvatar(member);
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
          ref.invalidate(tableEventsProvider(widget.tableId));
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'The table will be archived. You can still view the summary.',
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('End Session'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
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

  Future<void> _renameTable(String currentName) async {
    final newName = await _showTableNameDialog(currentName);
    if (newName == null || newName == currentName) return;

    await ref
        .read(tableRepositoryProvider)
        .renameTable(widget.tableId, newName);
    ref.invalidate(activeTablesProvider);
    ref.invalidate(archivedTablesProvider);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(membersProvider(widget.tableId));
    final orders = ref.watch(ordersProvider(widget.tableId));
    final table = ref.watch(tableProvider(widget.tableId));

    final activeMembers = members.where((m) => !m.isPaid).toList();
    final paidMembers = members.where((m) => m.isPaid).toList();
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        title: Text(table?.name ?? 'Table'),
        actions: [
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
          ListView(
            padding: EdgeInsets.fromLTRB(20, topPad, 20, 110),
            children: [
              TableHeroCard(
                tableName: table?.name ?? 'Table',
                orderCount: orders.length,
                members: members,
                onEditName: table == null
                    ? null
                    : () => _renameTable(table.name),
              ),
              const SizedBox(height: 20),
              MemberQuickStrip(
                members: members,
                onAdd: _addMember,
                onTapMember: _editMember,
              ),
              const SizedBox(height: 24),
              const AppSectionHeader(title: 'Active members'),
              const SizedBox(height: 12),
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
                  onDecrement: () => _removeLastOrder(m),
                  onLongPress: () => _showMemberOptions(m),
                  onEdit: () => _renameMember(m),
                  onDelete: () => _removeMember(m),
                  onPaidToggle: () async {
                    await ref
                        .read(membersProvider(widget.tableId).notifier)
                        .markPaid(m.id);
                    ref.invalidate(tableEventsProvider(widget.tableId));
                  },
                ),
              ),
              if (paidMembers.isNotEmpty) ...[
                const SizedBox(height: 16),
                const AppSectionHeader(title: 'Paid & gone'),
                const SizedBox(height: 12),
                ...paidMembers.map(
                  (m) => _MemberCard(
                    member: m,
                    orderCount: ref
                        .watch(ordersProvider(widget.tableId).notifier)
                        .getCountForMember(m.id),
                    lastOrderTime: null,
                    onTap: () => _showPaidMemberDialog(m),
                    onDecrement: null,
                    onLongPress: () => _showMemberOptions(m),
                    isPaid: true,
                    onEdit: () => _renameMember(m),
                    onDelete: () => _removeMember(m),
                    onPaidToggle: () async {
                      await ref
                          .read(membersProvider(widget.tableId).notifier)
                          .markUnpaid(m.id);
                      ref.invalidate(tableEventsProvider(widget.tableId));
                    },
                  ),
                ),
              ],
            ],
          ),
          if (_showUndo)
            Positioned(
              bottom: 104,
              left: 16,
              right: 16,
              child: Material(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.darkButton,
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _undoMessage ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _undoLast,
                        child: const Text(
                          'UNDO',
                          style: TextStyle(
                            color: Color(0xFFFDE68A),
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
      bottomNavigationBar: SafeArea(
        child: ActiveTableMenuBar(
          items: [
            MenuBarItemData(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => context.go('/'),
            ),
            MenuBarItemData(
              icon: Icons.control_point_duplicate,
              label: '+1 All',
              onTap: _addForAll,
            ),
            MenuBarItemData(
              icon: Icons.shuffle,
              label: 'Random',
              onTap: _addRandom,
            ),
            MenuBarItemData(
              icon: Icons.receipt_long_outlined,
              label: 'Summary',
              onTap: () => context.push('/table/${widget.tableId}/summary'),
            ),
          ],
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
  final VoidCallback? onDecrement;
  final VoidCallback? onLongPress;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onPaidToggle;
  final bool isPaid;

  const _MemberCard({
    required this.member,
    required this.orderCount,
    required this.lastOrderTime,
    required this.onTap,
    required this.onDecrement,
    required this.onLongPress,
    required this.onEdit,
    required this.onDelete,
    required this.onPaidToggle,
    this.isPaid = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final paidFmt = member.paidAt == null
        ? null
        : timeFmt.format(member.paidAt!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey('member-${member.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.78,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit?.call(),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.edit_outlined,
              label: 'Edit',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (_) => onDelete?.call(),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              padding: EdgeInsets.zero,
            ),
            SlidableAction(
              onPressed: (_) => onPaidToggle?.call(),
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              icon: isPaid
                  ? Icons.local_drink_outlined
                  : Icons.check_circle_outline,
              label: isPaid ? 'Active' : 'Paid',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: Opacity(
          opacity: isPaid ? 0.6 : 1.0,
          child: AppSurfaceCard(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            onTap: onTap,
            onLongPress: onLongPress,
            child: Row(
              children: [
                MemberAvatar(
                  memberId: member.id,
                  avatarAsset: member.avatarAsset,
                  name: member.name,
                  diameter: 46,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              member.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isPaid) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: AppColors.success,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (isPaid && paidFmt != null)
                        Text(
                          'Paid at $paidFmt',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (lastOrderTime != null)
                        Text(
                          'Last: ${timeFmt.format(lastOrderTime!)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedLight,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        const Text(
                          'No orders yet',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.mutedLight,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isPaid)
                  AppIconCircleButton(
                    icon: Icons.remove_rounded,
                    onPressed: orderCount > 0 ? onDecrement : null,
                    foregroundColor: AppColors.mutedLight,
                    backgroundColor: AppColors.chipLight,
                  ),
                const SizedBox(width: 8),
                Text(
                  '$orderCount',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                if (!isPaid) ...[
                  const SizedBox(width: 8),
                  AppIconCircleButton(
                    icon: Icons.add_rounded,
                    onPressed: onTap,
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.darkButton,
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
  final VoidCallback onChangeAvatar;
  final VoidCallback onRemove;
  final VoidCallback onPaidToggle;

  const _MemberOptionsSheet({
    required this.member,
    required this.onRename,
    required this.onChangeAvatar,
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
            leading: const Icon(Icons.face_outlined),
            title: const Text('Change avatar'),
            onTap: onChangeAvatar,
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

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _controller = TextEditingController();
  String _avatar = randomAvatarAsset();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final chosen = await showAvatarPickerSheet(context, current: _avatar);
    if (chosen != null) setState(() => _avatar = chosen);
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(context, (name: name, avatar: _avatar));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add member'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: GestureDetector(
              onTap: _pickAvatar,
              child: MemberAvatar(
                memberId: 'new-member',
                avatarAsset: _avatar,
                name: _controller.text,
                diameter: 72,
              ),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: _pickAvatar,
              icon: const Icon(Icons.shuffle, size: 16),
              label: const Text('Change avatar'),
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Member name'),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          AppDialogActions(
            primary: ElevatedButton(
              onPressed: _submit,
              child: const Text('Add'),
            ),
            secondary: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RandomOrderDialog extends StatefulWidget {
  final int activeMemberCount;
  final int initial;
  const _RandomOrderDialog({
    required this.activeMemberCount,
    required this.initial,
  });

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
                onPressed: () => setState(() => _count++),
                icon: const Icon(Icons.add_circle_outline, size: 32),
              ),
            ],
          ),
          Text(
            '${widget.activeMemberCount} active members in the draw',
            style: TextStyle(color: AppColors.mutedLight, fontSize: 13),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(context, _count),
                child: const Text('Add randomly'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

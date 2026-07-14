import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/core/utils/notification_service.dart';
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

class _ActiveTableScreenState extends ConsumerState<ActiveTableScreen>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  late final AnimationController _undoCountdownController;
  late final AnimationController _undoBannerController;
  bool _showUndo = false;
  String? _undoMessage;
  int _undoTotalSeconds = 3;

  @override
  void initState() {
    super.initState();
    _undoCountdownController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              _hideUndoBanner();
            }
          });
    _undoBannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
      reverseDuration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _undoBannerController.dispose();
    _undoCountdownController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showUndoBanner(String message, {required int seconds}) {
    _undoCountdownController
      ..stop()
      ..duration = Duration(seconds: seconds);
    _undoBannerController.stop();
    setState(() {
      _undoTotalSeconds = seconds;
      _showUndo = true;
      _undoMessage = message;
    });
    _undoBannerController.forward(from: 0);
    _undoCountdownController.forward(from: 0);
  }

  Future<void> _hideUndoBanner() async {
    if (!_showUndo) return;
    await _undoBannerController.reverse();
    if (!mounted) return;
    setState(() {
      _showUndo = false;
      _undoMessage = null;
    });
  }

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

  Future<void> _showTimerSheet(MemberModel member) async {
    final now = DateTime.now();
    final initial =
        member.timerEndsAt != null && member.timerEndsAt!.isAfter(now)
        ? member.timerEndsAt!
        : now;
    var selected = initial;

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border(context),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Set timer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 216,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true,
                initialDateTime: initial,
                onDateTimeChanged: (value) => selected = value,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: AppPrimaryButton(
                label: 'Set time',
                icon: Icons.timer_outlined,
                onPressed: () => Navigator.pop(context, selected),
              ),
            ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    var endsAt = DateTime(
      now.year,
      now.month,
      now.day,
      picked.hour,
      picked.minute,
    );
    if (!endsAt.isAfter(now)) {
      endsAt = endsAt.add(const Duration(days: 1));
    }
    await ref
        .read(membersProvider(widget.tableId).notifier)
        .setTimerAt(member.id, endsAt);
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
            if (!member.isPaid)
              ListTile(
                leading: const Icon(Icons.timer_outlined),
                title: Text(
                  member.timerEndsAt != null &&
                          member.timerEndsAt!.isAfter(DateTime.now())
                      ? 'Change timer'
                      : 'Set timer',
                ),
                subtitle:
                    member.timerEndsAt != null &&
                        member.timerEndsAt!.isAfter(DateTime.now())
                    ? Text(
                        'Ends at ${DateFormat('HH:mm').format(member.timerEndsAt!)}',
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(context);
                  await _showTimerSheet(member);
                },
              ),
            if (!member.isPaid && member.timerEndsAt != null)
              ListTile(
                leading: const Icon(Icons.timer_off_outlined),
                title: const Text('Clear timer'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(membersProvider(widget.tableId).notifier)
                      .clearTimer(member.id);
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
      showAppToast(context, 'Members with existing orders cannot be removed');
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
    _showUndoBanner('+1 for ${member.name}', seconds: 3);
  }

  void _removeLastOrder(MemberModel member) async {
    final notifier = ref.read(ordersProvider(widget.tableId).notifier);
    if (notifier.getCountForMember(member.id) == 0) return;

    HapticFeedback.selectionClick();
    await notifier.removeLastOrderForMember(member.id);
    if (!mounted) return;

    _undoCountdownController.stop();
    _hideUndoBanner();
  }

  void _undoLast() async {
    HapticFeedback.mediumImpact();
    await ref.read(ordersProvider(widget.tableId).notifier).undoLastOrder();
    _undoCountdownController.stop();
    _hideUndoBanner();
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
      _showUndoBanner('+1 for everyone (${members.length})', seconds: 5);
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
      _showUndoBanner('Random +$confirmed orders added', seconds: 5);
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
        onTimer: member.isPaid
            ? null
            : () async {
                Navigator.pop(context);
                await _showTimerSheet(member);
              },
        onClearTimer: !member.isPaid && member.timerEndsAt != null
            ? () async {
                Navigator.pop(context);
                await ref
                    .read(membersProvider(widget.tableId).notifier)
                    .clearTimer(member.id);
              }
            : null,
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
    await NotificationService.instance.syncTableTimerNotifications(
      widget.tableId,
      ref.read(tableRepositoryProvider),
    );
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
    final undoBottomOffset = MediaQuery.of(context).padding.bottom + 86;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: glassAppBar(
        context: context,
        scrollController: _scrollController,
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
          const Positioned.fill(child: _ActiveTableGlowBackdrop()),
          ListView(
            controller: _scrollController,
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
                  onTimer: () => _showTimerSheet(m),
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
                ...paidMembers.map((m) {
                  final ordersNotifier = ref.watch(
                    ordersProvider(widget.tableId).notifier,
                  );
                  final allPaidEvents = ref
                      .watch(tableEventsProvider(widget.tableId))
                      .where((event) => event.type == 'paid')
                      .where((event) => event.memberId == m.id)
                      .toList();
                  final paidEventCounts = {
                    for (final event in allPaidEvents)
                      event.id: ordersNotifier.getCountForPaidEvent(
                        m.id,
                        event.timestamp,
                      ),
                  };
                  final paidEvents = allPaidEvents
                      .where((event) => (paidEventCounts[event.id] ?? 0) > 0)
                      .toList();
                  final lastPaidEvent = paidEvents.lastOrNull;
                  final lastPaidCount = lastPaidEvent == null
                      ? null
                      : paidEventCounts[lastPaidEvent.id];

                  return _MemberCard(
                    member: m,
                    orderCount: ordersNotifier.getTotalCountForMember(m.id),
                    lastOrderTime: null,
                    onTap: () => _showPaidMemberDialog(m),
                    onDecrement: null,
                    onLongPress: () => _showMemberOptions(m),
                    isPaid: true,
                    onEdit: () => _renameMember(m),
                    onDelete: () => _removeMember(m),
                    lastPaidCount: lastPaidCount,
                    onPaidToggle: () async {
                      await ref
                          .read(membersProvider(widget.tableId).notifier)
                          .markUnpaid(m.id);
                      ref.invalidate(tableEventsProvider(widget.tableId));
                    },
                  );
                }),
              ],
            ],
          ),
          if (_showUndo && _undoMessage != null)
            Positioned(
              bottom: undoBottomOffset,
              left: 16,
              right: 16,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _undoBannerController,
                  curve: Curves.easeOutCubic,
                  reverseCurve: Curves.easeInCubic,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _undoBannerController,
                          curve: Curves.easeOutCubic,
                          reverseCurve: Curves.easeInCubic,
                        ),
                      ),
                  child: Material(
                    borderRadius: BorderRadius.circular(999),
                    color: AppColors.chipDark,
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          AnimatedBuilder(
                            animation: _undoCountdownController,
                            builder: (context, _) {
                              final remaining = math.max(
                                1,
                                (_undoTotalSeconds *
                                        (1 - _undoCountdownController.value))
                                    .ceil(),
                              );
                              return _UndoCountdownBadge(
                                progress: 1 - _undoCountdownController.value,
                                remaining: remaining,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _undoMessage!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _undoLast,
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'UNDO',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
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

class _UndoCountdownBadge extends StatelessWidget {
  final double progress;
  final int remaining;

  const _UndoCountdownBadge({required this.progress, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 2.4,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          Text(
            '$remaining',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _orderLabel(int count) => count == 1 ? 'order' : 'orders';

class _ActiveTableGlowBackdrop extends StatelessWidget {
  const _ActiveTableGlowBackdrop();

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
                        Color(0xFFfd530c),
                        Color(0xFFfc5c0c),
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

class _MemberCard extends StatelessWidget {
  final MemberModel member;
  final int orderCount;
  final DateTime? lastOrderTime;
  final VoidCallback? onTap;
  final VoidCallback? onDecrement;
  final VoidCallback? onLongPress;
  final VoidCallback? onTimer;
  final Future<void> Function()? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function()? onPaidToggle;
  final bool isPaid;
  final int? lastPaidCount;

  const _MemberCard({
    required this.member,
    required this.orderCount,
    required this.lastOrderTime,
    required this.onTap,
    required this.onDecrement,
    required this.onLongPress,
    this.onTimer,
    required this.onEdit,
    required this.onDelete,
    required this.onPaidToggle,
    this.isPaid = false,
    this.lastPaidCount,
  });

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final paidFmt = member.paidAt == null
        ? null
        : timeFmt.format(member.paidAt!);
    final radius = BorderRadius.circular(20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey('member-${member.id}'),
        startActionPane: !isPaid
            ? ActionPane(
                motion: const DrawerMotion(),
                extentRatio: 0.26,
                children: [
                  SlidableAction(
                    onPressed: (_) => onTimer?.call(),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: Icons.timer_outlined,
                    label: 'Time',
                    padding: EdgeInsets.zero,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                ],
              )
            : null,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.78,
          children: [
            SlidableAction(
              onPressed: (_) => onEdit?.call(),
              backgroundColor: AppColors.secondary,
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
            borderRadius: radius,
            padding: EdgeInsets.zero,
            onTap: onTap,
            onLongPress: onLongPress,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _OrderWaveFill(
                      lastOrderTime: !isPaid ? lastOrderTime : null,
                      borderRadius: radius,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
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
                                  lastPaidCount != null && lastPaidCount! > 0
                                      ? 'Last paid at $paidFmt - $lastPaidCount ${_orderLabel(lastPaidCount!)}'
                                      : 'Paid at $paidFmt',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              else if (member.timerEndsAt != null &&
                                  member.timerEndsAt!.isAfter(DateTime.now()))
                                _MemberTimerLine(endsAt: member.timerEndsAt!)
                              else if (lastOrderTime != null)
                                Text(
                                  'Last: ${timeFmt.format(lastOrderTime!)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              else
                                Text(
                                  'No orders yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.muted(context),
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
                            foregroundColor: AppColors.muted(context),
                            backgroundColor: AppColors.chip(context),
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
                            backgroundColor: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MemberTimerLine extends StatefulWidget {
  final DateTime endsAt;

  const _MemberTimerLine({required this.endsAt});

  @override
  State<_MemberTimerLine> createState() => _MemberTimerLineState();
}

class _MemberTimerLineState extends State<_MemberTimerLine> {
  late Timer _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.endsAt.difference(_now);
    if (remaining <= Duration.zero) {
      return Text(
        'Time is up',
        style: TextStyle(
          fontSize: 13,
          color: AppColors.secondary,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final endFmt = DateFormat('HH:mm').format(widget.endsAt);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: AppColors.secondary.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 14,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatTimerRemaining(remaining),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          'Ends $endFmt',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _formatTimerRemaining(Duration remaining) {
  if (remaining.inHours >= 1) {
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return minutes == 0 ? '${hours}h left' : '${hours}h ${minutes}m left';
  }
  if (remaining.inMinutes >= 1) {
    return '${remaining.inMinutes}m left';
  }
  return '${remaining.inSeconds}s left';
}

class _OrderWaveFill extends StatefulWidget {
  final DateTime? lastOrderTime;
  final BorderRadius borderRadius;

  const _OrderWaveFill({
    required this.lastOrderTime,
    required this.borderRadius,
  });

  @override
  State<_OrderWaveFill> createState() => _OrderWaveFillState();
}

// Waves na pozadí MemberCard, když přidáme objednávku, tak se naplní a pak postupně vyprchá, pokud nepřijdou další objednávky.
class _OrderWaveFillState extends State<_OrderWaveFill>
    with TickerProviderStateMixin {
  static const _fullFill = 0.9;
  static const _waveLoop = Duration(
    seconds: 252,
  ); // lcm(7, 9, 12), waves rotace
  static const _fillDuration = Duration(
    seconds: 1,
  ); // animace naplnění po přidání objednávky
  static const _drainDuration = Duration(
    minutes: 5,
  ); // čas, po kterém se fill vyprchá, pokud nepřijdou další objednávky

  late final AnimationController _waveController;
  late final AnimationController _fillController;
  double _fillFrom = 0;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(vsync: this, duration: _waveLoop)
      ..repeat();
    _fillController = AnimationController(vsync: this, duration: _fillDuration);
  }

  @override
  void dispose() {
    _fillController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OrderWaveFill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.lastOrderTime != oldWidget.lastOrderTime &&
        widget.lastOrderTime != null) {
      _fillFrom = _currentFill(DateTime.now(), oldWidget.lastOrderTime);
      _fillController.forward(from: 0);
    }
  }

  double _targetFill(DateTime now, DateTime? triggerTime) {
    if (triggerTime == null) return 0;
    final age = now.difference(triggerTime);
    if (age >= _drainDuration) return 0;
    final progress = age.inMilliseconds / _drainDuration.inMilliseconds;
    return (_fullFill * (1 - progress)).clamp(0, _fullFill);
  }

  double _currentFill(DateTime now, DateTime? triggerTime) {
    final targetFill = _targetFill(now, triggerTime);
    if (!_fillController.isAnimating || widget.lastOrderTime == null) {
      return targetFill;
    }
    final progress = Curves.easeOutCubic.transform(_fillController.value);
    return lerpDouble(_fillFrom, targetFill, progress) ?? targetFill;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_waveController, _fillController]),
        builder: (context, _) {
          final fill = _currentFill(DateTime.now(), widget.lastOrderTime);
          if (fill <= 0.001) return const SizedBox.shrink();

          return Opacity(
            opacity: 0.09, // wave fill opacity
            child: ClipRRect(
              borderRadius: widget.borderRadius,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final waveSize = constraints.maxWidth * 2;
                  final emptyTop = constraints.maxHeight + 18;
                  final fullTop = constraints.maxHeight * 0.1;
                  final fillProgress = (fill / _fullFill).clamp(0.0, 1.0);
                  final top =
                      lerpDouble(emptyTop, fullTop, fillProgress) ?? emptyTop;
                  final baseTurns = _waveController.value;

                  return Stack(
                    children: [
                      _WaveBlob(
                        top: top,
                        left: -constraints.maxWidth * 0.5,
                        size: waveSize,
                        turns: baseTurns * 36,
                        color: AppColors.primary,
                      ),
                      _WaveBlob(
                        top: top + 8,
                        left: -constraints.maxWidth * 0.48,
                        size: waveSize,
                        turns: baseTurns * 28,
                        color: AppColors.secondary,
                      ),
                      _WaveBlob(
                        top: top + 14,
                        left: -constraints.maxWidth * 0.54,
                        size: waveSize * 0.96,
                        turns: baseTurns * 21,
                        color: AppColors.secondarySoft,
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _WaveBlob extends StatelessWidget {
  final double top;
  final double left;
  final double size;
  final double turns;
  final Color color;

  const _WaveBlob({
    required this.top,
    required this.left,
    required this.size,
    required this.turns,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      child: Transform.rotate(
        angle: turns * math.pi * 2,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(size * 0.36),
              topRight: Radius.circular(size * 0.44),
              bottomLeft: Radius.circular(size * 0.42),
              bottomRight: Radius.circular(size * 0.34),
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
  final VoidCallback? onTimer;
  final VoidCallback? onClearTimer;
  final VoidCallback onRemove;
  final VoidCallback onPaidToggle;

  const _MemberOptionsSheet({
    required this.member,
    required this.onRename,
    required this.onChangeAvatar,
    this.onTimer,
    this.onClearTimer,
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
          if (onTimer != null)
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: Text(
                member.timerEndsAt != null &&
                        member.timerEndsAt!.isAfter(DateTime.now())
                    ? 'Change timer'
                    : 'Set timer',
              ),
              subtitle:
                  member.timerEndsAt != null &&
                      member.timerEndsAt!.isAfter(DateTime.now())
                  ? Text(
                      'Ends at ${DateFormat('HH:mm').format(member.timerEndsAt!)}',
                    )
                  : null,
              onTap: onTimer,
            ),
          if (onClearTimer != null)
            ListTile(
              leading: const Icon(Icons.timer_off_outlined),
              title: const Text('Clear timer'),
              onTap: onClearTimer,
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
              color: member.isPaid
                  ? AppColors.muted(context)
                  : AppColors.success,
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
            style: TextStyle(color: AppColors.muted(context)),
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
            style: TextStyle(color: AppColors.muted(context), fontSize: 13),
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

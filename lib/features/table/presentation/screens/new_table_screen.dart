import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/table/data/member_avatars.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/widgets/avatar_picker_sheet.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

class NewTableScreen extends ConsumerStatefulWidget {
  const NewTableScreen({super.key});

  @override
  ConsumerState<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends ConsumerState<NewTableScreen> {
  final _tableNameController = TextEditingController();
  final _memberController = TextEditingController();
  final _memberFocus = FocusNode();
  final List<_PendingMember> _members = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _tableNameController.dispose();
    _memberController.dispose();
    _memberFocus.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _memberController.text.trim();
    if (name.isEmpty) return;
    setState(
      () => _members.add(_PendingMember(name: name, avatar: randomAvatarAsset())),
    );
    _memberController.clear();
    _memberFocus.requestFocus();
  }

  void _removeMember(int index) => setState(() => _members.removeAt(index));

  Future<void> _changePendingAvatar(int index) async {
    final chosen = await showAvatarPickerSheet(
      context,
      current: _members[index].avatar,
    );
    if (chosen == null) return;
    setState(() => _members[index].avatar = chosen);
  }

  Future<void> _createTable() async {
    if (_members.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Add at least one member')));
      return;
    }

    setState(() => _isCreating = true);
    final repo = ref.read(tableRepositoryProvider);
    final table = await repo.createTable(_tableNameController.text.trim());
    for (final member in _members) {
      await repo.addMember(table.id, member.name, avatarAsset: member.avatar);
    }
    ref.invalidate(activeTablesProvider);
    if (mounted) context.pushReplacement('/table/${table.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nové sezení'), centerTitle: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Založte stůl a přidejte partu.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedLight,
              ),
            ),
            const SizedBox(height: 20),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(title: 'Stůl'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tableNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Název stolu (volitelné)',
                      prefixIcon: Icon(Icons.table_bar_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AppSurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionHeader(title: 'Členové'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _memberController,
                          focusNode: _memberFocus,
                          textCapitalization: TextCapitalization.words,
                          onSubmitted: (_) => _addMember(),
                          decoration: const InputDecoration(
                            hintText: 'Jméno člena',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppIconCircleButton(
                        icon: Icons.add,
                        backgroundColor: AppColors.darkButton,
                        foregroundColor: Colors.white,
                        onPressed: _addMember,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Přidaní lidé',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceLight,
                    ),
                  ),
                ),
                AppPill(
                  label: '${_members.length}',
                  backgroundColor: AppColors.primarySoft,
                  foregroundColor: const Color(0xFF92400E),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_members.isEmpty)
              const _NewTableEmptyState()
            else
              ...List.generate(
                _members.length,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppSurfaceCard(
                    borderRadius: BorderRadius.circular(20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _changePendingAvatar(index),
                          child: MemberAvatar(
                            memberId: _members[index].name,
                            avatarAsset: _members[index].avatar,
                            name: _members[index].name,
                            diameter: 40,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _members[index].name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurfaceLight,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          color: AppColors.mutedLight,
                          onPressed: () => _removeMember(index),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppPrimaryButton(
              label:
                  'Start (${_members.length} member${_members.length == 1 ? '' : 's'})',
              icon: Icons.play_arrow_rounded,
              onPressed: _createTable,
              isLoading: _isCreating,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingMember {
  final String name;
  String avatar;

  _PendingMember({required this.name, required this.avatar});
}

class _NewTableEmptyState extends StatelessWidget {
  const _NewTableEmptyState();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      color: AppColors.chipLight,
      child: const Text(
        'Add your friends to get started',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedLight,
        ),
      ),
    );
  }
}

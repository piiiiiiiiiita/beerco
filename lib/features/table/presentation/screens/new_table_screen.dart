import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/core/theme/app_theme.dart';

class NewTableScreen extends ConsumerStatefulWidget {
  const NewTableScreen({super.key});

  @override
  ConsumerState<NewTableScreen> createState() => _NewTableScreenState();
}

class _NewTableScreenState extends ConsumerState<NewTableScreen> {
  final _tableNameController = TextEditingController();
  final _memberController = TextEditingController();
  final _memberFocus = FocusNode();
  final List<String> _members = [];
  bool _isCreating = false;

  final List<String> _emojis = [
    '🧑',
    '👩',
    '👨',
    '🧔',
    '👱',
    '🧕',
    '👴',
    '👵',
    '🧒',
    '👦',
    '👧',
  ];

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
    setState(() => _members.add(name));
    _memberController.clear();
    _memberFocus.requestFocus();
  }

  void _removeMember(int index) => setState(() => _members.removeAt(index));

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
    for (final name in _members) {
      await repo.addMember(table.id, name);
    }
    ref.invalidate(activeTablesProvider);
    if (mounted) context.pushReplacement('/table/${table.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Table',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table name
              TextField(
                controller: _tableNameController,
                decoration: InputDecoration(
                  hintText: 'Table name (optional)',
                  prefixIcon: const Icon(Icons.table_bar_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  filled: true,
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 28),
              Text(
                'Members',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Add member input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _memberController,
                      focusNode: _memberFocus,
                      decoration: InputDecoration(
                        hintText: 'Member name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                      ),
                      textCapitalization: TextCapitalization.words,
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: ElevatedButton(
                      onPressed: _addMember,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Icon(Icons.add, size: 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Members list
              Expanded(
                child: _members.isEmpty
                    ? Center(
                        child: Text(
                          'Add your friends to get started',
                          style: TextStyle(color: AppColors.mutedLight),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, i) {
                          final emoji = _emojis[i % _emojis.length];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                _members[i],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => _removeMember(i),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isCreating ? null : _createTable,
                child: _isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Start (${_members.length} member${_members.length == 1 ? '' : 's'})',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

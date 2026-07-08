import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/table/data/member_avatars.dart';

/// Bottom sheet to pick a member avatar. Returns the chosen asset path,
/// a random one (via the Random button), or null if dismissed.
Future<String?> showAvatarPickerSheet(BuildContext context, {String? current}) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose avatar',
                      style: Theme.of(sheetContext).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pop(sheetContext, randomAvatarAsset()),
                    icon: const Icon(Icons.shuffle, size: 18),
                    label: const Text('Random'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  for (final asset in memberAvatarAssets)
                    _AvatarOption(
                      asset: asset,
                      selected: asset == current,
                      onTap: () => Navigator.pop(sheetContext, asset),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AvatarOption extends StatelessWidget {
  final String asset;
  final bool selected;
  final VoidCallback onTap;

  const _AvatarOption({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : AppColors.border(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.chip(context),
          border: Border.all(color: borderColor, width: selected ? 3 : 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipOval(child: Image.asset(asset, fit: BoxFit.cover)),
      ),
    );
  }
}

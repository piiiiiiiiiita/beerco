import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

/// Hero card for the active table. Solid base colour with a soft top-left
/// radial light and an uneven (more rounded at the bottom) shape.
///
/// [creatorName] / [creatorAvatarAsset] are reserved for the future logged-in
/// mode; offline they stay null and the creator chip falls back to the table
/// name initial.
class TableHeroCard extends StatelessWidget {
  final String tableName;
  final int orderCount;
  final List<MemberModel> members;
  final VoidCallback? onEditName;
  final String? creatorName;
  final String? creatorAvatarAsset;

  const TableHeroCard({
    super.key,
    required this.tableName,
    required this.orderCount,
    required this.members,
    this.onEditName,
    this.creatorName,
    this.creatorAvatarAsset,
  });

  @override
  Widget build(BuildContext context) {
    final creatorInitial = tableName.trim().isNotEmpty
        ? tableName.trim()[0].toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
        // Single top-left white light over a solid grey base (opaque end
        // colour, so far corners stay grey instead of showing a second light).
        gradient: const RadialGradient(
          center: Alignment(-0.4, -0.8),
          radius: 1.3,
          colors: [Color(0xFFFDFDFF), Color(0xFFF8A91F)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _CreatorChip(
                initial: creatorInitial,
                name: creatorName,
                avatarAsset: creatorAvatarAsset,
              ),
              const Spacer(),
              AppIconCircleButton(
                icon: Icons.edit_outlined,
                onPressed: onEditName,
                backgroundColor: Colors.white.withValues(alpha: 0.5),
                borderColor: AppColors.borderLight.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              // White light fading into amber at 0.7 opacity (alpha 0xB3).
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.8),
                radius: 4.8,
                colors: [Color(0xFFFFFFFF), Color(0xB3F8A91F)],
              ),
            ),
            child: Text(
              tableName.isEmpty ? 'Stůl' : tableName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.mutedLight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$orderCount',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceLight,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'orders',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.mutedLight,
            ),
          ),
          if (members.isNotEmpty) ...[
            const SizedBox(height: 18),
            _MemberAvatarRow(members: members),
          ],
        ],
      ),
    );
  }
}

class _CreatorChip extends StatelessWidget {
  final String initial;
  final String? name;
  final String? avatarAsset;

  const _CreatorChip({required this.initial, this.name, this.avatarAsset});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            image: avatarAsset == null
                ? null
                : DecorationImage(
                    image: AssetImage(avatarAsset!),
                    fit: BoxFit.cover,
                  ),
          ),
          alignment: Alignment.center,
          child: avatarAsset != null
              ? null
              : Text(
                  initial,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF92400E),
                  ),
                ),
        ),
        if (name != null && name!.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            name!,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurfaceLight,
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  final List<MemberModel> members;

  const _MemberAvatarRow({required this.members});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 4;
    final visible = members.take(maxVisible).toList();
    final hasMore = members.length > maxVisible;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final member in visible)
          Align(
            widthFactor: 0.72,
            child: MemberAvatar(
              memberId: member.id,
              avatarAsset: member.avatarAsset,
              name: member.name,
              diameter: 52,
              ringWidth: 3,
            ),
          ),
        if (hasMore)
          Align(
            widthFactor: 0.72,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.chipLight,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.more_horiz,
                size: 22,
                color: AppColors.mutedLight,
              ),
            ),
          ),
      ],
    );
  }
}


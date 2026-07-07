import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/table/data/member_avatars.dart';

/// Circular member avatar: shows the chosen (or deterministic) character image,
/// falling back to the name initial if the image cannot be loaded.
class MemberAvatar extends StatelessWidget {
  final String memberId;
  final String? avatarAsset;
  final String name;
  final double diameter;
  final double ringWidth;
  final Color ringColor;
  final bool shadow;

  const MemberAvatar({
    super.key,
    required this.memberId,
    required this.avatarAsset,
    required this.name,
    required this.diameter,
    this.ringWidth = 2,
    this.ringColor = Colors.white,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
        border: Border.all(color: ringColor, width: ringWidth),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          resolvedAvatarAsset(memberId, avatarAsset),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: diameter * 0.42,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

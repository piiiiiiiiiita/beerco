import 'dart:math';

import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

/// Horizontal, scrollable member strip. First tile is a dashed "+" that adds a
/// member; tapping an existing member opens its edit options (name / avatar).
class MemberQuickStrip extends StatelessWidget {
  final List<MemberModel> members;
  final VoidCallback onAdd;
  final void Function(MemberModel member) onTapMember;

  const MemberQuickStrip({
    super.key,
    required this.members,
    required this.onAdd,
    required this.onTapMember,
  });

  static const double _avatar = 56;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.muted(context);

    return SizedBox(
      height: _avatar + 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: members.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _StripTile(
              label: 'Add',
              onTap: onAdd,
              child: CustomPaint(
                painter: _DashedCirclePainter(
                  color: muted.withValues(alpha: 0.6),
                ),
                child: const SizedBox(
                  width: _avatar,
                  height: _avatar,
                  child: Icon(Icons.add, color: AppColors.primary, size: 26),
                ),
              ),
            );
          }

          final member = members[index - 1];
          return _StripTile(
            label: member.name,
            onTap: () => onTapMember(member),
            child: MemberAvatar(
              memberId: member.id,
              avatarAsset: member.avatarAsset,
              name: member.name,
              diameter: _avatar,
            ),
          );
        },
      ),
    );
  }
}

class _StripTile extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback onTap;

  const _StripTile({
    required this.child,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: child),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;

  _DashedCirclePainter({required this.color});

  static const double _strokeWidth = 2;
  static const int _dashes = 22;
  static const double _gapRatio = 0.45;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (min(size.width, size.height) - _strokeWidth) / 2,
    );
    const segment = (2 * pi) / _dashes;
    const dash = segment * (1 - _gapRatio);
    for (var i = 0; i < _dashes; i++) {
      canvas.drawArc(rect, i * segment, dash, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter oldDelegate) =>
      oldDelegate.color != color;
}

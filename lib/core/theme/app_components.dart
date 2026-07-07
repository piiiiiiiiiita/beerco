import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';

/// Frosted-glass AppBar for detail screens. Use together with
/// `Scaffold(extendBodyBehindAppBar: true)` so content scrolls under the blur.
PreferredSizeWidget glassAppBar({
  Widget? title,
  List<Widget>? actions,
  bool centerTitle = false,
}) {
  return AppBar(
    title: title,
    actions: actions,
    centerTitle: centerTitle,
    backgroundColor: Colors.transparent,
    scrolledUnderElevation: 0,
    flexibleSpace: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            border: const Border(
              bottom: BorderSide(color: AppColors.borderLight),
            ),
          ),
        ),
      ),
    ),
  );
}

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final BorderRadius? borderRadius;
  final Color? color;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceLight,
        borderRadius: radius,
        boxShadow: [
          // Soft UI: borderless surface, soft diffuse shadow.
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const AppSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final trailingWidgets = trailing == null ? const <Widget>[] : [trailing!];

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.onSurfaceLight,
            ),
          ),
        ),
        ...trailingWidgets,
      ],
    );
  }
}

class AppPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: foregroundColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
      ),
    );
  }
}

class AppIconCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const AppIconCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor ?? AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? AppColors.borderLight),
          ),
          child: Icon(
            icon,
            size: 20,
            color: foregroundColor ?? AppColors.onSurfaceLight,
          ),
        ),
      ),
    );
  }
}

/// Full-width, vertically stacked dialog actions with spacing.
/// Primary (high emphasis) on top, secondary (medium emphasis) below.
class AppDialogActions extends StatelessWidget {
  final Widget primary;
  final Widget secondary;

  const AppDialogActions({
    super.key,
    required this.primary,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [primary, const SizedBox(height: 10), secondary],
    );
  }
}

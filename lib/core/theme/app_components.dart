import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';

/// Frosted-glass AppBar for detail screens. Use together with
/// `Scaffold(extendBodyBehindAppBar: true)` so content scrolls under the blur.
PreferredSizeWidget glassAppBar({
  required BuildContext context,
  required ScrollController scrollController,
  Widget? title,
  List<Widget>? actions,
  bool centerTitle = false,
}) {
  return _ScrollReactiveGlassAppBar(
    context: context,
    scrollController: scrollController,
    title: title,
    actions: actions,
    centerTitle: centerTitle,
  );
}

class _ScrollReactiveGlassAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final BuildContext context;
  final ScrollController scrollController;
  final Widget? title;
  final List<Widget>? actions;
  final bool centerTitle;

  const _ScrollReactiveGlassAppBar({
    required this.context,
    required this.scrollController,
    this.title,
    this.actions,
    required this.centerTitle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext _) {
    final isDark = AppColors.isDark(context);

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final showGlass =
            scrollController.hasClients && scrollController.offset > 8;

        return AppBar(
          title: title,
          actions: actions,
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          scrolledUnderElevation: 0,
          flexibleSpace: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            opacity: showGlass ? 1 : 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.backgroundDark.withValues(alpha: 0.32)
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
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
    final isDark = AppColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.surface(context),
        borderRadius: radius,
        border: isDark ? Border.all(color: AppColors.border(context)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
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
              color: AppColors.onSurface(context),
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
  final Gradient? gradient;

  const AppPill({
    super.key,
    required this.label,
    this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = gradient == null
        ? backgroundColor.withValues(alpha: 0.9)
        : Colors.white.withValues(alpha: 0.14);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: gradient == null ? backgroundColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
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
    final radius = BorderRadius.circular(999);
    final enabled = onPressed != null && !isLoading;
    final opacity = enabled || isLoading ? 1.0 : 0.55;

    return SizedBox(
      height: 58,
      child: Opacity(
        opacity: opacity,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.primary, AppColors.secondary],
              ),
              borderRadius: radius,
            ),
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: radius,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else ...[
                      Icon(
                        icon ?? Icons.arrow_forward,
                        size: 18,
                        color: Colors.white,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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
    final surface = backgroundColor ?? AppColors.surface(context);
    final border = borderColor ?? AppColors.border(context);
    final foreground = foregroundColor ?? AppColors.onSurface(context);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, size: 20, color: foreground),
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

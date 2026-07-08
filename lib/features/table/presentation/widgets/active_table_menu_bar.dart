import 'package:flutter/material.dart';
import 'package:beerco/core/theme/app_theme.dart';

class MenuBarItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const MenuBarItemData({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Dark rounded action bar. The tapped item expands into a pill with its label;
/// the others stay icon-only.
class ActiveTableMenuBar extends StatefulWidget {
  final List<MenuBarItemData> items;

  const ActiveTableMenuBar({super.key, required this.items});

  @override
  State<ActiveTableMenuBar> createState() => _ActiveTableMenuBarState();
}

class _ActiveTableMenuBarState extends State<ActiveTableMenuBar> {
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.isDark(context)
        ? AppColors.backgroundDark
        : AppColors.darkButton;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < widget.items.length; i++)
            _MenuButton(
              item: widget.items[i],
              selected: _selected == i,
              onTap: () {
                setState(() => _selected = i);
                widget.items[i].onTap();
              },
            ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  final MenuBarItemData item;
  final bool selected;
  final VoidCallback onTap;

  const _MenuButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  // Peek: hold (long-press) or hover reveals the label without firing onTap.
  bool _peeking = false;

  void _setPeek(bool value) {
    if (_peeking != value) setState(() => _peeking = value);
  }

  @override
  Widget build(BuildContext context) {
    final expanded = widget.selected || _peeking;

    return MouseRegion(
      onEnter: (_) => _setPeek(true),
      onExit: (_) => _setPeek(false),
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPressStart: (_) => _setPeek(true),
        onLongPressEnd: (_) => _setPeek(false),
        onLongPressCancel: () => _setPeek(false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: expanded
              ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
              : const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: expanded
                ? Colors.white.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.item.icon, size: 22, color: Colors.white),
              if (expanded) ...[
                const SizedBox(width: 8),
                Text(
                  widget.item.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

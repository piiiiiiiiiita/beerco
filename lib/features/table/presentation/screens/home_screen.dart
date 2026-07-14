import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:beerco/core/theme/app_components.dart';
import 'package:beerco/core/theme/app_theme.dart';
import 'package:beerco/features/order/presentation/providers/order_providers.dart';
import 'package:beerco/features/table/data/models/member_model.dart';
import 'package:beerco/features/table/data/models/table_model.dart';
import 'package:beerco/features/table/presentation/providers/table_providers.dart';
import 'package:beerco/features/table/presentation/widgets/member_avatar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(activeTablesProvider);
    final archived = ref.watch(archivedTablesProvider);
    final showOnboarding = active.isEmpty && archived.isEmpty;

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: _HomeGlowBackdrop()),
          SafeArea(
            child: showOnboarding
                ? _HomeOnboarding(onStart: () => context.push('/new-table'))
                : Column(
                    children: [
                      const _HomeHeader(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                          children: [
                            AppSectionHeader(
                              title: 'Aktivní stoly',
                              trailing: AppPill(
                                label: '${active.length}',
                                backgroundColor: AppColors.primaryTint(context),
                                foregroundColor:
                                    AppColors.primaryTintForeground(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            if (active.isEmpty)
                              const _EmptyStateCard(
                                title: 'Nothing is running yet',
                                subtitle:
                                    'Start a new session and add your first table.',
                              )
                            else
                              ...active.map(
                                (table) => _HomeTableCard(table: table),
                              ),
                            const SizedBox(height: 28),
                            const AppSectionHeader(title: 'History'),
                            const SizedBox(height: 14),
                            if (archived.isEmpty)
                              const _EmptyStateCard(
                                title: 'History is empty',
                                subtitle: 'Closed tables will appear here.',
                              )
                            else
                              AppSurfaceCard(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  children: [
                                    for (
                                      var i = 0;
                                      i < archived.length;
                                      i++
                                    ) ...[
                                      _HistoryRow(table: archived[i]),
                                      if (i != archived.length - 1)
                                        Divider(
                                          height: 1,
                                          indent: 12,
                                          endIndent: 12,
                                          color: AppColors.border(context),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: showOnboarding
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: AppPrimaryButton(
                  label: 'New Session',
                  icon: Icons.add,
                  onPressed: () => context.push('/new-table'),
                ),
              ),
            ),
    );
  }
}

class _HomeOnboarding extends StatelessWidget {
  final VoidCallback onStart;

  const _HomeOnboarding({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          const Spacer(),
          _OnboardingAvatarOrbit(isDark: isDark),
          const SizedBox(height: 36),
          Text(
            'First Session',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Create a table, add a party and start counting orders.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              height: 1.35,
              color: AppColors.muted(context),
            ),
          ),
          const SizedBox(height: 32),
          AppPrimaryButton(
            label: 'New Session',
            icon: Icons.add,
            onPressed: onStart,
          ),
          const Spacer(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _OnboardingAvatarOrbit extends StatelessWidget {
  final bool isDark;

  const _OnboardingAvatarOrbit({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const orbitAssets = [
      'assets/images/onboard/avatars/avatar-onboard-6.jpg',
      'assets/images/onboard/avatars/avatar-onboard-2.jpg',
      'assets/images/onboard/avatars/avatar-onboard-3.jpg',
      'assets/images/onboard/avatars/avatar-onboard-4.jpg',
      'assets/images/onboard/avatars/avatar-onboard-5.jpg',
      'assets/images/onboard/avatars/avatar-onboard-1.jpg',
      'assets/images/onboard/avatars/avatar-onboard-7.jpg',
      'assets/images/onboard/avatars/avatar-onboard-8.jpg',
    ];
    final circleSpecs = [
      (
        size: 332.0,
        color: isDark
            ? AppColors.glowYellow.withValues(alpha: 0.10)
            : AppColors.primary.withValues(alpha: 0.12),
        shadow: isDark
            ? AppColors.glowOrange.withValues(alpha: 0.12)
            : AppColors.primary.withValues(alpha: 0.10),
      ),
      (
        size: 248.0,
        color: isDark
            ? AppColors.glowOrange.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.22),
        shadow: isDark
            ? AppColors.glowOrange.withValues(alpha: 0.16)
            : AppColors.primary.withValues(alpha: 0.12),
      ),
      (
        size: 168.0,
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.34)
            : AppColors.primary.withValues(alpha: 0.44),
        shadow: isDark
            ? AppColors.glowOrange.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.14),
      ),
      /* (
        size: 112.0,
        color: isDark
            ? AppColors.primary.withValues(alpha: 0.72)
            : AppColors.primary.withValues(alpha: 0.88),
        shadow: isDark
            ? AppColors.glowOrange.withValues(alpha: 0.20)
            : AppColors.primary.withValues(alpha: 0.16),
      ), */
    ];

    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: 382,
              height: 382,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final spec in circleSpecs)
                    Container(
                      width: spec.size,
                      height: spec.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: spec.color,
                        boxShadow: [
                          BoxShadow(
                            color: spec.shadow,
                            blurRadius: 28,
                            spreadRadius: 1,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const _OrbitAvatar(
            asset: 'assets/images/onboard/avatars/avatar-onboard-0.jpg',
            size: 104,
            top: 108,
            left: 108,
            hero: true,
          ),
          for (var i = 0; i < orbitAssets.length; i++)
            _OrbitAvatar(
              asset: orbitAssets[i],
              size: _orbitSpecs[i].size,
              top: _orbitSpecs[i].top,
              left: _orbitSpecs[i].left,
              rotation: _orbitSpecs[i].rotation,
              orbitIndex: i,
            ),
        ],
      ),
    );
  }
}

class _OrbitAvatar extends StatefulWidget {
  final String asset;
  final double size;
  final double top;
  final double left;
  final double rotation;
  final bool hero;
  final int? orbitIndex;

  const _OrbitAvatar({
    required this.asset,
    required this.size,
    required this.top,
    required this.left,
    this.rotation = 0.0,
    this.hero = false,
    this.orbitIndex,
  });

  @override
  State<_OrbitAvatar> createState() => _OrbitAvatarState();
}

class _OrbitAvatarState extends State<_OrbitAvatar>
    with TickerProviderStateMixin {
  AnimationController? _scaleController;
  AnimationController? _rotationController;

  bool get _animates => !widget.hero && widget.orbitIndex != null;

  void _ensureControllers() {
    final orbitIndex = widget.orbitIndex ?? 0;
    _scaleController ??= AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 5200 + (orbitIndex * 430)),
    );
    _rotationController ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    if (_animates) {
      if (!_scaleController!.isAnimating) {
        _scaleController!.value = ((orbitIndex * 13) % 100) / 100;
        _scaleController!.repeat(reverse: true);
      }
      if (!_rotationController!.isAnimating) {
        _rotationController!.repeat(reverse: true);
      }
    } else {
      _scaleController!.value = 0.5;
      _rotationController!.value = 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureControllers();
  }

  @override
  void reassemble() {
    super.reassemble();
    _ensureControllers();
  }

  @override
  void dispose() {
    _scaleController?.dispose();
    _rotationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _ensureControllers();
    final isDark = AppColors.isDark(context);
    final orbitIndex = widget.orbitIndex ?? 0;
    final minScale = 0.96 + ((orbitIndex % 3) * 0.01);
    final maxScale = 1.03 + ((orbitIndex % 4) * 0.01);
    final cornerRadius = widget.hero ? 30.0 : widget.size * 0.22;

    final avatar = Container(
      width: widget.size,
      height: widget.size,
      decoration: widget.hero
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              image: DecorationImage(
                image: AssetImage(widget.asset),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.75),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
                  blurRadius: 34,
                  offset: const Offset(0, 12),
                ),
              ],
            )
          : BoxDecoration(
              borderRadius: BorderRadius.circular(cornerRadius),
              image: DecorationImage(
                image: AssetImage(widget.asset),
                fit: BoxFit.cover,
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.82),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? AppColors.glowOrange.withValues(alpha: 0.18)
                      : AppColors.glowYellow.withValues(alpha: 0.24),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
    );

    return Positioned(
      top: widget.top,
      left: widget.left,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleController!, _rotationController!]),
        child: avatar,
        builder: (context, child) {
          final rotation = _animates
              ? ui.lerpDouble(
                  widget.rotation,
                  widget.rotation + 0.15,
                  Curves.easeInOut.transform(_rotationController!.value),
                )!
              : 0.0;
          final scale = _animates
              ? ui.lerpDouble(
                  minScale,
                  maxScale,
                  Curves.easeInOut.transform(_scaleController!.value),
                )!
              : 1.0;

          return Transform.rotate(
            angle: rotation,
            child: Transform.scale(scale: scale, child: child),
          );
        },
      ),
    );
  }
}

class _OrbitSpec {
  final double size;
  final double top;
  final double left;
  final double rotation;

  const _OrbitSpec({
    required this.size,
    required this.top,
    required this.left,
    required this.rotation,
  });
}

const _orbitSpecs = [
  // Position and rotation follow the same orbitAssets index order.
  _OrbitSpec(
    size: 60,
    top: -14,
    left: 120,
    rotation: -0.25,
  ), // avatar-onboard-6.jpg
  _OrbitSpec(
    size: 72,
    top: 40,
    left: 22,
    rotation: 0.1,
  ), // avatar-onboard-2.jpg
  _OrbitSpec(
    size: 70,
    top: 30,
    left: 190,
    rotation: 0.36,
  ), //avatar-onboard-3.jpg
  _OrbitSpec(
    size: 54,
    top: 145,
    left: -10,
    rotation: -0.32,
  ), // avatar-onboard-4.jpg
  _OrbitSpec(
    size: 54,
    top: 90,
    left: 272,
    rotation: 0.64,
  ), // avatar-onboard-5.jpg
  _OrbitSpec(
    size: 74,
    top: 230,
    left: 52,
    rotation: -0.16,
  ), // avatar-onboard-1.jpg
  _OrbitSpec(
    size: 64,
    top: 170,
    left: 250,
    rotation: -0.42,
  ), // avatar-onboard-7.jpg
  _OrbitSpec(
    size: 62,
    top: 235,
    left: 160,
    rotation: -0.03,
  ), // avatar-onboard-8.jpg
];

class _HomeGlowBackdrop extends StatelessWidget {
  const _HomeGlowBackdrop();

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
                        Color(0xCCfd530c),
                        Color(0x88fc5c0c),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _AnimatedHomeBrand(),
          const SizedBox(height: 4),
          Text(
            'Track orders. Check the bill.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.glowYellow.withValues(alpha: 0.86)
                  : AppColors.surfaceDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedHomeBrand extends StatefulWidget {
  const _AnimatedHomeBrand();

  @override
  State<_AnimatedHomeBrand> createState() => _AnimatedHomeBrandState();
}

class _AnimatedHomeBrandState extends State<_AnimatedHomeBrand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const text = Text(
      'BEERCO',
      style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
    );

    return AnimatedBuilder(
      animation: _controller,
      child: text,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final shaderRect = Rect.fromLTWH(
              bounds.left - bounds.width * 3.5,
              bounds.top,
              bounds.width * 8,
              bounds.height,
            );

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              tileMode: TileMode.repeated,
              transform: _SlidingGradientTransform(_controller.value),
              colors: const [
                AppColors.backgroundDark,
                Color(0xFF2B0B02),
                Color(0xFF120503),
                Color(0xFF2B0C02),
                Color(0xFF451203),
                Color(0xFF5C1805),
                Color(0xFF7B2006),
                Color(0xFFA73A11),
                Color(0xFFC95C23),
                Color(0xFFDC7332),
                Color(0xFFE5823B),
                Color(0xFFF19B4F),
                Color(0xFF631A04),
                Color(0xFFF19B4F),
                Color(0xFFE5823B),
                Color(0xFFDC7332),
                Color(0xFFC95C23),
                Color(0xFFA73A11),
                Color(0xFF7B2006),
                Color(0xFF5C1805),
                Color(0xFF451203),
                Color(0xFF2B0C02),
                Color(0xFF120503),
                Color(0xFF2B0B02),
                AppColors.backgroundDark,
              ],
            ).createShader(shaderRect);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {ui.TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

class _HomeTableCard extends ConsumerWidget {
  final TableModel table;

  const _HomeTableCard({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(membersProvider(table.id));
    final orders = ref.watch(ordersProvider(table.id));
    final orderCount = orders.fold<int>(
      0,
      (sum, order) => sum + order.quantity,
    );
    final isDark = AppColors.isDark(context);

    final card = AppSurfaceCard(
      onTap: () => context.push('/table/${table.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          // table name , název stolu
                          child: Text(
                            table.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: AppColors.muted(context),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatRelativeTime(table.createdAt),
                          style: TextStyle(
                            color: AppColors.muted(context),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AppPill(
                label: '$orderCount piv',
                icon: Icons.local_bar_rounded,
                backgroundColor: AppColors.successTint(context),
                foregroundColor: isDark
                    ? AppColors.mutedDark
                    : AppColors.muted(context),
                gradient: isDark
                    ? const RadialGradient(
                        center: Alignment(-0.3, -0.8),
                        radius: 4.8,
                        colors: [Color(0x21FFFFFF), Color(0x4DF8A91F)],
                      )
                    : const RadialGradient(
                        center: Alignment(-0.3, -0.8),
                        radius: 4.8,
                        colors: [Color(0xFFF7F7F7), Color(0xFFF7F7F7)],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _MemberAvatarStrip(members: members)),
              const SizedBox(width: 12),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Detail',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey('table-${table.id}'),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.5,
          children: [
            SlidableAction(
              onPressed: (_) => _TableActions.archive(context, table),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: Icons.archive_outlined,
              label: 'Archive',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _TableActions.delete(context, table),
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              padding: EdgeInsets.zero,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ],
        ),
        child: card,
      ),
    );
  }
}

class _HistoryRow extends ConsumerWidget {
  final TableModel table;

  const _HistoryRow({required this.table});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider(table.id));
    final orderCount = orders.fold<int>(
      0,
      (sum, order) => sum + order.quantity,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/table/${table.id}/summary'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 20,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    table.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('d. M. HH:mm').format(table.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$orderCount piv',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                PopupMenuButton<_HistoryAction>(
                  onSelected: (action) {
                    if (action == _HistoryAction.restore) {
                      _TableActions.restore(context, table);
                    } else {
                      _TableActions.delete(context, table);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _HistoryAction.restore,
                      child: Text('Restore'),
                    ),
                    PopupMenuItem(
                      value: _HistoryAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum _HistoryAction { restore, delete }

class _MemberAvatarStrip extends StatelessWidget {
  final List<MemberModel> members;

  const _MemberAvatarStrip({required this.members});

  @override
  Widget build(BuildContext context) {
    final visible = members.take(3).toList();
    final overflow = members.length - visible.length;

    return Row(
      children: [
        for (final member in visible)
          Align(
            widthFactor: 0.7,
            child: MemberAvatar(
              memberId: member.id,
              avatarAsset: member.avatarAsset,
              name: member.name,
              diameter: 32,
              shadow: false,
            ),
          ),
        if (overflow > 0)
          Align(
            widthFactor: 0.7,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.chip(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.avatarRing(context),
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '+$overflow',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.muted(context),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _EmptyStateCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableActions {
  static Future<void> archive(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Archive table?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${table.name} will move to history. You can restore it later.',
            ),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Archive'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await container.read(tableRepositoryProvider).archiveTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      showAppToast(context, '${table.name} moved to history');
    }
  }

  static Future<void> restore(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    await container.read(tableRepositoryProvider).reactivateTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      showAppToast(context, '${table.name} restored to active tables');
    }
  }

  static Future<void> delete(BuildContext context, TableModel table) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete table?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${table.name} and all related orders will be deleted.'),
            const SizedBox(height: 20),
            AppDialogActions(
              primary: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                child: const Text('Delete'),
              ),
              secondary: OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    await container.read(tableRepositoryProvider).deleteTable(table.id);
    container.invalidate(activeTablesProvider);
    container.invalidate(archivedTablesProvider);
    if (context.mounted) {
      showAppToast(context, '${table.name} deleted');
    }
  }
}

String _formatRelativeTime(DateTime createdAt) {
  final difference = DateTime.now().difference(createdAt);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inMinutes < 60) return 'před ${difference.inMinutes} min';
  if (difference.inHours < 24) {
    final minutes = difference.inMinutes.remainder(60);
    if (minutes == 0) return 'před ${difference.inHours} h';
    return 'před ${difference.inHours}h ${minutes}m';
  }
  return DateFormat('d. M.').format(createdAt);
}

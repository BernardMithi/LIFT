import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/widgets/lift_floating_island.dart';
import 'package:lift/shared/widgets/lift_pressable.dart';

class LiftIslandHeader extends StatefulWidget {
  const LiftIslandHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.center,
    this.leadingSlotWidth = 48,
    this.trailingSlotWidth = 48,
    this.scrollController,
    this.collapseOnScroll = true,
    this.collapseScrollDistance = kLiftIslandHeaderCollapseDistance,
    this.collapsedCenter,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? center;
  final double leadingSlotWidth;
  final double trailingSlotWidth;

  /// When set with [collapseOnScroll], vertical scroll offset drives the
  /// expanded bar → floating buttons transition.
  final ScrollController? scrollController;

  final bool collapseOnScroll;
  final double collapseScrollDistance;
  final Widget? collapsedCenter;

  @override
  State<LiftIslandHeader> createState() => _LiftIslandHeaderState();
}

class _LiftIslandHeaderState extends State<LiftIslandHeader> {
  double _collapseT = 0.0;

  bool get _usesScrollCollapse =>
      widget.collapseOnScroll && widget.scrollController != null;

  @override
  void initState() {
    super.initState();
    widget.scrollController?.addListener(_syncCollapseFromScroll);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _syncCollapseFromScroll(),
    );
  }

  @override
  void didUpdateWidget(covariant LiftIslandHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController?.removeListener(_syncCollapseFromScroll);
      widget.scrollController?.addListener(_syncCollapseFromScroll);
    }
    _syncCollapseFromScroll();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_syncCollapseFromScroll);
    super.dispose();
  }

  void _syncCollapseFromScroll() {
    if (!_usesScrollCollapse) {
      if (_collapseT != 0.0) {
        setState(() => _collapseT = 0.0);
      }
      return;
    }
    final c = widget.scrollController!;
    if (!c.hasClients) return;
    // Same controller must not be attached to two scroll views at once.
    if (c.positions.length != 1) return;
    final position = c.positions.single;
    if (position.axis != Axis.vertical) return;
    final t = (position.pixels / widget.collapseScrollDistance).clamp(0.0, 1.0);
    if ((t - _collapseT).abs() > 0.004) {
      setState(() => _collapseT = t);
    }
  }

  Widget _centerContent() {
    if (widget.center != null) return widget.center!;

    final titleTrim = widget.title?.trim();
    final subtitleTrim = widget.subtitle?.trim();
    final hasTitle = titleTrim != null && titleTrim.isNotEmpty;
    final hasSubtitle = subtitleTrim != null && subtitleTrim.isNotEmpty;

    if (!hasTitle && !hasSubtitle) {
      return const _LiftIslandEmptyGrabber();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasTitle)
          Text(
            titleTrim,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kLiftIslandOnFrosted,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (hasSubtitle) ...[
          if (hasTitle) const SizedBox(height: 2),
          Text(
            subtitleTrim,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _leadingSlot(Widget? child, {required bool reserveSpace}) {
    return SizedBox(
      width: reserveSpace ? widget.leadingSlotWidth : 0.0,
      height: 48,
      child: Align(
        alignment: Alignment.centerLeft,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  Widget _trailingSlot(Widget? child, {required bool reserveSpace}) {
    return SizedBox(
      width: reserveSpace ? widget.trailingSlotWidth : 0.0,
      height: 48,
      child: Align(
        alignment: Alignment.centerRight,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  /// 48×48 circular frosted backing for scroll-collapsed leading / trailing.
  static const double _kCollapsedOrbRadius = 24;

  Widget _collapsedOrb(Widget chrome) {
    return LiftFloatingIslandSurface(
      borderRadius: _kCollapsedOrbRadius,
      boxShadow: LiftFloatingIslandTokens.chipShadows,
      child: SizedBox(width: 48, height: 48, child: chrome),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leading = widget.leading;
    final trailing = widget.trailing;
    final canCollapseChrome = leading != null || trailing != null;
    final reserveSideSlots = canCollapseChrome;
    final t = _usesScrollCollapse && canCollapseChrome ? _collapseT : 0.0;

    return IconTheme.merge(
      data: const IconThemeData(color: kLiftIslandOnFrosted, size: 24),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: kLiftIslandOnFrosted),
        child:
            _usesScrollCollapse && canCollapseChrome
                ? SizedBox(
                  height: kLiftIslandHeaderHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Full-width island: fades out as user scrolls down.
                      IgnorePointer(
                        ignoring: t >= 0.5,
                        child: Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: LiftFloatingIslandSurface(
                            boxShadow: LiftFloatingIslandTokens.headerShadows,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  _leadingSlot(
                                    leading,
                                    reserveSpace: reserveSideSlots,
                                  ),
                                  Expanded(
                                    child: Center(child: _centerContent()),
                                  ),
                                  _trailingSlot(
                                    trailing,
                                    reserveSpace: reserveSideSlots,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Twin floating frosted buttons: fade in (same horizontal slots).
                      IgnorePointer(
                        ignoring: t < 0.5,
                        child: Opacity(
                          opacity: t.clamp(0.0, 1.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (widget.collapsedCenter != null)
                                widget.collapsedCenter!,
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (leading != null)
                                      _collapsedOrb(leading)
                                    else
                                      const SizedBox.shrink(),
                                    const Spacer(),
                                    if (trailing != null)
                                      _collapsedOrb(trailing)
                                    else
                                      const SizedBox.shrink(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                : SizedBox(
                  height: kLiftIslandHeaderHeight,
                  child: LiftFloatingIslandSurface(
                    boxShadow: LiftFloatingIslandTokens.headerShadows,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _leadingSlot(leading, reserveSpace: reserveSideSlots),
                          Expanded(child: Center(child: _centerContent())),
                          _trailingSlot(
                            trailing,
                            reserveSpace: reserveSideSlots,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }
}

/// Neutral pill shown when the island has no title/subtitle (and no custom [LiftIslandHeader.center]).
class _LiftIslandEmptyGrabber extends StatelessWidget {
  const _LiftIslandEmptyGrabber();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 5,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class LiftIslandHeaderAction extends StatelessWidget {
  const LiftIslandHeaderAction({
    super.key,
    required this.child,
    this.onTap,
    this.onTapWithContext,
  }) : assert(
         onTap == null || onTapWithContext == null,
         'Provide only one of onTap or onTapWithContext',
       );

  final Widget child;
  final VoidCallback? onTap;

  /// Receives this control's context (for overlay anchoring without a [GlobalKey]
  /// when the header duplicates actions during scroll collapse).
  final void Function(BuildContext buttonContext)? onTapWithContext;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (buttonContext) {
        return LiftPressable(
          onTap:
              onTapWithContext != null
                  ? () => onTapWithContext!(buttonContext)
                  : onTap,
          borderRadius: kIosCornerRadius,
          pressedScale: LiftMotion.gentlePressScale,
          child: SizedBox(width: 48, height: 48, child: Center(child: child)),
        );
      },
    );
  }
}

class LiftIslandHeaderIconAction extends StatelessWidget {
  const LiftIslandHeaderIconAction({
    super.key,
    this.icon,
    this.iconWidget,
    this.onTap,
    this.onTapWithContext,
    this.iconSize = kLiftIslandHeaderLeadingIconSize,
    this.color = kLiftIslandOnFrosted,
  }) : assert(icon != null || iconWidget != null, 'Provide icon or iconWidget'),
       assert(
         onTap == null || onTapWithContext == null,
         'Provide only one of onTap or onTapWithContext',
       );

  final IconData? icon;
  final Widget? iconWidget;
  final VoidCallback? onTap;
  final void Function(BuildContext buttonContext)? onTapWithContext;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LiftIslandHeaderAction(
      onTap: onTap,
      onTapWithContext: onTapWithContext,
      child: iconWidget ?? Icon(icon!, size: iconSize, color: color),
    );
  }
}

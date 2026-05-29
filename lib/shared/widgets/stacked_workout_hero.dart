import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/workout_template.dart';
import 'package:lift/shared/widgets/workout_template_hero_image.dart';

/// Page snap tuned slightly softer than default [PageScrollPhysics] for deck cycling.
class _StackedDeckPagePhysics extends PageScrollPhysics {
  const _StackedDeckPagePhysics({super.parent});

  @override
  _StackedDeckPagePhysics applyTo(ScrollPhysics? ancestor) {
    return _StackedDeckPagePhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
    mass: 0.52,
    stiffness: 88.0,
    ratio: 1.18,
  );
}

/// When there are **3+** templates, both behind-card peek strips use this fraction of
/// hero height so the **middle** and **back** visible bands match in height.
/// For **2** templates, one strip uses the same fraction (width steps replace scale).
const double kStackedWorkoutWalletPeekStripFraction = 0.085;

/// One peek strip must fit [_PeekTitleText] (padding + ~10.5pt line); raw fraction
/// alone was too short on typical heroes and clipped labels.
const double kStackedWorkoutWalletPeekStripMinHeight = 24.0;
const double kStackedWorkoutWalletPeekStripMaxHeight = 44.0;

/// Effective height for one wallet peek strip — must match [StackedWorkoutHero] layout.
double stackedWorkoutPeekStripHeight(double maxHeight) {
  if (!maxHeight.isFinite || maxHeight <= 0) return 0.0;
  final raw = maxHeight * kStackedWorkoutWalletPeekStripFraction;
  return raw.clamp(
    kStackedWorkoutWalletPeekStripMinHeight,
    kStackedWorkoutWalletPeekStripMaxHeight,
  );
}

/// Horizontal width of each stack layer: front 100%, first behind 90%, second 80%, …
double stackedWorkoutWalletWidthFactorForDepth(int depth) {
  if (depth <= 0) return 1.0;
  if (depth == 1) return 0.9;
  if (depth == 2) return 0.8;
  return (1.0 - 0.1 * depth).clamp(0.5, 1.0);
}

/// Vertical offset from the top of the hero to where the **front** card image starts
/// (below wallet peek strips). Use to align overlays (e.g. completion badges) with the
/// visible front card.
double stackedWorkoutFrontCardTopInset({
  required double maxHeight,
  required int templateCount,
}) {
  if (templateCount <= 1 || !maxHeight.isFinite || maxHeight <= 0) return 0.0;
  final strip = stackedWorkoutPeekStripHeight(maxHeight);
  if (templateCount >= 3) return strip + strip;
  return strip;
}

/// Hero tile for one or more workouts on the same day: **vertical** swipe cycles
/// cards — the front moves to the **back** of the deck (no card flies off-screen).
/// **Wallet-style**: behind cards use **stepped widths** (100% / 90% / 80%, …) centered
/// under the front, and peek **strips** at the top expose titles. Transforms are lerped
/// against [PageController.page] for smooth motion.
class StackedWorkoutHero extends StatefulWidget {
  const StackedWorkoutHero({
    super.key,
    required this.templates,
    required this.borderRadius,
    required this.onTap,
    required this.overlayBuilder,
    this.onPageChanged,
    this.interactive = true,
  }) : assert(templates.length > 0);

  final List<WorkoutTemplate> templates;
  final double borderRadius;
  final VoidCallback onTap;
  final void Function(int index)? onPageChanged;

  /// When false, swiping between workouts still works but there is no tap splash
  /// (e.g. month calendar preview).
  final bool interactive;

  /// Bottom gradient + labels for the workout at [index].
  final Widget Function(
    BuildContext context,
    WorkoutTemplate template,
    int index,
  )
  overlayBuilder;

  @override
  State<StackedWorkoutHero> createState() => _StackedWorkoutHeroState();
}

/// Distance from front in stack order: 0 = front, 1 = first behind, …
int cyclicDepth(int templateIndex, int frontIndex, int n) {
  if (n <= 1) return 0;
  final p = frontIndex.clamp(0, n - 1);
  return (templateIndex - p + n) % n;
}

/// Wraps a signed integer index for template \([0, n)\).
int _modInt(int i, int n) {
  if (n <= 1) return 0;
  var m = i % n;
  if (m < 0) m += n;
  return m;
}

class _StackedWorkoutHeroState extends State<StackedWorkoutHero> {
  static const double _kBehindDyPerStep = 6.0;

  /// Large middle band so users can swipe up/down indefinitely (cyclic deck).
  static const int _kPageBand = 1000;

  late PageController _controller;
  /// Logical front index in \([0, n)\), not the raw PageView index.
  int _logicalPage = 0;

  int get _n => widget.templates.length;

  @override
  void initState() {
    super.initState();
    final n = _n;
    final initialRaw = n * _kPageBand;
    _controller = PageController(initialPage: initialRaw);
    _logicalPage = 0;
  }

  @override
  void didUpdateWidget(StackedWorkoutHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.templates.length != widget.templates.length) {
      final n = _n;
      final preserved = _logicalPage.clamp(0, n > 0 ? n - 1 : 0);
      _controller.dispose();
      final initialRaw = n * _kPageBand + preserved;
      _controller = PageController(initialPage: initialRaw);
      _logicalPage = preserved;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Lerp metrics between discrete front indices so swaps stay smooth.
  /// [rawPage] is the unbounded [PageController.page]; do **not** pre-modulo it or
  /// lerps break when crossing multiples of [n].
  _WalletMetrics _metricsForCard({
    required int index,
    required double rawPage,
    required int n,
    required double peekHeight,
    required double secondPeekHeight,
  }) {
    if (n <= 1) {
      return _WalletMetrics(
        ty: 0.0,
        opacity: 1.0,
        layerTopInset: 0.0,
        widthFactor: 1.0,
      );
    }

    final pf = _modInt(rawPage.floor(), n);
    final pc = _modInt(rawPage.ceil(), n);
    final t = rawPage - rawPage.floor();

    final d0 = cyclicDepth(index, pf, n);
    final d1 = cyclicDepth(index, pc, n);

    final m0 = _metricsForDepth(d0, n, peekHeight, secondPeekHeight);
    final m1 = _metricsForDepth(d1, n, peekHeight, secondPeekHeight);

    // Lerp depth-derived visuals (handles 0↔n-1 wrap smoothly in metric space).
    return _WalletMetrics(
      ty: lerpDouble(m0.ty, m1.ty, t)!,
      opacity: lerpDouble(m0.opacity, m1.opacity, t)!,
      layerTopInset: lerpDouble(
        m0.layerTopInset,
        m1.layerTopInset,
        t,
      )!,
      widthFactor: lerpDouble(m0.widthFactor, m1.widthFactor, t)!,
    );
  }

  _WalletMetrics _metricsForDepth(
    int depth,
    int n,
    double peekHeight,
    double secondPeekHeight,
  ) {
    final d = depth.clamp(0, n).toDouble();
    final h2 = n >= 3 ? secondPeekHeight : 0.0;

    // Per-layer top padding so each card behind exposes a peek strip above it.
    double layerTopInset = 0.0;
    if (depth == 0 && n > 1) {
      layerTopInset = peekHeight + h2;
    } else if (depth == 1 && n >= 3) {
      layerTopInset = h2;
    }

    final widthFactor = stackedWorkoutWalletWidthFactorForDepth(depth);

    // Depth ≥2 used to nudge cards down; that skews the top peek vs the middle band.
    // For the 3-card wallet, keep depth 2 flush so both behind strips match in height.
    final ty =
        depth <= 1 || (depth == 2 && n >= 3)
            ? 0.0
            : _kBehindDyPerStep * (depth - 1);
    final opacity =
        depth <= 2
            ? 1.0
            : (1.0 - 0.07 * (d - 1).clamp(0.0, 2.0)).clamp(0.62, 1.0);

    return _WalletMetrics(
      ty: ty,
      opacity: opacity,
      layerTopInset: layerTopInset,
      widthFactor: widthFactor,
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.templates.length;

    final body = ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxH = constraints.maxHeight;
          // Two-card deck: first peek matches scale gap. Three+: both strips equal height.
          final double peekHeight;
          final double secondPeekHeight;
          if (!maxH.isFinite) {
            peekHeight = 0.0;
            secondPeekHeight = 0.0;
          } else if (n >= 3) {
            final strip = stackedWorkoutPeekStripHeight(maxH);
            peekHeight = strip;
            secondPeekHeight = strip;
          } else if (n == 2) {
            peekHeight = stackedWorkoutPeekStripHeight(maxH);
            secondPeekHeight = 0.0;
          } else {
            peekHeight = 0.0;
            secondPeekHeight = 0.0;
          }

          final wallet = AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final rawPage =
                  _controller.hasClients
                      ? (_controller.page ?? _controller.initialPage.toDouble())
                      : _controller.initialPage.toDouble();

              // Sort by depth (furthest back first) using lerped depth for z-order.
              final order = List<int>.generate(n, (i) => i);
              final pf = _modInt(rawPage.floor(), n);
              final pc = _modInt(rawPage.ceil(), n);
              final tt = rawPage - rawPage.floor();
              order.sort((a, b) {
                final da =
                    lerpDouble(
                      cyclicDepth(a, pf, n).toDouble(),
                      cyclicDepth(a, pc, n).toDouble(),
                      tt,
                    )!;
                final db =
                    lerpDouble(
                      cyclicDepth(b, pf, n).toDouble(),
                      cyclicDepth(b, pc, n).toDouble(),
                      tt,
                    )!;
                final c = db.compareTo(da);
                if (c != 0) return c;
                return a.compareTo(b);
              });

              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (final i in order)
                    Builder(
                      key: ValueKey<String>(widget.templates[i].id),
                      builder: (context) {
                        final t = widget.templates[i];
                        final m = _metricsForCard(
                          index: i,
                          rawPage: rawPage,
                          n: n,
                          peekHeight: peekHeight,
                          secondPeekHeight: secondPeekHeight,
                        );
                        if (m.opacity < 0.02) {
                          return const SizedBox.shrink();
                        }
                        final pageChild = _WorkoutHeroPage(
                          key: ValueKey<String>('hero_${t.id}'),
                          template: t,
                          borderRadius: widget.borderRadius,
                          overlay: widget.overlayBuilder(context, t, i),
                          pageListenable: _controller,
                          pageIndex: i,
                          templateCount: n,
                        );
                        return Positioned.fill(
                          child: RepaintBoundary(
                            child: Padding(
                              padding: EdgeInsets.only(top: m.layerTopInset),
                              child: Transform.translate(
                                offset: Offset(0, m.ty),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: FractionallySizedBox(
                                    widthFactor: m.widthFactor.clamp(0.01, 1.0),
                                    child: Opacity(
                                      opacity: m.opacity.clamp(0.0, 1.0),
                                      child: pageChild,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  if (n > 1 && peekHeight > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _WalletPeekTitlesLayer(
                          templates: widget.templates,
                          pageListenable: _controller,
                          peekHeight: peekHeight,
                          secondPeekHeight: secondPeekHeight,
                          n: n,
                        ),
                      ),
                    ),
                ],
              );
            },
          );

          // Wallet paints underneath; vertical PageView on top so vertical drags cycle
          // the deck (horizontal drags pass to parents if any).
          final platform = Theme.of(context).platform;
          final useBouncing =
              platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;

          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(child: wallet),
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.interactive ? widget.onTap : null,
                  behavior: HitTestBehavior.deferToChild,
                  child: PageView.builder(
                    scrollDirection: Axis.vertical,
                    controller: _controller,
                    physics: _StackedDeckPagePhysics(
                      parent: AlwaysScrollableScrollPhysics(
                        parent:
                            useBouncing
                                ? const BouncingScrollPhysics()
                                : const ClampingScrollPhysics(),
                      ),
                    ),
                    onPageChanged: (rawIndex) {
                      _logicalPage = rawIndex % n;
                      HapticFeedback.selectionClick();
                      widget.onPageChanged?.call(_logicalPage);
                    },
                    itemBuilder: (context, _) {
                      return const SizedBox.expand();
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!widget.interactive) {
      return body;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      clipBehavior: Clip.antiAlias,
      child: body,
    );
  }
}

class _WalletMetrics {
  const _WalletMetrics({
    required this.ty,
    required this.opacity,
    required this.layerTopInset,
    required this.widthFactor,
  });

  final double ty;
  final double opacity;
  /// Top padding for this layer so cards behind expose wallet peek strips above.
  final double layerTopInset;
  /// Fraction of stack width (1.0 = front, 0.9 / 0.8 = stepped behind cards).
  final double widthFactor;
}

/// Peek titles for the wallet strips — must paint **above** all stacked cards so the
/// middle strip is not covered by the front card (same global Y as front top inset).
class _WalletPeekTitlesLayer extends StatelessWidget {
  const _WalletPeekTitlesLayer({
    required this.templates,
    required this.pageListenable,
    required this.peekHeight,
    required this.secondPeekHeight,
    required this.n,
  });

  final List<WorkoutTemplate> templates;
  final PageController pageListenable;
  final double peekHeight;
  final double secondPeekHeight;
  final int n;

  @override
  Widget build(BuildContext context) {
    final h1 = peekHeight;
    final h2 = n >= 3 ? secondPeekHeight : 0.0;
    final topFirst = n >= 3 && h2 > 0 ? h2 : 0.0;

    return AnimatedBuilder(
      animation: pageListenable,
      builder: (context, _) {
        final raw =
            pageListenable.hasClients
                ? (pageListenable.page ??
                    pageListenable.initialPage.toDouble())
                : pageListenable.initialPage.toDouble();
        final pf = _modInt(raw.floor(), n);
        final pc = _modInt(raw.ceil(), n);
        final tSwipe = raw - raw.floor();

        double depthLerpFor(int i) {
          final d0 = cyclicDepth(i, pf, n);
          final d1 = cyclicDepth(i, pc, n);
          return lerpDouble(d0.toDouble(), d1.toDouble(), tSwipe)!;
        }

        final depths = List<double>.generate(n, depthLerpFor);

        Widget? topStrip;
        if (h2 > 0 && n >= 3) {
          final idx = _dominantPeekIndex(depths, targetDepth: 2.0);
          final opacity = _peekTitleOpacity(depths[idx], 2.0);
          topStrip = Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: h2,
            child: Opacity(
              opacity: opacity,
              child: _PeekTitleText(
                text: templates[idx].name.toUpperCase(),
              ),
            ),
          );
        }

        Widget? midStrip;
        if (h1 > 0 && n > 1) {
          final idx = _dominantPeekIndex(depths, targetDepth: 1.0);
          final opacity = _peekTitleOpacity(depths[idx], 1.0);
          midStrip = Positioned(
            left: 0,
            right: 0,
            top: topFirst,
            height: h1,
            child: Opacity(
              opacity: opacity,
              child: _PeekTitleText(
                text: templates[idx].name.toUpperCase(),
              ),
            ),
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (topStrip != null) topStrip,
            if (midStrip != null) midStrip,
          ],
        );
      },
    );
  }
}

/// Index of the template whose lerped depth is closest to [targetDepth] (peek row).
/// Near-ties pick the lower index so the label does not flip frame-to-frame.
int _dominantPeekIndex(List<double> depths, {required double targetDepth}) {
  const tieEps = 1e-6;
  var best = 0;
  var bestDist = double.infinity;
  for (var i = 0; i < depths.length; i++) {
    final dist = (depths[i] - targetDepth).abs();
    final isCloser = dist < bestDist - tieEps;
    final isTieBreak = (dist - bestDist).abs() <= tieEps && i < best;
    if (isCloser || isTieBreak) {
      bestDist = dist;
      best = i;
    }
  }
  return best;
}

/// Fades peek labels at the edges of each depth band instead of hard thresholds.
double _peekTitleOpacity(double depth, double targetDepth) {
  final dist = (depth - targetDepth).abs();
  // Slightly sharper falloff so only one strip reads as dominant during transitions.
  return (1.0 - dist / 0.5).clamp(0.0, 1.0);
}

class _PeekTitleText extends StatelessWidget {
  const _PeekTitleText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.68,
              height: 1.05,
              shadows: const [
                Shadow(
                  offset: Offset(0, 1),
                  blurRadius: 4,
                  color: Color(0x66000000),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutHeroPage extends StatelessWidget {
  const _WorkoutHeroPage({
    super.key,
    required this.template,
    required this.borderRadius,
    required this.overlay,
    this.pageListenable,
    this.pageIndex = 0,
    this.templateCount = 1,
  });

  final WorkoutTemplate template;
  final double borderRadius;
  final Widget overlay;
  final PageController? pageListenable;
  final int pageIndex;
  final int templateCount;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          WorkoutTemplateHeroImage(
            imageUrl: template.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccentDark, kAccentMid, kAccentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child:
                pageListenable != null
                    ? AnimatedBuilder(
                      animation: pageListenable!,
                      builder: (context, _) {
                        final raw =
                            pageListenable!.hasClients
                                ? (pageListenable!.page ??
                                    pageListenable!.initialPage.toDouble())
                                : pageListenable!.initialPage.toDouble();
                        final n = templateCount;
                        final pf = _modInt(raw.floor(), n);
                        final pc = _modInt(raw.ceil(), n);
                        final tSwipe = raw - raw.floor();
                        final d0 = cyclicDepth(pageIndex, pf, n);
                        final d1 = cyclicDepth(pageIndex, pc, n);
                        final depthLerp =
                            lerpDouble(d0.toDouble(), d1.toDouble(), tSwipe)!;
                        double overlayOpacity;
                        if (n <= 1) {
                          overlayOpacity = 1.0;
                        } else if (depthLerp <= 1.0) {
                          overlayOpacity =
                              1.0 -
                              Curves.easeInOutCubic.transform(
                                depthLerp.clamp(0.0, 1.0),
                              );
                        } else {
                          overlayOpacity = 0.0;
                        }
                        return Opacity(
                          opacity: overlayOpacity,
                          child: overlay,
                        );
                      },
                    )
                    : overlay,
          ),
        ],
      ),
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';

/// Alpha mask for the bottom of a top blur band — avoids a sharp horizontal cut.
Shader featherTopBlurMask(Rect bounds) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFFFFFFFF),
      const Color(0xFFFFFFFF).withValues(alpha: 0.92),
      const Color(0xFFFFFFFF).withValues(alpha: 0.45),
      const Color(0xFFFFFFFF).withValues(alpha: 0.12),
      const Color(0x00FFFFFF),
    ],
    stops: const [0.0, 0.12, 0.38, 0.62, 1.0],
  ).createShader(bounds);
}

/// 0 → 1 as [scroll] moves from [start] toward [start] + [rampDistance] (px).
/// Uses smoothstep so the blur eases in instead of popping on.
double scrollLinkedTopBlurProgress(
  ScrollController scroll, {
  double start = 0,
  double rampDistance = 100,
}) {
  if (!scroll.hasClients || scroll.positions.length != 1) return 0;
  final position = scroll.positions.single;
  if (position.axis != Axis.vertical) return 0;
  final pixels = position.pixels;
  if (pixels <= start) return 0;
  if (pixels >= start + rampDistance) return 1;
  final t = (pixels - start) / rampDistance;
  return t * t * (3 - 2 * t);
}

/// Blurs list/content behind it as the user scrolls up, strongest near the top.
/// Uses a feathered vertical mask so there is no hard edge through the content.
///
/// Place in a [Stack] **above** the scrolling child and **below** a floating
/// header; wrap in [IgnorePointer] so gestures reach the list.
///
/// Prefer a **taller** [Positioned] height (e.g. `listTopPadding + ~100`) so the
/// fade has room to run in screen space.
class ScrollLinkedTopBlurScrim extends StatelessWidget {
  const ScrollLinkedTopBlurScrim({
    super.key,
    required this.scrollController,
    this.maxBlurSigma = 18,
    this.scrollRampDistance = 100,
    this.topTint = Colors.white,
    this.maxTintOpacity = 0.28,
  });

  final ScrollController scrollController;
  final double maxBlurSigma;
  final double scrollRampDistance;
  final Color topTint;
  final double maxTintOpacity;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, _) {
        final t = scrollLinkedTopBlurProgress(
          scrollController,
          rampDistance: scrollRampDistance,
        );
        if (t < 0.003) {
          return const ColoredBox(color: Color(0x00000000));
        }
        final sigma = maxBlurSigma * t;
        // Feather the *entire* blur + tint so the bottom isn’t a hard ClipRect edge.
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: featherTopBlurMask,
          child: Stack(
            fit: StackFit.expand,
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: const DecoratedBox(
                  decoration: BoxDecoration(color: Color(0x00000000)),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      topTint.withValues(alpha: maxTintOpacity * t),
                      topTint.withValues(alpha: maxTintOpacity * 0.55 * t),
                      topTint.withValues(alpha: maxTintOpacity * 0.18 * t),
                      topTint.withValues(alpha: 0),
                    ],
                    stops: const [0.0, 0.22, 0.48, 1.0],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Neutral frosted band that stays visible at scroll offset 0.
///
/// Use where [ScrollLinkedTopBlurScrim] would disappear (t ≈ 0), e.g. workout
/// template detail: otherwise the hero photo bleeds through the translucent
/// island and reads as a coloured tint.
class StaticFeatheredTopBlurScrim extends StatelessWidget {
  const StaticFeatheredTopBlurScrim({
    super.key,
    this.blurSigma = 26,
  });

  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: featherTopBlurMask,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: const ColoredBox(color: Color(0x00000000)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.36),
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.28, 0.58, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

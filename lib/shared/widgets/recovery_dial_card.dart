import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

/// Dial diameter from card inner width — stable when tile height changes.
double recoveryDialSizeFromInnerWidth(double innerWidth) {
  final gap = (innerWidth * 0.05).clamp(12.0, 22.0);
  final rowInnerW = innerWidth * 0.95;
  const textColumnReserve = 76.0;
  final maxByWidth = (rowInnerW - gap - textColumnReserve).clamp(0.0, 240.0);
  const kPreferred = 128.0;
  return math.min(kPreferred, maxByWidth);
}

class RecoveryDialCard extends StatelessWidget {
  const RecoveryDialCard({
    super.key,
    required this.muscleName,
    required this.percentage,
    this.recoveryEtaLabel,
    this.lastHitLabel,
    this.showDots = false,
    this.dotCount = 0,
    this.activeDotIndex = 0,
    this.animationDuration = const Duration(milliseconds: 420),
  });

  final String muscleName;
  final int percentage;
  final String? recoveryEtaLabel;
  final String? lastHitLabel;
  final bool showDots;
  final int dotCount;
  final int activeDotIndex;
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percentage.clamp(0, 100).toDouble();
    final showIndicator = showDots && dotCount > 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final padX = (constraints.maxWidth * 0.05).clamp(10.0, 18.0).toDouble();
        const padY = 6.0;

        final innerW = (constraints.maxWidth - 2 * padX).clamp(
          0.0,
          double.infinity,
        );
        final verticalPad = 2 * padY;
        final availableH = math.max(0.0, constraints.maxHeight - verticalPad);
        // Dots row is ~8px; keep a few px slack for subpixel layout (avoids Column overflow).
        const dotsRowReserve = 12.0;
        final heightCap =
            showIndicator
                ? math.max(0.0, availableH - dotsRowReserve)
                : math.max(0.0, availableH - 2.0);
        const dialVisualScale = 0.84;
        final dialSide =
            math.min(recoveryDialSizeFromInnerWidth(innerW), heightCap) *
            dialVisualScale;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: padX, vertical: padY),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Center(
                        child: SizedBox(
                          height: dialSide,
                          child: _RecoveryDialFace(
                            muscleName: muscleName,
                            percentage: clampedPercent,
                            recoveryEtaLabel: recoveryEtaLabel,
                            lastHitLabel: lastHitLabel,
                            animationDuration: animationDuration,
                            dialSize: dialSide,
                          ),
                        ),
                      ),
                    ),
                    if (showIndicator)
                      Center(
                        child: _RecoverySwipeDots(
                          count: dotCount,
                          activeIndex: activeDotIndex,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecoveryDialFace extends StatelessWidget {
  const _RecoveryDialFace({
    required this.muscleName,
    required this.percentage,
    required this.recoveryEtaLabel,
    required this.lastHitLabel,
    required this.animationDuration,
    required this.dialSize,
  });

  final String muscleName;
  final double percentage;
  final String? recoveryEtaLabel;
  final String? lastHitLabel;
  final Duration animationDuration;
  final double dialSize;

  @override
  Widget build(BuildContext context) {
    final normalized = (percentage.clamp(0, 100) / 100.0);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: normalized),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            Color baseColorFor(double percent) {
              if (percent >= 80) return Colors.green.shade500;
              if (percent >= 50) return kRecoveryMidColor;
              return Colors.red.shade500;
            }

            final baseColor = baseColorFor(percentage);
            final eta = recoveryEtaLabel;
            final last = lastHitLabel;
            final gap = (constraints.maxWidth * 0.05).clamp(12.0, 22.0);
            final strokeWidth = (dialSize * 0.105).clamp(4.0, 13.0).toDouble();
            final percentFont = (dialSize * 0.24).clamp(11.0, 28.0).toDouble();
            var innerPadding = (strokeWidth * 1.9).clamp(6.0, 18.0).toDouble();
            innerPadding = math.min(innerPadding, dialSize * 0.30);

            return Center(
              child: FractionallySizedBox(
                widthFactor: 0.95,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: dialSize,
                      height: dialSize,
                      child: Stack(
                        fit: StackFit.expand,
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            painter: _RecoveryArcPainter(
                              progress: value,
                              strokeWidth: strokeWidth,
                              baseColor: baseColor,
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.all(innerPadding),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '${percentage.round()}%',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: percentFont,
                                    fontWeight: FontWeight.w600,
                                    color: baseColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              muscleName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                              ),
                            ),
                            if (eta != null && eta.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                eta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: baseColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2,
                                ),
                              ),
                            ],
                            if (last != null && last.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                last,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.70),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecoveryArcPainter extends CustomPainter {
  _RecoveryArcPainter({
    required this.progress,
    required this.strokeWidth,
    required this.baseColor,
  });

  final double progress;
  final double strokeWidth;
  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = size.center(Offset.zero);
    final radius = (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    // "C" shaped arc, open on the right side like the wireframe.
    const startAngle = 135 * math.pi / 180; // top-left
    const sweepAngle = 270 * math.pi / 180; // around to bottom-left

    final backgroundPaint =
        Paint()
          ..color = baseColor.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final progressPaint =
        Paint()
          ..shader = LinearGradient(
            colors: [baseColor.withValues(alpha: 0.65), baseColor],
          ).createShader(Rect.fromCircle(center: center, radius: radius))
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(arcRect, startAngle, sweepAngle, false, backgroundPaint);

    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress <= 0) return;

    canvas.drawArc(
      arcRect,
      startAngle,
      sweepAngle * clampedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RecoveryArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class _RecoverySwipeDots extends StatelessWidget {
  const _RecoverySwipeDots({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final active = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? 8 : 6,
          height: active ? 8 : 6,
          margin: EdgeInsets.only(right: index == count - 1 ? 0 : 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                active
                    ? Colors.white.withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}

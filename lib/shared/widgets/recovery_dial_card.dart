import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

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
        final padX = (constraints.maxWidth * 0.04).clamp(10.0, 18.0).toDouble();
        final padY =
            (constraints.maxHeight * 0.05).clamp(12.0, 20.0).toDouble();
        final percentFont =
            (constraints.maxHeight * 0.11).clamp(24.0, 34.0).toDouble();

        return Padding(
          padding: EdgeInsets.fromLTRB(padX, padY, padX, padY),
          child: Column(
            children: [
              Expanded(
                flex: 72,
                child: _RecoveryDialFace(
                  muscleName: muscleName,
                  percentage: clampedPercent,
                  percentFont: percentFont,
                  recoveryEtaLabel: recoveryEtaLabel,
                  lastHitLabel: lastHitLabel,
                  animationDuration: animationDuration,
                ),
              ),
              if (showIndicator) ...[
                const SizedBox(height: 14),
                _RecoverySwipeDots(
                  count: dotCount,
                  activeIndex: activeDotIndex,
                ),
              ],
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
    required this.percentFont,
    required this.recoveryEtaLabel,
    required this.lastHitLabel,
    required this.animationDuration,
  });

  final String muscleName;
  final double percentage;
  final double percentFont;
  final String? recoveryEtaLabel;
  final String? lastHitLabel;
  final Duration animationDuration;

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
            final dialWidth = constraints.maxWidth;
            final dialHeight = constraints.maxHeight;
            final strokeWidth =
                (math.min(dialWidth, dialHeight) * 0.16).clamp(10.0, 22.0);

            Color _baseColorFor(double percent) {
              if (percent >= 80) return Colors.green.shade500;
              if (percent >= 50) return Colors.amber.shade600;
              return Colors.red.shade500;
            }

            final baseColor = _baseColorFor(percentage);

            return Row(
              children: [
                Expanded(
                  flex: 11,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _RecoveryArcPainter(
                            progress: value,
                            strokeWidth: strokeWidth,
                            baseColor: baseColor,
                          ),
                        ),
                        Center(
                          child: Text(
                            '${percentage.round()}%',
                            style: TextStyle(
                              fontSize: percentFont,
                              fontWeight: FontWeight.w700,
                              color: baseColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  flex: 12,
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (recoveryEtaLabel != null &&
                          recoveryEtaLabel!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          recoveryEtaLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: baseColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (lastHitLabel != null &&
                          lastHitLabel!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          lastHitLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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

    final center = size.center(Offset.zero) + const Offset(-4, 2);
    final radius =
        (math.min(size.width, size.height) / 2) - (strokeWidth / 2);

    // "C" shaped arc, open on the right side like the wireframe.
    const startAngle = 135 * math.pi / 180; // top-left
    const sweepAngle = 270 * math.pi / 180; // around to bottom-left

    final backgroundPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          baseColor.withValues(alpha: 0.65),
          baseColor,
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
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

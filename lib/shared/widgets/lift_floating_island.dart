import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

/// Visual tokens shared with [_FloatingIslandNav] in [HomeScreen] — frosted
/// glass bar used for the shell bottom nav and top island header.
abstract final class LiftFloatingIslandTokens {
  static const double borderRadius = kIosCornerRadius;

  /// Strong enough to read as frosted glass; fill stays translucent so blur shows.
  static const double blurSigma = 18;
  static const Color frostedFill = Color(0xC8FFFFFF); // ~78% white — was ~97%

  static List<BoxShadow> get barShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.18),
      blurRadius: 30,
      spreadRadius: 2,
      offset: const Offset(0, 16),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.10),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get headerShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 22,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  /// Smaller shadow for 48×48 collapsed header orbs (scroll-collapsed chrome).
  static List<BoxShadow> get chipShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.16),
      blurRadius: 18,
      spreadRadius: 0,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Frosted “floating island” surface matching the bottom navigation bar.
class LiftFloatingIslandSurface extends StatelessWidget {
  const LiftFloatingIslandSurface({
    super.key,
    required this.child,
    this.borderRadius = LiftFloatingIslandTokens.borderRadius,
    this.boxShadow,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma,
  });

  final Widget child;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final Color? backgroundColor;
  final Color? borderColor;
  final double? blurSigma;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(borderRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: boxShadow ?? LiftFloatingIslandTokens.barShadows,
      ),
      child: ClipRRect(
        borderRadius: r,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurSigma ?? LiftFloatingIslandTokens.blurSigma,
            sigmaY: blurSigma ?? LiftFloatingIslandTokens.blurSigma,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor ?? LiftFloatingIslandTokens.frostedFill,
              borderRadius: r,
              border: Border.all(
                color: borderColor ?? Colors.black.withValues(alpha: 0.06),
                width: 1,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

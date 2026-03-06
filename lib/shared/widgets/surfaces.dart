import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(12),
    this.blur = 12,
    this.showBorder = true,
    this.showSheen = true,
  });

  final Widget child;
  final double? height;
  final double? width;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;
  final bool showBorder;
  final bool showSheen;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final glassGrey = const Color(0xFFD8DDE3);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            spreadRadius: 0.5,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            height: height,
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  glassGrey.withValues(alpha: 0.22),
                  glassGrey.withValues(alpha: 0.18),
                  glassGrey.withValues(alpha: 0.14),
                ],
              ),
              border:
                  showBorder
                      ? Border.all(
                        color: glassGrey.withValues(alpha: 0.26),
                        width: 1,
                      )
                      : null,
            ),
            child: Stack(
              children: [
                if (showSheen)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              glassGrey.withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.02),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassIsland extends StatelessWidget {
  const GlassIsland({
    super.key,
    required this.child,
    this.height = 76,
    this.borderRadius = 30,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    this.blur = 14,
  });

  final Widget child;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      height: height,
      borderRadius: borderRadius,
      blur: blur,
      showBorder: false,
      showSheen: false,
      padding: padding,
      child: child,
    );
  }
}

class SectionBoundary extends StatelessWidget {
  const SectionBoundary({
    super.key,
    required this.child,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.all(8),
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            spreadRadius: 0.5,
            offset: Offset.zero,
          ),
        ],
      ),
      child: child,
    );
  }
}

import 'dart:ui';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';

import 'package:flutter/material.dart';

class LiftMenuSheet extends StatelessWidget {
  const LiftMenuSheet({
    super.key,
    required this.children,
    this.title,
    this.subtitle,
    this.borderRadius = kIosSurfaceRadius,
    this.padding = const EdgeInsets.fromLTRB(14, 8, 14, 10),
    this.safeAreaBottomFactor = 1.0,
  });

  final String? title;
  final String? subtitle;
  final List<Widget> children;
  final double borderRadius;
  final EdgeInsets padding;
  final double safeAreaBottomFactor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final bottomInset =
        (MediaQuery.paddingOf(context).bottom * safeAreaBottomFactor) +
        MediaQuery.viewInsetsOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 34,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
          child: Container(
            width: double.infinity,
            padding: padding.add(EdgeInsets.only(bottom: bottomInset)),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF1F2F5).withValues(alpha: 0.78),
                  const Color(0xFFE7E9EE).withValues(alpha: 0.70),
                  const Color(0xFFF3F4F7).withValues(alpha: 0.84),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.09),
                      borderRadius: kIosChipBorderRadius,
                    ),
                  ),
                ),
                if (title != null || subtitle != null) ...[
                  const SizedBox(height: 8),
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.4,
                        color: Color(0xFF161616),
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF74808E),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 6),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LiftMenuActionTile extends StatelessWidget {
  const LiftMenuActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.accent = kAccentColor,
    this.showChevron = true,
  });

  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: kIosControlBorderRadius,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(6, 6, 2, 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.10),
                  borderRadius: kIosChipBorderRadius,
                  border: Border.all(color: accent.withValues(alpha: 0.20)),
                ),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.center,
                    child: IconTheme(
                      data: IconThemeData(color: accent, size: 22),
                      child: icon,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171717),
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF7A8693),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Colors.black.withValues(alpha: 0.16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LiftMenuHeaderIconButton extends StatelessWidget {
  const LiftMenuHeaderIconButton({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(width: 48, height: 48, child: Center(child: child)),
      ),
    );
  }
}

class LiftSimulatedMachineScanOverlay extends StatelessWidget {
  const LiftSimulatedMachineScanOverlay({
    super.key,
    required this.machineLabel,
  });

  final String machineLabel;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.06),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: kAccentColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: MynauiIcon(
                      MynauiGlyphs.qrCode,
                      size: 32,
                      color: kAccentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Scanning machine',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  machineLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    minHeight: 6,
                    color: kAccentColor,
                    backgroundColor: Color(0xFFE3E7EC),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Matching this station to your exercise library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: Colors.black.withValues(alpha: 0.58),
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

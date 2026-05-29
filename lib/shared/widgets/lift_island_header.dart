import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

class LiftIslandHeader extends StatelessWidget {
  const LiftIslandHeader({
    super.key,
    this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.center,
  });

  final String? title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    final centerWidget =
        center ??
        (title != null
            ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.76),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            )
            : Container(
              width: 52,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ));

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAccentDark.withValues(alpha: 0.96),
            kAccentMid.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: leading ?? const SizedBox.shrink(),
          ),
          Expanded(child: Center(child: centerWidget)),
          SizedBox(
            width: 44,
            height: 44,
            child: trailing ?? const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class LiftIslandHeaderAction extends StatelessWidget {
  const LiftIslandHeaderAction({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            color: Colors.white.withValues(alpha: 0.08),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class LiftIslandHeaderIconAction extends StatelessWidget {
  const LiftIslandHeaderIconAction({
    super.key,
    required this.icon,
    this.onTap,
    this.iconSize = 28,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LiftIslandHeaderAction(
      onTap: onTap,
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

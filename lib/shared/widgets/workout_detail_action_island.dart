import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/widgets/lift_floating_island.dart';
import 'package:lift/shared/widgets/lift_pressable.dart';

class WorkoutDetailActionIsland extends StatelessWidget {
  WorkoutDetailActionIsland({
    super.key,
    this.onSecondaryTap,
    required this.onPrimaryTap,
    this.showSecondary = true,
    this.primaryLabel,
    this.primaryIcon,
    this.primaryChild,
    this.primaryLeading,
    this.secondaryIcon = Icons.insights_rounded,
    this.secondaryChild,
    this.primaryWidth = 148,
    this.middleIcon,
    this.onMiddleTap,
    this.middle,
    this.primaryReplacement,
    this.height,
  }) : assert(
         primaryReplacement != null ||
             primaryChild != null ||
             primaryIcon != null ||
             (primaryLabel != null && primaryLabel.isNotEmpty),
       ),
       assert(
         primaryLeading == null ||
             (primaryLabel != null && primaryLabel.isNotEmpty),
       );

  final VoidCallback? onSecondaryTap;
  final VoidCallback onPrimaryTap;
  final bool showSecondary;

  /// Shown in the primary pill when [primaryIcon] is null.
  final String? primaryLabel;

  /// Optional leading widget (e.g. [MynauiIcon]) before [primaryLabel].
  final Widget? primaryLeading;

  /// When set, the primary control is an icon (e.g. check) instead of [primaryLabel].
  final IconData? primaryIcon;

  /// When set (e.g. SVG asset icon), replaces [primaryLabel] and [primaryIcon].
  final Widget? primaryChild;
  final IconData secondaryIcon;

  /// When set (e.g. Mynaui home), replaces [secondaryIcon] for the leading control.
  final Widget? secondaryChild;
  final double primaryWidth;

  /// Optional center control (e.g. delete) between secondary and primary.
  final IconData? middleIcon;
  final VoidCallback? onMiddleTap;

  /// When set, replaces [middleIcon] / [onMiddleTap] (e.g. drag target + custom styling).
  final Widget? middle;

  /// When set, replaces the primary pill (e.g. read-only hint text).
  final Widget? primaryReplacement;

  /// Defaults to [kLiftIslandHeaderHeight] when null (e.g. taller for multi-line hints).
  final double? height;

  static const Color _background = Color(0xEAF7F7F7);
  static const Color _border = Color(0x12000000);
  static const Color _highlight = Color(0xFF111111);
  static const double _radius = 30.0;
  static const double _iconButtonWidth = 44.0;
  static const double _iconButtonHeight = 40.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? kLiftIslandHeaderHeight,
      child: LiftFloatingIslandSurface(
        borderRadius: _radius,
        backgroundColor: _background,
        borderColor: _border,
        blurSigma: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showSecondary)
                _IslandIconButton(
                  onTap: onSecondaryTap,
                  icon: secondaryChild == null ? secondaryIcon : null,
                  child: secondaryChild,
                ),
              if (!showSecondary)
                const SizedBox(
                  width: _iconButtonWidth,
                  height: _iconButtonHeight,
                ),
              // Do not put a [Spacer] before [primaryReplacement]: it would share
              // width 50/50 with [Expanded] and truncate multi-line hint text.
              if (primaryReplacement != null)
                Expanded(child: primaryReplacement!)
              else ...[
                const Spacer(),
                if (middle != null) ...[
                  middle!,
                  const Spacer(),
                ] else if (middleIcon != null && onMiddleTap != null) ...[
                  _IslandIconButton(onTap: onMiddleTap!, icon: middleIcon!),
                  const Spacer(),
                ],
                _IslandPrimaryButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  leading: primaryLeading,
                  width: primaryWidth,
                  onTap: onPrimaryTap,
                  child: primaryChild,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IslandIconButton extends StatelessWidget {
  const _IslandIconButton({required this.onTap, this.icon, this.child})
    : assert(child != null || icon != null);

  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? child;

  static final Color _iconColor = Colors.black.withValues(alpha: 0.74);

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor =
        enabled ? _iconColor : Colors.black.withValues(alpha: 0.22);
    return LiftPressable(
      onTap: onTap,
      borderRadius: kIosControlRadius,
      pressedScale: LiftMotion.gentlePressScale,
      child: SizedBox(
        width: WorkoutDetailActionIsland._iconButtonWidth,
        height: WorkoutDetailActionIsland._iconButtonHeight,
        child: Center(
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: child ?? Icon(icon!, size: 23, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _IslandPrimaryButton extends StatelessWidget {
  _IslandPrimaryButton({
    this.label,
    this.icon,
    this.leading,
    required this.width,
    required this.onTap,
    this.child,
  }) : assert(
         child != null || icon != null || (label != null && label.isNotEmpty),
       ),
       assert(leading == null || (label != null && label.isNotEmpty));

  final String? label;
  final IconData? icon;
  final Widget? leading;
  final double width;
  final VoidCallback onTap;
  final Widget? child;

  static TextStyle _labelStyle() => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.1,
    color: Colors.white.withValues(alpha: 0.96),
  );

  @override
  Widget build(BuildContext context) {
    return LiftPressable(
      onTap: onTap,
      borderRadius: kIosControlRadius,
      child: Ink(
        width: width,
        height: 40,
        decoration: BoxDecoration(
          color: WorkoutDetailActionIsland._highlight,
          borderRadius: BorderRadius.circular(kIosControlRadius),
        ),
        child: Center(
          child:
              child ??
              (leading != null && label != null && label!.isNotEmpty
                  ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      leading!,
                      const SizedBox(width: 6),
                      Text(label!, style: _labelStyle()),
                    ],
                  )
                  : icon != null
                  ? Icon(
                    icon,
                    size: 22,
                    color: Colors.white.withValues(alpha: 0.96),
                  )
                  : Text(label!, style: _labelStyle())),
        ),
      ),
    );
  }
}

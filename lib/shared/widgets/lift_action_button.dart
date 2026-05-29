import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/shared/widgets/lift_pressable.dart';

class LiftActionButton extends StatelessWidget {
  const LiftActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kAccentColor,
    this.height = 44,
    this.borderRadius = kIosControlRadius,
    this.fontSize,
    this.solid = false,
    this.leadingAssetPath,
    this.leadingSize = 18,
  });

  final String label;
  final VoidCallback onTap;
  final Color color;
  final double height;
  final double borderRadius;
  final double? fontSize;

  /// Filled background using [color]; label contrasts via luminance when true.
  final bool solid;

  /// Optional SVG from [MynauiGlyphs] paths; tinted to match label color.
  final String? leadingAssetPath;
  final double leadingSize;

  Widget _buildLabelContent({
    required Color labelColor,
    required FontWeight fontWeight,
  }) {
    final style = TextStyle(
      color: labelColor,
      fontSize: fontSize ?? 16,
      fontWeight: fontWeight,
    );
    if (leadingAssetPath == null) {
      return Center(child: Text(label, style: style));
    }
    if (label.isEmpty) {
      return Center(
        child: MynauiIcon(
          leadingAssetPath!,
          size: leadingSize,
          color: labelColor,
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MynauiIcon(
                leadingAssetPath!,
                size: leadingSize,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Text(label, style: style),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (solid) {
      final labelColor =
          color.computeLuminance() > 0.5
              ? const Color(0xFF171717)
              : Colors.white;
      return LiftPressable(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _buildLabelContent(
            labelColor: labelColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return LiftPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _buildLabelContent(
          labelColor: color,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class LiftActionIconButton extends StatelessWidget {
  const LiftActionIconButton({
    super.key,
    this.icon,
    this.assetPath,
    required this.onTap,
    this.color = kAccentColor,
    this.size = 56,
    this.iconSize = 28,
    this.borderRadius = kIosControlRadius,
  }) : assert(icon != null || assetPath != null, 'Provide icon or assetPath');

  final IconData? icon;
  final String? assetPath;
  final VoidCallback onTap;
  final Color color;
  final double size;
  final double iconSize;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LiftPressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: Ink(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.06),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.30)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            assetPath != null
                ? Center(
                  child: MynauiIcon(assetPath!, size: iconSize, color: color),
                )
                : Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}

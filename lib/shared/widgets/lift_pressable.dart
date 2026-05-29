import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

class LiftPressable extends StatefulWidget {
  const LiftPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.borderRadius = kIosControlRadius,
    this.pressedScale = LiftMotion.pressScale,
    this.duration = LiftMotion.pressDuration,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double borderRadius;
  final double pressedScale;
  final Duration duration;

  @override
  State<LiftPressable> createState() => _LiftPressableState();
}

class _LiftPressableState extends State<LiftPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return AnimatedScale(
      duration: widget.duration,
      curve: LiftMotion.pressCurve,
      scale: enabled && _pressed ? widget.pressedScale : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          onHighlightChanged: _setPressed,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

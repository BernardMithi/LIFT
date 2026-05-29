import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/widgets/lift_action_button.dart';

class LiftDialogShell extends StatelessWidget {
  const LiftDialogShell({
    super.key,
    required this.child,
    this.maxWidth = 440,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(kIosCornerRadius);
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: radius,
                // Match [LiftMenuSheet] frosted surface.
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
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: IgnorePointer(
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.09),
                            borderRadius: kIosChipBorderRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(padding: const EdgeInsets.only(top: 8), child: child),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> showLiftConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Cancel',
  Color cancelColor = kAccentColor,
  Color confirmColor = kAccentColor,
  String? cancelLeadingAssetPath,
  String? confirmLeadingAssetPath,
  double leadingIconSize = 18,
  String? cancelSemanticsLabel,
  String? confirmSemanticsLabel,
}) async {
  final cancelA11y =
      cancelSemanticsLabel ?? (cancelLabel.isEmpty ? 'Cancel' : cancelLabel);
  final confirmA11y =
      confirmSemanticsLabel ??
      (confirmLabel.isEmpty ? 'Confirm' : confirmLabel);
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (dialogContext) {
      return LiftDialogShell(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
                color: Color(0xFF161616),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    label: cancelA11y,
                    button: true,
                    child: LiftActionButton(
                      label: cancelLabel,
                      height: 38,
                      fontSize: 14,
                      color: cancelColor,
                      leadingAssetPath: cancelLeadingAssetPath,
                      leadingSize: leadingIconSize,
                      onTap: () => Navigator.pop(dialogContext, false),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Semantics(
                    label: confirmA11y,
                    button: true,
                    child: LiftActionButton(
                      label: confirmLabel,
                      height: 38,
                      fontSize: 14,
                      color: confirmColor,
                      solid: true,
                      leadingAssetPath: confirmLeadingAssetPath,
                      leadingSize: leadingIconSize,
                      onTap: () => Navigator.pop(dialogContext, true),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  return confirmed == true;
}

Future<T?> showLiftTextInputDialog<T>({
  required BuildContext context,
  required String title,
  required String initialValue,
  required TextInputType keyboardType,
  required T? Function(String value) parser,
  String? message,
  String? hintText,
  String? labelText,
  String? suffixText,
  String confirmLabel = 'Save',
  String cancelLabel = 'Cancel',
  Color confirmColor = kAccentColor,
}) async {
  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.34),
    builder: (dialogContext) {
      return _LiftTextInputDialog<T>(
        title: title,
        initialValue: initialValue,
        keyboardType: keyboardType,
        parser: parser,
        message: message,
        hintText: hintText,
        labelText: labelText,
        suffixText: suffixText,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        confirmColor: confirmColor,
      );
    },
  );
}

class _LiftTextInputDialog<T> extends StatefulWidget {
  const _LiftTextInputDialog({
    required this.title,
    required this.initialValue,
    required this.keyboardType,
    required this.parser,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.confirmColor,
    this.message,
    this.hintText,
    this.labelText,
    this.suffixText,
  });

  final String title;
  final String initialValue;
  final TextInputType keyboardType;
  final T? Function(String value) parser;
  final String? message;
  final String? hintText;
  final String? labelText;
  final String? suffixText;
  final String confirmLabel;
  final String cancelLabel;
  final Color confirmColor;

  @override
  State<_LiftTextInputDialog<T>> createState() =>
      _LiftTextInputDialogState<T>();
}

class _LiftTextInputDialogState<T> extends State<_LiftTextInputDialog<T>> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiftDialogShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.4,
              color: Color(0xFF161616),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 6),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            style: const TextStyle(fontSize: 14, height: 1.35),
            decoration: InputDecoration(
              hintText: widget.hintText,
              labelText: widget.labelText,
              suffixText: widget.suffixText,
              hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIosCornerRadius),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIosCornerRadius),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(kIosCornerRadius),
                borderSide: BorderSide(
                  color: widget.confirmColor,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: LiftActionButton(
                  label: widget.cancelLabel,
                  height: 38,
                  fontSize: 14,
                  onTap: () => Navigator.pop(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: LiftActionButton(
                  label: widget.confirmLabel,
                  height: 38,
                  fontSize: 14,
                  color: widget.confirmColor,
                  solid: true,
                  onTap: () {
                    final parsed = widget.parser(_controller.text.trim());
                    if (parsed == null) return;
                    Navigator.pop(context, parsed);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

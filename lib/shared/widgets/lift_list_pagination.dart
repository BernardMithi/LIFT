import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

/// Prev / page dots / Next row matching Guides explore pagination.
class LiftListPagination extends StatelessWidget {
  const LiftListPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.isChangingPage = false,
    this.onPrevious,
    this.onNext,
    this.onSelectPage,
  });

  /// 1-based page index.
  final int currentPage;

  final int totalPages;
  final bool isChangingPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<int>? onSelectPage;

  List<int> get _visiblePages {
    if (totalPages <= 5) {
      return List<int>.generate(totalPages, (index) => index + 1);
    }
    final windowStart = math.max(1, math.min(currentPage - 2, totalPages - 4));
    return List<int>.generate(5, (index) => windowStart + index);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _LiftListPaginationButton(
          label: 'Prev',
          onTap: isChangingPage ? null : onPrevious,
          icon: Icons.chevron_left_rounded,
        ),
        Expanded(
          child: Center(
            child:
                isChangingPage
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: kAccentColor,
                      ),
                    )
                    : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _visiblePages
                          .map(
                            (page) => Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 5),
                              child: _LiftListPaginationDot(
                                selected: page == currentPage,
                                onTap:
                                    onSelectPage == null
                                        ? null
                                        : () => onSelectPage!(page),
                              ),
                            ),
                          )
                          .toList(growable: false),
                    ),
          ),
        ),
        _LiftListPaginationButton(
          label: 'Next',
          onTap: isChangingPage ? null : onNext,
          icon: Icons.chevron_right_rounded,
          trailingIcon: true,
        ),
      ],
    );
  }
}

class _LiftListPaginationButton extends StatelessWidget {
  const _LiftListPaginationButton({
    required this.label,
    required this.icon,
    this.onTap,
    this.trailingIcon = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = enabled ? const Color(0xFF171717) : Colors.grey.shade400;
    return SizedBox(
      width: 84,
      child: Align(
        alignment: trailingIcon ? Alignment.centerRight : Alignment.centerLeft,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: foreground,
            overlayColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kIosCornerRadius),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children:
                trailingIcon
                    ? [
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(icon, color: foreground, size: 16),
                    ]
                    : [
                      Icon(icon, color: foreground, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
          ),
        ),
      ),
    );
  }
}

class _LiftListPaginationDot extends StatelessWidget {
  const _LiftListPaginationDot({required this.selected, this.onTap});

  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? const Color(0xFF171717) : Colors.transparent,
            border: Border.all(
              color: selected ? const Color(0xFF171717) : Colors.grey.shade300,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }
}

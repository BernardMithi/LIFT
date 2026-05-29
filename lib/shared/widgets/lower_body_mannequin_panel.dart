import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';

const String _kRecoveryMannequinBasePath = 'assets/images/recovery/mannequins';

enum LowerBodyMannequinBodyType { male, female }

enum LowerBodyRegion { quads, hamstrings, glutes, calves }

enum LowerBodyHighlightState { recovered, mid, fatigued }

enum _LowerBodyView { front, back }

enum _LowerBodyMuscleRegion {
  leftQuadricepsFemoris,
  rightQuadricepsFemoris,
  leftTibialisAnterior,
  rightTibialisAnterior,
  leftGluteusMaximus,
  rightGluteusMaximus,
  leftHamstrings,
  rightHamstrings,
  leftGastrocnemius,
  rightGastrocnemius,
}

Set<LowerBodyRegion> lowerBodyRegionsForLabels(Iterable<String> labels) {
  final regions = <LowerBodyRegion>{};
  for (final rawLabel in labels) {
    final label = rawLabel.toLowerCase();
    if (label.contains('quad')) {
      regions.add(LowerBodyRegion.quads);
    }
    if (label.contains('ham')) {
      regions.add(LowerBodyRegion.hamstrings);
    }
    if (label.contains('glute')) {
      regions.add(LowerBodyRegion.glutes);
    }
    if (label.contains('calf') || label.contains('calves')) {
      regions.add(LowerBodyRegion.calves);
    }
  }
  return regions;
}

class LowerBodyMannequinPanel extends StatefulWidget {
  const LowerBodyMannequinPanel({
    super.key,
    required this.highlightedRegions,
    this.bodyType = LowerBodyMannequinBodyType.female,
    this.highlightColor = const Color(0xFF171717),
    this.regionStates = const <LowerBodyRegion, LowerBodyHighlightState>{},
    this.pulsateHighlights = false,
  });

  final Set<LowerBodyRegion> highlightedRegions;
  final LowerBodyMannequinBodyType bodyType;
  final Color highlightColor;
  final Map<LowerBodyRegion, LowerBodyHighlightState> regionStates;
  final bool pulsateHighlights;

  @override
  State<LowerBodyMannequinPanel> createState() =>
      _LowerBodyMannequinPanelState();
}

class _LowerBodyMannequinPanelState extends State<LowerBodyMannequinPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
    if (widget.pulsateHighlights) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant LowerBodyMannequinPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsateHighlights == widget.pulsateHighlights) {
      return;
    }
    if (widget.pulsateHighlights) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        return Row(
          children: [
            Expanded(
              child: _LowerBodyMannequinFigure(
                title: 'Front',
                bodyType: widget.bodyType,
                view: _LowerBodyView.front,
                highlightedRegions: widget.highlightedRegions,
                highlightColor: widget.highlightColor,
                regionStates: widget.regionStates,
                pulse: widget.pulsateHighlights ? _pulse.value : 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LowerBodyMannequinFigure(
                title: 'Back',
                bodyType: widget.bodyType,
                view: _LowerBodyView.back,
                highlightedRegions: widget.highlightedRegions,
                highlightColor: widget.highlightColor,
                regionStates: widget.regionStates,
                pulse: widget.pulsateHighlights ? _pulse.value : 0,
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _lowerBodyStateColor(
  LowerBodyHighlightState state, {
  Color fallback = const Color(0xFF171717),
}) {
  switch (state) {
    case LowerBodyHighlightState.recovered:
      return Colors.green.shade500;
    case LowerBodyHighlightState.mid:
      return kRecoveryMidColor;
    case LowerBodyHighlightState.fatigued:
      return Colors.red.shade500;
  }
}

double _lowerBodyStatePriority(LowerBodyHighlightState state) {
  switch (state) {
    case LowerBodyHighlightState.recovered:
      return 0;
    case LowerBodyHighlightState.mid:
      return 1;
    case LowerBodyHighlightState.fatigued:
      return 2;
  }
}

Color _lowerBodyFillColor(
  LowerBodyHighlightState state, {
  required bool emphasized,
  required double pulse,
  Color fallback = const Color(0xFF171717),
}) {
  final base = _lowerBodyStateColor(state, fallback: fallback);
  final pulseBoost = emphasized ? lerpDouble(0.62, 1.42, pulse)! : 1.0;
  final alpha = switch (state) {
    LowerBodyHighlightState.recovered => emphasized ? 0.36 : 0.14,
    LowerBodyHighlightState.mid => emphasized ? 0.56 : 0.40,
    LowerBodyHighlightState.fatigued => emphasized ? 0.68 : 0.52,
  };
  final maxAlpha = switch (state) {
    LowerBodyHighlightState.recovered => emphasized ? 0.48 : 0.24,
    LowerBodyHighlightState.mid => emphasized ? 0.64 : 0.50,
    LowerBodyHighlightState.fatigued => emphasized ? 0.74 : 0.60,
  };
  return base.withValues(
    alpha: (alpha * pulseBoost).clamp(0, maxAlpha).toDouble(),
  );
}

Color _lowerBodyOutlineColor(
  LowerBodyHighlightState state, {
  required bool emphasized,
  required double pulse,
  Color fallback = const Color(0xFF171717),
}) {
  final base = _lowerBodyStateColor(state, fallback: fallback);
  final alpha = switch (state) {
    LowerBodyHighlightState.recovered => emphasized ? 0.88 : 0.34,
    LowerBodyHighlightState.mid => emphasized ? 0.94 : 0.44,
    LowerBodyHighlightState.fatigued => emphasized ? 0.98 : 0.56,
  };
  final extra = emphasized ? (0.08 * pulse) : 0;
  return base.withValues(alpha: (alpha + extra).clamp(0, 1).toDouble());
}

class _LowerBodyMannequinFigure extends StatelessWidget {
  const _LowerBodyMannequinFigure({
    required this.title,
    required this.bodyType,
    required this.view,
    required this.highlightedRegions,
    required this.highlightColor,
    required this.regionStates,
    required this.pulse,
  });

  final String title;
  final LowerBodyMannequinBodyType bodyType;
  final _LowerBodyView view;
  final Set<LowerBodyRegion> highlightedRegions;
  final Color highlightColor;
  final Map<LowerBodyRegion, LowerBodyHighlightState> regionStates;
  final double pulse;

  String _mannequinAssetPath() {
    switch ((bodyType, view)) {
      case (LowerBodyMannequinBodyType.female, _LowerBodyView.front):
        return '$_kRecoveryMannequinBasePath/female_front.png';
      case (LowerBodyMannequinBodyType.female, _LowerBodyView.back):
        return '$_kRecoveryMannequinBasePath/female_back.png';
      case (LowerBodyMannequinBodyType.male, _LowerBodyView.front):
        return '$_kRecoveryMannequinBasePath/male_front.png';
      case (LowerBodyMannequinBodyType.male, _LowerBodyView.back):
        return '$_kRecoveryMannequinBasePath/male_back.png';
    }
  }

  Widget _fallbackPart({
    required double leftFactor,
    required double topFactor,
    required double widthFactor,
    required double heightFactor,
    required double radius,
    required Color color,
  }) {
    return Positioned.fill(
      child: FractionallySizedBox(
        alignment: Alignment(
          (leftFactor + (widthFactor / 2)) * 2 - 1,
          (topFactor + (heightFactor / 2)) * 2 - 1,
        ),
        widthFactor: widthFactor,
        heightFactor: heightFactor,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      ),
    );
  }

  List<Widget> _fallbackBaseParts(Color baseColor) {
    return [
      _fallbackPart(
        leftFactor: 0.43,
        topFactor: 0.06,
        widthFactor: 0.14,
        heightFactor: 0.09,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.40,
        topFactor: 0.15,
        widthFactor: 0.20,
        heightFactor: 0.26,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.22,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.66,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.35,
        topFactor: 0.41,
        widthFactor: 0.30,
        heightFactor: 0.11,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.39,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.51,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.39,
        topFactor: 0.83,
        widthFactor: 0.10,
        heightFactor: 0.14,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _fallbackPart(
        leftFactor: 0.51,
        topFactor: 0.83,
        widthFactor: 0.10,
        heightFactor: 0.14,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.withValues(alpha: 0.18);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kIosControlRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        color: const Color(0xFFF7F7F8),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 150,
                  maxHeight: 296,
                ),
                child: AspectRatio(
                  aspectRatio: 0.58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          _mannequinAssetPath(),
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (context, error, stackTrace) {
                            return Stack(
                              fit: StackFit.expand,
                              children: _fallbackBaseParts(baseColor),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _LowerBodyMannequinOverlayPainter(
                            highlightedRegions: highlightedRegions,
                            highlightColor: highlightColor,
                            regionStates: regionStates,
                            bodyType: bodyType,
                            view: view,
                            pulse: pulse,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowerBodyMannequinOverlayPainter extends CustomPainter {
  const _LowerBodyMannequinOverlayPainter({
    required this.highlightedRegions,
    required this.highlightColor,
    required this.regionStates,
    required this.bodyType,
    required this.view,
    required this.pulse,
  });

  final Set<LowerBodyRegion> highlightedRegions;
  final Color highlightColor;
  final Map<LowerBodyRegion, LowerBodyHighlightState> regionStates;
  final LowerBodyMannequinBodyType bodyType;
  final _LowerBodyView view;
  final double pulse;

  Size _sourceImageSize() {
    switch (bodyType) {
      case LowerBodyMannequinBodyType.female:
        return const Size(1094, 2407);
      case LowerBodyMannequinBodyType.male:
        return const Size(1215, 2447);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final musclePaths = _lowerBodyMuscleRegionPaths.getPaths(bodyType, view);
    if (musclePaths.isEmpty || size.isEmpty) return;

    final mapping =
        view == _LowerBodyView.front
            ? _frontLowerBodyRegionMap
            : _backLowerBodyRegionMap;

    final outputRect = Offset.zero & size;
    final fitted = applyBoxFit(BoxFit.contain, _sourceImageSize(), size);
    final destinationRect = Alignment.topCenter.inscribe(
      fitted.destination,
      outputRect,
    );

    if (destinationRect.isEmpty) return;

    final scaleMatrix = Float64List.fromList([
      destinationRect.width / _LowerBodyMuscleRegionPaths.designWidth,
      0,
      0,
      0,
      0,
      destinationRect.height / _LowerBodyMuscleRegionPaths.designHeight,
      0,
      0,
      0,
      0,
      1,
      0,
      destinationRect.left,
      destinationRect.top,
      0,
      1,
    ]);

    final fillPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..isAntiAlias = true;
    final outlinePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = true;
    final glowPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true;

    final orderedEntries = mapping.entries.toList(growable: false)..sort((
      a,
      b,
    ) {
      final aState = regionStates[a.value] ?? LowerBodyHighlightState.recovered;
      final bState = regionStates[b.value] ?? LowerBodyHighlightState.recovered;
      return _lowerBodyStatePriority(
        aState,
      ).compareTo(_lowerBodyStatePriority(bState));
    });

    canvas.save();
    canvas.clipRect(destinationRect);
    for (final entry in orderedEntries) {
      final rawPath = musclePaths[entry.key];
      if (rawPath == null || !highlightedRegions.contains(entry.value)) {
        continue;
      }
      final state = regionStates[entry.value] ?? LowerBodyHighlightState.mid;
      final pulseT = Curves.easeInOut.transform(pulse);
      final scaledPath = rawPath.transform(scaleMatrix);
      var animatedPath = scaledPath;

      final bounds = scaledPath.getBounds();
      if (bounds.isFinite && !bounds.isEmpty) {
        final scale = 1 + (0.038 * pulseT);
        final tx = bounds.center.dx - (bounds.center.dx * scale);
        final ty = bounds.center.dy - (bounds.center.dy * scale);
        animatedPath = scaledPath.transform(
          Float64List.fromList([
            scale,
            0,
            0,
            0,
            0,
            scale,
            0,
            0,
            0,
            0,
            1,
            0,
            tx,
            ty,
            0,
            1,
          ]),
        );
      }

      glowPaint
        ..strokeWidth = 2.2 + (2.4 * pulseT)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0 + (4.2 * pulseT))
        ..color = _lowerBodyStateColor(
          state,
          fallback: highlightColor,
        ).withValues(alpha: 0.20 + (0.28 * pulseT));
      fillPaint.color = _lowerBodyFillColor(
        state,
        emphasized: true,
        pulse: pulseT,
        fallback: highlightColor,
      );
      outlinePaint
        ..strokeWidth = 1.2 + (1.4 * pulseT)
        ..color = _lowerBodyOutlineColor(
          state,
          emphasized: true,
          pulse: pulseT,
          fallback: highlightColor,
        );
      canvas.drawPath(animatedPath, glowPaint);
      canvas.drawPath(animatedPath, fillPaint);
      canvas.drawPath(animatedPath, outlinePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LowerBodyMannequinOverlayPainter oldDelegate) {
    return !setEquals(oldDelegate.highlightedRegions, highlightedRegions) ||
        oldDelegate.highlightColor != highlightColor ||
        !mapEquals(oldDelegate.regionStates, regionStates) ||
        oldDelegate.bodyType != bodyType ||
        oldDelegate.view != view ||
        oldDelegate.pulse != pulse;
  }
}

class _LowerBodyMuscleRegionPaths {
  _LowerBodyMuscleRegionPaths() {
    _initializeFemaleFrontPaths();
    _initializeFemaleBackPaths();
    _initializeMaleFrontPaths();
    _initializeMaleBackPaths();
  }

  static const double designWidth = 930;
  static const double designHeight = 1300;

  final Map<String, Map<_LowerBodyMuscleRegion, Path>> _paths = {};

  String _getKey(LowerBodyMannequinBodyType bodyType, _LowerBodyView view) =>
      '${bodyType.name}_${view.name}';

  Map<_LowerBodyMuscleRegion, Path> getPaths(
    LowerBodyMannequinBodyType bodyType,
    _LowerBodyView view,
  ) {
    return _paths[_getKey(bodyType, view)] ??
        const <_LowerBodyMuscleRegion, Path>{};
  }

  Path _roundedRect({
    required double left,
    required double top,
    required double width,
    required double height,
    double radius = kIosCornerRadius,
  }) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, width, height),
        Radius.circular(radius),
      ),
    );
  }

  Path _ellipse({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return Path()..addOval(Rect.fromLTWH(left, top, width, height));
  }

  Map<_LowerBodyMuscleRegion, Path> _cloneMap(
    Map<_LowerBodyMuscleRegion, Path> source,
  ) {
    return source.map(
      (region, path) =>
          MapEntry<_LowerBodyMuscleRegion, Path>(region, Path.from(path)),
    );
  }

  void _initializeFemaleFrontPaths() {
    final key = _getKey(
      LowerBodyMannequinBodyType.female,
      _LowerBodyView.front,
    );
    _paths[key] = <_LowerBodyMuscleRegion, Path>{
      _LowerBodyMuscleRegion.leftQuadricepsFemoris: _roundedRect(
        left: 316,
        top: 650,
        width: 82,
        height: 190,
      ),
      _LowerBodyMuscleRegion.rightQuadricepsFemoris: _roundedRect(
        left: 532,
        top: 650,
        width: 82,
        height: 190,
      ),
      _LowerBodyMuscleRegion.leftTibialisAnterior: _roundedRect(
        left: 314,
        top: 950,
        width: 60,
        height: 230,
      ),
      _LowerBodyMuscleRegion.rightTibialisAnterior: _roundedRect(
        left: 556,
        top: 950,
        width: 60,
        height: 230,
      ),
    };
  }

  void _initializeFemaleBackPaths() {
    final key = _getKey(LowerBodyMannequinBodyType.female, _LowerBodyView.back);
    _paths[key] = <_LowerBodyMuscleRegion, Path>{
      _LowerBodyMuscleRegion.leftGluteusMaximus: _ellipse(
        left: 318,
        top: 560,
        width: 118,
        height: 126,
      ),
      _LowerBodyMuscleRegion.rightGluteusMaximus: _ellipse(
        left: 494,
        top: 560,
        width: 118,
        height: 126,
      ),
      _LowerBodyMuscleRegion.leftHamstrings: _roundedRect(
        left: 312,
        top: 724,
        width: 78,
        height: 172,
      ),
      _LowerBodyMuscleRegion.rightHamstrings: _roundedRect(
        left: 540,
        top: 724,
        width: 78,
        height: 172,
      ),
      _LowerBodyMuscleRegion.leftGastrocnemius: _roundedRect(
        left: 314,
        top: 955,
        width: 60,
        height: 196,
      ),
      _LowerBodyMuscleRegion.rightGastrocnemius: _roundedRect(
        left: 556,
        top: 955,
        width: 60,
        height: 196,
      ),
    };
  }

  void _initializeMaleFrontPaths() {
    final key = _getKey(LowerBodyMannequinBodyType.male, _LowerBodyView.front);
    final base = getPaths(
      LowerBodyMannequinBodyType.female,
      _LowerBodyView.front,
    );
    _paths[key] = _cloneMap(base);
  }

  void _initializeMaleBackPaths() {
    final key = _getKey(LowerBodyMannequinBodyType.male, _LowerBodyView.back);
    final base = getPaths(
      LowerBodyMannequinBodyType.female,
      _LowerBodyView.back,
    );
    _paths[key] = _cloneMap(base);
  }
}

const Map<_LowerBodyMuscleRegion, LowerBodyRegion> _frontLowerBodyRegionMap = {
  _LowerBodyMuscleRegion.leftQuadricepsFemoris: LowerBodyRegion.quads,
  _LowerBodyMuscleRegion.rightQuadricepsFemoris: LowerBodyRegion.quads,
  _LowerBodyMuscleRegion.leftTibialisAnterior: LowerBodyRegion.calves,
  _LowerBodyMuscleRegion.rightTibialisAnterior: LowerBodyRegion.calves,
};

const Map<_LowerBodyMuscleRegion, LowerBodyRegion> _backLowerBodyRegionMap = {
  _LowerBodyMuscleRegion.leftGluteusMaximus: LowerBodyRegion.glutes,
  _LowerBodyMuscleRegion.rightGluteusMaximus: LowerBodyRegion.glutes,
  _LowerBodyMuscleRegion.leftHamstrings: LowerBodyRegion.hamstrings,
  _LowerBodyMuscleRegion.rightHamstrings: LowerBodyRegion.hamstrings,
  _LowerBodyMuscleRegion.leftGastrocnemius: LowerBodyRegion.calves,
  _LowerBodyMuscleRegion.rightGastrocnemius: LowerBodyRegion.calves,
};

final _LowerBodyMuscleRegionPaths _lowerBodyMuscleRegionPaths =
    _LowerBodyMuscleRegionPaths();

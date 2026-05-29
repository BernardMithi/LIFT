import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/widgets/lower_body_mannequin_panel.dart'
    show LowerBodyMannequinBodyType;

const String _kWorkoutTargetMannequinBasePath =
    'assets/images/recovery/mannequins';

enum WorkoutTargetRegion {
  shoulders,
  chest,
  abs,
  back,
  lats,
  biceps,
  triceps,
  forearms,
  glutes,
  quads,
  hamstrings,
  calves,
}

enum WorkoutTargetHighlightState { recovered, mid, fatigued }

enum _WorkoutTargetView { front, back }

enum _WorkoutTargetMuscleRegion {
  leftDeltoid,
  rightDeltoid,
  leftPectoralisMajor,
  rightPectoralisMajor,
  leftBicepsBrachii,
  rightBicepsBrachii,
  leftForearmAnterior,
  rightForearmAnterior,
  rectusAbdominis,
  leftExternalOblique,
  rightExternalOblique,
  leftQuadricepsFemoris,
  rightQuadricepsFemoris,
  leftTibialisAnterior,
  rightTibialisAnterior,
  leftUpperTrapezius,
  rightUpperTrapezius,
  leftLatissimusDorsi,
  rightLatissimusDorsi,
  leftTricepsBrachii,
  rightTricepsBrachii,
  leftForearmPosterior,
  rightForearmPosterior,
  leftGluteusMaximus,
  rightGluteusMaximus,
  leftHamstrings,
  rightHamstrings,
  leftGastrocnemius,
  rightGastrocnemius,
  erectorsSpinae,
}

Set<WorkoutTargetRegion> workoutTargetRegionsForLabels(
  Iterable<String> labels,
) {
  final regions = <WorkoutTargetRegion>{};
  for (final rawLabel in labels) {
    final label = rawLabel.toLowerCase();
    if (label.contains('quad')) {
      regions.add(WorkoutTargetRegion.quads);
    }
    if (label.contains('ham')) {
      regions.add(WorkoutTargetRegion.hamstrings);
    }
    if (label.contains('glute')) {
      regions.add(WorkoutTargetRegion.glutes);
    }
    if (label.contains('chest')) {
      regions.add(WorkoutTargetRegion.chest);
    }
    if (label.contains('shoulder')) {
      regions.add(WorkoutTargetRegion.shoulders);
    }
    if (label.contains('back')) {
      regions
        ..add(WorkoutTargetRegion.back)
        ..add(WorkoutTargetRegion.lats);
    }
    if (label.contains('lat')) {
      regions.add(WorkoutTargetRegion.lats);
    }
    if (label.contains('bicep')) {
      regions.add(WorkoutTargetRegion.biceps);
    }
    if (label.contains('tricep')) {
      regions.add(WorkoutTargetRegion.triceps);
    }
    if (label.contains('forearm') ||
        label.contains('wrist') ||
        label.contains('grip')) {
      regions.add(WorkoutTargetRegion.forearms);
    }
    if (label.contains('arm')) {
      regions
        ..add(WorkoutTargetRegion.biceps)
        ..add(WorkoutTargetRegion.triceps)
        ..add(WorkoutTargetRegion.forearms);
    }
    if (label.contains('core') || label.contains('ab')) {
      regions.add(WorkoutTargetRegion.abs);
    }
    if (label.contains('conditioning') || label.contains('cardio')) {
      regions
        ..add(WorkoutTargetRegion.abs)
        ..add(WorkoutTargetRegion.calves);
    }
    if (label.contains('calf') || label.contains('calves')) {
      regions.add(WorkoutTargetRegion.calves);
    }
    if (label.contains('push')) {
      regions
        ..add(WorkoutTargetRegion.chest)
        ..add(WorkoutTargetRegion.shoulders)
        ..add(WorkoutTargetRegion.triceps);
    }
    if (label.contains('pull')) {
      regions
        ..add(WorkoutTargetRegion.back)
        ..add(WorkoutTargetRegion.lats)
        ..add(WorkoutTargetRegion.biceps)
        ..add(WorkoutTargetRegion.forearms);
    }
    if (label.contains('lower')) {
      regions
        ..add(WorkoutTargetRegion.quads)
        ..add(WorkoutTargetRegion.hamstrings)
        ..add(WorkoutTargetRegion.glutes)
        ..add(WorkoutTargetRegion.calves);
    }
  }

  if (regions.isEmpty && labels.isNotEmpty) {
    regions.add(WorkoutTargetRegion.abs);
  }
  return regions;
}

class WorkoutTargetMannequinPanel extends StatefulWidget {
  const WorkoutTargetMannequinPanel({
    super.key,
    required this.highlightedRegions,
    required this.bodyType,
    this.highlightColor = const Color(0xFF171717),
    this.regionStates =
        const <WorkoutTargetRegion, WorkoutTargetHighlightState>{},
    this.pulsateHighlights = false,
    this.cardCornerRadius = kIosControlRadius,
    this.showViewLabels = true,
  });

  final Set<WorkoutTargetRegion> highlightedRegions;
  final LowerBodyMannequinBodyType bodyType;
  final Color highlightColor;
  final Map<WorkoutTargetRegion, WorkoutTargetHighlightState> regionStates;
  final bool pulsateHighlights;
  final double cardCornerRadius;
  final bool showViewLabels;

  @override
  State<WorkoutTargetMannequinPanel> createState() =>
      _WorkoutTargetMannequinPanelState();
}

class _WorkoutTargetMannequinPanelState
    extends State<WorkoutTargetMannequinPanel>
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
  void didUpdateWidget(covariant WorkoutTargetMannequinPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulsateHighlights == widget.pulsateHighlights) return;
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
              child: _WorkoutTargetFigure(
                title: 'Front',
                front: true,
                bodyType: widget.bodyType,
                highlightedRegions: widget.highlightedRegions,
                highlightColor: widget.highlightColor,
                regionStates: widget.regionStates,
                pulse: widget.pulsateHighlights ? _pulse.value : 0,
                cardCornerRadius: widget.cardCornerRadius,
                showTitle: widget.showViewLabels,
              ),
            ),
            SizedBox(width: widget.showViewLabels ? 12 : 8),
            Expanded(
              child: _WorkoutTargetFigure(
                title: 'Back',
                front: false,
                bodyType: widget.bodyType,
                highlightedRegions: widget.highlightedRegions,
                highlightColor: widget.highlightColor,
                regionStates: widget.regionStates,
                pulse: widget.pulsateHighlights ? _pulse.value : 0,
                cardCornerRadius: widget.cardCornerRadius,
                showTitle: widget.showViewLabels,
              ),
            ),
          ],
        );
      },
    );
  }
}

Color _workoutTargetStateColor(WorkoutTargetHighlightState state) {
  switch (state) {
    case WorkoutTargetHighlightState.recovered:
      return Colors.green.shade500;
    case WorkoutTargetHighlightState.mid:
      return kRecoveryMidColor;
    case WorkoutTargetHighlightState.fatigued:
      return Colors.red.shade500;
  }
}

int _workoutTargetStatePriority(WorkoutTargetHighlightState state) {
  switch (state) {
    case WorkoutTargetHighlightState.recovered:
      return 0;
    case WorkoutTargetHighlightState.mid:
      return 1;
    case WorkoutTargetHighlightState.fatigued:
      return 2;
  }
}

Color _workoutTargetFillColor(
  WorkoutTargetHighlightState state, {
  required bool emphasized,
  required double pulse,
}) {
  final base = _workoutTargetStateColor(state);
  final pulseBoost = emphasized ? lerpDouble(0.62, 1.48, pulse)! : 1.0;
  final alpha = switch (state) {
    WorkoutTargetHighlightState.recovered => emphasized ? 0.34 : 0.12,
    WorkoutTargetHighlightState.mid => emphasized ? 0.62 : 0.46,
    WorkoutTargetHighlightState.fatigued => emphasized ? 0.72 : 0.56,
  };
  final maxAlpha = switch (state) {
    WorkoutTargetHighlightState.recovered => emphasized ? 0.46 : 0.20,
    WorkoutTargetHighlightState.mid => emphasized ? 0.64 : 0.50,
    WorkoutTargetHighlightState.fatigued => emphasized ? 0.70 : 0.58,
  };
  return base.withValues(
    alpha: (alpha * pulseBoost).clamp(0, maxAlpha).toDouble(),
  );
}

Color _workoutTargetOutlineColor(
  WorkoutTargetHighlightState state, {
  required bool emphasized,
  required double pulse,
}) {
  final base = _workoutTargetStateColor(state);
  final pulseBoost = emphasized ? lerpDouble(0.55, 1.65, pulse)! : 1.0;
  final alpha = switch (state) {
    WorkoutTargetHighlightState.recovered => emphasized ? 0.56 : 0.22,
    WorkoutTargetHighlightState.mid => emphasized ? 0.68 : 0.34,
    WorkoutTargetHighlightState.fatigued => emphasized ? 0.78 : 0.42,
  };
  return base.withValues(alpha: (alpha * pulseBoost).clamp(0, 1).toDouble());
}

class _WorkoutTargetFigure extends StatelessWidget {
  const _WorkoutTargetFigure({
    required this.title,
    required this.front,
    required this.bodyType,
    required this.highlightedRegions,
    required this.highlightColor,
    required this.regionStates,
    required this.pulse,
    required this.cardCornerRadius,
    required this.showTitle,
  });

  final String title;
  final bool front;
  final LowerBodyMannequinBodyType bodyType;
  final Set<WorkoutTargetRegion> highlightedRegions;
  final Color highlightColor;
  final Map<WorkoutTargetRegion, WorkoutTargetHighlightState> regionStates;
  final double pulse;
  final double cardCornerRadius;
  final bool showTitle;

  _WorkoutTargetView get _view =>
      front ? _WorkoutTargetView.front : _WorkoutTargetView.back;

  String _mannequinAssetPath() {
    switch ((bodyType, front)) {
      case (LowerBodyMannequinBodyType.female, true):
        return '$_kWorkoutTargetMannequinBasePath/female_front.png';
      case (LowerBodyMannequinBodyType.female, false):
        return '$_kWorkoutTargetMannequinBasePath/female_back.png';
      case (LowerBodyMannequinBodyType.male, true):
        return '$_kWorkoutTargetMannequinBasePath/male_front.png';
      case (LowerBodyMannequinBodyType.male, false):
        return '$_kWorkoutTargetMannequinBasePath/male_back.png';
    }
  }

  Widget _part({
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
      _part(
        leftFactor: 0.43,
        topFactor: 0.06,
        widthFactor: 0.14,
        heightFactor: 0.09,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.40,
        topFactor: 0.15,
        widthFactor: 0.20,
        heightFactor: 0.26,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.22,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.66,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.35,
        topFactor: 0.41,
        widthFactor: 0.30,
        heightFactor: 0.11,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.39,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.51,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.39,
        topFactor: 0.83,
        widthFactor: 0.10,
        heightFactor: 0.14,
        radius: kIosCornerRadius,
        color: baseColor,
      ),
      _part(
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
      padding: EdgeInsets.fromLTRB(
        showTitle ? 10 : 6,
        showTitle ? 10 : 6,
        showTitle ? 10 : 6,
        showTitle ? 10 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(cardCornerRadius),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        color: const Color(0xFFF7F7F8),
      ),
      child: Column(
        children: [
          if (showTitle) ...[
            Text(
              title,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: showTitle ? 165 : 220,
                  maxHeight: showTitle ? 350 : 440,
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
                          painter: _WorkoutTargetOverlayPainter(
                            highlightedRegions: highlightedRegions,
                            highlightColor: highlightColor,
                            regionStates: regionStates,
                            bodyType: bodyType,
                            view: _view,
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

class _WorkoutTargetOverlayPainter extends CustomPainter {
  const _WorkoutTargetOverlayPainter({
    required this.highlightedRegions,
    required this.highlightColor,
    required this.regionStates,
    required this.bodyType,
    required this.view,
    required this.pulse,
  });

  final Set<WorkoutTargetRegion> highlightedRegions;
  final Color highlightColor;
  final Map<WorkoutTargetRegion, WorkoutTargetHighlightState> regionStates;
  final LowerBodyMannequinBodyType bodyType;
  final _WorkoutTargetView view;
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
    final musclePaths = _workoutTargetMuscleRegionPaths.getPaths(
      bodyType,
      view,
    );
    if (musclePaths.isEmpty || size.isEmpty) return;

    final mapping =
        view == _WorkoutTargetView.front
            ? _frontWorkoutTargetRegionMap
            : _backWorkoutTargetRegionMap;

    final outputRect = Offset.zero & size;
    final fitted = applyBoxFit(BoxFit.contain, _sourceImageSize(), size);
    final destinationRect = Alignment.topCenter.inscribe(
      fitted.destination,
      outputRect,
    );
    if (destinationRect.isEmpty) return;

    final scaleMatrix = Float64List.fromList([
      destinationRect.width / _WorkoutTargetMuscleRegionPaths.designWidth,
      0,
      0,
      0,
      0,
      destinationRect.height / _WorkoutTargetMuscleRegionPaths.designHeight,
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

    final orderedEntries = mapping.entries.toList(growable: false)
      ..sort((a, b) {
        final aState =
            regionStates[a.value] ?? WorkoutTargetHighlightState.recovered;
        final bState =
            regionStates[b.value] ?? WorkoutTargetHighlightState.recovered;
        return _workoutTargetStatePriority(
          aState,
        ).compareTo(_workoutTargetStatePriority(bState));
      });

    canvas.save();
    canvas.clipRect(destinationRect);
    for (final entry in orderedEntries) {
      final rawPath = musclePaths[entry.key];
      if (rawPath == null || !highlightedRegions.contains(entry.value)) {
        continue;
      }

      final state = regionStates[entry.value];
      final emphasized = state != null;
      final pulseT = emphasized ? Curves.easeInOut.transform(pulse) : 0.0;
      final scaledPath = rawPath.transform(scaleMatrix);
      var animatedPath = scaledPath;

      if (emphasized) {
        final bounds = scaledPath.getBounds();
        if (bounds.isFinite && !bounds.isEmpty) {
          final scale = 1 + (0.045 * pulseT);
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
          ..strokeWidth = 2.6 + (2.8 * pulseT)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 1.8 + (3.8 * pulseT))
          ..color = _workoutTargetStateColor(
            state,
          ).withValues(alpha: 0.22 + (0.30 * pulseT));
        canvas.drawPath(animatedPath, glowPaint);
      }

      if (state != null) {
        fillPaint.color = _workoutTargetFillColor(
          state,
          emphasized: emphasized,
          pulse: pulseT,
        );
        outlinePaint.color = _workoutTargetOutlineColor(
          state,
          emphasized: emphasized,
          pulse: pulseT,
        );
        outlinePaint.strokeWidth = emphasized ? (1.2 + (1.6 * pulseT)) : 1;
      } else {
        fillPaint.color = highlightColor.withValues(alpha: 0.18);
        outlinePaint
          ..color = highlightColor.withValues(alpha: 0.28)
          ..strokeWidth = 1;
      }

      canvas.drawPath(animatedPath, fillPaint);
      canvas.drawPath(animatedPath, outlinePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WorkoutTargetOverlayPainter oldDelegate) {
    return oldDelegate.regionStates != regionStates ||
        !setEquals(oldDelegate.highlightedRegions, highlightedRegions) ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.pulse != pulse ||
        oldDelegate.bodyType != bodyType ||
        oldDelegate.view != view;
  }
}

class _WorkoutTargetMuscleRegionPaths {
  _WorkoutTargetMuscleRegionPaths() {
    _initializeFemaleFrontPaths();
    _initializeFemaleBackPaths();
    _initializeMaleFrontPaths();
    _initializeMaleBackPaths();
  }

  static const double designWidth = 930;
  static const double designHeight = 1300;

  final Map<String, Map<_WorkoutTargetMuscleRegion, Path>> _paths = {};

  String _getKey(
    LowerBodyMannequinBodyType bodyType,
    _WorkoutTargetView view,
  ) => '${bodyType.name}_${view.name}';

  Map<_WorkoutTargetMuscleRegion, Path> getPaths(
    LowerBodyMannequinBodyType bodyType,
    _WorkoutTargetView view,
  ) {
    return _paths[_getKey(bodyType, view)] ??
        const <_WorkoutTargetMuscleRegion, Path>{};
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

  Path _rotatedRoundedRect({
    required double left,
    required double top,
    required double width,
    required double height,
    required double radius,
    required double angleRadians,
    double pivotXFactor = 0.5,
    double pivotYFactor = 0.5,
  }) {
    final path = _roundedRect(
      left: left,
      top: top,
      width: width,
      height: height,
      radius: radius,
    );
    final centerX = left + (width * pivotXFactor);
    final centerY = top + (height * pivotYFactor);
    final cosA = math.cos(angleRadians);
    final sinA = math.sin(angleRadians);
    final tx = centerX - (centerX * cosA) + (centerY * sinA);
    final ty = centerY - (centerX * sinA) - (centerY * cosA);
    return path.transform(
      Float64List.fromList([
        cosA,
        sinA,
        0,
        0,
        -sinA,
        cosA,
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

  Map<_WorkoutTargetMuscleRegion, Path> _cloneMap(
    Map<_WorkoutTargetMuscleRegion, Path> source,
  ) {
    return source.map(
      (region, path) =>
          MapEntry<_WorkoutTargetMuscleRegion, Path>(region, Path.from(path)),
    );
  }

  void _initializeFemaleFrontPaths() {
    final key = _getKey(
      LowerBodyMannequinBodyType.female,
      _WorkoutTargetView.front,
    );
    _paths[key] = {
      _WorkoutTargetMuscleRegion.leftDeltoid: _ellipse(
        left: 230,
        top: 228,
        width: 92,
        height: 86,
      ),
      _WorkoutTargetMuscleRegion.rightDeltoid: _ellipse(
        left: 608,
        top: 228,
        width: 92,
        height: 86,
      ),
      _WorkoutTargetMuscleRegion.leftPectoralisMajor: _ellipse(
        left: 317,
        top: 242,
        width: 132,
        height: 116,
      ),
      _WorkoutTargetMuscleRegion.rightPectoralisMajor: _ellipse(
        left: 483,
        top: 242,
        width: 132,
        height: 116,
      ),
      _WorkoutTargetMuscleRegion.leftBicepsBrachii: _ellipse(
        left: 190,
        top: 338,
        width: 86,
        height: 112,
      ),
      _WorkoutTargetMuscleRegion.rightBicepsBrachii: _ellipse(
        left: 654,
        top: 338,
        width: 86,
        height: 112,
      ),
      _WorkoutTargetMuscleRegion.leftForearmAnterior: _rotatedRoundedRect(
        left: 156,
        top: 456,
        width: 50,
        height: 142,
        radius: kIosCornerRadius,
        angleRadians: 0.46,
        pivotYFactor: 0.24,
      ),
      _WorkoutTargetMuscleRegion.rightForearmAnterior: _rotatedRoundedRect(
        left: 716,
        top: 456,
        width: 50,
        height: 142,
        radius: kIosCornerRadius,
        angleRadians: -0.46,
        pivotYFactor: 0.24,
      ),
      _WorkoutTargetMuscleRegion.rectusAbdominis: _roundedRect(
        left: 398,
        top: 390,
        width: 134,
        height: 184,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.leftExternalOblique: _ellipse(
        left: 326,
        top: 462,
        width: 74,
        height: 102,
      ),
      _WorkoutTargetMuscleRegion.rightExternalOblique: _ellipse(
        left: 530,
        top: 462,
        width: 74,
        height: 102,
      ),
      _WorkoutTargetMuscleRegion.leftQuadricepsFemoris: _roundedRect(
        left: 314,
        top: 646,
        width: 96,
        height: 194,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.rightQuadricepsFemoris: _roundedRect(
        left: 520,
        top: 646,
        width: 96,
        height: 194,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.leftTibialisAnterior: _roundedRect(
        left: 322,
        top: 950,
        width: 68,
        height: 230,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.rightTibialisAnterior: _roundedRect(
        left: 540,
        top: 950,
        width: 68,
        height: 230,
        radius: kIosCornerRadius,
      ),
    };
  }

  void _initializeFemaleBackPaths() {
    final key = _getKey(
      LowerBodyMannequinBodyType.female,
      _WorkoutTargetView.back,
    );
    _paths[key] = {
      _WorkoutTargetMuscleRegion.leftDeltoid: _ellipse(
        left: 230,
        top: 228,
        width: 92,
        height: 86,
      ),
      _WorkoutTargetMuscleRegion.rightDeltoid: _ellipse(
        left: 608,
        top: 228,
        width: 92,
        height: 86,
      ),
      _WorkoutTargetMuscleRegion.leftUpperTrapezius: _ellipse(
        left: 304,
        top: 202,
        width: 112,
        height: 96,
      ),
      _WorkoutTargetMuscleRegion.rightUpperTrapezius: _ellipse(
        left: 514,
        top: 202,
        width: 112,
        height: 96,
      ),
      _WorkoutTargetMuscleRegion.leftLatissimusDorsi: _roundedRect(
        left: 278,
        top: 340,
        width: 112,
        height: 184,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.rightLatissimusDorsi: _roundedRect(
        left: 540,
        top: 340,
        width: 112,
        height: 184,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.leftTricepsBrachii: _ellipse(
        left: 188,
        top: 320,
        width: 88,
        height: 108,
      ),
      _WorkoutTargetMuscleRegion.rightTricepsBrachii: _ellipse(
        left: 654,
        top: 320,
        width: 88,
        height: 108,
      ),
      _WorkoutTargetMuscleRegion.leftForearmPosterior: _rotatedRoundedRect(
        left: 156,
        top: 458,
        width: 58,
        height: 142,
        radius: kIosCornerRadius,
        angleRadians: 0.40,
        pivotYFactor: 0.24,
      ),
      _WorkoutTargetMuscleRegion.rightForearmPosterior: _rotatedRoundedRect(
        left: 716,
        top: 458,
        width: 58,
        height: 142,
        radius: kIosCornerRadius,
        angleRadians: -0.40,
        pivotYFactor: 0.24,
      ),
      _WorkoutTargetMuscleRegion.erectorsSpinae: _roundedRect(
        left: 430,
        top: 304,
        width: 70,
        height: 286,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.leftGluteusMaximus: _ellipse(
        left: 316,
        top: 554,
        width: 136,
        height: 132,
      ),
      _WorkoutTargetMuscleRegion.rightGluteusMaximus: _ellipse(
        left: 478,
        top: 554,
        width: 136,
        height: 132,
      ),
      _WorkoutTargetMuscleRegion.leftHamstrings: _roundedRect(
        left: 308,
        top: 724,
        width: 94,
        height: 170,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.rightHamstrings: _roundedRect(
        left: 528,
        top: 724,
        width: 94,
        height: 170,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.leftGastrocnemius: _roundedRect(
        left: 322,
        top: 955,
        width: 68,
        height: 196,
        radius: kIosCornerRadius,
      ),
      _WorkoutTargetMuscleRegion.rightGastrocnemius: _roundedRect(
        left: 540,
        top: 955,
        width: 68,
        height: 196,
        radius: kIosCornerRadius,
      ),
    };
  }

  void _initializeMaleFrontPaths() {
    final key = _getKey(
      LowerBodyMannequinBodyType.male,
      _WorkoutTargetView.front,
    );
    final base = getPaths(
      LowerBodyMannequinBodyType.female,
      _WorkoutTargetView.front,
    );
    _paths[key] = _cloneMap(base);
  }

  void _initializeMaleBackPaths() {
    final key = _getKey(
      LowerBodyMannequinBodyType.male,
      _WorkoutTargetView.back,
    );
    final base = getPaths(
      LowerBodyMannequinBodyType.female,
      _WorkoutTargetView.back,
    );
    _paths[key] = _cloneMap(base);
  }
}

const Map<_WorkoutTargetMuscleRegion, WorkoutTargetRegion>
_frontWorkoutTargetRegionMap = {
  _WorkoutTargetMuscleRegion.leftDeltoid: WorkoutTargetRegion.shoulders,
  _WorkoutTargetMuscleRegion.rightDeltoid: WorkoutTargetRegion.shoulders,
  _WorkoutTargetMuscleRegion.leftPectoralisMajor: WorkoutTargetRegion.chest,
  _WorkoutTargetMuscleRegion.rightPectoralisMajor: WorkoutTargetRegion.chest,
  _WorkoutTargetMuscleRegion.leftBicepsBrachii: WorkoutTargetRegion.biceps,
  _WorkoutTargetMuscleRegion.rightBicepsBrachii: WorkoutTargetRegion.biceps,
  _WorkoutTargetMuscleRegion.leftForearmAnterior: WorkoutTargetRegion.forearms,
  _WorkoutTargetMuscleRegion.rightForearmAnterior: WorkoutTargetRegion.forearms,
  _WorkoutTargetMuscleRegion.rectusAbdominis: WorkoutTargetRegion.abs,
  _WorkoutTargetMuscleRegion.leftExternalOblique: WorkoutTargetRegion.abs,
  _WorkoutTargetMuscleRegion.rightExternalOblique: WorkoutTargetRegion.abs,
  _WorkoutTargetMuscleRegion.leftQuadricepsFemoris: WorkoutTargetRegion.quads,
  _WorkoutTargetMuscleRegion.rightQuadricepsFemoris: WorkoutTargetRegion.quads,
  _WorkoutTargetMuscleRegion.leftTibialisAnterior: WorkoutTargetRegion.calves,
  _WorkoutTargetMuscleRegion.rightTibialisAnterior: WorkoutTargetRegion.calves,
};

const Map<_WorkoutTargetMuscleRegion, WorkoutTargetRegion>
_backWorkoutTargetRegionMap = {
  _WorkoutTargetMuscleRegion.leftDeltoid: WorkoutTargetRegion.shoulders,
  _WorkoutTargetMuscleRegion.rightDeltoid: WorkoutTargetRegion.shoulders,
  _WorkoutTargetMuscleRegion.leftUpperTrapezius: WorkoutTargetRegion.back,
  _WorkoutTargetMuscleRegion.rightUpperTrapezius: WorkoutTargetRegion.back,
  _WorkoutTargetMuscleRegion.erectorsSpinae: WorkoutTargetRegion.back,
  _WorkoutTargetMuscleRegion.leftLatissimusDorsi: WorkoutTargetRegion.lats,
  _WorkoutTargetMuscleRegion.rightLatissimusDorsi: WorkoutTargetRegion.lats,
  _WorkoutTargetMuscleRegion.leftTricepsBrachii: WorkoutTargetRegion.triceps,
  _WorkoutTargetMuscleRegion.rightTricepsBrachii: WorkoutTargetRegion.triceps,
  _WorkoutTargetMuscleRegion.leftForearmPosterior: WorkoutTargetRegion.forearms,
  _WorkoutTargetMuscleRegion.rightForearmPosterior:
      WorkoutTargetRegion.forearms,
  _WorkoutTargetMuscleRegion.leftGluteusMaximus: WorkoutTargetRegion.glutes,
  _WorkoutTargetMuscleRegion.rightGluteusMaximus: WorkoutTargetRegion.glutes,
  _WorkoutTargetMuscleRegion.leftHamstrings: WorkoutTargetRegion.hamstrings,
  _WorkoutTargetMuscleRegion.rightHamstrings: WorkoutTargetRegion.hamstrings,
  _WorkoutTargetMuscleRegion.leftGastrocnemius: WorkoutTargetRegion.calves,
  _WorkoutTargetMuscleRegion.rightGastrocnemius: WorkoutTargetRegion.calves,
};

final _WorkoutTargetMuscleRegionPaths _workoutTargetMuscleRegionPaths =
    _WorkoutTargetMuscleRegionPaths();

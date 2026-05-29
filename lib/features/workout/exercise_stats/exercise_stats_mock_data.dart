import 'dart:math' as math;

import 'package:lift/features/progress/leg_day_trends/leg_day_trends_models.dart';
import 'package:lift/features/workout/exercise_stats/exercise_stats_models.dart';

/// Deterministic mock series per exercise name (stable across rebuilds).
abstract final class ExerciseStatsMockData {
  static ExerciseStatsData forExercise(String exerciseName) {
    final s = exerciseName.hashCode.abs();
    final baseVol = 800 + (s % 4200).toDouble();
    final baseReps = (48 + (s % 55)).toDouble();
    final baseTop = 32 + (s % 48).toDouble();

    final rangeSnapshots = <LegDayTrendRange, LegDayRangeSnapshot>{
      LegDayTrendRange.sevenDays: _snapshot(
        LegDayTrendRange.sevenDays,
        s,
        baseVol,
        baseReps,
        baseTop,
        7,
        (i) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i],
      ),
      LegDayTrendRange.thirtyDays: _snapshot(
        LegDayTrendRange.thirtyDays,
        s + 11,
        baseVol,
        baseReps,
        baseTop,
        6,
        (i) => ['W1', 'W2', 'W3', 'W4', 'W5', 'Now'][i],
      ),
      LegDayTrendRange.ninetyDays: _snapshot(
        LegDayTrendRange.ninetyDays,
        s + 23,
        baseVol,
        baseReps,
        baseTop,
        7,
        (i) => ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Now'][i],
      ),
      LegDayTrendRange.custom: _snapshot(
        LegDayTrendRange.custom,
        s + 37,
        baseVol,
        baseReps,
        baseTop,
        6,
        (i) => ['Base', 'Build', 'Peak', 'Deload', 'Reload', 'Now'][i],
      ),
    };

    final drift = 1 + (s % 8) / 100.0;
    final sessions = 4 + (s % 18);
    final bestKg = baseTop + (s % 12);
    final bestReps = 8 + (s % 6);

    return ExerciseStatsData(
      exerciseName: exerciseName,
      subtitle:
          'How this movement has been trending — volume, reps, and heaviest set.',
      rangeSnapshots: rangeSnapshots,
      summary: ExerciseStatsSummary(
        sessionsWithExercise: sessions,
        bestRecentSet: '${bestKg.toStringAsFixed(0)} kg × $bestReps',
        lastPerformedLabel:
            drift >= 1.04 ? '2–4 days ago' : 'About a week ago',
      ),
    );
  }

  static LegDayRangeSnapshot _snapshot(
    LegDayTrendRange range,
    int seed,
    double baseVol,
    double baseReps,
    double baseTop,
    int count,
    String Function(int index) labelFor,
  ) {
    final volPoints = <TrendPoint>[];
    final repPoints = <TrendPoint>[];
    final topPoints = <TrendPoint>[];
    for (var i = 0; i < count; i++) {
      final t = i / math.max(1, count - 1);
      final wobble = 1 + 0.04 * math.sin((seed + i * 17) * 0.1);
      final ramp = 0.88 + 0.14 * t;
      volPoints.add(
        TrendPoint(
          label: labelFor(i),
          value: (baseVol * ramp * wobble).roundToDouble(),
        ),
      );
      repPoints.add(
        TrendPoint(
          label: labelFor(i),
          value: (baseReps * ramp * wobble).roundToDouble(),
        ),
      );
      topPoints.add(
        TrendPoint(
          label: labelFor(i),
          value: (baseTop * ramp * wobble).roundToDouble(),
        ),
      );
    }

    return LegDayRangeSnapshot(
      range: range,
      metricSeries: {
        LegDayTrendMetric.volume: MetricTrendSeries(
          points: volPoints,
          insight:
              'Total weight moved for this exercise is trending in this window.',
        ),
        LegDayTrendMetric.reps: MetricTrendSeries(
          points: repPoints,
          insight: 'Rep volume is holding steady with room to push quality.',
        ),
        LegDayTrendMetric.topSet: MetricTrendSeries(
          points: topPoints,
          insight:
              'Your heaviest set for this lift is moving in the right direction.',
        ),
      },
    );
  }
}

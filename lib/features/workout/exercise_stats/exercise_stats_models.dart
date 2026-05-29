import 'package:lift/features/progress/leg_day_trends/leg_day_trends_models.dart';

/// Per-exercise analytics (mock-backed until history is persisted).
class ExerciseStatsData {
  const ExerciseStatsData({
    required this.exerciseName,
    required this.subtitle,
    required this.rangeSnapshots,
    required this.summary,
  });

  final String exerciseName;
  final String subtitle;
  final Map<LegDayTrendRange, LegDayRangeSnapshot> rangeSnapshots;
  final ExerciseStatsSummary summary;

  LegDayRangeSnapshot snapshotFor(LegDayTrendRange range) {
    return rangeSnapshots[range]!;
  }
}

class ExerciseStatsSummary {
  const ExerciseStatsSummary({
    required this.sessionsWithExercise,
    required this.bestRecentSet,
    required this.lastPerformedLabel,
  });

  final int sessionsWithExercise;
  final String bestRecentSet;
  final String lastPerformedLabel;
}

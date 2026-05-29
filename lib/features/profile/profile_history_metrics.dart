import 'dart:math' as math;

import 'package:lift/features/profile/profile_models.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/services/health_sync_service.dart';

class ProfileHistoryMetrics {
  const ProfileHistoryMetrics({
    required this.stats,
    required this.trainingScore,
    required this.analytics,
    required this.activity,
    required this.highlights,
  });

  final UserProfileStats stats;
  final TrainingScore trainingScore;
  final ProfileAnalytics analytics;
  final List<ActivityEntry> activity;
  final List<HighlightSummary> highlights;
}

ProfileHistoryMetrics deriveProfileHistoryMetrics(
  List<WorkoutHistoryEntry> history, {
  HealthSyncService healthSyncService = const MockHealthSyncService(),
}) {
  final sorted = List<WorkoutHistoryEntry>.from(history)
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

  if (sorted.isEmpty) {
    return const ProfileHistoryMetrics(
      stats: UserProfileStats(workouts: 0, streak: 0, score: 0),
      trainingScore: TrainingScore(
        value: 0,
        label: 'Recover',
        consistency: 0,
        balance: 'No data yet',
        recovery: 'No history',
        insight:
            'Complete at least one workout to unlock performance insights and progress analytics.',
      ),
      analytics: ProfileAnalytics(
        volumeTrend: <TrendPoint>[],
        strengthProgression: <StrengthLiftSnapshot>[],
        muscleBalance: <MuscleBalanceDatum>[],
      ),
      activity: <ActivityEntry>[],
      highlights: <HighlightSummary>[],
    );
  }

  final connectionState = healthSyncService.connectionState();
  final recoverySnapshot = healthSyncService.latestRecoverySnapshot();
  final latest = sorted.last;
  final streak = _streakDays(sorted);
  final weeklyCompletionPercent = _weeklyCompletionPercent(sorted);
  final sessionsLastWeek = _sessionsInLastDays(sorted, 7);
  final restDaysLastWeek = (7 - sessionsLastWeek).clamp(0, 7);
  final thisWeekVolume = _weeklyVolume(sorted, 0);
  final previousWeekVolume = _weeklyVolume(sorted, 1);
  final loadDeltaPercent =
      previousWeekVolume <= 0
          ? 0.0
          : ((thisWeekVolume - previousWeekVolume) / previousWeekVolume) * 100;
  final recoveryPercent = _averageRecoveryForTrainedMuscles(
    latest,
    sorted,
    recoverySnapshot: recoverySnapshot,
  );
  final trainingScore = _trainingScore(
    sortedHistory: sorted,
    weeklyCompletionPercent: weeklyCompletionPercent,
    connectionState: connectionState,
    recoverySnapshot: recoverySnapshot,
  );
  final readinessScore =
      recoverySnapshot?.readinessScore ??
      _estimatedReadinessScore(
        weeklyCompletionPercent: weeklyCompletionPercent,
        restDaysLastWeek: restDaysLastWeek,
        loadDeltaPercent: loadDeltaPercent.abs(),
      );
  final balanceEntries = _entriesInLastDays(sorted, 42);
  final balanceSource = balanceEntries.isEmpty ? sorted : balanceEntries;
  final muscleTotals = _muscleVolumeTotals(balanceSource);
  final ratio = _pushPullRatio(muscleTotals);

  return ProfileHistoryMetrics(
    stats: UserProfileStats(
      workouts: sorted.length,
      streak: streak,
      score: trainingScore.totalScore,
    ),
    trainingScore: TrainingScore(
      value: trainingScore.totalScore,
      label: _trainingScoreLabel(trainingScore.totalScore),
      consistency: weeklyCompletionPercent,
      balance: _balanceLabel(ratio.pushRatio, ratio.pullRatio),
      recovery: _recoveryLabelForPercent(recoveryPercent, readinessScore),
      insight: _trainingInsight(
        weeklyCompletionPercent: weeklyCompletionPercent,
        pushRatio: ratio.pushRatio,
        pullRatio: ratio.pullRatio,
        recoveryPercent: recoveryPercent,
      ),
    ),
    analytics: ProfileAnalytics(
      volumeTrend: _buildVolumeTrend(sorted),
      strengthProgression: _buildStrengthProgression(sorted),
      muscleBalance: _buildMuscleBalance(balanceSource),
    ),
    activity: _buildActivity(sorted, streak: streak),
    highlights: _buildHighlights(sorted),
  );
}

DateTime _atStartOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

List<WorkoutHistoryEntry> _entriesInLastDays(
  List<WorkoutHistoryEntry> sorted,
  int days,
) {
  if (sorted.isEmpty) return const <WorkoutHistoryEntry>[];
  final today = _atStartOfDay(DateTime.now());
  final start = today.subtract(Duration(days: days - 1));
  return sorted
      .where((entry) {
        final day = _atStartOfDay(entry.completedAt);
        return !day.isBefore(start) && !day.isAfter(today);
      })
      .toList(growable: false);
}

int _streakDays(List<WorkoutHistoryEntry> sorted) {
  if (sorted.isEmpty) return 0;
  final workedDays =
      sorted.map((entry) => _atStartOfDay(entry.completedAt)).toSet();
  var day = _atStartOfDay(DateTime.now());
  if (!workedDays.contains(day)) {
    day = day.subtract(const Duration(days: 1));
  }
  var streak = 0;
  while (workedDays.contains(day)) {
    streak += 1;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

int _longestStreakDays(List<WorkoutHistoryEntry> sorted) {
  if (sorted.isEmpty) return 0;
  final workedDays = sorted
    .map((entry) => _atStartOfDay(entry.completedAt))
    .toSet()
    .toList(growable: false)..sort((a, b) => a.compareTo(b));
  var longest = 1;
  var current = 1;
  for (var index = 1; index < workedDays.length; index += 1) {
    final gap = workedDays[index].difference(workedDays[index - 1]).inDays;
    if (gap == 1) {
      current += 1;
      longest = math.max(longest, current);
    } else {
      current = 1;
    }
  }
  return longest;
}

int _weeklyCompletionPercent(List<WorkoutHistoryEntry> sorted) {
  final today = _atStartOfDay(DateTime.now());
  final start = today.subtract(const Duration(days: 6));
  var sessions = 0;
  for (final entry in sorted) {
    final day = _atStartOfDay(entry.completedAt);
    if (!day.isBefore(start) && !day.isAfter(today)) {
      sessions += 1;
    }
  }
  return ((sessions / 4) * 100).round().clamp(0, 100);
}

int _sessionsInLastDays(List<WorkoutHistoryEntry> sorted, int days) {
  if (sorted.isEmpty) return 0;
  final today = _atStartOfDay(DateTime.now());
  final start = today.subtract(Duration(days: days - 1));
  return sorted.where((entry) {
    final day = _atStartOfDay(entry.completedAt);
    return !day.isBefore(start) && !day.isAfter(today);
  }).length;
}

double _weeklyVolume(List<WorkoutHistoryEntry> sorted, int weeksAgo) {
  if (sorted.isEmpty) return 0;
  final today = _atStartOfDay(DateTime.now());
  final end = today.subtract(Duration(days: weeksAgo * 7));
  final start = end.subtract(const Duration(days: 6));
  return sorted.fold<double>(0, (sum, entry) {
    final day = _atStartOfDay(entry.completedAt);
    if (day.isBefore(start) || day.isAfter(end)) return sum;
    return sum + entry.totalVolumeKg;
  });
}

int _estimatedReadinessScore({
  required int weeklyCompletionPercent,
  required int restDaysLastWeek,
  required double loadDeltaPercent,
}) {
  final consistencyPenalty = (weeklyCompletionPercent - 75).abs() * 0.20;
  final restBonus = math.min(8, restDaysLastWeek * 3);
  final loadPenalty = math.max(0.0, loadDeltaPercent - 25) * 0.18;
  final score = 74 + restBonus - consistencyPenalty - loadPenalty;
  return score.round().clamp(25, 96);
}

Map<
  String,
  List<({DateTime completedAt, WorkoutHistoryExerciseSummary summary})>
>
_exerciseSeries(List<WorkoutHistoryEntry> entries) {
  final series =
      <
        String,
        List<({DateTime completedAt, WorkoutHistoryExerciseSummary summary})>
      >{};
  for (final entry in entries) {
    for (final summary in entry.exerciseSummaries) {
      series.putIfAbsent(
        summary.exerciseName,
        () =>
            <({DateTime completedAt, WorkoutHistoryExerciseSummary summary})>[],
      );
      series[summary.exerciseName]!.add((
        completedAt: entry.completedAt,
        summary: summary,
      ));
    }
  }
  for (final values in series.values) {
    values.sort((a, b) => a.completedAt.compareTo(b.completedAt));
  }
  return series;
}

WorkoutHistoryExerciseSummary? _findPreviousExerciseSummary(
  String exerciseName,
  List<WorkoutHistoryEntry> sortedHistory, {
  required DateTime before,
}) {
  for (var index = sortedHistory.length - 1; index >= 0; index -= 1) {
    final entry = sortedHistory[index];
    if (!entry.completedAt.isBefore(before)) continue;
    for (final summary in entry.exerciseSummaries) {
      if (summary.exerciseName == exerciseName) return summary;
    }
  }
  return null;
}

int _completionPoints(WorkoutHistoryEntry entry) {
  if (entry.totalExercises <= 0) return 0;
  final ratio = entry.exercisesCompleted / entry.totalExercises;
  if (ratio >= 0.90) return 30;
  if (ratio >= 0.70) return 20;
  return entry.exercisesCompleted > 0 ? 10 : 0;
}

int _intensityMatchPoints(
  WorkoutHistoryEntry entry,
  List<WorkoutHistoryEntry> sortedHistory,
) {
  var comparisons = 0;
  var totalDiff = 0.0;
  for (final summary in entry.exerciseSummaries) {
    final previous = _findPreviousExerciseSummary(
      summary.exerciseName,
      sortedHistory,
      before: entry.completedAt,
    );
    if (previous == null) continue;
    final baseline = math.max(1.0, previous.maxWeightKg.abs());
    final diff =
        ((summary.maxWeightKg - previous.maxWeightKg).abs()) / baseline;
    totalDiff += diff;
    comparisons += 1;
  }
  if (comparisons == 0) return 7;
  final averageDiff = totalDiff / comparisons;
  if (averageDiff <= 0.10) return 10;
  if (averageDiff <= 0.15) return 7;
  return 4;
}

int _effortConfirmationPoints(
  WorkoutHistoryEntry entry,
  HealthRecoverySnapshot? recoverySnapshot,
) {
  final targetMinutes = math.max(20, entry.totalExercises * 12);
  final ratio = entry.duration.inMinutes / targetMinutes;
  var points = 4;
  if (ratio >= 0.75 && ratio <= 1.45) {
    points = 10;
  } else if (ratio >= 0.60 && ratio <= 1.70) {
    points = 7;
  }

  if (recoverySnapshot != null) {
    final readiness = recoverySnapshot.readinessScore;
    if (readiness < 40 && ratio > 1.50) {
      points = math.max(4, points - 2);
    } else if (readiness > 80 && ratio < 0.55) {
      points = math.max(4, points - 2);
    }
  }
  return math.min(10, math.max(0, points));
}

double _averageRecoveryForTrainedMuscles(
  WorkoutHistoryEntry entry,
  List<WorkoutHistoryEntry> sortedHistory, {
  HealthRecoverySnapshot? recoverySnapshot,
}) {
  final muscles = entry.muscleGroupVolumeKg.keys
      .where((key) => key.trim().isNotEmpty)
      .toSet()
      .toList(growable: false);
  if (muscles.isEmpty) {
    return (recoverySnapshot?.readinessScore.toDouble() ?? 70)
        .clamp(0, 100)
        .toDouble();
  }

  final referenceDay = _atStartOfDay(entry.completedAt);
  var totalRecovery = 0.0;
  for (final muscle in muscles) {
    var fatigue = 0.0;
    for (final pastEntry in sortedHistory) {
      if (!pastEntry.completedAt.isBefore(entry.completedAt)) continue;
      final day = _atStartOfDay(pastEntry.completedAt);
      final daysAgo = referenceDay.difference(day).inDays;
      if (daysAgo <= 0 || daysAgo > 6) continue;
      final volume = pastEntry.muscleGroupVolumeKg[muscle] ?? 0;
      if (volume <= 0) continue;
      final decay = math.pow(0.58, daysAgo).toDouble();
      fatigue += (volume / 1400) * decay;
    }
    final recovery = (1 - fatigue.clamp(0.0, 1.0)) * 100;
    totalRecovery += recovery;
  }

  var averageRecovery = totalRecovery / muscles.length;
  if (recoverySnapshot != null) {
    averageRecovery =
        (averageRecovery * 0.72) + (recoverySnapshot.readinessScore * 0.28);
  }
  return averageRecovery.clamp(0, 100).toDouble();
}

int _consistencyPoints(WorkoutHistoryEntry entry, int weeklyCompletionPercent) {
  var points = 10;
  if (_isPlannedTrainingDay(entry.completedAt)) {
    points += 5;
  } else {
    points -= 3;
  }
  if (weeklyCompletionPercent < 50) {
    points = math.max(0, points - 2);
  }
  return math.min(15, math.max(0, points));
}

int _loadQualityPoints(
  WorkoutHistoryEntry entry,
  List<WorkoutHistoryEntry> sortedHistory,
) {
  if (entry.prsAchieved > 0) return 10;
  var progressed = 0;
  var stable = 0;
  var regressed = 0;
  var compared = 0;

  for (final summary in entry.exerciseSummaries) {
    final previous = _findPreviousExerciseSummary(
      summary.exerciseName,
      sortedHistory,
      before: entry.completedAt,
    );
    if (previous == null) continue;
    compared += 1;
    final improvedWeight = summary.maxWeightKg > previous.maxWeightKg + 0.01;
    final improvedReps = summary.totalReps > previous.totalReps;
    final sameWeight =
        (summary.maxWeightKg - previous.maxWeightKg).abs() <= 0.01;
    final sameReps = (summary.totalReps - previous.totalReps).abs() <= 1;

    if (improvedWeight || improvedReps) {
      progressed += 1;
    } else if (sameWeight && sameReps) {
      stable += 1;
    } else {
      regressed += 1;
    }
  }

  if (compared == 0) return 6;
  if (progressed > 0) return 10;
  if (stable > 0) return 6;
  if (regressed > 0) return 3;
  return 6;
}

_GymScoreBreakdown _trainingScore({
  required List<WorkoutHistoryEntry> sortedHistory,
  required int weeklyCompletionPercent,
  required HealthConnectionState connectionState,
  required HealthRecoverySnapshot? recoverySnapshot,
}) {
  if (sortedHistory.isEmpty) {
    return const _GymScoreBreakdown(totalScore: 0);
  }

  final latest = sortedHistory.last;
  final completion = _completionPoints(latest);
  final intensity = _intensityMatchPoints(latest, sortedHistory);
  final effort = _effortConfirmationPoints(latest, recoverySnapshot);
  final workoutPoints = math.min(
    50,
    math.max(0, completion + intensity + effort),
  );
  final averageRecovery = _averageRecoveryForTrainedMuscles(
    latest,
    sortedHistory,
    recoverySnapshot: recoverySnapshot,
  );
  final recoveryPoints = math.min(
    25,
    math.max(0, ((averageRecovery / 100) * 25).round()),
  );
  final consistencyPoints = _consistencyPoints(latest, weeklyCompletionPercent);
  final loadQualityPoints = _loadQualityPoints(latest, sortedHistory);
  final total = math.min(
    100,
    math.max(
      0,
      workoutPoints + recoveryPoints + consistencyPoints + loadQualityPoints,
    ),
  );
  return _GymScoreBreakdown(totalScore: total);
}

bool _isPlannedTrainingDay(DateTime date) {
  final weekday = date.weekday;
  return weekday == DateTime.monday ||
      weekday == DateTime.tuesday ||
      weekday == DateTime.thursday ||
      weekday == DateTime.saturday;
}

String _trainingScoreLabel(int score) {
  if (score >= 80) return 'Prime';
  if (score >= 65) return 'Balanced';
  return 'Recover';
}

String _balanceLabel(double pushRatio, double pullRatio) {
  final delta = (pushRatio - pullRatio).abs();
  if (delta < 0.08) return 'Well distributed';
  if (pushRatio > pullRatio) {
    return delta >= 0.18 ? 'Pull under target' : 'Pull slightly low';
  }
  return delta >= 0.18 ? 'Push under target' : 'Push slightly low';
}

String _recoveryLabelForPercent(double recoveryPercent, int readinessScore) {
  final blended =
      ((recoveryPercent * 0.68) + (readinessScore * 0.32))
          .clamp(0, 100)
          .toDouble();
  if (blended >= 80) return 'Fresh';
  if (blended >= 62) return 'Stable';
  return 'Recovering';
}

String _trainingInsight({
  required int weeklyCompletionPercent,
  required double pushRatio,
  required double pullRatio,
  required double recoveryPercent,
}) {
  final consistencySentence =
      weeklyCompletionPercent >= 75
          ? 'Strong consistency this week.'
          : weeklyCompletionPercent >= 50
          ? 'Consistency is building this week.'
          : 'Consistency is low this week.';
  final delta = (pushRatio - pullRatio).abs();
  if (delta >= 0.14) {
    if (pushRatio > pullRatio) {
      return '$consistencySentence Pull movements are slightly undertrained.';
    }
    return '$consistencySentence Push movements are slightly undertrained.';
  }
  if (recoveryPercent >= 80) {
    return '$consistencySentence Recovery is supporting another strong training block.';
  }
  if (recoveryPercent >= 60) {
    return '$consistencySentence Recovery cadence looks stable for progressive loading.';
  }
  return '$consistencySentence Recovery is trending down after recent loading.';
}

List<TrendPoint> _buildVolumeTrend(List<WorkoutHistoryEntry> sorted) {
  final today = _atStartOfDay(DateTime.now());
  return List<TrendPoint>.generate(8, (index) {
    final weeksAgo = 7 - index;
    final end = today.subtract(Duration(days: weeksAgo * 7));
    final start = end.subtract(const Duration(days: 6));
    final total = sorted.fold<double>(0, (sum, entry) {
      final day = _atStartOfDay(entry.completedAt);
      if (day.isBefore(start) || day.isAfter(end)) return sum;
      return sum + entry.totalVolumeKg;
    });
    return TrendPoint(
      label: 'W${index + 1}',
      value: total <= 0 ? 0 : total / 1000,
    );
  });
}

List<StrengthLiftSnapshot> _buildStrengthProgression(
  List<WorkoutHistoryEntry> sorted,
) {
  final candidates = <_StrengthProgressCandidate>[];
  for (final pair in _exerciseSeries(sorted).entries) {
    final weightedPoints = pair.value
        .where((point) => point.summary.maxWeightKg > 0.01)
        .toList(growable: false);
    if (weightedPoints.length < 2) continue;
    final first = weightedPoints.first.summary.maxWeightKg;
    final last = weightedPoints.last.summary.maxWeightKg;
    candidates.add(
      _StrengthProgressCandidate(
        snapshot: StrengthLiftSnapshot(
          lift: pair.key,
          current: last,
          previous: first,
        ),
        sessionCount: weightedPoints.length,
        deltaKg: last - first,
      ),
    );
  }

  candidates.sort((a, b) {
    final bySessions = b.sessionCount.compareTo(a.sessionCount);
    if (bySessions != 0) return bySessions;
    final byDelta = b.deltaKg.abs().compareTo(a.deltaKg.abs());
    if (byDelta != 0) return byDelta;
    return b.snapshot.current.compareTo(a.snapshot.current);
  });

  return candidates
      .take(4)
      .map((candidate) => candidate.snapshot)
      .toList(growable: false);
}

Map<String, double> _muscleVolumeTotals(List<WorkoutHistoryEntry> entries) {
  final totals = <String, double>{};
  for (final entry in entries) {
    for (final pair in entry.muscleGroupVolumeKg.entries) {
      totals[pair.key] = (totals[pair.key] ?? 0) + pair.value;
    }
  }
  return totals;
}

({double pushRatio, double pullRatio}) _pushPullRatio(
  Map<String, double> muscleTotals,
) {
  const pushMuscles = <String>{
    'Chest',
    'Shoulders',
    'Triceps',
    'Quads',
    'Glutes',
  };
  const pullMuscles = <String>{'Back', 'Biceps', 'Hamstrings'};
  final push = muscleTotals.entries
      .where((entry) => pushMuscles.contains(entry.key))
      .fold<double>(0, (sum, entry) => sum + entry.value);
  final pull = muscleTotals.entries
      .where((entry) => pullMuscles.contains(entry.key))
      .fold<double>(0, (sum, entry) => sum + entry.value);
  final total = push + pull;
  if (total <= 0) return (pushRatio: 0.5, pullRatio: 0.5);
  return (pushRatio: push / total, pullRatio: pull / total);
}

List<MuscleBalanceDatum> _buildMuscleBalance(
  List<WorkoutHistoryEntry> entries,
) {
  final totals = <String, double>{};
  for (final entry in entries) {
    for (final pair in entry.muscleGroupVolumeKg.entries) {
      final category = _balanceCategory(pair.key);
      totals[category] = (totals[category] ?? 0) + pair.value;
    }
  }
  final ranked =
      totals.entries.where((entry) => entry.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  if (ranked.isEmpty) return const <MuscleBalanceDatum>[];

  final totalVolume = ranked.fold<double>(0, (sum, entry) => sum + entry.value);
  final averageShare = 1 / ranked.length;
  return ranked
      .take(5)
      .map((entry) {
        final share = totalVolume <= 0 ? 0.0 : entry.value / totalVolume;
        return MuscleBalanceDatum(
          label: entry.key,
          share: share,
          status: _balanceStatus(share, averageShare),
        );
      })
      .toList(growable: false);
}

String _balanceCategory(String muscle) {
  final normalized = muscle.trim().toLowerCase();
  if (normalized.contains('quad') || normalized.contains('calf')) {
    return 'Lower Body';
  }
  if (normalized.contains('ham') ||
      normalized.contains('glute') ||
      normalized.contains('lower back')) {
    return 'Posterior Chain';
  }
  if (normalized.contains('back') ||
      normalized.contains('lat') ||
      normalized.contains('bicep') ||
      normalized.contains('forearm') ||
      normalized.contains('rear delt')) {
    return 'Pull';
  }
  if (normalized.contains('chest') ||
      normalized.contains('shoulder') ||
      normalized.contains('tricep')) {
    return 'Push';
  }
  if (normalized.contains('condition')) return 'Conditioning';
  if (normalized.contains('core')) return 'Core';
  return 'Accessory';
}

String _balanceStatus(double share, double averageShare) {
  if (share >= averageShare * 1.35) return 'Primary driver';
  if (share >= averageShare * 0.95) return 'On target';
  if (share >= averageShare * 0.65) return 'Slightly behind';
  return 'Low dose';
}

List<ActivityEntry> _buildActivity(
  List<WorkoutHistoryEntry> sorted, {
  required int streak,
}) {
  final items = <ActivityEntry>[];
  for (final entry in sorted.reversed) {
    items.add(
      ActivityEntry(
        id: 'activity-workout-${entry.id}',
        kind: ActivityEntryKind.workout,
        title: 'Completed ${entry.workoutName}',
        detail:
            '${_formatSessionDuration(entry.duration)} • ${_formatCompactMass(entry.totalVolumeKg)} total volume',
        date: entry.completedAt,
      ),
    );
    if (entry.prsAchieved > 0) {
      items.add(
        ActivityEntry(
          id: 'activity-pr-${entry.id}',
          kind: ActivityEntryKind.pr,
          title:
              entry.prsAchieved == 1
                  ? 'New PR in ${entry.workoutName}'
                  : '${entry.prsAchieved} new PRs in ${entry.workoutName}',
          detail: 'Logged on ${_formatDate(entry.completedAt)}',
          date: entry.completedAt,
        ),
      );
    }
  }
  if (streak >= 7 && sorted.isNotEmpty) {
    items.add(
      ActivityEntry(
        id: 'activity-streak',
        kind: ActivityEntryKind.milestone,
        title: '$streak-day training streak',
        detail: 'Built from consecutive logged training days.',
        date: sorted.last.completedAt,
      ),
    );
  }
  items.sort((a, b) => b.date.compareTo(a.date));
  return items.take(6).toList(growable: false);
}

List<HighlightSummary> _buildHighlights(List<WorkoutHistoryEntry> sorted) {
  final longestStreak = _longestStreakDays(sorted);
  final totalVolume = sorted.fold<double>(
    0,
    (sum, entry) => sum + entry.totalVolumeKg,
  );
  final bestLift = _bestLift(sorted);

  final highlights = <HighlightSummary>[
    HighlightSummary(
      title: 'Longest Streak',
      value: '$longestStreak days',
      detail: 'Best consecutive run from logged workout history.',
    ),
    HighlightSummary(
      title: 'Volume Milestone',
      value: _formatCompactMass(totalVolume, compactMillions: true),
      detail: 'Total logged training volume to date.',
    ),
  ];
  if (bestLift != null) {
    highlights.insert(
      1,
      HighlightSummary(
        title: 'Best Lift',
        value: bestLift.value,
        detail: bestLift.detail,
      ),
    );
  }
  return highlights;
}

({String value, String detail})? _bestLift(List<WorkoutHistoryEntry> sorted) {
  WorkoutHistoryExerciseSummary? bestSummary;
  for (final entry in sorted) {
    for (final summary in entry.exerciseSummaries) {
      if (summary.maxWeightKg <= 0.01) continue;
      if (bestSummary == null ||
          summary.maxWeightKg > bestSummary.maxWeightKg) {
        bestSummary = summary;
      }
    }
  }
  if (bestSummary == null) return null;
  final weight = bestSummary.maxWeightKg;
  final value =
      weight % 1 == 0
          ? '${bestSummary.exerciseName} ${weight.toStringAsFixed(0)}kg'
          : '${bestSummary.exerciseName} ${weight.toStringAsFixed(1)}kg';
  return (value: value, detail: 'Top logged load across completed sessions.');
}

String _formatCompactMass(double valueKg, {bool compactMillions = false}) {
  if (valueKg >= 1000000 && compactMillions) {
    return '${(valueKg / 1000000).toStringAsFixed(2)}M kg';
  }
  if (valueKg >= 1000) {
    return '${(valueKg / 1000).toStringAsFixed(1)}k kg';
  }
  return '${valueKg.round()} kg';
}

String _formatSessionDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes % 60;
  if (hours <= 0) return '${duration.inMinutes} min session';
  return '${hours}h ${minutes}m session';
}

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

class _GymScoreBreakdown {
  const _GymScoreBreakdown({required this.totalScore});

  final int totalScore;
}

class _StrengthProgressCandidate {
  const _StrengthProgressCandidate({
    required this.snapshot,
    required this.sessionCount,
    required this.deltaKg,
  });

  final StrengthLiftSnapshot snapshot;
  final int sessionCount;
  final double deltaKg;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/services/health_sync_service.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const String _kExercisePlaceholderImageUrl =
    'https://blocks.astratic.com/img/general-img-landscape.png';

enum _ProgressRange { week, month, quarter, custom }

enum _ProgressMetric { volume, reps, duration }

enum _ProgressSectionId {
  recovery,
  insight,
  performance,
  machineAnalytics,
  exerciseAssessments,
  consistency,
  muscleBalance,
  conditioning,
}

const List<_ProgressSectionId> _kDefaultProgressSectionOrder =
    <_ProgressSectionId>[
      _ProgressSectionId.recovery,
      _ProgressSectionId.insight,
      _ProgressSectionId.performance,
      _ProgressSectionId.machineAnalytics,
      _ProgressSectionId.exerciseAssessments,
      _ProgressSectionId.consistency,
      _ProgressSectionId.muscleBalance,
      _ProgressSectionId.conditioning,
    ];

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.extraBottomInset = 0,
    this.history = const <WorkoutHistoryEntry>[],
    this.onArrangeModeChanged,
  });

  final double extraBottomInset;
  final List<WorkoutHistoryEntry> history;
  final ValueChanged<bool>? onArrangeModeChanged;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  _ProgressRange _selectedRange = _ProgressRange.month;
  _ProgressMetric _selectedMetric = _ProgressMetric.volume;
  final HealthSyncService _healthSyncService = const MockHealthSyncService();
  bool _isReorderMode = false;
  late List<_ProgressSectionId> _sectionOrder;
  late final AnimationController _jiggleController;

  @override
  void initState() {
    super.initState();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    _sectionOrder = List<_ProgressSectionId>.from(
      _kDefaultProgressSectionOrder,
    );
  }

  @override
  void dispose() {
    if (_isReorderMode) {
      widget.onArrangeModeChanged?.call(false);
    }
    _jiggleController.dispose();
    super.dispose();
  }

  void _setReorderMode(bool value) {
    if (_isReorderMode == value) return;
    setState(() => _isReorderMode = value);
    if (value) {
      _jiggleController.repeat(reverse: true);
    } else {
      _jiggleController.stop();
      _jiggleController.value = 0;
    }
    widget.onArrangeModeChanged?.call(value);
  }

  void _enterReorderMode() => _setReorderMode(true);

  void _exitReorderMode() => _setReorderMode(false);

  List<_ProgressSectionId> _effectiveSectionOrder() {
    final seen = <_ProgressSectionId>{};
    final normalized = <_ProgressSectionId>[];
    for (final id in _sectionOrder) {
      if (seen.add(id)) {
        normalized.add(id);
      }
    }
    for (final id in _kDefaultProgressSectionOrder) {
      if (seen.add(id)) {
        normalized.add(id);
      }
    }
    return normalized;
  }

  void _onSectionReorder(int oldIndex, int newIndex) {
    setState(() {
      var insertAt = newIndex;
      if (newIndex > oldIndex) {
        insertAt -= 1;
      }
      final moved = _sectionOrder.removeAt(oldIndex);
      _sectionOrder.insert(insertAt, moved);
    });
  }

  Widget _buildSectionById(
    _ProgressSectionId sectionId,
    _ProgressAnalytics analytics,
  ) {
    return switch (sectionId) {
      _ProgressSectionId.recovery => _RecoverySection(
        readinessScore: analytics.readinessScore,
        recoveryLabel: analytics.recoveryLabel,
        averageRecoveryHours: analytics.avgRecoveryHours,
        muscleRecoveryScores: analytics.muscleRecoveryScores,
        restDayAdherencePercent: analytics.restDayAdherencePercent,
        loadDeltaPercent: analytics.loadDeltaPercent,
        connectionState: analytics.connectionState,
        restingHeartRate: analytics.restingHeartRate,
        hrvMs: analytics.hrvMs,
        sleepMinutes: analytics.sleepMinutes,
        sourceLabel: analytics.healthDataSourceLabel,
      ),
      _ProgressSectionId.insight => _InsightCard(text: analytics.insightText),
      _ProgressSectionId.performance => _PerformanceSection(
        selectedRange: _selectedRange,
        selectedMetric: _selectedMetric,
        series: analytics.series,
        trendPercent: analytics.trendPercent,
        bestMachine: analytics.bestMachine,
        prCount: analytics.prCount,
        onRangeChanged: (range) {
          if (range == null) return;
          setState(() => _selectedRange = range);
        },
        onMetricChanged: (metric) {
          if (metric == null) return;
          setState(() => _selectedMetric = metric);
        },
      ),
      _ProgressSectionId.machineAnalytics => _MachineAnalyticsSection(
        machineStats: analytics.machineStats,
      ),
      _ProgressSectionId.exerciseAssessments => _ExerciseAssessmentSection(
        assessments: analytics.exerciseAssessments,
      ),
      _ProgressSectionId.consistency => _ConsistencySection(
        streakDays: analytics.streakDays,
        weeklyCompletionPercent: analytics.weeklyCompletionPercent,
        trainingScore: analytics.trainingScore,
        heatmapShades: analytics.heatmapShades,
      ),
      _ProgressSectionId.muscleBalance => _MuscleBalanceSection(
        pushRatio: analytics.pushRatio,
        pullRatio: analytics.pullRatio,
        recoveryLabel: analytics.recoveryLabel,
      ),
      _ProgressSectionId.conditioning => _ConditioningSection(
        pullupReps: analytics.pullupReps,
        bodyweightReps: analytics.bodyweightReps,
        conditioningDurationLabel: analytics.conditioningDurationLabel,
      ),
    };
  }

  List<WorkoutHistoryEntry> _sortedHistory() {
    final sorted = List<WorkoutHistoryEntry>.from(widget.history);
    sorted.sort((a, b) => a.completedAt.compareTo(b.completedAt));
    return sorted;
  }

  DateTime _atStartOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  List<WorkoutHistoryEntry> _entriesInSelectedRange(
    List<WorkoutHistoryEntry> sorted,
  ) {
    if (sorted.isEmpty) return const <WorkoutHistoryEntry>[];
    final now = DateTime.now();
    final today = _atStartOfDay(now);
    DateTime rangeStart;
    switch (_selectedRange) {
      case _ProgressRange.week:
        rangeStart = today.subtract(const Duration(days: 6));
      case _ProgressRange.month:
        rangeStart = today.subtract(const Duration(days: 29));
      case _ProgressRange.quarter:
        rangeStart = today.subtract(const Duration(days: 89));
      case _ProgressRange.custom:
        rangeStart = _atStartOfDay(sorted.first.completedAt);
    }

    return sorted
        .where((entry) {
          final day = _atStartOfDay(entry.completedAt);
          return !day.isBefore(rangeStart) && !day.isAfter(today);
        })
        .toList(growable: false);
  }

  double _metricValueForEntry(WorkoutHistoryEntry entry) {
    switch (_selectedMetric) {
      case _ProgressMetric.volume:
        return entry.totalVolumeKg;
      case _ProgressMetric.reps:
        return entry.totalReps.toDouble();
      case _ProgressMetric.duration:
        return entry.duration.inMinutes.toDouble();
    }
  }

  List<double> _buildSeries(
    List<WorkoutHistoryEntry> rangeEntries,
    List<WorkoutHistoryEntry> allSorted,
  ) {
    final today = _atStartOfDay(DateTime.now());
    switch (_selectedRange) {
      case _ProgressRange.week:
        return _aggregateDaily(rangeEntries, today, dayCount: 7);
      case _ProgressRange.month:
        return _aggregateBucketed(
          rangeEntries,
          today,
          totalDays: 30,
          bucketSizeDays: 3,
        );
      case _ProgressRange.quarter:
        return _aggregateBucketed(
          rangeEntries,
          today,
          totalDays: 90,
          bucketSizeDays: 7,
        );
      case _ProgressRange.custom:
        return _aggregateMonthly(rangeEntries, allSorted);
    }
  }

  List<double> _aggregateDaily(
    List<WorkoutHistoryEntry> entries,
    DateTime today, {
    required int dayCount,
  }) {
    final byDay = <DateTime, double>{};
    for (final entry in entries) {
      final day = _atStartOfDay(entry.completedAt);
      byDay[day] = (byDay[day] ?? 0) + _metricValueForEntry(entry);
    }
    return List<double>.generate(dayCount, (index) {
      final day = today.subtract(Duration(days: dayCount - 1 - index));
      return byDay[day] ?? 0;
    });
  }

  List<double> _aggregateBucketed(
    List<WorkoutHistoryEntry> entries,
    DateTime today, {
    required int totalDays,
    required int bucketSizeDays,
  }) {
    final bucketCount = (totalDays / bucketSizeDays).ceil();
    final buckets = List<double>.filled(bucketCount, 0, growable: false);
    final rangeStart = today.subtract(Duration(days: totalDays - 1));
    for (final entry in entries) {
      final day = _atStartOfDay(entry.completedAt);
      if (day.isBefore(rangeStart) || day.isAfter(today)) continue;
      final dayOffset = day.difference(rangeStart).inDays;
      final bucketIndex = (dayOffset / bucketSizeDays).floor().clamp(
        0,
        bucketCount - 1,
      );
      buckets[bucketIndex] += _metricValueForEntry(entry);
    }
    return buckets;
  }

  List<double> _aggregateMonthly(
    List<WorkoutHistoryEntry> rangeEntries,
    List<WorkoutHistoryEntry> allSorted,
  ) {
    if (allSorted.isEmpty) {
      return List<double>.filled(6, 0, growable: false);
    }
    final latest = _atStartOfDay(DateTime.now());
    final earliestRange =
        rangeEntries.isNotEmpty
            ? _atStartOfDay(rangeEntries.first.completedAt)
            : _atStartOfDay(allSorted.first.completedAt);
    final start = DateTime(earliestRange.year, earliestRange.month);
    final end = DateTime(latest.year, latest.month);

    final monthKeys = <DateTime>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      monthKeys.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    final normalizedKeys =
        monthKeys.length > 12
            ? monthKeys.sublist(monthKeys.length - 12)
            : monthKeys;

    final byMonth = <DateTime, double>{};
    for (final entry in rangeEntries) {
      final key = DateTime(entry.completedAt.year, entry.completedAt.month);
      byMonth[key] = (byMonth[key] ?? 0) + _metricValueForEntry(entry);
    }
    return normalizedKeys
        .map((key) => byMonth[key] ?? 0)
        .toList(growable: false);
  }

  int _countPrs(List<WorkoutHistoryEntry> entries) {
    return entries.fold<int>(0, (sum, entry) => sum + entry.prsAchieved);
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
              <
                ({DateTime completedAt, WorkoutHistoryExerciseSummary summary})
              >[],
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

  List<_MachineProgressStat> _machineStats(List<WorkoutHistoryEntry> entries) {
    final series = _exerciseSeries(entries);
    final items = <_MachineProgressStat>[];
    for (final machine in series.entries) {
      final points = machine.value;
      if (points.isEmpty) continue;
      final first = points.first.summary.maxWeightKg;
      final last = points.last.summary.maxWeightKg;
      final gain = last - first;
      final useCount = points.length;
      final spanDays = math.max(
        1,
        points.last.completedAt.difference(points.first.completedAt).inDays,
      );
      final spanWeeks = math.max(1, (spanDays / 7).round());
      items.add(
        _MachineProgressStat(
          name: machine.key,
          gainKg: gain,
          periodLabel: '$spanWeeks week${spanWeeks == 1 ? '' : 's'}',
          usageCount: useCount,
          latestMaxWeightKg: last,
        ),
      );
    }
    items.sort((a, b) {
      final usage = b.usageCount.compareTo(a.usageCount);
      if (usage != 0) return usage;
      return b.latestMaxWeightKg.compareTo(a.latestMaxWeightKg);
    });
    return items;
  }

  List<_ExerciseAssessment> _exerciseAssessments(
    List<WorkoutHistoryEntry> entries,
  ) {
    final series = _exerciseSeries(entries);
    final items = <_ExerciseAssessment>[];
    for (final pair in series.entries) {
      final points = pair.value;
      if (points.isEmpty) continue;
      final first = points.first.summary;
      final latest = points.last.summary;
      final maxWeightDelta = latest.maxWeightKg - first.maxWeightKg;
      final totalVolume = points.fold<double>(
        0,
        (sum, point) => sum + point.summary.totalVolumeKg,
      );
      final totalSets = points.fold<int>(
        0,
        (sum, point) => sum + point.summary.setCount,
      );
      final totalReps = points.fold<int>(
        0,
        (sum, point) => sum + point.summary.totalReps,
      );
      final avgRepsPerSet = totalSets == 0 ? 0.0 : totalReps / totalSets;
      final trend =
          points.length <= 1
              ? _ExerciseTrend.newExercise
              : maxWeightDelta >= 2.5
              ? _ExerciseTrend.improving
              : maxWeightDelta <= -2.5
              ? _ExerciseTrend.regressing
              : _ExerciseTrend.stable;
      final insight = switch (trend) {
        _ExerciseTrend.improving => 'Load capacity is trending up.',
        _ExerciseTrend.stable => 'Progress is stable. Push for reps or load.',
        _ExerciseTrend.regressing =>
          'Performance dipped. Focus on recovery and form.',
        _ExerciseTrend.newExercise =>
          'New movement. Complete more sessions for clearer trend.',
      };
      items.add(
        _ExerciseAssessment(
          name: pair.key,
          trend: trend,
          sessions: points.length,
          maxWeightDeltaKg: maxWeightDelta,
          latestMaxWeightKg: latest.maxWeightKg,
          totalVolumeKg: totalVolume,
          averageRepsPerSet: avgRepsPerSet,
          insight: insight,
        ),
      );
    }
    items.sort((a, b) {
      final byTrend = b.trend.priority.compareTo(a.trend.priority);
      if (byTrend != 0) return byTrend;
      final bySessions = b.sessions.compareTo(a.sessions);
      if (bySessions != 0) return bySessions;
      return b.latestMaxWeightKg.compareTo(a.latestMaxWeightKg);
    });
    return items;
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

  double? _averageRecoveryHours(List<WorkoutHistoryEntry> sorted) {
    if (sorted.length < 2) return null;
    double totalHours = 0;
    var intervals = 0;
    for (var i = 1; i < sorted.length; i++) {
      final gapHours =
          sorted[i].completedAt.difference(sorted[i - 1].completedAt).inHours;
      if (gapHours <= 0) continue;
      totalHours += gapHours;
      intervals += 1;
    }
    if (intervals == 0) return null;
    return totalHours / intervals;
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

  List<double> _heatmapShades(List<WorkoutHistoryEntry> sorted) {
    const dayCount = 35;
    final today = _atStartOfDay(DateTime.now());
    final byDay = <DateTime, double>{};
    for (final entry in sorted) {
      final day = _atStartOfDay(entry.completedAt);
      byDay[day] = (byDay[day] ?? 0) + entry.totalVolumeKg;
    }
    final values = List<double>.generate(dayCount, (index) {
      final day = today.subtract(Duration(days: dayCount - 1 - index));
      return byDay[day] ?? 0;
    });
    final maxValue = values.fold<double>(0, math.max);
    return values
        .map((value) {
          if (value <= 0) return 0.03;
          final normalized = maxValue <= 0 ? 0 : value / maxValue;
          return (0.08 + (normalized * 0.34)).clamp(0.08, 0.42);
        })
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

  String _recoveryLabel(List<WorkoutHistoryEntry> sorted) {
    if (sorted.length < 2) return 'Not enough history';
    double totalHours = 0;
    var intervals = 0;
    for (var i = 1; i < sorted.length; i++) {
      final gapHours =
          sorted[i].completedAt.difference(sorted[i - 1].completedAt).inHours;
      if (gapHours <= 0) continue;
      totalHours += gapHours;
      intervals += 1;
    }
    if (intervals == 0) return 'Not enough history';
    final avgHours = totalHours / intervals;
    if (avgHours >= 48) {
      final days = avgHours / 24;
      return '${days.toStringAsFixed(1)}d average recovery';
    }
    return '${avgHours.toStringAsFixed(0)}h average recovery';
  }

  bool _isPlannedTrainingDay(DateTime date) {
    final weekday = date.weekday;
    return weekday == DateTime.monday ||
        weekday == DateTime.tuesday ||
        weekday == DateTime.thursday ||
        weekday == DateTime.saturday;
  }

  WorkoutHistoryExerciseSummary? _findPreviousExerciseSummary(
    String exerciseName,
    List<WorkoutHistoryEntry> sortedHistory, {
    required DateTime before,
  }) {
    for (var index = sortedHistory.length - 1; index >= 0; index--) {
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
    final avgDiff = totalDiff / comparisons;
    if (avgDiff <= 0.10) return 10;
    if (avgDiff <= 0.15) return 7;
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

  List<_MuscleRecoveryScore> _individualRecoveryForTrainedMuscles(
    WorkoutHistoryEntry entry,
    List<WorkoutHistoryEntry> sortedHistory, {
    HealthRecoverySnapshot? recoverySnapshot,
  }) {
    final muscles = entry.muscleGroupVolumeKg.keys
        .where((key) => key.trim().isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (muscles.isEmpty) return const <_MuscleRecoveryScore>[];

    final referenceDay = _atStartOfDay(entry.completedAt);
    final readinessBlend = recoverySnapshot?.readinessScore.toDouble();
    final scores = <_MuscleRecoveryScore>[];
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
      var recovery = (1 - fatigue.clamp(0.0, 1.0)) * 100;
      if (readinessBlend != null) {
        recovery = (recovery * 0.72) + (readinessBlend * 0.28);
      }
      scores.add(
        _MuscleRecoveryScore(
          muscle: muscle,
          recoveryPercent: recovery.clamp(0, 100).toDouble(),
        ),
      );
    }
    scores.sort((a, b) => a.recoveryPercent.compareTo(b.recoveryPercent));
    return scores;
  }

  int _consistencyPoints(
    WorkoutHistoryEntry entry,
    int weeklyCompletionPercent,
  ) {
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

  int _integrationConfidenceScore(
    HealthConnectionState connectionState,
    HealthRecoverySnapshot? recoverySnapshot,
  ) {
    var score = 72;
    if (connectionState.anyConnected) score += 10;
    if (connectionState.appleHealthConnected) score += 6;
    if (connectionState.googleFitConnected) score += 6;
    if (connectionState.appleWatchConnected) score += 6;
    if (recoverySnapshot?.restingHeartRate != null) score += 4;
    if (recoverySnapshot?.hrvMs != null) score += 4;
    if (recoverySnapshot?.sleepMinutes != null) score += 4;
    return math.min(100, math.max(55, score));
  }

  _GymScoreBreakdown _trainingScore({
    required List<WorkoutHistoryEntry> sortedHistory,
    required int weeklyCompletionPercent,
    required HealthConnectionState connectionState,
    required HealthRecoverySnapshot? recoverySnapshot,
  }) {
    if (sortedHistory.isEmpty) {
      return _GymScoreBreakdown(
        totalScore: 0,
        workoutPoints: 0,
        recoveryPoints: 0,
        consistencyPoints: 0,
        loadQualityPoints: 0,
        confidenceScore: _integrationConfidenceScore(
          connectionState,
          recoverySnapshot,
        ),
      );
    }
    final latest = sortedHistory.last;
    final completion = _completionPoints(latest);
    final intensity = _intensityMatchPoints(latest, sortedHistory);
    final effort = _effortConfirmationPoints(latest, recoverySnapshot);
    final workoutPoints = math.min(
      50,
      math.max(0, completion + intensity + effort),
    );

    final avgRecovery = _averageRecoveryForTrainedMuscles(
      latest,
      sortedHistory,
      recoverySnapshot: recoverySnapshot,
    );
    final recoveryPoints = math.min(
      25,
      math.max(0, ((avgRecovery / 100) * 25).round()),
    );
    final consistencyPoints = _consistencyPoints(
      latest,
      weeklyCompletionPercent,
    );
    final loadQualityPoints = _loadQualityPoints(latest, sortedHistory);
    final total = math.min(
      100,
      math.max(
        0,
        workoutPoints + recoveryPoints + consistencyPoints + loadQualityPoints,
      ),
    );
    final confidence = _integrationConfidenceScore(
      connectionState,
      recoverySnapshot,
    );
    return _GymScoreBreakdown(
      totalScore: total,
      workoutPoints: workoutPoints,
      recoveryPoints: recoveryPoints,
      consistencyPoints: consistencyPoints,
      loadQualityPoints: loadQualityPoints,
      confidenceScore: confidence,
    );
  }

  String _conditioningDurationLabel(List<WorkoutHistoryEntry> entries) {
    final keywords = <String>{'cardio', 'walk', 'row erg', 'conditioning'};
    var duration = Duration.zero;
    for (final entry in entries) {
      final workoutName = entry.workoutName.toLowerCase();
      final hasConditioningInWorkout = keywords.any(workoutName.contains);
      final hasConditioningExercise = entry.exerciseSummaries.any((summary) {
        final name = summary.exerciseName.toLowerCase();
        return keywords.any(name.contains);
      });
      if (hasConditioningInWorkout || hasConditioningExercise) {
        duration += entry.duration;
      }
    }
    if (duration == Duration.zero) return '0m';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  int _bodyweightReps(List<WorkoutHistoryEntry> entries) {
    var total = 0;
    for (final entry in entries) {
      for (final summary in entry.exerciseSummaries) {
        if (summary.maxWeightKg <= 0.01) {
          total += summary.totalReps;
        }
      }
    }
    return total;
  }

  int _pullupReps(List<WorkoutHistoryEntry> entries) {
    var total = 0;
    for (final entry in entries) {
      for (final summary in entry.exerciseSummaries) {
        final name = summary.exerciseName.toLowerCase();
        if (name.contains('pull up') || name.contains('pull-up')) {
          total += summary.totalReps;
        }
      }
    }
    return total;
  }

  _ProgressAnalytics _buildAnalytics(
    List<WorkoutHistoryEntry> allSorted,
    List<WorkoutHistoryEntry> rangeEntries,
  ) {
    final series = _buildSeries(rangeEntries, allSorted);
    final safeSeries =
        series.isEmpty ? List<double>.filled(6, 0, growable: false) : series;
    final first = safeSeries.first;
    final last = safeSeries.last;
    final trendPercent = first <= 0 ? 0.0 : ((last - first) / first) * 100;
    final totalPrs = _countPrs(rangeEntries);
    final machineStats = _machineStats(rangeEntries);
    final exerciseAssessments = _exerciseAssessments(rangeEntries);
    final bestMachine =
        machineStats.isEmpty ? 'No machine data' : machineStats.first.name;
    final streak = _streakDays(allSorted);
    final weeklyCompletion = _weeklyCompletionPercent(allSorted);
    final sessionsLastWeek = _sessionsInLastDays(allSorted, 7);
    final restDaysLastWeek = (7 - sessionsLastWeek).clamp(0, 7);
    final restDayAdherencePercent = ((restDaysLastWeek / 2) * 100)
        .round()
        .clamp(0, 100);
    final heatmap = _heatmapShades(allSorted);
    final muscleTotals = _muscleVolumeTotals(rangeEntries);
    final ratio = _pushPullRatio(muscleTotals);
    final recoveryLabel = _recoveryLabel(allSorted);
    final avgRecoveryHours = _averageRecoveryHours(allSorted);
    final thisWeekVolume = _weeklyVolume(allSorted, 0);
    final previousWeekVolume = _weeklyVolume(allSorted, 1);
    final loadDeltaPercent =
        previousWeekVolume <= 0
            ? 0.0
            : ((thisWeekVolume - previousWeekVolume) / previousWeekVolume) *
                100;
    final connectionState = _healthSyncService.connectionState();
    final healthRecovery = _healthSyncService.latestRecoverySnapshot();
    final readinessScore =
        healthRecovery?.readinessScore ??
        _estimatedReadinessScore(
          weeklyCompletionPercent: weeklyCompletion,
          restDaysLastWeek: restDaysLastWeek,
          loadDeltaPercent: loadDeltaPercent.abs(),
        );
    final gymScore = _trainingScore(
      sortedHistory: allSorted,
      weeklyCompletionPercent: weeklyCompletion,
      connectionState: connectionState,
      recoverySnapshot: healthRecovery,
    );
    final muscleRecoveryScores =
        allSorted.isEmpty
            ? const <_MuscleRecoveryScore>[]
            : _individualRecoveryForTrainedMuscles(
              allSorted.last,
              allSorted,
              recoverySnapshot: healthRecovery,
            );
    final insightText = _buildInsightText(
      rangeEntries: rangeEntries,
      trendPercent: trendPercent,
      ratio: ratio,
    );

    return _ProgressAnalytics(
      insightText: insightText,
      series: safeSeries,
      trendPercent: trendPercent,
      bestMachine: bestMachine,
      prCount: totalPrs,
      machineStats: machineStats.take(3).toList(growable: false),
      exerciseAssessments: exerciseAssessments.take(6).toList(growable: false),
      streakDays: streak,
      weeklyCompletionPercent: weeklyCompletion,
      trainingScore: gymScore.totalScore,
      gymScore: gymScore,
      heatmapShades: heatmap,
      pushRatio: ratio.pushRatio,
      pullRatio: ratio.pullRatio,
      recoveryLabel: recoveryLabel,
      readinessScore: readinessScore,
      avgRecoveryHours: avgRecoveryHours,
      muscleRecoveryScores: muscleRecoveryScores,
      restDayAdherencePercent: restDayAdherencePercent,
      loadDeltaPercent: loadDeltaPercent,
      connectionState: connectionState,
      restingHeartRate: healthRecovery?.restingHeartRate,
      hrvMs: healthRecovery?.hrvMs,
      sleepMinutes: healthRecovery?.sleepMinutes,
      healthDataSourceLabel: healthRecovery?.sourceLabel,
      bodyweightReps: _bodyweightReps(rangeEntries),
      pullupReps: _pullupReps(rangeEntries),
      conditioningDurationLabel: _conditioningDurationLabel(rangeEntries),
      hasData: rangeEntries.isNotEmpty,
    );
  }

  String _buildInsightText({
    required List<WorkoutHistoryEntry> rangeEntries,
    required double trendPercent,
    required ({double pushRatio, double pullRatio}) ratio,
  }) {
    if (rangeEntries.isEmpty) {
      return 'Complete at least one workout to unlock progress insights and trend analytics.';
    }
    final trendWord = trendPercent >= 0 ? 'increased' : 'decreased';
    final trendMagnitude = trendPercent.abs().toStringAsFixed(1);
    final ratioDelta = (ratio.pushRatio - ratio.pullRatio).abs();
    if (ratioDelta >= 0.14) {
      if (ratio.pushRatio > ratio.pullRatio) {
        return 'Training load has $trendWord by $trendMagnitude% in this range. Pull movements are undertrained vs push.';
      }
      return 'Training load has $trendWord by $trendMagnitude% in this range. Push movements are undertrained vs pull.';
    }
    switch (_selectedMetric) {
      case _ProgressMetric.volume:
        return 'Total weekly volume has $trendWord by $trendMagnitude%. Your push/pull balance is within target.';
      case _ProgressMetric.reps:
        return 'Rep output has $trendWord by $trendMagnitude% across selected sessions. Consistency is trending positively.';
      case _ProgressMetric.duration:
        return 'Session duration has $trendWord by $trendMagnitude%. Recovery cadence looks stable for progressive loading.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSorted = _sortedHistory();
    final rangeEntries = _entriesInSelectedRange(allSorted);
    final analytics = _buildAnalytics(allSorted, rangeEntries);
    final baseBottomInset = _isReorderMode ? 96.0 : 104.0;
    final bottomInset = baseBottomInset + widget.extraBottomInset;
    final sectionOrder = _effectiveSectionOrder();
    final mediaBottomInset = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          ReorderableListView(
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomInset),
            buildDefaultDragHandles: false,
            onReorder: _onSectionReorder,
            proxyDecorator: (child, index, animation) {
              final curve = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return AnimatedBuilder(
                animation: curve,
                builder: (context, _) {
                  final t = curve.value;
                  final scale = 1.0 + (0.02 * t);
                  return Transform.scale(
                    scale: scale,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.12 + (0.12 * t),
                            ),
                            blurRadius: 24 + (12 * t),
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
              );
            },
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: _enterReorderMode,
                  child: _TrainingScoreHero(gymScore: analytics.gymScore),
                ),
                const SizedBox(height: 10),
                if (_isReorderMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Arrange mode: drag cards to reorder',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
              ],
            ),
            footer: null,
            children: List<Widget>.generate(sectionOrder.length, (index) {
              final sectionId = sectionOrder[index];
              final baseChild = _buildSectionById(sectionId, analytics);
              Widget reorderableChild;
              if (_isReorderMode) {
                reorderableChild = ReorderableDelayedDragStartListener(
                  index: index,
                  child: AnimatedBuilder(
                    animation: _jiggleController,
                    child: baseChild,
                    builder: (context, child) {
                      final wave = (0.004 + (_jiggleController.value * 0.008));
                      final angle = index.isEven ? wave : -wave;
                      return Transform.rotate(
                        angle: angle,
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                  ),
                );
              } else {
                reorderableChild = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onLongPress: _enterReorderMode,
                  child: baseChild,
                );
              }
              return Container(
                key: ValueKey<String>('progress-section-${sectionId.name}'),
                margin: const EdgeInsets.only(bottom: 14),
                child: reorderableChild,
              );
            }),
          ),
          if (_isReorderMode)
            Positioned(
              right: 16,
              bottom: widget.extraBottomInset + mediaBottomInset + 16,
              child: SafeArea(
                top: false,
                bottom: false,
                child: FilledButton(
                  onPressed: _exitReorderMode,
                  style: FilledButton.styleFrom(
                    backgroundColor: kAccentColor.withValues(alpha: 0.92),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressAnalytics {
  const _ProgressAnalytics({
    required this.insightText,
    required this.series,
    required this.trendPercent,
    required this.bestMachine,
    required this.prCount,
    required this.machineStats,
    required this.exerciseAssessments,
    required this.streakDays,
    required this.weeklyCompletionPercent,
    required this.trainingScore,
    required this.gymScore,
    required this.heatmapShades,
    required this.pushRatio,
    required this.pullRatio,
    required this.recoveryLabel,
    required this.readinessScore,
    required this.avgRecoveryHours,
    required this.muscleRecoveryScores,
    required this.restDayAdherencePercent,
    required this.loadDeltaPercent,
    required this.connectionState,
    required this.restingHeartRate,
    required this.hrvMs,
    required this.sleepMinutes,
    required this.healthDataSourceLabel,
    required this.bodyweightReps,
    required this.pullupReps,
    required this.conditioningDurationLabel,
    required this.hasData,
  });

  final String insightText;
  final List<double> series;
  final double trendPercent;
  final String bestMachine;
  final int prCount;
  final List<_MachineProgressStat> machineStats;
  final List<_ExerciseAssessment> exerciseAssessments;
  final int streakDays;
  final int weeklyCompletionPercent;
  final int trainingScore;
  final _GymScoreBreakdown gymScore;
  final List<double> heatmapShades;
  final double pushRatio;
  final double pullRatio;
  final String recoveryLabel;
  final int readinessScore;
  final double? avgRecoveryHours;
  final List<_MuscleRecoveryScore> muscleRecoveryScores;
  final int restDayAdherencePercent;
  final double loadDeltaPercent;
  final HealthConnectionState connectionState;
  final int? restingHeartRate;
  final int? hrvMs;
  final int? sleepMinutes;
  final String? healthDataSourceLabel;
  final int bodyweightReps;
  final int pullupReps;
  final String conditioningDurationLabel;
  final bool hasData;
}

class _GymScoreBreakdown {
  const _GymScoreBreakdown({
    required this.totalScore,
    required this.workoutPoints,
    required this.recoveryPoints,
    required this.consistencyPoints,
    required this.loadQualityPoints,
    required this.confidenceScore,
  });

  final int totalScore;
  final int workoutPoints;
  final int recoveryPoints;
  final int consistencyPoints;
  final int loadQualityPoints;
  final int confidenceScore;
}

class _MachineProgressStat {
  const _MachineProgressStat({
    required this.name,
    required this.gainKg,
    required this.periodLabel,
    required this.usageCount,
    required this.latestMaxWeightKg,
  });

  final String name;
  final double gainKg;
  final String periodLabel;
  final int usageCount;
  final double latestMaxWeightKg;
}

class _MuscleRecoveryScore {
  const _MuscleRecoveryScore({
    required this.muscle,
    required this.recoveryPercent,
  });

  final String muscle;
  final double recoveryPercent;
}

enum _ExerciseTrend { improving, stable, regressing, newExercise }

extension _ExerciseTrendX on _ExerciseTrend {
  String get label {
    switch (this) {
      case _ExerciseTrend.improving:
        return 'Improving';
      case _ExerciseTrend.stable:
        return 'Stable';
      case _ExerciseTrend.regressing:
        return 'Needs attention';
      case _ExerciseTrend.newExercise:
        return 'New';
    }
  }

  Color get color {
    switch (this) {
      case _ExerciseTrend.improving:
        return Colors.green.shade700;
      case _ExerciseTrend.stable:
        return Colors.blueGrey.shade700;
      case _ExerciseTrend.regressing:
        return Colors.red.shade600;
      case _ExerciseTrend.newExercise:
        return kAccentColor;
    }
  }

  int get priority {
    switch (this) {
      case _ExerciseTrend.improving:
        return 4;
      case _ExerciseTrend.stable:
        return 3;
      case _ExerciseTrend.newExercise:
        return 2;
      case _ExerciseTrend.regressing:
        return 1;
    }
  }
}

class _ExerciseAssessment {
  const _ExerciseAssessment({
    required this.name,
    required this.trend,
    required this.sessions,
    required this.maxWeightDeltaKg,
    required this.latestMaxWeightKg,
    required this.totalVolumeKg,
    required this.averageRepsPerSet,
    required this.insight,
  });

  final String name;
  final _ExerciseTrend trend;
  final int sessions;
  final double maxWeightDeltaKg;
  final double latestMaxWeightKg;
  final double totalVolumeKg;
  final double averageRepsPerSet;
  final String insight;
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kAccentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: kAccentColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade800,
                height: 1.4,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrainingScoreHero extends StatelessWidget {
  const _TrainingScoreHero({required this.gymScore});

  final _GymScoreBreakdown gymScore;

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green.shade700;
    if (score >= 65) return kAccentColor;
    if (score >= 50) return Colors.orange.shade700;
    return Colors.red.shade600;
  }

  String _scoreStatus(int score) {
    if (score >= 80) return 'Strong momentum';
    if (score >= 65) return 'Building well';
    if (score >= 50) return 'Needs consistency';
    return 'Reset and recover';
  }

  @override
  Widget build(BuildContext context) {
    final score = gymScore.totalScore.clamp(0, 100);
    final scoreColor = _scoreColor(score);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scoreColor.withValues(alpha: 0.10), Colors.white],
        ),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Training score',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _scoreStatus(score),
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: scoreColor.withValues(alpha: 0.35),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '$score',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Daily max is 100. Integrations improve score confidence, not the score ceiling.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ScoreChip(
                label: 'Workout',
                value: '${gymScore.workoutPoints}/50',
              ),
              _ScoreChip(
                label: 'Recovery',
                value: '${gymScore.recoveryPoints}/25',
              ),
              _ScoreChip(
                label: 'Consistency',
                value: '${gymScore.consistencyPoints}/15',
              ),
              _ScoreChip(
                label: 'Load quality',
                value: '${gymScore.loadQualityPoints}/10',
              ),
              _ScoreChip(
                label: 'Confidence',
                value: '${gymScore.confidenceScore}%',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.grey.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({
    required this.selectedRange,
    required this.selectedMetric,
    required this.series,
    required this.trendPercent,
    required this.bestMachine,
    required this.prCount,
    required this.onRangeChanged,
    required this.onMetricChanged,
  });

  final _ProgressRange selectedRange;
  final _ProgressMetric selectedMetric;
  final List<double> series;
  final double trendPercent;
  final String bestMachine;
  final int prCount;
  final ValueChanged<_ProgressRange?> onRangeChanged;
  final ValueChanged<_ProgressMetric?> onMetricChanged;

  @override
  Widget build(BuildContext context) {
    final trendText =
        '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%';

    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance trends',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RangeChip(
                label: '7D',
                selected: selectedRange == _ProgressRange.week,
                onTap: () => onRangeChanged(_ProgressRange.week),
              ),
              _RangeChip(
                label: '30D',
                selected: selectedRange == _ProgressRange.month,
                onTap: () => onRangeChanged(_ProgressRange.month),
              ),
              _RangeChip(
                label: '90D',
                selected: selectedRange == _ProgressRange.quarter,
                onTap: () => onRangeChanged(_ProgressRange.quarter),
              ),
              _RangeChip(
                label: 'Custom',
                selected: selectedRange == _ProgressRange.custom,
                onTap: () => onRangeChanged(_ProgressRange.custom),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<_ProgressMetric>(
            showSelectedIcon: false,
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              side: WidgetStatePropertyAll(
                BorderSide(color: Colors.grey.shade300),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? Colors.white
                    : Colors.grey.shade700;
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? kAccentColor
                    : Colors.white;
              }),
            ),
            segments: const [
              ButtonSegment(
                value: _ProgressMetric.volume,
                label: Text('Volume'),
              ),
              ButtonSegment(value: _ProgressMetric.reps, label: Text('Reps')),
              ButtonSegment(
                value: _ProgressMetric.duration,
                label: Text('Duration'),
              ),
            ],
            selected: {selectedMetric},
            onSelectionChanged: (next) {
              if (next.isEmpty) return;
              onMetricChanged(next.first);
            },
          ),
          const SizedBox(height: 12),
          Container(
            height: 170,
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CustomPaint(
              painter: _TrendChartPainter(series: series, color: kAccentColor),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStatTile(title: 'Trend', value: trendText)),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(title: 'Best machine', value: bestMachine),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'PR timeline',
                  value: '$prCount PRs',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MachineAnalyticsSection extends StatelessWidget {
  const _MachineAnalyticsSection({required this.machineStats});

  final List<_MachineProgressStat> machineStats;

  @override
  Widget build(BuildContext context) {
    final machines = machineStats;

    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Machine analytics',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (machines.isEmpty)
            Text(
              'Complete workouts to unlock machine progression.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...machines.map((machine) {
              final gainPrefix = machine.gainKg >= 0 ? '+' : '';
              final gain =
                  '$gainPrefix${machine.gainKg.toStringAsFixed(machine.gainKg.abs() < 10 ? 1 : 0)}kg';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MachineStatRow(
                  name: machine.name,
                  gain: gain,
                  period: machine.periodLabel,
                  usage: '${machine.usageCount} uses',
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ExerciseAssessmentSection extends StatelessWidget {
  const _ExerciseAssessmentSection({required this.assessments});

  final List<_ExerciseAssessment> assessments;

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercise assessments',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (assessments.isEmpty)
            Text(
              'Complete workouts to unlock per-exercise progression assessments.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          else
            ...assessments.map((assessment) {
              final gainPrefix = assessment.maxWeightDeltaKg >= 0 ? '+' : '';
              final gainValue =
                  '$gainPrefix${_formatWeight(assessment.maxWeightDeltaKg)}kg';
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assessment.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: assessment.trend.color.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: assessment.trend.color.withValues(
                                  alpha: 0.28,
                                ),
                              ),
                            ),
                            child: Text(
                              assessment.trend.label.toUpperCase(),
                              style: TextStyle(
                                color: assessment.trend.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniStatTile(
                              title: 'Max load trend',
                              value: gainValue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStatTile(
                              title: 'Current max',
                              value:
                                  '${_formatWeight(assessment.latestMaxWeightKg)}kg',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniStatTile(
                              title: 'Sessions',
                              value: '${assessment.sessions}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${assessment.insight} Avg reps/set ${assessment.averageRepsPerSet.toStringAsFixed(1)} • Volume ${assessment.totalVolumeKg.toStringAsFixed(0)}kg',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          height: 1.3,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _RecoverySection extends StatelessWidget {
  const _RecoverySection({
    required this.readinessScore,
    required this.recoveryLabel,
    required this.averageRecoveryHours,
    required this.muscleRecoveryScores,
    required this.restDayAdherencePercent,
    required this.loadDeltaPercent,
    required this.connectionState,
    required this.restingHeartRate,
    required this.hrvMs,
    required this.sleepMinutes,
    required this.sourceLabel,
  });

  final int readinessScore;
  final String recoveryLabel;
  final double? averageRecoveryHours;
  final List<_MuscleRecoveryScore> muscleRecoveryScores;
  final int restDayAdherencePercent;
  final double loadDeltaPercent;
  final HealthConnectionState connectionState;
  final int? restingHeartRate;
  final int? hrvMs;
  final int? sleepMinutes;
  final String? sourceLabel;

  String _formatMinutes(int? minutes) {
    if (minutes == null) return '--';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return '${hours}h ${rem}m';
  }

  Color _recoveryColor(double recoveryPercent) {
    if (recoveryPercent >= 70) return Colors.green.shade700;
    if (recoveryPercent >= 40) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  String _recoveryStatus(double recoveryPercent) {
    if (recoveryPercent >= 70) return 'Recovered';
    if (recoveryPercent >= 40) return 'Caution';
    return 'Fatigued';
  }

  @override
  Widget build(BuildContext context) {
    final loadText =
        '${loadDeltaPercent >= 0 ? '+' : ''}${loadDeltaPercent.toStringAsFixed(1)}%';

    Widget sourceChip(String label, bool connected) {
      final color = connected ? Colors.green.shade700 : Colors.grey.shade600;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: connected ? 0.13 : 0.09),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.24)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      );
    }

    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recovery stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              sourceChip('Apple Health', connectionState.appleHealthConnected),
              sourceChip('Google Fit', connectionState.googleFitConnected),
              sourceChip('Apple Watch', connectionState.appleWatchConnected),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  title: 'Readiness',
                  value: '$readinessScore/100',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Avg recovery',
                  value:
                      averageRecoveryHours == null
                          ? '--'
                          : '${averageRecoveryHours!.toStringAsFixed(1)}h',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Rest-day adherence',
                  value: '$restDayAdherencePercent%',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  title: 'Resting HR',
                  value:
                      restingHeartRate == null
                          ? '-- bpm'
                          : '$restingHeartRate bpm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'HRV',
                  value: hrvMs == null ? '-- ms' : '$hrvMs ms',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Sleep',
                  value: _formatMinutes(sleepMinutes),
                ),
              ),
            ],
          ),
          if (muscleRecoveryScores.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Worked muscle recovery',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: muscleRecoveryScores
                  .map((score) {
                    final color = _recoveryColor(score.recoveryPercent);
                    final percent = score.recoveryPercent.toStringAsFixed(0);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: color.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Text(
                        '${score.muscle}: $percent% • ${_recoveryStatus(score.recoveryPercent)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  })
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Weekly training load: $loadText • $recoveryLabel${sourceLabel == null ? '' : ' • Source: $sourceLabel'}',
            style: TextStyle(
              color: Colors.grey.shade700,
              height: 1.35,
              fontSize: 12.5,
            ),
          ),
          if (!connectionState.anyConnected) ...[
            const SizedBox(height: 8),
            Text(
              'Health integrations are not linked yet. Once connected, readiness, sleep, HRV, and heart-rate recovery will sync automatically.',
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.35,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsistencySection extends StatelessWidget {
  const _ConsistencySection({
    required this.streakDays,
    required this.weeklyCompletionPercent,
    required this.trainingScore,
    required this.heatmapShades,
  });

  final int streakDays;
  final int weeklyCompletionPercent;
  final int trainingScore;
  final List<double> heatmapShades;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consistency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  title: 'Streak',
                  value: '$streakDays day${streakDays == 1 ? '' : 's'}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Weekly completion',
                  value: '$weeklyCompletionPercent%',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Training score',
                  value: '$trainingScore/100',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _HeatmapCalendar(shades: heatmapShades),
        ],
      ),
    );
  }
}

class _MuscleBalanceSection extends StatelessWidget {
  const _MuscleBalanceSection({
    required this.pushRatio,
    required this.pullRatio,
    required this.recoveryLabel,
  });

  final double pushRatio;
  final double pullRatio;
  final String recoveryLabel;

  @override
  Widget build(BuildContext context) {
    final ratioText =
        '${(pushRatio * 100).round()}/${(pullRatio * 100).round()}';
    final imbalance = (pushRatio - pullRatio).abs();
    final note =
        imbalance >= 0.14
            ? (pushRatio > pullRatio
                ? 'Pull workload is under target.'
                : 'Push workload is under target.')
            : 'Push/Pull balance is within range.';

    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muscle balance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _BalanceBar(label: 'Push', value: pushRatio),
          const SizedBox(height: 8),
          _BalanceBar(label: 'Pull', value: pullRatio),
          const SizedBox(height: 10),
          Text(
            'Push/Pull ratio: $ratioText. $note\n$recoveryLabel.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _ConditioningSection extends StatelessWidget {
  const _ConditioningSection({
    required this.pullupReps,
    required this.bodyweightReps,
    required this.conditioningDurationLabel,
  });

  final int pullupReps;
  final int bodyweightReps;
  final String conditioningDurationLabel;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bodyweight + conditioning',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStatTile(
                  title: 'Total pull-ups',
                  value: '$pullupReps',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Bodyweight reps',
                  value: '$bodyweightReps',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStatTile(
                  title: 'Conditioning',
                  value: conditioningDurationLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? kAccentColor.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? kAccentColor.withValues(alpha: 0.45)
                      : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? kAccentColor : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MachineStatRow extends StatelessWidget {
  const _MachineStatRow({
    required this.name,
    required this.gain,
    required this.period,
    required this.usage,
  });

  final String name;
  final String gain;
  final String period;
  final String usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              _kExercisePlaceholderImageUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade500,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '$gain over $period',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(usage, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: kAccentColor),
        ],
      ),
    );
  }
}

class _HeatmapCalendar extends StatelessWidget {
  const _HeatmapCalendar({required this.shades});

  final List<double> shades;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 5,
      runSpacing: 5,
      children: List.generate(shades.length, (index) {
        return Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: kAccentColor.withValues(alpha: shades[index]),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(0.0, 1.0).toDouble();
    final isPush = label.toLowerCase().contains('push');
    final fillGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors:
          isPush
              ? const [Color(0xFFF97316), Color(0xFFF59E0B)]
              : const [Color(0xFF0EA5E9), Color(0xFF22C55E)],
    );

    return Row(
      children: [
        SizedBox(
          width: 46,
          child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;
              final minVisibleFill = clampedValue > 0 ? 10.0 : 0.0;
              final fillWidth = math
                  .max(minVisibleFill, trackWidth * clampedValue)
                  .clamp(0.0, trackWidth);
              return Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: fillGradient,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(clampedValue * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({required this.series, required this.color});

  final List<double> series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.length < 2) return;
    final minValue = series.reduce(math.min);
    final maxValue = series.reduce(math.max);
    final valueRange = math.max(1.0, maxValue - minValue);

    final gridPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final y = (size.height - 8) * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint =
        Paint()
          ..color = color
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke;

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.04),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = <Offset>[];
    final stepX = size.width / (series.length - 1);
    for (var i = 0; i < series.length; i++) {
      final normalized = (series[i] - minValue) / valueRange;
      final y = (size.height - 8) - (normalized * (size.height - 16));
      points.add(Offset(stepX * i, y));
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final current = points[i];
      final control = Offset((prev.dx + current.dx) / 2, prev.dy);
      final control2 = Offset((prev.dx + current.dx) / 2, current.dy);
      linePath.cubicTo(
        control.dx,
        control.dy,
        control2.dx,
        control2.dy,
        current.dx,
        current.dy,
      );
    }

    final fillPath =
        Path.from(linePath)
          ..lineTo(points.last.dx, size.height)
          ..lineTo(points.first.dx, size.height)
          ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    if (oldDelegate.color != color) return true;
    if (oldDelegate.series.length != series.length) return true;
    for (var i = 0; i < series.length; i++) {
      if (oldDelegate.series[i] != series[i]) return true;
    }
    return false;
  }
}

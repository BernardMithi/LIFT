import 'dart:math' as math;

import 'package:lift/features/progress/leg_day_trends/leg_day_trends_models.dart';
import 'package:lift/shared/models/workout_template.dart';

class LegDayTrendsMockData {
  const LegDayTrendsMockData._();

  static const LegDayTrendsData sample = LegDayTrendsData(
    title: 'Leg Day Trends',
    subtitle: 'Track lower body progress, balance, and recovery over time.',
    rangeSnapshots: {
      LegDayTrendRange.sevenDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.sevenDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Mon', value: 4120),
              TrendPoint(label: 'Tue', value: 4280),
              TrendPoint(label: 'Wed', value: 4360),
              TrendPoint(label: 'Thu', value: 4510),
              TrendPoint(label: 'Fri', value: 4725),
              TrendPoint(label: 'Sat', value: 4860),
              TrendPoint(label: 'Sun', value: 4980),
            ],
            insight: 'Leg volume is up 7% over the last 7 days.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Mon', value: 78),
              TrendPoint(label: 'Tue', value: 80),
              TrendPoint(label: 'Wed', value: 81),
              TrendPoint(label: 'Thu', value: 84),
              TrendPoint(label: 'Fri', value: 88),
              TrendPoint(label: 'Sat', value: 90),
              TrendPoint(label: 'Sun', value: 92),
            ],
            insight:
                'Rep output is trending up without a drop in session pace.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Mon', value: 132),
              TrendPoint(label: 'Tue', value: 132),
              TrendPoint(label: 'Wed', value: 134),
              TrendPoint(label: 'Thu', value: 136),
              TrendPoint(label: 'Fri', value: 136),
              TrendPoint(label: 'Sat', value: 138),
              TrendPoint(label: 'Sun', value: 140),
            ],
            insight: 'Your heaviest lower-body set climbed 8kg this week.',
          ),
        },
      ),
      LegDayTrendRange.thirtyDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.thirtyDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: [
              TrendPoint(label: 'W1', value: 3840),
              TrendPoint(label: 'W2', value: 4015),
              TrendPoint(label: 'W3', value: 4280),
              TrendPoint(label: 'W4', value: 4470),
              TrendPoint(label: 'W5', value: 4790),
              TrendPoint(label: 'Now', value: 5150),
            ],
            insight: 'Leg volume is up 18% over the last 30 days.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: [
              TrendPoint(label: 'W1', value: 84),
              TrendPoint(label: 'W2', value: 89),
              TrendPoint(label: 'W3', value: 94),
              TrendPoint(label: 'W4', value: 98),
              TrendPoint(label: 'W5', value: 104),
              TrendPoint(label: 'Now', value: 109),
            ],
            insight:
                'Reps are building steadily, which usually signals better work capacity.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: [
              TrendPoint(label: 'W1', value: 130),
              TrendPoint(label: 'W2', value: 134),
              TrendPoint(label: 'W3', value: 136),
              TrendPoint(label: 'W4', value: 140),
              TrendPoint(label: 'W5', value: 143),
              TrendPoint(label: 'Now', value: 146),
            ],
            insight:
                'Your top set is trending upward while volume is still moving.',
          ),
        },
      ),
      LegDayTrendRange.ninetyDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.ninetyDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Jan', value: 3180),
              TrendPoint(label: 'Feb', value: 3370),
              TrendPoint(label: 'Mar', value: 3560),
              TrendPoint(label: 'Apr', value: 3890),
              TrendPoint(label: 'May', value: 4260),
              TrendPoint(label: 'Jun', value: 4710),
              TrendPoint(label: 'Now', value: 5150),
            ],
            insight:
                'Lower-body workload has climbed steadily across the quarter.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Jan', value: 70),
              TrendPoint(label: 'Feb', value: 74),
              TrendPoint(label: 'Mar', value: 81),
              TrendPoint(label: 'Apr', value: 89),
              TrendPoint(label: 'May', value: 97),
              TrendPoint(label: 'Jun', value: 103),
              TrendPoint(label: 'Now', value: 109),
            ],
            insight:
                'Rep quality and session density are moving in the right direction.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Jan', value: 118),
              TrendPoint(label: 'Feb', value: 124),
              TrendPoint(label: 'Mar', value: 129),
              TrendPoint(label: 'Apr', value: 134),
              TrendPoint(label: 'May', value: 138),
              TrendPoint(label: 'Jun', value: 142),
              TrendPoint(label: 'Now', value: 146),
            ],
            insight: 'Peak strength is building without a long plateau.',
          ),
        },
      ),
      LegDayTrendRange.custom: LegDayRangeSnapshot(
        range: LegDayTrendRange.custom,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Base', value: 3620),
              TrendPoint(label: 'Build', value: 4080),
              TrendPoint(label: 'Peak', value: 4525),
              TrendPoint(label: 'Deload', value: 3280),
              TrendPoint(label: 'Reload', value: 4385),
              TrendPoint(label: 'Push', value: 4970),
            ],
            insight: 'Your custom block shows a clean rebound after deload.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Base', value: 81),
              TrendPoint(label: 'Build', value: 86),
              TrendPoint(label: 'Peak', value: 93),
              TrendPoint(label: 'Deload', value: 74),
              TrendPoint(label: 'Reload', value: 95),
              TrendPoint(label: 'Push', value: 108),
            ],
            insight: 'Rep tolerance returned quickly once fatigue came down.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: [
              TrendPoint(label: 'Base', value: 126),
              TrendPoint(label: 'Build', value: 132),
              TrendPoint(label: 'Peak', value: 140),
              TrendPoint(label: 'Deload', value: 122),
              TrendPoint(label: 'Reload', value: 142),
              TrendPoint(label: 'Push', value: 148),
            ],
            insight: 'Your top set is strongest when the deload is respected.',
          ),
        },
      ),
    },
    keyLifts: [
      KeyLiftTrend(
        exerciseName: 'Hack Squat',
        bestRecentSet: '140kg x 8',
        changeKg: 12,
      ),
      KeyLiftTrend(
        exerciseName: 'Leg Press',
        bestRecentSet: '280kg x 10',
        changeKg: 20,
      ),
      KeyLiftTrend(
        exerciseName: 'Leg Curl',
        bestRecentSet: '68kg x 12',
        changeKg: 6,
      ),
      KeyLiftTrend(
        exerciseName: 'Leg Extension',
        bestRecentSet: '86kg x 12',
        changeKg: 4,
      ),
      KeyLiftTrend(
        exerciseName: 'Calf Raise',
        bestRecentSet: '120kg x 15',
        changeKg: 8,
      ),
    ],
    muscleBalance: MuscleBalanceSummary(
      distribution: [
        MuscleBalanceEntry(label: 'Quads', share: 0.38),
        MuscleBalanceEntry(label: 'Hamstrings', share: 0.19),
        MuscleBalanceEntry(label: 'Glutes', share: 0.27),
        MuscleBalanceEntry(label: 'Calves', share: 0.16),
      ],
      insight: 'Hamstrings are undertrained compared to quads.',
    ),
    recovery: RecoveryTrendsSummary(
      averageRecoveryDays: 3.2,
      averageDaysBetweenSessions: 2.4,
      currentState: RecoveryState.recovering,
      muscleStatuses: [
        MuscleRecoveryStatus(label: 'Quads', state: RecoveryState.fatigued),
        MuscleRecoveryStatus(
          label: 'Hamstrings',
          state: RecoveryState.recovering,
        ),
        MuscleRecoveryStatus(label: 'Glutes', state: RecoveryState.fresh),
        MuscleRecoveryStatus(label: 'Calves', state: RecoveryState.fresh),
      ],
      recommendation:
          'You may be training legs too frequently for your current load.',
    ),
    consistency: ConsistencySummary(
      sessionsThisMonth: 6,
      currentStreak: 4,
      missedSessions: 1,
    ),
    smartInsight: SmartInsightSummary(
      title: 'Smart insight',
      message:
          'Quad volume is progressing well, but hamstring work is lagging behind. Consider increasing leg curl or RDL volume in your next lower session.',
    ),
  );

  static LegDayTrendsData forTemplate(WorkoutTemplate template) {
    final targetMuscles = _resolvedFocusTags(template);
    final lowerBodyFocus = _isLowerBodyFocus(template, targetMuscles);
    final blockLabel = template.name.trim().isEmpty ? 'Workout' : template.name;
    final volumeBase = math.max(1800.0, _estimatedVolume(template));
    final repsBase = math.max(48.0, _estimatedReps(template).toDouble());
    final topSetBase = math.max(24.0, _topSetWeight(template));
    final weightedExercises = template.exercises
        .where((exercise) => exercise.presetRows.any((row) => row.weightKg > 0))
        .toList(growable: false);
    final keyLiftSource = (weightedExercises.isNotEmpty
            ? weightedExercises
            : template.exercises)
        .take(5)
        .toList(growable: false);
    final balance = _buildMuscleBalance(targetMuscles);
    final recovery = _buildRecovery(targetMuscles, template.durationMinutes);

    return LegDayTrendsData(
      title: '$blockLabel Trends',
      subtitle:
          'Track ${lowerBodyFocus ? 'lower body' : _focusPhrase(targetMuscles)} progress, balance, and recovery over time.',
      rangeSnapshots: _buildRangeSnapshots(
        blockLabel: blockLabel,
        volumeBase: volumeBase,
        repsBase: repsBase,
        topSetBase: topSetBase,
        lowerBodyFocus: lowerBodyFocus,
      ),
      keyLifts: [
        for (var index = 0; index < keyLiftSource.length; index += 1)
          _buildKeyLiftTrend(keyLiftSource[index], index),
      ],
      muscleBalance: balance,
      recovery: recovery,
      consistency: _buildConsistency(template),
      smartInsight: _buildSmartInsight(
        template: template,
        targetMuscles: targetMuscles,
        balance: balance,
      ),
    );
  }

  static Map<LegDayTrendRange, LegDayRangeSnapshot> _buildRangeSnapshots({
    required String blockLabel,
    required double volumeBase,
    required double repsBase,
    required double topSetBase,
    required bool lowerBodyFocus,
  }) {
    final workloadLabel = lowerBodyFocus ? 'Lower-body' : blockLabel;
    return {
      LegDayTrendRange.sevenDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.sevenDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: _points(
              labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              base: volumeBase,
              multipliers: const [0.84, 0.87, 0.89, 0.92, 0.95, 0.98, 1.0],
            ),
            insight: '$workloadLabel volume is up 7% over the last 7 days.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: _points(
              labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              base: repsBase,
              multipliers: const [0.84, 0.87, 0.90, 0.93, 0.96, 0.98, 1.0],
            ),
            insight:
                'Rep output is trending up without a visible drop in session quality.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: _points(
              labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
              base: topSetBase,
              multipliers: const [0.92, 0.93, 0.94, 0.96, 0.97, 0.99, 1.0],
            ),
            insight:
                'Your top set is nudging up while the rest of the session still looks stable.',
          ),
        },
      ),
      LegDayTrendRange.thirtyDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.thirtyDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: _points(
              labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'Now'],
              base: volumeBase,
              multipliers: const [0.76, 0.80, 0.85, 0.89, 0.94, 1.0],
            ),
            insight: '$workloadLabel volume is up 18% over the last 30 days.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: _points(
              labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'Now'],
              base: repsBase,
              multipliers: const [0.77, 0.82, 0.87, 0.91, 0.96, 1.0],
            ),
            insight:
                'Work capacity is building steadily, which usually shows up first in rep quality.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: _points(
              labels: const ['W1', 'W2', 'W3', 'W4', 'W5', 'Now'],
              base: topSetBase,
              multipliers: const [0.88, 0.91, 0.94, 0.96, 0.98, 1.0],
            ),
            insight:
                'Top-end loading is progressing without flattening the rest of the block.',
          ),
        },
      ),
      LegDayTrendRange.ninetyDays: LegDayRangeSnapshot(
        range: LegDayTrendRange.ninetyDays,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: _points(
              labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Now'],
              base: volumeBase,
              multipliers: const [0.62, 0.69, 0.74, 0.81, 0.89, 0.95, 1.0],
            ),
            insight:
                '$workloadLabel workload has climbed steadily across the quarter.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: _points(
              labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Now'],
              base: repsBase,
              multipliers: const [0.66, 0.71, 0.77, 0.84, 0.90, 0.95, 1.0],
            ),
            insight:
                'Rep tolerance is trending in the right direction with no long plateau.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: _points(
              labels: const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Now'],
              base: topSetBase,
              multipliers: const [0.80, 0.84, 0.88, 0.92, 0.95, 0.98, 1.0],
            ),
            insight: 'Peak output keeps moving without a long stall.',
          ),
        },
      ),
      LegDayTrendRange.custom: LegDayRangeSnapshot(
        range: LegDayTrendRange.custom,
        metricSeries: {
          LegDayTrendMetric.volume: MetricTrendSeries(
            points: _points(
              labels: const [
                'Base',
                'Build',
                'Peak',
                'Deload',
                'Reload',
                'Push',
              ],
              base: volumeBase,
              multipliers: const [0.72, 0.80, 0.90, 0.68, 0.92, 1.0],
            ),
            insight:
                'Your custom block shows a clean rebound after fatigue drops.',
          ),
          LegDayTrendMetric.reps: MetricTrendSeries(
            points: _points(
              labels: const [
                'Base',
                'Build',
                'Peak',
                'Deload',
                'Reload',
                'Push',
              ],
              base: repsBase,
              multipliers: const [0.74, 0.81, 0.89, 0.70, 0.93, 1.0],
            ),
            insight:
                'Rep tolerance returned quickly once the middle of the block eased off.',
          ),
          LegDayTrendMetric.topSet: MetricTrendSeries(
            points: _points(
              labels: const [
                'Base',
                'Build',
                'Peak',
                'Deload',
                'Reload',
                'Push',
              ],
              base: topSetBase,
              multipliers: const [0.84, 0.89, 0.95, 0.80, 0.97, 1.0],
            ),
            insight:
                'Your heaviest work tends to show up once the deload is respected.',
          ),
        },
      ),
    };
  }

  static List<TrendPoint> _points({
    required List<String> labels,
    required double base,
    required List<double> multipliers,
  }) {
    return [
      for (var index = 0; index < labels.length; index += 1)
        TrendPoint(label: labels[index], value: base * multipliers[index]),
    ];
  }

  static KeyLiftTrend _buildKeyLiftTrend(
    WorkoutTemplateExercise exercise,
    int index,
  ) {
    WorkoutTemplateSetRow bestRow =
        exercise.presetRows.isNotEmpty
            ? exercise.presetRows.first
            : const WorkoutTemplateSetRow(
              label: '1',
              reps: 10,
              weightKg: 0,
              restSeconds: 60,
            );
    for (final row in exercise.presetRows) {
      if (row.weightKg > bestRow.weightKg ||
          (row.weightKg == bestRow.weightKg && row.reps > bestRow.reps)) {
        bestRow = row;
      }
    }

    final bestRecentSet =
        bestRow.weightKg > 0
            ? '${_formatNumber(bestRow.weightKg)}kg x ${bestRow.reps}'
            : '${math.max(exercise.estimatedMinutes, bestRow.reps)} reps';
    final changeKg =
        bestRow.weightKg > 0
            ? math.max(
              2.0,
              double.parse(
                (bestRow.weightKg * (0.05 + (index * 0.01))).toStringAsFixed(1),
              ),
            )
            : 0.0;

    return KeyLiftTrend(
      exerciseName: exercise.name,
      bestRecentSet: bestRecentSet,
      changeKg: changeKg,
    );
  }

  static MuscleBalanceSummary _buildMuscleBalance(List<String> targetMuscles) {
    final safeMuscles =
        targetMuscles.isEmpty ? const ['Primary focus'] : targetMuscles;
    final baseWeights = <double>[1.0, 0.82, 0.68, 0.54, 0.42];
    final usedWeights = baseWeights
        .take(safeMuscles.length)
        .toList(growable: false);
    final weightTotal = usedWeights.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final distribution = <MuscleBalanceEntry>[
      for (var index = 0; index < safeMuscles.length; index += 1)
        MuscleBalanceEntry(
          label: safeMuscles[index],
          share: usedWeights[index] / weightTotal,
        ),
    ];

    final primary = distribution.first.label.toLowerCase();
    final insight =
        distribution.length > 1
            ? '${_capitalize(distribution.last.label)} work is lagging behind $primary volume.'
            : '${_capitalize(distribution.first.label)} is carrying most of this block right now.';

    return MuscleBalanceSummary(distribution: distribution, insight: insight);
  }

  static RecoveryTrendsSummary _buildRecovery(
    List<String> targetMuscles,
    int durationMinutes,
  ) {
    final safeMuscles =
        targetMuscles.isEmpty ? const ['Primary focus'] : targetMuscles;
    final statuses = <MuscleRecoveryStatus>[
      for (var index = 0; index < safeMuscles.length; index += 1)
        MuscleRecoveryStatus(
          label: safeMuscles[index],
          state:
              index == 0
                  ? RecoveryState.fatigued
                  : index == 1
                  ? RecoveryState.recovering
                  : RecoveryState.fresh,
        ),
    ];
    final averageRecoveryDays = double.parse(
      (1.8 + (durationMinutes / 45) + (safeMuscles.length * 0.18))
          .clamp(1.8, 4.8)
          .toStringAsFixed(1),
    );
    final averageDaysBetweenSessions = double.parse(
      (averageRecoveryDays - 0.7).clamp(1.4, 4.0).toStringAsFixed(1),
    );

    return RecoveryTrendsSummary(
      averageRecoveryDays: averageRecoveryDays,
      averageDaysBetweenSessions: averageDaysBetweenSessions,
      currentState: RecoveryState.recovering,
      muscleStatuses: statuses,
      recommendation:
          averageDaysBetweenSessions < averageRecoveryDays
              ? 'You may be revisiting this block before the main target area is fully recovered.'
              : 'Recovery timing looks well matched to the load in this block right now.',
    );
  }

  static ConsistencySummary _buildConsistency(WorkoutTemplate template) {
    final sessionsThisMonth =
        (4 +
                math.min(template.exercises.length, 3) +
                (template.durationMinutes >= 55 ? 1 : 0))
            .clamp(4, 8)
            .toInt();
    final currentStreak = math.max(
      1,
      math.min(5, (sessionsThisMonth / 2).round()),
    );
    final missedSessions =
        template.durationMinutes >= 70
            ? 1
            : template.exercises.length >= 4
            ? 1
            : 0;

    return ConsistencySummary(
      sessionsThisMonth: sessionsThisMonth,
      currentStreak: currentStreak,
      missedSessions: missedSessions,
    );
  }

  static SmartInsightSummary _buildSmartInsight({
    required WorkoutTemplate template,
    required List<String> targetMuscles,
    required MuscleBalanceSummary balance,
  }) {
    final focusLead =
        targetMuscles.isNotEmpty ? targetMuscles.first : template.name;
    final lagging =
        balance.distribution.length > 1
            ? balance.distribution.last.label
            : focusLead;
    final firstExercise =
        template.exercises.isNotEmpty
            ? template.exercises.first.name
            : template.name;

    return SmartInsightSummary(
      title: 'Smart insight',
      message:
          '${_capitalize(focusLead)} output is progressing well, but $lagging work is still a step behind. Consider adding one more focused hard set or pushing ${firstExercise.toLowerCase()} harder in your next ${template.name.toLowerCase()} session.',
    );
  }

  static List<String> _resolvedFocusTags(WorkoutTemplate template) {
    final cleaned = <String>[];
    final seen = <String>{};

    void addLabel(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        cleaned.add(_capitalize(trimmed));
      }
    }

    for (final tag in template.focusTags) {
      addLabel(tag);
    }

    if (cleaned.isNotEmpty) return cleaned;

    final name = template.name.toLowerCase();
    if (name.contains('leg') || name.contains('lower')) {
      return const ['Quads', 'Hamstrings', 'Glutes', 'Calves'];
    }
    if (name.contains('push')) {
      return const ['Chest', 'Shoulders', 'Triceps'];
    }
    if (name.contains('pull')) {
      return const ['Back', 'Biceps', 'Forearms'];
    }
    if (name.contains('core') ||
        name.contains('cardio') ||
        name.contains('conditioning')) {
      return const ['Core', 'Conditioning'];
    }
    return const ['Primary focus'];
  }

  static bool _isLowerBodyFocus(
    WorkoutTemplate template,
    List<String> targetMuscles,
  ) {
    const lowerBodyTags = <String>{'quads', 'hamstrings', 'glutes', 'calves'};
    if (targetMuscles.isNotEmpty &&
        targetMuscles.every(
          (muscle) => lowerBodyTags.contains(muscle.toLowerCase()),
        )) {
      return true;
    }
    final name = template.name.toLowerCase();
    return name.contains('leg') || name.contains('lower');
  }

  static double _estimatedVolume(WorkoutTemplate template) {
    var total = 0.0;
    for (final exercise in template.exercises) {
      for (final row in exercise.presetRows) {
        if (row.weightKg <= 0) continue;
        total += row.weightKg * row.reps;
      }
    }
    if (total > 0) return total;
    return template.durationMinutes *
        math.max(template.exercises.length, 1) *
        42;
  }

  static int _estimatedReps(WorkoutTemplate template) {
    var total = 0;
    for (final exercise in template.exercises) {
      for (final row in exercise.presetRows) {
        total += row.reps;
      }
    }
    return total > 0 ? total : math.max(24, template.exercises.length * 18);
  }

  static double _topSetWeight(WorkoutTemplate template) {
    var topSet = 0.0;
    for (final exercise in template.exercises) {
      for (final row in exercise.presetRows) {
        topSet = math.max(topSet, row.weightKg);
      }
    }
    return topSet > 0 ? topSet : template.durationMinutes.toDouble();
  }

  static String _focusPhrase(List<String> targetMuscles) {
    if (targetMuscles.isEmpty) return 'training';
    if (targetMuscles.length == 1) return targetMuscles.first.toLowerCase();
    if (targetMuscles.length == 2) {
      return '${targetMuscles[0].toLowerCase()} and ${targetMuscles[1].toLowerCase()}';
    }
    final visible =
        targetMuscles.take(3).map((muscle) => muscle.toLowerCase()).toList();
    return '${visible[0]}, ${visible[1]}, and ${visible[2]}';
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  static String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }
}

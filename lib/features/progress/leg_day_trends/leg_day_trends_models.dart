enum LegDayTrendRange {
  sevenDays('7D'),
  thirtyDays('30D'),
  ninetyDays('90D'),
  custom('Custom');

  const LegDayTrendRange(this.label);

  final String label;
}

enum LegDayTrendMetric {
  volume('Volume'),
  reps('Reps'),
  topSet('Top Set');

  const LegDayTrendMetric(this.label);

  final String label;
}

enum RecoveryState {
  fresh('Fresh'),
  recovering('Recovering'),
  fatigued('Fatigued');

  const RecoveryState(this.label);

  final String label;
}

class MuscleRecoveryStatus {
  const MuscleRecoveryStatus({required this.label, required this.state});

  final String label;
  final RecoveryState state;
}

class LegDayTrendsData {
  const LegDayTrendsData({
    required this.title,
    required this.subtitle,
    required this.rangeSnapshots,
    required this.keyLifts,
    required this.muscleBalance,
    required this.recovery,
    required this.consistency,
    required this.smartInsight,
  });

  final String title;
  final String subtitle;
  final Map<LegDayTrendRange, LegDayRangeSnapshot> rangeSnapshots;
  final List<KeyLiftTrend> keyLifts;
  final MuscleBalanceSummary muscleBalance;
  final RecoveryTrendsSummary recovery;
  final ConsistencySummary consistency;
  final SmartInsightSummary smartInsight;

  LegDayRangeSnapshot snapshotFor(LegDayTrendRange range) {
    return rangeSnapshots[range]!;
  }
}

class LegDayRangeSnapshot {
  const LegDayRangeSnapshot({required this.range, required this.metricSeries});

  final LegDayTrendRange range;
  final Map<LegDayTrendMetric, MetricTrendSeries> metricSeries;

  MetricTrendSeries seriesFor(LegDayTrendMetric metric) {
    return metricSeries[metric]!;
  }
}

class MetricTrendSeries {
  const MetricTrendSeries({required this.points, required this.insight});

  final List<TrendPoint> points;
  final String insight;
}

class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class KeyLiftTrend {
  const KeyLiftTrend({
    required this.exerciseName,
    required this.bestRecentSet,
    required this.changeKg,
  });

  final String exerciseName;
  final String bestRecentSet;
  final double changeKg;
}

class MuscleBalanceSummary {
  const MuscleBalanceSummary({
    required this.distribution,
    required this.insight,
  });

  final List<MuscleBalanceEntry> distribution;
  final String insight;
}

class MuscleBalanceEntry {
  const MuscleBalanceEntry({required this.label, required this.share});

  final String label;
  final double share;
}

class RecoveryTrendsSummary {
  const RecoveryTrendsSummary({
    required this.averageRecoveryDays,
    required this.averageDaysBetweenSessions,
    required this.currentState,
    required this.muscleStatuses,
    required this.recommendation,
  });

  final double averageRecoveryDays;
  final double averageDaysBetweenSessions;
  final RecoveryState currentState;
  final List<MuscleRecoveryStatus> muscleStatuses;
  final String recommendation;
}

class ConsistencySummary {
  const ConsistencySummary({
    required this.sessionsThisMonth,
    required this.currentStreak,
    required this.missedSessions,
  });

  final int sessionsThisMonth;
  final int currentStreak;
  final int missedSessions;
}

class SmartInsightSummary {
  const SmartInsightSummary({required this.title, required this.message});

  final String title;
  final String message;
}

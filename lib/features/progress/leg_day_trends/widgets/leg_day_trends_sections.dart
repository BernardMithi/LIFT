import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/progress/leg_day_trends/leg_day_trends_models.dart';
import 'package:lift/features/progress/leg_day_trends/widgets/leg_day_trends_chart.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/shared/widgets/lower_body_mannequin_panel.dart';
import 'package:lift/shared/widgets/workout_target_mannequin_panel.dart';
import 'package:lift/shared/widgets/surfaces.dart';

class LegDayTrendsHeader extends StatelessWidget {
  const LegDayTrendsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.leadingInset = 62,
  });

  final String title;
  final String subtitle;
  final double leadingInset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: leadingInset),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    height: 1.02,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class LegDayRangeSelector extends StatelessWidget {
  const LegDayRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onChanged,
    required this.accentColor,
  });

  final LegDayTrendRange selectedRange;
  final ValueChanged<LegDayTrendRange> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LegDayTrendRange.values
          .map((range) {
            final isSelected = range == selectedRange;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: range == LegDayTrendRange.custom ? 0 : 8,
                ),
                child: _SelectorPill(
                  label: range.label,
                  selected: isSelected,
                  accentColor: accentColor,
                  onTap: () => onChanged(range),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class TargetMusclesCard extends StatelessWidget {
  const TargetMusclesCard({
    super.key,
    required this.targetMuscles,
    required this.muscleStatuses,
    required this.bodyType,
    required this.accentColor,
    this.subtitle =
        'Front and back view of the main muscles this block is driving.',
  });

  final List<String> targetMuscles;
  final List<MuscleRecoveryStatus> muscleStatuses;
  final LowerBodyMannequinBodyType bodyType;
  final Color accentColor;
  final String subtitle;

  LowerBodyHighlightState _stateForRecovery(RecoveryState state) {
    switch (state) {
      case RecoveryState.fresh:
        return LowerBodyHighlightState.recovered;
      case RecoveryState.recovering:
        return LowerBodyHighlightState.mid;
      case RecoveryState.fatigued:
        return LowerBodyHighlightState.fatigued;
    }
  }

  int _statePriority(LowerBodyHighlightState state) {
    switch (state) {
      case LowerBodyHighlightState.recovered:
        return 0;
      case LowerBodyHighlightState.mid:
        return 1;
      case LowerBodyHighlightState.fatigued:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightedRegions = lowerBodyRegionsForLabels(targetMuscles);
    final regionStates = <LowerBodyRegion, LowerBodyHighlightState>{};

    for (final status in muscleStatuses) {
      final nextState = _stateForRecovery(status.state);
      for (final region in lowerBodyRegionsForLabels([status.label])) {
        final current = regionStates[region];
        if (current == null ||
            _statePriority(nextState) >= _statePriority(current)) {
          regionStates[region] = nextState;
        }
      }
    }

    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(title: 'Target map', subtitle: subtitle),
          const SizedBox(height: 14),
          SizedBox(
            height: 268,
            child: LowerBodyMannequinPanel(
              highlightedRegions: highlightedRegions,
              bodyType: bodyType,
              highlightColor: accentColor,
              regionStates: regionStates,
              pulsateHighlights: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final muscle in targetMuscles)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(kIosChipRadius),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor.withValues(alpha: 0.92),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorkoutFocusCard extends StatelessWidget {
  const WorkoutFocusCard({
    super.key,
    required this.targetMuscles,
    required this.muscleStatuses,
    required this.bodyType,
    required this.accentColor,
  });

  final List<String> targetMuscles;
  final List<MuscleRecoveryStatus> muscleStatuses;
  final LowerBodyMannequinBodyType bodyType;
  final Color accentColor;

  WorkoutTargetHighlightState _stateForRecovery(RecoveryState state) {
    switch (state) {
      case RecoveryState.fresh:
        return WorkoutTargetHighlightState.recovered;
      case RecoveryState.recovering:
        return WorkoutTargetHighlightState.mid;
      case RecoveryState.fatigued:
        return WorkoutTargetHighlightState.fatigued;
    }
  }

  int _statePriority(WorkoutTargetHighlightState state) {
    switch (state) {
      case WorkoutTargetHighlightState.recovered:
        return 0;
      case WorkoutTargetHighlightState.mid:
        return 1;
      case WorkoutTargetHighlightState.fatigued:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightedRegions = workoutTargetRegionsForLabels(targetMuscles);
    final regionStates = <WorkoutTargetRegion, WorkoutTargetHighlightState>{};

    for (final status in muscleStatuses) {
      final nextState = _stateForRecovery(status.state);
      for (final region in workoutTargetRegionsForLabels([status.label])) {
        final current = regionStates[region];
        if (current == null ||
            _statePriority(nextState) >= _statePriority(current)) {
          regionStates[region] = nextState;
        }
      }
    }

    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Target map',
            subtitle:
                'Front and back view of the main muscles this block is driving.',
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 268,
            child: WorkoutTargetMannequinPanel(
              highlightedRegions: highlightedRegions,
              bodyType: bodyType,
              highlightColor: accentColor,
              regionStates: regionStates,
              pulsateHighlights: true,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final muscle in targetMuscles)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(kIosChipRadius),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Text(
                    muscle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accentColor.withValues(alpha: 0.90),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrimaryTrendCard extends StatelessWidget {
  const PrimaryTrendCard({
    super.key,
    required this.snapshot,
    required this.selectedMetric,
    required this.onMetricChanged,
    required this.accentColor,
  });

  final LegDayRangeSnapshot snapshot;
  final LegDayTrendMetric selectedMetric;
  final ValueChanged<LegDayTrendMetric> onMetricChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final series = snapshot.seriesFor(selectedMetric);
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Performance',
            subtitle: 'Main output across this block over time.',
          ),
          const SizedBox(height: 14),
          _MetricSelector(
            selectedMetric: selectedMetric,
            onChanged: onMetricChanged,
            accentColor: accentColor,
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 232,
            child: LegDayTrendChart(
              series: series,
              metric: selectedMetric,
              accentColor: accentColor,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(kIosControlRadius),
              border: Border.all(color: accentColor.withValues(alpha: 0.14)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MynauiIcon(MynauiGlyphs.courseUp, size: 18, color: accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    series.insight,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KeyLiftsCard extends StatelessWidget {
  const KeyLiftsCard({super.key, required this.keyLifts});

  final List<KeyLiftTrend> keyLifts;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Key lifts',
            subtitle:
                'Best recent sets across the main movements in this block.',
          ),
          const SizedBox(height: 12),
          ...keyLifts.asMap().entries.map((entry) {
            final index = entry.key;
            final lift = entry.value;
            return Column(
              children: [
                _KeyLiftRow(lift: lift),
                if (index != keyLifts.length - 1)
                  Divider(
                    height: 22,
                    thickness: 1,
                    color: Theme.of(context).dividerTheme.color,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class MuscleBalanceCard extends StatelessWidget {
  const MuscleBalanceCard({
    super.key,
    required this.summary,
    required this.accentColor,
  });

  final MuscleBalanceSummary summary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Muscle balance',
            subtitle:
                'Distribution across the primary target muscles in this block.',
          ),
          const SizedBox(height: 12),
          ...summary.distribution.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MuscleBalanceRow(entry: entry, accentColor: accentColor),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(kIosControlRadius),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              summary.insight,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecoveryTrendsCard extends StatelessWidget {
  const RecoveryTrendsCard({super.key, required this.summary});

  final RecoveryTrendsSummary summary;

  @override
  Widget build(BuildContext context) {
    final stateColor = _recoveryStateColor(summary.currentState);
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Recovery trends',
            subtitle:
                'How well this target area is bouncing back between sessions.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrendStatTile(
                  title: 'Average recovery',
                  value:
                      '${summary.averageRecoveryDays.toStringAsFixed(1)} days',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendStatTile(
                  title: 'Time between sessions',
                  value:
                      '${summary.averageDaysBetweenSessions.toStringAsFixed(1)} days',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendStatTile(
                  title: 'Current state',
                  value: summary.currentState.label,
                  valueColor: stateColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(kIosControlRadius),
              border: Border.all(color: stateColor.withValues(alpha: 0.18)),
            ),
            child: Text(
              summary.recommendation,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConsistencyCard extends StatelessWidget {
  const ConsistencyCard({super.key, required this.summary});

  final ConsistencySummary summary;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            title: 'Consistency',
            subtitle:
                'How consistently this workout is showing up in your month.',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TrendStatTile(
                  title: 'Sessions this month',
                  value: '${summary.sessionsThisMonth}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendStatTile(
                  title: 'Current streak',
                  value: '${summary.currentStreak}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TrendStatTile(
                  title: 'Missed sessions',
                  value: '${summary.missedSessions}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SmartInsightsCard extends StatelessWidget {
  const SmartInsightsCard({
    super.key,
    required this.summary,
    required this.accentColor,
  });

  final SmartInsightSummary summary;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: kIosCornerRadius,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accentColor.withValues(alpha: 0.16)),
            ),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: 20,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  summary.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SelectorPill extends StatelessWidget {
  const _SelectorPill({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kIosControlRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? accentColor : Colors.white,
            borderRadius: BorderRadius.circular(kIosControlRadius),
            border: Border.all(
              color:
                  selected
                      ? accentColor
                      : const Color(0xFF171717).withValues(alpha: 0.10),
            ),
            boxShadow:
                selected
                    ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ]
                    : const [],
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade700,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({
    required this.selectedMetric,
    required this.onChanged,
    required this.accentColor,
  });

  final LegDayTrendMetric selectedMetric;
  final ValueChanged<LegDayTrendMetric> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(kIosControlRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: LegDayTrendMetric.values
            .map((metric) {
              final selected = metric == selectedMetric;
              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onChanged(metric),
                    borderRadius: BorderRadius.circular(kIosChipRadius),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? accentColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(kIosChipRadius),
                      ),
                      child: Center(
                        child: Text(
                          metric.label,
                          style: TextStyle(
                            color:
                                selected ? Colors.white : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _KeyLiftRow extends StatelessWidget {
  const _KeyLiftRow({required this.lift});

  final KeyLiftTrend lift;

  @override
  Widget build(BuildContext context) {
    final changeText =
        '${lift.changeKg >= 0 ? '+' : ''}${lift.changeKg.toStringAsFixed(lift.changeKg.abs() < 10 ? 1 : 0)}kg';
    final deltaColor =
        lift.changeKg >= 0 ? const Color(0xFF2E6D5A) : const Color(0xFF8C5454);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lift.exerciseName,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lift.bestRecentSet,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: deltaColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(kIosChipRadius),
            border: Border.all(color: deltaColor.withValues(alpha: 0.18)),
          ),
          child: Text(
            changeText,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: deltaColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _MuscleBalanceRow extends StatelessWidget {
  const _MuscleBalanceRow({required this.entry, required this.accentColor});

  final MuscleBalanceEntry entry;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final fillColor = accentColor.withValues(
      alpha: (0.35 + (entry.share * 0.9)).clamp(0.35, 1.0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              entry.label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
            const Spacer(),
            Text(
              '${(entry.share * 100).round()}%',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: entry.share,
            minHeight: 10,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(fillColor),
          ),
        ),
      ],
    );
  }
}

class _TrendStatTile extends StatelessWidget {
  const _TrendStatTile({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(kIosControlRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: valueColor ?? const Color(0xFF171717),
            ),
          ),
        ],
      ),
    );
  }
}

Color _recoveryStateColor(RecoveryState state) {
  return switch (state) {
    RecoveryState.fresh => const Color(0xFF2E6D5A),
    RecoveryState.recovering => const Color(0xFF6B6654),
    RecoveryState.fatigued => const Color(0xFF8C5454),
  };
}

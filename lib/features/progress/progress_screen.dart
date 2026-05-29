import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/features/settings/settings_screen.dart';
import 'package:lift/features/progress/workout_history_detail_page.dart';
import 'package:lift/shared/exercise_demo_images.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/services/health_sync_service.dart';
import 'package:lift/shared/widgets/lift_floating_island.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/lift_pressable.dart';
import 'package:lift/shared/widgets/scroll_linked_top_blur_scrim.dart';
import 'package:lift/shared/widgets/surfaces.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _ProgressRange { week, month, quarter, custom }

enum _ProgressMetric { volume, reps, duration }

enum _ProgressSectionId {
  trainingScore,
  recovery,
  activity,
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
      _ProgressSectionId.trainingScore,
      _ProgressSectionId.recovery,
      _ProgressSectionId.activity,
      _ProgressSectionId.insight,
      _ProgressSectionId.performance,
      _ProgressSectionId.machineAnalytics,
      _ProgressSectionId.exerciseAssessments,
      _ProgressSectionId.consistency,
      _ProgressSectionId.muscleBalance,
      _ProgressSectionId.conditioning,
    ];

const List<_ProgressSectionId> _kRecoveryFocusSectionOrder =
    <_ProgressSectionId>[
      _ProgressSectionId.recovery,
      _ProgressSectionId.muscleBalance,
    ];

const String _kProgressSectionOrderStorageKey = 'progress_section_order_v1';
const String _kProgressVisibleSectionsStorageKey =
    'progress_visible_sections_v1';

const Color kProgressCanvasColor = Color(0xFFF2F2F7);

class ProgressArrangeController {
  VoidCallback? _showAddTileSheet;
  VoidCallback? _exitArrangeMode;

  void bind({
    required VoidCallback showAddTileSheet,
    required VoidCallback exitArrangeMode,
  }) {
    _showAddTileSheet = showAddTileSheet;
    _exitArrangeMode = exitArrangeMode;
  }

  void unbind() {
    _showAddTileSheet = null;
    _exitArrangeMode = null;
  }

  bool showAddTileSheet() {
    final callback = _showAddTileSheet;
    if (callback == null) return false;
    callback();
    return true;
  }

  bool exitArrangeMode() {
    final callback = _exitArrangeMode;
    if (callback == null) return false;
    callback();
    return true;
  }
}

extension _ProgressSectionIdUi on _ProgressSectionId {
  String get label {
    switch (this) {
      case _ProgressSectionId.trainingScore:
        return 'Training score';
      case _ProgressSectionId.recovery:
        return 'Recovery stats';
      case _ProgressSectionId.activity:
        return 'Activity';
      case _ProgressSectionId.insight:
        return 'Smart insight';
      case _ProgressSectionId.performance:
        return 'Performance';
      case _ProgressSectionId.machineAnalytics:
        return 'Machine analytics';
      case _ProgressSectionId.exerciseAssessments:
        return 'Exercise trends';
      case _ProgressSectionId.consistency:
        return 'Consistency';
      case _ProgressSectionId.muscleBalance:
        return 'Muscle balance';
      case _ProgressSectionId.conditioning:
        return 'Bodyweight + conditioning';
    }
  }

  String get subtitle {
    switch (this) {
      case _ProgressSectionId.trainingScore:
        return 'Score breakdown and confidence.';
      case _ProgressSectionId.recovery:
        return 'Readiness, health data, and recovery.';
      case _ProgressSectionId.activity:
        return 'Completed workouts and recent sessions.';
      case _ProgressSectionId.insight:
        return 'AI-style coaching summary for this range.';
      case _ProgressSectionId.performance:
        return 'Trend chart across the selected metric.';
      case _ProgressSectionId.machineAnalytics:
        return 'Strength progress across your top machines.';
      case _ProgressSectionId.exerciseAssessments:
        return 'Session-by-session movement trends.';
      case _ProgressSectionId.consistency:
        return 'Streak, completion, and heatmap activity.';
      case _ProgressSectionId.muscleBalance:
        return 'Push/pull workload distribution.';
      case _ProgressSectionId.conditioning:
        return 'Bodyweight work and conditioning output.';
    }
  }

  IconData get icon {
    switch (this) {
      case _ProgressSectionId.trainingScore:
        return Icons.stacked_line_chart_rounded;
      case _ProgressSectionId.recovery:
        return Icons.favorite_outline_rounded;
      case _ProgressSectionId.activity:
        return Icons.history_rounded;
      case _ProgressSectionId.insight:
        return Icons.auto_awesome_rounded;
      case _ProgressSectionId.performance:
        return Icons.show_chart_rounded;
      case _ProgressSectionId.machineAnalytics:
        return Icons.fitness_center_rounded;
      case _ProgressSectionId.exerciseAssessments:
        return Icons.insights_rounded;
      case _ProgressSectionId.consistency:
        return Icons.calendar_month_rounded;
      case _ProgressSectionId.muscleBalance:
        return Icons.balance_rounded;
      case _ProgressSectionId.conditioning:
        return Icons.directions_run_rounded;
    }
  }
}

_ProgressSectionId? _progressSectionIdFromName(String raw) {
  for (final value in _ProgressSectionId.values) {
    if (value.name == raw) return value;
  }
  return null;
}

Color _trainingScoreAccentColor(int score) {
  return _scoreSignalColor(score / 100);
}

Color _scoreSignalColor(double ratio) {
  final normalized = ratio.clamp(0.0, 1.0);
  if (normalized >= 0.75) return Colors.green.shade700;
  if (normalized >= 0.45) return Colors.orange.shade700;
  return Colors.red.shade600;
}

String _trainingScoreStatus(int score) {
  if (score >= 80) return 'Strong momentum';
  if (score >= 65) return 'Building well';
  if (score >= 50) return 'Needs consistency';
  return 'Reset and recover';
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({
    super.key,
    this.extraBottomInset = 0,
    this.history = const <WorkoutHistoryEntry>[],
    this.onArrangeModeChanged,
    this.onLeadingTap,
    this.arrangeController,
    this.headerTitle,
    this.showBack = false,
    this.showProfileAction = true,
    this.onProfileTap,
    this.recoveryFocusMode = false,
  });

  final double extraBottomInset;
  final List<WorkoutHistoryEntry> history;
  final ValueChanged<bool>? onArrangeModeChanged;
  final VoidCallback? onLeadingTap;
  final ProgressArrangeController? arrangeController;
  final String? headerTitle;
  final bool showBack;
  final bool showProfileAction;
  final VoidCallback? onProfileTap;
  final bool recoveryFocusMode;

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
  late Set<_ProgressSectionId> _visibleSections;
  late final AnimationController _jiggleController;
  final ScrollController _progressScrollController = ScrollController();
  final Map<_ProgressSectionId, GlobalKey> _sectionKeys =
      <_ProgressSectionId, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _jiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 190),
    );
    final initialSections =
        widget.recoveryFocusMode
            ? _kRecoveryFocusSectionOrder
            : _kDefaultProgressSectionOrder;
    _sectionOrder = List<_ProgressSectionId>.from(initialSections);
    _visibleSections = initialSections.toSet();
    widget.arrangeController?.bind(
      showAddTileSheet: _showAddSectionSheet,
      exitArrangeMode: _exitReorderMode,
    );
    if (!widget.recoveryFocusMode) {
      _loadSectionLayout();
    }
  }

  @override
  void didUpdateWidget(covariant ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.arrangeController != widget.arrangeController) {
      oldWidget.arrangeController?.unbind();
      widget.arrangeController?.bind(
        showAddTileSheet: _showAddSectionSheet,
        exitArrangeMode: _exitReorderMode,
      );
    }
  }

  @override
  void dispose() {
    if (_isReorderMode) {
      widget.onArrangeModeChanged?.call(false);
    }
    widget.arrangeController?.unbind();
    _jiggleController.dispose();
    _progressScrollController.dispose();
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

  Future<void> _loadSectionLayout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawOrder = prefs.getStringList(_kProgressSectionOrderStorageKey);
      final rawVisible = prefs.getStringList(
        _kProgressVisibleSectionsStorageKey,
      );
      if (rawOrder == null && rawVisible == null) return;

      final normalizedOrder = <_ProgressSectionId>[
        if (rawOrder != null)
          ...rawOrder
              .map(_progressSectionIdFromName)
              .whereType<_ProgressSectionId>(),
      ];
      if (normalizedOrder.isEmpty) {
        normalizedOrder.addAll(_kDefaultProgressSectionOrder);
      }

      final visibleSections =
          rawVisible == null
              ? _kDefaultProgressSectionOrder.toSet()
              : rawVisible
                  .map(_progressSectionIdFromName)
                  .whereType<_ProgressSectionId>()
                  .toSet();

      if (!mounted) return;
      setState(() {
        _sectionOrder = normalizedOrder;
        _visibleSections =
            visibleSections.isEmpty
                ? _kDefaultProgressSectionOrder.toSet()
                : visibleSections;
      });
    } catch (_) {
      // Keep page usable if local section preferences fail to load.
    }
  }

  Future<void> _persistSectionLayout() async {
    if (widget.recoveryFocusMode) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kProgressSectionOrderStorageKey,
        _normalizedSectionOrder().map((id) => id.name).toList(growable: false),
      );
      await prefs.setStringList(
        _kProgressVisibleSectionsStorageKey,
        _visibleSections.map((id) => id.name).toList(growable: false),
      );
    } catch (_) {
      // Non-fatal local persistence failure.
    }
  }

  List<_ProgressSectionId> _normalizedSectionOrder() {
    if (widget.recoveryFocusMode) {
      return List<_ProgressSectionId>.from(_kRecoveryFocusSectionOrder);
    }
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

  List<_ProgressSectionId> _effectiveSectionOrder() {
    final normalized = _normalizedSectionOrder();
    return normalized.where(_visibleSections.contains).toList(growable: false);
  }

  List<_ProgressSectionId> _hiddenSections() {
    return _normalizedSectionOrder()
        .where((id) => !_visibleSections.contains(id))
        .toList(growable: false);
  }

  void _onSectionReorder(int oldIndex, int newIndex) {
    final visibleOrder = _effectiveSectionOrder().toList(growable: true);
    if (oldIndex < 0 || oldIndex >= visibleOrder.length) return;
    setState(() {
      var insertAt = newIndex;
      if (newIndex > oldIndex) {
        insertAt -= 1;
      }
      insertAt = insertAt.clamp(0, visibleOrder.length - 1);
      final moved = visibleOrder.removeAt(oldIndex);
      visibleOrder.insert(insertAt, moved);
      final hiddenOrder = _hiddenSections();
      _sectionOrder = <_ProgressSectionId>[...visibleOrder, ...hiddenOrder];
    });
    _persistSectionLayout();
  }

  void _removeSection(_ProgressSectionId sectionId) {
    if (!_visibleSections.contains(sectionId)) return;
    setState(() => _visibleSections.remove(sectionId));
    _persistSectionLayout();
  }

  void _addSection(_ProgressSectionId sectionId) {
    if (_visibleSections.contains(sectionId)) return;
    setState(() {
      _visibleSections.add(sectionId);
      if (!_sectionOrder.contains(sectionId)) {
        _sectionOrder.add(sectionId);
      }
    });
    _persistSectionLayout();
  }

  GlobalKey _sectionKey(_ProgressSectionId sectionId) {
    return _sectionKeys.putIfAbsent(sectionId, () => GlobalKey());
  }

  void _scrollToSection(_ProgressSectionId sectionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _sectionKey(sectionId).currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: LiftMotion.standard,
        curve: LiftMotion.enterCurve,
        alignment: 0.08,
      );
    });
  }

  Future<void> _showAddSectionSheet() async {
    final allSections = _normalizedSectionOrder();
    final selectedSection = await showModalBottomSheet<_ProgressSectionId>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        final viewportHeight = MediaQuery.sizeOf(sheetContext).height;
        final listHeight = (viewportHeight * 0.52).clamp(280.0, 560.0);
        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: viewportHeight * 0.74),
              child: LiftMenuSheet(
                title: 'Add tiles',
                subtitle:
                    'Choose which Progress tiles appear on the page. Tiles already showing are marked below.',
                children: [
                  SizedBox(
                    height: listHeight,
                    child: ListView.separated(
                      padding: EdgeInsets.zero,
                      physics: const ClampingScrollPhysics(),
                      itemCount: allSections.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final sectionId = allSections[index];
                        final isVisible = _visibleSections.contains(sectionId);
                        final subtitle =
                            isVisible
                                ? '${sectionId.subtitle} Already on your page.'
                                : sectionId.subtitle;
                        return Opacity(
                          opacity: isVisible ? 0.6 : 1,
                          child: IgnorePointer(
                            ignoring: isVisible,
                            child: LiftMenuActionTile(
                              icon:
                                  isVisible
                                      ? MynauiIcon(
                                        MynauiGlyphs.checkUnread,
                                        size: 22,
                                        color: Colors.grey.shade500,
                                      )
                                      : sectionId ==
                                          _ProgressSectionId.consistency
                                      ? MynauiIcon(
                                        MynauiGlyphs.calendarMark,
                                        size: 22,
                                        color: kRecoveryMidColor,
                                      )
                                      : Icon(sectionId.icon),
                              title: sectionId.label,
                              subtitle: subtitle,
                              accent:
                                  isVisible
                                      ? Colors.grey.shade500
                                      : kRecoveryMidColor,
                              showChevron: !isVisible,
                              onTap: () {
                                Navigator.pop(sheetContext, sectionId);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (!mounted || selectedSection == null) return;
    _addSection(selectedSection);
    _scrollToSection(selectedSection);
  }

  Widget _buildSectionById(
    _ProgressSectionId sectionId,
    _ProgressAnalytics analytics, {
    int sectionIndex = 0,
    List<WorkoutHistoryEntry> allHistory = const <WorkoutHistoryEntry>[],
  }) {
    final useFirstSectionCorners = sectionIndex == 0;
    return switch (sectionId) {
      _ProgressSectionId.trainingScore => _TrainingScoreHero(
        gymScore: analytics.gymScore,
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
      ),
      _ProgressSectionId.recovery => _RecoverySection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
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
      _ProgressSectionId.activity => _ActivitySection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
        entries: analytics.recentWorkouts,
        completedWorkouts: analytics.completedWorkoutsInRange,
        totalMinutes: analytics.totalMinutesInRange,
        totalVolumeKg: analytics.totalVolumeInRange,
        selectedRange: _selectedRange,
        onSeeAll: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => _WorkoutHistoryPage(
                    entries: allHistory.reversed.toList(growable: false),
                    selectedRange: _selectedRange,
                  ),
            ),
          );
        },
      ),
      _ProgressSectionId.insight => _InsightCard(
        text: analytics.insightText,
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
      ),
      _ProgressSectionId.performance => _PerformanceSection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
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
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
        machineStats: analytics.machineStats,
      ),
      _ProgressSectionId.exerciseAssessments => _ExerciseAssessmentSection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
        assessments: analytics.exerciseAssessments,
      ),
      _ProgressSectionId.consistency => _ConsistencySection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
        streakDays: analytics.streakDays,
        weeklyCompletionPercent: analytics.weeklyCompletionPercent,
        trainingScore: analytics.trainingScore,
        heatmapShades: analytics.heatmapShades,
      ),
      _ProgressSectionId.muscleBalance => _MuscleBalanceSection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
        pushRatio: analytics.pushRatio,
        pullRatio: analytics.pullRatio,
        recoveryLabel: analytics.recoveryLabel,
      ),
      _ProgressSectionId.conditioning => _ConditioningSection(
        customBorderRadius:
            useFirstSectionCorners ? kProgressFirstSectionRadius : null,
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
    final recentWorkouts = allSorted.reversed.take(4).toList(growable: false);
    final totalMinutesInRange = rangeEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.duration.inMinutes,
    );
    final totalVolumeInRange = rangeEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalVolumeKg,
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
      recentWorkouts: recentWorkouts,
      completedWorkoutsInRange: rangeEntries.length,
      totalMinutesInRange: totalMinutesInRange,
      totalVolumeInRange: totalVolumeInRange,
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
    const baseBottomInset = 12.0;
    final bottomInset = baseBottomInset + widget.extraBottomInset;
    final sectionOrder = _effectiveSectionOrder();
    final topInset = MediaQuery.paddingOf(context).top;
    const islandTop = 16.0;
    const progressHeaderGap = 10.0;
    const progressHeaderSpacer = 4.0;

    /// Space reserved for status bar + floating island + gap (scrim + header).
    final listTopPadding =
        topInset + islandTop + kLiftIslandHeaderHeight + progressHeaderGap;

    /// Align list content with that inset so titles never sit under the opaque
    /// island. The blur band still extends below this so the hero top can read
    /// frosted when scrolled slightly.
    final listScrollTopPadding = listTopPadding;
    final topBlurBandHeight = listTopPadding + 88.0;

    /// Slightly off-white so [BackdropFilter] on the scrim + island has
    /// something to blur (pure white parent makes glass read as flat paint).
    return Material(
      color: kProgressCanvasColor,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // List paints first so [BackdropFilter] in the scrim blurs live content.
            Positioned.fill(
              child: ReorderableListView(
                scrollController: _progressScrollController,
                primary: false,
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  kPagePadding,
                  listScrollTopPadding,
                  kPagePadding,
                  bottomInset,
                ),
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
                            borderRadius: BorderRadius.circular(
                              kIosCornerRadius,
                            ),
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
                    if (_isReorderMode)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          'Arrange mode: drag to reorder, tap + to add tiles, and use x to remove them.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: progressHeaderSpacer),
                  ],
                ),
                footer: null,
                children: List<Widget>.generate(sectionOrder.length, (index) {
                  final sectionId = sectionOrder[index];
                  final baseChild = _buildSectionById(
                    sectionId,
                    analytics,
                    sectionIndex: index,
                    allHistory: allSorted,
                  );
                  final removableChild =
                      _isReorderMode
                          ? _ReorderEditableTile(
                            onRemove: () => _removeSection(sectionId),
                            child: baseChild,
                          )
                          : baseChild;
                  Widget reorderableChild;
                  if (_isReorderMode) {
                    reorderableChild = ReorderableDelayedDragStartListener(
                      index: index,
                      child: AnimatedBuilder(
                        animation: _jiggleController,
                        child: removableChild,
                        builder: (context, child) {
                          final wave =
                              (0.004 + (_jiggleController.value * 0.008));
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
                    reorderableChild =
                        widget.recoveryFocusMode
                            ? removableChild
                            : GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onLongPress: _enterReorderMode,
                              child: removableChild,
                            );
                  }
                  return Container(
                    key: _sectionKey(sectionId),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: reorderableChild,
                  );
                }),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topBlurBandHeight,
              child: IgnorePointer(
                child: const _ProgressTopGradientBlurScrim(),
              ),
            ),
            Positioned(
              top: topInset + islandTop,
              left: kPagePadding,
              right: kPagePadding,
              child: LiftIslandHeader(
                scrollController: _progressScrollController,
                title: widget.headerTitle,
                trailingSlotWidth: widget.showProfileAction ? 48 : 0,
                leading: LiftIslandHeaderAction(
                  onTap:
                      widget.showBack
                          ? (widget.onLeadingTap ??
                              () => Navigator.of(context).pop())
                          : (widget.onLeadingTap ?? () {}),
                  child: MynauiIcon(
                    widget.showBack
                        ? MynauiGlyphs.altArrowLeft
                        : MynauiGlyphs.qrCode,
                    size:
                        widget.showBack ? 22 : kLiftIslandHeaderLeadingIconSize,
                    color: kLiftIslandOnFrosted,
                  ),
                ),
                trailing:
                    widget.showProfileAction
                        ? LiftIslandHeaderAction(
                          onTap:
                              widget.onProfileTap ??
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => SettingsScreen(
                                          workoutHistory: widget.history,
                                        ),
                                  ),
                                );
                              },
                          child: const MynauiIcon(
                            MynauiGlyphs.userNoCircle,
                            size: kLiftIslandHeaderTrailingIconSize,
                            color: kLiftIslandOnFrosted,
                          ),
                        )
                        : null,
              ),
            ),
            if (_isReorderMode && !widget.recoveryFocusMode)
              Positioned(
                left: 16,
                right: 16,
                bottom: kShellFloatingNavBottomInset,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: _ProgressArrangeBottomIsland(
                    onAddTap: _showAddSectionSheet,
                    onDoneTap: _exitReorderMode,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Neutral frosted blur behind status bar + header (no score-based colour tint).
class _ProgressTopGradientBlurScrim extends StatelessWidget {
  const _ProgressTopGradientBlurScrim();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: featherTopBlurMask,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: const ColoredBox(color: Color(0x00000000)),
            ),
            // Light veil so blur stays visible (heavy white reads as flat paint).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.38),
                    Colors.white.withValues(alpha: 0.20),
                    Colors.white.withValues(alpha: 0.07),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.28, 0.58, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressArrangeBottomIsland extends StatelessWidget {
  const _ProgressArrangeBottomIsland({
    required this.onAddTap,
    required this.onDoneTap,
  });

  final VoidCallback onAddTap;
  final VoidCallback onDoneTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kLiftIslandHeaderHeight,
      child: LiftFloatingIslandSurface(
        borderRadius: 30,
        backgroundColor: const Color(0xEAF7F7F7),
        borderColor: const Color(0x12000000),
        blurSigma: 24,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              LiftPressable(
                onTap: onAddTap,
                borderRadius: kIosControlRadius,
                pressedScale: LiftMotion.gentlePressScale,
                child: SizedBox(
                  width: 44,
                  height: 40,
                  child: Center(
                    child: MynauiIcon(
                      MynauiGlyphs.addCircle,
                      size: 25,
                      color: const Color(0xBF000000),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              LiftPressable(
                onTap: onDoneTap,
                borderRadius: kIosControlRadius,
                child: Ink(
                  width: 148,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(kIosControlRadius),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    required this.recentWorkouts,
    required this.completedWorkoutsInRange,
    required this.totalMinutesInRange,
    required this.totalVolumeInRange,
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
  final List<WorkoutHistoryEntry> recentWorkouts;
  final int completedWorkoutsInRange;
  final int totalMinutesInRange;
  final double totalVolumeInRange;
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
  const _InsightCard({required this.text, this.customBorderRadius});

  final String text;
  final BorderRadius? customBorderRadius;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kAccentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(kIosCornerRadius),
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

extension _ProgressRangeDisplay on _ProgressRange {
  String get activityLabel {
    switch (this) {
      case _ProgressRange.week:
        return 'Last 7 days';
      case _ProgressRange.month:
        return 'Last 30 days';
      case _ProgressRange.quarter:
        return 'Last 90 days';
      case _ProgressRange.custom:
        return 'All time';
    }
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    this.customBorderRadius,
    required this.entries,
    required this.completedWorkouts,
    required this.totalMinutes,
    required this.totalVolumeKg,
    required this.selectedRange,
    required this.onSeeAll,
  });

  final BorderRadius? customBorderRadius;
  final List<WorkoutHistoryEntry> entries;
  final int completedWorkouts;
  final int totalMinutes;
  final double totalVolumeKg;
  final _ProgressRange selectedRange;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final subtitleColor = Colors.grey.shade600;
    final visibleEntries = entries.take(2).toList(growable: false);
    return LiftPressable(
      onTap: onSeeAll,
      borderRadius: kIosCornerRadius,
      pressedScale: LiftMotion.gentlePressScale,
      child: SectionBoundary(
        customBorderRadius: customBorderRadius,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeaderRow(
              title: 'Activity',
              actionLabel: 'See all',
              onActionTap: onSeeAll,
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedWorkouts completed workout${completedWorkouts == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedRange.activityLabel} • $totalMinutes min trained • ${totalVolumeKg.toStringAsFixed(0)}kg moved',
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              Text(
                'Complete a workout to start building your activity history.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  height: 1.35,
                ),
              )
            else
              Column(
                children: [
                  for (var i = 0; i < visibleEntries.length; i++) ...[
                    _ActivityWorkoutRow(
                      entry: visibleEntries[i],
                      onTap:
                          () => pushWorkoutHistoryDetailPage(
                            context,
                            entry: visibleEntries[i],
                          ),
                    ),
                    if (i != visibleEntries.length - 1)
                      Divider(
                        height: 18,
                        color: Theme.of(context).dividerTheme.color,
                      ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TrainingScoreHero extends StatelessWidget {
  const _TrainingScoreHero({required this.gymScore, this.customBorderRadius});

  final _GymScoreBreakdown gymScore;
  final BorderRadius? customBorderRadius;

  @override
  Widget build(BuildContext context) {
    final score = gymScore.totalScore.clamp(0, 100);
    final scoreColor = _trainingScoreAccentColor(score);
    final workoutRatio = gymScore.workoutPoints / 50;
    final recoveryRatio = gymScore.recoveryPoints / 25;
    final consistencyRatio = gymScore.consistencyPoints / 15;
    final loadQualityRatio = gymScore.loadQualityPoints / 10;
    final borderRadius =
        customBorderRadius ?? BorderRadius.circular(kIosCornerRadius);
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scoreColor.withValues(alpha: 0.10), Colors.white],
        ),
        border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderRow(title: 'Training score'),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _trainingScoreStatus(score),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Training score blends workout quality, recovery, and consistency.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 112,
                      height: 112,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$score%',
                            style: TextStyle(
                              color: scoreColor,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ScoreBreakdownBar(
                  label: 'Workout',
                  value: gymScore.workoutPoints,
                  max: 50,
                  color: _scoreSignalColor(workoutRatio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreBreakdownBar(
                  label: 'Recovery',
                  value: gymScore.recoveryPoints,
                  max: 25,
                  color: _scoreSignalColor(recoveryRatio),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ScoreBreakdownBar(
                  label: 'Consistency',
                  value: gymScore.consistencyPoints,
                  max: 15,
                  color: _scoreSignalColor(consistencyRatio),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ScoreBreakdownBar(
                  label: 'Load quality',
                  value: gymScore.loadQualityPoints,
                  max: 10,
                  color: _scoreSignalColor(loadQualityRatio),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Confidence ${gymScore.confidenceScore}%',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Integrations improve score confidence, not the score ceiling.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    final hasAction = actionLabel != null && actionLabel!.trim().isNotEmpty;
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (hasAction)
          LiftPressable(
            onTap: onActionTap,
            borderRadius: kIosCornerRadius,
            pressedScale: LiftMotion.gentlePressScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  color: kAccentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScoreBreakdownBar extends StatelessWidget {
  const _ScoreBreakdownBar({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  final String label;
  final int value;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$value/$max',
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 4,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _PerformanceSection extends StatelessWidget {
  const _PerformanceSection({
    this.customBorderRadius,
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
  final BorderRadius? customBorderRadius;

  @override
  Widget build(BuildContext context) {
    final trendText =
        '${trendPercent >= 0 ? '+' : ''}${trendPercent.toStringAsFixed(1)}%';

    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance trends',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
              borderRadius: BorderRadius.circular(kIosCornerRadius),
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
  const _MachineAnalyticsSection({
    this.customBorderRadius,
    required this.machineStats,
  });

  final BorderRadius? customBorderRadius;
  final List<_MachineProgressStat> machineStats;

  @override
  Widget build(BuildContext context) {
    final machines = machineStats;

    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Machine analytics',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
  const _ExerciseAssessmentSection({
    this.customBorderRadius,
    required this.assessments,
  });

  final BorderRadius? customBorderRadius;
  final List<_ExerciseAssessment> assessments;

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Exercise assessments',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
                    borderRadius: BorderRadius.circular(kIosCornerRadius),
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
                              borderRadius: BorderRadius.circular(
                                kIosCornerRadius,
                              ),
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
    this.customBorderRadius,
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

  final BorderRadius? customBorderRadius;
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
    if (recoveryPercent >= 40) return kCautionColor;
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
          borderRadius: BorderRadius.circular(kIosCornerRadius),
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
      customBorderRadius: customBorderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderRow(
            title: 'Recovery stats',
            actionLabel: 'Sources',
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
                        borderRadius: BorderRadius.circular(kIosCornerRadius),
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
    this.customBorderRadius,
    required this.streakDays,
    required this.weeklyCompletionPercent,
    required this.trainingScore,
    required this.heatmapShades,
  });

  final int streakDays;
  final int weeklyCompletionPercent;
  final int trainingScore;
  final List<double> heatmapShades;
  final BorderRadius? customBorderRadius;

  @override
  Widget build(BuildContext context) {
    final trainingScoreColor = _trainingScoreAccentColor(trainingScore);
    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeaderRow(title: 'Consistency', actionLabel: 'Weekly'),
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
                  accentColor: trainingScoreColor,
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
    this.customBorderRadius,
    required this.pushRatio,
    required this.pullRatio,
    required this.recoveryLabel,
  });

  final double pushRatio;
  final double pullRatio;
  final String recoveryLabel;
  final BorderRadius? customBorderRadius;

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
      customBorderRadius: customBorderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Muscle balance',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
    this.customBorderRadius,
    required this.pullupReps,
    required this.bodyweightReps,
    required this.conditioningDurationLabel,
  });

  final int pullupReps;
  final int bodyweightReps;
  final String conditioningDurationLabel;
  final BorderRadius? customBorderRadius;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      customBorderRadius: customBorderRadius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bodyweight + conditioning',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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
        borderRadius: BorderRadius.circular(kIosCornerRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                selected ? kAccentColor.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(kIosCornerRadius),
            border: Border.all(
              color:
                  selected
                      ? kAccentColor.withValues(alpha: 0.45)
                      : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: selected ? kAccentColor : Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniStatTile extends StatelessWidget {
  const _MiniStatTile({
    required this.title,
    required this.value,
    this.accentColor,
  });

  final String title;
  final String value;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final hasAccent = accentColor != null;
    final foreground = accentColor ?? Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color:
            hasAccent
                ? accentColor!.withValues(alpha: 0.09)
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(kIosCornerRadius),
        border: Border.all(
          color:
              hasAccent
                  ? accentColor!.withValues(alpha: 0.20)
                  : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color:
                  hasAccent
                      ? accentColor!.withValues(alpha: 0.90)
                      : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ActivityWorkoutRow extends StatelessWidget {
  const _ActivityWorkoutRow({required this.entry, this.onTap});

  final WorkoutHistoryEntry entry;
  final VoidCallback? onTap;

  String _formatDateTime(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final date = localizations.formatShortDate(entry.completedAt);
    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(entry.completedAt),
    );
    return '$date • $time';
  }

  String _formatDuration() {
    final minutes = entry.duration.inMinutes;
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    return rem == 0 ? '${hours}h' : '${hours}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final previewExercise =
        entry.exerciseSummaries.isNotEmpty
            ? entry.exerciseSummaries.first.exerciseName
            : entry.workoutName;
    return LiftPressable(
      onTap: onTap,
      borderRadius: kIosControlRadius,
      pressedScale: LiftMotion.gentlePressScale,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: kExerciseImageBorderRadius,
            child: Image.network(
              exerciseDemoImageUrl(previewExercise),
              width: 58,
              height: 58,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    color: Colors.grey.shade200,
                    child: MynauiIcon(
                      MynauiGlyphs.galleryMinimalistic,
                      color: Colors.grey.shade500,
                      size: 26,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.workoutName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDateTime(context),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    _ActivityMeta(
                      icon: Icons.schedule_rounded,
                      label: _formatDuration(),
                    ),
                    _ActivityMeta(
                      icon: Icons.local_fire_department_rounded,
                      label: '${entry.totalVolumeKg.toStringAsFixed(0)} kg',
                    ),
                    _ActivityMeta(
                      icon: Icons.checklist_rounded,
                      label:
                          '${entry.exercisesCompleted}/${entry.totalExercises} exercises',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}

class _ActivityMeta extends StatelessWidget {
  const _ActivityMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _WorkoutHistoryPage extends StatelessWidget {
  const _WorkoutHistoryPage({
    required this.entries,
    required this.selectedRange,
  });

  final List<WorkoutHistoryEntry> entries;
  final _ProgressRange selectedRange;

  int get _totalMinutes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.duration.inMinutes);

  double get _totalVolume =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalVolumeKg);

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: kProgressCanvasColor,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              kPagePadding,
              topInset + 16,
              kPagePadding,
              0,
            ),
            child: Column(
              children: [
                LiftIslandHeader(
                  collapseOnScroll: false,
                  title: 'Workout history',
                  subtitle: selectedRange.activityLabel,
                  leading: LiftIslandHeaderAction(
                    onTap: () => Navigator.pop(context),
                    child: const MynauiIcon(
                      MynauiGlyphs.altArrowLeft,
                      size: 24,
                      color: kLiftIslandOnFrosted,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SectionBoundary(
                  child: Row(
                    children: [
                      Expanded(
                        child: _MiniStatTile(
                          title: 'Workouts',
                          value: '${entries.length}',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatTile(
                          title: 'Training time',
                          value: '$_totalMinutes min',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _MiniStatTile(
                          title: 'Volume',
                          value: '${_totalVolume.toStringAsFixed(0)}kg',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder:
                        (context, index) => SectionBoundary(
                          child: _ActivityWorkoutRow(
                            entry: entries[index],
                            onTap:
                                () => pushWorkoutHistoryDetailPage(
                                  context,
                                  entry: entries[index],
                                ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        borderRadius: BorderRadius.circular(kIosCornerRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: kExerciseImageBorderRadius,
            child: Image.network(
              exerciseDemoImageUrl(name),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: MynauiIcon(
                      MynauiGlyphs.galleryMinimalistic,
                      color: Colors.grey.shade500,
                      size: 26,
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
            borderRadius: BorderRadius.circular(kIosCornerRadius),
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
                  borderRadius: BorderRadius.circular(kIosCornerRadius),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: fillGradient,
                      borderRadius: BorderRadius.circular(kIosCornerRadius),
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

class _ReorderEditableTile extends StatelessWidget {
  const _ReorderEditableTile({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: LiftPressable(
            onTap: onRemove,
            borderRadius: 16,
            pressedScale: LiftMotion.gentlePressScale,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: MynauiIcon(
                MynauiGlyphs.closeCircle,
                size: 18,
                color: Colors.grey.shade800,
              ),
            ),
          ),
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

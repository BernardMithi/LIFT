import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/articles/articles_screen.dart';
import 'package:lift/features/home/today_workout_detail_screen.dart';
import 'package:lift/features/machines/machine_screen.dart';
import 'package:lift/features/machines/mock_machines.dart';
import 'package:lift/features/pass/gym_pass_dialog.dart';
import 'package:lift/features/progress/progress_screen.dart';
import 'package:lift/features/settings/settings_screen.dart';
import 'package:lift/features/workout/mock_workout_templates.dart';
import 'package:lift/features/workout/workout_templates_flow.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/models/workout_template.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/recovery_dial_card.dart';
import 'package:lift/shared/widgets/surfaces.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.signedInUserGender});

  final String? signedInUserGender;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _workoutHistoryStorageKey = 'lift_workout_history_v1';
  static const String _userGenderStorageKey = 'lift_user_gender';
  static const Duration _fullRecoveryWindow = Duration(hours: 72);

  int _selectedIndex = 0;
  int _selectedDay = 0;
  final List<String> _days = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<WorkoutTemplate> _templateLibrary = MockWorkoutTemplates.seed();
  final List<WorkoutHistoryEntry> _workoutHistory = <WorkoutHistoryEntry>[];
  bool _hideWorkoutShellNav = false;
  WorkoutLiveDockHandle? _liveDockHandle;
  WorkoutLiveFullscreenHandle? _liveFullscreenHandle;
  WorkoutFlowCommand? _pendingWorkoutCommand;
  int _workoutCommandSeed = 0;
  _RecoveryUserGender _userGender = _RecoveryUserGender.male;

  void _setStateSafely(VoidCallback update) {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(update);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(update);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.signedInUserGender != null) {
      _userGender = _RecoveryUserGenderX.fromRaw(widget.signedInUserGender!);
    }
    _loadWorkoutHistory();
    _loadUserGender();
  }

  void _onNavItemTapped(int index) => setState(() => _selectedIndex = index);
  void _onDaySelected(int day) => setState(() => _selectedDay = day);
  bool get _showShellNav => !(_selectedIndex == 2 && _hideWorkoutShellNav);
  WorkoutTemplate get _selectedDayTemplate =>
      _templateLibrary[_selectedDay % _templateLibrary.length];

  List<_RecoveryMuscleStat> _recoveryStatsFor(WorkoutTemplate template) {
    final latestByMuscle = <String, DateTime>{};
    for (final entry in _workoutHistory) {
      final trainedMuscles = <String>{
        ...entry.muscleGroupVolumeKg.keys.map((group) => group.trim()),
        ...entry.exerciseSummaries.expand(
          (summary) => summary.muscleGroups.map((group) => group.trim()),
        ),
      }.where((group) => group.isNotEmpty);

      for (final group in trainedMuscles) {
        final current = latestByMuscle[group];
        if (current == null || entry.completedAt.isAfter(current)) {
          latestByMuscle[group] = entry.completedAt;
        }
      }
    }

    final targetOrder = <String>{
      ...template.focusTags
          .map((group) => group.trim())
          .where((group) => group.isNotEmpty),
    }.toList(growable: false);

    final knownMuscles = <String>{
      ...latestByMuscle.keys,
      ..._templateLibrary.expand(
        (item) => item.focusTags.map((group) => group.trim()),
      ),
      ...targetOrder,
    }.where((group) => group.isNotEmpty).toList(growable: false);

    final otherMuscles =
        knownMuscles.where((group) => !targetOrder.contains(group)).toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    final ordered = <String>[...targetOrder, ...otherMuscles];
    final now = DateTime.now();

    return ordered
        .map((muscle) {
          final lastTrainedAt = latestByMuscle[muscle];
          final recoveryPercent =
              lastTrainedAt == null
                  ? 100
                  : ((now.difference(lastTrainedAt).inSeconds /
                              _fullRecoveryWindow.inSeconds) *
                          100)
                      .clamp(0, 100)
                      .round();

          return _RecoveryMuscleStat(
            muscleGroup: muscle,
            recoveryPercent: recoveryPercent,
            lastTrainedAt: lastTrainedAt,
          );
        })
        .toList(growable: false);
  }

  Color _recoveryColor(int percent) {
    if (percent >= 80) return Colors.green.shade700;
    if (percent >= 50) return Colors.orange.shade700;
    return Colors.red.shade700;
  }

  Future<void> _openRecoveryHeatMap(
    _RecoveryMuscleStat stat,
    List<_RecoveryMuscleStat> allStats,
  ) async {
    final heatColor = _recoveryColor(stat.recoveryPercent);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      isScrollControlled: true,
      builder: (context) {
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        return FractionallySizedBox(
          alignment: Alignment.bottomCenter,
          heightFactor: 0.72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomInset),
              child: _RecoveryHeatMapSheet(
                stat: stat,
                allStats: allStats,
                heatColor: heatColor,
                regions: _regionsForMuscle(stat.muscleGroup),
                userGender: _userGender,
              ),
            ),
          ),
        );
      },
    );
  }

  void _onWorkoutShellNavVisibilityChanged(bool shouldHide) {
    if (_hideWorkoutShellNav == shouldHide) return;
    _setStateSafely(() => _hideWorkoutShellNav = shouldHide);
  }

  void _onLiveDockChanged(WorkoutLiveDockHandle? handle) {
    if (_liveDockHandle == handle) return;
    _setStateSafely(() => _liveDockHandle = handle);
  }

  void _onLiveFullscreenChanged(WorkoutLiveFullscreenHandle? handle) {
    if (_liveFullscreenHandle == handle) return;
    _setStateSafely(() => _liveFullscreenHandle = handle);
  }

  void _dispatchWorkoutCommand({
    required WorkoutFlowRouteTarget target,
    String? templateId,
  }) {
    _workoutCommandSeed += 1;
    final command = WorkoutFlowCommand(
      id: 'home_workout_cmd_$_workoutCommandSeed',
      target: target,
      templateId: templateId,
    );
    setState(() {
      _selectedIndex = 2;
      _pendingWorkoutCommand = command;
    });
  }

  void _onWorkoutCommandHandled(String commandId) {
    if (_pendingWorkoutCommand?.id != commandId) return;
    setState(() => _pendingWorkoutCommand = null);
  }

  Future<void> _openTodayWorkoutDetail() async {
    final template = _selectedDayTemplate;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => TodayWorkoutDetailScreen(
              template: template,
              history: _workoutHistory,
              onEdit: () {
                _dispatchWorkoutCommand(
                  target: WorkoutFlowRouteTarget.editor,
                  templateId: template.id,
                );
              },
              onStart: () {
                _dispatchWorkoutCommand(
                  target: WorkoutFlowRouteTarget.live,
                  templateId: template.id,
                );
              },
            ),
      ),
    );
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_workoutHistoryStorageKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <WorkoutHistoryEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final parsed = _historyEntryFromMap(map);
        if (parsed != null) {
          restored.add(parsed);
        }
      }
      if (!mounted) return;
      setState(() {
        _workoutHistory
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Keep app usable if persisted history cannot be parsed.
    }
  }

  Future<void> _persistWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(
        _workoutHistory.map(_historyEntryToMap).toList(growable: false),
      );
      await prefs.setString(_workoutHistoryStorageKey, payload);
    } catch (_) {
      // Non-fatal local persistence failure.
    }
  }

  Future<void> _loadUserGender() async {
    try {
      if (widget.signedInUserGender != null) return;
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userGenderStorageKey);
      if (raw == null) return;
      final resolved = _RecoveryUserGenderX.fromRaw(raw);
      if (!mounted || resolved == _userGender) return;
      setState(() => _userGender = resolved);
    } catch (_) {
      // Keep app usable if user profile metadata isn't available.
    }
  }

  void _onWorkoutCompleted(WorkoutHistoryEntry entry) {
    setState(() {
      _workoutHistory.removeWhere((value) => value.id == entry.id);
      _workoutHistory.add(entry);
      _workoutHistory.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    });
    _persistWorkoutHistory();
  }

  Map<String, dynamic> _historyEntryToMap(WorkoutHistoryEntry entry) {
    return <String, dynamic>{
      'id': entry.id,
      'workoutName': entry.workoutName,
      'startedAt': entry.startedAt.toIso8601String(),
      'completedAt': entry.completedAt.toIso8601String(),
      'durationMs': entry.duration.inMilliseconds,
      'totalVolumeKg': entry.totalVolumeKg,
      'totalReps': entry.totalReps,
      'exercisesCompleted': entry.exercisesCompleted,
      'totalExercises': entry.totalExercises,
      'prsAchieved': entry.prsAchieved,
      'exerciseSummaries': entry.exerciseSummaries
          .map(
            (summary) => <String, dynamic>{
              'exerciseName': summary.exerciseName,
              'setCount': summary.setCount,
              'totalReps': summary.totalReps,
              'totalVolumeKg': summary.totalVolumeKg,
              'maxWeightKg': summary.maxWeightKg,
              'muscleGroups': summary.muscleGroups,
            },
          )
          .toList(growable: false),
      'muscleGroupVolumeKg': entry.muscleGroupVolumeKg,
    };
  }

  WorkoutHistoryEntry? _historyEntryFromMap(Map<String, dynamic> map) {
    try {
      final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
      final completedAt = DateTime.tryParse('${map['completedAt'] ?? ''}');
      if (startedAt == null || completedAt == null) return null;
      final summariesRaw = map['exerciseSummaries'];
      final summaries = <WorkoutHistoryExerciseSummary>[];
      if (summariesRaw is List) {
        for (final item in summariesRaw) {
          if (item is! Map) continue;
          final summaryMap = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final exerciseName = '${summaryMap['exerciseName'] ?? ''}'.trim();
          if (exerciseName.isEmpty) continue;
          summaries.add(
            WorkoutHistoryExerciseSummary(
              exerciseName: exerciseName,
              setCount: (summaryMap['setCount'] as num?)?.toInt() ?? 0,
              totalReps: (summaryMap['totalReps'] as num?)?.toInt() ?? 0,
              totalVolumeKg:
                  (summaryMap['totalVolumeKg'] as num?)?.toDouble() ?? 0,
              maxWeightKg: (summaryMap['maxWeightKg'] as num?)?.toDouble() ?? 0,
              muscleGroups:
                  (summaryMap['muscleGroups'] is List)
                      ? (summaryMap['muscleGroups'] as List)
                          .whereType<String>()
                          .toList(growable: false)
                      : const <String>[],
            ),
          );
        }
      }

      final muscleRaw = map['muscleGroupVolumeKg'];
      final muscleVolume = <String, double>{};
      if (muscleRaw is Map) {
        for (final entry in muscleRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is num) {
            muscleVolume[key] = value.toDouble();
          }
        }
      }

      final id = '${map['id'] ?? ''}'.trim();
      final workoutName = '${map['workoutName'] ?? ''}'.trim();
      if (id.isEmpty || workoutName.isEmpty) return null;

      return WorkoutHistoryEntry(
        id: id,
        workoutName: workoutName,
        startedAt: startedAt,
        completedAt: completedAt,
        duration: Duration(
          milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0,
        ),
        totalVolumeKg: (map['totalVolumeKg'] as num?)?.toDouble() ?? 0,
        totalReps: (map['totalReps'] as num?)?.toInt() ?? 0,
        exercisesCompleted: (map['exercisesCompleted'] as num?)?.toInt() ?? 0,
        totalExercises: (map['totalExercises'] as num?)?.toInt() ?? 0,
        prsAchieved: (map['prsAchieved'] as num?)?.toInt() ?? 0,
        exerciseSummaries: summaries,
        muscleGroupVolumeKg: muscleVolume,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showTopLeftActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              0,
              12,
              10 + MediaQuery.paddingOf(sheetContext).bottom,
            ),
            child: LiftMenuSheet(
              title: 'Quick actions',
              subtitle: 'Gym access and machine tools',
              children: [
                LiftMenuActionTile(
                  icon: const Icon(Icons.qr_code_2_rounded),
                  title: 'Open gym pass',
                  subtitle: 'QR + backup entry code',
                  accent: kAccentColor,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    showGymPassDialog(context);
                  },
                ),
                const SizedBox(height: 8),
                LiftMenuActionTile(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  title: 'Simulate machine scan',
                  subtitle: 'Open Lat Pulldown machine screen',
                  accent: const Color(0xFF0A7A6B),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const MachineScreen(
                              machine: MockMachines.latPulldown,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              const ArticlesScreen(extraBottomInset: 84),
              WorkoutTemplatesFlow(
                onWorkoutCompleted: _onWorkoutCompleted,
                onHideShellNavChanged: _onWorkoutShellNavVisibilityChanged,
                onLiveDockChanged: _onLiveDockChanged,
                onLiveFullscreenChanged: _onLiveFullscreenChanged,
                externalCommand: _pendingWorkoutCommand,
                onExternalCommandHandled: _onWorkoutCommandHandled,
              ),
              ProgressScreen(history: _workoutHistory, extraBottomInset: 0),
            ],
          ),
          if (_liveDockHandle != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: _showShellNav ? 100 : 18,
              child: SafeArea(
                top: false,
                bottom: false,
                child: WorkoutLiveDock(
                  state: _liveDockHandle!.state,
                  onTap: _liveDockHandle!.onResume,
                ),
              ),
            ),
          if (_showShellNav)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SafeArea(
                top: false,
                bottom: false,
                child: _FloatingIslandNav(
                  selectedIndex: _selectedIndex,
                  onTap: _onNavItemTapped,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final recoveryStats = _recoveryStatsFor(_selectedDayTemplate);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        child: Column(
          children: [
            LiftIslandHeader(
              leading: LiftIslandHeaderAction(
                onTap: _showTopLeftActions,
                child: const PhosphorIcon(
                  PhosphorIconsRegular.qrCode,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              trailing: LiftIslandHeaderAction(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: const PhosphorIcon(
                  PhosphorIconsRegular.userCircle,
                  size: 33,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: SizedBox(
                      width: double.infinity,
                      child: SectionBoundary(
                        padding: EdgeInsets.zero,
                        child: _TodayWorkoutTile(
                          template: _selectedDayTemplate,
                          onTap: _openTodayWorkoutDetail,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SectionBoundary(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_days.length, (index) {
                        final selected = _selectedDay == index;
                        return GestureDetector(
                          onTap: () => _onDaySelected(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? kAccentColor : Colors.grey,
                                width: selected ? 2 : 1,
                              ),
                              color:
                                  selected
                                      ? kAccentColor.withValues(alpha: 0.10)
                                      : Colors.transparent,
                            ),
                            child: Center(
                              child: Text(
                                _days[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selected ? kAccentColor : Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    flex: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF20141B), Color(0xFF0F1016)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.16),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          child: _RecoveryStatsCarousel(
                            stats: recoveryStats,
                            onTapStat:
                                (stat) =>
                                    _openRecoveryHeatMap(stat, recoveryStats),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayWorkoutTile extends StatelessWidget {
  const _TodayWorkoutTile({required this.template, required this.onTap});

  final WorkoutTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                template.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kAccentDark, kAccentMid, kAccentLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.45),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _WorkoutStatChip(
                            icon: Icons.schedule_rounded,
                            label: '${template.estimatedDurationMinutes} min',
                            dark: true,
                          ),
                          const SizedBox(width: 8),
                          _WorkoutStatChip(
                            icon: Icons.list_alt_rounded,
                            label: '${template.exercises.length} exercises',
                            dark: true,
                          ),
                        ],
                      ),
                    ],
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

class _WorkoutStatChip extends StatelessWidget {
  const _WorkoutStatChip({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            dark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              dark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dark ? Colors.white : kAccentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecoveryMuscleStat {
  const _RecoveryMuscleStat({
    required this.muscleGroup,
    required this.recoveryPercent,
    required this.lastTrainedAt,
  });

  final String muscleGroup;
  final int recoveryPercent;
  final DateTime? lastTrainedAt;
}

const Duration _recoveryWindowDuration = Duration(hours: 72);

Duration _remainingRecoveryDuration(DateTime? lastTrainedAt) {
  if (lastTrainedAt == null) return Duration.zero;
  final remaining = lastTrainedAt
      .add(_recoveryWindowDuration)
      .difference(DateTime.now());
  if (remaining.isNegative) return Duration.zero;
  return remaining;
}

String _daysUntilRecoveryText(DateTime? lastTrainedAt) {
  final remaining = _remainingRecoveryDuration(lastTrainedAt);
  if (remaining == Duration.zero) return '0.0 days';
  final days = remaining.inMinutes / Duration.minutesPerDay;
  final decimals = days >= 10 ? 0 : 1;
  return '${days.toStringAsFixed(decimals)} days';
}

String _lastWorkedText(DateTime? lastTrainedAt) {
  if (lastTrainedAt == null) return 'No history yet';
  final diff = DateTime.now().difference(lastTrainedAt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
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
  return '${months[lastTrainedAt.month - 1]} ${lastTrainedAt.day}';
}

const String _recoveryMannequinBasePath = 'assets/images/recovery/mannequins';

class _RecoveryStatsCarousel extends StatefulWidget {
  const _RecoveryStatsCarousel({required this.stats, required this.onTapStat});

  final List<_RecoveryMuscleStat> stats;
  final ValueChanged<_RecoveryMuscleStat> onTapStat;

  @override
  State<_RecoveryStatsCarousel> createState() => _RecoveryStatsCarouselState();
}

class _RecoveryStatsCarouselState extends State<_RecoveryStatsCarousel> {
  int _currentPage = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _RecoveryStatsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stats.isEmpty) {
      _currentPage = 0;
      return;
    }
    if (_currentPage >= widget.stats.length) {
      _currentPage = widget.stats.length - 1;
      _pageController.jumpToPage(_currentPage);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stats.isEmpty) {
      return Center(
        child: Text(
          'Recovery stats unavailable',
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Recovery',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Swipe',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Shared dial and indicator, driven by _currentPage.
                Builder(
                  builder: (context) {
                    final stat = widget.stats[_currentPage];
                    return IgnorePointer(
                      ignoring: true,
                      child: RecoveryDialCard(
                        muscleName: stat.muscleGroup,
                        percentage: stat.recoveryPercent,
                        recoveryEtaLabel:
                            '${_daysUntilRecoveryText(stat.lastTrainedAt)} to recovery',
                        lastHitLabel:
                            'Last hit ${_lastWorkedText(stat.lastTrainedAt).toLowerCase()}',
                        showDots: widget.stats.length > 1,
                        dotCount: widget.stats.length,
                        activeDotIndex: _currentPage,
                      ),
                    );
                  },
                ),
                // Invisible pages on top to handle swipe + tap.
                PageView.builder(
                  controller: _pageController,
                  itemCount: widget.stats.length,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          final stat = widget.stats[_currentPage];
                          widget.onTapStat(stat);
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

enum _RecoveryBodyRegion {
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

enum _RecoveryUserGender { male, female }

enum _RecoveryState { recovered, mid, fatigued }

extension _RecoveryUserGenderX on _RecoveryUserGender {
  static _RecoveryUserGender fromRaw(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'female' ||
        normalized == 'f' ||
        normalized == 'woman' ||
        normalized == 'girl') {
      return _RecoveryUserGender.female;
    }
    return _RecoveryUserGender.male;
  }
}

Color _recoveryStateColor(_RecoveryState state) {
  switch (state) {
    case _RecoveryState.recovered:
      return Colors.green.shade500;
    case _RecoveryState.mid:
      return Colors.amber.shade600;
    case _RecoveryState.fatigued:
      return Colors.red.shade500;
  }
}

Color _recoveryOverlayColor(
  _RecoveryState state, {
  bool emphasized = false,
  double pulse = 0,
}) {
  final base = _recoveryStateColor(state);
  final pulseBoost = emphasized ? lerpDouble(0.62, 1.48, pulse)! : 1.0;
  double alpha;
  double maxAlpha;
  switch (state) {
    case _RecoveryState.recovered:
      alpha = emphasized ? 0.34 : 0.12;
      maxAlpha = emphasized ? 0.46 : 0.20;
      break;
    case _RecoveryState.mid:
      alpha = emphasized ? 0.62 : 0.46;
      maxAlpha = emphasized ? 0.64 : 0.50;
      break;
    case _RecoveryState.fatigued:
      alpha = emphasized ? 0.72 : 0.56;
      maxAlpha = emphasized ? 0.70 : 0.58;
      break;
  }
  final finalAlpha = (alpha * pulseBoost).clamp(0, maxAlpha).toDouble();
  return base.withValues(alpha: finalAlpha);
}

Color _recoveryOutlineColor(
  _RecoveryState state, {
  bool emphasized = false,
  double pulse = 0,
}) {
  final base = _recoveryStateColor(state);
  final pulseBoost = emphasized ? lerpDouble(0.55, 1.65, pulse)! : 1.0;
  double alpha;
  switch (state) {
    case _RecoveryState.recovered:
      alpha = emphasized ? 0.56 : 0.22;
      break;
    case _RecoveryState.mid:
      alpha = emphasized ? 0.68 : 0.34;
      break;
    case _RecoveryState.fatigued:
      alpha = emphasized ? 0.78 : 0.42;
      break;
  }
  return base.withValues(alpha: (alpha * pulseBoost).clamp(0, 1).toDouble());
}

int _recoveryStatePriority(_RecoveryState state) {
  switch (state) {
    case _RecoveryState.recovered:
      return 0;
    case _RecoveryState.mid:
      return 1;
    case _RecoveryState.fatigued:
      return 2;
  }
}

Set<_RecoveryBodyRegion> _regionsForMuscle(String muscleGroup) {
  final value = muscleGroup.toLowerCase();
  if (value.contains('quad')) {
    return {_RecoveryBodyRegion.quads};
  }
  if (value.contains('ham')) {
    return {_RecoveryBodyRegion.hamstrings};
  }
  if (value.contains('glute')) {
    return {_RecoveryBodyRegion.glutes};
  }
  if (value.contains('chest')) {
    return {_RecoveryBodyRegion.chest};
  }
  if (value.contains('shoulder')) {
    return {_RecoveryBodyRegion.shoulders};
  }
  if (value.contains('back')) {
    return {_RecoveryBodyRegion.back, _RecoveryBodyRegion.lats};
  }
  if (value.contains('lat')) {
    return {_RecoveryBodyRegion.lats};
  }
  if (value.contains('bicep')) {
    return {_RecoveryBodyRegion.biceps};
  }
  if (value.contains('tricep')) {
    return {_RecoveryBodyRegion.triceps};
  }
  if (value.contains('forearm') ||
      value.contains('wrist') ||
      value.contains('grip')) {
    return {_RecoveryBodyRegion.forearms};
  }
  if (value.contains('arm')) {
    return {
      _RecoveryBodyRegion.biceps,
      _RecoveryBodyRegion.triceps,
      _RecoveryBodyRegion.forearms,
    };
  }
  if (value.contains('core') || value.contains('ab')) {
    return {_RecoveryBodyRegion.abs};
  }
  if (value.contains('calf') || value.contains('calves')) {
    return {_RecoveryBodyRegion.calves};
  }
  return {_RecoveryBodyRegion.abs};
}

enum _RecoveryBodyType { male, female }

enum _RecoveryBodyView { front, back }

enum _RecoveryMuscleRegion {
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

class _RecoveryMuscleRegionPaths {
  _RecoveryMuscleRegionPaths() {
    _initializeFemaleFrontPaths();
    _initializeFemaleBackPaths();
    _initializeMaleFrontPaths();
    _initializeMaleBackPaths();
  }

  static const double designWidth = 930;
  static const double designHeight = 1300;

  final Map<String, Map<_RecoveryMuscleRegion, Path>> _paths = {};

  String _getKey(_RecoveryBodyType bodyType, _RecoveryBodyView view) =>
      '${bodyType.name}_${view.name}';

  Map<_RecoveryMuscleRegion, Path> getPaths(
    _RecoveryBodyType bodyType,
    _RecoveryBodyView view,
  ) {
    return _paths[_getKey(bodyType, view)] ??
        const <_RecoveryMuscleRegion, Path>{};
  }

  Path _roundedRect({
    required double left,
    required double top,
    required double width,
    required double height,
    double radius = 20,
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

  Map<_RecoveryMuscleRegion, Path> _cloneMap(
    Map<_RecoveryMuscleRegion, Path> source,
  ) {
    return source.map(
      (region, path) =>
          MapEntry<_RecoveryMuscleRegion, Path>(region, Path.from(path)),
    );
  }

  void _initializeFemaleFrontPaths() {
    final key = _getKey(_RecoveryBodyType.female, _RecoveryBodyView.front);
    final regionPaths = <_RecoveryMuscleRegion, Path>{
      _RecoveryMuscleRegion.leftDeltoid: _ellipse(
        left: 230,
        top: 228,
        width: 92,
        height: 86,
      ),
      _RecoveryMuscleRegion.rightDeltoid: _ellipse(
        left: 608,
        top: 228,
        width: 92,
        height: 86,
      ),
      _RecoveryMuscleRegion.leftPectoralisMajor: _ellipse(
        left: 317,
        top: 242,
        width: 132,
        height: 116,
      ),
      _RecoveryMuscleRegion.rightPectoralisMajor: _ellipse(
        left: 483,
        top: 242,
        width: 132,
        height: 116,
      ),
      _RecoveryMuscleRegion.leftBicepsBrachii: _ellipse(
        left: 190,
        top: 338,
        width: 86,
        height: 112,
      ),
      _RecoveryMuscleRegion.rightBicepsBrachii: _ellipse(
        left: 654,
        top: 338,
        width: 86,
        height: 112,
      ),
      _RecoveryMuscleRegion.leftForearmAnterior: _rotatedRoundedRect(
        left: 156,
        top: 456,
        width: 50,
        height: 142,
        radius: 26,
        angleRadians: 0.46,
        pivotYFactor: 0.24,
      ),
      _RecoveryMuscleRegion.rightForearmAnterior: _rotatedRoundedRect(
        left: 716,
        top: 456,
        width: 50,
        height: 142,
        radius: 26,
        angleRadians: -0.46,
        pivotYFactor: 0.24,
      ),
      _RecoveryMuscleRegion.rectusAbdominis: _roundedRect(
        left: 398,
        top: 390,
        width: 134,
        height: 184,
        radius: 12,
      ),
      _RecoveryMuscleRegion.leftExternalOblique: _ellipse(
        left: 326,
        top: 462,
        width: 74,
        height: 102,
      ),
      _RecoveryMuscleRegion.rightExternalOblique: _ellipse(
        left: 530,
        top: 462,
        width: 74,
        height: 102,
      ),
      _RecoveryMuscleRegion.leftQuadricepsFemoris: _roundedRect(
        left: 314,
        top: 646,
        width: 96,
        height: 194,
        radius: 28,
      ),
      _RecoveryMuscleRegion.rightQuadricepsFemoris: _roundedRect(
        left: 520,
        top: 646,
        width: 96,
        height: 194,
        radius: 28,
      ),
      _RecoveryMuscleRegion.leftTibialisAnterior: _roundedRect(
        left: 322,
        top: 950,
        width: 68,
        height: 230,
        radius: 24,
      ),
      _RecoveryMuscleRegion.rightTibialisAnterior: _roundedRect(
        left: 540,
        top: 950,
        width: 68,
        height: 230,
        radius: 24,
      ),
    };
    _paths[key] = regionPaths;
  }

  void _initializeFemaleBackPaths() {
    final key = _getKey(_RecoveryBodyType.female, _RecoveryBodyView.back);
    final regionPaths = <_RecoveryMuscleRegion, Path>{
      _RecoveryMuscleRegion.leftDeltoid: _ellipse(
        left: 230,
        top: 228,
        width: 92,
        height: 86,
      ),
      _RecoveryMuscleRegion.rightDeltoid: _ellipse(
        left: 608,
        top: 228,
        width: 92,
        height: 86,
      ),
      _RecoveryMuscleRegion.leftUpperTrapezius: _ellipse(
        left: 304,
        top: 202,
        width: 112,
        height: 96,
      ),
      _RecoveryMuscleRegion.rightUpperTrapezius: _ellipse(
        left: 514,
        top: 202,
        width: 112,
        height: 96,
      ),
      _RecoveryMuscleRegion.leftLatissimusDorsi: _roundedRect(
        left: 278,
        top: 340,
        width: 112,
        height: 184,
        radius: 26,
      ),
      _RecoveryMuscleRegion.rightLatissimusDorsi: _roundedRect(
        left: 540,
        top: 340,
        width: 112,
        height: 184,
        radius: 26,
      ),
      _RecoveryMuscleRegion.leftTricepsBrachii: _ellipse(
        left: 188,
        top: 320,
        width: 88,
        height: 108,
      ),
      _RecoveryMuscleRegion.rightTricepsBrachii: _ellipse(
        left: 654,
        top: 320,
        width: 88,
        height: 108,
      ),
      _RecoveryMuscleRegion.leftForearmPosterior: _rotatedRoundedRect(
        left: 156,
        top: 458,
        width: 58,
        height: 142,
        radius: 26,
        angleRadians: 0.40,
        pivotYFactor: 0.24,
      ),
      _RecoveryMuscleRegion.rightForearmPosterior: _rotatedRoundedRect(
        left: 716,
        top: 458,
        width: 58,
        height: 142,
        radius: 26,
        angleRadians: -0.40,
        pivotYFactor: 0.24,
      ),
      _RecoveryMuscleRegion.erectorsSpinae: _roundedRect(
        left: 430,
        top: 304,
        width: 70,
        height: 286,
        radius: 12,
      ),
      _RecoveryMuscleRegion.leftGluteusMaximus: _ellipse(
        left: 316,
        top: 554,
        width: 136,
        height: 132,
      ),
      _RecoveryMuscleRegion.rightGluteusMaximus: _ellipse(
        left: 478,
        top: 554,
        width: 136,
        height: 132,
      ),
      _RecoveryMuscleRegion.leftHamstrings: _roundedRect(
        left: 308,
        top: 724,
        width: 94,
        height: 170,
        radius: 28,
      ),
      _RecoveryMuscleRegion.rightHamstrings: _roundedRect(
        left: 528,
        top: 724,
        width: 94,
        height: 170,
        radius: 28,
      ),
      _RecoveryMuscleRegion.leftGastrocnemius: _roundedRect(
        left: 322,
        top: 955,
        width: 68,
        height: 196,
        radius: 24,
      ),
      _RecoveryMuscleRegion.rightGastrocnemius: _roundedRect(
        left: 540,
        top: 955,
        width: 68,
        height: 196,
        radius: 24,
      ),
    };
    _paths[key] = regionPaths;
  }

  void _initializeMaleFrontPaths() {
    final key = _getKey(_RecoveryBodyType.male, _RecoveryBodyView.front);
    final base = getPaths(_RecoveryBodyType.female, _RecoveryBodyView.front);
    _paths[key] = _cloneMap(base);
  }

  void _initializeMaleBackPaths() {
    final key = _getKey(_RecoveryBodyType.male, _RecoveryBodyView.back);
    final base = getPaths(_RecoveryBodyType.female, _RecoveryBodyView.back);
    _paths[key] = _cloneMap(base);
  }
}

const Map<_RecoveryMuscleRegion, _RecoveryBodyRegion> _frontMuscleRegionMap = {
  _RecoveryMuscleRegion.leftDeltoid: _RecoveryBodyRegion.shoulders,
  _RecoveryMuscleRegion.rightDeltoid: _RecoveryBodyRegion.shoulders,
  _RecoveryMuscleRegion.leftPectoralisMajor: _RecoveryBodyRegion.chest,
  _RecoveryMuscleRegion.rightPectoralisMajor: _RecoveryBodyRegion.chest,
  _RecoveryMuscleRegion.leftBicepsBrachii: _RecoveryBodyRegion.biceps,
  _RecoveryMuscleRegion.rightBicepsBrachii: _RecoveryBodyRegion.biceps,
  _RecoveryMuscleRegion.leftForearmAnterior: _RecoveryBodyRegion.forearms,
  _RecoveryMuscleRegion.rightForearmAnterior: _RecoveryBodyRegion.forearms,
  _RecoveryMuscleRegion.rectusAbdominis: _RecoveryBodyRegion.abs,
  _RecoveryMuscleRegion.leftExternalOblique: _RecoveryBodyRegion.abs,
  _RecoveryMuscleRegion.rightExternalOblique: _RecoveryBodyRegion.abs,
  _RecoveryMuscleRegion.leftQuadricepsFemoris: _RecoveryBodyRegion.quads,
  _RecoveryMuscleRegion.rightQuadricepsFemoris: _RecoveryBodyRegion.quads,
  _RecoveryMuscleRegion.leftTibialisAnterior: _RecoveryBodyRegion.calves,
  _RecoveryMuscleRegion.rightTibialisAnterior: _RecoveryBodyRegion.calves,
};

const Map<_RecoveryMuscleRegion, _RecoveryBodyRegion> _backMuscleRegionMap = {
  _RecoveryMuscleRegion.leftDeltoid: _RecoveryBodyRegion.shoulders,
  _RecoveryMuscleRegion.rightDeltoid: _RecoveryBodyRegion.shoulders,
  _RecoveryMuscleRegion.leftUpperTrapezius: _RecoveryBodyRegion.back,
  _RecoveryMuscleRegion.rightUpperTrapezius: _RecoveryBodyRegion.back,
  _RecoveryMuscleRegion.erectorsSpinae: _RecoveryBodyRegion.back,
  _RecoveryMuscleRegion.leftLatissimusDorsi: _RecoveryBodyRegion.lats,
  _RecoveryMuscleRegion.rightLatissimusDorsi: _RecoveryBodyRegion.lats,
  _RecoveryMuscleRegion.leftTricepsBrachii: _RecoveryBodyRegion.triceps,
  _RecoveryMuscleRegion.rightTricepsBrachii: _RecoveryBodyRegion.triceps,
  _RecoveryMuscleRegion.leftForearmPosterior: _RecoveryBodyRegion.forearms,
  _RecoveryMuscleRegion.rightForearmPosterior: _RecoveryBodyRegion.forearms,
  _RecoveryMuscleRegion.leftGluteusMaximus: _RecoveryBodyRegion.glutes,
  _RecoveryMuscleRegion.rightGluteusMaximus: _RecoveryBodyRegion.glutes,
  _RecoveryMuscleRegion.leftHamstrings: _RecoveryBodyRegion.hamstrings,
  _RecoveryMuscleRegion.rightHamstrings: _RecoveryBodyRegion.hamstrings,
  _RecoveryMuscleRegion.leftGastrocnemius: _RecoveryBodyRegion.calves,
  _RecoveryMuscleRegion.rightGastrocnemius: _RecoveryBodyRegion.calves,
};

final _RecoveryMuscleRegionPaths _recoveryMuscleRegionPaths =
    _RecoveryMuscleRegionPaths();

class _RecoveryMannequinOverlayPainter extends CustomPainter {
  const _RecoveryMannequinOverlayPainter({
    required this.states,
    required this.activeRegions,
    required this.pulse,
    required this.bodyType,
    required this.view,
  });

  final Map<_RecoveryBodyRegion, _RecoveryState> states;
  final Set<_RecoveryBodyRegion> activeRegions;
  final double pulse;
  final _RecoveryBodyType bodyType;
  final _RecoveryBodyView view;

  Size _sourceImageSize() {
    switch (bodyType) {
      case _RecoveryBodyType.female:
        return const Size(1094, 2407);
      case _RecoveryBodyType.male:
        return const Size(1215, 2447);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final musclePaths = _recoveryMuscleRegionPaths.getPaths(bodyType, view);
    if (musclePaths.isEmpty || size.isEmpty) return;

    final mapping =
        view == _RecoveryBodyView.front
            ? _frontMuscleRegionMap
            : _backMuscleRegionMap;

    final outputRect = Offset.zero & size;
    final fitted = applyBoxFit(BoxFit.contain, _sourceImageSize(), size);
    final destinationRect = Alignment.topCenter.inscribe(
      fitted.destination,
      outputRect,
    );

    if (destinationRect.isEmpty) return;

    final scaleMatrix = Float64List.fromList([
      destinationRect.width / _RecoveryMuscleRegionPaths.designWidth,
      0,
      0,
      0,
      0,
      destinationRect.height / _RecoveryMuscleRegionPaths.designHeight,
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
        final aState = states[a.value] ?? _RecoveryState.recovered;
        final bState = states[b.value] ?? _RecoveryState.recovered;
        return _recoveryStatePriority(
          aState,
        ).compareTo(_recoveryStatePriority(bState));
      });

    canvas.save();
    canvas.clipRect(destinationRect);
    for (final entry in orderedEntries) {
      final rawPath = musclePaths[entry.key];
      if (rawPath == null) continue;
      final region = entry.value;
      final state = states[region] ?? _RecoveryState.recovered;
      final emphasized = activeRegions.contains(region);
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
          ..color = _recoveryStateColor(
            state,
          ).withValues(alpha: 0.22 + (0.30 * pulseT));
        canvas.drawPath(animatedPath, glowPaint);
      }

      fillPaint.color = _recoveryOverlayColor(
        state,
        emphasized: emphasized,
        pulse: pulseT,
      );
      outlinePaint.color = _recoveryOutlineColor(
        state,
        emphasized: emphasized,
        pulse: pulseT,
      );
      outlinePaint.strokeWidth = emphasized ? (1.2 + (1.6 * pulseT)) : 1;
      canvas.drawPath(animatedPath, fillPaint);
      canvas.drawPath(animatedPath, outlinePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RecoveryMannequinOverlayPainter oldDelegate) {
    return oldDelegate.states != states ||
        !setEquals(oldDelegate.activeRegions, activeRegions) ||
        oldDelegate.pulse != pulse ||
        oldDelegate.bodyType != bodyType ||
        oldDelegate.view != view;
  }
}

class _RecoveryHeatMapSheet extends StatefulWidget {
  const _RecoveryHeatMapSheet({
    required this.stat,
    required this.allStats,
    required this.heatColor,
    required this.regions,
    required this.userGender,
  });

  final _RecoveryMuscleStat stat;
  final List<_RecoveryMuscleStat> allStats;
  final Color heatColor;
  final Set<_RecoveryBodyRegion> regions;
  final _RecoveryUserGender userGender;

  @override
  State<_RecoveryHeatMapSheet> createState() => _RecoveryHeatMapSheetState();
}

class _RecoveryHeatMapSheetState extends State<_RecoveryHeatMapSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  _RecoveryState _stateFromPercent(int recoveryPercent) {
    if (recoveryPercent >= 80) return _RecoveryState.recovered;
    if (recoveryPercent >= 50) return _RecoveryState.mid;
    return _RecoveryState.fatigued;
  }

  Map<_RecoveryBodyRegion, _RecoveryState> _regionStates() {
    final regionStates = <_RecoveryBodyRegion, _RecoveryState>{
      for (final region in _RecoveryBodyRegion.values)
        region: _RecoveryState.recovered,
    };

    for (final muscleStat in widget.allStats) {
      final state = _stateFromPercent(muscleStat.recoveryPercent);
      final statRegions = _regionsForMuscle(muscleStat.muscleGroup);
      for (final region in statRegions) {
        final current = regionStates[region] ?? _RecoveryState.recovered;
        if (_recoveryStatePriority(state) >= _recoveryStatePriority(current)) {
          regionStates[region] = state;
        }
      }
    }

    return regionStates;
  }

  String _statusLabel() {
    if (widget.stat.recoveryPercent >= 80) return 'Recovered';
    if (widget.stat.recoveryPercent >= 50) return 'Recovering';
    return 'Fatigued';
  }

  String _detailEtaLabel() {
    if (widget.stat.recoveryPercent >= 100 ||
        _remainingRecoveryDuration(widget.stat.lastTrainedAt) ==
            Duration.zero) {
      return 'Recovered';
    }
    return _daysUntilRecoveryText(widget.stat.lastTrainedAt);
  }

  String _detailLastWorkedLabel() {
    return _lastWorkedText(widget.stat.lastTrainedAt);
  }

  Widget _detailInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.3,
                    color: Colors.grey.shade900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(_RecoveryState state, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: _recoveryStateColor(state),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final regionStates = _regionStates();

    return Column(
      children: [
        Container(
          width: 46,
          height: 5,
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.stat.muscleGroup} recovery',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${widget.stat.recoveryPercent}%',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: widget.heatColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _statusLabel(),
            style: TextStyle(
              fontSize: 13,
              color: widget.heatColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (context, _) {
              return Row(
                children: [
                  Expanded(
                    child: _RecoveryMannequinFigure(
                      title: 'Front',
                      front: true,
                      states: regionStates,
                      activeRegions: widget.regions,
                      pulse: _pulse.value,
                      userGender: widget.userGender,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RecoveryMannequinFigure(
                      title: 'Back',
                      front: false,
                      states: regionStates,
                      activeRegions: widget.regions,
                      pulse: _pulse.value,
                      userGender: widget.userGender,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _detailInfoCard(
                icon: Icons.timelapse_rounded,
                label: 'Recovery ETA',
                value: _detailEtaLabel(),
                accent: widget.heatColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _detailInfoCard(
                icon: Icons.history_rounded,
                label: 'Last Worked',
                value: _detailLastWorkedLabel(),
                accent: const Color(0xFF5A6475),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Align(
          alignment: Alignment.bottomCenter,
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _legendItem(_RecoveryState.recovered, 'Recovered'),
              _legendItem(_RecoveryState.mid, 'Mid'),
              _legendItem(_RecoveryState.fatigued, 'Fatigued'),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecoveryMannequinFigure extends StatelessWidget {
  const _RecoveryMannequinFigure({
    required this.title,
    required this.front,
    required this.states,
    required this.activeRegions,
    required this.pulse,
    required this.userGender,
  });

  final String title;
  final bool front;
  final Map<_RecoveryBodyRegion, _RecoveryState> states;
  final Set<_RecoveryBodyRegion> activeRegions;
  final double pulse;
  final _RecoveryUserGender userGender;

  _RecoveryBodyType get _bodyType =>
      userGender == _RecoveryUserGender.female
          ? _RecoveryBodyType.female
          : _RecoveryBodyType.male;

  _RecoveryBodyView get _bodyView =>
      front ? _RecoveryBodyView.front : _RecoveryBodyView.back;

  String _mannequinAssetPath() {
    switch ((userGender, front)) {
      case (_RecoveryUserGender.female, true):
        return '$_recoveryMannequinBasePath/female_front.png';
      case (_RecoveryUserGender.female, false):
        return '$_recoveryMannequinBasePath/female_back.png';
      case (_RecoveryUserGender.male, true):
        return '$_recoveryMannequinBasePath/male_front.png';
      case (_RecoveryUserGender.male, false):
        return '$_recoveryMannequinBasePath/male_back.png';
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
        radius: 999,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.40,
        topFactor: 0.15,
        widthFactor: 0.20,
        heightFactor: 0.26,
        radius: 18,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.22,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: 14,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.66,
        topFactor: 0.16,
        widthFactor: 0.12,
        heightFactor: 0.30,
        radius: 14,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.35,
        topFactor: 0.41,
        widthFactor: 0.30,
        heightFactor: 0.11,
        radius: 18,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.39,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: 14,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.51,
        topFactor: 0.52,
        widthFactor: 0.10,
        heightFactor: 0.30,
        radius: 14,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.39,
        topFactor: 0.83,
        widthFactor: 0.10,
        heightFactor: 0.14,
        radius: 14,
        color: baseColor,
      ),
      _part(
        leftFactor: 0.51,
        topFactor: 0.83,
        widthFactor: 0.10,
        heightFactor: 0.14,
        radius: 14,
        color: baseColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.grey.withValues(alpha: 0.24);

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.24)),
        color: const Color(0xFFF8F8F9),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 165,
                  maxHeight: 350,
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
                          painter: _RecoveryMannequinOverlayPainter(
                            states: states,
                            activeRegions: activeRegions,
                            pulse: pulse,
                            bodyType: _bodyType,
                            view: _bodyView,
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

class _FloatingIslandNav extends StatelessWidget {
  const _FloatingIslandNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.house,
                  label: 'Home',
                ),
                _NavItem(
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.newspaper,
                  label: 'Guides',
                ),
                _NavItem(
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.lightning,
                  label: 'Workouts',
                ),
                _NavItem(
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.chartLine,
                  label: 'Progress',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final PhosphorIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Center(
                child: PhosphorIcon(
                  icon,
                  color: isSelected ? kAccentColor : Colors.black87,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? kAccentColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: isSelected ? 18 : 6,
              height: 2.5,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? kAccentColor
                        : Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

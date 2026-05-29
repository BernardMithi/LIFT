import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/models/workout_template.dart';
import 'package:lift/shared/widgets/lift_action_button.dart';
import 'package:lift/shared/widgets/lift_dialogs.dart';
import 'package:lift/shared/widgets/lift_menu_sheet.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const Color _kGlassGreyTint = Color(0xFFD8DDE3);
const String _kExercisePlaceholderImageUrl =
    'https://blocks.astratic.com/img/general-img-landscape.png';

Color _glassGreyTint(double alpha) => _kGlassGreyTint.withValues(alpha: alpha);

enum _LiveSwapExerciseEquipment {
  machine,
  barbell,
  dumbbell,
  cables,
  bodyweight,
}

extension _LiveSwapExerciseEquipmentX on _LiveSwapExerciseEquipment {
  String get label {
    switch (this) {
      case _LiveSwapExerciseEquipment.machine:
        return 'Machines';
      case _LiveSwapExerciseEquipment.barbell:
        return 'Barbell';
      case _LiveSwapExerciseEquipment.dumbbell:
        return 'Dumbbell';
      case _LiveSwapExerciseEquipment.cables:
        return 'Cables';
      case _LiveSwapExerciseEquipment.bodyweight:
        return 'Bodyweight';
    }
  }
}

class _LiveSwapExerciseCatalogItem {
  const _LiveSwapExerciseCatalogItem({
    required this.name,
    required this.muscleGroups,
    required this.equipment,
    this.keywords = const <String>[],
  });

  final String name;
  final List<String> muscleGroups;
  final _LiveSwapExerciseEquipment equipment;
  final List<String> keywords;
}

const List<_LiveSwapExerciseCatalogItem> _kLiveSwapExerciseCatalog = [
  _LiveSwapExerciseCatalogItem(
    name: 'Leg Press',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['leg', 'press', 'quad'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Hamstring Curls',
    muscleGroups: ['Hamstrings'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['hamstring', 'curl', 'leg'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Leg Extension',
    muscleGroups: ['Quads'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['leg', 'extension', 'quad'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Barbell Back Squat',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _LiveSwapExerciseEquipment.barbell,
    keywords: ['squat', 'barbell', 'leg'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Romanian Deadlift',
    muscleGroups: ['Hamstrings', 'Glutes'],
    equipment: _LiveSwapExerciseEquipment.barbell,
    keywords: ['hinge', 'hamstring', 'deadlift', 'barbell'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Dumbbell Lunges',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _LiveSwapExerciseEquipment.dumbbell,
    keywords: ['lunge', 'dumbbell', 'leg'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Standing Calf Raise',
    muscleGroups: ['Calves'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['calf', 'raise', 'standing', 'lower leg'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Lat Pulldown',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _LiveSwapExerciseEquipment.cables,
    keywords: ['lat', 'pull', 'back'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Seated Row',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _LiveSwapExerciseEquipment.cables,
    keywords: ['row', 'back', 'pull'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Cable Face Pull',
    muscleGroups: ['Back', 'Shoulders'],
    equipment: _LiveSwapExerciseEquipment.cables,
    keywords: ['face', 'pull', 'rear'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Pull Up',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _LiveSwapExerciseEquipment.bodyweight,
    keywords: ['pull', 'up', 'back'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Wrist Curl',
    muscleGroups: ['Forearms'],
    equipment: _LiveSwapExerciseEquipment.dumbbell,
    keywords: ['wrist', 'curl', 'forearm', 'grip'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Chest Press',
    muscleGroups: ['Chest', 'Triceps'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['chest', 'press', 'push'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Shoulder Press',
    muscleGroups: ['Shoulders', 'Triceps'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['shoulder', 'press', 'push'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Lateral Raise',
    muscleGroups: ['Shoulders'],
    equipment: _LiveSwapExerciseEquipment.dumbbell,
    keywords: ['lateral', 'raise', 'shoulder'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Tricep Pushdown',
    muscleGroups: ['Triceps'],
    equipment: _LiveSwapExerciseEquipment.cables,
    keywords: ['tricep', 'pushdown', 'cable'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Bench Press',
    muscleGroups: ['Chest', 'Triceps'],
    equipment: _LiveSwapExerciseEquipment.barbell,
    keywords: ['bench', 'press', 'chest'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Dumbbell Incline Press',
    muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
    equipment: _LiveSwapExerciseEquipment.dumbbell,
    keywords: ['incline', 'press', 'chest'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Push Up',
    muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
    equipment: _LiveSwapExerciseEquipment.bodyweight,
    keywords: ['push', 'up', 'chest'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Ab Crunch Machine',
    muscleGroups: ['Core'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['ab', 'crunch', 'core'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Cable Woodchop',
    muscleGroups: ['Core'],
    equipment: _LiveSwapExerciseEquipment.cables,
    keywords: ['core', 'rotation', 'cable'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Plank',
    muscleGroups: ['Core'],
    equipment: _LiveSwapExerciseEquipment.bodyweight,
    keywords: ['plank', 'core'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Incline Walk',
    muscleGroups: ['Conditioning'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['walk', 'cardio', 'conditioning'],
  ),
  _LiveSwapExerciseCatalogItem(
    name: 'Row Erg',
    muscleGroups: ['Conditioning', 'Back'],
    equipment: _LiveSwapExerciseEquipment.machine,
    keywords: ['row', 'cardio', 'conditioning'],
  ),
];

class LiveWorkoutMiniState {
  const LiveWorkoutMiniState({
    required this.templateName,
    required this.elapsedLabel,
    required this.restLabel,
    required this.currentExerciseName,
    required this.progressLabel,
    required this.isResting,
    required this.isFinished,
  });

  final String templateName;
  final String elapsedLabel;
  final String restLabel;
  final String currentExerciseName;
  final String progressLabel;
  final bool isResting;
  final bool isFinished;
}

class LiveWorkoutSummaryState {
  const LiveWorkoutSummaryState({
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.elapsed,
    required this.totalVolumeKg,
    required this.totalReps,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.prsAchieved,
    required this.exerciseSummaries,
    required this.muscleGroupVolumeKg,
  });

  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration elapsed;
  final double totalVolumeKg;
  final int totalReps;
  final int exercisesCompleted;
  final int totalExercises;
  final int prsAchieved;
  final List<WorkoutHistoryExerciseSummary> exerciseSummaries;
  final Map<String, double> muscleGroupVolumeKg;
}

class LiveWorkoutScreen extends StatefulWidget {
  const LiveWorkoutScreen({
    super.key,
    required this.template,
    required this.onBack,
    required this.onDiscard,
    required this.onCompleteWorkout,
    this.showBottomActions = true,
    this.onStateChanged,
    this.onSummaryChanged,
    this.onAddExerciseActionChanged,
  });

  final WorkoutTemplate template;
  final VoidCallback onBack;
  final VoidCallback onDiscard;
  final VoidCallback onCompleteWorkout;
  final bool showBottomActions;
  final ValueChanged<LiveWorkoutMiniState>? onStateChanged;
  final ValueChanged<LiveWorkoutSummaryState>? onSummaryChanged;
  final ValueChanged<VoidCallback?>? onAddExerciseActionChanged;

  @override
  State<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

enum _LiveSetStatus { upcoming, active, done }

class _LiveExerciseRun {
  _LiveExerciseRun({
    required this.exercise,
    required List<_LiveSetStatus> statuses,
    this.supersetGroupId,
  }) : statuses = List<_LiveSetStatus>.from(statuses, growable: true);

  WorkoutTemplateExercise exercise;
  final List<_LiveSetStatus> statuses;
  String? supersetGroupId;
  bool isExpanded = false;
}

class _LivePointer {
  const _LivePointer(this.exerciseIndex, this.rowIndex);

  final int exerciseIndex;
  final int rowIndex;
}

class _LiveExerciseDragPayload {
  const _LiveExerciseDragPayload({
    required this.anchorExerciseId,
    required this.blockExerciseIds,
    required this.anchorExerciseName,
    required this.isSupersetBlock,
  });

  final String anchorExerciseId;
  final List<String> blockExerciseIds;
  final String anchorExerciseName;
  final bool isSupersetBlock;
}

class _LiveExerciseRunSnapshot {
  const _LiveExerciseRunSnapshot({
    required this.exercise,
    required this.statuses,
    required this.isExpanded,
    required this.supersetGroupId,
  });

  final WorkoutTemplateExercise exercise;
  final List<_LiveSetStatus> statuses;
  final bool isExpanded;
  final String? supersetGroupId;
}

class _LiveWorkoutSnapshot {
  const _LiveWorkoutSnapshot({
    required this.runs,
    required this.restRemainingSeconds,
    required this.isRestTimerActive,
    required this.capturedAt,
  });

  final List<_LiveExerciseRunSnapshot> runs;
  final int restRemainingSeconds;
  final bool isRestTimerActive;
  final DateTime capturedAt;
}

enum _LiveActionKind { setCompletion, swap }

class _LiveActionRecord {
  const _LiveActionRecord({
    required this.snapshot,
    required this.kind,
    this.pointer,
  });

  final _LiveWorkoutSnapshot snapshot;
  final _LiveActionKind kind;
  final _LivePointer? pointer;
}

class _LiveWorkoutScreenState extends State<LiveWorkoutScreen> {
  late final DateTime _startedAt;
  late final List<_LiveExerciseRun> _runs;
  Timer? _ticker;
  bool _isDisposed = false;
  bool _tickFrameScheduled = false;
  int _restRemainingSeconds = 0;
  bool _isRestTimerActive = false;
  final List<_LiveActionRecord> _actionHistory = <_LiveActionRecord>[];
  bool _isSetConfirmDialogOpen = false;
  bool _isExerciseDragInProgress = false;
  int _dynamicExerciseSeed = 0;
  int _supersetGroupSeed = 0;
  bool _announcementsEnabled = true;
  bool _hapticsEnabled = true;
  bool _soundEnabled = true;

  LiveWorkoutMiniState _buildMiniState() {
    final elapsed = DateTime.now().difference(_startedAt);
    final active = _activePointer;
    final activeRun = active == null ? null : _runs[active.exerciseIndex];
    final progressLabel =
        active == null
            ? (_isWorkoutFinished ? 'Workout complete' : 'No active set')
            : 'Ex ${active.exerciseIndex + 1}/${_runs.length} • Set ${active.rowIndex + 1}/${activeRun!.exercise.presetRows.length}';

    return LiveWorkoutMiniState(
      templateName: widget.template.name,
      elapsedLabel: _formatElapsed(elapsed),
      restLabel: _formatRest(_restRemainingSeconds),
      currentExerciseName:
          activeRun?.exercise.name ??
          (_isWorkoutFinished ? 'Workout complete' : 'No exercise yet'),
      progressLabel: progressLabel,
      isResting: _isRestTimerActive,
      isFinished: _isWorkoutFinished,
    );
  }

  LiveWorkoutSummaryState _buildSummaryState() {
    final completedAt = DateTime.now();
    final elapsed = completedAt.difference(_startedAt);
    final baselineById = <String, WorkoutTemplateExercise>{
      for (final exercise in widget.template.exercises) exercise.id: exercise,
    };
    var totalVolumeKg = 0.0;
    var totalReps = 0;
    var exercisesCompleted = 0;
    var prsAchieved = 0;
    final exerciseSummaries = <WorkoutHistoryExerciseSummary>[];
    final muscleGroupVolume = <String, double>{};

    for (final run in _runs) {
      final rows = run.exercise.presetRows;
      var allDone = run.statuses.isNotEmpty && rows.isNotEmpty;
      final baselineExercise = baselineById[run.exercise.id];
      var exerciseSetCount = 0;
      var exerciseTotalReps = 0;
      var exerciseTotalVolume = 0.0;
      var exerciseMaxWeight = 0.0;
      final catalogItem = _catalogItemForExerciseName(run.exercise.name);
      final fallbackMuscles = _heuristicMuscleTagsForName(run.exercise.name);
      final muscles = <String>{
        ...(catalogItem?.muscleGroups ?? fallbackMuscles),
      }.toList(growable: false);

      for (var rowIndex = 0; rowIndex < run.statuses.length; rowIndex++) {
        final status = run.statuses[rowIndex];
        if (status != _LiveSetStatus.done) {
          allDone = false;
          continue;
        }

        if (rowIndex >= rows.length) continue;
        final row = rows[rowIndex];
        final rowVolume = row.weightKg * row.reps;
        totalVolumeKg += rowVolume;
        totalReps += row.reps;
        exerciseSetCount += 1;
        exerciseTotalReps += row.reps;
        exerciseTotalVolume += rowVolume;
        exerciseMaxWeight = math.max(exerciseMaxWeight, row.weightKg);

        final distributionMuscles = muscles.isEmpty ? const ['Other'] : muscles;
        final perMuscleVolume = rowVolume / distributionMuscles.length;
        for (final muscle in distributionMuscles) {
          muscleGroupVolume[muscle] =
              (muscleGroupVolume[muscle] ?? 0) + perMuscleVolume;
        }

        if (baselineExercise != null &&
            rowIndex < baselineExercise.presetRows.length) {
          final baseline = baselineExercise.presetRows[rowIndex];
          final beatsWeight = row.weightKg > baseline.weightKg + 0.001;
          final sameWeight = (row.weightKg - baseline.weightKg).abs() <= 0.001;
          final beatsReps = row.reps > baseline.reps;
          if (beatsWeight || (sameWeight && beatsReps)) {
            prsAchieved += 1;
          }
        }
      }

      if (allDone) {
        exercisesCompleted += 1;
      }

      if (exerciseSetCount > 0) {
        exerciseSummaries.add(
          WorkoutHistoryExerciseSummary(
            exerciseName: run.exercise.name,
            setCount: exerciseSetCount,
            totalReps: exerciseTotalReps,
            totalVolumeKg: exerciseTotalVolume,
            maxWeightKg: exerciseMaxWeight,
            muscleGroups: muscles,
          ),
        );
      }
    }

    return LiveWorkoutSummaryState(
      workoutName: widget.template.name,
      startedAt: _startedAt,
      completedAt: completedAt,
      elapsed: elapsed,
      totalVolumeKg: totalVolumeKg,
      totalReps: totalReps,
      exercisesCompleted: exercisesCompleted,
      totalExercises: _runs.length,
      prsAchieved: prsAchieved,
      exerciseSummaries: List<WorkoutHistoryExerciseSummary>.unmodifiable(
        exerciseSummaries,
      ),
      muscleGroupVolumeKg: Map<String, double>.unmodifiable(muscleGroupVolume),
    );
  }

  void _emitMiniState() {
    widget.onStateChanged?.call(_buildMiniState());
    widget.onSummaryChanged?.call(_buildSummaryState());
  }

  void _handleExternalAddExercise() {
    if (!mounted) return;
    unawaited(_addExerciseAtEnd());
  }

  void _scheduleTickerRefresh() {
    if (_isDisposed || !mounted || _tickFrameScheduled) return;
    _tickFrameScheduled = true;
    final binding = WidgetsBinding.instance;
    binding.addPostFrameCallback((_) {
      _tickFrameScheduled = false;
      if (_isDisposed || !mounted) return;
      setState(() {
        if (_isRestTimerActive) {
          _restRemainingSeconds = math.max(0, _restRemainingSeconds - 1);
          if (_restRemainingSeconds == 0) {
            _isRestTimerActive = false;
          }
        }
      });
      _emitMiniState();
    });
    binding.scheduleFrame();
  }

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _runs =
        widget.template.exercises
            .map(
              (exercise) => _LiveExerciseRun(
                exercise: exercise,
                statuses: List<_LiveSetStatus>.filled(
                  exercise.presetRows.length,
                  _LiveSetStatus.upcoming,
                  growable: true,
                ),
              ),
            )
            .toList();

    if (_runs.isNotEmpty) {
      _runs.first.isExpanded = true;
      if (_runs.first.statuses.isNotEmpty) {
        _runs.first.statuses[0] = _LiveSetStatus.active;
      }
    }

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _scheduleTickerRefresh();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitMiniState();
      widget.onAddExerciseActionChanged?.call(_handleExternalAddExercise);
    });
  }

  @override
  void didUpdateWidget(covariant LiveWorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onAddExerciseActionChanged ==
        widget.onAddExerciseActionChanged) {
      return;
    }
    oldWidget.onAddExerciseActionChanged?.call(null);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onAddExerciseActionChanged?.call(_handleExternalAddExercise);
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.onAddExerciseActionChanged?.call(null);
    _ticker?.cancel();
    super.dispose();
  }

  _LivePointer? get _activePointer {
    for (var exerciseIndex = 0; exerciseIndex < _runs.length; exerciseIndex++) {
      final run = _runs[exerciseIndex];
      for (var rowIndex = 0; rowIndex < run.statuses.length; rowIndex++) {
        if (run.statuses[rowIndex] == _LiveSetStatus.active) {
          return _LivePointer(exerciseIndex, rowIndex);
        }
      }
    }
    return null;
  }

  bool get _isWorkoutFinished => _activePointer == null && _runs.isNotEmpty;

  _LivePointer? get _undoableCompletedPointer {
    if (_actionHistory.isEmpty) return null;
    final last = _actionHistory.last;
    if (last.kind != _LiveActionKind.setCompletion) return null;
    return last.pointer;
  }

  String _formatElapsed(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final mins = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final secs = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$mins:$secs';
  }

  String _formatRest(int seconds) {
    final isOverrun = seconds < 0;
    final totalSeconds = seconds.abs();
    if (totalSeconds >= 3600) {
      final hours = totalSeconds ~/ 3600;
      final mins = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
      return '${isOverrun ? '+' : ''}${hours}h ${mins}m';
    }
    final mins = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (totalSeconds % 60).toString().padLeft(2, '0');
    return '${isOverrun ? '+' : ''}$mins:$secs';
  }

  String _formatWeight(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toStringAsFixed(0)}KG';
    return '${kg.toStringAsFixed(1)}KG';
  }

  String _setLabel(String label) {
    switch (label.toLowerCase()) {
      case 'warmup':
        return 'W';
      case 'working set':
        return 'WK';
      case 'cooldown':
        return 'C';
      default:
        return label;
    }
  }

  bool _isWarmupLabel(String label) => label.trim().toLowerCase() == 'warmup';

  bool _isCooldownLabel(String label) =>
      label.trim().toLowerCase() == 'cooldown';

  bool _isWorkingLikeLabel(String label) {
    final normalized = label.trim().toLowerCase();
    if (normalized == 'working set') return true;
    return int.tryParse(label.trim()) != null;
  }

  String _displaySetLabelForRun(_LiveExerciseRun run, int rowIndex) {
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return '';
    final row = run.exercise.presetRows[rowIndex];
    final label = row.label.trim();
    if (_isWarmupLabel(label)) return 'W';
    if (_isCooldownLabel(label)) return 'C';
    if (_isWorkingLikeLabel(label)) {
      var workingIndex = 0;
      for (var i = 0; i <= rowIndex; i++) {
        final candidate = run.exercise.presetRows[i].label;
        if (_isWorkingLikeLabel(candidate)) {
          workingIndex += 1;
        }
      }
      return '$workingIndex';
    }
    return _setLabel(label);
  }

  void _updateRunRows(int exerciseIndex, List<WorkoutTemplateSetRow> rows) {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    final statuses = List<_LiveSetStatus>.from(run.statuses);
    if (statuses.length > rows.length) {
      statuses.removeRange(rows.length, statuses.length);
    } else if (statuses.length < rows.length) {
      statuses.addAll(
        List<_LiveSetStatus>.filled(
          rows.length - statuses.length,
          _LiveSetStatus.upcoming,
          growable: true,
        ),
      );
    }
    final updatedRun = _LiveExerciseRun(
      exercise: run.exercise.copyWith(
        presetRows: rows,
        setCount: rows.length,
        estimatedMinutes: _estimateExerciseMinutesFromRows(rows),
      ),
      statuses: statuses,
    )..isExpanded = run.isExpanded;
    _runs[exerciseIndex] = updatedRun;
  }

  String _nextSupersetGroupId() {
    _supersetGroupSeed += 1;
    return 'ss_${DateTime.now().millisecondsSinceEpoch}_$_supersetGroupSeed';
  }

  List<int> _indicesForSupersetGroup(String groupId) {
    final indices = <int>[];
    for (var i = 0; i < _runs.length; i++) {
      if (_runs[i].supersetGroupId == groupId) {
        indices.add(i);
      }
    }
    return indices;
  }

  bool _hasSupersetPrev(int index) {
    if (index <= 0 || index >= _runs.length) return false;
    final groupId = _runs[index].supersetGroupId;
    return groupId != null && _runs[index - 1].supersetGroupId == groupId;
  }

  bool _hasSupersetNext(int index) {
    if (index < 0 || index >= _runs.length - 1) return false;
    final groupId = _runs[index].supersetGroupId;
    return groupId != null && _runs[index + 1].supersetGroupId == groupId;
  }

  bool _isFirstInSupersetGroup(int index) {
    if (index < 0 || index >= _runs.length) return false;
    final groupId = _runs[index].supersetGroupId;
    return groupId != null && !_hasSupersetPrev(index);
  }

  bool _isSupersetMember(int index) {
    if (index < 0 || index >= _runs.length) return false;
    return _runs[index].supersetGroupId != null;
  }

  void _normalizeSupersetGroups() {
    final counts = <String, int>{};
    for (final run in _runs) {
      final id = run.supersetGroupId;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
    }
    for (final run in _runs) {
      final id = run.supersetGroupId;
      if (id == null) continue;
      if ((counts[id] ?? 0) < 2) {
        run.supersetGroupId = null;
      }
    }
  }

  void _assignSupersetBetween(int baseIndex, int newIndex) {
    if (baseIndex < 0 ||
        baseIndex >= _runs.length ||
        newIndex < 0 ||
        newIndex >= _runs.length) {
      return;
    }
    final existing = _runs[baseIndex].supersetGroupId;
    final groupId = existing ?? _nextSupersetGroupId();
    _runs[baseIndex].supersetGroupId = groupId;
    _runs[newIndex].supersetGroupId = groupId;
    _normalizeSupersetGroups();
  }

  _LivePointer? _findNextSupersetPointerAfter(_LivePointer current) {
    final groupId = _runs[current.exerciseIndex].supersetGroupId;
    if (groupId == null) return null;
    final groupIndices = _indicesForSupersetGroup(groupId);
    if (groupIndices.length < 2) return null;
    final currentPos = groupIndices.indexOf(current.exerciseIndex);
    if (currentPos == -1) return null;

    // Finish the same "round" (same row index) across the remaining exercises first.
    for (var offset = 1; offset < groupIndices.length; offset++) {
      final index = groupIndices[(currentPos + offset) % groupIndices.length];
      if (current.rowIndex < _runs[index].statuses.length &&
          _runs[index].statuses[current.rowIndex] == _LiveSetStatus.upcoming) {
        return _LivePointer(index, current.rowIndex);
      }
    }

    // Then move to the next working row, keeping group order.
    final maxRows = groupIndices.fold<int>(
      0,
      (maxValue, index) => math.max(maxValue, _runs[index].statuses.length),
    );
    for (var rowIndex = current.rowIndex + 1; rowIndex < maxRows; rowIndex++) {
      for (final index in groupIndices) {
        if (rowIndex < _runs[index].statuses.length &&
            _runs[index].statuses[rowIndex] == _LiveSetStatus.upcoming) {
          return _LivePointer(index, rowIndex);
        }
      }
    }
    return null;
  }

  bool _shouldStartRestAfterCompletion(_LivePointer completedPointer) {
    final groupId = _runs[completedPointer.exerciseIndex].supersetGroupId;
    if (groupId == null) return true;
    final indices = _indicesForSupersetGroup(groupId);
    if (indices.length < 2) return true;

    for (final index in indices) {
      if (index == completedPointer.exerciseIndex) continue;
      if (completedPointer.rowIndex < _runs[index].statuses.length &&
          _runs[index].statuses[completedPointer.rowIndex] ==
              _LiveSetStatus.upcoming) {
        return false;
      }
    }
    return true;
  }

  ({int start, int end})? _blockBoundsForExerciseId(String exerciseId) {
    final index = _runs.indexWhere((run) => run.exercise.id == exerciseId);
    if (index == -1) return null;
    final groupId = _runs[index].supersetGroupId;
    if (groupId == null) return (start: index, end: index);

    var start = index;
    while (start > 0 && _runs[start - 1].supersetGroupId == groupId) {
      start -= 1;
    }
    var end = index;
    while (end < _runs.length - 1 &&
        _runs[end + 1].supersetGroupId == groupId) {
      end += 1;
    }
    return (start: start, end: end);
  }

  _LiveExerciseDragPayload _dragPayloadForIndex(int index) {
    final run = _runs[index];
    final bounds = _blockBoundsForExerciseId(run.exercise.id)!;
    final blockIds = _runs
        .sublist(bounds.start, bounds.end + 1)
        .map((item) => item.exercise.id)
        .toList(growable: false);
    return _LiveExerciseDragPayload(
      anchorExerciseId: run.exercise.id,
      blockExerciseIds: blockIds,
      anchorExerciseName: run.exercise.name,
      isSupersetBlock: run.supersetGroupId != null,
    );
  }

  bool _isReorderBoundaryInsideSuperset(int insertIndex) {
    if (insertIndex <= 0 || insertIndex >= _runs.length) return false;
    final leftGroup = _runs[insertIndex - 1].supersetGroupId;
    final rightGroup = _runs[insertIndex].supersetGroupId;
    return leftGroup != null && leftGroup == rightGroup;
  }

  bool _canAcceptReorderDrop(
    _LiveExerciseDragPayload? payload,
    int insertIndex,
  ) {
    if (payload == null) return false;
    if (insertIndex < 0 || insertIndex > _runs.length) return false;
    if (_isReorderBoundaryInsideSuperset(insertIndex)) return false;
    final bounds = _blockBoundsForExerciseId(payload.anchorExerciseId);
    if (bounds == null) return false;
    return !(insertIndex >= bounds.start && insertIndex <= bounds.end + 1);
  }

  void _moveDraggedBlockToInsertIndex(
    _LiveExerciseDragPayload payload,
    int insertIndex,
  ) {
    final bounds = _blockBoundsForExerciseId(payload.anchorExerciseId);
    if (bounds == null) return;
    if (!_canAcceptReorderDrop(payload, insertIndex)) return;

    setState(() {
      final block = List<_LiveExerciseRun>.from(
        _runs.sublist(bounds.start, bounds.end + 1),
        growable: false,
      );
      final blockLength = block.length;
      _runs.removeRange(bounds.start, bounds.end + 1);

      var normalizedInsert = insertIndex;
      if (normalizedInsert > bounds.end + 1) {
        normalizedInsert -= blockLength;
      }
      normalizedInsert = normalizedInsert.clamp(0, _runs.length);

      _runs.insertAll(normalizedInsert, block);
      _normalizeSupersetGroups();
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  bool _canAcceptSupersetDrop(
    _LiveExerciseDragPayload? payload,
    int targetIndex,
  ) {
    if (payload == null) return false;
    if (targetIndex < 0 || targetIndex >= _runs.length) return false;
    final targetId = _runs[targetIndex].exercise.id;
    if (payload.blockExerciseIds.contains(targetId)) return false;
    final sourceIndex = _runs.indexWhere(
      (run) => run.exercise.id == payload.anchorExerciseId,
    );
    if (sourceIndex == -1) return false;
    final sourceGroupId = _runs[sourceIndex].supersetGroupId;
    final targetGroupId = _runs[targetIndex].supersetGroupId;
    if (sourceGroupId != null && sourceGroupId == targetGroupId) return false;
    return true;
  }

  void _attachDraggedBlockAsSuperset(
    _LiveExerciseDragPayload payload,
    int targetIndex,
  ) {
    if (!_canAcceptSupersetDrop(payload, targetIndex)) return;
    final targetExerciseId = _runs[targetIndex].exercise.id;
    final sourceBounds = _blockBoundsForExerciseId(payload.anchorExerciseId);
    if (sourceBounds == null) return;

    setState(() {
      final sourceBlock = List<_LiveExerciseRun>.from(
        _runs.sublist(sourceBounds.start, sourceBounds.end + 1),
        growable: false,
      );
      _runs.removeRange(sourceBounds.start, sourceBounds.end + 1);

      final targetIndexAfterRemoval = _runs.indexWhere(
        (run) => run.exercise.id == targetExerciseId,
      );
      if (targetIndexAfterRemoval == -1) return;

      final targetGroupId = _runs[targetIndexAfterRemoval].supersetGroupId;
      var insertIndex = targetIndexAfterRemoval + 1;
      if (targetGroupId != null) {
        while (insertIndex < _runs.length &&
            _runs[insertIndex].supersetGroupId == targetGroupId) {
          insertIndex += 1;
        }
      }

      _runs.insertAll(insertIndex, sourceBlock);

      final mergedGroupId = targetGroupId ?? _nextSupersetGroupId();
      _runs[targetIndexAfterRemoval].supersetGroupId = mergedGroupId;
      for (final movedRun in sourceBlock) {
        movedRun.supersetGroupId = mergedGroupId;
      }

      _normalizeSupersetGroups();
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  void _cycleSetTypeAt(int exerciseIndex, int rowIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return;

    setState(() {
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);
      final current = rows[rowIndex];
      final nextLabel =
          _isCooldownLabel(current.label)
              ? 'Warmup'
              : _isWarmupLabel(current.label)
              ? 'Working set'
              : 'Cooldown';
      rows[rowIndex] = current.copyWith(label: nextLabel);
      _updateRunRows(exerciseIndex, rows);
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  Future<void> _editRepsAt(int exerciseIndex, int rowIndex) async {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return;
    final value = await showLiftTextInputDialog<int>(
      context: context,
      title: 'Edit reps',
      initialValue: run.exercise.presetRows[rowIndex].reps.toString(),
      keyboardType: TextInputType.number,
      labelText: 'Reps',
      parser: (value) {
        final reps = int.tryParse(value);
        if (reps == null) return null;
        return reps.clamp(0, 99);
      },
    );
    if (value == null || !mounted) return;
    setState(() {
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);
      rows[rowIndex] = rows[rowIndex].copyWith(reps: value);
      _updateRunRows(exerciseIndex, rows);
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  Future<void> _editWeightAt(int exerciseIndex, int rowIndex) async {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return;
    final selected = await _showWeightPicker(
      run.exercise.presetRows[rowIndex].weightKg,
    );
    if (selected == null || !mounted) return;
    setState(() {
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);
      rows[rowIndex] = rows[rowIndex].copyWith(weightKg: selected);
      _updateRunRows(exerciseIndex, rows);
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  Future<void> _editRestAt(int exerciseIndex, int rowIndex) async {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return;
    final current = run.exercise.presetRows[rowIndex].restSeconds;
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        Duration temp = Duration(seconds: current);
        return SafeArea(
          top: false,
          child: SizedBox(
            height: 340,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Rest Timer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Expanded(
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: Duration(
                      minutes: temp.inMinutes,
                      seconds: temp.inSeconds % 60,
                    ),
                    onTimerDurationChanged: (duration) {
                      temp = duration;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: kAccentColor,
                      ),
                      onPressed: () => Navigator.pop(context, temp.inSeconds),
                      child: const Text('Use rest time'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);
      rows[rowIndex] = rows[rowIndex].copyWith(restSeconds: selected);
      _updateRunRows(exerciseIndex, rows);
      _actionHistory.clear();
    });
    _emitMiniState();
  }

  Future<double?> _showWeightPicker(double initialWeight) async {
    final values = List<double>.generate(161, (i) => i * 2.5);
    int selectedIndex = values.indexWhere(
      (v) => (v - initialWeight).abs() < 0.01,
    );
    if (selectedIndex == -1) {
      selectedIndex = (initialWeight / 2.5).round().clamp(0, values.length - 1);
    }
    double selectedValue = values[selectedIndex];

    return showModalBottomSheet<double>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SizedBox(
                height: 320,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${selectedValue.toStringAsFixed(selectedValue % 1 == 0 ? 0 : 1)} kg',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 36,
                        scrollController: FixedExtentScrollController(
                          initialItem: selectedIndex,
                        ),
                        onSelectedItemChanged: (index) {
                          selectedIndex = index;
                          setModalState(() => selectedValue = values[index]);
                        },
                        children:
                            values
                                .map(
                                  (v) => Center(
                                    child: Text(
                                      '${v.toStringAsFixed(v % 1 == 0 ? 0 : 1)} kg',
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final typed = await _promptTypedWeight(
                                  selectedValue,
                                );
                                if (!context.mounted || typed == null) return;
                                Navigator.pop(context, typed);
                              },
                              child: const Text('Type in'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: kAccentColor,
                              ),
                              onPressed:
                                  () => Navigator.pop(context, selectedValue),
                              child: const Text('Use weight'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<double?> _promptTypedWeight(double currentValue) async {
    final result = await showLiftTextInputDialog<double>(
      context: context,
      title: 'Type weight',
      initialValue: currentValue.toStringAsFixed(currentValue % 1 == 0 ? 0 : 1),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      suffixText: 'kg',
      parser: (value) {
        final parsed = double.tryParse(value);
        if (parsed == null) return null;
        return parsed.clamp(0, 400).toDouble();
      },
    );
    return result;
  }

  _LiveSwapExerciseCatalogItem? _catalogItemForExerciseName(String name) {
    final needle = name.trim().toLowerCase();
    for (final item in _kLiveSwapExerciseCatalog) {
      if (item.name.toLowerCase() == needle) return item;
    }
    for (final item in _kLiveSwapExerciseCatalog) {
      final itemName = item.name.toLowerCase();
      if (itemName.contains(needle) || needle.contains(itemName)) return item;
    }
    return null;
  }

  List<String> _heuristicMuscleTagsForName(String rawName) {
    final name = rawName.toLowerCase();
    final tags = <String>{};
    final isForearmFocused =
        name.contains('forearm') ||
        name.contains('wrist') ||
        name.contains('grip') ||
        name.contains('farmer') ||
        name.contains('reverse curl') ||
        name.contains('pronation') ||
        name.contains('supination');
    if (name.contains('ham')) tags.add('Hamstrings');
    if (name.contains('quad') ||
        name.contains('leg press') ||
        name.contains('squat') ||
        name.contains('leg extension')) {
      tags.add('Quads');
    }
    if (name.contains('glute') ||
        name.contains('leg press') ||
        name.contains('hip')) {
      tags.add('Glutes');
    }
    if (name.contains('lat') || name.contains('row') || name.contains('pull')) {
      tags.add('Back');
    }
    if (isForearmFocused) tags.add('Forearms');
    if ((name.contains('bicep') ||
            (name.contains('curl') && !name.contains('ham'))) &&
        !isForearmFocused &&
        !name.contains('tricep')) {
      tags.add('Biceps');
    }
    if (name.contains('press') && !name.contains('leg')) tags.add('Chest');
    if (name.contains('shoulder') || name.contains('lateral')) {
      tags.add('Shoulders');
    }
    if (name.contains('tricep') ||
        name.contains('pushdown') ||
        name.contains('skull crusher') ||
        name.contains('overhead extension') ||
        name.contains('dip')) {
      tags.add('Triceps');
    }
    if (name.contains('ab') ||
        name.contains('core') ||
        name.contains('plank')) {
      tags.add('Core');
    }
    if (name.contains('cardio') ||
        name.contains('walk') ||
        name.contains('run')) {
      tags.add('Conditioning');
    }
    return tags.toList();
  }

  Set<String> _swapSimilarityTokens(
    String name, [
    List<String> keywords = const [],
  ]) {
    final tokens = <String>{};
    final normalized = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9 ]'),
      ' ',
    );
    for (final token in normalized.split(RegExp(r'\s+'))) {
      if (token.length >= 3) tokens.add(token);
    }
    tokens.addAll(keywords.map((e) => e.toLowerCase()));
    return tokens;
  }

  List<_LiveSwapExerciseCatalogItem> _rankedSwapSuggestions(
    WorkoutTemplateExercise exercise,
  ) {
    final current = _catalogItemForExerciseName(exercise.name);
    final targetMuscles = <String>{
      ...(current?.muscleGroups ?? _heuristicMuscleTagsForName(exercise.name)),
    };
    final targetEquipment = current?.equipment;
    final targetTokens = _swapSimilarityTokens(
      exercise.name,
      current?.keywords ?? const [],
    );

    final scored = <MapEntry<_LiveSwapExerciseCatalogItem, int>>[];
    for (final item in _kLiveSwapExerciseCatalog) {
      if (item.name.toLowerCase() == exercise.name.toLowerCase()) continue;
      final sharedMuscles =
          item.muscleGroups.where(targetMuscles.contains).length;
      final sharedTokens = item.keywords.where(targetTokens.contains).length;
      final nameTokens =
          _swapSimilarityTokens(
            item.name,
            item.keywords,
          ).where(targetTokens.contains).length;

      var score = 0;
      score += sharedMuscles * 4;
      score += sharedTokens * 2;
      score += nameTokens;
      if (targetEquipment != null && item.equipment == targetEquipment) {
        score += 3;
      }
      if (score > 0) scored.add(MapEntry(item, score));
    }

    scored.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.name.compareTo(b.key.name);
    });
    return scored.take(6).map((e) => e.key).toList();
  }

  String _swapExerciseSubtitle(_LiveSwapExerciseCatalogItem item) {
    return '${item.muscleGroups.join(' • ')}  •  ${item.equipment.label}';
  }

  String _nextDynamicExerciseId() {
    _dynamicExerciseSeed += 1;
    return 'live_ex_${DateTime.now().millisecondsSinceEpoch}_$_dynamicExerciseSeed';
  }

  int _estimateExerciseMinutesFromRows(List<WorkoutTemplateSetRow> rows) {
    final totalSeconds =
        rows.fold<int>(0, (sum, row) => sum + row.restSeconds) +
        (rows.length * 45);
    final minutes = (totalSeconds / 60).ceil();
    return minutes.clamp(10, 30);
  }

  WorkoutTemplateExercise _buildLiveExerciseTemplate(String name) {
    final catalogItem = _catalogItemForExerciseName(name);
    final rows = <WorkoutTemplateSetRow>[
      const WorkoutTemplateSetRow(
        label: 'Warmup',
        reps: 12,
        weightKg: 20,
        restSeconds: 90,
      ),
      const WorkoutTemplateSetRow(
        label: '1',
        reps: 10,
        weightKg: 30,
        restSeconds: 120,
      ),
      const WorkoutTemplateSetRow(
        label: '2',
        reps: 10,
        weightKg: 30,
        restSeconds: 120,
      ),
    ];

    final estimatedMinutes = _estimateExerciseMinutesFromRows(rows);

    return WorkoutTemplateExercise(
      id: _nextDynamicExerciseId(),
      name: catalogItem?.name ?? name,
      setCount: rows.length,
      estimatedMinutes: estimatedMinutes,
      presetRows: rows,
    );
  }

  _LivePointer? _firstUpcomingPointer() {
    for (var exerciseIndex = 0; exerciseIndex < _runs.length; exerciseIndex++) {
      final run = _runs[exerciseIndex];
      for (var rowIndex = 0; rowIndex < run.statuses.length; rowIndex++) {
        if (run.statuses[rowIndex] == _LiveSetStatus.upcoming) {
          return _LivePointer(exerciseIndex, rowIndex);
        }
      }
    }
    return null;
  }

  _LiveWorkoutSnapshot _takeSnapshot() {
    return _LiveWorkoutSnapshot(
      restRemainingSeconds: _restRemainingSeconds,
      isRestTimerActive: _isRestTimerActive,
      capturedAt: DateTime.now(),
      runs: _runs
          .map(
            (run) => _LiveExerciseRunSnapshot(
              exercise: run.exercise,
              statuses: List<_LiveSetStatus>.from(run.statuses),
              isExpanded: run.isExpanded,
              supersetGroupId: run.supersetGroupId,
            ),
          )
          .toList(growable: false),
    );
  }

  void _restoreSnapshot(_LiveWorkoutSnapshot snapshot) {
    for (var i = 0; i < _runs.length && i < snapshot.runs.length; i++) {
      final snapRun = snapshot.runs[i];
      final restoredRun = _LiveExerciseRun(
        exercise: snapRun.exercise,
        statuses: List<_LiveSetStatus>.from(snapRun.statuses),
        supersetGroupId: snapRun.supersetGroupId,
      )..isExpanded = snapRun.isExpanded;
      _runs[i] = restoredRun;
    }
    _isRestTimerActive = snapshot.isRestTimerActive;
    if (_isRestTimerActive) {
      final elapsedSinceSnapshot =
          DateTime.now().difference(snapshot.capturedAt).inSeconds;
      _restRemainingSeconds =
          snapshot.restRemainingSeconds - elapsedSinceSnapshot;
    } else {
      _restRemainingSeconds = snapshot.restRemainingSeconds;
    }
  }

  void _pushActionSnapshot(_LiveActionKind kind, {_LivePointer? pointer}) {
    _actionHistory.add(
      _LiveActionRecord(
        snapshot: _takeSnapshot(),
        kind: kind,
        pointer:
            pointer == null
                ? null
                : _LivePointer(pointer.exerciseIndex, pointer.rowIndex),
      ),
    );
    if (_actionHistory.length > 30) {
      _actionHistory.removeAt(0);
    }
  }

  bool _samePointer(_LivePointer? a, int exerciseIndex, int rowIndex) {
    if (a == null) return false;
    return a.exerciseIndex == exerciseIndex && a.rowIndex == rowIndex;
  }

  Future<({int reps, double weightKg})?> _confirmSetCompletionDraft(
    _LivePointer pointer,
  ) async {
    if (_isSetConfirmDialogOpen || !mounted) return null;
    final run = _runs[pointer.exerciseIndex];
    final row = run.exercise.presetRows[pointer.rowIndex];
    var repsText = row.reps.toString();
    var weightText =
        row.weightKg == row.weightKg.roundToDouble()
            ? row.weightKg.toStringAsFixed(0)
            : row.weightKg.toStringAsFixed(1);

    _isSetConfirmDialogOpen = true;
    try {
      return await showDialog<({int reps, double weightKg})>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.42),
        builder: (context) {
          var isClosing = false;
          final setBadge = _setLabel(row.label);

          Widget metricCard({
            required IconData icon,
            required String label,
            required String unit,
            required String value,
            required TextInputType keyboardType,
            required ValueChanged<String> onChanged,
          }) {
            return Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_glassGreyTint(0.20), _glassGreyTint(0.14)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _glassGreyTint(0.30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 14, color: kAccentColor),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      key: ValueKey('$label-$value'),
                      initialValue: value,
                      keyboardType: keyboardType,
                      textAlign: TextAlign.center,
                      onChanged: onChanged,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.74),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 14,
                        ),
                        suffixText: unit.isEmpty ? null : unit,
                        suffixStyle: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _glassGreyTint(0.40),
                            width: 1.1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(14),
                          ),
                          borderSide: BorderSide(
                            color: kAccentColor.withValues(alpha: 0.8),
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget quickAdjustChip({
            required String label,
            required VoidCallback onTap,
          }) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _glassGreyTint(0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _glassGreyTint(0.30)),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: kAccentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          }

          void close([({int reps, double weightKg})? value]) {
            if (isClosing) return;
            isClosing = true;
            Navigator.of(context, rootNavigator: true).pop(value);
          }

          return StatefulBuilder(
            builder: (context, setDialogState) {
              void nudgeReps(int delta) {
                final current = int.tryParse(repsText.trim()) ?? row.reps;
                repsText = math.max(1, current + delta).toString();
                setDialogState(() {});
              }

              void nudgeWeight(double delta) {
                final current =
                    double.tryParse(weightText.trim()) ?? row.weightKg;
                final next = math.max(0, current + delta);
                final snapped = (next * 10).round() / 10;
                weightText =
                    snapped == snapped.roundToDouble()
                        ? snapped.toStringAsFixed(0)
                        : snapped.toStringAsFixed(1);
                setDialogState(() {});
              }

              return Dialog(
                backgroundColor: Colors.transparent,
                insetPadding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 24,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [_glassGreyTint(0.40), _glassGreyTint(0.28)],
                        ),
                        border: Border.all(color: _glassGreyTint(0.34)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 24,
                            offset: Offset.zero,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    _glassGreyTint(0.20),
                                    _glassGreyTint(0.12),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _glassGreyTint(0.32)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: kAccentColor,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Confirm set',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          run.exercise.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey.shade800,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _glassGreyTint(0.22),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _glassGreyTint(0.32),
                                      ),
                                    ),
                                    child: Text(
                                      'SET $setBadge',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: kAccentColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                metricCard(
                                  icon: Icons.repeat_rounded,
                                  label: 'Reps',
                                  unit: '',
                                  value: repsText,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => repsText = value,
                                ),
                                const SizedBox(width: 10),
                                metricCard(
                                  icon: Icons.fitness_center_rounded,
                                  label: 'Weight',
                                  unit: 'KG',
                                  value: weightText,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  onChanged: (value) => weightText = value,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      quickAdjustChip(
                                        label: '-1 rep',
                                        onTap: () => nudgeReps(-1),
                                      ),
                                      quickAdjustChip(
                                        label: '+1 rep',
                                        onTap: () => nudgeReps(1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      quickAdjustChip(
                                        label: '-2.5kg',
                                        onTap: () => nudgeWeight(-2.5),
                                      ),
                                      quickAdjustChip(
                                        label: '+2.5kg',
                                        onTap: () => nudgeWeight(2.5),
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
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kAccentColor,
                                      backgroundColor: _glassGreyTint(0.16),
                                      side: BorderSide(
                                        color: _glassGreyTint(0.32),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: () => close(),
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: kAccentColor,
                                      elevation: 0,
                                      shadowColor: Colors.transparent,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (isClosing) return;
                                      final reps = int.tryParse(
                                        repsText.trim(),
                                      );
                                      final weight = double.tryParse(
                                        weightText.trim(),
                                      );
                                      if (reps == null ||
                                          reps <= 0 ||
                                          weight == null ||
                                          weight < 0) {
                                        return;
                                      }
                                      close((reps: reps, weightKg: weight));
                                    },
                                    child: const Text(
                                      'Log Set',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      _isSetConfirmDialogOpen = false;
    }
  }

  Future<String?> _pickSwapExerciseName(
    WorkoutTemplateExercise replacing, {
    bool allowSameSelection = false,
    String title = 'Swap exercise',
    String? subtitle,
  }) async {
    final currentCatalogItem = _catalogItemForExerciseName(replacing.name);
    final suggested = _rankedSwapSuggestions(replacing);
    final allMuscleGroups =
        _kLiveSwapExerciseCatalog
            .expand((item) => item.muscleGroups)
            .toSet()
            .toList()
          ..sort();

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String? selectedMuscleGroup =
            currentCatalogItem?.muscleGroups.isNotEmpty == true
                ? currentCatalogItem!.muscleGroups.first
                : null;
        _LiveSwapExerciseEquipment? selectedEquipment =
            currentCatalogItem?.equipment;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered =
                _kLiveSwapExerciseCatalog.where((item) {
                    final matchesMuscle =
                        selectedMuscleGroup == null ||
                        item.muscleGroups.contains(selectedMuscleGroup);
                    final matchesEquipment =
                        selectedEquipment == null ||
                        item.equipment == selectedEquipment;
                    return matchesMuscle && matchesEquipment;
                  }).toList()
                  ..sort((a, b) => a.name.compareTo(b.name));

            return SafeArea(
              top: false,
              child: SizedBox(
                height: math.min(MediaQuery.sizeOf(context).height * 0.84, 700),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle ?? 'Replacing ${replacing.name}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          if (suggested.isNotEmpty) ...[
                            const _LiveSwapSectionTitle('Suggested Exercises'),
                            const SizedBox(height: 8),
                            ...suggested.map(
                              (item) => _LiveSwapExerciseTile(
                                title: item.name,
                                subtitle: _swapExerciseSubtitle(item),
                                isCurrent: item.name == replacing.name,
                                onTap: () => Navigator.pop(context, item.name),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const _LiveSwapSectionTitle('Muscle Groups'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: selectedMuscleGroup == null,
                                onSelected: (_) {
                                  setModalState(
                                    () => selectedMuscleGroup = null,
                                  );
                                },
                              ),
                              ...allMuscleGroups.map(
                                (group) => ChoiceChip(
                                  label: Text(group),
                                  selected: selectedMuscleGroup == group,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedMuscleGroup =
                                          selectedMuscleGroup == group
                                              ? null
                                              : group;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _LiveSwapSectionTitle('Equipment'),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('All'),
                                selected: selectedEquipment == null,
                                onSelected: (_) {
                                  setModalState(() => selectedEquipment = null);
                                },
                              ),
                              ..._LiveSwapExerciseEquipment.values.map(
                                (equipment) => ChoiceChip(
                                  label: Text(equipment.label),
                                  selected: selectedEquipment == equipment,
                                  onSelected: (_) {
                                    setModalState(() {
                                      selectedEquipment =
                                          selectedEquipment == equipment
                                              ? null
                                              : equipment;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _LiveSwapSectionTitle(
                            'Exercises (${filtered.length})',
                          ),
                          const SizedBox(height: 8),
                          ...filtered.map(
                            (item) => _LiveSwapExerciseTile(
                              title: item.name,
                              subtitle: _swapExerciseSubtitle(item),
                              isCurrent: item.name == replacing.name,
                              onTap: () => Navigator.pop(context, item.name),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null) return null;
    if (!allowSameSelection && selected == replacing.name) return null;
    return selected;
  }

  Future<void> _swapExerciseAt(int index) async {
    final selected = await _pickSwapExerciseName(_runs[index].exercise);
    if (selected == null || !mounted) return;
    setState(() {
      _pushActionSnapshot(_LiveActionKind.swap);
      _runs[index].exercise = _runs[index].exercise.copyWith(name: selected);
    });
    _emitMiniState();
  }

  Future<bool?> _promptAddExerciseMode({
    required bool canAddSuperset,
    String title = 'Add exercise',
  }) async {
    if (!canAddSuperset) return false;
    return showModalBottomSheet<bool>(
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
              title: title,
              subtitle: 'Choose how to insert the next movement.',
              children: [
                LiftMenuActionTile(
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  title: 'Add as new exercise',
                  subtitle: 'Creates a standalone exercise card',
                  accent: kAccentColor,
                  onTap: () => Navigator.pop(sheetContext, false),
                ),
                const SizedBox(height: 8),
                LiftMenuActionTile(
                  icon: const Icon(Icons.link_rounded),
                  title: 'Add as superset',
                  subtitle:
                      'Adds it to the same superset block as the previous exercise',
                  accent: const Color(0xFF0A7A6B),
                  onTap: () => Navigator.pop(sheetContext, true),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addExerciseAfter(int index, {bool asSuperset = false}) async {
    if (index < 0 || index >= _runs.length) return;
    final baseExercise = _runs[index].exercise;
    final selected = await _pickSwapExerciseName(
      baseExercise,
      allowSameSelection: true,
      title: 'Add exercise',
      subtitle: 'Add after ${baseExercise.name}',
    );
    if (selected == null || !mounted) return;

    setState(() {
      final activeBefore = _activePointer;
      final newExercise = _buildLiveExerciseTemplate(selected);
      final newRun = _LiveExerciseRun(
        exercise: newExercise,
        statuses: List<_LiveSetStatus>.filled(
          newExercise.presetRows.length,
          _LiveSetStatus.upcoming,
          growable: true,
        ),
      );
      newRun.isExpanded = true;

      for (final run in _runs) {
        run.isExpanded = false;
      }

      var insertAt = index + 1;
      if (insertAt < 0) insertAt = 0;
      if (insertAt > _runs.length) insertAt = _runs.length;
      _runs.insert(insertAt, newRun);
      if (asSuperset) {
        _assignSupersetBetween(index, insertAt);
      }

      _actionHistory.clear();

      final hasActive = _activePointer != null;
      if (!hasActive && newRun.statuses.isNotEmpty) {
        newRun.statuses[0] = _LiveSetStatus.active;
        _isRestTimerActive = false;
        _restRemainingSeconds = 0;
      } else if (activeBefore != null) {
        final activeIndex =
            activeBefore.exerciseIndex >= insertAt
                ? activeBefore.exerciseIndex + 1
                : activeBefore.exerciseIndex;
        if (activeIndex >= 0 &&
            activeIndex < _runs.length &&
            activeBefore.rowIndex < _runs[activeIndex].statuses.length) {
          _runs[activeIndex].isExpanded = false;
        }
      }
    });
    _emitMiniState();
  }

  Future<void> _addExerciseAtEnd() async {
    final addAsSuperset = await _promptAddExerciseMode(
      canAddSuperset: _runs.isNotEmpty,
    );
    if (addAsSuperset == null || !mounted) return;

    if (_runs.isEmpty) {
      final seedExercise = _buildLiveExerciseTemplate(
        _kLiveSwapExerciseCatalog.first.name,
      );
      final selected = await _pickSwapExerciseName(
        seedExercise,
        allowSameSelection: true,
        title: 'Add exercise',
        subtitle: 'Add an exercise to this live workout',
      );
      if (selected == null || !mounted) return;
      setState(() {
        final newExercise = _buildLiveExerciseTemplate(selected);
        final statuses = List<_LiveSetStatus>.filled(
          newExercise.presetRows.length,
          _LiveSetStatus.upcoming,
          growable: true,
        );
        final noActiveSet = _activePointer == null;
        if (noActiveSet && statuses.isNotEmpty) {
          statuses[0] = _LiveSetStatus.active;
          _isRestTimerActive = false;
          _restRemainingSeconds = 0;
        }
        final run = _LiveExerciseRun(exercise: newExercise, statuses: statuses)
          ..isExpanded = true;
        _runs.add(run);
        _actionHistory.clear();
      });
      _emitMiniState();
      return;
    }

    await _addExerciseAfter(_runs.length - 1, asSuperset: addAsSuperset);
  }

  void _deleteExerciseAt(int index) {
    if (index < 0 || index >= _runs.length) return;
    if (_runs.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one exercise is required in a live workout.'),
        ),
      );
      return;
    }

    setState(() {
      final runBeingRemoved = _runs[index];
      final removedHadActiveSet = runBeingRemoved.statuses.contains(
        _LiveSetStatus.active,
      );

      _runs.removeAt(index);
      _normalizeSupersetGroups();
      _actionHistory.clear();

      if (removedHadActiveSet) {
        final next = _firstUpcomingPointer();
        if (next != null) {
          for (final run in _runs) {
            run.isExpanded = false;
          }
          _runs[next.exerciseIndex].isExpanded = true;
          _runs[next.exerciseIndex].statuses[next.rowIndex] =
              _LiveSetStatus.active;
        } else {
          _isRestTimerActive = false;
          _restRemainingSeconds = 0;
        }
      }
    });
    _emitMiniState();
  }

  void _deleteSetAt(int exerciseIndex, int rowIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final run = _runs[exerciseIndex];
    if (rowIndex < 0 || rowIndex >= run.exercise.presetRows.length) return;

    if (run.exercise.presetRows.length <= 1) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least one set is required in an exercise.'),
        ),
      );
      return;
    }

    setState(() {
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows)
        ..removeAt(rowIndex);
      final statuses = List<_LiveSetStatus>.from(run.statuses)
        ..removeAt(rowIndex);

      final updatedRun = _LiveExerciseRun(
        exercise: run.exercise.copyWith(
          presetRows: rows,
          setCount: rows.length,
          estimatedMinutes: _estimateExerciseMinutesFromRows(rows),
        ),
        statuses: statuses,
      )..isExpanded = run.isExpanded;

      _runs[exerciseIndex] = updatedRun;
      _actionHistory.clear();

      final activeAfter = _activePointer;
      if (activeAfter == null) {
        final next = _firstUpcomingPointer();
        if (next != null) {
          for (final item in _runs) {
            item.isExpanded = false;
          }
          _runs[next.exerciseIndex].isExpanded = true;
          _runs[next.exerciseIndex].statuses[next.rowIndex] =
              _LiveSetStatus.active;
        } else {
          _isRestTimerActive = false;
          _restRemainingSeconds = 0;
        }
      }
    });

    _emitMiniState();
  }

  _LivePointer? _findNextUpcomingPointerFrom(_LivePointer current) {
    for (
      var exerciseIndex = current.exerciseIndex;
      exerciseIndex < _runs.length;
      exerciseIndex++
    ) {
      final run = _runs[exerciseIndex];
      final startRow =
          exerciseIndex == current.exerciseIndex ? current.rowIndex + 1 : 0;
      for (
        var rowIndex = startRow;
        rowIndex < run.statuses.length;
        rowIndex++
      ) {
        if (run.statuses[rowIndex] == _LiveSetStatus.upcoming) {
          return _LivePointer(exerciseIndex, rowIndex);
        }
      }
    }
    return null;
  }

  Future<void> _confirmAndCompleteCurrentSet() async {
    final active = _activePointer;
    if (active == null) return;
    await _confirmAndCompleteSetAt(active);
  }

  Future<void> _confirmAndCompleteSetAt(_LivePointer pointer) async {
    final status = _runs[pointer.exerciseIndex].statuses[pointer.rowIndex];
    if (status == _LiveSetStatus.done) return;
    final draft = await _confirmSetCompletionDraft(pointer);
    if (draft == null || !mounted) return;
    _completeSetAtPointer(
      pointer,
      repsOverride: draft.reps,
      weightOverrideKg: draft.weightKg,
    );
  }

  void _completeSetAtPointer(
    _LivePointer target, {
    int? repsOverride,
    double? weightOverrideKg,
  }) {
    if (target.exerciseIndex < 0 || target.exerciseIndex >= _runs.length) {
      return;
    }
    if (target.rowIndex < 0 ||
        target.rowIndex >= _runs[target.exerciseIndex].statuses.length) {
      return;
    }
    if (_runs[target.exerciseIndex].statuses[target.rowIndex] ==
        _LiveSetStatus.done) {
      return;
    }

    setState(() {
      _pushActionSnapshot(_LiveActionKind.setCompletion, pointer: target);
      final previousActive = _activePointer;
      if (previousActive != null &&
          !(previousActive.exerciseIndex == target.exerciseIndex &&
              previousActive.rowIndex == target.rowIndex)) {
        _runs[previousActive.exerciseIndex].statuses[previousActive.rowIndex] =
            _LiveSetStatus.upcoming;
      }

      final run = _runs[target.exerciseIndex];
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);
      final originalRow = rows[target.rowIndex];
      final completedRow = originalRow.copyWith(
        reps: repsOverride ?? originalRow.reps,
        weightKg: weightOverrideKg ?? originalRow.weightKg,
      );
      rows[target.rowIndex] = completedRow;
      run.exercise = run.exercise.copyWith(
        presetRows: rows,
        setCount: rows.length,
        estimatedMinutes: _estimateExerciseMinutesFromRows(rows),
      );
      run.statuses[target.rowIndex] = _LiveSetStatus.done;

      final next =
          _findNextSupersetPointerAfter(target) ??
          _findNextUpcomingPointerFrom(target) ??
          _firstUpcomingPointer();
      if (next != null) {
        if (_shouldStartRestAfterCompletion(target)) {
          _restRemainingSeconds = completedRow.restSeconds;
          _isRestTimerActive = true;
        } else {
          _restRemainingSeconds = 0;
          _isRestTimerActive = false;
        }
        for (final item in _runs) {
          item.isExpanded = false;
        }
        _runs[next.exerciseIndex].isExpanded = true;
        _runs[next.exerciseIndex].statuses[next.rowIndex] =
            _LiveSetStatus.active;
      } else {
        _restRemainingSeconds = 0;
        _isRestTimerActive = false;
      }
    });
    _emitMiniState();
  }

  void _addSetToExercise(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= _runs.length) return;
    final activeBefore = _activePointer;

    setState(() {
      final run = _runs[exerciseIndex];
      final rows = List<WorkoutTemplateSetRow>.from(run.exercise.presetRows);

      final fallback = const WorkoutTemplateSetRow(
        label: 'Working set',
        reps: 10,
        weightKg: 20,
        restSeconds: 90,
      );
      final lastWorkingIndex = rows.lastIndexWhere(
        (row) => row.label.toLowerCase() == 'working set',
      );
      final baseRow =
          rows.isEmpty
              ? fallback
              : (lastWorkingIndex >= 0 ? rows[lastWorkingIndex] : rows.last);
      final normalizedLabel =
          baseRow.label.toLowerCase() == 'cooldown'
              ? 'Working set'
              : baseRow.label;
      rows.add(baseRow.copyWith(label: normalizedLabel));

      final nextStatuses = List<_LiveSetStatus>.from(run.statuses);
      final noActiveSet = activeBefore == null;
      final shouldActivateNewRow =
          noActiveSet &&
          (exerciseIndex == _runs.length - 1 || _isWorkoutFinished);
      nextStatuses.add(
        shouldActivateNewRow ? _LiveSetStatus.active : _LiveSetStatus.upcoming,
      );

      final nextExercise = run.exercise.copyWith(
        presetRows: rows,
        setCount: rows.length,
        estimatedMinutes: _estimateExerciseMinutesFromRows(rows),
      );
      final updatedRun = _LiveExerciseRun(
        exercise: nextExercise,
        statuses: nextStatuses,
      )..isExpanded = run.isExpanded;
      _runs[exerciseIndex] = updatedRun;
      _actionHistory.clear();

      if (shouldActivateNewRow) {
        updatedRun.isExpanded = true;
        _restRemainingSeconds = 0;
        _isRestTimerActive = false;
      }
    });

    _emitMiniState();
  }

  void _undoSetCompletionFromTick(int exerciseIndex, int rowIndex) {
    if (_actionHistory.isEmpty) return;
    final last = _actionHistory.last;
    if (last.kind != _LiveActionKind.setCompletion) return;
    if (!_samePointer(last.pointer, exerciseIndex, rowIndex)) return;
    setState(() {
      final record = _actionHistory.removeLast();
      _restoreSnapshot(record.snapshot);
    });
    _emitMiniState();
  }

  void _toggleExercise(int index) {
    setState(() {
      _runs[index].isExpanded = !_runs[index].isExpanded;
    });
    _emitMiniState();
  }

  Future<void> _confirmDiscard() async {
    final confirmed = await showLiftConfirmDialog(
      context: context,
      title: 'Discard workout?',
      message:
          'This will leave the live workout session and lose unsaved progress in this prototype.',
      confirmLabel: 'Discard',
      confirmColor: Colors.red.shade600,
    );
    if (confirmed == true && mounted) {
      widget.onDiscard();
    }
  }

  void _addRestTimeFromOptions(int seconds) {
    setState(() {
      _restRemainingSeconds += seconds;
      _isRestTimerActive = true;
    });
    _emitMiniState();
  }

  Future<void> _openTimerOptionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            void updateSetting(void Function() update) {
              if (!mounted) return;
              setState(update);
              modalSetState(() {});
            }

            return SafeArea(
              top: false,
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  10 +
                      MediaQuery.paddingOf(context).bottom +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: LiftMenuSheet(
                  title: 'Timer options',
                  subtitle: 'Adjust rest time and session feedback.',
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                  children: [
                    const SizedBox(height: 2),
                    const Text(
                      'Add time',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _TimerOptionChip(
                          label: '+15s',
                          onTap: () => _addRestTimeFromOptions(15),
                        ),
                        _TimerOptionChip(
                          label: '+30s',
                          onTap: () => _addRestTimeFromOptions(30),
                        ),
                        _TimerOptionChip(
                          label: '+60s',
                          onTap: () => _addRestTimeFromOptions(60),
                        ),
                        _TimerOptionChip(
                          label: '+2m',
                          onTap: () => _addRestTimeFromOptions(120),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _TimerSettingTile(
                      title: 'Announcements',
                      subtitle: 'Voice time cues',
                      value: _announcementsEnabled,
                      onChanged:
                          (value) => updateSetting(
                            () => _announcementsEnabled = value,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _TimerSettingTile(
                      title: 'Haptics',
                      subtitle: 'Vibration cues',
                      value: _hapticsEnabled,
                      onChanged:
                          (value) =>
                              updateSetting(() => _hapticsEnabled = value),
                    ),
                    const SizedBox(height: 10),
                    _TimerSettingTile(
                      title: 'Sound',
                      subtitle: 'Audio alerts',
                      value: _soundEnabled,
                      onChanged:
                          (value) =>
                              updateSetting(() => _soundEnabled = value),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showPlaceholderAction(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label coming next')));
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(_startedAt);
    final active = _activePointer;
    final undoableCompleted = _undoableCompletedPointer;
    final activeRun = active == null ? null : _runs[active.exerciseIndex];
    final activeRow =
        (active == null || activeRun == null)
            ? null
            : activeRun.exercise.presetRows[active.rowIndex];
    final activeSetDisplayLabel =
        (active == null || activeRun == null)
            ? null
            : _displaySetLabelForRun(activeRun, active.rowIndex);
    final exerciseProgressText =
        active == null
            ? (_isWorkoutFinished ? 'Workout complete' : 'No active set')
            : 'Exercise ${active.exerciseIndex + 1} of ${_runs.length} • Set ${active.rowIndex + 1} of ${activeRun!.exercise.presetRows.length}';

    return SizedBox.expand(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.93),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: _glassGreyTint(0.24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 14,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: _isSetConfirmDialogOpen ? null : widget.onBack,
                        borderRadius: BorderRadius.circular(18),
                        child: Ink(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.grey.shade300),
                            color: Colors.white,
                          ),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 28,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 260),
                            child: GlassContainer(
                              borderRadius: 18,
                              blur: 12,
                              showSheen: false,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _formatElapsed(elapsed),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    exerciseProgressText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 46),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GlassContainer(
                    borderRadius: 22,
                    blur: 14,
                    showBorder: false,
                    showSheen: false,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: SizedBox(
                      height: 92,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 142),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MetricRow(
                                    icon: Icons.favorite_rounded,
                                    label: 'BPM',
                                    value: '—',
                                  ),
                                  const SizedBox(height: 8),
                                  _MetricRow(
                                    icon: Icons.local_fire_department_rounded,
                                    label: 'KCAL',
                                    value: '—',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 86,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'REST TIME',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    height: 42,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatRest(_restRemainingSeconds),
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontSize: 34,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              tooltip: 'Workout options',
                              onPressed: _openTimerOptionsSheet,
                              icon: const Icon(Icons.menu_rounded, size: 28),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'NEXT EXERCISE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _NextSetPreviewCard(
                    exerciseName:
                        activeRun?.exercise.name ??
                        (_isWorkoutFinished
                            ? 'Workout complete'
                            : 'No exercise yet'),
                    row: activeRow,
                    setDisplayValue: activeSetDisplayLabel,
                    weightFormatter: _formatWeight,
                    onComplete:
                        active == null ? null : _confirmAndCompleteCurrentSet,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const footerSectionHeight = 76.0;
                final showBottomActions = widget.showBottomActions;

                Widget footerButtonsPlate() {
                  return GlassIsland(
                    height: footerSectionHeight,
                    borderRadius: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: LiftActionButton(
                            label: 'Discard',
                            color: Colors.red.shade400,
                            onTap: _confirmDiscard,
                          ),
                        ),
                        const SizedBox(width: 10),
                        LiftActionIconButton(
                          icon: Icons.add_rounded,
                          color: kAccentColor,
                          size: 48,
                          iconSize: 24,
                          borderRadius: 18,
                          onTap: _addExerciseAtEnd,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiftActionButton(
                            label: 'Complete',
                            onTap: widget.onCompleteWorkout,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                Widget footerActionSection() {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: footerButtonsPlate(),
                    ),
                  );
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          bottom:
                              showBottomActions ? footerSectionHeight + 16 : 16,
                        ),
                        itemCount: _runs.length + 1,
                        itemBuilder: (context, index) {
                          Widget buildInsertDropZone(int insertIndex) {
                            final boundaryLocked =
                                _isReorderBoundaryInsideSuperset(insertIndex);
                            if (boundaryLocked) {
                              return const SizedBox(height: 2);
                            }

                            return DragTarget<_LiveExerciseDragPayload>(
                              onWillAcceptWithDetails:
                                  (details) => _canAcceptReorderDrop(
                                    details.data,
                                    insertIndex,
                                  ),
                              onAcceptWithDetails:
                                  (details) => _moveDraggedBlockToInsertIndex(
                                    details.data,
                                    insertIndex,
                                  ),
                              builder: (context, candidates, rejected) {
                                final hovering =
                                    candidates.isNotEmpty &&
                                    _canAcceptReorderDrop(
                                      candidates.last,
                                      insertIndex,
                                    );
                                final showTrack =
                                    _isExerciseDragInProgress || hovering;
                                final placeholderHeight =
                                    (() {
                                      if (!hovering) {
                                        return showTrack ? 10.0 : 4.0;
                                      }
                                      final payload = candidates.last;
                                      if (payload == null) return 92.0;
                                      return payload.isSupersetBlock
                                          ? 118.0
                                          : 98.0;
                                    })();
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 170),
                                  curve: Curves.easeOutCubic,
                                  height: placeholderHeight,
                                  margin: EdgeInsets.only(
                                    top: hovering ? 2 : 0,
                                    bottom: hovering ? 8 : 0,
                                  ),
                                  child: Center(
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 170,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      width: double.infinity,
                                      decoration:
                                          hovering
                                              ? BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                color: Colors.white.withValues(
                                                  alpha: 0.40,
                                                ),
                                                border: Border.all(
                                                  color: kAccentColor
                                                      .withValues(alpha: 0.26),
                                                ),
                                              )
                                              : null,
                                      child:
                                          hovering
                                              ? Center(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    color: Colors.white
                                                        .withValues(
                                                          alpha: 0.62,
                                                        ),
                                                    border: Border.all(
                                                      color: kAccentColor
                                                          .withValues(
                                                            alpha: 0.20,
                                                          ),
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    'Drop to reorder',
                                                    style: TextStyle(
                                                      color: kAccentColor,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              : Center(
                                                child: AnimatedContainer(
                                                  duration: const Duration(
                                                    milliseconds: 170,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  height: 2,
                                                  width: showTrack ? 96 : 36,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                    color:
                                                        showTrack
                                                            ? kAccentColor
                                                                .withValues(
                                                                  alpha: 0.18,
                                                                )
                                                            : Colors
                                                                .transparent,
                                                  ),
                                                ),
                                              ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }

                          if (index == _runs.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                children: [
                                  if (_runs.isNotEmpty)
                                    buildInsertDropZone(_runs.length),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            );
                          }

                          final run = _runs[index];
                          final isCurrentExercise =
                              active?.exerciseIndex == index;
                          final exerciseId = run.exercise.id;
                          final isSupersetMember = _isSupersetMember(index);
                          final isSupersetLead = _isFirstInSupersetGroup(index);
                          final hasSupersetNext = _hasSupersetNext(index);
                          final dragPayload = _dragPayloadForIndex(index);
                          final draggedExerciseCount =
                              dragPayload.blockExerciseIds.length;
                          final draggedSetCount = dragPayload.blockExerciseIds
                              .fold<int>(0, (sum, id) {
                                final runIndex = _runs.indexWhere(
                                  (item) => item.exercise.id == id,
                                );
                                if (runIndex == -1) return sum;
                                return sum +
                                    _runs[runIndex].exercise.presetRows.length;
                              });
                          final supersetCard = _LiveExerciseCard(
                            run: run,
                            isCurrentExercise: isCurrentExercise,
                            onToggle: () => _toggleExercise(index),
                            setDisplayLabelForRow:
                                (rowIndex) =>
                                    _displaySetLabelForRun(run, rowIndex),
                            restFormatter: _formatRest,
                            weightFormatter: _formatWeight,
                            onStats:
                                () => _showPlaceholderAction('Exercise stats'),
                            onSwap: () => _swapExerciseAt(index),
                            onAddSet: () => _addSetToExercise(index),
                            onDeleteRow:
                                (rowIndex) => _deleteSetAt(index, rowIndex),
                            onTapSetLabel:
                                (rowIndex) => _cycleSetTypeAt(index, rowIndex),
                            onTapReps:
                                (rowIndex) => _editRepsAt(index, rowIndex),
                            onTapWeight:
                                (rowIndex) => _editWeightAt(index, rowIndex),
                            onTapRest:
                                (rowIndex) => _editRestAt(index, rowIndex),
                            onCompleteRow: (rowIndex) {
                              _confirmAndCompleteSetAt(
                                _LivePointer(index, rowIndex),
                              );
                            },
                            onUndoRow: (rowIndex) {
                              _undoSetCompletionFromTick(index, rowIndex);
                            },
                            isUndoableDoneRow:
                                (rowIndex) => _samePointer(
                                  undoableCompleted,
                                  index,
                                  rowIndex,
                                ),
                          );
                          final cardBody = ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Dismissible(
                              key: ValueKey('live-exercise-$exerciseId'),
                              direction: DismissDirection.endToStart,
                              background: const SizedBox.expand(),
                              confirmDismiss: (_) async {
                                if (_runs.length <= 1) {
                                  if (!mounted) return false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'At least one exercise is required in a live workout.',
                                      ),
                                    ),
                                  );
                                  return false;
                                }
                                return true;
                              },
                              onDismissed: (_) {
                                final deleteIndex = _runs.indexWhere(
                                  (item) => item.exercise.id == exerciseId,
                                );
                                if (deleteIndex >= 0) {
                                  _deleteExerciseAt(deleteIndex);
                                }
                              },
                              secondaryBackground: const _SwipeDeleteReveal(
                                borderRadius: 16,
                                iconSize: 24,
                              ),
                              child:
                                  isSupersetMember
                                      ? Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          color: kAccentColor.withValues(
                                            alpha: 0.03,
                                          ),
                                          border: Border.all(
                                            color: kAccentColor.withValues(
                                              alpha: 0.14,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            if (isSupersetLead) ...[
                                              const _LiveSupersetBadge(),
                                              const SizedBox(height: 6),
                                            ],
                                            supersetCard,
                                          ],
                                        ),
                                      )
                                      : supersetCard,
                            ),
                          );
                          final cardSupersetTarget =
                              DragTarget<_LiveExerciseDragPayload>(
                                onWillAcceptWithDetails:
                                    (details) => _canAcceptSupersetDrop(
                                      details.data,
                                      index,
                                    ),
                                onAcceptWithDetails:
                                    (details) => _attachDraggedBlockAsSuperset(
                                      details.data,
                                      index,
                                    ),
                                builder: (context, candidates, rejected) {
                                  final hovering =
                                      candidates.isNotEmpty &&
                                      _canAcceptSupersetDrop(
                                        candidates.last,
                                        index,
                                      );
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    curve: Curves.easeOut,
                                    decoration:
                                        hovering
                                            ? BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                              border: Border.all(
                                                color: kAccentColor.withValues(
                                                  alpha: 0.35,
                                                ),
                                              ),
                                              color: kAccentColor.withValues(
                                                alpha: 0.04,
                                              ),
                                            )
                                            : null,
                                    padding:
                                        hovering
                                            ? const EdgeInsets.all(2)
                                            : EdgeInsets.zero,
                                    child: cardBody,
                                  );
                                },
                              );
                          final draggableCard = LongPressDraggable<
                            _LiveExerciseDragPayload
                          >(
                            data: dragPayload,
                            maxSimultaneousDrags: 1,
                            feedback: Material(
                              color: Colors.transparent,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: math.min(
                                    320,
                                    MediaQuery.sizeOf(context).width - 32,
                                  ),
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width - 24,
                                ),
                                child: Transform.scale(
                                  scale: 1.03,
                                  child: _LiveExerciseDragGhost(
                                    exerciseName:
                                        dragPayload.anchorExerciseName,
                                    setCount: draggedSetCount,
                                    exerciseCount: draggedExerciseCount,
                                    isSupersetBlock:
                                        dragPayload.isSupersetBlock,
                                  ),
                                ),
                              ),
                            ),
                            onDragStarted: () {
                              if (!mounted) return;
                              setState(() => _isExerciseDragInProgress = true);
                            },
                            onDragEnd: (_) {
                              if (!mounted) return;
                              setState(() => _isExerciseDragInProgress = false);
                            },
                            childWhenDragging: Opacity(
                              opacity: 0.38,
                              child: IgnorePointer(child: cardSupersetTarget),
                            ),
                            child: cardSupersetTarget,
                          );
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: hasSupersetNext ? 6 : 12,
                            ),
                            child: Column(
                              children: [
                                buildInsertDropZone(index),
                                draggableCard,
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    if (showBottomActions)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          ignoring: false,
                          child: footerActionSection(),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blueGrey.shade600),
        const SizedBox(width: 8),
        Text(
          '$value $label',
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TimerOptionChip extends StatelessWidget {
  const _TimerOptionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: kAccentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: kAccentColor.withValues(alpha: 0.26)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: kAccentColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerSettingTile extends StatelessWidget {
  const _TimerSettingTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.82),
            kAccentColor.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: kAccentColor.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF65707C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoSwitch(
            value: value,
            activeTrackColor: kAccentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SwipeDeleteReveal extends StatelessWidget {
  const _SwipeDeleteReveal({
    required this.borderRadius,
    required this.iconSize,
  });

  final double borderRadius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.red.shade50.withValues(alpha: 0.94),
        border: Border.all(color: Colors.red.shade100),
      ),
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade100.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade400,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _NextSetPreviewCard extends StatelessWidget {
  const _NextSetPreviewCard({
    required this.exerciseName,
    required this.row,
    required this.setDisplayValue,
    required this.weightFormatter,
    required this.onComplete,
  });

  final String exerciseName;
  final WorkoutTemplateSetRow? row;
  final String? setDisplayValue;
  final String Function(double) weightFormatter;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: Offset.zero,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_glassGreyTint(0.26), _glassGreyTint(0.20)],
              ),
              border: Border.all(color: _glassGreyTint(0.24)),
            ),
            child: Row(
              children: [
                const _ExerciseThumb(size: 60),
                const SizedBox(width: 10),
                Expanded(
                  child:
                      row == null
                          ? Text(
                            exerciseName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exerciseName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniValueHeader(
                                      label: 'SET',
                                      value: setDisplayValue ?? row!.label,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MiniValueHeader(
                                      label: 'REPS',
                                      value: '${row!.reps}',
                                    ),
                                  ),
                                  Expanded(
                                    child: _MiniValueHeader(
                                      label: 'WEIGHT',
                                      value: weightFormatter(row!.weightKg),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: onComplete,
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            onComplete == null
                                ? _glassGreyTint(0.24)
                                : Colors.teal.withValues(alpha: 0.28),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors:
                            onComplete == null
                                ? [_glassGreyTint(0.20), _glassGreyTint(0.14)]
                                : [
                                  Colors.teal.withValues(alpha: 0.12),
                                  _glassGreyTint(0.10),
                                ],
                      ),
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 38,
                      color:
                          onComplete == null
                              ? Colors.grey.shade500
                              : Colors.teal.shade700,
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

class _MiniValueHeader extends StatelessWidget {
  const _MiniValueHeader({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }
}

class _LiveExerciseCard extends StatelessWidget {
  const _LiveExerciseCard({
    required this.run,
    required this.isCurrentExercise,
    required this.onToggle,
    required this.setDisplayLabelForRow,
    required this.restFormatter,
    required this.weightFormatter,
    required this.onStats,
    required this.onSwap,
    required this.onAddSet,
    required this.onDeleteRow,
    required this.onTapSetLabel,
    required this.onTapReps,
    required this.onTapWeight,
    required this.onTapRest,
    required this.onCompleteRow,
    required this.onUndoRow,
    required this.isUndoableDoneRow,
  });

  final _LiveExerciseRun run;
  final bool isCurrentExercise;
  final VoidCallback onToggle;
  final String Function(int rowIndex) setDisplayLabelForRow;
  final String Function(int) restFormatter;
  final String Function(double) weightFormatter;
  final VoidCallback onStats;
  final VoidCallback onSwap;
  final VoidCallback onAddSet;
  final void Function(int rowIndex) onDeleteRow;
  final void Function(int rowIndex) onTapSetLabel;
  final void Function(int rowIndex) onTapReps;
  final void Function(int rowIndex) onTapWeight;
  final void Function(int rowIndex) onTapRest;
  final void Function(int rowIndex) onCompleteRow;
  final void Function(int rowIndex) onUndoRow;
  final bool Function(int rowIndex) isUndoableDoneRow;

  @override
  Widget build(BuildContext context) {
    final exercise = run.exercise;
    final durationChip = '${exercise.estimatedMinutes} MINS';

    return GlassContainer(
      borderRadius: 16,
      blur: 12,
      showSheen: false,
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _ExerciseThumb(label: exercise.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exercise.presetRows.length} Sets',
                          style: TextStyle(
                            color: Colors.black.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kAccentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      durationChip,
                      style: const TextStyle(
                        color: kAccentColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    run.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 26,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (run.isExpanded) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _TableHeader(label: 'SETS')),
                Expanded(child: _TableHeader(label: 'REPS')),
                Expanded(child: _TableHeader(label: 'WEIGHT')),
                Expanded(child: _TableHeader(label: 'REST')),
                const SizedBox(width: 34),
              ],
            ),
            const SizedBox(height: 6),
            ...List.generate(exercise.presetRows.length, (rowIndex) {
              final row = exercise.presetRows[rowIndex];
              final status = run.statuses[rowIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Dismissible(
                    key: ValueKey(
                      '${exercise.id}-row-$rowIndex-${row.label}-${row.reps}-${row.weightKg}-${row.restSeconds}',
                    ),
                    direction: DismissDirection.endToStart,
                    background: const SizedBox.expand(),
                    confirmDismiss: (_) async {
                      if (exercise.presetRows.length > 1) return true;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'At least one set is required in an exercise.',
                          ),
                        ),
                      );
                      return false;
                    },
                    secondaryBackground: const _SwipeDeleteReveal(
                      borderRadius: 12,
                      iconSize: 20,
                    ),
                    onDismissed: (_) => onDeleteRow(rowIndex),
                    child: _LiveSetRowTile(
                      label: setDisplayLabelForRow(rowIndex),
                      reps: '${row.reps}',
                      weight: weightFormatter(row.weightKg),
                      rest: restFormatter(row.restSeconds),
                      status: status,
                      onTapLabel: () => onTapSetLabel(rowIndex),
                      onTapReps: () => onTapReps(rowIndex),
                      onTapWeight: () => onTapWeight(rowIndex),
                      onTapRest: () => onTapRest(rowIndex),
                      onCheck:
                          status == _LiveSetStatus.done
                              ? null
                              : () => onCompleteRow(rowIndex),
                      onUndo:
                          status == _LiveSetStatus.done &&
                                  isUndoableDoneRow(rowIndex)
                              ? () => onUndoRow(rowIndex)
                              : null,
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: _LiveExerciseActionButton(
                    label: 'Stats',
                    onPressed: onStats,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LiveExerciseActionButton(
                    label: 'Add set',
                    onPressed: onAddSet,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LiveExerciseActionButton(
                    label: 'Swap',
                    onPressed: onSwap,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LiveExerciseActionButton extends StatelessWidget {
  const _LiveExerciseActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: kAccentColor,
        backgroundColor: Colors.white.withValues(alpha: 0.70),
        side: BorderSide(color: kAccentColor.withValues(alpha: 0.22)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LiveSupersetBadge extends StatelessWidget {
  const _LiveSupersetBadge();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: kAccentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: kAccentColor.withValues(alpha: 0.18)),
        ),
        child: const Text(
          'SUPERSET',
          style: TextStyle(
            color: kAccentColor,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _LiveExerciseDragGhost extends StatelessWidget {
  const _LiveExerciseDragGhost({
    required this.exerciseName,
    required this.setCount,
    required this.exerciseCount,
    required this.isSupersetBlock,
  });

  final String exerciseName;
  final int setCount;
  final int exerciseCount;
  final bool isSupersetBlock;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.96,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_glassGreyTint(0.34), _glassGreyTint(0.24)],
              ),
              border: Border.all(color: _glassGreyTint(0.30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -12,
                  left: -18,
                  child: IgnorePointer(
                    child: Container(
                      width: 110,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: RadialGradient(
                          colors: [
                            _glassGreyTint(0.16),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            kAccentColor.withValues(alpha: 0.16),
                            _glassGreyTint(0.16),
                          ],
                        ),
                        border: Border.all(color: _glassGreyTint(0.26)),
                      ),
                      child: Stack(
                        children: [
                          const Center(
                            child: Icon(
                              Icons.drag_indicator_rounded,
                              color: kAccentColor,
                              size: 26,
                            ),
                          ),
                          if (isSupersetBlock)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kAccentColor.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exerciseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kAccentColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: kAccentColor.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Text(
                                  isSupersetBlock ? 'SUPERSET' : 'MOVE',
                                  style: const TextStyle(
                                    color: kAccentColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isSupersetBlock
                                ? '$exerciseCount exercises • $setCount total sets'
                                : '$setCount sets • Drop on a card to make a superset',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveSetRowTile extends StatelessWidget {
  const _LiveSetRowTile({
    required this.label,
    required this.reps,
    required this.weight,
    required this.rest,
    required this.status,
    required this.onTapLabel,
    required this.onTapReps,
    required this.onTapWeight,
    required this.onTapRest,
    required this.onCheck,
    this.onUndo,
  });

  final String label;
  final String reps;
  final String weight;
  final String rest;
  final _LiveSetStatus status;
  final VoidCallback onTapLabel;
  final VoidCallback onTapReps;
  final VoidCallback onTapWeight;
  final VoidCallback onTapRest;
  final VoidCallback? onCheck;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final palette = switch (status) {
      _LiveSetStatus.upcoming => (
        bg: Colors.white,
        border: Colors.grey.shade300,
        text: Colors.black87,
      ),
      _LiveSetStatus.active => (
        bg: kAccentColor.withValues(alpha: 0.06),
        border: kAccentColor.withValues(alpha: 0.55),
        text: kAccentDark,
      ),
      _LiveSetStatus.done => (
        bg: Colors.teal.withValues(alpha: 0.08),
        border: Colors.teal.shade300,
        text: Colors.teal.shade900,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            spreadRadius: 0.2,
            offset: Offset.zero,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _RowValue(
              text: label,
              color: palette.text,
              onTap: onTapLabel,
            ),
          ),
          Expanded(
            child: _RowValue(
              text: reps,
              color: palette.text,
              onTap: onTapReps,
              showInteractiveBorder: true,
            ),
          ),
          Expanded(
            child: _RowValue(
              text: weight,
              color: palette.text,
              onTap: onTapWeight,
              showInteractiveBorder: true,
            ),
          ),
          Expanded(
            child: _RowValue(
              text: rest,
              color: palette.text,
              onTap: onTapRest,
              showInteractiveBorder: true,
            ),
          ),
          SizedBox(
            width: 30,
            child: Center(
              child: switch (status) {
                _LiveSetStatus.done => InkWell(
                  onTap: onUndo,
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color:
                        onUndo == null
                            ? Colors.teal.shade300
                            : Colors.teal.shade700,
                    size: 22,
                  ),
                ),
                _LiveSetStatus.active => InkWell(
                  onTap: onCheck,
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: kAccentColor,
                    size: 22,
                  ),
                ),
                _LiveSetStatus.upcoming => InkWell(
                  onTap: onCheck,
                  borderRadius: BorderRadius.circular(999),
                  child: Icon(
                    Icons.radio_button_unchecked_rounded,
                    color: Colors.grey.shade500,
                    size: 22,
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RowValue extends StatelessWidget {
  const _RowValue({
    required this.text,
    required this.color,
    this.onTap,
    this.showInteractiveBorder = false,
  });

  final String text;
  final Color color;
  final VoidCallback? onTap;
  final bool showInteractiveBorder;

  @override
  Widget build(BuildContext context) {
    final child =
        showInteractiveBorder
            ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade400.withValues(alpha: 0.9),
                ),
                color: Colors.white.withValues(alpha: 0.42),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.015),
                    blurRadius: 4,
                    offset: Offset.zero,
                  ),
                ],
              ),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            )
            : Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w500, color: color),
              ),
            );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: child,
    );
  }
}

class _LiveSwapSectionTitle extends StatelessWidget {
  const _LiveSwapSectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade700,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _LiveSwapExerciseTile extends StatelessWidget {
  const _LiveSwapExerciseTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isCurrent = false,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  isCurrent
                      ? kAccentColor.withValues(alpha: 0.35)
                      : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                spreadRadius: 0.3,
                offset: Offset.zero,
              ),
            ],
          ),
          child: Row(
            children: [
              _ExerciseThumb(size: 50, label: title),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCurrent)
                const Icon(Icons.check_rounded, color: kAccentColor)
              else
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseThumb extends StatelessWidget {
  const _ExerciseThumb({this.size = 72, this.label});

  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: _glassGreyTint(0.22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: Offset.zero,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            _kExercisePlaceholderImageUrl,
            fit: BoxFit.cover,
            errorBuilder:
                (context, error, stackTrace) => Container(
                  color: _glassGreyTint(0.18),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.image_outlined,
                    color: Colors.grey.shade500,
                    size: size * 0.34,
                  ),
                ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_glassGreyTint(0.08), _glassGreyTint(0.18)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

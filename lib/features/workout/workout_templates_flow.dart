import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/workout/live_workout_screen.dart';
import 'package:lift/features/workout/mock_workout_templates.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/models/workout_template.dart';
import 'package:lift/shared/widgets/surfaces.dart';

enum _WorkoutTemplatesMode { overview, list, detail, editor, live }

enum _SwapExerciseEquipment { machine, barbell, dumbbell, cables, bodyweight }

extension _SwapExerciseEquipmentX on _SwapExerciseEquipment {
  String get label {
    switch (this) {
      case _SwapExerciseEquipment.machine:
        return 'Machines';
      case _SwapExerciseEquipment.barbell:
        return 'Barbell';
      case _SwapExerciseEquipment.dumbbell:
        return 'Dumbbell';
      case _SwapExerciseEquipment.cables:
        return 'Cables';
      case _SwapExerciseEquipment.bodyweight:
        return 'Bodyweight';
    }
  }
}

class _SwapExerciseCatalogItem {
  const _SwapExerciseCatalogItem({
    required this.name,
    required this.muscleGroups,
    required this.equipment,
    this.keywords = const <String>[],
  });

  final String name;
  final List<String> muscleGroups;
  final _SwapExerciseEquipment equipment;
  final List<String> keywords;
}

const List<_SwapExerciseCatalogItem> _kSwapExerciseCatalog = [
  _SwapExerciseCatalogItem(
    name: 'Leg Press',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['leg', 'press', 'quad'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Hamstring Curls',
    muscleGroups: ['Hamstrings'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['hamstring', 'curl', 'leg'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Leg Extension',
    muscleGroups: ['Quads'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['leg', 'extension', 'quad'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Barbell Back Squat',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _SwapExerciseEquipment.barbell,
    keywords: ['squat', 'barbell', 'leg'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Romanian Deadlift',
    muscleGroups: ['Hamstrings', 'Glutes'],
    equipment: _SwapExerciseEquipment.barbell,
    keywords: ['hinge', 'hamstring', 'deadlift', 'barbell'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Dumbbell Lunges',
    muscleGroups: ['Quads', 'Glutes'],
    equipment: _SwapExerciseEquipment.dumbbell,
    keywords: ['lunge', 'dumbbell', 'leg'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Lat Pulldown',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _SwapExerciseEquipment.cables,
    keywords: ['lat', 'pull', 'back'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Seated Row',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _SwapExerciseEquipment.cables,
    keywords: ['row', 'back', 'pull'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Cable Face Pull',
    muscleGroups: ['Back', 'Shoulders'],
    equipment: _SwapExerciseEquipment.cables,
    keywords: ['face', 'pull', 'rear'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Pull Up',
    muscleGroups: ['Back', 'Biceps'],
    equipment: _SwapExerciseEquipment.bodyweight,
    keywords: ['pull', 'up', 'back'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Chest Press',
    muscleGroups: ['Chest', 'Triceps'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['chest', 'press', 'push'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Shoulder Press',
    muscleGroups: ['Shoulders', 'Triceps'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['shoulder', 'press', 'push'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Lateral Raise',
    muscleGroups: ['Shoulders'],
    equipment: _SwapExerciseEquipment.dumbbell,
    keywords: ['lateral', 'raise', 'shoulder'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Tricep Pushdown',
    muscleGroups: ['Triceps'],
    equipment: _SwapExerciseEquipment.cables,
    keywords: ['tricep', 'pushdown', 'cable'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Bench Press',
    muscleGroups: ['Chest', 'Triceps'],
    equipment: _SwapExerciseEquipment.barbell,
    keywords: ['bench', 'press', 'chest'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Dumbbell Incline Press',
    muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
    equipment: _SwapExerciseEquipment.dumbbell,
    keywords: ['incline', 'press', 'chest'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Push Up',
    muscleGroups: ['Chest', 'Shoulders', 'Triceps'],
    equipment: _SwapExerciseEquipment.bodyweight,
    keywords: ['push', 'up', 'chest'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Ab Crunch Machine',
    muscleGroups: ['Core'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['ab', 'crunch', 'core'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Cable Woodchop',
    muscleGroups: ['Core'],
    equipment: _SwapExerciseEquipment.cables,
    keywords: ['core', 'rotation', 'cable'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Plank',
    muscleGroups: ['Core'],
    equipment: _SwapExerciseEquipment.bodyweight,
    keywords: ['plank', 'core'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Incline Walk',
    muscleGroups: ['Conditioning'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['walk', 'cardio', 'conditioning'],
  ),
  _SwapExerciseCatalogItem(
    name: 'Row Erg',
    muscleGroups: ['Conditioning', 'Back'],
    equipment: _SwapExerciseEquipment.machine,
    keywords: ['row', 'cardio', 'conditioning'],
  ),
];

class WorkoutTemplatesFlow extends StatefulWidget {
  const WorkoutTemplatesFlow({
    super.key,
    this.onLiveDockChanged,
    this.onLiveFullscreenChanged,
    this.onWorkoutCompleted,
    this.onHideShellNavChanged,
  });

  final ValueChanged<WorkoutLiveDockHandle?>? onLiveDockChanged;
  final ValueChanged<WorkoutLiveFullscreenHandle?>? onLiveFullscreenChanged;
  final ValueChanged<WorkoutHistoryEntry>? onWorkoutCompleted;
  final ValueChanged<bool>? onHideShellNavChanged;

  @override
  State<WorkoutTemplatesFlow> createState() => _WorkoutTemplatesFlowState();
}

class WorkoutLiveDockHandle {
  const WorkoutLiveDockHandle({
    required this.state,
    required this.onResume,
    required this.onClose,
  });

  final LiveWorkoutMiniState state;
  final VoidCallback onResume;
  final VoidCallback onClose;
}

class WorkoutLiveFullscreenHandle {
  const WorkoutLiveFullscreenHandle({
    required this.onDiscard,
    required this.onComplete,
  });

  final VoidCallback onDiscard;
  final VoidCallback onComplete;
}

class _WorkoutTemplatesFlowState extends State<WorkoutTemplatesFlow> {
  late List<WorkoutTemplate> _templates;
  _WorkoutTemplatesMode _mode = _WorkoutTemplatesMode.overview;
  _WorkoutTemplatesMode _editorReturnMode = _WorkoutTemplatesMode.list;
  _WorkoutTemplatesMode _liveReturnMode = _WorkoutTemplatesMode.detail;
  String? _selectedTemplateId;
  WorkoutTemplate? _activeLiveTemplate;
  LiveWorkoutMiniState? _liveMiniState;
  LiveWorkoutSummaryState? _liveSummaryState;
  int _liveSessionSeed = 0;
  Key? _liveSessionKey;
  String _searchQuery = '';
  final Set<String> _expandedExerciseIds = <String>{};
  int _templateIdSeed = 100;
  int _exerciseIdSeed = 100;
  bool _isCompletingLiveWorkout = false;
  bool _isDiscardingLiveWorkout = false;
  bool? _lastPublishedHideShellNav;

  @override
  void initState() {
    super.initState();
    _templates = MockWorkoutTemplates.seed();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _publishShellNavVisibility();
    });
  }

  @override
  void dispose() {
    widget.onHideShellNavChanged?.call(false);
    super.dispose();
  }

  List<WorkoutTemplate> get _filteredTemplates {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _templates;
    return _templates.where((template) {
      return template.name.toLowerCase().contains(query) ||
          template.focusTags.any((tag) => tag.toLowerCase().contains(query));
    }).toList();
  }

  WorkoutTemplate? get _selectedTemplate {
    if (_selectedTemplateId == null) return null;
    for (final template in _templates) {
      if (template.id == _selectedTemplateId) return template;
    }
    return null;
  }

  bool get _hasActiveLiveWorkout => _activeLiveTemplate != null;

  bool get _showLiveDock =>
      _hasActiveLiveWorkout &&
      _mode != _WorkoutTemplatesMode.live &&
      _liveMiniState != null;

  bool get _showLiveFullscreenActions =>
      _hasActiveLiveWorkout && _mode == _WorkoutTemplatesMode.live;

  void _publishLiveDockState() {
    final callback = widget.onLiveDockChanged;
    if (callback == null) return;
    if (_showLiveDock && _liveMiniState != null) {
      callback(
        WorkoutLiveDockHandle(
          state: _liveMiniState!,
          onResume: _resumeLiveWorkout,
          onClose: _closeLiveWorkoutFromDock,
        ),
      );
      return;
    }
    callback(null);
  }

  void _publishLiveFullscreenState() {
    final callback = widget.onLiveFullscreenChanged;
    if (callback == null) return;
    if (_showLiveFullscreenActions) {
      callback(
        WorkoutLiveFullscreenHandle(
          onDiscard: _discardLiveWorkout,
          onComplete: _completeLiveWorkout,
        ),
      );
      return;
    }
    callback(null);
  }

  void _publishLiveShellState() {
    _publishLiveDockState();
    _publishLiveFullscreenState();
    _publishShellNavVisibility();
  }

  bool get _shouldHideShellNav =>
      !_hasActiveLiveWorkout && _mode == _WorkoutTemplatesMode.detail;

  void _publishShellNavVisibility() {
    final shouldHide = _shouldHideShellNav;
    if (_lastPublishedHideShellNav == shouldHide) return;
    _lastPublishedHideShellNav = shouldHide;
    widget.onHideShellNavChanged?.call(shouldHide);
  }

  void _syncShellNavVisibilityFromBuild() {
    final callback = widget.onHideShellNavChanged;
    if (callback == null) return;
    final shouldHide = _shouldHideShellNav;
    if (_lastPublishedHideShellNav == shouldHide) return;
    _lastPublishedHideShellNav = shouldHide;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      callback(shouldHide);
    });
  }

  void _discardLiveWorkout() {
    if (_isDiscardingLiveWorkout) return;
    _discardLiveWorkoutAsync();
  }

  void _completeLiveWorkout() {
    if (_isCompletingLiveWorkout) return;
    _completeLiveWorkoutAsync();
  }

  Future<void> _discardLiveWorkoutAsync() async {
    final template = _activeLiveTemplate ?? _selectedTemplate;
    if (template == null) return;
    _isDiscardingLiveWorkout = true;
    try {
      final confirmed = await _confirmDiscardLiveWorkoutDialog();
      if (!confirmed || !mounted) return;
      final latestTemplate = _activeLiveTemplate ?? _selectedTemplate;
      if (latestTemplate == null) return;
      setState(() {
        _clearLiveWorkoutSession();
        _selectedTemplateId = latestTemplate.id;
        _mode = _WorkoutTemplatesMode.detail;
      });
      _publishLiveShellState();
    } finally {
      _isDiscardingLiveWorkout = false;
    }
  }

  Future<void> _completeLiveWorkoutAsync() async {
    final template = _activeLiveTemplate ?? _selectedTemplate;
    if (template == null) return;
    _isCompletingLiveWorkout = true;
    try {
      final confirmed = await _confirmCompleteLiveWorkoutDialog();
      if (!confirmed || !mounted) return;
      final summary = _liveSummaryState ?? _buildFallbackSummaryState(template);
      await _showWorkoutSummaryDialog(summary);
      if (!mounted) return;
      final historyEntry = _toHistoryEntry(summary, template);
      widget.onWorkoutCompleted?.call(historyEntry);
      final latestTemplate = _activeLiveTemplate ?? _selectedTemplate;
      if (latestTemplate == null) return;
      setState(() {
        _clearLiveWorkoutSession();
        _selectedTemplateId = latestTemplate.id;
        _mode = _WorkoutTemplatesMode.detail;
      });
      _publishLiveShellState();
    } finally {
      _isCompletingLiveWorkout = false;
    }
  }

  LiveWorkoutSummaryState _buildFallbackSummaryState(WorkoutTemplate template) {
    final completedAt = DateTime.now();
    return LiveWorkoutSummaryState(
      workoutName: template.name,
      startedAt: completedAt,
      completedAt: completedAt,
      elapsed: Duration.zero,
      totalVolumeKg: 0,
      totalReps: 0,
      exercisesCompleted: 0,
      totalExercises: template.exercises.length,
      prsAchieved: 0,
      exerciseSummaries: const <WorkoutHistoryExerciseSummary>[],
      muscleGroupVolumeKg: const <String, double>{},
    );
  }

  WorkoutHistoryEntry _toHistoryEntry(
    LiveWorkoutSummaryState summary,
    WorkoutTemplate template,
  ) {
    final normalizedDuration =
        summary.elapsed.isNegative ? Duration.zero : summary.elapsed;
    return WorkoutHistoryEntry(
      id: 'history_${template.id}_${summary.completedAt.millisecondsSinceEpoch}',
      workoutName: summary.workoutName,
      startedAt: summary.startedAt,
      completedAt: summary.completedAt,
      duration: normalizedDuration,
      totalVolumeKg: summary.totalVolumeKg,
      totalReps: summary.totalReps,
      exercisesCompleted: summary.exercisesCompleted,
      totalExercises: summary.totalExercises,
      prsAchieved: summary.prsAchieved,
      exerciseSummaries: summary.exerciseSummaries,
      muscleGroupVolumeKg: summary.muscleGroupVolumeKg,
    );
  }

  Future<bool> _confirmDiscardLiveWorkoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Discard workout?'),
            content: const Text(
              'This will end your live workout and discard this session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep workout'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Discard'),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  Future<bool> _confirmCompleteLiveWorkoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Complete workout?'),
            content: const Text(
              'This will end the live workout and show your summary.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Keep workout'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccentColor,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Complete'),
              ),
            ],
          ),
    );
    return confirmed == true;
  }

  void _openOverview() {
    setState(() => _mode = _WorkoutTemplatesMode.overview);
    _publishLiveShellState();
  }

  void _openList() {
    setState(() => _mode = _WorkoutTemplatesMode.list);
    _publishLiveShellState();
  }

  void _openDetail(WorkoutTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _mode = _WorkoutTemplatesMode.detail;
    });
    _publishLiveShellState();
  }

  void _openCreate() {
    setState(() {
      _selectedTemplateId = null;
      _editorReturnMode = _WorkoutTemplatesMode.list;
      _mode = _WorkoutTemplatesMode.editor;
    });
    _publishLiveShellState();
  }

  void _openEdit(WorkoutTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _editorReturnMode = _WorkoutTemplatesMode.detail;
      _mode = _WorkoutTemplatesMode.editor;
    });
    _publishLiveShellState();
  }

  void _openLiveWorkout(WorkoutTemplate template) {
    setState(() {
      _selectedTemplateId = template.id;
      _activeLiveTemplate = template;
      _liveReturnMode = _WorkoutTemplatesMode.overview;
      _liveMiniState = null;
      _liveSessionSeed += 1;
      _liveSessionKey = ValueKey(
        'live_session_${template.id}_$_liveSessionSeed',
      );
      _mode = _WorkoutTemplatesMode.live;
    });
    _publishLiveShellState();
  }

  void _minimizeLiveWorkout() {
    if (!_hasActiveLiveWorkout) return;
    setState(() {
      _mode = _WorkoutTemplatesMode.overview;
    });
    _publishLiveShellState();
  }

  void _resumeLiveWorkout() {
    if (!_hasActiveLiveWorkout) return;
    setState(() {
      _mode = _WorkoutTemplatesMode.live;
    });
    _publishLiveShellState();
  }

  void _closeLiveWorkoutFromDock() {
    if (!_hasActiveLiveWorkout) return;
    setState(() {
      _clearLiveWorkoutSession();
    });
    _publishLiveShellState();
  }

  void _clearLiveWorkoutSession() {
    _activeLiveTemplate = null;
    _liveMiniState = null;
    _liveSummaryState = null;
    _liveSessionKey = null;
  }

  String _formatSummaryDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }

  String _formatVolume(double volumeKg) {
    final rounded = volumeKg.round();
    final digits = rounded.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write(',');
      }
    }
    return '${buffer.toString()} kg';
  }

  Future<void> _showWorkoutSummaryDialog(LiveWorkoutSummaryState summary) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        Widget metricRow({
          required IconData icon,
          required String label,
          required String value,
          String? note,
        }) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: Offset.zero,
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: kAccentColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (note != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          );
        }

        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout Summary',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Completed workout',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                metricRow(
                  icon: Icons.fitness_center_rounded,
                  label: 'Workout name',
                  value: summary.workoutName,
                ),
                const SizedBox(height: 10),
                metricRow(
                  icon: Icons.schedule_rounded,
                  label: 'Duration',
                  value: _formatSummaryDuration(summary.elapsed),
                ),
                const SizedBox(height: 10),
                metricRow(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Total volume (weight × reps)',
                  value: _formatVolume(summary.totalVolumeKg),
                ),
                const SizedBox(height: 10),
                metricRow(
                  icon: Icons.checklist_rounded,
                  label: 'Exercises completed',
                  value:
                      '${summary.exercisesCompleted}/${summary.totalExercises}',
                ),
                const SizedBox(height: 10),
                metricRow(
                  icon: Icons.emoji_events_rounded,
                  label: 'PRs achieved',
                  value: summary.prsAchieved.toString(),
                  note:
                      summary.prsAchieved == 0
                          ? 'No PRs this session'
                          : 'Nice work',
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveTemplate(WorkoutTemplate template) {
    final existingIndex = _templates.indexWhere((t) => t.id == template.id);
    setState(() {
      if (existingIndex >= 0) {
        _templates[existingIndex] = template;
      } else {
        _templates.insert(0, template);
      }
      _selectedTemplateId = template.id;
      _mode = _WorkoutTemplatesMode.detail;
    });
    _publishLiveShellState();
  }

  void _handleBack() {
    switch (_mode) {
      case _WorkoutTemplatesMode.overview:
        return;
      case _WorkoutTemplatesMode.list:
        _openOverview();
      case _WorkoutTemplatesMode.detail:
        _openList();
      case _WorkoutTemplatesMode.editor:
        setState(() => _mode = _editorReturnMode);
      case _WorkoutTemplatesMode.live:
        _minimizeLiveWorkout();
    }
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '$hours hour';
      return '${hours}hr ${mins}mins';
    }
    return '$minutes mins';
  }

  String _formatShortDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '$hours hour';
      return '${hours}hr ${mins}mins';
    }
    return '$minutes mins';
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rem';
  }

  WorkoutTemplate _createEmptyTemplate() {
    _templateIdSeed += 1;
    return WorkoutTemplate(
      id: 'template_custom_$_templateIdSeed',
      name: 'New Workout',
      imageUrl:
          'https://images.pexels.com/photos/4162490/pexels-photo-4162490.jpeg',
      durationMinutes: 45,
      focusTags: const ['Custom'],
      exercises: const [],
    );
  }

  String _nextExerciseId() {
    _exerciseIdSeed += 1;
    return 'exercise_$_exerciseIdSeed';
  }

  @override
  Widget build(BuildContext context) {
    _syncShellNavVisibilityFromBuild();
    final showLiveFullscreen =
        _hasActiveLiveWorkout && _mode == _WorkoutTemplatesMode.live;
    final contentMode = showLiveFullscreen ? _liveReturnMode : _mode;
    final showFloatingDetailAction =
        contentMode == _WorkoutTemplatesMode.detail &&
        !showLiveFullscreen &&
        !_showLiveDock;
    final detailTemplate =
        contentMode == _WorkoutTemplatesMode.detail ? _selectedTemplate : null;
    final bottomPadding =
        (contentMode == _WorkoutTemplatesMode.detail ? 24.0 : 104.0) +
        (_showLiveDock ? 96.0 : 0.0);
    final contentPadding = EdgeInsets.fromLTRB(16, 14, 16, bottomPadding);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          Padding(
            padding: contentPadding,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: KeyedSubtree(
                      key: ValueKey(contentMode),
                      child: switch (contentMode) {
                        _WorkoutTemplatesMode.overview => _buildOverview(),
                        _WorkoutTemplatesMode.list => _buildTemplateList(),
                        _WorkoutTemplatesMode.detail => _buildTemplateDetail(
                          showFloatingAction: showFloatingDetailAction,
                        ),
                        _WorkoutTemplatesMode.editor => _buildEditor(),
                        _WorkoutTemplatesMode.live => _buildLiveWorkout(),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showLiveFullscreen)
            const Positioned.fill(
              child: IgnorePointer(
                ignoring: true,
                child: ColoredBox(color: Colors.white),
              ),
            ),
          if (_hasActiveLiveWorkout)
            Positioned.fill(
              child: Padding(
                padding: contentPadding,
                child: Offstage(
                  offstage: !showLiveFullscreen,
                  child: _buildLiveWorkout(),
                ),
              ),
            ),
          if (showFloatingDetailAction && detailTemplate != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: SafeArea(
                top: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: math.min(196, MediaQuery.sizeOf(context).width - 32),
                    child: _TemplateDetailActionBar(
                      hasActiveLiveWorkout: _hasActiveLiveWorkout,
                      onStartWorkout: () => _openLiveWorkout(detailTemplate),
                      onResumeWorkout: _resumeLiveWorkout,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    final templates = _templates;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TemplatesHeader(
          title: 'Templates',
          rightWidget: TextButton(
            onPressed: _openList,
            style: TextButton.styleFrom(
              foregroundColor: kAccentColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'VIEW ALL',
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const railBleed = 16.0;
              final railWidth = constraints.maxWidth + (railBleed * 2);
              final cardWidth = (railWidth * 0.66).clamp(240.0, 300.0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: OverflowBox(
                      alignment: Alignment.center,
                      minWidth: railWidth,
                      maxWidth: railWidth,
                      child: SizedBox(
                        width: railWidth,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16),
                          itemCount: templates.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final template = templates[index];
                            return SizedBox(
                              width: cardWidth,
                              child: _TemplateFeatureCard(
                                template: template,
                                durationLabel: _formatShortDuration(
                                  template.estimatedDurationMinutes,
                                ),
                                onTap: () => _openDetail(template),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SectionBoundary(
                    borderRadius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start from scratch or create a custom template for your gym.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _CreateActionsRow(
                          onEmptyWorkout: () {
                            final template = _createEmptyTemplate().copyWith(
                              name: 'Empty Workout',
                            );
                            _openEdit(template);
                          },
                          onCreate: _openCreate,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateList() {
    final filtered = _filteredTemplates;
    return Column(
      children: [
        _TemplatesHeader(
          title: 'Templates',
          showBack: true,
          onBack: _handleBack,
          rightWidget: IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(
              PhosphorIconsRegular.userCircle,
              color: kAccentColor,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kAccentColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filters coming next')),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.filter_alt_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(
          child:
              filtered.isEmpty
                  ? Center(
                    child: Text(
                      'No templates match "$_searchQuery"',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                  : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final template = filtered[index];
                      return _TemplateListRow(
                        template: template,
                        durationLabel: _formatDuration(
                          template.estimatedDurationMinutes,
                        ),
                        onTap: () => _openDetail(template),
                      );
                    },
                  ),
        ),
        const SizedBox(height: 14),
        _CreateActionsRow(
          onEmptyWorkout: () {
            final template = _createEmptyTemplate().copyWith(
              name: 'Empty Workout',
            );
            _openEdit(template);
          },
          onCreate: _openCreate,
        ),
      ],
    );
  }

  Widget _buildTemplateDetail({required bool showFloatingAction}) {
    final template = _selectedTemplate;
    if (template == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Template not found'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openList,
              child: const Text('Go to templates'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _TemplatesHeader(
          title: 'Templates',
          showBack: true,
          onBack: _handleBack,
          rightWidget: IconButton(
            onPressed: () => _openEdit(template),
            icon: const PhosphorIcon(
              PhosphorIconsRegular.pencilSimple,
              color: kAccentColor,
            ),
            tooltip: 'Edit template',
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _TemplateHeroDetailCard(
                template: template,
                durationLabel: _formatDuration(
                  template.estimatedDurationMinutes,
                ),
              ),
              const SizedBox(height: 12),
              _TemplateStatsTile(
                exerciseCount: template.exercises.length,
                totalSetCount: template.exercises.fold<int>(
                  0,
                  (sum, exercise) => sum + exercise.presetRows.length,
                ),
                totalRestLabel: _formatRest(template.totalRestSeconds),
                focusTags: template.focusTags,
              ),
              const SizedBox(height: 14),
              ...template.exercises.map(
                (exercise) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ExerciseDetailCard(
                    exercise: exercise,
                    isExpanded: _expandedExerciseIds.contains(exercise.id),
                    restFormatter: _formatRest,
                    onToggle: () {
                      setState(() {
                        if (_expandedExerciseIds.contains(exercise.id)) {
                          _expandedExerciseIds.remove(exercise.id);
                        } else {
                          _expandedExerciseIds.add(exercise.id);
                        }
                      });
                    },
                  ),
                ),
              ),
              SizedBox(height: showFloatingAction ? 78 : 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditor() {
    final initialTemplate = _selectedTemplate ?? _createEmptyTemplate();
    final isEditingExisting = _templates.any((t) => t.id == initialTemplate.id);

    return _TemplateEditorScreen(
      template: initialTemplate,
      showBack: true,
      nextExerciseId: _nextExerciseId,
      onBack: _handleBack,
      onSave: _saveTemplate,
      title: isEditingExisting ? 'Edit Template' : 'New Template',
    );
  }

  Widget _buildLiveWorkout() {
    final template = _activeLiveTemplate ?? _selectedTemplate;
    if (template == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Workout template not found'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openList,
              child: const Text('Go to templates'),
            ),
          ],
        ),
      );
    }

    return LiveWorkoutScreen(
      key: _liveSessionKey,
      template: template,
      onBack: _minimizeLiveWorkout,
      onDiscard: _discardLiveWorkout,
      onCompleteWorkout: _completeLiveWorkout,
      showBottomActions: false,
      onStateChanged: (state) {
        if (!mounted) return;
        setState(() {
          _liveMiniState = state;
        });
        _publishLiveShellState();
      },
      onSummaryChanged: (summary) {
        if (!mounted) return;
        _liveSummaryState = summary;
      },
    );
  }
}

class WorkoutLiveDock extends StatelessWidget {
  const WorkoutLiveDock({
    super.key,
    required this.state,
    required this.onTap,
    required this.onClose,
  });

  final LiveWorkoutMiniState state;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: GlassContainer(
          borderRadius: 24,
          blur: 14,
          showBorder: false,
          showSheen: false,
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: kAccentColor.withValues(alpha: 0.10),
                ),
                child: Icon(
                  state.isFinished
                      ? Icons.check_circle_rounded
                      : Icons.timer_rounded,
                  color: kAccentColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            state.templateName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            state.isResting
                                ? 'REST ${state.restLabel}'
                                : state.elapsedLabel,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: kAccentColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.currentExerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${state.progressLabel} • ${state.elapsedLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onClose,
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade600),
                splashRadius: 18,
                tooltip: 'Close live workout',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplatesHeader extends StatelessWidget {
  const _TemplatesHeader({
    required this.title,
    this.showBack = false,
    this.onBack,
    this.rightWidget,
  });

  final String title;
  final bool showBack;
  final VoidCallback? onBack;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (showBack)
          IconButton(
            onPressed: onBack,
            icon: const PhosphorIcon(PhosphorIconsRegular.caretLeft, size: 28),
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: Text(
            title.toUpperCase(),
            textAlign: showBack ? TextAlign.center : TextAlign.left,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        if (showBack)
          SizedBox(
            width: 56,
            child: Align(
              alignment: Alignment.centerRight,
              child: rightWidget ?? const SizedBox.shrink(),
            ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: rightWidget ?? const SizedBox(width: 12),
          ),
      ],
    );
  }
}

class _TemplateFeatureCard extends StatelessWidget {
  const _TemplateFeatureCard({
    required this.template,
    required this.durationLabel,
    required this.onTap,
  });

  final WorkoutTemplate template;
  final String durationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: SectionBoundary(
        borderRadius: 18,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      template.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.grey.shade500,
                              size: 36,
                            ),
                          ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.focusTags.join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _DurationChip(label: durationLabel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplateListRow extends StatelessWidget {
  const _TemplateListRow({
    required this.template,
    required this.durationLabel,
    required this.onTap,
  });

  final WorkoutTemplate template;
  final String durationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SectionBoundary(
        borderRadius: 16,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 78,
                height: 78,
                child: Image.network(
                  template.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade500,
                        ),
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
                    template.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    template.focusTags.join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${template.exercises.length} exercises',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _DurationChip(label: durationLabel),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kAccentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: kAccentColor,
        ),
      ),
    );
  }
}

class _SwapSectionTitle extends StatelessWidget {
  const _SwapSectionTitle(this.label);

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

const String _kExercisePlaceholderImageUrl =
    'https://blocks.astratic.com/img/general-img-landscape.png';

String _exercisePlaceholderUrl(String name, {int size = 112}) {
  return _kExercisePlaceholderImageUrl;
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({
    required this.name,
    this.size = 56,
    this.radius = 10,
  });

  final String name;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              _exercisePlaceholderUrl(name, size: (size * 2).round()),
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.fitness_center,
                      color: Colors.grey.shade500,
                      size: size * 0.38,
                    ),
                  ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.00),
                      Colors.black.withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwapExerciseTile extends StatelessWidget {
  const _SwapExerciseTile({
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
          ),
          child: Row(
            children: [
              _ExerciseThumbnail(name: title, size: 50, radius: 12),
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

class _TemplateHeroDetailCard extends StatelessWidget {
  const _TemplateHeroDetailCard({
    required this.template,
    required this.durationLabel,
  });

  final WorkoutTemplate template;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: 18,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 1.45,
              child: Image.network(
                template.imageUrl,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        color: Colors.grey.shade500,
                      ),
                    ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0),
                      Colors.black.withValues(alpha: 0.42),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      durationLabel.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
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

class _TemplateStatsTile extends StatelessWidget {
  const _TemplateStatsTile({
    required this.exerciseCount,
    required this.totalSetCount,
    required this.totalRestLabel,
    required this.focusTags,
  });

  final int exerciseCount;
  final int totalSetCount;
  final String totalRestLabel;
  final List<String> focusTags;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _TemplateStatCell(
                  label: 'Exercises',
                  value: '$exerciseCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TemplateStatCell(
                  label: 'Sets',
                  value: '$totalSetCount',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TemplateStatCell(label: 'Rest', value: totalRestLabel),
              ),
            ],
          ),
          if (focusTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'MUSCLES WORKED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  focusTags
                      .take(5)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: kAccentColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: kAccentColor.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kAccentColor,
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateStatCell extends StatelessWidget {
  const _TemplateStatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  const _ExerciseDetailCard({
    required this.exercise,
    required this.isExpanded,
    required this.onToggle,
    required this.restFormatter,
    this.footer,
    this.expandedTable,
  });

  final WorkoutTemplateExercise exercise;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String Function(int seconds) restFormatter;
  final Widget? footer;
  final Widget? expandedTable;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      borderRadius: 16,
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _ExerciseThumbnail(name: exercise.name),
                  const SizedBox(width: 10),
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
                        _DurationChip(label: '${exercise.setCount} sets'),
                      ],
                    ),
                  ),
                  _DurationChip(label: '${exercise.estimatedMinutes} mins'),
                  const SizedBox(width: 6),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 28,
                    color: Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 8),
            expandedTable ??
                _SetPresetTable(
                  rows: exercise.presetRows,
                  restFormatter: restFormatter,
                ),
          ],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}

class _SetPresetTable extends StatelessWidget {
  const _SetPresetTable({required this.rows, required this.restFormatter});

  final List<WorkoutTemplateSetRow> rows;
  final String Function(int seconds) restFormatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            _TableHeaderCell('SETS'),
            _TableHeaderCell('REPS'),
            _TableHeaderCell('WEIGHT'),
            _TableHeaderCell('REST'),
          ],
        ),
        const SizedBox(height: 6),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  _TableValueCell(row.label),
                  _TableValueCell('${row.reps}'),
                  _TableValueCell(
                    row.weightKg <= 0
                        ? '--'
                        : '${row.weightKg.toStringAsFixed(0)}KG',
                  ),
                  _TableValueCell(
                    row.restSeconds <= 0
                        ? '--'
                        : restFormatter(row.restSeconds),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _TableValueCell extends StatelessWidget {
  const _TableValueCell(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _EditableCell extends StatelessWidget {
  const _EditableCell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
            color: Colors.white,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.expand_more_rounded,
                size: 16,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditStateChip extends StatelessWidget {
  const _EditStateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CreateActionsRow extends StatelessWidget {
  const _CreateActionsRow({
    required this.onEmptyWorkout,
    required this.onCreate,
  });

  final VoidCallback onEmptyWorkout;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: kAccentColor,
              side: BorderSide(color: kAccentColor.withValues(alpha: 0.35)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: onEmptyWorkout,
            child: const Text('EMPTY WORKOUT'),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 58,
          height: 58,
          child: Material(
            color: kAccentColor,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onCreate,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(Icons.add, color: Colors.white, size: 32),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TemplateDetailActionBar extends StatelessWidget {
  const _TemplateDetailActionBar({
    required this.hasActiveLiveWorkout,
    required this.onStartWorkout,
    required this.onResumeWorkout,
  });

  final bool hasActiveLiveWorkout;
  final VoidCallback onStartWorkout;
  final VoidCallback onResumeWorkout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      width: double.infinity,
      child:
          hasActiveLiveWorkout
              ? FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: onResumeWorkout,
                child: const Text(
                  'RESUME',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              )
              : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kAccentColor,
                  side: const BorderSide(color: kAccentColor),
                  backgroundColor: Colors.white.withValues(alpha: 0.86),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                onPressed: onStartWorkout,
                child: const Text(
                  'START',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
    );
  }
}

class _TemplateEditorScreen extends StatelessWidget {
  const _TemplateEditorScreen({
    required this.template,
    required this.showBack,
    required this.title,
    required this.onBack,
    required this.onSave,
    required this.nextExerciseId,
  });

  final WorkoutTemplate template;
  final bool showBack;
  final String title;
  final VoidCallback onBack;
  final ValueChanged<WorkoutTemplate> onSave;
  final String Function() nextExerciseId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TemplatesHeader(
          title: 'Templates',
          showBack: showBack,
          onBack: onBack,
          rightWidget: IconButton(
            onPressed: () {},
            icon: const PhosphorIcon(
              PhosphorIconsRegular.userCircle,
              color: kAccentColor,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _TemplateEditorForm(
            template: template,
            nextExerciseId: nextExerciseId,
            onSave: onSave,
          ),
        ),
      ],
    );
  }
}

class _TemplateEditorForm extends StatefulWidget {
  const _TemplateEditorForm({
    required this.template,
    required this.nextExerciseId,
    required this.onSave,
  });

  final WorkoutTemplate template;
  final String Function() nextExerciseId;
  final ValueChanged<WorkoutTemplate> onSave;

  @override
  State<_TemplateEditorForm> createState() => _TemplateEditorFormState();
}

class _TemplateEditorFormState extends State<_TemplateEditorForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _imageController;
  late int _durationMinutes;
  late List<WorkoutTemplateExercise> _exercises;
  final Set<String> _expandedExerciseIds = <String>{};
  final List<String> _heroImageUploadPresets = const [
    'https://images.pexels.com/photos/949130/pexels-photo-949130.jpeg',
    'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg',
    'https://images.pexels.com/photos/18060190/pexels-photo-18060190.jpeg',
    'https://images.pexels.com/photos/4162490/pexels-photo-4162490.jpeg',
  ];

  WorkoutTemplate get _draftTemplatePreview {
    final tags = _derivedFocusTagsFromExercises(_exercises);
    return widget.template.copyWith(
      name:
          _nameController.text.trim().isEmpty
              ? widget.template.name
              : _nameController.text.trim(),
      imageUrl:
          _imageController.text.trim().isEmpty
              ? widget.template.imageUrl
              : _imageController.text.trim(),
      durationMinutes: _durationMinutes,
      focusTags: tags.isEmpty ? const ['Custom'] : tags,
      exercises: _exercises,
    );
  }

  int get _estimatedDurationFromExercisesMinutes {
    if (_exercises.isEmpty) return _durationMinutes;
    final exerciseMinutes = _exercises.fold<int>(
      0,
      (sum, exercise) => sum + exercise.estimatedMinutes,
    );
    final restSeconds = _exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum +
          exercise.presetRows.fold<int>(
            0,
            (restSum, row) => restSum + row.restSeconds,
          ),
    );
    return exerciseMinutes + (restSeconds / 60).ceil();
  }

  int get _durationOverTargetMinutes =>
      math.max(0, _estimatedDurationFromExercisesMinutes - _durationMinutes);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template.name);
    _imageController = TextEditingController(text: widget.template.imageUrl);
    _durationMinutes = widget.template.durationMinutes;
    _exercises = List<WorkoutTemplateExercise>.from(widget.template.exercises);
    _expandedExerciseIds.addAll(_exercises.map((e) => e.id));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return '$hours hour';
      return '${hours}hr ${mins}mins';
    }
    return '$minutes mins';
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rem';
  }

  List<String> _derivedFocusTagsFromExercises(
    List<WorkoutTemplateExercise> exercises,
  ) {
    final tags = <String>{};
    for (final exercise in exercises) {
      final name = exercise.name.toLowerCase();
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
      if (name.contains('lat') ||
          name.contains('row') ||
          name.contains('pull')) {
        tags.add('Back');
      }
      if (name.contains('curl') && !name.contains('ham')) tags.add('Biceps');
      if (name.contains('press') && !name.contains('leg')) tags.add('Chest');
      if (name.contains('shoulder') || name.contains('lateral')) {
        tags.add('Shoulders');
      }
      if (name.contains('tricep')) tags.add('Triceps');
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
    }
    if (tags.isEmpty) return const ['Custom'];
    return tags.take(4).toList();
  }

  Future<void> _editHeroImage() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.upload_rounded,
                    color: kAccentColor,
                  ),
                  title: const Text('Upload image'),
                  subtitle: const Text('Pick from your photo library (mocked)'),
                  onTap: () {
                    Navigator.pop(context);
                    _showMockUploadChooser();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_rounded, color: kAccentColor),
                  title: const Text('Use image URL'),
                  subtitle: const Text('Paste a direct image link'),
                  onTap: () {
                    Navigator.pop(context);
                    _promptForHeroImageUrl();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMockUploadChooser() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select image',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 94,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _heroImageUploadPresets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final url = _heroImageUploadPresets[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _imageController.text = url);
                          Navigator.pop(context);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 120,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.image_outlined),
                                  ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Using a mock picker for now. We can wire a real device upload next.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptForHeroImageUrl() async {
    final controller = TextEditingController(text: _imageController.text);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hero image URL'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'https://...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccentColor),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Use URL'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result == null || result.isEmpty) return;
    setState(() => _imageController.text = result);
  }

  void _updateExerciseRows(
    WorkoutTemplateExercise exercise,
    List<WorkoutTemplateSetRow> rows,
  ) {
    setState(() {
      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index < 0) return;
      _exercises[index] = _exercises[index].copyWith(
        presetRows: rows,
        setCount: rows.length,
      );
    });
  }

  _SwapExerciseCatalogItem? _catalogItemForExerciseName(String name) {
    final needle = name.trim().toLowerCase();
    for (final item in _kSwapExerciseCatalog) {
      if (item.name.toLowerCase() == needle) return item;
    }
    for (final item in _kSwapExerciseCatalog) {
      if (item.name.toLowerCase().contains(needle) ||
          needle.contains(item.name.toLowerCase())) {
        return item;
      }
    }
    return null;
  }

  List<String> _heuristicMuscleTagsForName(String rawName) {
    final name = rawName.toLowerCase();
    final tags = <String>{};
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
    if (name.contains('curl') && !name.contains('ham')) {
      tags.add('Biceps');
    }
    if (name.contains('press') && !name.contains('leg')) {
      tags.add('Chest');
    }
    if (name.contains('shoulder') || name.contains('lateral')) {
      tags.add('Shoulders');
    }
    if (name.contains('tricep')) {
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

  List<_SwapExerciseCatalogItem> _rankedSwapSuggestions(
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

    final scored = <MapEntry<_SwapExerciseCatalogItem, int>>[];
    for (final item in _kSwapExerciseCatalog) {
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
      if (score > 0) {
        scored.add(MapEntry(item, score));
      }
    }

    scored.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.name.compareTo(b.key.name);
    });
    return scored.take(6).map((e) => e.key).toList();
  }

  String _swapExerciseSubtitle(_SwapExerciseCatalogItem item) {
    return '${item.muscleGroups.join(' • ')}  •  ${item.equipment.label}';
  }

  List<WorkoutTemplateSetRow> _defaultPresetRowsForExercise() {
    return const [
      WorkoutTemplateSetRow(
        label: 'W',
        reps: 12,
        weightKg: 20,
        restSeconds: 90,
      ),
      WorkoutTemplateSetRow(
        label: '1',
        reps: 10,
        weightKg: 40,
        restSeconds: 120,
      ),
      WorkoutTemplateSetRow(
        label: '2',
        reps: 10,
        weightKg: 40,
        restSeconds: 120,
      ),
    ];
  }

  WorkoutTemplateExercise _newExerciseFromCatalogName(String name) {
    return WorkoutTemplateExercise(
      id: widget.nextExerciseId(),
      name: name,
      setCount: 3,
      estimatedMinutes: 15,
      presetRows: _defaultPresetRowsForExercise(),
    );
  }

  Future<String?> _pickExerciseNameFromCatalog({
    WorkoutTemplateExercise? replacingExercise,
  }) async {
    final currentCatalogItem =
        replacingExercise == null
            ? null
            : _catalogItemForExerciseName(replacingExercise.name);
    final suggested =
        replacingExercise == null
            ? const <_SwapExerciseCatalogItem>[]
            : _rankedSwapSuggestions(replacingExercise);
    final allMuscleGroups =
        _kSwapExerciseCatalog
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
        _SwapExerciseEquipment? selectedEquipment =
            currentCatalogItem?.equipment;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredExercises =
                _kSwapExerciseCatalog.where((item) {
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
                            replacingExercise == null
                                ? 'Add exercise'
                                : 'Swap exercise',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            replacingExercise == null
                                ? 'Choose an exercise for this workout'
                                : 'Replacing ${replacingExercise.name}',
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
                            const _SwapSectionTitle('Suggested Exercises'),
                            const SizedBox(height: 8),
                            ...suggested.map(
                              (item) => _SwapExerciseTile(
                                title: item.name,
                                subtitle: _swapExerciseSubtitle(item),
                                isCurrent: item.name == replacingExercise?.name,
                                onTap: () => Navigator.pop(context, item.name),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          const _SwapSectionTitle('Muscle Groups'),
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
                          const _SwapSectionTitle('Equipment'),
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
                              ..._SwapExerciseEquipment.values.map(
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
                          _SwapSectionTitle(
                            'Exercises (${filteredExercises.length})',
                          ),
                          const SizedBox(height: 8),
                          ...filteredExercises.map(
                            (item) => _SwapExerciseTile(
                              title: item.name,
                              subtitle: _swapExerciseSubtitle(item),
                              isCurrent: item.name == replacingExercise?.name,
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
    if (selected == replacingExercise?.name) return null;
    return selected;
  }

  Future<void> _addExerciseFromCatalog() async {
    final selected = await _pickExerciseNameFromCatalog();
    if (selected == null) return;

    final result = _newExerciseFromCatalogName(selected);

    setState(() {
      _exercises.add(result);
      _expandedExerciseIds.add(result.id);
    });
  }

  Future<void> _swapExercise(WorkoutTemplateExercise exercise) async {
    final selected = await _pickExerciseNameFromCatalog(
      replacingExercise: exercise,
    );
    if (selected == null) return;

    setState(() {
      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index < 0) return;
      _exercises[index] = _exercises[index].copyWith(name: selected);
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      if (oldIndex == newIndex) return;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  Widget _exerciseReorderProxyDecorator(
    Widget child,
    int index,
    Animation<double> animation,
  ) {
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero;
    Widget content = child;
    if (child is Padding) {
      outerPadding = child.padding;
      content = child.child ?? const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: animation,
      child: content,
      builder: (context, proxyChild) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return Padding(
          padding: outerPadding,
          child: Transform.scale(
            scale: 1 + (0.008 * t),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10 + (0.06 * t)),
                    blurRadius: 14 + (6 * t),
                    offset: Offset(0, 6 + (2 * t)),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shadowColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: proxyChild,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editSetTypeCell(
    WorkoutTemplateExercise exercise,
    int rowIndex,
  ) async {
    const options = ['Warmup', 'Working set', 'Cooldown'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ...options.map(
                (option) => ListTile(
                  title: Text(option),
                  onTap: () => Navigator.pop(context, option),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected == null) return;
    final rows = List<WorkoutTemplateSetRow>.from(exercise.presetRows);
    rows[rowIndex] = rows[rowIndex].copyWith(label: selected);
    _updateExerciseRows(exercise, rows);
  }

  Future<void> _editRepsCell(
    WorkoutTemplateExercise exercise,
    int rowIndex,
  ) async {
    final controller = TextEditingController(
      text: exercise.presetRows[rowIndex].reps.toString(),
    );
    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit reps'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Reps',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccentColor),
              onPressed: () {
                final reps = int.tryParse(controller.text.trim());
                if (reps == null) return;
                Navigator.pop(context, reps.clamp(0, 99));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (value == null) return;
    final rows = List<WorkoutTemplateSetRow>.from(exercise.presetRows);
    rows[rowIndex] = rows[rowIndex].copyWith(reps: value);
    _updateExerciseRows(exercise, rows);
  }

  Future<void> _editWeightCell(
    WorkoutTemplateExercise exercise,
    int rowIndex,
  ) async {
    final current = exercise.presetRows[rowIndex].weightKg;
    final weight = await _showWeightPicker(current);
    if (weight == null) return;
    final rows = List<WorkoutTemplateSetRow>.from(exercise.presetRows);
    rows[rowIndex] = rows[rowIndex].copyWith(weightKg: weight);
    _updateExerciseRows(exercise, rows);
  }

  Future<double?> _showWeightPicker(double initialWeight) async {
    final values = List<double>.generate(161, (i) => i * 2.5); // 0..400kg
    int selectedIndex = values.indexWhere(
      (v) => (v - initialWeight).abs() < 0.01,
    );
    if (selectedIndex == -1) {
      selectedIndex = (initialWeight / 2.5).round().clamp(0, values.length - 1);
    }
    double selectedValue = values[selectedIndex];

    final result = await showModalBottomSheet<double>(
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
                                if (!context.mounted) return;
                                if (typed == null) return;
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

    return result;
  }

  Future<double?> _promptTypedWeight(double currentValue) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(currentValue % 1 == 0 ? 0 : 1),
    );
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Type weight'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              suffixText: 'kg',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kAccentColor),
              onPressed: () {
                final value = double.tryParse(controller.text.trim());
                if (value == null) return;
                Navigator.pop(context, value.clamp(0, 400));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  Future<void> _editRestCell(
    WorkoutTemplateExercise exercise,
    int rowIndex,
  ) async {
    final current = exercise.presetRows[rowIndex].restSeconds;
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
    if (selected == null) return;
    final rows = List<WorkoutTemplateSetRow>.from(exercise.presetRows);
    rows[rowIndex] = rows[rowIndex].copyWith(restSeconds: selected);
    _updateExerciseRows(exercise, rows);
  }

  Widget _buildEditableSetTable(WorkoutTemplateExercise exercise) {
    final rows = exercise.presetRows;
    return Column(
      children: [
        Row(
          children: const [
            _TableHeaderCell('SETS'),
            _TableHeaderCell('REPS'),
            _TableHeaderCell('WEIGHT'),
            _TableHeaderCell('REST'),
          ],
        ),
        const SizedBox(height: 6),
        ...rows.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: _EditableCell(
                    label: row.label,
                    onTap: () => _editSetTypeCell(exercise, rowIndex),
                  ),
                ),
                Expanded(
                  child: _EditableCell(
                    label: '${row.reps}',
                    onTap: () => _editRepsCell(exercise, rowIndex),
                  ),
                ),
                Expanded(
                  child: _EditableCell(
                    label:
                        row.weightKg <= 0
                            ? '--'
                            : '${row.weightKg.toStringAsFixed(row.weightKg % 1 == 0 ? 0 : 1)}KG',
                    onTap: () => _editWeightCell(exercise, rowIndex),
                  ),
                ),
                Expanded(
                  child: _EditableCell(
                    label:
                        row.restSeconds <= 0
                            ? '--'
                            : _formatRest(row.restSeconds),
                    onTap: () => _editRestCell(exercise, rowIndex),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _saveTemplate() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final rawTags = _derivedFocusTagsFromExercises(_exercises);

    final template = widget.template.copyWith(
      name: name,
      imageUrl:
          _imageController.text.trim().isEmpty
              ? widget.template.imageUrl
              : _imageController.text.trim(),
      durationMinutes: _durationMinutes,
      focusTags: rawTags.isEmpty ? const ['Custom'] : rawTags,
      exercises: _exercises,
    );

    widget.onSave(template);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftTemplatePreview;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Stack(
                children: [
                  _TemplateHeroDetailCard(
                    template: draft,
                    durationLabel: _formatDuration(
                      draft.estimatedDurationMinutes,
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: InkWell(
                      onTap: _editHeroImage,
                      borderRadius: BorderRadius.circular(999),
                      child: Ink(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.30),
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SectionBoundary(
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template settings',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Workout name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Muscles worked (generated from exercises)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          draft.focusTags
                              .map((tag) => _EditStateChip(label: tag))
                              .toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Target duration',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        _DurationChip(label: '$_durationMinutes mins'),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Estimated from exercise time + rest: $_estimatedDurationFromExercisesMinutes mins',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (_durationOverTargetMinutes > 0) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange.shade800,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current build is $_durationOverTargetMinutes min over your target duration.',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 20,
                      max: 120,
                      divisions: 20,
                      activeColor: kAccentColor,
                      label: 'Target $_durationMinutes',
                      onChanged: (value) {
                        setState(() => _durationMinutes = value.round());
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Exercises (${_exercises.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _addExerciseFromCatalog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercise'),
                  ),
                ],
              ),
              if (_exercises.isEmpty)
                SectionBoundary(
                  borderRadius: 16,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No exercises yet.\nAdd one to start building this workout.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  clipBehavior: Clip.hardEdge,
                  buildDefaultDragHandles: false,
                  proxyDecorator: _exerciseReorderProxyDecorator,
                  itemCount: _exercises.length,
                  onReorder: _reorderExercises,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Padding(
                      key: ValueKey(exercise.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: _ExerciseDetailCard(
                          exercise: exercise,
                          isExpanded: _expandedExerciseIds.contains(
                            exercise.id,
                          ),
                          restFormatter: _formatRest,
                          onToggle: () {
                            setState(() {
                              if (_expandedExerciseIds.contains(exercise.id)) {
                                _expandedExerciseIds.remove(exercise.id);
                              } else {
                                _expandedExerciseIds.add(exercise.id);
                              }
                            });
                          },
                          expandedTable: _buildEditableSetTable(exercise),
                          footer: Row(
                            children: [
                              const Spacer(),
                              InkWell(
                                onTap: () => _swapExercise(exercise),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 18,
                                        color: Colors.grey.shade700,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Swap',
                                        style: TextStyle(
                                          color: Colors.grey.shade800,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _exercises.removeWhere(
                                      (e) => e.id == exercise.id,
                                    );
                                    _expandedExerciseIds.remove(exercise.id);
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.red.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.red.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            InkWell(
              onTap: _addExerciseFromCatalog,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: const Icon(Icons.add, size: 28, color: kAccentColor),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _saveTemplate,
                child: const Text('SAVE TEMPLATE'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Tip: hold and drag an exercise card to rearrange. Tap a card to collapse/expand while editing.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/models/workout_template.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const String _kExercisePlaceholderImageUrl =
    'https://blocks.astratic.com/img/general-img-landscape.png';

enum _WorkoutMenuAction { edit, review, share }

class TodayWorkoutDetailScreen extends StatefulWidget {
  const TodayWorkoutDetailScreen({
    super.key,
    required this.template,
    required this.history,
    required this.onEdit,
    required this.onStart,
  });

  final WorkoutTemplate template;
  final List<WorkoutHistoryEntry> history;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  @override
  State<TodayWorkoutDetailScreen> createState() =>
      _TodayWorkoutDetailScreenState();
}

class _TodayWorkoutDetailScreenState extends State<TodayWorkoutDetailScreen> {
  final Set<String> _expandedExerciseIds = <String>{};

  @override
  void initState() {
    super.initState();
    if (widget.template.exercises.isNotEmpty) {
      _expandedExerciseIds.add(widget.template.exercises.first.id);
    }
  }

  List<WorkoutHistoryEntry> get _historyForTemplate {
    final key = widget.template.name.trim().toLowerCase();
    final matches = widget.history
        .where((entry) => entry.workoutName.trim().toLowerCase() == key)
        .toList(growable: false);
    final sorted = List<WorkoutHistoryEntry>.from(matches);
    sorted.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    return sorted;
  }

  String _formatRest(int seconds) {
    final minutes = seconds ~/ 60;
    final rem = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rem';
  }

  String _formatWeight(double value) {
    if (value == value.roundToDouble()) {
      return '${value.round()}KG';
    }
    return '${value.toStringAsFixed(1)}KG';
  }

  void _openTrends() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => _WorkoutTrendsScreen(
              workoutName: widget.template.name,
              entries: _historyForTemplate,
            ),
      ),
    );
  }

  void _handleEdit() {
    widget.onEdit();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _handleStart() {
    widget.onStart();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _handleMenuSelection(_WorkoutMenuAction action) {
    switch (action) {
      case _WorkoutMenuAction.edit:
        _handleEdit();
        break;
      case _WorkoutMenuAction.review:
        _openReview();
        break;
      case _WorkoutMenuAction.share:
        _shareWorkout();
        break;
    }
  }

  Future<void> _showWorkoutOptionsSheet() async {
    final action = await showModalBottomSheet<_WorkoutMenuAction>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          bottom: false,
          child: GlassContainer(
            borderRadius: 24,
            blur: 18,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 8),
                _WorkoutActionRow(
                  icon: PhosphorIconsRegular.pencilSimple,
                  label: 'Edit workout',
                  onTap: () {
                    Navigator.of(sheetContext).pop(_WorkoutMenuAction.edit);
                  },
                ),
                const SizedBox(height: 8),
                _WorkoutActionRow(
                  icon: PhosphorIconsRegular.notepad,
                  label: 'Review',
                  onTap: () {
                    Navigator.of(sheetContext).pop(_WorkoutMenuAction.review);
                  },
                ),
                const SizedBox(height: 8),
                _WorkoutActionRow(
                  icon: PhosphorIconsRegular.shareFat,
                  label: 'Share',
                  onTap: () {
                    Navigator.of(sheetContext).pop(_WorkoutMenuAction.share);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || action == null) return;
    _handleMenuSelection(action);
  }

  void _openReview() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder:
            (_) => _WorkoutReviewScreen(
              template: widget.template,
              history: _historyForTemplate,
            ),
      ),
    );
  }

  void _shareWorkout() async {
    final text = '''
Workout: ${widget.template.name}
Duration: ${widget.template.estimatedDurationMinutes} min
Exercises: ${widget.template.exercises.length}
''';

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Workout info copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    const bottomActionRowHeight = 64.0;
    const bottomActionRowMargin = 14.0;
    final listBottomPadding =
        bottomInset + bottomActionRowHeight + bottomActionRowMargin + 8;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  LiftIslandHeader(
                    title: widget.template.name.toUpperCase(),
                    leading: LiftIslandHeaderAction(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    trailing: LiftIslandHeaderAction(
                      onTap: _showWorkoutOptionsSheet,
                      child: const PhosphorIcon(
                        PhosphorIconsRegular.dotsThreeOutlineVertical,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: listBottomPadding),
                      children: [
                        _HeroWorkoutCard(
                          template: widget.template,
                          durationLabel:
                              '${widget.template.estimatedDurationMinutes} min',
                          exercisesLabel:
                              '${widget.template.exercises.length} exercises',
                        ),
                        const SizedBox(height: 12),
                        ...widget.template.exercises.map((exercise) {
                          final isExpanded = _expandedExerciseIds.contains(
                            exercise.id,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ExercisePreviewCard(
                              exercise: exercise,
                              restFormatter: _formatRest,
                              weightFormatter: _formatWeight,
                              isExpanded: isExpanded,
                              onToggle: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedExerciseIds.remove(exercise.id);
                                  } else {
                                    _expandedExerciseIds.add(exercise.id);
                                  }
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SafeArea(
                top: false,
                bottom: false,
                child: Container(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.97),
                          borderRadius: BorderRadius.circular(32),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: OutlinedButton(
                                  onPressed: _openTrends,
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: kAccentColor,
                                    side: BorderSide(
                                      color: kAccentColor.withValues(
                                        alpha: 0.55,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Trends',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kAccentColor,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: FilledButton(
                                  onPressed: _handleStart,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                  ),
                                  child: const Text(
                                    'Start',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutActionRow extends StatelessWidget {
  const _WorkoutActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final PhosphorIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const color = Colors.black87;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.20)),
          color: Colors.white.withValues(alpha: 0.35),
        ),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroWorkoutCard extends StatelessWidget {
  const _HeroWorkoutCard({
    required this.template,
    required this.durationLabel,
    required this.exercisesLabel,
  });

  final WorkoutTemplate template;
  final String durationLabel;
  final String exercisesLabel;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      padding: EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: 1.12,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                template.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_outlined,
                      color: Colors.grey.shade500,
                      size: 58,
                    ),
                  );
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 24, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.black.withValues(alpha: 0.46),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          template.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      _HeroPill(label: durationLabel),
                      const SizedBox(width: 8),
                      _HeroPill(label: exercisesLabel),
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

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExercisePreviewCard extends StatelessWidget {
  const _ExercisePreviewCard({
    required this.exercise,
    required this.restFormatter,
    required this.weightFormatter,
    required this.isExpanded,
    required this.onToggle,
    this.footer,
  });

  final WorkoutTemplateExercise exercise;
  final String Function(int seconds) restFormatter;
  final String Function(double weightKg) weightFormatter;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SectionBoundary(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.network(
                    _kExercisePlaceholderImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Icons.image_outlined,
                          color: Colors.grey.shade500,
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
                      exercise.name.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _SetPill(label: '${exercise.presetRows.length} sets'),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 30,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'SETS',
                    style: _ColumnLabelStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'REPS',
                    style: _ColumnLabelStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'WEIGHT',
                    style: _ColumnLabelStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'REST',
                    style: _ColumnLabelStyle(),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...exercise.presetRows.map(
              (row) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 19,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${row.reps}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        weightFormatter(row.weightKg),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        restFormatter(row.restSeconds),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isExpanded && footer != null) ...[
            const SizedBox(height: 8),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _ColumnLabelStyle extends TextStyle {
  const _ColumnLabelStyle()
    : super(
        fontSize: 12,
        color: Colors.grey,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.35,
      );
}

class _SetPill extends StatelessWidget {
  const _SetPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: kAccentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: kAccentColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WorkoutTrendsScreen extends StatelessWidget {
  const _WorkoutTrendsScreen({
    required this.workoutName,
    required this.entries,
  });

  final String workoutName;
  final List<WorkoutHistoryEntry> entries;

  String _formatDuration(Duration value) {
    final minutes = value.inMinutes;
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '${minutes}m $seconds';
  }

  String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final totalVolume = entries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalVolumeKg,
    );
    final totalDuration = entries.fold<Duration>(
      Duration.zero,
      (sum, entry) => sum + entry.duration,
    );
    final avgDuration =
        entries.isEmpty
            ? Duration.zero
            : Duration(seconds: totalDuration.inSeconds ~/ entries.length);
    final avgVolume = entries.isEmpty ? 0.0 : totalVolume / entries.length;
    final prs = entries.fold<int>(0, (sum, entry) => sum + entry.prsAchieved);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  Expanded(
                    child: Text(
                      '$workoutName Trends',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 8),
              SectionBoundary(
                child: Row(
                  children: [
                    _TrendMetric(label: 'Sessions', value: '${entries.length}'),
                    _TrendMetric(
                      label: 'Avg duration',
                      value: _formatDuration(avgDuration),
                    ),
                    _TrendMetric(
                      label: 'Avg volume',
                      value:
                          avgVolume == avgVolume.roundToDouble()
                              ? '${avgVolume.round()}kg'
                              : '${avgVolume.toStringAsFixed(1)}kg',
                    ),
                    _TrendMetric(label: 'PRs', value: '$prs'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child:
                    entries.isEmpty
                        ? SectionBoundary(
                          child: Center(
                            child: Text(
                              'No previous sessions yet for this workout.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        : ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return SectionBoundary(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDate(entry.completedAt),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    _formatDuration(entry.duration),
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${entry.totalVolumeKg.round()}kg',
                                    style: const TextStyle(
                                      color: kAccentColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
  }
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          color: Colors.grey.shade50,
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutReviewScreen extends StatefulWidget {
  const _WorkoutReviewScreen({required this.template, required this.history});

  final WorkoutTemplate template;
  final List<WorkoutHistoryEntry> history;

  @override
  State<_WorkoutReviewScreen> createState() => _WorkoutReviewScreenState();
}

class _WorkoutReviewScreenState extends State<_WorkoutReviewScreen> {
  late List<WorkoutTemplateExercise> _exercises;
  final Set<String> _expandedExerciseIds = <String>{};
  late final Map<String, TextEditingController> _weightControllers;

  static const List<String> _swapOptions = [
    'Leg Press',
    'Hamstring Curls',
    'Leg Extension',
    'Barbell Back Squat',
    'Romanian Deadlift',
    'Dumbbell Lunges',
    'Standing Calf Raise',
    'Lat Pulldown',
    'Seated Row',
    'Cable Face Pull',
    'Wrist Curl',
    'Push Up',
    'Chest Press',
    'Lateral Raise',
    'Tricep Pushdown',
    'Bench Press',
  ];

  @override
  void initState() {
    super.initState();

    final lastEntry = widget.history.isNotEmpty ? widget.history.first : null;
    final lastWeights = <String, double>{};

    if (lastEntry != null) {
      for (final summary in lastEntry.exerciseSummaries) {
        lastWeights[summary.exerciseName] = summary.maxWeightKg;
      }
    }

    _exercises = List<WorkoutTemplateExercise>.from(widget.template.exercises);

    _weightControllers = {
      for (final exercise in _exercises)
        exercise.id: TextEditingController(
          text: (lastWeights[exercise.name] ??
                  exercise.presetRows
                      .map((r) => r.weightKg)
                      .fold<double>(0, (a, b) => a > b ? a : b))
              .toStringAsFixed(1),
        ),
    };

    _expandedExerciseIds.addAll(_exercises.map((e) => e.id));
  }

  @override
  void dispose() {
    for (final controller in _weightControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _swapExercise(WorkoutTemplateExercise exercise) async {
    final selected = await showModalBottomSheet<String>(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Swap exercise',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose a new exercise for this slot.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ..._swapOptions.map(
                  (option) => ListTile(
                    title: Text(option),
                    trailing:
                        option == exercise.name
                            ? const Icon(Icons.check, color: kAccentColor)
                            : null,
                    onTap: () => Navigator.pop(context, option),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected == null || selected == exercise.name) return;

    setState(() {
      final index = _exercises.indexWhere((e) => e.id == exercise.id);
      if (index < 0) return;
      _exercises[index] = _exercises[index].copyWith(name: selected);
      _expandedExerciseIds.add(exercise.id);
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      if (oldIndex == newIndex) return;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
  }

  void _handleSave() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review saved (not persisted)')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            children: [
              LiftIslandHeader(
                title: 'REVIEW WORKOUT',
                leading: LiftIslandHeaderAction(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                trailing: LiftIslandHeaderAction(
                  onTap: _handleSave,
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ReorderableListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  onReorder: _reorderExercises,
                  proxyDecorator: (child, index, animation) {
                    return Material(
                      elevation: 12,
                      borderRadius: BorderRadius.circular(16),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    final controller = _weightControllers[exercise.id]!;
                    final isExpanded = _expandedExerciseIds.contains(
                      exercise.id,
                    );

                    return Padding(
                      key: ValueKey(exercise.id),
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReorderableDelayedDragStartListener(
                        index: index,
                        child: _ExercisePreviewCard(
                          exercise: exercise,
                          isExpanded: isExpanded,
                          onToggle: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedExerciseIds.remove(exercise.id);
                              } else {
                                _expandedExerciseIds.add(exercise.id);
                              }
                            });
                          },
                          restFormatter: (seconds) {
                            final minutes = seconds ~/ 60;
                            final rem = (seconds % 60).toString().padLeft(
                              2,
                              '0',
                            );
                            return '$minutes:$rem';
                          },
                          weightFormatter: (weight) {
                            if (weight == weight.roundToDouble()) {
                              return '${weight.round()}KG';
                            }
                            return '${weight.toStringAsFixed(1)}KG';
                          },
                          footer: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: controller,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: const InputDecoration(
                                  labelText: 'Last logged weight (kg)',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _swapExercise(exercise),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: kAccentColor,
                                        side: BorderSide(
                                          color: kAccentColor.withValues(
                                            alpha: 0.55,
                                          ),
                                        ),
                                      ),
                                      child: const Text('Swap'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _exercises.removeWhere(
                                            (e) => e.id == exercise.id,
                                          );
                                          _expandedExerciseIds.remove(
                                            exercise.id,
                                          );
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red.shade600,
                                        side: BorderSide(
                                          color: Colors.red.shade200,
                                        ),
                                      ),
                                      child: const Text('Remove'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
  }
}

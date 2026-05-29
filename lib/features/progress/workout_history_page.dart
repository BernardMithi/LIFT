import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/progress/workout_history_detail_page.dart';
import 'package:lift/shared/exercise_demo_images.dart';
import 'package:lift/shared/icons/mynaui_glyphs.dart';
import 'package:lift/shared/icons/mynaui_icon.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/widgets/lift_island_header.dart';
import 'package:lift/shared/widgets/lift_pressable.dart';
import 'package:lift/shared/widgets/surfaces.dart';

const Color _kWorkoutHistoryCanvas = Color(0xFFF2F2F7);

class WorkoutHistoryPage extends StatelessWidget {
  const WorkoutHistoryPage({
    super.key,
    required this.entries,
    this.subtitle = 'All logged sessions',
  });

  final List<WorkoutHistoryEntry> entries;
  final String subtitle;

  int get _totalMinutes =>
      entries.fold<int>(0, (sum, entry) => sum + entry.duration.inMinutes);

  double get _totalVolume =>
      entries.fold<double>(0, (sum, entry) => sum + entry.totalVolumeKg);

  @override
  Widget build(BuildContext context) {
    final sorted = List<WorkoutHistoryEntry>.from(entries)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ColoredBox(
        color: _kWorkoutHistoryCanvas,
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
                  subtitle: subtitle,
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
                          value: '${sorted.length}',
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
                  child:
                      sorted.isEmpty
                          ? const Center(
                            child: Text(
                              'No workouts logged yet.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF6D7178),
                              ),
                            ),
                          )
                          : ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: sorted.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 10),
                            itemBuilder:
                                (context, index) => SectionBoundary(
                                  child: _WorkoutHistoryRow(
                                    entry: sorted[index],
                                    onTap:
                                        () => pushWorkoutHistoryDetailPage(
                                          context,
                                          entry: sorted[index],
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
        borderRadius: BorderRadius.circular(kIosCornerRadius),
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
            style: TextStyle(
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutHistoryRow extends StatelessWidget {
  const _WorkoutHistoryRow({required this.entry, this.onTap});

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

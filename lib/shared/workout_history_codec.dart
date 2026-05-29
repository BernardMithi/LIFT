import 'package:lift/shared/models/workout_history_entry.dart';

/// Same key as [HomeScreen] local persistence.
const String kWorkoutHistoryStorageKey = 'lift_workout_history_v1';

WorkoutHistoryEntry? workoutHistoryEntryFromMap(Map<String, dynamic> map) {
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
        final setRowsRaw = summaryMap['setRows'];
        final setRows = <WorkoutHistorySetRow>[];
        if (setRowsRaw is List) {
          for (final row in setRowsRaw) {
            if (row is! Map) continue;
            final rowMap = row.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            setRows.add(
              WorkoutHistorySetRow(
                label: '${rowMap['label'] ?? ''}'.trim(),
                reps: (rowMap['reps'] as num?)?.toInt() ?? 0,
                weightKg: (rowMap['weightKg'] as num?)?.toDouble() ?? 0,
                restSeconds: (rowMap['restSeconds'] as num?)?.toInt() ?? 0,
              ),
            );
          }
        }
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
            setRows: List<WorkoutHistorySetRow>.unmodifiable(setRows),
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

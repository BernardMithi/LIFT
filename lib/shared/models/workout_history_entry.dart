class WorkoutHistoryEntry {
  const WorkoutHistoryEntry({
    required this.id,
    required this.workoutName,
    required this.startedAt,
    required this.completedAt,
    required this.duration,
    required this.totalVolumeKg,
    required this.totalReps,
    required this.exercisesCompleted,
    required this.totalExercises,
    required this.prsAchieved,
    required this.exerciseSummaries,
    required this.muscleGroupVolumeKg,
  });

  final String id;
  final String workoutName;
  final DateTime startedAt;
  final DateTime completedAt;
  final Duration duration;
  final double totalVolumeKg;
  final int totalReps;
  final int exercisesCompleted;
  final int totalExercises;
  final int prsAchieved;
  final List<WorkoutHistoryExerciseSummary> exerciseSummaries;
  final Map<String, double> muscleGroupVolumeKg;
}

class WorkoutHistoryExerciseSummary {
  const WorkoutHistoryExerciseSummary({
    required this.exerciseName,
    required this.setCount,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.maxWeightKg,
    required this.muscleGroups,
  });

  final String exerciseName;
  final int setCount;
  final int totalReps;
  final double totalVolumeKg;
  final double maxWeightKg;
  final List<String> muscleGroups;
}

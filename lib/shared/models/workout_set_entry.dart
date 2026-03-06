class WorkoutSetEntry {
  const WorkoutSetEntry({
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    required this.createdAt,
    required this.restSecondsPlanned,
  });

  final int setNumber;
  final double weightKg;
  final int reps;
  final DateTime createdAt;
  final int restSecondsPlanned;
}

class LogSetDraft {
  const LogSetDraft({
    required this.weightKg,
    required this.reps,
    required this.restSeconds,
  });

  final double weightKg;
  final int reps;
  final int restSeconds;
}

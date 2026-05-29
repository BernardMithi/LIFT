class WorkoutSetEntry {
  const WorkoutSetEntry({
    required this.setNumber,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.createdAt,
    required this.restSecondsPlanned,
  });

  final int setNumber;

  /// Movement name (e.g. from the machine’s supported exercises).
  final String exerciseName;

  final double weightKg;
  final int reps;
  final DateTime createdAt;
  final int restSecondsPlanned;

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'exerciseName': exerciseName,
    'weightKg': weightKg,
    'reps': reps,
    'createdAt': createdAt.toIso8601String(),
    'restSecondsPlanned': restSecondsPlanned,
  };

  static WorkoutSetEntry? fromJsonMap(Map<String, dynamic> json) {
    try {
      final createdRaw = json['createdAt'];
      if (createdRaw is! String) return null;
      final createdAt = DateTime.tryParse(createdRaw);
      if (createdAt == null) return null;
      return WorkoutSetEntry(
        setNumber: (json['setNumber'] as num?)?.toInt() ?? 1,
        exerciseName: (json['exerciseName'] as String?)?.trim() ?? '',
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        reps: (json['reps'] as num?)?.toInt() ?? 0,
        createdAt: createdAt,
        restSecondsPlanned: (json['restSecondsPlanned'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
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

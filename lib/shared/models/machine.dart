class Machine {
  const Machine({
    required this.id,
    required this.machineCode,
    required this.brand,
    required this.fullName,
    required this.displayName,
    required this.zone,
    required this.muscleGroups,
    required this.imageUrl,
    required this.heroImageUrl,
    required this.supportedExercises,
    required this.lastWeightKg,
    required this.lastReps,
    required this.lastUsedLabel,
    this.lastExerciseName,
    required this.defaultRestSeconds,
  });

  final String id;
  final String machineCode;
  final String brand;
  final String fullName;
  final String displayName;
  final String zone;
  final List<String> muscleGroups;
  final String imageUrl;
  final String heroImageUrl;
  final List<String> supportedExercises;
  final double lastWeightKg;
  final int lastReps;
  final String lastUsedLabel;

  /// Which movement was used last session (machines often support several).
  final String? lastExerciseName;

  final int defaultRestSeconds;
}

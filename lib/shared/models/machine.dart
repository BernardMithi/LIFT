class Machine {
  const Machine({
    required this.id,
    required this.machineCode,
    required this.displayName,
    required this.zone,
    required this.muscleGroups,
    required this.imageUrl,
    required this.lastWeightKg,
    required this.lastReps,
    required this.lastUsedLabel,
    required this.defaultRestSeconds,
  });

  final String id;
  final String machineCode;
  final String displayName;
  final String zone;
  final List<String> muscleGroups;
  final String imageUrl;
  final double lastWeightKg;
  final int lastReps;
  final String lastUsedLabel;
  final int defaultRestSeconds;
}

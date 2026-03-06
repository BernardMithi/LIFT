class WorkoutTemplate {
  const WorkoutTemplate({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.durationMinutes,
    required this.focusTags,
    required this.exercises,
  });

  final String id;
  final String name;
  final String imageUrl;
  final int durationMinutes;
  final List<String> focusTags;
  final List<WorkoutTemplateExercise> exercises;

  int get exerciseTimeMinutes => exercises.fold<int>(
    0,
    (sum, exercise) => sum + exercise.estimatedMinutes,
  );

  int get totalRestSeconds => exercises.fold<int>(
    0,
    (sum, exercise) =>
        sum +
        exercise.presetRows.fold<int>(
          0,
          (restSum, row) => restSum + row.restSeconds,
        ),
  );

  int get estimatedDurationMinutes {
    if (exercises.isEmpty) return durationMinutes;
    final restMinutes = (totalRestSeconds / 60).ceil();
    return exerciseTimeMinutes + restMinutes;
  }

  WorkoutTemplate copyWith({
    String? id,
    String? name,
    String? imageUrl,
    int? durationMinutes,
    List<String>? focusTags,
    List<WorkoutTemplateExercise>? exercises,
  }) {
    return WorkoutTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      focusTags: focusTags ?? this.focusTags,
      exercises: exercises ?? this.exercises,
    );
  }
}

class WorkoutTemplateExercise {
  const WorkoutTemplateExercise({
    required this.id,
    required this.name,
    required this.setCount,
    required this.estimatedMinutes,
    required this.presetRows,
  });

  final String id;
  final String name;
  final int setCount;
  final int estimatedMinutes;
  final List<WorkoutTemplateSetRow> presetRows;

  WorkoutTemplateExercise copyWith({
    String? id,
    String? name,
    int? setCount,
    int? estimatedMinutes,
    List<WorkoutTemplateSetRow>? presetRows,
  }) {
    return WorkoutTemplateExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      setCount: setCount ?? this.setCount,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      presetRows: presetRows ?? this.presetRows,
    );
  }
}

class WorkoutTemplateSetRow {
  const WorkoutTemplateSetRow({
    required this.label,
    required this.reps,
    required this.weightKg,
    required this.restSeconds,
  });

  final String label;
  final int reps;
  final double weightKg;
  final int restSeconds;

  WorkoutTemplateSetRow copyWith({
    String? label,
    int? reps,
    double? weightKg,
    int? restSeconds,
  }) {
    return WorkoutTemplateSetRow(
      label: label ?? this.label,
      reps: reps ?? this.reps,
      weightKg: weightKg ?? this.weightKg,
      restSeconds: restSeconds ?? this.restSeconds,
    );
  }
}

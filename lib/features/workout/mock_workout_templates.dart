import 'package:lift/shared/models/workout_template.dart';

class MockWorkoutTemplates {
  static List<WorkoutTemplate> seed() {
    return const [
      WorkoutTemplate(
        id: 'template_leg_day',
        name: 'Leg Day',
        imageUrl:
            'https://images.pexels.com/photos/949130/pexels-photo-949130.jpeg',
        durationMinutes: 85,
        focusTags: ['Quads', 'Hamstrings', 'Glutes'],
        exercises: [
          WorkoutTemplateExercise(
            id: 'ham_curls',
            name: 'Hamstring Curls',
            setCount: 3,
            estimatedMinutes: 25,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 15,
                weightKg: 35,
                restSeconds: 150,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 12,
                weightKg: 65,
                restSeconds: 150,
              ),
              WorkoutTemplateSetRow(
                label: '2',
                reps: 12,
                weightKg: 65,
                restSeconds: 150,
              ),
            ],
          ),
          WorkoutTemplateExercise(
            id: 'leg_press',
            name: 'Leg Press',
            setCount: 4,
            estimatedMinutes: 20,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 12,
                weightKg: 80,
                restSeconds: 150,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 10,
                weightKg: 140,
                restSeconds: 180,
              ),
              WorkoutTemplateSetRow(
                label: '2',
                reps: 10,
                weightKg: 140,
                restSeconds: 180,
              ),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        id: 'template_push',
        name: 'Push',
        imageUrl:
            'https://images.pexels.com/photos/4162490/pexels-photo-4162490.jpeg',
        durationMinutes: 50,
        focusTags: ['Chest', 'Shoulders', 'Triceps'],
        exercises: [
          WorkoutTemplateExercise(
            id: 'chest_press',
            name: 'Chest Press',
            setCount: 4,
            estimatedMinutes: 18,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 15,
                weightKg: 30,
                restSeconds: 120,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 10,
                weightKg: 55,
                restSeconds: 150,
              ),
            ],
          ),
          WorkoutTemplateExercise(
            id: 'lateral_raise',
            name: 'Lateral Raise',
            setCount: 3,
            estimatedMinutes: 12,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 15,
                weightKg: 6,
                restSeconds: 90,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 12,
                weightKg: 10,
                restSeconds: 120,
              ),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        id: 'template_pull',
        name: 'Pull',
        imageUrl:
            'https://images.pexels.com/photos/18060190/pexels-photo-18060190.jpeg',
        durationMinutes: 45,
        focusTags: ['Back', 'Biceps'],
        exercises: [
          WorkoutTemplateExercise(
            id: 'lat_pulldown',
            name: 'Lat Pulldown',
            setCount: 4,
            estimatedMinutes: 16,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 15,
                weightKg: 25,
                restSeconds: 120,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 12,
                weightKg: 55,
                restSeconds: 150,
              ),
            ],
          ),
          WorkoutTemplateExercise(
            id: 'seated_row',
            name: 'Seated Row',
            setCount: 3,
            estimatedMinutes: 14,
            presetRows: [
              WorkoutTemplateSetRow(
                label: 'W',
                reps: 12,
                weightKg: 35,
                restSeconds: 120,
              ),
              WorkoutTemplateSetRow(
                label: '1',
                reps: 10,
                weightKg: 60,
                restSeconds: 150,
              ),
            ],
          ),
        ],
      ),
      WorkoutTemplate(
        id: 'template_core_cardio',
        name: 'Core & Cardio',
        imageUrl:
            'https://images.pexels.com/photos/1552242/pexels-photo-1552242.jpeg',
        durationMinutes: 60,
        focusTags: ['Core', 'Conditioning'],
        exercises: [
          WorkoutTemplateExercise(
            id: 'ab_crunch',
            name: 'Ab Crunch Machine',
            setCount: 3,
            estimatedMinutes: 15,
            presetRows: [
              WorkoutTemplateSetRow(
                label: '1',
                reps: 15,
                weightKg: 20,
                restSeconds: 90,
              ),
              WorkoutTemplateSetRow(
                label: '2',
                reps: 12,
                weightKg: 25,
                restSeconds: 90,
              ),
            ],
          ),
          WorkoutTemplateExercise(
            id: 'incline_walk',
            name: 'Incline Walk',
            setCount: 1,
            estimatedMinutes: 20,
            presetRows: [
              WorkoutTemplateSetRow(
                label: '1',
                reps: 1,
                weightKg: 0,
                restSeconds: 0,
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

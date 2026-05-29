// Thumbnails from Motra (Train Fitness) exercise guides.
// Library: https://www.motra.com/exercises?muscle=&equipment=&type=allTypes&sortBy=pop&page=1&search=
// Each URL uses the official CDN still used on exercise pages (og:image → exercise-assets/…/thumbnailOriginal.jpg).

const String kMotraExerciseLibraryUrl =
    'https://www.motra.com/exercises?muscle=&equipment=&type=allTypes&sortBy=pop&page=1&search=';

/// Neutral fallback when a name is not in [kExerciseDemoImageByName] (Motra leg press artwork).
const String kFallbackExerciseImage =
    'https://cdn.motra.com/exercise-assets/12e71a5177/thumbnailOriginal.jpg';

/// Maps [WorkoutTemplateExercise.name] / catalog labels → Motra CDN thumbnail.
/// Slugs (for reference when adding names): motra.com/ex/{camelCaseSlug}
const Map<String, String> kExerciseDemoImageByName = {
  'Leg Press':
      'https://cdn.motra.com/exercise-assets/12e71a5177/thumbnailOriginal.jpg',
  'Machine Leg Press':
      'https://cdn.motra.com/exercise-assets/12e71a5177/thumbnailOriginal.jpg',
  'Hamstring Curls':
      'https://cdn.motra.com/exercise-assets/65660a28ea/thumbnailOriginal.jpg',
  'Leg Extension':
      'https://cdn.motra.com/exercise-assets/58842e7380/thumbnailOriginal.jpg',
  'Seated Leg Extension':
      'https://cdn.motra.com/exercise-assets/58842e7380/thumbnailOriginal.jpg',
  'Barbell Back Squat':
      'https://cdn.motra.com/exercise-assets/081135bec4/thumbnailOriginal.jpg',
  'Back Squat':
      'https://cdn.motra.com/exercise-assets/081135bec4/thumbnailOriginal.jpg',
  'Barbell Squat':
      'https://cdn.motra.com/exercise-assets/081135bec4/thumbnailOriginal.jpg',
  'Romanian Deadlift':
      'https://cdn.motra.com/exercise-assets/c9dd20f5ba/thumbnailOriginal.jpg',
  'RDL':
      'https://cdn.motra.com/exercise-assets/c9dd20f5ba/thumbnailOriginal.jpg',
  'Dumbbell Lunges':
      'https://cdn.motra.com/exercise-assets/a3aa32395c/thumbnailOriginal.jpg',
  'Dumbbell Lunge':
      'https://cdn.motra.com/exercise-assets/a3aa32395c/thumbnailOriginal.jpg',
  'Standing Calf Raise':
      'https://cdn.motra.com/exercise-assets/e24404d742/thumbnailOriginal.jpg',
  'Standing Calf Raises':
      'https://cdn.motra.com/exercise-assets/e24404d742/thumbnailOriginal.jpg',
  'Lat Pulldown':
      'https://cdn.motra.com/exercise-assets/3897e79551/thumbnailOriginal.jpg',
  'Lat Pull Down':
      'https://cdn.motra.com/exercise-assets/3897e79551/thumbnailOriginal.jpg',
  'Seated Row':
      'https://cdn.motra.com/exercise-assets/911f003a30/thumbnailOriginal.jpg',
  'Seated Cable Row':
      'https://cdn.motra.com/exercise-assets/911f003a30/thumbnailOriginal.jpg',
  'Single Arm Row':
      'https://cdn.motra.com/exercise-assets/911f003a30/thumbnailOriginal.jpg',
  'Wide Grip Row':
      'https://cdn.motra.com/exercise-assets/911f003a30/thumbnailOriginal.jpg',
  'Neutral Grip Row':
      'https://cdn.motra.com/exercise-assets/911f003a30/thumbnailOriginal.jpg',
  'Cable Face Pull':
      'https://cdn.motra.com/exercise-assets/8e30c2c2a2/thumbnailOriginal.jpg',
  'Face Pull':
      'https://cdn.motra.com/exercise-assets/8e30c2c2a2/thumbnailOriginal.jpg',
  'Cable Facepull':
      'https://cdn.motra.com/exercise-assets/8e30c2c2a2/thumbnailOriginal.jpg',
  'Pull Up':
      'https://cdn.motra.com/exercise-assets/f0d6e6aebf/thumbnailOriginal.jpg',
  'Pull-ups':
      'https://cdn.motra.com/exercise-assets/f0d6e6aebf/thumbnailOriginal.jpg',
  'Pullups':
      'https://cdn.motra.com/exercise-assets/f0d6e6aebf/thumbnailOriginal.jpg',
  'Wrist Curl':
      'https://cdn.motra.com/exercise-assets/291b18753b/thumbnailOriginal.jpg',
  'Cable Wrist Curl':
      'https://cdn.motra.com/exercise-assets/291b18753b/thumbnailOriginal.jpg',
  'Hammer Curls':
      'https://cdn.motra.com/exercise-assets/1bbae50800/thumbnailOriginal.jpg',
  'Hammer Curl':
      'https://cdn.motra.com/exercise-assets/1bbae50800/thumbnailOriginal.jpg',
  'Chest Press':
      'https://cdn.motra.com/exercise-assets/d96346654e/thumbnailOriginal.jpg',
  'Machine Chest Press':
      'https://cdn.motra.com/exercise-assets/d96346654e/thumbnailOriginal.jpg',
  'Shoulder Press':
      'https://cdn.motra.com/exercise-assets/acd29d0b82/thumbnailOriginal.jpg',
  'Machine Shoulder Press':
      'https://cdn.motra.com/exercise-assets/acd29d0b82/thumbnailOriginal.jpg',
  'Overhead Press':
      'https://cdn.motra.com/exercise-assets/acd29d0b82/thumbnailOriginal.jpg',
  'Lateral Raise':
      'https://cdn.motra.com/exercise-assets/b3df8c4d1e/thumbnailOriginal.jpg',
  'Lateral Raises':
      'https://cdn.motra.com/exercise-assets/b3df8c4d1e/thumbnailOriginal.jpg',
  'Dumbbell Lateral Raise':
      'https://cdn.motra.com/exercise-assets/b3df8c4d1e/thumbnailOriginal.jpg',
  'Tricep Pushdown':
      'https://cdn.motra.com/exercise-assets/da88910ead/thumbnailOriginal.jpg',
  'Triceps Pushdown':
      'https://cdn.motra.com/exercise-assets/da88910ead/thumbnailOriginal.jpg',
  'Cable Tricep Pushdown':
      'https://cdn.motra.com/exercise-assets/da88910ead/thumbnailOriginal.jpg',
  'Bench Press':
      'https://cdn.motra.com/exercise-assets/62100947ff/thumbnailOriginal.jpg',
  'Barbell Bench Press':
      'https://cdn.motra.com/exercise-assets/62100947ff/thumbnailOriginal.jpg',
  'Flat Bench Press':
      'https://cdn.motra.com/exercise-assets/62100947ff/thumbnailOriginal.jpg',
  'Dumbbell Incline Press':
      'https://cdn.motra.com/exercise-assets/ba9fe08d66/thumbnailOriginal.jpg',
  'Dumbell Incline Press':
      'https://cdn.motra.com/exercise-assets/ba9fe08d66/thumbnailOriginal.jpg',
  'Incline Dumbbell Press':
      'https://cdn.motra.com/exercise-assets/ba9fe08d66/thumbnailOriginal.jpg',
  'Dumbbell Incline':
      'https://cdn.motra.com/exercise-assets/ba9fe08d66/thumbnailOriginal.jpg',
  'Push Up':
      'https://cdn.motra.com/exercise-assets/965e675fe4/thumbnailOriginal.jpg',
  'Push Ups':
      'https://cdn.motra.com/exercise-assets/965e675fe4/thumbnailOriginal.jpg',
  'Pushups':
      'https://cdn.motra.com/exercise-assets/965e675fe4/thumbnailOriginal.jpg',
  'Ab Crunch Machine':
      'https://cdn.motra.com/exercise-assets/910ee6eaa7/thumbnailOriginal.jpg',
  'Ab Crunch':
      'https://cdn.motra.com/exercise-assets/910ee6eaa7/thumbnailOriginal.jpg',
  'Ab Crunches':
      'https://cdn.motra.com/exercise-assets/910ee6eaa7/thumbnailOriginal.jpg',
  'Reverse Crunch':
      'https://cdn.motra.com/exercise-assets/062e65bc5c/thumbnailOriginal.jpg',
  'Cable Woodchop':
      'https://cdn.motra.com/exercise-assets/8ff22c97ee/thumbnailOriginal.jpg',
  'Cable Woodchops':
      'https://cdn.motra.com/exercise-assets/8ff22c97ee/thumbnailOriginal.jpg',
  'Plank':
      'https://cdn.motra.com/exercise-assets/c80bf876dd/thumbnailOriginal.jpg',
  'Forearm Plank':
      'https://cdn.motra.com/exercise-assets/c80bf876dd/thumbnailOriginal.jpg',
  'Incline Walk':
      'https://cdn.motra.com/exercise-assets/fb049be3ff/thumbnailOriginal.jpg',
  'Incline Walking':
      'https://cdn.motra.com/exercise-assets/fb049be3ff/thumbnailOriginal.jpg',
  'Row Erg':
      'https://cdn.motra.com/exercise-assets/89524e7a5f/thumbnailOriginal.jpg',
  'Rowing Erg':
      'https://cdn.motra.com/exercise-assets/89524e7a5f/thumbnailOriginal.jpg',
};

String exerciseDemoImageUrl(String exerciseName) {
  final trimmed = exerciseName.trim();
  return kExerciseDemoImageByName[trimmed] ?? kFallbackExerciseImage;
}

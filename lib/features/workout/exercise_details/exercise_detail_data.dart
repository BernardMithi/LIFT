import 'dart:math' as math;

import 'package:lift/features/workout/exercise_stats/exercise_stats_mock_data.dart';
import 'package:lift/shared/exercise_demo_images.dart';
import 'package:lift/shared/widgets/workout_target_mannequin_panel.dart';

class ExerciseDetailData {
  const ExerciseDetailData({
    required this.exerciseName,
    required this.summary,
    required this.mediaImageUrl,
    required this.exerciseType,
    required this.difficulty,
    required this.equipmentLabel,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.coachingTips,
    required this.targeting,
    required this.relatedExercises,
  });

  final String exerciseName;
  final String summary;
  final String mediaImageUrl;
  final String exerciseType;
  final String difficulty;
  final String equipmentLabel;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final List<String> coachingTips;
  final List<ExerciseTargetingEntry> targeting;
  final List<ExerciseRelatedExercise> relatedExercises;

  List<String> get allMuscles => <String>[
    ...primaryMuscles,
    ...secondaryMuscles,
  ];

  Set<WorkoutTargetRegion> get highlightedRegions =>
      workoutTargetRegionsForLabels(allMuscles);

  Map<WorkoutTargetRegion, WorkoutTargetHighlightState> get regionStates {
    final states = <WorkoutTargetRegion, WorkoutTargetHighlightState>{};
    for (final region in workoutTargetRegionsForLabels(secondaryMuscles)) {
      states[region] = WorkoutTargetHighlightState.mid;
    }
    for (final region in workoutTargetRegionsForLabels(primaryMuscles)) {
      states[region] = WorkoutTargetHighlightState.fatigued;
    }
    return states;
  }
}

class ExerciseTargetingEntry {
  const ExerciseTargetingEntry({
    required this.label,
    required this.scoreOutOfTen,
    required this.details,
  });

  final String label;
  final int scoreOutOfTen;
  final String details;
}

class ExerciseRelatedExercise {
  const ExerciseRelatedExercise({
    required this.name,
    required this.imageUrl,
    required this.loggedSetCount,
    required this.muscleGroups,
    required this.equipmentLabel,
  });

  final String name;
  final String imageUrl;
  final int loggedSetCount;
  final List<String> muscleGroups;
  final String equipmentLabel;
}

enum _ExercisePattern {
  legPress,
  hamstringCurl,
  legExtension,
  squat,
  hinge,
  lunge,
  calfRaise,
  verticalPull,
  horizontalPull,
  facePull,
  chestPress,
  shoulderPress,
  lateralRaise,
  tricepPushdown,
  wristCurl,
  coreCrunch,
  woodchop,
  plank,
  inclineWalk,
  rowErg,
}

class _ExerciseSeed {
  const _ExerciseSeed({
    required this.name,
    required this.aliases,
    required this.pattern,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipmentLabel,
    required this.exerciseType,
    required this.difficulty,
  });

  final String name;
  final List<String> aliases;
  final _ExercisePattern pattern;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipmentLabel;
  final String exerciseType;
  final String difficulty;
}

abstract final class ExerciseDetailMockData {
  static ExerciseDetailData forExercise(String exerciseName) {
    final seed = _findSeed(exerciseName) ?? _fallbackSeed(exerciseName);
    final displayName = exerciseName.trim().isEmpty ? seed.name : exerciseName;
    final summary = _buildSummary(seed);

    return ExerciseDetailData(
      exerciseName: displayName,
      summary: summary,
      mediaImageUrl: exerciseDemoImageUrl(displayName),
      exerciseType: seed.exerciseType,
      difficulty: seed.difficulty,
      equipmentLabel: seed.equipmentLabel,
      primaryMuscles: List<String>.unmodifiable(seed.primaryMuscles),
      secondaryMuscles: List<String>.unmodifiable(seed.secondaryMuscles),
      instructions: List<String>.unmodifiable(_instructionsFor(seed.pattern)),
      coachingTips: List<String>.unmodifiable(_tipsFor(seed.pattern)),
      targeting: List<ExerciseTargetingEntry>.unmodifiable(
        _buildTargeting(seed),
      ),
      relatedExercises: List<ExerciseRelatedExercise>.unmodifiable(
        _buildRelatedExercises(seed),
      ),
    );
  }

  static _ExerciseSeed? _findSeed(String exerciseName) {
    final normalized = _normalize(exerciseName);
    for (final seed in _kExerciseSeeds) {
      if (_normalize(seed.name) == normalized) return seed;
      for (final alias in seed.aliases) {
        if (_normalize(alias) == normalized) return seed;
      }
    }
    return null;
  }

  static _ExerciseSeed _fallbackSeed(String exerciseName) {
    final normalized = exerciseName.toLowerCase();
    final equipmentLabel = _inferEquipmentLabel(normalized);
    final primaryMuscles = _inferPrimaryMuscles(normalized);
    final secondaryMuscles = _inferSecondaryMuscles(normalized, primaryMuscles);

    return _ExerciseSeed(
      name: exerciseName.trim().isEmpty ? 'Exercise details' : exerciseName,
      aliases: const <String>[],
      pattern: _inferPattern(normalized),
      primaryMuscles: primaryMuscles,
      secondaryMuscles: secondaryMuscles,
      equipmentLabel: equipmentLabel,
      exerciseType: _inferExerciseType(normalized, primaryMuscles),
      difficulty: _inferDifficulty(normalized, equipmentLabel),
    );
  }

  static String _buildSummary(_ExerciseSeed seed) {
    final primary = _joined(seed.primaryMuscles);
    final secondary =
        seed.secondaryMuscles.isEmpty
            ? ''
            : ' with ${_joined(seed.secondaryMuscles)} support';
    return '${seed.exerciseType} ${seed.equipmentLabel.toLowerCase()} movement focused on $primary$secondary.';
  }

  static List<ExerciseTargetingEntry> _buildTargeting(_ExerciseSeed seed) {
    final entries = <ExerciseTargetingEntry>[];
    for (var index = 0; index < seed.primaryMuscles.length; index += 1) {
      final muscle = seed.primaryMuscles[index];
      entries.add(
        ExerciseTargetingEntry(
          label: muscle,
          scoreOutOfTen: math.max(8, 10 - index),
          details: _muscleDetails(muscle),
        ),
      );
    }
    for (var index = 0; index < seed.secondaryMuscles.length; index += 1) {
      final muscle = seed.secondaryMuscles[index];
      entries.add(
        ExerciseTargetingEntry(
          label: muscle,
          scoreOutOfTen: math.max(5, 7 - index),
          details: _muscleDetails(muscle),
        ),
      );
    }
    return entries.take(4).toList(growable: false);
  }

  static List<ExerciseRelatedExercise> _buildRelatedExercises(
    _ExerciseSeed seed,
  ) {
    final scored = <MapEntry<_ExerciseSeed, int>>[];
    for (final candidate in _kExerciseSeeds) {
      if (_normalize(candidate.name) == _normalize(seed.name)) continue;
      final sharedPrimary =
          candidate.primaryMuscles.where(seed.primaryMuscles.contains).length;
      final sharedSecondary =
          candidate.secondaryMuscles
              .where(
                (muscle) =>
                    seed.primaryMuscles.contains(muscle) ||
                    seed.secondaryMuscles.contains(muscle),
              )
              .length;
      var score = (sharedPrimary * 5) + (sharedSecondary * 2);
      if (candidate.equipmentLabel == seed.equipmentLabel) score += 3;
      if (candidate.pattern == seed.pattern) score += 2;
      if (score > 0) {
        scored.add(MapEntry(candidate, score));
      }
    }

    scored.sort((a, b) {
      final scoreCompare = b.value.compareTo(a.value);
      if (scoreCompare != 0) return scoreCompare;
      return a.key.name.compareTo(b.key.name);
    });

    return scored
        .take(4)
        .map((entry) {
          final name = entry.key.name;
          final hash = name.hashCode.abs();
          final loggedSetCount =
              hash % 9 == 0 ? 0 : 40 + (hash % 320) + (entry.value * 3);
          final statsSummary = ExerciseStatsMockData.forExercise(name).summary;
          return ExerciseRelatedExercise(
            name: name,
            imageUrl: exerciseDemoImageUrl(name),
            loggedSetCount: math.max(
              loggedSetCount,
              statsSummary.sessionsWithExercise * 12,
            ),
            muscleGroups: entry.key.primaryMuscles,
            equipmentLabel: entry.key.equipmentLabel,
          );
        })
        .toList(growable: false);
  }

  static List<String> _instructionsFor(_ExercisePattern pattern) {
    switch (pattern) {
      case _ExercisePattern.legPress:
        return const [
          'Set the seat so knees start bent without the lower back lifting off the pad.',
          'Plant feet mid-platform, brace the trunk, and unlock the sled under control.',
          'Lower until thighs reach a strong range without the hips tucking underneath.',
          'Drive through the full foot to press the platform away while knees track over toes.',
          'Stop just short of a hard lockout, then repeat with the same tempo.',
        ];
      case _ExercisePattern.hamstringCurl:
        return const [
          'Align the machine pivot with the knee joint and lock the hips into the pad.',
          'Set the ankle pad just above the heels and brace before each rep.',
          'Curl the pad by pulling the heels toward the glutes without lifting the hips.',
          'Pause briefly in the shortened position to fully contract the hamstrings.',
          'Lower slowly until the knees are nearly straight and repeat.',
        ];
      case _ExercisePattern.legExtension:
        return const [
          'Set the back pad so the knees line up with the machine pivot.',
          'Place the shin pad just above the ankles and keep the hips pinned down.',
          'Extend the knees smoothly until the quads are fully shortened.',
          'Avoid snapping into lockout and hold tension for a short pause.',
          'Lower under control until the weight stack almost settles before the next rep.',
        ];
      case _ExercisePattern.squat:
        return const [
          'Unrack with the feet set under the hips and the ribs stacked over the pelvis.',
          'Breathe in, brace hard, and sit down between the feet while keeping the chest organised.',
          'Let the knees travel naturally while keeping pressure through the mid-foot.',
          'Drive up by pushing the floor away and keeping the bar path over the centre of the foot.',
          'Stand tall under control before resetting the breath for the next rep.',
        ];
      case _ExercisePattern.hinge:
        return const [
          'Stand tall with the implement close to the body and soften the knees slightly.',
          'Push the hips back to lengthen the hamstrings while keeping the spine neutral.',
          'Lower only as far as the hips can keep moving back without the shoulders rounding.',
          'Drive the feet into the floor and extend the hips to return to standing.',
          'Finish tall with glutes engaged, then start the next rep from a stable hinge.',
        ];
      case _ExercisePattern.lunge:
        return const [
          'Stand upright with the load balanced and feet set hip-width apart.',
          'Step into the lunge and lower by bending both knees under control.',
          'Keep the torso stacked over the hips and the front foot planted through the floor.',
          'Drive through the front leg to stand back up without wobbling side to side.',
          'Reset your balance before moving into the next rep.',
        ];
      case _ExercisePattern.calfRaise:
        return const [
          'Set the shoulders or pad position so the ankles can move through a full range.',
          'Start from a deep stretch with the heels dropped under control.',
          'Press through the big toe and ball of the foot to rise as high as possible.',
          'Pause at the top to fully shorten the calves.',
          'Lower slowly back into the stretch and repeat without bouncing.',
        ];
      case _ExercisePattern.verticalPull:
        return const [
          'Set the seat and thigh support so the torso stays anchored.',
          'Reach tall to create length through the lats before beginning the pull.',
          'Drive the elbows down toward the ribs while keeping the chest lifted.',
          'Pause when the handle reaches the upper chest or collarbone line.',
          'Return overhead with control without losing tension through the trunk.',
        ];
      case _ExercisePattern.horizontalPull:
        return const [
          'Set the chest or torso support so the shoulders can move freely.',
          'Reach forward to protract the shoulder blades at the start.',
          'Pull the elbows back by driving through the upper back, not by shrugging.',
          'Finish with the handle close to the torso and the shoulders down.',
          'Control the reach forward and keep the ribcage stacked throughout.',
        ];
      case _ExercisePattern.facePull:
        return const [
          'Set the cable around face height and step back until the line of pull is clean.',
          'Start with arms extended and shoulders relaxed away from the ears.',
          'Pull the rope toward the face while spreading the hands apart.',
          'Finish with elbows high enough to bias the rear delts and upper back.',
          'Return slowly without letting the torso rock backward.',
        ];
      case _ExercisePattern.chestPress:
        return const [
          'Set the seat so the handles line up with the mid-chest.',
          'Pull the shoulders down and back into the pad before pressing.',
          'Press in a smooth arc without flaring the elbows excessively.',
          'Stop short of losing shoulder position at lockout.',
          'Lower until the chest and front delts feel loaded, then repeat.',
        ];
      case _ExercisePattern.shoulderPress:
        return const [
          'Set the seat so the handles start around chin to ear height.',
          'Brace the trunk and keep the ribs from lifting as the press begins.',
          'Drive the handles overhead in a straight, controlled path.',
          'Finish with the shoulders active but not shrugged into the ears.',
          'Lower back to the start without collapsing into the bottom position.',
        ];
      case _ExercisePattern.lateralRaise:
        return const [
          'Start with a soft bend in the elbows and the weights by the sides.',
          'Raise the arms out and slightly forward until the delts are fully loaded.',
          'Keep the neck relaxed and avoid shrugging during the lift.',
          'Pause briefly near shoulder height to keep tension on the side delts.',
          'Lower under control and reset before the next rep.',
        ];
      case _ExercisePattern.tricepPushdown:
        return const [
          'Set the cable so the elbows can stay pinned close to the torso.',
          'Brace the trunk and keep the shoulders down before each press.',
          'Extend the elbows by pushing the handle down without swinging the torso.',
          'Squeeze the triceps at full extension for a short pause.',
          'Return slowly until the elbows bend enough to reload the movement.',
        ];
      case _ExercisePattern.wristCurl:
        return const [
          'Support the forearms so the wrists can move freely through the range.',
          'Start from a controlled stretch with the wrists extended.',
          'Curl through the wrists without turning the movement into an elbow flexion.',
          'Pause in the shortened position to fully engage the forearm flexors.',
          'Lower slowly back into the stretch and repeat.',
        ];
      case _ExercisePattern.coreCrunch:
        return const [
          'Set the machine or bench so the torso can flex through the midline.',
          'Brace lightly, then curl the ribs toward the pelvis rather than pulling with the arms.',
          'Exhale as the abs shorten and keep the hips stable.',
          'Pause briefly at peak contraction without yanking through the neck.',
          'Unroll slowly until the abs are lengthened again.',
        ];
      case _ExercisePattern.woodchop:
        return const [
          'Set the cable height and stance so the hips can rotate cleanly.',
          'Brace before moving and keep the shoulders packed.',
          'Rotate through the torso and hips as the handle travels across the body.',
          'Finish balanced with the ribs stacked and glutes engaged.',
          'Return under control instead of letting the cable pull you back.',
        ];
      case _ExercisePattern.plank:
        return const [
          'Set the elbows under the shoulders and create a long line from head to heel.',
          'Tuck the pelvis slightly and brace the abs as if preparing for a punch.',
          'Push the floor away to keep the upper back active.',
          'Breathe behind the brace without letting the hips sag or pike.',
          'Finish the set before tension quality drops.',
        ];
      case _ExercisePattern.inclineWalk:
        return const [
          'Set the incline and speed so the posture stays tall and controlled.',
          'Keep the ribcage stacked over the pelvis while the feet strike under the body.',
          'Drive through the whole foot to keep the glutes and calves active.',
          'Use a natural arm swing instead of leaning heavily onto the rails.',
          'Maintain a pace you can sustain with clean breathing mechanics.',
        ];
      case _ExercisePattern.rowErg:
        return const [
          'Start tall at the catch with the shins near vertical and the trunk braced.',
          'Drive through the legs first, then open the hips and finish with the arms.',
          'Keep the handle path smooth and close to the body.',
          'Reverse the recovery by extending the arms before the knees bend.',
          'Hold a repeatable rhythm instead of sprinting the early strokes.',
        ];
    }
  }

  static List<String> _tipsFor(_ExercisePattern pattern) {
    switch (pattern) {
      case _ExercisePattern.legPress:
        return const [
          'Keep the lower back glued to the pad.',
          'Push evenly through the full foot.',
          'Do not let the knees cave inward.',
        ];
      case _ExercisePattern.hamstringCurl:
        return const [
          'Lead with the heels, not the toes.',
          'Keep the hips heavy on the pad.',
          'Control the lowering phase.',
        ];
      case _ExercisePattern.legExtension:
        return const [
          'Move smoothly into the top, not explosively.',
          'Keep the hips locked into the seat.',
          'Use the squeeze, not momentum, to finish each rep.',
        ];
      case _ExercisePattern.squat:
        return const [
          'Brace before every descent.',
          'Keep pressure through the mid-foot.',
          'Stand up by driving the floor away.',
        ];
      case _ExercisePattern.hinge:
        return const [
          'Think hips back, not chest down.',
          'Keep the implement close to the body.',
          'Stop where hamstring tension peaks without rounding.',
        ];
      case _ExercisePattern.lunge:
        return const [
          'Stay balanced between both feet.',
          'Keep the front foot planted flat.',
          'Own the bottom before driving up.',
        ];
      case _ExercisePattern.calfRaise:
        return const [
          'Use a full stretch at the bottom.',
          'Pause at peak plantar flexion.',
          'Avoid bouncing through the ankles.',
        ];
      case _ExercisePattern.verticalPull:
        return const [
          'Pull elbows into the ribs.',
          'Keep the chest proud without over-arching.',
          'Let the lats lengthen on the way up.',
        ];
      case _ExercisePattern.horizontalPull:
        return const [
          'Reach forward to reset each rep.',
          'Finish with the shoulders down.',
          'Avoid jerking the torso backward.',
        ];
      case _ExercisePattern.facePull:
        return const [
          'Spread the rope apart at the finish.',
          'Lead with elbows, not wrists.',
          'Keep neck tension out of the movement.',
        ];
      case _ExercisePattern.chestPress:
        return const [
          'Set the shoulder blades first.',
          'Press without shrugging.',
          'Control the final third of the lowering phase.',
        ];
      case _ExercisePattern.shoulderPress:
        return const [
          'Brace hard so the ribs stay down.',
          'Press up and slightly back.',
          'Do not dump into the bottom position.',
        ];
      case _ExercisePattern.lateralRaise:
        return const [
          'Lead with the elbows.',
          'Keep traps quiet.',
          'Stop where the side delts stay loaded.',
        ];
      case _ExercisePattern.tricepPushdown:
        return const [
          'Keep elbows pinned.',
          'Finish with the triceps, not the shoulders.',
          'Do not sway the torso for momentum.',
        ];
      case _ExercisePattern.wristCurl:
        return const [
          'Move only through the wrists.',
          'Stay controlled in the stretched position.',
          'Use smaller jumps in load than you think.',
        ];
      case _ExercisePattern.coreCrunch:
        return const [
          'Curl the torso instead of yanking with the arms.',
          'Exhale into the contraction.',
          'Keep tension through the whole range.',
        ];
      case _ExercisePattern.woodchop:
        return const [
          'Rotate through hips and ribs together.',
          'Stay tall as the handle travels.',
          'Resist the cable on the way back.',
        ];
      case _ExercisePattern.plank:
        return const [
          'Squeeze glutes and abs together.',
          'Push the floor away.',
          'Stop before the lower back takes over.',
        ];
      case _ExercisePattern.inclineWalk:
        return const [
          'Use the rails lightly or not at all.',
          'Stay tall through the ribcage.',
          'Keep the stride clean and repeatable.',
        ];
      case _ExercisePattern.rowErg:
        return const [
          'Legs, hips, then arms on the drive.',
          'Arms, hips, then legs on the recovery.',
          'Keep stroke rate matched to the target effort.',
        ];
    }
  }

  static String _muscleDetails(String muscle) {
    switch (muscle) {
      case 'Quads':
        return 'Rectus Femoris, Vastus Lateralis, Vastus Medialis';
      case 'Glutes':
        return 'Glute Max, Glute Med';
      case 'Hamstrings':
        return 'Biceps Femoris, Semitendinosus';
      case 'Calves':
        return 'Gastrocnemius, Soleus';
      case 'Back':
        return 'Mid Traps, Rhomboids, Erectors';
      case 'Lats':
        return 'Latissimus Dorsi, Teres Major';
      case 'Chest':
        return 'Pectoralis Major, Pectoralis Minor';
      case 'Shoulders':
        return 'Anterior, Lateral, Rear Deltoid';
      case 'Biceps':
        return 'Biceps Brachii, Brachialis';
      case 'Triceps':
        return 'Long, Lateral, Medial Head';
      case 'Forearms':
        return 'Wrist Flexors, Wrist Extensors';
      case 'Core':
        return 'Rectus Abdominis, Obliques';
      case 'Adductors':
        return 'Adductor Magnus, Longus';
      case 'Conditioning':
        return 'Cardiorespiratory demand, calves, trunk';
      default:
        return '$muscle emphasis';
    }
  }

  static List<String> _inferPrimaryMuscles(String normalized) {
    final muscles = <String>[];
    if (normalized.contains('leg press') ||
        normalized.contains('squat') ||
        normalized.contains('leg extension') ||
        normalized.contains('lunge')) {
      muscles.add('Quads');
    }
    if (normalized.contains('ham') ||
        normalized.contains('deadlift') ||
        normalized.contains('hinge')) {
      muscles.add('Hamstrings');
    }
    if (normalized.contains('glute') ||
        normalized.contains('leg press') ||
        normalized.contains('hip')) {
      muscles.add('Glutes');
    }
    if (normalized.contains('lat') ||
        normalized.contains('row') ||
        normalized.contains('pull')) {
      muscles.add('Back');
    }
    if (normalized.contains('press') && !normalized.contains('leg')) {
      muscles.add('Chest');
    }
    if (normalized.contains('shoulder') || normalized.contains('lateral')) {
      muscles.add('Shoulders');
    }
    if (normalized.contains('tricep') || normalized.contains('pushdown')) {
      muscles.add('Triceps');
    }
    if ((normalized.contains('curl') && !normalized.contains('ham')) ||
        normalized.contains('bicep')) {
      muscles.add('Biceps');
    }
    if (normalized.contains('wrist') || normalized.contains('forearm')) {
      muscles.add('Forearms');
    }
    if (normalized.contains('ab') ||
        normalized.contains('core') ||
        normalized.contains('plank')) {
      muscles.add('Core');
    }
    if (normalized.contains('walk') ||
        normalized.contains('cardio') ||
        normalized.contains('erg')) {
      muscles.add('Conditioning');
    }
    if (normalized.contains('calf')) muscles.add('Calves');
    if (muscles.isEmpty) muscles.add('Core');
    return muscles.take(2).toList(growable: false);
  }

  static List<String> _inferSecondaryMuscles(
    String normalized,
    List<String> primary,
  ) {
    final muscles = <String>[];
    if (normalized.contains('leg press')) {
      muscles.addAll(['Adductors', 'Hamstrings']);
    }
    if (normalized.contains('press') && !normalized.contains('leg')) {
      muscles.addAll(['Shoulders', 'Triceps']);
    }
    if (normalized.contains('row') || normalized.contains('pull')) {
      muscles.addAll(['Biceps', 'Forearms']);
    }
    if (normalized.contains('squat') || normalized.contains('lunge')) {
      muscles.addAll(['Glutes', 'Hamstrings']);
    }
    if (normalized.contains('walk') || normalized.contains('erg')) {
      muscles.addAll(['Calves', 'Core']);
    }
    return muscles
        .where((muscle) => !primary.contains(muscle))
        .take(3)
        .toList(growable: false);
  }

  static _ExercisePattern _inferPattern(String normalized) {
    if (normalized.contains('leg press')) return _ExercisePattern.legPress;
    if (normalized.contains('ham')) return _ExercisePattern.hamstringCurl;
    if (normalized.contains('leg extension')) {
      return _ExercisePattern.legExtension;
    }
    if (normalized.contains('squat')) return _ExercisePattern.squat;
    if (normalized.contains('deadlift')) return _ExercisePattern.hinge;
    if (normalized.contains('lunge')) return _ExercisePattern.lunge;
    if (normalized.contains('calf')) return _ExercisePattern.calfRaise;
    if (normalized.contains('lat')) return _ExercisePattern.verticalPull;
    if (normalized.contains('face pull')) return _ExercisePattern.facePull;
    if (normalized.contains('row')) return _ExercisePattern.horizontalPull;
    if (normalized.contains('lateral')) return _ExercisePattern.lateralRaise;
    if (normalized.contains('tricep') || normalized.contains('pushdown')) {
      return _ExercisePattern.tricepPushdown;
    }
    if (normalized.contains('wrist')) return _ExercisePattern.wristCurl;
    if (normalized.contains('woodchop')) return _ExercisePattern.woodchop;
    if (normalized.contains('plank')) return _ExercisePattern.plank;
    if (normalized.contains('walk')) return _ExercisePattern.inclineWalk;
    if (normalized.contains('erg')) return _ExercisePattern.rowErg;
    if (normalized.contains('shoulder')) return _ExercisePattern.shoulderPress;
    if (normalized.contains('ab') || normalized.contains('core')) {
      return _ExercisePattern.coreCrunch;
    }
    if (normalized.contains('press') || normalized.contains('push')) {
      return _ExercisePattern.chestPress;
    }
    return _ExercisePattern.chestPress;
  }

  static String _inferEquipmentLabel(String normalized) {
    if (normalized.contains('barbell')) return 'Barbell';
    if (normalized.contains('dumbbell')) return 'Dumbbell';
    if (normalized.contains('cable')) return 'Cables';
    if (normalized.contains('machine') ||
        normalized.contains('press') ||
        normalized.contains('extension') ||
        normalized.contains('curl') ||
        normalized.contains('row erg') ||
        normalized.contains('walk')) {
      return 'Machines';
    }
    if (normalized.contains('push up') ||
        normalized.contains('pull up') ||
        normalized.contains('plank')) {
      return 'Bodyweight';
    }
    return 'Manual';
  }

  static String _inferExerciseType(String normalized, List<String> primary) {
    if (normalized.contains('walk') || normalized.contains('erg')) {
      return 'Conditioning';
    }
    if (primary.length >= 2 ||
        normalized.contains('press') ||
        normalized.contains('row') ||
        normalized.contains('squat')) {
      return 'Compound';
    }
    return 'Isolation';
  }

  static String _inferDifficulty(String normalized, String equipmentLabel) {
    if (normalized.contains('squat') ||
        normalized.contains('deadlift') ||
        normalized.contains('woodchop')) {
      return 'Intermediate';
    }
    if (equipmentLabel == 'Bodyweight' &&
        (normalized.contains('pull up') || normalized.contains('plank'))) {
      return 'Intermediate';
    }
    return 'Beginner';
  }

  static String _normalize(String value) =>
      value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');

  static String _joined(List<String> values) {
    if (values.isEmpty) return 'full-body training';
    if (values.length == 1) return values.first.toLowerCase();
    if (values.length == 2) {
      return '${values.first.toLowerCase()} and ${values.last.toLowerCase()}';
    }
    final rest = values.take(values.length - 1).map((e) => e.toLowerCase());
    return '${rest.join(', ')}, and ${values.last.toLowerCase()}';
  }
}

const List<_ExerciseSeed> _kExerciseSeeds = [
  _ExerciseSeed(
    name: 'Leg Press',
    aliases: ['Machine Leg Press'],
    pattern: _ExercisePattern.legPress,
    primaryMuscles: ['Quads', 'Glutes'],
    secondaryMuscles: ['Adductors', 'Hamstrings', 'Calves'],
    equipmentLabel: 'Machines',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Hamstring Curls',
    aliases: ['Lying Hamstring Curl', 'Seated Hamstring Curl'],
    pattern: _ExercisePattern.hamstringCurl,
    primaryMuscles: ['Hamstrings'],
    secondaryMuscles: ['Calves', 'Glutes'],
    equipmentLabel: 'Machines',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Leg Extension',
    aliases: ['Seated Leg Extension'],
    pattern: _ExercisePattern.legExtension,
    primaryMuscles: ['Quads'],
    secondaryMuscles: ['Hip Flexors'],
    equipmentLabel: 'Machines',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Barbell Back Squat',
    aliases: ['Back Squat', 'Barbell Squat'],
    pattern: _ExercisePattern.squat,
    primaryMuscles: ['Quads', 'Glutes'],
    secondaryMuscles: ['Hamstrings', 'Core', 'Calves'],
    equipmentLabel: 'Barbell',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Romanian Deadlift',
    aliases: ['RDL'],
    pattern: _ExercisePattern.hinge,
    primaryMuscles: ['Hamstrings', 'Glutes'],
    secondaryMuscles: ['Back', 'Forearms'],
    equipmentLabel: 'Barbell',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Dumbbell Lunges',
    aliases: ['Dumbbell Lunge'],
    pattern: _ExercisePattern.lunge,
    primaryMuscles: ['Quads', 'Glutes'],
    secondaryMuscles: ['Hamstrings', 'Calves', 'Core'],
    equipmentLabel: 'Dumbbell',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Standing Calf Raise',
    aliases: ['Standing Calf Raises'],
    pattern: _ExercisePattern.calfRaise,
    primaryMuscles: ['Calves'],
    secondaryMuscles: ['Glutes'],
    equipmentLabel: 'Machines',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Lat Pulldown',
    aliases: ['Lat Pull Down'],
    pattern: _ExercisePattern.verticalPull,
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Forearms', 'Shoulders'],
    equipmentLabel: 'Cables',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Seated Row',
    aliases: ['Seated Cable Row'],
    pattern: _ExercisePattern.horizontalPull,
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Forearms', 'Shoulders'],
    equipmentLabel: 'Cables',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Cable Face Pull',
    aliases: ['Face Pull', 'Cable Facepull'],
    pattern: _ExercisePattern.facePull,
    primaryMuscles: ['Shoulders', 'Back'],
    secondaryMuscles: ['Biceps', 'Forearms'],
    equipmentLabel: 'Cables',
    exerciseType: 'Accessory',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Pull Up',
    aliases: ['Pullups', 'Pull-ups'],
    pattern: _ExercisePattern.verticalPull,
    primaryMuscles: ['Back'],
    secondaryMuscles: ['Biceps', 'Forearms', 'Core'],
    equipmentLabel: 'Bodyweight',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Wrist Curl',
    aliases: ['Cable Wrist Curl'],
    pattern: _ExercisePattern.wristCurl,
    primaryMuscles: ['Forearms'],
    secondaryMuscles: ['Biceps'],
    equipmentLabel: 'Dumbbell',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Chest Press',
    aliases: ['Machine Chest Press'],
    pattern: _ExercisePattern.chestPress,
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Shoulders', 'Triceps'],
    equipmentLabel: 'Machines',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Shoulder Press',
    aliases: ['Machine Shoulder Press', 'Overhead Press'],
    pattern: _ExercisePattern.shoulderPress,
    primaryMuscles: ['Shoulders'],
    secondaryMuscles: ['Triceps', 'Upper Back'],
    equipmentLabel: 'Machines',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Lateral Raise',
    aliases: ['Lateral Raises', 'Dumbbell Lateral Raise'],
    pattern: _ExercisePattern.lateralRaise,
    primaryMuscles: ['Shoulders'],
    secondaryMuscles: ['Upper Back'],
    equipmentLabel: 'Dumbbell',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Tricep Pushdown',
    aliases: ['Triceps Pushdown', 'Cable Tricep Pushdown'],
    pattern: _ExercisePattern.tricepPushdown,
    primaryMuscles: ['Triceps'],
    secondaryMuscles: ['Shoulders'],
    equipmentLabel: 'Cables',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Bench Press',
    aliases: ['Barbell Bench Press', 'Flat Bench Press'],
    pattern: _ExercisePattern.chestPress,
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Shoulders', 'Triceps'],
    equipmentLabel: 'Barbell',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Dumbbell Incline Press',
    aliases: ['Dumbell Incline Press', 'Incline Dumbbell Press'],
    pattern: _ExercisePattern.chestPress,
    primaryMuscles: ['Chest', 'Shoulders'],
    secondaryMuscles: ['Triceps'],
    equipmentLabel: 'Dumbbell',
    exerciseType: 'Compound',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Push Up',
    aliases: ['Pushups', 'Push Ups'],
    pattern: _ExercisePattern.chestPress,
    primaryMuscles: ['Chest'],
    secondaryMuscles: ['Shoulders', 'Triceps', 'Core'],
    equipmentLabel: 'Bodyweight',
    exerciseType: 'Compound',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Ab Crunch Machine',
    aliases: ['Ab Crunch'],
    pattern: _ExercisePattern.coreCrunch,
    primaryMuscles: ['Core'],
    secondaryMuscles: ['Hip Flexors'],
    equipmentLabel: 'Machines',
    exerciseType: 'Isolation',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Cable Woodchop',
    aliases: ['Cable Woodchops'],
    pattern: _ExercisePattern.woodchop,
    primaryMuscles: ['Core'],
    secondaryMuscles: ['Shoulders', 'Glutes'],
    equipmentLabel: 'Cables',
    exerciseType: 'Rotational',
    difficulty: 'Intermediate',
  ),
  _ExerciseSeed(
    name: 'Plank',
    aliases: ['Forearm Plank'],
    pattern: _ExercisePattern.plank,
    primaryMuscles: ['Core'],
    secondaryMuscles: ['Shoulders', 'Glutes'],
    equipmentLabel: 'Bodyweight',
    exerciseType: 'Isometric',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Incline Walk',
    aliases: ['Incline Walking'],
    pattern: _ExercisePattern.inclineWalk,
    primaryMuscles: ['Conditioning'],
    secondaryMuscles: ['Calves', 'Glutes', 'Core'],
    equipmentLabel: 'Machines',
    exerciseType: 'Conditioning',
    difficulty: 'Beginner',
  ),
  _ExerciseSeed(
    name: 'Row Erg',
    aliases: ['Rowing Erg'],
    pattern: _ExercisePattern.rowErg,
    primaryMuscles: ['Conditioning', 'Back'],
    secondaryMuscles: ['Legs', 'Core'],
    equipmentLabel: 'Machines',
    exerciseType: 'Conditioning',
    difficulty: 'Beginner',
  ),
];

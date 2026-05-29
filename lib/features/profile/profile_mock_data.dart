import 'package:lift/features/profile/profile_models.dart';

abstract final class ProfileMockData {
  static ProfileViewData ownProfile() {
    final now = DateTime.now();
    return ProfileViewData(
      user: UserProfile(
        id: 'maya-okafor',
        name: 'Maya Okafor',
        username: '@maya.strength',
        mode: ProfileMode.gym,
        gymName: 'Foundry Barbell Club',
        gymDescription:
            'Performance-first gym with recovery pods, plate-loaded strength machines, and coached open sessions.',
        plan: 'Included in membership',
        stats: const UserProfileStats(workouts: 148, streak: 19, score: 84),
        headline:
            'Lower-body focused hypertrophy block with a strong consistency pattern this month.',
      ),
      trainingScore: const TrainingScore(
        value: 84,
        label: 'Prime',
        consistency: 92,
        balance: 'Pull slightly low',
        recovery: 'Fresh',
        insight:
            'Strong consistency this week. Pull movements are slightly undertrained versus your lower-body volume.',
      ),
      recentWorkouts: <WorkoutSummary>[
        WorkoutSummary(
          id: 'leg-day-a',
          name: 'Lower Push',
          date: now.subtract(const Duration(days: 1)),
          duration: const Duration(minutes: 74),
          volume: 18420,
          muscles: const <String>['Quads', 'Glutes', 'Calves'],
          personalRecord: 'Hack squat +20kg',
        ),
        WorkoutSummary(
          id: 'upper-pull-a',
          name: 'Upper Pull',
          date: now.subtract(const Duration(days: 3)),
          duration: const Duration(minutes: 63),
          volume: 13260,
          muscles: const <String>['Lats', 'Upper Back', 'Biceps'],
        ),
        WorkoutSummary(
          id: 'posterior-a',
          name: 'Posterior Chain',
          date: now.subtract(const Duration(days: 5)),
          duration: const Duration(minutes: 69),
          volume: 17180,
          muscles: const <String>['Hamstrings', 'Glutes', 'Lower Back'],
        ),
        WorkoutSummary(
          id: 'upper-push-a',
          name: 'Upper Push',
          date: now.subtract(const Duration(days: 7)),
          duration: const Duration(minutes: 58),
          volume: 11940,
          muscles: const <String>['Chest', 'Shoulders', 'Triceps'],
          personalRecord: 'Incline press 40kg x 10',
        ),
      ],
      analytics: const ProfileAnalytics(
        volumeTrend: <TrendPoint>[
          TrendPoint(label: 'W1', value: 42),
          TrendPoint(label: 'W2', value: 46),
          TrendPoint(label: 'W3', value: 44),
          TrendPoint(label: 'W4', value: 51),
          TrendPoint(label: 'W5', value: 55),
          TrendPoint(label: 'W6', value: 53),
          TrendPoint(label: 'W7', value: 59),
          TrendPoint(label: 'W8', value: 62),
        ],
        strengthProgression: <StrengthLiftSnapshot>[
          StrengthLiftSnapshot(lift: 'Hack Squat', current: 220, previous: 200),
          StrengthLiftSnapshot(
            lift: 'Romanian DL',
            current: 120,
            previous: 112.5,
          ),
          StrengthLiftSnapshot(
            lift: 'Incline Press',
            current: 80,
            previous: 75,
          ),
          StrengthLiftSnapshot(lift: 'Pull-Up', current: 25, previous: 20),
        ],
        muscleBalance: <MuscleBalanceDatum>[
          MuscleBalanceDatum(
            label: 'Lower Body',
            share: 0.36,
            status: 'Primary driver',
          ),
          MuscleBalanceDatum(
            label: 'Pull',
            share: 0.22,
            status: 'Slightly behind',
          ),
          MuscleBalanceDatum(label: 'Push', share: 0.20, status: 'On target'),
          MuscleBalanceDatum(
            label: 'Posterior Chain',
            share: 0.16,
            status: 'Stable',
          ),
          MuscleBalanceDatum(label: 'Core', share: 0.06, status: 'Low dose'),
        ],
      ),
      activity: <ActivityEntry>[
        ActivityEntry(
          id: 'activity-1',
          kind: ActivityEntryKind.workout,
          title: 'Completed Lower Push',
          detail: '74 min session • 18.4k kg total volume',
          date: now.subtract(const Duration(hours: 20)),
        ),
        ActivityEntry(
          id: 'activity-2',
          kind: ActivityEntryKind.pr,
          title: 'New PR on Hack Squat',
          detail: '+20kg versus the last strength block',
          date: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        ActivityEntry(
          id: 'activity-3',
          kind: ActivityEntryKind.milestone,
          title: '19-day training streak',
          detail: 'Best streak this quarter',
          date: now.subtract(const Duration(days: 2)),
        ),
        ActivityEntry(
          id: 'activity-4',
          kind: ActivityEntryKind.workout,
          title: 'Completed Upper Pull',
          detail: '63 min session • Lat and upper-back focus',
          date: now.subtract(const Duration(days: 3)),
        ),
      ],
      gym: const GymSummary(
        name: 'Foundry Barbell Club',
        description:
            'Recovery booths, calibrated plates, machine analytics, and coached lifting windows built into membership.',
      ),
      highlights: const <HighlightSummary>[
        HighlightSummary(
          title: 'Longest Streak',
          value: '27 days',
          detail: 'Built during the last hypertrophy block.',
        ),
        HighlightSummary(
          title: 'Best Lift',
          value: '220kg x 6',
          detail: 'Hack squat top set this mesocycle.',
        ),
        HighlightSummary(
          title: 'Volume Milestone',
          value: '1.48M kg',
          detail: 'Total logged training volume to date.',
        ),
      ],
    );
  }

  static ProfileViewData viewedProfile() {
    final now = DateTime.now();
    return ProfileViewData(
      user: UserProfile(
        id: 'dylan-hayes',
        name: 'Dylan Hayes',
        username: '@dylanhayes',
        mode: ProfileMode.independent,
        plan: 'Pro Plan',
        stats: const UserProfileStats(workouts: 96, streak: 11, score: 76),
        headline:
            'Strength-biased independent athlete tracking balanced upper and lower progress.',
      ),
      trainingScore: const TrainingScore(
        value: 76,
        label: 'Balanced',
        consistency: 86,
        balance: 'Well distributed',
        recovery: 'Moderate fatigue',
        insight:
            'Training balance is strong. Recovery is trending slightly down after two high-output sessions.',
      ),
      recentWorkouts: <WorkoutSummary>[
        WorkoutSummary(
          id: 'viewed-1',
          name: 'Pull Strength',
          date: now.subtract(const Duration(days: 1)),
          duration: const Duration(minutes: 57),
          volume: 12140,
          muscles: const <String>['Lats', 'Upper Back', 'Biceps'],
        ),
        WorkoutSummary(
          id: 'viewed-2',
          name: 'Lower Strength',
          date: now.subtract(const Duration(days: 4)),
          duration: const Duration(minutes: 71),
          volume: 16480,
          muscles: const <String>['Quads', 'Hamstrings', 'Glutes'],
          personalRecord: 'Front squat +5kg',
        ),
      ],
      analytics: const ProfileAnalytics(
        volumeTrend: <TrendPoint>[
          TrendPoint(label: 'W1', value: 31),
          TrendPoint(label: 'W2', value: 34),
          TrendPoint(label: 'W3', value: 36),
          TrendPoint(label: 'W4', value: 38),
          TrendPoint(label: 'W5', value: 41),
          TrendPoint(label: 'W6', value: 40),
        ],
        strengthProgression: <StrengthLiftSnapshot>[
          StrengthLiftSnapshot(
            lift: 'Front Squat',
            current: 145,
            previous: 140,
          ),
          StrengthLiftSnapshot(
            lift: 'Bench Press',
            current: 105,
            previous: 100,
          ),
          StrengthLiftSnapshot(lift: 'Row', current: 92.5, previous: 87.5),
        ],
        muscleBalance: <MuscleBalanceDatum>[
          MuscleBalanceDatum(label: 'Pull', share: 0.28, status: 'Leading'),
          MuscleBalanceDatum(
            label: 'Lower Body',
            share: 0.27,
            status: 'Strong',
          ),
          MuscleBalanceDatum(label: 'Push', share: 0.24, status: 'Stable'),
          MuscleBalanceDatum(label: 'Core', share: 0.11, status: 'Consistent'),
          MuscleBalanceDatum(
            label: 'Conditioning',
            share: 0.10,
            status: 'Light',
          ),
        ],
      ),
      activity: <ActivityEntry>[
        ActivityEntry(
          id: 'viewed-activity-1',
          kind: ActivityEntryKind.pr,
          title: 'New PR on Front Squat',
          detail: '+5kg from the previous block',
          date: now.subtract(const Duration(days: 4)),
        ),
        ActivityEntry(
          id: 'viewed-activity-2',
          kind: ActivityEntryKind.workout,
          title: 'Completed Pull Strength',
          detail: '57 min session',
          date: now.subtract(const Duration(days: 1)),
        ),
      ],
      highlights: const <HighlightSummary>[
        HighlightSummary(
          title: 'Best Streak',
          value: '18 days',
          detail: 'Most consistent run this year.',
        ),
        HighlightSummary(
          title: 'Top Pull-Up',
          value: '+25kg',
          detail: 'Weighted pull-up single.',
        ),
        HighlightSummary(
          title: 'Sessions Logged',
          value: '96',
          detail: 'Tracked across the current training year.',
        ),
      ],
      isFollowing: true,
    );
  }
}

import 'package:flutter/foundation.dart';

enum ProfileMode { gym, independent }

@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.mode,
    this.gymName,
    this.gymDescription,
    required this.plan,
    required this.stats,
    this.headline,
  });

  final String id;
  final String name;
  final String username;
  final String? avatarUrl;
  final ProfileMode mode;
  final String? gymName;
  final String? gymDescription;
  final String plan;
  final UserProfileStats stats;
  final String? headline;

  UserProfile copyWith({
    String? id,
    String? name,
    String? username,
    String? avatarUrl,
    bool clearAvatarUrl = false,
    ProfileMode? mode,
    String? gymName,
    bool clearGymName = false,
    String? gymDescription,
    bool clearGymDescription = false,
    String? plan,
    UserProfileStats? stats,
    String? headline,
    bool clearHeadline = false,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      mode: mode ?? this.mode,
      gymName: clearGymName ? null : (gymName ?? this.gymName),
      gymDescription:
          clearGymDescription ? null : (gymDescription ?? this.gymDescription),
      plan: plan ?? this.plan,
      stats: stats ?? this.stats,
      headline: clearHeadline ? null : (headline ?? this.headline),
    );
  }
}

@immutable
class UserProfileStats {
  const UserProfileStats({
    required this.workouts,
    required this.streak,
    required this.score,
  });

  final int workouts;
  final int streak;
  final int score;
}

@immutable
class WorkoutSummary {
  const WorkoutSummary({
    required this.id,
    required this.name,
    required this.date,
    required this.duration,
    required this.volume,
    required this.muscles,
    this.personalRecord,
  });

  final String id;
  final String name;
  final DateTime date;
  final Duration duration;
  final int volume;
  final List<String> muscles;
  final String? personalRecord;
}

@immutable
class TrainingScore {
  const TrainingScore({
    required this.value,
    required this.label,
    required this.consistency,
    required this.balance,
    required this.recovery,
    required this.insight,
  });

  final int value;
  final String label;
  final int consistency;
  final String balance;
  final String recovery;
  final String insight;
}

enum ActivityEntryKind { workout, pr, milestone }

@immutable
class ActivityEntry {
  const ActivityEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.date,
  });

  final String id;
  final ActivityEntryKind kind;
  final String title;
  final String detail;
  final DateTime date;
}

@immutable
class GymSummary {
  const GymSummary({
    required this.name,
    required this.description,
    this.logoUrl,
    this.ctaLabel = 'View Gym',
  });

  final String name;
  final String description;
  final String? logoUrl;
  final String ctaLabel;

  GymSummary copyWith({
    String? name,
    String? description,
    String? logoUrl,
    bool clearLogoUrl = false,
    String? ctaLabel,
  }) {
    return GymSummary(
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: clearLogoUrl ? null : (logoUrl ?? this.logoUrl),
      ctaLabel: ctaLabel ?? this.ctaLabel,
    );
  }
}

@immutable
class HighlightSummary {
  const HighlightSummary({
    required this.title,
    required this.value,
    required this.detail,
  });

  final String title;
  final String value;
  final String detail;
}

@immutable
class TrendPoint {
  const TrendPoint({required this.label, required this.value});

  final String label;
  final double value;
}

@immutable
class StrengthLiftSnapshot {
  const StrengthLiftSnapshot({
    required this.lift,
    required this.current,
    required this.previous,
  });

  final String lift;
  final double current;
  final double previous;
}

@immutable
class MuscleBalanceDatum {
  const MuscleBalanceDatum({
    required this.label,
    required this.share,
    required this.status,
  });

  final String label;
  final double share;
  final String status;
}

@immutable
class ProfileAnalytics {
  const ProfileAnalytics({
    required this.volumeTrend,
    required this.strengthProgression,
    required this.muscleBalance,
  });

  final List<TrendPoint> volumeTrend;
  final List<StrengthLiftSnapshot> strengthProgression;
  final List<MuscleBalanceDatum> muscleBalance;
}

@immutable
class ProfileViewData {
  const ProfileViewData({
    required this.user,
    required this.trainingScore,
    required this.recentWorkouts,
    required this.analytics,
    required this.activity,
    required this.highlights,
    this.gym,
    this.isFollowing = false,
  });

  final UserProfile user;
  final TrainingScore trainingScore;
  final List<WorkoutSummary> recentWorkouts;
  final ProfileAnalytics analytics;
  final List<ActivityEntry> activity;
  final List<HighlightSummary> highlights;
  final GymSummary? gym;
  final bool isFollowing;

  ProfileViewData copyWith({
    UserProfile? user,
    TrainingScore? trainingScore,
    List<WorkoutSummary>? recentWorkouts,
    ProfileAnalytics? analytics,
    List<ActivityEntry>? activity,
    List<HighlightSummary>? highlights,
    GymSummary? gym,
    bool clearGym = false,
    bool? isFollowing,
  }) {
    return ProfileViewData(
      user: user ?? this.user,
      trainingScore: trainingScore ?? this.trainingScore,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      analytics: analytics ?? this.analytics,
      activity: activity ?? this.activity,
      highlights: highlights ?? this.highlights,
      gym: clearGym ? null : (gym ?? this.gym),
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

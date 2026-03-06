class HealthConnectionState {
  const HealthConnectionState({
    this.appleHealthConnected = false,
    this.googleFitConnected = false,
    this.appleWatchConnected = false,
  });

  final bool appleHealthConnected;
  final bool googleFitConnected;
  final bool appleWatchConnected;

  bool get anyConnected =>
      appleHealthConnected || googleFitConnected || appleWatchConnected;
}

class HealthRecoverySnapshot {
  const HealthRecoverySnapshot({
    required this.readinessScore,
    this.restingHeartRate,
    this.hrvMs,
    this.sleepMinutes,
    this.sourceLabel = 'Health sync',
  });

  final int readinessScore;
  final int? restingHeartRate;
  final int? hrvMs;
  final int? sleepMinutes;
  final String sourceLabel;
}

abstract class HealthSyncService {
  const HealthSyncService();

  HealthConnectionState connectionState();

  HealthRecoverySnapshot? latestRecoverySnapshot();
}

class MockHealthSyncService extends HealthSyncService {
  const MockHealthSyncService();

  @override
  HealthConnectionState connectionState() {
    return const HealthConnectionState();
  }

  @override
  HealthRecoverySnapshot? latestRecoverySnapshot() {
    return null;
  }
}

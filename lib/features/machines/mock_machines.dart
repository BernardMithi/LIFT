import 'package:lift/shared/models/machine.dart';

class MockMachines {
  static const Machine latPulldown = Machine(
    id: 'machine_lat_pulldown_01',
    machineCode: 'LAT_PULLDOWN_01',
    displayName: 'Lat Pulldown',
    zone: 'Upper Body',
    muscleGroups: ['Back', 'Biceps'],
    imageUrl:
        'https://images.pexels.com/photos/18060190/pexels-photo-18060190.jpeg',
    lastWeightKg: 65,
    lastReps: 12,
    lastUsedLabel: '2 days ago',
    defaultRestSeconds: 90,
  );
}

import 'package:lift/shared/models/machine.dart';

class MockMachines {
  static const Machine swivelHandleRow = Machine(
    id: 'machine_swivel_handle_row_01',
    machineCode: 'SWIVEL_HANDLE_ROW_01',
    brand: 'Primal Performance Series',
    fullName: 'Primal Performance Series Plate Loaded Swivel Handle Row',
    displayName: 'Swivel Handle Row',
    zone: 'Upper Body',
    muscleGroups: ['Back', 'Lats', 'Biceps'],
    imageUrl:
        'https://www.primalstrength.com/cdn/shop/files/multiwayrow.jpg?v=1716206289',
    heroImageUrl:
        'https://www.primalstrength.com/cdn/shop/files/multiwayrow.jpg?v=1716206289',
    supportedExercises: [
      'Seated Row',
      'Single Arm Row',
      'Wide Grip Row',
      'Neutral Grip Row',
    ],
    lastWeightKg: 65,
    lastReps: 12,
    lastUsedLabel: '2 days ago',
    lastExerciseName: 'Seated Row',
    defaultRestSeconds: 90,
  );
}

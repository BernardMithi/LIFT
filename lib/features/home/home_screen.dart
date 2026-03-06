import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/articles/articles_screen.dart';
import 'package:lift/features/machines/machine_screen.dart';
import 'package:lift/features/machines/mock_machines.dart';
import 'package:lift/features/pass/gym_pass_dialog.dart';
import 'package:lift/features/progress/progress_screen.dart';
import 'package:lift/features/settings/settings_screen.dart';
import 'package:lift/features/workout/workout_templates_flow.dart';
import 'package:lift/shared/models/workout_history_entry.dart';
import 'package:lift/shared/widgets/surfaces.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String _workoutHistoryStorageKey = 'lift_workout_history_v1';

  int _selectedIndex = 0;
  int _selectedDay = 0;
  final List<String> _days = const ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final List<WorkoutHistoryEntry> _workoutHistory = <WorkoutHistoryEntry>[];
  bool _hideWorkoutShellNav = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutHistory();
  }

  void _onNavItemTapped(int index) => setState(() => _selectedIndex = index);
  void _onDaySelected(int day) => setState(() => _selectedDay = day);
  bool get _showShellNav => !(_selectedIndex == 2 && _hideWorkoutShellNav);

  void _onWorkoutShellNavVisibilityChanged(bool shouldHide) {
    if (_hideWorkoutShellNav == shouldHide) return;
    setState(() => _hideWorkoutShellNav = shouldHide);
  }

  Future<void> _loadWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_workoutHistoryStorageKey);
      if (raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final restored = <WorkoutHistoryEntry>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final map = item.map((key, value) => MapEntry(key.toString(), value));
        final parsed = _historyEntryFromMap(map);
        if (parsed != null) {
          restored.add(parsed);
        }
      }
      if (!mounted) return;
      setState(() {
        _workoutHistory
          ..clear()
          ..addAll(restored);
      });
    } catch (_) {
      // Keep app usable if persisted history cannot be parsed.
    }
  }

  Future<void> _persistWorkoutHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = jsonEncode(
        _workoutHistory.map(_historyEntryToMap).toList(growable: false),
      );
      await prefs.setString(_workoutHistoryStorageKey, payload);
    } catch (_) {
      // Non-fatal local persistence failure.
    }
  }

  void _onWorkoutCompleted(WorkoutHistoryEntry entry) {
    setState(() {
      _workoutHistory.removeWhere((value) => value.id == entry.id);
      _workoutHistory.add(entry);
      _workoutHistory.sort((a, b) => b.completedAt.compareTo(a.completedAt));
    });
    _persistWorkoutHistory();
  }

  Map<String, dynamic> _historyEntryToMap(WorkoutHistoryEntry entry) {
    return <String, dynamic>{
      'id': entry.id,
      'workoutName': entry.workoutName,
      'startedAt': entry.startedAt.toIso8601String(),
      'completedAt': entry.completedAt.toIso8601String(),
      'durationMs': entry.duration.inMilliseconds,
      'totalVolumeKg': entry.totalVolumeKg,
      'totalReps': entry.totalReps,
      'exercisesCompleted': entry.exercisesCompleted,
      'totalExercises': entry.totalExercises,
      'prsAchieved': entry.prsAchieved,
      'exerciseSummaries': entry.exerciseSummaries
          .map(
            (summary) => <String, dynamic>{
              'exerciseName': summary.exerciseName,
              'setCount': summary.setCount,
              'totalReps': summary.totalReps,
              'totalVolumeKg': summary.totalVolumeKg,
              'maxWeightKg': summary.maxWeightKg,
              'muscleGroups': summary.muscleGroups,
            },
          )
          .toList(growable: false),
      'muscleGroupVolumeKg': entry.muscleGroupVolumeKg,
    };
  }

  WorkoutHistoryEntry? _historyEntryFromMap(Map<String, dynamic> map) {
    try {
      final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
      final completedAt = DateTime.tryParse('${map['completedAt'] ?? ''}');
      if (startedAt == null || completedAt == null) return null;
      final summariesRaw = map['exerciseSummaries'];
      final summaries = <WorkoutHistoryExerciseSummary>[];
      if (summariesRaw is List) {
        for (final item in summariesRaw) {
          if (item is! Map) continue;
          final summaryMap = item.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          final exerciseName = '${summaryMap['exerciseName'] ?? ''}'.trim();
          if (exerciseName.isEmpty) continue;
          summaries.add(
            WorkoutHistoryExerciseSummary(
              exerciseName: exerciseName,
              setCount: (summaryMap['setCount'] as num?)?.toInt() ?? 0,
              totalReps: (summaryMap['totalReps'] as num?)?.toInt() ?? 0,
              totalVolumeKg:
                  (summaryMap['totalVolumeKg'] as num?)?.toDouble() ?? 0,
              maxWeightKg: (summaryMap['maxWeightKg'] as num?)?.toDouble() ?? 0,
              muscleGroups:
                  (summaryMap['muscleGroups'] is List)
                      ? (summaryMap['muscleGroups'] as List)
                          .whereType<String>()
                          .toList(growable: false)
                      : const <String>[],
            ),
          );
        }
      }

      final muscleRaw = map['muscleGroupVolumeKg'];
      final muscleVolume = <String, double>{};
      if (muscleRaw is Map) {
        for (final entry in muscleRaw.entries) {
          final key = entry.key.toString();
          final value = entry.value;
          if (value is num) {
            muscleVolume[key] = value.toDouble();
          }
        }
      }

      final id = '${map['id'] ?? ''}'.trim();
      final workoutName = '${map['workoutName'] ?? ''}'.trim();
      if (id.isEmpty || workoutName.isEmpty) return null;

      return WorkoutHistoryEntry(
        id: id,
        workoutName: workoutName,
        startedAt: startedAt,
        completedAt: completedAt,
        duration: Duration(
          milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0,
        ),
        totalVolumeKg: (map['totalVolumeKg'] as num?)?.toDouble() ?? 0,
        totalReps: (map['totalReps'] as num?)?.toInt() ?? 0,
        exercisesCompleted: (map['exercisesCompleted'] as num?)?.toInt() ?? 0,
        totalExercises: (map['totalExercises'] as num?)?.toInt() ?? 0,
        prsAchieved: (map['prsAchieved'] as num?)?.toInt() ?? 0,
        exerciseSummaries: summaries,
        muscleGroupVolumeKg: muscleVolume,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _showTopLeftActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_2_rounded,
                    color: kAccentColor,
                  ),
                  title: const Text('Open gym pass'),
                  subtitle: const Text('QR + backup entry code'),
                  onTap: () {
                    Navigator.pop(context);
                    showGymPassDialog(this.context);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: kAccentColor,
                  ),
                  title: const Text('Simulate machine scan'),
                  subtitle: const Text('Open Lat Pulldown machine screen'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder:
                            (_) => const MachineScreen(
                              machine: MockMachines.latPulldown,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          IndexedStack(
            index: _selectedIndex,
            children: [
              _buildHomeTab(),
              const ArticlesScreen(extraBottomInset: 84),
              WorkoutTemplatesFlow(
                onWorkoutCompleted: _onWorkoutCompleted,
                onHideShellNavChanged: _onWorkoutShellNavVisibilityChanged,
              ),
              ProgressScreen(history: _workoutHistory, extraBottomInset: 0),
            ],
          ),
          if (_showShellNav)
            Positioned(
              left: 16,
              right: 16,
              bottom: 14,
              child: SafeArea(
                top: false,
                bottom: false,
                child: _FloatingIslandNav(
                  selectedIndex: _selectedIndex,
                  onTap: _onNavItemTapped,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
        child: Column(
          children: [
            _TopControlIsland(
              onLeftTap: _showTopLeftActions,
              onRightTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: double.infinity,
                  child: SectionBoundary(
                    padding: EdgeInsets.zero,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _TodayWorkoutTile(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SectionBoundary(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_days.length, (index) {
                  final selected = _selectedDay == index;
                  return GestureDetector(
                    onTap: () => _onDaySelected(index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? kAccentColor : Colors.grey,
                          width: selected ? 2 : 1,
                        ),
                        color:
                            selected
                                ? kAccentColor.withValues(alpha: 0.10)
                                : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          _days[index],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected ? kAccentColor : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 14),
            SectionBoundary(
              child: const GlassContainer(
                height: 140,
                borderRadius: 16,
                child: Center(
                  child: Text(
                    'Recovery stats',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayWorkoutTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            MockMachines.latPulldown.imageUrl,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kAccentDark, kAccentMid, kAccentLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 24, 12, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.28),
                    Colors.black.withValues(alpha: 0.45),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pull Day',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _WorkoutStatChip(
                        icon: Icons.schedule_rounded,
                        label: '45 min',
                        dark: true,
                      ),
                      SizedBox(width: 8),
                      _WorkoutStatChip(
                        icon: Icons.list_alt_rounded,
                        label: '6 exercises',
                        dark: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutStatChip extends StatelessWidget {
  const _WorkoutStatChip({
    required this.icon,
    required this.label,
    this.dark = false,
  });

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            dark
                ? Colors.black.withValues(alpha: 0.28)
                : Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              dark
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.grey.shade200,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dark ? Colors.white : kAccentColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: dark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopControlIsland extends StatelessWidget {
  const _TopControlIsland({required this.onLeftTap, required this.onRightTap});

  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kAccentDark.withValues(alpha: 0.96),
            kAccentMid.withValues(alpha: 0.94),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onLeftTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsRegular.qrCode,
                  size: 35,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Container(
            width: 52,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          GestureDetector(
            onTap: onRightTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: PhosphorIcon(
                  PhosphorIconsRegular.userCircle,
                  size: 33,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIslandNav extends StatelessWidget {
  const _FloatingIslandNav({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 76,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.97),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  index: 0,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.house,
                  label: 'Home',
                ),
                _NavItem(
                  index: 1,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.newspaper,
                  label: 'Guides',
                ),
                _NavItem(
                  index: 2,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.lightning,
                  label: 'Workouts',
                ),
                _NavItem(
                  index: 3,
                  selectedIndex: selectedIndex,
                  onTap: onTap,
                  icon: PhosphorIconsRegular.chartLine,
                  label: 'Progress',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  final int index;
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final PhosphorIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 25,
              height: 25,
              child: Center(
                child: PhosphorIcon(
                  icon,
                  color: isSelected ? kAccentColor : Colors.black87,
                  size: 23,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? kAccentColor : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: isSelected ? 18 : 6,
              height: 2.5,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? kAccentColor
                        : Colors.black.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

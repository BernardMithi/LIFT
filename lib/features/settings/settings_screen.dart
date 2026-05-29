import 'package:flutter/material.dart';
import 'package:lift/app/app_bootstrap.dart';
import 'package:lift/features/account/account_page.dart';
import 'package:lift/features/profile/profile_page.dart';
import 'package:lift/shared/models/workout_history_entry.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.workoutHistory});

  final List<WorkoutHistoryEntry>? workoutHistory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<WorkoutHistoryEntry>? _workoutHistory;

  @override
  void initState() {
    super.initState();
    _workoutHistory =
        widget.workoutHistory != null
            ? List<WorkoutHistoryEntry>.from(widget.workoutHistory!)
            : null;
    if (_workoutHistory == null) {
      _loadWorkoutHistory();
    }
  }

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workoutHistory != widget.workoutHistory &&
        widget.workoutHistory != null) {
      _workoutHistory = List<WorkoutHistoryEntry>.from(widget.workoutHistory!);
    }
  }

  Future<void> _loadWorkoutHistory() async {
    final storedHistory = await loadStoredWorkoutHistory();
    if (!mounted) return;
    setState(() => _workoutHistory = storedHistory);
  }

  void _handleWorkoutHistoryChanged(List<WorkoutHistoryEntry> history) {
    setState(() => _workoutHistory = List<WorkoutHistoryEntry>.from(history));
  }

  @override
  Widget build(BuildContext context) {
    return ProfilePage(
      showBack: true,
      workoutHistory: _workoutHistory,
      onSettingsTap: (profileData) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder:
                (_) => AccountPage(
                  profileData: profileData,
                  workoutHistory: _workoutHistory,
                  onWorkoutHistoryChanged: _handleWorkoutHistoryChanged,
                  showBack: true,
                  showSettingsAction: false,
                  extraBottomInset: 0,
                ),
          ),
        );
      },
    );
  }
}

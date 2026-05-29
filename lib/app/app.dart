import 'package:flutter/material.dart';
import 'package:lift/app/app_bootstrap.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/home/home_screen.dart';

/// Prevents overscroll into empty areas across the app.
class _ClampingScrollBehavior extends ScrollBehavior {
  const _ClampingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}

class LiftApp extends StatelessWidget {
  const LiftApp({super.key, required this.bootstrapData});

  final LiftAppBootstrapData bootstrapData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIFT',
      theme: buildLiftTheme(),
      builder:
          (context, child) => ScrollConfiguration(
            behavior: const _ClampingScrollBehavior(),
            child: child!,
          ),
      home: HomeScreen(
        initialWorkoutHistory: bootstrapData.workoutHistory,
        signedInUserGender: bootstrapData.userGenderRaw,
        preloadedFromBootstrap: true,
      ),
    );
  }
}

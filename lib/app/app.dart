import 'package:flutter/material.dart';
import 'package:lift/app/theme.dart';
import 'package:lift/features/home/home_screen.dart';

class LiftApp extends StatelessWidget {
  const LiftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIFT',
      theme: buildLiftTheme(),
      home: const HomeScreen(),
    );
  }
}

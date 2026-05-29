import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lift/app/app.dart';
import 'package:lift/app/app_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeFirebaseSafely();
  final bootstrapData = await loadLiftAppBootstrapData();
  runApp(LiftApp(bootstrapData: bootstrapData));
}

Future<void> _initializeFirebaseSafely() async {
  try {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase is optional in local/dev environments until platform config is added.
  }
}

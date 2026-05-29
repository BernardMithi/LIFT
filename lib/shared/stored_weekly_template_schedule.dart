import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:lift/shared/weekly_default_template_schedule.dart';

/// Persists Mon–Sun template IDs (same shape as [kWeeklyDefaultTemplateIds]) so
/// [TrainingCalendarScreen] edits and [HomeScreen] stay in sync across launches.
const String kWeeklyTemplateScheduleStorageKey =
    'lift_weekly_template_schedule_v1';

/// Ensures seven lists (Mon–Sun); pads missing days from [kWeeklyDefaultTemplateIds].
List<List<String>> normalizeStoredWeeklySchedule(List<List<String>> raw) {
  final def = kWeeklyDefaultTemplateIds;
  final out = <List<String>>[];
  for (var i = 0; i < 7; i++) {
    if (i < raw.length) {
      out.add(List<String>.from(raw[i]));
    } else {
      out.add(List<String>.from(def[i]));
    }
  }
  return out;
}

Future<List<List<String>>> loadWeeklyTemplateSchedule() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(kWeeklyTemplateScheduleStorageKey);
  if (stored == null || stored.isEmpty) {
    return kWeeklyDefaultTemplateIds
        .map((e) => List<String>.from(e))
        .toList();
  }
  try {
    final decoded = jsonDecode(stored) as List<dynamic>;
    final lists = decoded
        .map(
          (e) =>
              (e as List<dynamic>).map((x) => x as String).toList(),
        )
        .toList();
    return normalizeStoredWeeklySchedule(lists);
  } catch (_) {
    return kWeeklyDefaultTemplateIds
        .map((e) => List<String>.from(e))
        .toList();
  }
}

Future<void> saveWeeklyTemplateSchedule(List<List<String>> days) async {
  final normalized = normalizeStoredWeeklySchedule(days);
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    kWeeklyTemplateScheduleStorageKey,
    jsonEncode(normalized),
  );
}

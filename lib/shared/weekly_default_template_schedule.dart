/// Mon–Sun (index 0 = Monday) template IDs for the demo weekly schedule.
///
/// Used by [HomeScreen] (hero stack) and [TrainingCalendarScreen] (week + month
/// views) so both surfaces show the same workouts per day, including multiple
/// sessions on one day.
const List<List<String>> kWeeklyDefaultTemplateIds = <List<String>>[
  <String>['template_leg_day'],
  <String>['template_push'],
  <String>['template_pull', 'template_core_cardio'],
  <String>['template_core_cardio'],
  // Two workouts so the wallet stack peek is visible on a common demo day.
  <String>['template_leg_day', 'template_core_cardio'],
  <String>['template_push'],
  <String>['template_pull'],
];

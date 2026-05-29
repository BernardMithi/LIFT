/// Asset paths for SVG icons under [assets/icons].
///
/// Streamline **Solar Broken** (and related) filenames map here explicitly — use
/// these constants in code instead of string paths so the bundle always matches UI.
///
/// **Bottom shell tabs** ([HomeScreen] nav): [home] → `Home--Streamline-Solar-Broken.svg`,
/// [guides] → `Notes--Streamline-Solar-Broken.svg`, [weightlifting] → `Dumbbell-Large--…`,
/// [progress] → `Diagram-Up--Streamline-Solar-Broken.svg`.
abstract final class MynauiGlyphs {
  MynauiGlyphs._();

  static const String _root = 'assets/icons';

  /// Shell “Home” tab — Streamline Solar Broken.
  static const String home = '$_root/Home--Streamline-Solar-Broken.svg';

  /// Shell “Guides” tab — Streamline Solar Broken (notes / guides).
  static const String bookOpen = '$_root/Notes--Streamline-Solar-Broken.svg';

  /// Alias for [bookOpen] — clearer at call sites for the Guides tab.
  static const String guides = bookOpen;

  static const String lightning = '$_root/lightning.svg';

  /// Shell “Workouts” tab — Streamline Solar Broken (large dumbbell).
  static const String weightlifting =
      '$_root/Dumbbell-Large--Streamline-Solar-Broken.svg';

  /// Alias for [weightlifting].
  static const String workouts = weightlifting;

  /// Heart + pulse — live workout BPM (`Heart-Pulse--Streamline-Solar-Broken.svg`).
  static const String heartPulse =
      '$_root/Heart-Pulse--Streamline-Solar-Broken.svg';

  /// Flame / calories — live workout KCAL (`Flame--Streamline-Solar-Broken.svg`).
  static const String flame = '$_root/Flame--Streamline-Solar-Broken.svg';

  /// Swap exercise — horizontal sort (`Sort-Horizontal--Streamline-Solar-Broken.svg`).
  static const String sortHorizontal =
      '$_root/Sort-Horizontal--Streamline-Solar-Broken.svg';

  /// Filter / refine lists — `Filter--Streamline-Solar-Broken.svg`.
  static const String filter = '$_root/Filter--Streamline-Solar-Broken.svg';

  /// Live workout exercise stats (`Align-Bottom--Streamline-Solar-Broken.svg`).
  static const String alignBottom =
      '$_root/Align-Bottom--Streamline-Solar-Broken.svg';

  /// Tappable Save / confirm / primary actions — `Check-Circle--Streamline-Solar-Broken.svg`.
  static const String checkCircle =
      '$_root/Check-Circle--Streamline-Solar-Broken.svg';

  /// Passive ticks (status, selection, “already done”) — not for primary buttons.
  /// `Unread--Streamline-Solar-Broken.svg` (broken-line checkmark).
  static const String checkUnread =
      '$_root/Unread--Streamline-Solar-Broken.svg';

  /// `Diagram-Up--Streamline-Solar-Broken.svg` — shell “Progress” tab.
  static const String diagramUp =
      '$_root/Diagram-Up--Streamline-Solar-Broken.svg';

  /// Alias for [diagramUp] — clearer at call sites for the Progress tab.
  static const String progress = diagramUp;

  /// Trends / performance — `Course-Up--Streamline-Solar-Broken.svg`.
  static const String courseUp =
      '$_root/Course-Up--Streamline-Solar-Broken.svg';

  /// Alias for [courseUp] (leg day trends, workout detail trends control).
  static const String trends = courseUp;

  /// Exercise execution / movement preview — `Stretching-Round--Streamline-Solar-Broken.svg`.
  static const String stretchingRound =
      '$_root/Stretching-Round--Streamline-Solar-Broken.svg';

  /// Exercise target / muscle map — `Target--Streamline-Solar-Broken.svg`.
  static const String target = '$_root/Target--Streamline-Solar-Broken.svg';

  /// Profile / settings control on shell island headers — `user-no-circle.svg`.
  static const String userNoCircle = '$_root/user-no-circle.svg';

  /// Alias for [userNoCircle] (profile button in [LiftIslandHeader] and related).
  static const String profile = userNoCircle;

  /// `Qr-Code--Streamline-Solar-Broken.svg`
  static const String qrCode = '$_root/Qr-Code--Streamline-Solar-Broken.svg';

  /// Alias for [qrCode].
  static const String qr = qrCode;

  /// `Magnifer--Streamline-Solar-Broken.svg`
  static const String magnifer = '$_root/Magnifer--Streamline-Solar-Broken.svg';

  /// Alias for [magnifer].
  static const String search = magnifer;

  /// `Calendar--Streamline-Solar-Broken.svg`
  static const String calendarMark =
      '$_root/Calendar--Streamline-Solar-Broken.svg';

  /// Alias for [calendarMark].
  static const String calendar = calendarMark;

  /// Month grid → week list toggle on training calendar nav.
  static const String viewAgenda =
      '$_root/View-Agenda--Streamline-Rounded-Material-Symbols.svg';

  /// Overflow / options menu (header & toolbars).
  static const String menuDotsCircle =
      '$_root/Menu-Dots-Circle--Streamline-Solar-Broken.svg';

  /// Delete / remove actions — Streamline Solar Broken.
  static const String trashBin =
      '$_root/Trash-Bin-Minimalistic--Streamline-Solar-Broken.svg';

  /// Add / create — `Add-Circle--Streamline-Solar-Broken.svg`.
  static const String addCircle =
      '$_root/Add-Circle--Streamline-Solar-Broken.svg';

  /// Alias for [addCircle] (FABs, headers, primary “add”).
  static const String add = addCircle;

  /// Legacy name for [addCircle] — same asset as [addCircle].
  static const String plus = addCircle;
  static const String chevronRight = '$_root/chevron-right.svg';
  static const String chevronLeft = '$_root/chevron-left.svg';
  static const String arrowLeft = '$_root/arrow-left.svg';

  /// Back navigation — `Alt-Arrow-Left--Streamline-Solar-Broken.svg` (headers, pop affordances).
  static const String altArrowLeft =
      '$_root/Alt-Arrow-Left--Streamline-Solar-Broken.svg';

  /// Forward / schedule card — `Alt-Arrow-Right--Streamline-Solar-Broken.svg`.
  static const String altArrowRight =
      '$_root/Alt-Arrow-Right--Streamline-Solar-Broken.svg';

  /// Alias for [altArrowLeft].
  static const String back = altArrowLeft;

  /// Saved articles / bookmark actions.
  static const String bookmark = '$_root/Bookmark--Streamline-Solar-Broken.svg';

  /// Share actions (article hero, workout options sheet, etc.).
  static const String squareShareLine =
      '$_root/Square-Share-Line--Streamline-Solar-Broken.svg';

  /// Settings / configuration actions — `Settings--Streamline-Solar-Broken.svg`.
  static const String settings = '$_root/Settings--Streamline-Solar-Broken.svg';

  /// Review / checklist — `Clipboard-List--Streamline-Solar-Broken.svg`.
  static const String clipboardList =
      '$_root/Clipboard-List--Streamline-Solar-Broken.svg';

  /// Edit actions — `Pen-New-Square--Streamline-Solar-Broken.svg`.
  static const String editOne =
      '$_root/Pen-New-Square--Streamline-Solar-Broken.svg';

  /// Alias for [editOne].
  static const String edit = editOne;

  /// Upload / library pick — `Upload--Streamline-Solar-Broken.svg`.
  static const String upload = '$_root/Upload--Streamline-Solar-Broken.svg';

  /// Paste URL / link — `Link-Circle--Streamline-Solar-Broken.svg`.
  static const String linkCircle =
      '$_root/Link-Circle--Streamline-Solar-Broken.svg';

  /// Start workout on [WorkoutDetailActionIsland] primary pill.
  static const String stopwatchPlay =
      '$_root/Stopwatch-Play--Streamline-Solar-Broken.svg';

  /// Reset filters — `Restart-Circle--Streamline-Solar-Broken.svg`.
  static const String restartCircle =
      '$_root/Restart-Circle--Streamline-Solar-Broken.svg';

  /// Close / dismiss actions — `Close-Circle--Streamline-Solar-Broken.svg`.
  static const String closeCircle =
      '$_root/Close-Circle--Streamline-Solar-Broken.svg';

  /// Alias for [closeCircle] — sheet cancel, dismiss, legacy `x` call sites.
  static const String x = closeCircle;

  /// Gallery / hero / image placeholders — `Gallery-Minimalistic--Streamline-Solar-Broken.svg`.
  static const String galleryMinimalistic =
      '$_root/Gallery-Minimalistic--Streamline-Solar-Broken.svg';

  /// Refresh / repeat actions — `Refresh--Streamline-Solar-Broken.svg`.
  static const String refresh = '$_root/Refresh--Streamline-Solar-Broken.svg';

  /// Weight / dumbbell pair — `Dumbbells--Streamline-Solar-Broken.svg`.
  static const String dumbbells =
      '$_root/Dumbbells--Streamline-Solar-Broken.svg';

  /// Generic machine / equipment icon — `Treadmill--Streamline-Solar-Broken.svg`.
  static const String treadmill =
      '$_root/Treadmill--Streamline-Solar-Broken.svg';

  /// Alias for [treadmill] in machine metadata surfaces.
  static const String machine = treadmill;

  /// Show all / list — `List-Down--Streamline-Solar-Broken.svg`.
  static const String listDown =
      '$_root/List-Down--Streamline-Solar-Broken.svg';

  /// Exercise count / documents; also workouts list → default carousel.
  /// `Documents--Streamline-Solar-Broken.svg`.
  static const String documents =
      '$_root/Documents--Streamline-Solar-Broken.svg';

  /// Duration / paused timer — `Alarm-Pause--Streamline-Solar-Broken.svg`.
  static const String alarmPause =
      '$_root/Alarm-Pause--Streamline-Solar-Broken.svg';

  /// Announcements / voice cues — `Megaphone--Streamline-Ultimate.svg`.
  static const String megaphone = '$_root/Megaphone--Streamline-Ultimate.svg';

  /// Small volume / audio cues — `Volume-Small--Streamline-Solar-Broken.svg`.
  static const String volumeSmall =
      '$_root/Volume-Small--Streamline-Solar-Broken.svg';

  /// Haptics / vibration cues — `Smartphone-Vibration--Streamline-Solar-Broken.svg`.
  static const String smartphoneVibration =
      '$_root/Smartphone-Vibration--Streamline-Solar-Broken.svg';

  /// Notes / notetaking — `Notebook--Streamline-Solar-Broken.svg`.
  static const String notebook = '$_root/Notebook--Streamline-Solar-Broken.svg';

  /// Info / metadata details — `Info-Circle--Streamline-Solar-Broken.svg`.
  static const String infoCircle =
      '$_root/Info-Circle--Streamline-Solar-Broken.svg';

  /// Brand / label metadata — `Tag-Horizontal--Streamline-Solar-Broken.svg`.
  static const String tagHorizontal =
      '$_root/Tag-Horizontal--Streamline-Solar-Broken.svg';

  /// Machine ID / code metadata — `Hashtag-Square--Streamline-Solar-Broken.svg`.
  static const String hashtagSquare =
      '$_root/Hashtag-Square--Streamline-Solar-Broken.svg';

  /// Recovery carousel swipe hint — `Hand-Move--Streamline-Tabler.svg`.
  static const String handMoveStreamlineTabler =
      '$_root/Hand-Move--Streamline-Tabler.svg';
}

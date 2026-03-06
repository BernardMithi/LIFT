import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kAccentColor = Color(0xFF8A3A08);
const Color kAccentDark = Color(0xFF3A1706);
const Color kAccentMid = Color(0xFF7A2F08);
const Color kAccentLight = Color(0xFFB65A1B);

ThemeData buildLiftTheme() {
  final baseTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: kAccentColor),
    useMaterial3: true,
  );

  return baseTheme.copyWith(
    textTheme: GoogleFonts.spaceGroteskTextTheme(baseTheme.textTheme),
    scaffoldBackgroundColor: Colors.white,
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Barlow Condensed (heavy, tight) for headings, Barlow for reading,
/// JetBrains Mono for data: prices in DZD, IDs, distances, times, labels.
TextStyle figs({double size = 12, FontWeight weight = FontWeight.w500, Color? color}) => GoogleFonts.jetBrainsMono(
  fontSize: size,
  fontWeight: weight == FontWeight.w600 ? FontWeight.w500 : (weight == FontWeight.w800 ? FontWeight.w700 : weight),
  color: color ?? C.ink,
  letterSpacing: 0,
);

TextStyle display({double size = 28, Color? color, FontWeight weight = FontWeight.w700}) => GoogleFonts.barlowCondensed(
  fontSize: size,
  fontWeight: weight == FontWeight.w400 ? FontWeight.w500 : (weight == FontWeight.w600 ? FontWeight.w700 : weight),
  color: color ?? C.ink,
  height: .95,
  letterSpacing: -.2,
);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: C.isLight ? Brightness.light : Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      brightness: C.isLight ? Brightness.light : Brightness.dark,
      seedColor: C.volt,
      primary: C.volt,
      onPrimary: C.onFill,
      secondary: C.teal,
      onSecondary: C.onFill,
      surface: C.card,
      onSurface: C.ink,
      error: C.red,
    ),
    scaffoldBackgroundColor: C.bg,
    canvasColor: C.bg,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    dividerColor: C.line,
  );
  final text = GoogleFonts.barlowTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15.5, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(fontSize: 13.5, color: C.inkSoft, height: 1.35),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: TextStyle(color: C.inkSoft),
      counterStyle: TextStyle(color: C.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: BorderSide(color: C.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: BorderSide(color: C.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: BorderSide(color: C.volt, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: C.volt, selectionColor: (C.isLight ? C.highlight : C.volt).withValues(alpha: .4), selectionHandleColor: C.volt),
    sliderTheme: SliderThemeData(
      activeTrackColor: C.volt,
      inactiveTrackColor: C.line,
      thumbColor: C.volt,
      overlayColor: Colors.transparent,
      trackHeight: 3,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.onFill : C.inkSoft),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.volt : C.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.volt : Colors.transparent),
      checkColor: WidgetStateProperty.all(C.onFill),
      side: BorderSide(color: C.lineStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: C.card, surfaceTintColor: Colors.transparent),
    dialogTheme: DialogThemeData(backgroundColor: C.card, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.volt,
      contentTextStyle: GoogleFonts.jetBrainsMono(color: C.onFill, fontWeight: FontWeight.w700, fontSize: 13),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
    ),
  );
}

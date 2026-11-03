import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Plus Jakarta Sans everywhere: friendly, modern, very legible.
/// [figs] is for data (prices, times, distances, IDs): same face, tabular figures.
TextStyle figs({double size = 12, FontWeight weight = FontWeight.w500, Color? color}) => GoogleFonts.plusJakartaSans(
  fontSize: size + 1,
  fontWeight: weight == FontWeight.w700 ? FontWeight.w600 : weight,
  color: color ?? C.ink,
  fontFeatures: const [FontFeature.tabularFigures()],
);

TextStyle display({double size = 28, Color? color, FontWeight weight = FontWeight.w700}) => GoogleFonts.plusJakartaSans(
  // The old condensed face ran small; Jakarta is wide, so scale big sizes down a little.
  fontSize: size > 30 ? size * .62 + 6 : size * .82,
  fontWeight: weight == FontWeight.w800 ? FontWeight.w800 : FontWeight.w700,
  color: color ?? C.ink,
  height: 1.2,
  letterSpacing: -.3,
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
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
      bodySmall: text.bodySmall?.copyWith(fontSize: 13.5, color: C.inkSoft, height: 1.45),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, fontSize: 16),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    textSelectionTheme: TextSelectionThemeData(cursorColor: C.volt, selectionColor: C.volt.withValues(alpha: .25), selectionHandleColor: C.volt),
    sliderTheme: SliderThemeData(
      activeTrackColor: C.volt,
      inactiveTrackColor: C.line,
      thumbColor: C.volt,
      overlayColor: Colors.transparent,
      trackHeight: 3,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.onFill : C.card),
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
      backgroundColor: C.isLight ? C.ink : C.card,
      contentTextStyle: GoogleFonts.plusJakartaSans(color: C.isLight ? Colors.white : C.ink, fontWeight: FontWeight.w600, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
    ),
  );
}

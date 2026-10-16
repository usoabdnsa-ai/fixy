import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

/// Archivo for everything people read, IBM Plex Mono for "stamped" data:
/// prices in DZD, IDs, distances, timestamps.
TextStyle mono({double size = 12, FontWeight weight = FontWeight.w500, Color color = C.ink}) =>
    GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.2);

TextStyle display({double size = 28, Color color = C.ink, FontWeight weight = FontWeight.w800}) =>
    GoogleFonts.archivo(fontSize: size, fontWeight: weight, color: color, height: 1.05, letterSpacing: -0.6);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.orange,
      primary: C.orange,
      onPrimary: C.ink,
      secondary: C.teal,
      onSecondary: Colors.white,
      surface: C.card,
      onSurface: C.ink,
      error: C.red,
    ),
    scaffoldBackgroundColor: C.paper,
    splashFactory: NoSplash.splashFactory, // press feedback is the scale/shadow, not an ink ripple
    highlightColor: Colors.transparent,
  );
  final text = GoogleFonts.archivoTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink);
  return base.copyWith(
    textTheme: text.copyWith(
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.4),
      bodySmall: text.bodySmall?.copyWith(fontSize: 13, color: C.inkSoft, height: 1.35),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: const TextStyle(color: C.inkSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: const BorderSide(color: C.line, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: const BorderSide(color: C.line, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(R.md),
        borderSide: const BorderSide(color: C.ink, width: 2),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: C.ink,
      inactiveTrackColor: C.line,
      thumbColor: C.orange,
      overlayColor: Colors.transparent,
      trackHeight: 4,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.card : C.inkSoft),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.teal : C.line),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.ink,
      contentTextStyle: GoogleFonts.archivo(color: C.paper, fontWeight: FontWeight.w600),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
    ),
  );
}

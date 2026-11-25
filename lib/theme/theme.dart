import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// Inter everywhere (spec 4.4); Inter Display for big titles.
const _inter = 'Inter';

TextStyle title({double size = 22, Color color = C.ink, FontWeight weight = FontWeight.w700}) =>
    TextStyle(fontFamily: size >= 20 ? 'InterDisplay' : _inter, fontSize: size, fontWeight: weight, color: color, height: 1.2, letterSpacing: size >= 20 ? -.4 : -.1);

TextStyle body({double size = 15, Color color = C.ink, FontWeight weight = FontWeight.w400, double height = 1.45}) =>
    TextStyle(fontFamily: _inter, fontSize: size, fontWeight: weight, color: color, height: height);

/// Prices, counts, dates: tabular figures so numbers line up.
TextStyle figs({double size = 14, Color color = C.ink, FontWeight weight = FontWeight.w600}) =>
    TextStyle(fontFamily: _inter, fontSize: size, fontWeight: weight, color: color, fontFeatures: const [FontFeature.tabularFigures()]);

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: _inter,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.navy,
      primary: C.navy,
      onPrimary: C.white,
      secondary: C.turq,
      onSecondary: C.navy,
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
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink, fontFamily: _inter),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: CupertinoPageTransitionsBuilder(), TargetPlatform.iOS: CupertinoPageTransitionsBuilder()},
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      foregroundColor: C.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontFamily: 'InterDisplay', fontSize: 20, fontWeight: FontWeight.w700, color: C.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      hintStyle: const TextStyle(color: C.inkFaint, fontFamily: _inter),
      labelStyle: const TextStyle(color: C.inkSoft, fontFamily: _inter),
      floatingLabelStyle: const TextStyle(color: C.turqText, fontFamily: _inter, fontWeight: FontWeight.w600),
      prefixIconColor: C.inkSoft,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.turq, width: 1.6)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.red)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(R.md), borderSide: const BorderSide(color: C.red, width: 1.6)),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: C.navy, selectionColor: C.turq.withValues(alpha: .3), selectionHandleColor: C.turq),
    sliderTheme: const SliderThemeData(
      activeTrackColor: C.turq,
      inactiveTrackColor: C.line,
      thumbColor: C.navy,
      overlayColor: Colors.transparent,
      trackHeight: 4,
      valueIndicatorColor: C.navy,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.all(C.white),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.turq : C.lineStrong),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? C.navy : Colors.transparent),
      checkColor: WidgetStateProperty.all(C.white),
      side: const BorderSide(color: C.lineStrong, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: C.card, surfaceTintColor: Colors.transparent, showDragHandle: true),
    dialogTheme: const DialogThemeData(backgroundColor: C.card, surfaceTintColor: Colors.transparent),
    datePickerTheme: const DatePickerThemeData(backgroundColor: C.card, surfaceTintColor: Colors.transparent),
    timePickerTheme: const TimePickerThemeData(backgroundColor: C.card),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.navy,
      contentTextStyle: const TextStyle(fontFamily: _inter, color: C.white, fontWeight: FontWeight.w600, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.sm)),
    ),
  );
}

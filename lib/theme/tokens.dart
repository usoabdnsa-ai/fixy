import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:flutter/foundation.dart' show ValueNotifier;

/// One set of Fixy colors. v3 "Trust blue": [Palette.day] is the default,
/// [Palette.night] is the dark-mode toggle. Read colors through [C].
///
/// Role names are historical: `volt` is the brand primary (trust blue),
/// `hot` is urgent (orange), `teal` is verified/success (green), `amber`
/// is ratings and pending.
class Palette {
  const Palette({
    required this.bg, required this.card, required this.ink, required this.inkSoft, required this.line,
    required this.lineStrong, required this.volt, required this.voltWash, required this.highlight,
    required this.onFill, required this.onFillSoft, required this.hot, required this.hotText, required this.hotWash,
    required this.teal, required this.tealWash, required this.red, required this.redWash, required this.amber,
    required this.amberWash, required this.nightBg, required this.seriesA, required this.seriesB,
  });
  final Color bg, card, ink, inkSoft, line, lineStrong, volt, voltWash, highlight, onFill, onFillSoft;
  final Color hot, hotText, hotWash, teal, tealWash, red, redWash, amber, amberWash, nightBg, seriesA, seriesB;

  /// Light (default): soft grey-blue page, white cards, slate text, trust blue.
  /// ink/bg 16.3, inkSoft/card 7.6, white/volt 6.7, hotText/card 5.2,
  /// teal/card 5.0, amber(text)/amberWash 5.9.
  static const day = Palette(
    bg: Color(0xFFF4F6FA), card: Color(0xFFFFFFFF), ink: Color(0xFF0F172A), inkSoft: Color(0xFF475569),
    line: Color(0xFFE2E8F0), lineStrong: Color(0xFFCBD5E1), volt: Color(0xFF1D4ED8), voltWash: Color(0xFFE8EFFE),
    highlight: Color(0x00000000), onFill: Color(0xFFFFFFFF), onFillSoft: Color(0xFFDCE6FD),
    hot: Color(0xFFC2410C), hotText: Color(0xFFC2410C), hotWash: Color(0xFFFFF1E8),
    teal: Color(0xFF15803D), tealWash: Color(0xFFE7F7EC), red: Color(0xFFDC2626), redWash: Color(0xFFFDECEC),
    amber: Color(0xFF92600A), amberWash: Color(0xFFFEF5E1), nightBg: Color(0xFF0F172A),
    seriesA: Color(0xFF1D4ED8), seriesB: Color(0xFFF59E0B),
  );

  /// Dark: deep slate, lighter blue so fills keep contrast with white labels.
  /// ink/bg 15.9, inkSoft/bg 7.2, white/volt 5.2, hotText/bg 7.0, teal/bg 8.6.
  static const night = Palette(
    bg: Color(0xFF0B1220), card: Color(0xFF151E31), ink: Color(0xFFF1F5F9), inkSoft: Color(0xFF94A3B8),
    line: Color(0xFF243049), lineStrong: Color(0xFF334262), volt: Color(0xFF2F6BF0), voltWash: Color(0xFF16264A),
    highlight: Color(0x00000000), onFill: Color(0xFFFFFFFF), onFillSoft: Color(0xFFD6E2FF),
    hot: Color(0xFFC2410C), hotText: Color(0xFFFB923C), hotWash: Color(0xFF2E1A10),
    teal: Color(0xFF4ADE80), tealWash: Color(0xFF12301F), red: Color(0xFFF87171), redWash: Color(0xFF331616),
    amber: Color(0xFFFBBF24), amberWash: Color(0xFF2E2510), nightBg: Color(0xFF060A14),
    seriesA: Color(0xFF60A5FA), seriesB: Color(0xFFFBBF24),
  );
}

class C {
  /// true = light palette (the default). The app root listens and restyles every screen.
  static final light = ValueNotifier<bool>(true);
  static Palette get _p => light.value ? Palette.day : Palette.night;
  static bool get isLight => light.value;

  static Color get bg => _p.bg;
  static Color get card => _p.card; // raised surface
  static Color get ink => _p.ink; // primary text
  static Color get inkSoft => _p.inkSoft;
  static Color get line => _p.line; // borders, dividers
  static Color get lineStrong => _p.lineStrong;
  static Color get volt => _p.volt; // brand primary (trust blue)
  static Color get voltWash => _p.voltWash; // primary tint for chips / icon tiles
  static Color get highlight => _p.highlight;
  static Color get onFill => _p.onFill; // labels on primary / urgent / success fills
  static Color get onFillSoft => _p.onFillSoft;
  static Color get hot => _p.hot; // urgent fill
  static Color get hotText => _p.hotText; // urgent as text
  static Color get hotWash => _p.hotWash;
  static Color get teal => _p.teal; // verified / success
  static Color get tealWash => _p.tealWash;
  static Color get red => _p.red;
  static Color get redWash => _p.redWash;
  static Color get amber => _p.amber; // pending text
  static Color get amberWash => _p.amberWash;
  static Color get star => const Color(0xFFF59E0B); // rating stars, both themes
  static Color get night => _p.nightBg;
  static Color get seriesA => _p.seriesA;
  static Color get seriesB => _p.seriesB;
}

class S {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 20.0;
}

/// Soft, friendly corners.
class R {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 22.0;
  static const pill = 999.0;
}

/// Motion tokens: calm ease-outs and a gentle spring with a touch of overshoot.
class M {
  static const press = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 45);
  static const out = Cubic(0.22, 1, 0.36, 1); // ease-out-quint
  static const inOut = Cubic(0.65, 0, 0.35, 1);
  static const spring = Cubic(0.34, 1.4, 0.64, 1); // small overshoot
}

/// Soft elevation on light; on dark, borders do the work and shadows vanish.
List<BoxShadow> get lift => C.isLight
    ? const [
        BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2),
        BoxShadow(color: Color(0x140F172A), offset: Offset(0, 8), blurRadius: 24, spreadRadius: -6),
      ]
    : const [];
List<BoxShadow> get liftPressed => C.isLight ? const [BoxShadow(color: Color(0x0F0F172A), offset: Offset(0, 1), blurRadius: 2)] : const [];

/// Brand shadow under primary buttons and live markers.
List<BoxShadow> get glow => [BoxShadow(color: C.volt.withValues(alpha: C.isLight ? .28 : .4), offset: const Offset(0, 8), blurRadius: 20, spreadRadius: -6)];

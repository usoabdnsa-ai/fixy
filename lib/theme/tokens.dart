import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'package:flutter/foundation.dart' show ValueNotifier;

/// One set of Fixy colors. Two exist: [Palette.night] (default) and
/// [Palette.day]. Read colors through [C]; flip with [C.light].
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

  /// Night shift: near-black, electric volt, hairlines. Bright fills carry dark labels.
  /// ink/bg 17.6, inkSoft/bg 7.0, volt/bg 17.0, onFill/volt 17.0, onFill/hot 6.9,
  /// onFill/teal 10.9, hotText/bg 7.4, teal/bg 10.9.
  static const night = Palette(
    bg: Color(0xFF0B0C0E), card: Color(0xFF15171B), ink: Color(0xFFF2F3EE), inkSoft: Color(0xFF9198A4),
    line: Color(0xFF262A31), lineStrong: Color(0xFF3A3F48), volt: Color(0xFFE4FF3A), voltWash: Color(0xFF22270C),
    highlight: Color(0x00000000), onFill: Color(0xFF0B0C0E), onFillSoft: Color(0xFF34381C),
    hot: Color(0xFFFF5A36), hotText: Color(0xFFFF7A5C), hotWash: Color(0xFF2E140D),
    teal: Color(0xFF2BD9A0), tealWash: Color(0xFF0E2A20), red: Color(0xFFFF5A5A), redWash: Color(0xFF331414),
    amber: Color(0xFFFFC547), amberWash: Color(0xFF2E2410), nightBg: Color(0xFF050607),
    seriesA: Color(0xFFE4FF3A), seriesB: Color(0xFFFF5A36),
  );

  /// Day shift: same tool, printed on paper. The "volt" role becomes solid
  /// ink (black slabs with volt labels); volt itself survives as a marker
  /// [highlight] behind accent words.
  /// ink/bg 18.4, inkSoft/bg 6.0, onFill(volt)/volt(ink) 17.0, onFill/hot 4.9,
  /// hotText/bg 5.3, teal/bg 4.9, white text never used on light surfaces.
  static const day = Palette(
    bg: Color(0xFFF6F6F1), card: Color(0xFFFFFFFF), ink: Color(0xFF0B0C0E), inkSoft: Color(0xFF575D68),
    line: Color(0xFFE2E2DB), lineStrong: Color(0xFFC4C4BA), volt: Color(0xFF0B0C0E), voltWash: Color(0xFFEEF8B0),
    highlight: Color(0xFFE4FF3A), onFill: Color(0xFFE4FF3A), onFillSoft: Color(0xFFB4C45A),
    hot: Color(0xFFD33A1A), hotText: Color(0xFFC0361A), hotWash: Color(0xFFFCE6DF),
    teal: Color(0xFF0B7A57), tealWash: Color(0xFFDDF3EA), red: Color(0xFFC62828), redWash: Color(0xFFFBE3E3),
    amber: Color(0xFF8A5A00), amberWash: Color(0xFFFFF1D0), nightBg: Color(0xFF0B0C0E),
    seriesA: Color(0xFF0B0C0E), seriesB: Color(0xFFD33A1A),
  );
}

class C {
  /// true = day palette. Listened to by the app root, which restyles every screen.
  static final light = ValueNotifier<bool>(false);
  static Palette get _p => light.value ? Palette.day : Palette.night;
  static bool get isLight => light.value;

  static Color get bg => _p.bg;
  static Color get card => _p.card; // raised surface
  static Color get ink => _p.ink; // primary text
  static Color get inkSoft => _p.inkSoft;
  static Color get line => _p.line; // hairlines
  static Color get lineStrong => _p.lineStrong;
  static Color get volt => _p.volt; // primary fill + highlight text
  static Color get voltWash => _p.voltWash;
  static Color get highlight => _p.highlight; // marker behind accent words (day only)
  static Color get onFill => _p.onFill; // labels on volt / hot / teal
  static Color get onFillSoft => _p.onFillSoft;
  static Color get hot => _p.hot; // urgent fill
  static Color get hotText => _p.hotText; // urgent as text
  static Color get hotWash => _p.hotWash;
  static Color get teal => _p.teal; // verified / success
  static Color get tealWash => _p.tealWash;
  static Color get red => _p.red;
  static Color get redWash => _p.redWash;
  static Color get amber => _p.amber;
  static Color get amberWash => _p.amberWash;
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

/// Sharp, tool-like corners.
class R {
  static const sm = 3.0;
  static const md = 6.0;
  static const lg = 8.0;
  static const pill = 999.0;
}

/// Motion tokens. Night shift motion is fast and mechanical: hard ease-outs,
/// wipes and scrambles, no bounce.
class M {
  static const press = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 380);
  static const stagger = Duration(milliseconds: 40);
  static const out = Cubic(0.16, 1, 0.3, 1); // expo-out
  static const inOut = Cubic(0.87, 0, 0.13, 1);
  static const spring = Cubic(0.16, 1, 0.3, 1); // no overshoot in this theme
}

/// No soft shadows on dark: depth is a hairline plus a faint volt edge glow.
const lift = <BoxShadow>[];
const liftPressed = <BoxShadow>[];
List<BoxShadow> get glow => C.isLight ? const [] : const [BoxShadow(color: Color(0x40E4FF3A), blurRadius: 24, spreadRadius: -4)];

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Fixy "workshop toolbox" tokens.
/// Contrast contract (checked with tastemaker check_contrast.py):
///   ink on paper 15.0, ink on card 17.1, ink on orange 5.6 (labels on orange are ink, never white),
///   teal on paper 5.6, white on teal 6.3, rust on paper 5.1 (orange is a fill, rust is orange-as-text).
class C {
  static const paper = Color(0xFFF4EEE3);
  static const card = Color(0xFFFFFDF8);
  static const ink = Color(0xFF1C1A17);
  static const inkSoft = Color(0xFF6B6357); // secondary text, 5.1:1 on paper
  static const line = Color(0xFFDED3C0);
  static const lineStrong = Color(0xFFC9BCA5);
  static const orange = Color(0xFFFF5A1F); // safety orange, fills only
  static const rust = Color(0xFFA9370B); // orange used as text
  static const teal = Color(0xFF0F6B5C); // verified / success
  static const tealWash = Color(0xFFDCEBE6);
  static const orangeWash = Color(0xFFFFE3D6);
  static const red = Color(0xFFB42318);
  static const redWash = Color(0xFFFBE2DF);
  static const amber = Color(0xFF8A5A00);
  static const amberWash = Color(0xFFFCEFCF);
  static const night = Color(0xFF1C1A17);
  // Chart series (validated with dataviz validate_palette.js vs card surface).
  static const seriesA = Color(0xFFFF5A1F);
  static const seriesB = Color(0xFF0B8C78);
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

class R {
  static const sm = 8.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

/// Motion tokens. UI motion stays under 300ms; only the splash and the
/// "verified" stamp are allowed to run longer (they happen once).
class M {
  static const press = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 45);
  static const out = Cubic(0.23, 1, 0.32, 1); // strong ease-out
  static const inOut = Cubic(0.77, 0, 0.175, 1);
  static const spring = Cubic(0.34, 1.36, 0.64, 1); // small overshoot for stamps/badges
}

/// Hard "tool tag" shadow: offset, no blur. Reads as a printed tag, not a floating card.
const tagShadow = [BoxShadow(color: C.ink, offset: Offset(0, 3), blurRadius: 0)];
const tagShadowPressed = [BoxShadow(color: C.ink, offset: Offset(0, 1), blurRadius: 0)];

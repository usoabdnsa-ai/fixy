import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// Fixy colours, from the specification (section 4.4):
/// Deep Navy #0D1B2A, Turquoise #00C49A, White #FFFFFF.
///
/// Contrast rules (WCAG AA):
/// - Turquoise is a FILL with navy labels (8.9:1). White on turquoise is only 2.3:1, never use it.
/// - Turquoise as TEXT on white uses [turqText] (4.9:1).
/// - Navy fills take white labels (17:1).
abstract final class C {
  static const navy = Color(0xFF0D1B2A);
  static const navySoft = Color(0xFF1B2B3D); // raised surface on navy
  static const turq = Color(0xFF00C49A);
  static const turqText = Color(0xFF00785E);
  static const turqWash = Color(0xFFE3F8F2);
  static const white = Color(0xFFFFFFFF);

  static const bg = Color(0xFFF5F7F9); // page
  static const card = white;
  static const ink = navy; // primary text
  static const inkSoft = Color(0xFF55657A); // secondary text, 5.9:1 on white
  static const inkFaint = Color(0xFF8593A5); // placeholders, icons only
  static const line = Color(0xFFE3E8EE);
  static const lineStrong = Color(0xFFCBD3DC);

  static const star = Color(0xFFF5A524);
  static const amber = Color(0xFF9A6100); // "En attente" text, 5.0:1 on its wash
  static const amberWash = Color(0xFFFFF3DC);
  static const blue = Color(0xFF1F5FD1); // "Acceptée"
  static const blueWash = Color(0xFFE6EEFC);
  static const green = Color(0xFF14804A); // "Terminée"
  static const greenWash = Color(0xFFE4F5EB);
  static const red = Color(0xFFC62828); // "Annulée", errors
  static const redWash = Color(0xFFFDECEC);
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

/// Radii: the spec asks for rounded 16px cards.
class R {
  static const sm = 10.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const pill = 999.0;
}

class M {
  static const press = Duration(milliseconds: 110);
  static const fast = Duration(milliseconds: 180);
  static const base = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 40);
  static const out = Cubic(0.22, 1, 0.36, 1);
  static const inOut = Cubic(0.65, 0, 0.35, 1);
  static const spring = Cubic(0.34, 1.4, 0.64, 1);
}

/// The spec's "subtle shadows".
const List<BoxShadow> lift = [
  BoxShadow(color: Color(0x0D0D1B2A), offset: Offset(0, 1), blurRadius: 2),
  BoxShadow(color: Color(0x120D1B2A), offset: Offset(0, 6), blurRadius: 18, spreadRadius: -6),
];

import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../widgets/icons.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'demo_links.dart';
import 'onboarding.dart';

/// Intro, ~2.2s, skippable by tap. On brand blue:
///  1. soft rings ripple out from the centre,
///  2. the white house tile pops in with a little spring,
///  3. the check mark draws itself in the doorway,
///  4. "fixy" and the promise rise in underneath.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  Timer? _t;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t != null) return;
    final still = reduceMotion(context);
    still ? _c.value = 1 : _c.forward();
    _t = Timer(Duration(milliseconds: still ? 500 : 2600), _next);
  }

  void _next() {
    if (_left || !mounted) return;
    _left = true;
    if (openDeepLink(context)) return;
    Navigator.of(context).pushReplacement(fadeRoute(const OnboardingScreen()));
  }

  @override
  void dispose() {
    _t?.cancel();
    _c.dispose();
    super.dispose();
  }

  double _seg(double a, double b, [Curve curve = M.out]) => curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    const blue = Color(0xFF1D4ED8);
    return Scaffold(
      backgroundColor: blue,
      body: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final pop = _seg(.15, .45, M.spring);
            return Stack(
              children: [
                // Soft brand gradient.
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)]),
                    ),
                  ),
                ),
                // Ripples.
                for (var i = 0; i < 3; i++)
                  Center(
                    child: Opacity(
                      opacity: (1 - _seg(i * .12, .55 + i * .12, Curves.easeOut)) * .25 * (_c.value > i * .12 ? 1 : 0),
                      child: Container(
                        width: 120 + 360 * _seg(i * .12, .55 + i * .12, Curves.easeOut),
                        height: 120 + 360 * _seg(i * .12, .55 + i * .12, Curves.easeOut),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(
                        scale: pop,
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 30, offset: Offset(0, 12))],
                          ),
                          alignment: Alignment.center,
                          child: FixyMark(size: 72, bolt: _seg(.4, .62, Curves.easeInOut)),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Opacity(
                        opacity: _seg(.55, .75),
                        child: Transform.translate(
                          offset: Offset(0, 12 * (1 - _seg(.55, .8))),
                          child: Text(
                            'fixy',
                            style: GoogleFonts.plusJakartaSans(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.5, height: 1),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: _seg(.7, .9),
                        child: Text(
                          'Trusted repairs, right at your door.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: .85)),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: pad.bottom + 32,
                  child: Opacity(
                    opacity: _seg(.8, 1),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsFill.sealCheck, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          "Every m'lem ID-verified",
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

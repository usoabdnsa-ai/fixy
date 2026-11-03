import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'demo_links.dart';
import 'onboarding.dart';

/// Intro, ~2.4s, skippable by tap. A night-shift boot sequence:
///  1. a volt scanline sweeps down the black screen,
///  2. three mono status lines type themselves in,
///  3. the volt square wipes in and the bolt is punched out of it,
///  4. "FIXY" decodes from random glyphs.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  Timer? _t;
  bool _left = false;

  static const _lines = ['> LOCATING YOU ......... KOUBA, ALGER', "> SCANNING M'LEMS ...... 12 ONLINE", '> VERIFIED IDS ......... OK'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t != null) return;
    final still = reduceMotion(context);
    still ? _c.value = 1 : _c.forward();
    _t = Timer(Duration(milliseconds: still ? 500 : 2800), _next);
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
    return Scaffold(
      backgroundColor: C.bg,
      body: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final h = MediaQuery.sizeOf(context).height;
            final scan = _seg(0, .3, Curves.easeInOut);
            return Stack(
              children: [
                const Positioned.fill(child: Scanlines(opacity: .035)),
                // Sweep line with a fading trail.
                if (scan > 0 && scan < 1)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: h * scan - 80,
                    height: 82,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [C.volt.withValues(alpha: 0), C.volt.withValues(alpha: .13), C.volt],
                          stops: [0, .97, 1],
                        ),
                      ),
                    ),
                  ),
                // Boot log, top left.
                Positioned(
                  left: S.gutter,
                  right: S.gutter,
                  top: pad.top + 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, l) in _lines.indexed)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            l.substring(0, (l.length * _seg(.12 + i * .12, .3 + i * .12, Curves.linear)).round()),
                            style: figs(size: 11, color: i == 2 && _c.value > .55 ? C.teal : C.inkSoft),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: S.gutter,
                  right: S.gutter,
                  bottom: pad.bottom + 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FixyMark(size: 84, reveal: _seg(.5, .62, M.inOut), bolt: _seg(.6, .75)),
                      const SizedBox(height: 22),
                      if (_c.value > .66) Headline('FIXY', style: display(size: 120, weight: FontWeight.w800).copyWith(height: .82, letterSpacing: -2)),
                      if (_c.value <= .66) SizedBox(height: 120 * .82 * 1.2),
                      const SizedBox(height: 14),
                      Opacity(
                        opacity: _seg(.85, 1),
                        child: Row(
                          children: [
                            Container(width: 28, height: 3, color: C.volt),
                            const SizedBox(width: 10),
                            Text("VERIFIED M'LEMS. ANY HOUR.", style: figs(size: 12, weight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: S.gutter,
                  right: S.gutter,
                  bottom: pad.bottom + 32,
                  child: Opacity(
                    opacity: _seg(.85, 1),
                    child: Row(
                      children: [
                        Text('ALGER · ORAN · CONSTANTINE', style: figs(size: 10.5, color: C.inkSoft)),
                        const Spacer(),
                        Text('58 WILAYAS', style: figs(size: 10.5, color: C.inkSoft)),
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

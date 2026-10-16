import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../main.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'demo_links.dart';
import 'onboarding.dart';

/// Intro: the hex nut drops onto the bench and gets tightened a sixth of a
/// turn (one wrench click), then the wordmark slides out from behind it.
/// Plays once per launch, ~1.5s, skippable by tap.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _t;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _t ??= Timer(Duration(milliseconds: reduceMotion(context) ? 500 : 2100), _next);
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    Widget nut = const FixyMark(size: 84);
    Widget word = Text('fixy', style: display(size: 64, weight: FontWeight.w900));
    Widget tag = Text("Verified m'lems, near you.", style: mono(size: 13, color: C.inkSoft));
    if (!still) {
      nut = nut
          .animate()
          .moveY(begin: -40, end: 0, duration: 420.ms, curve: Curves.easeOutBack)
          .fadeIn(duration: 160.ms)
          .then(delay: 60.ms)
          .rotate(begin: -1 / 6, end: 0, duration: 340.ms, curve: M.spring)
          .shake(hz: 6, rotation: 0.01, duration: 160.ms);
      word = word
          .animate(delay: 760.ms)
          .fadeIn(duration: 200.ms)
          .moveX(begin: -36, end: 0, duration: 380.ms, curve: M.out)
          .blurXY(begin: 6, end: 0, duration: 260.ms);
      tag = tag.animate(delay: 1050.ms).fadeIn(duration: 260.ms).moveY(begin: 6, end: 0, curve: M.out);
    }
    return Scaffold(
      backgroundColor: C.paper,
      body: GestureDetector(
        onTap: _next,
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            const Positioned.fill(child: _BenchGrid()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      nut,
                      const SizedBox(width: 16),
                      ClipRect(child: word),
                    ],
                  ),
                  const SizedBox(height: 14),
                  tag,
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 36 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: Text('ALGER · ORAN · CONSTANTINE · 58 WILAYAS', style: mono(size: 10.5, color: C.inkSoft)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Faint cutting-mat grid, the "workbench" texture used behind hero moments.
class _BenchGrid extends StatelessWidget {
  const _BenchGrid({super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(painter: _GridPainter());
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = C.line.withValues(alpha: .6)
      ..strokeWidth = 1;
    const step = 28.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class BenchGrid extends _BenchGrid {
  const BenchGrid({super.key});
}

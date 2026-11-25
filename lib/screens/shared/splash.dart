import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'demo_links.dart';
import 'router.dart';

/// Screen 1: logo, name, French tagline, loading indicator.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1900), () async {
      if (!mounted) return;
      final s = context.read<AppState>();
      if (await openDemoLink(context, s)) return;
      if (mounted) goHome(context);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: C.navy,
        body: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _c,
                builder: (_, _) {
                  final t = still ? 1.0 : _c.value;
                  final reveal = Curves.easeOutBack.transform((t / .35).clamp(0, 1));
                  final draw = Curves.easeInOut.transform(((t - .2) / .5).clamp(0, 1));
                  final text = Curves.easeOut.transform(((t - .55) / .45).clamp(0, 1));
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FixyMark(size: 92, reveal: reveal, draw: draw, onDark: true),
                      const SizedBox(height: S.xl),
                      Opacity(
                        opacity: text,
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - text)),
                          child: Column(
                            children: [
                              Text(
                                'Fixy',
                                style: title(size: 40, weight: FontWeight.w800, color: C.white),
                              ),
                              const SizedBox(height: S.sm),
                              Text('Vos artisans de confiance en Algérie', style: body(size: 15.5, color: const Color(0xFFB7C4D3))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: Center(
                child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.4, color: C.turq)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

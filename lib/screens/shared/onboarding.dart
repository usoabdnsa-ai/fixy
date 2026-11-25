import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../auth/auth_screen.dart';
import 'router.dart';

class _Slide {
  const _Slide(this.photo, this.icon, this.title, this.text);
  final String photo;
  final IconData icon;
  final String title, text;
}

const _slides = [
  _Slide('assets/photos/plumb-1.jpg', PhosphorIconsBold.magnifyingGlass, 'Trouvez un artisan près de chez vous',
      'Plombiers, électriciens, peintres, serruriers… dans votre wilaya et votre commune.'),
  _Slide('assets/photos/elec-1.jpg', PhosphorIconsBold.star, 'Comparez les avis et les prix',
      'Des notes laissées par de vrais clients et des tarifs indicatifs en dinars (DA).'),
  _Slide('assets/photos/tools-1.jpg', PhosphorIconsBold.phoneCall, 'Appelez ou envoyez une demande',
      "Un appel direct, sans chat. Suivez chaque demande : en attente, acceptée, terminée."),
];

/// Screen 2: three swipeable slides, dots, "Commencer" and a login link.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  Future<void> _done({required bool login}) async {
    await context.read<AppState>().finishOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(AuthScreen(startOnLogin: login)));
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _i == _slides.length - 1;
    return Scaffold(
      backgroundColor: C.card,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pc,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _i = i),
              itemBuilder: (_, i) => _SlideView(_slides[i]),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.sm, S.gutter, S.lg),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var d = 0; d < _slides.length; d++)
                        AnimatedContainer(
                          duration: M.base,
                          curve: M.out,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: d == _i ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(color: d == _i ? C.turq : C.line, borderRadius: BorderRadius.circular(R.pill)),
                        ),
                    ],
                  ),
                  const SizedBox(height: S.xl),
                  Btn(
                    last ? 'Commencer' : 'Suivant',
                    icon: last ? null : PhosphorIconsBold.arrowRight,
                    onTap: () => last ? _done(login: false) : _pc.nextPage(duration: M.slow, curve: M.out),
                  ),
                  const SizedBox(height: S.sm),
                  Btn.ghost("J'ai déjà un compte · Se connecter", onTap: () => _done(login: true)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView(this.s);
  final _Slide s;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 11,
        child: Stack(
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              child: Image.asset(s.photo, fit: BoxFit.cover),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [C.navy.withValues(alpha: .35), C.navy.withValues(alpha: 0), C.navy.withValues(alpha: .55)],
                  stops: const [0, .4, 1],
                ),
              ),
            ),
            const Positioned(top: 0, left: S.gutter, child: SafeArea(child: Padding(padding: EdgeInsets.only(top: S.md), child: Wordmark(size: 22, onDark: true)))),
            Positioned(
              left: S.gutter,
              bottom: -24,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: C.turq, borderRadius: BorderRadius.circular(18), boxShadow: lift),
                child: Icon(s.icon, color: C.navy, size: 27),
              ),
            ),
          ],
        ),
      ),
      Expanded(
        flex: 6,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.gutter, 44, S.gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.title, style: title(size: 26)),
              const SizedBox(height: S.md),
              Text(s.text, style: body(size: 15.5, color: C.inkSoft)),
            ],
          ),
        ),
      ),
    ],
  );
}

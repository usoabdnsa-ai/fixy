import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../main.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'auth.dart';

/// Three slides, each one a picture of the product doing the thing,
/// with a one-line caption. No paragraphs.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _page = 0;

  static const _titles = [
    'Water on the floor?\nPost it in 30 seconds.',
    "Every m'lem is checked.\nNational ID, trade, reviews.",
    'Know the price\nbefore anyone comes.',
  ];

  void _finish() => Navigator.of(context).pushReplacement(fadeRoute(const AuthScreen()));

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: pad.top + 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: S.gutter),
                child: Row(
                  children: [
                    const Wordmark(size: 22),
                    const Spacer(),
                    Pressable(
                      onTap: _finish,
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          'Skip',
                          style: TextStyle(fontWeight: FontWeight.w700, color: C.inkSoft),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: S.md),
              // The slides play on a soft blue stage: a big rounded panel with
              // two faint circles, so each product moment floats in light.
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: S.gutter),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(32)),
                    child: Stack(
                      children: [
                        Positioned(right: -60, top: -40, child: _Blob(size: 220, color: C.volt.withValues(alpha: .08))),
                        Positioned(left: -50, bottom: -70, child: _Blob(size: 200, color: C.volt.withValues(alpha: .06))),
                        PageView(
                          controller: _pc,
                          onPageChanged: (i) => setState(() => _page = i),
                          children: const [_SlidePost(), _SlideVerified(), _SlideQuotes()],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: S.xl),
              Padding(
                padding: EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, pad.bottom + S.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: M.base,
                      switchInCurve: M.out,
                      transitionBuilder: (c, a) => FadeTransition(
                        opacity: a,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0, .15), end: Offset.zero).animate(a),
                          child: c,
                        ),
                      ),
                      child: Headline(
                        _titles[_page].split('\n').first,
                        key: ValueKey(_page),
                        style: display(size: 34, weight: FontWeight.w800).copyWith(height: 1.2),
                        accent: '\n${_titles[_page].split('\n').last}',
                        accentStyle: display(size: 34, weight: FontWeight.w800, color: C.isLight ? C.volt : C.inkSoft).copyWith(height: 1.2),
                      ),
                    ),
                    const SizedBox(height: S.xl),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedContainer(
                            duration: M.base,
                            curve: M.out,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _page ? 26 : 8,
                            height: 8,
                            decoration: BoxDecoration(color: i == _page ? C.volt : C.lineStrong, borderRadius: BorderRadius.circular(R.pill)),
                          ),
                        const Spacer(),
                        TagButton(
                          expand: false,
                          label: _page == 2 ? 'Get started' : 'Next',
                          icon: PhosphorIconsBold.arrowRight,
                          onTap: () => _page == 2 ? _finish() : _pc.nextPage(duration: M.slow, curve: M.inOut),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlidePost extends StatelessWidget {
  const _SlidePost();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 300,
        height: 340,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 20,
              top: 10,
              child: Transform.rotate(
                angle: -0.05,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.lg), boxShadow: lift),
                  child: const Photo('plumb-1', width: 240, height: 200, radius: R.md),
                ),
              ).animate().fadeIn(duration: 300.ms).scale(begin: const Offset(.94, .94), curve: M.out),
            ),
            Positioned(
              right: 0,
              bottom: 40,
              child: Transform.rotate(
                angle: 0.06,
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), boxShadow: lift),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(PhosphorIconsBold.pipeWrench, size: 16, color: C.volt),
                          const SizedBox(width: 6),
                          Text(
                            'Plumbing',
                            style: figs(size: 11, weight: FontWeight.w700, color: C.volt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Pipe burst under the sink', style: display(size: 19)),
                      const SizedBox(height: 8),
                      const UrgencyChip(Urgency.now),
                    ],
                  ),
                ),
              ).animate(delay: 250.ms).fadeIn(duration: 200.ms).moveY(begin: 30, end: 0, duration: 420.ms, curve: M.spring),
            ),
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.pill), boxShadow: glow),
                child: Row(
                  children: [
                    Icon(PhosphorIconsFill.bell, size: 14, color: C.onFill),
                    const SizedBox(width: 6),
                    Text(
                      "4 m'lems alerted within 3 km",
                      style: figs(size: 11, color: C.onFill, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ).animate(delay: 650.ms).fadeIn(duration: 220.ms).moveX(begin: -12, end: 0, curve: M.out),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideVerified extends StatelessWidget {
  const _SlideVerified();
  @override
  Widget build(BuildContext context) {
    final c = byId('c1');
    Widget row(String k, String v, int i) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(PhosphorIconsFill.checkCircle, size: 18, color: C.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(v, style: figs(size: 12, color: C.inkSoft)),
        ],
      ),
    ).animate(delay: (300 + i * 140).ms).fadeIn(duration: 200.ms).moveX(begin: 10, end: 0, curve: M.out);
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.lg), boxShadow: lift),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Avatar(craftsman: c, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                      Text('${c.trade.local} · ${c.commune}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: C.line, height: 1),
            const SizedBox(height: 6),
            row('National ID (NIN)', 'checked', 0),
            row('Trade certificate', 'CFPA 2011', 1),
            row('Client reviews', '${c.reviews.length} real jobs', 2),
            const SizedBox(height: 8),
            const Align(alignment: Alignment.centerRight, child: VerifiedStamp(animate: true)),
          ],
        ),
      ),
    );
  }
}

class _SlideQuotes extends StatelessWidget {
  const _SlideQuotes();
  @override
  Widget build(BuildContext context) {
    final quotes = [(byId('c2'), 4500, 'Tomorrow 9:00'), (byId('c7'), 5200, 'Saturday')];
    return Center(
      child: SizedBox(
        width: 310,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < quotes.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TagCard(
                  raised: i == 0,
                  child: Row(
                    children: [
                      Avatar(craftsman: quotes[i].$1, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quotes[i].$1.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(quotes[i].$3, style: figs(size: 11, color: C.inkSoft)),
                          ],
                        ),
                      ),
                      Text(dzd(quotes[i].$2), style: figs(size: 16, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ).animate(delay: (150 + i * 160).ms).fadeIn(duration: 220.ms).moveY(begin: 16, end: 0, curve: M.out),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(PhosphorIconsBold.lockSimple, size: 14, color: C.volt),
                const SizedBox(width: 6),
                Text(
                  'Price locked when you accept',
                  style: figs(size: 12, weight: FontWeight.w600, color: C.inkSoft),
                ),
              ],
            ).animate(delay: 520.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

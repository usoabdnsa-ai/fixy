import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import '../../data/mock.dart';
import '../../main.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'auth.dart';
import 'splash.dart';

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
          const Positioned.fill(child: BenchGrid()),
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
                      child: const Padding(
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
              Expanded(
                child: PageView(
                  controller: _pc,
                  onPageChanged: (i) => setState(() => _page = i),
                  children: const [_SlidePost(), _SlideVerified(), _SlideQuotes()],
                ),
              ),
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
                      child: Text(_titles[_page], key: ValueKey(_page), style: display(size: 30)),
                    ),
                    const SizedBox(height: S.xl),
                    Row(
                      children: [
                        for (var i = 0; i < 3; i++)
                          AnimatedContainer(
                            duration: M.base,
                            curve: M.out,
                            margin: const EdgeInsets.only(right: 6),
                            width: i == _page ? 28 : 8,
                            height: 8,
                            decoration: BoxDecoration(color: i == _page ? C.ink : C.lineStrong, borderRadius: BorderRadius.circular(R.pill)),
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
                  decoration: BoxDecoration(
                    color: C.card,
                    border: Border.all(color: C.ink, width: 2),
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  child: const Photo('plumb-1', width: 240, height: 200, radius: R.sm),
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
                  decoration: BoxDecoration(
                    color: C.orange,
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: C.ink, width: 2),
                    boxShadow: tagShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(PhosphorIconsBold.pipeWrench, size: 16),
                          const SizedBox(width: 6),
                          Text('PLUMBING', style: mono(size: 11, weight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Pipe burst under the sink', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('KOUBA · RIGHT NOW', style: mono(size: 10.5, weight: FontWeight.w600)),
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
                decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(R.pill)),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.bell, size: 14, color: C.orange),
                    const SizedBox(width: 6),
                    Text(
                      "4 m'lems alerted within 3 km",
                      style: mono(size: 11, color: C.paper, weight: FontWeight.w600),
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
          const Icon(PhosphorIconsFill.checkCircle, size: 18, color: C.teal),
          const SizedBox(width: 10),
          Expanded(
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Text(v, style: mono(size: 12, color: C.inkSoft)),
        ],
      ),
    ).animate(delay: (300 + i * 140).ms).fadeIn(duration: 200.ms).moveX(begin: 10, end: 0, curve: M.out);
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.lg),
          border: Border.all(color: C.ink, width: 2),
          boxShadow: tagShadow,
        ),
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
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      Text('${c.trade.local} · ${c.commune}', style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: C.line, height: 1),
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
                            Text(quotes[i].$3, style: mono(size: 11, color: C.inkSoft)),
                          ],
                        ),
                      ),
                      Text(dzd(quotes[i].$2), style: mono(size: 16, weight: FontWeight.w700)),
                    ],
                  ),
                ),
              ).animate(delay: (150 + i * 160).ms).fadeIn(duration: 220.ms).moveY(begin: 16, end: 0, curve: M.out),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsBold.lockSimple, size: 14, color: C.inkSoft),
                const SizedBox(width: 6),
                Text('Price locked when you accept', style: mono(size: 11.5, color: C.inkSoft)),
              ],
            ).animate(delay: 520.ms).fadeIn(),
          ],
        ),
      ),
    );
  }
}

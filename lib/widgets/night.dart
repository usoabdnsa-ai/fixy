import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import 'icons.dart';
import 'kit.dart';

// v2 "Night shift" building blocks: the bolt mark, scrambling headlines,
// the main-tab page frame and the volt wipe transition.

/// The Fixy mark: a volt square with a lightning bolt punched out of it.
/// [reveal] (0..1) wipes the square in from the left; [bolt] (0..1) cuts the bolt.
class FixyMark extends StatelessWidget {
  const FixyMark({super.key, this.size = 40, this.color, this.reveal = 1, this.bolt = 1});
  final double size;
  final Color? color;
  final double reveal;
  final double bolt;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BoltPainter(color ?? (C.isLight ? C.ink : C.volt), reveal, bolt));
}

Path boltPath(Size s) {
  final w = s.width, h = s.height;
  return Path()
    ..moveTo(w * .58, h * .14)
    ..lineTo(w * .26, h * .56)
    ..lineTo(w * .47, h * .56)
    ..lineTo(w * .40, h * .86)
    ..lineTo(w * .74, h * .42)
    ..lineTo(w * .53, h * .42)
    ..close();
}

class _BoltPainter extends CustomPainter {
  _BoltPainter(this.color, this.reveal, this.bolt);
  final Color color;
  final double reveal, bolt;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));
    final sq = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * .1)));
    if (bolt > 0) {
      final c = size.center(Offset.zero);
      final m = Matrix4.identity()
        ..translateByDouble(c.dx, c.dy, 0, 1)
        ..scaleByDouble(bolt, bolt, 1, 1)
        ..translateByDouble(-c.dx, -c.dy, 0, 1);
      sq.addPath(boltPath(size).transform(m.storage), Offset.zero);
      sq.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(sq, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BoltPainter o) => o.reveal != reveal || o.bolt != bolt || o.color != color;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26, this.color});
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FixyMark(size: size),
      SizedBox(width: size * 0.3),
      Text('FIXY', style: display(size: size * 1.05, color: color ?? C.ink, weight: FontWeight.w800).copyWith(height: 1, letterSpacing: 1)),
    ],
  );
}

const _glyphs = 'ABCDEFGHJKLMNPQRSTUVWXYZ0123456789#/+';

/// Uppercase condensed headline that "decodes": each letter cycles through
/// random glyphs before locking in, left to right. Runs once.
class Headline extends StatefulWidget {
  const Headline(this.text, {super.key, required this.style, this.accent, this.accentStyle, this.delay = Duration.zero});
  final String text;
  final TextStyle style;

  /// Trailing word(s) drawn in [accentStyle] (volt by default).
  final String? accent;
  final TextStyle? accentStyle;
  final Duration delay;

  @override
  State<Headline> createState() => _HeadlineState();
}

class _HeadlineState extends State<Headline> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _t = Duration.zero;
  final _rnd = math.Random(7);
  bool _still = false;

  static const _run = Duration(milliseconds: 650);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      setState(() => _t = d);
      if (d > _run + widget.delay) _ticker.stop();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = reduceMotion(context);
    if (!_still && !_ticker.isActive && _t == Duration.zero) _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  String _scramble(String s, int offset, int total) {
    if (_still) return s;
    final p = ((_t - widget.delay).inMilliseconds / _run.inMilliseconds).clamp(0.0, 1.0);
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      final lockAt = (offset + i) / math.max(total, 1) * .8 + .2;
      if (ch == ' ' || ch == '\n' || p >= lockAt) {
        b.write(ch);
      } else if (p <= 0) {
        b.write(' ');
      } else {
        b.write(_glyphs[_rnd.nextInt(_glyphs.length)]);
      }
    }
    return b.toString();
  }

  /// Night: accent words glow volt. Day: ink words on a volt marker stroke.
  TextStyle _accent() {
    final st = widget.accentStyle ?? widget.style.copyWith(color: C.volt);
    if (!C.isLight) return st;
    return st.copyWith(color: C.ink, background: Paint()..color = C.highlight);
  }

  @override
  Widget build(BuildContext context) {
    final main = widget.text.toUpperCase();
    final acc = widget.accent?.toUpperCase();
    final total = main.length + (acc?.length ?? 0) + 1;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: _scramble(main, 0, total), style: widget.style),
          if (acc != null) ...[
            TextSpan(text: ' ', style: widget.style),
            TextSpan(text: _scramble(acc, main.length + 1, total), style: _accent()),
          ],
        ],
      ),
    );
  }
}

/// Volt rule that draws itself under headlines.
class VoltRule extends StatelessWidget {
  const VoltRule({super.key, this.width = 56, this.delay = const Duration(milliseconds: 300)});
  final double width;
  final Duration delay;
  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return Container(width: width, height: 4, color: C.volt);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520) + delay,
      curve: Interval(delay.inMilliseconds / (520 + delay.inMilliseconds), 1, curve: M.out),
      builder: (_, v, _) => Container(width: width * v, height: 4, color: C.volt),
    );
  }
}

/// Blinking status dot (live / online).
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color, this.size = 8});
  final Color? color;
  final double size;
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!reduceMotion(context) && !_c.isAnimating) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => Opacity(
      opacity: _c.value < .5 ? 1 : .25,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(color: widget.color ?? (C.isLight ? C.teal : C.volt), shape: BoxShape.circle),
      ),
    ),
  );
}

/// Main-tab page: mono status line, a giant decoding headline with a volt
/// rule, then content. Once the headline scrolls away, a compact black bar
/// with a hairline takes over.
class TabPage extends StatefulWidget {
  const TabPage({
    super.key,
    required this.title,
    this.accent,
    this.eyebrow,
    this.subtitle,
    this.trailing,
    this.headerChild,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, S.xl),
  });
  final String title;
  final String? accent;
  final String? eyebrow;
  final String? subtitle;
  final Widget? trailing;
  final Widget? headerChild;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  State<TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<TabPage> {
  final _ctl = ScrollController();
  final _offset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => _offset.value = _ctl.offset);
  }

  @override
  void dispose() {
    _ctl.dispose();
    _offset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final full = (widget.accent == null ? widget.title : '${widget.title} ${widget.accent}').toUpperCase();
    return Stack(
      children: [
        CustomScrollView(
          controller: _ctl,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const LiveDot(),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.eyebrow ?? 'FIXY',
                            style: figs(size: 11.5, weight: FontWeight.w700, color: C.inkSoft).copyWith(letterSpacing: 1.2),
                          ),
                        ),
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                    const SizedBox(height: 22),
                    Headline(
                      widget.title,
                      accent: widget.accent,
                      style: display(size: 60, weight: FontWeight.w800),
                    ),
                    const SizedBox(height: 14),
                    const VoltRule(),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 14),
                      Text(widget.subtitle!, style: figs(size: 12.5, color: C.inkSoft)),
                    ],
                    if (widget.headerChild != null) ...[const SizedBox(height: S.xl), widget.headerChild!],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: widget.padding,
              sliver: SliverList.list(children: widget.children),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _offset,
            builder: (_, o, _) {
              final t = ((o - 90) / 40).clamp(0.0, 1.0);
              return IgnorePointer(
                ignoring: t < .5,
                child: Opacity(
                  opacity: t,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, 12),
                    decoration: BoxDecoration(
                      color: C.bg,
                      border: Border(bottom: BorderSide(color: C.line)),
                    ),
                    child: Row(
                      children: [
                        Container(width: 4, height: 18, color: C.volt),
                        const SizedBox(width: 10),
                        Text(full, style: display(size: 24, weight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Route transition: a volt band sweeps left to right, uncovering the new page.
Route<T> wipeRoute<T>(Widget page, {bool fullscreenDialog = false}) => PageRouteBuilder<T>(
  fullscreenDialog: fullscreenDialog,
  transitionDuration: const Duration(milliseconds: 460),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, a, _, child) {
    if (reduceMotion(context)) return FadeTransition(opacity: a, child: child);
    final c = CurvedAnimation(parent: a, curve: M.inOut, reverseCurve: Curves.easeIn);
    return AnimatedBuilder(
      animation: c,
      child: child,
      builder: (context, child) {
        final w = MediaQuery.sizeOf(context).width;
        final x = w * c.value;
        return Stack(
          children: [
            ClipRect(clipper: _LeftReveal(x), child: child),
            if (c.value < 1)
              Positioned(
                left: x - 10,
                top: 0,
                bottom: 0,
                width: 10,
                child: ColoredBox(color: C.volt),
              ),
          ],
        );
      },
    );
  },
);

class _LeftReveal extends CustomClipper<Rect> {
  _LeftReveal(this.x);
  final double x;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, x, size.height);
  @override
  bool shouldReclip(covariant _LeftReveal old) => old.x != x;
}

/// Faint scanlines + vignette for hero moments (splash, onboarding).
class Scanlines extends StatelessWidget {
  const Scanlines({super.key, this.opacity = .05});
  final double opacity;
  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _ScanPainter(opacity), size: Size.infinite));
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.opacity);
  final double opacity;
  final Color ink = C.ink;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = ink.withValues(alpha: opacity);
    for (var y = 0.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter o) => o.opacity != opacity || o.ink != ink;
}

/// Index label used in section heads and rows: "01".
String idx(int i) => (i + 1).toString().padLeft(2, '0');

/// Day / night switch: two mono segments, the active one filled.
/// Flipping it restyles every screen in place (see main.dart).
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key});
  @override
  Widget build(BuildContext context) {
    Widget seg(bool light, IconData icon, String label) {
      final on = C.isLight == light;
      return Expanded(
        child: Pressable(
          semanticLabel: '$label theme',
          onTap: () => C.light.value = light,
          child: AnimatedContainer(
            duration: M.fast,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: on ? C.volt : Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: on ? C.onFill : C.inkSoft),
                const SizedBox(width: 8),
                Text(label, style: figs(size: 12, weight: FontWeight.w700, color: on ? C.onFill : C.inkSoft).copyWith(letterSpacing: 1.2)),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.line, width: 1.5)),
      child: Row(
        children: [
          Icon(C.isLight ? PhosphorIconsBold.sun : PhosphorIconsBold.moon, size: 20),
          const SizedBox(width: 12),
          const Expanded(child: Text('Theme', style: TextStyle(fontWeight: FontWeight.w700))),
          SizedBox(
            width: 190,
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border.all(color: C.lineStrong)),
              child: Row(children: [seg(false, PhosphorIconsBold.moon, 'NIGHT'), seg(true, PhosphorIconsBold.sun, 'DAY')]),
            ),
          ),
        ],
      ),
    );
  }
}

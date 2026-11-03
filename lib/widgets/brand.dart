import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/tokens.dart';
import 'icons.dart';
import 'kit.dart';

// v3 "Trust blue" brand pieces: the house-and-check mark, friendly page
// headers, the slide transition and the theme switch.

/// The Fixy mark: a blue rounded tile holding a white house whose door is a
/// check mark ("home, fixed"). [reveal] (0..1) grows the tile in; [bolt]
/// (0..1) draws the check. Names kept from v2 so call sites still work.
class FixyMark extends StatelessWidget {
  const FixyMark({super.key, this.size = 40, this.color, this.reveal = 1, this.bolt = 1});
  final double size;
  final Color? color;
  final double reveal;
  final double bolt;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter(color ?? C.volt, reveal, bolt));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color, this.reveal, this.check);
  final Color color;
  final double reveal, check;

  @override
  void paint(Canvas canvas, Size s) {
    if (reveal <= 0) return;
    final w = s.width;
    canvas.save();
    final c = s.center(Offset.zero);
    canvas.translate(c.dx, c.dy);
    canvas.scale(reveal);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * .28)), Paint()..color = color);
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .085
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    // House outline: roof peak + walls.
    final house = Path()
      ..moveTo(w * .22, w * .48)
      ..lineTo(w * .5, w * .24)
      ..lineTo(w * .78, w * .48)
      ..moveTo(w * .3, w * .42)
      ..lineTo(w * .3, w * .76)
      ..lineTo(w * .7, w * .76)
      ..lineTo(w * .7, w * .42);
    canvas.drawPath(house, white);
    // The check, drawn progressively.
    if (check > 0) {
      final tick = Path()
        ..moveTo(w * .39, w * .58)
        ..lineTo(w * .47, w * .66)
        ..lineTo(w * .62, w * .51);
      for (final m in tick.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * check.clamp(0.0, 1.0)), white);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter o) => o.reveal != reveal || o.check != check || o.color != color;
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
      SizedBox(width: size * 0.32),
      Text(
        'fixy',
        style: GoogleFonts.plusJakartaSans(fontSize: size * .95, fontWeight: FontWeight.w800, color: color ?? C.ink, letterSpacing: -.8, height: 1),
      ),
    ],
  );
}

/// Headline with an optional accent word in brand blue. Rises in once.
class Headline extends StatelessWidget {
  const Headline(this.text, {super.key, required this.style, this.accent, this.accentStyle, this.delay = Duration.zero});
  final String text;
  final TextStyle style;
  final String? accent;
  final TextStyle? accentStyle;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final t = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text, style: style),
          if (accent != null) ...[
            TextSpan(text: ' ', style: style),
            TextSpan(
              text: accent,
              style: accentStyle ?? style.copyWith(color: C.isLight ? C.volt : const Color(0xFF7FA7FF)),
            ),
          ],
        ],
      ),
    );
    if (reduceMotion(context)) return t;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 480) + delay,
      curve: Interval(delay.inMilliseconds / (480 + delay.inMilliseconds), 1, curve: M.out),
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 10 * (1 - v)), child: child),
      ),
      child: t,
    );
  }
}

/// Kept for API compatibility; the trust-blue look has no rule under titles.
class VoltRule extends StatelessWidget {
  const VoltRule({super.key, this.width = 56, this.delay = Duration.zero});
  final double width;
  final Duration delay;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Live status dot with a soft expanding halo.
class LiveDot extends StatefulWidget {
  const LiveDot({super.key, this.color, this.size = 8});
  final Color? color;
  final double size;
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
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
  Widget build(BuildContext context) {
    final color = widget.color ?? C.teal;
    final s = widget.size;
    return SizedBox(
      width: s * 2,
      height: s * 2,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: s * (1 + _c.value),
              height: s * (1 + _c.value),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .35 * (1 - _c.value)),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: s,
              height: s,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Main-tab page: a soft blue wash at the top, a small eyebrow line, a
/// friendly bold title, then content. Once the title scrolls away a white
/// app bar with a shadow fades in.
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
    this.padding = const EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, S.xl),
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
    final full = widget.accent == null ? widget.title : '${widget.title} ${widget.accent}';
    return Stack(
      children: [
        // Soft wash behind the header; scrolls with the content.
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 320 + top,
          child: ValueListenableBuilder<double>(
            valueListenable: _offset,
            builder: (_, o, child) => Transform.translate(offset: Offset(0, -o.clamp(0.0, 400.0)), child: child),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.voltWash, C.bg]),
              ),
            ),
          ),
        ),
        CustomScrollView(
          controller: _ctl,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(S.gutter, top + 16, S.gutter, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.eyebrow ?? 'Fixy',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: C.inkSoft),
                          ),
                        ),
                        if (widget.trailing != null) widget.trailing!,
                      ],
                    ),
                    const SizedBox(height: 6),
                    Headline(
                      widget.title,
                      accent: widget.accent,
                      style: GoogleFonts.plusJakartaSans(fontSize: 30, fontWeight: FontWeight.w800, color: C.ink, height: 1.15, letterSpacing: -.8),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(widget.subtitle!, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: C.inkSoft)),
                    ],
                    if (widget.headerChild != null) ...[const SizedBox(height: S.lg + 4), widget.headerChild!],
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
              final t = ((o - 60) / 30).clamp(0.0, 1.0);
              return IgnorePointer(
                ignoring: t < .5,
                child: Opacity(
                  opacity: t,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, 14),
                    decoration: BoxDecoration(
                      color: C.card,
                      boxShadow: lift,
                      border: C.isLight ? null : Border(bottom: BorderSide(color: C.line)),
                    ),
                    child: Text(
                      full,
                      style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w700, color: C.ink),
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

/// Route transition: the new screen slides in from the right with a fade,
/// the old one drifts left a little. Full-screen dialogs rise from below.
Route<T> wipeRoute<T>(Widget page, {bool fullscreenDialog = false}) => PageRouteBuilder<T>(
  fullscreenDialog: fullscreenDialog,
  transitionDuration: const Duration(milliseconds: 380),
  reverseTransitionDuration: const Duration(milliseconds: 260),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (context, a, b, child) {
    if (reduceMotion(context)) return FadeTransition(opacity: a, child: child);
    final c = CurvedAnimation(parent: a, curve: M.out, reverseCurve: Curves.easeInCubic);
    final begin = fullscreenDialog ? const Offset(0, .12) : const Offset(.18, 0);
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-.06, 0)).animate(CurvedAnimation(parent: b, curve: M.out)),
      child: FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween(begin: begin, end: Offset.zero).animate(c),
          child: child,
        ),
      ),
    );
  },
);

/// Kept for API compatibility; no texture overlays in this theme.
class Scanlines extends StatelessWidget {
  const Scanlines({super.key, this.opacity = .05});
  final double opacity;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Index label: "01".
String idx(int i) => (i + 1).toString().padLeft(2, '0');

/// Light / dark switch: a pill with a sliding thumb.
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
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: on ? C.card : Colors.transparent, borderRadius: BorderRadius.circular(R.pill), boxShadow: on ? lift : null),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: on ? C.ink : C.inkSoft),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: on ? C.ink : C.inkSoft),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line),
      ),
      child: Row(
        children: [
          Icon(C.isLight ? PhosphorIconsBold.sun : PhosphorIconsBold.moon, size: 20, color: C.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Appearance',
              style: TextStyle(fontWeight: FontWeight.w700, color: C.ink),
            ),
          ),
          Container(
            width: 180,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.pill)),
            child: Row(children: [seg(true, PhosphorIconsBold.sun, 'Light'), seg(false, PhosphorIconsBold.moon, 'Dark')]),
          ),
        ],
      ),
    );
  }
}

/// OSM tile tint: light keeps the map natural but calmer, so blue routes and
/// pins stand out; dark inverts it to a slate night map.
List<double> get mapTint => C.isLight ? _dayTint : _nightTint;
const _dayTint = <double>[0.36, 0.5, 0.08, 0, 22, 0.28, 0.58, 0.08, 0, 22, 0.28, 0.5, 0.16, 0, 30, 0, 0, 0, 1, 0];
const _nightTint = <double>[-0.12, -0.2, -0.04, 0, 70, -0.1, -0.2, -0.04, 0, 78, -0.08, -0.16, -0.02, 0, 100, 0, 0, 0, 1, 0];

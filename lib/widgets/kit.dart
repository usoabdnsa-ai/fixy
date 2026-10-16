import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'icons.dart';

import '../data/models.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Native-feeling press: feedback lands on pointer-down (not on release),
/// scales to 0.97 over 120ms ease-out, light haptic on tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.haptic = true, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.lightImpact();
                widget.onTap!();
              },
        child: AnimatedScale(scale: _down ? widget.scale : 1, duration: M.press, curve: M.out, child: widget.child),
      ),
    );
  }
}

/// The primary action: an orange tool tag with a hard ink shadow that
/// "presses into the bench" (shadow collapses, tag drops 2px).
class TagButton extends StatefulWidget {
  const TagButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color = C.orange,
    this.textColor = C.ink,
    this.expand = true,
    this.loading = false,
    this.compact = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final bool expand;
  final bool loading;
  final bool compact;

  const TagButton.dark({super.key, required this.label, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false})
    : color = C.ink,
      textColor = C.paper;

  const TagButton.light({super.key, required this.label, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false})
    : color = C.card,
      textColor = C.ink;

  @override
  State<TagButton> createState() => _TagButtonState();
}

class _TagButtonState extends State<TagButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    final h = widget.compact ? 44.0 : 56.0;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: enabled
            ? () {
                HapticFeedback.mediumImpact();
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: M.press,
          curve: M.out,
          height: h,
          width: widget.expand ? double.infinity : null,
          transform: Matrix4.translationValues(0, _down ? 2 : 0, 0),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 22),
          decoration: BoxDecoration(
            color: enabled || widget.loading ? widget.color : C.line,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: C.ink, width: 2),
            boxShadow: !enabled ? null : (_down ? tagShadowPressed : tagShadow),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: M.fast,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: ScaleTransition(scale: Tween(begin: .8, end: 1.0).animate(a), child: c),
                ),
                child: widget.loading
                    ? SizedBox(
                        key: const ValueKey('l'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.textColor),
                      )
                    : Row(
                        key: const ValueKey('c'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[Icon(widget.icon, size: 20, color: enabled ? widget.textColor : C.inkSoft), const SizedBox(width: 10)],
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: widget.compact ? 14 : 16,
                              color: enabled ? widget.textColor : C.inkSoft,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A card with a 2px ink-tinted border; optional hard shadow for "tool tag" cards.
class TagCard extends StatelessWidget {
  const TagCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(S.lg), this.color = C.card, this.raised = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color color;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: raised ? C.ink : C.line, width: raised ? 2 : 1.5),
        boxShadow: raised ? tagShadow : null,
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, scale: 0.98, child: box);
  }
}

/// Initials on a trade-colored tag with a punched hole, like a key tag.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.craftsman, this.size = 52});
  final Craftsman craftsman;
  final double size;

  static const _tints = [Color(0xFFFFD2BF), Color(0xFFCFE5DE), Color(0xFFF3E0B5), Color(0xFFE2D7F0), Color(0xFFD6E4F5), Color(0xFFF1D4D4)];

  @override
  Widget build(BuildContext context) {
    final tint = _tints[craftsman.trade.index % _tints.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: C.ink, width: 1.5),
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.1,
            right: size * 0.1,
            child: Container(
              width: size * 0.13,
              height: size * 0.13,
              decoration: BoxDecoration(
                color: C.paper,
                shape: BoxShape.circle,
                border: Border.all(color: C.ink, width: 1.2),
              ),
            ),
          ),
          Center(
            child: Text(
              craftsman.initials,
              style: display(size: size * 0.36, weight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rubber-stamp "VERIFIED" badge. Stamps in once (scale from 1.5 + slight
/// rotation settle) the first time it is built with [animate].
class VerifiedStamp extends StatelessWidget {
  const VerifiedStamp({super.key, this.small = false, this.animate = false});
  final bool small;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final w = Transform.rotate(
      angle: -0.06,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 5 : 8, vertical: small ? 1 : 3),
        decoration: BoxDecoration(
          border: Border.all(color: C.teal, width: small ? 1.5 : 2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIconsFill.sealCheck, size: small ? 11 : 14, color: C.teal),
            SizedBox(width: small ? 3 : 4),
            Text(
              'VERIFIED',
              style: mono(size: small ? 9.5 : 11, weight: FontWeight.w700, color: C.teal),
            ),
          ],
        ),
      ),
    );
    if (!animate || reduceMotion(context)) return w;
    return w
        .animate()
        .scale(begin: const Offset(1.6, 1.6), end: const Offset(1, 1), duration: 380.ms, curve: M.spring)
        .rotate(begin: -0.03, end: 0, duration: 380.ms, curve: M.out)
        .fadeIn(duration: 120.ms);
  }
}

class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 14});
  final double value;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIconsFill.star, size: size, color: C.orange),
        const SizedBox(width: 3),
        Text(
          value == 0 ? 'New' : value.toStringAsFixed(1),
          style: mono(size: size - 1, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final JobStatus status;
  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      JobStatus.pending => (C.amberWash, C.amber),
      JobStatus.quoted => (C.orangeWash, C.rust),
      JobStatus.accepted => (C.tealWash, C.teal),
      JobStatus.inProgress => (C.ink, C.paper),
      JobStatus.completed => (C.line, C.ink),
      JobStatus.cancelled => (C.redWash, C.red),
    };
    return AnimatedContainer(
      duration: M.base,
      curve: M.out,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Text(
        status.label.toUpperCase(),
        style: mono(size: 10.5, weight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class UrgencyChip extends StatelessWidget {
  const UrgencyChip(this.urgency, {super.key});
  final Urgency urgency;
  @override
  Widget build(BuildContext context) {
    final hot = urgency == Urgency.now;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: hot ? C.orange : C.paper,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: hot ? C.ink : C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hot) ...[const Icon(PhosphorIconsBold.siren, size: 12, color: C.ink), const SizedBox(width: 4)],
          Text(urgency.label.toUpperCase(), style: mono(size: 10.5, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class Photo extends StatelessWidget {
  const Photo(this.name, {super.key, this.radius = R.md, this.height, this.width});
  final String name;
  final double radius;
  final double? height;
  final double? width;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset('assets/photos/$name.jpg', fit: BoxFit.cover, height: height, width: width, cacheWidth: 600),
    );
  }
}

class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, S.md),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: display(size: 19, weight: FontWeight.w800)),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: Text(
                  action!,
                  style: const TextStyle(fontWeight: FontWeight.w700, color: C.rust, fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, this.onTap, this.label, this.bg = C.card});
  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final Color bg;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.92,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: C.line, width: 1.5),
        ),
        child: Icon(icon, size: 20, color: C.ink),
      ),
    );
  }
}

/// Shimmering placeholder block for loading states.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.height = 16, this.width = double.infinity, this.radius = R.sm});
  final double height;
  final double width;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      height: height,
      width: width,
      decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(radius)),
    );
    if (reduceMotion(context)) return box;
    return box.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1100.ms, color: C.card.withValues(alpha: .7));
  }
}

/// The Fixy mark: a hex nut. On the splash it is "tightened" a sixth of a turn.
class FixyMark extends StatelessWidget {
  const FixyMark({super.key, this.size = 40, this.color = C.orange, this.ink = C.ink});
  final double size;
  final Color color;
  final Color ink;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _NutPainter(color, ink));
}

class _NutPainter extends CustomPainter {
  _NutPainter(this.color, this.ink);
  final Color color;
  final Color ink;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i - math.pi / 6;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    final hole = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.38));
    final shape = Path.combine(PathOperation.difference, hex, hole);
    canvas.drawPath(shape, Paint()..color = color);
    canvas.drawPath(
      shape,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.06
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _NutPainter old) => old.color != color || old.ink != ink;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26, this.color = C.ink});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FixyMark(size: size * 1.05, ink: color),
      SizedBox(width: size * 0.3),
      Text(
        'fixy',
        style: display(size: size, color: color, weight: FontWeight.w900),
      ),
    ],
  );
}

/// Staggered entrance used for lists: 8px rise + fade, 45ms apart, capped so
/// long lists don't keep the user waiting.
extension Entrance on Widget {
  Widget enter(BuildContext context, int index, {double dy = 10}) {
    if (reduceMotion(context)) return this;
    final i = math.min(index, 8);
    return animate(delay: M.stagger * i).fadeIn(duration: M.base, curve: M.out).moveY(begin: dy, end: 0, duration: M.base, curve: M.out);
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
}

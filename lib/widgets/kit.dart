import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'icons.dart';

export 'brand.dart';

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

/// The primary action: a rounded trust-blue button with a soft brand shadow.
/// [TagButton.dark] is the tinted secondary, [TagButton.light] the outlined tertiary.
class TagButton extends StatefulWidget {
  const TagButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.color,
    this.textColor,
    this.expand = true,
    this.loading = false,
    this.compact = false,
  }) : _kind = 0;
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? color;
  final Color? textColor;
  final int _kind; // 0 primary, 1 secondary, 2 tertiary

  Color get fillColor =>
      color ??
      switch (_kind) {
        1 => C.voltWash,
        2 => C.card,
        _ => C.volt,
      };
  Color get labelColor =>
      textColor ??
      switch (_kind) {
        1 => C.isLight ? C.volt : C.ink,
        2 => C.ink,
        _ => C.onFill,
      };
  final bool expand;
  final bool loading;
  final bool compact;

  const TagButton.dark({super.key, required this.label, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false})
    : color = null,
      textColor = null,
      _kind = 1;

  const TagButton.light({super.key, required this.label, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false})
    : color = null,
      textColor = null,
      _kind = 2;

  @override
  State<TagButton> createState() => _TagButtonState();
}

class _TagButtonState extends State<TagButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    final h = widget.compact ? 48.0 : 56.0;
    final outline = widget._kind == 2 || widget.fillColor == C.card;
    final primary = widget.fillColor == C.volt;
    final fill = !enabled && !widget.loading ? C.line : widget.fillColor;
    final fg = !enabled && !widget.loading ? C.inkSoft : widget.labelColor;
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
        child: AnimatedScale(
          scale: _down ? .97 : 1,
          duration: M.press,
          curve: M.out,
          child: AnimatedContainer(
            duration: M.fast,
            curve: M.out,
            height: h,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: widget.compact ? 16 : 22),
            decoration: BoxDecoration(
              color: _down && enabled ? Color.lerp(fill, C.ink, .08) : fill,
              borderRadius: BorderRadius.circular(R.md - 2),
              border: outline ? Border.all(color: C.lineStrong) : null,
              boxShadow: enabled && primary && !_down ? glow : null,
            ),
            child: Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.loading)
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.labelColor))
                else ...[
                  if (widget.icon != null && widget.icon != PhosphorIconsBold.arrowRight) ...[
                    Icon(widget.icon, size: 19, color: fg),
                    const SizedBox(width: 10),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: widget.compact ? 14.5 : 16, fontWeight: FontWeight.w700, color: fg),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// White card with a soft shadow (light) or a border (dark). [raised] lifts it a bit more.
class TagCard extends StatelessWidget {
  const TagCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(S.lg), this.color, this.raised = false});
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final Color? color;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? C.card,
        borderRadius: BorderRadius.circular(R.md + 2),
        border: C.isLight
            ? Border.all(color: raised ? Colors.transparent : C.line.withValues(alpha: .7))
            : Border.all(color: raised ? C.volt.withValues(alpha: .5) : C.line),
        boxShadow: lift,
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, scale: 0.98, child: box);
  }
}

/// Round avatar: initials on a soft tint picked by trade, with a white ring.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.craftsman, this.size = 52});
  final Craftsman craftsman;
  final double size;

  static const _tints = [
    (Color(0xFFDBEAFE), Color(0xFF1E40AF)),
    (Color(0xFFFEF3C7), Color(0xFF92400E)),
    (Color(0xFFDCFCE7), Color(0xFF166534)),
    (Color(0xFFFCE7F3), Color(0xFF9D174D)),
    (Color(0xFFEDE9FE), Color(0xFF5B21B6)),
    (Color(0xFFFFEDD5), Color(0xFF9A3412)),
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tints[craftsman.id.codeUnits.fold(0, (a, b) => a + b) % _tints.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: C.card, width: size > 40 ? 2.5 : 1.5),
        boxShadow: C.isLight ? const [BoxShadow(color: Color(0x1A0F172A), blurRadius: 6, offset: Offset(0, 2))] : null,
      ),
      child: Text(
        craftsman.initials,
        style: GoogleFonts.plusJakartaSans(fontSize: size * .34, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// "Verified" pill: green seal + label.
class VerifiedStamp extends StatelessWidget {
  const VerifiedStamp({super.key, this.small = false, this.animate = false});
  final bool small;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final w = Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 8, vertical: small ? 2 : 3),
      decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsFill.sealCheck, size: small ? 12 : 14, color: C.teal),
          SizedBox(width: small ? 3 : 4),
          Text(
            'Verified',
            style: GoogleFonts.plusJakartaSans(fontSize: small ? 11 : 12, fontWeight: FontWeight.w700, color: C.teal),
          ),
        ],
      ),
    );
    if (!animate || reduceMotion(context)) return w;
    return w.animate().fadeIn(duration: 160.ms).scale(begin: const Offset(.8, .8), duration: 320.ms, curve: M.spring);
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
        Icon(PhosphorIconsFill.star, size: size, color: C.star),
        const SizedBox(width: 3),
        Text(
          value == 0 ? 'New' : value.toStringAsFixed(1),
          style: figs(size: size - 1.5, weight: FontWeight.w700),
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
      JobStatus.quoted => (C.voltWash, C.isLight ? C.volt : C.ink),
      JobStatus.accepted => (C.tealWash, C.teal),
      JobStatus.inProgress => (C.volt, C.onFill),
      JobStatus.completed => (C.line, C.inkSoft),
      JobStatus.cancelled => (C.redWash, C.red),
    };
    return AnimatedContainer(
      duration: M.base,
      curve: M.out,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Text(
        status.label,
        style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: hot ? C.hotWash : C.line.withValues(alpha: .6), borderRadius: BorderRadius.circular(R.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hot) ...[Icon(PhosphorIconsBold.lightning, size: 12, color: C.hotText), const SizedBox(width: 3)],
          Text(
            urgency.label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: hot ? C.hotText : C.inkSoft),
          ),
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

/// Section head: bold title, optional blue "See all" action. [index] is ignored (kept for API).
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.action, this.onAction, this.index});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final int? index;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.gutter, S.xl + 4, S.gutter, S.md),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w700, color: C.ink, letterSpacing: -.2),
            ),
          ),
          if (action != null)
            Pressable(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  action!,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: C.isLight ? C.volt : C.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Round icon button on a white disc with a soft shadow.
class IconCircle extends StatelessWidget {
  const IconCircle({super.key, required this.icon, this.onTap, this.label, this.bg});
  final IconData icon;
  final VoidCallback? onTap;
  final String? label;
  final Color? bg;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      scale: 0.9,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: bg == null || bg == C.bg ? C.card : bg,
          shape: BoxShape.circle,
          border: C.isLight ? null : Border.all(color: C.line),
          boxShadow: lift,
        ),
        child: Icon(icon, size: 20, color: C.ink),
      ),
    );
  }
}

/// Loading placeholder with a soft blue shimmer.
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

/// Staggered entrance: items rise 12px and fade in, 45ms apart, capped.
extension Entrance on Widget {
  Widget enter(BuildContext context, int index, {double dy = 12}) {
    if (reduceMotion(context)) return this;
    final i = math.min(index, 8);
    return animate(delay: 60.ms + M.stagger * i).fadeIn(duration: 220.ms).moveY(begin: dy == 0 ? 12 : dy, end: 0, duration: 420.ms, curve: M.out);
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.md)),
      ),
    );
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'icons.dart';

export 'night.dart';

import 'night.dart';

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

/// The primary action: a flat volt slab, uppercase condensed label, arrow.
/// On press it flips to outline (volt border, volt label) for 90ms.
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

  /// Resolved at build time so the button follows the day/night palette.
  Color get fillColor => color ?? switch (_kind) { 1 => C.isLight ? C.highlight : C.ink, 2 => C.card, _ => C.volt };
  Color get labelColor => textColor ?? switch (_kind) { 1 => C.isLight ? C.ink : C.onFill, 2 => C.ink, _ => C.onFill };
  final bool expand;
  final bool loading;
  final bool compact;

  /// Secondary: light slab with dark label (night) / volt slab with ink label (day).
  const TagButton.dark({super.key, required this.label, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false})
    : color = null,
      textColor = null,
      _kind = 1;

  /// Tertiary: outlined, transparent.
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
    final h = widget.compact ? 44.0 : 56.0;
    final outline = widget._kind == 2 || widget.fillColor == C.card;
    final fill = !enabled && !widget.loading ? C.line : (_down ? C.bg : widget.fillColor);
    final fg = !enabled && !widget.loading ? C.inkSoft : (_down ? (outline ? C.volt : widget.fillColor) : widget.labelColor);
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
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 14 : 20),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(color: outline ? C.lineStrong : (_down ? widget.fillColor : fill), width: 1.5),
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: widget.expand ? MainAxisAlignment.spaceBetween : MainAxisAlignment.center,
            children: [
              if (widget.loading)
                SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: widget.labelColor))
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null && widget.icon != PhosphorIconsBold.arrowRight) ...[Icon(widget.icon, size: 19, color: fg), const SizedBox(width: 10)],
                    Text(
                      widget.label.toUpperCase(),
                      style: display(size: widget.compact ? 17 : 20, weight: FontWeight.w700, color: fg).copyWith(letterSpacing: .6),
                    ),
                  ],
                ),
              if (widget.expand && !widget.loading) ...[
                const SizedBox(width: 8),
                Icon(PhosphorIconsBold.arrowRight, size: 18, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark surface with a hairline. [raised] swaps the hairline for a volt edge on the left.
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
        borderRadius: BorderRadius.circular(R.md),
        border: raised ? Border(left: BorderSide(color: C.volt, width: 3), top: BorderSide(color: C.line), right: BorderSide(color: C.line), bottom: BorderSide(color: C.line)) : Border.all(color: C.line),
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, scale: 0.985, child: box);
  }
}

/// Initials in mono on a square tile; the corner notch is tinted by trade.
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.craftsman, this.size = 52});
  final Craftsman craftsman;
  final double size;

  static List<Color> get _tints => [C.volt, C.hot, C.teal, C.amber, Color(0xFFB69CFF), Color(0xFF5CC8FF)];

  @override
  Widget build(BuildContext context) {
    final tint = _tints[craftsman.trade.index % _tints.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.lineStrong),
      ),
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: Container(width: size * .22, height: size * .22, color: tint)),
          Center(
            child: Text(craftsman.initials, style: figs(size: size * .3, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// "VERIFIED" tag: teal check + mono caps. Slides in once with [animate].
class VerifiedStamp extends StatelessWidget {
  const VerifiedStamp({super.key, this.small = false, this.animate = false});
  final bool small;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final w = Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 5 : 7, vertical: small ? 2 : 3),
      decoration: BoxDecoration(
        color: C.tealWash,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.teal.withValues(alpha: .4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIconsBold.sealCheck, size: small ? 11 : 13, color: C.teal),
          SizedBox(width: small ? 3 : 5),
          Text('VERIFIED', style: figs(size: small ? 9.5 : 11, weight: FontWeight.w700, color: C.teal)),
        ],
      ),
    );
    if (!animate || reduceMotion(context)) return w;
    return w.animate().fadeIn(duration: 120.ms).moveX(begin: 12, end: 0, duration: 380.ms, curve: M.out);
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
        Icon(PhosphorIconsFill.star, size: size, color: C.volt),
        const SizedBox(width: 4),
        Text(
          value == 0 ? 'NEW' : value.toStringAsFixed(1),
          style: figs(size: size - 1, weight: FontWeight.w700),
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
      JobStatus.quoted => (C.voltWash, C.volt),
      JobStatus.accepted => (C.tealWash, C.teal),
      JobStatus.inProgress => (C.volt, C.onFill),
      JobStatus.completed => (C.line, C.ink),
      JobStatus.cancelled => (C.redWash, C.red),
    };
    return AnimatedContainer(
      duration: M.base,
      curve: M.out,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.sm)),
      child: Text(
        status.label.toUpperCase(),
        style: figs(size: 10.5, weight: FontWeight.w700, color: fg),
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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: hot ? C.hot : Colors.transparent,
        borderRadius: BorderRadius.circular(R.sm),
        border: hot ? null : Border.all(color: C.lineStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hot) ...[Icon(PhosphorIconsBold.siren, size: 12, color: C.onFill), const SizedBox(width: 4)],
          Text(urgency.label.toUpperCase(), style: figs(size: 10.5, weight: FontWeight.w700, color: hot ? C.onFill : C.inkSoft)),
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

/// Section head: hairline, condensed caps title, mono volt action.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.action, this.onAction, this.index});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final int? index;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(S.gutter, S.xxl, S.gutter, S.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (index != null) ...[
                Text(idx(index!), style: figs(size: 12, weight: FontWeight.w700, color: C.volt)),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title.toUpperCase(), style: display(size: 26, weight: FontWeight.w800)),
              ),
              if (action != null)
                Pressable(
                  onTap: onAction,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Text('${action!.toUpperCase()} →', style: figs(size: 11.5, weight: FontWeight.w700, color: C.volt)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: C.line),
        ],
      ),
    );
  }
}

/// Square icon button with a hairline.
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: bg == null || bg == C.bg ? C.card : bg,
          borderRadius: BorderRadius.circular(R.sm),
          border: Border.all(color: C.lineStrong),
        ),
        child: Icon(icon, size: 20, color: C.ink),
      ),
    );
  }
}

/// Loading placeholder: a dark bar with a volt-tinted sweep.
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
    return box.animate(onPlay: (c) => c.repeat()).shimmer(duration: 1000.ms, color: C.volt.withValues(alpha: .12));
  }
}

/// Staggered entrance: rows slide in from the left with a quick fade, 40ms
/// apart, capped so long lists don't keep the user waiting.
extension Entrance on Widget {
  Widget enter(BuildContext context, int index, {double dy = 0}) {
    if (reduceMotion(context)) return this;
    final i = math.min(index, 8);
    return animate(delay: 80.ms + M.stagger * i)
        .fadeIn(duration: 160.ms)
        .moveX(begin: -24, end: 0, duration: 380.ms, curve: M.out)
        .moveY(begin: dy, end: 0, duration: 380.ms, curve: M.out);
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg.toUpperCase()), duration: const Duration(seconds: 2)));
}

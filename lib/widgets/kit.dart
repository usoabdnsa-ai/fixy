import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/models.dart';
import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../util/format.dart';
import 'icons.dart';

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Press feedback on pointer-down: scale to 0.97, light haptic on tap.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.scale = 0.97, this.semanticLabel});
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap != null && _down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) => Semantics(
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
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      child: AnimatedScale(scale: _down ? widget.scale : 1, duration: M.press, curve: M.out, child: widget.child),
    ),
  );
}

enum BtnKind { primary, accent, outline, ghost, danger }

/// Buttons. primary = navy fill; accent = turquoise fill with navy label
/// (used for "Appeler"); outline = white with border; ghost = text only.
class Btn extends StatelessWidget {
  const Btn(this.label, {super.key, this.onTap, this.icon, this.kind = BtnKind.primary, this.expand = true, this.loading = false, this.compact = false});
  const Btn.accent(this.label, {super.key, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false}) : kind = BtnKind.accent;
  const Btn.outline(this.label, {super.key, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false}) : kind = BtnKind.outline;
  const Btn.ghost(this.label, {super.key, this.onTap, this.icon, this.expand = false, this.loading = false, this.compact = true}) : kind = BtnKind.ghost;
  const Btn.danger(this.label, {super.key, this.onTap, this.icon, this.expand = true, this.loading = false, this.compact = false}) : kind = BtnKind.danger;

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final BtnKind kind;
  final bool expand, loading, compact;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (kind) {
      BtnKind.primary => (C.navy, C.white, C.navy),
      BtnKind.accent => (C.turq, C.navy, C.turq),
      BtnKind.outline => (C.card, C.ink, C.lineStrong),
      BtnKind.ghost => (Colors.transparent, C.turqText, Colors.transparent),
      BtnKind.danger => (C.card, C.red, const Color(0xFFF3C7C7)),
    };
    final disabled = onTap == null && !loading;
    final h = compact ? 42.0 : 52.0;
    final child = AnimatedOpacity(
      duration: M.fast,
      opacity: disabled ? .45 : 1,
      child: Container(
        height: h,
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: border, width: kind == BtnKind.outline || kind == BtnKind.danger ? 1.2 : 0),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
            else ...[
              if (icon != null) ...[Icon(icon, size: compact ? 17 : 19, color: fg), const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(size: compact ? 14 : 15.5, weight: FontWeight.w700, color: fg),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Pressable(onTap: loading ? null : onTap, semanticLabel: label, child: child);
  }
}

// ---------------------------------------------------------------- brand

/// The Fixy mark from the spec ("house-wrench logo"): a navy rounded tile
/// with a white house outline and a turquoise wrench as the door.
/// [reveal] grows the tile in, [draw] traces the strokes.
class FixyMark extends StatelessWidget {
  const FixyMark({super.key, this.size = 40, this.reveal = 1, this.draw = 1, this.onDark = false});
  final double size, reveal, draw;
  final bool onDark;
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _MarkPainter(reveal, draw, onDark));
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.reveal, this.draw, this.onDark);
  final double reveal, draw;
  final bool onDark;

  @override
  void paint(Canvas canvas, Size s) {
    if (reveal <= 0) return;
    final w = s.width;
    final c = s.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(reveal);
    canvas.translate(-c.dx, -c.dy);
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(w * .28)), Paint()..color = onDark ? C.turq : C.navy);
    final stroke = Paint()
      ..color = onDark ? C.navy : C.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final house = Path()
      ..moveTo(w * .2, w * .47)
      ..lineTo(w * .5, w * .22)
      ..lineTo(w * .8, w * .47)
      ..moveTo(w * .29, w * .41)
      ..lineTo(w * .29, w * .77)
      ..lineTo(w * .71, w * .77)
      ..lineTo(w * .71, w * .41);
    for (final m in house.computeMetrics()) {
      canvas.drawPath(m.extractPath(0, m.length * draw.clamp(0.0, 1.0)), stroke);
    }
    // Wrench: a short diagonal handle ending in an open jaw.
    if (draw > .5) {
      final t = ((draw - .5) * 2).clamp(0.0, 1.0);
      final wrench = Paint()
        ..color = onDark ? C.navy : C.turq
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .075
        ..strokeCap = StrokeCap.round;
      final a = Offset(w * .4, w * .69), b = Offset(w * .545, w * .545);
      canvas.drawLine(a, Offset.lerp(a, b, t)!, wrench);
      if (t > .6) {
        // Open jaw facing up-right, away from the handle: arc from 15° to 255°.
        final jaw = Path()..addArc(Rect.fromCircle(center: Offset(w * .6, w * .49), radius: w * .08), 0.26, 4.19);
        canvas.drawPath(jaw, wrench);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MarkPainter o) => o.reveal != reveal || o.draw != draw || o.onDark != onDark;
}

class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = 26, this.onDark = false});
  final double size;
  final bool onDark;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      FixyMark(size: size * 1.15, onDark: onDark),
      SizedBox(width: size * .35),
      Text(
        'Fixy',
        style: title(size: size, weight: FontWeight.w800, color: onDark ? C.white : C.ink),
      ),
    ],
  );
}

// ---------------------------------------------------------------- surfaces

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(S.lg), this.onTap, this.color = C.card, this.border = false});
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color color;
  final bool border;
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(R.md),
        boxShadow: border ? null : lift,
        border: border ? Border.all(color: C.line) : null,
      ),
      child: child,
    );
    return onTap == null ? box : Pressable(onTap: onTap, scale: .985, child: box);
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, this.size = 40, this.color = C.navy, this.wash = C.turqWash});
  final IconData icon;
  final double size;
  final Color color, wash;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: wash, borderRadius: BorderRadius.circular(size * .3)),
    child: Icon(icon, size: size * .5, color: color),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.md),
    child: Row(
      children: [
        Expanded(child: Text(text, style: title(size: 18))),
        if (action != null)
          Pressable(
            onTap: onAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Text(
                action!,
                style: body(size: 14, weight: FontWeight.w700, color: C.turqText),
              ),
            ),
          ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.text, this.action, this.onAction});
  final IconData icon;
  final String title, text;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => _build(title);

  Widget _build(String heading) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: S.xl, vertical: S.xxl),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconTile(icon: icon, size: 64),
        const SizedBox(height: S.lg),
        Text(heading, textAlign: TextAlign.center, style: title_(18)),
        const SizedBox(height: S.sm),
        Text(
          text,
          textAlign: TextAlign.center,
          style: body(size: 14.5, color: C.inkSoft),
        ),
        if (action != null) ...[const SizedBox(height: S.lg), Btn(action!, onTap: onAction, expand: false, compact: true)],
      ],
    ),
  );
}

TextStyle title_(double size) => title(size: size);

// ---------------------------------------------------------------- people & photos

/// Photo stored as an asset path or as base64 JPEG bytes.
class StoredImage extends StatelessWidget {
  const StoredImage(this.data, {super.key, this.fit = BoxFit.cover, this.width, this.height});
  final String data;
  final BoxFit fit;
  final double? width, height;

  static final _cache = <int, Uint8List>{};

  @override
  Widget build(BuildContext context) {
    if (data.startsWith('assets/')) return Image.asset(data, fit: fit, width: width, height: height);
    final bytes = _cache.putIfAbsent(data.hashCode, () => base64Decode(data));
    return Image.memory(bytes, fit: fit, width: width, height: height, gaplessPlayback: true);
  }
}

/// Provider or user picture. With no photo it shows the spec's default silhouette.
class Avatar extends StatelessWidget {
  const Avatar({super.key, this.photo, this.size = 48, this.ring = false});
  final String? photo;
  final double size;
  final bool ring;
  @override
  Widget build(BuildContext context) {
    final has = photo != null && photo!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      padding: ring ? const EdgeInsets.all(3) : EdgeInsets.zero,
      decoration: BoxDecoration(shape: BoxShape.circle, color: ring ? C.white : null, boxShadow: ring ? lift : null),
      child: ClipOval(
        child: has
            ? StoredImage(photo!)
            : Container(
                color: const Color(0xFFDCE3EA),
                alignment: Alignment.bottomCenter,
                child: CustomPaint(size: Size.square(size), painter: _Silhouette()),
              ),
      ),
    );
  }
}

class _Silhouette extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()..color = const Color(0xFF9AA8B8);
    final w = s.width;
    canvas.drawCircle(Offset(w / 2, w * .4), w * .19, p);
    canvas.drawOval(Rect.fromCenter(center: Offset(w / 2, w * 1.02), width: w * .78, height: w * .66), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => compact
      ? const Icon(PhosphorIconsFill.sealCheck, size: 17, color: C.turq, semanticLabel: 'Vérifié')
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: C.turqWash, borderRadius: BorderRadius.circular(R.pill)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(PhosphorIconsFill.sealCheck, size: 14, color: C.turqText),
              const SizedBox(width: 4),
              Text(
                'Vérifié',
                style: body(size: 12, weight: FontWeight.w700, color: C.turqText),
              ),
            ],
          ),
        );
}

// ---------------------------------------------------------------- ratings & status

class Stars extends StatelessWidget {
  const Stars(this.value, {super.key, this.size = 14});
  final double value;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 1; i <= 5; i++)
        Icon(
          value >= i - .25 ? PhosphorIconsFill.star : (value >= i - .75 ? PhosphorIconsFill.starHalf : PhosphorIconsBold.star),
          size: size,
          color: value >= i - .75 ? C.star : C.lineStrong,
        ),
    ],
  );
}

/// "★ 4,8 (12)".
class RatingLine extends StatelessWidget {
  const RatingLine(this.summary, {super.key, this.size = 13.5});
  final RatingSummary summary;
  final double size;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(PhosphorIconsFill.star, size: size + 1, color: C.star),
      const SizedBox(width: 3),
      if (summary.count == 0)
        Text(
          'Nouveau',
          style: body(size: size, weight: FontWeight.w600, color: C.inkSoft),
        )
      else ...[
        Text(
          rating1(summary.average),
          style: figs(size: size, weight: FontWeight.w700),
        ),
        Text(
          ' (${summary.count})',
          style: figs(size: size, weight: FontWeight.w500, color: C.inkSoft),
        ),
      ],
    ],
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.refused = false});
  final RequestStatus status;
  final bool refused;
  @override
  Widget build(BuildContext context) {
    final (fg, bg, icon) = switch (status) {
      RequestStatus.enAttente => (C.amber, C.amberWash, PhosphorIconsBold.hourglass),
      RequestStatus.acceptee => (C.blue, C.blueWash, PhosphorIconsBold.check),
      RequestStatus.terminee => (C.green, C.greenWash, PhosphorIconsBold.checkCircle),
      RequestStatus.annulee => (C.red, C.redWash, PhosphorIconsBold.xCircle),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: body(size: 12.5, weight: FontWeight.w700, color: fg, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Selectable pill used by filters, sort and category pickers.
class ChoicePill extends StatelessWidget {
  const ChoicePill(this.label, {super.key, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: label,
    child: AnimatedContainer(
      duration: M.fast,
      curve: M.out,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? C.navy : C.card,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: selected ? C.navy : C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 15, color: selected ? C.turq : C.inkSoft), const SizedBox(width: 6)],
          Text(
            label,
            style: body(size: 13.5, weight: FontWeight.w600, color: selected ? C.white : C.ink, height: 1.2),
          ),
        ],
      ),
    ),
  );
}

/// Label + value row used in detail cards.
class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: C.inkSoft),
        const SizedBox(width: S.md),
        SizedBox(
          width: 92,
          child: Text(label, style: body(size: 13.5, color: C.inkSoft)),
        ),
        Expanded(
          child: Text(value, style: body(size: 14, weight: FontWeight.w600)),
        ),
      ],
    ),
  );
}

/// Entrance animation: fade + rise, staggered by [index].
class Rise extends StatelessWidget {
  const Rise({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;
  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return child;
    final delay = M.stagger * index.clamp(0, 8);
    final total = M.slow + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: M.out),
      builder: (_, v, c) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: c),
      ),
      child: child,
    );
  }
}

void toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
}

/// Runs [action]; shows its error message (FixyException or any) as a toast.
Future<bool> attempt(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } catch (e) {
    if (context.mounted) toast(context, e.toString().replaceFirst('Exception: ', ''));
    return false;
  }
}

Future<bool> confirmDialog(BuildContext context, {required String title, required String text, required String confirm, bool danger = false}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
      title: Text(title, style: title_(19)),
      content: Text(text, style: body(size: 14.5, color: C.inkSoft)),
      actionsPadding: const EdgeInsets.fromLTRB(S.lg, 0, S.lg, S.lg),
      actions: [
        Row(
          children: [
            Expanded(child: Btn.outline('Retour', compact: true, onTap: () => Navigator.pop(ctx, false))),
            const SizedBox(width: S.sm),
            Expanded(
              child: danger
                  ? Btn.danger(confirm, compact: true, onTap: () => Navigator.pop(ctx, true))
                  : Btn(confirm, compact: true, onTap: () => Navigator.pop(ctx, true)),
            ),
          ],
        ),
      ],
    ),
  );
  return r ?? false;
}

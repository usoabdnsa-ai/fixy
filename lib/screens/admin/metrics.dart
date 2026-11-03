import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});
  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  int _range = 14;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final req = requestsPerDay.sublist(requestsPerDay.length - _range);
    final done = completedPerDay.sublist(completedPerDay.length - _range);
    final totalReq = req.reduce((a, b) => a + b);
    final totalDone = done.reduce((a, b) => a + b);
    final verified = craftsmen.where((c) => c.verified).length;

    return TabPage(
      eyebrow: 'Admin · all wilayas',
      title: 'Platform',
      accent: 'today',
      children: [
        // Filters sit in one row above the charts.
        Row(
          children: [
            for (final r in [7, 14])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Pressable(
                  haptic: false,
                  onTap: () => setState(() => _range = r),
                  child: AnimatedContainer(
                    duration: M.fast,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _range == r ? C.volt : C.card,
                      borderRadius: BorderRadius.circular(R.pill),
                      border: Border.all(color: _range == r ? C.volt : C.line),
                    ),
                    child: Text(
                      'Last $r days',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _range == r ? C.onFill : C.ink),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: S.lg),
        Row(
          children: [
            Expanded(
              child: _Stat(label: 'Active requests', value: '${s.board.length + 37}', delta: '+12%').enter(context, 0),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(label: 'Completion', value: '${(100 * totalDone / totalReq).round()}%', delta: '+3 pts').enter(context, 1),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: "Verified m'lems",
                value: '$verified / ${craftsmen.length}',
                delta: '${s.verifications.where((v) => v.decision == null).length} pending',
              ).enter(context, 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Stat(label: 'Open flags', value: '${s.flags.where((f) => !f.resolved).length}', delta: 'oldest 28 h').enter(context, 3),
            ),
          ],
        ),
        const SizedBox(height: S.lg),
        TagCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Requests vs completed jobs', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),
              Row(children: [_legend(C.seriesA, 'Requests', '$totalReq'), const SizedBox(width: 16), _legend(C.seriesB, 'Completed', '$totalDone')]),
              const SizedBox(height: 12),
              _LineChart(a: req, b: done, key: ValueKey(_range)),
            ],
          ),
        ).enter(context, 4),
        const SizedBox(height: S.lg),
        TagCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Requests by trade, %', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              for (final e in tradeShare.entries) _ShareBar(trade: e.key, pct: e.value),
            ],
          ),
        ).enter(context, 5),
      ],
    );
  }

  Widget _legend(Color c, String label, String v) => Row(
    children: [
      Container(
        width: 14,
        height: 3,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)),
      ),
      const SizedBox(width: 6),
      Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
      const SizedBox(width: 6),
      Text(v, style: figs(size: 12, weight: FontWeight.w700)),
    ],
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.delta});
  final String label;
  final String value;
  final String delta;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: figs(size: 10, weight: FontWeight.w700, color: C.inkSoft),
          ),
          const SizedBox(height: 6),
          Text(value, style: figs(size: 22, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(delta, style: figs(size: 11, color: C.inkSoft)),
        ],
      ),
    );
  }
}

/// Two-series line chart on one y-axis. Lines draw in once; drag/hover shows a
/// crosshair with both values.
class _LineChart extends StatefulWidget {
  const _LineChart({super.key, required this.a, required this.b});
  final List<int> a;
  final List<int> b;
  @override
  State<_LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<_LineChart> with SingleTickerProviderStateMixin {
  late final AnimationController _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  int? _hover;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _draw.value = 1;
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _at(double dx, double w) {
    final n = widget.a.length;
    final i = ((dx - 28) / (w - 28) * (n - 1)).round().clamp(0, n - 1);
    if (i != _hover) {
      HapticFeedback.selectionClick();
      setState(() => _hover = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.a.length;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 26,
              child: _hover == null
                  ? Text('Drag across the chart for daily values', style: figs(size: 11, color: C.inkSoft))
                  : Row(
                      children: [
                        Text('Day ${_hover! + 1 - n}', style: figs(size: 11.5, weight: FontWeight.w700)),
                        const SizedBox(width: 12),
                        Text('Requests ${widget.a[_hover!]}', style: figs(size: 11.5)),
                        const SizedBox(width: 12),
                        Text('Completed ${widget.b[_hover!]}', style: figs(size: 11.5)),
                      ],
                    ),
            ),
            MouseRegion(
              onHover: (e) => _at(e.localPosition.dx, w),
              onExit: (_) => setState(() => _hover = null),
              child: GestureDetector(
                onHorizontalDragStart: (d) => _at(d.localPosition.dx, w),
                onHorizontalDragUpdate: (d) => _at(d.localPosition.dx, w),
                onHorizontalDragEnd: (_) => setState(() => _hover = null),
                onTapDown: (d) => _at(d.localPosition.dx, w),
                child: AnimatedBuilder(
                  animation: _draw,
                  builder: (_, _) =>
                      CustomPaint(size: Size(w, 150), painter: _ChartPainter(widget.a, widget.b, Curves.easeOutCubic.transform(_draw.value), _hover)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                children: [
                  Text('$n days ago', style: figs(size: 10, color: C.inkSoft)),
                  const Spacer(),
                  Text('today', style: figs(size: 10, color: C.inkSoft)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(this.a, this.b, this.t, this.hover);
  final List<int> a;
  final List<int> b;
  final double t;
  final int? hover;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    final w = size.width - left;
    final h = size.height - 8;
    final maxV = ((([...a, ...b].reduce(math.max)) / 20).ceil() * 20).toDouble();
    final grid = Paint()
      ..color = C.line
      ..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 2; i++) {
      final y = 4 + h * i / 2;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      tp.text = TextSpan(
        text: '${(maxV * (1 - i / 2)).round()}',
        style: figs(size: 9.5, color: C.inkSoft),
      );
      tp.layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }
    Offset pt(List<int> s, int i) => Offset(left + w * i / (s.length - 1), 4 + h * (1 - s[i] / maxV));

    void line(List<int> s, Color c) {
      final p = Path()..moveTo(pt(s, 0).dx, pt(s, 0).dy);
      for (var i = 1; i < s.length; i++) {
        p.lineTo(pt(s, i).dx, pt(s, i).dy);
      }
      final metric = p.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * t),
        Paint()
          ..color = c
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (t == 1) {
        final end = pt(s, s.length - 1);
        canvas.drawCircle(end, 6, Paint()..color = C.card);
        canvas.drawCircle(end, 4, Paint()..color = c);
      }
    }

    line(a, C.seriesA);
    line(b, C.seriesB);

    if (hover != null) {
      final x = pt(a, hover!).dx;
      canvas.drawLine(
        Offset(x, 4),
        Offset(x, 4 + h),
        Paint()
          ..color = C.ink
          ..strokeWidth = 1,
      );
      for (final (s, c) in [(a, C.seriesA), (b, C.seriesB)]) {
        final p = pt(s, hover!);
        canvas.drawCircle(p, 6, Paint()..color = C.card);
        canvas.drawCircle(p, 4.5, Paint()..color = c);
      }
    }
  }

  final bool _light = C.isLight;
  @override
  bool shouldRepaint(covariant _ChartPainter old) => old._light != _light || old.t != t || old.hover != hover || old.a != a;
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.trade, required this.pct});
  final Trade trade;
  final int pct;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(trade.icon, size: 16),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: Text(trade.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: reduceMotion(context) ? pct / 40 : 0, end: pct / 40),
              duration: const Duration(milliseconds: 700),
              curve: M.out,
              builder: (_, v, _) => Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: v.clamp(0, 1),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: C.volt,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text(
              '$pct',
              textAlign: TextAlign.right,
              style: figs(size: 12, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

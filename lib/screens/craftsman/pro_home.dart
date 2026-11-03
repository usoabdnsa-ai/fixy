import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'earnings.dart';
import 'pro_board.dart';
import 'pro_shell.dart';

class ProHome extends StatelessWidget {
  const ProHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final next = s.proJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).toList();

    return Stack(
      children: [
        TabPage(
          eyebrow: 'Thursday 15 Oct',
          title: 'Sbah el khir,',
          accent: me.firstName,
          trailing: Avatar(craftsman: me, size: 44),
          children: [
            _OnlineCard(online: s.online, radius: s.radiusKm, onChanged: s.setOnline).enter(context, 0),
            const SizedBox(height: S.md),
            Row(
              children: [
                _Kpi(label: 'This week', value: dzd(s.earningsWeek), accent: true, onTap: () => Navigator.of(context).push(wipeRoute(const EarningsScreen()))),
                const SizedBox(width: 10),
                _Kpi(label: 'Rating', value: me.rating.toStringAsFixed(1)),
                const SizedBox(width: 10),
                _Kpi(label: 'Jobs', value: '${me.jobsDone}'),
              ],
            ).enter(context, 1),
            const SizedBox(height: S.md),
            Pressable(
              scale: 0.98,
              semanticLabel: 'Open wallet',
              onTap: () => Navigator.of(context).push(wipeRoute(const EarningsScreen())),
              child: const EarningsChart(),
            ).enter(context, 2),
            const SizedBox(height: S.xl),
            Row(
              children: [
                Expanded(child: Text('Next up', style: display(size: 19))),
                Text('${next.length} booked', style: figs(size: 12, color: C.inkSoft)),
              ],
            ),
            const SizedBox(height: 10),
            if (next.isEmpty)
              Text('Nothing booked. Stay online to receive requests.', style: Theme.of(context).textTheme.bodySmall)
            else
              for (final (i, j) in next.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TagCard(
                    onTap: () => proShellKey.currentState?.go(2),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: i == 0 ? C.volt : C.voltWash, borderRadius: BorderRadius.circular(R.sm)),
                          child: Column(
                            children: [
                              Text(
                                i == 0 ? '11:00' : '15:30',
                                style: figs(size: 13, weight: FontWeight.w700, color: i == 0 ? C.onFill : C.volt),
                              ),
                              Text('today', style: figs(size: 9.5, color: i == 0 ? C.onFillSoft : C.volt)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                j.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text('${j.clientName} · ${j.commune}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                        StatusChip(j.status),
                      ],
                    ),
                  ).enter(context, i + 3),
                ),
          ],
        ),
        // Live job alert drops in from the top.
        Positioned(
          left: 12,
          right: 12,
          top: top + 8,
          child: AnimatedSwitcher(
            duration: M.slow,
            switchInCurve: M.spring,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (c, a) => SlideTransition(
              position: Tween(begin: const Offset(0, -1.3), end: Offset.zero).animate(a),
              child: FadeTransition(opacity: a, child: c),
            ),
            child: s.incoming == null ? const SizedBox.shrink(key: ValueKey('none')) : _IncomingAlert(key: ValueKey(s.incoming!.id), job: s.incoming!),
          ),
        ),
      ],
    );
  }
}

class _OnlineCard extends StatelessWidget {
  const _OnlineCard({required this.online, required this.radius, required this.onChanged});
  final bool online;
  final int radius;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      semanticLabel: online ? 'Go offline' : 'Go online',
      onTap: () {
        HapticFeedback.mediumImpact();
        onChanged(!online);
      },
      child: AnimatedContainer(
        duration: M.base,
        curve: M.out,
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(
          color: online ? C.teal : C.card,
          borderRadius: BorderRadius.circular(R.lg - 4),
          border: online ? null : Border.all(color: C.line),
          boxShadow: online ? lift : null,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (online && !reduceMotion(context))
                    Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: C.volt, width: 2),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .scale(begin: const Offset(.3, .3), end: const Offset(1, 1), duration: 1600.ms, curve: Curves.easeOut)
                        .fadeOut(duration: 1600.ms),
                  AnimatedContainer(
                    duration: M.base,
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: online ? C.volt : C.lineStrong, shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: M.base,
                    style: display(size: 20, color: online ? C.onFill : C.ink),
                    child: Text(online ? "You're online" : "You're offline"),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    online ? 'Receiving jobs within $radius km of Hussein Dey' : 'Tap to start receiving requests',
                    style: TextStyle(fontSize: 13, color: online ? C.onFillSoft : C.inkSoft),
                  ),
                ],
              ),
            ),
            IgnorePointer(
              child: Switch(value: online, onChanged: (_) {}),
            ),
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, this.accent = false, this.onTap});
  final String label;
  final String value;
  final bool accent;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: accent ? 2 : 1,
      child: Pressable(
        onTap: onTap,
        semanticLabel: onTap == null ? null : 'Open wallet',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent ? C.volt : C.card,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: accent ? C.volt : C.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: figs(size: 10, weight: FontWeight.w700, color: accent ? C.onFillSoft : C.inkSoft),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: figs(size: 18, weight: FontWeight.w700, color: accent ? C.onFill : C.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EarningsChart extends StatelessWidget {
  const EarningsChart({super.key});
  static const _days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  static const _vals = [3500, 6000, 2000, 4500, 2500, 0, 0];
  @override
  Widget build(BuildContext context) {
    final max = _vals.reduce((a, b) => a > b ? a : b);
    return TagCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Earnings', style: TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('This week', style: figs(size: 10.5, color: C.inkSoft)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 96,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (i == 4)
                            Text(
                              'today',
                              style: figs(size: 9, color: C.hotText, weight: FontWeight.w700),
                            ),
                          const SizedBox(height: 3),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: reduceMotion(context) ? 1 : 0, end: 1),
                            duration: Duration(milliseconds: 500 + i * 60),
                            curve: M.out,
                            builder: (_, t, _) => Container(
                              height: (_vals[i] == 0 ? 4 : 60 * _vals[i] / max) * t + 2,
                              decoration: BoxDecoration(color: i == 4 ? C.hot : (i > 4 ? C.line : C.volt), borderRadius: BorderRadius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_days[i], style: figs(size: 10.5, color: C.inkSoft)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Urgent request alert with a 60s countdown ring. Accept or pass.
class _IncomingAlert extends StatefulWidget {
  const _IncomingAlert({super.key, required this.job});
  final Job job;
  @override
  State<_IncomingAlert> createState() => _IncomingAlertState();
}

class _IncomingAlertState extends State<_IncomingAlert> with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(vsync: this, duration: const Duration(seconds: 60))
    ..forward().whenComplete(() {
      if (mounted) context.read<AppState>().dismissIncoming();
    });

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    final d = kmFrom(me.location, j.location);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: C.hot.withValues(alpha: .5), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x330F172A), offset: Offset(0, 16), blurRadius: 36, spreadRadius: -8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsBold.siren, size: 16, color: C.hotText),
              const SizedBox(width: 6),
              Text(
                'Urgent · ${km(d)} away',
                style: figs(size: 11.5, weight: FontWeight.w700, color: C.hotText),
              ),
              const Spacer(),
              SizedBox(
                width: 30,
                height: 30,
                child: AnimatedBuilder(
                  animation: _ring,
                  builder: (_, _) => Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: 1 - _ring.value, strokeWidth: 3, color: C.hot, backgroundColor: C.hotWash),
                      Text(
                        '${(60 * (1 - _ring.value)).ceil()}',
                        style: figs(size: 10, weight: FontWeight.w700, color: C.hotText),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(j.title, style: display(size: 22)),
          const SizedBox(height: 4),
          Text(
            '${j.clientName} · ${j.commune} · ${j.budgetHint ?? ''}',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: C.inkSoft),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TagButton.light(compact: true, label: 'Pass', onTap: () => context.read<AppState>().dismissIncoming()),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TagButton(
                  compact: true,
                  label: 'Accept job',
                  icon: PhosphorIconsBold.check,
                  onTap: () {
                    final s = context.read<AppState>();
                    s.acceptBoardJob(j, price: 4000);
                    toast(context, 'Accepted. ${j.clientName} has been notified.');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Pressable(
              onTap: () => showJobSheet(context, j),
              child: Padding(
                padding: EdgeInsets.all(6),
                child: Text(
                  'See details',
                  style: TextStyle(fontWeight: FontWeight.w700, color: C.isLight ? C.volt : C.ink),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

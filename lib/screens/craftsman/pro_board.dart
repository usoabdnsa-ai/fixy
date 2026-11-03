import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';

/// Open requests in the craftsman's radius. Swipe right = quote/accept,
/// swipe left = pass. Buttons do the same for people who don't swipe.
class ProBoard extends StatelessWidget {
  const ProBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = s.board.where((j) => kmFrom(me.location, j.location) <= s.radiusKm).toList()..sort((a, b) => a.urgency.index.compareTo(b.urgency.index));

    return TabPage(
      eyebrow: 'New work',
      title: 'Open',
      accent: 'requests',
      subtitle: '${me.trade.label} · within ${s.radiusKm} km of ${me.commune}',
      children: [
        TagCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 4),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(PhosphorIconsBold.crosshair, size: 18),
                  const SizedBox(width: 8),
                  const Text('Alert radius', style: TextStyle(fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Text('${s.radiusKm} km', style: figs(size: 13, weight: FontWeight.w700)),
                  const SizedBox(width: 6),
                ],
              ),
              Slider(
                value: s.radiusKm.toDouble(),
                min: 2,
                max: 30,
                divisions: 28,
                onChanged: (v) {
                  if (v.round() != s.radiusKm) HapticFeedback.selectionClick();
                  s.setRadius(v.round());
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        if (list.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 40),
            child: Column(
              children: [
                Icon(PhosphorIconsBold.tray, size: 44, color: C.inkSoft),
                const SizedBox(height: 12),
                Text('No open requests', style: display(size: 18)),
                const SizedBox(height: 6),
                Text('Widen your radius or stay online, new ones arrive as alerts.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        for (final (i, j) in list.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Dismissible(
              key: ValueKey(j.id),
              background: _swipeBg(true),
              secondaryBackground: _swipeBg(false),
              confirmDismiss: (dir) async {
                HapticFeedback.mediumImpact();
                if (dir == DismissDirection.startToEnd) {
                  showJobSheet(context, j);
                  return false;
                }
                return true;
              },
              onDismissed: (_) {
                s.declineBoardJob(j);
                toast(context, 'Passed on ${j.id}');
              },
              child: _RequestCard(job: j).enter(context, i),
            ),
          ),
        if (list.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'Swipe right to quote · left to pass',
                style: figs(size: 10.5, color: C.inkSoft, weight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _swipeBg(bool accept) => Container(
    alignment: accept ? Alignment.centerLeft : Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 24),
    decoration: BoxDecoration(color: accept ? C.teal : C.line, borderRadius: BorderRadius.circular(R.lg)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(accept ? PhosphorIconsBold.check : PhosphorIconsBold.x, color: accept ? C.onFill : C.ink),
        const SizedBox(width: 8),
        Text(
          accept ? 'Quote' : 'Pass',
          style: TextStyle(fontWeight: FontWeight.w700, color: accept ? C.onFill : C.ink),
        ),
      ],
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final d = kmFrom(me.location, job.location);
    return TagCard(
      raised: job.urgency == Urgency.now,
      onTap: () => showJobSheet(context, job),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UrgencyChip(job.urgency),
              const SizedBox(width: 8),
              Text(ago(job.postedMinsAgo), style: figs(size: 11, color: C.inkSoft)),
              const Spacer(),
              Icon(PhosphorIconsFill.navigationArrow, size: 13, color: C.hotText),
              const SizedBox(width: 4),
              Text(
                km(d),
                style: figs(size: 12, weight: FontWeight.w700, color: C.hotText),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (job.photos.isNotEmpty) ...[const SizedBox(width: 10), Photo(job.photos.first, width: 64, height: 64, radius: R.sm)],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('${job.clientName} · ${job.commune}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Spacer(),
              Text(job.budgetHint ?? '', style: figs(size: 12, weight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Request details + send a quote in DZD (stepper) or accept at the suggested price.
void showJobSheet(BuildContext context, Job job) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.card,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
    builder: (_) => _JobSheet(job: job),
  );
}

class _JobSheet extends StatefulWidget {
  const _JobSheet({required this.job});
  final Job job;
  @override
  State<_JobSheet> createState() => _JobSheetState();
}

class _JobSheetState extends State<_JobSheet> {
  late int _price = me.callout + me.hourly * 2;

  void _bump(int d) {
    HapticFeedback.selectionClick();
    setState(() => _price = (_price + d).clamp(500, 50000));
  }

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Padding(
      padding: EdgeInsets.fromLTRB(S.gutter, 12, S.gutter, MediaQuery.paddingOf(context).bottom + S.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: C.lineStrong, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: S.lg),
          Row(
            children: [
              UrgencyChip(j.urgency),
              const SizedBox(width: 8),
              Text(j.id, style: figs(size: 11, color: C.inkSoft)),
            ],
          ),
          const SizedBox(height: 10),
          Text(j.title, style: display(size: 22)),
          const SizedBox(height: 6),
          Text(j.description, style: Theme.of(context).textTheme.bodyMedium),
          if (j.photos.isNotEmpty) ...[const SizedBox(height: 12), Photo(j.photos.first, height: 140, width: double.infinity)],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(PhosphorIconsBold.mapPin, size: 16),
              const SizedBox(width: 6),
              Text('${j.commune} · ${km(kmFrom(me.location, j.location))} from you', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: S.lg),
          Text(
            'Your price',
            style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconCircle(icon: PhosphorIconsBold.minus, label: 'Lower price', onTap: () => _bump(-500)),
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: M.fast,
                    transitionBuilder: (c, a) => FadeTransition(
                      opacity: a,
                      child: SlideTransition(
                        position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a),
                        child: c,
                      ),
                    ),
                    child: Text(
                      dzd(_price),
                      key: ValueKey(_price),
                      style: figs(size: 28, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              IconCircle(icon: PhosphorIconsBold.plus, label: 'Raise price', onTap: () => _bump(500)),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text('Client budget: ${j.budgetHint ?? 'open'}', style: figs(size: 11, color: C.inkSoft)),
          ),
          const SizedBox(height: S.lg),
          Row(
            children: [
              Expanded(
                child: TagButton.light(
                  label: 'Send quote',
                  onTap: () {
                    context.read<AppState>().declineBoardJob(j); // leaves the board, quote is "sent"
                    Navigator.pop(context);
                    toast(context, 'Quote of ${dzd(_price)} sent to ${j.clientName}');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TagButton(
                  label: 'Accept now',
                  onTap: () {
                    context.read<AppState>().acceptBoardJob(j, price: _price);
                    Navigator.pop(context);
                    toast(context, 'Accepted ${j.id}. Chat with ${j.clientName} is open.');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'craftsman_profile.dart';

void openProfile(BuildContext context, Craftsman c) => Navigator.of(context).push(wipeRoute(CraftsmanProfileScreen(craftsman: c)));

/// List row for a craftsman: tag avatar, name + stamp, trade/commune,
/// then a mono data strip (rating · distance · callout).
class CraftsmanTile extends StatelessWidget {
  const CraftsmanTile({super.key, required this.c, this.onTap});
  final Craftsman c;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final d = kmFrom(clientHome, c.location);
    return TagCard(
      onTap: onTap ?? () => openProfile(context, c),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Hero(
            tag: 'avatar-${c.id}',
            child: Avatar(craftsman: c, size: 54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                    if (c.verified) ...[const SizedBox(width: 8), const VerifiedStamp(small: true)],
                  ],
                ),
                const SizedBox(height: 3),
                Text('${c.trade.local} · ${c.commune}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Stars(value: c.rating, size: 13),
                    _dot(),
                    Text(km(d), style: figs(size: 12, weight: FontWeight.w600)),
                    _dot(),
                    Text('from ${dzd(c.callout + c.hourly)}', style: figs(size: 12, color: C.inkSoft)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _AvailDot(available: c.available),
        ],
      ),
    );
  }

  Widget _dot() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 7),
    child: Text('·', style: TextStyle(color: C.inkSoft)),
  );
}

class _AvailDot extends StatelessWidget {
  const _AvailDot({required this.available});
  final bool available;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: available ? 'Available now' : 'Busy',
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: available ? C.teal : C.lineStrong,
          shape: BoxShape.circle,
          border: Border.all(color: C.card, width: 2),
        ),
      ),
    );
  }
}

/// Four-stop job progress: Posted → Accepted → On site → Done.
class JobProgress extends StatelessWidget {
  const JobProgress({super.key, required this.status, this.labels = true});
  final JobStatus status;
  final bool labels;

  int get step => switch (status) {
    JobStatus.pending || JobStatus.quoted => 0,
    JobStatus.accepted => 1,
    JobStatus.inProgress => 2,
    JobStatus.completed => 3,
    JobStatus.cancelled => -1,
  };

  @override
  Widget build(BuildContext context) {
    const names = ['Posted', 'Accepted', 'On site', 'Done'];
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(2)),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: step < 0 ? 0 : step / 3),
                    duration: M.slow,
                    curve: M.out,
                    builder: (_, v, _) => Container(
                      width: w * v,
                      height: 4,
                      decoration: BoxDecoration(color: C.teal, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: (w - 18) * i / 3,
                      child: AnimatedContainer(
                        duration: M.base,
                        curve: M.out,
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: i <= step ? C.teal : C.card,
                          shape: BoxShape.circle,
                          border: Border.all(color: i <= step ? C.teal : C.lineStrong, width: 2),
                        ),
                        child: i <= step ? Icon(PhosphorIconsBold.check, size: 10, color: C.onFill) : null,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (labels) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < 4; i++)
                Expanded(
                  child: Text(
                    names[i],
                    textAlign: i == 0 ? TextAlign.left : (i == 3 ? TextAlign.right : TextAlign.center),
                    style: figs(size: 10.5, weight: i == step ? FontWeight.w700 : FontWeight.w500, color: i <= step ? C.ink : C.inkSoft),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

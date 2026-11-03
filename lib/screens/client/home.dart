import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'chat.dart';
import 'client_shell.dart';
import 'explore.dart';
import 'job_detail.dart';
import 'post_request.dart';
import 'widgets.dart';
import '../shared/track.dart';

/// Client home. One giant question and one volt action up top, a live
/// ticker of free m'lems, then numbered trade rows and the nearest pros.
class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  void _explore(BuildContext context, {Trade? trade, bool availableOnly = false}) {
    exploreFilter.value = ExploreFilter(trade: trade, availableOnly: availableOnly);
    clientShellKey.currentState?.go(1);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final live = s.clientJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).toList();
    final nearby = [...craftsmen.where((c) => c.verified)]..sort((a, b) => kmFrom(clientHome, a.location).compareTo(kmFrom(clientHome, b.location)));
    final freeNow = craftsmen.where((c) => c.available && kmFrom(clientHome, c.location) < 5).length;
    const gutter = EdgeInsets.symmetric(horizontal: S.gutter);
    var section = 0;

    final h = DateTime.now().hour;
    final greet = h < 12 ? 'SBAH EL KHIR' : (h < 18 ? 'SALAM' : 'MSA EL KHIR');
    return TabPage(
      eyebrow: '$greet, AMINA',
      title: 'What',
      accent: 'broke?',
      trailing: IconCircle(icon: PhosphorIconsBold.bell, label: 'Notifications', onTap: () => toast(context, 'No new notifications')),
      headerChild: Column(
        children: [
          _Where(address: s.address).animate(delay: 300.ms).fadeIn(duration: 200.ms),
          const SizedBox(height: 14),
          TagButton(
            label: 'Post a job',
            icon: PhosphorIconsBold.camera,
            onTap: () => Navigator.of(context).push(wipeRoute(fullscreenDialog: true, const PostRequestScreen())),
          ).animate(delay: 350.ms).fadeIn(duration: 160.ms).moveX(begin: -24, end: 0, duration: 380.ms, curve: M.out),
          const SizedBox(height: 14),
          Pressable(
            scale: 0.98,
            semanticLabel: 'See free m\'lems on the map',
            onTap: () => _explore(context, availableOnly: true),
            child: Row(
              children: [
                LiveDot(color: C.teal),
                const SizedBox(width: 10),
                Text(
                  '$freeNow FREE NOW',
                  style: figs(size: 12, weight: FontWeight.w700, color: C.teal),
                ),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: C.line)),
                const SizedBox(width: 10),
                Text(
                  '≤ 5 KM  →',
                  style: figs(size: 12, weight: FontWeight.w700, color: C.inkSoft),
                ),
              ],
            ),
          ).animate(delay: 450.ms).fadeIn(duration: 200.ms),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, S.xxl),
      children: [
        if (live.isNotEmpty) ...[
          SectionHead('Happening now', index: section++),
          Padding(
            padding: gutter,
            child: LiveTracker(job: live.first).enter(context, 0),
          ),
        ],
        SectionHead('Trades', index: section++, action: 'Map', onAction: () => _explore(context)),
        for (final (i, t) in Trade.values.indexed)
          _TradeRow(
            index: i,
            trade: t,
            onTap: () => _explore(context, trade: t),
          ).enter(context, i + 1),
        SectionHead('Verified near you', index: section++, action: 'All', onAction: () => _explore(context)),
        for (final (i, c) in nearby.take(4).indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, 10),
            child: CraftsmanTile(c: c).enter(context, i + 2),
          ),
      ],
    );
  }
}

/// "01  [icon]  PLUMBER        2 PROS  →" on a hairline.
class _TradeRow extends StatelessWidget {
  const _TradeRow({required this.index, required this.trade, required this.onTap});
  final int index;
  final Trade trade;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final count = craftsmen.where((c) => c.trade == trade).length;
    return Pressable(
      onTap: onTap,
      semanticLabel: trade.label,
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.fromLTRB(S.gutter, 14, S.gutter, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: C.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(idx(index), style: figs(size: 12, color: C.inkSoft)),
            ),
            Icon(trade.icon, size: 22, color: C.volt),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trade.label.toUpperCase(), style: display(size: 24, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(trade.local.toUpperCase(), style: figs(size: 10.5, color: C.inkSoft)),
                ],
              ),
            ),
            Text(
              '$count PROS',
              style: figs(size: 11.5, weight: FontWeight.w700, color: C.inkSoft),
            ),
            const SizedBox(width: 12),
            Icon(PhosphorIconsBold.arrowRight, size: 16, color: C.ink),
          ],
        ),
      ),
    );
  }
}

/// Location selector: the saved address jobs get posted to.
class _Where extends StatelessWidget {
  const _Where({required this.address});
  final Address address;

  void _pick(BuildContext context) {
    final s = context.read<AppState>();
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, MediaQuery.paddingOf(ctx).bottom + S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SEND M\'LEMS TO',
              style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
            ),
            const SizedBox(height: 10),
            for (final a in addresses)
              Pressable(
                semanticLabel: a.label,
                onTap: () {
                  s.setAddress(a);
                  Navigator.pop(ctx);
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: C.line)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        a.label == 'Home' ? PhosphorIconsBold.house : (a.label == 'Office' ? PhosphorIconsBold.briefcase : PhosphorIconsBold.heart),
                        color: C.volt,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.label.toUpperCase(), style: display(size: 20, weight: FontWeight.w700)),
                            Text('${a.line}, ${a.commune}', style: TextStyle(fontSize: 13, color: C.inkSoft)),
                          ],
                        ),
                      ),
                      if (a == s.address) Icon(PhosphorIconsFill.checkCircle, color: C.volt),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      semanticLabel: 'Change address, now ${address.label}',
      onTap: () => _pick(context),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(R.sm),
          border: Border.all(color: C.lineStrong),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsFill.mapPin, size: 18, color: C.volt),
            const SizedBox(width: 10),
            Text(address.label.toUpperCase(), style: figs(size: 12, weight: FontWeight.w700)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${address.commune}, Alger',
                overflow: TextOverflow.ellipsis,
                style: figs(size: 12, color: C.inkSoft),
              ),
            ),
            Icon(PhosphorIconsBold.caretRight, size: 14, color: C.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Live booking tracker: a big ticking ETA, the route progress and the m'lem.
/// Taps through to the map. Falls back to the job page when nobody is driving.
class LiveTracker extends StatelessWidget {
  const LiveTracker({super.key, required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final c = job.craftsman!;
    final trip = job.trip;
    final onSite = job.status == JobStatus.inProgress || (trip?.arrived ?? false);
    return TagCard(
      raised: true,
      onTap: () => Navigator.of(context).push(wipeRoute(trip != null && !onSite ? TrackScreen(job: job) : JobDetailScreen(job: job))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LiveDot(color: onSite ? C.teal : null),
              const SizedBox(width: 8),
              Text(
                onSite ? 'ON SITE' : (trip != null ? 'ON THE WAY' : 'BOOKED'),
                style: figs(size: 11, weight: FontWeight.w700, color: onSite ? C.teal : C.volt),
              ),
              const Spacer(),
              Text(job.id, style: figs(size: 11, color: C.inkSoft)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              if (trip != null && !onSite)
                Semantics(
                  label: 'Arriving in ${etaMins(trip)} minutes',
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AnimatedSwitcher(
                        duration: M.base,
                        child: Text(
                          '${etaMins(trip)}',
                          key: ValueKey(etaMins(trip)),
                          style: display(size: 44, weight: FontWeight.w800, color: C.volt).copyWith(height: .9),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          'MIN',
                          style: figs(size: 11, weight: FontWeight.w700, color: C.volt),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (trip != null && !onSite) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: trip.progress),
                duration: const Duration(milliseconds: 950),
                builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: C.line, color: C.volt),
              ),
            ),
            const SizedBox(height: 6),
            Text('${km(routeKm(trip.route) * (1 - trip.progress))} away · tap for live map', style: figs(size: 11, color: C.inkSoft)),
          ] else
            JobProgress(status: job.status),
          const SizedBox(height: 14),
          Row(
            children: [
              Avatar(craftsman: c, size: 38),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (c.verified) ...[const SizedBox(width: 6), const VerifiedStamp(small: true)],
                      ],
                    ),
                    Text('★ ${c.rating.toStringAsFixed(1)} · ${dzd(job.price ?? 0)}', style: figs(size: 11.5, color: C.inkSoft)),
                  ],
                ),
              ),
              IconCircle(
                icon: PhosphorIconsBold.chatCircleDots,
                label: 'Chat',
                bg: C.bg,
                onTap: () => Navigator.of(context).push(wipeRoute(ChatScreen(job: job))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

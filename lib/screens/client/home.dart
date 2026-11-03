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

    return TabPage(
      eyebrow: 'KOUBA, ALGER  ·  SALAM AMINA',
      title: 'What',
      accent: 'broke?',
      trailing: IconCircle(icon: PhosphorIconsBold.bell, label: 'Notifications', onTap: () => toast(context, 'No new notifications')),
      headerChild: Column(
        children: [
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
                Text('$freeNow FREE NOW', style: figs(size: 12, weight: FontWeight.w700, color: C.teal)),
                const SizedBox(width: 10),
                Expanded(child: Container(height: 1, color: C.line)),
                const SizedBox(width: 10),
                Text('≤ 5 KM  →', style: figs(size: 12, weight: FontWeight.w700, color: C.inkSoft)),
              ],
            ),
          ).animate(delay: 450.ms).fadeIn(duration: 200.ms),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, S.xxl),
      children: [
        if (live.isNotEmpty) ...[
          SectionHead('Happening now', index: section++),
          Padding(padding: gutter, child: _LiveJob(job: live.first).enter(context, 0)),
        ],
        SectionHead('Trades', index: section++, action: 'Map', onAction: () => _explore(context)),
        for (final (i, t) in Trade.values.indexed) _TradeRow(index: i, trade: t, onTap: () => _explore(context, trade: t)).enter(context, i + 1),
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
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.line))),
        child: Row(
          children: [
            SizedBox(width: 28, child: Text(idx(index), style: figs(size: 12, color: C.inkSoft))),
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
            Text('$count PROS', style: figs(size: 11.5, weight: FontWeight.w700, color: C.inkSoft)),
            const SizedBox(width: 12),
            Icon(PhosphorIconsBold.arrowRight, size: 16, color: C.ink),
          ],
        ),
      ),
    );
  }
}

class _LiveJob extends StatelessWidget {
  const _LiveJob({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final c = job.craftsman!;
    return TagCard(
      raised: true,
      onTap: () => Navigator.of(context).push(wipeRoute(JobDetailScreen(job: job))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(job.id, style: figs(size: 11, color: C.inkSoft)),
              const Spacer(),
              StatusChip(job.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 14),
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
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('Arrives 11:00 · ${dzd(job.price ?? 0)}', style: figs(size: 11.5, color: C.inkSoft)),
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

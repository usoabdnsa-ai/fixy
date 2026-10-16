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
    final top = MediaQuery.paddingOf(context).top;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, 0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(PhosphorIconsFill.mapPin, size: 14, color: C.rust),
                          const SizedBox(width: 4),
                          Text(
                            'KOUBA, ALGER',
                            style: mono(size: 11.5, weight: FontWeight.w700, color: C.rust),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Salam, Amina', style: display(size: 26)),
                    ],
                  ),
                ),
                IconCircle(icon: PhosphorIconsBold.bell, label: 'Notifications', onTap: () => toast(context, 'No new notifications')),
              ],
            ),
          ),
        ),
        // "What broke?" - the one primary entry point.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, 0),
            child: Pressable(
              scale: 0.98,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => const PostRequestScreen())),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
                decoration: BoxDecoration(
                  color: C.orange,
                  borderRadius: BorderRadius.circular(R.lg),
                  border: Border.all(color: C.ink, width: 2),
                  boxShadow: tagShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What broke?', style: display(size: 24, weight: FontWeight.w900)),
                          const SizedBox(height: 4),
                          const Text('Describe it, add a photo, get quotes.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(R.md)),
                      child: const Icon(PhosphorIconsBold.camera, color: C.orange),
                    ),
                  ],
                ),
              ),
            ),
          ).enter(context, 0),
        ),
        // Emergency strip: live count, pulsing dot.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, 0),
            child: Pressable(
              scale: 0.98,
              onTap: () => _explore(context, availableOnly: true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(R.lg)),
                child: Row(
                  children: [
                    const _Pulse(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "$freeNow m'lems free ",
                              style: const TextStyle(color: C.paper, fontWeight: FontWeight.w800),
                            ),
                            const TextSpan(
                              text: 'within 5 km right now',
                              style: TextStyle(color: Color(0xFFCFC6B6)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(PhosphorIconsBold.arrowRight, color: C.orange, size: 18),
                  ],
                ),
              ),
            ),
          ).enter(context, 1),
        ),
        if (live.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SectionHead('Happening now')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              child: _LiveJob(job: live.first).enter(context, 2),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SectionHead('Pick a trade', action: 'See all', onAction: () => _explore(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: S.gutter),
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.02,
            children: [
              for (final (i, t) in Trade.values.indexed)
                _TradeTag(
                  trade: t,
                  onTap: () => _explore(context, trade: t),
                ).enter(context, i + 2),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHead('Verified near you', action: 'Map', onAction: () => _explore(context)),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: S.gutter),
          sliver: SliverList.separated(
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => CraftsmanTile(c: nearby[i]).enter(context, i + 4),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: S.xxl)),
      ],
    );
  }
}

class _TradeTag extends StatelessWidget {
  const _TradeTag({required this.trade, required this.onTap});
  final Trade trade;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final count = craftsmen.where((c) => c.trade == trade).length;
    return Pressable(
      onTap: onTap,
      semanticLabel: trade.label,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: C.line, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(trade.icon, size: 24),
                const Spacer(),
                Text('$count', style: mono(size: 11, color: C.inkSoft)),
              ],
            ),
            const Spacer(),
            Text(
              trade.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
            Text(
              trade.local,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: mono(size: 10, color: C.inkSoft),
            ),
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
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => JobDetailScreen(job: job))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(job.id, style: mono(size: 11, color: C.inkSoft)),
              const Spacer(),
              StatusChip(job.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(job.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                    Text('Arrives 11:00 · ${dzd(job.price ?? 0)}', style: mono(size: 11.5, color: C.inkSoft)),
                  ],
                ),
              ),
              IconCircle(
                icon: PhosphorIconsBold.chatCircleDots,
                label: 'Chat',
                bg: C.paper,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(job: job))),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse();
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(color: C.orange, shape: BoxShape.circle),
    );
    if (reduceMotion(context)) return dot;
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: C.orange, width: 2),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .scale(begin: const Offset(.4, .4), end: const Offset(1.1, 1.1), duration: 1400.ms, curve: Curves.easeOut)
              .fadeOut(duration: 1400.ms, curve: Curves.easeIn),
          dot,
        ],
      ),
    );
  }
}

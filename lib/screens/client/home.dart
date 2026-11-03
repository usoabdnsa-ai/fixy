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

/// Client home, trust-blue layout: greeting + question, address chip, a
/// search-style entry into the booking wizard, a service grid, the live
/// booking tracker, top pros near you, and why Fixy is safe.
class ClientHome extends StatelessWidget {
  const ClientHome({super.key});

  void _explore(BuildContext context, {Trade? trade, bool availableOnly = false}) {
    exploreFilter.value = ExploreFilter(trade: trade, availableOnly: availableOnly);
    clientShellKey.currentState?.go(1);
  }

  void _post(BuildContext context) => Navigator.of(context).push(wipeRoute(fullscreenDialog: true, const PostRequestScreen()));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final live = s.clientJobs.where((j) => j.status == JobStatus.accepted || j.status == JobStatus.inProgress).toList();
    final nearby = [...craftsmen.where((c) => c.verified)]..sort((a, b) => kmFrom(clientHome, a.location).compareTo(kmFrom(clientHome, b.location)));
    final freeNow = craftsmen.where((c) => c.available && kmFrom(clientHome, c.location) < 5).length;
    const gutter = EdgeInsets.symmetric(horizontal: S.gutter);

    final h = DateTime.now().hour;
    final greet = h < 12 ? 'Good morning' : (h < 18 ? 'Good afternoon' : 'Good evening');
    return TabPage(
      eyebrow: '$greet, Amina',
      title: 'What needs',
      accent: 'fixing?',
      trailing: IconCircle(icon: PhosphorIconsBold.bell, label: 'Notifications', onTap: () => toast(context, 'No new notifications')),
      headerChild: Column(
        children: [
          _Where(address: s.address).animate(delay: 200.ms).fadeIn(duration: 220.ms),
          const SizedBox(height: 12),
          _SearchEntry(onTap: () => _post(context)).animate(delay: 280.ms).fadeIn(duration: 220.ms).moveY(begin: 10, end: 0, curve: M.out),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, S.xxl),
      children: [
        SectionHead('Services', action: 'Map', onAction: () => _explore(context)),
        Padding(
          padding: gutter,
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .92,
            children: [
              for (final (i, t) in Trade.values.indexed)
                _ServiceTile(
                  trade: t,
                  onTap: () => _explore(context, trade: t),
                ).enter(context, i),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        Padding(
          padding: gutter,
          child: _FreeNow(count: freeNow, onTap: () => _explore(context, availableOnly: true)),
        ),
        if (live.isNotEmpty) ...[
          const SectionHead('Your booking'),
          Padding(
            padding: gutter,
            child: LiveTracker(job: live.first).enter(context, 2),
          ),
        ],
        SectionHead('Top pros near you', action: 'See all', onAction: () => _explore(context)),
        SizedBox(
          height: 186,
          child: ListView.separated(
            padding: gutter,
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: nearby.take(6).length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _ProCard(c: nearby[i]).enter(context, i),
          ),
        ),
        const SectionHead('Why people trust Fixy'),
        const Padding(padding: gutter, child: _TrustStrip()),
      ],
    );
  }
}

/// Looks like a search field; opens the booking wizard.
class _SearchEntry extends StatelessWidget {
  const _SearchEntry({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      semanticLabel: 'Describe your problem and post a job',
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.fromLTRB(18, 0, 6, 0),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.md),
          boxShadow: lift,
          border: C.isLight ? null : Border.all(color: C.line),
        ),
        child: Row(
          children: [
            Icon(PhosphorIconsBold.magnifyingGlass, size: 20, color: C.inkSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Describe the problem…', style: TextStyle(fontSize: 15.5, color: C.inkSoft)),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.sm + 2)),
              child: Icon(PhosphorIconsBold.camera, size: 20, color: C.onFill),
            ),
          ],
        ),
      ),
    );
  }
}

/// Service tile: soft tinted icon disc, name, starting price.
class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.trade, required this.onTap});
  final Trade trade;
  final VoidCallback onTap;

  static const _tints = [
    (Color(0xFFE0ECFF), Color(0xFF1D4ED8)), // plumbing
    (Color(0xFFFFF4D6), Color(0xFFB45309)), // electrical
    (Color(0xFFDDF6F7), Color(0xFF0E7490)), // ac
    (Color(0xFFEDE9FE), Color(0xFF6D28D9)), // mechanic
    (Color(0xFFFFEADB), Color(0xFFC2410C)), // carpentry
    (Color(0xFFE5F7EA), Color(0xFF15803D)), // painting
  ];

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _tints[trade.index % _tints.length];
    final pros = craftsmen.where((c) => c.trade == trade).toList();
    final from = pros.isEmpty ? 0 : pros.map((c) => c.callout).reduce((a, b) => a < b ? a : b);
    return Pressable(
      onTap: onTap,
      semanticLabel: trade.label,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.md + 2),
          boxShadow: lift,
          border: C.isLight ? null : Border.all(color: C.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: C.isLight ? bg : fg.withValues(alpha: .18), shape: BoxShape.circle),
              child: Icon(trade.icon, size: 24, color: C.isLight ? fg : bg),
            ),
            const SizedBox(height: 10),
            Text(
              trade.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: C.ink),
            ),
            const SizedBox(height: 2),
            Text(from == 0 ? 'Get quotes' : 'from ${dzd(from)}', style: figs(size: 10.5, color: C.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _FreeNow extends StatelessWidget {
  const _FreeNow({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.98,
      semanticLabel: "See $count free m'lems on the map",
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.md)),
        child: Row(
          children: [
            LiveDot(color: C.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "$count m'lems free now",
                      style: TextStyle(fontWeight: FontWeight.w700, color: C.teal),
                    ),
                    TextSpan(
                      text: ' within 5 km of you',
                      style: TextStyle(color: C.ink),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Icon(PhosphorIconsBold.caretRight, size: 16, color: C.teal),
          ],
        ),
      ),
    );
  }
}

/// Compact pro card for the horizontal "Top pros" row.
class _ProCard extends StatelessWidget {
  const _ProCard({required this.c});
  final Craftsman c;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 156,
      child: TagCard(
        onTap: () => openProfile(context, c),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Hero(
                  tag: 'avatar-${c.id}',
                  child: Avatar(craftsman: c, size: 50),
                ),
                const Spacer(),
                if (c.available)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.pill)),
                    child: Text(
                      'Free',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: C.teal),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              c.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: C.ink),
            ),
            Text(c.trade.label, style: TextStyle(fontSize: 12.5, color: C.inkSoft)),
            const Spacer(),
            Row(
              children: [
                Stars(value: c.rating, size: 13),
                const SizedBox(width: 6),
                Text('(${c.jobsDone})', style: figs(size: 11, color: C.inkSoft)),
                const Spacer(),
                if (c.verified) Icon(PhosphorIconsFill.sealCheck, size: 16, color: C.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip();
  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String title, String sub) => Expanded(
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: C.voltWash, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: C.isLight ? C.volt : C.ink),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: C.ink),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: C.inkSoft, height: 1.3),
          ),
        ],
      ),
    );
    return TagCard(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(PhosphorIconsBold.shieldCheck, 'ID-verified', 'Every m\'lem checked'),
          item(PhosphorIconsBold.receipt, 'Upfront price', 'Know it before'),
          item(PhosphorIconsBold.star, 'Real reviews', 'One per job'),
        ],
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
              'Send m\'lems to',
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
                            Text(a.label, style: display(size: 20, weight: FontWeight.w700)),
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
            Text(address.label, style: figs(size: 12, weight: FontWeight.w700)),
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
                onSite ? 'On site' : (trip != null ? 'On the way' : 'Booked'),
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
                          'min',
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

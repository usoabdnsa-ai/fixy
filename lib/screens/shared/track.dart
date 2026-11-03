import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/chat.dart';
import '../client/widgets.dart';

/// Live trip on a map. Client side: where the m'lem is, ETA, who they are,
/// and a chat strip. M'lem side ([asPro]): the same route as turn-by-turn,
/// with the client's address and an "arrived" action.
class TrackScreen extends StatelessWidget {
  const TrackScreen({super.key, required this.job, this.asPro = false});
  final Job job;
  final bool asPro;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final trip = job.trip;
    final pad = MediaQuery.paddingOf(context);
    if (trip == null) {
      return Scaffold(
        body: Center(
          child: Text('No live trip for ${job.id}', style: figs(size: 13, color: C.inkSoft)),
        ),
      );
    }
    final eta = etaMins(trip);
    final left = routeKm(trip.route) * (1 - trip.progress);

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: RouteMap(trip: trip)),
                Positioned(
                  left: S.gutter,
                  right: S.gutter,
                  top: pad.top + 10,
                  child: Row(
                    children: [
                      IconCircle(icon: PhosphorIconsBold.arrowLeft, label: 'Back', bg: C.bg, onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      _EtaBadge(eta: eta, arrived: trip.arrived),
                    ],
                  ),
                ),
                if (asPro && !trip.arrived)
                  Positioned(
                    left: S.gutter,
                    right: S.gutter,
                    top: pad.top + 66,
                    child: _Direction(trip: trip),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(S.gutter, 16, S.gutter, 14 + pad.bottom),
            decoration: BoxDecoration(
              color: C.bg,
              border: Border(top: BorderSide(color: C.volt, width: 2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LiveDot(color: trip.arrived ? C.teal : null),
                    const SizedBox(width: 8),
                    Text(
                      trip.arrived ? 'ARRIVED' : (asPro ? 'NAVIGATING · ${km(left)} LEFT' : 'ON THE WAY · ${km(left)} LEFT'),
                      style: figs(size: 11.5, weight: FontWeight.w700, color: trip.arrived ? C.teal : C.ink).copyWith(letterSpacing: 1),
                    ),
                    const Spacer(),
                    Text(job.id, style: figs(size: 11, color: C.inkSoft)),
                  ],
                ),
                const SizedBox(height: 10),
                _TripBar(progress: trip.progress),
                const SizedBox(height: S.lg),
                if (asPro) _ClientCard(job: job) else _ProCard(job: job),
                const SizedBox(height: S.md),
                if (!asPro) _ChatStrip(job: job),
                if (asPro)
                  TagButton(
                    label: trip.arrived ? "I'm here · start job" : 'Waiting to arrive…',
                    icon: trip.arrived ? PhosphorIconsBold.check : PhosphorIconsBold.navigationArrow,
                    onTap: trip.arrived
                        ? () {
                            HapticFeedback.heavyImpact();
                            s.advance(job);
                            Navigator.pop(context);
                            toast(context, 'Job started. ${job.clientName} has been told.');
                          }
                        : null,
                  ),
                if (!trip.arrived) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Pressable(
                      onTap: () => s.skipAhead(job),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          'DEMO · SKIP AHEAD',
                          style: figs(size: 11, color: C.inkSoft, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dark-tinted OSM map with the route: the part already driven is a dim
/// hairline, the part ahead is volt, and the m'lem glides between ticks.
class RouteMap extends StatelessWidget {
  const RouteMap({super.key, required this.trip, this.interactive = true});
  final Trip trip;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final r = trip.route;
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.coordinates(coordinates: r, padding: EdgeInsets.fromLTRB(48, interactive ? 140 : 28, 48, interactive ? 48 : 64)),
        interactionOptions: InteractionOptions(flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dz.fixy.app',
          tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: ColorFilter.matrix(mapTint), child: tile),
        ),
        // Glide between the 1 s state ticks instead of jumping.
        TweenAnimationBuilder<double>(
          tween: Tween(end: trip.progress),
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 950),
          builder: (context, p, _) {
            final at = pointAlong(r, p);
            final ahead = _split(r, p);
            return Stack(
              children: [
                PolylineLayer(
                  polylines: [
                    Polyline(points: r, strokeWidth: 3, color: C.lineStrong),
                    Polyline(points: ahead, strokeWidth: 5, color: C.volt, borderStrokeWidth: 2, borderColor: C.bg),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(point: r.last, width: 40, height: 40, child: const _HomePin()),
                    Marker(
                      point: at,
                      width: 44,
                      height: 44,
                      child: _Van(arrived: trip.arrived),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
          alignment: Alignment.bottomLeft,
        ),
      ],
    );
  }

  /// The not-yet-driven part of the route: current point, then the rest.
  static List<LatLng> _split(List<LatLng> r, double p) {
    final at = pointAlong(r, p);
    final total = routeKm(r);
    var walked = 0.0;
    final out = <LatLng>[at];
    for (var i = 1; i < r.length; i++) {
      walked += kmFrom(r[i - 1], r[i]);
      if (walked > total * p) out.add(r[i]);
    }
    return out;
  }
}

class _Van extends StatelessWidget {
  const _Van({required this.arrived});
  final bool arrived;
  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: arrived ? C.teal : C.volt,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.bg, width: 2),
        boxShadow: glow,
      ),
      child: Icon(arrived ? PhosphorIconsBold.check : PhosphorIconsBold.car, size: 18, color: C.onFill),
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        if (!arrived && !reduceMotion(context))
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: C.volt, width: 2),
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(.5, .5), end: const Offset(1.3, 1.3), duration: 1400.ms).fadeOut(duration: 1400.ms),
        dot,
      ],
    );
  }
}

class _HomePin extends StatelessWidget {
  const _HomePin();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: C.ink,
        borderRadius: BorderRadius.circular(R.sm),
        border: Border.all(color: C.volt, width: 2),
      ),
      child: Icon(PhosphorIconsFill.mapPin, size: 16, color: C.bg),
    ),
  );
}

class _EtaBadge extends StatelessWidget {
  const _EtaBadge({required this.eta, required this.arrived});
  final int eta;
  final bool arrived;
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: arrived ? 'Arrived' : 'Arriving in $eta minutes',
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
        decoration: BoxDecoration(color: arrived ? C.teal : C.volt, borderRadius: BorderRadius.circular(R.sm), boxShadow: glow),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              arrived ? 'HERE' : 'ETA',
              style: figs(size: 10, weight: FontWeight.w700, color: C.onFillSoft),
            ),
            if (!arrived) ...[
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: M.base,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, .4), end: Offset.zero).animate(a),
                    child: c,
                  ),
                ),
                child: Text(
                  '$eta',
                  key: ValueKey(eta),
                  style: display(size: 30, weight: FontWeight.w800, color: C.onFill).copyWith(height: 1),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'MIN',
                style: figs(size: 11, weight: FontWeight.w700, color: C.onFill),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mono progress rail with a start and end label.
class _TripBar extends StatelessWidget {
  const _TripBar({required this.progress});
  final double progress;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: progress),
            duration: const Duration(milliseconds: 950),
            builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 4, backgroundColor: C.line, color: progress >= 1 ? C.teal : C.volt),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('DISPATCHED', style: figs(size: 9.5, color: C.inkSoft)),
            const Spacer(),
            Text('YOUR DOOR', style: figs(size: 9.5, color: C.inkSoft)),
          ],
        ),
      ],
    );
  }
}

/// Technician card: rating, completed jobs, verified badge, call / chat.
class _ProCard extends StatelessWidget {
  const _ProCard({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final c = job.craftsman!;
    return Row(
      children: [
        Pressable(
          onTap: () => openProfile(context, c),
          child: Avatar(craftsman: c, size: 52),
        ),
        const SizedBox(width: 12),
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
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                  if (c.verified) ...[const SizedBox(width: 6), const VerifiedStamp(small: true)],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Stars(value: c.rating, size: 12),
                  const SizedBox(width: 10),
                  Text('${c.jobsDone} JOBS · ${c.years} YRS', style: figs(size: 11, color: C.inkSoft)),
                ],
              ),
            ],
          ),
        ),
        IconCircle(icon: PhosphorIconsBold.phone, label: 'Call ${c.firstName}', onTap: () => toast(context, 'Calling ${c.firstName}… (prototype)')),
      ],
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(R.sm),
            border: Border.all(color: C.lineStrong),
          ),
          child: Icon(PhosphorIconsFill.mapPin, color: C.volt),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(job.clientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 2),
              Text('${job.commune} · ${job.title}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        IconCircle(
          icon: PhosphorIconsBold.chatCircleDots,
          label: 'Message ${job.clientName}',
          onTap: () => Navigator.of(context).push(wipeRoute(ChatScreen(job: job, asPro: true))),
        ),
      ],
    );
  }
}

/// The last message plus one-tap replies; the field opens the full chat.
class _ChatStrip extends StatelessWidget {
  const _ChatStrip({required this.job});
  final Job job;
  static const _quick = ["I'm downstairs", 'Gate code 1954', 'Bring a spare valve'];
  @override
  Widget build(BuildContext context) {
    final last = job.messages.where((m) => !m.system).lastOrNull;
    final s = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (last != null)
          Pressable(
            onTap: () => Navigator.of(context).push(wipeRoute(ChatScreen(job: job))),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: C.line),
              ),
              child: Row(
                children: [
                  Text(
                    last.fromMe ? 'YOU' : job.craftsman!.firstName.toUpperCase(),
                    style: figs(size: 10.5, weight: FontWeight.w700, color: C.volt),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(last.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  Icon(PhosphorIconsBold.caretRight, size: 14, color: C.inkSoft),
                ],
              ),
            ),
          ).animate(key: ValueKey(job.messages.length)).fadeIn(duration: 200.ms),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final q in _quick)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pressable(
                    semanticLabel: 'Send: $q',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      s.sendMessage(job, q);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(R.sm),
                        border: Border.all(color: C.lineStrong),
                      ),
                      child: Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Turn-by-turn card for the m'lem. Instructions are canned per route leg.
class _Direction extends StatelessWidget {
  const _Direction({required this.trip});
  final Trip trip;
  static const _steps = [
    ('Head south on Rue Tripoli', '400 m'),
    ('Turn right onto Bd. Mohamed Belouizdad', '650 m'),
    ('Left at the roundabout, 2nd exit', '300 m'),
    ('Continue on Chemin Fernane Hanafi', '500 m'),
    ('Turn left into Cité 1200 Logements', '150 m'),
    ('Destination on your right, Bt 14', '50 m'),
  ];
  @override
  Widget build(BuildContext context) {
    final i = (trip.progress * _steps.length).floor().clamp(0, _steps.length - 1);
    final (what, dist) = _steps[i];
    return AnimatedSwitcher(
      duration: M.base,
      child: Container(
        key: ValueKey(i),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.md), boxShadow: glow),
        child: Row(
          children: [
            Icon(i.isEven ? PhosphorIconsBold.arrowUpRight : PhosphorIconsBold.navigationArrow, size: 26, color: C.onFill),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dist,
                    style: display(size: 22, weight: FontWeight.w800, color: C.onFill).copyWith(height: 1),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    what,
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: C.onFillSoft),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

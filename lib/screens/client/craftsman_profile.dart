import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'post_request.dart';

class CraftsmanProfileScreen extends StatelessWidget {
  const CraftsmanProfileScreen({super.key, required this.craftsman, this.readOnly = false});
  final Craftsman craftsman;

  /// Used by the craftsman's own "preview my profile" and by admin.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final c = craftsman;
    final s = context.watch<AppState>();
    final fav = s.favorites.contains(c.id);
    final reviews = c.reviews.where((r) => !r.flagged).toList();
    final pad = MediaQuery.paddingOf(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            stretch: true,
            backgroundColor: C.bg,
            surfaceTintColor: Colors.transparent,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconCircle(icon: PhosphorIconsBold.arrowLeft, label: 'Back', onTap: () => Navigator.pop(context)),
            ),
            actions: [
              if (!readOnly)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Pressable(
                    scale: 0.85,
                    semanticLabel: fav ? 'Remove from saved' : 'Save',
                    onTap: () => s.toggleFavorite(c.id),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: C.card,
                        shape: BoxShape.circle,
                        boxShadow: lift,
                      ),
                      child: AnimatedSwitcher(
                        duration: M.fast,
                        transitionBuilder: (w, a) => ScaleTransition(
                          scale: CurvedAnimation(parent: a, curve: M.spring),
                          child: w,
                        ),
                        child: Icon(fav ? PhosphorIconsFill.heart : PhosphorIconsBold.heart, key: ValueKey(fav), color: fav ? C.hotText : C.ink, size: 20),
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset('assets/photos/${c.photos.first}.jpg', fit: BoxFit.cover),
                    // Dark fade top and bottom keeps the buttons readable and melts the photo into the page.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withValues(alpha: .55), C.bg.withValues(alpha: 0), C.bg],
                          stops: [0, .4, 1],
                        ),
                      ),
                    ),
                    const Scanlines(opacity: .06),
                    // Volt strip along the bottom edge.
                    Positioned(left: 0, bottom: 0, width: 72, height: 4, child: ColoredBox(color: C.volt)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Hero(
                        tag: 'avatar-${c.id}',
                        child: Avatar(craftsman: c, size: 72),
                      ),
                      const Spacer(),
                      if (c.verified) const VerifiedStamp(animate: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Headline(c.name.split(' ').first, accent: c.name.split(' ').skip(1).join(' '), style: display(size: 44, weight: FontWeight.w800).copyWith(height: 1)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(c.trade.icon, size: 16),
                      const SizedBox(width: 6),
                      Text('${c.trade.local} · ${c.commune}, ${c.wilaya}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: S.lg),
                  _StatStrip(c: c),
                  const SizedBox(height: S.lg),
                  Text(c.bio, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: S.xl),
                  _RateCard(c: c),
                  const SizedBox(height: S.xl),
                  _title('Rating breakdown'),
                  _Bar(label: 'Punctuality', value: c.sub((r) => r.punctuality)),
                  _Bar(label: 'Pricing', value: c.sub((r) => r.pricing)),
                  _Bar(label: 'Quality', value: c.sub((r) => r.quality)),
                  const SizedBox(height: S.xl),
                  _title('Past work'),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: S.gutter),
                itemCount: c.photos.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => Pressable(
                  scale: 0.97,
                  onTap: () => _viewPhoto(context, c.photos[i]),
                  child: Hero(tag: 'photo-${c.id}-$i', child: Photo(c.photos[i], width: 200, height: 150)),
                ).enter(context, i),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: S.xl),
                  _title('Skills'),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final k in c.skills) _chip(k)]),
                  const SizedBox(height: S.lg),
                  _title('Works in'),
                  Wrap(spacing: 8, runSpacing: 8, children: [for (final w in c.wilayas) _chip(w, icon: PhosphorIconsBold.mapPin)]),
                  if (c.certificates.isNotEmpty) ...[
                    const SizedBox(height: S.lg),
                    _title('Certificates'),
                    for (final cert in c.certificates)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(PhosphorIconsBold.certificate, size: 18, color: C.teal),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(cert, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: S.xl),
                  Row(children: [Expanded(child: _title('Reviews (${reviews.length})'))]),
                  if (reviews.isEmpty) Text('No reviews yet.', style: Theme.of(context).textTheme.bodySmall),
                  for (final (i, r) in reviews.indexed) _ReviewTile(r: r).enter(context, i),
                  SizedBox(height: readOnly ? S.xxl : 110 + pad.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: readOnly
          ? null
          : Container(
              padding: EdgeInsets.fromLTRB(S.gutter, 12, S.gutter, 12 + pad.bottom),
              decoration: BoxDecoration(
                color: C.card,
                border: Border(top: BorderSide(color: C.line, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TagButton.light(
                      label: 'Get a quote',
                      onTap: () =>
                          Navigator.of(context).push(wipeRoute(fullscreenDialog: true, PostRequestScreen(direct: c, quoteOnly: true))),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TagButton(
                      label: c.available ? 'Book now' : 'Busy today',
                      icon: c.available ? PhosphorIconsBold.lightning : null,
                      onTap: c.available
                          ? () => Navigator.of(context).push(wipeRoute(fullscreenDialog: true, PostRequestScreen(direct: c)))
                          : null,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _viewPhoto(BuildContext context, String name) {
    final i = craftsman.photos.indexOf(name);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (_, _, _) => GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: Hero(
              tag: 'photo-${craftsman.id}-$i',
              child: InteractiveViewer(child: Image.asset('assets/photos/$name.jpg')),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(t, style: display(size: 18)),
  );

  Widget _chip(String t, {IconData? icon}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: C.card,
      borderRadius: BorderRadius.circular(R.pill),
      border: Border.all(color: C.line, width: 1.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 13), const SizedBox(width: 5)],
        Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.c});
  final Craftsman c;
  @override
  Widget build(BuildContext context) {
    Widget cell(String v, String k) => Expanded(
      child: Column(
        children: [
          Text(v, style: figs(size: 17, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(k, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5)),
        ],
      ),
    );
    Widget div() => Container(width: 1.5, height: 30, color: C.line);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: Row(
        children: [
          cell(c.rating == 0 ? 'New' : c.rating.toStringAsFixed(1), 'rating'),
          div(),
          cell('${c.jobsDone}', 'jobs done'),
          div(),
          cell('${c.years} yr', 'experience'),
          div(),
          cell('~${c.responseMins}m', 'replies in'),
        ],
      ),
    );
  }
}

class _RateCard extends StatelessWidget {
  const _RateCard({required this.c});
  final Craftsman c;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(S.lg),
      decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.lg - 4)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOURLY',
                  style: figs(size: 10.5, color: C.onFillSoft, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  dzd(c.hourly),
                  style: figs(size: 22, color: C.onFill, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Container(width: 1.5, height: 40, color: C.lineStrong),
          const SizedBox(width: S.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CALL-OUT',
                  style: figs(size: 10.5, color: C.onFillSoft, weight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  c.callout == 0 ? 'Free' : dzd(c.callout),
                  style: figs(size: 22, color: C.volt, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.label, required this.value});
  final String label;
  final double value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(R.pill),
              child: Stack(
                children: [
                  Container(height: 10, color: C.line),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: reduceMotion(context) ? value / 5 : 0, end: value / 5),
                    duration: const Duration(milliseconds: 700),
                    curve: M.out,
                    builder: (_, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(height: 10, color: C.volt),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(value.toStringAsFixed(1), style: figs(size: 13, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.r});
  final Review r;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
              Text(r.author, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Stars(value: r.average, size: 12),
              const Spacer(),
              Text(r.daysAgo == 0 ? 'today' : '${r.daysAgo}d ago', style: figs(size: 11, color: C.inkSoft)),
            ],
          ),
          const SizedBox(height: 6),
          Text(r.text),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(PhosphorIconsBold.sealCheck, size: 13, color: C.teal),
              const SizedBox(width: 4),
              Text(
                'Verified job on Fixy',
                style: figs(size: 10.5, color: C.teal, weight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

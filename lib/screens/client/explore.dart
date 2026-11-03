import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../widgets/icons.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'widgets.dart';

class ExploreFilter {
  const ExploreFilter({
    this.trade,
    this.availableOnly = false,
    this.verifiedOnly = false,
    this.minRating = 0,
    this.radiusKm = 10,
    this.wilaya = 'Alger',
    this.sort = 'distance',
  });
  final Trade? trade;
  final bool availableOnly;
  final bool verifiedOnly;
  final double minRating;
  final double radiusKm;
  final String wilaya;
  final String sort;

  ExploreFilter copyWith({
    Trade? trade,
    bool clearTrade = false,
    bool? availableOnly,
    bool? verifiedOnly,
    double? minRating,
    double? radiusKm,
    String? wilaya,
    String? sort,
  }) => ExploreFilter(
    trade: clearTrade ? null : (trade ?? this.trade),
    availableOnly: availableOnly ?? this.availableOnly,
    verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    minRating: minRating ?? this.minRating,
    radiusKm: radiusKm ?? this.radiusKm,
    wilaya: wilaya ?? this.wilaya,
    sort: sort ?? this.sort,
  );

  int get extraCount => (availableOnly ? 1 : 0) + (verifiedOnly ? 1 : 0) + (minRating > 0 ? 1 : 0) + (radiusKm != 10 ? 1 : 0);
}

/// Shared so Home can open Explore pre-filtered.
final exploreFilter = ValueNotifier(const ExploreFilter());

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  bool _map = true;
  Craftsman? _selected;
  final _mapCtl = MapController();

  List<Craftsman> _results(ExploreFilter f) {
    final list = craftsmen.where((c) {
      if (f.trade != null && c.trade != f.trade) return false;
      if (f.availableOnly && !c.available) return false;
      if (f.verifiedOnly && !c.verified) return false;
      if (c.rating < f.minRating) return false;
      if (!c.wilayas.contains(f.wilaya)) return false;
      return kmFrom(clientHome, c.location) <= f.radiusKm;
    }).toList();
    list.sort((a, b) => f.sort == 'rating' ? b.rating.compareTo(a.rating) : kmFrom(clientHome, a.location).compareTo(kmFrom(clientHome, b.location)));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ValueListenableBuilder(
      valueListenable: exploreFilter,
      builder: (context, f, _) {
        final results = _results(f);
        if (_selected != null && !results.contains(_selected)) _selected = null;
        return Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(duration: M.base, switchInCurve: M.out, child: _map ? _buildMap(f, results) : _buildList(results, top)),
            ),
            // Header floats over the map.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(S.gutter, top + 10, S.gutter, 10),
                decoration: BoxDecoration(
                  gradient: _map
                      ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.bg, C.bg.withValues(alpha: 0)], stops: const [.6, 1])
                      : null,
                  color: _map ? null : C.bg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(f.trade?.label ?? "All m'lems", style: display(size: 24))),
                        _Segmented(map: _map, onChanged: (v) => setState(() => _map = v)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        children: [
                          _FilterChip(
                            label: f.extraCount > 0 ? 'Filters · ${f.extraCount}' : 'Filters',
                            icon: PhosphorIconsBold.slidersHorizontal,
                            selected: f.extraCount > 0,
                            onTap: () => _openFilters(f),
                          ),
                          _FilterChip(label: 'All', selected: f.trade == null, onTap: () => exploreFilter.value = f.copyWith(clearTrade: true)),
                          for (final t in Trade.values)
                            _FilterChip(
                              label: t.label,
                              icon: t.icon,
                              selected: f.trade == t,
                              onTap: () => exploreFilter.value = f.copyWith(trade: t),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_map)
              Positioned(
                left: S.gutter,
                right: S.gutter,
                bottom: S.lg,
                child: AnimatedSwitcher(
                  duration: M.base,
                  switchInCurve: M.out,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (c, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, .25), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  ),
                  child: _selected != null
                      ? Container(
                          key: ValueKey(_selected!.id),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(R.lg), boxShadow: lift),
                          child: CraftsmanTile(c: _selected!),
                        )
                      : Container(
                          key: const ValueKey('count'),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(R.pill)),
                          child: Text(
                            results.isEmpty ? 'No one matches. Widen the radius.' : "${results.length} m'lems within ${f.radiusKm.round()} km · tap a pin",
                            textAlign: TextAlign.center,
                            style: figs(size: 12, color: C.bg, weight: FontWeight.w600),
                          ),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMap(ExploreFilter f, List<Craftsman> results) {
    return FlutterMap(
      key: const ValueKey('map'),
      mapController: _mapCtl,
      options: MapOptions(
        initialCenter: const LatLng(36.742, 3.075),
        initialZoom: 12.2,
        minZoom: 9,
        maxZoom: 17,
        onTap: (_, _) => setState(() => _selected = null),
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'dz.fixy.app',
          // Warm, low-contrast paper tint so pins stay the loudest thing on the map.
          tileBuilder: (context, tile, _) => ColorFiltered(colorFilter: ColorFilter.matrix(mapTint), child: tile),
        ),
        CircleLayer(
          circles: [
            CircleMarker(
              point: clientHome,
              radius: f.radiusKm * 1000,
              useRadiusInMeter: true,
              color: C.volt.withValues(alpha: .07),
              borderColor: C.volt,
              borderStrokeWidth: 1.5,
            ),
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(point: clientHome, width: 26, height: 26, child: const _MeDot()),
            for (final (i, c) in results.indexed)
              Marker(
                point: c.location,
                width: 46,
                height: 54,
                alignment: Alignment.topCenter,
                child: _Pin(
                  c: c,
                  selected: _selected == c,
                  index: i,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selected = c);
                    _mapCtl.move(c.location, _mapCtl.camera.zoom < 13 ? 13 : _mapCtl.camera.zoom);
                  },
                ),
              ),
          ],
        ),
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
          alignment: Alignment.bottomRight,
        ),
      ],
    );
  }

  Widget _buildList(List<Craftsman> results, double top) {
    if (results.isEmpty) {
      return Center(
        key: const ValueKey('empty'),
        child: Padding(
          padding: const EdgeInsets.all(S.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsBold.magnifyingGlass, size: 40, color: C.inkSoft),
              const SizedBox(height: 12),
              Text("No m'lem matches these filters", style: display(size: 18)),
              const SizedBox(height: 6),
              Text('Try a wider radius or turn off "Available now".', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              TagButton.light(label: 'Reset filters', expand: false, compact: true, onTap: () => exploreFilter.value = const ExploreFilter()),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      key: const ValueKey('list'),
      padding: EdgeInsets.fromLTRB(S.gutter, top + 116, S.gutter, S.xl),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => CraftsmanTile(c: results[i]).enter(context, i),
    );
  }

  void _openFilters(ExploreFilter f) {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
      builder: (_) => _FilterSheet(initial: f),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.map, required this.onChanged});
  final bool map;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    Widget half(bool isMap, IconData icon, String label) => Expanded(
      child: Pressable(
        onTap: () => onChanged(isMap),
        haptic: false,
        semanticLabel: label,
        child: SizedBox(
          height: 36,
          child: Center(
            child: AnimatedSwitcher(
              duration: M.fast,
              child: Icon(icon, key: ValueKey(map == isMap), size: 18, color: map == isMap ? C.onFill : C.ink),
            ),
          ),
        ),
      ),
    );
    return Container(
      width: 92,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: C.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: M.base,
            curve: M.out,
            alignment: map ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              width: 43,
              height: 36,
              decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.pill)),
            ),
          ),
          Row(children: [half(true, PhosphorIconsBold.mapTrifold, 'Map view'), half(false, PhosphorIconsBold.list, 'List view')]),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap, this.icon});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        haptic: false,
        child: AnimatedContainer(
          duration: M.fast,
          curve: M.out,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? C.volt : C.card,
            borderRadius: BorderRadius.circular(R.pill),
            border: Border.all(color: selected ? C.volt : C.line),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: selected ? C.onFill : C.ink), const SizedBox(width: 6)],
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? C.onFill : C.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.c, required this.selected, required this.onTap, required this.index});
  final Craftsman c;
  final bool selected;
  final VoidCallback onTap;
  final int index;
  @override
  Widget build(BuildContext context) {
    final pin = GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.18 : 1,
        duration: M.base,
        curve: M.spring,
        alignment: Alignment.bottomCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: M.fast,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected ? C.volt : (c.available ? C.card : C.bg),
                shape: BoxShape.circle,
                border: Border.all(color: selected ? C.card : C.line, width: selected ? 2 : 1),
                boxShadow: lift,
              ),
              child: Icon(c.trade.icon, size: 20, color: selected ? C.onFill : (c.available ? C.volt : C.inkSoft)),
            ),
            Container(width: 2, height: 8, color: selected ? C.volt : C.lineStrong),
          ],
        ),
      ),
    );
    if (reduceMotion(context)) return pin;
    return pin.animate(delay: (40 * index).ms).fadeIn(duration: 200.ms).moveY(begin: -14, end: 0, duration: 320.ms, curve: M.spring);
  }
}

class _MeDot extends StatelessWidget {
  const _MeDot();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB),
        shape: BoxShape.circle,
        border: Border.all(color: C.onFill, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6)],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});
  final ExploreFilter initial;
  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late ExploreFilter f = widget.initial;

  @override
  Widget build(BuildContext context) {
    final count = craftsmen.where((c) {
      if (f.trade != null && c.trade != f.trade) return false;
      if (f.availableOnly && !c.available) return false;
      if (f.verifiedOnly && !c.verified) return false;
      if (c.rating < f.minRating) return false;
      if (!c.wilayas.contains(f.wilaya)) return false;
      return kmFrom(clientHome, c.location) <= f.radiusKm;
    }).length;

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
              Expanded(child: Text('Filters', style: display(size: 22))),
              Pressable(
                onTap: () => setState(() => f = const ExploreFilter()),
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    'Reset',
                    style: TextStyle(fontWeight: FontWeight.w700, color: C.hotText),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: S.lg),
          _label('Wilaya'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final w in wilayas.take(5)) _choice(w, f.wilaya == w, () => setState(() => f = f.copyWith(wilaya: w)))],
          ),
          const SizedBox(height: S.lg),
          Row(
            children: [
              _label('Radius'),
              const Spacer(),
              Text('${f.radiusKm.round()} km', style: figs(size: 13, weight: FontWeight.w700)),
            ],
          ),
          Slider(
            value: f.radiusKm,
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: (v) => setState(() => f = f.copyWith(radiusKm: v)),
          ),
          _label('Minimum rating'),
          Wrap(
            spacing: 8,
            children: [
              for (final r in [0.0, 4.0, 4.5])
                _choice(r == 0 ? 'Any' : '${r.toStringAsFixed(1)}+', f.minRating == r, () => setState(() => f = f.copyWith(minRating: r))),
            ],
          ),
          const SizedBox(height: S.md),
          _toggle('Available now', f.availableOnly, (v) => setState(() => f = f.copyWith(availableOnly: v))),
          _toggle('Verified only', f.verifiedOnly, (v) => setState(() => f = f.copyWith(verifiedOnly: v))),
          const SizedBox(height: S.sm),
          _label('Sort by'),
          Wrap(
            spacing: 8,
            children: [
              _choice('Nearest', f.sort == 'distance', () => setState(() => f = f.copyWith(sort: 'distance'))),
              _choice('Top rated', f.sort == 'rating', () => setState(() => f = f.copyWith(sort: 'rating'))),
            ],
          ),
          const SizedBox(height: S.xl),
          TagButton(
            label: count == 0 ? 'No results' : "Show $count m'lems",
            onTap: count == 0
                ? null
                : () {
                    exploreFilter.value = f;
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t.toUpperCase(),
      style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
    ),
  );

  Widget _choice(String label, bool sel, VoidCallback onTap) => Pressable(
    onTap: onTap,
    haptic: false,
    child: AnimatedContainer(
      duration: M.fast,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: sel ? C.volt : C.bg,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: sel ? C.volt : C.line),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: sel ? C.onFill : C.ink),
      ),
    ),
  );

  Widget _toggle(String label, bool v, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        ),
        Switch(value: v, onChanged: onChanged),
      ],
    ),
  );
}

/// Desaturate to ~25% and lift toward the paper tone (#F4EEE3).

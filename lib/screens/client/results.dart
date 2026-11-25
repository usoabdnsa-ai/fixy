import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../services/provider_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/provider_card.dart';
import '../shared/router.dart';
import 'filters.dart';

/// Screen 7: search field, sort pills, active filters, provider cards.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.initial, this.autofocus = false});
  final ProviderQuery initial;
  final bool autofocus;
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late ProviderQuery _q = widget.initial;
  late final _text = TextEditingController(text: widget.initial.text);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final q = await push<ProviderQuery>(context, FiltersScreen(initial: _q));
    if (q != null) setState(() => _q = q);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final results = s.search(_q);
    final chips = <(String, ProviderQuery)>[
      if (_q.category != null) (_q.category!.label, _q.copyWith(category: () => null)),
      if (_q.wilaya != null) (_q.wilaya!, _q.copyWith(wilaya: () => null, communes: {})),
      for (final c in _q.communes) (c, _q.copyWith(communes: {..._q.communes}..remove(c))),
      if (_q.minRating > 0) ('${_q.minRating.toStringAsFixed(1).replaceAll('.', ',')}+ ★', _q.copyWith(minRating: 0)),
      if (_q.maxPrice != null) ('≤ ${_q.maxPrice} DA', _q.copyWith(maxPrice: () => null)),
      if (_q.availableToday) ('Disponible aujourd’hui', _q.copyWith(availableToday: false)),
      if (_q.weekend) ('Week-end', _q.copyWith(weekend: false)),
      if (_q.urgent) ('Urgences', _q.copyWith(urgent: false)),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(_q.category?.label ?? 'Rechercher')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.md),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    autofocus: widget.autofocus,
                    textInputAction: TextInputAction.search,
                    onChanged: (v) => setState(() => _q = _q.copyWith(text: v)),
                    decoration: InputDecoration(
                      hintText: 'Nom, métier, commune…',
                      prefixIcon: const Icon(PhosphorIconsBold.magnifyingGlass, size: 20),
                      suffixIcon: _text.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer',
                              icon: const Icon(PhosphorIconsBold.x, size: 18),
                              onPressed: () => setState(() {
                                _text.clear();
                                _q = _q.copyWith(text: '');
                              }),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: S.sm),
                Pressable(
                  onTap: _openFilters,
                  semanticLabel: 'Filtres',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: C.navy, borderRadius: BorderRadius.circular(R.md)),
                        child: const Icon(PhosphorIconsBold.slidersHorizontal, color: C.white, size: 21),
                      ),
                      if (_q.activeCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: C.turq, shape: BoxShape.circle, border: Border.all(color: C.bg, width: 2)),
                            child: Text('${_q.activeCount}', style: figs(size: 10.5, color: C.navy, weight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              children: [
                for (final sort in SortBy.values)
                  Padding(
                    padding: const EdgeInsets.only(right: S.sm),
                    child: ChoicePill(sort.label, selected: _q.sort == sort, onTap: () => setState(() => _q = _q.copyWith(sort: sort))),
                  ),
              ],
            ),
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final (label, without) in chips)
                      Pressable(
                        onTap: () => setState(() => _q = without),
                        semanticLabel: 'Retirer le filtre $label',
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(10, 5, 7, 5),
                          decoration: BoxDecoration(color: C.turqWash, borderRadius: BorderRadius.circular(R.pill)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(label, style: body(size: 12.5, weight: FontWeight.w600, color: C.turqText, height: 1.2)),
                              const SizedBox(width: 4),
                              const Icon(PhosphorIconsBold.x, size: 12, color: C.turqText),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                results.isEmpty ? 'Aucun artisan' : '${results.length} artisan${results.length > 1 ? 's' : ''}',
                style: body(size: 13.5, weight: FontWeight.w600, color: C.inkSoft),
              ),
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: PhosphorIconsBold.magnifyingGlass,
                      title: 'Aucun artisan ne correspond',
                      text: 'Essayez une autre commune, ou retirez quelques filtres.',
                      action: _q.activeCount > 0 ? 'Effacer les filtres' : null,
                      onAction: () => setState(() => _q = _q.cleared()),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.md),
                    itemBuilder: (_, i) => Rise(index: i, child: ProviderCard(results[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

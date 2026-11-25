import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../services/provider_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/kit.dart';

/// Screen 8: profession, wilaya/commune chips, minimum rating, DA price
/// slider, availability, sort. Returns the new query.
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key, required this.initial});
  final ProviderQuery initial;
  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late ProviderQuery _q = widget.initial;
  static const _maxSlider = 20000.0;

  void _set(ProviderQuery q) => setState(() => _q = q);

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().search(_q).length;
    final price = (_q.maxPrice ?? _maxSlider).toDouble();
    return Scaffold(
      backgroundColor: C.card,
      appBar: AppBar(
        backgroundColor: C.card,
        title: const Text('Filtres'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: S.sm),
            child: Btn.ghost('Réinitialiser', onTap: () => _set(ProviderQuery(text: _q.text))),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.sm, S.gutter, S.xl),
        children: [
          _Section('Métier', Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoicePill('Tous', selected: _q.category == null, onTap: () => _set(_q.copyWith(category: () => null))),
              for (final c in Category.values)
                ChoicePill(c.label, icon: c.icon, selected: _q.category == c, onTap: () => _set(_q.copyWith(category: () => c))),
            ],
          )),
          _Section('Wilaya', Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoicePill('Toutes', selected: _q.wilaya == null, onTap: () => _set(_q.copyWith(wilaya: () => null, communes: {}))),
              for (final w in wilayas.keys)
                ChoicePill(w, selected: _q.wilaya == w, onTap: () => _set(_q.copyWith(wilaya: () => w, communes: {}))),
            ],
          )),
          if (_q.wilaya != null)
            _Section('Communes', Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in wilayas[_q.wilaya]!)
                  ChoicePill(c, selected: _q.communes.contains(c), onTap: () {
                    final next = {..._q.communes};
                    next.contains(c) ? next.remove(c) : next.add(c);
                    _set(_q.copyWith(communes: next));
                  }),
              ],
            )),
          _Section('Note minimale', Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in [0.0, 4.0, 4.5, 4.8])
                ChoicePill(r == 0 ? 'Toutes' : '${rating1(r)}+ ★', selected: _q.minRating == r, onTap: () => _set(_q.copyWith(minRating: r))),
            ],
          )),
          _Section(
            'Prix indicatif maximum',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_q.maxPrice == null ? 'Tous les prix' : 'Jusqu’à ${da(_q.maxPrice!)}', style: figs(size: 16, weight: FontWeight.w700, color: C.turqText)),
                Slider(
                  value: price,
                  min: 1000,
                  max: _maxSlider,
                  divisions: 38,
                  label: price >= _maxSlider ? 'Tous' : da(price.round()),
                  onChanged: (v) => _set(_q.copyWith(maxPrice: () => v >= _maxSlider ? null : v.round())),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(da(1000), style: figs(size: 12.5, color: C.inkSoft)), Text('${da(20000)} +', style: figs(size: 12.5, color: C.inkSoft))],
                ),
                const SizedBox(height: 4),
                Text('Prix « à partir de » affiché par l’artisan, à confirmer avec lui.', style: body(size: 12.5, color: C.inkSoft)),
              ],
            ),
          ),
          _Section('Disponibilité', Column(
            children: [
              _Check('Disponible aujourd’hui', _q.availableToday, (v) => _set(_q.copyWith(availableToday: v))),
              _Check('Disponible le week-end', _q.weekend, (v) => _set(_q.copyWith(weekend: v))),
              _Check('Accepte les urgences', _q.urgent, (v) => _set(_q.copyWith(urgent: v))),
            ],
          )),
          _Section('Trier par', Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final s in SortBy.values) ChoicePill(s.label, selected: _q.sort == s, onTap: () => _set(_q.copyWith(sort: s)))],
          )),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.md),
          decoration: const BoxDecoration(color: C.card, border: Border(top: BorderSide(color: C.line))),
          child: Btn(
            count == 0 ? 'Aucun résultat' : 'Afficher $count résultat${count > 1 ? 's' : ''}',
            onTap: count == 0 ? null : () => Navigator.pop(context, _q),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.label, this.child);
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: title(size: 16)), const SizedBox(height: S.md), child],
    ),
  );
}

class _Check extends StatelessWidget {
  const _Check(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => onChanged(!value),
    scale: .99,
    semanticLabel: label,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 24, height: 24, child: Checkbox(value: value, onChanged: (v) => onChanged(v ?? false))),
          const SizedBox(width: S.md),
          Expanded(child: Text(label, style: body(weight: FontWeight.w500))),
        ],
      ),
    ),
  );
}

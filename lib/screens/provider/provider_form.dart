import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/native.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/router.dart';

/// Screen 15 (registration) and screen 18 (edit): photo with
/// "Ajouter une photo" / "Modifier la photo", name, phone, trade chips,
/// wilaya coverage, services & DA rates, experience description.
class ProviderFormScreen extends StatefulWidget {
  const ProviderFormScreen.register({super.key}) : editing = false;
  const ProviderFormScreen.edit({super.key}) : editing = true;
  final bool editing;
  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _RateRow {
  _RateRow(String name, int? price) : name = TextEditingController(text: name), price = TextEditingController(text: price?.toString() ?? '');
  final TextEditingController name, price;
  void dispose() {
    name.dispose();
    price.dispose();
  }
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  late final AppState _s = context.read<AppState>();
  late final Provider? _existing = _s.myProvider;
  late final _name = TextEditingController(text: _existing?.name ?? _s.user?.name ?? '');
  late final _phone = TextEditingController(text: phoneFmt(_existing?.phone ?? _s.user?.phone ?? ''));
  late final _bio = TextEditingController(text: _existing?.bio ?? '');
  late final _years = TextEditingController(text: (_existing?.yearsExperience ?? 0) == 0 ? '' : '${_existing!.yearsExperience}');
  late String? _photo = _existing?.photo;
  late Category? _category = _existing?.category;
  late String _wilaya = _existing?.wilaya ?? 'Alger';
  late String? _commune = _existing?.commune;
  late Set<String> _coverage = {...?_existing?.coverage};
  late bool _available = _existing?.available ?? true;
  late bool _weekend = _existing?.availableWeekend ?? false;
  late bool _urgent = _existing?.urgent ?? false;
  late final List<_RateRow> _rates = _existing == null || _existing.services.isEmpty
      ? [_RateRow('Diagnostic / déplacement', null)]
      : [for (final r in _existing.services) _RateRow(r.name, r.priceDa)];
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _bio, _years]) {
      c.dispose();
    }
    for (final r in _rates) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    final u = _s.user!;
    String? problem;
    if (_category == null) problem = 'Choisissez votre métier.';
    if (_commune == null) problem ??= 'Choisissez votre commune.';
    final services = <ServiceRate>[];
    for (final r in _rates) {
      final n = r.name.text.trim();
      final pr = int.tryParse(r.price.text.replaceAll(RegExp(r'\D'), ''));
      if (n.isEmpty && r.price.text.trim().isEmpty) continue;
      if (n.isEmpty || pr == null || pr <= 0) {
        problem ??= 'Chaque service doit avoir un nom et un prix en DA.';
        continue;
      }
      services.add(ServiceRate(name: n, priceDa: pr));
    }
    if (services.isEmpty) problem ??= 'Ajoutez au moins un service avec son prix.';
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final p = Provider(
      id: u.id,
      name: _name.text.trim(),
      phone: _phone.text,
      category: _category!,
      wilaya: _wilaya,
      commune: _commune!,
      coverage: _coverage.where((c) => c != _commune).toList(),
      bio: _bio.text.trim(),
      yearsExperience: int.tryParse(_years.text) ?? 0,
      services: services,
      photo: _photo,
      verified: _existing?.verified ?? false,
      available: _available,
      availableWeekend: _weekend,
      urgent: _urgent,
    );
    setState(() => _busy = true);
    try {
      await _s.saveProvider(p);
      // Keep the account's name and phone in step with the public profile.
      u
        ..name = p.name
        ..phone = p.phone;
      await _s.updateUser(u);
      if (!mounted) return;
      if (widget.editing) {
        toast(context, 'Profil enregistré');
        Navigator.pop(context);
      } else {
        goHome(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = _photo != null && _photo!.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing ? 'Modifier mon profil' : 'Mon profil d’artisan'),
        automaticallyImplyLeading: widget.editing,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          if (!widget.editing) ...[
            Text('Les clients vous trouveront grâce à ces informations. Vous pourrez tout modifier plus tard.', style: body(color: C.inkSoft)),
            const SizedBox(height: S.xl),
          ],
          Center(
            child: Column(
              children: [
                Pressable(
                  onTap: _pickPhoto,
                  semanticLabel: hasPhoto ? 'Modifier la photo' : 'Ajouter une photo',
                  child: Stack(
                    children: [
                      Avatar(photo: _photo, size: 112, ring: true),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(color: C.turq, shape: BoxShape.circle, border: Border.all(color: C.white, width: 3)),
                          child: const Icon(PhosphorIconsBold.camera, size: 17, color: C.navy),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: S.sm),
                Btn.ghost(hasPhoto ? 'Modifier la photo' : 'Ajouter une photo', onTap: _pickPhoto),
              ],
            ),
          ),
          const _Head('Informations'),
          TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(PhosphorIconsBold.user, size: 20))),
          const SizedBox(height: S.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            decoration: const InputDecoration(labelText: 'Téléphone (visible par les clients)', prefixIcon: Icon(PhosphorIconsBold.phone, size: 20)),
          ),
          const _Head('Métier'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in Category.values) ChoicePill(c.label, icon: c.icon, selected: _category == c, onTap: () => setState(() => _category = c))],
          ),
          const _Head('Zone d’intervention'),
          Text('Wilaya', style: body(size: 13.5, color: C.inkSoft)),
          const SizedBox(height: S.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final w in wilayas.keys)
                ChoicePill(w, selected: _wilaya == w, onTap: () => setState(() {
                  _wilaya = w;
                  _commune = null;
                  _coverage = {};
                })),
            ],
          ),
          const SizedBox(height: S.lg),
          Text('Votre commune', style: body(size: 13.5, color: C.inkSoft)),
          const SizedBox(height: S.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final c in wilayas[_wilaya]!) ChoicePill(c, selected: _commune == c, onTap: () => setState(() => _commune = c))],
          ),
          if (_commune != null) ...[
            const SizedBox(height: S.lg),
            Text('Vous vous déplacez aussi à…', style: body(size: 13.5, color: C.inkSoft)),
            const SizedBox(height: S.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in wilayas[_wilaya]!.where((c) => c != _commune))
                  ChoicePill(c, selected: _coverage.contains(c), onTap: () => setState(() => _coverage.contains(c) ? _coverage.remove(c) : _coverage.add(c))),
              ],
            ),
          ],
          const _Head('Services et tarifs (DA)'),
          for (final (i, r) in _rates.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: S.sm),
              child: Row(
                children: [
                  Expanded(flex: 6, child: TextField(controller: r.name, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Service'))),
                  const SizedBox(width: S.sm),
                  Expanded(
                    flex: 4,
                    child: TextField(
                      controller: r.price,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(7)],
                      decoration: const InputDecoration(hintText: 'Prix', suffixText: 'DA'),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Retirer ce service',
                    icon: const Icon(PhosphorIconsBold.trash, size: 19, color: C.inkSoft),
                    onPressed: _rates.length == 1
                        ? null
                        : () => setState(() {
                            _rates.removeAt(i).dispose();
                          }),
                  ),
                ],
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: Btn.ghost('Ajouter un service', icon: PhosphorIconsBold.plus, onTap: () => setState(() => _rates.add(_RateRow('', null)))),
          ),
          const _Head('Expérience'),
          TextField(
            controller: _years,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
            decoration: const InputDecoration(labelText: 'Années d’expérience', prefixIcon: Icon(PhosphorIconsBold.briefcase, size: 20)),
          ),
          const SizedBox(height: S.md),
          TextField(
            controller: _bio,
            minLines: 3,
            maxLines: 6,
            maxLength: 400,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Présentez votre savoir-faire : spécialités, matériel, délais…'),
          ),
          const _Head('Disponibilités'),
          _SwitchRow('Disponible aujourd’hui', _available, (v) => setState(() => _available = v)),
          _SwitchRow('Je travaille le week-end', _weekend, (v) => setState(() => _weekend = v)),
          _SwitchRow('J’accepte les urgences', _urgent, (v) => setState(() => _urgent = v)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: S.lg),
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.warning, size: 18, color: C.red),
                  const SizedBox(width: S.sm),
                  Expanded(child: Text(_error!, style: body(size: 14, color: C.red, weight: FontWeight.w600))),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.md),
          decoration: const BoxDecoration(color: C.card, border: Border(top: BorderSide(color: C.line))),
          child: Btn(widget.editing ? 'Enregistrer' : 'Créer mon profil', loading: _busy, onTap: _save),
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final p = await pickPhoto(context, title: _photo == null ? 'Ajouter une photo' : 'Modifier la photo', allowRemove: _photo != null && _photo!.isNotEmpty);
    if (p != null) setState(() => _photo = p.isEmpty ? null : p);
  }
}

class _Head extends StatelessWidget {
  const _Head(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: S.xl, bottom: S.md),
    child: Text(text, style: title(size: 17)),
  );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: body(weight: FontWeight.w500))),
      Switch(value: value, onChanged: onChanged),
    ],
  );
}

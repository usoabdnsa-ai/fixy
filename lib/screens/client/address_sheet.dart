import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';

/// Pick the address searches start from (home location pill).
Future<void> showAddressSheet(BuildContext context) => showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  builder: (ctx) {
    final s = ctx.watch<AppState>();
    final list = s.user?.addresses ?? [];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Où avez-vous besoin d’un artisan ?', style: title(size: 18)),
            const SizedBox(height: S.md),
            for (final a in list)
              _AddressTile(a: a, selected: identical(a, s.location), onTap: () {
                s.setLocation(a);
                Navigator.pop(ctx);
              }),
            const SizedBox(height: S.sm),
            Btn.outline('Ajouter une adresse', icon: PhosphorIconsBold.plus, onTap: () async {
              final a = await showAddressEditor(ctx);
              if (a == null || !ctx.mounted) return;
              final u = s.user!;
              u.addresses = [...u.addresses, a];
              if (await attempt(ctx, () => s.updateUser(u))) s.setLocation(a);
            }),
          ],
        ),
      ),
    );
  },
);

class _AddressTile extends StatelessWidget {
  const _AddressTile({required this.a, required this.selected, required this.onTap});
  final SavedAddress a;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: S.sm),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? C.turqWash : C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: selected ? C.turq : C.line, width: selected ? 1.6 : 1),
      ),
      child: Row(
        children: [
          IconTile(icon: a.label.toLowerCase().contains('parent') ? PhosphorIconsBold.users : PhosphorIconsBold.houseLine, size: 38),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.label, style: body(size: 15, weight: FontWeight.w700)),
                Text(a.full, maxLines: 2, overflow: TextOverflow.ellipsis, style: body(size: 13, color: C.inkSoft)),
              ],
            ),
          ),
          if (selected) const Icon(PhosphorIconsFill.checkCircle, color: C.turqText, size: 22),
        ],
      ),
    ),
  );
}

/// Add or edit a saved address ("Domicile", "Parents", …).
Future<SavedAddress?> showAddressEditor(BuildContext context, {SavedAddress? initial}) => showModalBottomSheet<SavedAddress>(
  context: context,
  isScrollControlled: true,
  builder: (ctx) => _AddressEditor(initial: initial),
);

class _AddressEditor extends StatefulWidget {
  const _AddressEditor({this.initial});
  final SavedAddress? initial;
  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late final _line = TextEditingController(text: widget.initial?.line ?? '');
  late String _wilaya = widget.initial?.wilaya ?? 'Alger';
  late String _commune = widget.initial?.commune ?? wilayas['Alger']!.first;
  String? _error;

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    super.dispose();
  }

  void _save() {
    if (_label.text.trim().isEmpty || _line.text.trim().length < 4) {
      setState(() => _error = 'Donnez un nom à l’adresse et indiquez la rue.');
      return;
    }
    Navigator.pop(context, SavedAddress(label: _label.text.trim(), line: _line.text.trim(), commune: _commune, wilaya: _wilaya));
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.initial == null ? 'Nouvelle adresse' : 'Modifier l’adresse', style: title(size: 18)),
            const SizedBox(height: S.lg),
            TextField(controller: _label, decoration: const InputDecoration(labelText: 'Nom (ex. Domicile, Parents)'), textCapitalization: TextCapitalization.sentences),
            const SizedBox(height: S.md),
            TextField(controller: _line, decoration: const InputDecoration(labelText: 'Rue, bâtiment, appartement')),
            const SizedBox(height: S.lg),
            Text('Wilaya', style: body(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: S.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final w in wilayas.keys)
                  ChoicePill(w, selected: w == _wilaya, onTap: () => setState(() {
                    _wilaya = w;
                    _commune = wilayas[w]!.first;
                  })),
              ],
            ),
            const SizedBox(height: S.lg),
            Text('Commune', style: body(size: 14, weight: FontWeight.w700)),
            const SizedBox(height: S.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final c in wilayas[_wilaya]!) ChoicePill(c, selected: c == _commune, onTap: () => setState(() => _commune = c))],
            ),
            if (_error != null) Padding(padding: const EdgeInsets.only(top: S.md), child: Text(_error!, style: body(size: 13.5, color: C.red, weight: FontWeight.w600))),
            const SizedBox(height: S.xl),
            Btn('Enregistrer', onTap: _save),
          ],
        ),
      ),
    ),
  );
}

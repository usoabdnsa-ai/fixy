import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/address_sheet.dart';
import '../client/provider_profile.dart';
import '../provider/provider_form.dart';
import 'router.dart';

/// Screen 20: profile card, editable personal info, saved addresses,
/// account settings, notification switches, "Se déconnecter".
/// For a prestataire it also links to the profile editor (screen 18).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final u = s.user;
    if (u == null) return const SizedBox.shrink();
    final pro = s.myProvider;
    final isPro = u.role == Role.prestataire;

    Future<void> save() => attempt(context, () => s.updateUser(u));

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          AppCard(
            child: Row(
              children: [
                Avatar(photo: pro?.photo, size: 60),
                const SizedBox(width: S.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u.name, style: title(size: 18)),
                      Text(phoneFmt(u.phone), style: figs(size: 14, color: C.inkSoft, weight: FontWeight.w500)),
                      if (u.email != null) Text(u.email!, style: body(size: 13.5, color: C.inkSoft)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: C.turqWash, borderRadius: BorderRadius.circular(R.pill)),
                        child: Text(isPro ? 'Prestataire · ${pro?.category.label ?? ''}' : 'Client', style: body(size: 12, weight: FontWeight.w700, color: C.turqText)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Modifier mes informations',
                  icon: const Icon(PhosphorIconsBold.pencilSimple, size: 20),
                  onPressed: () => isPro ? push(context, const ProviderFormScreen.edit()) : _editInfo(context, s, u),
                ),
              ],
            ),
          ),
          if (isPro && pro != null) ...[
            const SizedBox(height: S.md),
            _Group(children: [
              _Tile(icon: PhosphorIconsBold.notePencil, label: 'Modifier mon profil professionnel', onTap: () => push(context, const ProviderFormScreen.edit())),
              _Tile(icon: PhosphorIconsBold.eye, label: 'Voir mon profil public', onTap: () => push(context, ProviderProfileScreen(providerId: pro.id, preview: true))),
            ]),
          ],
          if (!isPro) ...[
            const SizedBox(height: S.xl),
            SectionHeader('Adresses enregistrées', action: 'Ajouter', onAction: () async {
              final a = await showAddressEditor(context);
              if (a == null) return;
              u.addresses = [...u.addresses, a];
              await save();
            }),
            if (u.addresses.isEmpty)
              Text('Ajoutez votre domicile pour remplir vos demandes plus vite.', style: body(size: 14, color: C.inkSoft))
            else
              _Group(children: [
                for (final (i, a) in u.addresses.indexed)
                  _Tile(
                    icon: a.label.toLowerCase().contains('parent') ? PhosphorIconsBold.users : PhosphorIconsBold.houseLine,
                    label: a.label,
                    sub: a.full,
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Options',
                      color: C.card,
                      icon: const Icon(PhosphorIconsBold.pencilSimple, size: 18, color: C.inkSoft),
                      onSelected: (v) async {
                        if (v == 'edit') {
                          final b = await showAddressEditor(context, initial: a);
                          if (b == null) return;
                          u.addresses = [...u.addresses]..[i] = b;
                        } else {
                          u.addresses = [...u.addresses]..removeAt(i);
                        }
                        await save();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Modifier')),
                        PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                      ],
                    ),
                  ),
              ]),
          ],
          const SizedBox(height: S.xl),
          const SectionHeader('Notifications'),
          _Group(children: [
            _SwitchTile(
              label: isPro ? 'Nouvelles demandes' : 'Réponses à mes demandes',
              value: u.notifyRequests,
              onChanged: (v) {
                u.notifyRequests = v;
                save();
              },
            ),
            _SwitchTile(
              label: 'Conseils et nouveautés Fixy',
              value: u.notifyPromos,
              onChanged: (v) {
                u.notifyPromos = v;
                save();
              },
            ),
          ]),
          const SizedBox(height: S.xl),
          const SectionHeader('Compte'),
          _Group(children: [
            _Tile(icon: PhosphorIconsBold.shieldCheck, label: 'Confidentialité', sub: 'Votre numéro n’est visible que par les artisans à qui vous écrivez.'),
            _Tile(icon: PhosphorIconsBold.info, label: 'À propos de Fixy', sub: 'Version MVP 1.0 · Vos artisans de confiance en Algérie'),
          ]),
          const SizedBox(height: S.xl),
          Btn.danger('Se déconnecter', icon: PhosphorIconsBold.signOut, onTap: () async {
            if (await confirmDialog(context, title: 'Se déconnecter ?', text: 'Vous pourrez vous reconnecter avec votre numéro et votre mot de passe.', confirm: 'Se déconnecter', danger: true) &&
                context.mounted) {
              await s.logout();
              if (context.mounted) goHome(context);
            }
          }),
        ],
      ),
    );
  }

  Future<void> _editInfo(BuildContext context, AppState s, AppUser u) async {
    final name = TextEditingController(text: u.name);
    final phone = TextEditingController(text: phoneFmt(u.phone));
    final email = TextEditingController(text: u.email ?? '');
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mes informations', style: title(size: 18)),
                const SizedBox(height: S.lg),
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nom complet'), textCapitalization: TextCapitalization.words),
                const SizedBox(height: S.md),
                TextField(controller: phone, decoration: const InputDecoration(labelText: 'Téléphone'), keyboardType: TextInputType.phone),
                const SizedBox(height: S.md),
                TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail (facultatif)'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: S.xl),
                Btn('Enregistrer', onTap: () => Navigator.pop(ctx, true)),
              ],
            ),
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final before = (u.name, u.phone, u.email);
    u
      ..name = name.text.trim().isEmpty ? u.name : name.text.trim()
      ..phone = phone.text
      ..email = email.text.trim().isEmpty ? null : email.text.trim().toLowerCase();
    if (!await attempt(context, () => s.updateUser(u))) {
      u
        ..name = before.$1
        ..phone = before.$2
        ..email = before.$3;
    } else if (context.mounted) {
      toast(context, 'Informations enregistrées');
    }
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: Column(
      children: [
        for (final (i, c) in children.indexed) ...[if (i > 0) const Divider(height: 1, indent: 60), c],
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, this.sub, this.onTap, this.trailing});
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: S.lg, vertical: 12),
      child: Row(
        children: [
          IconTile(icon: icon, size: 34),
          const SizedBox(width: S.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: body(size: 15, weight: FontWeight.w600)),
                if (sub != null) Text(sub!, style: body(size: 13, color: C.inkSoft)),
              ],
            ),
          ),
          ?trailing,
          if (trailing == null && onTap != null) const Icon(PhosphorIconsBold.caretRight, size: 16, color: C.inkFaint),
        ],
      ),
    );
    return onTap == null ? row : Pressable(onTap: onTap, scale: .99, child: row);
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({required this.label, required this.value, required this.onChanged});
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(S.lg, 6, S.sm, 6),
    child: Row(
      children: [
        const IconTile(icon: PhosphorIconsBold.bell, size: 34),
        const SizedBox(width: S.md),
        Expanded(child: Text(label, style: body(size: 15, weight: FontWeight.w600))),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import '../shared/auth.dart';
import 'widgets.dart';
import '../../data/models.dart';
import '../shared/mode_switch.dart';

void signOut(BuildContext context) {
  context.read<AppState>().signOut();
  Navigator.of(context).pushAndRemoveUntil(fadeRoute(const AuthScreen()), (_) => false);
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String _lang = 'FR';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final saved = craftsmen.where((c) => s.favorites.contains(c.id)).toList();
    return TabPage(
      eyebrow: 'AMINA BELKACEM',
      title: 'Your',
      accent: 'account',
      children: [
        TagCard(
          raised: true,
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: C.voltWash,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: C.line),
                ),
                alignment: Alignment.center,
                child: Text('AB', style: display(size: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(clientName, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 2),
                    Text('+213 ${s.phone.isEmpty ? '0555 12 34 56' : s.phone}', style: figs(size: 12, color: C.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        Row(
          children: [
            _stat('${s.clientJobs.length}', 'jobs posted'),
            const SizedBox(width: 10),
            _stat('${s.clientJobs.where((j) => j.rated).length + 4}', 'reviews given'),
            const SizedBox(width: 10),
            _stat('2024', 'member since'),
          ],
        ),
        const SizedBox(height: S.xl),
        Text("Saved m'lems", style: display(size: 18)),
        const SizedBox(height: 10),
        if (saved.isEmpty) Text('Tap the heart on a profile to keep it here.', style: Theme.of(context).textTheme.bodySmall),
        for (final c in saved)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: CraftsmanTile(c: c),
          ),
        const SizedBox(height: S.lg),
        const ModeSwitch(to: Role.craftsman),
        const SizedBox(height: S.lg),
        Text('Settings', style: display(size: 18)),
        const SizedBox(height: 10),
        _row(PhosphorIconsBold.mapPin, 'Addresses', '${s.address.label} · ${s.address.commune}'),
        _row(PhosphorIconsBold.bell, 'Notifications', 'Quotes, messages'),
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: C.line, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(PhosphorIconsBold.translate, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Language', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final l in ['العربية', 'FR', 'EN'])
                Pressable(
                  haptic: false,
                  onTap: () => setState(() => _lang = l),
                  child: AnimatedContainer(
                    duration: M.fast,
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: _lang == l ? C.volt : C.bg, borderRadius: BorderRadius.circular(R.pill)),
                    child: Text(
                      l,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: _lang == l ? C.onFill : C.ink),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const ThemeSwitch(),
        _row(PhosphorIconsBold.shieldCheck, 'Safety & trust', 'How we verify m\'lems'),
        _row(PhosphorIconsBold.question, 'Help', 'FAQ, contact Fixy'),
        const SizedBox(height: S.lg),
        TagButton.light(label: 'Sign out', icon: PhosphorIconsBold.signOut, onTap: () => signOut(context)),
        const SizedBox(height: S.lg),
        Center(
          child: Text('Fixy prototype · v0.1 · mock data', style: figs(size: 10.5, color: C.inkSoft)),
        ),
      ],
    );
  }

  Widget _stat(String v, String k) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: Column(
        children: [
          Text(v, style: figs(size: 18, weight: FontWeight.w700)),
          Text(k, style: TextStyle(fontSize: 11.5, color: C.inkSoft)),
        ],
      ),
    ),
  );

  Widget _row(IconData icon, String title, String sub) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: TagCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => toast(context, '$title (prototype)'),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Text(sub, style: TextStyle(fontSize: 12.5, color: C.inkSoft)),
          const SizedBox(width: 6),
          Icon(PhosphorIconsBold.caretRight, size: 14, color: C.inkSoft),
        ],
      ),
    ),
  );
}

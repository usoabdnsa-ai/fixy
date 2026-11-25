import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/router.dart';

/// Screen 4: choose "Client" or "Prestataire", then "Continuer".
class AccountTypeScreen extends StatefulWidget {
  const AccountTypeScreen({super.key});
  @override
  State<AccountTypeScreen> createState() => _AccountTypeScreenState();
}

class _AccountTypeScreenState extends State<AccountTypeScreen> {
  Role? _role;
  bool _busy = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final ok = await attempt(context, () => context.read<AppState>().chooseRole(_role!));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) goHome(context);
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AppState>().user?.firstName ?? '';
    return Scaffold(
      backgroundColor: C.card,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, S.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bienvenue $name !', style: title(size: 28)),
              const SizedBox(height: S.sm),
              Text('Comment souhaitez-vous utiliser Fixy ?', style: body(color: C.inkSoft)),
              const SizedBox(height: S.xl),
              Rise(
                child: _TypeCard(
                  icon: PhosphorIconsBold.house,
                  heading: 'Client',
                  text: 'Je cherche un artisan pour un service à domicile.',
                  selected: _role == Role.client,
                  onTap: () => setState(() => _role = Role.client),
                ),
              ),
              const SizedBox(height: S.md),
              Rise(
                index: 1,
                child: _TypeCard(
                  icon: PhosphorIconsBold.toolbox,
                  heading: 'Prestataire',
                  text: 'Je propose mes services et je reçois des demandes.',
                  selected: _role == Role.prestataire,
                  onTap: () => setState(() => _role = Role.prestataire),
                ),
              ),
              const Spacer(),
              Btn('Continuer', loading: _busy, onTap: _role == null ? null : _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.icon, required this.heading, required this.text, required this.selected, required this.onTap});
  final IconData icon;
  final String heading, text;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: heading,
    child: AnimatedContainer(
      duration: M.fast,
      curve: M.out,
      padding: const EdgeInsets.all(S.lg),
      decoration: BoxDecoration(
        color: selected ? C.turqWash : C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: selected ? C.turq : C.line, width: selected ? 2 : 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: selected ? C.turq : C.bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: C.navy, size: 26),
          ),
          const SizedBox(width: S.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(heading, style: title(size: 18)),
                const SizedBox(height: 2),
                Text(text, style: body(size: 14, color: C.inkSoft)),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: M.fast,
            child: selected
                ? const Icon(PhosphorIconsFill.checkCircle, key: ValueKey(1), color: C.turqText, size: 26)
                : Container(key: const ValueKey(0), width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.lineStrong, width: 1.6))),
          ),
        ],
      ),
    ),
  );
}

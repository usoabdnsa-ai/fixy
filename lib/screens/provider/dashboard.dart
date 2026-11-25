import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../../widgets/shell.dart';
import '../shared/router.dart';
import 'manage_requests.dart';
import 'provider_form.dart';

/// Screen 16: photo, profile completion bar, 2×2 status counters,
/// incoming request preview.
class ProviderDashboard extends StatelessWidget {
  const ProviderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.myProvider;
    if (p == null) return const SizedBox.shrink();
    final pending = s.incoming.where((r) => r.status == RequestStatus.enAttente).toList();
    final rating = s.rating(p.id);
    final pct = (p.completion * 100).round();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: C.navy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Avatar(photo: p.photo, size: 58, ring: true),
                          const SizedBox(width: S.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bonjour ${p.name.split(' ').first}', style: title(size: 22, color: C.white)),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text('${p.category.label} · ', style: body(size: 14, color: const Color(0xFFB7C4D3))),
                                    const Icon(PhosphorIconsFill.star, size: 14, color: C.star),
                                    const SizedBox(width: 3),
                                    Text(
                                      rating.count == 0 ? 'Nouveau' : '${rating.average.toStringAsFixed(1).replaceAll('.', ',')} (${rating.count})',
                                      style: figs(size: 14, color: C.white),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: S.lg),
                      _AvailabilityToggle(
                        on: p.available,
                        onChanged: (v) {
                          p.available = v;
                          attempt(context, () => s.saveProvider(p));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, S.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Rise(
                    child: AppCard(
                      onTap: pct < 100 ? () => push(context, const ProviderFormScreen.edit()) : null,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Profil complété', style: body(size: 15, weight: FontWeight.w700)),
                              ),
                              Text(
                                '$pct %',
                                style: figs(size: 16, weight: FontWeight.w800, color: C.turqText),
                              ),
                            ],
                          ),
                          const SizedBox(height: S.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(R.pill),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: p.completion),
                              duration: const Duration(milliseconds: 700),
                              curve: M.out,
                              builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 10, backgroundColor: C.line, color: C.turq),
                            ),
                          ),
                          if (pct < 100) ...[const SizedBox(height: S.sm), Text(_nextTip(p), style: body(size: 13.5, color: C.inkSoft))],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: S.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: S.md,
                    crossAxisSpacing: S.md,
                    childAspectRatio: 1.55,
                    children: [
                      _Counter('Nouvelles demandes', s.newIncoming, PhosphorIconsBold.bellRinging, C.turqText, C.turqWash, 1),
                      _Counter('En attente', s.incomingCount(RequestStatus.enAttente), PhosphorIconsBold.hourglass, C.amber, C.amberWash, 1),
                      _Counter('Acceptées', s.incomingCount(RequestStatus.acceptee), PhosphorIconsBold.check, C.blue, C.blueWash, 1),
                      _Counter('Terminées', s.incomingCount(RequestStatus.terminee), PhosphorIconsBold.checkCircle, C.green, C.greenWash, 1),
                    ].indexed.map((e) => Rise(index: e.$1 + 1, child: e.$2)).toList(),
                  ),
                  const SizedBox(height: S.xl),
                  SectionHeader('Demandes à traiter', action: pending.isEmpty ? null : 'Tout voir', onAction: () => AppShell.of(context)?.go(1)),
                  if (pending.isEmpty)
                    AppCard(
                      border: true,
                      child: Row(
                        children: [
                          const IconTile(icon: PhosphorIconsBold.checkCircle, size: 40),
                          const SizedBox(width: S.md),
                          Expanded(
                            child: Text('Vous êtes à jour : aucune demande en attente.', style: body(size: 14.5, color: C.inkSoft)),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final r in pending.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: S.md),
                        child: IncomingRequestCard(r),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _nextTip(Provider p) {
    if (p.photo == null) return 'Ajoutez une photo : les clients font plus confiance à un visage.';
    if (p.bio.trim().length < 30) return 'Décrivez votre savoir-faire en quelques lignes.';
    if (p.coverage.isEmpty) return 'Indiquez les communes où vous vous déplacez.';
    if (p.yearsExperience == 0) return 'Indiquez vos années d’expérience.';
    return 'Ajoutez vos tarifs.';
  }
}

class _Counter extends StatelessWidget {
  const _Counter(this.label, this.value, this.icon, this.fg, this.bg, this.tab);
  final String label;
  final int value;
  final IconData icon;
  final Color fg, bg;
  final int tab;
  @override
  Widget build(BuildContext context) => AppCard(
    onTap: () => AppShell.of(context)?.go(tab),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon: icon, size: 32, color: fg, wash: bg),
            const Spacer(),
            Text('$value', style: figs(size: 26, weight: FontWeight.w800)),
          ],
        ),
        const Spacer(),
        Text(
          label,
          style: body(size: 13.5, weight: FontWeight.w600, color: C.inkSoft),
        ),
      ],
    ),
  );
}

class _AvailabilityToggle extends StatelessWidget {
  const _AvailabilityToggle({required this.on, required this.onChanged});
  final bool on;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
    decoration: BoxDecoration(color: C.navySoft, borderRadius: BorderRadius.circular(R.md)),
    child: Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: on ? C.turq : const Color(0xFF6B7A8C)),
        ),
        const SizedBox(width: S.sm),
        Expanded(
          child: Text(
            on ? 'Disponible aujourd’hui' : 'Indisponible aujourd’hui',
            style: body(size: 14.5, weight: FontWeight.w600, color: C.white),
          ),
        ),
        Switch(value: on, onChanged: onChanged),
      ],
    ),
  );
}

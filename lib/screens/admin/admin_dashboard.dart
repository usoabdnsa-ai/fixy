import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../../widgets/shell.dart';

/// Admin home: what needs action, platform counters, requests by status,
/// by day and by trade. Every number is computed from the stored data.
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final st = s.admin.stats(DateTime.now());
    final name = s.user?.firstName ?? '';

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
                          const FixyMark(size: 44, onDark: true),
                          const SizedBox(width: S.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bonjour $name', style: title(size: 22, color: C.white)),
                                const SizedBox(height: 2),
                                Text('Administration · équipe Fixy', style: body(size: 14, color: const Color(0xFFB7C4D3))),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: S.lg),
                      _Todo(
                        icon: PhosphorIconsBold.shieldCheck,
                        text: st.toVerify == 0 ? 'Aucun prestataire à vérifier' : '${plural(st.toVerify, 'prestataire')} à vérifier',
                        onTap: () => AppShell.of(context)?.go(1),
                        urgent: st.toVerify > 0,
                      ),
                      const SizedBox(height: S.sm),
                      _Todo(
                        icon: PhosphorIconsBold.flag,
                        text: st.toModerate == 0 ? 'Aucun avis à examiner' : '${plural(st.toModerate, 'avis', 'avis')} à examiner',
                        onTap: () => AppShell.of(context)?.go(2),
                        urgent: st.toModerate > 0,
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: S.md,
                    crossAxisSpacing: S.md,
                    childAspectRatio: 1.55,
                    children: [
                      _Counter('Clients', '${st.clients}', PhosphorIconsBold.users, C.blue, C.blueWash),
                      _Counter('Prestataires', '${st.providers}', PhosphorIconsBold.toolbox, C.turqText, C.turqWash, sub: '${st.verified} vérifiés'),
                      _Counter('Demandes', '${st.requests}', PhosphorIconsBold.clipboardText, C.amber, C.amberWash),
                      _Counter(
                        'Note moyenne',
                        st.reviews == 0 ? '–' : rating1(st.averageRating),
                        PhosphorIconsBold.star,
                        C.amber,
                        C.amberWash,
                        sub: plural(st.reviews, 'avis', 'avis'),
                      ),
                    ].indexed.map((e) => Rise(index: e.$1, child: e.$2)).toList(),
                  ),
                  const SizedBox(height: S.xl),
                  const SectionHeader('Demandes par statut'),
                  Rise(index: 4, child: _StatusCard(st)),
                  const SizedBox(height: S.xl),
                  const SectionHeader('7 derniers jours'),
                  Rise(index: 5, child: _WeekCard(st.last7Days)),
                  const SizedBox(height: S.xl),
                  const SectionHeader('Demandes par métier'),
                  Rise(index: 6, child: _TradeCard(st.byCategory)),
                  if (st.suspended > 0) ...[
                    const SizedBox(height: S.lg),
                    Text(
                      '${plural(st.suspended, 'prestataire suspendu', 'prestataires suspendus')} (masqués de la recherche).',
                      style: body(size: 13.5, color: C.inkSoft),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable to-do line in the navy header.
class _Todo extends StatelessWidget {
  const _Todo({required this.icon, required this.text, required this.onTap, required this.urgent});
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool urgent;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .98,
    semanticLabel: text,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(color: C.navySoft, borderRadius: BorderRadius.circular(R.md)),
      child: Row(
        children: [
          Icon(icon, size: 19, color: urgent ? C.turq : const Color(0xFF6B7A8C)),
          const SizedBox(width: S.md),
          Expanded(
            child: Text(
              text,
              style: body(size: 14.5, weight: FontWeight.w600, color: C.white),
            ),
          ),
          const Icon(PhosphorIconsBold.caretRight, size: 15, color: Color(0xFFB7C4D3)),
        ],
      ),
    ),
  );
}

class _Counter extends StatelessWidget {
  const _Counter(this.label, this.value, this.icon, this.fg, this.bg, {this.sub});
  final String label, value;
  final String? sub;
  final IconData icon;
  final Color fg, bg;
  @override
  Widget build(BuildContext context) => AppCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon: icon, size: 32, color: fg, wash: bg),
            const Spacer(),
            Text(value, style: figs(size: 26, weight: FontWeight.w800)),
          ],
        ),
        const Spacer(),
        Text(
          label,
          style: body(size: 13.5, weight: FontWeight.w600, color: C.inkSoft),
        ),
        if (sub != null) Text(sub!, style: body(size: 12, color: C.inkSoft, height: 1.2)),
      ],
    ),
  );
}

(Color, Color) _statusColors(RequestStatus s) => switch (s) {
  RequestStatus.enAttente => (C.amber, C.amberWash),
  RequestStatus.acceptee => (C.blue, C.blueWash),
  RequestStatus.terminee => (C.green, C.greenWash),
  RequestStatus.annulee => (C.red, C.redWash),
};

/// One stacked bar for the 4 statuses, a legend, and the completion rate.
class _StatusCard extends StatelessWidget {
  const _StatusCard(this.st);
  final PlatformStats st;
  @override
  Widget build(BuildContext context) {
    final total = st.requests;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(R.pill),
            child: SizedBox(
              height: 12,
              child: total == 0
                  ? Container(color: C.line)
                  : Row(
                      children: [
                        for (final s in RequestStatus.values)
                          if ((st.byStatus[s] ?? 0) > 0)
                            Expanded(
                              flex: st.byStatus[s]!,
                              child: Container(color: _statusColors(s).$1, margin: const EdgeInsets.only(right: 2)),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: S.md),
          for (final s in RequestStatus.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: _statusColors(s).$1, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: S.sm),
                  Expanded(
                    child: Text(s.label, style: body(size: 14, weight: FontWeight.w600)),
                  ),
                  Text('${st.byStatus[s] ?? 0}', style: figs(size: 14, weight: FontWeight.w700)),
                ],
              ),
            ),
          const Divider(height: S.xl),
          Row(
            children: [
              Expanded(
                child: Text('Taux de réalisation', style: body(size: 14, color: C.inkSoft)),
              ),
              Text(
                '${(st.completionRate * 100).round()} %',
                style: figs(size: 16, weight: FontWeight.w800, color: C.turqText),
              ),
            ],
          ),
          Text('Terminées parmi les demandes clôturées.', style: body(size: 12.5, color: C.inkSoft)),
        ],
      ),
    );
  }
}

/// Requests created per day, last 7 days.
class _WeekCard extends StatelessWidget {
  const _WeekCard(this.days);
  final List<int> days;
  static const _short = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  @override
  Widget build(BuildContext context) {
    final max = days.fold(0, (a, b) => a > b ? a : b);
    final today = DateTime.now();
    return AppCard(
      child: SizedBox(
        height: 130,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final (i, n) in days.indexed)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '$n',
                      style: figs(size: 12, weight: FontWeight.w700, color: n == 0 ? C.inkFaint : C.ink),
                    ),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: max == 0 ? 0 : n / max),
                      duration: const Duration(milliseconds: 700),
                      curve: M.out,
                      builder: (_, v, _) => Container(
                        width: 22,
                        height: 4 + 76 * v,
                        decoration: BoxDecoration(color: i == 6 ? C.turq : C.navy, borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      i == 6 ? 'Auj.' : _short[today.subtract(Duration(days: 6 - i)).weekday - 1],
                      style: body(size: 12, weight: i == 6 ? FontWeight.w700 : FontWeight.w500, color: C.inkSoft, height: 1.2),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal bars per trade, busiest first. Trades with no request are hidden.
class _TradeCard extends StatelessWidget {
  const _TradeCard(this.byCategory);
  final Map<Category, int> byCategory;
  @override
  Widget build(BuildContext context) {
    final rows = byCategory.entries.where((e) => e.value > 0).toList()..sort((a, b) => b.value.compareTo(a.value));
    if (rows.isEmpty) {
      return AppCard(
        child: Text('Aucune demande pour le moment.', style: body(size: 14, color: C.inkSoft)),
      );
    }
    final max = rows.first.value;
    return AppCard(
      child: Column(
        children: [
          for (final e in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(e.key.icon, size: 18, color: C.inkSoft),
                  const SizedBox(width: S.sm),
                  SizedBox(
                    width: 104,
                    child: Text(e.key.label, style: body(size: 14, weight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(R.pill),
                      child: LinearProgressIndicator(value: e.value / max, minHeight: 10, backgroundColor: C.line, color: C.turq),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${e.value}',
                      textAlign: TextAlign.right,
                      style: figs(size: 14, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

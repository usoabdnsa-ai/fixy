import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import '../../widgets/shell.dart';
import '../client/account.dart';
import 'flags.dart';
import 'metrics.dart';
import 'verify.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, this.tab = 0});
  final int tab;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Shell(
      initialIndex: tab,
      items: [
        const NavItem('Metrics', PhosphorIconsBold.chartBar, PhosphorIconsFill.chartBar, MetricsScreen()),
        NavItem(
          'Verify',
          PhosphorIconsBold.identificationCard,
          PhosphorIconsFill.identificationCard,
          const VerifyScreen(),
          badge: s.verifications.where((v) => v.decision == null).length,
        ),
        NavItem('Flags', PhosphorIconsBold.flag, PhosphorIconsFill.flag, const FlagsScreen(), badge: s.flags.where((f) => !f.resolved).length),
        const NavItem('Team', PhosphorIconsBold.user, PhosphorIconsFill.user, _AdminAccount()),
      ],
    );
  }
}

class _AdminAccount extends StatelessWidget {
  const _AdminAccount();
  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return ListView(
      padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, S.xl),
      children: [
        Text('Fixy team', style: display(size: 28)),
        const SizedBox(height: S.lg),
        TagCard(
          child: Row(
            children: [
              const FixyMark(size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Moderator · Lina', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Permissions: verify, moderate, read metrics', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        Text(
          'Role permissions (RBAC)',
          style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
        ),
        const SizedBox(height: 8),
        const _RbacTable(),
        const SizedBox(height: S.xl),
        const ThemeSwitch(),
        const SizedBox(height: S.md),
        TagButton.light(label: 'Sign out', icon: PhosphorIconsBold.signOut, onTap: () => signOut(context)),
      ],
    );
  }
}

class _RbacTable extends StatelessWidget {
  const _RbacTable();
  static const rows = [
    ('Post a job', true, false, false),
    ('Accept / quote jobs', false, true, false),
    ('Chat after acceptance', true, true, false),
    ('Rate a completed job', true, false, false),
    ('Grant "Verified" badge', false, false, true),
    ('Hide reviews / suspend', false, false, true),
    ('Platform metrics', false, false, true),
  ];
  @override
  Widget build(BuildContext context) {
    Widget cell(bool v) => Expanded(
      child: Center(child: Icon(v ? PhosphorIconsFill.checkCircle : PhosphorIconsBold.minus, size: 16, color: v ? C.teal : C.lineStrong)),
    );
    return Container(
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                for (final h in ['Client', "M'lem", 'Admin'])
                  Expanded(
                    child: Center(
                      child: Text(h, style: figs(size: 10.5, weight: FontWeight.w700)),
                    ),
                  ),
              ],
            ),
          ),
          for (final r in rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: C.line)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(r.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  cell(r.$2),
                  cell(r.$3),
                  cell(r.$4),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

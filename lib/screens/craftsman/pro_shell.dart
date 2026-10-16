import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/shell.dart';
import 'pro_board.dart';
import 'pro_home.dart';
import 'pro_jobs.dart';
import 'pro_profile.dart';

final proShellKey = GlobalKey<ShellState>();

class ProShell extends StatelessWidget {
  const ProShell({super.key, this.tab = 0});
  final int tab;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Shell(
      key: proShellKey,
      initialIndex: tab,
      items: [
        const NavItem('Today', PhosphorIconsBold.gauge, PhosphorIconsFill.gauge, ProHome()),
        NavItem('Requests', PhosphorIconsBold.tray, PhosphorIconsFill.tray, const ProBoard(), badge: s.board.length),
        NavItem(
          'My jobs',
          PhosphorIconsBold.calendarCheck,
          PhosphorIconsFill.calendarCheck,
          const ProJobs(),
          badge: s.proJobs.where((j) => j.status == JobStatus.accepted).length,
        ),
        const NavItem('Profile', PhosphorIconsBold.identificationBadge, PhosphorIconsFill.identificationBadge, ProProfile()),
      ],
    );
  }
}

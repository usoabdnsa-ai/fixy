import 'package:flutter/material.dart';
import '../../widgets/kit.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/shell.dart';
import 'account.dart';
import 'explore.dart';
import 'home.dart';
import 'jobs.dart';
import 'post_request.dart';

final clientShellKey = GlobalKey<ShellState>();

class ClientShell extends StatelessWidget {
  const ClientShell({super.key, this.tab = 0});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final quoted = s.clientJobs.where((j) => j.status == JobStatus.quoted).length;
    return Shell(
      key: clientShellKey,
      initialIndex: tab,
      center: (
        icon: PhosphorIconsBold.plus,
        label: 'Post a job',
        onTap: () => Navigator.of(context).push(wipeRoute(fullscreenDialog: true, const PostRequestScreen())),
      ),
      items: [
        const NavItem('Home', PhosphorIconsBold.house, PhosphorIconsFill.house, ClientHome()),
        const NavItem('Explore', PhosphorIconsBold.mapTrifold, PhosphorIconsFill.mapTrifold, ExploreScreen()),
        NavItem('Jobs', PhosphorIconsBold.clipboardText, PhosphorIconsFill.clipboardText, const JobsScreen(), badge: quoted),
        const NavItem('Account', PhosphorIconsBold.user, PhosphorIconsFill.user, AccountScreen()),
      ],
    );
  }
}

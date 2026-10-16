import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../admin/admin_shell.dart';
import '../client/chat.dart';
import '../client/client_shell.dart';
import '../client/craftsman_profile.dart';
import '../client/job_detail.dart';
import '../client/post_request.dart';
import '../client/rate.dart';
import '../craftsman/pro_shell.dart';
import 'auth.dart';

/// Web demo shortcut: `?go=<screen>` jumps straight to a screen after the
/// splash, e.g. `?go=profile` or `?go=pro`. Used for presenting and for
/// screenshot checks. Returns false when there is no link.
bool openDeepLink(BuildContext context) {
  final go = Uri.base.queryParameters['go'];
  if (go == null) return false;
  final s = context.read<AppState>();
  final nav = Navigator.of(context);

  void root(Role role, Widget shell, [Widget? on]) {
    s.signIn(role, '0555123456');
    nav.pushAndRemoveUntil(fadeRoute(shell), (_) => false);
    if (on != null) nav.push(MaterialPageRoute(builder: (_) => on));
  }

  Job job(JobStatus st) => s.clientJobs.firstWhere((j) => j.status == st);

  switch (go) {
    case 'auth':
      nav.pushReplacement(fadeRoute(const AuthScreen()));
    case 'client':
      root(Role.client, const ClientShell());
    case 'explore':
      root(Role.client, const ClientShell(tab: 1));
    case 'jobs':
      root(Role.client, const ClientShell(tab: 2));
    case 'account':
      root(Role.client, const ClientShell(tab: 3));
    case 'profile':
      root(Role.client, const ClientShell(), CraftsmanProfileScreen(craftsman: byId('c1')));
    case 'post':
      root(Role.client, const ClientShell(), const PostRequestScreen());
    case 'quotes':
      root(Role.client, const ClientShell(tab: 2), JobDetailScreen(job: job(JobStatus.quoted)));
    case 'tracking':
      root(Role.client, const ClientShell(tab: 2), JobDetailScreen(job: job(JobStatus.accepted)));
    case 'chat':
      root(Role.client, const ClientShell(), ChatScreen(job: job(JobStatus.accepted)));
    case 'rate':
      root(Role.client, const ClientShell(tab: 2), RateScreen(job: job(JobStatus.completed)));
    case 'pro':
      root(Role.craftsman, const ProShell());
    case 'board':
      root(Role.craftsman, const ProShell(tab: 1));
    case 'projobs':
      root(Role.craftsman, const ProShell(tab: 2));
    case 'proprofile':
      root(Role.craftsman, const ProShell(tab: 3));
    case 'admin':
      root(Role.admin, const AdminShell());
    case 'verify':
      root(Role.admin, const AdminShell(tab: 1));
    case 'flags':
      root(Role.admin, const AdminShell(tab: 2));
    case 'team':
      root(Role.admin, const AdminShell(tab: 3));
    default:
      return false;
  }
  return true;
}

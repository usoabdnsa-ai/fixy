import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../widgets/icons.dart';
import '../../widgets/shell.dart';
import '../shared/settings.dart';
import 'admin_dashboard.dart';
import 'admin_providers.dart';
import 'admin_reviews.dart';

/// Admin area (équipe Fixy): Tableau de bord · Prestataires · Avis · Profil.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, this.initial = 0});
  final int initial;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppShell(
      initial: initial,
      items: [
        const NavItem('Tableau', PhosphorIconsBold.chartBar, PhosphorIconsFill.chartBar, AdminDashboard()),
        NavItem('Prestataires', PhosphorIconsBold.shieldCheck, PhosphorIconsFill.sealCheck, const AdminProvidersScreen(), badge: s.admin.toVerify.length),
        NavItem('Avis', PhosphorIconsBold.flag, PhosphorIconsFill.flag, const AdminReviewsScreen(), badge: s.admin.toModerate.length),
        const NavItem('Profil', PhosphorIconsBold.user, PhosphorIconsFill.user, SettingsScreen()),
      ],
    );
  }
}

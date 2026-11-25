import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/icons.dart';
import '../../widgets/shell.dart';
import '../shared/provider_reviews.dart';
import '../shared/settings.dart';
import 'dashboard.dart';
import 'manage_requests.dart';

/// Prestataire area: Accueil · Demandes · Avis · Profil.
class ProviderShell extends StatelessWidget {
  const ProviderShell({super.key, this.initial = 0});
  final int initial;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return AppShell(
      initial: initial,
      items: [
        const NavItem('Accueil', PhosphorIconsBold.squaresFour, PhosphorIconsFill.squaresFour, ProviderDashboard()),
        NavItem('Demandes', PhosphorIconsBold.clipboardText, PhosphorIconsFill.clipboardText, const ManageRequestsScreen(), badge: s.incomingCount(RequestStatus.enAttente)),
        NavItem('Avis', PhosphorIconsBold.star, PhosphorIconsFill.star, ProviderReviewsScreen(providerId: s.user?.id ?? '', embedded: true)),
        const NavItem('Profil', PhosphorIconsBold.user, PhosphorIconsFill.user, SettingsScreen()),
      ],
    );
  }
}

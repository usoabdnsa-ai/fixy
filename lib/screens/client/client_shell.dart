import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../widgets/icons.dart';
import '../../widgets/shell.dart';
import '../shared/settings.dart';
import 'favorites.dart';
import 'home.dart';
import 'my_requests.dart';

/// Client area: Accueil · Demandes · Favoris · Profil.
class ClientShell extends StatelessWidget {
  const ClientShell({super.key, this.initial = 0});
  final int initial;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final toRate = s.myRequests.where((r) => r.status == RequestStatus.terminee && !r.reviewed).length;
    return AppShell(
      initial: initial,
      items: [
        const NavItem('Accueil', PhosphorIconsBold.house, PhosphorIconsFill.house, ClientHome()),
        NavItem('Demandes', PhosphorIconsBold.clipboardText, PhosphorIconsFill.clipboardText, const MyRequestsScreen(), badge: toRate),
        const NavItem('Favoris', PhosphorIconsBold.heart, PhosphorIconsFill.heart, FavoritesScreen()),
        const NavItem('Profil', PhosphorIconsBold.user, PhosphorIconsFill.user, SettingsScreen()),
      ],
    );
  }
}

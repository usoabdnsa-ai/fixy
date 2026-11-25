import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../../widgets/shell.dart';
import '../shared/provider_card.dart';

/// Screen 13: saved artisans with "Appeler" and "Voir le profil".
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final list = context.watch<AppState>().favoriteProviders;
    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: list.isEmpty
          ? Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: PhosphorIconsBold.heart,
                  title: 'Pas encore de favoris',
                  text: 'Touchez le cœur sur un artisan pour le retrouver ici et l’appeler en un geste.',
                  action: 'Explorer les artisans',
                  onAction: () => AppShell.of(context)?.go(0),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: S.md),
              itemBuilder: (_, i) => Rise(index: i, child: ProviderCard(list[i])),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../services/provider_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import '../shared/router.dart';
import 'results.dart';

/// Screen 6: 2-column grid of the 8 categories.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Services')),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.sm, S.gutter, S.xl),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: S.md, crossAxisSpacing: S.md, childAspectRatio: 1.05),
        itemCount: Category.values.length,
        itemBuilder: (_, i) {
          final c = Category.values[i];
          final n = s.search(ProviderQuery(category: c)).length;
          return Rise(
            index: i,
            child: AppCard(
              onTap: () => push(context, ResultsScreen(initial: ProviderQuery(category: c, wilaya: s.location?.wilaya))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(icon: c.icon, size: 50),
                  const Spacer(),
                  Text(c.label, style: title(size: 16.5)),
                  const SizedBox(height: 2),
                  Text(n == 0 ? 'Bientôt' : '$n artisan${n > 1 ? 's' : ''}', style: body(size: 13.5, color: C.inkSoft)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

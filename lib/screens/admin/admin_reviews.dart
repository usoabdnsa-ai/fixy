import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/provider_reviews.dart';

enum _Filter { toModerate, hidden, all }

/// Review moderation. Low ratings (≤ 2★) land in "À examiner"; the admin
/// keeps them or hides them. Hidden reviews no longer count in the rating.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});
  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  _Filter _filter = _Filter.toModerate;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.reviews.all;
    bool keep(Review r, _Filter f) => switch (f) {
      _Filter.toModerate => !r.moderated && r.stars <= AdminService.lowStars,
      _Filter.hidden => r.hidden,
      _Filter.all => true,
    };
    int count(_Filter f) => all.where((r) => keep(r, f)).length;
    final list = all.where((r) => keep(r, _filter)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Modération des avis')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.sm),
              children: [
                for (final (f, label) in [(_Filter.toModerate, 'À examiner'), (_Filter.hidden, 'Masqués'), (_Filter.all, 'Tous')])
                  Padding(
                    padding: const EdgeInsets.only(right: S.sm),
                    child: ChoicePill('$label (${count(f)})', selected: _filter == f, onTap: () => setState(() => _filter = f)),
                  ),
              ],
            ),
          ),
          if (_filter == _Filter.toModerate && list.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.sm),
              child: Text(
                'Avis de ${AdminService.lowStars} étoiles ou moins. Masquez ceux qui sont injurieux, hors sujet ou faux.',
                style: body(size: 13.5, color: C.inkSoft),
              ),
            ),
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: PhosphorIconsBold.checkCircle,
                      title: _filter == _Filter.hidden ? 'Aucun avis masqué' : 'Rien à examiner',
                      text: _filter == _Filter.hidden ? 'Les avis que vous masquez apparaîtront ici.' : 'Les avis de 1 ou 2 étoiles arriveront ici.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.gutter, S.sm, S.gutter, S.xl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.md),
                    itemBuilder: (_, i) => Rise(
                      index: i,
                      child: _ModerationCard(list[i], showKeep: _filter == _Filter.toModerate),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ModerationCard extends StatelessWidget {
  const _ModerationCard(this.r, {required this.showKeep});
  final Review r;
  final bool showKeep;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final p = s.providers.byId(r.providerId);

    Future<void> setHidden(bool v) async {
      if (v &&
          !await confirmDialog(
            context,
            title: 'Masquer cet avis ?',
            text: 'Il ne sera plus visible et ne comptera plus dans la note de ${p?.name ?? 'ce prestataire'}. Vous pourrez le rétablir.',
            confirm: 'Masquer',
            danger: true,
          )) {
        return;
      }
      if (!context.mounted) return;
      if (await attempt(context, () => s.moderateReview(r.id, hidden: v)) && context.mounted) {
        toast(context, v ? 'Avis masqué' : (showKeep ? 'Avis conservé' : 'Avis rétabli'));
      }
    }

    return Opacity(
      opacity: r.hidden ? .75 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReviewCard(r),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, S.sm, 0, 0),
            child: Row(
              children: [
                Icon(p?.category.icon ?? PhosphorIconsBold.user, size: 15, color: C.inkSoft),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'Pour ${p?.name ?? 'prestataire supprimé'}${r.hidden ? ' · masqué' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: body(size: 13, color: C.inkSoft),
                  ),
                ),
                if (showKeep) Btn.ghost('Garder', onTap: () => setHidden(false)),
                r.hidden
                    ? Btn.ghost('Rétablir', icon: PhosphorIconsBold.eye, onTap: () => setHidden(false))
                    : Pressable(
                        onTap: () => setHidden(true),
                        semanticLabel: 'Masquer',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(PhosphorIconsBold.eyeSlash, size: 16, color: C.red),
                              const SizedBox(width: 5),
                              Text(
                                'Masquer',
                                style: body(size: 14, weight: FontWeight.w700, color: C.red),
                              ),
                            ],
                          ),
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

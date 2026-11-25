import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';

/// Screen 19: overall score, 5→1 star distribution bars, dated review cards.
class ProviderReviewsScreen extends StatelessWidget {
  const ProviderReviewsScreen({super.key, required this.providerId, this.embedded = false});
  final String providerId;

  /// In the provider's own tab: no back button title change.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final p = s.providers.byId(providerId);
    final sum = s.rating(providerId);
    final list = s.reviews.forProvider(providerId);
    return Scaffold(
      appBar: AppBar(title: Text(embedded ? 'Mes avis' : 'Avis · ${p?.name ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          AppCard(
            child: Row(
              children: [
                Column(
                  children: [
                    Text(sum.count == 0 ? '–' : rating1(sum.average), style: figs(size: 44, weight: FontWeight.w800)),
                    Stars(sum.average, size: 16),
                    const SizedBox(height: 4),
                    Text(plural(sum.count, 'avis', 'avis'), style: body(size: 13, color: C.inkSoft)),
                  ],
                ),
                const SizedBox(width: S.xl),
                Expanded(
                  child: Column(
                    children: [
                      for (var st = 5; st >= 1; st--)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              SizedBox(width: 12, child: Text('$st', style: figs(size: 13, color: C.inkSoft))),
                              const Icon(PhosphorIconsFill.star, size: 12, color: C.star),
                              const SizedBox(width: S.sm),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(R.pill),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: sum.count == 0 ? 0 : sum.byStars[st]! / sum.count),
                                    duration: M.slow,
                                    curve: M.out,
                                    builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 8, backgroundColor: C.line, color: C.turq),
                                  ),
                                ),
                              ),
                              const SizedBox(width: S.sm),
                              SizedBox(width: 22, child: Text('${sum.byStars[st]}', textAlign: TextAlign.right, style: figs(size: 13, color: C.inkSoft))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: S.xl),
          if (list.isEmpty)
            const EmptyState(icon: PhosphorIconsBold.star, title: 'Pas encore d’avis', text: 'Les avis apparaissent après chaque service terminé.')
          else
            for (final (i, r) in list.indexed) Padding(padding: const EdgeInsets.only(bottom: S.md), child: Rise(index: i, child: ReviewCard(r))),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard(this.r, {super.key});
  final Review r;
  @override
  Widget build(BuildContext context) => AppCard(
    border: true,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: C.turqWash,
              child: Text(r.authorName.isEmpty ? '?' : r.authorName[0].toUpperCase(), style: body(size: 14, weight: FontWeight.w800, color: C.turqText)),
            ),
            const SizedBox(width: S.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.authorName, style: body(size: 14.5, weight: FontWeight.w700)),
                  Text(ago(r.createdAt), style: body(size: 12.5, color: C.inkSoft)),
                ],
              ),
            ),
            Stars(r.stars.toDouble(), size: 14),
          ],
        ),
        if (r.comment.isNotEmpty) ...[const SizedBox(height: S.sm), Text(r.comment, style: body(size: 14.5))],
      ],
    ),
  );
}

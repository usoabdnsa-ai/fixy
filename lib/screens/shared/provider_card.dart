import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/native.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/provider_profile.dart';
import 'router.dart';

/// Search result card (screen 7): photo or default avatar, trade, rating,
/// commune, indicative price, "Appeler" and "Voir le profil".
class ProviderCard extends StatelessWidget {
  const ProviderCard(this.p, {super.key});
  final Provider p;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final fav = s.isFavorite(p.id);
    void open() => push(context, ProviderProfileScreen(providerId: p.id));
    return AppCard(
      onTap: open,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(photo: p.photo, size: 58),
              const SizedBox(width: S.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: title(size: 16.5))),
                        if (p.verified) ...[const SizedBox(width: 5), const VerifiedBadge(compact: true)],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(p.category.label, style: body(size: 14, color: C.inkSoft, weight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        RatingLine(s.rating(p.id)),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsBold.mapPin, size: 14, color: C.inkSoft),
                            const SizedBox(width: 3),
                            Text(p.commune, style: body(size: 13.5, color: C.inkSoft)),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsBold.phone, size: 14, color: C.inkSoft),
                            const SizedBox(width: 3),
                            Text(phoneFmt(p.phone), style: figs(size: 13.5, weight: FontWeight.w500, color: C.inkSoft)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _HeartButton(on: fav, onTap: () async {
                final added = await s.toggleFavorite(p.id);
                if (context.mounted) toast(context, added ? '${p.name} ajouté aux favoris' : 'Retiré des favoris');
              }),
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            children: [
              Text('À partir de ', style: body(size: 13.5, color: C.inkSoft)),
              Text(da(p.fromPrice), style: figs(size: 15, weight: FontWeight.w700)),
              const Spacer(),
              if (p.available)
                _Dot(color: C.green, label: 'Disponible')
              else
                _Dot(color: C.inkFaint, label: 'Occupé aujourd’hui'),
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            children: [
              Expanded(child: Btn.accent('Appeler', icon: PhosphorIconsBold.phone, compact: true, onTap: () => callPhone(context, p.phone))),
              const SizedBox(width: S.sm),
              Expanded(child: Btn.outline('Voir le profil', compact: true, onTap: open)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: body(size: 12.5, color: C.inkSoft, weight: FontWeight.w600)),
    ],
  );
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.on, required this.onTap});
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: .85,
    semanticLabel: on ? 'Retirer des favoris' : 'Ajouter aux favoris',
    child: SizedBox(
      width: 40,
      height: 40,
      child: AnimatedSwitcher(
        duration: M.fast,
        transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: M.spring), child: c),
        child: Icon(
          on ? PhosphorIconsFill.heart : PhosphorIconsBold.heart,
          key: ValueKey(on),
          color: on ? const Color(0xFFE5484D) : C.inkFaint,
          size: 23,
        ),
      ),
    ),
  );
}

/// Smaller vertical card for the "Artisans populaires" row on the home screen.
class ProviderMiniCard extends StatelessWidget {
  const ProviderMiniCard(this.p, {super.key});
  final Provider p;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return SizedBox(
      width: 164,
      child: AppCard(
        onTap: () => push(context, ProviderProfileScreen(providerId: p.id)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Avatar(photo: p.photo, size: 46),
                const Spacer(),
                if (p.verified) const VerifiedBadge(compact: true),
              ],
            ),
            const SizedBox(height: S.md),
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: title(size: 15)),
            Text(p.category.label, style: body(size: 13, color: C.inkSoft)),
            const SizedBox(height: 6),
            RatingLine(s.rating(p.id), size: 13),
            const SizedBox(height: 6),
            Text(p.commune, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(size: 12.5, color: C.inkSoft)),
            const SizedBox(height: S.sm),
            Text(da(p.fromPrice), style: figs(size: 14, weight: FontWeight.w700, color: C.turqText)),
          ],
        ),
      ),
    );
  }
}

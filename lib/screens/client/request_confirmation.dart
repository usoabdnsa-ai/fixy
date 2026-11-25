import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/native.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/request_detail.dart';
import '../shared/router.dart';

/// Screen 11: success message, provider summary, date/time/place,
/// "Appeler le prestataire" and a details button.
class RequestConfirmationScreen extends StatelessWidget {
  const RequestConfirmationScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = s.requests.byId(requestId)!;
    final p = s.providers.byId(r.providerId)!;
    return Scaffold(
      backgroundColor: C.card,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(S.gutter, S.xxl, S.gutter, S.xl),
          children: [
            const Center(child: _SuccessBadge()),
            const SizedBox(height: S.xl),
            Text('Demande envoyée !', textAlign: TextAlign.center, style: title(size: 26)),
            const SizedBox(height: S.sm),
            Text(
              '${p.name} va recevoir votre demande. Vous verrez sa réponse dans « Demandes ». Pour aller plus vite, appelez-le.',
              textAlign: TextAlign.center,
              style: body(color: C.inkSoft),
            ),
            const SizedBox(height: S.xl),
            Rise(
              child: AppCard(
                border: true,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Avatar(photo: p.photo, size: 46),
                        const SizedBox(width: S.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: title(size: 16)),
                              Text(p.category.label, style: body(size: 13.5, color: C.inkSoft)),
                            ],
                          ),
                        ),
                        StatusPill(r.status),
                      ],
                    ),
                    const Divider(height: S.xl),
                    InfoRow(icon: PhosphorIconsBold.wrench, label: 'Service', value: r.service),
                    InfoRow(icon: PhosphorIconsBold.calendarBlank, label: 'Date', value: when(r.scheduledAt)),
                    InfoRow(icon: PhosphorIconsBold.mapPin, label: 'Adresse', value: r.address),
                    InfoRow(icon: PhosphorIconsBold.phone, label: 'Téléphone', value: phoneFmt(p.phone)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: S.xl),
            Btn.accent('Appeler le prestataire', icon: PhosphorIconsBold.phone, onTap: () => callPhone(context, p.phone)),
            const SizedBox(height: S.sm),
            Btn.outline('Voir les détails de la demande', onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RequestDetailScreen(requestId: r.id)))),
            const SizedBox(height: S.sm),
            Center(child: Btn.ghost('Retour à l’accueil', onTap: () => goHome(context))),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge();
  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: M.spring,
      builder: (_, v, _) => Transform.scale(
        scale: v,
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(color: C.turqWash, shape: BoxShape.circle, border: Border.all(color: C.turq, width: 3)),
          child: const Icon(PhosphorIconsBold.check, size: 46, color: C.turqText),
        ),
      ),
    );
  }
}

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
import '../client/review_form.dart';
import 'router.dart';

/// Full request: status, the other party, service details, photo, and the
/// actions allowed for this role and status.
class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = s.requests.byId(requestId);
    if (r == null) return const Scaffold(body: Center(child: Text('Demande introuvable.')));
    final p = s.providers.byId(r.providerId);
    final asProvider = s.user?.role == Role.prestataire;

    return Scaffold(
      appBar: AppBar(title: const Text('Détails de la demande')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          _StatusBanner(r),
          const SizedBox(height: S.lg),
          AppCard(
            onTap: asProvider || p == null ? null : () => push(context, ProviderProfileScreen(providerId: p.id)),
            child: Row(
              children: [
                if (asProvider) const Avatar(size: 48) else Avatar(photo: p?.photo, size: 48),
                const SizedBox(width: S.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asProvider ? 'Client' : 'Prestataire', style: body(size: 12.5, color: C.inkSoft)),
                      Text(asProvider ? r.clientName : (p?.name ?? '—'), style: title(size: 16.5)),
                      Text(phoneFmt(asProvider ? r.clientPhone : (p?.phone ?? '')), style: figs(size: 14, color: C.inkSoft, weight: FontWeight.w500)),
                    ],
                  ),
                ),
                if (!asProvider) const Icon(PhosphorIconsBold.caretRight, size: 18, color: C.inkFaint),
              ],
            ),
          ),
          const SizedBox(height: S.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoRow(icon: PhosphorIconsBold.wrench, label: 'Service', value: r.service),
                InfoRow(icon: PhosphorIconsBold.calendarBlank, label: 'Prévu le', value: when(r.scheduledAt)),
                InfoRow(icon: PhosphorIconsBold.mapPin, label: 'Adresse', value: r.address),
                InfoRow(icon: PhosphorIconsBold.clock, label: 'Envoyée', value: ago(r.createdAt)),
                const Divider(height: S.xl),
                Text('Problème', style: body(size: 13.5, color: C.inkSoft)),
                const SizedBox(height: 4),
                Text(r.description, style: body()),
              ],
            ),
          ),
          if (r.photo != null) ...[
            const SizedBox(height: S.md),
            ClipRRect(borderRadius: BorderRadius.circular(R.md), child: AspectRatio(aspectRatio: 4 / 3, child: StoredImage(r.photo!))),
          ],
          const SizedBox(height: S.xl),
          ..._actions(context, s, r, p, asProvider),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, AppState s, ServiceRequest r, Provider? p, bool asProvider) {
    const gap = SizedBox(height: S.sm);
    if (asProvider) {
      return switch (r.status) {
        RequestStatus.enAttente => [
          Btn('Accepter', icon: PhosphorIconsBold.check, onTap: () => attempt(context, () => s.accept(r.id)).then((ok) {
            if (ok && context.mounted) toast(context, 'Demande acceptée. Appelez le client pour confirmer.');
          })),
          gap,
          Btn.danger('Refuser', onTap: () async {
            if (await confirmDialog(context, title: 'Refuser la demande ?', text: '${r.clientName} sera informé que vous n’êtes pas disponible.', confirm: 'Refuser', danger: true) &&
                context.mounted) {
              await attempt(context, () => s.refuse(r.id));
            }
          }),
          gap,
          Btn.outline('Appeler le client', icon: PhosphorIconsBold.phone, onTap: () => callPhone(context, r.clientPhone)),
        ],
        RequestStatus.acceptee => [
          Btn.accent('Appeler le client', icon: PhosphorIconsBold.phone, onTap: () => callPhone(context, r.clientPhone)),
          gap,
          Btn('Marquer comme terminée', icon: PhosphorIconsBold.checkCircle, onTap: () async {
            if (await confirmDialog(context, title: 'Service terminé ?', text: 'Le client pourra ensuite laisser son avis.', confirm: 'Oui, terminé') && context.mounted) {
              await attempt(context, () => s.finish(r.id));
            }
          }),
        ],
        _ => [],
      };
    }
    return [
      if (p != null && r.status != RequestStatus.annulee) ...[
        Btn.accent('Appeler le prestataire', icon: PhosphorIconsBold.phone, onTap: () => callPhone(context, p.phone)),
        gap,
      ],
      if (r.status == RequestStatus.terminee && !r.reviewed) ...[
        Btn('Évaluer le service', icon: PhosphorIconsBold.star, onTap: () => push(context, ReviewFormScreen(requestId: r.id))),
        gap,
      ],
      if (r.status == RequestStatus.enAttente || r.status == RequestStatus.acceptee)
        Btn.danger('Annuler la demande', onTap: () => cancelRequest(context, s, r)),
    ];
  }
}

Future<void> cancelRequest(BuildContext context, AppState s, ServiceRequest r) async {
  if (await confirmDialog(context, title: 'Annuler la demande ?', text: 'Le prestataire ne pourra plus l’accepter.', confirm: 'Annuler la demande', danger: true) &&
      context.mounted) {
    if (await attempt(context, () => s.cancel(r.id)) && context.mounted) toast(context, 'Demande annulée');
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner(this.r);
  final ServiceRequest r;
  @override
  Widget build(BuildContext context) {
    final text = switch (r.status) {
      RequestStatus.enAttente => 'En attente de la réponse du prestataire.',
      RequestStatus.acceptee => 'Acceptée. Le prestataire viendra à la date prévue.',
      RequestStatus.terminee => r.reviewed ? 'Service terminé. Merci pour votre avis !' : 'Service terminé. Pensez à laisser un avis.',
      RequestStatus.annulee => r.refused ? 'Le prestataire n’est pas disponible pour cette demande.' : 'Cette demande a été annulée.',
    };
    return Row(
      children: [
        StatusPill(r.status),
        const SizedBox(width: S.md),
        Expanded(child: Text(text, style: body(size: 14, color: C.inkSoft))),
      ],
    );
  }
}

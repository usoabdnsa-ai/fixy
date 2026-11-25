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
import '../../widgets/shell.dart';
import '../shared/request_detail.dart';
import '../shared/router.dart';
import 'review_form.dart';

/// Screen 12: the client's requests with the 4 status badges and
/// "Appeler" / "Annuler" / "Détails" / "Évaluer".
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});
  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  RequestStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.myRequests;
    final list = _filter == null ? all : all.where((r) => r.status == _filter).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Mes demandes')),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              children: [
                _pill('Toutes', null, all.length),
                for (final st in RequestStatus.values) _pill(st.label, st, all.where((r) => r.status == st).length),
              ],
            ),
          ),
          const SizedBox(height: S.md),
          Expanded(
            child: list.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: PhosphorIconsBold.clipboardText,
                      title: all.isEmpty ? 'Aucune demande pour l’instant' : 'Rien ici',
                      text: all.isEmpty ? 'Trouvez un artisan et envoyez-lui une demande : elle apparaîtra ici.' : 'Aucune demande avec ce statut.',
                      action: all.isEmpty ? 'Trouver un artisan' : null,
                      onAction: () => AppShell.of(context)?.go(0),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.xl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.md),
                    itemBuilder: (_, i) => Rise(index: i, child: _RequestCard(list[i])),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, RequestStatus? st, int n) => Padding(
    padding: const EdgeInsets.only(right: S.sm),
    child: ChoicePill('$label · $n', selected: _filter == st, onTap: () => setState(() => _filter = st)),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard(this.r);
  final ServiceRequest r;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    final p = s.providers.byId(r.providerId);
    void details() => push(context, RequestDetailScreen(requestId: r.id));
    final canCall = p != null && r.status != RequestStatus.annulee;
    final canCancel = r.status == RequestStatus.enAttente || r.status == RequestStatus.acceptee;
    final canRate = r.status == RequestStatus.terminee && !r.reviewed;
    return AppCard(
      onTap: details,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(photo: p?.photo, size: 44),
              const SizedBox(width: S.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p?.name ?? 'Prestataire', maxLines: 1, overflow: TextOverflow.ellipsis, style: title(size: 15.5)),
                    Text(r.service, maxLines: 1, overflow: TextOverflow.ellipsis, style: body(size: 13.5, color: C.inkSoft)),
                  ],
                ),
              ),
              StatusPill(r.status),
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            children: [
              const Icon(PhosphorIconsBold.calendarBlank, size: 15, color: C.inkSoft),
              const SizedBox(width: 5),
              Text(when(r.scheduledAt), style: body(size: 13.5, weight: FontWeight.w600)),
              if (r.refused) ...[
                const Spacer(),
                Text('Refusée par l’artisan', style: body(size: 12.5, color: C.red, weight: FontWeight.w600)),
              ],
              if (r.reviewed) ...[
                const Spacer(),
                const Icon(PhosphorIconsFill.star, size: 14, color: C.star),
                const SizedBox(width: 3),
                Text('Avis envoyé', style: body(size: 12.5, color: C.inkSoft, weight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            children: [
              if (canCall) ...[Expanded(child: Btn.accent('Appeler', icon: PhosphorIconsBold.phone, compact: true, onTap: () => callPhone(context, p.phone))), const SizedBox(width: S.sm)],
              if (canRate) ...[Expanded(child: Btn('Évaluer', icon: PhosphorIconsBold.star, compact: true, onTap: () => push(context, ReviewFormScreen(requestId: r.id)))), const SizedBox(width: S.sm)],
              if (canCancel && !canRate) ...[Expanded(child: Btn.danger('Annuler', compact: true, onTap: () => cancelRequest(context, s, r))), const SizedBox(width: S.sm)],
              Expanded(child: Btn.outline('Détails', compact: true, onTap: details)),
            ],
          ),
        ],
      ),
    );
  }
}

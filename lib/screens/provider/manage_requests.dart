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
import '../shared/request_detail.dart';
import '../shared/router.dart';

/// Screen 17: incoming requests with problem details and photo,
/// "Accepter" / "Refuser", and "Appeler le client" once accepted.
class ManageRequestsScreen extends StatefulWidget {
  const ManageRequestsScreen({super.key});
  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {
  RequestStatus _tab = RequestStatus.enAttente;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final all = s.incoming;
    final list = all.where((r) => r.status == _tab).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Demandes reçues')),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: S.gutter),
              children: [
                for (final st in RequestStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: S.sm),
                    child: ChoicePill('${st.label} · ${all.where((r) => r.status == st).length}', selected: _tab == st, onTap: () => setState(() => _tab = st)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: S.md),
          Expanded(
            child: list.isEmpty
                ? SingleChildScrollView(
                    child: EmptyState(
                      icon: PhosphorIconsBold.clipboardText,
                      title: switch (_tab) {
                        RequestStatus.enAttente => 'Aucune nouvelle demande',
                        RequestStatus.acceptee => 'Aucune demande acceptée',
                        RequestStatus.terminee => 'Aucun service terminé',
                        RequestStatus.annulee => 'Aucune demande annulée',
                      },
                      text: _tab == RequestStatus.enAttente
                          ? 'Les demandes des clients arrivent ici. Un profil complet avec photo et tarifs en attire plus.'
                          : 'Rien à afficher pour l’instant.',
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.xl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: S.md),
                    itemBuilder: (_, i) => Rise(index: i, child: IncomingRequestCard(list[i])),
                  ),
          ),
        ],
      ),
    );
  }
}

class IncomingRequestCard extends StatelessWidget {
  const IncomingRequestCard(this.r, {super.key});
  final ServiceRequest r;

  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    void details() => push(context, RequestDetailScreen(requestId: r.id));
    return AppCard(
      onTap: details,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.service, style: title(size: 16)),
                    const SizedBox(height: 2),
                    Text('${r.clientName} · ${ago(r.createdAt)}', style: body(size: 13.5, color: C.inkSoft)),
                  ],
                ),
              ),
              StatusPill(r.status),
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(r.description, maxLines: 3, overflow: TextOverflow.ellipsis, style: body(size: 14.5))),
              if (r.photo != null) ...[
                const SizedBox(width: S.md),
                ClipRRect(borderRadius: BorderRadius.circular(R.sm), child: StoredImage(r.photo!, width: 72, height: 72)),
              ],
            ],
          ),
          const SizedBox(height: S.md),
          Row(
            children: [
              const Icon(PhosphorIconsBold.calendarBlank, size: 15, color: C.inkSoft),
              const SizedBox(width: 5),
              Text(when(r.scheduledAt), style: body(size: 13.5, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: Icon(PhosphorIconsBold.mapPin, size: 15, color: C.inkSoft)),
              const SizedBox(width: 5),
              Expanded(child: Text(r.address, style: body(size: 13.5, color: C.inkSoft))),
            ],
          ),
          if (r.status == RequestStatus.enAttente || r.status == RequestStatus.acceptee) const SizedBox(height: S.md),
          if (r.status == RequestStatus.enAttente)
            Row(
              children: [
                Expanded(
                  child: Btn.danger('Refuser', compact: true, onTap: () async {
                    if (await confirmDialog(context, title: 'Refuser la demande ?', text: '${r.clientName} sera informé que vous n’êtes pas disponible.', confirm: 'Refuser', danger: true) &&
                        context.mounted) {
                      await attempt(context, () => s.refuse(r.id));
                    }
                  }),
                ),
                const SizedBox(width: S.sm),
                Expanded(
                  child: Btn('Accepter', icon: PhosphorIconsBold.check, compact: true, onTap: () async {
                    if (await attempt(context, () => s.accept(r.id)) && context.mounted) {
                      toast(context, 'Demande acceptée. Appelez ${r.clientName} pour confirmer.');
                    }
                  }),
                ),
              ],
            ),
          if (r.status == RequestStatus.acceptee)
            Row(
              children: [
                Expanded(child: Btn.accent('Appeler le client', icon: PhosphorIconsBold.phone, compact: true, onTap: () => callPhone(context, r.clientPhone))),
                const SizedBox(width: S.sm),
                Expanded(
                  child: Btn.outline('Terminée', icon: PhosphorIconsBold.checkCircle, compact: true, onTap: () async {
                    if (await confirmDialog(context, title: 'Service terminé ?', text: 'Le client pourra ensuite laisser son avis.', confirm: 'Oui, terminé') && context.mounted) {
                      await attempt(context, () => s.finish(r.id));
                    }
                  }),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

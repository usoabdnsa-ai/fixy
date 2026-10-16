import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'chat.dart';
import 'rate.dart';
import 'widgets.dart';

class JobDetailScreen extends StatelessWidget {
  const JobDetailScreen({super.key, required this.job});
  final Job job;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final c = job.craftsman;
    final pad = MediaQuery.paddingOf(context);
    final chatOpen = c != null && (job.status == JobStatus.accepted || job.status == JobStatus.inProgress || job.status == JobStatus.completed);

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(S.gutter, pad.top + 8, S.gutter, 120 + pad.bottom),
        children: [
          Row(
            children: [
              IconCircle(icon: PhosphorIconsBold.arrowLeft, label: 'Back', onTap: () => Navigator.pop(context)),
              const Spacer(),
              Text(job.id, style: mono(size: 12, color: C.inkSoft)),
              const SizedBox(width: 10),
              StatusChip(job.status),
            ],
          ),
          const SizedBox(height: S.xl),
          Row(
            children: [
              Icon(job.trade.icon, size: 18),
              const SizedBox(width: 6),
              Text(job.trade.label.toUpperCase(), style: mono(size: 12, weight: FontWeight.w700)),
              const SizedBox(width: 10),
              UrgencyChip(job.urgency),
            ],
          ),
          const SizedBox(height: 10),
          Text(job.title, style: display(size: 26)),
          if (job.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(job.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: C.inkSoft)),
          ],
          if (job.photos.isNotEmpty) ...[
            const SizedBox(height: S.lg),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [for (final p in job.photos) Padding(padding: const EdgeInsets.only(right: 8), child: Photo(p, width: 160, height: 120))],
              ),
            ),
          ],
          const SizedBox(height: S.xl),
          if (job.status != JobStatus.cancelled) TagCard(child: JobProgress(status: job.status)),
          const SizedBox(height: S.xl),
          // ---- state-specific body ----
          if (job.status == JobStatus.pending && c == null) const _Waiting(),
          if (job.status == JobStatus.pending && c != null) _AssignedCard(job: job, waiting: true),
          if (job.status == JobStatus.quoted) ...[
            Text('Quotes (${job.quotes.length})', style: display(size: 19)),
            const SizedBox(height: 4),
            Text('Price is locked once you accept. Chat opens after.', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: S.md),
            for (final (i, q) in (job.quotes.toList()..sort((a, b) => a.amount.compareTo(b.amount))).indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _QuoteCard(job: job, q: q, best: i == 0).enter(context, i),
              ),
          ],
          if (chatOpen) _AssignedCard(job: job),
          if (job.status == JobStatus.completed) ...[
            const SizedBox(height: S.lg),
            job.rated
                ? Container(
                    padding: const EdgeInsets.all(S.lg),
                    decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.lg)),
                    child: Row(
                      children: [
                        const Icon(PhosphorIconsFill.sealCheck, color: C.teal),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'You rated this job. One review per job keeps ratings honest.',
                            style: const TextStyle(fontWeight: FontWeight.w600, color: C.teal),
                          ),
                        ),
                      ],
                    ),
                  )
                : TagButton(
                    label: 'Rate ${c!.firstName}',
                    icon: PhosphorIconsBold.star,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(fullscreenDialog: true, builder: (_) => RateScreen(job: job))),
                  ),
          ],
          if (job.status == JobStatus.accepted || job.status == JobStatus.inProgress) ...[
            const SizedBox(height: S.xl),
            // Prototype helper so the whole lifecycle can be demoed from the client side.
            Center(
              child: Pressable(
                onTap: () => s.advance(job),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(R.pill),
                    border: Border.all(color: C.lineStrong, width: 1.5),
                  ),
                  child: Text(
                    job.status == JobStatus.accepted ? "DEMO · m'lem arrives on site" : 'DEMO · m\'lem marks job done',
                    style: mono(size: 11, color: C.inkSoft, weight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
          if (job.status == JobStatus.pending || job.status == JobStatus.quoted) ...[
            const SizedBox(height: S.xl),
            Center(
              child: Pressable(
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: C.card,
                      title: const Text('Cancel this request?'),
                      content: const Text("M'lems who quoted will be told it's closed."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Keep it', style: TextStyle(color: C.ink)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text(
                            'Cancel request',
                            style: TextStyle(color: C.red, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) s.cancelJob(job);
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Cancel request',
                    style: TextStyle(color: C.red, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomSheet: chatOpen && job.status != JobStatus.completed
          ? Container(
              padding: EdgeInsets.fromLTRB(S.gutter, 12, S.gutter, 12 + pad.bottom),
              decoration: const BoxDecoration(
                color: C.card,
                border: Border(top: BorderSide(color: C.line, width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TagButton.light(label: 'Call', icon: PhosphorIconsBold.phone, onTap: () => toast(context, 'Calling ${c.firstName}… (prototype)')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TagButton(
                      label: 'Message',
                      icon: PhosphorIconsBold.chatCircleDots,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(job: job))),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class _Waiting extends StatelessWidget {
  const _Waiting();
  @override
  Widget build(BuildContext context) {
    return TagCard(
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: const Icon(
              PhosphorIconsBold.bell,
              color: C.rust,
            ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.03, end: 0.03, duration: 500.ms, curve: Curves.easeInOut),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("M'lems are looking at it", style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text('Quotes land here. Usually within 10 minutes.', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.job, required this.q, required this.best});
  final Job job;
  final Quote q;
  final bool best;
  @override
  Widget build(BuildContext context) {
    final c = q.craftsman;
    return TagCard(
      raised: best,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (best)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'LOWEST PRICE',
                style: mono(size: 10.5, weight: FontWeight.w700, color: C.rust),
              ),
            ),
          Row(
            children: [
              Pressable(
                onTap: () => openProfile(context, c),
                child: Avatar(craftsman: c, size: 46),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (c.verified) ...[const SizedBox(width: 6), const VerifiedStamp(small: true)],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Stars(value: c.rating, size: 12),
                        const SizedBox(width: 8),
                        Text(km(kmFrom(clientHome, c.location)), style: mono(size: 11.5, color: C.inkSoft)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(dzd(q.amount), style: mono(size: 17, weight: FontWeight.w700)),
                  Text(q.eta, style: mono(size: 11, color: C.inkSoft)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('"${q.note}"', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          TagButton(
            compact: true,
            label: 'Accept ${dzd(q.amount)}',
            color: best ? C.orange : C.card,
            onTap: () {
              HapticFeedback.heavyImpact();
              context.read<AppState>().acceptQuote(job, q);
              toast(context, 'Accepted. ${c.firstName} has been notified.');
            },
          ),
        ],
      ),
    );
  }
}

class _AssignedCard extends StatelessWidget {
  const _AssignedCard({required this.job, this.waiting = false});
  final Job job;
  final bool waiting;
  @override
  Widget build(BuildContext context) {
    final c = job.craftsman!;
    return TagCard(
      onTap: () => openProfile(context, c),
      child: Row(
        children: [
          Avatar(craftsman: c, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                    if (c.verified) ...[const SizedBox(width: 6), const VerifiedStamp(small: true)],
                  ],
                ),
                const SizedBox(height: 3),
                Text(waiting ? 'Waiting for ${c.firstName} to confirm' : '${c.trade.local} · ${c.commune}', style: Theme.of(context).textTheme.bodySmall),
                if (job.price != null) ...[const SizedBox(height: 4), Text('Agreed ${dzd(job.price!)}', style: mono(size: 12.5, weight: FontWeight.w700))],
              ],
            ),
          ),
          const Icon(PhosphorIconsBold.caretRight, size: 16, color: C.inkSoft),
        ],
      ),
    );
  }
}

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
import '../client/chat.dart';
import '../client/widgets.dart';

/// Craftsman's accepted jobs. Status moves Accepted → In progress → Completed;
/// "Mark completed" is hold-to-confirm so it can't be tapped by accident.
class ProJobs extends StatelessWidget {
  const ProJobs({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final active = s.proJobs.where((j) => j.status != JobStatus.completed).toList();
    final done = s.proJobs.where((j) => j.status == JobStatus.completed).toList();
    return TabPage(
      eyebrow: 'BOOKED WORK',
      title: 'My',
      accent: 'jobs',
      subtitle: '${active.length} active · ${done.length} done today',
      children: [
        if (active.isEmpty) Text('No active jobs. Accept a request to see it here.', style: Theme.of(context).textTheme.bodySmall),
        for (final (i, j) in active.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ProJobCard(job: j).enter(context, i),
          ),
        if (done.isNotEmpty) ...[
          const SizedBox(height: S.lg),
          Text('Completed today', style: display(size: 18)),
          const SizedBox(height: 10),
          for (final j in done)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: C.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.checkCircle, color: C.teal),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      j.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '+${dzd(j.price ?? 0)}',
                    style: figs(size: 13, weight: FontWeight.w700, color: C.teal),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 220.ms).moveY(begin: 8, end: 0, curve: M.out),
        ],
      ],
    );
  }
}

class _ProJobCard extends StatelessWidget {
  const _ProJobCard({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final s = context.read<AppState>();
    return TagCard(
      raised: job.status == JobStatus.inProgress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(job.id, style: figs(size: 11, color: C.inkSoft)),
              const Spacer(),
              StatusChip(job.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('${job.clientName} · ${job.commune} · ${dzd(job.price ?? 0)}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 14),
          JobProgress(status: job.status, labels: false),
          const SizedBox(height: 14),
          Row(
            children: [
              IconCircle(
                icon: PhosphorIconsBold.chatCircleDots,
                label: 'Chat with client',
                bg: C.bg,
                onTap: () {
                  if (job.messages.isEmpty) {
                    job.messages.add(Message(fromMe: false, text: 'Job accepted. Chat is open.', time: 'now', system: true));
                  }
                  Navigator.of(context).push(wipeRoute(ChatScreen(job: job, asPro: true)));
                },
              ),
              const SizedBox(width: 8),
              IconCircle(
                icon: PhosphorIconsBold.navigationArrow,
                label: 'Directions',
                bg: C.bg,
                onTap: () => toast(context, 'Opening directions to ${job.commune} (prototype)'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: job.status == JobStatus.accepted
                    ? TagButton(compact: true, label: "I'm on site", icon: PhosphorIconsBold.mapPin, onTap: () => s.advance(job))
                    : _HoldToConfirm(
                        label: 'Hold to complete',
                        onConfirmed: () {
                          s.advance(job);
                          toast(context, 'Job closed. ${job.clientName} will be asked to rate you.');
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Press and hold for 900ms; the fill tracks the finger, releases early
/// drain back quickly.
class _HoldToConfirm extends StatefulWidget {
  const _HoldToConfirm({required this.label, required this.onConfirmed});
  final String label;
  final VoidCallback onConfirmed;
  @override
  State<_HoldToConfirm> createState() => _HoldToConfirmState();
}

class _HoldToConfirmState extends State<_HoldToConfirm> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900), reverseDuration: const Duration(milliseconds: 200))
        ..addStatusListener((st) {
          if (st == AnimationStatus.completed) {
            HapticFeedback.heavyImpact();
            widget.onConfirmed();
          }
        });

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      onTap: widget.onConfirmed, // screen readers get a plain activation
      child: GestureDetector(
        onTapDown: (_) {
          HapticFeedback.lightImpact();
          _c.forward();
        },
        onTapUp: (_) {
          if (!_c.isCompleted) _c.reverse();
        },
        onTapCancel: () {
          if (!_c.isCompleted) _c.reverse();
        },
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: C.line),
            boxShadow: lift,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(R.md - 2),
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _c.value,
                    child: Container(color: C.teal),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsBold.checkCircle, size: 18, color: _c.value > .5 ? C.onFill : C.ink),
                        const SizedBox(width: 8),
                        Text(
                          widget.label,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _c.value > .5 ? C.onFill : C.ink),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';

/// Flagged reviews, conduct reports and listings.
class FlagsScreen extends StatelessWidget {
  const FlagsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final open = s.flags.where((f) => !f.resolved).toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, S.xl),
      children: [
        Text('Flags & disputes', style: display(size: 28)),
        const SizedBox(height: 4),
        Text('${open.length} open', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: S.lg),
        if (open.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const Icon(PhosphorIconsBold.flag, size: 44, color: C.inkSoft),
                const SizedBox(height: 10),
                Text('All clear', style: display(size: 18)),
              ],
            ),
          ),
        for (final (i, f) in open.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AnimatedSize(
              duration: M.base,
              curve: M.out,
              child: _FlagCard(f: f).enter(context, i),
            ),
          ),
      ],
    );
  }
}

class _FlagCard extends StatelessWidget {
  const _FlagCard({required this.f});
  final Flag f;
  @override
  Widget build(BuildContext context) {
    final (icon, tint, fg, label) = switch (f.kind) {
      'review' => (PhosphorIconsBold.star, C.amberWash, C.amber, 'FAKE REVIEW?'),
      'conduct' => (PhosphorIconsBold.warning, C.redWash, C.red, 'CONDUCT'),
      _ => (PhosphorIconsBold.images, C.orangeWash, C.rust, 'LISTING'),
    };
    final s = context.read<AppState>();
    return TagCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(R.pill)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: fg),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: mono(size: 10.5, weight: FontWeight.w700, color: fg),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text('${f.hoursAgo} h ago', style: mono(size: 11, color: C.inkSoft)),
            ],
          ),
          const SizedBox(height: 10),
          Text(f.subject, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 4),
          Text(f.reason, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: C.ink)),
          if (f.review != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.paper,
                borderRadius: BorderRadius.circular(R.sm),
                border: Border.all(color: C.line),
              ),
              child: Row(
                children: [
                  Stars(value: f.review!.average, size: 12),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('"${f.review!.text}" · ${f.review!.author}', style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text('Reported by ${f.reporter}', style: mono(size: 10.5, color: C.inkSoft)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TagButton.light(
                  compact: true,
                  label: 'Dismiss',
                  onTap: () {
                    s.resolveFlag(f, removeContent: false);
                    toast(context, 'Flag dismissed');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TagButton.dark(
                  compact: true,
                  label: f.kind == 'review' ? 'Hide review' : (f.kind == 'conduct' ? 'Warn m\'lem' : 'Suspend'),
                  onTap: () {
                    s.resolveFlag(f, removeContent: true);
                    toast(context, f.kind == 'review' ? 'Review hidden, rating recalculated' : 'Action recorded');
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

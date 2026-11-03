import 'package:flutter/material.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import 'job_detail.dart';
import 'post_request.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});
  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _done = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simulated fetch so the skeleton state is part of the prototype.
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    bool isDone(Job j) => j.status == JobStatus.completed || j.status == JobStatus.cancelled;
    final list = s.clientJobs.where((j) => isDone(j) == _done).toList();

    return TabPage(
      eyebrow: 'Your requests',
      title: 'My',
      accent: 'jobs',
      headerChild: _Tabs(
        left: 'Active · ${s.clientJobs.where((j) => !isDone(j)).length}',
        right: 'History · ${s.clientJobs.where(isDone).length}',
        rightSelected: _done,
        onChanged: (v) => setState(() => _done = v),
      ),
      children: [
        if (_loading)
          for (var i = 0; i < 3; i++) const _SkeletonCard()
        else if (list.isEmpty)
          _Empty(done: _done)
        else
          for (final (i, j) in list.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _JobCard(job: j).enter(context, i),
            ),
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.left, required this.right, required this.rightSelected, required this.onChanged});
  final String left;
  final String right;
  final bool rightSelected;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    Widget half(String t, bool isRight) => Expanded(
      child: Pressable(
        haptic: false,
        onTap: () => onChanged(isRight),
        child: SizedBox(
          height: 40,
          child: Center(
            child: AnimatedDefaultTextStyle(
              duration: M.fast,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: rightSelected == isRight ? C.bg : C.ink,
                fontFamily: DefaultTextStyle.of(context).style.fontFamily,
              ),
              child: Text(t),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: M.base,
            curve: M.out,
            alignment: rightSelected ? Alignment.centerRight : Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: .5,
              child: Container(
                decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.pill)),
              ),
            ),
          ),
          Row(children: [half(left, false), half(right, true)]),
        ],
      ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.job});
  final Job job;
  @override
  Widget build(BuildContext context) {
    final c = job.craftsman;
    final needsRating = job.status == JobStatus.completed && !job.rated;
    return TagCard(
      raised: job.status == JobStatus.quoted || needsRating,
      onTap: () => Navigator.of(context).push(wipeRoute(JobDetailScreen(job: job))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(job.trade.icon, size: 16),
              const SizedBox(width: 6),
              Text(job.id, style: figs(size: 11, color: C.inkSoft)),
              const SizedBox(width: 6),
              Text('· ${ago(job.postedMinsAgo)}', style: figs(size: 11, color: C.inkSoft)),
              const Spacer(),
              StatusChip(job.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(job.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 10),
          if (job.status == JobStatus.quoted)
            Row(
              children: [
                for (final q in job.quotes.take(3))
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Avatar(craftsman: q.craftsman, size: 28),
                  ),
                const SizedBox(width: 6),
                Text(
                  '${job.quotes.length} quotes · from ${dzd(job.quotes.map((q) => q.amount).reduce((a, b) => a < b ? a : b))}',
                  style: figs(size: 12, weight: FontWeight.w700, color: C.hotText),
                ),
              ],
            )
          else if (c != null)
            Row(
              children: [
                Avatar(craftsman: c, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (job.price != null) Text(dzd(job.price!), style: figs(size: 13, weight: FontWeight.w700)),
              ],
            )
          else
            Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: C.inkSoft)),
                const SizedBox(width: 8),
                Text('Waiting for quotes…', style: figs(size: 12, color: C.inkSoft)),
              ],
            ),
          if (needsRating) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.sm)),
              child: Row(
                children: [
                  Icon(PhosphorIconsFill.star, size: 14, color: C.hotText),
                  const SizedBox(width: 6),
                  Text(
                    'Rate ${c?.firstName ?? ''} to close this job',
                    style: TextStyle(fontWeight: FontWeight.w700, color: C.hotText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(S.lg),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.lg),
        border: Border.all(color: C.line, width: 1.5),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Skeleton(width: 90, height: 12),
              Spacer(),
              Skeleton(width: 70, height: 18, radius: R.pill),
            ],
          ),
          SizedBox(height: 12),
          Skeleton(width: 220, height: 16),
          SizedBox(height: 12),
          Row(children: [Skeleton(width: 28, height: 28, radius: 8), SizedBox(width: 8), Skeleton(width: 120, height: 12)]),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.done});
  final bool done;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Icon(PhosphorIconsBold.toolbox, size: 44, color: C.inkSoft),
          const SizedBox(height: 12),
          Text(done ? 'No finished jobs yet' : 'Nothing broken right now', style: display(size: 18)),
          const SizedBox(height: 6),
          Text(
            done ? 'Completed and cancelled jobs show up here.' : 'When something breaks, post it and get quotes in minutes.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!done) ...[
            const SizedBox(height: S.lg),
            TagButton(
              label: 'Post a job',
              expand: false,
              icon: PhosphorIconsBold.plus,
              onTap: () => Navigator.of(context).push(wipeRoute(fullscreenDialog: true, const PostRequestScreen())),
            ),
          ],
        ],
      ),
    );
  }
}

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
import 'job_detail.dart';

/// Trade → describe + photos → urgency + place → review.
/// With [direct] set, the trade step is skipped and the job goes to that m'lem.
class PostRequestScreen extends StatefulWidget {
  const PostRequestScreen({super.key, this.direct, this.quoteOnly = false});
  final Craftsman? direct;
  final bool quoteOnly;
  @override
  State<PostRequestScreen> createState() => _PostRequestScreenState();
}

class _PostRequestScreenState extends State<PostRequestScreen> {
  late int _step = widget.direct != null ? 1 : 0;
  late Trade? _trade = widget.direct?.trade;
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final List<String> _photos = [];
  Urgency _urgency = Urgency.today;
  bool _sending = false;
  bool _forward = true;

  static const _stepNames = ['Trade', 'Problem', 'When', 'Review'];
  static const _gallery = ['plumb-1', 'plumb-2', 'elec-1', 'mech-1', 'wood-1', 'metal-2'];

  int get _first => widget.direct != null ? 1 : 0;

  bool get _canNext => switch (_step) {
    0 => _trade != null,
    1 => _title.text.trim().length >= 4,
    _ => true,
  };

  void _go(int to) {
    HapticFeedback.selectionClick();
    setState(() {
      _forward = to > _step;
      _step = to;
    });
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final job = await context.read<AppState>().postRequest(
      trade: _trade!,
      title: _title.text.trim(),
      description: _desc.text.trim(),
      urgency: _urgency,
      photos: List.of(_photos),
      direct: widget.direct,
    );
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final track = await Navigator.of(context).push<bool>(
      PageRouteBuilder<bool>(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, _, _) => _Posted(job: job, direct: widget.direct),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );
    if (!mounted) return;
    // The confirmation pops with true for "Track this job"; this form then
    // replaces itself so Back from the job lands on Home, not on the form.
    if (track == true) {
      Navigator.of(context).pushReplacement(wipeRoute(JobDetailScreen(job: job)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    final total = 4 - _first;
    final pos = _step - _first;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(S.gutter, 8, S.gutter, 0),
              child: Row(
                children: [
                  IconCircle(
                    icon: _step == _first ? PhosphorIconsBold.x : PhosphorIconsBold.arrowLeft,
                    label: _step == _first ? 'Close' : 'Back',
                    onTap: () => _step == _first ? Navigator.pop(context) : _go(_step - 1),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP ${pos + 1} OF $total · ${_stepNames[_step].toUpperCase()}',
                          style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(R.pill),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(end: (pos + 1) / total),
                            duration: M.slow,
                            curve: M.out,
                            builder: (_, v, _) => LinearProgressIndicator(value: v, minHeight: 6, backgroundColor: C.line, color: C.volt),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (widget.direct != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(S.gutter, 14, S.gutter, 0),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: C.tealWash, borderRadius: BorderRadius.circular(R.md)),
                  child: Row(
                    children: [
                      Avatar(craftsman: widget.direct!, size: 32),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.quoteOnly ? 'Asking ${widget.direct!.name} for a quote' : 'Booking ${widget.direct!.name} directly',
                          style: TextStyle(fontWeight: FontWeight.w700, color: C.teal),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: M.base,
                switchInCurve: M.out,
                switchOutCurve: Curves.easeIn,
                layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
                transitionBuilder: (c, a) {
                  final incoming = c.key == ValueKey(_step);
                  final dx = (incoming == _forward) ? .08 : -.08;
                  return FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(a),
                      child: c,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(S.gutter, S.xl, S.gutter, S.xl),
                    child: [_tradeStep, _describeStep, _whenStep, _reviewStep][_step](),
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(S.gutter, 12, S.gutter, 12 + pad.bottom),
              decoration: BoxDecoration(
                color: C.card,
                border: Border(top: BorderSide(color: C.line, width: 1.5)),
              ),
              child: TagButton(
                label: _step == 3 ? (widget.direct != null ? (widget.quoteOnly ? 'Send quote request' : 'Send booking') : "Post & alert m'lems") : 'Continue',
                icon: _step == 3 ? PhosphorIconsBold.paperPlaneRight : null,
                loading: _sending,
                onTap: _canNext ? (_step == 3 ? _submit : () => _go(_step + 1)) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _h(String t, [String? sub]) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Headline(t.replaceAll('\n', ' '), style: display(size: 28)),
      if (sub != null) ...[const SizedBox(height: 6), Text(sub, style: Theme.of(context).textTheme.bodySmall)],
      const SizedBox(height: S.xl),
    ],
  );

  Widget _tradeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('What kind of\nrepair?'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final (i, t) in Trade.values.indexed)
              Pressable(
                onTap: () {
                  setState(() => _trade = t);
                  Future.delayed(const Duration(milliseconds: 180), () {
                    if (mounted && _step == 0) _go(1);
                  });
                },
                child: AnimatedContainer(
                  duration: M.fast,
                  curve: M.out,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _trade == t ? C.volt : C.card,
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: _trade == t ? C.volt : C.line),
                    boxShadow: _trade == t ? lift : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(t.icon, size: 26, color: _trade == t ? C.onFill : C.volt),
                      const Spacer(),
                      Text(
                        t.label,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: _trade == t ? C.onFill : C.ink),
                      ),
                      Text(t.local, style: figs(size: 10.5, color: _trade == t ? C.onFillSoft : C.inkSoft)),
                    ],
                  ),
                ),
              ).enter(context, i),
          ],
        ),
      ],
    );
  }

  Widget _describeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h("What's wrong?", 'A short title and a photo get you quotes twice as fast.'),
        TextField(
          controller: _title,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (_) => setState(() {}),
          maxLength: 60,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          decoration: InputDecoration(hintText: _hintFor(_trade), counterText: ''),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desc,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          style: const TextStyle(fontSize: 16),
          decoration: const InputDecoration(hintText: 'Details: since when, what you tried, floor / access…'),
        ),
        const SizedBox(height: S.xl),
        Row(
          children: [
            Text(
              'PHOTOS',
              style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
            ),
            const Spacer(),
            Text('${_photos.length}/4', style: figs(size: 11, color: C.inkSoft)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              for (final p in _photos)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Photo(p, width: 92, height: 92),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Pressable(
                          semanticLabel: 'Remove photo',
                          onTap: () => setState(() => _photos.remove(p)),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: C.ink,
                              shape: BoxShape.circle,
                              border: Border.all(color: C.card, width: 2),
                            ),
                            child: Icon(PhosphorIconsBold.x, size: 12, color: C.bg),
                          ),
                        ),
                      ),
                    ],
                  ).animate().scale(begin: const Offset(.7, .7), duration: 220.ms, curve: M.spring).fadeIn(duration: 120.ms),
                ),
              if (_photos.length < 4)
                Pressable(
                  semanticLabel: 'Add photo',
                  onTap: _pickPhoto,
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: C.card,
                      borderRadius: BorderRadius.circular(R.md),
                      border: Border.all(color: C.lineStrong, width: 1.5),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(PhosphorIconsBold.camera, size: 24),
                        SizedBox(height: 4),
                        Text('Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _pickPhoto() {
    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, MediaQuery.paddingOf(ctx).bottom + S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Camera roll', style: display(size: 20)),
            const SizedBox(height: 4),
            Text('Prototype: pick a sample photo', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: S.lg),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final p in _gallery)
                  Pressable(
                    onTap: () {
                      if (!_photos.contains(p)) setState(() => _photos.add(p));
                      Navigator.pop(ctx);
                    },
                    child: Photo(p, radius: R.sm),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _hintFor(Trade? t) => switch (t) {
    Trade.plumbing => 'e.g. Leak under the kitchen sink',
    Trade.electrical => 'e.g. Breaker trips when oven is on',
    Trade.hvac => 'e.g. AC blows warm air',
    Trade.mechanic => 'e.g. Car won\'t start, battery?',
    Trade.carpentry => 'e.g. Bedroom door won\'t close',
    Trade.painting => 'e.g. Repaint living room, 20 m²',
    null => 'Short title',
  };

  Widget _whenStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('How urgent\nis it?'),
        for (final (i, u) in Urgency.values.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Pressable(
              scale: 0.98,
              onTap: () => setState(() => _urgency = u),
              child: AnimatedContainer(
                duration: M.fast,
                curve: M.out,
                padding: const EdgeInsets.all(S.lg),
                decoration: BoxDecoration(
                  color: _urgency == u ? (u == Urgency.now ? C.hot : C.card) : C.bg,
                  borderRadius: BorderRadius.circular(R.lg - 4),
                  border: Border.all(color: _urgency == u ? (u == Urgency.now ? C.hot : C.volt) : C.line, width: _urgency == u ? 1.5 : 1),
                  boxShadow: _urgency == u ? lift : null,
                ),
                child: Row(
                  children: [
                    Icon(switch (u) {
                      Urgency.now => PhosphorIconsBold.siren,
                      Urgency.today => PhosphorIconsBold.clock,
                      Urgency.week => PhosphorIconsBold.calendarBlank,
                    }, size: 24, color: _urgency == u && u == Urgency.now ? C.onFill : C.volt),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.label,
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _urgency == u && u == Urgency.now ? C.onFill : C.ink),
                          ),
                          Text(
                            u.hint,
                            style: TextStyle(fontSize: 13, color: _urgency == u && u == Urgency.now ? C.onFillSoft : C.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    AnimatedScale(scale: _urgency == u ? 1 : 0, duration: M.fast, curve: M.spring, child: Icon(PhosphorIconsFill.checkCircle, color: u == Urgency.now ? C.onFill : C.volt)),
                  ],
                ),
              ),
            ),
          ).enter(context, i),
        const SizedBox(height: S.lg),
        Text(
          'WHERE',
          style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
        ),
        const SizedBox(height: 10),
        TagCard(
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.md)),
                child: Icon(PhosphorIconsFill.mapPin, color: C.volt),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Home · Cité 1200 Logements', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Kouba, Alger 16050', style: TextStyle(fontSize: 13, color: C.inkSoft)),
                  ],
                ),
              ),
              Text(
                'Change',
                style: TextStyle(fontWeight: FontWeight.w700, color: C.hotText.withValues(alpha: 1)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewStep() {
    final reach = craftsmen.where((c) => c.trade == _trade && c.verified && kmFrom(clientHome, c.location) <= 10).length;
    final who = reach == 1 ? 'verified ${_trade!.local.toLowerCase()}' : 'verified ${_trade!.local.toLowerCase()}s';
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              k.toUpperCase(),
              style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
            ),
          ),
          Expanded(
            child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('Check and send'),
        TagCard(
          raised: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_trade!.icon, size: 20),
                  const SizedBox(width: 8),
                  Text(_trade!.label.toUpperCase(), style: figs(size: 12, weight: FontWeight.w700)),
                  const Spacer(),
                  UrgencyChip(_urgency),
                ],
              ),
              const SizedBox(height: 10),
              Text(_title.text, style: display(size: 20)),
              if (_desc.text.isNotEmpty) ...[const SizedBox(height: 6), Text(_desc.text, style: Theme.of(context).textTheme.bodySmall)],
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final p in _photos)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Photo(p, width: 56, height: 56, radius: R.sm),
                      ),
                  ],
                ),
              ],
              Divider(height: 28, color: C.line),
              row('Where', 'Kouba, Alger'),
              row('Sent to', widget.direct?.name ?? "$reach $who within 10 km"),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        Row(
          children: [
            Icon(PhosphorIconsBold.lockSimple, size: 14, color: C.inkSoft),
            const SizedBox(width: 6),
            Expanded(child: Text('Your phone number stays hidden until you accept a quote.', style: Theme.of(context).textTheme.bodySmall)),
          ],
        ),
      ],
    );
  }
}

/// Confirmation: the request "stamp" lands, then a radar sweeps while
/// nearby m'lems get alerted.
class _Posted extends StatelessWidget {
  const _Posted({required this.job, this.direct});
  final Job job;
  final Craftsman? direct;

  @override
  Widget build(BuildContext context) {
    final still = reduceMotion(context);
    final pros = craftsmen.where((c) => c.trade == job.trade).take(4).toList();
    Widget radar = SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            (still
                ? Container(
                    width: 220.0 - i * 60,
                    height: 220.0 - i * 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: C.lineStrong, width: 1.5),
                    ),
                  )
                : Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: C.volt, width: 2),
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(), delay: (i * 600).ms)
                      .scale(begin: const Offset(.2, .2), end: const Offset(1, 1), duration: 1800.ms, curve: Curves.easeOut)
                      .fadeOut(duration: 1800.ms, curve: Curves.easeIn)),
          for (final (i, c) in pros.indexed)
            Align(
              alignment: [const Alignment(-.75, -.55), const Alignment(.8, -.3), const Alignment(-.5, .75), const Alignment(.6, .7)][i],
              child: Avatar(
                craftsman: c,
                size: 34,
              ).animate(delay: (500 + i * 280).ms).fadeIn(duration: 200.ms).scale(begin: const Offset(.4, .4), curve: M.spring, duration: 300.ms),
            ),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: C.volt,
              shape: BoxShape.circle,
              boxShadow: lift,
            ),
            child: Icon(job.trade.icon, size: 28, color: C.onFill),
          ),
        ],
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(S.gutter),
          child: Column(
            children: [
              const Spacer(),
              radar,
              const SizedBox(height: S.xl),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.pill)),
                child: Text(
                  'Posted · ${job.id}',
                  style: figs(size: 14, weight: FontWeight.w700, color: C.volt),
                ),
              ).animate().scale(begin: const Offset(1.4, 1.4), end: const Offset(1, 1), duration: 360.ms, curve: M.spring).fadeIn(duration: 100.ms),
              const SizedBox(height: S.lg),
              Text(
                direct != null ? '${direct!.firstName} has your request' : "Alerting m'lems near you",
                textAlign: TextAlign.center,
                style: display(size: 26),
              ).animate(delay: 250.ms).fadeIn(duration: 240.ms).moveY(begin: 8, end: 0, curve: M.out),
              const SizedBox(height: 8),
              Text(
                direct != null
                    ? 'Usually replies in ~${direct!.responseMins} min. You\'ll get a notification.'
                    : 'Quotes usually arrive within 10 minutes. We\'ll notify you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ).animate(delay: 350.ms).fadeIn(duration: 240.ms),
              const Spacer(),
              TagButton(label: 'Track this job', onTap: () => Navigator.pop(context, true)),
              const SizedBox(height: 10),
              TagButton.light(label: 'Back to home', onTap: () => Navigator.pop(context)),
            ],
          ),
        ),
      ),
    );
  }
}

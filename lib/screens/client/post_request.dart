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
  bool _instant = true;
  late final List<List<Slot>> _days = slotsAhead();
  int _day = 0;
  Slot? _slot;
  Diagnosis? _dx;
  String? _scanning; // photo being read by the mock model
  bool _sending = false;
  bool _forward = true;

  /// Instant is "right now"; a slot today is "today"; later is "this week".
  Urgency get _urgency => _instant ? Urgency.now : (_slot != null && dayLabel(_slot!.day) != 'Today' ? Urgency.week : Urgency.today);
  PriceEstimate get _estimate => estimateFor(_trade!, instant: _instant, dx: _dx);

  static const _stepNames = ['Trade', 'Problem', 'When', 'Review'];
  static const _gallery = ['plumb-1', 'plumb-2', 'elec-1', 'mech-1', 'wood-1', 'metal-2'];

  int get _first => widget.direct != null ? 1 : 0;

  bool get _canNext => switch (_step) {
    0 => _trade != null,
    1 => _title.text.trim().length >= 4,
    2 => _instant || _slot != null,
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
      slot: _instant ? null : _slot,
      estimate: _estimate,
      diagnosis: _dx,
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
                          'Step ${pos + 1} of $total · ${_stepNames[_step]}',
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
              'Photos',
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
                          onTap: () => setState(() {
                            _photos.remove(p);
                            if (_photos.isEmpty) {
                              _dx = null;
                              _scanning = null;
                            }
                          }),
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
        const SizedBox(height: S.lg),
        _aiCard(),
      ],
    );
  }

  /// Fixy AI: reads the first photo and suggests what's wrong, a title,
  /// a time and parts. Prototype: canned answers per sample photo.
  Widget _aiCard() {
    if (_scanning == null && _dx == null) {
      return Row(
        children: [
          Icon(PhosphorIconsBold.sparkle, size: 16, color: C.volt),
          const SizedBox(width: 8),
          Expanded(child: Text('Add a photo and Fixy AI will guess the problem and the parts.', style: Theme.of(context).textTheme.bodySmall)),
        ],
      );
    }
    if (_scanning != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: C.volt),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(R.sm),
                child: Stack(
                  children: [
                    Positioned.fill(child: Photo(_scanning!, radius: 0)),
                    if (!reduceMotion(context))
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(height: 3, color: C.volt),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 61, duration: 900.ms, curve: Curves.easeInOut),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(PhosphorIconsBold.scan, size: 14, color: C.volt),
                      const SizedBox(width: 6),
                      Text(
                        'Fixy AI is reading your photo…',
                        style: figs(size: 10.5, weight: FontWeight.w700, color: C.volt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Skeleton(height: 12),
                  const SizedBox(height: 6),
                  const Skeleton(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      );
    }
    final dx = _dx!;
    final applied = _title.text.trim() == dx.title;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: C.lineStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsFill.sparkle, size: 14, color: C.volt),
              const SizedBox(width: 6),
              Text(
                'Fixy AI thinks',
                style: figs(size: 10.5, weight: FontWeight.w700, color: C.volt),
              ),
              const Spacer(),
              Text(
                '${(dx.confidence * 100).round()}% sure',
                style: figs(size: 10.5, weight: FontWeight.w700, color: C.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(dx.issue, style: display(size: 20)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(PhosphorIconsBold.timer, size: 14, color: C.inkSoft),
              const SizedBox(width: 4),
              Text('~${dx.minutes} min', style: figs(size: 11, color: C.inkSoft)),
              const SizedBox(width: 14),
              Icon(PhosphorIconsBold.wrench, size: 14, color: C.inkSoft),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  dx.parts,
                  overflow: TextOverflow.ellipsis,
                  style: figs(size: 11, color: C.inkSoft),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TagButton.light(
            compact: true,
            label: applied ? 'Title set' : 'Use "${dx.title}" as title',
            icon: applied ? PhosphorIconsBold.check : null,
            onTap: applied
                ? null
                : () => setState(() {
                    _title.text = dx.title;
                    if (_desc.text.isEmpty) _desc.text = 'Photo suggests: ${dx.issue.toLowerCase()}.';
                  }),
          ),
          const SizedBox(height: 6),
          Text('A guess, not a diagnosis. The m\'lem confirms on site.', style: figs(size: 10.5, color: C.inkSoft)),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms).moveY(begin: 8, end: 0, curve: M.out);
  }

  Future<void> _analyze(String photo) async {
    setState(() {
      _scanning = photo;
      _dx = null;
    });
    final dx = await context.read<AppState>().analyzePhoto(photo, _trade);
    if (!mounted || _scanning != photo) return;
    HapticFeedback.lightImpact();
    setState(() {
      _scanning = null;
      _dx = dx;
    });
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
                      if (!_photos.contains(p)) {
                        setState(() => _photos.add(p));
                        // Read the first photo only; that's the one m'lems see first.
                        if (_photos.length == 1) _analyze(p);
                      }
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
    final addr = context.watch<AppState>().address;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('When do you\nneed it?'),
        // Instant vs Scheduled: one segmented control, the slab slides.
        Container(
          height: 56,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: C.card,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: C.line),
          ),
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                AnimatedPositioned(
                  duration: M.base,
                  curve: M.out,
                  left: _instant ? 0 : box.maxWidth / 2,
                  width: box.maxWidth / 2,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(color: _instant ? C.hot : C.volt, borderRadius: BorderRadius.circular(R.sm)),
                  ),
                ),
                Row(
                  children: [
                    for (final instant in [true, false])
                      Expanded(
                        child: Semantics(
                          selected: _instant == instant,
                          button: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _instant = instant);
                            },
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    instant ? PhosphorIconsBold.lightning : PhosphorIconsBold.calendarBlank,
                                    size: 18,
                                    color: _instant == instant ? C.onFill : C.ink,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    instant ? 'Instant' : 'Scheduled',
                                    style: display(size: 18, weight: FontWeight.w700, color: _instant == instant ? C.onFill : C.ink),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: S.lg),
        AnimatedSize(duration: M.base, curve: M.out, alignment: Alignment.topCenter, child: _instant ? _instantInfo() : _slotPicker()),
        const SizedBox(height: S.xl),
        Text(
          'Where',
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
                    Text('${addr.label} · ${addr.line}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${addr.commune}, Alger', style: TextStyle(fontSize: 13, color: C.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _instantInfo() {
    final near = craftsmen.where((c) => c.trade == _trade && c.available).toList();
    final fastest = near.isEmpty ? 25 : near.map((c) => c.responseMins).reduce((a, b) => a < b ? a : b) + 10;
    return Container(
      key: const ValueKey('instant'),
      width: double.infinity,
      padding: const EdgeInsets.all(S.lg),
      decoration: BoxDecoration(color: C.hotWash, borderRadius: BorderRadius.circular(R.md)),
      child: Row(
        children: [
          Icon(PhosphorIconsBold.siren, color: C.hotText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${near.length} free now · first one in ~$fastest min',
                  style: TextStyle(fontWeight: FontWeight.w700, color: C.hotText),
                ),
                const SizedBox(height: 2),
                Text('For leaks, outages, anything that can\'t wait. Adds an 800 DA priority fee.', style: TextStyle(fontSize: 13, color: C.inkSoft)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slotPicker() {
    final slots = _days[_day];
    return Column(
      key: const ValueKey('slots'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = _days[i].first.day;
              final on = i == _day;
              final free = _days[i].where((x) => !x.taken).length;
              return Pressable(
                semanticLabel: '${dayLabel(d)}, $free free slots',
                onTap: () => setState(() {
                  _day = i;
                  if (_slot != null && _slot!.day != d) _slot = null;
                }),
                child: AnimatedContainer(
                  duration: M.fast,
                  width: 64,
                  decoration: BoxDecoration(
                    color: on ? C.volt : C.card,
                    borderRadius: BorderRadius.circular(R.md),
                    border: Border.all(color: on ? C.volt : C.line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        i == 0 ? 'Today' : weekday(d),
                        style: figs(size: 10, weight: FontWeight.w700, color: on ? C.onFillSoft : C.inkSoft),
                      ),
                      Text(
                        '${d.day}',
                        style: display(size: 24, weight: FontWeight.w800, color: on ? C.onFill : C.ink).copyWith(height: 1.05),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: S.md),
        if (slots.every((x) => x.taken))
          Text('Fully booked. Try another day.', style: Theme.of(context).textTheme.bodySmall)
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: [
              for (final x in slots)
                Pressable(
                  semanticLabel: x.taken ? '${x.hours}, taken' : x.hours,
                  onTap: x.taken
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _slot = x);
                        },
                  child: AnimatedContainer(
                    duration: M.fast,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _slot == x ? C.volt : (x.taken ? C.bg : C.card),
                      borderRadius: BorderRadius.circular(R.sm),
                      border: Border.all(color: _slot == x ? C.volt : C.line),
                    ),
                    child: Text(
                      '${x.start.toString().padLeft(2, '0')}–${x.end.toString().padLeft(2, '0')}',
                      style: figs(
                        size: 13,
                        weight: FontWeight.w700,
                        color: _slot == x ? C.onFill : (x.taken ? C.inkSoft.withValues(alpha: .5) : C.ink),
                      ).copyWith(decoration: x.taken ? TextDecoration.lineThrough : null),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _priceCard() => PriceBreakdown(estimate: _estimate);

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
              k,
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
                  Text(_trade!.label, style: figs(size: 12, weight: FontWeight.w700)),
                  const Spacer(),
                  _instant
                      ? UrgencyChip(_urgency)
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.sm)),
                          child: Text('Scheduled', style: figs(size: 10.5, weight: FontWeight.w700, color: C.volt)),
                        ),
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
              row('Where', '${context.read<AppState>().address.label} · ${context.read<AppState>().address.commune}'),
              row('When', _instant ? 'Instant · first m\'lem free' : '${dayLabel(_slot!.day)} · ${_slot!.hours}'),
              row('Sent to', widget.direct?.name ?? "$reach $who within 10 km"),
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        _priceCard(),
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

/// Upfront price breakdown, shown before anything is sent.
class PriceBreakdown extends StatelessWidget {
  const PriceBreakdown({super.key, required this.estimate, this.locked});
  final PriceEstimate estimate;
  final int? locked; // the accepted quote, once there is one
  @override
  Widget build(BuildContext context) {
    String money(PriceLine l) => l.isRange ? '${dzd(l.low).replaceAll(' DA', '')}–${dzd(l.high)}' : dzd(l.low);
    return TagCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(PhosphorIconsBold.receipt, size: 16, color: C.volt),
              const SizedBox(width: 8),
              Text(
                'Upfront estimate',
                style: figs(size: 11, weight: FontWeight.w700, color: C.volt),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final l in estimate.lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (l.note != null) Text(l.note!, style: figs(size: 10.5, color: C.inkSoft)),
                      ],
                    ),
                  ),
                  Text(money(l), style: figs(size: 13, weight: FontWeight.w700)),
                ],
              ),
            ),
          Divider(height: 20, color: C.lineStrong),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  locked != null ? 'Estimate was' : 'You pay',
                  style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
                ),
              ),
              Text(
                '${dzd(estimate.low).replaceAll(' DA', '')}–${dzd(estimate.high)}',
                style: display(size: 26, weight: FontWeight.w800, color: locked != null ? C.inkSoft : C.ink),
              ),
            ],
          ),
          if (locked != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Locked price',
                    style: figs(size: 11, weight: FontWeight.w700, color: C.teal),
                  ),
                ),
                Text(
                  dzd(locked!),
                  style: display(size: 26, weight: FontWeight.w800, color: C.teal),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              'Quotes land inside this range. The quote you accept is the final price, paid cash after the job.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
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
            decoration: BoxDecoration(color: C.volt, shape: BoxShape.circle, boxShadow: lift),
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

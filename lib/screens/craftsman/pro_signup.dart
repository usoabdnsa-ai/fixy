import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/account.dart' show signOut;
import '../shared/documents.dart';
import 'pro_shell.dart';

const _communes = ['Kouba', 'Hussein Dey', 'Bab Ezzouar', 'El Harrach', 'Hydra', 'Bir Mourad Raïs', 'Bab El Oued', 'Chéraga'];

/// Optional trade documents a m'lem can attach.
const _certs = [
  ('CFPA diploma', 'Vocational training certificate'),
  ('Carte d\'artisan', 'Chambre de l\'artisanat (CAM)'),
  ('Registre de commerce', 'If you work as a company'),
];

/// New m'lem account: about you → ID card → trade documents → review.
/// Submitting puts the application in the admin Verify queue.
class ProSignupScreen extends StatefulWidget {
  const ProSignupScreen({super.key});
  @override
  State<ProSignupScreen> createState() => _ProSignupScreenState();
}

enum _Up { none, reading, done }

class _ProSignupScreenState extends State<ProSignupScreen> {
  int _step = 0;
  bool _forward = true;
  final _name = TextEditingController();
  final _nin = TextEditingController();
  Trade? _trade;
  String _commune = _communes.first;
  double _years = 5;
  _Up _front = _Up.none, _back = _Up.none;
  final Map<String, _Up> _docs = {};
  bool _consent = false;
  bool _sending = false;

  static const _steps = ['About you', 'ID card', 'Trade papers', 'Review'];

  bool get _canNext => switch (_step) {
    0 => _name.text.trim().split(' ').where((w) => w.isNotEmpty).length >= 2 && _trade != null,
    1 => _front == _Up.done && _back == _Up.done && _nin.text.replaceAll(' ', '').length == 18,
    2 => !_docs.values.contains(_Up.reading),
    _ => _consent,
  };

  void _go(int to) {
    HapticFeedback.selectionClick();
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = to > _step;
      _step = to;
    });
  }

  /// Mock camera / gallery: always succeeds after a short "reading" beat.
  Future<void> _upload(String what, void Function(_Up) set) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(R.lg))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, MediaQuery.paddingOf(ctx).bottom + S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: C.lineStrong, borderRadius: BorderRadius.circular(R.pill)),
              ),
            ),
            const SizedBox(height: S.lg),
            Text('Add $what', style: display(size: 22)),
            const SizedBox(height: 4),
            Text('Lay it flat, in good light, with all four corners visible.', style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: S.lg),
            TagButton(label: 'Take a photo', icon: PhosphorIconsBold.camera, onTap: () => Navigator.pop(ctx, true)),
            const SizedBox(height: 10),
            TagButton.light(label: 'Choose from gallery', icon: PhosphorIconsBold.images, onTap: () => Navigator.pop(ctx, true)),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => set(_Up.reading));
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => set(_Up.done));
  }

  Future<void> _submit() async {
    setState(() => _sending = true);
    final docs = ['National ID (front)', 'National ID (back)', ..._docs.entries.where((e) => e.value == _Up.done).map((e) => e.key)];
    await context.read<AppState>().submitApplication(
      name: _name.text.trim(),
      trade: _trade!,
      commune: _commune,
      years: _years.round(),
      nin: _nin.text.trim(),
      documents: docs,
    );
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(const PendingReviewScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(S.gutter, pad.top + 10, S.gutter, 0),
            child: Row(
              children: [
                IconCircle(
                  icon: _step == 0 ? PhosphorIconsBold.x : PhosphorIconsBold.arrowLeft,
                  label: _step == 0 ? 'Cancel' : 'Back',
                  onTap: () => _step == 0 ? signOut(context) : _go(_step - 1),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Step ${_step + 1} of 4 · ${_steps[_step]}",
                        style: figs(size: 11, weight: FontWeight.w600, color: C.inkSoft),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(R.pill),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(end: (_step + 1) / 4),
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
          Expanded(
            child: AnimatedSwitcher(
              duration: M.base,
              switchInCurve: M.out,
              layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topCenter, children: [...prev, ?cur]),
              transitionBuilder: (c, a) {
                final dx = (c.key == ValueKey(_step)) == _forward ? .08 : -.08;
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
                  child: [_aboutStep, _idStep, _docsStep, _reviewStep][_step](),
                ),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(S.gutter, 12, S.gutter, 12 + pad.bottom),
            decoration: BoxDecoration(
              color: C.card,
              border: Border(top: BorderSide(color: C.line)),
            ),
            child: TagButton(
              label: _step == 3 ? 'Submit for verification' : (_step == 2 && _docs.isEmpty ? 'Skip for now' : 'Continue'),
              icon: _step == 3 ? PhosphorIconsBold.paperPlaneRight : null,
              loading: _sending,
              onTap: _canNext ? (_step == 3 ? _submit : () => _go(_step + 1)) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _h(String t, String sub) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Headline(t, style: display(size: 28)),
      const SizedBox(height: 6),
      Text(sub, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: S.xl),
    ],
  );

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: S.lg),
    child: Text(
      t,
      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: C.ink),
    ),
  );

  // ---------- 1. about you ----------

  Widget _aboutStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Expanded(child: _h("Let's set up your m'lem profile", 'Clients see this. It takes about 3 minutes.'))]),
        _label('Full name (as on your ID)'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'e.g. Mehdi Benali'),
        ),
        _label('Your trade'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in Trade.values)
              Pressable(
                semanticLabel: t.label,
                onTap: () => setState(() => _trade = t),
                child: AnimatedContainer(
                  duration: M.fast,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _trade == t ? C.volt : C.card,
                    borderRadius: BorderRadius.circular(R.pill),
                    border: Border.all(color: _trade == t ? C.volt : C.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(t.icon, size: 16, color: _trade == t ? C.onFill : C.inkSoft),
                      const SizedBox(width: 6),
                      Text(
                        t.label,
                        style: TextStyle(fontWeight: FontWeight.w600, color: _trade == t ? C.onFill : C.ink),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        _label('Where you work'),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _communes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = _communes[i];
              final on = c == _commune;
              return Pressable(
                onTap: () => setState(() => _commune = c),
                child: AnimatedContainer(
                  duration: M.fast,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: on ? C.voltWash : C.card,
                    borderRadius: BorderRadius.circular(R.pill),
                    border: Border.all(color: on ? C.volt : C.line),
                  ),
                  child: Text(
                    c,
                    style: TextStyle(fontWeight: FontWeight.w600, color: on && C.isLight ? C.volt : C.ink),
                  ),
                ),
              );
            },
          ),
        ),
        _label('Years of experience'),
        Row(
          children: [
            Expanded(
              child: Slider(value: _years, min: 0, max: 30, divisions: 30, onChanged: (v) => setState(() => _years = v)),
            ),
            SizedBox(
              width: 64,
              child: Text(
                '${_years.round()} yrs',
                textAlign: TextAlign.right,
                style: figs(size: 14, weight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------- 2. ID card ----------

  Widget _idStep() {
    final name = _name.text.trim().isEmpty ? 'Your name' : _name.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('Your national ID card', 'Only the Fixy team sees it. Clients only see the Verified badge.'),
        Row(
          children: [
            Expanded(
              child: _idSlot(
                'Front',
                _front,
                () => _upload('the front of your ID', (u) {
                  _front = u;
                  // The mock "reads" the NIN off the card.
                  if (u == _Up.done && _nin.text.isEmpty) _nin.text = '1099 8812 0457 3321 08';
                }),
                back: false,
                name: name,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: _idSlot('Back', _back, () => _upload('the back of your ID', (u) => _back = u), back: true, name: name)),
          ],
        ),
        _label('NIN (national identification number)'),
        TextField(
          controller: _nin,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '18 digits, on the front of the card',
            suffixIcon: _front == _Up.done && _nin.text.isNotEmpty ? Icon(PhosphorIconsFill.sparkle, color: C.volt, size: 18) : null,
          ),
        ),
        if (_front == _Up.done)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Read from your card. Fix it if anything is wrong.', style: figs(size: 11, color: C.inkSoft)),
          ),
        const SizedBox(height: S.lg),
        _tip(PhosphorIconsBold.lockSimple, 'Your ID is encrypted and deleted 30 days after the decision.'),
      ],
    );
  }

  Widget _idSlot(String side, _Up state, VoidCallback onTap, {required bool back, required String name}) {
    return Pressable(
      semanticLabel: '$side of ID card',
      onTap: state == _Up.reading ? null : onTap,
      child: AspectRatio(
        aspectRatio: 1.45,
        child: AnimatedContainer(
          duration: M.base,
          decoration: BoxDecoration(
            color: state == _Up.none ? C.card : C.bg,
            borderRadius: BorderRadius.circular(R.md),
            border: Border.all(color: state == _Up.done ? C.teal : C.lineStrong, width: state == _Up.done ? 2 : 1.5),
          ),
          clipBehavior: Clip.antiAlias,
          child: switch (state) {
            _Up.none => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: C.voltWash, shape: BoxShape.circle),
                  child: Icon(PhosphorIconsBold.camera, size: 18, color: C.isLight ? C.volt : C.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  side,
                  style: TextStyle(fontWeight: FontWeight.w700, color: C.ink),
                ),
                Text('Tap to add', style: figs(size: 10.5, color: C.inkSoft)),
              ],
            ),
            _ => Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: FittedBox(
                      child: IdCardPreview(name: name, nin: '109988120457332108', back: back),
                    ),
                  ),
                ),
                if (state == _Up.reading) ...[
                  Positioned.fill(child: ColoredBox(color: C.bg.withValues(alpha: .45))),
                  if (!reduceMotion(context))
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(height: 3, color: C.volt),
                    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: 0, end: 100, duration: 800.ms, curve: Curves.easeInOut),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.pill), boxShadow: lift),
                      child: Text(
                        'Reading…',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: C.ink),
                      ),
                    ),
                  ),
                ],
                if (state == _Up.done)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: C.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(PhosphorIconsBold.check, size: 12, color: Colors.white),
                    ).animate().scale(begin: const Offset(.3, .3), curve: M.spring, duration: 320.ms),
                  ),
              ],
            ),
          },
        ),
      ),
    );
  }

  // ---------- 3. trade documents ----------

  Widget _docsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('Proof of your trade', 'Optional, but m\'lems with a certificate get about 3× more requests.'),
        for (final (i, (name, sub)) in _certs.indexed) ...[
          TagCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _docs[name] == _Up.done
                    ? const DocThumb(label: '', size: 40)
                    : Container(
                        width: 40,
                        height: 48,
                        decoration: BoxDecoration(
                          color: C.bg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: C.line),
                        ),
                        child: Icon(PhosphorIconsBold.certificate, size: 18, color: C.inkSoft),
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(fontWeight: FontWeight.w700, color: C.ink),
                      ),
                      Text(
                        _docs[name] == _Up.done ? 'Uploaded · 1 photo' : sub,
                        style: TextStyle(fontSize: 12.5, color: _docs[name] == _Up.done ? C.teal : C.inkSoft),
                      ),
                    ],
                  ),
                ),
                switch (_docs[name]) {
                  _Up.reading => SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: C.volt)),
                  _Up.done => IconCircle(icon: PhosphorIconsBold.x, label: 'Remove $name', onTap: () => setState(() => _docs.remove(name))),
                  _ => TagButton.dark(
                    compact: true,
                    expand: false,
                    label: 'Add',
                    icon: PhosphorIconsBold.plus,
                    onTap: () => _upload(name, (u) => _docs[name] = u),
                  ),
                },
              ],
            ),
          ).enter(context, i),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: S.sm),
        _tip(PhosphorIconsBold.question, 'No papers? You can still be verified with your ID. Your first 3 jobs are reviewed by the Fixy team.'),
      ],
    );
  }

  // ---------- 4. review ----------

  Widget _reviewStep() {
    final docs = _docs.entries.where((e) => e.value == _Up.done).map((e) => e.key).toList();
    Widget row(String k, String v) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 104,
            child: Text(k, style: TextStyle(fontSize: 13, color: C.inkSoft)),
          ),
          Expanded(
            child: Text(
              v,
              style: TextStyle(fontWeight: FontWeight.w600, color: C.ink),
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _h('Check and submit', 'The Fixy team reviews applications in under 24 hours.'),
        TagCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row('Name', _name.text.trim()),
              row('Trade', '${_trade!.label} · ${_trade!.local}'),
              row('Area', '$_commune, Alger'),
              row('Experience', '${_years.round()} years'),
              row('NIN', _nin.text.trim()),
              Divider(height: 24, color: C.line),
              Text(
                'Documents',
                style: TextStyle(fontWeight: FontWeight.w700, color: C.ink),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final back in [false, true])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pressable(
                          semanticLabel: back ? 'View ID back' : 'View ID front',
                          onTap: () => showDocument(
                            context,
                            IdCardPreview(name: _name.text.trim(), nin: '109988120457332108', back: back),
                            back ? 'ID card · back' : 'ID card · front',
                          ),
                          child: FittedBox(
                            child: IdCardPreview(name: _name.text.trim(), nin: '109988120457332108', back: back, width: 280),
                          ),
                        ),
                      ),
                    for (final d in docs)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: d,
                          child: const DocThumb(label: '', size: 58),
                        ),
                      ),
                  ],
                ),
              ),
              if (docs.isEmpty) ...[
                const SizedBox(height: 6),
                Text('No trade papers. You can add them later from your profile.', style: figs(size: 11, color: C.inkSoft)),
              ],
            ],
          ),
        ),
        const SizedBox(height: S.lg),
        Pressable(
          semanticLabel: 'I confirm these documents are mine',
          onTap: () => setState(() => _consent = !_consent),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: M.fast,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _consent ? C.volt : C.card,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: _consent ? C.volt : C.lineStrong, width: 2),
                ),
                child: _consent ? const Icon(PhosphorIconsBold.check, size: 14, color: Colors.white) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These documents are mine and up to date. I accept the Fixy m\'lem rules: fair prices, show up on time, one review per job.',
                  style: TextStyle(fontSize: 13.5, color: C.ink, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tip(IconData icon, String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.md)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: C.isLight ? C.volt : C.ink),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: C.ink, height: 1.4)),
        ),
      ],
    ),
  );
}

/// After submitting: where the application stands. Updates live when the
/// admin (or the demo button) decides.
class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final app = s.myApplication;
    final pad = MediaQuery.paddingOf(context);
    if (app == null) return const Scaffold();
    final decided = app.decision;
    final ok = decided == true;

    Widget stepRow(String title, String sub, {required bool done, bool active = false, bool last = false}) {
      final color = done ? C.teal : (active ? C.volt : C.lineStrong);
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: done ? C.teal : (active ? C.voltWash : C.card),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: done
                      ? const Icon(PhosphorIconsBold.check, size: 13, color: Colors.white)
                      : (active ? Center(child: LiveDot(color: C.volt, size: 6)) : null),
                ),
                if (!last)
                  Expanded(
                    child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4), color: done ? C.teal : C.line),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 20, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.w700, color: C.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(sub, style: TextStyle(fontSize: 13, color: C.inkSoft)),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(S.gutter, pad.top + S.xl, S.gutter, pad.bottom + S.xl),
        children: [
          Center(
            child: AnimatedSwitcher(
              duration: M.slow,
              transitionBuilder: (c, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: M.spring),
                child: c,
              ),
              child: Container(
                key: ValueKey(decided),
                width: 96,
                height: 96,
                decoration: BoxDecoration(color: ok ? C.tealWash : (decided == false ? C.redWash : C.voltWash), shape: BoxShape.circle),
                child: Icon(
                  ok ? PhosphorIconsFill.sealCheck : (decided == false ? PhosphorIconsBold.warning : PhosphorIconsBold.clock),
                  size: 46,
                  color: ok ? C.teal : (decided == false ? C.red : (C.isLight ? C.volt : C.ink)),
                ),
              ),
            ),
          ),
          const SizedBox(height: S.lg),
          Text(
            ok ? "You're verified, ${app.craftsman.firstName}!" : (decided == false ? 'We need more information' : 'Application sent'),
            textAlign: TextAlign.center,
            style: display(size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            ok
                ? 'Your profile now shows the Verified badge. Go online to start getting jobs near ${app.craftsman.commune}.'
                : (decided == false
                      ? 'The Fixy team could not confirm your documents. We sent you an SMS with what to fix.'
                      : 'The Fixy team checks your ID and papers, usually in under 24 hours. We\'ll send you an SMS.'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: S.xl),
          TagCard(
            child: Column(
              children: [
                stepRow('Application submitted', 'ID card + ${app.documents.length - 2} trade document${app.documents.length - 2 == 1 ? '' : 's'}', done: true),
                stepRow('Fixy team review', decided == null ? 'In progress · usually under 24 h' : 'Done', done: decided != null, active: decided == null),
                stepRow('Verified badge on your profile', ok ? 'Live' : 'Then you can receive jobs', done: ok, last: true),
              ],
            ),
          ),
          const SizedBox(height: S.xl),
          if (ok)
            TagButton(
              label: 'Start getting jobs',
              icon: PhosphorIconsBold.lightning,
              onTap: () {
                s.switchMode(Role.craftsman);
                Navigator.of(context).pushAndRemoveUntil(fadeRoute(const ProShell()), (_) => false);
              },
            )
          else ...[
            if (decided == null)
              TagButton.dark(
                label: 'Demo: approve as the Fixy team',
                icon: PhosphorIconsBold.sealCheck,
                onTap: () {
                  HapticFeedback.heavyImpact();
                  s.decide(app, true);
                },
              ),
            const SizedBox(height: 10),
            Text(
              'Prototype tip: the application is also in the admin app under Verify. Sign in as "Fixy team" to approve it there.',
              textAlign: TextAlign.center,
              style: figs(size: 11, color: C.inkSoft),
            ),
          ],
          const SizedBox(height: S.lg),
          TagButton.light(label: 'Sign out', icon: PhosphorIconsBold.signOut, onTap: () => signOut(context)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';

/// Three separate scores (punctuality, pricing, quality). One rating per
/// completed job: AppState.rate() refuses a second one.
class RateScreen extends StatefulWidget {
  const RateScreen({super.key, required this.job});
  final Job job;
  @override
  State<RateScreen> createState() => _RateScreenState();
}

class _RateScreenState extends State<RateScreen> {
  final _scores = <String, int>{'Punctuality': 0, 'Pricing': 0, 'Quality': 0};
  final _text = TextEditingController();
  bool _done = false;

  bool get _complete => _scores.values.every((v) => v > 0);

  void _submit() {
    final ok = context.read<AppState>().rate(
      widget.job,
      punctuality: _scores['Punctuality']!,
      pricing: _scores['Pricing']!,
      quality: _scores['Quality']!,
      text: _text.text.trim().isEmpty ? 'Good job.' : _text.text.trim(),
    );
    if (!ok) {
      toast(context, 'This job already has a rating.');
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.job.craftsman!;
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(duration: M.base, child: _done ? _thanks(c) : _form(c, pad)),
      ),
    );
  }

  Widget _form(Craftsman c, EdgeInsets pad) {
    return Column(
      key: const ValueKey('form'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(S.gutter),
            children: [
              Row(
                children: [IconCircle(icon: PhosphorIconsBold.x, label: 'Close', onTap: () => Navigator.pop(context))],
              ),
              const SizedBox(height: S.xl),
              Center(child: Avatar(craftsman: c, size: 76)),
              const SizedBox(height: S.md),
              Center(child: Text('How did ${c.firstName} do?', style: display(size: 26))),
              const SizedBox(height: 4),
              Center(
                child: Text('${widget.job.title} · ${widget.job.id}', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ),
              const SizedBox(height: S.xl),
              for (final k in _scores.keys)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: TagCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(k, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        ),
                        _StarPicker(value: _scores[k]!, onChanged: (v) => setState(() => _scores[k] = v)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              TextField(
                controller: _text,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 16),
                decoration: const InputDecoration(hintText: 'Anything others should know? (optional)'),
              ),
              const SizedBox(height: S.md),
              Row(
                children: [
                  const Icon(PhosphorIconsBold.shieldCheck, size: 14, color: C.inkSoft),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Only clients with a completed job can rate. One review per job.', style: Theme.of(context).textTheme.bodySmall)),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(S.gutter, 8, S.gutter, S.lg),
          child: TagButton(label: _complete ? 'Submit rating' : 'Score all three', onTap: _complete ? _submit : null),
        ),
      ],
    );
  }

  Widget _thanks(Craftsman c) {
    final avg = _scores.values.reduce((a, b) => a + b) / 3;
    return Padding(
      key: const ValueKey('thanks'),
      padding: const EdgeInsets.all(S.gutter),
      child: Column(
        children: [
          const Spacer(),
          Transform.rotate(
            angle: -0.06,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: C.teal, width: 3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: mono(size: 44, weight: FontWeight.w700, color: C.teal),
                  ),
                  Text(
                    'REVIEW FILED',
                    style: mono(size: 13, weight: FontWeight.w700, color: C.teal),
                  ),
                ],
              ),
            ),
          ).animate().scale(begin: const Offset(2, 2), end: const Offset(1, 1), duration: 380.ms, curve: M.spring).fadeIn(duration: 100.ms),
          const SizedBox(height: S.xl),
          Text('Shukran!', style: display(size: 30)).animate(delay: 250.ms).fadeIn().moveY(begin: 8, end: 0, curve: M.out),
          const SizedBox(height: 6),
          Text(
            "Your review is now on ${c.firstName}'s profile and helps your neighbours choose.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ).animate(delay: 350.ms).fadeIn(),
          const Spacer(),
          TagButton(label: 'Done', onTap: () => Navigator.pop(context)),
        ],
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(i);
            },
            child: Semantics(
              button: true,
              label: '$i star${i > 1 ? 's' : ''}',
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: AnimatedScale(
                  scale: i <= value ? 1.12 : 1,
                  duration: M.fast,
                  curve: M.spring,
                  child: Icon(i <= value ? PhosphorIconsFill.star : PhosphorIconsBold.star, size: 26, color: i <= value ? C.orange : C.lineStrong),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

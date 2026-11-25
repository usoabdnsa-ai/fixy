import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/provider_reviews.dart';

/// Screen 14: interactive 5-star selector, written feedback,
/// "Envoyer mon avis", and the provider's existing reviews.
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, required this.requestId});
  final String requestId;
  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  int _stars = 0;
  final _text = TextEditingController();
  bool _busy = false;

  static const _words = ['', 'Très décevant', 'Décevant', 'Correct', 'Très bien', 'Excellent'];

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final s = context.read<AppState>();
    final r = s.requests.byId(widget.requestId)!;
    setState(() => _busy = true);
    final ok = await attempt(context, () => s.addReview(r, _stars, _text.text));
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      toast(context, 'Merci ! Votre avis est publié.');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final r = s.requests.byId(widget.requestId)!;
    final p = s.providers.byId(r.providerId)!;
    final others = s.reviews.forProvider(p.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Votre avis')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          AppCard(
            child: Column(
              children: [
                Avatar(photo: p.photo, size: 64),
                const SizedBox(height: S.md),
                Text('Comment s’est passé le service avec ${p.name} ?', textAlign: TextAlign.center, style: title(size: 18)),
                const SizedBox(height: 4),
                Text(r.service, style: body(size: 14, color: C.inkSoft)),
                const SizedBox(height: S.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Pressable(
                        onTap: () => setState(() => _stars = i),
                        scale: .8,
                        semanticLabel: '$i étoile${i > 1 ? 's' : ''}',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: AnimatedScale(
                            duration: M.fast,
                            curve: M.spring,
                            scale: i <= _stars ? 1.08 : 1,
                            child: Icon(i <= _stars ? PhosphorIconsFill.star : PhosphorIconsBold.star, size: 42, color: i <= _stars ? C.star : C.lineStrong),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: S.sm),
                AnimatedSwitcher(
                  duration: M.fast,
                  child: Text(
                    _stars == 0 ? 'Touchez une étoile' : _words[_stars],
                    key: ValueKey(_stars),
                    style: body(size: 15, weight: FontWeight.w700, color: _stars == 0 ? C.inkFaint : C.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: S.lg),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            maxLength: 400,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Ponctualité, qualité du travail, prix… (facultatif)'),
          ),
          const SizedBox(height: S.sm),
          Btn('Envoyer mon avis', loading: _busy, onTap: _stars == 0 ? null : _send),
          if (others.isNotEmpty) ...[
            const SizedBox(height: S.xxl),
            Text('Ce que disent les autres clients', style: title(size: 17)),
            const SizedBox(height: S.md),
            for (final rv in others.take(4)) Padding(padding: const EdgeInsets.only(bottom: S.md), child: ReviewCard(rv)),
          ],
        ],
      ),
    );
  }
}

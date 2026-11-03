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
import '../shared/documents.dart';

/// NIN + trade-document review. Approving stamps the badge onto the profile.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pending = s.verifications.where((v) => v.decision == null).toList();
    final decided = s.verifications.where((v) => v.decision != null).toList();
    return TabPage(
      eyebrow: 'Trust & safety',
      title: 'Verify',
      accent: "m'lems",
      subtitle: '${pending.length} waiting · target under 24 h',
      children: [
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                Icon(PhosphorIconsFill.sealCheck, size: 44, color: C.teal).animate().scale(begin: const Offset(.5, .5), curve: M.spring, duration: 360.ms),
                const SizedBox(height: 10),
                Text('Queue is empty', style: display(size: 18)),
              ],
            ),
          ),
        for (final (i, v) in pending.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _Request(v: v).enter(context, i),
          ),
        if (decided.isNotEmpty) ...[
          const SizedBox(height: S.md),
          Text(
            'Decided today',
            style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
          ),
          const SizedBox(height: 8),
          for (final v in decided)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: C.line, width: 1.5),
              ),
              child: Row(
                children: [
                  Avatar(craftsman: v.craftsman, size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(v.craftsman.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  v.decision!
                      ? const VerifiedStamp(small: true, animate: true)
                      : Text(
                          'Rejected',
                          style: figs(size: 10.5, weight: FontWeight.w700, color: C.red),
                        ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Request extends StatefulWidget {
  const _Request({required this.v});
  final VerificationRequest v;
  @override
  State<_Request> createState() => _RequestState();
}

class _RequestState extends State<_Request> {
  final _checked = <int>{};

  @override
  Widget build(BuildContext context) {
    final v = widget.v;
    final c = v.craftsman;
    final all = _checked.length == v.documents.length;
    return TagCard(
      raised: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Avatar(craftsman: c, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('${c.trade.local} · ${c.commune} · ${c.years} yrs', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (v.uploaded)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: C.voltWash, borderRadius: BorderRadius.circular(R.pill)),
                  child: Text(
                    'New',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: C.isLight ? C.volt : C.ink),
                  ),
                ),
              Text(
                v.submittedHoursAgo == 0 ? 'now' : '${v.submittedHoursAgo} h',
                style: figs(size: 11, color: v.submittedHoursAgo > 12 ? C.hotText : C.inkSoft, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Uploaded from the app: show the actual card photos.
          if (v.uploaded)
            SizedBox(
              height: 110,
              child: Row(
                children: [
                  for (final back in [false, true]) ...[
                    Expanded(
                      child: Pressable(
                        semanticLabel: back ? 'View ID back' : 'View ID front',
                        onTap: () => showDocument(
                          context,
                          IdCardPreview(name: c.name, nin: v.nin.replaceAll(' ', ''), back: back),
                          back ? 'ID card · back' : 'ID card · front',
                        ),
                        child: FittedBox(
                          child: IdCardPreview(name: c.name, nin: v.nin.replaceAll(' ', ''), back: back),
                        ),
                      ),
                    ),
                    if (!back) const SizedBox(width: 8),
                  ],
                ],
              ),
            )
          else
            // ID card mock
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(R.sm),
                border: Border.all(color: C.lineStrong, width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 56,
                    decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(4)),
                    child: Icon(PhosphorIconsFill.user, color: C.inkSoft),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CARTE NATIONALE D\'IDENTITÉ',
                          style: figs(size: 9.5, weight: FontWeight.w700, color: C.inkSoft),
                        ),
                        const SizedBox(height: 4),
                        Text(c.name.toUpperCase(), style: figs(size: 12, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('NIN ${v.nin}', style: figs(size: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Checklist',
            style: figs(size: 10.5, weight: FontWeight.w700, color: C.inkSoft),
          ),
          for (var i = 0; i < v.documents.length; i++)
            Pressable(
              haptic: false,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _checked.contains(i) ? _checked.remove(i) : _checked.add(i));
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: M.fast,
                      curve: M.out,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _checked.contains(i) ? C.teal : C.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _checked.contains(i) ? C.teal : C.lineStrong, width: 2),
                      ),
                      child: AnimatedScale(
                        scale: _checked.contains(i) ? 1 : 0,
                        duration: M.fast,
                        curve: M.spring,
                        child: Icon(PhosphorIconsBold.check, size: 13, color: C.onFill),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(v.documents[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Pressable(
                      semanticLabel: 'View ${v.documents[i]}',
                      onTap: () => showDocument(
                        context,
                        v.documents[i].startsWith('National ID')
                            ? IdCardPreview(name: c.name, nin: v.nin.replaceAll(' ', ''), back: v.documents[i].contains('back'))
                            : const DocThumb(label: '', size: 180),
                        v.documents[i],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(PhosphorIconsBold.eye, size: 18, color: C.inkSoft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TagButton.light(
                  compact: true,
                  label: 'Reject',
                  onTap: () {
                    context.read<AppState>().decide(v, false);
                    toast(context, '${c.firstName} rejected. Reason sent by SMS.');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TagButton(
                  compact: true,
                  color: C.teal,
                  textColor: C.onFill,
                  label: all ? 'Grant Verified' : 'Check all ${v.documents.length} first',
                  icon: all ? PhosphorIconsBold.sealCheck : null,
                  onTap: all
                      ? () {
                          HapticFeedback.heavyImpact();
                          context.read<AppState>().decide(v, true);
                          toast(context, '${c.firstName} is now Verified');
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

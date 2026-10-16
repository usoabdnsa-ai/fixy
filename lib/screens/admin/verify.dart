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

/// NIN + trade-document review. Approving stamps the badge onto the profile.
class VerifyScreen extends StatelessWidget {
  const VerifyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final top = MediaQuery.paddingOf(context).top;
    final pending = s.verifications.where((v) => v.decision == null).toList();
    final decided = s.verifications.where((v) => v.decision != null).toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(S.gutter, top + 14, S.gutter, S.xl),
      children: [
        Text('Verification', style: display(size: 28)),
        const SizedBox(height: 4),
        Text('${pending.length} waiting · target under 24 h', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: S.lg),
        if (pending.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const Icon(
                  PhosphorIconsFill.sealCheck,
                  size: 44,
                  color: C.teal,
                ).animate().scale(begin: const Offset(.5, .5), curve: M.spring, duration: 360.ms),
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
            'DECIDED TODAY',
            style: mono(size: 11, weight: FontWeight.w700, color: C.inkSoft),
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
                          'REJECTED',
                          style: mono(size: 10.5, weight: FontWeight.w700, color: C.red),
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
                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('${c.trade.local} · ${c.commune} · ${c.years} yrs', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                '${v.submittedHoursAgo} h',
                style: mono(size: 11, color: v.submittedHoursAgo > 12 ? C.rust : C.inkSoft, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // ID card mock
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: C.paper,
              borderRadius: BorderRadius.circular(R.sm),
              border: Border.all(color: C.lineStrong, width: 1.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 56,
                  decoration: BoxDecoration(color: C.line, borderRadius: BorderRadius.circular(4)),
                  child: const Icon(PhosphorIconsFill.user, color: C.inkSoft),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARTE NATIONALE D\'IDENTITÉ',
                        style: mono(size: 9.5, weight: FontWeight.w700, color: C.inkSoft),
                      ),
                      const SizedBox(height: 4),
                      Text(c.name.toUpperCase(), style: mono(size: 12, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('NIN ${v.nin}', style: mono(size: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'CHECKLIST',
            style: mono(size: 10.5, weight: FontWeight.w700, color: C.inkSoft),
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
                        child: const Icon(PhosphorIconsBold.check, size: 13, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(v.documents[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const Icon(PhosphorIconsBold.eye, size: 16, color: C.inkSoft),
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
                  textColor: Colors.white,
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

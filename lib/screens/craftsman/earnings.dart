import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import 'pro_home.dart' show EarningsChart;

/// M'lem wallet: balance, cash-out, this week's split, and every payout.
/// Fixy takes [commissionRate] of each job; clients pay cash or Baridimob.
class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  bool _cashing = false;

  Future<void> _cashOut() async {
    final s = context.read<AppState>();
    final amount = s.balance;
    setState(() => _cashing = true);
    await s.cashOut();
    if (!mounted) return;
    setState(() => _cashing = false);
    toast(context, '${dzd(amount)} on its way to CCP •• 4471. Usually 24 h.');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pad = MediaQuery.paddingOf(context);
    final gross = s.earningsWeek;
    final fee = (gross * commissionRate).round();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(S.gutter, pad.top + 8, S.gutter, pad.bottom + S.xxl),
        children: [
          Row(
            children: [
              IconCircle(icon: PhosphorIconsBold.arrowLeft, label: 'Back', onTap: () => Navigator.pop(context)),
              const Spacer(),
              Text(
                'Wallet',
                style: figs(size: 12, weight: FontWeight.w700, color: C.inkSoft),
              ),
            ],
          ),
          const SizedBox(height: S.xl),
          Text(
            'Available balance',
            style: figs(size: 11, weight: FontWeight.w700, color: C.inkSoft),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            tween: Tween(end: s.balance.toDouble()),
            duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 700),
            curve: M.out,
            builder: (_, v, _) => Text(dzd(v.round()), style: display(size: 56, weight: FontWeight.w800).copyWith(height: 1)),
          ),
          const SizedBox(height: 12),
          const VoltRule(),
          const SizedBox(height: S.lg),
          TagButton(
            label: s.balance > 0 ? 'Cash out to CCP' : 'Nothing to cash out',
            icon: PhosphorIconsBold.arrowUpRight,
            loading: _cashing,
            onTap: s.balance > 0 ? _cashOut : null,
          ),
          const SizedBox(height: S.xl),
          Row(
            children: [
              _Split(label: 'Earned', value: dzd(gross)),
              const SizedBox(width: 10),
              _Split(label: 'Fixy ${(commissionRate * 100).round()}%', value: dzd(fee)),
              const SizedBox(width: 10),
              _Split(label: 'You keep', value: dzd(gross - fee), accent: true),
            ],
          ),
          const SizedBox(height: S.md),
          const EarningsChart(),
          const SizedBox(height: S.xl),
          Text('History', style: display(size: 19)),
          const SizedBox(height: 6),
          for (final p in s.payouts)
            Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: C.line)),
              ),
              child: Row(
                children: [
                  Icon(p.cashOut ? PhosphorIconsBold.arrowUpRight : PhosphorIconsBold.wrench, size: 18, color: p.cashOut ? C.inkSoft : C.volt),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${p.daysAgo == 0 ? 'Today' : (p.daysAgo == 1 ? 'Yesterday' : '${p.daysAgo} days ago')}${p.jobId != null ? ' · ${p.jobId}' : ''}',
                          style: figs(size: 10.5, color: C.inkSoft),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    p.amount > 0 ? '+${dzd(p.amount)}' : dzd(p.amount),
                    style: figs(size: 13, weight: FontWeight.w700, color: p.amount > 0 ? C.teal : C.inkSoft),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Split extends StatelessWidget {
  const _Split({required this.label, required this.value, this.accent = false});
  final String label;
  final String value;
  final bool accent;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent ? C.volt : C.card,
        borderRadius: BorderRadius.circular(R.md),
        border: Border.all(color: accent ? C.volt : C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: figs(size: 10, weight: FontWeight.w700, color: accent ? C.onFillSoft : C.inkSoft),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: figs(size: 15, weight: FontWeight.w700, color: accent ? C.onFill : C.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

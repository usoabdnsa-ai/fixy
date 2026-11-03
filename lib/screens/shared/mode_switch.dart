import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../client/client_shell.dart';
import '../craftsman/pro_shell.dart';

/// One account, two sides. Swaps the whole shell; the volt wipe makes the
/// change of world obvious.
class ModeSwitch extends StatelessWidget {
  const ModeSwitch({super.key, required this.to});
  final Role to;

  @override
  Widget build(BuildContext context) {
    final pro = to == Role.craftsman;
    return Pressable(
      scale: 0.98,
      semanticLabel: pro ? 'Switch to Pro mode' : 'Switch to client mode',
      onTap: () {
        HapticFeedback.heavyImpact();
        context.read<AppState>().switchMode(to);
        Navigator.of(context).pushAndRemoveUntil(fadeRoute(pro ? const ProShell() : const ClientShell()), (_) => false);
      },
      child: Container(
        padding: const EdgeInsets.all(S.lg),
        decoration: BoxDecoration(
          color: C.card,
          borderRadius: BorderRadius.circular(R.md),
          border: Border.all(color: C.volt, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: C.volt, borderRadius: BorderRadius.circular(R.sm)),
              child: Icon(PhosphorIconsBold.userSwitch, color: C.onFill),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pro ? 'PRO MODE' : 'CLIENT MODE', style: display(size: 22, weight: FontWeight.w800)),
                  Text(pro ? 'Take jobs, navigate, track earnings' : 'Book a m\'lem for your own place', style: TextStyle(fontSize: 13, color: C.inkSoft)),
                ],
              ),
            ),
            Icon(PhosphorIconsBold.arrowsLeftRight, color: C.volt),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/icons.dart';

import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../main.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import '../admin/admin_shell.dart';
import '../client/client_shell.dart';
import '../craftsman/pro_shell.dart';

/// Role → phone → OTP. Mock: any 4 digits pass.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  int _step = 0;
  Role _role = Role.client;
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  String? _error;

  bool get _phoneOk => RegExp(r'^0?[567]\d{8}$').hasMatch(_phone.text.replaceAll(' ', ''));

  Future<void> _sendCode() async {
    if (!_phoneOk) {
      setState(() => _error = 'Algerian mobile numbers start with 05, 06 or 07 and have 10 digits.');
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loading = false;
      _step = 2;
    });
  }

  Future<void> _verify() async {
    if (_otp.text.length < 4) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.read<AppState>().signIn(_role, _phone.text);
    final home = switch (_role) {
      Role.client => const ClientShell(),
      Role.craftsman => const ProShell(),
      Role.admin => const AdminShell(),
    };
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(home), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(S.gutter, pad.top + 14, S.gutter, 0),
            child: Row(
              children: [
                AnimatedOpacity(
                  opacity: _step == 0 ? 0 : 1,
                  duration: M.fast,
                  child: Pressable(
                    onTap: _step == 0 ? null : () => setState(() => _step--),
                    semanticLabel: 'Back',
                    scale: 0.92,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(border: Border.all(color: C.lineStrong), borderRadius: BorderRadius.circular(R.sm)),
                      child: Icon(PhosphorIconsBold.arrowLeft, size: 20, color: C.ink),
                    ),
                  ),
                ),
                const Spacer(),
                const Wordmark(size: 22),
                const Spacer(),
                Text('${idx(_step)}/03', style: figs(size: 12, weight: FontWeight.w700, color: C.volt).copyWith(letterSpacing: 1.2)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Step progress: three volt segments across the full width.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: S.gutter),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      height: 3,
                      color: C.lineStrong,
                      alignment: Alignment.centerLeft,
                      child: AnimatedFractionallySizedBox(
                        duration: M.slow,
                        curve: M.out,
                        widthFactor: i <= _step ? 1 : 0,
                        child: Container(color: C.volt),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, pad.bottom > 0 ? 0 : S.lg),
              child: AnimatedSwitcher(
                duration: M.base,
                switchInCurve: M.out,
                switchOutCurve: Curves.easeOut,
                transitionBuilder: (c, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(.06, 0), end: Offset.zero).animate(a),
                    child: c,
                  ),
                ),
                layoutBuilder: (cur, prev) => Stack(alignment: Alignment.topLeft, children: [...prev, ?cur]),
                child: KeyedSubtree(key: ValueKey(_step), child: [_roleStep(), _phoneStep(), _otpStep()][_step]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleStep() {
    Widget option(Role r, String title, String sub, IconData icon, int i) {
      final sel = _role == r;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Pressable(
          onTap: () => setState(() => _role = r),
          scale: 0.98,
          child: AnimatedContainer(
            duration: M.fast,
            curve: M.out,
            padding: const EdgeInsets.all(S.lg),
            decoration: BoxDecoration(
              color: sel ? C.card : C.bg,
              borderRadius: BorderRadius.circular(R.lg),
              border: Border.all(color: sel ? C.volt : C.line, width: sel ? 1.5 : 1),
              boxShadow: sel ? lift : null,
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: M.fast,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: sel ? C.volt : C.voltWash,
                    borderRadius: BorderRadius.circular(R.md),
                  ),
                  child: Icon(icon, color: sel ? C.onFill : C.volt),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      const SizedBox(height: 2),
                      Text(sub, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: sel ? 1 : 0,
                  duration: M.fast,
                  curve: M.spring,
                  child: Icon(PhosphorIconsFill.checkCircle, color: C.teal),
                ),
              ],
            ),
          ),
        ),
      ).enter(context, i);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline('Who are you', accent: 'on Fixy?', style: display(size: 40, weight: FontWeight.w800).copyWith(height: 1.02)),
        const SizedBox(height: S.xl),
        option(Role.client, 'I need a repair', 'Home or business. Post jobs, compare quotes.', PhosphorIconsBold.house, 0),
        option(Role.craftsman, "I'm a m'lem", 'Get local jobs, set your rates in DZD.', PhosphorIconsBold.toolbox, 1),
        option(Role.admin, 'Fixy team', 'Verification, disputes, metrics.', PhosphorIconsBold.shieldCheck, 2),
        const Spacer(),
        TagButton(label: 'Continue', icon: PhosphorIconsBold.arrowRight, onTap: () => setState(() => _step = 1)),
        const SizedBox(height: S.lg),
      ],
    );
  }

  Widget _phoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline('Your phone', accent: 'number', style: display(size: 40, weight: FontWeight.w800).copyWith(height: 1.02)),
        const SizedBox(height: 8),
        Text("We text you a code. No password to remember.", style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: S.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(R.md),
                border: Border.all(color: C.line, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text('+213', style: figs(size: 16, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _phone,
                autofocus: true,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendCode(),
                onChanged: (_) => setState(() => _error = null),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                style: figs(size: 18, weight: FontWeight.w600),
                decoration: InputDecoration(hintText: '0555 12 34 56', errorText: _error, errorMaxLines: 2),
              ),
            ),
          ],
        ),
        const Spacer(),
        TagButton(label: 'Send code', loading: _loading, onTap: _phone.text.isEmpty ? null : _sendCode),
        const SizedBox(height: S.lg),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Headline('Enter the', accent: '4-digit code', style: display(size: 40, weight: FontWeight.w800).copyWith(height: 1.02)),
        const SizedBox(height: 8),
        Text('Sent to +213 ${_phone.text}. Any code works in this prototype.', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: S.xl),
        Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < 4; i++)
                  Expanded(
                    child: AnimatedContainer(
                      duration: M.fast,
                      curve: M.out,
                      height: 68,
                      margin: EdgeInsets.only(right: i < 3 ? 10 : 0),
                      decoration: BoxDecoration(
                        color: C.card,
                        borderRadius: BorderRadius.circular(R.md),
                        border: Border.all(color: i == _otp.text.length ? C.volt : C.line, width: i == _otp.text.length ? 2 : 1),
                        boxShadow: i < _otp.text.length ? lift : null,
                      ),
                      alignment: Alignment.center,
                      child: i < _otp.text.length
                          ? Text(
                              _otp.text[i],
                              style: figs(size: 26, weight: FontWeight.w700),
                            ).animate().scale(begin: const Offset(.6, .6), duration: 160.ms, curve: M.spring)
                          : null,
                    ),
                  ),
              ],
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.01,
                child: TextField(
                  controller: _otp,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                  onChanged: (v) {
                    setState(() {});
                    if (v.length == 4) _verify();
                  },
                  decoration: const InputDecoration(border: InputBorder.none, filled: false),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: S.lg),
        Text('Resend in 0:42', style: figs(size: 12, color: C.inkSoft)),
        const Spacer(),
        TagButton(label: 'Verify', loading: _loading, onTap: _otp.text.length == 4 ? _verify : null),
        const SizedBox(height: S.lg),
      ],
    );
  }
}

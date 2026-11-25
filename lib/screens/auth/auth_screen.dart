import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/seed.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import '../shared/router.dart';

/// Screen 3: "S'inscrire" / "Se connecter" toggle with name, phone, optional e-mail and password.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.startOnLogin = false});
  final bool startOnLogin;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _login = widget.startOnLogin;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _hide = true, _busy = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _id, _pw]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final s = context.read<AppState>();
    try {
      if (_login) {
        await s.login(_id.text, _pw.text);
      } else {
        await s.register(name: _name.text, phone: _phone.text, email: _email.text, password: _pw.text);
      }
      if (mounted) goHome(context);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillDemo(String phone) => setState(() {
    _login = true;
    _id.text = phoneFmt(phone);
    _pw.text = demoPassword;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.card,
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(S.gutter, S.lg, S.gutter, S.xl),
            children: [
              const Align(alignment: Alignment.centerLeft, child: Wordmark(size: 22)),
              const SizedBox(height: S.xl),
              Text(_login ? 'Bon retour parmi nous' : 'Créez votre compte', style: title(size: 28)),
              const SizedBox(height: S.sm),
              Text(
                _login ? 'Connectez-vous avec votre numéro ou votre e-mail.' : 'Quelques informations et vous trouvez votre artisan.',
                style: body(color: C.inkSoft),
              ),
              const SizedBox(height: S.xl),
              _Segmented(login: _login, onChanged: (v) => setState(() {
                _login = v;
                _error = null;
              })),
              const SizedBox(height: S.xl),
              AnimatedSize(
                duration: M.base,
                curve: M.out,
                alignment: Alignment.topCenter,
                child: Column(
                  children: _login
                      ? [
                          _Field(controller: _id, label: 'Téléphone ou e-mail', icon: PhosphorIconsBold.user, keyboard: TextInputType.emailAddress,
                              validator: (v) => (v ?? '').trim().isEmpty ? 'Entrez votre numéro ou e-mail.' : null),
                        ]
                      : [
                          _Field(controller: _name, label: 'Nom complet', icon: PhosphorIconsBold.user, caps: TextCapitalization.words,
                              validator: (v) => (v ?? '').trim().length < 3 ? 'Entrez votre nom complet.' : null),
                          _Field(controller: _phone, label: 'Téléphone', hint: '0550 12 34 56', icon: PhosphorIconsBold.phone, keyboard: TextInputType.phone,
                              formatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
                              validator: (v) => RegExp(r'^0[5-7][0-9]{8}$').hasMatch((v ?? '').replaceAll(RegExp(r'[^0-9]'), '').replaceFirst(RegExp(r'^213'), '0'))
                                  ? null
                                  : 'Numéro mobile algérien : 05, 06 ou 07 + 8 chiffres.'),
                          _Field(controller: _email, label: 'E-mail (facultatif)', icon: PhosphorIconsBold.envelope, keyboard: TextInputType.emailAddress),
                        ],
                ),
              ),
              _Field(
                controller: _pw,
                label: 'Mot de passe',
                icon: PhosphorIconsBold.lock,
                obscure: _hide,
                suffix: IconButton(
                  tooltip: _hide ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                  icon: Icon(_hide ? PhosphorIconsBold.eye : PhosphorIconsBold.eyeSlash, size: 20, color: C.inkSoft),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
                validator: (v) => (v ?? '').length < 6 ? 'Au moins 6 caractères.' : null,
                onSubmit: _submit,
              ),
              if (_error != null)
                Container(
                  margin: const EdgeInsets.only(bottom: S.md),
                  padding: const EdgeInsets.all(S.md),
                  decoration: BoxDecoration(color: C.redWash, borderRadius: BorderRadius.circular(R.sm)),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsBold.warning, color: C.red, size: 18),
                      const SizedBox(width: S.sm),
                      Expanded(child: Text(_error!, style: body(size: 14, color: C.red, weight: FontWeight.w600))),
                    ],
                  ),
                ),
              const SizedBox(height: S.sm),
              Btn(_login ? 'Se connecter' : "S'inscrire", loading: _busy, onTap: _submit),
              const SizedBox(height: S.xl),
              _DemoCard(onClient: () => _fillDemo(demoClientPhone), onProvider: () => _fillDemo(demoProviderPhone)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.login, required this.onChanged});
  final bool login;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    height: 50,
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.md)),
    child: Stack(
      children: [
        AnimatedAlign(
          duration: M.base,
          curve: M.out,
          alignment: login ? Alignment.centerRight : Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: .5,
            heightFactor: 1,
            child: Container(decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(12), boxShadow: lift)),
          ),
        ),
        Row(
          children: [
            for (final (v, label) in [(false, "S'inscrire"), (true, 'Se connecter')])
              Expanded(
                child: Pressable(
                  onTap: () => onChanged(v),
                  semanticLabel: label,
                  child: Center(child: Text(label, style: body(size: 14.5, weight: FontWeight.w700, color: login == v ? C.ink : C.inkSoft))),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.keyboard,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.formatters,
    this.caps = TextCapitalization.none,
    this.onSubmit,
  });
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? formatters;
  final TextCapitalization caps;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: S.md),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      validator: validator,
      inputFormatters: formatters,
      textCapitalization: caps,
      autocorrect: false,
      onFieldSubmitted: onSubmit == null ? null : (_) => onSubmit!(),
      style: body(weight: FontWeight.w500),
      decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20), suffixIcon: suffix),
    ),
  );
}

/// Shortcut for the demo: fills in a seeded account.
class _DemoCard extends StatelessWidget {
  const _DemoCard({required this.onClient, required this.onProvider});
  final VoidCallback onClient, onProvider;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(S.lg),
    decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.line)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsBold.info, size: 18, color: C.inkSoft),
            const SizedBox(width: S.sm),
            Text('Comptes de démonstration', style: body(size: 14, weight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 4),
        Text('Mot de passe : $demoPassword', style: body(size: 13.5, color: C.inkSoft)),
        const SizedBox(height: S.md),
        Row(
          children: [
            Expanded(child: Btn.outline('Client', compact: true, icon: PhosphorIconsBold.user, onTap: onClient)),
            const SizedBox(width: S.sm),
            Expanded(child: Btn.outline('Prestataire', compact: true, icon: PhosphorIconsBold.wrench, onTap: onProvider)),
          ],
        ),
      ],
    ),
  );
}

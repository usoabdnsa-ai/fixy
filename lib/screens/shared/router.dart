import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../auth/account_type.dart';
import '../auth/auth_screen.dart';
import '../client/client_shell.dart';
import '../provider/provider_form.dart';
import '../provider/provider_shell.dart';
import 'onboarding.dart';

/// Where a user belongs right now, given what they have completed.
Widget homeFor(AppState s) {
  final u = s.user;
  if (!s.onboarded) return const OnboardingScreen();
  if (u == null) return const AuthScreen();
  if (u.role == null) return const AccountTypeScreen();
  if (u.role == Role.client) return const ClientShell();
  if (s.myProvider == null) return const ProviderFormScreen.register();
  return const ProviderShell();
}

/// Replace the whole stack with the right home (after login, logout, sign-up steps).
void goHome(BuildContext context) {
  final s = context.read<AppState>();
  Navigator.of(context).pushAndRemoveUntil(fadeRoute(homeFor(s)), (_) => false);
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
  transitionDuration: const Duration(milliseconds: 380),
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, a, _, child) => FadeTransition(
    opacity: CurvedAnimation(parent: a, curve: Curves.easeOut),
    child: SlideTransition(
      position: Tween(begin: const Offset(0, .03), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: const Cubic(0.22, 1, 0.36, 1))),
      child: child,
    ),
  ),
);

Future<T?> push<T>(BuildContext context, Widget page) => Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

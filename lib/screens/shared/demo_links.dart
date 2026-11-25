import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../data/seed.dart';
import '../../services/provider_service.dart';
import '../../state/app_state.dart';
import '../admin/admin_shell.dart';
import '../auth/account_type.dart';
import '../auth/auth_screen.dart';
import '../client/categories.dart';
import '../client/client_shell.dart';
import '../client/filters.dart';
import '../client/provider_profile.dart';
import '../client/request_confirmation.dart';
import '../client/request_form.dart';
import '../client/results.dart';
import '../client/review_form.dart';
import '../provider/provider_form.dart';
import '../provider/provider_shell.dart';
import '../shared/provider_reviews.dart';
import '../shared/request_detail.dart';
import 'onboarding.dart';
import 'router.dart';

/// Web-only shortcuts for screenshots and demos: `?go=<screen>`.
/// Client screens sign in the demo client, provider screens the demo plombier.
/// Does nothing on Android.
Future<bool> openDemoLink(BuildContext context, AppState s) async {
  if (!kIsWeb) return false;
  final go = Uri.base.queryParameters['go'];
  if (go == null) return false;
  final nav = Navigator.of(context);
  void replace(Widget w) => nav.pushAndRemoveUntil(fadeRoute(w), (_) => false);
  void over(Widget base, Widget top) {
    replace(base);
    nav.push(MaterialPageRoute(builder: (_) => top));
  }

  const adminScreens = {'admin', 'adminproviders', 'adminreviews'};
  const providerScreens = {'dashboard', 'manage', 'edit', 'proreviews', 'prosettings', 'prodetail'};
  if (go == 'onboarding') {
    replace(const OnboardingScreen());
    return true;
  }
  if (go == 'auth') {
    await s.logout();
    replace(const AuthScreen());
    return true;
  }
  await s.finishOnboarding();
  await s.login(
    adminScreens.contains(go) ? demoAdminPhone : (providerScreens.contains(go) ? demoProviderPhone : demoClientPhone),
    demoPassword,
  );

  switch (go) {
    case 'type':
      replace(const AccountTypeScreen());
    case 'register':
      replace(const ProviderFormScreen.register());
    case 'home':
      replace(const ClientShell());
    case 'categories':
      over(const ClientShell(), const CategoriesScreen());
    case 'results':
      over(const ClientShell(), const ResultsScreen(initial: ProviderQuery(category: Category.plombier, wilaya: 'Alger')));
    case 'filters':
      over(const ClientShell(), const FiltersScreen(initial: ProviderQuery(category: Category.plombier, wilaya: 'Alger', minRating: 4.5)));
    case 'profile':
      over(const ClientShell(), const ProviderProfileScreen(providerId: 'p01'));
    case 'request':
      over(const ClientShell(), RequestFormScreen(provider: s.providers.byId('p01')!));
    case 'confirm':
      over(const ClientShell(), const RequestConfirmationScreen(requestId: 'r_demo2'));
    case 'requests':
      replace(const ClientShell(initial: 1));
    case 'favorites':
      if (s.favoriteProviders.isEmpty) {
        await s.toggleFavorite('p01');
        await s.toggleFavorite('p03');
      }
      replace(const ClientShell(initial: 2));
    case 'review':
      over(const ClientShell(initial: 1), const ReviewFormScreen(requestId: 'r_demo1'));
    case 'detail':
      over(const ClientShell(initial: 1), const RequestDetailScreen(requestId: 'r_demo2'));
    case 'settings':
      replace(const ClientShell(initial: 3));
    case 'reviews':
      over(const ClientShell(), const ProviderReviewsScreen(providerId: 'p01'));
    case 'dashboard':
      replace(const ProviderShell());
    case 'manage':
      replace(const ProviderShell(initial: 1));
    case 'proreviews':
      replace(const ProviderShell(initial: 2));
    case 'prosettings':
      replace(const ProviderShell(initial: 3));
    case 'edit':
      over(const ProviderShell(), const ProviderFormScreen.edit());
    case 'prodetail':
      over(const ProviderShell(initial: 1), const RequestDetailScreen(requestId: 'r_demo3'));
    case 'admin':
      replace(const AdminShell());
    case 'adminproviders':
      replace(const AdminShell(initial: 1));
    case 'adminreviews':
      replace(const AdminShell(initial: 2));
    default:
      return false;
  }
  return true;
}

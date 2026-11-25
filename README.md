# Fixy · MVP

**Vos artisans de confiance en Algérie.** An Android app (Flutter) that connects households with local home-service professionals: find an artisan, compare ratings and indicative prices in DA, call them directly or send a service request, and rate the service once it's done.

This is the **MVP release**. It implements the 20 screens and the 3 core rules of the specification (`Fixy_Specification.pdf`, 24 Oct 2026):

- **Rule A, no in-app chat.** Every provider card and profile shows the phone number and an **Appeler** button that opens the phone's dialer.
- **Rule B, provider photos.** Providers add or change their photo from the camera or gallery. Without a photo, a default silhouette is shown.
- **Rule C, simple requests.** Service, description, address, date/time, optional photo. No checkout.

## Run it

1. Install Flutter (stable): https://docs.flutter.dev/get-started/install
2. In this folder:

```bash
flutter pub get
flutter run            # on a plugged-in Android phone (USB debugging on) or an emulator
flutter build apk      # builds build/app/outputs/flutter-apk/app-release.apk to install on any Android phone
```

`flutter run -d chrome` also works for a quick look. On a wide screen the app is framed at phone width. Calling and the camera need a real phone.

## Demo accounts

All passwords: **`fixy1234`**. The login screen has two buttons that fill these in.

| Role | Phone | Who |
|---|---|---|
| Client | 0550 11 22 33 | Amine Haddad (Bab Ezzouar) |
| Prestataire | 0661 23 45 01 | Karim Benali, plombier |
| Prestataire | any provider's number shown in the app | the other 13 providers |

**A full loop on one phone:** log in as the client and send Karim a request. Log out, log in as Karim, accept it and mark it done. Log back in as the client and rate him. His rating updates.

You can also create your own accounts. Everything is saved on the phone and survives closing the app.

## The 20 screens

| # | Screen | File |
|---|---|---|
| 1 | Splash | `screens/shared/splash.dart` |
| 2 | Onboarding (3 slides) | `screens/shared/onboarding.dart` |
| 3 | S'inscrire / Se connecter | `screens/auth/auth_screen.dart` |
| 4 | Client or Prestataire | `screens/auth/account_type.dart` |
| 5 | Client home | `screens/client/home.dart` |
| 6 | Categories | `screens/client/categories.dart` |
| 7 | Search results | `screens/client/results.dart` |
| 8 | Filters | `screens/client/filters.dart` |
| 9 | Provider profile | `screens/client/provider_profile.dart` |
| 10 | Request a service | `screens/client/request_form.dart` |
| 11 | Confirmation | `screens/client/request_confirmation.dart` |
| 12 | My requests | `screens/client/my_requests.dart` (+ `shared/request_detail.dart`) |
| 13 | Favorites | `screens/client/favorites.dart` |
| 14 | Rate a service | `screens/client/review_form.dart` |
| 15 | Provider registration | `screens/provider/provider_form.dart` (register) |
| 16 | Provider dashboard | `screens/provider/dashboard.dart` |
| 17 | Manage requests | `screens/provider/manage_requests.dart` |
| 18 | Edit provider profile | `screens/provider/provider_form.dart` (edit) |
| 19 | Provider reviews | `screens/shared/provider_reviews.dart` |
| 20 | Profile & settings | `screens/shared/settings.dart` |

## Architecture

```
lib/
  data/       models (Provider, ServiceRequest, Review, AppUser), seed data, LocalStore
  services/   AuthService, ProviderService, RequestService, ReviewService, FavoriteService
              each one = an abstract interface + a Local* implementation
  state/      AppState (ChangeNotifier): the only thing screens talk to
  screens/    auth · client · provider · shared
  widgets/    design kit (buttons, cards, avatar, stars, status pill…), bottom navigation
  theme/      tokens (navy #0D1B2A, turquoise #00C49A, white; Inter; 16 px radius) + ThemeData
  util/       French formatting (DA, dates), native features (dialer, photo picker)
```

The layers go **screens → AppState → services → LocalStore**. Only `LocalStore` touches device storage (`shared_preferences`, JSON). Phase 5 of the plan ("connect the service layer to a database") replaces the `Local*` services with database-backed ones that implement the same interfaces. The screens don't change.

**Request life cycle** (`services/request_service.dart`): *En attente → Acceptée → Terminée*, or *Annulée* (cancelled by the client, or refused by the provider). Terminée and Annulée are final. A review is only possible once, by the client, after Terminée.

**Security note:** passwords are stored as SHA-256 hashes, never in clear. Real authentication (server-side, salted slow hash) comes with the backend.

## Tests

```bash
flutter test
```

15 tests cover accounts, all request status transitions (including forbidden ones), one-review-per-request, search filters and sorting, favourites, validation, and data surviving a restart.

## Out of scope (per the specification)

In-app chat, online payment and live GPS tracking are excluded by design. iOS and desktop are not targeted.

## Credits

Fonts: Inter and Inter Display (SIL OFL). Onboarding photos: CC0 / public domain (see `assets/CREDITS.txt`). Icons: Phosphor.

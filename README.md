# Fixy (front-end prototype)

Flutter prototype of Fixy, an on-demand repair marketplace for Algeria. It covers three roles: client, craftsman (m'lem) and admin.
All data is local and fake (`lib/data/mock.dart`). There is no backend. "Network" calls are short delays so the loading states can be seen.

## Run

```bash
export PATH=$HOME/.local/pkgs/root/usr/bin:$HOME/flutter/bin:$PATH   # unzip + flutter
flutter pub get
flutter run -d web-server --web-port 3200     # then open http://localhost:3200
# or a phone/emulator once the Android SDK is installed:
flutter run
```

On a wide screen the app is framed at phone width.

## Demo shortcuts (web)

Add `?go=<screen>` to open a screen straight after the splash.

| Client | Craftsman | Admin |
|---|---|---|
| `client` home, `explore` map/list, `profile`, `post`, `jobs`, `quotes`, `tracking`, `chat`, `rate`, `account` | `pro` dashboard (a live job alert arrives after 6 s), `board`, `projobs`, `proprofile` | `admin` metrics, `verify`, `flags`, `team` (RBAC table) |

When signing in normally, any Algerian mobile number (05/06/07…) and any 4-digit code work.

## Structure

```
lib/
  theme/      tokens (colors, spacing, motion) + ThemeData
  data/       models + mock data (Alger communes, DZD prices)
  state/      AppState (ChangeNotifier): jobs, quotes, chat, ratings, verification, flags
  widgets/    kit (Pressable, TagButton, VerifiedStamp, Avatar…), bottom-tab shell, icon table
  screens/    shared (splash, onboarding, auth) · client · craftsman · admin
```

## Notes

- The rule "one rating per completed job" lives in `AppState.rate()` and is covered by `test/widget_test.dart`.
- `lib/widgets/icons.dart` is generated from phosphor_flutter's font tables. On Flutter 3.47 that package's Dart code doesn't compile, because `IconData` is now `final`.
- `google_fonts` is pinned to 8.1.0. Version 9 targets the new `material_ui` package and its types clash with `flutter/material`.
- The map uses OpenStreetMap tiles with a paper tint. Photos are CC0 / public domain from Openverse (`assets/CREDITS.txt`).

# Fixy architecture

Fixy is an on-demand home repair marketplace for Algeria. Clients post a job,
vetted craftsmen (m'lems) quote or accept it, and Fixy tracks the job to the
review. This repo is a front-end-only Flutter prototype: all data is mock data
held in memory, and every "network" call is a short `Future.delayed`, so the
loading states are real.

## Stack

| Concern | Choice | Why |
|---|---|---|
| UI | Flutter 3.x, Material 3 widgets restyled | One codebase for Android, iOS and the web demo |
| State | `provider` + one `ChangeNotifier` (`AppState`) | Small app, one store, no codegen. Riverpod is the upgrade path (see below) |
| Maps | `flutter_map` + OSM tiles, tinted per theme | No API key needed for a student project |
| Motion | `flutter_animate`, implicit animations, haptics via `HapticFeedback` | Every animation checks `reduceMotion(context)` |
| Look | v3 "Trust blue": see `.tastemaker/style-lock.md` | Light default, dark toggle |
| Type | Plus Jakarta Sans, bundled; tabular figures for prices and times | Friendly and legible, works offline |
| Icons | Phosphor fonts via a generated const table (`lib/widgets/icons.dart`) | `phosphor_flutter`'s Dart code breaks on Flutter 3.47 |

## Folder layout

```
lib/
  main.dart                 app root, day/night switch, phone frame on desktop
  data/
    models.dart             all types (schema below)
    mock.dart               seed data + pure helpers (pricing, routes, ETA, AI mock)
  state/app_state.dart      the single store: actions + timers
  theme/                    tokens (C, S, R, M) and ThemeData
  widgets/
    kit.dart                buttons, cards, chips, avatar, toast, skeleton
    brand.dart              Trust blue pieces: FixyMark logo, TabPage, Headline, wipeRoute, ThemeSwitch, mapTint
    shell.dart              bottom-tab shell shared by the 3 roles
  screens/
    shared/                 splash, onboarding, auth, track (live map), mode_switch, demo_links
    client/                 home, explore, jobs, job_detail, post_request, chat, rate, account
    craftsman/              pro_home, pro_board, pro_jobs, earnings, pro_profile
    admin/                  metrics, verify, flags
```

## State

`AppState` is the only source of truth. Screens read it with
`context.watch<AppState>()` and call its methods; nothing else mutates models.

- **Client**: `postRequest`, `acceptQuote`, `cancelJob`, `sendMessage`, `rate`, `setAddress`, `analyzePhoto`
- **Live trips**: one `Timer.periodic(1s)` advances every `Job.trip` whose job is accepted. `skipAhead` is a demo shortcut. `startNavigation` creates the m'lem-side trip.
- **M'lem**: `setOnline`, `setRadius`, incoming-job alert timer, `acceptBoardJob`, `declineBoardJob`, `advance` (accepted → in progress → completed, which also writes a wallet payout), `cashOut`, `balance`
- **Account**: `signIn`, `signOut`, `switchMode` (same account, client ⇄ pro)
- **Admin**: `decide` (verification), `resolveFlag`

Pure logic lives in `mock.dart` and has no state: `estimateFor`, `diagnose`,
`routeBetween`, `pointAlong`, `etaMins`, `slotsAhead`. Moving to a backend means
replacing these with API calls and keeping the method names on `AppState`.

**Riverpod path**: split `AppState` into `clientJobsProvider`,
`proJobsProvider`, `tripProvider(jobId)` (a `StreamProvider` fed by the
backend's location socket) and `walletProvider`. The screens already depend
on narrow slices of state, so the change is mostly mechanical.

## Navigation

- `SplashScreen` → onboarding → `AuthScreen` (role picked at sign-in) → role shell.
- Each role has a `Shell` with bottom tabs (`ClientShell`, `ProShell`, `AdminShell`). Detail screens are pushed on top with `wipeRoute` (slide in from the right; full-screen dialogs rise from below; a fade under reduced motion).
- `ModeSwitch` replaces the whole stack with the other shell.
- Web deep links (`?go=`) for demos and screenshots: `client`, `explore`, `jobs`, `account`, `post`, `signup`, `quotes`, `tracking`, `live`, `chat`, `rate`, `profile`, `pro`, `board`, `projobs`, `navigate`, `wallet`, `proprofile`, `admin`, `verify`, `flags`, `team`. Light mode is the default; add `&theme=dark` for dark mode.

## Data schema

```dart
enum Role { client, craftsman, admin }
enum Trade { plumbing, electrical, hvac, mechanic, carpentry, painting }   // label, local, icon
enum Urgency { now, today, week }
enum JobStatus { pending, quoted, accepted, inProgress, completed, cancelled }

class Craftsman {            // the "Technician"
  String id, name, commune, wilaya, bio;
  Trade trade; LatLng location;
  int years, hourly, callout, jobsDone, responseMins;   // money in DZD
  bool verified, available;
  List<String> photos, skills, wilayas, certificates;
  List<Review> reviews;      // rating = mean of unflagged reviews
}

class Job {                  // the "Booking"
  String id, title, description, commune, clientName;
  Trade trade; Urgency urgency; JobStatus status; LatLng location;
  List<String> photos; List<Quote> quotes; List<Message> messages;
  Craftsman? craftsman; int? price;          // price = accepted quote, locked
  Slot? slot;                // null = instant
  PriceEstimate? estimate;   // shown before posting
  Diagnosis? diagnosis;      // mock AI read of the first photo
  Trip? trip;                // live route while the m'lem drives over
  bool rated;
}

class Quote { Craftsman craftsman; int amount; String eta; String note; }
class Message { bool fromMe, system; String text, time; }
class Review { String author, text; int punctuality, pricing, quality, daysAgo; bool flagged; }

class Address { String label, line, commune; LatLng location; }
class Slot { DateTime day; int start, end; bool taken; }
class Diagnosis { String issue, parts, title; double confidence; int minutes, partsCost; }
class PriceLine { String label; int low, high; String? note; }
class PriceEstimate { List<PriceLine> lines; int low; int high; }
class Trip { List<LatLng> route; double progress; bool arrived; }
class Payout { String label; int amount; int daysAgo; String? jobId; bool cashOut; }

class VerificationRequest { Craftsman craftsman; String nin; List<String> documents; bool? decision; }
class Flag { String kind, subject, reason, reporter; Review? review; bool resolved; }
```

Services are the `Trade` enum. A backend would turn it into a table so admins
can add trades without a release.

## Pricing rule

`estimateFor(trade, instant, diagnosis)` adds:

1. Call-out: the average call-out fee of m'lems in that trade
2. Labour: average hourly rate × the AI time estimate (60 min with no photo), shown as a range up to +60 %
3. Parts: from the AI read, up to +30 %
4. Instant fee: 800 DA when the client picks Instant
5. Fixy service fee: 200 DA

Quotes land inside this range. The accepted quote is the locked price, and
the job page shows it next to the original estimate. M'lems keep 90 %:
`commissionRate = 0.10`.

## Key flows

1. **Home**: time-of-day greeting, address selector, a search-style entry into the wizard, a service grid with starting prices, free m'lems nearby, the live booking tracker (ticking ETA, route progress, chat), top pros near you, and trust signals.
2. **Booking wizard**: Trade → Problem (title, details, photos; Fixy AI reads the first photo and can fill the title) → When (Instant, or Scheduled with a day strip and 2-hour slots; taken slots are struck out) → Review (summary + upfront price breakdown) → posted (radar) → job page.
3. **Live tracking**: full map with the route still to drive in volt, the m'lem gliding between ticks, an ETA badge, a technician card (rating, jobs done, verified), the last message and one-tap replies. The job page shows a mini version.
4. **M'lem sign-up** (`craftsman/pro_signup.dart`): after the SMS code a new m'lem fills About you (name, trade, area, years) → ID card front and back (mock camera; the NIN is "read" off the card) → optional trade papers (CFPA diploma, carte d'artisan, registre de commerce) → Review + consent → Pending review. The application lands in the admin Verify queue with the photos attached (`VerificationRequest.uploaded`). Approving it there, or with the demo button, flips the pending screen to "You're verified". "I already have an account" on the phone step skips sign-up.
5. **Pro mode**: online toggle, urgent job alerts with a 60 s countdown, a job board to accept or pass, Navigate (turn-by-turn card → "I'm here · start job"), hold-to-complete, and a wallet with a balance, cash-out to CCP, the commission split and history.

## Running

Flutter is at `~/flutter/bin` (not on PATH).

```
flutter build web --no-web-resources-cdn --pwa-strategy=none
cd build/web && python3 -m http.server 8097
```

Use a fresh port after each build so the browser doesn't serve a cached app.

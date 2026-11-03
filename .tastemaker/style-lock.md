# Fixy style lock (v2 "Night shift", 2026-10-16)

User rejected Casbah blue ("tourism app") and picked Night shift. No arches, tiles or cultural decoration.
Near-black #0B0C0E, card #15171B, volt #E4FF3A (fills with dark labels), hot #FF5A36 urgent, teal #2BD9A0 verified.
Barlow Condensed uppercase display + JetBrains Mono data. Hairlines instead of cards where possible, sharp radii 3/6/8.
Building blocks in lib/widgets/night.dart: FixyMark (bolt), Wordmark, Headline (glyph scramble), VoltRule, LiveDot,
TabPage, wipeRoute (volt band wipe), Scanlines, idx(). Onboarding = viewfinder frame with volt corner brackets.
Map tiles: dark inverted tint (_nightTint).

## Day / night (added 2026-10-16)
Two palettes in lib/theme/tokens.dart (`Palette.night`, `Palette.day`); `C.*` are getters, so colors are never const.
`C.light` (ValueNotifier) flips them; main.dart marks every element dirty so cached route pages restyle too.
Day: paper #F6F6F1, ink slabs with volt labels (the volt role becomes ink), accent words get a volt marker
background (`Headline._accent`), map uses `_dayTint`. Switch: `ThemeSwitch` in client Account, m'lem profile, admin Team.
Web deep link: `?theme=light`. Painters must compare palette state in shouldRepaint.

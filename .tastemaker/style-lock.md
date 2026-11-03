# Fixy style lock (v3 "Trust blue", 2026-11-03)

User rejected Night shift as "cyberpunk, not the vibe of service providers" and picked Trust blue
(Thumbtack / TaskRabbit feel). Earlier rejected: Workshop toolbox, Casbah blue ("tourism app"), Night shift.

- Light is the default; dark is a toggle (Account > Appearance, `?theme=dark`).
- Colors (lib/theme/tokens.dart): bg #F4F6FA, cards white, ink slate #0F172A, inkSoft #475569,
  primary trust blue #1D4ED8 (token name `C.volt` kept for history), urgent orange #C2410C (`C.hot`),
  verified green #15803D (`C.teal`), rating stars amber #F59E0B (`C.star`).
- Type: Plus Jakarta Sans only (bundled). `figs()` = same face with tabular figures for prices/times.
- Sentence case everywhere. No ALL-CAPS mono labels, no scramble text, no scanlines, no wipes.
- Shapes: radii 10/16/22, pills for chips, circle avatars and icon buttons, soft shadows (`lift`, `glow`).
- Logo: blue rounded tile with a white house whose door is a check (`FixyMark` in lib/widgets/brand.dart).
- Motion: rise + fade entrances, gentle spring on press/tab pill, slide-from-right routes, sheets rise.
- Maps: OSM tinted calm (`mapTint`), blue route, round white-ringed markers.

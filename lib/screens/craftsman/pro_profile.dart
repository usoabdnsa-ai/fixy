import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../shared/mode_switch.dart';

import 'package:flutter/services.dart';

import '../../widgets/icons.dart';

import '../../data/mock.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../widgets/kit.dart';
import '../client/account.dart';
import '../client/craftsman_profile.dart';

class ProProfile extends StatefulWidget {
  const ProProfile({super.key});
  @override
  State<ProProfile> createState() => _ProProfileState();
}

class _ProProfileState extends State<ProProfile> {
  late int _hourly = me.hourly;
  late int _callout = me.callout;
  late final Set<String> _skills = {...me.skills};
  late final Set<String> _wilayas = {...me.wilayas};
  bool _flat = false;
  bool _saving = false;

  static const _allSkills = ['Leak repair', 'Chauffe-eau', 'Bathroom fit-out', 'Unblocking', 'Gas pipes', 'Water pumps', 'Kitchen sinks'];

  Future<void> _save() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _saving = false);
    toast(context, 'Profile saved');
  }

  @override
  Widget build(BuildContext context) {
    return TabPage(
      eyebrow: 'WHAT CLIENTS SEE',
      title: 'Your',
      accent: 'profile',
      trailing: TagButton.light(
        compact: true,
        expand: false,
        label: 'Preview',
        icon: PhosphorIconsBold.eye,
        onTap: () => Navigator.of(context).push(wipeRoute(CraftsmanProfileScreen(craftsman: me, readOnly: true))),
      ),
      children: [
        // Verification status
        Container(
          padding: const EdgeInsets.all(S.lg),
          decoration: BoxDecoration(
            color: C.tealWash,
            borderRadius: BorderRadius.circular(R.lg),
            border: Border.all(color: C.teal, width: 1.5),
          ),
          child: Row(
            children: [
              Avatar(craftsman: me, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(me.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                    const SizedBox(height: 6),
                    const VerifiedStamp(),
                    const SizedBox(height: 6),
                    Text('NIN checked 12 Mar 2025 · CFPA certificate', style: figs(size: 10.5, color: C.teal)),
                  ],
                ),
              ),
            ],
          ),
        ),
        _section('Rates'),
        TagCard(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text('Pricing model', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  _seg('Hourly', !_flat, () => setState(() => _flat = false)),
                  const SizedBox(width: 6),
                  _seg('Flat', _flat, () => setState(() => _flat = true)),
                ],
              ),
              Divider(height: 24, color: C.line),
              _stepper(_flat ? 'Flat rate per job' : 'Hourly rate', _hourly, (v) => setState(() => _hourly = v)),
              const SizedBox(height: 10),
              _stepper('Call-out fee', _callout, (v) => setState(() => _callout = v), step: 200, min: 0),
            ],
          ),
        ),
        _section('Skills'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final k in _allSkills) _toggleChip(k, _skills.contains(k), () => setState(() => _skills.contains(k) ? _skills.remove(k) : _skills.add(k))),
          ],
        ),
        _section('Wilayas you cover'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in wilayas) _toggleChip(w, _wilayas.contains(w), () => setState(() => _wilayas.contains(w) ? _wilayas.remove(w) : _wilayas.add(w))),
          ],
        ),
        _section('Portfolio'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            for (final p in me.photos) Photo(p, radius: R.sm),
            Pressable(
              onTap: () => toast(context, 'Photo picker (prototype)'),
              child: Container(
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(R.sm),
                  border: Border.all(color: C.lineStrong, width: 1.5),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(PhosphorIconsBold.plus),
                    SizedBox(height: 4),
                    Text('Add work', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
        _section('Certificates'),
        for (final c in me.certificates)
          TagCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(PhosphorIconsBold.certificate, color: C.teal),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(c, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Text(
                  'APPROVED',
                  style: figs(size: 10, weight: FontWeight.w700, color: C.teal),
                ),
              ],
            ),
          ),
        const SizedBox(height: S.xl),
        TagButton(label: 'Save changes', loading: _saving, onTap: _save),
        const SizedBox(height: 10),
        const ThemeSwitch(),
        const SizedBox(height: S.md),
        const ModeSwitch(to: Role.client),
        const SizedBox(height: S.md),
        TagButton.light(label: 'Sign out', icon: PhosphorIconsBold.signOut, onTap: () => signOut(context)),
      ],
    );
  }

  Widget _section(String t) => Padding(
    padding: const EdgeInsets.only(top: S.xl, bottom: 10),
    child: Text(t, style: display(size: 18)),
  );

  Widget _seg(String label, bool sel, VoidCallback onTap) => Pressable(
    onTap: onTap,
    haptic: false,
    child: AnimatedContainer(
      duration: M.fast,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(color: sel ? C.volt : C.bg, borderRadius: BorderRadius.circular(R.pill)),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: sel ? C.onFill : C.ink),
      ),
    ),
  );

  Widget _stepper(String label, int value, ValueChanged<int> onChanged, {int step = 100, int min = 500}) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        IconCircle(
          icon: PhosphorIconsBold.minus,
          label: 'Decrease $label',
          onTap: value - step < min
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onChanged(value - step);
                },
        ),
        SizedBox(
          width: 104,
          child: Center(
            child: AnimatedSwitcher(
              duration: M.fast,
              transitionBuilder: (c, a) => FadeTransition(
                opacity: a,
                child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(a), child: c),
              ),
              child: Text(
                value == 0 ? 'Free' : dzd(value),
                key: ValueKey(value),
                style: figs(size: 15, weight: FontWeight.w700),
              ),
            ),
          ),
        ),
        IconCircle(
          icon: PhosphorIconsBold.plus,
          label: 'Increase $label',
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(value + step);
          },
        ),
      ],
    );
  }

  Widget _toggleChip(String label, bool sel, VoidCallback onTap) => Pressable(
    onTap: onTap,
    haptic: false,
    child: AnimatedContainer(
      duration: M.fast,
      curve: M.out,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: sel ? C.volt : C.card,
        borderRadius: BorderRadius.circular(R.pill),
        border: Border.all(color: sel ? C.volt : C.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: M.fast,
            curve: M.out,
            child: sel
                ? Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(PhosphorIconsBold.check, size: 13, color: C.onFill),
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: sel ? C.onFill : C.ink),
          ),
        ],
      ),
    ),
  );
}

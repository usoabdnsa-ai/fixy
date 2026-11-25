import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Provider;

import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../theme/theme.dart';
import '../../theme/tokens.dart';
import '../../util/format.dart';
import '../../util/native.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';
import 'address_sheet.dart';
import 'request_confirmation.dart';

/// Screen 10: service, problem description, intervention address, date and
/// time, optional problem photo, "Confirmer la demande".
class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key, required this.provider});
  final Provider provider;
  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  static const _other = 'Autre (à préciser)';
  late String _service = widget.provider.services.isNotEmpty ? widget.provider.services.first.name : _other;
  final _desc = TextEditingController();
  final _address = TextEditingController();
  DateTime? _day;
  TimeOfDay? _time;
  String? _photo;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final a = context.read<AppState>().location;
    if (a != null) _address.text = a.full;
  }

  @override
  void dispose() {
    _desc.dispose();
    _address.dispose();
    super.dispose();
  }

  DateTime? get _when => _day == null || _time == null ? null : DateTime(_day!.year, _day!.month, _day!.day, _time!.hour, _time!.minute);

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
      helpText: 'Date d’intervention',
      cancelText: 'Annuler',
      confirmText: 'Valider',
    );
    if (d != null) setState(() => _day = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Heure souhaitée',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t != null) setState(() => _time = t);
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (_when == null) {
      setState(() => _error = 'Choisissez une date et une heure.');
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await context.read<AppState>().createRequest(
        provider: widget.provider,
        service: _service,
        description: _desc.text,
        address: _address.text,
        scheduledAt: _when!,
        photo: _photo,
      );
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => RequestConfirmationScreen(requestId: r.id)));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final s = context.watch<AppState>();
    final addresses = s.user?.addresses ?? [];
    final services = [...p.services.map((e) => e.name), _other];
    return Scaffold(
      appBar: AppBar(title: const Text('Demander un service')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(S.gutter, S.xs, S.gutter, S.xl),
        children: [
          AppCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Avatar(photo: p.photo, size: 48),
                const SizedBox(width: S.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: title(size: 16)),
                      Text('${p.category.label} · ${p.commune}', style: body(size: 13.5, color: C.inkSoft)),
                    ],
                  ),
                ),
                RatingLine(s.rating(p.id)),
              ],
            ),
          ),
          const _Label('Service'),
          DropdownButtonFormField<String>(
            initialValue: _service,
            isExpanded: true,
            borderRadius: BorderRadius.circular(R.md),
            dropdownColor: C.card,
            icon: const Icon(PhosphorIconsBold.caretDown, size: 18),
            items: [
              for (final sv in services)
                DropdownMenuItem(
                  value: sv,
                  child: Row(
                    children: [
                      Expanded(child: Text(sv, overflow: TextOverflow.ellipsis, style: body(weight: FontWeight.w500))),
                      for (final rate in p.services.where((x) => x.name == sv)) Text(da(rate.priceDa), style: figs(size: 13.5, color: C.inkSoft)),
                    ],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _service = v!),
          ),
          const _Label('Décrivez le problème'),
          TextField(
            controller: _desc,
            minLines: 3,
            maxLines: 6,
            maxLength: 500,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Ex. : fuite sous l’évier de la cuisine depuis ce matin…'),
          ),
          const _Label('Adresse d’intervention'),
          if (addresses.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in addresses)
                  ChoicePill(a.label, icon: PhosphorIconsBold.mapPin, selected: _address.text == a.full, onTap: () => setState(() => _address.text = a.full)),
                ChoicePill('Nouvelle', icon: PhosphorIconsBold.plus, selected: false, onTap: () async {
                  final a = await showAddressEditor(context);
                  if (a == null || !context.mounted) return;
                  final u = s.user!;
                  u.addresses = [...u.addresses, a];
                  await attempt(context, () => s.updateUser(u));
                  setState(() => _address.text = a.full);
                }),
              ],
            ),
            const SizedBox(height: S.sm),
          ],
          TextField(
            controller: _address,
            minLines: 1,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Rue, bâtiment, commune', prefixIcon: Icon(PhosphorIconsBold.mapPin, size: 20)),
          ),
          const _Label('Date et heure souhaitées'),
          Row(
            children: [
              Expanded(child: _PickerBox(icon: PhosphorIconsBold.calendarBlank, text: _day == null ? 'Date' : dayLabel(_day!), set: _day != null, onTap: _pickDay)),
              const SizedBox(width: S.sm),
              Expanded(child: _PickerBox(icon: PhosphorIconsBold.clock, text: _time == null ? 'Heure' : _time!.format24, set: _time != null, onTap: _pickTime)),
            ],
          ),
          const _Label('Photo du problème (facultatif)'),
          _PhotoBox(
            photo: _photo,
            onTap: () async {
              final ph = await pickPhoto(context, title: 'Photo du problème', allowRemove: _photo != null);
              if (ph != null) setState(() => _photo = ph.isEmpty ? null : ph);
            },
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: S.lg),
              child: Row(
                children: [
                  const Icon(PhosphorIconsBold.warning, size: 18, color: C.red),
                  const SizedBox(width: S.sm),
                  Expanded(child: Text(_error!, style: body(size: 14, color: C.red, weight: FontWeight.w600))),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(S.gutter, S.md, S.gutter, S.md),
          decoration: const BoxDecoration(color: C.card, border: Border(top: BorderSide(color: C.line))),
          child: Btn('Confirmer la demande', loading: _busy, onTap: _submit),
        ),
      ),
    );
  }
}

extension on TimeOfDay {
  String get format24 => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: S.xl, bottom: S.sm),
    child: Text(text, style: body(size: 14.5, weight: FontWeight.w700)),
  );
}

class _PickerBox extends StatelessWidget {
  const _PickerBox({required this.icon, required this.text, required this.set, required this.onTap});
  final IconData icon;
  final String text;
  final bool set;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: text,
    child: Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: set ? C.turq : C.line, width: set ? 1.5 : 1)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: set ? C.turqText : C.inkSoft),
          const SizedBox(width: S.sm),
          Expanded(child: Text(text, overflow: TextOverflow.ellipsis, style: body(weight: set ? FontWeight.w700 : FontWeight.w500, color: set ? C.ink : C.inkFaint))),
        ],
      ),
    ),
  );
}

class _PhotoBox extends StatelessWidget {
  const _PhotoBox({required this.photo, required this.onTap});
  final String? photo;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    semanticLabel: photo == null ? 'Ajouter une photo' : 'Changer la photo',
    child: Container(
      height: photo == null ? 96 : 180,
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(R.md), border: Border.all(color: C.lineStrong)),
      clipBehavior: Clip.antiAlias,
      child: photo == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsBold.camera, size: 26, color: C.inkSoft),
                const SizedBox(height: 6),
                Text('Ajouter une photo', style: body(size: 14, weight: FontWeight.w600, color: C.inkSoft)),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                StoredImage(photo!),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: C.navy.withValues(alpha: .8), borderRadius: BorderRadius.circular(R.pill)),
                    child: Text('Changer', style: body(size: 12.5, color: C.white, weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
    ),
  );
}

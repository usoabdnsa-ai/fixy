import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/theme.dart';
import '../theme/tokens.dart';
import '../widgets/icons.dart';
import '../widgets/kit.dart';
import 'format.dart';

/// "Appeler": opens the phone's native dialer with the number filled in (spec Rule A).
/// Nothing is dialled until the user presses call in the dialer.
Future<void> callPhone(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'\s'), ''));
  final ok = await canLaunchUrl(uri) && await launchUrl(uri);
  if (!ok && context.mounted) {
    toast(context, "Impossible d'ouvrir le téléphone. Composez le ${phoneFmt(phone)}.");
  }
}

/// Camera or gallery (spec Rule B). Returns the photo as base64 JPEG, resized
/// so it stays small, or null if the user cancelled.
Future<String?> pickPhoto(BuildContext context, {String title = 'Ajouter une photo', bool allowRemove = false}) async {
  final source = await showModalBottomSheet<Object>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(S.gutter, 0, S.gutter, S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: title_(18)),
            const SizedBox(height: S.md),
            _SourceTile(icon: PhosphorIconsBold.camera, label: 'Appareil photo', onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            _SourceTile(icon: PhosphorIconsBold.images, label: 'Galerie', onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            if (allowRemove) _SourceTile(icon: PhosphorIconsBold.trash, label: 'Supprimer la photo', danger: true, onTap: () => Navigator.pop(ctx, 'remove')),
          ],
        ),
      ),
    ),
  );
  if (source == null) return null;
  if (source == 'remove') return '';
  try {
    final file = await ImagePicker().pickImage(source: source as ImageSource, maxWidth: 900, maxHeight: 900, imageQuality: 72);
    if (file == null) return null;
    return base64Encode(await file.readAsBytes());
  } catch (_) {
    if (context.mounted) toast(context, source == ImageSource.camera ? "L'appareil photo n'est pas disponible." : 'Impossible de lire cette image.');
    return null;
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.icon, required this.label, required this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: S.md),
      child: Row(
        children: [
          IconTile(icon: icon, color: danger ? C.red : C.navy, wash: danger ? C.redWash : C.turqWash),
          const SizedBox(width: S.md),
          Text(label, style: body(weight: FontWeight.w600, color: danger ? C.red : C.ink)),
        ],
      ),
    ),
  );
}

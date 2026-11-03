import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/tokens.dart';
import '../../widgets/icons.dart';
import '../../widgets/kit.dart';

/// Stand-in for a photo of an Algerian biometric ID card. The prototype
/// has no camera, so "uploading" produces this drawn card instead.
class IdCardPreview extends StatelessWidget {
  const IdCardPreview({super.key, required this.name, required this.nin, this.back = false, this.width = 280});
  final String name;
  final String nin;
  final bool back;
  final double width;

  @override
  Widget build(BuildContext context) {
    final h = width * .63;
    final t = width / 280; // scale text with the card
    TextStyle st(double size, {FontWeight w = FontWeight.w600, Color? c}) =>
        GoogleFonts.plusJakartaSans(fontSize: size * t, fontWeight: w, color: c ?? const Color(0xFF1F2937), height: 1.2);
    return Container(
      width: width,
      height: h,
      padding: EdgeInsets.all(12 * t),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12 * t),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE6F4EA), Color(0xFFD9ECF7), Color(0xFFF3E9D8)]),
        boxShadow: const [BoxShadow(color: Color(0x290F172A), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: back
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34 * t,
                      height: 26 * t,
                      decoration: BoxDecoration(color: const Color(0xFFCBA135), borderRadius: BorderRadius.circular(4 * t)),
                    ),
                    const Spacer(),
                    Text('NIN $nin', style: st(9, w: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                for (final l in ['IDDZA$nin<<<<<<<<', '9001017M3401017DZA<<<<<<<<<<<', '${name.toUpperCase().replaceAll(' ', '<<')}<<<<<<<<<'])
                  Text(
                    l,
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: GoogleFonts.jetBrainsMono(fontSize: 9.5 * t, color: const Color(0xFF1F2937), letterSpacing: .5),
                  ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الجمهورية الجزائرية الديمقراطية الشعبية', style: st(8, w: FontWeight.w700)),
                Text(
                  "CARTE NATIONALE D'IDENTITÉ",
                  style: st(8.5, w: FontWeight.w800, c: const Color(0xFF0F5132)),
                ),
                SizedBox(height: 8 * t),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 62 * t,
                        decoration: BoxDecoration(color: const Color(0xFFB8C4CF), borderRadius: BorderRadius.circular(6 * t)),
                        child: Icon(PhosphorIconsFill.user, size: 40 * t, color: const Color(0xFF7B8794)),
                      ),
                      SizedBox(width: 10 * t),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Nom / Prénom', style: st(7.5, c: const Color(0xFF6B7280))),
                            Text(name, maxLines: 2, style: st(11, w: FontWeight.w800)),
                            SizedBox(height: 6 * t),
                            Text('NIN', style: st(7.5, c: const Color(0xFF6B7280))),
                            Text(nin, style: st(9.5, w: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// Thumbnail for an uploaded certificate photo.
class DocThumb extends StatelessWidget {
  const DocThumb({super.key, required this.label, this.size = 56});
  final String label;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.2,
      padding: EdgeInsets.all(size * .12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5DCC3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(PhosphorIconsBold.certificate, size: size * .3, color: const Color(0xFFB45309)),
          const Spacer(),
          for (var i = 0; i < 3; i++)
            Container(margin: const EdgeInsets.only(top: 3), height: 2.5, width: size * (i == 2 ? .4 : .7), color: const Color(0xFFD6CDB5)),
        ],
      ),
    );
  }
}

/// Full-screen look at an uploaded document (admin and the m'lem's review step).
void showDocument(BuildContext context, Widget doc, String title) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: C.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(R.lg)),
      child: Padding(
        padding: const EdgeInsets.all(S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.ink),
            ),
            const SizedBox(height: S.lg),
            FittedBox(child: doc),
            const SizedBox(height: S.lg),
            TagButton.light(compact: true, label: 'Close', onTap: () => Navigator.pop(ctx)),
          ],
        ),
      ),
    ),
  );
}

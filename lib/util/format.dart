/// French formatting without extra packages.
const _months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
const _monthsLong = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
const _days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _daysLong = ['lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'];

/// 12500 → "12 500 DA" (narrow no-break space as thousands separator).
String da(int amount) {
  final s = amount.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
    b.write(s[i]);
  }
  return '${amount < 0 ? '-' : ''}$b DA';
}

String hhmm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Aujourd'hui", "Demain", "Hier", or "mar. 3 déc.".
String dayLabel(DateTime d, {DateTime? now}) {
  final n = now ?? DateTime.now();
  if (_sameDay(d, n)) return "Aujourd'hui";
  if (_sameDay(d, n.add(const Duration(days: 1)))) return 'Demain';
  if (_sameDay(d, n.subtract(const Duration(days: 1)))) return 'Hier';
  final y = d.year != n.year ? ' ${d.year}' : '';
  return '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}$y';
}

/// "Demain à 09:00", "mar. 3 déc. à 14:30".
String when(DateTime d) => '${dayLabel(d)} à ${hhmm(d)}';

/// "mardi 3 décembre 2026".
String longDate(DateTime d) => '${_daysLong[d.weekday - 1]} ${d.day} ${_monthsLong[d.month - 1]} ${d.year}';

/// "il y a 3 h", "il y a 2 j", "le 12 oct.".
String ago(DateTime d, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(d);
  if (diff.inMinutes < 1) return "à l'instant";
  if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
  if (diff.inDays < 30) return 'il y a ${diff.inDays} j';
  return 'le ${d.day} ${_months[d.month - 1]}${d.year != DateTime.now().year ? ' ${d.year}' : ''}';
}

/// "0550123456" → "0550 12 34 56".
String phoneFmt(String p) {
  final d = p.replaceAll(RegExp(r'\D'), '');
  if (d.length != 10) return p;
  return '${d.substring(0, 4)} ${d.substring(4, 6)} ${d.substring(6, 8)} ${d.substring(8)}';
}

String plural(int n, String one, [String? many]) => '$n ${n > 1 ? (many ?? '${one}s') : one}';

String rating1(double r) => r.toStringAsFixed(1).replaceAll('.', ',');

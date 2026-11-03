import 'package:latlong2/latlong.dart';

import 'models.dart';

/// All data is local and fake. No backend.
const clientHome = LatLng(36.7300, 3.0800); // Kouba, Alger
const clientName = 'Amina Belkacem';
const clientCommune = 'Kouba';

const wilayas = ['Alger', 'Blida', 'Boumerdès', 'Tipaza', 'Oran', 'Constantine', 'Sétif', 'Tizi Ouzou'];

List<Review> _r(List<List<Object>> rows) => [
  for (final row in rows)
    Review(
      author: row[0] as String,
      punctuality: row[1] as int,
      pricing: row[2] as int,
      quality: row[3] as int,
      text: row[4] as String,
      daysAgo: row[5] as int,
    ),
];

final craftsmen = <Craftsman>[
  Craftsman(
    id: 'c1',
    name: 'Karim Boudiaf',
    trade: Trade.plumbing,
    commune: 'Hussein Dey',
    wilaya: 'Alger',
    location: const LatLng(36.7397, 3.0950),
    years: 14,
    hourly: 1500,
    callout: 1000,
    verified: true,
    available: true,
    jobsDone: 312,
    responseMins: 8,
    bio: 'Water heaters, leaks, full bathroom piping. I carry common spare parts in the van so most jobs finish in one visit.',
    photos: ['plumb-1', 'plumb-2', 'tools-1'],
    skills: ['Leak repair', 'Chauffe-eau', 'Bathroom fit-out', 'Unblocking'],
    wilayas: ['Alger', 'Boumerdès'],
    certificates: ['CFPA Plomberie sanitaire, 2011'],
    reviews: _r([
      ['Samir H.', 5, 4, 5, 'Came 20 minutes after I called. Fixed the chauffe-eau and showed me what was wrong.', 3],
      ['Nadia K.', 5, 5, 5, 'Clean work, fair price, left the kitchen tidy.', 12],
      ['Yacine M.', 4, 4, 5, 'A bit late but the repair is solid.', 30],
    ]),
  ),
  Craftsman(
    id: 'c2',
    name: 'Nadir Khelifi',
    trade: Trade.electrical,
    commune: 'Kouba',
    wilaya: 'Alger',
    location: const LatLng(36.7262, 3.0870),
    years: 9,
    hourly: 1800,
    callout: 1200,
    verified: true,
    available: true,
    jobsDone: 188,
    responseMins: 12,
    bio: 'Tableau électrique, disjoncteur trips, new circuits. Licensed, works to NF C 15-100.',
    photos: ['elec-1', 'tools-1'],
    skills: ['Breaker panels', 'Rewiring', 'Lighting', 'Intercom'],
    wilayas: ['Alger', 'Blida'],
    certificates: ['BTS Électrotechnique, 2015', 'Habilitation électrique B2V'],
    reviews: _r([
      ['Lamia D.', 5, 4, 5, 'Found the fault in the panel in 10 minutes.', 5],
      ['Omar B.', 4, 5, 4, 'Honest quote before starting.', 21],
    ]),
  ),
  Craftsman(
    id: 'c3',
    name: 'Rachid Ouali',
    trade: Trade.hvac,
    commune: 'Bab Ezzouar',
    wilaya: 'Alger',
    location: const LatLng(36.7167, 3.1833),
    years: 11,
    hourly: 2000,
    callout: 1500,
    verified: true,
    available: false,
    jobsDone: 241,
    responseMins: 25,
    bio: 'Split AC install, gas recharge, yearly cleaning before summer. Condor, LG, Samsung, Gree.',
    photos: ['metal-1', 'metal-2'],
    skills: ['AC install', 'Gas recharge', 'Cleaning', 'Chaudière'],
    wilayas: ['Alger'],
    reviews: _r([
      ['Farid A.', 4, 3, 5, 'Expensive in July but the AC is ice cold now.', 8],
      ['Imane S.', 5, 4, 4, 'Explained everything clearly.', 40],
    ]),
  ),
  Craftsman(
    id: 'c4',
    name: 'Sofiane Mebarki',
    trade: Trade.mechanic,
    commune: 'Bir Mourad Raïs',
    wilaya: 'Alger',
    location: const LatLng(36.7350, 3.0500),
    years: 17,
    hourly: 1700,
    callout: 1500,
    verified: true,
    available: true,
    jobsDone: 420,
    responseMins: 15,
    bio: 'Mobile mechanic: battery, starter, brakes, diagnostics at your door. Renault, Peugeot, Hyundai, Kia.',
    photos: ['mech-1', 'mech-2', 'mech-3'],
    skills: ['Diagnostics', 'Battery', 'Brakes', 'Vidange'],
    wilayas: ['Alger', 'Tipaza'],
    reviews: _r([
      ['Hakim Z.', 5, 5, 4, 'Car started again in the parking lot, saved me a tow.', 2],
      ['Meriem T.', 5, 4, 5, 'Very professional.', 15],
      ['Walid R.', 4, 4, 4, 'Good, would call again.', 60],
    ]),
  ),
  Craftsman(
    id: 'c5',
    name: 'Mourad Haddad',
    trade: Trade.carpentry,
    commune: 'El Biar',
    wilaya: 'Alger',
    location: const LatLng(36.7690, 3.0330),
    years: 22,
    hourly: 1600,
    callout: 800,
    verified: true,
    available: true,
    jobsDone: 156,
    responseMins: 40,
    bio: 'Doors, cupboards, kitchen fronts, repairs on old wooden shutters. Workshop in El Biar since 2004.',
    photos: ['wood-1', 'tools-1'],
    skills: ['Doors', 'Kitchens', 'Shutters', 'Furniture repair'],
    wilayas: ['Alger'],
    reviews: _r([
      ['Kenza L.', 4, 5, 5, 'The shutters look new.', 9],
    ]),
  ),
  Craftsman(
    id: 'c6',
    name: 'Bilal Saadi',
    trade: Trade.plumbing,
    commune: 'Bordj El Kiffan',
    wilaya: 'Alger',
    location: const LatLng(36.7489, 3.1925),
    years: 5,
    hourly: 1200,
    callout: 700,
    verified: false,
    available: true,
    jobsDone: 41,
    responseMins: 10,
    bio: 'Young plumber, fast on leaks and blocked drains. Available evenings and Fridays.',
    photos: ['plumb-2'],
    skills: ['Leak repair', 'Unblocking'],
    wilayas: ['Alger'],
    reviews: _r([
      ['Anis F.', 5, 5, 4, 'Came on a Friday evening!', 6],
    ]),
  ),
  Craftsman(
    id: 'c7',
    name: 'Youcef Amrani',
    trade: Trade.electrical,
    commune: 'Chéraga',
    wilaya: 'Alger',
    location: const LatLng(36.7667, 2.9667),
    years: 7,
    hourly: 1500,
    callout: 1000,
    verified: true,
    available: true,
    jobsDone: 97,
    responseMins: 20,
    bio: 'Home electrics and solar water heater wiring.',
    photos: ['elec-1'],
    skills: ['Rewiring', 'Solar', 'Sockets'],
    wilayas: ['Alger', 'Tipaza'],
    reviews: _r([
      ['Rania C.', 4, 4, 4, 'Good job.', 18],
    ]),
  ),
  Craftsman(
    id: 'c8',
    name: 'Hamza Benali',
    trade: Trade.painting,
    commune: 'Alger Centre',
    wilaya: 'Alger',
    location: const LatLng(36.7731, 3.0588),
    years: 10,
    hourly: 1300,
    callout: 0,
    verified: true,
    available: true,
    jobsDone: 133,
    responseMins: 30,
    bio: 'Interior painting, damp walls treatment, enduit. Free estimate on site.',
    photos: ['tools-1', 'wood-1'],
    skills: ['Interior', 'Damp treatment', 'Enduit'],
    wilayas: ['Alger', 'Blida'],
    reviews: _r([
      ['Sabrina O.', 5, 4, 5, 'Very neat, covered all the furniture.', 11],
      ['Djamel N.', 4, 5, 4, 'Good price per m².', 25],
    ]),
  ),
  Craftsman(
    id: 'c9',
    name: 'Adel Ziani',
    trade: Trade.hvac,
    commune: 'Hydra',
    wilaya: 'Alger',
    location: const LatLng(36.7400, 3.0300),
    years: 6,
    hourly: 1900,
    callout: 1200,
    verified: false,
    available: true,
    jobsDone: 58,
    responseMins: 18,
    bio: 'AC and gas boiler maintenance.',
    photos: ['metal-2'],
    skills: ['AC install', 'Chaudière'],
    wilayas: ['Alger'],
    reviews: _r([
      ['Lina M.', 4, 4, 4, 'Okay.', 14],
    ]),
  ),
];

Craftsman byId(String id) => craftsmen.firstWhere((c) => c.id == id);

/// The signed-in craftsman in "craftsman" mode.
Craftsman get me => byId('c1');

List<Job> seedClientJobs() => [
  Job(
    id: 'FX-2041',
    title: 'Water heater leaking under the tank',
    description: 'Chauffe-eau in the bathroom drips from the bottom valve, small puddle every morning.',
    trade: Trade.plumbing,
    urgency: Urgency.today,
    commune: clientCommune,
    location: clientHome,
    status: JobStatus.accepted,
    postedMinsAgo: 95,
    clientName: clientName,
    photos: ['plumb-1'],
    craftsman: byId('c1'),
    price: 3500,
    messages: [
      Message(fromMe: false, text: 'Job accepted. Karim is on the way.', time: '10:12', system: true),
      Message(fromMe: false, text: 'Salam, I can come at 11:00. Is the main valve closed?', time: '10:13'),
      Message(fromMe: true, text: 'Wa alaykum salam, yes I closed it this morning.', time: '10:15'),
      Message(fromMe: false, text: 'Perfect, I will bring a new valve just in case. 3500 DA all included.', time: '10:16'),
    ],
  ),
  Job(
    id: 'FX-2038',
    title: 'Breaker trips when the oven is on',
    description: 'Disjoncteur cuts the whole kitchen when the oven and the kettle run together.',
    trade: Trade.electrical,
    urgency: Urgency.week,
    commune: clientCommune,
    location: clientHome,
    status: JobStatus.quoted,
    postedMinsAgo: 600,
    clientName: clientName,
    quotes: [
      Quote(craftsman: byId('c2'), amount: 4500, eta: 'Tomorrow 9:00', note: 'Likely needs a dedicated 32A circuit for the oven.'),
      Quote(craftsman: byId('c7'), amount: 5200, eta: 'Saturday', note: 'Includes new breaker and cable.'),
    ],
  ),
  Job(
    id: 'FX-1990',
    title: 'Car battery dead in the parking',
    description: 'Clio 4 will not start.',
    trade: Trade.mechanic,
    urgency: Urgency.now,
    commune: clientCommune,
    location: clientHome,
    status: JobStatus.completed,
    postedMinsAgo: 60 * 24 * 6,
    clientName: clientName,
    craftsman: byId('c4'),
    price: 2500,
    messages: [Message(fromMe: false, text: 'Job completed.', time: 'Sat', system: true)],
  ),
];

/// Open requests visible on the craftsman job board.
List<Job> seedBoard() => [
  Job(
    id: 'FX-2050',
    title: 'Kitchen sink pipe burst',
    description: 'Water everywhere under the sink, I closed the main valve. Need someone fast.',
    trade: Trade.plumbing,
    urgency: Urgency.now,
    commune: 'Hussein Dey',
    location: const LatLng(36.7420, 3.0990),
    status: JobStatus.pending,
    postedMinsAgo: 2,
    clientName: 'Sarah M.',
    photos: ['plumb-1'],
    budgetHint: '2 000 – 4 000 DA',
  ),
  Job(
    id: 'FX-2047',
    title: 'Toilet flush runs all night',
    description: 'Chasse d\'eau never stops filling.',
    trade: Trade.plumbing,
    urgency: Urgency.today,
    commune: 'Kouba',
    location: const LatLng(36.7290, 3.0840),
    status: JobStatus.pending,
    postedMinsAgo: 34,
    clientName: 'Mohamed L.',
    budgetHint: '1 500 – 2 500 DA',
  ),
  Job(
    id: 'FX-2043',
    title: 'Install new bathroom mixer',
    description: 'I bought the mixer (Grohe), need it installed. Old one is rusted.',
    trade: Trade.plumbing,
    urgency: Urgency.week,
    commune: 'El Magharia',
    location: const LatLng(36.7320, 3.1100),
    status: JobStatus.pending,
    postedMinsAgo: 180,
    clientName: 'Khadidja R.',
    budgetHint: 'Open to quotes',
  ),
];

List<Job> seedProActive() => [
  Job(
    id: 'FX-2041',
    title: 'Water heater leaking under the tank',
    description: 'Chauffe-eau drips from the bottom valve.',
    trade: Trade.plumbing,
    urgency: Urgency.today,
    commune: 'Kouba',
    location: clientHome,
    status: JobStatus.accepted,
    postedMinsAgo: 95,
    clientName: clientName,
    price: 3500,
  ),
  Job(
    id: 'FX-2029',
    title: 'Replace shower hose and head',
    description: '',
    trade: Trade.plumbing,
    urgency: Urgency.week,
    commune: 'Hussein Dey',
    location: const LatLng(36.7397, 3.0950),
    status: JobStatus.inProgress,
    postedMinsAgo: 60 * 26,
    clientName: 'Rafik T.',
    price: 2000,
  ),
];

List<VerificationRequest> seedVerifications() => [
  VerificationRequest(
    craftsman: byId('c6'),
    nin: '1099 8823 4410 2275 03',
    submittedHoursAgo: 3,
    documents: ['National ID (front)', 'National ID (back)', 'CFPA certificate'],
  ),
  VerificationRequest(
    craftsman: byId('c9'),
    nin: '1098 1172 0934 5561 11',
    submittedHoursAgo: 20,
    documents: ['National ID (front)', 'National ID (back)', 'Registre de commerce'],
  ),
];

List<Flag> seedFlags() {
  // The suspicious review is live on Rachid's profile (it drags his rating
  // down) until a moderator hides it.
  final spam = Review(author: 'User #4471', punctuality: 1, pricing: 1, quality: 1, text: 'Thief, never call him.', daysAgo: 0);
  byId('c3').reviews.insert(0, spam);
  return [
    Flag(
      kind: 'review',
      subject: 'Review on Rachid Ouali',
      reason: 'Same phone posted 4 one-star reviews on AC technicians in 1 hour',
      reporter: 'Auto-detector',
      hoursAgo: 1,
      review: spam,
    ),
    Flag(
      kind: 'conduct',
      subject: 'Job FX-1977',
      reason: 'Client reports the craftsman asked for double the agreed price on site',
      reporter: 'Lamia D.',
      hoursAgo: 5,
    ),
    Flag(
      kind: 'listing',
      subject: 'Profile: "Fast Repair 24/7"',
      reason: 'Portfolio photos copied from a Google search',
      reporter: 'Hamza Benali',
      hoursAgo: 28,
    ),
  ];
}

/// Admin metrics, last 14 days.
const requestsPerDay = [38, 41, 35, 52, 61, 47, 44, 58, 66, 71, 63, 59, 74, 82];
const completedPerDay = [30, 35, 29, 44, 50, 41, 39, 49, 57, 60, 55, 52, 63, 70];
const tradeShare = {Trade.plumbing: 34, Trade.electrical: 22, Trade.hvac: 18, Trade.mechanic: 12, Trade.carpentry: 8, Trade.painting: 6};

// ---------- booking wizard ----------

const addresses = [
  Address('Home', 'Cité 1200 Logements, Bt 14', 'Kouba', clientHome),
  Address('Parents', 'Rue Hassiba Ben Bouali', 'Hussein Dey', LatLng(36.7420, 3.0990)),
  Address('Office', 'Lot. Said Hamdine', 'Bir Mourad Raïs', LatLng(36.7390, 3.0450)),
];

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
String dayLabel(DateTime d) {
  final today = DateTime.now();
  final diff = DateTime(d.year, d.month, d.day).difference(DateTime(today.year, today.month, today.day)).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Tomorrow';
  return '${_dayShort[d.weekday - 1]} ${d.day} ${_monthShort[d.month - 1]}';
}

String weekday(DateTime d) => _dayShort[d.weekday - 1];

/// Next 6 days of 2-hour windows. Friday afternoon is off; a few windows
/// are already booked so the picker has something to skip.
List<List<Slot>> slotsAhead() {
  final now = DateTime.now();
  final days = <List<Slot>>[];
  for (var d = 0; d < 6; d++) {
    final day = DateTime(now.year, now.month, now.day + d);
    final list = <Slot>[];
    for (final h in [8, 10, 12, 14, 16, 18]) {
      if (day.weekday == DateTime.friday && h >= 12) continue;
      final past = d == 0 && h <= now.hour;
      final busy = (d * 7 + h) % 5 == 0;
      list.add(Slot(day: day, start: h, end: h + 2, taken: past || busy));
    }
    days.add(list);
  }
  return days;
}

/// Mock vision model: a canned read per sample photo.
Diagnosis diagnose(String photo, Trade? trade) => switch (photo) {
  'plumb-1' => const Diagnosis(
    issue: 'Worn compression seal on the supply valve',
    confidence: .86,
    minutes: 45,
    parts: 'Seal kit + PTFE tape',
    partsCost: 450,
    title: 'Supply valve dripping',
  ),
  'plumb-2' => const Diagnosis(
    issue: 'Cracked P-trap under the basin',
    confidence: .78,
    minutes: 40,
    parts: 'PVC P-trap 40 mm',
    partsCost: 700,
    title: 'Leak under the sink',
  ),
  'elec-1' => const Diagnosis(
    issue: 'Overloaded circuit, breaker undersized',
    confidence: .71,
    minutes: 90,
    parts: '32A breaker + 6 mm² cable',
    partsCost: 2400,
    title: 'Breaker keeps tripping',
  ),
  'mech-1' => const Diagnosis(
    issue: 'Battery terminals corroded',
    confidence: .74,
    minutes: 30,
    parts: 'Terminal clamps',
    partsCost: 600,
    title: "Car won't start",
  ),
  'wood-1' => const Diagnosis(
    issue: 'Door hinge screws stripped, door sagging',
    confidence: .82,
    minutes: 50,
    parts: '3 hinges + long screws',
    partsCost: 900,
    title: "Door won't close",
  ),
  _ => Diagnosis(
    issue: 'Rust on the fitting, likely a slow leak',
    confidence: .63,
    minutes: 60,
    parts: 'Fitting + sealant',
    partsCost: 800,
    title: '${trade?.label ?? 'Repair'} needed',
  ),
};

/// Upfront estimate: call-out + labour range + parts + urgent fee + service fee.
PriceEstimate estimateFor(Trade trade, {required bool instant, Diagnosis? dx}) {
  final pros = craftsmen.where((c) => c.trade == trade).toList();
  final callout = pros.isEmpty ? 1000 : (pros.map((c) => c.callout).reduce((a, b) => a + b) / pros.length / 100).round() * 100;
  final hourly = pros.isEmpty ? 1500 : (pros.map((c) => c.hourly).reduce((a, b) => a + b) / pros.length / 100).round() * 100;
  final mins = dx?.minutes ?? 60;
  final labourLow = (hourly * mins / 60 / 100).round() * 100;
  final labourHigh = (labourLow * 1.6 / 100).round() * 100;
  return PriceEstimate([
    PriceLine('Call-out', callout),
    PriceLine('Labour', labourLow, labourHigh, dx == null ? 'about 1 h' : 'about ${dx.minutes} min'),
    if (dx != null) PriceLine('Parts', dx.partsCost, (dx.partsCost * 1.3 / 50).round() * 50, dx.parts),
    if (instant) const PriceLine('Instant fee', 800, 800, 'priority dispatch'),
    const PriceLine('Fixy service fee', 200),
  ]);
}

// ---------- live tracking ----------

/// A street-ish route: steps that alternate north-south and east-west legs
/// with a small wobble, so it reads as driving rather than a straight line.
List<LatLng> routeBetween(LatLng from, LatLng to) {
  const legs = 6;
  final pts = <LatLng>[from];
  for (var i = 1; i < legs; i++) {
    final t = i / legs;
    final wobble = (i.isEven ? 1 : -1) * 0.0012;
    final lat = from.latitude + (to.latitude - from.latitude) * t;
    final lng = from.longitude + (to.longitude - from.longitude) * t;
    final prev = pts.last;
    pts.add(i.isOdd ? LatLng(lat + wobble, prev.longitude) : LatLng(prev.latitude, lng + wobble));
  }
  pts.add(LatLng(to.latitude, pts.last.longitude));
  pts.add(to);
  return pts;
}

double routeKm(List<LatLng> r) {
  var d = 0.0;
  for (var i = 1; i < r.length; i++) {
    d += kmFrom(r[i - 1], r[i]);
  }
  return d;
}

/// Point at [t] (0..1) along the route, by distance.
LatLng pointAlong(List<LatLng> r, double t) {
  final total = routeKm(r);
  var target = total * t.clamp(0.0, 1.0);
  for (var i = 1; i < r.length; i++) {
    final seg = kmFrom(r[i - 1], r[i]);
    if (target <= seg || i == r.length - 1) {
      final f = seg == 0 ? 0.0 : (target / seg).clamp(0.0, 1.0);
      return LatLng(r[i - 1].latitude + (r[i].latitude - r[i - 1].latitude) * f, r[i - 1].longitude + (r[i].longitude - r[i - 1].longitude) * f);
    }
    target -= seg;
  }
  return r.last;
}

/// City driving in Alger: ~18 km/h door to door, never under a minute.
int etaMins(Trip t) {
  final left = routeKm(t.route) * (1 - t.progress);
  return t.arrived ? 0 : (left / 18 * 60).ceil().clamp(1, 999);
}

// ---------- m'lem wallet ----------

const commissionRate = 0.10;

List<Payout> seedPayouts() => const [
  Payout(label: 'Kitchen tap replaced · Kouba', amount: 3150, daysAgo: 0, jobId: 'FX-2035'),
  Payout(label: 'Water heater service · Hydra', amount: 4050, daysAgo: 1, jobId: 'FX-2031'),
  Payout(label: 'Cash out to CCP •• 4471', amount: -12000, daysAgo: 2, cashOut: true),
  Payout(label: 'Shower mixer install · Hussein Dey', amount: 2700, daysAgo: 3, jobId: 'FX-2024'),
  Payout(label: 'Leak search · El Biar', amount: 5400, daysAgo: 4, jobId: 'FX-2019'),
  Payout(label: 'Toilet flush repair · Kouba', amount: 1800, daysAgo: 5, jobId: 'FX-2012'),
];

String dzd(int amount) {
  if (amount < 0) return '−${dzd(-amount)}';
  final s = amount.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf DA';
}

String ago(int mins) {
  if (mins < 1) return 'now';
  if (mins < 60) return '$mins min ago';
  if (mins < 60 * 24) return '${mins ~/ 60} h ago';
  return '${mins ~/ (60 * 24)} d ago';
}

final _dist = const Distance();
double kmFrom(LatLng a, LatLng b) => _dist.as(LengthUnit.Meter, a, b) / 1000;
String km(double v) => v < 1 ? '${(v * 1000).round()} m' : '${v.toStringAsFixed(1)} km';

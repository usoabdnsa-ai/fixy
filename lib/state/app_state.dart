import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock.dart';
import '../data/models.dart';

/// In-memory store for the prototype. Every "network" call is a short
/// Future.delayed so loading states are real and visible.
class AppState extends ChangeNotifier {
  Role? role;
  String phone = '';

  final List<Job> clientJobs = seedClientJobs();
  final List<Job> board = seedBoard();
  final List<Job> proJobs = seedProActive();
  final List<VerificationRequest> verifications = seedVerifications();
  final List<Flag> flags = seedFlags();
  final Set<String> favorites = {'c1'};

  bool online = true;
  int radiusKm = 8;
  Job? incoming; // live alert shown on the craftsman home
  Timer? _alertTimer;
  int _seq = 2060;

  void signIn(Role r, String phoneNumber) {
    role = r;
    phone = phoneNumber;
    if (r == Role.craftsman) _scheduleAlert();
    notifyListeners();
  }

  void signOut() {
    role = null;
    _alertTimer?.cancel();
    incoming = null;
    notifyListeners();
  }

  void toggleFavorite(String id) {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    notifyListeners();
  }

  // ---------- client ----------

  Future<Job> postRequest({
    required Trade trade,
    required String title,
    required String description,
    required Urgency urgency,
    required List<String> photos,
    Craftsman? direct,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final job = Job(
      id: 'FX-${_seq++}',
      title: title.isEmpty ? '${trade.label} job' : title,
      description: description,
      trade: trade,
      urgency: urgency,
      commune: clientCommune,
      location: clientHome,
      status: direct != null ? JobStatus.pending : JobStatus.pending,
      postedMinsAgo: 0,
      clientName: clientName,
      photos: photos,
      craftsman: direct,
    );
    clientJobs.insert(0, job);
    notifyListeners();
    // Simulate craftsmen answering with quotes a few seconds later.
    if (direct == null) {
      Timer(const Duration(seconds: 4), () {
        final pros = craftsmen.where((c) => c.trade == trade && c.available).take(2).toList();
        for (final p in pros) {
          job.quotes.add(
            Quote(
              craftsman: p,
              amount: p.callout + p.hourly * 2,
              eta: urgency == Urgency.now ? '${p.responseMins + 10} min' : 'Tomorrow',
              note: 'Can come with parts.',
            ),
          );
        }
        if (job.quotes.isNotEmpty && job.status == JobStatus.pending) job.status = JobStatus.quoted;
        notifyListeners();
      });
    }
    return job;
  }

  void acceptQuote(Job job, Quote q) {
    job.craftsman = q.craftsman;
    job.price = q.amount;
    job.status = JobStatus.accepted;
    job.messages.add(Message(fromMe: false, text: 'Quote accepted. Chat is now open with ${q.craftsman.firstName}.', time: 'now', system: true));
    notifyListeners();
  }

  void cancelJob(Job job) {
    job.status = JobStatus.cancelled;
    notifyListeners();
  }

  void sendMessage(Job job, String text) {
    job.messages.add(Message(fromMe: true, text: text, time: 'now'));
    notifyListeners();
    final c = job.craftsman;
    if (c == null) return;
    Timer(const Duration(milliseconds: 1600), () {
      job.messages.add(Message(fromMe: false, text: 'Bien reçu, ${c.firstName} here. I will confirm shortly.', time: 'now'));
      notifyListeners();
    });
  }

  /// One rating per completed job; the guard lives here, not in the UI.
  bool rate(Job job, {required int punctuality, required int pricing, required int quality, required String text}) {
    if (job.rated || job.status != JobStatus.completed || job.craftsman == null) return false;
    job.craftsman!.reviews.insert(0, Review(author: 'Amina B.', punctuality: punctuality, pricing: pricing, quality: quality, text: text, daysAgo: 0));
    job.rated = true;
    notifyListeners();
    return true;
  }

  // ---------- craftsman ----------

  void setOnline(bool v) {
    online = v;
    if (!v) {
      incoming = null;
      _alertTimer?.cancel();
    } else {
      _scheduleAlert();
    }
    notifyListeners();
  }

  void setRadius(int v) {
    radiusKm = v;
    notifyListeners();
  }

  void _scheduleAlert() {
    _alertTimer?.cancel();
    _alertTimer = Timer(const Duration(seconds: 6), () {
      if (!online || role != Role.craftsman) return;
      incoming = Job(
        id: 'FX-${_seq++}',
        title: 'Water coming through the ceiling',
        description: 'Neighbour upstairs is away, water is dripping from the bathroom ceiling.',
        trade: Trade.plumbing,
        urgency: Urgency.now,
        commune: 'Kouba',
        location: const LatLng(36.7330, 3.0890),
        status: JobStatus.pending,
        postedMinsAgo: 0,
        clientName: 'Yasmine K.',
        budgetHint: '3 000 – 6 000 DA',
      );
      notifyListeners();
    });
  }

  void dismissIncoming() {
    if (incoming != null) board.insert(0, incoming!);
    incoming = null;
    notifyListeners();
  }

  void acceptBoardJob(Job job, {int? price}) {
    board.remove(job);
    if (incoming == job) incoming = null;
    job.status = JobStatus.accepted;
    job.price = price ?? job.price;
    proJobs.insert(0, job);
    notifyListeners();
  }

  void declineBoardJob(Job job) {
    board.remove(job);
    if (incoming == job) incoming = null;
    notifyListeners();
  }

  void advance(Job job) {
    job.status = switch (job.status) {
      JobStatus.accepted => JobStatus.inProgress,
      JobStatus.inProgress => JobStatus.completed,
      _ => job.status,
    };
    // Keep the client's copy in sync for the demo.
    for (final j in clientJobs.where((j) => j.id == job.id)) {
      j.status = job.status;
    }
    notifyListeners();
  }

  int get earningsWeek => 18500 + proJobs.where((j) => j.status == JobStatus.completed).fold(0, (s, j) => s + (j.price ?? 0));

  // ---------- admin ----------

  void decide(VerificationRequest v, bool approve) {
    v.decision = approve;
    v.craftsman.verified = approve;
    notifyListeners();
  }

  void resolveFlag(Flag f, {required bool removeContent}) {
    f.resolved = true;
    if (removeContent && f.review != null) f.review!.flagged = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }
}

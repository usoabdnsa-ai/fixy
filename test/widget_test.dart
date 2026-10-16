import 'package:fixy/data/mock.dart';
import 'package:fixy/data/models.dart';
import 'package:fixy/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a completed job can be rated only once', () {
    final s = AppState();
    final job = s.clientJobs.firstWhere((j) => j.status == JobStatus.completed);
    final before = job.craftsman!.reviews.length;
    expect(s.rate(job, punctuality: 5, pricing: 4, quality: 5, text: 'ok'), isTrue);
    expect(s.rate(job, punctuality: 1, pricing: 1, quality: 1, text: 'spam'), isFalse);
    expect(job.craftsman!.reviews.length, before + 1);
  });

  test('jobs that are not completed cannot be rated', () {
    final s = AppState();
    final job = s.clientJobs.firstWhere((j) => j.status == JobStatus.accepted);
    expect(s.rate(job, punctuality: 5, pricing: 5, quality: 5, text: 'x'), isFalse);
  });

  test('hiding a flagged review recalculates the rating', () {
    final s = AppState();
    final rachid = byId('c3');
    final withSpam = rachid.rating;
    s.resolveFlag(s.flags.firstWhere((f) => f.kind == 'review'), removeContent: true);
    expect(rachid.rating, greaterThan(withSpam));
  });

  test('dzd formats with thin spaces', () {
    expect(dzd(3500), '3 500 DA');
  });
}

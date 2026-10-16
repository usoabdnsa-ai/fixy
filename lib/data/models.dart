import 'package:flutter/widgets.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/icons.dart';

enum Role { client, craftsman, admin }

enum Trade {
  plumbing('Plumbing', 'Plombier', PhosphorIconsBold.pipeWrench),
  electrical('Electrical', 'Électricien', PhosphorIconsBold.lightning),
  hvac('AC repair', 'Climatisation', PhosphorIconsBold.snowflake),
  mechanic('Mechanic', 'Mécanicien', PhosphorIconsBold.car),
  carpentry('Carpentry', 'Menuisier', PhosphorIconsBold.hammer),
  painting('Painting', 'Peintre', PhosphorIconsBold.paintRoller);

  const Trade(this.label, this.local, this.icon);
  final String label;
  final String local;
  final IconData icon;
}

enum Urgency {
  now('Right now', 'Leak, outage, danger'),
  today('Today', 'Within a few hours'),
  week('This week', 'Can wait, want quotes');

  const Urgency(this.label, this.hint);
  final String label;
  final String hint;
}

enum JobStatus {
  pending('Pending'),
  quoted('Quotes in'),
  accepted('Accepted'),
  inProgress('In progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const JobStatus(this.label);
  final String label;
}

class Review {
  Review({
    required this.author,
    required this.punctuality,
    required this.pricing,
    required this.quality,
    required this.text,
    required this.daysAgo,
    this.flagged = false,
  });
  final String author;
  final int punctuality;
  final int pricing;
  final int quality;
  final String text;
  final int daysAgo;
  bool flagged;
  double get average => (punctuality + pricing + quality) / 3;
}

class Craftsman {
  Craftsman({
    required this.id,
    required this.name,
    required this.trade,
    required this.commune,
    required this.wilaya,
    required this.location,
    required this.years,
    required this.hourly,
    required this.callout,
    required this.verified,
    required this.available,
    required this.jobsDone,
    required this.bio,
    required this.photos,
    required this.reviews,
    required this.skills,
    required this.wilayas,
    required this.responseMins,
    this.certificates = const [],
  });
  final String id;
  final String name;
  final Trade trade;
  final String commune;
  final String wilaya;
  final LatLng location;
  final int years;
  final int hourly; // DZD
  final int callout; // DZD flat fee to come out
  bool verified;
  bool available;
  final int jobsDone;
  final String bio;
  final List<String> photos;
  final List<Review> reviews;
  final List<String> skills;
  final List<String> wilayas;
  final int responseMins;
  final List<String> certificates;

  String get initials => name.split(' ').take(2).map((p) => p[0]).join();
  String get firstName => name.split(' ').first;

  double get rating {
    final visible = reviews.where((r) => !r.flagged).toList();
    if (visible.isEmpty) return 0;
    return visible.map((r) => r.average).reduce((a, b) => a + b) / visible.length;
  }

  double sub(int Function(Review r) pick) {
    final visible = reviews.where((r) => !r.flagged).toList();
    if (visible.isEmpty) return 0;
    return visible.map(pick).reduce((a, b) => a + b) / visible.length;
  }
}

class Quote {
  Quote({required this.craftsman, required this.amount, required this.eta, required this.note});
  final Craftsman craftsman;
  final int amount;
  final String eta;
  final String note;
}

class Message {
  Message({required this.fromMe, required this.text, required this.time, this.system = false});
  final bool fromMe;
  final String text;
  final String time;
  final bool system;
}

class Job {
  Job({
    required this.id,
    required this.title,
    required this.description,
    required this.trade,
    required this.urgency,
    required this.commune,
    required this.location,
    required this.status,
    required this.postedMinsAgo,
    required this.clientName,
    this.photos = const [],
    this.craftsman,
    this.price,
    List<Quote>? quotes,
    List<Message>? messages,
    this.rated = false,
    this.budgetHint,
  }) : quotes = quotes ?? [],
       messages = messages ?? [];
  final String id;
  final String title;
  final String description;
  final Trade trade;
  final Urgency urgency;
  final String commune;
  final LatLng location;
  JobStatus status;
  final int postedMinsAgo;
  final String clientName;
  final List<String> photos;
  Craftsman? craftsman;
  int? price;
  final List<Quote> quotes;
  final List<Message> messages;
  bool rated;
  final String? budgetHint;
}

class VerificationRequest {
  VerificationRequest({required this.craftsman, required this.nin, required this.submittedHoursAgo, required this.documents, this.decision});
  final Craftsman craftsman;
  final String nin;
  final int submittedHoursAgo;
  final List<String> documents;
  bool? decision;
}

class Flag {
  Flag({required this.kind, required this.subject, required this.reason, required this.reporter, required this.hoursAgo, this.review, this.resolved = false});
  final String kind; // review, conduct, listing
  final String subject;
  final String reason;
  final String reporter;
  final int hoursAgo;
  final Review? review;
  bool resolved;
}

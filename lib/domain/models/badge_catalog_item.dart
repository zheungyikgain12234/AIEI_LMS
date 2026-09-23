import 'package:stitch_aiei_lms/core/session/app_session.dart';

/// One row of the Badges master data (`certifications` table) — admin
/// managed, exposing only the fields the admin form asks for: a unique
/// code, name, description, and issuing party. Every other column on
/// `certifications` (badge_icon, competencies, hash, narrative,
/// accrediting_bodies, metrics) is left at its schema default; those back
/// the richer student-facing Certifications & Badges screen, not this form.
class BadgeCatalogItem {
  final String id;
  final String code;
  final String title;
  final String description;
  final String issuingBody;

  const BadgeCatalogItem({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.issuingBody,
  });

  factory BadgeCatalogItem.fromMap(Map<String, dynamic> map) {
    return BadgeCatalogItem(
      id: map['id'] as String,
      code: displayCode(map['code'] as String),
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      issuingBody: map['issuing_body'] as String,
    );
  }
}

import 'package:flutter/material.dart';

/// An earned enterprise credential / badge, either active & verified or
/// revoked & suspended (see [isRevoked]).
class EarnedCredential {
  final String id;
  final String categoryTag;
  final String statusPillText;
  final IconData statusPillIcon;
  final bool isRevoked;
  final IconData emblemIcon;
  final String emblemCode;
  final String emblemSubtext;
  final String title;
  final String? titleChipText;
  final String description;
  final IconData metaIcon;
  final String metaText;
  final String hash;
  final String? incidentBannerText;
  final String? incidentLinkText;
  final String competenciesLabel;
  final List<String> competencies;
  final bool linkedInEnabled;
  final String linkedInButtonText;
  final String footerLinkText;
  final String issuerFullName;

  // Detail-screen-only fields (executive_leadership_detail_screen.dart /
  // revoked_credential_detail_screen.dart).
  final String narrative;
  final List<String> accreditingBodies;
  final Map<String, dynamic> metrics;
  final String? cohortLabel;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? revokedAt;
  final String? caseRef;
  final String? inspectingOfficer;

  const EarnedCredential({
    required this.id,
    required this.categoryTag,
    required this.statusPillText,
    required this.statusPillIcon,
    required this.isRevoked,
    required this.emblemIcon,
    required this.emblemCode,
    required this.emblemSubtext,
    required this.title,
    this.titleChipText,
    required this.description,
    required this.metaIcon,
    required this.metaText,
    required this.hash,
    this.incidentBannerText,
    this.incidentLinkText,
    required this.competenciesLabel,
    required this.competencies,
    required this.linkedInEnabled,
    required this.linkedInButtonText,
    required this.footerLinkText,
    required this.issuerFullName,
    this.narrative = '',
    this.accreditingBodies = const [],
    this.metrics = const {},
    this.cohortLabel,
    this.issuedAt,
    this.expiresAt,
    this.revokedAt,
    this.caseRef,
    this.inspectingOfficer,
  });
}

import 'package:flutter/material.dart';

/// An earned enterprise credential / badge, either active & verified or
/// revoked & suspended (see [isRevoked]).
class EarnedCredential {
  final String id;
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
  final String? incidentBannerText;
  final String issuerFullName;

  const EarnedCredential({
    required this.id,
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
    this.incidentBannerText,
    required this.issuerFullName,
  });
}

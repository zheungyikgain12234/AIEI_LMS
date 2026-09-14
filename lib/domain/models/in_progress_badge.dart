import 'package:flutter/material.dart';

/// A badge / certification track that is still in progress or locked.
class InProgressBadge {
  final String id;
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String statusChipText;
  final bool isUrgent;
  final String title;
  final String description;
  final int progressPercent;
  final int completedModules;
  final int totalModules;
  final Color progressColor;
  final String checklistDoneText;
  final IconData checklistPendingIcon;
  final Color checklistPendingColor;
  final String checklistPendingText;
  final String ctaText;

  const InProgressBadge({
    required this.id,
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.statusChipText,
    this.isUrgent = false,
    required this.title,
    required this.description,
    required this.progressPercent,
    required this.completedModules,
    required this.totalModules,
    required this.progressColor,
    required this.checklistDoneText,
    required this.checklistPendingIcon,
    required this.checklistPendingColor,
    required this.checklistPendingText,
    required this.ctaText,
  });
}

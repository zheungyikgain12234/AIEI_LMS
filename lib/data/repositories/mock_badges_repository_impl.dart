import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';
import 'package:stitch_aiei_lms/domain/repositories/badges_repository.dart';

class MockBadgesRepositoryImpl implements BadgesRepository {
  @override
  Future<BadgeStats> getBadgeStats() async {
    return const BadgeStats(
      totalBadgesEarned: 2,
      totalBadgesTag: 'Accredited',
      totalBadgesSubtitle: 'Top tier compliance verified',
      inProgressCount: 4,
      inProgressTag: 'Active Tracks',
      inProgressSubtitle: 'Avg. completion 54%',
    );
  }

  @override
  Future<List<EarnedCredential>> getEarnedCredentials() async {
    return const [
      EarnedCredential(
        id: 'badge-oshabig',
        categoryTag: 'OSHA / OSHE Compliant',
        statusPillText: 'Revoked • Incident #INC-2025-08492',
        statusPillIcon: Icons.cancel,
        isRevoked: true,
        emblemIcon: Icons.gpp_bad,
        emblemCode: 'CSO-2025',
        emblemSubtext: 'VOIDED',
        title: 'Certified Safety Officer 2025',
        titleChipText: 'Suspended',
        description:
            'Comprehensive occupational health and hazardous material incident management, site command protocol, and emergency mitigation.',
        metaIcon: Icons.warning,
        metaText: 'Revoked by OSHA Accredited Corporate Board',
        hash: '0x7F2B...C84B (Ledger Status: REVOKED)',
        incidentBannerText:
            'Incident #INC-2025-08492: Switchboard Safety Infraction',
        incidentLinkText: 'View Revocation Notice',
        competenciesLabel: 'Competencies (Credentials Voided)',
        competencies: [
          'Hazard Identification',
          'GHS Rev 8',
          'Emergency Evacuation',
          'SDS Compliance',
        ],
        linkedInEnabled: false,
        linkedInButtonText: 'Add to LinkedIn (Disabled)',
        footerLinkText: 'View Revocation Audit Ledger',
        issuerFullName: 'OSHA Accredited Corporate Board',
      ),
      EarnedCredential(
        id: 'badge-leadbig',
        categoryTag: 'Executive Leadership Track',
        statusPillText: 'Top 5% Cohort Score',
        statusPillIcon: Icons.workspace_premium,
        isRevoked: false,
        emblemIcon: Icons.record_voice_over,
        emblemCode: 'EXEC-COMM',
        emblemSubtext: 'OCT 2024',
        title: 'Leadership Communicator & Executive Alignment',
        description:
            'High-stakes boardroom presentation, cross-functional organizational influence, investor messaging, and conflict mediation.',
        metaIcon: Icons.school,
        metaText: 'Issuer: AIEI Executive Leadership Academy',
        hash: '0x94D1...71E0',
        competenciesLabel: 'Competencies Verified',
        competencies: [
          'Stakeholder Management',
          'Boardroom Synthesis',
          'Crisis Comms',
          'Executive Presence',
        ],
        linkedInEnabled: true,
        linkedInButtonText: 'Add to LinkedIn',
        footerLinkText: 'View Verification Ledger',
        issuerFullName: 'SkillBridge Executive Leadership Academy',
      ),
    ];
  }

  @override
  Future<List<InProgressBadge>> getInProgressBadges() async {
    return const [
      InProgressBadge(
        id: 'python-automation',
        icon: Icons.terminal,
        iconColor: AppColors.secondary,
        iconBackgroundColor: AppColors.surfaceContainerLow,
        statusChipText: '70% Done',
        title: 'Python Automation Specialist 2025',
        description:
            'Data pipeline orchestration, API integration, and automated ETL workflows.',
        progressPercent: 70,
        completedModules: 7,
        totalModules: 10,
        progressColor: AppColors.secondary,
        checklistDoneText: 'Advanced NumPy & Pandas',
        checklistPendingIcon: Icons.schedule,
        checklistPendingColor: AppColors.onSurfaceVariant,
        checklistPendingText: 'Capstone: Distributed Web Scraping',
        ctaText: 'Resume Capstone',
      ),
      InProgressBadge(
        id: 'enterprise-ai',
        icon: Icons.smart_toy,
        iconColor: AppColors.primary,
        iconBackgroundColor: AppColors.surfaceContainerLow,
        statusChipText: '40% Done',
        title: 'Enterprise AI & Prompt Engineering',
        description:
            'LLM prompt chains, context retrieval architectures, and agentic workflows.',
        progressPercent: 40,
        completedModules: 4,
        totalModules: 10,
        progressColor: AppColors.secondaryContainer,
        checklistDoneText: 'Context Window Design',
        checklistPendingIcon: Icons.lock,
        checklistPendingColor: AppColors.onSurfaceVariant,
        checklistPendingText: '6 Lessons Remaining',
        ctaText: 'Resume Module 5',
      ),
      InProgressBadge(
        id: 'cyber-sentinel',
        icon: Icons.security,
        iconColor: AppColors.error,
        iconBackgroundColor: AppColors.errorContainer,
        statusChipText: 'Due in 5 Days',
        isUrgent: true,
        title: 'Certified Cyber Sentinel',
        description:
            'Phishing vectors, social engineering prevention, and live drill response.',
        progressPercent: 85,
        completedModules: 0,
        totalModules: 0,
        progressColor: AppColors.error,
        checklistDoneText: 'Zero-Day Attack Patterns',
        checklistPendingIcon: Icons.warning_amber_rounded,
        checklistPendingColor: AppColors.error,
        checklistPendingText: 'Final Incident Sim Due',
        ctaText: 'Continue Course',
      ),
      InProgressBadge(
        id: 'fpa-analyst',
        icon: Icons.analytics,
        iconColor: AppColors.outline,
        iconBackgroundColor: AppColors.surfaceContainerLow,
        statusChipText: '20% Done',
        title: 'FP&A Certified Financial Analyst',
        description:
            'Forecasting methodologies, capital expenditure modeling, and budget variance.',
        progressPercent: 20,
        completedModules: 2,
        totalModules: 10,
        progressColor: AppColors.outline,
        checklistDoneText: 'P&L Mechanics',
        checklistPendingIcon: Icons.lock,
        checklistPendingColor: AppColors.onSurfaceVariant,
        checklistPendingText: '8 Lessons Locked',
        ctaText: 'Continue Course',
      ),
    ];
  }
}

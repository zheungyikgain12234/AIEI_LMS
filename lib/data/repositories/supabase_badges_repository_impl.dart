import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';
import 'package:stitch_aiei_lms/domain/repositories/badges_repository.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart';

/// Supabase-backed [BadgesRepository]. "In progress" badges are simply the
/// demo student's not-yet-completed enrolled courses (reuses
/// [CoursesRepository] rather than re-deriving the same course/module/
/// material join), while "earned" credentials come from `student_certifications`.
class SupabaseBadgesRepositoryImpl implements BadgesRepository {
  SupabaseBadgesRepositoryImpl(this._client, this._coursesRepository);

  final SupabaseClient _client;
  final CoursesRepository _coursesRepository;

  @override
  Future<BadgeStats> getBadgeStats() async {
    final earned = await getEarnedCredentials();
    final inProgress = await getInProgressBadges();
    final activeCount = earned.where((c) => !c.isRevoked).length;

    return BadgeStats(
      totalBadgesEarned: activeCount,
      totalBadgesTag: 'Accredited',
      totalBadgesSubtitle: 'Top tier compliance verified',
      inProgressCount: inProgress.length,
      inProgressTag: 'Active Tracks',
      inProgressSubtitle: inProgress.isEmpty
          ? 'No active tracks'
          : 'Avg. completion ${(inProgress.fold<int>(0, (sum, b) => sum + b.progressPercent) / inProgress.length).round()}%',
    );
  }

  @override
  Future<List<EarnedCredential>> getEarnedCredentials() async {
    final rows = await _client
        .from('student_certifications')
        .select('*, certifications(*)')
        .eq('student_id', DemoIdentity.studentId)
        .inFilter('status', ['earned', 'revoked']);

    return [
      for (final row in rows as List) _mapEarnedCredential(row as Map<String, dynamic>),
    ];
  }

  EarnedCredential _mapEarnedCredential(Map<String, dynamic> row) {
    final cert = row['certifications'] as Map<String, dynamic>;
    final isRevoked = row['status'] == 'revoked';
    final competencies = List<String>.from(cert['competencies'] as List? ?? []);

    return EarnedCredential(
      id: row['id'] as String,
      categoryTag: cert['title'] as String,
      statusPillText: isRevoked
          ? 'Revoked • Incident #${row['case_ref'] ?? 'N/A'}'
          : 'Verified',
      statusPillIcon: isRevoked ? Icons.cancel : Icons.workspace_premium,
      isRevoked: isRevoked,
      emblemIcon: isRevoked ? Icons.gpp_bad : Icons.military_tech,
      emblemCode: (cert['id'] as String).substring(0, 8).toUpperCase(),
      emblemSubtext: isRevoked ? 'VOIDED' : 'VERIFIED',
      title: cert['title'] as String,
      titleChipText: isRevoked ? 'Suspended' : null,
      description: cert['description'] as String? ?? '',
      metaIcon: isRevoked ? Icons.warning : Icons.school,
      metaText: isRevoked
          ? 'Revoked by ${cert['issuing_body']}'
          : 'Issuer: ${cert['issuing_body']}',
      hash: cert['hash'] as String? ?? '',
      incidentBannerText: isRevoked
          ? 'Incident #${row['case_ref']}: ${row['revocation_reason'] ?? 'Compliance violation'}'
          : null,
      incidentLinkText: isRevoked ? 'View Revocation Notice' : null,
      competenciesLabel: isRevoked ? 'Competencies (Credentials Voided)' : 'Competencies Verified',
      competencies: competencies,
      linkedInEnabled: !isRevoked,
      linkedInButtonText: isRevoked ? 'Add to LinkedIn (Disabled)' : 'Add to LinkedIn',
      footerLinkText: isRevoked ? 'View Revocation Audit Ledger' : 'View Verification Ledger',
      issuerFullName: cert['issuing_body'] as String,
      narrative: cert['narrative'] as String? ?? '',
      accreditingBodies: List<String>.from(cert['accrediting_bodies'] as List? ?? []),
      metrics: Map<String, dynamic>.from(cert['metrics'] as Map? ?? {}),
      cohortLabel: row['cohort_label'] as String?,
      issuedAt: row['issued_at'] != null ? DateTime.parse(row['issued_at'] as String) : null,
      expiresAt: row['expires_at'] != null ? DateTime.parse(row['expires_at'] as String) : null,
      revokedAt: row['revoked_at'] != null ? DateTime.parse(row['revoked_at'] as String) : null,
      caseRef: row['case_ref'] as String?,
      inspectingOfficer: row['inspecting_officer'] as String?,
    );
  }

  @override
  Future<List<InProgressBadge>> getInProgressBadges() async {
    final courses = await _coursesRepository.getEnrolledCourses();
    final inProgress = courses.where((c) => !c.isCompleted).toList();

    return [
      for (final course in inProgress)
        InProgressBadge(
          id: course.id,
          icon: course.instructorIcon,
          iconColor: course.instructorIconColor,
          iconBackgroundColor: AppColors.surfaceContainerLow,
          statusChipText: course.progressPercentage >= 100
              ? 'Done'
              : '${course.progressPercentage}% Done',
          isUrgent: course.deadlineDays <= 7,
          title: course.title,
          description: course.nextLessonOrStatus,
          progressPercent: course.progressPercentage,
          completedModules: course.completedLessons,
          totalModules: course.totalLessons,
          progressColor: course.instructorIconColor,
          checklistDoneText: course.completedLessons > 0 ? 'Progress recorded' : 'Not started yet',
          checklistPendingIcon: course.isWarningNextLesson ? Icons.warning_amber_rounded : Icons.lock,
          checklistPendingColor:
              course.isWarningNextLesson ? AppColors.error : AppColors.onSurfaceVariant,
          checklistPendingText:
              '${course.totalLessons - course.completedLessons} lessons remaining',
          ctaText: course.ctaButtonText,
        ),
    ];
  }
}

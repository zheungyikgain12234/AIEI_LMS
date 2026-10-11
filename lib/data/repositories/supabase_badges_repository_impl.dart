import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stitch_aiei_lms/core/config/demo_identity.dart';
import 'package:stitch_aiei_lms/core/session/app_session.dart';
import 'package:stitch_aiei_lms/core/theme/app_colors.dart';
import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';
import 'package:stitch_aiei_lms/domain/repositories/badges_repository.dart';
import 'package:stitch_aiei_lms/domain/repositories/courses_repository.dart';

/// Supabase-backed [BadgesRepository]. "In progress" badges are simply the
/// demo student's not-yet-completed enrolled courses (reuses
/// [CoursesRepository] rather than re-deriving the same course/module/
/// material join), while "earned" credentials come from `badge_awards` —
/// the same table the admin "Manage Badges" screen and the auto-award-on-
/// course-completion flow (`_syncProgressAndBadges` in
/// SupabaseSubmissionGradingRepositoryImpl) both write to. (An older
/// `student_certifications` table existed for this previously, but nothing
/// in the app writes to it any more — reading from it left every course-
/// completion badge invisible here.)
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
      totalBadgesSubtitle: '',
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
        .from('badge_awards')
        .select('*, certifications(*)')
        .eq('student_id', DemoIdentity.studentId);

    return [
      for (final row in rows as List) _mapEarnedCredential(row as Map<String, dynamic>),
    ];
  }

  EarnedCredential _mapEarnedCredential(Map<String, dynamic> row) {
    final cert = row['certifications'] as Map<String, dynamic>;
    final isRevoked = row['is_revoked'] as bool? ?? false;

    return EarnedCredential(
      id: row['id'] as String,
      statusPillText: isRevoked ? 'Revoked' : 'Verified',
      statusPillIcon: isRevoked ? Icons.cancel : Icons.workspace_premium,
      isRevoked: isRevoked,
      emblemIcon: isRevoked ? Icons.gpp_bad : Icons.military_tech,
      // `certifications.code` (e.g. "TN01-CERT-PYAUTO") is the real,
      // human-assigned badge code — unlike the row's own uuid, which has no
      // meaning to show and (in this seed data) misleadingly looks
      // identical across badges since every certification id happens to
      // start with the same demo prefix.
      emblemCode: displayCode(cert['code'] as String),
      emblemSubtext: isRevoked ? 'VOIDED' : 'VERIFIED',
      title: cert['title'] as String,
      titleChipText: isRevoked ? 'Suspended' : null,
      description: cert['description'] as String? ?? '',
      metaIcon: isRevoked ? Icons.warning : Icons.school,
      metaText: isRevoked
          ? 'Revoked by ${cert['issuing_body']}'
          : 'Issuer: ${cert['issuing_body']}',
      incidentBannerText: isRevoked ? 'This badge has been revoked.' : null,
      issuerFullName: cert['issuing_body'] as String,
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
          isUrgent: false,
          title: course.title,
          description: course.badgeCount > 0 ? 'Unlocks ${course.badgeCount} badge(s) on completion' : 'In progress',
          progressPercent: course.progressPercentage,
          completedModules: course.progressPercentage,
          totalModules: 100,
          progressColor: course.instructorIconColor,
          checklistDoneText: course.progressPercentage > 0 ? 'Progress recorded' : 'Not started yet',
          checklistPendingIcon: Icons.lock,
          checklistPendingColor: AppColors.onSurfaceVariant,
          checklistPendingText: '${100 - course.progressPercentage}% remaining',
          ctaText: course.ctaButtonText,
        ),
    ];
  }
}

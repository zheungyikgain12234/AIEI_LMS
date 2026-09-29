import 'package:stitch_aiei_lms/domain/models/badge_stats.dart';
import 'package:stitch_aiei_lms/domain/models/earned_credential.dart';
import 'package:stitch_aiei_lms/domain/models/in_progress_badge.dart';

class BadgesState {
  final BadgeStats? stats;
  final List<EarnedCredential> earnedCredentials;
  final List<InProgressBadge> inProgressBadges;
  /// The signed-in student's tenant-stripped `student_code` (`students`
  /// table), for the page header — null until loaded.
  final String? studentCode;
  final bool isLoading;
  final String? errorMessage;

  const BadgesState({
    this.stats,
    this.earnedCredentials = const [],
    this.inProgressBadges = const [],
    this.studentCode,
    this.isLoading = false,
    this.errorMessage,
  });

  BadgesState copyWith({
    BadgeStats? stats,
    List<EarnedCredential>? earnedCredentials,
    List<InProgressBadge>? inProgressBadges,
    String? studentCode,
    bool? isLoading,
    String? errorMessage,
  }) {
    return BadgesState(
      stats: stats ?? this.stats,
      earnedCredentials: earnedCredentials ?? this.earnedCredentials,
      inProgressBadges: inProgressBadges ?? this.inProgressBadges,
      studentCode: studentCode ?? this.studentCode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

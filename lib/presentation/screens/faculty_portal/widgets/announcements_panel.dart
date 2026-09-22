import 'package:flutter/material.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_colors.dart';
import 'package:stitch_aiei_lms/core/theme/faculty_typography.dart';
import 'package:stitch_aiei_lms/domain/models/course_announcement.dart';

/// Renders "2h ago" / "3d ago" style relative times for an announcement's
/// `created_at` — shared by the lecturer's Course Dashboard and the
/// student's Course Content sidebar so both read the same way.
String formatAnnouncementTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}

/// One posted announcement — a title/time header, the lecturer's name, and
/// the body text. Used read-only by both the lecturer's own dashboard list
/// and the student sidebar/sheet.
class AnnouncementCard extends StatelessWidget {
  final CourseAnnouncement announcement;

  const AnnouncementCard({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: FacultyColors.surfaceBright, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  announcement.title,
                  style: FacultyTypography.bodyMd(color: FacultyColors.onSurface).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(formatAnnouncementTime(announcement.createdAt), style: FacultyTypography.labelXs()),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            announcement.lecturerName,
            style: FacultyTypography.labelXs(color: FacultyColors.primary).copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(announcement.body, style: FacultyTypography.bodySm()),
        ],
      ),
    );
  }
}

/// The "no announcements yet" placeholder, shared by every surface that
/// lists them.
class AnnouncementsEmptyState extends StatelessWidget {
  const AnnouncementsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Text('No announcements posted yet.', style: FacultyTypography.bodySm());
  }
}

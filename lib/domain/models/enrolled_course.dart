import 'package:flutter/material.dart';

enum CourseCategory {
  all('all', 'All Courses'),
  compliance('compliance', 'Compliance'),
  techData('tech-data', 'Technical & Data'),
  aiTools('ai-tools', 'AI & Tools'),
  productivity('productivity', 'Productivity & Soft Skills');

  final String key;
  final String label;
  const CourseCategory(this.key, this.label);

  static CourseCategory fromKey(String key) {
    return CourseCategory.values.firstWhere(
      (c) => c.key == key,
      orElse: () => CourseCategory.all,
    );
  }
}

class CourseTag {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final bool hasCheckIcon;

  const CourseTag({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.hasCheckIcon = false,
  });
}

class EnrolledCourse {
  final String id;
  final String title;
  final CourseCategory category;

  /// The class (`course_sections` row) this student is enrolled in for this
  /// course — module/session/content-block syllabus is class-scoped, so
  /// this is what "View Course" needs to load the right content. Null if
  /// the student hasn't been assigned to a class yet.
  final String? sectionId;

  /// That class's `section_code` (e.g. `CLS-PY402-A01`) — shown on the
  /// catalogue card so a student can tell classes of the same course apart.
  /// Null alongside [sectionId] when unassigned.
  final String? classCode;
  final String instructorOrBoard;
  final IconData instructorIcon;
  final Color instructorIconColor;
  final String imageUrl;
  final List<CourseTag> tags;
  final String? durationText;
  final String? trackTypeText;
  final String? scoreText;
  final int progressPercentage;

  /// Badges configured on this course (`course_badges`) that the student
  /// unlocks on completion — just the count and names are shown on the
  /// catalogue card (names only on hover), not per-badge detail.
  final int badgeCount;
  final List<String> badgeNames;
  final String ctaButtonText;
  final bool isCompleted;

  const EnrolledCourse({
    required this.id,
    required this.title,
    required this.category,
    this.sectionId,
    this.classCode,
    required this.instructorOrBoard,
    required this.instructorIcon,
    required this.instructorIconColor,
    required this.imageUrl,
    required this.tags,
    this.durationText,
    this.trackTypeText,
    this.scoreText,
    required this.progressPercentage,
    this.badgeCount = 0,
    this.badgeNames = const [],
    required this.ctaButtonText,
    this.isCompleted = false,
  });
}

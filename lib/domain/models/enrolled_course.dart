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
  final String instructorOrBoard;
  final IconData instructorIcon;
  final Color instructorIconColor;
  final String imageUrl;
  final List<CourseTag> tags;
  final String? durationText;
  final String? trackTypeText;
  final String? scoreText;
  final int progressPercentage;
  final int completedLessons;
  final int totalLessons;
  final String nextLessonOrStatus;
  final bool isWarningNextLesson;
  final String unlockBadgeTitle;
  final IconData unlockBadgeIcon;
  final int deadlineDays;
  final String ctaButtonText;
  final bool isCompleted;

  const EnrolledCourse({
    required this.id,
    required this.title,
    required this.category,
    required this.instructorOrBoard,
    required this.instructorIcon,
    required this.instructorIconColor,
    required this.imageUrl,
    required this.tags,
    this.durationText,
    this.trackTypeText,
    this.scoreText,
    required this.progressPercentage,
    required this.completedLessons,
    required this.totalLessons,
    required this.nextLessonOrStatus,
    this.isWarningNextLesson = false,
    required this.unlockBadgeTitle,
    required this.unlockBadgeIcon,
    required this.deadlineDays,
    required this.ctaButtonText,
    this.isCompleted = false,
  });
}

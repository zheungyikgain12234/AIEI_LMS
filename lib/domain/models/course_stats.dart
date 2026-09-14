class CourseStats {
  final int enrolledCourses;
  final int inProgressCourses;
  final int completedCourses;
  final int completedLessons;
  final int totalLessons;
  final int badgesEarned;

  const CourseStats({
    required this.enrolledCourses,
    required this.inProgressCourses,
    required this.completedCourses,
    required this.completedLessons,
    required this.totalLessons,
    required this.badgesEarned,
  });
}
